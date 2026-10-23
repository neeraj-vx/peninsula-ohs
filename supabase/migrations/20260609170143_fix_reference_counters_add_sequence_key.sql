-- Add the sequence_key / last_value columns used by module 18-25 triggers
ALTER TABLE reference_counters
  ADD COLUMN IF NOT EXISTS sequence_key text,
  ADD COLUMN IF NOT EXISTS last_value   integer NOT NULL DEFAULT 0;

-- Unique constraint the triggers rely on for ON CONFLICT
CREATE UNIQUE INDEX IF NOT EXISTS idx_rc_org_seq
  ON reference_counters (organisation_id, sequence_key)
  WHERE sequence_key IS NOT NULL;
