-- easter_sunday / holiday_date were created without explicit grants and
-- picked up Supabase's default EXECUTE for anon. They are pure date
-- helpers, but nothing in public should be callable by anon.
REVOKE EXECUTE ON FUNCTION public.easter_sunday(integer)              FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.holiday_date(holiday_rules, integer) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.easter_sunday(integer)              TO authenticated, service_role;
GRANT  EXECUTE ON FUNCTION public.holiday_date(holiday_rules, integer) TO authenticated, service_role;
