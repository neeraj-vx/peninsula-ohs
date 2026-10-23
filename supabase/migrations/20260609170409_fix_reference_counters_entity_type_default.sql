-- Allow entity_type to be empty for the new sequence_key-based rows
ALTER TABLE reference_counters ALTER COLUMN entity_type SET DEFAULT '';
ALTER TABLE reference_counters ALTER COLUMN year SET DEFAULT 0;
