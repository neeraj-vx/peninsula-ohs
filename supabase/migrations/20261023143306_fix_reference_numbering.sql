-- =============================================================
-- D1 residual + D13 + RLS prerequisite
-- * One SECURITY DEFINER counter helper. The generators run as the
--   inserting user, and reference_counters has no policies, so with
--   RLS enabled every TRN/JSA/TBX/... insert failed.
-- * Sequence-key counters now reset per year (the numbers already
--   print the year). The current year inherits the old year-0 count.
-- * HIR / BGC numbers move off MAX+1 / COUNT+1 (race-prone) onto
--   perpetual counters seeded from existing numbers.
-- =============================================================

CREATE OR REPLACE FUNCTION public.next_sequence_value(
  p_organisation_id uuid,
  p_sequence_key    text,
  p_per_year        boolean DEFAULT true
) RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_year integer := CASE WHEN p_per_year THEN EXTRACT(YEAR FROM now())::integer ELSE 0 END;
  v_next integer;
BEGIN
  INSERT INTO reference_counters (entity_type, organisation_id, year, sequence_key, last_value)
  VALUES ('', p_organisation_id, v_year, p_sequence_key, 1)
  ON CONFLICT (entity_type, organisation_id, year, sequence_key)
  DO UPDATE SET last_value = reference_counters.last_value + 1
  RETURNING last_value INTO v_next;
  RETURN v_next;
END;
$$;

CREATE OR REPLACE FUNCTION public.next_reference_number(p_entity_type text, p_organisation_id uuid, p_prefix text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_year integer := EXTRACT(YEAR FROM now())::integer;
  v_num  integer;
BEGIN
  INSERT INTO reference_counters (entity_type, organisation_id, year, sequence_key, last_number)
  VALUES (p_entity_type, p_organisation_id, v_year, '', 1)
  ON CONFLICT (entity_type, organisation_id, year, sequence_key)
  DO UPDATE SET last_number = reference_counters.last_number + 1
  RETURNING last_number INTO v_num;

  RETURN p_prefix || '-' || v_year || '-' || LPAD(v_num::text, 5, '0');
END;
$$;

-- Carry the year-0 sequence counts into the current year
INSERT INTO reference_counters (entity_type, organisation_id, year, sequence_key, last_value)
SELECT '', organisation_id, EXTRACT(YEAR FROM now())::integer, sequence_key, last_value
FROM reference_counters
WHERE entity_type = '' AND year = 0 AND sequence_key <> ''
ON CONFLICT (entity_type, organisation_id, year, sequence_key)
DO UPDATE SET last_value = GREATEST(reference_counters.last_value, EXCLUDED.last_value);

-- Seed perpetual HIR / BGC counters from the numbers already issued
INSERT INTO reference_counters (entity_type, organisation_id, year, sequence_key, last_value)
SELECT '', organisation_id, 0, 'HIR', MAX(SUBSTRING(hire_number FROM 5)::integer)
FROM hires WHERE hire_number ~ '^HIR-[0-9]+$'
GROUP BY organisation_id
ON CONFLICT (entity_type, organisation_id, year, sequence_key)
DO UPDATE SET last_value = GREATEST(reference_counters.last_value, EXCLUDED.last_value);

INSERT INTO reference_counters (entity_type, organisation_id, year, sequence_key, last_value)
SELECT '', organisation_id, 0, 'BGC', MAX(SUBSTRING(package_number FROM 5)::integer)
FROM bgc_packages WHERE package_number ~ '^BGC-[0-9]+$'
GROUP BY organisation_id
ON CONFLICT (entity_type, organisation_id, year, sequence_key)
DO UPDATE SET last_value = GREATEST(reference_counters.last_value, EXCLUDED.last_value);

-- Generators: <PREFIX>-<YYYY>-<00000>, only when no number was supplied
CREATE OR REPLACE FUNCTION public.generate_compliance_task_number() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.task_number IS NULL THEN
    NEW.task_number := 'COMP-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(next_sequence_value(NEW.organisation_id, 'COMP')::text, 5, '0');
  END IF;
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.generate_delivery_number() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.delivery_number IS NULL THEN
    NEW.delivery_number := 'TBX-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(next_sequence_value(NEW.organisation_id, 'TBX')::text, 5, '0');
  END IF;
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.generate_drill_number() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.drill_number IS NULL THEN
    NEW.drill_number := 'DRL-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(next_sequence_value(NEW.organisation_id, 'DRL')::text, 5, '0');
  END IF;
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.generate_jsa_number() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.jsa_number IS NULL THEN
    NEW.jsa_number := 'JSA-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(next_sequence_value(NEW.organisation_id, 'JSA')::text, 5, '0');
  END IF;
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.generate_loto_authorization_number() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.authorization_number IS NULL THEN
    NEW.authorization_number := 'LAUTH-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(next_sequence_value(NEW.organisation_id, 'LAUTH')::text, 5, '0');
  END IF;
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.generate_loto_number() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.procedure_number IS NULL THEN
    NEW.procedure_number := 'LOTO-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(next_sequence_value(NEW.organisation_id, 'LOTO')::text, 5, '0');
  END IF;
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.generate_loto_procedure_number() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.procedure_number IS NULL THEN
    NEW.procedure_number := 'LOTO-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(next_sequence_value(NEW.organisation_id, 'LOTO')::text, 5, '0');
  END IF;
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.generate_plan_number() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.plan_number IS NULL THEN
    NEW.plan_number := 'ERP-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(next_sequence_value(NEW.organisation_id, 'ERP')::text, 5, '0');
  END IF;
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.generate_speak_up_number() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.report_number IS NULL THEN
    NEW.report_number := 'SPK-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(next_sequence_value(NEW.organisation_id, 'SPK')::text, 5, '0');
  END IF;
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.generate_speak_up_report_number() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.report_number IS NULL THEN
    NEW.report_number := 'SPK-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(next_sequence_value(NEW.organisation_id, 'SPK')::text, 5, '0');
  END IF;
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.generate_training_number() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.record_number IS NULL THEN
    NEW.record_number := 'TRN-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(next_sequence_value(NEW.organisation_id, 'TRN')::text, 5, '0');
  END IF;
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.generate_training_record_number() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.record_number IS NULL THEN
    NEW.record_number := 'TRN-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(next_sequence_value(NEW.organisation_id, 'TRN')::text, 5, '0');
  END IF;
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.generate_hire_number() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.hire_number IS NULL THEN
    NEW.hire_number := 'HIR-' || LPAD(next_sequence_value(NEW.organisation_id, 'HIR', false)::text, 4, '0');
  END IF;
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.generate_bgc_package_number() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.package_number IS NULL THEN
    NEW.package_number := 'BGC-' || LPAD(next_sequence_value(NEW.organisation_id, 'BGC', false)::text, 4, '0');
  END IF;
  RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.generate_document_number() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.document_number IS NULL THEN
    NEW.document_number := next_reference_number('document', NEW.organisation_id, 'DOC');
  END IF;
  RETURN NEW;
END $$;

-- Maintains documents.current_version for whoever inserts a version
CREATE OR REPLACE FUNCTION public.sync_document_current_version() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  UPDATE documents
  SET current_version = NEW.version_number,
      updated_at      = now()
  WHERE id = NEW.document_id
    AND NEW.version_number > current_version;
  RETURN NEW;
END $$;

REVOKE EXECUTE ON FUNCTION public.next_sequence_value(uuid, text, boolean) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.next_sequence_value(uuid, text, boolean) TO authenticated, service_role;
