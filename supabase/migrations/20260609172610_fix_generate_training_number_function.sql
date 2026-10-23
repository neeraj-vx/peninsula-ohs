CREATE OR REPLACE FUNCTION generate_training_number()
RETURNS TRIGGER AS $$
DECLARE v_counter INT;
BEGIN
  INSERT INTO reference_counters(entity_type, organisation_id, year, sequence_key, last_value)
  VALUES('', NEW.organisation_id, 0, 'TRN', 1)
  ON CONFLICT(entity_type, organisation_id, year, sequence_key)
  DO UPDATE SET last_value = reference_counters.last_value + 1
  RETURNING last_value INTO v_counter;
  NEW.record_number := 'TRN-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(v_counter::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
