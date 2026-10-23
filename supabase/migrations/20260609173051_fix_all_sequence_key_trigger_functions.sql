-- Fix all sequence_key-style counter functions to use the 4-column PK
-- (entity_type='', year=0, organisation_id, sequence_key=<PREFIX>)

CREATE OR REPLACE FUNCTION generate_jsa_number()
RETURNS TRIGGER AS $$
DECLARE v_counter INT;
BEGIN
  INSERT INTO reference_counters (entity_type, organisation_id, year, sequence_key, last_value)
  VALUES ('', NEW.organisation_id, 0, 'JSA', 1)
  ON CONFLICT (entity_type, organisation_id, year, sequence_key)
  DO UPDATE SET last_value = reference_counters.last_value + 1
  RETURNING last_value INTO v_counter;
  NEW.jsa_number := 'JSA-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(v_counter::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_loto_procedure_number()
RETURNS TRIGGER AS $$
DECLARE v_counter INT;
BEGIN
  INSERT INTO reference_counters (entity_type, organisation_id, year, sequence_key, last_value)
  VALUES ('', NEW.organisation_id, 0, 'LOTO', 1)
  ON CONFLICT (entity_type, organisation_id, year, sequence_key)
  DO UPDATE SET last_value = reference_counters.last_value + 1
  RETURNING last_value INTO v_counter;
  NEW.procedure_number := 'LOTO-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(v_counter::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_loto_authorization_number()
RETURNS TRIGGER AS $$
DECLARE v_counter INT;
BEGIN
  INSERT INTO reference_counters (entity_type, organisation_id, year, sequence_key, last_value)
  VALUES ('', NEW.organisation_id, 0, 'LAUTH', 1)
  ON CONFLICT (entity_type, organisation_id, year, sequence_key)
  DO UPDATE SET last_value = reference_counters.last_value + 1
  RETURNING last_value INTO v_counter;
  NEW.authorization_number := 'LAUTH-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(v_counter::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_speak_up_report_number()
RETURNS TRIGGER AS $$
DECLARE v_counter INT;
BEGIN
  INSERT INTO reference_counters (entity_type, organisation_id, year, sequence_key, last_value)
  VALUES ('', NEW.organisation_id, 0, 'SPK', 1)
  ON CONFLICT (entity_type, organisation_id, year, sequence_key)
  DO UPDATE SET last_value = reference_counters.last_value + 1
  RETURNING last_value INTO v_counter;
  NEW.report_number := 'SPK-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(v_counter::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_compliance_task_number()
RETURNS TRIGGER AS $$
DECLARE v_counter INT;
BEGIN
  INSERT INTO reference_counters (entity_type, organisation_id, year, sequence_key, last_value)
  VALUES ('', NEW.organisation_id, 0, 'COMP', 1)
  ON CONFLICT (entity_type, organisation_id, year, sequence_key)
  DO UPDATE SET last_value = reference_counters.last_value + 1
  RETURNING last_value INTO v_counter;
  NEW.task_number := 'COMP-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(v_counter::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_drill_number()
RETURNS TRIGGER AS $$
DECLARE v_counter INT;
BEGIN
  INSERT INTO reference_counters (entity_type, organisation_id, year, sequence_key, last_value)
  VALUES ('', NEW.organisation_id, 0, 'DRL', 1)
  ON CONFLICT (entity_type, organisation_id, year, sequence_key)
  DO UPDATE SET last_value = reference_counters.last_value + 1
  RETURNING last_value INTO v_counter;
  NEW.drill_number := 'DRL-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(v_counter::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_plan_number()
RETURNS TRIGGER AS $$
DECLARE v_counter INT;
BEGIN
  INSERT INTO reference_counters (entity_type, organisation_id, year, sequence_key, last_value)
  VALUES ('', NEW.organisation_id, 0, 'ERP', 1)
  ON CONFLICT (entity_type, organisation_id, year, sequence_key)
  DO UPDATE SET last_value = reference_counters.last_value + 1
  RETURNING last_value INTO v_counter;
  NEW.plan_number := 'ERP-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(v_counter::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_delivery_number()
RETURNS TRIGGER AS $$
DECLARE v_counter INT;
BEGIN
  INSERT INTO reference_counters (entity_type, organisation_id, year, sequence_key, last_value)
  VALUES ('', NEW.organisation_id, 0, 'TBX', 1)
  ON CONFLICT (entity_type, organisation_id, year, sequence_key)
  DO UPDATE SET last_value = reference_counters.last_value + 1
  RETURNING last_value INTO v_counter;
  NEW.delivery_number := 'TBX-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(v_counter::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_training_number()
RETURNS TRIGGER AS $$
DECLARE v_counter INT;
BEGIN
  INSERT INTO reference_counters (entity_type, organisation_id, year, sequence_key, last_value)
  VALUES ('', NEW.organisation_id, 0, 'TRN', 1)
  ON CONFLICT (entity_type, organisation_id, year, sequence_key)
  DO UPDATE SET last_value = reference_counters.last_value + 1
  RETURNING last_value INTO v_counter;
  NEW.record_number := 'TRN-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(v_counter::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
