-- audit_trigger_function records NEW.id; rule_org_settings had only a
-- composite key, so every insert failed. Give it a surrogate id.
ALTER TABLE public.rule_org_settings
  ADD COLUMN id uuid NOT NULL DEFAULT gen_random_uuid() UNIQUE;
