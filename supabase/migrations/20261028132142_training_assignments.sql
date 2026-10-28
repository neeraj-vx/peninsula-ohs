-- =============================================================
-- Step 3 — training reconciliation (gap analysis §7)
--
-- * training_assignment_rules: which course each role (optionally a
--   site or province) must complete, and how many business days a
--   new worker gets. Replaces the unused training_needs_matrix (its
--   rows are copied; the table is kept).
-- * training_assignments: one open assignment per worker+course,
--   generated from the rules, refreshed before certificates expire,
--   completed automatically when a training record is logged.
-- * training records derive expiry_date from the course validity.
-- * competency_types / worker_competencies: tickets and certificates
--   (recommendation (a) in §7), alongside BGC worker_licences.
-- * training_evidence: several files per training record.
-- * Toolbox talks can count as training.
-- * training.assigned / training.completed notifications, the
--   TRAINING_COMPLIANCE KPI and two cron jobs.
-- =============================================================

-- ── Courses ──────────────────────────────────────────────────────
ALTER TABLE training_courses
  ADD COLUMN IF NOT EXISTS training_type text NOT NULL DEFAULT 'course'
    CHECK (training_type IN ('course', 'induction', 'toolbox_talk', 'external_cert', 'refresher')),
  ADD COLUMN IF NOT EXISTS is_sample_content boolean NOT NULL DEFAULT false;

-- ── Rules ────────────────────────────────────────────────────────
CREATE TABLE training_assignment_rules (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organisation_id  uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  course_id        uuid NOT NULL REFERENCES training_courses(id) ON DELETE CASCADE,
  role_id          uuid REFERENCES roles(id) ON DELETE CASCADE,   -- NULL = everyone
  site_id          uuid REFERENCES sites(id) ON DELETE CASCADE,   -- NULL = every site
  province         text,                                          -- NULL = any province
  due_within_days  integer NOT NULL DEFAULT 30 CHECK (due_within_days BETWEEN 0 AND 365),
  is_active        boolean NOT NULL DEFAULT true,
  effective_from   date NOT NULL DEFAULT CURRENT_DATE,
  effective_to     date,
  notes            text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  created_by       uuid REFERENCES auth.users(id)
);

CREATE UNIQUE INDEX uq_training_rule_active ON training_assignment_rules (
  organisation_id, course_id,
  COALESCE(role_id, '00000000-0000-0000-0000-000000000000'::uuid),
  COALESCE(site_id, '00000000-0000-0000-0000-000000000000'::uuid),
  COALESCE(province, '')
) WHERE is_active;

INSERT INTO training_assignment_rules (organisation_id, course_id, role_id, due_within_days)
SELECT organisation_id, course_id, role_id, 30 FROM training_needs_matrix
ON CONFLICT DO NOTHING;

