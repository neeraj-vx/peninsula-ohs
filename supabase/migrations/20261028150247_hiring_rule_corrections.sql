-- =============================================================
-- Hiring rule corrections (docs/compliance-guide.md §2.2). These were
-- wrong from the start, so they are corrected in place with a note
-- rather than versioned.
-- 1. BC "notice under 1 year" was 0 days; 1 week is owed after 3
--    consecutive months (ESA s.63).
-- 2. "Maximum probation period" (all provinces): employment standards
--    don't cap probation. They set an initial period in which no
--    termination notice is owed. Relabelled; the hiring check now warns
--    instead of blocking. (rule_type stays 'probation_max_days' because
--    of the table's check constraint; the code reads it as the
--    notice-free period.)
-- 3. "stat holiday pay" holds minimum VACATION pay; relabelled
--    (rule_type stays 'stat_holiday_pay_pct' for the same reason).
-- =============================================================

UPDATE employment_jurisdiction_rules
SET rule_value = '7', rule_value_numeric = 7,
    notes = 'No notice in the first 3 consecutive months; 1 week after 3 months and before 1 year (ESA s.63). Corrected 2026-10-28 (was 0).',
    updated_at = now()
WHERE organisation_id IS NULL AND province_code = 'BC' AND rule_key = 'notice_less_1_yr';

UPDATE employment_jurisdiction_rules
SET rule_key   = 'notice_free_period',
    rule_label = 'No-notice period at start of employment',
    notes = CASE province_code
      WHEN 'ON' THEN 'No statutory termination notice is owed in the first 3 months (ESA 2000 s.54/57). The ESA sets no maximum probation length.'
      WHEN 'BC' THEN 'No notice owed in the first 3 consecutive months (ESA s.63). The ESA sets no maximum probation length.'
      WHEN 'AB' THEN 'No notice owed in the first 90 days (Employment Standards Code s.55). The Code sets no maximum probation length.'
      WHEN 'QC' THEN 'Notice is owed after 3 months of uninterrupted service (Act respecting labour standards s.82).'
      ELSE notes END
      || ' Corrected 2026-10-28 (was "Maximum Probation Period").',
    updated_at = now()
WHERE organisation_id IS NULL AND rule_type = 'probation_max_days';

UPDATE employment_jurisdiction_rules
SET rule_key   = 'vacation_pay',
    rule_label = 'Minimum Vacation Pay',
    notes = COALESCE(notes, '') || ' Corrected 2026-10-28 (was labelled as statutory holiday pay).',
    updated_at = now()
WHERE organisation_id IS NULL AND rule_type = 'stat_holiday_pay_pct';
