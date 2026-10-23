-- =============================================================
-- Found by the integration suite right after RLS was re-enabled.
-- D30 (critical): up_update_own has no WITH CHECK, so a user could
--   set their own organisation_id to another tenant's id and then
--   read that tenant through get_my_organisation_id(). A trigger now
--   rejects organisation_id changes from user sessions, and stops
--   users deactivating or re-activating themselves.
-- D28: incident submitters could not read back their own incident
--   (inc_select_own checks is_involved_in_incident(id), which can't
--   see the row being inserted), so createIncident's
--   .insert().select() failed for workers and supervisors.
-- Site scope: production has no user_site_assignments, so site-scoped
--   policies hid everything from supervisors and workers. A user
--   with no assignments now gets every active site in their org;
--   assigning sites narrows it as before.
-- =============================================================

CREATE OR REPLACE FUNCTION public.guard_user_profile_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;  -- service role / cron / migrations
  END IF;

  IF NEW.organisation_id IS DISTINCT FROM OLD.organisation_id THEN
    RAISE EXCEPTION 'organisation_id cannot be changed' USING ERRCODE = '42501';
  END IF;

  IF NEW.id = auth.uid() AND NEW.is_active IS DISTINCT FROM OLD.is_active THEN
    RAISE EXCEPTION 'users cannot change their own active status' USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_guard_user_profile_update
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION guard_user_profile_update();

CREATE POLICY inc_select_submitter ON public.incidents FOR SELECT TO authenticated
  USING (organisation_id = get_my_organisation_id()
         AND (submitted_by = auth.uid() OR created_by = auth.uid()));

CREATE OR REPLACE FUNCTION public.can_access_site(p_site_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT CASE
    WHEN is_system_admin() OR is_hse_officer() OR is_executive()
         OR NOT EXISTS (SELECT 1 FROM user_site_assignments WHERE user_id = auth.uid()) THEN
      -- Wide-access roles, and users not restricted to particular sites
      EXISTS (
        SELECT 1 FROM sites
        WHERE id = p_site_id
          AND organisation_id = get_my_organisation_id()
          AND is_active = true
      )
    ELSE
      -- Explicitly assigned sites only
      p_site_id = ANY(get_my_site_ids())
  END;
$$;

REVOKE EXECUTE ON FUNCTION public.guard_user_profile_update() FROM PUBLIC, anon, authenticated;
