-- =============================================================
-- Statutory holiday calendars for every province and territory,
-- generated from rules instead of typed by hand.
--
-- * holiday_rules: one row per jurisdiction + holiday, describing how
--   its date is found (fixed day, nth Monday, Easter offset, Victoria).
-- * generate_statutory_holidays(year): computes the dates. A fixed-date
--   holiday falling on a weekend moves to the next weekday not already
--   a holiday (the observed day), matching the hand-checked 2026–27
--   federal and Ontario rows.
-- * Seeds 2026–2030 for all jurisdictions; a December cron job keeps
--   two years ahead.
-- All provincial lists need review by Peninsula before relying on
-- them (needs_review = true). Notes:
--   QC: employers choose Good Friday OR Easter Monday; Good Friday used.
--   MB: National Day for Truth and Reconciliation not included; confirm.
--   NS: Remembrance Day (separate Act) not included; confirm.
-- =============================================================

ALTER TABLE public.statutory_holidays
  ADD COLUMN IF NOT EXISTS needs_review boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS rule_code text;

CREATE TABLE public.holiday_rules (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  jurisdiction  text NOT NULL,
  code          text NOT NULL,
  name          text NOT NULL,
  kind          text NOT NULL CHECK (kind IN ('fixed', 'nth_monday', 'easter_offset', 'victoria')),
  month         integer CHECK (month BETWEEN 1 AND 12),
  day           integer CHECK (day BETWEEN 1 AND 31),
  nth           integer CHECK (nth BETWEEN 1 AND 5),
  offset_days   integer,
  is_active     boolean NOT NULL DEFAULT true,
  UNIQUE (jurisdiction, code)
);

ALTER TABLE public.holiday_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY holiday_rules_select ON public.holiday_rules FOR SELECT TO authenticated USING (true);
REVOKE ALL ON public.holiday_rules FROM anon;

