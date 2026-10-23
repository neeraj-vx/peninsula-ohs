-- =============================================================
-- Security hotfix (gap analysis D18 / D19)
-- 1. cleanup_demo_org: service_role only (was executable by anon)
-- 2. anon: no table, sequence or function access in public.
--    The app never queries as anon: middleware redirects every
--    unauthenticated platform request to /login.
-- RLS stays disabled here; re-enabling it is Step 2.7.
-- =============================================================

-- 1. Destructive demo cleanup — only the seed script (service role) may call it
REVOKE EXECUTE ON FUNCTION public.cleanup_demo_org(text) FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.cleanup_demo_org(text) TO service_role;

-- 2a. Tables and sequences
REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM anon;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon;

-- 2b. Functions owned by postgres (excludes extension members).
--     anon inherits PUBLIC's EXECUTE, so revoke from PUBLIC and
--     grant back to the roles the app uses.
DO $$
DECLARE f regprocedure;
BEGIN
  FOR f IN
    SELECT p.oid::regprocedure
    FROM pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.proowner = 'postgres'::regrole
      AND NOT EXISTS (SELECT 1 FROM pg_depend d WHERE d.objid = p.oid AND d.deptype = 'e')
      AND p.oid <> 'public.cleanup_demo_org(text)'::regprocedure
  LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon', f);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated, service_role', f);
  END LOOP;
END $$;

-- 2c. Objects created later by postgres don't get anon access by default
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE ALL     ON TABLES    FROM anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE ALL     ON SEQUENCES FROM anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon;
