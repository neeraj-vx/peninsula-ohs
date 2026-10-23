-- All SECURITY DEFINER functions that reference public schema tables
-- must set search_path explicitly — the auth service and trigger contexts
-- don't include public in their search path by default.

CREATE OR REPLACE FUNCTION public.audit_trigger_function()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_old_data       jsonb;
  v_new_data       jsonb;
  v_changed_fields jsonb := '{}';
  v_user_id        uuid;
  v_user_email     text;
  v_ip_address     text;
  v_user_agent     text;
  v_request_id     text;
  v_org_id         uuid;
  v_record_id      text;
  v_key            text;
  v_old_val        jsonb;
  v_new_val        jsonb;
  v_headers        jsonb;
BEGIN
  v_user_id := auth.uid();

  BEGIN
    v_headers    := current_setting('request.headers', true)::jsonb;
    v_ip_address := coalesce(v_headers->>'x-forwarded-for', v_headers->>'x-real-ip');
    v_user_agent := v_headers->>'user-agent';
    v_request_id := v_headers->>'x-request-id';
  EXCEPTION WHEN OTHERS THEN NULL; END;

  IF v_user_id IS NOT NULL THEN
    SELECT email INTO v_user_email FROM auth.users WHERE id = v_user_id;
  END IF;

  IF TG_OP = 'DELETE' THEN
    v_old_data  := to_jsonb(OLD);
    v_record_id := v_old_data->>'id';
    v_org_id := CASE TG_TABLE_NAME WHEN 'organisations' THEN (v_old_data->>'id')::uuid ELSE (v_old_data->>'organisation_id')::uuid END;
    INSERT INTO public.audit_logs (organisation_id, table_name, record_id, action, old_data, new_data, changed_fields, changed_by, changed_by_email, ip_address, user_agent, request_id)
    VALUES (v_org_id, TG_TABLE_NAME, v_record_id, 'DELETE', v_old_data, NULL, NULL, v_user_id, v_user_email, v_ip_address, v_user_agent, v_request_id);
    RETURN OLD;

  ELSIF TG_OP = 'INSERT' THEN
    v_new_data  := to_jsonb(NEW);
    v_record_id := v_new_data->>'id';
    v_org_id := CASE TG_TABLE_NAME WHEN 'organisations' THEN (v_new_data->>'id')::uuid ELSE (v_new_data->>'organisation_id')::uuid END;
    INSERT INTO public.audit_logs (organisation_id, table_name, record_id, action, old_data, new_data, changed_fields, changed_by, changed_by_email, ip_address, user_agent, request_id)
    VALUES (v_org_id, TG_TABLE_NAME, v_record_id, 'INSERT', NULL, v_new_data, NULL, v_user_id, v_user_email, v_ip_address, v_user_agent, v_request_id);
    RETURN NEW;

  ELSIF TG_OP = 'UPDATE' THEN
    v_old_data  := to_jsonb(OLD);
    v_new_data  := to_jsonb(NEW);
    v_record_id := v_new_data->>'id';
    v_org_id := CASE TG_TABLE_NAME WHEN 'organisations' THEN (v_new_data->>'id')::uuid ELSE (v_new_data->>'organisation_id')::uuid END;
    FOR v_key IN SELECT jsonb_object_keys(v_new_data) LOOP
      v_old_val := v_old_data->v_key;
      v_new_val := v_new_data->v_key;
      IF v_old_val IS DISTINCT FROM v_new_val THEN
        v_changed_fields := v_changed_fields || jsonb_build_object(v_key, jsonb_build_object('from', v_old_val, 'to', v_new_val));
      END IF;
    END LOOP;
    IF v_changed_fields = '{}' OR v_changed_fields = jsonb_build_object('updated_at', jsonb_build_object('from', v_old_data->'updated_at', 'to', v_new_data->'updated_at')) THEN
      RETURN NEW;
    END IF;
    INSERT INTO public.audit_logs (organisation_id, table_name, record_id, action, old_data, new_data, changed_fields, changed_by, changed_by_email, ip_address, user_agent, request_id)
    VALUES (v_org_id, TG_TABLE_NAME, v_record_id, 'UPDATE', v_old_data, v_new_data, v_changed_fields, v_user_id, v_user_email, v_ip_address, v_user_agent, v_request_id);
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION public.row_version_trigger_function()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_snapshot       jsonb;
  v_old_snapshot   jsonb;
  v_changed_fields jsonb := '{}';
  v_user_id        uuid;
  v_user_email     text;
  v_ip_address     text;
  v_org_id         uuid;
  v_record_id      text;
  v_version_number integer;
  v_key            text;
  v_headers        jsonb;
