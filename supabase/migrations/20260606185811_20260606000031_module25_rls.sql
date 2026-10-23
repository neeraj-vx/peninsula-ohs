-- MODULE 25: Row Level Security — Mental Health & Wellbeing

ALTER TABLE wellbeing_resources  ENABLE ROW LEVEL SECURITY;
ALTER TABLE wellbeing_check_ins  ENABLE ROW LEVEL SECURITY;
ALTER TABLE wellbeing_programs   ENABLE ROW LEVEL SECURITY;

CREATE POLICY "wbr_select" ON wellbeing_resources FOR SELECT
  USING (organisation_id = get_my_organisation_id());

CREATE POLICY "wbr_insert" ON wellbeing_resources FOR INSERT
  WITH CHECK (organisation_id = get_my_organisation_id()
    AND (is_hse_officer() OR is_system_admin()));

CREATE POLICY "wbr_update" ON wellbeing_resources FOR UPDATE
  USING (organisation_id = get_my_organisation_id()
    AND (is_hse_officer() OR is_system_admin()));

CREATE POLICY "wbci_insert" ON wellbeing_check_ins FOR INSERT
  WITH CHECK (organisation_id = get_my_organisation_id());

CREATE POLICY "wbci_select" ON wellbeing_check_ins FOR SELECT
  USING (organisation_id = get_my_organisation_id()
    AND (is_hse_officer() OR is_system_admin() OR is_executive()));

CREATE POLICY "wbp_select" ON wellbeing_programs FOR SELECT
  USING (organisation_id = get_my_organisation_id());

CREATE POLICY "wbp_insert" ON wellbeing_programs FOR INSERT
  WITH CHECK (organisation_id = get_my_organisation_id()
    AND (is_hse_officer() OR is_system_admin()));

CREATE POLICY "wbp_update" ON wellbeing_programs FOR UPDATE
  USING (organisation_id = get_my_organisation_id()
    AND (is_hse_officer() OR is_system_admin()));
