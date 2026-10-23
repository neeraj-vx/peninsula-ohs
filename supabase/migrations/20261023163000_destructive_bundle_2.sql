-- Applied manually via the SQL editor on 2026-10-23 (history row inserted afterwards)
-- =============================================================
-- Destructive bundle 2 — run once in the Supabase SQL editor.
-- Found by the integration suite after RLS was re-enabled.
-- One transaction. Tell Claude when it has run.
--
--   1. per_org_reference_numbers (D27)
--   2. speak_up_confidentiality  (D29)
-- =============================================================


-- -------------------------------------------------------------
-- 1. D27: 18 tables had a globally unique *_number while the
--    generators number per organisation (INC-2026-00001 in every
--    org). The first record of that kind in any second organisation
--    failed with a duplicate key. Uniqueness becomes per org.
--    The old keys are stricter, so existing rows can't violate the
--    new ones.
-- -------------------------------------------------------------

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      ('actions',                   'actions_action_number_key',                        'action_number'),
      ('asset_maintenance_records', 'asset_maintenance_records_maintenance_number_key', 'maintenance_number'),
      ('assets',                    'assets_asset_number_key',                          'asset_number'),
      ('audits',                    'audits_audit_number_key',                          'audit_number'),
      ('bgc_packages',              'bgc_packages_package_number_key',                  'package_number'),
      ('chemicals',                 'chemicals_chemical_number_key',                    'chemical_number'),
      ('documents',                 'documents_document_number_key',                    'document_number'),
      ('hazard_reports',            'hazard_reports_report_number_key',                 'report_number'),
      ('health_check_records',      'health_check_records_check_number_key',            'check_number'),
      ('hires',                     'hires_hire_number_key',                            'hire_number'),
      ('incident_capa',             'incident_capa_capa_number_key',                    'capa_number'),
      ('incidents',                 'incidents_incident_number_key',                    'incident_number'),
      ('inspections',               'inspections_inspection_number_key',                'inspection_number'),
      ('investigations',            'investigations_investigation_number_key',          'investigation_number'),
      ('permits',                   'permits_permit_number_key',                        'permit_number'),
      ('return_to_work_plans',      'return_to_work_plans_plan_number_key',             'plan_number'),
      ('risk_reviews',              'risk_reviews_review_number_key',                   'review_number'),
      ('risks',                     'risks_risk_number_key',                            'risk_number')
    ) AS t(tbl, con, col)
  LOOP
    EXECUTE format('ALTER TABLE public.%I DROP CONSTRAINT %I', r.tbl, r.con);
    EXECUTE format('ALTER TABLE public.%I ADD CONSTRAINT %I UNIQUE (organisation_id, %I)',
                   r.tbl, r.tbl || '_org_' || r.col || '_key', r.col);
  END LOOP;
END $$;

-- -------------------------------------------------------------
-- 2. D29: speak_up_reports accepted inserts into any organisation
--    (WITH CHECK true) and every org member could read every
--    confidential report. Reports stay anonymous (no reporter
--    column); any member can file into their own org, and only
--    safety managers or the assigned investigator can read/update.
--    The app inserts without reading the row back.
-- -------------------------------------------------------------

DROP POLICY IF EXISTS reports_insert_anonymous ON public.speak_up_reports;
DROP POLICY IF EXISTS reports_select_org       ON public.speak_up_reports;
DROP POLICY IF EXISTS reports_update_org       ON public.speak_up_reports;

CREATE POLICY speak_up_insert ON public.speak_up_reports FOR INSERT TO authenticated
  WITH CHECK (organisation_id = get_my_organisation_id());
CREATE POLICY speak_up_select ON public.speak_up_reports FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id() AND (is_safety_manager() OR assigned_to = auth.uid()));
CREATE POLICY speak_up_update ON public.speak_up_reports FOR UPDATE TO authenticated
  USING (organisation_id = get_my_organisation_id() AND (is_safety_manager() OR assigned_to = auth.uid()))
  WITH CHECK (organisation_id = get_my_organisation_id());

