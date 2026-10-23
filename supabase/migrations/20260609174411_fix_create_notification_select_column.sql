-- Fix: the subquery column is aliased 'jval' but the SELECT targets 'name'
CREATE OR REPLACE FUNCTION create_notification(
  p_trigger_event       text,
  p_organisation_id     uuid,
  p_site_id             uuid    DEFAULT NULL,
  p_trigger_entity_type text    DEFAULT NULL,
  p_trigger_entity_id   uuid    DEFAULT NULL,
  p_data                jsonb   DEFAULT '{}'
) RETURNS integer LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_rule          record;
  v_template      record;
  v_recipient_id  uuid;
  v_title         text;
  v_body          text;
  v_created_count integer := 0;
  v_data          jsonb;
  v_site_name     text;
BEGIN
  v_data := p_data;
  -- Enrich with site name if not already provided
  IF p_site_id IS NOT NULL AND v_data->>'site_name' IS NULL THEN
    SELECT s.name INTO v_site_name FROM sites s WHERE s.id = p_site_id;
    v_data := v_data || jsonb_build_object('site_name', COALESCE(v_site_name, ''));
  END IF;

  FOR v_rule IN
    SELECT nr.*, ec.is_active AS chain_active
    FROM notification_rules nr
    LEFT JOIN escalation_chains ec ON ec.id = nr.escalation_chain_id
    WHERE nr.organisation_id = p_organisation_id
      AND nr.trigger_event   = p_trigger_event
      AND nr.is_active       = true
  LOOP
    SELECT * INTO v_template
    FROM notification_templates
    WHERE trigger_event = p_trigger_event
      AND (organisation_id = p_organisation_id OR organisation_id IS NULL)
      AND id = v_rule.template_id
      AND is_active = true
    ORDER BY organisation_id NULLS LAST
    LIMIT 1;

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
        AND (NOT nrr.site_scoped OR p_site_id IS NULL OR ur.site_id = p_site_id)
      UNION
      SELECT up.id
      FROM notification_rule_recipients nrr
      JOIN user_profiles up ON up.organisation_id = p_organisation_id AND up.is_active = true
      WHERE nrr.rule_id = v_rule.id AND nrr.recipient_type = 'all_org_users'
    LOOP
      INSERT INTO notifications (
        organisation_id, recipient_id, trigger_event,
        trigger_entity_type, trigger_entity_id,
        title, body, data,
        rule_id, template_id
      ) VALUES (
        p_organisation_id, v_recipient_id, p_trigger_event,
        p_trigger_entity_type, p_trigger_entity_id,
        v_title, v_body, v_data,
        v_rule.id, v_template.id
      );
      v_created_count := v_created_count + 1;
    END LOOP;
  END LOOP;

  RETURN v_created_count;
END;
$$;
