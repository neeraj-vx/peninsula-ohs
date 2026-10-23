-- Auth-triggered functions must explicitly set search_path = public
-- because the Supabase auth service calls them without a schema search path.

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id uuid;
  v_fname  text;
  v_lname  text;
BEGIN
  v_org_id := (NEW.raw_user_meta_data->>'organisation_id')::uuid;
  v_fname  := coalesce(NEW.raw_user_meta_data->>'first_name', split_part(NEW.email, '@', 1));
  v_lname  := coalesce(NEW.raw_user_meta_data->>'last_name', '');

  IF v_org_id IS NOT NULL THEN
    INSERT INTO public.user_profiles (id, organisation_id, first_name, last_name, email)
    VALUES (NEW.id, v_org_id, v_fname, v_lname, NEW.email)
    ON CONFLICT (id) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_auth_user_login()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id   uuid;
  v_headers  jsonb;
  v_ip       text;
  v_ua       text;
  v_provider text;
BEGIN
  SELECT organisation_id INTO v_org_id
  FROM public.user_profiles WHERE id = NEW.id;

  BEGIN
    v_headers := current_setting('request.headers', true)::jsonb;
    v_ip      := coalesce(v_headers->>'x-forwarded-for', v_headers->>'x-real-ip');
    v_ua      := v_headers->>'user-agent';
  EXCEPTION WHEN OTHERS THEN NULL; END;

  v_provider := coalesce(NEW.app_metadata->>'provider', 'email');

  INSERT INTO public.auth_events (
    organisation_id, user_id, user_email,
    event_type, provider, ip_address, user_agent, success
  ) VALUES (
    v_org_id, NEW.id, NEW.email,
    'login_success', v_provider, v_ip, v_ua, true
  );

  RETURN NEW;
END;
$$;