-- ── Assignments ──────────────────────────────────────────────────
CREATE TABLE training_assignments (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organisation_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  worker_id            uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  course_id            uuid NOT NULL REFERENCES training_courses(id) ON DELETE CASCADE,
  rule_id              uuid REFERENCES training_assignment_rules(id) ON DELETE SET NULL,
  source               text NOT NULL DEFAULT 'rule' CHECK (source IN ('rule', 'refresher', 'manual')),
  status               text NOT NULL DEFAULT 'assigned' CHECK (status IN ('assigned', 'completed', 'overdue', 'waived')),
  assigned_at          timestamptz NOT NULL DEFAULT now(),
  due_date             date NOT NULL,
  completed_at         timestamptz,
  completed_record_id  uuid REFERENCES training_records(id) ON DELETE SET NULL,
  waived_reason        text,
  waived_by            uuid REFERENCES auth.users(id),
  created_by           uuid REFERENCES auth.users(id),
  updated_at           timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX uq_training_assignment_open ON training_assignments (worker_id, course_id)
  WHERE status IN ('assigned', 'overdue');
CREATE INDEX idx_training_assignments_org_status ON training_assignments (organisation_id, status, due_date);
CREATE INDEX idx_training_assignments_worker ON training_assignments (worker_id, status);

ALTER TABLE training_records
  ADD COLUMN IF NOT EXISTS assignment_id uuid REFERENCES training_assignments(id) ON DELETE SET NULL;

-- ── Competencies ─────────────────────────────────────────────────
CREATE TABLE competency_types (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organisation_id         uuid REFERENCES organisations(id) ON DELETE CASCADE,  -- NULL = system type
  code                    text NOT NULL,
  name                    text NOT NULL,
  description             text,
  requires_expiry         boolean NOT NULL DEFAULT true,
  default_validity_months integer,
  is_sample_content       boolean NOT NULL DEFAULT false,
  is_active               boolean NOT NULL DEFAULT true,
  created_at              timestamptz NOT NULL DEFAULT now(),
  UNIQUE NULLS NOT DISTINCT (organisation_id, code)
);

CREATE TABLE worker_competencies (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organisation_id     uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  worker_id           uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  competency_type_id  uuid NOT NULL REFERENCES competency_types(id),
  credential_number   text,
  issuing_body        text,
  issuing_province    text,
  issued_date         date,
  expiry_date         date,
  evidence_url        text,
  evidence_file_name  text,
  notes               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES auth.users(id)
);
CREATE INDEX idx_worker_competencies_worker ON worker_competencies (worker_id);
CREATE INDEX idx_worker_competencies_org_expiry ON worker_competencies (organisation_id, expiry_date);

-- One list of everything a worker holds: competencies + BGC licences
CREATE VIEW worker_competency_status WITH (security_invoker = true) AS
SELECT wc.id, wc.organisation_id, wc.worker_id, 'competency'::text AS source,
       ct.name, wc.credential_number, wc.issuing_body, wc.issued_date, wc.expiry_date,
       CASE WHEN wc.expiry_date IS NULL THEN 'current'
            WHEN wc.expiry_date < CURRENT_DATE THEN 'expired'
            WHEN wc.expiry_date <= CURRENT_DATE + 60 THEN 'expiring_soon'
            ELSE 'current' END AS status
FROM worker_competencies wc
JOIN competency_types ct ON ct.id = wc.competency_type_id
UNION ALL
SELECT wl.id, wl.organisation_id, wl.worker_id, 'licence'::text,
       wl.licence_type, wl.licence_number, wl.issuing_body, wl.issue_date, wl.expiry_date,
       CASE WHEN wl.expiry_date IS NULL THEN 'current'
            WHEN wl.expiry_date < CURRENT_DATE THEN 'expired'
            WHEN wl.expiry_date <= CURRENT_DATE + 60 THEN 'expiring_soon'
            ELSE 'current' END
FROM worker_licences wl;

-- ── Evidence ─────────────────────────────────────────────────────
CREATE TABLE training_evidence (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organisation_id     uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  training_record_id  uuid NOT NULL REFERENCES training_records(id) ON DELETE CASCADE,
  file_url            text NOT NULL,
  file_name           text,
  uploaded_by         uuid REFERENCES auth.users(id),
  created_at          timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_training_evidence_record ON training_evidence (training_record_id);

-- ── Toolbox talks can count as training ──────────────────────────
ALTER TABLE toolbox_talk_templates
  ADD COLUMN IF NOT EXISTS training_course_id uuid REFERENCES training_courses(id) ON DELETE SET NULL;

-- ── RLS ──────────────────────────────────────────────────────────
ALTER TABLE training_assignment_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_assignments      ENABLE ROW LEVEL SECURITY;
ALTER TABLE competency_types          ENABLE ROW LEVEL SECURITY;
ALTER TABLE worker_competencies       ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_evidence         ENABLE ROW LEVEL SECURITY;

CREATE POLICY tar_select ON training_assignment_rules FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id());
CREATE POLICY tar_write ON training_assignment_rules FOR ALL TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager())
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_safety_manager());

CREATE POLICY ta_select ON training_assignments FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id()
         AND (worker_id = auth.uid() OR is_supervisor_or_above() OR is_executive()));
