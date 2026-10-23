-- The current PK is (entity_type, organisation_id, year).
-- New-style triggers use (organisation_id, sequence_key) — two rows with entity_type='' clash.
-- Fix: include sequence_key in the primary key so each sequence gets its own row.

ALTER TABLE reference_counters DROP CONSTRAINT reference_counters_pkey;

-- entity_type defaults '' and year defaults 0 for new-style rows;
-- old-style rows have their own (entity_type, year) values.
ALTER TABLE reference_counters
  ADD PRIMARY KEY (entity_type, organisation_id, year, sequence_key);
