-- =============================================================
-- MODULE 19: Triggers & Functions — LOTO Procedures
-- =============================================================

CREATE TRIGGER trg_loto_proc_updated_at
  BEFORE UPDATE ON loto_procedures
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION generate_loto_procedure_number()
RETURNS TRIGGER AS $$
DECLARE
  v_counter INT;
BEGIN
  INSERT INTO reference_counters (organisation_id, sequence_key, last_value)
  VALUES (NEW.organisation_id, 'LOTO', 1)
  ON CONFLICT (organisation_id, sequence_key)
  DO UPDATE SET last_value = reference_counters.last_value + 1
  RETURNING last_value INTO v_counter;

  NEW.procedure_number := 'LOTO-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(v_counter::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_loto_proc_number
  BEFORE INSERT ON loto_procedures
  FOR EACH ROW
  WHEN (NEW.procedure_number IS NULL)
  EXECUTE FUNCTION generate_loto_procedure_number();

CREATE OR REPLACE FUNCTION generate_loto_authorization_number()
RETURNS TRIGGER AS $$
DECLARE
  v_counter INT;
BEGIN
  INSERT INTO reference_counters (organisation_id, sequence_key, last_value)
  VALUES (NEW.organisation_id, 'LAUTH', 1)
  ON CONFLICT (organisation_id, sequence_key)
  DO UPDATE SET last_value = reference_counters.last_value + 1
  RETURNING last_value INTO v_counter;

  NEW.authorization_number := 'LAUTH-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(v_counter::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_loto_auth_number
  BEFORE INSERT ON loto_authorizations
  FOR EACH ROW
  WHEN (NEW.authorization_number IS NULL)
  EXECUTE FUNCTION generate_loto_authorization_number();
