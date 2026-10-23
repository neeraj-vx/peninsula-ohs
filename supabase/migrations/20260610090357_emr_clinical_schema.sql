-- EMR Clinical Module Migration

CREATE TABLE IF NOT EXISTS emr_encounters (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id              UUID        NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    encounter_number    TEXT        NOT NULL,
    patient_id          UUID        NOT NULL REFERENCES emr_patients(id),
    appointment_id      UUID        REFERENCES emr_appointments(id),
    doctor_id           UUID        REFERENCES emr_doctor_profiles(id),
    site_id             UUID        REFERENCES sites(id),
    encounter_type      TEXT        NOT NULL DEFAULT 'opd'
                            CHECK (encounter_type IN ('opd','ipd','er','teleconsult')),
    status              TEXT        NOT NULL DEFAULT 'open'
                            CHECK (status IN ('open','in_progress','completed','cancelled')),
    chief_complaint     TEXT,
    encounter_date      DATE        NOT NULL DEFAULT CURRENT_DATE,
    encounter_time      TIME        DEFAULT CURRENT_TIME,
    consultation_fee    NUMERIC(10,2),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by          UUID        REFERENCES user_profiles(id),
    UNIQUE (org_id, encounter_number)
);

CREATE TABLE IF NOT EXISTS emr_vitals (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    encounter_id        UUID        NOT NULL REFERENCES emr_encounters(id) ON DELETE CASCADE,
    recorded_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    temperature_celsius NUMERIC(4,1),
    pulse_bpm           INTEGER,
    bp_systolic         INTEGER,
    bp_diastolic        INTEGER,
    respiratory_rate    INTEGER,
    spo2_percent        NUMERIC(4,1),
    weight_kg           NUMERIC(5,1),
    height_cm           NUMERIC(5,1),
    bmi                 NUMERIC(4,1),
    pain_score          INTEGER     CHECK (pain_score BETWEEN 0 AND 10),
    blood_glucose_mmol  NUMERIC(4,1),
    notes               TEXT,
    recorded_by         UUID        REFERENCES user_profiles(id)
);