CREATE POLICY ta_write ON training_assignments FOR ALL TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager())
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_safety_manager());

CREATE POLICY ct_select ON competency_types FOR SELECT TO authenticated
  USING (organisation_id IS NULL OR organisation_id = get_my_organisation_id());
CREATE POLICY ct_write ON competency_types FOR ALL TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager())
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_safety_manager());

CREATE POLICY wc_select ON worker_competencies FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id()
         AND (worker_id = auth.uid() OR is_supervisor_or_above() OR is_executive()));
CREATE POLICY wc_insert ON worker_competencies FOR INSERT TO authenticated
  WITH CHECK (organisation_id = get_my_organisation_id() AND (worker_id = auth.uid() OR is_supervisor_or_above()));
CREATE POLICY wc_update ON worker_competencies FOR UPDATE TO authenticated
  USING (organisation_id = get_my_organisation_id() AND (worker_id = auth.uid() OR is_supervisor_or_above()))
  WITH CHECK (organisation_id = get_my_organisation_id());
CREATE POLICY wc_manage ON worker_competencies FOR ALL TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager())
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_safety_manager());

CREATE POLICY tev_select ON training_evidence FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id() AND EXISTS (
    SELECT 1 FROM training_records tr WHERE tr.id = training_record_id
      AND (tr.worker_id = auth.uid() OR is_supervisor_or_above() OR is_executive())));
CREATE POLICY tev_insert ON training_evidence FOR INSERT TO authenticated
  WITH CHECK (organisation_id = get_my_organisation_id() AND EXISTS (
    SELECT 1 FROM training_records tr WHERE tr.id = training_record_id
      AND (tr.worker_id = auth.uid() OR is_supervisor_or_above())));
CREATE POLICY tev_manage ON training_evidence FOR ALL TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager())
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_safety_manager());

-- ── Record triggers: expiry from validity, link + complete assignment ──
-- Named trg_a_* so they run before trg_training_record_status
CREATE OR REPLACE FUNCTION public.set_training_record_defaults()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.expiry_date IS NULL AND NEW.completed_date IS NOT NULL THEN
    SELECT (NEW.completed_date + make_interval(months => tc.validity_period_months))::date
    INTO NEW.expiry_date
    FROM training_courses tc
    WHERE tc.id = NEW.course_id AND tc.validity_period_months IS NOT NULL;
  END IF;

  IF NEW.assignment_id IS NULL THEN
    SELECT ta.id INTO NEW.assignment_id
    FROM training_assignments ta
    WHERE ta.worker_id = NEW.worker_id AND ta.course_id = NEW.course_id
      AND ta.status IN ('assigned', 'overdue');
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_a_training_record_defaults
  BEFORE INSERT ON training_records
  FOR EACH ROW EXECUTE FUNCTION set_training_record_defaults();

CREATE OR REPLACE FUNCTION public.complete_training_assignment()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_course text;
BEGIN
  IF NEW.assignment_id IS NOT NULL THEN
    UPDATE training_assignments
    SET status = 'completed', completed_at = now(), completed_record_id = NEW.id, updated_at = now()
    WHERE id = NEW.assignment_id AND status IN ('assigned', 'overdue');

    IF FOUND THEN
      SELECT name INTO v_course FROM training_courses WHERE id = NEW.course_id;
      PERFORM create_notification('training.completed', NEW.organisation_id, NULL, 'training_record', NEW.id,
        jsonb_build_object('course_name', v_course,
                           'worker_name', (SELECT first_name || ' ' || last_name FROM user_profiles WHERE id = NEW.worker_id),
                           'completed_date', NEW.completed_date::text));
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_complete_training_assignment
  AFTER INSERT ON training_records
  FOR EACH ROW EXECUTE FUNCTION complete_training_assignment();

