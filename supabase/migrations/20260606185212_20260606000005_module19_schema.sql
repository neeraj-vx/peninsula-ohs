-- =============================================================
-- MODULE 19: LOTO (Lockout/Tagout) Procedures — Schema
-- =============================================================
CREATE TABLE IF NOT EXISTS loto_energy_types (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT        NOT NULL UNIQUE,
  colour_code   TEXT        NOT NULL DEFAULT '#525252',
  display_order INT                  DEFAULT 0
);

CREATE TABLE IF NOT EXISTS loto_procedures (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  organisation_id  UUID        NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  procedure_number TEXT,
  title            TEXT        NOT NULL,
  description      TEXT,
  asset_description TEXT,
  site_id          UUID        REFERENCES sites(id),
  status           TEXT        NOT NULL DEFAULT 'draft'
                               CHECK (status IN ('draft', 'approved', 'archived')),
  revision_number  INT         NOT NULL DEFAULT 1,
  approved_by      UUID        REFERENCES user_profiles(id),
  approved_at      TIMESTAMPTZ,
  next_review_date DATE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by       UUID        REFERENCES user_profiles(id)
);

CREATE TABLE IF NOT EXISTS loto_isolation_points (
  id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  procedure_id         UUID        NOT NULL REFERENCES loto_procedures(id) ON DELETE CASCADE,
  sequence_number      INT         NOT NULL,
  energy_type_id       UUID        REFERENCES loto_energy_types(id),
  location_description TEXT        NOT NULL,
  isolation_method     TEXT        NOT NULL,
  lock_device_type     TEXT,
  verification_method  TEXT,
  notes                TEXT,
  created_at           TIMESTAMPTZ          DEFAULT now()
);

CREATE TABLE IF NOT EXISTS loto_authorizations (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  procedure_id        UUID        NOT NULL REFERENCES loto_procedures(id),
  organisation_id     UUID        NOT NULL REFERENCES organisations(id),
  authorization_number TEXT,
  job_description     TEXT        NOT NULL,
  status              TEXT        NOT NULL DEFAULT 'active'
                                  CHECK (status IN ('active', 'completed', 'cancelled')),
  authorized_by       UUID        REFERENCES user_profiles(id),
  authorized_at       TIMESTAMPTZ,
  work_start_at       TIMESTAMPTZ,
  work_end_at         TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by          UUID        REFERENCES user_profiles(id)
);

CREATE INDEX IF NOT EXISTS idx_loto_proc_org        ON loto_procedures(organisation_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_loto_proc_site        ON loto_procedures(site_id);
CREATE INDEX IF NOT EXISTS idx_loto_iso_proc         ON loto_isolation_points(procedure_id, sequence_number);
CREATE INDEX IF NOT EXISTS idx_loto_auth_proc        ON loto_authorizations(procedure_id, status);
CREATE INDEX IF NOT EXISTS idx_loto_auth_org         ON loto_authorizations(organisation_id, status, created_at DESC);
