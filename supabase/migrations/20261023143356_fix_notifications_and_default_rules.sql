-- =============================================================
-- D23: create_notification inserted into notifications.recipient_id
--      (column is recipient_user_id) and used an 'all_org_users'
--      recipient type the check constraint rejects. It also ignored
--      rule.channels and cooldown_minutes, and any caller could
--      target any organisation.
-- D7:  no notification_rules existed, so nothing was ever delivered.
--      Every organisation now gets one in-app rule per system
--      template event, sent to HSE Officer + System Admin plus the
--      event's subject when the caller passes data.reporter_id.
-- =============================================================

CREATE OR REPLACE FUNCTION public.create_notification(
  p_trigger_event       text,
  p_organisation_id     uuid,
  p_site_id             uuid  DEFAULT NULL,
  p_trigger_entity_type text  DEFAULT NULL,
  p_trigger_entity_id   uuid  DEFAULT NULL,
  p_data                jsonb DEFAULT '{}'
) RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rule          record;
  v_template      record;
  v_recipient_id  uuid;
  v_title         text;
  v_body          text;
  v_created_count integer := 0;
  v_data          jsonb := COALESCE(p_data, '{}');
  v_site_name     text;
  v_reporter_id   uuid;
BEGIN
  -- Users may only raise notifications inside their own organisation
  IF auth.uid() IS NOT NULL AND p_organisation_id IS DISTINCT FROM get_my_organisation_id() THEN
    RAISE EXCEPTION 'create_notification: organisation mismatch' USING ERRCODE = '42501';
  END IF;

  IF p_site_id IS NOT NULL AND v_data->>'site_name' IS NULL THEN
    SELECT s.name INTO v_site_name FROM sites s WHERE s.id = p_site_id;
    v_data := v_data || jsonb_build_object('site_name', COALESCE(v_site_name, ''));
  END IF;

  IF v_data->>'reporter_id' ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    v_reporter_id := (v_data->>'reporter_id')::uuid;
  END IF;

  FOR v_rule IN
    SELECT nr.*
    FROM notification_rules nr
    WHERE nr.organisation_id = p_organisation_id
      AND nr.trigger_event   = p_trigger_event
      AND nr.is_active       = true
  LOOP
    SELECT * INTO v_template
    FROM notification_templates
    WHERE id = v_rule.template_id
      AND trigger_event = p_trigger_event
      AND (organisation_id = p_organisation_id OR organisation_id IS NULL)
      AND is_active = true;

    IF NOT FOUND THEN CONTINUE; END IF;

    v_title := render_template(v_template.subject_template, v_data);
    v_body  := render_template(v_template.body_template,    v_data);

    FOR v_recipient_id IN
      SELECT nrr.user_id
      FROM notification_rule_recipients nrr
      WHERE nrr.rule_id = v_rule.id AND nrr.recipient_type = 'user' AND nrr.user_id IS NOT NULL
      UNION
      SELECT ur.user_id
      FROM notification_rule_recipients nrr
      JOIN user_roles ur ON ur.role_id = nrr.role_id
                        AND ur.organisation_id = p_organisation_id
                        AND ur.is_active = true
                        AND (ur.expires_at IS NULL OR ur.expires_at > now())
      WHERE nrr.rule_id = v_rule.id AND nrr.recipient_type = 'role' AND nrr.role_id IS NOT NULL
        AND (NOT nrr.site_scoped OR p_site_id IS NULL OR ur.site_id IS NULL OR ur.site_id = p_site_id)
      UNION
      SELECT up.id
      FROM notification_rule_recipients nrr
      JOIN user_profiles up ON up.id = v_reporter_id AND up.organisation_id = p_organisation_id
      WHERE nrr.rule_id = v_rule.id AND nrr.recipient_type = 'reporter'
    LOOP
      -- cooldown: one notification per rule/entity/recipient inside the window
      IF v_rule.cooldown_minutes > 0 AND EXISTS (
        SELECT 1 FROM notifications n
        WHERE n.rule_id = v_rule.id
          AND n.recipient_user_id = v_recipient_id
          AND n.trigger_entity_id IS NOT DISTINCT FROM p_trigger_entity_id
          AND n.created_at > now() - make_interval(mins => v_rule.cooldown_minutes)
      ) THEN
        CONTINUE;
      END IF;

      INSERT INTO notifications (
        organisation_id, recipient_user_id, trigger_event,
        trigger_entity_type, trigger_entity_id,
        title, body, data,
        rule_id, template_id, channels_requested
      ) VALUES (
        p_organisation_id, v_recipient_id, p_trigger_event,
        p_trigger_entity_type, p_trigger_entity_id,
        v_title, v_body, v_data,
        v_rule.id, v_template.id, v_rule.channels
      );
      v_created_count := v_created_count + 1;
    END LOOP;
  END LOOP;

  RETURN v_created_count;
END;
$$;

-- One rule per system template event that the org doesn't already cover
CREATE OR REPLACE FUNCTION public.seed_default_notification_rules(p_organisation_id uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tpl     record;
  v_rule_id uuid;
  v_count   integer := 0;
BEGIN
  FOR v_tpl IN
    SELECT DISTINCT ON (t.trigger_event) t.id, t.trigger_event, t.name
    FROM notification_templates t
    WHERE t.organisation_id IS NULL AND t.is_active = true
      AND NOT EXISTS (
        SELECT 1 FROM notification_rules r
        WHERE r.organisation_id = p_organisation_id AND r.trigger_event = t.trigger_event)
    ORDER BY t.trigger_event, t.created_at
  LOOP
    INSERT INTO notification_rules (organisation_id, name, description, trigger_event, template_id, channels, cooldown_minutes)
    VALUES (p_organisation_id, v_tpl.name, 'Default rule', v_tpl.trigger_event, v_tpl.id,
            ARRAY['in_app']::notification_channel_enum[], 0)
    RETURNING id INTO v_rule_id;

    INSERT INTO notification_rule_recipients (rule_id, recipient_type, role_id, site_scoped)
    SELECT v_rule_id, 'role', r.id, false
    FROM roles r
    WHERE r.is_system_role AND r.name IN ('HSE Officer', 'System Admin');

    INSERT INTO notification_rule_recipients (rule_id, recipient_type, site_scoped)
    VALUES (v_rule_id, 'reporter', false);

    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.seed_default_notification_rules_on_org()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM seed_default_notification_rules(NEW.id);
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_seed_default_notification_rules
  AFTER INSERT ON organisations
  FOR EACH ROW EXECUTE FUNCTION seed_default_notification_rules_on_org();

SELECT seed_default_notification_rules(id) FROM organisations;

REVOKE EXECUTE ON FUNCTION public.seed_default_notification_rules(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.seed_default_notification_rules_on_org() FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.seed_default_notification_rules(uuid) TO service_role;
REVOKE EXECUTE ON FUNCTION public.create_notification(text, uuid, uuid, text, uuid, jsonb) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.create_notification(text, uuid, uuid, text, uuid, jsonb) TO authenticated, service_role;
