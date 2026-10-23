-- Applied manually via the SQL editor on 2026-10-23 (history row inserted afterwards)
-- =============================================================
-- Destructive bundle — run once in the Supabase SQL editor
-- (Dashboard → SQL Editor → paste → Run).
--
-- These statements contain DROP / DELETE, which the Supabase MCP
-- server will not apply from this session without an interactive
-- confirmation. Everything else from 2026-10-23 is already applied.
-- Runs in one transaction: either all of it applies or none does.
-- After it succeeds, tell Claude so it can record the four parts in
-- supabase_migrations.schema_migrations and regenerate the files.
--
-- Parts:
--   1. test_support_functions           (Step 1 harness)
--   2. fix_training_needs_matrix_unique (D8)
--   3. rls_policy_repair                (D2, D3, D12, system courses)
--   4. drop_emr_pms_wfm                 (D21)
-- =============================================================


-- -------------------------------------------------------------
-- 1. test_support_functions
-- -------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.platform_security_report()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
  SELECT jsonb_build_object(
    'tables', (
      SELECT coalesce(jsonb_agg(c.relname ORDER BY c.relname), '[]')
      FROM pg_class c
      WHERE c.relnamespace = 'public'::regnamespace AND c.relkind = 'r'),
    'rls_disabled', (
      SELECT coalesce(jsonb_agg(c.relname ORDER BY c.relname), '[]')
      FROM pg_class c
      WHERE c.relnamespace = 'public'::regnamespace AND c.relkind = 'r' AND NOT c.relrowsecurity),
    'rls_without_policies', (
      SELECT coalesce(jsonb_agg(c.relname ORDER BY c.relname), '[]')
      FROM pg_class c
      WHERE c.relnamespace = 'public'::regnamespace AND c.relkind = 'r' AND c.relrowsecurity
        AND NOT EXISTS (SELECT 1 FROM pg_policy p WHERE p.polrelid = c.oid)),
    'anon_table_grants', (
      SELECT count(*)
      FROM pg_class c
      WHERE c.relnamespace = 'public'::regnamespace AND c.relkind IN ('r', 'v', 'm')
        AND has_table_privilege('anon', c.oid, 'SELECT,INSERT,UPDATE,DELETE')),
    'anon_executable_functions', (
      SELECT coalesce(jsonb_agg(DISTINCT p.proname), '[]')
      FROM pg_proc p
      WHERE p.pronamespace = 'public'::regnamespace
        AND NOT EXISTS (SELECT 1 FROM pg_depend d WHERE d.objid = p.oid AND d.deptype = 'e')
        AND has_function_privilege('anon', p.oid, 'EXECUTE')),
    'authenticated_executable_functions', (
      SELECT coalesce(jsonb_agg(DISTINCT p.proname), '[]')
      FROM pg_proc p
      WHERE p.pronamespace = 'public'::regnamespace
        AND NOT EXISTS (SELECT 1 FROM pg_depend d WHERE d.objid = p.oid AND d.deptype = 'e')
        AND has_function_privilege('authenticated', p.oid, 'EXECUTE')),
    'functions_without_search_path', (
      SELECT coalesce(jsonb_agg(DISTINCT p.proname), '[]')
      FROM pg_proc p
      WHERE p.pronamespace = 'public'::regnamespace
        AND NOT EXISTS (SELECT 1 FROM pg_depend d WHERE d.objid = p.oid AND d.deptype = 'e')
        AND NOT EXISTS (SELECT 1 FROM unnest(coalesce(p.proconfig, '{}')) cfg WHERE cfg LIKE 'search_path=%')),
    'cron_jobs', (
      SELECT coalesce(jsonb_agg(jsonb_build_object('name', j.jobname, 'schedule', j.schedule,
                                                   'command', j.command, 'active', j.active)
                                ORDER BY j.jobname), '[]')
      FROM cron.job j)
  );
$$;