-- ── Generation ───────────────────────────────────────────────────
-- For every active rule and every matching active worker without an
-- open assignment:
--   no record                    -> assign, due in N business days
--   record never expires         -> nothing
--   expires more than 60 days on -> nothing
--   expires within 60 days       -> refresher, due on the expiry date
--   already expired              -> refresher, due in N business days
-- Unchecked: called by cron, triggers and the checked wrapper below
CREATE OR REPLACE FUNCTION public.generate_training_assignments_internal(p_organisation_id uuid DEFAULT NULL)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  r        record;
  v_due    date;
  v_source text;
  v_id     uuid;
  v_count  integer := 0;
BEGIN
  FOR r IN
    SELECT DISTINCT ON (up.id, ru.course_id)
           ru.id AS rule_id, ru.organisation_id, ru.course_id, ru.due_within_days,
           up.id AS worker_id, o.province, tc.name AS course_name,
           latest.expiry_date, latest.id AS latest_record_id
    FROM training_assignment_rules ru
    JOIN organisations o     ON o.id = ru.organisation_id
    JOIN training_courses tc ON tc.id = ru.course_id AND tc.is_active
    JOIN user_profiles up    ON up.organisation_id = ru.organisation_id AND up.is_active
    LEFT JOIN LATERAL (
      SELECT tr.id, tr.expiry_date
      FROM training_records tr
      WHERE tr.worker_id = up.id AND tr.course_id = ru.course_id
      ORDER BY tr.completed_date DESC NULLS LAST, tr.created_at DESC
      LIMIT 1
    ) latest ON true
    WHERE ru.is_active
      AND ru.effective_from <= CURRENT_DATE
      AND (ru.effective_to IS NULL OR ru.effective_to >= CURRENT_DATE)
      AND (p_organisation_id IS NULL OR ru.organisation_id = p_organisation_id)
      AND (ru.role_id IS NULL OR EXISTS (
            SELECT 1 FROM user_roles ur
            WHERE ur.user_id = up.id AND ur.role_id = ru.role_id AND ur.organisation_id = ru.organisation_id
              AND ur.is_active AND (ur.expires_at IS NULL OR ur.expires_at > now())))
      AND (ru.site_id IS NULL OR EXISTS (
            SELECT 1 FROM user_site_assignments usa WHERE usa.user_id = up.id AND usa.site_id = ru.site_id))
      AND (ru.province IS NULL OR o.province = ru.province)
      AND NOT EXISTS (
            SELECT 1 FROM training_assignments ta
            WHERE ta.worker_id = up.id AND ta.course_id = ru.course_id AND ta.status IN ('assigned', 'overdue'))
    ORDER BY up.id, ru.course_id, ru.due_within_days ASC
  LOOP
    IF r.latest_record_id IS NULL THEN
      v_source := 'rule';
      v_due := add_business_days(CURRENT_DATE, r.due_within_days, 'CA-' || COALESCE(r.province, ''));
    ELSIF r.expiry_date IS NULL OR r.expiry_date > CURRENT_DATE + 60 THEN
      CONTINUE;
    ELSE
      v_source := 'refresher';
      v_due := CASE WHEN r.expiry_date >= CURRENT_DATE THEN r.expiry_date
                    ELSE add_business_days(CURRENT_DATE, r.due_within_days, 'CA-' || COALESCE(r.province, '')) END;
    END IF;

    v_id := NULL;
    INSERT INTO training_assignments (organisation_id, worker_id, course_id, rule_id, source, due_date)
    VALUES (r.organisation_id, r.worker_id, r.course_id, r.rule_id, v_source, v_due)
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_id;

    IF v_id IS NOT NULL THEN
      v_count := v_count + 1;
      PERFORM create_notification('training.assigned', r.organisation_id, NULL, 'training_assignment', v_id,
        jsonb_build_object('training_name', r.course_name, 'course_name', r.course_name,
                           'due_date', v_due::text, 'reporter_id', r.worker_id));
    END IF;
  END LOOP;
  RETURN v_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_overdue_training_assignments()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  r       record;
  v_count integer := 0;