INSERT INTO public.holiday_rules (jurisdiction, code, name, kind, month, day, nth, offset_days)
SELECT j, code, name, kind, month, day, nth, off FROM (VALUES
  -- Federal (Canada Labour Code general holidays)
  ('CA','new_year','New Year''s Day','fixed',1,1,NULL,NULL),
  ('CA','good_friday','Good Friday','easter_offset',NULL,NULL,NULL,-2),
  ('CA','victoria','Victoria Day','victoria',NULL,NULL,NULL,NULL),
  ('CA','canada','Canada Day','fixed',7,1,NULL,NULL),
  ('CA','labour','Labour Day','nth_monday',9,NULL,1,NULL),
  ('CA','ndtr','National Day for Truth and Reconciliation','fixed',9,30,NULL,NULL),
  ('CA','thanksgiving','Thanksgiving Day','nth_monday',10,NULL,2,NULL),
  ('CA','remembrance','Remembrance Day','fixed',11,11,NULL,NULL),
  ('CA','christmas','Christmas Day','fixed',12,25,NULL,NULL),
  ('CA','boxing','Boxing Day','fixed',12,26,NULL,NULL),
  -- Ontario (ESA public holidays)
  ('CA-ON','new_year','New Year''s Day','fixed',1,1,NULL,NULL),
  ('CA-ON','family','Family Day','nth_monday',2,NULL,3,NULL),
  ('CA-ON','good_friday','Good Friday','easter_offset',NULL,NULL,NULL,-2),
  ('CA-ON','victoria','Victoria Day','victoria',NULL,NULL,NULL,NULL),
  ('CA-ON','canada','Canada Day','fixed',7,1,NULL,NULL),
  ('CA-ON','labour','Labour Day','nth_monday',9,NULL,1,NULL),
  ('CA-ON','thanksgiving','Thanksgiving Day','nth_monday',10,NULL,2,NULL),
  ('CA-ON','christmas','Christmas Day','fixed',12,25,NULL,NULL),
  ('CA-ON','boxing','Boxing Day','fixed',12,26,NULL,NULL),
  -- British Columbia
  ('CA-BC','new_year','New Year''s Day','fixed',1,1,NULL,NULL),
  ('CA-BC','family','Family Day','nth_monday',2,NULL,3,NULL),
  ('CA-BC','good_friday','Good Friday','easter_offset',NULL,NULL,NULL,-2),
  ('CA-BC','victoria','Victoria Day','victoria',NULL,NULL,NULL,NULL),
  ('CA-BC','canada','Canada Day','fixed',7,1,NULL,NULL),
  ('CA-BC','bc_day','B.C. Day','nth_monday',8,NULL,1,NULL),
  ('CA-BC','labour','Labour Day','nth_monday',9,NULL,1,NULL),
  ('CA-BC','ndtr','National Day for Truth and Reconciliation','fixed',9,30,NULL,NULL),
  ('CA-BC','thanksgiving','Thanksgiving Day','nth_monday',10,NULL,2,NULL),
  ('CA-BC','remembrance','Remembrance Day','fixed',11,11,NULL,NULL),
  ('CA-BC','christmas','Christmas Day','fixed',12,25,NULL,NULL),
  -- Alberta (general holidays)
  ('CA-AB','new_year','New Year''s Day','fixed',1,1,NULL,NULL),
  ('CA-AB','family','Alberta Family Day','nth_monday',2,NULL,3,NULL),
  ('CA-AB','good_friday','Good Friday','easter_offset',NULL,NULL,NULL,-2),
  ('CA-AB','victoria','Victoria Day','victoria',NULL,NULL,NULL,NULL),
  ('CA-AB','canada','Canada Day','fixed',7,1,NULL,NULL),
  ('CA-AB','labour','Labour Day','nth_monday',9,NULL,1,NULL),
  ('CA-AB','thanksgiving','Thanksgiving Day','nth_monday',10,NULL,2,NULL),
  ('CA-AB','remembrance','Remembrance Day','fixed',11,11,NULL,NULL),
  ('CA-AB','christmas','Christmas Day','fixed',12,25,NULL,NULL),
  -- Saskatchewan
  ('CA-SK','new_year','New Year''s Day','fixed',1,1,NULL,NULL),
  ('CA-SK','family','Family Day','nth_monday',2,NULL,3,NULL),
  ('CA-SK','good_friday','Good Friday','easter_offset',NULL,NULL,NULL,-2),
  ('CA-SK','victoria','Victoria Day','victoria',NULL,NULL,NULL,NULL),
  ('CA-SK','canada','Canada Day','fixed',7,1,NULL,NULL),
  ('CA-SK','sask_day','Saskatchewan Day','nth_monday',8,NULL,1,NULL),
  ('CA-SK','labour','Labour Day','nth_monday',9,NULL,1,NULL),
  ('CA-SK','thanksgiving','Thanksgiving Day','nth_monday',10,NULL,2,NULL),
  ('CA-SK','remembrance','Remembrance Day','fixed',11,11,NULL,NULL),
  ('CA-SK','christmas','Christmas Day','fixed',12,25,NULL,NULL),
  -- Manitoba
  ('CA-MB','new_year','New Year''s Day','fixed',1,1,NULL,NULL),
  ('CA-MB','louis_riel','Louis Riel Day','nth_monday',2,NULL,3,NULL),
  ('CA-MB','good_friday','Good Friday','easter_offset',NULL,NULL,NULL,-2),
  ('CA-MB','victoria','Victoria Day','victoria',NULL,NULL,NULL,NULL),
  ('CA-MB','canada','Canada Day','fixed',7,1,NULL,NULL),
  ('CA-MB','labour','Labour Day','nth_monday',9,NULL,1,NULL),
  ('CA-MB','thanksgiving','Thanksgiving Day','nth_monday',10,NULL,2,NULL),
  ('CA-MB','christmas','Christmas Day','fixed',12,25,NULL,NULL),
  -- Quebec (statutory holidays; Good Friday OR Easter Monday at employer's choice)
  ('CA-QC','new_year','Jour de l''An','fixed',1,1,NULL,NULL),
  ('CA-QC','good_friday','Vendredi saint','easter_offset',NULL,NULL,NULL,-2),
  ('CA-QC','patriots','Journée nationale des patriotes','victoria',NULL,NULL,NULL,NULL),
  ('CA-QC','fete_nationale','Fête nationale du Québec','fixed',6,24,NULL,NULL),
  ('CA-QC','canada','Fête du Canada','fixed',7,1,NULL,NULL),
  ('CA-QC','labour','Fête du Travail','nth_monday',9,NULL,1,NULL),
  ('CA-QC','thanksgiving','Action de grâce','nth_monday',10,NULL,2,NULL),
  ('CA-QC','christmas','Noël','fixed',12,25,NULL,NULL),
  -- Nova Scotia
  ('CA-NS','new_year','New Year''s Day','fixed',1,1,NULL,NULL),
  ('CA-NS','heritage','Heritage Day','nth_monday',2,NULL,3,NULL),
  ('CA-NS','good_friday','Good Friday','easter_offset',NULL,NULL,NULL,-2),
  ('CA-NS','canada','Canada Day','fixed',7,1,NULL,NULL),
  ('CA-NS','labour','Labour Day','nth_monday',9,NULL,1,NULL),
  ('CA-NS','christmas','Christmas Day','fixed',12,25,NULL,NULL),
  -- New Brunswick
  ('CA-NB','new_year','New Year''s Day','fixed',1,1,NULL,NULL),
  ('CA-NB','family','Family Day','nth_monday',2,NULL,3,NULL),
  ('CA-NB','good_friday','Good Friday','easter_offset',NULL,NULL,NULL,-2),
  ('CA-NB','canada','Canada Day','fixed',7,1,NULL,NULL),
  ('CA-NB','nb_day','New Brunswick Day','nth_monday',8,NULL,1,NULL),
  ('CA-NB','labour','Labour Day','nth_monday',9,NULL,1,NULL),
  ('CA-NB','remembrance','Remembrance Day','fixed',11,11,NULL,NULL),
  ('CA-NB','christmas','Christmas Day','fixed',12,25,NULL,NULL),
  -- Prince Edward Island
  ('CA-PE','new_year','New Year''s Day','fixed',1,1,NULL,NULL),
  ('CA-PE','islander','Islander Day','nth_monday',2,NULL,3,NULL),
  ('CA-PE','good_friday','Good Friday','easter_offset',NULL,NULL,NULL,-2),
  ('CA-PE','canada','Canada Day','fixed',7,1,NULL,NULL),
  ('CA-PE','labour','Labour Day','nth_monday',9,NULL,1,NULL),
  ('CA-PE','ndtr','National Day for Truth and Reconciliation','fixed',9,30,NULL,NULL),
  ('CA-PE','remembrance','Remembrance Day','fixed',11,11,NULL,NULL),
  ('CA-PE','christmas','Christmas Day','fixed',12,25,NULL,NULL),
  -- Newfoundland and Labrador
  ('CA-NL','new_year','New Year''s Day','fixed',1,1,NULL,NULL),
  ('CA-NL','good_friday','Good Friday','easter_offset',NULL,NULL,NULL,-2),
  ('CA-NL','canada','Memorial Day / Canada Day','fixed',7,1,NULL,NULL),
  ('CA-NL','labour','Labour Day','nth_monday',9,NULL,1,NULL),
  ('CA-NL','remembrance','Remembrance Day','fixed',11,11,NULL,NULL),
  ('CA-NL','christmas','Christmas Day','fixed',12,25,NULL,NULL),
  -- Yukon
  ('CA-YT','new_year','New Year''s Day','fixed',1,1,NULL,NULL),
  ('CA-YT','good_friday','Good Friday','easter_offset',NULL,NULL,NULL,-2),
  ('CA-YT','victoria','Victoria Day','victoria',NULL,NULL,NULL,NULL),
  ('CA-YT','nipd','National Indigenous Peoples Day','fixed',6,21,NULL,NULL),
  ('CA-YT','canada','Canada Day','fixed',7,1,NULL,NULL),
  ('CA-YT','discovery','Discovery Day','nth_monday',8,NULL,3,NULL),
  ('CA-YT','labour','Labour Day','nth_monday',9,NULL,1,NULL),
  ('CA-YT','ndtr','National Day for Truth and Reconciliation','fixed',9,30,NULL,NULL),
  ('CA-YT','thanksgiving','Thanksgiving Day','nth_monday',10,NULL,2,NULL),
  ('CA-YT','remembrance','Remembrance Day','fixed',11,11,NULL,NULL),
  ('CA-YT','christmas','Christmas Day','fixed',12,25,NULL,NULL),
  -- Northwest Territories
  ('CA-NT','new_year','New Year''s Day','fixed',1,1,NULL,NULL),
  ('CA-NT','good_friday','Good Friday','easter_offset',NULL,NULL,NULL,-2),
  ('CA-NT','victoria','Victoria Day','victoria',NULL,NULL,NULL,NULL),
  ('CA-NT','nipd','National Indigenous Peoples Day','fixed',6,21,NULL,NULL),
  ('CA-NT','canada','Canada Day','fixed',7,1,NULL,NULL),
  ('CA-NT','civic','Civic Holiday','nth_monday',8,NULL,1,NULL),
  ('CA-NT','labour','Labour Day','nth_monday',9,NULL,1,NULL),
  ('CA-NT','ndtr','National Day for Truth and Reconciliation','fixed',9,30,NULL,NULL),
  ('CA-NT','thanksgiving','Thanksgiving Day','nth_monday',10,NULL,2,NULL),
  ('CA-NT','remembrance','Remembrance Day','fixed',11,11,NULL,NULL),
  ('CA-NT','christmas','Christmas Day','fixed',12,25,NULL,NULL),
  ('CA-NT','boxing','Boxing Day','fixed',12,26,NULL,NULL),
  -- Nunavut
  ('CA-NU','new_year','New Year''s Day','fixed',1,1,NULL,NULL),
  ('CA-NU','good_friday','Good Friday','easter_offset',NULL,NULL,NULL,-2),
  ('CA-NU','victoria','Victoria Day','victoria',NULL,NULL,NULL,NULL),
  ('CA-NU','canada','Canada Day','fixed',7,1,NULL,NULL),
  ('CA-NU','nunavut_day','Nunavut Day','fixed',7,9,NULL,NULL),
  ('CA-NU','civic','Civic Holiday','nth_monday',8,NULL,1,NULL),
  ('CA-NU','labour','Labour Day','nth_monday',9,NULL,1,NULL),
  ('CA-NU','ndtr','National Day for Truth and Reconciliation','fixed',9,30,NULL,NULL),
  ('CA-NU','thanksgiving','Thanksgiving Day','nth_monday',10,NULL,2,NULL),
  ('CA-NU','remembrance','Remembrance Day','fixed',11,11,NULL,NULL),
  ('CA-NU','christmas','Christmas Day','fixed',12,25,NULL,NULL),
  ('CA-NU','boxing','Boxing Day','fixed',12,26,NULL,NULL)
) AS v(j, code, name, kind, month, day, nth, off)
ON CONFLICT (jurisdiction, code) DO NOTHING;

-- Anonymous Gregorian algorithm (Meeus/Jones/Butcher)
CREATE OR REPLACE FUNCTION public.easter_sunday(p_year integer)
RETURNS date
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $$
DECLARE a int; b int; c int; d int; e int; f int; g int; h int; i int; k int; l int; m int; n int;
BEGIN
  a := p_year % 19; b := p_year / 100; c := p_year % 100;
  d := b / 4; e := b % 4; f := (b + 8) / 25; g := (b - f + 1) / 3;
  h := (19 * a + b - d - g + 15) % 30;
  i := c / 4; k := c % 4;
  l := (32 + 2 * e + 2 * i - h - k) % 7;
  m := (a + 11 * h + 22 * l) / 451;
  n := h + l - 7 * m + 114;
  RETURN make_date(p_year, n / 31, n % 31 + 1);
END;
$$;

CREATE OR REPLACE FUNCTION public.holiday_date(r holiday_rules, p_year integer)
RETURNS date
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $$
DECLARE v_first date; v_may24 date;
BEGIN
  CASE r.kind
    WHEN 'fixed' THEN
      RETURN make_date(p_year, r.month, r.day);
    WHEN 'nth_monday' THEN
      v_first := make_date(p_year, r.month, 1);
      RETURN v_first + ((8 - EXTRACT(ISODOW FROM v_first)::int) % 7) + (r.nth - 1) * 7;
    WHEN 'easter_offset' THEN
      RETURN easter_sunday(p_year) + r.offset_days;
    WHEN 'victoria' THEN
      -- Last Monday before 25 May
      v_may24 := make_date(p_year, 5, 24);
      RETURN v_may24 - ((EXTRACT(ISODOW FROM v_may24)::int + 6) % 7);
  END CASE;
END;
$$;

-- Inserts one year's observed holidays for every jurisdiction (or one).
-- Existing rows for that year are left alone.
CREATE OR REPLACE FUNCTION public.generate_statutory_holidays(p_year integer, p_jurisdiction text DEFAULT NULL)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  j        text;
  r        record;
  v_date   date;
  v_taken  date[];
  v_count  integer := 0;
  v_rows   integer;
BEGIN
  FOR j IN SELECT DISTINCT jurisdiction FROM holiday_rules
           WHERE is_active AND (p_jurisdiction IS NULL OR jurisdiction = p_jurisdiction)
  LOOP
    v_taken := '{}';
    FOR r IN
      SELECT hr.*, holiday_date(hr, p_year) AS actual
      FROM holiday_rules hr
      WHERE hr.jurisdiction = j AND hr.is_active
      ORDER BY holiday_date(hr, p_year)
    LOOP
      v_date := r.actual;
      -- Weekend (or a day already taken by an earlier holiday): next free weekday
      WHILE EXTRACT(ISODOW FROM v_date) > 5 OR v_date = ANY (v_taken) LOOP
        v_date := v_date + 1;
      END LOOP;
      v_taken := v_taken || v_date;

      INSERT INTO statutory_holidays (jurisdiction, holiday_date, name, rule_code, needs_review)
      VALUES (j, v_date, r.name || CASE WHEN v_date <> r.actual THEN ' (observed)' ELSE '' END, r.code, true)
      ON CONFLICT (jurisdiction, holiday_date) DO NOTHING;
      GET DIAGNOSTICS v_rows = ROW_COUNT;
      v_count := v_count + v_rows;
    END LOOP;
  END LOOP;
  RETURN v_count;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.generate_statutory_holidays(integer, text) FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.generate_statutory_holidays(integer, text) TO service_role;

SELECT generate_statutory_holidays(y) FROM generate_series(2026, 2030) AS y;

-- Keep two years ahead
SELECT cron.schedule('generate-statutory-holidays', '0 3 1 12 *',
  'SELECT generate_statutory_holidays(EXTRACT(YEAR FROM now())::int + 2)');
