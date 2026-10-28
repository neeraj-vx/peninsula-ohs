-- =============================================================
-- Rules engine — increment R1 (docs/rules-engine-design.md)
--
-- Decisions (2026-10-28): system rules are published by Peninsula with
-- two-person approval; Ontario first; customers may mark a rule "not
-- applicable" with a reason but cannot switch it off; no French at
-- launch (single-language labels).
--
-- * rule_types / rules / rule_versions / rule_applicability /
--   rule_org_settings / rule_findings.
-- * Exactly one PUBLISHED version of a rule is in force on any date
--   (exclusion constraint) — the general fix for D32.
-- * Publishing needs a reviewer different from the drafter.
-- * The 36 employment_jurisdiction_rules rows are migrated; that table
--   stays in place, unused, for one release.
-- * evaluate_hire_rules(hire) replaces the TypeScript checks in
--   runComplianceCheck, using the rules in force on the hire's start
--   date (today if none).
-- =============================================================

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA extensions;

CREATE TABLE public.rule_types (
  code             text PRIMARY KEY,
  name             text NOT NULL,
  description      text,
  parameter_schema jsonb NOT NULL DEFAULT '{}'
);

INSERT INTO public.rule_types (code, name, description, parameter_schema) VALUES
  ('min_threshold',     'Minimum value',       'A field must be at least a value (e.g. minimum wage).', '{"field": "text", "min": "number", "unit": "text", "applies_when": "object"}'),
  ('max_duration',      'Duration limit',      'Warn when a duration runs past a limit (e.g. the no-notice period).', '{"field": "text", "max_days": "number"}'),
  ('required_field',    'Required field',      'A field must be filled in when a condition holds.', '{"field": "text", "when": "text"}'),
  ('required_document', 'Required document',   'A document or training must be provided.', '{}'),
  ('information',       'Information',         'Shown to the user; never fails.', '{"value": "text"}'),
  ('reference',         'Reference value',     'Stored for reference; not evaluated yet.', '{}');

