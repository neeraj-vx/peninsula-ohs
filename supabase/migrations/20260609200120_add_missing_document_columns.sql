-- documents: add document_number (auto-generated reference)
ALTER TABLE documents ADD COLUMN IF NOT EXISTS document_number text UNIQUE;

-- document_versions: page queries change_summary but schema has change_notes; add alias + version_number as text
ALTER TABLE document_versions ADD COLUMN IF NOT EXISTS change_summary text;
ALTER TABLE document_versions ADD COLUMN IF NOT EXISTS organisation_id uuid REFERENCES organisations(id);

-- document_acknowledgements: add signer fields used by the AcknowledgementPanel
ALTER TABLE document_acknowledgements
  ADD COLUMN IF NOT EXISTS signer_name       text,
  ADD COLUMN IF NOT EXISTS signature_image_url text;

-- Auto-generate document_number on insert (DOC-YYYY-NNNNN)
CREATE OR REPLACE FUNCTION generate_document_number()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_num integer;
BEGIN
  IF NEW.document_number IS NULL THEN
    INSERT INTO reference_counters (entity_type, organisation_id, year, sequence_key, last_number)
    VALUES ('document', NEW.organisation_id, EXTRACT(YEAR FROM now())::int, '', 1)
    ON CONFLICT (entity_type, organisation_id, year, sequence_key)
    DO UPDATE SET last_number = reference_counters.last_number + 1
    RETURNING last_number INTO v_num;
    NEW.document_number := 'DOC-' || to_char(now(), 'YYYY') || '-' || LPAD(v_num::text, 5, '0');
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_document_number
  BEFORE INSERT ON documents
  FOR EACH ROW EXECUTE FUNCTION generate_document_number();
