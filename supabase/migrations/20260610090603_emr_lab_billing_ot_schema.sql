-- EMR Lab, Radiology, Billing, Insurance, OT, ER Modules

CREATE TABLE IF NOT EXISTS emr_lab_test_catalog (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id                UUID NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    test_name             TEXT NOT NULL,
    test_code             TEXT NOT NULL,
    category              TEXT CHECK (category IN ('Hematology','Biochemistry','Microbiology','Immunology','Serology','Pathology','Urine','Stool')),
    specimen_type         TEXT,
    reference_range_male  TEXT,
    reference_range_female TEXT,
    unit                  TEXT,
    tat_hours             INTEGER DEFAULT 24,
    price                 NUMERIC(10,2) DEFAULT 0,
    is_active             BOOLEAN NOT NULL DEFAULT true,
    UNIQUE (org_id, test_code)
);

CREATE TABLE IF NOT EXISTS emr_lab_orders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id          UUID NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    order_number    TEXT NOT NULL,
    encounter_id    UUID NOT NULL REFERENCES emr_encounters(id),
    patient_id      UUID NOT NULL REFERENCES emr_patients(id),
    test_id         UUID NOT NULL REFERENCES emr_lab_test_catalog(id),
    ordered_by      UUID REFERENCES emr_doctor_profiles(id),
    priority        TEXT DEFAULT 'routine' CHECK (priority IN ('routine','urgent','stat')),
    status          TEXT NOT NULL DEFAULT 'ordered' CHECK (status IN ('ordered','collected','processing','resulted','cancelled')),
    clinical_notes  TEXT,
    ordered_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (org_id, order_number)
);

CREATE TABLE IF NOT EXISTS emr_lab_specimens (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id         UUID NOT NULL REFERENCES emr_lab_orders(id) ON DELETE CASCADE,
    specimen_type    TEXT NOT NULL,
    collection_time  TIMESTAMPTZ DEFAULT now(),
    collected_by     UUID REFERENCES user_profiles(id),
    barcode          TEXT,
    rejection_reason TEXT,
    is_rejected      BOOLEAN DEFAULT false
);