CREATE TABLE public.rules (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code             text NOT NULL UNIQUE,
  name             text NOT NULL,
  category         text NOT NULL CHECK (category IN ('employment_standards', 'ohs', 'training', 'privacy')),
  rule_type        text NOT NULL REFERENCES public.rule_types(code),
  subject_type     text NOT NULL CHECK (subject_type IN ('hire', 'organisation', 'site', 'worker', 'incident')),
  result_key       text NOT NULL,           -- key shown in results (kept from the old checks)
  organisation_id  uuid REFERENCES public.organisations(id) ON DELETE CASCADE,  -- NULL = system rule
  is_active        boolean NOT NULL DEFAULT true,
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.rule_versions (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_id          uuid NOT NULL REFERENCES public.rules(id) ON DELETE CASCADE,
  version          integer NOT NULL,
  label            text NOT NULL,
  parameters       jsonb NOT NULL DEFAULT '{}',
  effective_from   date NOT NULL,
  effective_to     date,
  source_citation  text,
  source_url       text,
  review_status    text NOT NULL DEFAULT 'draft' CHECK (review_status IN ('draft', 'in_review', 'published', 'retired')),
  drafted_by       uuid REFERENCES auth.users(id),
  reviewed_by      uuid REFERENCES auth.users(id),
  reviewed_at      timestamptz,
  change_note      text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (rule_id, version),
  CHECK (effective_to IS NULL OR effective_to >= effective_from),
  EXCLUDE USING gist (rule_id WITH =, daterange(effective_from, effective_to, '[]') WITH &&)
    WHERE (review_status = 'published')
);

CREATE TABLE public.rule_applicability (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_version_id  uuid NOT NULL REFERENCES public.rule_versions(id) ON DELETE CASCADE,
  jurisdiction     text NOT NULL,           -- 'CA' federal, 'CA-ON', ...
  min_headcount    integer,
  max_headcount    integer
);
CREATE INDEX idx_rule_applicability_version ON public.rule_applicability (rule_version_id);
CREATE INDEX idx_rule_applicability_jurisdiction ON public.rule_applicability (jurisdiction);

CREATE TABLE public.rule_org_settings (
  organisation_id  uuid NOT NULL REFERENCES public.organisations(id) ON DELETE CASCADE,
  rule_id          uuid NOT NULL REFERENCES public.rules(id) ON DELETE CASCADE,
  not_applicable   boolean NOT NULL DEFAULT false,
  reason           text NOT NULL CHECK (char_length(trim(reason)) > 0),
  set_by           uuid REFERENCES auth.users(id),
  set_at           timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (organisation_id, rule_id)
);

CREATE TABLE public.rule_findings (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organisation_id  uuid NOT NULL REFERENCES public.organisations(id) ON DELETE CASCADE,
  rule_version_id  uuid NOT NULL REFERENCES public.rule_versions(id) ON DELETE CASCADE,
  subject_type     text NOT NULL,
  subject_id       uuid NOT NULL,
  passed           boolean NOT NULL,
  severity         text NOT NULL CHECK (severity IN ('info', 'warning', 'error')),
  message          text NOT NULL,
  evaluated_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (rule_version_id, subject_type, subject_id)
);
CREATE INDEX idx_rule_findings_subject ON public.rule_findings (subject_type, subject_id);

-- ── Published versions are immutable; publishing needs a second person ──
CREATE OR REPLACE FUNCTION public.guard_rule_version()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.review_status = 'published' THEN
    -- Only closing the version (effective_to) or retiring it is allowed
    IF NEW.parameters IS DISTINCT FROM OLD.parameters
       OR NEW.label IS DISTINCT FROM OLD.label
       OR NEW.effective_from IS DISTINCT FROM OLD.effective_from
       OR NEW.rule_id IS DISTINCT FROM OLD.rule_id
       OR NEW.review_status NOT IN ('published', 'retired') THEN
      RAISE EXCEPTION 'Published rule versions cannot be edited; create a new version' USING ERRCODE = '42501';
    END IF;
  END IF;

  IF NEW.review_status = 'published' AND (TG_OP = 'INSERT' OR OLD.review_status <> 'published') THEN
    IF NEW.drafted_by IS NOT NULL AND (NEW.reviewed_by IS NULL OR NEW.reviewed_by = NEW.drafted_by) THEN
      RAISE EXCEPTION 'A rule version must be approved by someone other than its drafter' USING ERRCODE = '42501';
    END IF;
    NEW.reviewed_at := COALESCE(NEW.reviewed_at, now());
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_guard_rule_version
  BEFORE INSERT OR UPDATE ON public.rule_versions
  FOR EACH ROW EXECUTE FUNCTION guard_rule_version();

-- ── RLS ──────────────────────────────────────────────────────────
ALTER TABLE public.rule_types         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rules              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rule_versions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rule_applicability ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rule_org_settings  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rule_findings      ENABLE ROW LEVEL SECURITY;

-- Rule content is written by Peninsula (service role) only in R1
CREATE POLICY rule_types_select ON public.rule_types FOR SELECT TO authenticated USING (true);
CREATE POLICY rules_select ON public.rules FOR SELECT TO authenticated
  USING (organisation_id IS NULL OR organisation_id = get_my_organisation_id());
CREATE POLICY rule_versions_select ON public.rule_versions FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM rules r WHERE r.id = rule_id
                 AND (r.organisation_id IS NULL OR r.organisation_id = get_my_organisation_id())));
CREATE POLICY rule_applicability_select ON public.rule_applicability FOR SELECT TO authenticated USING (true);

CREATE POLICY rule_org_settings_select ON public.rule_org_settings FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id());
CREATE POLICY rule_org_settings_write ON public.rule_org_settings FOR ALL TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager())
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_safety_manager());

CREATE POLICY rule_findings_select ON public.rule_findings FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id() AND (is_supervisor_or_above() OR is_executive()));

REVOKE ALL ON public.rule_types, public.rules, public.rule_versions, public.rule_applicability,
              public.rule_org_settings, public.rule_findings FROM anon;

CREATE TRIGGER audit_rule_versions     AFTER INSERT OR UPDATE ON public.rule_versions     FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
CREATE TRIGGER audit_rule_org_settings AFTER INSERT OR UPDATE ON public.rule_org_settings FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- ── Migrate employment_jurisdiction_rules ────────────────────────
INSERT INTO public.rules (code, name, category, rule_type, subject_type, result_key, organisation_id)
SELECT DISTINCT ON (ejr.organisation_id, ejr.province_code, ejr.rule_key)
       'ESA.' || ejr.province_code || '.' || ejr.rule_key
         || COALESCE('.' || left(ejr.organisation_id::text, 8), ''),
       ejr.rule_label,
       'employment_standards',
       CASE
         WHEN ejr.rule_type = 'minimum_wage' AND ejr.rule_key = 'min_wage_general' THEN 'min_threshold'
         WHEN ejr.rule_type = 'probation_max_days'          THEN 'max_duration'
         WHEN ejr.rule_type = 'fixed_term_notice_required'  THEN 'required_field'
         WHEN ejr.rule_type = 'required_doc'                THEN 'required_document'
         WHEN ejr.rule_type = 'stat_holiday_pay_pct'        THEN 'information'
         ELSE 'reference'
       END,
       'hire',
       ejr.rule_key,
       ejr.organisation_id
