-- PMS Module 1: Site & Property Register
CREATE TABLE pms_properties (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  site_id UUID REFERENCES sites(id),
  property_code TEXT,
  name TEXT NOT NULL,
  trading_name TEXT,
  property_type TEXT DEFAULT 'office',
  address TEXT,
  suburb TEXT,
  state TEXT DEFAULT 'NSW',
  postcode TEXT,
  country TEXT DEFAULT 'Australia',
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  timezone TEXT DEFAULT 'Australia/Sydney',
  operational_status TEXT DEFAULT 'active',
  established_date DATE,
  decommission_date DATE,
  ownership_type TEXT DEFAULT 'owned',
  landlord_name TEXT,
  landlord_contact TEXT,
  landlord_obligations TEXT,
  lease_expiry DATE,
  area_sqm DECIMAL(10,2),
  num_floors INTEGER DEFAULT 1,
  max_occupancy INTEGER,
  industry_sector TEXT,
  risk_tier TEXT DEFAULT 'medium',
  jurisdiction TEXT DEFAULT 'NSW',
  naics_code TEXT,
  wc_insurer TEXT,
  notes TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE pms_property_contacts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  property_id UUID NOT NULL REFERENCES pms_properties(id) ON DELETE CASCADE,
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  role_type TEXT NOT NULL,
  user_id UUID REFERENCES user_profiles(id),
  external_name TEXT,
  external_phone TEXT,
  external_email TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE pms_property_licences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  property_id UUID NOT NULL REFERENCES pms_properties(id) ON DELETE CASCADE,
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  licence_type TEXT NOT NULL,
  licence_number TEXT,
  issuing_authority TEXT,
  issue_date DATE,
  expiry_date DATE,
  renewal_lead_days INTEGER DEFAULT 30,
  renewal_responsible_user_id UUID REFERENCES user_profiles(id),
  status TEXT DEFAULT 'active',
  cost DECIMAL(10,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- PMS Module 2: Hazards & Risk
CREATE TABLE pms_hazards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  property_id UUID REFERENCES pms_properties(id),
  hazard_number TEXT,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT DEFAULT 'physical',
  source TEXT DEFAULT 'inspection',
  identified_date DATE DEFAULT CURRENT_DATE,
  identified_by_id UUID REFERENCES user_profiles(id),
  location_description TEXT,
  status TEXT DEFAULT 'open',
  inherent_likelihood INTEGER DEFAULT 3,
  inherent_consequence INTEGER DEFAULT 3,
  residual_likelihood INTEGER,
  residual_consequence INTEGER,
  risk_owner_id UUID REFERENCES user_profiles(id),
  review_due DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE pms_hazard_controls (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  hazard_id UUID NOT NULL REFERENCES pms_hazards(id) ON DELETE CASCADE,
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  control_type TEXT NOT NULL,
  description TEXT NOT NULL,
  owner_id UUID REFERENCES user_profiles(id),
  implementation_deadline DATE,
  verification_method TEXT,
  adequacy_rating TEXT DEFAULT 'adequate',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- PMS Module 3: Inspections
CREATE TABLE pms_inspections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  property_id UUID REFERENCES pms_properties(id),
  inspection_number TEXT,
  inspection_type TEXT NOT NULL DEFAULT 'routine_safety',
  title TEXT NOT NULL,
  scheduled_date DATE,
  completed_date DATE,
  assigned_to_id UUID REFERENCES user_profiles(id),
  status TEXT DEFAULT 'scheduled',
  score DECIMAL(5,2),
  outcome TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE pms_inspection_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  inspection_id UUID NOT NULL REFERENCES pms_inspections(id) ON DELETE CASCADE,
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  section TEXT,
  question TEXT NOT NULL,
  answer TEXT,
  score DECIMAL(5,2),
  notes TEXT,
  is_non_conformance BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- PMS Module 4: Compliance
CREATE TABLE pms_compliance_obligations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  property_id UUID REFERENCES pms_properties(id),
  obligation_number TEXT,
  title TEXT NOT NULL,
  description TEXT,
  regulatory_source TEXT,
  jurisdiction TEXT DEFAULT 'NSW',
  category TEXT DEFAULT 'whs',
  status TEXT DEFAULT 'compliant',
  responsible_user_id UUID REFERENCES user_profiles(id),
  review_frequency TEXT DEFAULT 'annually',
  next_review_date DATE,
  consequence TEXT,
  evidence_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- PMS Module 5: Incidents
CREATE TABLE pms_incidents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  property_id UUID REFERENCES pms_properties(id),
  incident_number TEXT,
  incident_type TEXT NOT NULL DEFAULT 'near_miss',
  title TEXT NOT NULL,
  description TEXT,
  incident_datetime TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  location_description TEXT,
  reported_by_id UUID REFERENCES user_profiles(id),
  injury_type TEXT,
  body_part TEXT,
  mechanism TEXT,
  immediate_cause TEXT,
  is_notifiable BOOLEAN DEFAULT FALSE,
  is_workers_comp BOOLEAN DEFAULT FALSE,
  days_lost INTEGER DEFAULT 0,
  status TEXT DEFAULT 'reported',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE pms_incident_investigations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  incident_id UUID NOT NULL REFERENCES pms_incidents(id) ON DELETE CASCADE,
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  methodology TEXT DEFAULT '5_whys',
  root_causes TEXT,
  contributing_factors TEXT,
  team_members TEXT,
  due_date DATE,
  completed_date DATE,
  status TEXT DEFAULT 'initiated',
  management_sign_off_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- PMS Module 6: Contractors & Visitors
CREATE TABLE pms_contractors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  property_id UUID REFERENCES pms_properties(id),
  company_name TEXT NOT NULL,
  abn TEXT,
  address TEXT,
  contact_name TEXT,
  contact_phone TEXT,
  contact_email TEXT,
  category TEXT DEFAULT 'general',
  approved_status TEXT DEFAULT 'pending',
  prequalification_score DECIMAL(5,2),
  prequalification_expiry DATE,
  pl_insurer TEXT,
  pl_policy_number TEXT,
  pl_expiry DATE,
  pl_limit DECIMAL(15,2),
  wc_insurer TEXT,
  wc_expiry DATE,
  performance_rating DECIMAL(3,1),
  is_blacklisted BOOLEAN DEFAULT FALSE,
  blacklist_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE pms_contractor_visits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  contractor_id UUID NOT NULL REFERENCES pms_contractors(id) ON DELETE CASCADE,
  property_id UUID REFERENCES pms_properties(id),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  visit_date DATE NOT NULL DEFAULT CURRENT_DATE,
  check_in TIMESTAMPTZ,
  check_out TIMESTAMPTZ,
  purpose TEXT,
  supervisor_id UUID REFERENCES user_profiles(id),
  status TEXT DEFAULT 'expected',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- PMS Module 7: Assets & Equipment
CREATE TABLE pms_assets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  property_id UUID REFERENCES pms_properties(id),
  asset_tag TEXT,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT DEFAULT 'plant',
  make TEXT,
  model TEXT,
  serial_number TEXT,
  manufacturer TEXT,
  supplier TEXT,
  purchase_date DATE,
  purchase_cost DECIMAL(12,2),
  location_description TEXT,
  custodian_id UUID REFERENCES user_profiles(id),
  status TEXT DEFAULT 'in_service',
  risk_classification TEXT DEFAULT 'low',
  warranty_expiry DATE,
  expected_eol DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE pms_asset_maintenance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  asset_id UUID NOT NULL REFERENCES pms_assets(id) ON DELETE CASCADE,
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  maintenance_type TEXT NOT NULL DEFAULT 'preventive',
  description TEXT,
  scheduled_date DATE,
  completed_date DATE,
  technician_id UUID REFERENCES user_profiles(id),
  technician_name TEXT,
  work_performed TEXT,
  parts_replaced TEXT,
  cost DECIMAL(10,2),
  status TEXT DEFAULT 'scheduled',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- PMS Module 8: Competencies (People)
CREATE TABLE pms_competencies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  property_id UUID REFERENCES pms_properties(id),
  worker_id UUID REFERENCES user_profiles(id),
  competency_name TEXT NOT NULL,
  category TEXT DEFAULT 'technical',
  assessment_date DATE,
  expiry_date DATE,
  status TEXT DEFAULT 'current',
  assessor_id UUID REFERENCES user_profiles(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- PMS Module 9: Emergency
CREATE TABLE pms_emergency_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  property_id UUID NOT NULL REFERENCES pms_properties(id),
  title TEXT NOT NULL,
  version TEXT DEFAULT '1.0',
  review_date DATE,
  reviewer_id UUID REFERENCES user_profiles(id),
  scenarios TEXT[],
  evacuation_procedures TEXT,
  muster_points TEXT,
  external_contacts TEXT,
  status TEXT DEFAULT 'current',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE pms_emergency_wardens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  property_id UUID NOT NULL REFERENCES pms_properties(id) ON DELETE CASCADE,
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  user_id UUID REFERENCES user_profiles(id),
  external_name TEXT,
  role_type TEXT NOT NULL DEFAULT 'floor_warden',
  zone_area TEXT,
  certification_expiry DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- PMS Module 10: Permits
CREATE TABLE pms_permits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  property_id UUID REFERENCES pms_properties(id),
  permit_number TEXT,
  permit_type TEXT NOT NULL DEFAULT 'hot_work',
  title TEXT NOT NULL,
  description TEXT,
  location TEXT,
  requested_by_id UUID REFERENCES user_profiles(id),
  approved_by_id UUID REFERENCES user_profiles(id),
  start_datetime TIMESTAMPTZ,
  end_datetime TIMESTAMPTZ,
  status TEXT DEFAULT 'draft',
  risk_level TEXT DEFAULT 'medium',
  worker_names TEXT,
  ppe_required TEXT,
  preconditions_met BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- PMS Module 11: Training
CREATE TABLE pms_training_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  property_id UUID REFERENCES pms_properties(id),
  worker_id UUID REFERENCES user_profiles(id),
  course_name TEXT NOT NULL,
  course_type TEXT DEFAULT 'induction',
  delivery_method TEXT DEFAULT 'face_to_face',
  completed_date DATE,
  expiry_date DATE,
  score DECIMAL(5,2),
  pass_score DECIMAL(5,2) DEFAULT 70,
  outcome TEXT DEFAULT 'in_progress',
  certificate_url TEXT,
  trainer_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- PMS Module 12: Documents
CREATE TABLE pms_documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  property_id UUID REFERENCES pms_properties(id),
  document_number TEXT,
  title TEXT NOT NULL,
  document_type TEXT DEFAULT 'procedure',
  author_id UUID REFERENCES user_profiles(id),
  owner_id UUID REFERENCES user_profiles(id),
  version TEXT DEFAULT '1.0',
  status TEXT DEFAULT 'draft',
  effective_date DATE,
  review_date DATE,
  file_url TEXT,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- PMS Module 13: CAPA
CREATE TABLE pms_actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  property_id UUID REFERENCES pms_properties(id),
  action_number TEXT,
  title TEXT NOT NULL,
  description TEXT,
  source TEXT DEFAULT 'inspection_finding',
  priority TEXT DEFAULT 'medium',
  assigned_to_id UUID REFERENCES user_profiles(id),
  due_date DATE,
  status TEXT DEFAULT 'open',
  verification_method TEXT,
  verified_by_id UUID REFERENCES user_profiles(id),
  verified_date DATE,
  closed_date DATE,
  evidence_url TEXT,
  effectiveness_rating TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- PMS Module 14: Environmental
CREATE TABLE pms_environmental_aspects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  property_id UUID REFERENCES pms_properties(id),
  aspect_type TEXT NOT NULL DEFAULT 'noise',
  description TEXT,
  significance_rating TEXT DEFAULT 'medium',
  applicable_legislation TEXT,
  control_measures TEXT,
  monitoring_required BOOLEAN DEFAULT FALSE,
  responsible_user_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE pms_environmental_monitoring (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  aspect_id UUID REFERENCES pms_environmental_aspects(id),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  property_id UUID REFERENCES pms_properties(id),
  monitoring_type TEXT NOT NULL DEFAULT 'noise',
  monitoring_date DATE NOT NULL DEFAULT CURRENT_DATE,
  location TEXT,
  value DECIMAL(12,4),
  unit TEXT,
  instrument_used TEXT,
  result_status TEXT DEFAULT 'normal',
  notes TEXT,
  created_by_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- PMS Module 16: Notification Rules
CREATE TABLE pms_notification_rules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  property_id UUID REFERENCES pms_properties(id),
  trigger_type TEXT NOT NULL,
  notify_user_ids UUID[] DEFAULT '{}',
  email_enabled BOOLEAN DEFAULT TRUE,
  advance_days INTEGER DEFAULT 7,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sequences for human-readable numbers
CREATE SEQUENCE pms_hazard_seq START 1;
CREATE SEQUENCE pms_inspection_seq START 1;
CREATE SEQUENCE pms_compliance_seq START 1;
CREATE SEQUENCE pms_incident_seq START 1;
CREATE SEQUENCE pms_permit_seq START 1;
CREATE SEQUENCE pms_action_seq START 1;
CREATE SEQUENCE pms_document_seq START 1;
CREATE SEQUENCE pms_property_seq START 1;

-- Auto-number triggers
CREATE OR REPLACE FUNCTION set_pms_property_number() RETURNS TRIGGER AS $$
BEGIN NEW.property_code := COALESCE(NEW.property_code, 'PROP-' || LPAD(nextval('pms_property_seq')::TEXT, 4, '0')); RETURN NEW; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_pms_property_number BEFORE INSERT ON pms_properties FOR EACH ROW EXECUTE FUNCTION set_pms_property_number();

CREATE OR REPLACE FUNCTION set_pms_hazard_number() RETURNS TRIGGER AS $$
BEGIN NEW.hazard_number := COALESCE(NEW.hazard_number, 'PH-' || LPAD(nextval('pms_hazard_seq')::TEXT, 4, '0')); RETURN NEW; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_pms_hazard_number BEFORE INSERT ON pms_hazards FOR EACH ROW EXECUTE FUNCTION set_pms_hazard_number();

CREATE OR REPLACE FUNCTION set_pms_inspection_number() RETURNS TRIGGER AS $$
BEGIN NEW.inspection_number := COALESCE(NEW.inspection_number, 'PI-' || LPAD(nextval('pms_inspection_seq')::TEXT, 4, '0')); RETURN NEW; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_pms_inspection_number BEFORE INSERT ON pms_inspections FOR EACH ROW EXECUTE FUNCTION set_pms_inspection_number();

CREATE OR REPLACE FUNCTION set_pms_incident_number() RETURNS TRIGGER AS $$
BEGIN NEW.incident_number := COALESCE(NEW.incident_number, 'PIN-' || LPAD(nextval('pms_incident_seq')::TEXT, 4, '0')); RETURN NEW; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_pms_incident_number BEFORE INSERT ON pms_incidents FOR EACH ROW EXECUTE FUNCTION set_pms_incident_number();

CREATE OR REPLACE FUNCTION set_pms_permit_number() RETURNS TRIGGER AS $$
BEGIN NEW.permit_number := COALESCE(NEW.permit_number, 'PP-' || LPAD(nextval('pms_permit_seq')::TEXT, 4, '0')); RETURN NEW; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_pms_permit_number BEFORE INSERT ON pms_permits FOR EACH ROW EXECUTE FUNCTION set_pms_permit_number();

CREATE OR REPLACE FUNCTION set_pms_action_number() RETURNS TRIGGER AS $$
BEGIN NEW.action_number := COALESCE(NEW.action_number, 'PA-' || LPAD(nextval('pms_action_seq')::TEXT, 4, '0')); RETURN NEW; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_pms_action_number BEFORE INSERT ON pms_actions FOR EACH ROW EXECUTE FUNCTION set_pms_action_number();

CREATE OR REPLACE FUNCTION set_pms_document_number() RETURNS TRIGGER AS $$
BEGIN NEW.document_number := COALESCE(NEW.document_number, 'PD-' || LPAD(nextval('pms_document_seq')::TEXT, 4, '0')); RETURN NEW; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_pms_document_number BEFORE INSERT ON pms_documents FOR EACH ROW EXECUTE FUNCTION set_pms_document_number();

CREATE OR REPLACE FUNCTION set_pms_compliance_number() RETURNS TRIGGER AS $$
BEGIN NEW.obligation_number := COALESCE(NEW.obligation_number, 'PC-' || LPAD(nextval('pms_compliance_seq')::TEXT, 4, '0')); RETURN NEW; END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_pms_compliance_number BEFORE INSERT ON pms_compliance_obligations FOR EACH ROW EXECUTE FUNCTION set_pms_compliance_number();

-- RLS
ALTER TABLE pms_properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_property_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_property_licences ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_hazards ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_hazard_controls ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_inspection_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_compliance_obligations ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_incident_investigations ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_contractors ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_contractor_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_asset_maintenance ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_competencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_emergency_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_emergency_wardens ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_permits ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_training_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_environmental_aspects ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_environmental_monitoring ENABLE ROW LEVEL SECURITY;
ALTER TABLE pms_notification_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "org_isolation" ON pms_properties FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_property_contacts FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_property_licences FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_hazards FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_hazard_controls FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_inspections FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_inspection_items FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_compliance_obligations FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_incidents FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_incident_investigations FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_contractors FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_contractor_visits FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_assets FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_asset_maintenance FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_competencies FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_emergency_plans FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_emergency_wardens FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_permits FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_training_records FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_documents FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_actions FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_environmental_aspects FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_environmental_monitoring FOR ALL USING (organisation_id = get_my_organisation_id());
CREATE POLICY "org_isolation" ON pms_notification_rules FOR ALL USING (organisation_id = get_my_organisation_id());
