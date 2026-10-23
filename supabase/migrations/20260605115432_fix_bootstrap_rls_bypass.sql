CREATE OR REPLACE FUNCTION bootstrap_organisation(
  p_org_name   text,
  p_first_name text,
  p_last_name  text,
  p_industry   text DEFAULT NULL,
  p_timezone   text DEFAULT 'UTC'
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id   uuid := auth.uid();
  v_org_id    uuid;
  v_slug      text;
  v_base_slug text;
  v_suffix    int := 0;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF EXISTS (SELECT 1 FROM user_profiles WHERE id = v_user_id) THEN
    RAISE EXCEPTION 'Organisation already set up for this account';
  END IF;

  IF trim(p_org_name) = '' THEN
    RAISE EXCEPTION 'Organisation name is required';
  END IF;
  IF trim(p_first_name) = '' THEN
    RAISE EXCEPTION 'First name is required';
  END IF;

  v_base_slug := lower(trim(regexp_replace(p_org_name, '[^a-zA-Z0-9]+', '-', 'g'), '-'));
  v_slug      := v_base_slug;
  WHILE EXISTS (SELECT 1 FROM organisations WHERE slug = v_slug) LOOP
    v_suffix := v_suffix + 1;
    v_slug   := v_base_slug || '-' || v_suffix;
  END LOOP;

  -- Bypass RLS for all three inserts — this function IS the bootstrap,
  -- so by definition the caller has no roles yet.
  SET LOCAL row_security = off;

  INSERT INTO organisations (name, slug, industry, timezone, created_by)
  VALUES (
    trim(p_org_name),
    v_slug,
    nullif(trim(p_industry), ''),
    coalesce(nullif(trim(p_timezone), ''), 'UTC'),
    v_user_id
  )
  RETURNING id INTO v_org_id;

  INSERT INTO user_profiles (id, organisation_id, first_name, last_name, email)
  SELECT
    v_user_id,
    v_org_id,
    trim(p_first_name),
    coalesce(nullif(trim(p_last_name), ''), ''),
    u.email
  FROM auth.users u WHERE u.id = v_user_id
  ON CONFLICT (id) DO UPDATE
    SET organisation_id = EXCLUDED.organisation_id,
        first_name      = EXCLUDED.first_name,
        last_name       = EXCLUDED.last_name,
        updated_at      = now();

  INSERT INTO user_roles (user_id, role_id, organisation_id, granted_by)
  SELECT v_user_id, r.id, v_org_id, v_user_id
  FROM roles r
  WHERE r.name = 'System Admin' AND r.is_system_role = true
  ON CONFLICT (user_id, role_id, organisation_id, site_id) DO NOTHING;

  RETURN jsonb_build_object(
    'organisation_id', v_org_id,
    'user_id',         v_user_id
  );
END;
$$;

REVOKE ALL ON FUNCTION bootstrap_organisation(text, text, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION bootstrap_organisation(text, text, text, text, text) TO authenticated;
