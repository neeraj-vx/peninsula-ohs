-- =============================================================
-- D15: no audit trail on the training, hiring, background-check,
-- compliance, contractor, emergency, JSA, toolbox and PPE tables.
-- Adds the existing audit_trigger_function (-> audit_logs, readable
-- by System Admin and HSE Officer in the same org).
-- Deliberately NOT audited, because audit_logs would copy their
-- contents to a wider audience than the table itself allows:
--   speak_up_reports (would record the anonymous reporter),
--   bgc_results, bgc_adjudications, bgc_disputes,
--   bgc_adverse_action_notices (BGC reviewers only),
--   health / medical tables.
-- =============================================================

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'training_courses', 'training_course_modules', 'training_needs_matrix',
    'training_records', 'training_module_completions',
    'hires', 'hire_documents', 'hire_prestart_tasks',
    'onboarding_templates', 'onboarding_template_tasks', 'onboarding_assignments', 'onboarding_task_completions',
    'bgc_packages', 'bgc_orders', 'bgc_organisation_providers', 'bgc_consent_templates', 'bgc_role_requirements',
    'bgc_reference_requests', 'bgc_reference_templates', 'bgc_reverification_schedules', 'bgc_reverification_events',
    'compliance_obligations', 'compliance_tasks',
    'contractor_companies', 'contractor_workers', 'contractor_site_access_log',
    'emergency_response_plans', 'emergency_wardens', 'emergency_drills', 'emergency_activations',
    'emergency_contacts', 'muster_points',
    'jsas', 'toolbox_talk_templates', 'toolbox_talk_deliveries',
    'ppe_items', 'ppe_issuances', 'ppe_fit_tests']
  LOOP
    IF to_regclass('public.' || t) IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM pg_trigger
      WHERE tgrelid = ('public.' || t)::regclass AND tgfoid = 'public.audit_trigger_function()'::regprocedure
    ) THEN
      EXECUTE format(
        'CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON public.%I FOR EACH ROW EXECUTE FUNCTION audit_trigger_function()',
        'audit_' || t, t);
    END IF;
  END LOOP;
END $$;