BEGIN
  FOR r IN
    UPDATE training_assignments ta
    SET status = 'overdue', updated_at = now()
    WHERE ta.status = 'assigned' AND ta.due_date < CURRENT_DATE
    RETURNING ta.id, ta.organisation_id, ta.worker_id, ta.course_id, ta.due_date
  LOOP
    v_count := v_count + 1;
    PERFORM create_notification('training.overdue', r.organisation_id, NULL, 'training_assignment', r.id,
      jsonb_build_object('training_name', (SELECT name FROM training_courses WHERE id = r.course_id),
                         'due_date', r.due_date::text, 'assigner_name', 'Your organisation',
                         'reporter_id', r.worker_id));
  END LOOP;
  RETURN v_count;
END;
$$;

-- Generate as soon as a rule is added or a role is granted
CREATE OR REPLACE FUNCTION public.generate_training_assignments_for_org()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM generate_training_assignments_internal(NEW.organisation_id);
  RETURN NEW;
END;
$$;

-- Checked entry point for the app: own organisation, safety managers only
CREATE OR REPLACE FUNCTION public.generate_training_assignments(p_organisation_id uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL AND (p_organisation_id IS DISTINCT FROM get_my_organisation_id() OR NOT is_safety_manager()) THEN
    RAISE EXCEPTION 'insufficient_privilege' USING ERRCODE = '42501';
  END IF;
  RETURN generate_training_assignments_internal(p_organisation_id);
END;
$$;

CREATE TRIGGER trg_generate_training_on_rule
  AFTER INSERT OR UPDATE OF is_active, role_id, site_id, province, effective_from, effective_to ON training_assignment_rules
  FOR EACH ROW WHEN (NEW.is_active) EXECUTE FUNCTION generate_training_assignments_for_org();

CREATE TRIGGER trg_generate_training_on_role
  AFTER INSERT ON user_roles
  FOR EACH ROW EXECUTE FUNCTION generate_training_assignments_for_org();

-- ── Toolbox talk attendance counts as training ───────────────────
CREATE OR REPLACE FUNCTION public.record_toolbox_training()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE d record;
BEGIN
  IF NEW.worker_id IS NULL OR NEW.acknowledged_at IS NULL THEN RETURN NEW; END IF;
  IF TG_OP = 'UPDATE' AND OLD.acknowledged_at IS NOT NULL THEN RETURN NEW; END IF;

  SELECT tdel.organisation_id, tdel.delivery_number, tdel.delivered_at, tt.training_course_id
  INTO d
  FROM toolbox_talk_deliveries tdel
  JOIN toolbox_talk_templates tt ON tt.id = tdel.template_id
  WHERE tdel.id = NEW.delivery_id;

  IF d.training_course_id IS NULL THEN RETURN NEW; END IF;

  INSERT INTO training_records (organisation_id, worker_id, course_id, completed_date, delivery_method, notes)
  SELECT d.organisation_id, NEW.worker_id, d.training_course_id, COALESCE(d.delivered_at, now())::date,
         'toolbox_talk', 'Toolbox talk ' || COALESCE(d.delivery_number, '')
  WHERE NOT EXISTS (
    SELECT 1 FROM training_records tr
    WHERE tr.worker_id = NEW.worker_id AND tr.course_id = d.training_course_id
      AND tr.completed_date = COALESCE(d.delivered_at, now())::date);
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_record_toolbox_training
  AFTER INSERT OR UPDATE OF acknowledged_at ON toolbox_talk_attendees
  FOR EACH ROW EXECUTE FUNCTION record_toolbox_training();

-- ── Notifications ────────────────────────────────────────────────
INSERT INTO notification_templates (organisation_id, trigger_event, name, subject_template, body_template, available_vars, is_active)
SELECT NULL, v.ev, v.name, v.subj, v.body, v.vars::jsonb, true
FROM (VALUES
  ('training.assigned', 'Training Assigned',
   'New training: {{training_name}}',
   E'You have been assigned {{training_name}}.\n\nPlease complete it by {{due_date}}.',
   '["training_name","due_date"]'),
  ('training.completed', 'Training Completed',
   '{{worker_name}} completed {{course_name}}',
   E'{{worker_name}} completed {{course_name}} on {{completed_date}}.',
   '["worker_name","course_name","completed_date"]')
) AS v(ev, name, subj, body, vars)
WHERE NOT EXISTS (SELECT 1 FROM notification_templates t WHERE t.organisation_id IS NULL AND t.trigger_event = v.ev);

-- Existing organisations pick up rules for the new events
SELECT seed_default_notification_rules(id) FROM organisations;

-- training.overdue's template expects training_name / due_date / assigner_name
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
        'training_name',  rec.course_name,
        'worker_name',    rec.worker_name,
        'expiry_date',    rec.expiry_date::text,
        'due_date',       rec.expiry_date::text,
        'assigner_name',  'Your organisation',
        'record_number',  COALESCE(rec.record_number, rec.id::text),
        'days_remaining', rec.days_remaining::text,
        'reporter_id',    rec.worker_id));
  END LOOP;