CREATE OR REPLACE FUNCTION public.test_support_delete_org(p_org_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
  v_name  text;
  v_users uuid[];
  r       record;
BEGIN
  SELECT name INTO v_name FROM organisations WHERE id = p_org_id;
  IF v_name IS NULL THEN RETURN; END IF;
  IF v_name NOT LIKE 'zz-test-%' THEN
    RAISE EXCEPTION 'test_support_delete_org only deletes zz-test-* organisations (got %)', v_name;
  END IF;

  SELECT array_agg(id) INTO v_users FROM user_profiles WHERE organisation_id = p_org_id;

  -- Rows are removed table by table regardless of FK order
  SET LOCAL session_replication_role = replica;

  DELETE FROM notification_deliveries
  WHERE notification_id IN (SELECT id FROM notifications WHERE organisation_id = p_org_id);
  DELETE FROM notification_rule_recipients
  WHERE rule_id IN (SELECT id FROM notification_rules WHERE organisation_id = p_org_id);

  FOR r IN
    SELECT c.table_name,
           bool_or(c.column_name = 'organisation_id') AS has_org,
           bool_or(c.column_name = 'user_id')         AS has_user
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema = c.table_schema AND t.table_name = c.table_name AND t.table_type = 'BASE TABLE'
    WHERE c.table_schema = 'public' AND c.table_name <> 'organisations'
    GROUP BY c.table_name
  LOOP
    IF r.has_org THEN
      EXECUTE format('DELETE FROM public.%I WHERE organisation_id = $1', r.table_name) USING p_org_id;
    ELSIF r.has_user AND v_users IS NOT NULL THEN
      EXECUTE format('DELETE FROM public.%I WHERE user_id = ANY($1)', r.table_name) USING v_users;
    END IF;
  END LOOP;

  DELETE FROM organisations WHERE id = p_org_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.platform_security_report()    FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.test_support_delete_org(uuid) FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.platform_security_report()    TO service_role;
GRANT  EXECUTE ON FUNCTION public.test_support_delete_org(uuid) TO service_role;

-- -------------------------------------------------------------
-- 2. fix_training_needs_matrix_unique (D8)
--    The old key (role_id, course_id) is stricter, so no existing
--    rows can violate the new one.
-- -------------------------------------------------------------

ALTER TABLE public.training_needs_matrix DROP CONSTRAINT training_needs_matrix_role_id_course_id_key;
ALTER TABLE public.training_needs_matrix
  ADD CONSTRAINT training_needs_matrix_org_role_course_key UNIQUE (organisation_id, role_id, course_id);

-- -------------------------------------------------------------
-- 3. rls_policy_repair (D2, D3, D12)
--    Replaces org-only FOR ALL policies with read-by-org and
--    role-checked writes. "Manager" = System Admin or HSE Officer;
--    "supervisor+" adds Supervisor. Self-service writes the app
--    relies on stay open: module completions, own training records,
--    own toolbox sign-on, own emergency contacts, raising an
--    emergency.
-- -------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.is_safety_manager()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT is_system_admin() OR is_hse_officer() $$;

CREATE OR REPLACE FUNCTION public.is_supervisor_or_above()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT is_system_admin() OR is_hse_officer() OR is_supervisor() $$;

REVOKE EXECUTE ON FUNCTION public.is_safety_manager()      FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.is_supervisor_or_above() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.is_safety_manager()      TO authenticated, service_role;
GRANT  EXECUTE ON FUNCTION public.is_supervisor_or_above() TO authenticated, service_role;

-- D2: training_module_completions was world-readable
DROP POLICY IF EXISTS public_read_tmc ON public.training_module_completions;
DROP POLICY IF EXISTS org_tmc         ON public.training_module_completions;
CREATE POLICY tmc_select ON public.training_module_completions FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id());
CREATE POLICY tmc_insert ON public.training_module_completions FOR INSERT TO authenticated
  WITH CHECK (organisation_id = get_my_organisation_id() AND (worker_id = auth.uid() OR is_supervisor_or_above()));
CREATE POLICY tmc_update ON public.training_module_completions FOR UPDATE TO authenticated
  USING (organisation_id = get_my_organisation_id() AND (worker_id = auth.uid() OR is_supervisor_or_above()))
  WITH CHECK (organisation_id = get_my_organisation_id());
CREATE POLICY tmc_delete ON public.training_module_completions FOR DELETE TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager());

-- D3: org_risks let any member write any org risk and any system template
DROP POLICY IF EXISTS org_risks ON public.risks;
CREATE POLICY risk_select_templates ON public.risks FOR SELECT TO authenticated
  USING (organisation_id IS NULL AND is_template = true);

-- System courses / modules (organisation_id NULL) were writable by everyone
DROP POLICY IF EXISTS org_tc ON public.training_courses;
CREATE POLICY tc_select ON public.training_courses FOR SELECT TO authenticated
  USING (organisation_id IS NULL OR organisation_id = get_my_organisation_id());
CREATE POLICY tc_insert ON public.training_courses FOR INSERT TO authenticated
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_safety_manager());
CREATE POLICY tc_update ON public.training_courses FOR UPDATE TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager())
  WITH CHECK (organisation_id = get_my_organisation_id());
