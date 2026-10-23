ALTER TABLE hr_document_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "hrdt_select" ON hr_document_templates
  FOR SELECT USING (
    organisation_id IS NULL
    OR organisation_id = get_my_organisation_id()
  );

CREATE POLICY "hrdt_insert" ON hr_document_templates
  FOR INSERT WITH CHECK (
    organisation_id = get_my_organisation_id()
    AND (is_system_admin() OR is_hse_officer())
  );

CREATE POLICY "hrdt_update" ON hr_document_templates
  FOR UPDATE USING (
    organisation_id = get_my_organisation_id()
    AND (is_system_admin() OR is_hse_officer())
  );

CREATE POLICY "hrdt_delete" ON hr_document_templates
  FOR DELETE USING (
    organisation_id = get_my_organisation_id()
    AND is_system_admin()
  );
