-- =============================================================
-- MODULE 20: Triggers & Functions — Compliance Calendar
-- =============================================================

CREATE TRIGGER trg_comp_obligations_updated_at
  BEFORE UPDATE ON compliance_obligations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_comp_tasks_updated_at
  BEFORE UPDATE ON compliance_tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION generate_compliance_task_number()
RETURNS TRIGGER AS $$
DECLARE
  v_counter INT;
BEGIN
  INSERT INTO reference_counters (organisation_id, sequence_key, last_value)
  VALUES (NEW.organisation_id, 'COMP', 1)
  ON CONFLICT (organisation_id, sequence_key)
  DO UPDATE SET last_value = reference_counters.last_value + 1
  RETURNING last_value INTO v_counter;

  NEW.task_number := 'COMP-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(v_counter::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_comp_task_number
  BEFORE INSERT ON compliance_tasks
  FOR EACH ROW
  WHEN (NEW.task_number IS NULL)
  EXECUTE FUNCTION generate_compliance_task_number();

CREATE OR REPLACE FUNCTION set_compliance_task_completion()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status <> 'completed' THEN
    IF NEW.completed_at IS NULL THEN
      NEW.completed_at := now();
    END IF;
    IF NEW.completed_by IS NULL THEN
      NEW.completed_by := auth.uid();
    END IF;
  END IF;
  IF OLD.status = 'completed' AND NEW.status <> 'completed' THEN
    NEW.completed_at := NULL;
    NEW.completed_by := NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_comp_task_completion
  BEFORE UPDATE ON compliance_tasks
  FOR EACH ROW EXECUTE FUNCTION set_compliance_task_completion();