CREATE POLICY tc_delete ON public.training_courses FOR DELETE TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager());

DROP POLICY IF EXISTS org_tcm ON public.training_course_modules;
CREATE POLICY tcm_select ON public.training_course_modules FOR SELECT TO authenticated
  USING (organisation_id IS NULL OR organisation_id = get_my_organisation_id());
CREATE POLICY tcm_insert ON public.training_course_modules FOR INSERT TO authenticated
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_safety_manager());
CREATE POLICY tcm_update ON public.training_course_modules FOR UPDATE TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager())
  WITH CHECK (organisation_id = get_my_organisation_id());
CREATE POLICY tcm_delete ON public.training_course_modules FOR DELETE TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager());

DROP POLICY IF EXISTS org_tnm ON public.training_needs_matrix;
CREATE POLICY tnm_select ON public.training_needs_matrix FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id());
CREATE POLICY tnm_write ON public.training_needs_matrix FOR ALL TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager())
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_safety_manager());

DROP POLICY IF EXISTS org_tr ON public.training_records;
CREATE POLICY tr_select ON public.training_records FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id()
         AND (worker_id = auth.uid() OR is_supervisor_or_above() OR is_executive()));
CREATE POLICY tr_insert ON public.training_records FOR INSERT TO authenticated
  WITH CHECK (organisation_id = get_my_organisation_id() AND (worker_id = auth.uid() OR is_supervisor_or_above()));
CREATE POLICY tr_update ON public.training_records FOR UPDATE TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_supervisor_or_above())
  WITH CHECK (organisation_id = get_my_organisation_id());
CREATE POLICY tr_delete ON public.training_records FOR DELETE TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager());

-- Toolbox talks
DROP POLICY IF EXISTS org_ttt ON public.toolbox_talk_templates;
CREATE POLICY ttt_select ON public.toolbox_talk_templates FOR SELECT TO authenticated
  USING (organisation_id IS NULL OR organisation_id = get_my_organisation_id());
CREATE POLICY ttt_write ON public.toolbox_talk_templates FOR ALL TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager())
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_safety_manager());

DROP POLICY IF EXISTS org_tttp ON public.toolbox_talk_template_points;
CREATE POLICY tttp_select ON public.toolbox_talk_template_points FOR SELECT TO authenticated
  USING (template_id IN (SELECT id FROM toolbox_talk_templates
                         WHERE organisation_id IS NULL OR organisation_id = get_my_organisation_id()));
CREATE POLICY tttp_write ON public.toolbox_talk_template_points FOR ALL TO authenticated
  USING (is_safety_manager() AND template_id IN (SELECT id FROM toolbox_talk_templates WHERE organisation_id = get_my_organisation_id()))
  WITH CHECK (is_safety_manager() AND template_id IN (SELECT id FROM toolbox_talk_templates WHERE organisation_id = get_my_organisation_id()));

DROP POLICY IF EXISTS org_tts ON public.toolbox_talk_schedules;
CREATE POLICY tts_select ON public.toolbox_talk_schedules FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id());
CREATE POLICY tts_write ON public.toolbox_talk_schedules FOR ALL TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_supervisor_or_above())
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_supervisor_or_above());

DROP POLICY IF EXISTS org_ttdel ON public.toolbox_talk_deliveries;
CREATE POLICY ttd_select ON public.toolbox_talk_deliveries FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id());
CREATE POLICY ttd_insert ON public.toolbox_talk_deliveries FOR INSERT TO authenticated
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_supervisor_or_above());
CREATE POLICY ttd_update ON public.toolbox_talk_deliveries FOR UPDATE TO authenticated
  USING (organisation_id = get_my_organisation_id() AND (delivered_by = auth.uid() OR is_supervisor_or_above()))
  WITH CHECK (organisation_id = get_my_organisation_id());
CREATE POLICY ttd_delete ON public.toolbox_talk_deliveries FOR DELETE TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager());

DROP POLICY IF EXISTS org_tta ON public.toolbox_talk_attendees;
CREATE POLICY tta_select ON public.toolbox_talk_attendees FOR SELECT TO authenticated
  USING (delivery_id IN (SELECT id FROM toolbox_talk_deliveries WHERE organisation_id = get_my_organisation_id()));
