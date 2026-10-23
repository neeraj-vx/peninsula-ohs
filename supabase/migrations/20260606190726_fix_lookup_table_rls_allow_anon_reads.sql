-- Global lookup/reference tables contain no sensitive data.
-- Replace auth.uid() IS NOT NULL guard with TRUE so the anon key can read them.
-- This fixes dropdowns showing empty when auth is disabled (dev) or for unauthenticated contexts.

DO $$ DECLARE t TEXT; BEGIN
  FOR t IN SELECT DISTINCT tablename FROM pg_policies
    WHERE qual = '(auth.uid() IS NOT NULL)' AND cmd = 'SELECT'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I',
      (SELECT policyname FROM pg_policies WHERE tablename = t AND cmd = 'SELECT' LIMIT 1), t);
    EXECUTE format('CREATE POLICY "public_read" ON %I FOR SELECT USING (true)', t);
  END LOOP;
END $$;
