-- Replace partial index with a proper unique constraint usable by ON CONFLICT
DROP INDEX IF EXISTS idx_rc_org_seq;

-- Set a default so existing rows (which have sequence_key = NULL) don't block the constraint
-- We'll use empty string as the "legacy" sentinel for old rows
UPDATE reference_counters SET sequence_key = '' WHERE sequence_key IS NULL;
ALTER TABLE reference_counters ALTER COLUMN sequence_key SET DEFAULT '';
ALTER TABLE reference_counters ALTER COLUMN sequence_key SET NOT NULL;

ALTER TABLE reference_counters
  ADD CONSTRAINT uq_rc_org_seq UNIQUE (organisation_id, sequence_key);
