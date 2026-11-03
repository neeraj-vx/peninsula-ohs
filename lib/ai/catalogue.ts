// What the assistant is allowed to read, and what each table means.
// Every query runs with the signed-in user's Supabase session, so row-level
// security keeps results inside their organisation and their permissions.
// Column lists come from the live schema (organisation_id/updated_at/deleted_at omitted).

export interface TableInfo {
  description: string
  columns: string
  /** App route for a single record, e.g. /incidents/{id} */
  route?: string
}

export const ENUMS: Record<string, string> = {
  action_type_enum: 'corrective, preventive, immediate, long_term',
  action_status_enum: 'open, in_progress, completed, verification_pending, verified, closed, overdue, reopened, cancelled',
  capa_status_enum: 'open, in_progress, pending_verification, verified, closed, overdue',
  hazard_report_status_enum: 'submitted, under_review, promoted_to_risk, actioned, closed, rejected',
  incident_status_enum: 'draft, submitted, triaged, under_investigation, capa_in_progress, pending_approval, closed, cancelled',
  inspection_result_enum: 'pass, conditional_pass, fail',
  inspection_status_enum: 'scheduled, draft, in_progress, completed, submitted, cancelled',
  investigation_status_enum: 'assigned, in_progress, rca_complete, capa_in_progress, pending_review, complete',
  risk_status_enum: 'active, under_review, closed, superseded',
  worker_licence_status: 'active, expired, suspended, cancelled',
  'actions.priority': 'low, medium, high, critical',
  'hazard_reports.severity_perception': 'low, medium, high',
  'hazard_reports.hazard_category': 'physical, chemical, electrical, biological, ergonomic, psychosocial, fire, environmental, other',
}

