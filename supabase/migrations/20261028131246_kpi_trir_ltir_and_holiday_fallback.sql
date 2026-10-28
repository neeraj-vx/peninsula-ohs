-- =============================================================
-- C10: Canadian (and North American) practice reports injury rates
-- per 200,000 hours worked (100 full-time workers for a year).
-- Adds TRIR and LTIR as the primary rates; TRIFR / LTIFR (per
-- 1,000,000 h) stay defined but inactive so history is kept.
-- D11 follow-up: business-day functions fall back to federal ('CA')
-- holidays for a jurisdiction that has no seeded rows yet.
-- =============================================================

INSERT INTO kpi_definitions (code, name, short_name, description, formula_description, formula_key, unit,
                             decimal_places, indicator_type, benchmark_direction, is_frequency_rate, is_active, display_order)
SELECT * FROM (VALUES
  ('TRIR', 'Total Recordable Incident Rate', 'TRIR',
   'Recordable injuries (medical treatment, hospital admission, lost time or fatality) per 100 full-time workers per year.',
   '(Recordable injuries × 200,000) ÷ Total hours worked', 'trir', 'per 200k hrs',
   2, 'lagging', 'lower_is_better', true, true, 1),
  ('LTIR', 'Lost Time Injury Rate', 'LTIR',
   'Injuries causing at least one day of lost time per 100 full-time workers per year.',
   '(Lost time injuries × 200,000) ÷ Total hours worked', 'ltir', 'per 200k hrs',
   2, 'lagging', 'lower_is_better', true, true, 2)
) AS v(code, name, short_name, description, formula_description, formula_key, unit,
       decimal_places, indicator_type, benchmark_direction, is_frequency_rate, is_active, display_order)
WHERE NOT EXISTS (SELECT 1 FROM kpi_definitions k WHERE k.formula_key = v.formula_key);

UPDATE kpi_definitions SET is_active = false, display_order = 90 + display_order
WHERE formula_key IN ('trifr', 'ltifr') AND is_active;

CREATE OR REPLACE FUNCTION public.compute_kpi_snapshot(p_formula_key text, p_org_id uuid, p_site_id uuid, p_period_type text, p_period_start date, p_period_end date)
 RETURNS numeric
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_kpi_id     uuid;
  v_value      decimal(18,4) := NULL;
  v_numer      decimal(18,4) := NULL;
  v_denom      decimal(18,4) := NULL;
  v_hours      decimal(18,4);
  -- Injury rates: per 200,000 h (TRIR/LTIR) or per 1,000,000 h (TRIFR/LTIFR)
  v_base       decimal(18,4) := CASE WHEN p_formula_key IN ('trir', 'ltir') THEN 200000 ELSE 1000000 END;
