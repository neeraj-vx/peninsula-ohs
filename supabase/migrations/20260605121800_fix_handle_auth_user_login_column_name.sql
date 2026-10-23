-- auth.users uses raw_app_meta_data, not app_metadata
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

  -- Column is raw_app_meta_data in this Supabase version, not app_metadata
  v_provider := coalesce(NEW.raw_app_meta_data->>'provider', 'email');

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