export const TABLES: Record<string, TableInfo> = {
  incidents: {
    description: 'Safety incidents: injuries, near misses, property damage. Join incident_types(name) and severity_levels(name).',
    route: '/incidents/{id}',
    columns: 'id:uuid,site_id:uuid,department_id:uuid,incident_number:text,incident_type_id:uuid,severity_level_id:uuid,title:text,description:text,incident_date:date,incident_time:time,exact_location:text,immediate_actions_taken:text,was_injury_involved:boolean,status:incident_status_enum,assigned_to:uuid,submitted_by:uuid,submitted_at:timestamptz,triaged_at:timestamptz,triage_notes:text,regulatory_reportable:boolean,regulatory_submitted:boolean,regulatory_due_date:date,closed_at:timestamptz,closure_notes:text,created_at:timestamptz,created_by:uuid',
  },
  incident_types: { description: 'Lookup of incident types.', columns: 'id:uuid,code:text,name:text,description:text,is_active:boolean' },
  severity_levels: { description: 'Lookup of incident severity levels.', columns: 'id:uuid,level_number:integer,name:text,description:text,investigation_required:boolean,regulatory_reporting_required:boolean,response_required_within_hours:integer,is_active:boolean' },
  incident_capa: {
    description: 'Corrective and preventive actions raised from incidents/investigations.',
    columns: 'id:uuid,incident_id:uuid,investigation_id:uuid,capa_number:text,title:text,description:text,capa_type:text,priority:text,assigned_to:uuid,due_date:date,status:capa_status_enum,completed_at:timestamptz,verified_at:timestamptz,created_at:timestamptz,action_id:uuid',
  },
  investigations: {
    description: 'Incident investigations and root-cause analysis.',
    route: '/investigations/{id}',
    columns: 'id:uuid,incident_id:uuid,investigation_number:text,investigator_id:uuid,status:investigation_status_enum,rca_method:text,start_date:date,target_completion_date:date,actual_completion_date:date,background:text,contributing_factors:text,investigation_summary:text,lessons_learned:text,created_at:timestamptz',
  },
  hazard_reports: {
    description: 'Hazards reported by workers.',
    route: '/hazards/{id}',
    columns: 'id:uuid,site_id:uuid,report_number:text,title:text,description:text,location_details:text,severity_perception:text,hazard_category:text,reported_by:uuid,reported_at:timestamptz,status:hazard_report_status_enum,review_notes:text,action_taken:text,promoted_to_risk_id:uuid,observed_at:timestamptz,immediate_risk_to_people:boolean,suggested_control:text,created_at:timestamptz',
  },
  risks: {
    description: 'Risk register. Scores are likelihood x consequence. is_template=true rows are templates, not live risks.',
    route: '/risks/{id}',
    columns: 'id:uuid,site_id:uuid,category_id:uuid,risk_number:text,title:text,hazard_description:text,location_activity:text,likelihood_score:integer,consequence_score:integer,inherent_risk_score:integer,inherent_risk_level:text,existing_controls_summary:text,residual_risk_score:integer,residual_risk_level:text,owner_id:uuid,review_frequency:text,next_review_date:date,last_reviewed_at:timestamptz,status:risk_status_enum,source_type:text,notes:text,created_at:timestamptz,is_template:boolean',
  },
  risk_controls: { description: 'Controls attached to a risk.', columns: 'id:uuid,risk_id:uuid,control_type:text,control_hierarchy:text,description:text,is_implemented:boolean,implementation_date:date,assigned_to:uuid,effectiveness_rating:integer,review_date:date' },
  actions: {
    description: 'Action items / tasks (corrective actions, follow-ups). "My tasks" = assigned_to = current user.',
    route: '/actions/{id}',
    columns: 'id:uuid,site_id:uuid,action_number:text,action_type:action_type_enum,priority:text,source_type:text,source_id:uuid,source_reference:text,title:text,description:text,assigned_to:uuid,assigned_by:uuid,due_date:date,extended_due_date:date,verification_required:boolean,status:action_status_enum,completion_notes:text,completed_at:timestamptz,verified_at:timestamptz,created_at:timestamptz,created_by:uuid',
  },
  inspections: {
    description: 'Completed or scheduled inspections.',
    route: '/inspections/{id}',
    columns: 'id:uuid,site_id:uuid,template_id:uuid,schedule_id:uuid,inspection_number:text,conducted_by:uuid,conducted_by_name:text,started_at:timestamptz,completed_at:timestamptz,status:inspection_status_enum,result:inspection_result_enum,score:numeric,failed_questions:integer,is_overdue:boolean,has_open_actions:boolean,notes:text,created_at:timestamptz,asset_id:uuid',
  },
  inspection_templates: { description: 'Inspection checklists.', columns: 'id:uuid,name:text,description:text,version:integer,is_published:boolean,passing_score_threshold:numeric,is_active:boolean' },
  inspection_schedules: { description: 'Recurring inspection schedules.', columns: 'id:uuid,site_id:uuid,template_id:uuid,name:text,assigned_to:uuid,recurrence_type:text,next_due_at:timestamptz,last_completed_at:timestamptz,is_active:boolean,asset_id:uuid' },
  audits: {
    description: 'Audits against standards with conformance counts.',
    route: '/audits/{id}',
    columns: 'id:uuid,audit_number:text,title:text,scope:text,standard_reference:text,lead_auditor_id:uuid,planned_start_date:date,planned_end_date:date,actual_end_date:date,status:text,total_criteria:integer,conformance_count:integer,minor_nc_count:integer,major_nc_count:integer,observation_count:integer,overall_rating:text,executive_summary:text,created_at:timestamptz',
  },
  audit_findings: { description: 'Findings within an audit.', columns: 'id:uuid,audit_id:uuid,criterion_id:uuid,finding_text:text,objective_evidence:text,root_cause:text,recommendation:text,action_created:boolean,assessed_at:timestamptz' },
  permits: {
    description: 'Permits to work (hot work, confined space, etc.). Join permit_types(name).',
    route: '/permits/{id}',
    columns: 'id:uuid,site_id:uuid,permit_number:text,permit_type_id:uuid,status_id:uuid,title:text,work_description:text,exact_location:text,valid_from:timestamptz,valid_until:timestamptz,actual_start:timestamptz,actual_end:timestamptz,applicant_id:uuid,responsible_person_id:uuid,isolation_requirements:text,closed_at:timestamptz,created_at:timestamptz',
  },
  permit_types: { description: 'Lookup of permit types.', columns: 'id:uuid,code:text,name:text,description:text,rescue_plan_required:boolean,isolation_required:boolean,max_duration_hours:integer' },
  jsas: { description: 'Job safety analyses.', route: '/jsa/{id}', columns: 'id:uuid,jsa_number:text,title:text,job_description:text,location:text,site_id:uuid,status:text,revision_number:integer,valid_from:date,valid_until:date,prepared_by:uuid,approved_at:timestamptz,created_at:timestamptz' },
  loto_procedures: { description: 'Lockout/tagout procedures.', route: '/loto/{id}', columns: 'id:uuid,procedure_number:text,title:text,description:text,asset_description:text,site_id:uuid,status:text,next_review_date:date,created_at:timestamptz' },
  toolbox_talk_deliveries: { description: 'Toolbox talks delivered.', columns: 'id:uuid,delivery_number:text,title:text,site_id:uuid,delivered_by:uuid,delivered_at:timestamptz,location:text,notes:text' },
  training_courses: { description: 'Training courses catalogue.', columns: 'id:uuid,code:text,name:text,description:text,course_type:text,training_type:text,duration_hours:numeric,validity_period_months:integer,is_certification:boolean,is_active:boolean' },
  training_records: { description: 'Completed training per worker (worker_id = user_profiles.id). Join training_courses(name).', columns: 'id:uuid,record_number:text,worker_id:uuid,course_id:uuid,completed_date:date,expiry_date:date,delivery_method:text,provider:text,certificate_number:text,status:text,created_at:timestamptz' },
  training_assignments: { description: 'Required training assigned to workers, with due dates. Join training_courses(name).', columns: 'id:uuid,worker_id:uuid,course_id:uuid,source:text,status:text,assigned_at:timestamptz,due_date:date,completed_at:timestamptz,waived_reason:text' },
  worker_licences: { description: 'Worker licences and tickets with expiry.', columns: 'id:uuid,worker_id:uuid,licence_type:text,licence_number:text,issuing_body:text,issuing_province:text,issue_date:date,expiry_date:date,status:worker_licence_status' },
  user_profiles: { description: 'People / workers in the organisation.', route: '/workers/{id}', columns: 'id:uuid,employee_id:text,first_name:text,last_name:text,display_name:text,email:text,phone:text,employment_type:text,primary_site_id:uuid,primary_department_id:uuid,job_title:text,hire_date:date,is_active:boolean,last_login_at:timestamptz,created_at:timestamptz' },
  sites: { description: 'Work sites / locations.', columns: 'id:uuid,name:text,code:text,site_type:text,address:jsonb,timezone:text,is_active:boolean' },
  departments: { description: 'Departments within sites.', columns: 'id:uuid,site_id:uuid,name:text,code:text,manager_id:uuid,is_active:boolean' },
  teams: { description: 'Teams.', columns: 'id:uuid,department_id:uuid,name:text,team_lead_id:uuid,is_active:boolean' },
  documents: { description: 'Controlled documents and policies.', route: '/documents/{id}', columns: 'id:uuid,site_id:uuid,document_number:text,title:text,name:text,description:text,category:text,document_type_id:uuid,file_name:text,file_mime_type:text,tags:text[],version_number:text,requires_acknowledgement:boolean,review_due_date:date,expiry_date:date,is_controlled_document:boolean,published_at:timestamptz,owner_id:uuid,is_active:boolean,created_at:timestamptz' },
  document_types: { description: 'Lookup of document types (Policy, Procedure, SWP, SOP, Emergency Plan, …).', columns: 'id:uuid,name:text,code:text,is_active:boolean' },
  document_acknowledgements: { description: 'Who has acknowledged which document.', columns: 'id:uuid,document_id:uuid,user_id:uuid,acknowledged_at:timestamptz,method:text' },
  assets: { description: 'Equipment register.', route: '/assets/{id}', columns: 'id:uuid,site_id:uuid,asset_number:text,name:text,description:text,serial_number:text,manufacturer:text,model:text,location_details:text,inspection_frequency:text,next_inspection_due:date,last_inspected_at:date,next_maintenance_due:date,last_maintained_at:date,is_active:boolean,risk_classification:text' },
  asset_maintenance_records: { description: 'Maintenance history for assets.', columns: 'id:uuid,asset_id:uuid,maintenance_number:text,performed_by_name:text,performed_at:timestamptz,next_maintenance_due:date,description:text,findings:text,total_cost:numeric' },
  chemicals: { description: 'Chemical register (WHMIS) with SDS details.', route: '/chemicals/{id}', columns: 'id:uuid,site_id:uuid,chemical_number:text,name:text,cas_number:text,un_number:text,is_hazardous:boolean,storage_class:text,supplier_name:text,manufacturer_name:text,sds_review_date:date,sds_issue_date:date,next_review_date:date,current_quantity:numeric,quantity_unit:text,storage_location:text,emergency_first_aid:text,emergency_spill:text,emergency_fire:text,is_active:boolean' },
  ppe_items: { description: 'PPE stock.', columns: 'id:uuid,ppe_type_id:uuid,item_code:text,brand:text,model:text,size:text,quantity_total:integer,quantity_available:integer,site_id:uuid,expiry_date:date' },
  ppe_issuances: { description: 'PPE issued to workers.', columns: 'id:uuid,worker_id:uuid,ppe_item_id:uuid,issued_date:date,expected_return_date:date,returned_date:date,status:text' },
  contractor_companies: { description: 'Contractor companies and prequalification.', route: '/contractors/{id}', columns: 'id:uuid,company_name:text,primary_contact_name:text,primary_contact_email:text,primary_contact_phone:text,prequalification_status:text,prequalification_expiry:date,is_active:boolean,business_number:text' },
  contractor_workers: { description: 'Contractor workers.', columns: 'id:uuid,contractor_id:uuid,first_name:text,last_name:text,email:text,role:text,is_active:boolean,induction_status:text,inducted_at:timestamptz' },
  compliance_obligations: { description: 'Recurring legal/compliance obligations.', columns: 'id:uuid,title:text,description:text,regulatory_body:text,standard_reference:text,site_id:uuid,frequency:text,next_due_date:date,owner_id:uuid,status:text,is_critical:boolean' },
  compliance_tasks: { description: 'Individual due tasks for compliance obligations.', columns: 'id:uuid,obligation_id:uuid,task_number:text,title:text,due_date:date,assigned_to:uuid,status:text,completed_at:timestamptz' },
  regulatory_requirements: { description: 'Regulatory clauses that apply to the organisation.', columns: 'id:uuid,standard_id:uuid,clause_reference:text,title:text,description:text,requirement_type:text,is_applicable:boolean' },
  emergency_response_plans: { description: 'Emergency response plans.', columns: 'id:uuid,plan_number:text,title:text,site_id:uuid,description:text,status:text,last_reviewed_date:date,next_review_date:date' },
  emergency_drills: { description: 'Emergency drills.', columns: 'id:uuid,plan_id:uuid,site_id:uuid,drill_number:text,title:text,scheduled_date:date,actual_date:date,status:text,drill_type:text,participants_count:integer,duration_minutes:integer,outcomes:text,findings:text' },
  hires: { description: 'Hiring workflow records for new hires.', route: '/hiring/{id}', columns: 'id:uuid,hire_number:text,status:text,current_step:integer,candidate_first_name:text,candidate_last_name:text,candidate_email:text,position_title:text,employment_type:text,site_id:uuid,start_date:date,compliance_province:text,compliance_passed_at:timestamptz,bgc_required:boolean,bgc_status:text,completed_at:timestamptz,created_at:timestamptz' },
  speak_up_reports: { description: 'Confidential speak-up concerns (visible to managers only).', columns: 'id:uuid,report_number:text,category_id:uuid,description:text,date_of_incident:date,location:text,site_id:uuid,severity:text,status:text,assigned_to:uuid,closed_at:timestamptz,created_at:timestamptz' },
  health_check_records: { description: 'Health surveillance check results.', columns: 'id:uuid,user_id:uuid,check_number:text,result:text,check_date:date,next_check_due:date,restrictions_issued:boolean' },
  fatigue_alerts: { description: 'Fatigue rule breaches.', columns: 'id:uuid,worker_id:uuid,alert_type:text,actual_value:numeric,threshold_value:numeric,severity:text,status:text,created_at:timestamptz' },
  env_monitoring_records: { description: 'Environmental monitoring measurements.', columns: 'id:uuid,site_id:uuid,parameter_type_id:uuid,measured_value:numeric,measured_at:timestamptz,exceeds_limit:boolean,investigation_required:boolean,corrective_action:text' },
  kpi_snapshots: { description: 'Computed KPI values per period (e.g. TRIR, LTIR).', columns: 'id:uuid,kpi_definition_id:uuid,site_id:uuid,period_type:text,period_start:date,period_end:date,value:numeric,numerator:numeric,denominator:numeric,is_current:boolean' },
  notifications: { description: "The current user's notifications.", columns: 'id:uuid,recipient_user_id:uuid,title:text,body:text,trigger_entity_type:text,trigger_entity_id:uuid,is_read:boolean,created_at:timestamptz' },
  wellbeing_resources: { description: 'Wellbeing / EAP support resources.', columns: 'id:uuid,title:text,description:text,resource_type:text,contact_name:text,contact_phone:text,contact_email:text,website_url:text,is_active:boolean' },
  rule_findings: { description: 'Rules-engine compliance check results.', columns: 'id:uuid,rule_version_id:uuid,subject_type:text,subject_id:uuid,passed:boolean,severity:text,message:text,evaluated_at:timestamptz' },
}

export const TABLE_NAMES = Object.keys(TABLES) as [string, ...string[]]

export function catalogueText(): string {
  const tables = Object.entries(TABLES)
    .map(([name, t]) => `- ${name}${t.route ? ` (link: ${t.route})` : ''}: ${t.description}\n  columns: ${t.columns}`)
    .join('\n')
  const enums = Object.entries(ENUMS).map(([k, v]) => `- ${k}: ${v}`).join('\n')
  return `${tables}\n\nAllowed values:\n${enums}`
}