BEGIN
  v_user_id := auth.uid();
  BEGIN
    v_headers    := current_setting('request.headers', true)::jsonb;
    v_ip_address := coalesce(v_headers->>'x-forwarded-for', v_headers->>'x-real-ip');
  EXCEPTION WHEN OTHERS THEN NULL; END;
  IF v_user_id IS NOT NULL THEN
    SELECT email INTO v_user_email FROM auth.users WHERE id = v_user_id;
  END IF;
  IF TG_OP = 'DELETE' THEN v_snapshot := to_jsonb(OLD); ELSE v_snapshot := to_jsonb(NEW); END IF;
  v_record_id := v_snapshot->>'id';
  v_org_id := CASE TG_TABLE_NAME WHEN 'organisations' THEN (v_snapshot->>'id')::uuid ELSE (v_snapshot->>'organisation_id')::uuid END;
  SELECT COALESCE(MAX(version_number), 0) + 1 INTO v_version_number FROM public.row_versions WHERE table_name = TG_TABLE_NAME AND record_id = v_record_id;
  IF TG_OP = 'UPDATE' THEN
    v_old_snapshot := to_jsonb(OLD);
    FOR v_key IN SELECT jsonb_object_keys(v_snapshot) LOOP
      IF (v_old_snapshot->v_key) IS DISTINCT FROM (v_snapshot->v_key) THEN
        v_changed_fields := v_changed_fields || jsonb_build_object(v_key, jsonb_build_object('from', v_old_snapshot->v_key, 'to', v_snapshot->v_key));
      END IF;
    END LOOP;
    IF v_changed_fields = '{}' OR v_changed_fields = jsonb_build_object('updated_at', jsonb_build_object('from', v_old_snapshot->'updated_at', 'to', v_snapshot->'updated_at')) THEN
      RETURN NEW;
    END IF;
  END IF;
  INSERT INTO public.row_versions (organisation_id, table_name, record_id, version_number, action, snapshot, changed_fields, changed_by, changed_by_email, ip_address)
  VALUES (v_org_id, TG_TABLE_NAME, v_record_id, v_version_number, TG_OP::audit_action_enum, v_snapshot, NULLIF(v_changed_fields, '{}'), v_user_id, v_user_email, v_ip_address);
  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$function$;

CREATE OR REPLACE FUNCTION public.handle_notification_acknowledged()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  IF OLD.acknowledged_at IS NOT NULL OR NEW.acknowledged_at IS NULL THEN
    RETURN NEW;
  END IF;
  UPDATE public.active_escalations
  SET is_active = false, resolved_at = now(), resolved_by = auth.uid(), resolution_type = 'acknowledged'
  WHERE notification_id = NEW.id AND is_active = true;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.log_auth_event(
  p_event_type auth_event_type_enum,
  p_user_id uuid DEFAULT NULL,
  p_user_email text DEFAULT NULL,
  p_provider text DEFAULT NULL,
  p_session_id text DEFAULT NULL,
  p_success boolean DEFAULT true,
  p_failure_reason text DEFAULT NULL,
  p_ip_address text DEFAULT NULL,
  p_user_agent text DEFAULT NULL,
  p_metadata jsonb DEFAULT NULL
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_org_id   uuid;
  v_event_id uuid;
  v_uid      uuid;
BEGIN
  v_uid := COALESCE(p_user_id, auth.uid());
  IF v_uid IS NOT NULL THEN
    SELECT organisation_id INTO v_org_id FROM public.user_profiles WHERE id = v_uid;
  END IF;
  INSERT INTO public.auth_events (organisation_id, user_id, user_email, event_type, provider, session_id, ip_address, user_agent, success, failure_reason, metadata)
  VALUES (v_org_id, v_uid, COALESCE(p_user_email, (SELECT email FROM auth.users WHERE id = v_uid)), p_event_type, p_provider, p_session_id, p_ip_address, p_user_agent, p_success, p_failure_reason, p_metadata)
  RETURNING id INTO v_event_id;
  RETURN v_event_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.record_user_session(
  p_supabase_session_id text,
  p_provider text DEFAULT 'email',
  p_ip_address text DEFAULT NULL,
  p_user_agent text DEFAULT NULL,
  p_expires_in_days integer DEFAULT 7
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_session_id uuid;
  v_org_id     uuid;
BEGIN
  SELECT organisation_id INTO v_org_id FROM public.user_profiles WHERE id = auth.uid();
  INSERT INTO public.user_sessions (user_id, organisation_id, supabase_session_id, provider, ip_address, user_agent, expires_at)
  VALUES (auth.uid(), v_org_id, p_supabase_session_id, p_provider, p_ip_address, p_user_agent, now() + (p_expires_in_days || ' days')::interval)
  RETURNING id INTO v_session_id;
  RETURN v_session_id;
END;
$function$;
