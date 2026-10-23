-- Make name nullable since the app uses 'title' as the primary text field
ALTER TABLE documents ALTER COLUMN name DROP NOT NULL;

-- Also make storage_path nullable since app uses file_url
ALTER TABLE documents ALTER COLUMN storage_path DROP NOT NULL;

-- Add a trigger that keeps name ↔ title and storage_path ↔ file_url in sync
CREATE OR REPLACE FUNCTION sync_documents_columns()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- Sync title → name
  IF NEW.title IS NOT NULL AND (NEW.name IS NULL OR NEW.name = '') THEN
    NEW.name := NEW.title;
  END IF;
  -- Sync name → title
  IF NEW.name IS NOT NULL AND (NEW.title IS NULL OR NEW.title = '') THEN
    NEW.title := NEW.name;
  END IF;
  -- Sync file_url → storage_path
  IF NEW.file_url IS NOT NULL AND (NEW.storage_path IS NULL OR NEW.storage_path = '') THEN
    NEW.storage_path := NEW.file_url;
  END IF;
  -- Sync file_size_bytes → file_size
  IF NEW.file_size_bytes IS NOT NULL AND NEW.file_size IS NULL THEN
    NEW.file_size := NEW.file_size_bytes;
  END IF;
  -- Sync file_mime_type → mime_type
  IF NEW.file_mime_type IS NOT NULL AND (NEW.mime_type IS NULL OR NEW.mime_type = '') THEN
    NEW.mime_type := NEW.file_mime_type;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sync_documents_columns
  BEFORE INSERT OR UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION sync_documents_columns();
