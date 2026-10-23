ALTER TABLE documents ADD COLUMN IF NOT EXISTS version text DEFAULT '1.0';

-- Update sync trigger to also keep version → current_version in sync
CREATE OR REPLACE FUNCTION sync_documents_columns()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.title IS NOT NULL AND (NEW.name IS NULL OR NEW.name = '') THEN
    NEW.name := NEW.title;
  END IF;
  IF NEW.name IS NOT NULL AND (NEW.title IS NULL OR NEW.title = '') THEN
    NEW.title := NEW.name;
  END IF;
  IF NEW.file_url IS NOT NULL AND (NEW.storage_path IS NULL OR NEW.storage_path = '') THEN
    NEW.storage_path := NEW.file_url;
  END IF;
  IF NEW.file_size_bytes IS NOT NULL AND NEW.file_size IS NULL THEN
    NEW.file_size := NEW.file_size_bytes;
  END IF;
  IF NEW.file_mime_type IS NOT NULL AND (NEW.mime_type IS NULL OR NEW.mime_type = '') THEN
    NEW.mime_type := NEW.file_mime_type;
  END IF;
  IF NEW.version IS NOT NULL AND NEW.current_version IS NOT NULL THEN
    NEW.current_version := 1;
  END IF;
  RETURN NEW;
END;
$$;
