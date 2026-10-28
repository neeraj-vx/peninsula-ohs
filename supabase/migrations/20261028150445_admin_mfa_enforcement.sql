-- =============================================================
-- Two-factor sign-in for System Admins (database side).
-- The app sends admins through a TOTP step (middleware); this makes
-- the same rule hold for anyone calling the API directly: a System
-- Admin whose session is not two-factor verified (JWT aal != 'aal2')
-- cannot create, change or remove admin-only data. Other roles are
-- unaffected. Restrictive policies are ANDed with the existing ones.
-- =============================================================

CREATE OR REPLACE FUNCTION public.admin_mfa_satisfied()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT NOT is_system_admin() OR COALESCE(auth.jwt() ->> 'aal', 'aal1') = 'aal2';
$$;

REVOKE EXECUTE ON FUNCTION public.admin_mfa_satisfied() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.admin_mfa_satisfied() TO authenticated, service_role;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'user_roles', 'roles', 'role_permissions', 'user_site_assignments', 'user_invitations',
    'api_keys', 'api_key_scopes', 'integrations', 'webhook_endpoints', 'webhook_endpoint_subscriptions']
  LOOP
    IF to_regclass('public.' || t) IS NULL THEN CONTINUE; END IF;
    EXECUTE format('CREATE POLICY %I ON public.%I AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK (admin_mfa_satisfied())', t || '_admin_mfa_insert', t);
    EXECUTE format('CREATE POLICY %I ON public.%I AS RESTRICTIVE FOR UPDATE TO authenticated USING (admin_mfa_satisfied()) WITH CHECK (admin_mfa_satisfied())', t || '_admin_mfa_update', t);
    EXECUTE format('CREATE POLICY %I ON public.%I AS RESTRICTIVE FOR DELETE TO authenticated USING (admin_mfa_satisfied())', t || '_admin_mfa_remove', t);
  END LOOP;
END $$;
