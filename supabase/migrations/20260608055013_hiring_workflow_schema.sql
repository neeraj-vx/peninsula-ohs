CREATE TABLE hires (
  id                          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  organisation_id             uuid        NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  hire_number                 text        UNIQUE,
  current_step                integer     NOT NULL DEFAULT 1,
  status                      text        NOT NULL DEFAULT 'draft'
                                          CHECK (status IN ('draft','in_progress','pending_signature','completed','cancelled')),
  candidate_first_name        text,
  candidate_last_name         text,
  candidate_email             text,
  candidate_phone             text,
  position_title              text,
  employment_type             text        CHECK (employment_type IN ('full_time','part_time','contractor','casual','volunteer')),
  site_id                     uuid        REFERENCES sites(id),
  department_id               uuid        REFERENCES departments(id),
  start_date                  date,
  is_fixed_term               boolean     NOT NULL DEFAULT false,
  contract_end_date           date,
  probation_period_days       integer,
  reports_to_id               uuid        REFERENCES user_profiles(id),
  salary_amount               numeric,
  pay_frequency               text        CHECK (pay_frequency IN ('hourly','weekly','biweekly','semi_monthly','monthly','annual')),
  hourly_rate                 numeric,
  overtime_eligible           boolean     NOT NULL DEFAULT false,
  compliance_province         text,
  compliance_check_results    jsonb,
  compliance_passed_at        timestamptz,
  compliance_overrides        jsonb,
  all_signatures_collected    boolean     NOT NULL DEFAULT false,
  signatures_collected_at     timestamptz,
  checklist_completed         boolean     NOT NULL DEFAULT false,
  checklist_completed_at      timestamptz,
  worker_id                   uuid        REFERENCES user_profiles(id),
  completed_at                timestamptz,
  cancelled_at                timestamptz,
  cancellation_reason         text,
  created_at                  timestamptz NOT NULL DEFAULT now(),
  updated_at                  timestamptz NOT NULL DEFAULT now(),
  created_by                  uuid        REFERENCES auth.users(id)
);

CREATE INDEX idx_hires_org            ON hires(organisation_id);
CREATE INDEX idx_hires_status         ON hires(status);
CREATE INDEX idx_hires_worker         ON hires(worker_id);
CREATE INDEX idx_hires_site           ON hires(site_id);
CREATE INDEX idx_hires_org_status     ON hires(organisation_id, status);

CREATE TABLE hire_documents (
  id                          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  organisation_id             uuid        NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  hire_id                     uuid        NOT NULL REFERENCES hires(id) ON DELETE CASCADE,
  template_id                 uuid        REFERENCES hr_document_templates(id),
  document_type               text        NOT NULL,
  file_name                   text        NOT NULL,
  storage_path                text        NOT NULL,
  file_size_bytes             integer,
  generated_at                timestamptz NOT NULL DEFAULT now(),
  generated_by                uuid        REFERENCES auth.users(id),
  requires_candidate_sig      boolean     NOT NULL DEFAULT true,
  candidate_signed_at         timestamptz,
  candidate_signature_url     text,
  requires_employer_sig       boolean     NOT NULL DEFAULT false,
  employer_signed_at          timestamptz,
  employer_signature_url      text,
  created_at                  timestamptz NOT NULL DEFAULT now(),
  updated_at                  timestamptz NOT NULL DEFAULT now(),
  created_by                  uuid        REFERENCES auth.users(id)
);

CREATE INDEX idx_hire_docs_hire    ON hire_documents(hire_id);
CREATE INDEX idx_hire_docs_org     ON hire_documents(organisation_id);

CREATE TABLE hire_prestart_tasks (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  organisation_id   uuid        NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  hire_id           uuid        NOT NULL REFERENCES hires(id) ON DELETE CASCADE,
  task_title        text        NOT NULL,
  task_type         text        NOT NULL DEFAULT 'task'
                                CHECK (task_type IN ('task','uniform','equipment','access','system_setup','training','other')),
  is_required       boolean     NOT NULL DEFAULT true,
  is_completed      boolean     NOT NULL DEFAULT false,
  completed_at      timestamptz,
  completed_by      uuid        REFERENCES auth.users(id),
  notes             text,
  display_order     integer     NOT NULL DEFAULT 0,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  created_by        uuid        REFERENCES auth.users(id)
);

CREATE INDEX idx_hpt_hire  ON hire_prestart_tasks(hire_id);
CREATE INDEX idx_hpt_org   ON hire_prestart_tasks(organisation_id);