BEGIN
  SELECT id INTO v_kpi_id FROM kpi_definitions WHERE formula_key = p_formula_key;
  IF NOT FOUND THEN RETURN NULL; END IF;

  -- Helper: sum hours worked for the scope and period
  SELECT COALESCE(SUM(whl.hours_worked), 0)
  INTO v_hours
  FROM workforce_hours_logs whl
  WHERE whl.organisation_id = p_org_id
    AND (p_site_id IS NULL OR whl.site_id = p_site_id)
    AND whl.period_start >= p_period_start
    AND whl.period_end   <= p_period_end;

  CASE p_formula_key

    -- Recordable injury rate — (Recordable incidents × base) / Hours worked
    WHEN 'trifr', 'trir' THEN
      SELECT COUNT(DISTINCT i.id)
      INTO v_numer
      FROM incidents i
      JOIN incident_medical im ON im.incident_id = i.id
      WHERE i.organisation_id = p_org_id
        AND (p_site_id IS NULL OR i.site_id = p_site_id)
        AND i.incident_date BETWEEN p_period_start AND p_period_end
        AND (im.treatment_provided IN ('medical_treatment','hospitalisation','fatality')
             OR im.hospital_admission
             OR COALESCE(im.lost_time_days, 0) > 0);

      v_denom := NULLIF(v_hours, 0);
      IF v_denom IS NOT NULL THEN
        v_value := ROUND((v_numer * v_base) / v_denom, 4);
      END IF;

    -- Lost time injury rate — (Lost time incidents × base) / Hours worked
    WHEN 'ltifr', 'ltir' THEN
      SELECT COUNT(DISTINCT i.id)
      INTO v_numer
      FROM incidents i
      JOIN incident_medical im ON im.incident_id = i.id
      WHERE i.organisation_id = p_org_id
        AND (p_site_id IS NULL OR i.site_id = p_site_id)
        AND i.incident_date BETWEEN p_period_start AND p_period_end
        AND im.lost_time_days > 0;

      v_denom := NULLIF(v_hours, 0);
      IF v_denom IS NOT NULL THEN
        v_value := ROUND((v_numer * v_base) / v_denom, 4);
      END IF;

    -- Severity Rate — days lost per million hours worked
    WHEN 'severity_rate' THEN
      SELECT COALESCE(SUM(im.lost_time_days), 0)
      INTO v_numer
      FROM incidents i
      JOIN incident_medical im ON im.incident_id = i.id
      WHERE i.organisation_id = p_org_id
        AND (p_site_id IS NULL OR i.site_id = p_site_id)
        AND i.incident_date BETWEEN p_period_start AND p_period_end
        AND im.lost_time_days IS NOT NULL;

      v_denom := NULLIF(v_hours, 0);
      IF v_denom IS NOT NULL THEN
        v_value := ROUND((v_numer * 1000000.0) / v_denom, 4);
      END IF;

    -- Near Miss Rate
    WHEN 'near_miss_rate' THEN
      SELECT COUNT(i.id)
      INTO v_numer
      FROM incidents i
      JOIN incident_types it ON it.id = i.incident_type_id
      WHERE i.organisation_id = p_org_id
        AND (p_site_id IS NULL OR i.site_id = p_site_id)
        AND i.incident_date BETWEEN p_period_start AND p_period_end
        AND it.code = 'near_miss';

      v_denom := NULLIF(v_hours, 0);
      IF v_denom IS NOT NULL THEN
        v_value := ROUND((v_numer * 1000000.0) / v_denom, 4);
      END IF;

    -- Inspection Completion Rate — % of scheduled inspections submitted
    -- within the schedule's overdue_after_hours of being created
    WHEN 'inspection_completion_rate' THEN
      SELECT
        COUNT(*) FILTER (WHERE i.status IN ('submitted', 'completed')
                           AND i.submitted_at <= i.created_at + make_interval(hours => COALESCE(is2.overdue_after_hours, 24))),
        COUNT(*)
      INTO v_numer, v_denom
      FROM inspection_schedules is2
      JOIN inspections i ON i.schedule_id = is2.id
      WHERE is2.organisation_id = p_org_id
        AND (p_site_id IS NULL OR is2.site_id = p_site_id)
        AND i.created_at::date BETWEEN p_period_start AND p_period_end;

      IF COALESCE(v_denom, 0) > 0 THEN
        v_value := ROUND((v_numer / v_denom) * 100.0, 2);
      END IF;

    -- Action Closure Rate — % of actions closed by their due date
    WHEN 'action_closure_rate' THEN
      SELECT
        COUNT(*) FILTER (
          WHERE a.status IN ('verified','closed')
            AND COALESCE(a.verified_at, a.completed_at)::date
                  <= COALESCE(a.extended_due_date, a.due_date)
        ),
        COUNT(*)
      INTO v_numer, v_denom
      FROM actions a
      WHERE a.organisation_id = p_org_id
        AND (p_site_id IS NULL OR a.site_id = p_site_id)
        AND a.due_date BETWEEN p_period_start AND p_period_end;

      IF COALESCE(v_denom, 0) > 0 THEN
        v_value := ROUND((v_numer / v_denom) * 100.0, 2);
      END IF;

    -- Audit Score — average conformance % across completed audits
    WHEN 'audit_score' THEN
      SELECT
        ROUND(AVG(
          CASE WHEN a.total_criteria > 0
               THEN (a.conformance_count::decimal / a.total_criteria) * 100
          END
        ), 2),
        COUNT(*)
      INTO v_value, v_numer
      FROM audits a
      WHERE a.organisation_id = p_org_id
        AND (p_site_id IS NULL OR p_site_id = ANY(a.site_ids))
        AND a.status = 'completed'
        AND a.actual_end_date BETWEEN p_period_start AND p_period_end;

      v_denom := v_numer;

    -- Hazard Report Rate — (Hazard reports × 1,000,000) / Hours worked
    WHEN 'hazard_report_rate' THEN
      SELECT COUNT(hr.id)
      INTO v_numer
      FROM hazard_reports hr
      WHERE hr.organisation_id = p_org_id
        AND (p_site_id IS NULL OR hr.site_id = p_site_id)
        AND hr.created_at::date BETWEEN p_period_start AND p_period_end;

      v_denom := NULLIF(v_hours, 0);
      IF v_denom IS NOT NULL THEN
        v_value := ROUND((v_numer * 1000000.0) / v_denom, 4);
      END IF;

    ELSE
      v_value := NULL;
  END CASE;

  -- Mark previous snapshots for this scope as not current
  UPDATE kpi_snapshots
  SET is_current = false
  WHERE kpi_definition_id = v_kpi_id
    AND organisation_id   = p_org_id
    AND (site_id          = p_site_id OR (site_id IS NULL AND p_site_id IS NULL))
    AND period_type       = p_period_type
    AND period_start      = p_period_start;

  -- Upsert the new snapshot
  INSERT INTO kpi_snapshots (
    kpi_definition_id, organisation_id, site_id, period_type,
    period_start, period_end, value, numerator, denominator,
    is_current, computed_at
  ) VALUES (
    v_kpi_id, p_org_id, p_site_id, p_period_type,
    p_period_start, p_period_end, v_value, v_numer, v_denom,
    true, now()
  )
  ON CONFLICT (kpi_definition_id, organisation_id, site_id, period_type, period_start)
  DO UPDATE
    SET value       = EXCLUDED.value,
        numerator   = EXCLUDED.numerator,
        denominator = EXCLUDED.denominator,
        is_current  = true,
        computed_at = now();

  RETURN v_value;
END;
$function$;

-- Holiday calendars: use the jurisdiction's own rows when seeded, else federal
CREATE OR REPLACE FUNCTION public.holiday_jurisdiction(p_jurisdiction text)
RETURNS text
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT CASE WHEN EXISTS (SELECT 1 FROM statutory_holidays WHERE jurisdiction = p_jurisdiction)
              THEN p_jurisdiction ELSE 'CA' END;
$$;

CREATE OR REPLACE FUNCTION public.is_business_day(p_date date, p_jurisdiction text DEFAULT 'CA')
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT EXTRACT(ISODOW FROM p_date) < 6
     AND NOT EXISTS (
       SELECT 1 FROM statutory_holidays
       WHERE jurisdiction = holiday_jurisdiction(p_jurisdiction) AND holiday_date = p_date);
$$;

REVOKE EXECUTE ON FUNCTION public.holiday_jurisdiction(text) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.holiday_jurisdiction(text) TO authenticated, service_role;
