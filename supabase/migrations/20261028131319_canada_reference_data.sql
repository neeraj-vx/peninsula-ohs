-- =============================================================
-- Canada localisation, gap analysis §6 "S" and "R" items.
-- Australian reference rows are deactivated, never deleted, so
-- existing records that point at them keep working.
-- =============================================================

-- Regulators: deactivate Australian bodies, add Canadian ones
UPDATE regulatory_bodies SET is_active = false WHERE jurisdiction LIKE 'AU%' AND is_active;

INSERT INTO regulatory_bodies (name, acronym, jurisdiction, website_url, is_active)
SELECT v.name, v.acronym, v.jurisdiction, v.website_url, true
FROM (VALUES
  ('Employment and Social Development Canada — Labour Program', 'ESDC Labour Program', 'CA', NULL),
  ('Canadian Centre for Occupational Health and Safety', 'CCOHS', 'CA', 'https://www.ccohs.ca'),
  ('CSA Group', 'CSA', 'CA', 'https://www.csagroup.org'),
  ('Ontario Ministry of Labour, Immigration, Training and Skills Development', 'MLITSD', 'CA-ON', NULL),
  ('Workplace Safety and Insurance Board', 'WSIB', 'CA-ON', 'https://www.wsib.ca'),
  ('WorkSafeBC', 'WorkSafeBC', 'CA-BC', 'https://www.worksafebc.com'),
  ('Alberta Occupational Health and Safety', 'Alberta OHS', 'CA-AB', NULL),
  ('Workers'' Compensation Board of Alberta', 'WCB Alberta', 'CA-AB', 'https://www.wcb.ab.ca'),
  ('Commission des normes, de l''équité, de la santé et de la sécurité du travail', 'CNESST', 'CA-QC', 'https://www.cnesst.gouv.qc.ca')
) AS v(name, acronym, jurisdiction, website_url)
WHERE NOT EXISTS (SELECT 1 FROM regulatory_bodies r WHERE r.name = v.name);

-- PPE: CSA / ANSI standards in place of AS/NZS
UPDATE ppe_types SET standard_reference = v.std
FROM (VALUES
  ('hard_hat',           'CSA Z94.1'),
  ('safety_boots',       'CSA Z195'),
  ('safety_gloves',      'ANSI/ISEA 105'),
  ('safety_glasses',     'CSA Z94.3'),
  ('face_shield',        'CSA Z94.3'),
  ('hearing_protection', 'CSA Z94.2'),
  ('hi_vis_vest',        'CSA Z96'),
  ('fall_harness',       'CSA Z259.10'),
  ('p1_respirator',      'CSA Z94.4'),
  ('p2_respirator',      'CSA Z94.4'),
  ('supplied_air',       'CSA Z94.4')
) AS v(code, std)
WHERE ppe_types.code = v.code
  AND (ppe_types.standard_reference IS NULL OR ppe_types.standard_reference LIKE 'AS/NZS%');

-- Document types: Canadian names (code 'swms' kept; seed data looks it up)
UPDATE document_types
SET name = 'Safe Work Procedure (SWP)',
    description = 'Step-by-step procedure for doing a task safely'
WHERE code = 'swms';

INSERT INTO document_types (code, name, description, requires_review, is_active, display_order)
SELECT 'flha', 'Field Level Hazard Assessment (FLHA)',
       'Pre-task hazard assessment completed at the work location', false, true,
       COALESCE((SELECT display_order FROM document_types WHERE code = 'swms'), 0) + 1
WHERE NOT EXISTS (SELECT 1 FROM document_types WHERE code = 'flha');

-- Contractors: CRA Business Number replaces the Australian ABN.
-- abn is kept (deprecated) so nothing reading it breaks; the app now
-- reads and writes business_number.
ALTER TABLE contractor_companies ADD COLUMN IF NOT EXISTS business_number text;
UPDATE contractor_companies SET business_number = abn WHERE business_number IS NULL AND abn IS NOT NULL;
COMMENT ON COLUMN contractor_companies.abn IS 'Deprecated: Australian ABN. Use business_number.';
COMMENT ON COLUMN contractor_companies.business_number IS 'CRA Business Number, e.g. 123456789 RT0001';