FROM employment_jurisdiction_rules ejr
ORDER BY ejr.organisation_id, ejr.province_code, ejr.rule_key, ejr.effective_date DESC;

INSERT INTO public.rule_versions (rule_id, version, label, parameters, effective_from, effective_to,
                                  source_citation, review_status, change_note)
SELECT r.id,
       ROW_NUMBER() OVER (PARTITION BY r.id ORDER BY ejr.effective_date),
       ejr.rule_label,
       CASE r.rule_type
         WHEN 'min_threshold'  THEN jsonb_build_object('field', 'hourly_rate', 'min', ejr.rule_value_numeric, 'unit', 'CAD/h',
                                                       'applies_when', jsonb_build_object('pay_frequency', 'hourly'))
         WHEN 'max_duration'   THEN jsonb_build_object('field', 'probation_period_days', 'max_days', ejr.rule_value_numeric)
         WHEN 'required_field' THEN jsonb_build_object('field', 'contract_end_date', 'when', 'is_fixed_term')
         ELSE jsonb_build_object('value', ejr.rule_value, 'value_numeric', ejr.rule_value_numeric)
       END,
       COALESCE(ejr.effective_date, DATE '2000-01-01'),
       ejr.expiry_date,
       ejr.notes,
       CASE WHEN ejr.is_active THEN 'published' ELSE 'retired' END,
       'Migrated from employment_jurisdiction_rules ' || ejr.id
FROM employment_jurisdiction_rules ejr
JOIN public.rules r
  ON r.code = 'ESA.' || ejr.province_code || '.' || ejr.rule_key || COALESCE('.' || left(ejr.organisation_id::text, 8), '');

INSERT INTO public.rule_applicability (rule_version_id, jurisdiction)
SELECT rv.id, 'CA-' || ejr.province_code
FROM public.rule_versions rv
JOIN employment_jurisdiction_rules ejr ON rv.change_note = 'Migrated from employment_jurisdiction_rules ' || ejr.id;

COMMENT ON TABLE public.employment_jurisdiction_rules IS
  'Deprecated 2026-10-28: migrated to rules / rule_versions (rules engine R1). Kept read-only for one release.';

