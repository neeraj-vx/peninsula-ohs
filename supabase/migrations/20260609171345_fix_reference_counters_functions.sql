-- Fix next_reference_number() to use the updated 4-column PK
CREATE OR REPLACE FUNCTION next_reference_number(
  p_entity_type     text,
  p_organisation_id uuid,
  p_prefix          text
) RETURNS text LANGUAGE plpgsql AS $$
DECLARE
  v_year   integer := EXTRACT(YEAR FROM now())::integer;
  v_num    integer;
BEGIN
  INSERT INTO reference_counters (entity_type, organisation_id, year, sequence_key, last_number)
  VALUES (p_entity_type, p_organisation_id, v_year, '', 1)
  ON CONFLICT (entity_type, organisation_id, year, sequence_key)
  DO UPDATE SET last_number = reference_counters.last_number + 1
  RETURNING last_number INTO v_num;

  RETURN p_prefix || '-' || v_year || '-' || LPAD(v_num::text, 5, '0');
END;
$$;

-- Ensure the unique constraint for new-style (organisation_id, sequence_key) triggers still exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'uq_rc_org_seq'
  ) THEN
    ALTER TABLE reference_counters
      ADD CONSTRAINT uq_rc_org_seq UNIQUE (organisation_id, sequence_key);
  END IF;
END $$;
