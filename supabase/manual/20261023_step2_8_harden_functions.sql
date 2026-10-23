-- =============================================================
-- Step 2.8 — function hardening (D19 tail, advisor 0011).
-- * Batch / cron functions are SECURITY DEFINER and were callable by
--   any signed-in user over RPC. Only cron (postgres) and the
--   service role need them. The app's only RPC is create_notification.
-- * next_sequence_value: callers may only advance their own org's
--   counters.
-- * Pin search_path on every function that lacks one.
-- Non-destructive: Claude can apply this with apply_migration.
-- =============================================================

DO $$
DECLARE f regprocedure;
BEGIN
  FOR f IN
    SELECT p.oid::regprocedure
    FROM pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.proname IN (
        'compute_kpi_snapshot', 'compute_all_kpi_snapshots',
        'mark_overdue_actions', 'mark_overdue_capas', 'mark_overdue_inspections', 'mark_overdue_asset_inspections',
        'mark_overdue_risk_reviews', 'mark_overdue_health_checks', 'mark_expired_permits',
        'check_expiring_training', 'check_hiring_compliance_alerts',
        'run_licence_expiry_alerts', 'run_reverification_due_checks',
        'notify_sds_review_due', 'notify_upcoming_health_checks', 'notify_expiring_documents', 'notify_env_reporting_due',
        'fire_escalation_step', 'create_scheduled_inspection', 'mark_delivery_delivered')
  LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon, authenticated', f);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO service_role', f);
  END LOOP;
END $$;

CREATE OR REPLACE FUNCTION public.next_sequence_value(
  p_organisation_id uuid,
  p_sequence_key    text,
  p_per_year        boolean DEFAULT true
) RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_year integer := CASE WHEN p_per_year THEN EXTRACT(YEAR FROM now())::integer ELSE 0 END;
  v_next integer;
BEGIN
  IF auth.uid() IS NOT NULL AND p_organisation_id IS DISTINCT FROM get_my_organisation_id() THEN
    RAISE EXCEPTION 'next_sequence_value: organisation mismatch' USING ERRCODE = '42501';
  END IF;

  INSERT INTO reference_counters (entity_type, organisation_id, year, sequence_key, last_value)
  VALUES ('', p_organisation_id, v_year, p_sequence_key, 1)
  ON CONFLICT (entity_type, organisation_id, year, sequence_key)
  DO UPDATE SET last_value = reference_counters.last_value + 1
  RETURNING last_value INTO v_next;
  RETURN v_next;
END;
$$;

-- Pin search_path on postgres-owned functions that don't set one
DO $$
DECLARE f regprocedure;
BEGIN
  FOR f IN
    SELECT p.oid::regprocedure
    FROM pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.proowner = 'postgres'::regrole
      AND NOT EXISTS (SELECT 1 FROM pg_depend d WHERE d.objid = p.oid AND d.deptype = 'e')
      AND NOT EXISTS (SELECT 1 FROM unnest(coalesce(p.proconfig, '{}')) cfg WHERE cfg LIKE 'search_path=%')
  LOOP
    EXECUTE format('ALTER FUNCTION %s SET search_path = public, extensions', f);
  END LOOP;
END $$;
