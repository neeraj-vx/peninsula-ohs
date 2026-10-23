-- =============================================================
-- Step 2.7 — re-enable RLS (D18). Apply ONLY after:
--   1. 20261023_destructive_bundle.sql has been applied, and
--   2. `pnpm test:integration` passes rls-smoke.test.ts against a
--      dry run (or the suite is re-run immediately after applying).
-- Undoes live-only migration 20260609195201_disable_rls_all_tables.
-- Prerequisites already applied on 2026-10-23:
--   fix_reference_numbering (generators no longer write
--   reference_counters as the calling user).
-- Non-destructive: Claude can apply this with apply_migration.
-- =============================================================

DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT c.relname
    FROM pg_class c
    WHERE c.relnamespace = 'public'::regnamespace AND c.relkind = 'r' AND NOT c.relrowsecurity
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', r.relname);
  END LOOP;
END $$;
