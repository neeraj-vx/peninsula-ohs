-- =============================================================
-- MODULE 20: Compliance Calendar — Schema
-- =============================================================

CREATE TABLE IF NOT EXISTS compliance_obligation_types (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT        NOT NULL UNIQUE,
  colour_code   TEXT        NOT NULL DEFAULT '#525252',
  display_order INT                  DEFAULT 0
);

CREATE TABLE IF NOT EXISTS compliance_obligations (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  organisation_id     UUID        NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  title               TEXT        NOT NULL,
  description         TEXT,
  obligation_type_id  UUID        REFERENCES compliance_obligation_types(id),
  regulatory_body     TEXT,
  standard_reference  TEXT,
  site_id             UUID        REFERENCES sites(id),
  frequency           TEXT                 DEFAULT 'annual'
                                  CHECK (frequency IN (
                                    'one_time','daily','weekly','monthly',
                                    'quarterly','semi_annual','annual','biennial'
                                  )),
  next_due_date       DATE,
  owner_id            UUID        REFERENCES user_profiles(id),
  status              TEXT        NOT NULL DEFAULT 'active'
                                  CHECK (status IN ('active','inactive','superseded')),
  is_critical         BOOLEAN              DEFAULT false,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by          UUID        REFERENCES user_profiles(id)
);

CREATE TABLE IF NOT EXISTS compliance_tasks (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  obligation_id   UUID        NOT NULL REFERENCES compliance_obligations(id) ON DELETE CASCADE,
  organisation_id UUID        NOT NULL REFERENCES organisations(id),
  task_number     TEXT,
  title           TEXT        NOT NULL,
  description     TEXT,
  due_date        DATE        NOT NULL,
  assigned_to     UUID        REFERENCES user_profiles(id),
  status          TEXT        NOT NULL DEFAULT 'pending'
                              CHECK (status IN (
                                'pending','in_progress','completed','overdue','cancelled'
                              )),
  completed_at    TIMESTAMPTZ,
  completed_by    UUID        REFERENCES user_profiles(id),
  evidence_notes  TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by      UUID        REFERENCES user_profiles(id)
);

CREATE INDEX IF NOT EXISTS idx_comp_oblig_org        ON compliance_obligations(organisation_id, status);
CREATE INDEX IF NOT EXISTS idx_comp_oblig_due        ON compliance_obligations(next_due_date) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_comp_oblig_owner      ON compliance_obligations(owner_id);
CREATE INDEX IF NOT EXISTS idx_comp_task_org         ON compliance_tasks(organisation_id, status);
CREATE INDEX IF NOT EXISTS idx_comp_task_due         ON compliance_tasks(due_date, status);
CREATE INDEX IF NOT EXISTS idx_comp_task_obligation  ON compliance_tasks(obligation_id);
CREATE INDEX IF NOT EXISTS idx_comp_task_assigned    ON compliance_tasks(assigned_to);