-- ── Evaluator ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.province_name(p_code text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  SELECT CASE p_code
    WHEN 'ON' THEN 'Ontario' WHEN 'BC' THEN 'British Columbia' WHEN 'AB' THEN 'Alberta'
    WHEN 'QC' THEN 'Quebec' WHEN 'SK' THEN 'Saskatchewan' WHEN 'MB' THEN 'Manitoba'
    WHEN 'NS' THEN 'Nova Scotia' WHEN 'NB' THEN 'New Brunswick' WHEN 'PE' THEN 'Prince Edward Island'
    WHEN 'NL' THEN 'Newfoundland and Labrador' WHEN 'YT' THEN 'Yukon'
    WHEN 'NT' THEN 'Northwest Territories' WHEN 'NU' THEN 'Nunavut'
    ELSE p_code END;
$$;

-- Returns the same shape the hiring UI already stores:
-- [{rule_key, rule_label, severity, passed, message}, ...]
CREATE OR REPLACE FUNCTION public.evaluate_hire_rules(p_hire_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  h          record;
  v          record;
  v_province text;
  v_name     text;
  v_as_of    date;
  v_results  jsonb := '[]'::jsonb;
  v_result   jsonb;
  v_value    numeric;
  v_rate     text;
BEGIN
  SELECT * INTO h FROM hires WHERE id = p_hire_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Hire not found'; END IF;

  IF auth.uid() IS NOT NULL AND h.organisation_id IS DISTINCT FROM get_my_organisation_id() THEN
    RAISE EXCEPTION 'insufficient_privilege' USING ERRCODE = '42501';
  END IF;

  SELECT province INTO v_province FROM organisations WHERE id = h.organisation_id;
  IF v_province IS NULL THEN
    RETURN jsonb_build_array(jsonb_build_object(
      'rule_key', 'no_province', 'rule_label', 'Province Not Set', 'severity', 'warning', 'passed', false,
      'message', 'No province is set for this site or organisation. Set a province in Organisation Settings to enable compliance checks.'));
  END IF;
  v_name  := province_name(v_province);
  v_as_of := COALESCE(h.start_date, CURRENT_DATE);

  FOR v IN
    SELECT rv.*, r.rule_type, r.result_key, r.organisation_id AS rule_org
    FROM rule_versions rv
    JOIN rules r ON r.id = rv.rule_id
    JOIN rule_applicability ra ON ra.rule_version_id = rv.id
    WHERE r.is_active AND r.subject_type = 'hire'
      AND rv.review_status = 'published'
      AND ra.jurisdiction = 'CA-' || v_province
      AND rv.effective_from <= v_as_of
      AND (rv.effective_to IS NULL OR rv.effective_to >= v_as_of)
      AND (r.organisation_id IS NULL OR r.organisation_id = h.organisation_id)
      AND NOT EXISTS (SELECT 1 FROM rule_org_settings s
                      WHERE s.organisation_id = h.organisation_id AND s.rule_id = r.id AND s.not_applicable)
    ORDER BY r.rule_type, r.result_key
  LOOP
    v_result := NULL;

    CASE v.rule_type
      WHEN 'min_threshold' THEN
        IF h.pay_frequency = COALESCE(v.parameters #>> '{applies_when,pay_frequency}', h.pay_frequency) THEN
          v_value := (v.parameters ->> 'min')::numeric;
          v_rate := to_char(h.hourly_rate, 'FM999999990.00');
          v_result := CASE
            WHEN h.hourly_rate IS NULL THEN jsonb_build_object('severity', 'warning', 'passed', false,
              'message', format('Could not verify minimum wage compliance — hourly rate not specified. %s minimum wage is $%s.', v_name, to_char(v_value, 'FM999990.00')))
            WHEN h.hourly_rate < v_value THEN jsonb_build_object('severity', 'error', 'passed', false,
              'message', format('Hourly rate ($%s) is below the %s minimum wage ($%s effective %s).', v_rate, v_name, to_char(v_value, 'FM999990.00'), v.effective_from))
            ELSE jsonb_build_object('severity', 'info', 'passed', true,
              'message', format('Hourly rate ($%s) meets the %s minimum wage ($%s).', v_rate, v_name, to_char(v_value, 'FM999990.00')))
          END;
        END IF;

      WHEN 'max_duration' THEN
        IF h.probation_period_days IS NOT NULL THEN
          v_value := (v.parameters ->> 'max_days')::numeric;
          v_result := CASE
            WHEN h.probation_period_days > v_value THEN jsonb_build_object('severity', 'warning', 'passed', false,
              'message', format('Probation of %s days runs past the first %s days. In %s, termination notice (or pay instead) is owed after that point even during probation.', h.probation_period_days, v_value, v_name))
            ELSE jsonb_build_object('severity', 'info', 'passed', true,
              'message', format('Probation of %s days is within the first %s days, when no statutory termination notice is owed in %s.', h.probation_period_days, v_value, v_name))
          END;
        END IF;

      WHEN 'required_field' THEN
        IF h.is_fixed_term THEN
          v_result := CASE
            WHEN h.contract_end_date IS NULL THEN jsonb_build_object('severity', 'error', 'passed', false,
              'message', format('Fixed-term contracts in %s require a specified end date.', v_name))
            ELSE jsonb_build_object('severity', 'info', 'passed', true,
              'message', format('Fixed-term contract end date is set: %s.', h.contract_end_date))
          END;
        END IF;

      WHEN 'required_document' THEN
        v_result := jsonb_build_object('severity', 'info', 'passed', true,
          'message', format('%s requires: %s%s', v_name, v.label, COALESCE(' — ' || NULLIF(regexp_replace(v.source_citation, ' Corrected \d{4}-\d{2}-\d{2}.*$', ''), ''), '')));

      WHEN 'information' THEN
        v_result := jsonb_build_object('severity', 'info', 'passed', true,
          'message', format('%s requires at least %s%% vacation pay on earnings%s.', v_name, v.parameters ->> 'value',
                            COALESCE(' (' || NULLIF(regexp_replace(v.source_citation, ' Corrected \d{4}-\d{2}-\d{2}.*$', ''), '') || ')', '')));

      ELSE
        NULL;  -- 'reference' rules are stored, not evaluated
    END CASE;

    IF v_result IS NOT NULL THEN
      v_result := v_result || jsonb_build_object('rule_key', v.result_key, 'rule_label', v.label);
      v_results := v_results || jsonb_build_array(v_result);

      INSERT INTO rule_findings (organisation_id, rule_version_id, subject_type, subject_id, passed, severity, message)
      VALUES (h.organisation_id, v.id, 'hire', h.id, (v_result ->> 'passed')::boolean, v_result ->> 'severity', v_result ->> 'message')
      ON CONFLICT (rule_version_id, subject_type, subject_id)
      DO UPDATE SET passed = EXCLUDED.passed, severity = EXCLUDED.severity, message = EXCLUDED.message, evaluated_at = now();
    END IF;
  END LOOP;

  RETURN v_results;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.evaluate_hire_rules(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.province_name(text)       FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.guard_rule_version()      FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.evaluate_hire_rules(uuid) TO authenticated, service_role;
GRANT  EXECUTE ON FUNCTION public.province_name(text)       TO authenticated, service_role;