CREATE TABLE IF NOT EXISTS emr_lab_results (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id        UUID NOT NULL REFERENCES emr_lab_orders(id) ON DELETE CASCADE,
    result_value    TEXT,
    numeric_value   NUMERIC,
    unit            TEXT,
    reference_range TEXT,
    is_critical     BOOLEAN DEFAULT false,
    is_abnormal     BOOLEAN DEFAULT false,
    abnormal_flag   TEXT CHECK (abnormal_flag IN ('H','L','HH','LL') OR abnormal_flag IS NULL),
    result_status   TEXT DEFAULT 'preliminary' CHECK (result_status IN ('preliminary','final','amended')),
    resulted_at     TIMESTAMPTZ,
    resulted_by     UUID REFERENCES user_profiles(id),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS emr_radiology_order_types (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id      UUID NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,
    modality    TEXT NOT NULL CHECK (modality IN ('X-Ray','CT Scan','MRI','Ultrasound','PET-CT','Mammography','Fluoroscopy')),
    body_part   TEXT,
    price       NUMERIC(10,2) DEFAULT 0,
    is_active   BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS emr_radiology_orders (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id              UUID NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    order_number        TEXT NOT NULL,
    encounter_id        UUID NOT NULL REFERENCES emr_encounters(id),
    patient_id          UUID NOT NULL REFERENCES emr_patients(id),
    order_type_id       UUID REFERENCES emr_radiology_order_types(id),
    ordered_by          UUID REFERENCES emr_doctor_profiles(id),
    priority            TEXT DEFAULT 'routine' CHECK (priority IN ('routine','urgent','stat')),
    status              TEXT NOT NULL DEFAULT 'ordered' CHECK (status IN ('ordered','scheduled','in_progress','reported','cancelled')),
    clinical_indication TEXT,
    contrast_required   BOOLEAN DEFAULT false,
    scheduled_at        TIMESTAMPTZ,
    ordered_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (org_id, order_number)
);

CREATE TABLE IF NOT EXISTS emr_radiology_reports (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id      UUID NOT NULL REFERENCES emr_radiology_orders(id) ON DELETE CASCADE,
    report_text   TEXT,
    impression    TEXT,
    is_critical   BOOLEAN DEFAULT false,
    report_status TEXT DEFAULT 'preliminary' CHECK (report_status IN ('preliminary','final','amended')),
    reported_by   UUID REFERENCES user_profiles(id),
    reported_at   TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS emr_service_categories (
    id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS emr_service_catalog (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id       UUID NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    service_code TEXT NOT NULL,
    service_name TEXT NOT NULL,
    category_id  UUID REFERENCES emr_service_categories(id),
    price        NUMERIC(10,2) NOT NULL DEFAULT 0,
    tax_percent  NUMERIC(4,2) DEFAULT 0,
    is_active    BOOLEAN NOT NULL DEFAULT true,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (org_id, service_code)
);

CREATE TABLE IF NOT EXISTS emr_invoices (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id          UUID NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    invoice_number  TEXT NOT NULL,
    patient_id      UUID NOT NULL REFERENCES emr_patients(id),
    encounter_id    UUID REFERENCES emr_encounters(id),
    admission_id    UUID REFERENCES emr_admissions(id),
    invoice_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date        DATE,
    subtotal        NUMERIC(10,2) NOT NULL DEFAULT 0,
    tax_amount      NUMERIC(10,2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
    total_amount    NUMERIC(10,2) NOT NULL DEFAULT 0,
    paid_amount     NUMERIC(10,2) NOT NULL DEFAULT 0,
    status          TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','issued','partially_paid','paid','cancelled','refunded')),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by      UUID REFERENCES user_profiles(id),
    UNIQUE (org_id, invoice_number)
);

CREATE TABLE IF NOT EXISTS emr_invoice_items (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id       UUID NOT NULL REFERENCES emr_invoices(id) ON DELETE CASCADE,
    service_id       UUID REFERENCES emr_service_catalog(id),
    description      TEXT NOT NULL,
    quantity         INTEGER NOT NULL DEFAULT 1,
    unit_price       NUMERIC(10,2) NOT NULL,
    tax_percent      NUMERIC(4,2) DEFAULT 0,
    discount_percent NUMERIC(4,2) DEFAULT 0,
    line_total       NUMERIC(10,2) NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS emr_payments (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id       UUID NOT NULL REFERENCES emr_invoices(id),
    payment_date     DATE NOT NULL DEFAULT CURRENT_DATE,
    amount           NUMERIC(10,2) NOT NULL,
    payment_mode     TEXT NOT NULL DEFAULT 'cash' CHECK (payment_mode IN ('cash','card','upi','bank_transfer','insurance','cheque')),
    reference_number TEXT,
    notes            TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by       UUID REFERENCES user_profiles(id)
);

CREATE TABLE IF NOT EXISTS emr_insurance_companies (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id        UUID NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    name          TEXT NOT NULL,
    contact_email TEXT,
    contact_phone TEXT,
    is_active     BOOLEAN NOT NULL DEFAULT true,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS emr_patient_insurance (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id           UUID NOT NULL REFERENCES emr_patients(id) ON DELETE CASCADE,
    insurance_company_id UUID NOT NULL REFERENCES emr_insurance_companies(id),
    policy_number        TEXT NOT NULL,
    member_id            TEXT,
    valid_from           DATE,
    valid_to             DATE,
    copay_amount         NUMERIC(10,2) DEFAULT 0,
    is_primary           BOOLEAN DEFAULT true,
    is_active            BOOLEAN NOT NULL DEFAULT true,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS emr_insurance_claims (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id               UUID NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    claim_number         TEXT NOT NULL,
    invoice_id           UUID NOT NULL REFERENCES emr_invoices(id),
    patient_insurance_id UUID NOT NULL REFERENCES emr_patient_insurance(id),
    claimed_amount       NUMERIC(10,2) NOT NULL,
    approved_amount      NUMERIC(10,2),
    settled_amount       NUMERIC(10,2),
    status               TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','submitted','under_review','approved','rejected','settled')),
    submitted_at         TIMESTAMPTZ,
    settled_at           TIMESTAMPTZ,
    rejection_reason     TEXT,
    notes                TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (org_id, claim_number)
);

CREATE TABLE IF NOT EXISTS emr_theaters (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id       UUID NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    site_id      UUID REFERENCES sites(id),
    name         TEXT NOT NULL,
    theater_type TEXT DEFAULT 'general',
    is_active    BOOLEAN NOT NULL DEFAULT true,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS emr_ot_bookings (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id                UUID NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    booking_number        TEXT NOT NULL,
    patient_id            UUID NOT NULL REFERENCES emr_patients(id),
    admission_id          UUID REFERENCES emr_admissions(id),
    theater_id            UUID REFERENCES emr_theaters(id),
    surgeon_id            UUID REFERENCES emr_doctor_profiles(id),
    anesthesiologist_id   UUID REFERENCES emr_doctor_profiles(id),
    procedure_name        TEXT NOT NULL,
    scheduled_date        DATE NOT NULL,
    scheduled_start       TIME,
    duration_minutes      INTEGER DEFAULT 60,
    booking_type          TEXT DEFAULT 'elective' CHECK (booking_type IN ('elective','emergency')),
    status                TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled','in_progress','completed','cancelled','postponed')),
    pre_op_notes          TEXT,
    post_op_notes         TEXT,
    anaesthesia_type      TEXT,
    blood_loss_ml         INTEGER,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (org_id, booking_number)
);

CREATE TABLE IF NOT EXISTS emr_triage_categories (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name             TEXT NOT NULL UNIQUE,
    level            INTEGER NOT NULL UNIQUE,
    description      TEXT,
    max_wait_minutes INTEGER,
    color_code       TEXT DEFAULT '#da1e28'
);

CREATE TABLE IF NOT EXISTS emr_ed_visits (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id               UUID NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    visit_number         TEXT NOT NULL,
    patient_id           UUID NOT NULL REFERENCES emr_patients(id),
    encounter_id         UUID REFERENCES emr_encounters(id),
    arrival_time         TIMESTAMPTZ NOT NULL DEFAULT now(),
    triage_time          TIMESTAMPTZ,
    triage_category_id   UUID REFERENCES emr_triage_categories(id),
    chief_complaint      TEXT NOT NULL,
    mode_of_arrival      TEXT DEFAULT 'walk_in',
    attending_doctor_id  UUID REFERENCES emr_doctor_profiles(id),
    disposition          TEXT CHECK (disposition IN ('discharged','admitted','transferred','ama','lwbs','deceased')),
    disposition_time     TIMESTAMPTZ,
    status               TEXT NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting','triaged','with_doctor','observation','disposition','closed')),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (org_id, visit_number)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_emr_lab_orders_org            ON emr_lab_orders (org_id);
CREATE INDEX IF NOT EXISTS idx_emr_lab_orders_encounter      ON emr_lab_orders (encounter_id);
CREATE INDEX IF NOT EXISTS idx_emr_lab_orders_status         ON emr_lab_orders (status);
CREATE INDEX IF NOT EXISTS idx_emr_lab_results_order         ON emr_lab_results (order_id);
CREATE INDEX IF NOT EXISTS idx_emr_invoices_org              ON emr_invoices (org_id);
CREATE INDEX IF NOT EXISTS idx_emr_invoices_patient          ON emr_invoices (patient_id);
CREATE INDEX IF NOT EXISTS idx_emr_invoices_status           ON emr_invoices (status);
CREATE INDEX IF NOT EXISTS idx_emr_payments_invoice          ON emr_payments (invoice_id);
CREATE INDEX IF NOT EXISTS idx_emr_ot_bookings_org           ON emr_ot_bookings (org_id);
CREATE INDEX IF NOT EXISTS idx_emr_ot_bookings_date          ON emr_ot_bookings (scheduled_date);
CREATE INDEX IF NOT EXISTS idx_emr_ed_visits_org             ON emr_ed_visits (org_id);
CREATE INDEX IF NOT EXISTS idx_emr_ed_visits_status          ON emr_ed_visits (status);

-- updated_at for invoices
CREATE TRIGGER trg_emr_invoices_updated_at
    BEFORE UPDATE ON emr_invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Seed data
INSERT INTO emr_triage_categories (name, level, description, max_wait_minutes, color_code) VALUES
    ('Immediate (Resuscitation)', 1, 'Life-threatening condition requiring immediate intervention', 0, '#da1e28'),
    ('Emergent', 2, 'High risk of deterioration; requires rapid medical attention', 10, '#ff832b'),
    ('Urgent', 3, 'Potentially serious condition requiring prompt attention', 30, '#f1c21b'),
    ('Semi-Urgent', 4, 'Less serious condition that can safely wait', 60, '#24a148'),
    ('Non-Urgent', 5, 'Non-acute condition; lowest priority', 120, '#0f62fe')
ON CONFLICT (level) DO NOTHING;

INSERT INTO emr_service_categories (name) VALUES ('Consultation'),('Procedure'),('Diagnostic'),('Pharmacy'),('Room Charges'),('Nursing'),('Other') ON CONFLICT (name) DO NOTHING;

-- RLS
ALTER TABLE emr_lab_test_catalog       ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_lab_orders             ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_lab_specimens          ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_lab_results            ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_radiology_order_types  ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_radiology_orders       ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_radiology_reports      ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_service_categories     ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_service_catalog        ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_invoices               ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_invoice_items          ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_payments               ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_insurance_companies    ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_patient_insurance      ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_insurance_claims       ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_theaters               ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_ot_bookings            ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_triage_categories      ENABLE ROW LEVEL SECURITY;
ALTER TABLE emr_ed_visits              ENABLE ROW LEVEL SECURITY;

CREATE POLICY "emr_lab_catalog_select" ON emr_lab_test_catalog FOR SELECT USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_lab_catalog_insert" ON emr_lab_test_catalog FOR INSERT WITH CHECK (org_id = get_my_organisation_id());
CREATE POLICY "emr_lab_catalog_update" ON emr_lab_test_catalog FOR UPDATE USING (org_id = get_my_organisation_id());

CREATE POLICY "emr_lab_orders_select" ON emr_lab_orders FOR SELECT USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_lab_orders_insert" ON emr_lab_orders FOR INSERT WITH CHECK (org_id = get_my_organisation_id());
CREATE POLICY "emr_lab_orders_update" ON emr_lab_orders FOR UPDATE USING (org_id = get_my_organisation_id());

CREATE POLICY "emr_lab_specimens_select" ON emr_lab_specimens FOR SELECT USING (order_id IN (SELECT id FROM emr_lab_orders WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_lab_specimens_insert" ON emr_lab_specimens FOR INSERT WITH CHECK (order_id IN (SELECT id FROM emr_lab_orders WHERE org_id = get_my_organisation_id()));

CREATE POLICY "emr_lab_results_select" ON emr_lab_results FOR SELECT USING (order_id IN (SELECT id FROM emr_lab_orders WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_lab_results_insert" ON emr_lab_results FOR INSERT WITH CHECK (order_id IN (SELECT id FROM emr_lab_orders WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_lab_results_update" ON emr_lab_results FOR UPDATE USING (order_id IN (SELECT id FROM emr_lab_orders WHERE org_id = get_my_organisation_id()));

CREATE POLICY "emr_rad_types_select" ON emr_radiology_order_types FOR SELECT USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_rad_types_insert" ON emr_radiology_order_types FOR INSERT WITH CHECK (org_id = get_my_organisation_id());

CREATE POLICY "emr_rad_orders_select" ON emr_radiology_orders FOR SELECT USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_rad_orders_insert" ON emr_radiology_orders FOR INSERT WITH CHECK (org_id = get_my_organisation_id());
CREATE POLICY "emr_rad_orders_update" ON emr_radiology_orders FOR UPDATE USING (org_id = get_my_organisation_id());

CREATE POLICY "emr_rad_reports_select" ON emr_radiology_reports FOR SELECT USING (order_id IN (SELECT id FROM emr_radiology_orders WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_rad_reports_insert" ON emr_radiology_reports FOR INSERT WITH CHECK (order_id IN (SELECT id FROM emr_radiology_orders WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_rad_reports_update" ON emr_radiology_reports FOR UPDATE USING (order_id IN (SELECT id FROM emr_radiology_orders WHERE org_id = get_my_organisation_id()));

CREATE POLICY "emr_svc_cats_select" ON emr_service_categories FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "emr_service_catalog_select" ON emr_service_catalog FOR SELECT USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_service_catalog_insert" ON emr_service_catalog FOR INSERT WITH CHECK (org_id = get_my_organisation_id());
CREATE POLICY "emr_service_catalog_update" ON emr_service_catalog FOR UPDATE USING (org_id = get_my_organisation_id());

CREATE POLICY "emr_invoices_select" ON emr_invoices FOR SELECT USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_invoices_insert" ON emr_invoices FOR INSERT WITH CHECK (org_id = get_my_organisation_id());
CREATE POLICY "emr_invoices_update" ON emr_invoices FOR UPDATE USING (org_id = get_my_organisation_id());

CREATE POLICY "emr_invoice_items_select" ON emr_invoice_items FOR SELECT USING (invoice_id IN (SELECT id FROM emr_invoices WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_invoice_items_insert" ON emr_invoice_items FOR INSERT WITH CHECK (invoice_id IN (SELECT id FROM emr_invoices WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_invoice_items_update" ON emr_invoice_items FOR UPDATE USING (invoice_id IN (SELECT id FROM emr_invoices WHERE org_id = get_my_organisation_id()));

CREATE POLICY "emr_payments_select" ON emr_payments FOR SELECT USING (invoice_id IN (SELECT id FROM emr_invoices WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_payments_insert" ON emr_payments FOR INSERT WITH CHECK (invoice_id IN (SELECT id FROM emr_invoices WHERE org_id = get_my_organisation_id()));

CREATE POLICY "emr_insurance_cos_select" ON emr_insurance_companies FOR SELECT USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_insurance_cos_insert" ON emr_insurance_companies FOR INSERT WITH CHECK (org_id = get_my_organisation_id());
CREATE POLICY "emr_insurance_cos_update" ON emr_insurance_companies FOR UPDATE USING (org_id = get_my_organisation_id());

CREATE POLICY "emr_patient_ins_select" ON emr_patient_insurance FOR SELECT USING (insurance_company_id IN (SELECT id FROM emr_insurance_companies WHERE org_id = get_my_organisation_id()));
CREATE POLICY "emr_patient_ins_insert" ON emr_patient_insurance FOR INSERT WITH CHECK (insurance_company_id IN (SELECT id FROM emr_insurance_companies WHERE org_id = get_my_organisation_id()));

CREATE POLICY "emr_claims_select" ON emr_insurance_claims FOR SELECT USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_claims_insert" ON emr_insurance_claims FOR INSERT WITH CHECK (org_id = get_my_organisation_id());
CREATE POLICY "emr_claims_update" ON emr_insurance_claims FOR UPDATE USING (org_id = get_my_organisation_id());

CREATE POLICY "emr_theaters_select" ON emr_theaters FOR SELECT USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_theaters_insert" ON emr_theaters FOR INSERT WITH CHECK (org_id = get_my_organisation_id());

CREATE POLICY "emr_ot_bookings_select" ON emr_ot_bookings FOR SELECT USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_ot_bookings_insert" ON emr_ot_bookings FOR INSERT WITH CHECK (org_id = get_my_organisation_id());
CREATE POLICY "emr_ot_bookings_update" ON emr_ot_bookings FOR UPDATE USING (org_id = get_my_organisation_id());

CREATE POLICY "emr_triage_cats_select" ON emr_triage_categories FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "emr_ed_visits_select" ON emr_ed_visits FOR SELECT USING (org_id = get_my_organisation_id());
CREATE POLICY "emr_ed_visits_insert" ON emr_ed_visits FOR INSERT WITH CHECK (org_id = get_my_organisation_id());
CREATE POLICY "emr_ed_visits_update" ON emr_ed_visits FOR UPDATE USING (org_id = get_my_organisation_id());
