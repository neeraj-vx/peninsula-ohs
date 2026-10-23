-- Add columns the app action code expects that don't exist in the original schema
ALTER TABLE documents
  ADD COLUMN IF NOT EXISTS title            text,
  ADD COLUMN IF NOT EXISTS file_url         text,
  ADD COLUMN IF NOT EXISTS file_size_bytes  bigint,
  ADD COLUMN IF NOT EXISTS file_mime_type   text,
  ADD COLUMN IF NOT EXISTS version_number   text DEFAULT '1.0',
  ADD COLUMN IF NOT EXISTS owner_id         uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS applicable_provinces text[],
  ADD COLUMN IF NOT EXISTS expiry_date      date;

-- Backfill title from name for any existing rows
UPDATE documents SET title = name WHERE title IS NULL AND name IS NOT NULL;

-- Backfill the reverse too: name from title if name is somehow null
UPDATE documents SET name = title WHERE name IS NULL AND title IS NOT NULL;

-- Sync storage_path ↔ file_url and size/mime columns for existing rows
UPDATE documents SET file_url        = storage_path  WHERE file_url IS NULL AND storage_path IS NOT NULL;
UPDATE documents SET file_size_bytes = file_size      WHERE file_size_bytes IS NULL AND file_size IS NOT NULL;
UPDATE documents SET file_mime_type  = mime_type      WHERE file_mime_type IS NULL AND mime_type IS NOT NULL;