CREATE POLICY tta_insert ON public.toolbox_talk_attendees FOR INSERT TO authenticated
  WITH CHECK (delivery_id IN (SELECT id FROM toolbox_talk_deliveries WHERE organisation_id = get_my_organisation_id())
              AND (worker_id = auth.uid() OR is_supervisor_or_above()));
CREATE POLICY tta_update ON public.toolbox_talk_attendees FOR UPDATE TO authenticated
  USING (delivery_id IN (SELECT id FROM toolbox_talk_deliveries WHERE organisation_id = get_my_organisation_id())
         AND (worker_id = auth.uid() OR is_supervisor_or_above()));
CREATE POLICY tta_delete ON public.toolbox_talk_attendees FOR DELETE TO authenticated
  USING (delivery_id IN (SELECT id FROM toolbox_talk_deliveries WHERE organisation_id = get_my_organisation_id())
         AND is_supervisor_or_above());

-- Contractors
DROP POLICY IF EXISTS org_cc ON public.contractor_companies;
CREATE POLICY cc_select ON public.contractor_companies FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id());
CREATE POLICY cc_write ON public.contractor_companies FOR ALL TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_supervisor_or_above())
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_supervisor_or_above());

DROP POLICY IF EXISTS org_ccd ON public.contractor_company_documents;
CREATE POLICY ccd_select ON public.contractor_company_documents FOR SELECT TO authenticated
  USING (contractor_id IN (SELECT id FROM contractor_companies WHERE organisation_id = get_my_organisation_id()));
CREATE POLICY ccd_write ON public.contractor_company_documents FOR ALL TO authenticated
  USING (is_supervisor_or_above() AND contractor_id IN (SELECT id FROM contractor_companies WHERE organisation_id = get_my_organisation_id()))
  WITH CHECK (is_supervisor_or_above() AND contractor_id IN (SELECT id FROM contractor_companies WHERE organisation_id = get_my_organisation_id()));

DROP POLICY IF EXISTS org_cw ON public.contractor_workers;
CREATE POLICY cw_select ON public.contractor_workers FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id());
CREATE POLICY cw_write ON public.contractor_workers FOR ALL TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_supervisor_or_above())
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_supervisor_or_above());

DROP POLICY IF EXISTS org_csal ON public.contractor_site_access_log;
CREATE POLICY csal_select ON public.contractor_site_access_log FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id());
CREATE POLICY csal_write ON public.contractor_site_access_log FOR ALL TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_supervisor_or_above())
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_supervisor_or_above());

-- Emergency management
DROP POLICY IF EXISTS org_erp ON public.emergency_response_plans;
CREATE POLICY erp_select ON public.emergency_response_plans FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id());
CREATE POLICY erp_write ON public.emergency_response_plans FOR ALL TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager())
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_safety_manager());

DROP POLICY IF EXISTS org_ew ON public.emergency_wardens;
CREATE POLICY ew_select ON public.emergency_wardens FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id());
CREATE POLICY ew_write ON public.emergency_wardens FOR ALL TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager())
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_safety_manager());

DROP POLICY IF EXISTS org_mp ON public.muster_points;
CREATE POLICY mp_select ON public.muster_points FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id());
CREATE POLICY mp_write ON public.muster_points FOR ALL TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager())
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_safety_manager());

DROP POLICY IF EXISTS org_ed ON public.emergency_drills;
CREATE POLICY ed_select ON public.emergency_drills FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id());
CREATE POLICY ed_write ON public.emergency_drills FOR ALL TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_supervisor_or_above())
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_supervisor_or_above());

DROP POLICY IF EXISTS org_ea ON public.emergency_activations;
CREATE POLICY ea_select ON public.emergency_activations FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id());
CREATE POLICY ea_insert ON public.emergency_activations FOR INSERT TO authenticated
  WITH CHECK (organisation_id = get_my_organisation_id());
CREATE POLICY ea_update ON public.emergency_activations FOR UPDATE TO authenticated
  USING (organisation_id = get_my_organisation_id() AND (activated_by = auth.uid() OR is_supervisor_or_above()))
  WITH CHECK (organisation_id = get_my_organisation_id());
CREATE POLICY ea_delete ON public.emergency_activations FOR DELETE TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_safety_manager());

-- Emergency contacts are personal data: own rows, or supervisor+
DROP POLICY IF EXISTS org_select_ec ON public.emergency_contacts;
DROP POLICY IF EXISTS org_insert_ec ON public.emergency_contacts;
DROP POLICY IF EXISTS org_update_ec ON public.emergency_contacts;
DROP POLICY IF EXISTS org_delete_ec ON public.emergency_contacts;
CREATE POLICY ec_all ON public.emergency_contacts FOR ALL TO authenticated
  USING (organisation_id = get_my_organisation_id() AND (worker_id = auth.uid() OR is_supervisor_or_above()))
  WITH CHECK (organisation_id = get_my_organisation_id() AND (worker_id = auth.uid() OR is_supervisor_or_above()));