END;
$$;

-- ── Sample Canadian content (flagged for legal review) ───────────
INSERT INTO training_courses (organisation_id, code, name, description, course_type, training_type, validity_period_months,
                              is_certification, is_active, is_sample_content, applicable_provinces)
SELECT NULL, v.code, v.name, 'SAMPLE CONTENT — legal review required. ' || v.description, v.course_type, v.training_type,
       v.validity, v.is_cert, true, true, v.provinces::text[]
FROM (VALUES
  ('ON-WHSA', 'Worker Health and Safety Awareness', 'Mandatory awareness training for every Ontario worker (O. Reg. 297/13).', 'e_learning', 'course', NULL::int, false, '{ON}'),
  ('ON-SHSA', 'Supervisor Health and Safety Awareness', 'Mandatory awareness training for Ontario supervisors (O. Reg. 297/13).', 'e_learning', 'course', NULL::int, false, '{ON}'),
  ('ON-WAH',  'Working at Heights (CPO-approved)', 'Ontario Chief Prevention Officer-approved program for workers on construction projects who use fall protection; refresher every 3 years.', 'classroom', 'external_cert', 36, true, '{ON}'),
  ('SFA-CPR-C', 'Standard First Aid and CPR Level C', 'Workplace first aid and CPR/AED certification from a recognised provider.', 'classroom', 'external_cert', 36, true, '{}'),
  ('LIFT-TRUCK', 'Lift Truck Operator', 'Lift truck operator training and evaluation (CSA B335).', 'blended', 'external_cert', 36, true, '{}'),
  ('JHSC-1', 'JHSC Certification Part One', 'Joint Health and Safety Committee certification, Part One (Ontario workplaces with 20+ workers).', 'classroom', 'external_cert', NULL::int, true, '{ON}')
) AS v(code, name, description, course_type, training_type, validity, is_cert, provinces)
WHERE NOT EXISTS (SELECT 1 FROM training_courses tc WHERE tc.organisation_id IS NULL AND tc.code = v.code);

INSERT INTO competency_types (organisation_id, code, name, description, requires_expiry, default_validity_months, is_sample_content)
SELECT NULL, v.code, v.name, v.description, v.requires_expiry, v.validity, true
FROM (VALUES
  ('first_aid_cpr',       'First Aid and CPR',                  'Typical validity; confirm with the issuing provider.', true, 36),
  ('working_at_heights',  'Working at Heights',                 'Ontario CPO-approved training; refresher every 3 years.', true, 36),
  ('fall_protection',     'Fall Protection',                    'Typical validity; confirm with the issuing provider.', true, 36),
  ('confined_space',      'Confined Space Entry',               'Typical validity; confirm with the issuing provider.', true, 36),
  ('lift_truck',          'Lift Truck Operator',                'CSA B335; re-evaluation at least every 3 years.', true, 36),
  ('aerial_work_platform','Aerial Work Platform Operator',      'CSA B354; typical validity 3 years.', true, 36),
  ('traffic_control',     'Traffic Control Person',             'Typical validity; confirm with the issuing provider.', true, 36),
  ('jhsc_certified',      'JHSC Certified Member',              'Ontario JHSC certification (Parts One and Two).', false, NULL)
) AS v(code, name, description, requires_expiry, validity)
ON CONFLICT DO NOTHING;