CREATE TABLE IF NOT EXISTS emr_soap_notes (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    encounter_id    UUID        NOT NULL REFERENCES emr_encounters(id) ON DELETE CASCADE,
    subjective      TEXT,
    objective       TEXT,
    assessment      TEXT,
    plan            TEXT,
    is_final        BOOLEAN     NOT NULL DEFAULT false,
    signed_at       TIMESTAMPTZ,
    signed_by       UUID        REFERENCES user_profiles(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS emr_diagnoses (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    encounter_id     UUID        NOT NULL REFERENCES emr_encounters(id) ON DELETE CASCADE,
    icd_code         TEXT        NOT NULL,
    icd_description  TEXT        NOT NULL,
    diagnosis_type   TEXT        DEFAULT 'primary'
                         CHECK (diagnosis_type IN ('primary','secondary','differential')),
    is_chronic       BOOLEAN     DEFAULT false,
    notes            TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS emr_prescriptions (
    id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id               UUID        NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    prescription_number  TEXT        NOT NULL,
    encounter_id         UUID        NOT NULL REFERENCES emr_encounters(id) ON DELETE CASCADE,
    patient_id           UUID        NOT NULL REFERENCES emr_patients(id),
    doctor_id            UUID        REFERENCES emr_doctor_profiles(id),
    prescribed_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    status               TEXT        NOT NULL DEFAULT 'pending'
                             CHECK (status IN ('pending','dispensed','partially_dispensed','cancelled')),
    notes                TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (org_id, prescription_number)
);

CREATE TABLE IF NOT EXISTS emr_prescription_items (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id  UUID        NOT NULL REFERENCES emr_prescriptions(id) ON DELETE CASCADE,
    drug_name        TEXT        NOT NULL,
    generic_name     TEXT,
    dose             TEXT        NOT NULL,
    frequency        TEXT        NOT NULL,
    route            TEXT        DEFAULT 'oral',
    duration_days    INTEGER,
    quantity         INTEGER,
    instructions     TEXT,
    is_dispensed     BOOLEAN     DEFAULT false,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS emr_referrals (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    encounter_id   UUID        NOT NULL REFERENCES emr_encounters(id) ON DELETE CASCADE,
    patient_id     UUID        NOT NULL REFERENCES emr_patients(id),
    referral_type  TEXT        DEFAULT 'internal'
                       CHECK (referral_type IN ('internal','external')),
    referred_to    TEXT        NOT NULL,
    specialty      TEXT,
    reason         TEXT,
    urgency        TEXT        DEFAULT 'routine',
    status         TEXT        DEFAULT 'pending',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_emr_encounters_org_id         ON emr_encounters (org_id);
CREATE INDEX IF NOT EXISTS idx_emr_encounters_patient_id     ON emr_encounters (patient_id);
CREATE INDEX IF NOT EXISTS idx_emr_encounters_doctor_id      ON emr_encounters (doctor_id);
CREATE INDEX IF NOT EXISTS idx_emr_encounters_encounter_date ON emr_encounters (encounter_date);
CREATE INDEX IF NOT EXISTS idx_emr_encounters_status         ON emr_encounters (status);
CREATE INDEX IF NOT EXISTS idx_emr_vitals_encounter_id       ON emr_vitals (encounter_id);
CREATE INDEX IF NOT EXISTS idx_emr_soap_notes_encounter_id   ON emr_soap_notes (encounter_id);
CREATE INDEX IF NOT EXISTS idx_emr_diagnoses_encounter_id    ON emr_diagnoses (encounter_id);
CREATE INDEX IF NOT EXISTS idx_emr_prescriptions_org_id      ON emr_prescriptions (org_id);
CREATE INDEX IF NOT EXISTS idx_emr_prescriptions_encounter_id ON emr_prescriptions (encounter_id);
CREATE INDEX IF NOT EXISTS idx_emr_prescriptions_patient_id  ON emr_prescriptions (patient_id);
CREATE INDEX IF NOT EXISTS idx_emr_prescription_items_prescription_id ON emr_prescription_items (prescription_id);
CREATE INDEX IF NOT EXISTS idx_emr_referrals_encounter_id    ON emr_referrals (encounter_id);

CREATE OR REPLACE FUNCTION generate_emr_encounter_number(p_org_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_year  TEXT   := to_char(now(), 'YY');
    v_count BIGINT;
BEGIN
    SELECT COALESCE(COUNT(*), 0) + 1 INTO v_count FROM emr_encounters WHERE org_id = p_org_id;
    RETURN 'E-' || v_year || '-' || lpad(v_count::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_emr_encounters_updated_at
    BEFORE UPDATE ON emr_encounters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_emr_soap_notes_updated_at
    BEFORE UPDATE ON emr_soap_notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE emr_encounters          ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_vitals              ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_soap_notes          ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_diagnoses           ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_prescriptions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_prescription_items  ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_referrals           ENABLE ROW LEVEL SECURITY;

CREATE POLICY emr_encounters_org_isolation ON emr_encounters
    USING (org_id = get_my_organisation_id());

CREATE POLICY emr_vitals_org_isolation ON emr_vitals
    USING (encounter_id IN (SELECT id FROM emr_encounters WHERE org_id = get_my_organisation_id()));

CREATE POLICY emr_soap_notes_org_isolation ON emr_soap_notes
    USING (encounter_id IN (SELECT id FROM emr_encounters WHERE org_id = get_my_organisation_id()));

CREATE POLICY emr_diagnoses_org_isolation ON emr_diagnoses
    USING (encounter_id IN (SELECT id FROM emr_encounters WHERE org_id = get_my_organisation_id()));

CREATE POLICY emr_prescriptions_org_isolation ON emr_prescriptions
    USING (org_id = get_my_organisation_id());

CREATE POLICY emr_prescription_items_org_isolation ON emr_prescription_items
    USING (prescription_id IN (SELECT id FROM emr_prescriptions WHERE org_id = get_my_organisation_id()));

CREATE POLICY emr_referrals_org_isolation ON emr_referrals
    USING (encounter_id IN (SELECT id FROM emr_encounters WHERE org_id = get_my_organisation_id()));
