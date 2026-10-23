-- EMR IPD and Pharmacy Modules

CREATE TABLE IF NOT EXISTS emr_ward_types (
    id         UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    name       TEXT    NOT NULL UNIQUE,
    sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS emr_wards (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id       UUID        NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    site_id      UUID        REFERENCES sites(id),
    ward_type_id UUID        REFERENCES emr_ward_types(id),
    name         TEXT        NOT NULL,
    floor        TEXT,
    total_beds   INTEGER     NOT NULL DEFAULT 0,
    notes        TEXT,
    is_active    BOOLEAN     NOT NULL DEFAULT true,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS emr_beds (
    id         UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    ward_id    UUID    NOT NULL REFERENCES emr_wards(id) ON DELETE CASCADE,
    bed_number TEXT    NOT NULL,
    bed_type   TEXT    NOT NULL DEFAULT 'standard'
                       CHECK (bed_type IN ('standard', 'icu', 'isolation', 'bariatric')),
    status     TEXT    NOT NULL DEFAULT 'available'
                       CHECK (status IN ('available', 'occupied', 'maintenance', 'reserved', 'cleaning')),
    is_active  BOOLEAN NOT NULL DEFAULT true,
    UNIQUE (ward_id, bed_number)
);

CREATE TABLE IF NOT EXISTS emr_admissions (
    id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id                UUID        NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    admission_number      TEXT        NOT NULL,
    patient_id            UUID        NOT NULL REFERENCES emr_patients(id),
    encounter_id          UUID        REFERENCES emr_encounters(id),
    ward_id               UUID        REFERENCES emr_wards(id),
    bed_id                UUID        REFERENCES emr_beds(id),
    admitting_doctor_id   UUID        REFERENCES emr_doctor_profiles(id),
    admission_type        TEXT        NOT NULL DEFAULT 'planned'
                                      CHECK (admission_type IN ('planned', 'emergency', 'transfer')),
    admission_date        DATE        NOT NULL DEFAULT CURRENT_DATE,
    admission_time        TIME        NOT NULL DEFAULT CURRENT_TIME,
    discharge_date        DATE,
    discharge_time        TIME,
    status                TEXT        NOT NULL DEFAULT 'admitted'
                                      CHECK (status IN ('admitted', 'discharged', 'transferred', 'ama', 'deceased')),
    admission_notes       TEXT,
    diagnosis_on_admission TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (org_id, admission_number)
);

CREATE TABLE IF NOT EXISTS emr_nursing_notes (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    admission_id UUID        NOT NULL REFERENCES emr_admissions(id) ON DELETE CASCADE,
    note_type    TEXT        NOT NULL DEFAULT 'nursing'
                             CHECK (note_type IN ('nursing', 'handover', 'assessment', 'wound_care')),
    notes        TEXT        NOT NULL,
    shift        TEXT        CHECK (shift IN ('morning', 'afternoon', 'night')),
    recorded_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    recorded_by  UUID        REFERENCES user_profiles(id)
);

CREATE TABLE IF NOT EXISTS emr_intake_output (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    admission_id UUID        NOT NULL REFERENCES emr_admissions(id) ON DELETE CASCADE,
    recorded_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_type  TEXT        NOT NULL CHECK (record_type IN ('intake', 'output')),
    category     TEXT        NOT NULL,
    amount_ml    INTEGER     NOT NULL,
    notes        TEXT,
    recorded_by  UUID        REFERENCES user_profiles(id)
);

CREATE TABLE IF NOT EXISTS emr_discharge_summaries (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    admission_id            UUID        NOT NULL REFERENCES emr_admissions(id) ON DELETE CASCADE,
    final_diagnosis         TEXT,
    procedures_done         TEXT,
    treatment_summary       TEXT,
    condition_at_discharge  TEXT,
    follow_up_instructions  TEXT,
    medications_at_discharge TEXT,
    is_final                BOOLEAN     NOT NULL DEFAULT false,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by              UUID        REFERENCES user_profiles(id)
);

CREATE TABLE IF NOT EXISTS emr_drug_categories (
    id            UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    name          TEXT    NOT NULL UNIQUE,
    is_controlled BOOLEAN NOT NULL DEFAULT false,
    sort_order    INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS emr_drugs (
    id                     UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id                 UUID        NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    generic_name           TEXT        NOT NULL,
    brand_names            TEXT[],
    category_id            UUID        REFERENCES emr_drug_categories(id),
    drug_form              TEXT,
    strength               TEXT,
    unit                   TEXT,
    is_controlled          BOOLEAN     NOT NULL DEFAULT false,
    requires_refrigeration BOOLEAN     NOT NULL DEFAULT false,
    is_active              BOOLEAN     NOT NULL DEFAULT true,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS emr_drug_inventory (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    drug_id          UUID        NOT NULL REFERENCES emr_drugs(id) ON DELETE CASCADE,
    site_id          UUID        REFERENCES sites(id),
    batch_number     TEXT,
    expiry_date      DATE,
    quantity_in_stock INTEGER    NOT NULL DEFAULT 0,
    reorder_level    INTEGER     NOT NULL DEFAULT 10,
    purchase_price   NUMERIC(10, 2),
    selling_price    NUMERIC(10, 2),
    supplier         TEXT,
    received_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_active        BOOLEAN     NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS emr_drug_dispensing (
    id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id      UUID        REFERENCES emr_prescriptions(id),
    prescription_item_id UUID        REFERENCES emr_prescription_items(id),
    inventory_id         UUID        REFERENCES emr_drug_inventory(id),
    quantity_dispensed   INTEGER     NOT NULL,
    dispensed_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    dispensed_by         UUID        REFERENCES user_profiles(id),
    notes                TEXT
);

CREATE INDEX IF NOT EXISTS idx_emr_wards_org_id         ON emr_wards(org_id);
CREATE INDEX IF NOT EXISTS idx_emr_beds_ward_id         ON emr_beds(ward_id);
CREATE INDEX IF NOT EXISTS idx_emr_beds_status          ON emr_beds(status);
CREATE INDEX IF NOT EXISTS idx_emr_admissions_org_id    ON emr_admissions(org_id);
CREATE INDEX IF NOT EXISTS idx_emr_admissions_patient   ON emr_admissions(patient_id);
CREATE INDEX IF NOT EXISTS idx_emr_admissions_status    ON emr_admissions(status);
CREATE INDEX IF NOT EXISTS idx_emr_drugs_org_id         ON emr_drugs(org_id);
CREATE INDEX IF NOT EXISTS idx_emr_drug_inventory_drug  ON emr_drug_inventory(drug_id);

CREATE OR REPLACE FUNCTION generate_emr_admission_number(p_org_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_year  TEXT   := to_char(now(), 'YY');
    v_count BIGINT;
BEGIN
    SELECT COALESCE(COUNT(*), 0) + 1 INTO v_count FROM emr_admissions WHERE org_id = p_org_id;
    RETURN 'A-' || v_year || '-' || lpad(v_count::TEXT, 5, '0');
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_emr_admissions_updated_at
    BEFORE UPDATE ON emr_admissions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_emr_discharge_summaries_updated_at
    BEFORE UPDATE ON emr_discharge_summaries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE emr_ward_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_wards ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_beds ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_admissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_nursing_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_intake_output ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_discharge_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_drug_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_drugs ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_drug_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_drug_dispensing ENABLE ROW LEVEL SECURITY;

CREATE POLICY "emr_ward_types_select" ON emr_ward_types FOR SELECT TO authenticated USING (true);

CREATE POLICY "emr_wards_select" ON emr_wards FOR SELECT TO authenticated USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_wards_insert" ON emr_wards FOR INSERT TO authenticated WITH CHECK (org_id = get_my_organisation_id());
CREATE POLICY "emr_wards_update" ON emr_wards FOR UPDATE TO authenticated USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_wards_delete" ON emr_wards FOR DELETE TO authenticated USING (org_id = get_my_organisation_id());

CREATE POLICY "emr_beds_select" ON emr_beds FOR SELECT TO authenticated USING (ward_id IN (SELECT id FROM emr_wards WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_beds_insert" ON emr_beds FOR INSERT TO authenticated WITH CHECK (ward_id IN (SELECT id FROM emr_wards WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_beds_update" ON emr_beds FOR UPDATE TO authenticated USING (ward_id IN (SELECT id FROM emr_wards WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_beds_delete" ON emr_beds FOR DELETE TO authenticated USING (ward_id IN (SELECT id FROM emr_wards WHERE org_id = get_my_organisation_id()));

CREATE POLICY "emr_admissions_select" ON emr_admissions FOR SELECT TO authenticated USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_admissions_insert" ON emr_admissions FOR INSERT TO authenticated WITH CHECK (org_id = get_my_organisation_id());
CREATE POLICY "emr_admissions_update" ON emr_admissions FOR UPDATE TO authenticated USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_admissions_delete" ON emr_admissions FOR DELETE TO authenticated USING (org_id = get_my_organisation_id());

CREATE POLICY "emr_nursing_notes_select" ON emr_nursing_notes FOR SELECT TO authenticated USING (admission_id IN (SELECT id FROM emr_admissions WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_nursing_notes_insert" ON emr_nursing_notes FOR INSERT TO authenticated WITH CHECK (admission_id IN (SELECT id FROM emr_admissions WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_nursing_notes_update" ON emr_nursing_notes FOR UPDATE TO authenticated USING (admission_id IN (SELECT id FROM emr_admissions WHERE org_id = get_my_organisation_id()));

CREATE POLICY "emr_intake_output_select" ON emr_intake_output FOR SELECT TO authenticated USING (admission_id IN (SELECT id FROM emr_admissions WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_intake_output_insert" ON emr_intake_output FOR INSERT TO authenticated WITH CHECK (admission_id IN (SELECT id FROM emr_admissions WHERE org_id = get_my_organisation_id()));

CREATE POLICY "emr_discharge_summaries_select" ON emr_discharge_summaries FOR SELECT TO authenticated USING (admission_id IN (SELECT id FROM emr_admissions WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_discharge_summaries_insert" ON emr_discharge_summaries FOR INSERT TO authenticated WITH CHECK (admission_id IN (SELECT id FROM emr_admissions WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_discharge_summaries_update" ON emr_discharge_summaries FOR UPDATE TO authenticated USING (admission_id IN (SELECT id FROM emr_admissions WHERE org_id = get_my_organisation_id()));

CREATE POLICY "emr_drug_categories_select" ON emr_drug_categories FOR SELECT TO authenticated USING (true);

CREATE POLICY "emr_drugs_select" ON emr_drugs FOR SELECT TO authenticated USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_drugs_insert" ON emr_drugs FOR INSERT TO authenticated WITH CHECK (org_id = get_my_organisation_id());
CREATE POLICY "emr_drugs_update" ON emr_drugs FOR UPDATE TO authenticated USING (org_id = get_my_organisation_id());

CREATE POLICY "emr_drug_inventory_select" ON emr_drug_inventory FOR SELECT TO authenticated USING (drug_id IN (SELECT id FROM emr_drugs WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_drug_inventory_insert" ON emr_drug_inventory FOR INSERT TO authenticated WITH CHECK (drug_id IN (SELECT id FROM emr_drugs WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_drug_inventory_update" ON emr_drug_inventory FOR UPDATE TO authenticated USING (drug_id IN (SELECT id FROM emr_drugs WHERE org_id = get_my_organisation_id()));

CREATE POLICY "emr_drug_dispensing_select" ON emr_drug_dispensing FOR SELECT TO authenticated USING (inventory_id IN (SELECT di.id FROM emr_drug_inventory di JOIN emr_drugs d ON d.id = di.drug_id WHERE d.org_id = get_my_organisation_id()));
CREATE POLICY "emr_drug_dispensing_insert" ON emr_drug_dispensing FOR INSERT TO authenticated WITH CHECK (inventory_id IN (SELECT di.id FROM emr_drug_inventory di JOIN emr_drugs d ON d.id = di.drug_id WHERE d.org_id = get_my_organisation_id()));

INSERT INTO emr_ward_types (name, sort_order) VALUES ('General',1),('Semi-Private',2),('Private',3),('ICU',4),('HDU',5),('Pediatric',6),('Maternity',7),('Psychiatric',8) ON CONFLICT (name) DO NOTHING;
INSERT INTO emr_drug_categories (name, is_controlled, sort_order) VALUES ('Analgesics',false,1),('Antibiotics',false,2),('Antivirals',false,3),('Cardiovascular',false,4),('Diabetes',false,5),('Respiratory',false,6),('Neurological',false,7),('Gastrointestinal',false,8),('Vitamins & Supplements',false,9),('Controlled Substances',true,10) ON CONFLICT (name) DO NOTHING;
