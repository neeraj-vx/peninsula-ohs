-- =============================================================
-- D24 (urgent): queue_webhook_deliveries (AFTER INSERT ON
-- notifications) read NEW.event_type / entity_type / entity_id /
-- site_id, none of which exist on notifications. Every notification
-- insert raised 42703. Before default rules were seeded no
-- notification was ever inserted, so this never surfaced.
-- =============================================================

CREATE OR REPLACE FUNCTION public.queue_webhook_deliveries()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Notifications fan out per recipient; queue one delivery per
  -- (endpoint, event, entity) rather than one per recipient
  IF EXISTS (
    SELECT 1 FROM webhook_deliveries wd
    WHERE wd.organisation_id = NEW.organisation_id
      AND wd.event_type_code = NEW.trigger_event
      AND wd.source_id IS NOT DISTINCT FROM NEW.trigger_entity_id
      AND wd.created_at > now() - INTERVAL '1 minute'
  ) THEN
    RETURN NEW;
  END IF;

  INSERT INTO webhook_deliveries (
    endpoint_id, organisation_id, event_type_code,
    notification_id, source_type, source_id, payload, status
  )
  SELECT
    e.id,
    NEW.organisation_id,
    NEW.trigger_event,
    NEW.id,
    NEW.trigger_entity_type,
    NEW.trigger_entity_id,
    jsonb_build_object(
      'event',           NEW.trigger_event,
      'organisation_id', NEW.organisation_id,
      'site_id',         NEW.data->>'site_id',
      'entity_type',     NEW.trigger_entity_type,
      'entity_id',       NEW.trigger_entity_id,
      'data',            NEW.data,
      'created_at',      NEW.created_at
    ),
    'pending'
  FROM webhook_endpoints e
  JOIN webhook_endpoint_subscriptions wes ON wes.endpoint_id = e.id
  JOIN webhook_event_types wet ON wet.id = wes.event_type_id
  WHERE e.organisation_id = NEW.organisation_id
    AND e.is_active   = true
    AND wes.is_active = true
    AND wet.code      = NEW.trigger_event;

  RETURN NEW;
END;
$$;
