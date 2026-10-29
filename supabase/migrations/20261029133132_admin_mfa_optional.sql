-- Two-step sign-in is now optional for System Admins (owner decision,
-- 2026-10-29). An admin who has set up an authenticator must still use
-- it: their admin-only writes need an aal2 session. Admins without one
-- are no longer blocked.
CREATE OR REPLACE FUNCTION public.admin_mfa_satisfied()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT NOT is_system_admin()
      OR COALESCE(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
      OR NOT EXISTS (SELECT 1 FROM auth.mfa_factors f WHERE f.user_id = auth.uid() AND f.status = 'verified');
$$;
