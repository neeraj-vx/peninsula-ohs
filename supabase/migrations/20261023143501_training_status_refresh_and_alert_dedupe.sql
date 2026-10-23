-- =============================================================
-- D9: training_records.status was only computed on write, so it
--     went stale; check_expiring_training re-sent every day for 60
--     days and check_hiring_compliance_alerts every day for 7.
-- Also adds the batch wrappers cron needs for functions that take
-- an id (create_scheduled_inspection, fire_escalation_step).
-- =============================================================

CREATE OR REPLACE FUNCTION public.notification_sent_since(p_trigger_event text, p_entity_id uuid, p_since timestamptz)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM notifications
    WHERE trigger_event = p_trigger_event
      AND trigger_entity_id = p_entity_id
      AND created_at >= p_since);
$$;

CREATE OR REPLACE FUNCTION public.refresh_training_record_statuses()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_count integer;
BEGIN
  UPDATE training_records tr
  SET status = s.computed
  FROM (
    SELECT id,
           CASE
             WHEN expiry_date IS NULL                        THEN 'current'
             WHEN expiry_date < CURRENT_DATE                 THEN 'expired'
             WHEN expiry_date <= CURRENT_DATE + INTERVAL '60 days' THEN 'expiring_soon'
             ELSE 'current'
           END AS computed
    FROM training_records
  ) s
  WHERE s.id = tr.id AND tr.status IS DISTINCT FROM s.computed;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- Notify at 60/30/14/7/1 days before expiry and on the day after expiry
CREATE OR REPLACE FUNCTION public.check_expiring_training()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rec RECORD;
BEGIN
  PERFORM refresh_training_record_statuses();

  FOR rec IN
    SELECT tr.id, tr.worker_id, tr.organisation_id, tr.expiry_date, tr.record_number,
           tc.name AS course_name,
           up.first_name || ' ' || up.last_name AS worker_name,
           (tr.expiry_date - CURRENT_DATE)::int AS days_remaining
    FROM training_records tr
    JOIN training_courses tc ON tc.id = tr.course_id
    JOIN user_profiles up    ON up.id = tr.worker_id
    WHERE tr.organisation_id IS NOT NULL
      AND tr.expiry_date IS NOT NULL
      AND (tr.expiry_date - CURRENT_DATE) IN (60, 30, 14, 7, 1, -1)
  LOOP
    CONTINUE WHEN notification_sent_since(
      CASE WHEN rec.days_remaining < 0 THEN 'training.overdue' ELSE 'training.expiring_soon' END,
      rec.id, CURRENT_DATE::timestamptz);

    PERFORM create_notification(
      CASE WHEN rec.days_remaining < 0 THEN 'training.overdue' ELSE 'training.expiring_soon' END,
      rec.organisation_id, NULL::uuid, 'training_record', rec.id,
      jsonb_build_object(
        'course_name',    rec.course_name,
        'worker_name',    rec.worker_name,
        'expiry_date',    rec.expiry_date::text,
        'record_number',  COALESCE(rec.record_number, rec.id::text),
        'days_remaining', rec.days_remaining::text,
        'reporter_id',    rec.worker_id));
  END LOOP;
END;
$$;

-- Same alerts as before, but once per hire per event
CREATE OR REPLACE FUNCTION public.check_hiring_compliance_alerts()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_hire    RECORD;
  v_today   date := CURRENT_DATE;
  v_horizon integer := 7;
BEGIN
  FOR v_hire IN
    SELECT h.id, h.organisation_id, h.site_id, h.hire_number,
           h.candidate_first_name || ' ' || h.candidate_last_name AS worker_name,
           h.position_title,
           (h.start_date + h.probation_period_days) AS review_date
    FROM hires h
    WHERE h.status = 'completed'
      AND h.probation_period_days IS NOT NULL
      AND h.start_date IS NOT NULL
      AND (h.start_date + h.probation_period_days) BETWEEN v_today AND (v_today + v_horizon)
  LOOP
    CONTINUE WHEN notification_sent_since('hiring.probation_review_due', v_hire.id, now() - INTERVAL '30 days');
    BEGIN
      PERFORM create_notification('hiring.probation_review_due'::text, v_hire.organisation_id, v_hire.site_id, 'hire'::text, v_hire.id,
        jsonb_build_object('worker_name', v_hire.worker_name, 'position_title', COALESCE(v_hire.position_title,''),
                           'review_date', v_hire.review_date::text, 'hire_number', COALESCE(v_hire.hire_number, v_hire.id::text)));
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'hiring.probation_review_due failed for hire %: %', v_hire.id, SQLERRM;
    END;
  END LOOP;

  FOR v_hire IN
    SELECT h.id, h.organisation_id, h.site_id, h.hire_number,
           h.candidate_first_name || ' ' || h.candidate_last_name AS worker_name,
           h.position_title, h.contract_end_date,
           (h.contract_end_date - v_today) AS days_remaining
    FROM hires h
    WHERE h.status = 'completed'
      AND h.is_fixed_term = true
      AND h.contract_end_date IS NOT NULL
      AND (h.contract_end_date - 60) BETWEEN v_today AND (v_today + v_horizon)
  LOOP
    CONTINUE WHEN notification_sent_since('hiring.contract_ending_soon', v_hire.id, now() - INTERVAL '30 days');
    BEGIN
      PERFORM create_notification('hiring.contract_ending_soon'::text, v_hire.organisation_id, v_hire.site_id, 'hire'::text, v_hire.id,
        jsonb_build_object('worker_name', v_hire.worker_name, 'position_title', COALESCE(v_hire.position_title,''),
                           'contract_end_date', v_hire.contract_end_date::text, 'days_remaining', v_hire.days_remaining::text,
                           'hire_number', COALESCE(v_hire.hire_number, v_hire.id::text)));
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'hiring.contract_ending_soon failed for hire %: %', v_hire.id, SQLERRM;
    END;
  END LOOP;
END;
$$;

-- Creates the next inspection for each active schedule that is due
-- (inside its advance-notice window) and has no open inspection
CREATE OR REPLACE FUNCTION public.create_due_scheduled_inspections()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id    uuid;
  v_count integer := 0;
BEGIN
  FOR v_id IN
    SELECT s.id
    FROM inspection_schedules s
    WHERE s.is_active
      AND s.next_due_at IS NOT NULL
      AND s.next_due_at <= now() + make_interval(days => COALESCE(s.advance_notice_days, 0))
      AND NOT EXISTS (
        SELECT 1 FROM inspections i
        WHERE i.schedule_id = s.id AND i.status IN ('scheduled', 'draft', 'in_progress'))
  LOOP
    PERFORM create_scheduled_inspection(v_id);
    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.process_due_escalations()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id    uuid;
  v_count integer := 0;
BEGIN
  FOR v_id IN
    SELECT id FROM active_escalations
    WHERE is_active AND next_escalation_at <= now()
  LOOP
    PERFORM fire_escalation_step(v_id);
    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.notification_sent_since(text, uuid, timestamptz) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.refresh_training_record_statuses()  FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.create_due_scheduled_inspections()  FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.process_due_escalations()           FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.refresh_training_record_statuses()  TO service_role;
GRANT  EXECUTE ON FUNCTION public.create_due_scheduled_inspections()  TO service_role;
GRANT  EXECUTE ON FUNCTION public.process_due_escalations()           TO service_role;

SELECT refresh_training_record_statuses();
