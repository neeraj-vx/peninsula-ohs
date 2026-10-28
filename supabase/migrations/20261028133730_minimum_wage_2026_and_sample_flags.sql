-- =============================================================
-- Compliance guide (docs/compliance-guide.md) "do now" items 2–4.
-- * Minimum wages were the 2024 rates, so the hiring check passed
--   offers below today's legal minimum. New rows are added with their
--   effective dates and sources; the old rows are closed off the day
--   before (history kept, nothing removed). getJurisdictionRules picks
--   the row in force on the day (D32).
-- * Older system courses are starter content: flag them as sample.
-- * "Working at Heights Awareness" (12-month validity) could be taken
--   for Ontario's CPO-approved program (3 years): renamed.
-- =============================================================

INSERT INTO employment_jurisdiction_rules
  (organisation_id, province_code, rule_type, rule_key, rule_label, rule_value, rule_value_numeric, effective_date, notes, is_active)
SELECT NULL, v.province, 'minimum_wage', v.rule_key, v.label, v.amount::text, v.amount, v.effective::date, v.notes, true
FROM (VALUES
  ('ON', 'min_wage_general', 'Minimum Wage (General)',            17.95, '2026-10-01', 'Source: hicksmorley.com/2026/04/01/ontario-minimum-wage-to-increase-october-1-2026 — confirm on ontario.ca'),
  ('ON', 'min_wage_student', 'Minimum Wage (Student Under 18)',   16.90, '2026-10-01', 'Secondary source (Landscape Ontario) — confirm on ontario.ca'),
  ('BC', 'min_wage_general', 'Minimum Wage (General)',            18.25, '2026-06-01', 'Source: news.gov.bc.ca/releases/2026lbr0021-000581'),
  ('QC', 'min_wage_general', 'Minimum Wage (General)',            16.60, '2026-05-01', 'Source: quebec.ca — taux général du salaire minimum 1er mai 2026'),
  ('QC', 'min_wage_tipped',  'Minimum Wage (Tipped Employees)',   13.30, '2026-05-01', 'Source: quebec.ca — taux général du salaire minimum 1er mai 2026')
) AS v(province, rule_key, label, amount, effective, notes)
WHERE NOT EXISTS (
  SELECT 1 FROM employment_jurisdiction_rules r
  WHERE r.organisation_id IS NULL AND r.province_code = v.province AND r.rule_key = v.rule_key
    AND r.effective_date = v.effective::date);

-- Close off each superseded system rate the day before its successor starts
UPDATE employment_jurisdiction_rules old
SET expiry_date = nxt.effective_date - 1, updated_at = now()
FROM employment_jurisdiction_rules nxt
WHERE old.organisation_id IS NULL AND nxt.organisation_id IS NULL
  AND old.rule_type = 'minimum_wage' AND nxt.rule_type = 'minimum_wage'
  AND old.province_code = nxt.province_code AND old.rule_key = nxt.rule_key
  AND nxt.effective_date > old.effective_date
  AND old.expiry_date IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM employment_jurisdiction_rules mid
    WHERE mid.organisation_id IS NULL AND mid.province_code = old.province_code AND mid.rule_key = old.rule_key
      AND mid.effective_date > old.effective_date AND mid.effective_date < nxt.effective_date);

UPDATE training_courses
SET is_sample_content = true,
    description = CASE WHEN description LIKE 'SAMPLE CONTENT%' THEN description
                       ELSE 'SAMPLE CONTENT — legal review required. ' || COALESCE(description, '') END
WHERE organisation_id IS NULL AND code IN ('WHMIS-2015', 'HVP-101', 'EVAC-101', 'MMH-101', 'WAH-101');

UPDATE training_courses
SET name = 'Working at Heights Awareness (not CPO-approved)'
WHERE organisation_id IS NULL AND code = 'WAH-101' AND name = 'Working at Heights Awareness';