-- ── KPI: training compliance, plus an extension hook so new KPIs
--    don't require restating compute_kpi_snapshot ───────────────────
CREATE OR REPLACE FUNCTION public.compute_kpi_value_extra(p_formula_key text, p_org_id uuid, p_site_id uuid, p_period_start date, p_period_end date,
                                                          OUT value numeric, OUT numerator numeric, OUT denominator numeric)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  CASE p_formula_key
    -- % of training assignments due by the period end that were completed on time
    WHEN 'training_compliance' THEN
      SELECT COUNT(*) FILTER (WHERE ta.status = 'completed' AND ta.completed_at::date <= ta.due_date),
             COUNT(*)
      INTO numerator, denominator
      FROM training_assignments ta
      WHERE ta.organisation_id = p_org_id
        AND ta.status <> 'waived'
        AND ta.due_date BETWEEN p_period_start AND LEAST(p_period_end, CURRENT_DATE);
      IF denominator > 0 THEN value := ROUND((numerator / denominator) * 100.0, 2); END IF;
    ELSE
      NULL;
  END CASE;
END;
$$;

DO $$
DECLARE v_def text;
BEGIN
  v_def := pg_get_functiondef('public.compute_kpi_snapshot(text, uuid, uuid, text, date, date)'::regprocedure);
  IF position(E'    ELSE\n      v_value := NULL;\n  END CASE;' IN v_def) = 0 THEN
    RAISE EXCEPTION 'compute_kpi_snapshot ELSE branch not found';
  END IF;
  v_def := replace(v_def, E'    ELSE\n      v_value := NULL;\n  END CASE;',
    E'    ELSE\n      SELECT x.value, x.numerator, x.denominator INTO v_value, v_numer, v_denom\n      FROM compute_kpi_value_extra(p_formula_key, p_org_id, p_site_id, p_period_start, p_period_end) x;\n  END CASE;');
  EXECUTE v_def;
END $$;

INSERT INTO kpi_definitions (code, name, short_name, description, formula_description, formula_key, unit,
                             decimal_places, indicator_type, benchmark_direction, is_frequency_rate, is_active, display_order)
SELECT 'TRAINING_COMPLIANCE', 'Training Compliance', 'Training', 'Share of required training completed by its due date.',
       '(Assignments completed on time ÷ Assignments due) × 100', 'training_compliance', '%',
       1, 'leading', 'higher_is_better', false, true, 9
WHERE NOT EXISTS (SELECT 1 FROM kpi_definitions WHERE formula_key = 'training_compliance');

-- ── Privileges and schedules ─────────────────────────────────────
REVOKE EXECUTE ON FUNCTION public.generate_training_assignments(uuid)          FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.generate_training_assignments(uuid)          TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.generate_training_assignments_internal(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.mark_overdue_training_assignments()          FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.compute_kpi_value_extra(text, uuid, uuid, date, date) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.set_training_record_defaults()               FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.complete_training_assignment()               FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.generate_training_assignments_for_org()      FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.record_toolbox_training()                    FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.generate_training_assignments_internal(uuid) TO service_role;
GRANT  EXECUTE ON FUNCTION public.mark_overdue_training_assignments()          TO service_role;
GRANT  EXECUTE ON FUNCTION public.compute_kpi_value_extra(text, uuid, uuid, date, date) TO service_role;

SELECT cron.schedule('generate-training-assignments', '0 6 * * *',  'SELECT generate_training_assignments_internal(NULL)');
SELECT cron.schedule('mark-overdue-training',         '12 0 * * *', 'SELECT mark_overdue_training_assignments()');

-- Audit trail (D15) for the new tables
CREATE TRIGGER audit_training_assignment_rules AFTER INSERT OR UPDATE ON training_assignment_rules FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
CREATE TRIGGER audit_training_assignments      AFTER INSERT OR UPDATE ON training_assignments      FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
CREATE TRIGGER audit_worker_competencies       AFTER INSERT OR UPDATE ON worker_competencies       FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