-- PPE stock and issue: supervisor+ writes
DROP POLICY IF EXISTS ppe_items_org_insert ON public.ppe_items;
DROP POLICY IF EXISTS ppe_items_org_update ON public.ppe_items;
CREATE POLICY ppe_items_insert ON public.ppe_items FOR INSERT TO authenticated
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_supervisor_or_above());
CREATE POLICY ppe_items_update ON public.ppe_items FOR UPDATE TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_supervisor_or_above())
  WITH CHECK (organisation_id = get_my_organisation_id());

DROP POLICY IF EXISTS ppe_issuances_org_insert ON public.ppe_issuances;
DROP POLICY IF EXISTS ppe_issuances_org_update ON public.ppe_issuances;
CREATE POLICY ppe_issuances_insert ON public.ppe_issuances FOR INSERT TO authenticated
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_supervisor_or_above());
CREATE POLICY ppe_issuances_update ON public.ppe_issuances FOR UPDATE TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_supervisor_or_above())
  WITH CHECK (organisation_id = get_my_organisation_id());

DROP POLICY IF EXISTS ppe_fit_tests_org_insert ON public.ppe_fit_tests;
DROP POLICY IF EXISTS ppe_fit_tests_org_update ON public.ppe_fit_tests;
CREATE POLICY ppe_fit_tests_insert ON public.ppe_fit_tests FOR INSERT TO authenticated
  WITH CHECK (organisation_id = get_my_organisation_id() AND is_supervisor_or_above());
CREATE POLICY ppe_fit_tests_update ON public.ppe_fit_tests FOR UPDATE TO authenticated
  USING (organisation_id = get_my_organisation_id() AND is_supervisor_or_above())
  WITH CHECK (organisation_id = get_my_organisation_id());

-- ppe_types is a global lookup (no organisation_id): read-only to users
DROP POLICY IF EXISTS ppe_types_insert_auth ON public.ppe_types;
DROP POLICY IF EXISTS ppe_types_update_auth ON public.ppe_types;
DROP POLICY IF EXISTS ppe_write             ON public.ppe_types;
DROP POLICY IF EXISTS public_read           ON public.ppe_types;

-- Lookup tables that had RLS on paper but no policy
CREATE POLICY emergency_types_select ON public.emergency_types FOR SELECT TO authenticated USING (true);
CREATE POLICY toolbox_talk_categories_select ON public.toolbox_talk_categories FOR SELECT TO authenticated USING (true);

-- -------------------------------------------------------------
-- 4. drop_emr_pms_wfm (D21)
--    Checked 2026-10-23: no FKs, views or triggers outside these
--    tables depend on them; only EMR seed lookups hold rows.
--    No CASCADE, so an unexpected dependency aborts the bundle.
-- -------------------------------------------------------------

DO $$
DECLARE v_tables text;
BEGIN
  SELECT string_agg(format('public.%I', tablename), ', ')
  INTO v_tables
  FROM pg_tables
  WHERE schemaname = 'public'
    AND (tablename LIKE 'emr\_%' OR tablename LIKE 'pms\_%' OR tablename LIKE 'wfm\_%');

  IF v_tables IS NOT NULL THEN
    EXECUTE 'DROP TABLE ' || v_tables;
  END IF;
END $$;

DO $$
DECLARE f regprocedure;
BEGIN
  FOR f IN
    SELECT p.oid::regprocedure
    FROM pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.proname IN (
        'generate_emr_admission_number', 'generate_emr_encounter_number', 'generate_emr_patient_number',
        'set_pms_action_number', 'set_pms_compliance_number', 'set_pms_document_number',
        'set_pms_hazard_number', 'set_pms_incident_number', 'set_pms_inspection_number',
        'set_pms_permit_number', 'set_pms_property_number')
  LOOP
    EXECUTE format('DROP FUNCTION %s', f);
  END LOOP;
END $$;

DROP SEQUENCE IF EXISTS
  public.pms_hazard_seq, public.pms_inspection_seq, public.pms_compliance_seq, public.pms_incident_seq,
  public.pms_permit_seq, public.pms_action_seq, public.pms_document_seq, public.pms_property_seq;

