-- Append-only tables have DO INSTEAD NOTHING rules on UPDATE/DELETE which
-- conflict with Postgres FK enforcement when auth.users rows are deleted.
-- These columns are audit/log references — they should be soft references
-- (UUID only, no enforced FK) so user deletion is never blocked.

ALTER TABLE public.auth_events               DROP CONSTRAINT IF EXISTS auth_events_user_id_fkey;
ALTER TABLE public.audit_logs                DROP CONSTRAINT IF EXISTS audit_logs_changed_by_fkey;
ALTER TABLE public.row_versions              DROP CONSTRAINT IF EXISTS row_versions_changed_by_fkey;
ALTER TABLE public.action_assignments        DROP CONSTRAINT IF EXISTS action_assignments_assigned_from_fkey;
ALTER TABLE public.action_assignments        DROP CONSTRAINT IF EXISTS action_assignments_assigned_to_fkey;
ALTER TABLE public.action_assignments        DROP CONSTRAINT IF EXISTS action_assignments_assigned_by_fkey;
ALTER TABLE public.action_comments           DROP CONSTRAINT IF EXISTS action_comments_user_id_fkey;
ALTER TABLE public.chemical_inventory_transactions DROP CONSTRAINT IF EXISTS chemical_inventory_transactions_transacted_by_fkey;
ALTER TABLE public.incident_status_history   DROP CONSTRAINT IF EXISTS incident_status_history_changed_by_fkey;
ALTER TABLE public.integration_sync_logs     DROP CONSTRAINT IF EXISTS integration_sync_logs_triggered_by_fkey;
ALTER TABLE public.report_execution_log      DROP CONSTRAINT IF EXISTS report_execution_log_triggered_by_fkey;
ALTER TABLE public.webhook_deliveries        DROP CONSTRAINT IF EXISTS webhook_deliveries_created_by_fkey;
