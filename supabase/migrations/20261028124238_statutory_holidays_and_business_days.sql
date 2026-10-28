-- =============================================================
-- D11: business-day / statutory-holiday logic in SQL, so deadlines
-- (regulatory reporting, dispute windows, notice periods) are
-- computed the same way everywhere. Jurisdiction codes follow the
-- localisation plan: 'CA' = federal (Canada Labour Code Part III
-- general holidays), 'CA-ON' = Ontario ESA public holidays.
-- Dates are the OBSERVED dates (a holiday on a weekend moves to the
-- next working day). Other provinces and later years are added by
-- seed migrations as the rules engine (Step 4) needs them.
-- =============================================================

CREATE TABLE public.statutory_holidays (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  jurisdiction  text NOT NULL,
  holiday_date  date NOT NULL,
  name          text NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (jurisdiction, holiday_date)
);

ALTER TABLE public.statutory_holidays ENABLE ROW LEVEL SECURITY;
CREATE POLICY statutory_holidays_select ON public.statutory_holidays FOR SELECT TO authenticated USING (true);
REVOKE ALL ON public.statutory_holidays FROM anon;

INSERT INTO public.statutory_holidays (jurisdiction, holiday_date, name) VALUES
  -- Federal 2026
  ('CA', '2026-01-01', 'New Year''s Day'),
  ('CA', '2026-04-03', 'Good Friday'),
  ('CA', '2026-05-18', 'Victoria Day'),
  ('CA', '2026-07-01', 'Canada Day'),
  ('CA', '2026-09-07', 'Labour Day'),
  ('CA', '2026-09-30', 'National Day for Truth and Reconciliation'),
  ('CA', '2026-10-12', 'Thanksgiving Day'),
  ('CA', '2026-11-11', 'Remembrance Day'),
  ('CA', '2026-12-25', 'Christmas Day'),
  ('CA', '2026-12-28', 'Boxing Day (observed)'),
  -- Federal 2027
  ('CA', '2027-01-01', 'New Year''s Day'),
  ('CA', '2027-03-26', 'Good Friday'),
  ('CA', '2027-05-24', 'Victoria Day'),
  ('CA', '2027-07-01', 'Canada Day'),
  ('CA', '2027-09-06', 'Labour Day'),
  ('CA', '2027-09-30', 'National Day for Truth and Reconciliation'),
  ('CA', '2027-10-11', 'Thanksgiving Day'),
  ('CA', '2027-11-11', 'Remembrance Day'),
  ('CA', '2027-12-27', 'Christmas Day (observed)'),
  ('CA', '2027-12-28', 'Boxing Day (observed)'),
  -- Ontario 2026
  ('CA-ON', '2026-01-01', 'New Year''s Day'),
  ('CA-ON', '2026-02-16', 'Family Day'),
  ('CA-ON', '2026-04-03', 'Good Friday'),
  ('CA-ON', '2026-05-18', 'Victoria Day'),
  ('CA-ON', '2026-07-01', 'Canada Day'),
  ('CA-ON', '2026-09-07', 'Labour Day'),
  ('CA-ON', '2026-10-12', 'Thanksgiving Day'),
  ('CA-ON', '2026-12-25', 'Christmas Day'),
  ('CA-ON', '2026-12-28', 'Boxing Day (observed)'),
  -- Ontario 2027
  ('CA-ON', '2027-01-01', 'New Year''s Day'),
  ('CA-ON', '2027-02-15', 'Family Day'),
  ('CA-ON', '2027-03-26', 'Good Friday'),
  ('CA-ON', '2027-05-24', 'Victoria Day'),
  ('CA-ON', '2027-07-01', 'Canada Day'),
  ('CA-ON', '2027-09-06', 'Labour Day'),
  ('CA-ON', '2027-10-11', 'Thanksgiving Day'),
  ('CA-ON', '2027-12-27', 'Christmas Day (observed)'),
  ('CA-ON', '2027-12-28', 'Boxing Day (observed)');

CREATE OR REPLACE FUNCTION public.is_business_day(p_date date, p_jurisdiction text DEFAULT 'CA')
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT EXTRACT(ISODOW FROM p_date) < 6
     AND NOT EXISTS (
       SELECT 1 FROM statutory_holidays
       WHERE jurisdiction = p_jurisdiction AND holiday_date = p_date);
$$;

-- p_days business days after p_start (p_start itself is not counted)
CREATE OR REPLACE FUNCTION public.add_business_days(p_start date, p_days integer, p_jurisdiction text DEFAULT 'CA')
RETURNS date
LANGUAGE plpgsql
STABLE
SET search_path = public
AS $$
DECLARE
  v_date  date := p_start;
  v_count integer := 0;
BEGIN
  IF p_days < 0 THEN RAISE EXCEPTION 'add_business_days: p_days must be >= 0'; END IF;
  WHILE v_count < p_days LOOP
    v_date := v_date + 1;
    IF is_business_day(v_date, p_jurisdiction) THEN
      v_count := v_count + 1;
    END IF;
  END LOOP;
  RETURN v_date;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.is_business_day(date, text)            FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.add_business_days(date, integer, text) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.is_business_day(date, text)            TO authenticated, service_role;
GRANT  EXECUTE ON FUNCTION public.add_business_days(date, integer, text) TO authenticated, service_role;
