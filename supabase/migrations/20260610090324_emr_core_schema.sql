-- =============================================================
-- EMR CORE MODULE — Schema, Functions, Triggers, RLS
-- Migration: 20260610000001_emr_core_schema.sql
-- =============================================================

CREATE TABLE emr_specialties (
  id        UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  name      TEXT    NOT NULL UNIQUE,
  code      TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE emr_doctor_profiles (
  id                       UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id                   UUID        NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  user_id                  UUID        NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  specialty_id             UUID        REFERENCES emr_specialties(id),
  registration_number      TEXT,
  qualification            TEXT,
  consultation_fee         NUMERIC(10,2) DEFAULT 0,
  bio                      TEXT,
  available_days           TEXT[]      DEFAULT ARRAY['monday','tuesday','wednesday','thursday','friday'],
  slot_duration_minutes    INTEGER     DEFAULT 30,
  is_active                BOOLEAN     NOT NULL DEFAULT true,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (org_id, user_id)
);

CREATE TABLE emr_patients (
  id                         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id                     UUID        NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  patient_number             TEXT        NOT NULL,
  title                      TEXT,
  first_name                 TEXT        NOT NULL,
  last_name                  TEXT        NOT NULL,
  date_of_birth              DATE,
  gender                     TEXT        CHECK (gender IN ('male','female','other','unknown')),
  blood_group                TEXT,
  marital_status             TEXT,
  nationality                TEXT        DEFAULT 'Australian',
  language_preference        TEXT        DEFAULT 'English',
  occupation                 TEXT,
  religion                   TEXT,
  mobile                     TEXT,
  home_phone                 TEXT,
  work_phone                 TEXT,
  email                      TEXT,
  address_line1              TEXT,
  address_line2              TEXT,
  city                       TEXT,
  state                      TEXT,
  postcode                   TEXT,
  country                    TEXT        DEFAULT 'Australia',
  emergency_contact_name     TEXT,
  emergency_contact_relation TEXT,
  emergency_contact_phone    TEXT,
  worker_id                  UUID        REFERENCES user_profiles(id),
  referring_doctor           TEXT,
  source                     TEXT        DEFAULT 'walk_in',
  notes                      TEXT,
  photo_url                  TEXT,
  is_active                  BOOLEAN     NOT NULL DEFAULT true,
  created_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by                 UUID        REFERENCES user_profiles(id),
  UNIQUE (org_id, patient_number)
);

CREATE TABLE emr_patient_allergies (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id    UUID        NOT NULL REFERENCES emr_patients(id) ON DELETE CASCADE,
  allergen      TEXT        NOT NULL,
  allergen_type TEXT        DEFAULT 'drug',
  reaction      TEXT,
  severity      TEXT        DEFAULT 'moderate',
  is_active     BOOLEAN     NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE emr_patient_identifiers (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id  UUID        NOT NULL REFERENCES emr_patients(id) ON DELETE CASCADE,
  id_type     TEXT        NOT NULL,
  id_value    TEXT        NOT NULL,
  issued_by   TEXT,
  valid_until DATE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE emr_appointment_types (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id           UUID        NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  name             TEXT        NOT NULL,
  duration_minutes INTEGER     NOT NULL DEFAULT 30,
  color_code       TEXT        DEFAULT '#0f62fe',
  is_active        BOOLEAN     NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE emr_doctor_availability (
  id                    UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id             UUID    NOT NULL REFERENCES emr_doctor_profiles(id) ON DELETE CASCADE,
  site_id               UUID    REFERENCES sites(id),
  day_of_week           INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time            TIME    NOT NULL,
  end_time              TIME    NOT NULL,
  slot_duration_minutes INTEGER NOT NULL DEFAULT 30,
  is_active             BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE emr_appointments (
  id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id               UUID        NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  appointment_number   TEXT        NOT NULL,
  patient_id           UUID        NOT NULL REFERENCES emr_patients(id),
  doctor_id            UUID        REFERENCES emr_doctor_profiles(id),
  site_id              UUID        REFERENCES sites(id),
  appointment_type_id  UUID        REFERENCES emr_appointment_types(id),
  scheduled_at         TIMESTAMPTZ NOT NULL,
  duration_minutes     INTEGER     NOT NULL DEFAULT 30,
  status               TEXT        NOT NULL DEFAULT 'scheduled'
                         CHECK (status IN ('scheduled','confirmed','checked_in','in_progress','completed','cancelled','no_show')),
  visit_type           TEXT        DEFAULT 'opd'
                         CHECK (visit_type IN ('opd','teleconsult','emergency')),
  chief_complaint      TEXT,
  notes                TEXT,
  cancelled_reason     TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by           UUID        REFERENCES user_profiles(id),
  UNIQUE (org_id, appointment_number)
);

CREATE INDEX idx_emr_doctor_profiles_org_id   ON emr_doctor_profiles (org_id);
CREATE INDEX idx_emr_doctor_profiles_user_id  ON emr_doctor_profiles (user_id);
CREATE INDEX idx_emr_patients_org_id          ON emr_patients (org_id);
CREATE INDEX idx_emr_patients_worker_id       ON emr_patients (worker_id);
CREATE INDEX idx_emr_appointment_types_org_id ON emr_appointment_types (org_id);
CREATE INDEX idx_emr_doctor_availability_doctor ON emr_doctor_availability (doctor_id);
CREATE INDEX idx_emr_appointments_org_id      ON emr_appointments (org_id);
CREATE INDEX idx_emr_appointments_patient_id  ON emr_appointments (patient_id);
CREATE INDEX idx_emr_appointments_scheduled_at ON emr_appointments (scheduled_at);
CREATE INDEX idx_emr_appointments_status      ON emr_appointments (status);

CREATE OR REPLACE FUNCTION generate_emr_patient_number(p_org_id UUID)
RETURNS TEXT AS $$
DECLARE
  v_year  TEXT   := to_char(now(), 'YY');
  v_count BIGINT;
BEGIN
  SELECT COALESCE(COUNT(*), 0) + 1 INTO v_count FROM emr_patients WHERE org_id = p_org_id;
  RETURN 'P-' || v_year || '-' || lpad(v_count::TEXT, 5, '0');
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_emr_doctor_profiles_updated_at
  BEFORE UPDATE ON emr_doctor_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_emr_patients_updated_at
  BEFORE UPDATE ON emr_patients
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_emr_appointments_updated_at
  BEFORE UPDATE ON emr_appointments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE emr_specialties          ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_doctor_profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_patients             ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_patient_allergies    ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_patient_identifiers  ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_appointment_types    ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_doctor_availability  ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_appointments         ENABLE ROW LEVEL SECURITY;

CREATE POLICY "emr_specialties_select" ON emr_specialties FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "emr_specialties_insert" ON emr_specialties FOR INSERT WITH CHECK (is_system_admin());
CREATE POLICY "emr_specialties_update" ON emr_specialties FOR UPDATE USING (is_system_admin());

CREATE POLICY "emr_doctor_profiles_select" ON emr_doctor_profiles FOR SELECT USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_doctor_profiles_insert" ON emr_doctor_profiles FOR INSERT WITH CHECK (org_id = get_my_organisation_id() AND (is_system_admin() OR is_hse_officer()));
CREATE POLICY "emr_doctor_profiles_update" ON emr_doctor_profiles FOR UPDATE USING (org_id = get_my_organisation_id() AND (is_system_admin() OR is_hse_officer()));
CREATE POLICY "emr_doctor_profiles_delete" ON emr_doctor_profiles FOR DELETE USING (org_id = get_my_organisation_id() AND is_system_admin());

CREATE POLICY "emr_patients_select" ON emr_patients FOR SELECT USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_patients_insert" ON emr_patients FOR INSERT WITH CHECK (org_id = get_my_organisation_id());
CREATE POLICY "emr_patients_update" ON emr_patients FOR UPDATE USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_patients_delete" ON emr_patients FOR DELETE USING (org_id = get_my_organisation_id() AND (is_system_admin() OR is_hse_officer()));

CREATE POLICY "emr_patient_allergies_select" ON emr_patient_allergies FOR SELECT USING (EXISTS (SELECT 1 FROM emr_patients p WHERE p.id = patient_id AND p.org_id = get_my_organisation_id()));
CREATE POLICY "emr_patient_allergies_insert" ON emr_patient_allergies FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM emr_patients p WHERE p.id = patient_id AND p.org_id = get_my_organisation_id()));
CREATE POLICY "emr_patient_allergies_update" ON emr_patient_allergies FOR UPDATE USING (EXISTS (SELECT 1 FROM emr_patients p WHERE p.id = patient_id AND p.org_id = get_my_organisation_id()));

CREATE POLICY "emr_patient_identifiers_select" ON emr_patient_identifiers FOR SELECT USING (EXISTS (SELECT 1 FROM emr_patients p WHERE p.id = patient_id AND p.org_id = get_my_organisation_id()));
CREATE POLICY "emr_patient_identifiers_insert" ON emr_patient_identifiers FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM emr_patients p WHERE p.id = patient_id AND p.org_id = get_my_organisation_id()));

CREATE POLICY "emr_appointment_types_select" ON emr_appointment_types FOR SELECT USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_appointment_types_insert" ON emr_appointment_types FOR INSERT WITH CHECK (org_id = get_my_organisation_id() AND (is_system_admin() OR is_hse_officer()));
CREATE POLICY "emr_appointment_types_update" ON emr_appointment_types FOR UPDATE USING (org_id = get_my_organisation_id() AND (is_system_admin() OR is_hse_officer()));

CREATE POLICY "emr_doctor_availability_select" ON emr_doctor_availability FOR SELECT USING (EXISTS (SELECT 1 FROM emr_doctor_profiles dp WHERE dp.id = doctor_id AND dp.org_id = get_my_organisation_id()));
CREATE POLICY "emr_doctor_availability_insert" ON emr_doctor_availability FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM emr_doctor_profiles dp WHERE dp.id = doctor_id AND dp.org_id = get_my_organisation_id()));
CREATE POLICY "emr_doctor_availability_update" ON emr_doctor_availability FOR UPDATE USING (EXISTS (SELECT 1 FROM emr_doctor_profiles dp WHERE dp.id = doctor_id AND dp.org_id = get_my_organisation_id()));

CREATE POLICY "emr_appointments_select" ON emr_appointments FOR SELECT USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_appointments_insert" ON emr_appointments FOR INSERT WITH CHECK (org_id = get_my_organisation_id());
CREATE POLICY "emr_appointments_update" ON emr_appointments FOR UPDATE USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_appointments_delete" ON emr_appointments FOR DELETE USING (org_id = get_my_organisation_id() AND (is_system_admin() OR is_hse_officer()));
