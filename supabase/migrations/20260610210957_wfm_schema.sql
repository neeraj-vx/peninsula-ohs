-- ============================================================
-- WFM (Workforce Management System) Schema Migration
-- EXXIO Platform
-- ============================================================

-- MODULE 2: CERTIFICATIONS
CREATE TABLE wfm_cert_types (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    name text NOT NULL,
    code text,
    category text,
    description text,
    validity_period_days int,
    requires_evidence bool DEFAULT true,
    is_mandatory bool DEFAULT false,
    is_active bool DEFAULT true,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_cert_types FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_cert_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_cert_types USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_worker_certs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    cert_type_id uuid REFERENCES wfm_cert_types(id) ON DELETE SET NULL,
    cert_number text,
    issued_by text,
    issue_date date,
    expiry_date date,
    evidence_url text,
    verification_status text DEFAULT 'pending' CHECK (verification_status IN ('pending','verified','failed','expired')),
    verified_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    verified_at timestamptz,
    notes text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_worker_certs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_worker_certs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_worker_certs USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_role_cert_requirements (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    role_title text NOT NULL,
    cert_type_id uuid REFERENCES wfm_cert_types(id) ON DELETE SET NULL,
    requirement_level text DEFAULT 'mandatory' CHECK (requirement_level IN ('mandatory','recommended','optional')),
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_role_cert_requirements FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_role_cert_requirements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_role_cert_requirements USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

-- MODULE 3: INDUCTIONS & TRAINING
CREATE TABLE wfm_induction_templates (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    title text NOT NULL,
    induction_type text CHECK (induction_type IN ('company','site','task','zone')),
    description text,
    validity_period_days int DEFAULT 365,
    is_active bool DEFAULT true,
    version int DEFAULT 1,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_induction_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_induction_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_induction_templates USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_induction_steps (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    template_id uuid REFERENCES wfm_induction_templates(id) ON DELETE CASCADE,
    step_order int NOT NULL,
    title text NOT NULL,
    content text,
    step_type text CHECK (step_type IN ('content','quiz','video','acknowledgement')),
    is_mandatory bool DEFAULT true,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_induction_steps FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_induction_steps ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_induction_steps USING (template_id IN (SELECT id FROM wfm_induction_templates WHERE organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid())));

CREATE TABLE wfm_induction_completions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    template_id uuid REFERENCES wfm_induction_templates(id) ON DELETE SET NULL,
    completed_at timestamptz,
    expiry_date date,
    score int,
    pass_mark int DEFAULT 80,
    passed bool DEFAULT false,
    facilitator_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_induction_completions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_induction_completions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_induction_completions USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_training_providers (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    name text NOT NULL,
    contact_name text,
    contact_email text,
    contact_phone text,
    address text,
    specialties text[],
    is_approved bool DEFAULT false,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_training_providers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_training_providers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_training_providers USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_training_sessions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    title text NOT NULL,
    training_type text,
    facilitator_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    provider text,
    scheduled_start timestamptz,
    scheduled_end timestamptz,
    location text,
    max_attendees int,
    status text DEFAULT 'scheduled' CHECK (status IN ('scheduled','completed','cancelled')),
    notes text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_training_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_training_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_training_sessions USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_session_attendees (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id uuid REFERENCES wfm_training_sessions(id) ON DELETE CASCADE,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    enrolled_at timestamptz DEFAULT now(),
    attended bool DEFAULT false,
    completed bool DEFAULT false,
    score int,
    certificate_issued bool DEFAULT false,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_session_attendees FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_session_attendees ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_session_attendees USING (session_id IN (SELECT id FROM wfm_training_sessions WHERE organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid())));

-- MODULE 4: CONTRACTOR PRE-QUALIFICATION
CREATE TABLE wfm_contractor_preqal (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    contractor_id uuid REFERENCES contractor_companies(id) ON DELETE SET NULL,
    status text DEFAULT 'pending' CHECK (status IN ('pending','approved','conditionally_approved','rejected','expired','suspended')),
    submitted_at timestamptz,
    reviewed_at timestamptz,
    reviewed_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    expiry_date date,
    score numeric(5,2),
    notes text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_contractor_preqal FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_contractor_preqal ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_contractor_preqal USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_contractor_documents (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    contractor_id uuid REFERENCES contractor_companies(id) ON DELETE SET NULL,
    doc_type text NOT NULL CHECK (doc_type IN ('public_liability','workers_comp','professional_indemnity','trade_license','safety_plan','ohs_policy','swms','env_plan')),
    file_url text,
    doc_number text,
    issue_date date,
    expiry_date date,
    insurer text,
    coverage_amount numeric(15,2),
    status text DEFAULT 'pending' CHECK (status IN ('pending','verified','expired','rejected')),
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_contractor_documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_contractor_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_contractor_documents USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_contractor_performance (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    contractor_id uuid REFERENCES contractor_companies(id) ON DELETE SET NULL,
    review_date date NOT NULL,
    safety_score int,
    quality_score int,
    schedule_score int,
    conduct_score int,
    overall_score numeric(4,2),
    reviewed_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    notes text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_contractor_performance FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_contractor_performance ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_contractor_performance USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

-- MODULE 5: VISITORS
CREATE TABLE wfm_visitor_types (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    name text NOT NULL,
    code text,
    requires_induction bool DEFAULT true,
    access_level text DEFAULT 'visitor',
    badge_color text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_visitor_types FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_visitor_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_visitor_types USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_visitors (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    full_name text NOT NULL,
    email text,
    phone text,
    company text,
    visitor_type_id uuid REFERENCES wfm_visitor_types(id) ON DELETE SET NULL,
    is_blacklisted bool DEFAULT false,
    blacklist_reason text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_visitors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_visitors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_visitors USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_visitor_sign_ins (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    visitor_id uuid REFERENCES wfm_visitors(id) ON DELETE SET NULL,
    host_user_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    sign_in_time timestamptz DEFAULT now(),
    sign_out_time timestamptz,
    expected_departure timestamptz,
    vehicle_rego text,
    badge_number text,
    purpose text,
    induction_completed bool DEFAULT false,
    induction_completed_at timestamptz,
    forms_signed jsonb DEFAULT '[]',
    status text DEFAULT 'signed_in' CHECK (status IN ('signed_in','signed_out','auto_signed_out')),
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_visitor_sign_ins FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_visitor_sign_ins ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_visitor_sign_ins USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

-- MODULE 6: SITE ACCESS CONTROL
CREATE TABLE wfm_site_zones (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    name text NOT NULL,
    code text,
    zone_type text CHECK (zone_type IN ('general','restricted','high_risk','blast','confined_space','clean_room')),
    description text,
    additional_cert_required text[],
    is_active bool DEFAULT true,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_site_zones FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_site_zones ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_site_zones USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_site_access_logs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    zone_id uuid REFERENCES wfm_site_zones(id) ON DELETE SET NULL,
    check_in_time timestamptz DEFAULT now(),
    check_out_time timestamptz,
    check_in_method text CHECK (check_in_method IN ('qr','nfc','geofence','biometric','manual','vehicle','supervisor_batch')),
    compliance_status text DEFAULT 'compliant' CHECK (compliance_status IN ('compliant','blocked','warning')),
    compliance_issues jsonb DEFAULT '[]',
    override_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    override_reason text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_site_access_logs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_site_access_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_site_access_logs USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_mobilizations (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    mobilization_type text DEFAULT 'mobilize' CHECK (mobilization_type IN ('mobilize','demobilize')),
    status text DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
    initiated_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    approved_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    mobilized_at timestamptz,
    demobilized_at timestamptz,
    reason text,
    compliance_snapshot jsonb DEFAULT '{}',
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_mobilizations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_mobilizations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_mobilizations USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_lone_worker_checkins (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    scheduled_at timestamptz,
    checked_in_at timestamptz,
    status text DEFAULT 'pending' CHECK (status IN ('pending','completed','missed','escalated')),
    location_lat numeric(10,7),
    location_lng numeric(10,7),
    notes text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_lone_worker_checkins FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_lone_worker_checkins ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_lone_worker_checkins USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

-- MODULE 7: ROSTERING
CREATE TABLE wfm_shift_templates (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    name text NOT NULL,
    shift_type text CHECK (shift_type IN ('day','night','afternoon','rotating','fifo','dido','on_call')),
    start_time time NOT NULL,
    end_time time NOT NULL,
    break_duration_mins int DEFAULT 30,
    total_hours numeric(4,2),
    is_active bool DEFAULT true,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_shift_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_shift_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_shift_templates USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_rosters (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    name text NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    status text DEFAULT 'draft' CHECK (status IN ('draft','reviewed','published','archived')),
    created_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    published_at timestamptz,
    notes text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_rosters FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_rosters ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_rosters USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_roster_shifts (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    roster_id uuid REFERENCES wfm_rosters(id) ON DELETE CASCADE,
    shift_template_id uuid REFERENCES wfm_shift_templates(id) ON DELETE SET NULL,
    shift_date date NOT NULL,
    start_time time NOT NULL,
    end_time time NOT NULL,
    required_headcount int DEFAULT 1,
    role_required text,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    zone_id uuid REFERENCES wfm_site_zones(id) ON DELETE SET NULL,
    notes text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_roster_shifts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_roster_shifts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_roster_shifts USING (roster_id IN (SELECT id FROM wfm_rosters WHERE organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid())));

CREATE TABLE wfm_shift_assignments (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    roster_shift_id uuid REFERENCES wfm_roster_shifts(id) ON DELETE CASCADE,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    status text DEFAULT 'assigned' CHECK (status IN ('assigned','confirmed','declined','swapped','cancelled')),
    assigned_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    confirmed_at timestamptz,
    fatigue_score_at_assignment numeric(5,2),
    compliance_check_passed bool DEFAULT true,
    compliance_issues jsonb DEFAULT '[]',
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_shift_assignments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_shift_assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_shift_assignments USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_shift_swap_requests (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    assignment_id uuid REFERENCES wfm_shift_assignments(id) ON DELETE CASCADE,
    requesting_worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    swap_with_worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    status text DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected','cancelled')),
    approved_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    reason text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_shift_swap_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_shift_swap_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_shift_swap_requests USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

-- MODULE 8: TIME & ATTENDANCE
CREATE TABLE wfm_timesheets (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    status text DEFAULT 'draft' CHECK (status IN ('draft','submitted','approved','rejected','locked')),
    total_hours numeric(6,2),
    overtime_hours numeric(6,2),
    submitted_at timestamptz,
    approved_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    approved_at timestamptz,
    payroll_exported bool DEFAULT false,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_timesheets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_timesheets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_timesheets USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_time_entries (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    timesheet_id uuid REFERENCES wfm_timesheets(id) ON DELETE CASCADE,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    clock_in timestamptz NOT NULL,
    clock_out timestamptz,
    break_minutes int DEFAULT 0,
    regular_hours numeric(5,2),
    overtime_hours numeric(5,2) DEFAULT 0,
    clock_in_method text CHECK (clock_in_method IN ('mobile','qr','biometric','geofence','manual','supervisor')),
    clock_in_lat numeric(10,7),
    clock_in_lng numeric(10,7),
    project_code text,
    notes text,
    is_amended bool DEFAULT false,
    amended_reason text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_time_entries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_time_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_time_entries USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_attendance_records (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    record_date date NOT NULL,
    attendance_type text CHECK (attendance_type IN ('present','absent','late','early_departure','unplanned_leave','planned_leave')),
    roster_shift_id uuid REFERENCES wfm_roster_shifts(id) ON DELETE SET NULL,
    absence_reason text,
    return_to_work_required bool DEFAULT false,
    rtw_completed_at timestamptz,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_attendance_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_attendance_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_attendance_records USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_overtime_approvals (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    overtime_date date NOT NULL,
    hours_requested numeric(4,2),
    reason text,
    status text DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
    requested_at timestamptz DEFAULT now(),
    approved_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    approved_at timestamptz,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_overtime_approvals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_overtime_approvals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_overtime_approvals USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

-- MODULE 9: FATIGUE RISK
CREATE TABLE wfm_fatigue_risk_settings (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    max_shift_hours numeric(4,2) DEFAULT 12,
    max_daily_hours numeric(4,2) DEFAULT 14,
    max_weekly_hours numeric(4,2) DEFAULT 60,
    max_fortnight_hours numeric(4,2) DEFAULT 100,
    min_rest_between_shifts_hours numeric(4,2) DEFAULT 10,
    max_consecutive_days int DEFAULT 6,
    night_shift_multiplier numeric(3,2) DEFAULT 1.3,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_fatigue_risk_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_fatigue_risk_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_fatigue_risk_settings USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_fatigue_waivers (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    waiver_date date NOT NULL,
    hours_exceeded numeric(4,2),
    reason text NOT NULL,
    status text DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
    approved_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    approved_at timestamptz,
    operations_approved bool DEFAULT false,
    safety_approved bool DEFAULT false,
    expires_at timestamptz,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_fatigue_waivers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_fatigue_waivers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_fatigue_waivers USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_pre_shift_fatigue (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    assessment_date date NOT NULL,
    shift_start timestamptz,
    sleep_hours numeric(3,1),
    perceived_fatigue int CHECK (perceived_fatigue BETWEEN 1 AND 10),
    alertness_rating int CHECK (alertness_rating BETWEEN 1 AND 10),
    supervisor_assessment_passed bool DEFAULT true,
    supervisor_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    reaction_time_ms int,
    outcome text DEFAULT 'cleared' CHECK (outcome IN ('cleared','restricted','stood_down')),
    notes text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_pre_shift_fatigue FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_pre_shift_fatigue ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_pre_shift_fatigue USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

-- MODULE 10: HEALTH & MEDICAL
CREATE TABLE wfm_medical_providers (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    name text NOT NULL,
    provider_type text CHECK (provider_type IN ('occupational_health','gp','specialist','physio','psychologist','rehab')),
    contact_name text,
    contact_email text,
    contact_phone text,
    address text,
    services text[],
    is_approved bool DEFAULT false,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_medical_providers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_medical_providers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_medical_providers USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_health_surveillance_schedules (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    role_title text,
    hazard_exposure text,
    surveillance_type text CHECK (surveillance_type IN ('audiometry','spirometry','biological_monitoring','vision','skin','general_medical','da_test')),
    frequency_days int NOT NULL,
    description text,
    is_active bool DEFAULT true,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_health_surveillance_schedules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_health_surveillance_schedules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_health_surveillance_schedules USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_drug_alcohol_tests (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    test_date timestamptz NOT NULL,
    test_type text CHECK (test_type IN ('urine','breath','oral_fluid')),
    test_reason text CHECK (test_reason IN ('pre_employment','random','post_incident','for_cause','return_to_work')),
    result text CHECK (result IN ('negative','positive','inconclusive','refused')),
    tester_name text,
    breathalyser_reading numeric(6,4),
    chain_of_custody_ref text,
    stood_down bool DEFAULT false,
    eap_referred bool DEFAULT false,
    hr_notified bool DEFAULT false,
    notes text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_drug_alcohol_tests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_drug_alcohol_tests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_drug_alcohol_tests USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_rtw_plans (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    incident_id uuid REFERENCES incidents(id) ON DELETE SET NULL,
    plan_start date NOT NULL,
    expected_return_date date,
    full_return_date date,
    status text DEFAULT 'active' CHECK (status IN ('active','completed','paused','cancelled')),
    provider_id uuid REFERENCES wfm_medical_providers(id) ON DELETE SET NULL,
    treating_practitioner text,
    restrictions text,
    graduated_duties jsonb DEFAULT '[]',
    milestones jsonb DEFAULT '[]',
    workers_comp_claim text,
    created_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_rtw_plans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_rtw_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_rtw_plans USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_occupational_exposures (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    exposure_type text CHECK (exposure_type IN ('noise','dust','chemical','uv','vibration','biological','radiation')),
    exposure_date date NOT NULL,
    duration_hours numeric(5,2),
    exposure_level text,
    measurement_value numeric(10,4),
    measurement_unit text,
    above_threshold bool DEFAULT false,
    ppe_worn bool DEFAULT true,
    notes text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_occupational_exposures FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_occupational_exposures ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_occupational_exposures USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

-- MODULE 11: PPE MANAGEMENT
CREATE TABLE wfm_ppe_types (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    name text NOT NULL,
    code text,
    category text CHECK (category IN ('head','foot','eye','hearing','respiratory','hand','body','fall_arrest','chemical','cut_resistant')),
    description text,
    service_interval_days int,
    expiry_period_days int,
    requires_inspection bool DEFAULT false,
    is_serialized bool DEFAULT false,
    is_active bool DEFAULT true,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_ppe_types FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_ppe_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_ppe_types USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_ppe_inventory (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    ppe_type_id uuid REFERENCES wfm_ppe_types(id) ON DELETE SET NULL,
    quantity_in_stock int DEFAULT 0,
    reorder_threshold int DEFAULT 5,
    supplier text,
    unit_cost numeric(10,2),
    last_restocked_at timestamptz,
    notes text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_ppe_inventory FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_ppe_inventory ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_ppe_inventory USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_ppe_inspections (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    issuance_id uuid REFERENCES ppe_issuances(id) ON DELETE SET NULL,
    inspection_date date NOT NULL,
    inspector_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    result text CHECK (result IN ('pass','fail','quarantine')),
    findings text,
    photo_urls text[],
    next_inspection_date date,
    is_quarantined bool DEFAULT false,
    quarantine_reason text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_ppe_inspections FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_ppe_inspections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_ppe_inspections USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

-- MODULE 13: COMPLIANCE OBLIGATIONS
CREATE TABLE wfm_compliance_obligations (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    title text NOT NULL,
    obligation_type text CHECK (obligation_type IN ('legislative','code_of_practice','standard','internal_policy','contractual')),
    jurisdiction text,
    legislation_reference text,
    owner_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    due_date date,
    review_frequency_days int,
    status text DEFAULT 'compliant' CHECK (status IN ('compliant','non_compliant','overdue','under_review')),
    last_reviewed_at date,
    next_review_date date,
    evidence_url text,
    notes text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_compliance_obligations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_compliance_obligations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_compliance_obligations USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_nonconformances (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    obligation_id uuid REFERENCES wfm_compliance_obligations(id) ON DELETE SET NULL,
    title text NOT NULL,
    description text,
    severity text CHECK (severity IN ('minor','major','critical')),
    status text DEFAULT 'open' CHECK (status IN ('open','in_progress','closed')),
    assigned_to uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    due_date date,
    closed_at timestamptz,
    corrective_action text,
    evidence_url text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_nonconformances FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_nonconformances ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_nonconformances USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_audit_programs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    title text NOT NULL,
    audit_type text CHECK (audit_type IN ('internal','external','regulatory')),
    scheduled_date date,
    lead_auditor_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    status text DEFAULT 'planned' CHECK (status IN ('planned','in_progress','completed','cancelled')),
    findings_count int DEFAULT 0,
    nc_count int DEFAULT 0,
    report_url text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_audit_programs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_audit_programs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_audit_programs USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

-- MODULE 17: EMERGENCY MANAGEMENT
CREATE TABLE wfm_emergency_warden_assignments (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    warden_role text CHECK (warden_role IN ('chief_warden','area_warden','deputy_warden','first_aider','hse_lead')),
    shift_pattern text,
    is_active bool DEFAULT true,
    assigned_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    effective_from date,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_emergency_warden_assignments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_emergency_warden_assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_emergency_warden_assignments USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_emergency_activations (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid REFERENCES organisations(id) ON DELETE SET NULL,
    site_id uuid REFERENCES sites(id) ON DELETE SET NULL,
    activation_type text CHECK (activation_type IN ('evacuation','medical','fire','chemical_spill','structural','lockdown','missing_person','hazmat')),
    activated_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    activated_at timestamptz DEFAULT now(),
    all_clear_at timestamptz,
    headcount_total int,
    headcount_confirmed int,
    unaccounted_persons jsonb DEFAULT '[]',
    event_log jsonb DEFAULT '[]',
    post_incident_review text,
    is_drill bool DEFAULT false,
    status text DEFAULT 'active' CHECK (status IN ('active','resolved','false_alarm')),
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_emergency_activations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_emergency_activations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_emergency_activations USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));

CREATE TABLE wfm_muster_checkins (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    activation_id uuid REFERENCES wfm_emergency_activations(id) ON DELETE CASCADE,
    worker_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
    checked_in_at timestamptz DEFAULT now(),
    check_in_method text CHECK (check_in_method IN ('app','kiosk','manual','warden')),
    location text,
    is_safe bool DEFAULT true,
    notes text,
    created_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE wfm_muster_checkins ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_muster_checkins USING (activation_id IN (SELECT id FROM wfm_emergency_activations WHERE organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid())));

-- WFM SETTINGS
CREATE TABLE wfm_settings (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    organisation_id uuid UNIQUE REFERENCES organisations(id) ON DELETE SET NULL,
    site_timezone text DEFAULT 'Australia/Sydney',
    working_week_start text DEFAULT 'monday',
    pay_period_type text DEFAULT 'fortnightly' CHECK (pay_period_type IN ('weekly','fortnightly','monthly')),
    payroll_cutoff_day int DEFAULT 5,
    enable_lone_worker bool DEFAULT true,
    lone_worker_checkin_interval_mins int DEFAULT 30,
    enable_fatigue_management bool DEFAULT true,
    enable_drug_alcohol bool DEFAULT true,
    enable_biometric bool DEFAULT false,
    visitor_induction_required bool DEFAULT true,
    visitor_badge_expiry_hours int DEFAULT 8,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TRIGGER set_updated_at BEFORE UPDATE ON wfm_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER TABLE wfm_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "org_isolation" ON wfm_settings USING (organisation_id = (SELECT organisation_id FROM user_profiles WHERE id = auth.uid()));
