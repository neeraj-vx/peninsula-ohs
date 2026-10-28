-- =============================================================
-- D31: SECURITY DEFINER functions callable over RPC that took ids
-- without checking the caller's organisation. The app's only RPC is
-- create_notification; the rest are reached from triggers, cron, the
-- service role, or other SECURITY DEFINER functions (which run as
-- postgres and are unaffected by the REVOKEs below).
-- =============================================================

-- Audit history: any table's snapshots across tenants -> own org, managers only
CREATE OR REPLACE FUNCTION public.get_record_history(p_table_name text, p_record_id text)
RETURNS TABLE(version_number integer, action audit_action_enum, snapshot jsonb, changed_fields jsonb,
              changed_by_email text, ip_address text, created_at timestamptz)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT rv.version_number, rv.action, rv.snapshot, rv.changed_fields,
         rv.changed_by_email, rv.ip_address, rv.created_at
  FROM row_versions rv
  WHERE rv.table_name = p_table_name
    AND rv.record_id  = p_record_id
    AND (auth.uid() IS NULL
         OR (rv.organisation_id = get_my_organisation_id() AND is_safety_manager()))
  ORDER BY rv.version_number ASC;
$$;

CREATE OR REPLACE FUNCTION public.get_record_at_version(p_table_name text, p_record_id text, p_version integer)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT rv.snapshot
  FROM row_versions rv
  WHERE rv.table_name     = p_table_name
    AND rv.record_id      = p_record_id
    AND rv.version_number = p_version
    AND (auth.uid() IS NULL
         OR (rv.organisation_id = get_my_organisation_id() AND is_safety_manager()));
$$;

CREATE OR REPLACE FUNCTION public.get_incident_summary(p_incident_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'incident_number',    i.incident_number,
    'title',              i.title,
    'status',             i.status,
    'incident_type',      it.name,
    'severity_level',     sl.name,
    'severity_number',    sl.level_number,
    'site_name',          s.name,
    'department_name',    d.name,
    'submitted_by',       up.display_name,
    'incident_date',      i.incident_date,
    'was_injury',         i.was_injury_involved,
    'regulatory_required',i.regulatory_reportable,
    'open_capa_count',    (
      SELECT COUNT(*) FROM incident_capa c
      WHERE c.incident_id = i.id
        AND c.status NOT IN ('verified','closed')
    )
  )
  FROM incidents i
  LEFT JOIN incident_types it ON it.id = i.incident_type_id
  LEFT JOIN severity_levels sl ON sl.id = i.severity_level_id
  LEFT JOIN sites s ON s.id = i.site_id
  LEFT JOIN departments d ON d.id = i.department_id
  LEFT JOIN user_profiles up ON up.id = i.submitted_by
  WHERE i.id = p_incident_id
    AND (auth.uid() IS NULL OR i.organisation_id = get_my_organisation_id());
$$;

-- Cross-tenant writes: org guard + the role the matching table policy requires
CREATE OR REPLACE FUNCTION public.create_audit_finding_action(p_finding_id uuid, p_title text DEFAULT NULL, p_assigned_to uuid DEFAULT NULL,
                                                              p_priority text DEFAULT 'medium', p_due_date date DEFAULT NULL)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_finding   record;
  v_audit     record;
  v_action_id uuid;
  v_title     text;
BEGIN
  SELECT af.*, afo.name AS outcome_name
  INTO v_finding
  FROM audit_findings af
  JOIN audit_finding_outcomes afo ON afo.id = af.outcome_id
  WHERE af.id = p_finding_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Audit finding not found'; END IF;

  SELECT * INTO v_audit FROM audits WHERE id = v_finding.audit_id;

  IF auth.uid() IS NOT NULL AND (v_audit.organisation_id IS DISTINCT FROM get_my_organisation_id() OR NOT is_supervisor_or_above()) THEN
    RAISE EXCEPTION 'insufficient_privilege' USING ERRCODE = '42501';
  END IF;

  v_title := COALESCE(p_title, v_finding.outcome_name || ': ' || LEFT(v_finding.finding_text, 120));

  INSERT INTO actions (
    organisation_id, action_type, priority,
    source_type, source_id, source_reference,
    title, description,
    assigned_to, assigned_by, assigned_at,
    due_date, verification_required, created_by
  ) VALUES (
    v_audit.organisation_id, 'corrective', p_priority,
    'audit', v_finding.audit_id, v_audit.audit_number,
    v_title, COALESCE(v_finding.finding_text, v_title),
    p_assigned_to, auth.uid(), CASE WHEN p_assigned_to IS NOT NULL THEN now() END,
    p_due_date, true, auth.uid()
  ) RETURNING id INTO v_action_id;

  INSERT INTO audit_finding_actions (finding_id, action_id, organisation_id, created_by)
  VALUES (p_finding_id, v_action_id, v_audit.organisation_id, auth.uid());

  UPDATE audit_findings SET action_created = true, updated_at = now() WHERE id = p_finding_id;

  RETURN v_action_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_inspection_action(p_response_id uuid, p_issue_description text, p_title text DEFAULT NULL,
                                                           p_assigned_to uuid DEFAULT NULL, p_priority text DEFAULT 'medium', p_due_date date DEFAULT NULL)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_response     record;
  v_inspection   record;
  v_question     record;
  v_action_id    uuid;
  v_title        text;
BEGIN
  SELECT * INTO v_response   FROM inspection_responses ir WHERE ir.id = p_response_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Inspection response not found'; END IF;
  SELECT * INTO v_inspection FROM inspections i WHERE i.id = v_response.inspection_id;
  SELECT * INTO v_question   FROM inspection_template_questions WHERE id = v_response.question_id;

  -- Conductor of the inspection, or supervisor+, in the caller's org
  IF auth.uid() IS NOT NULL AND (
       v_inspection.organisation_id IS DISTINCT FROM get_my_organisation_id()
       OR NOT (is_supervisor_or_above() OR v_inspection.conducted_by = auth.uid())) THEN
    RAISE EXCEPTION 'insufficient_privilege' USING ERRCODE = '42501';
  END IF;

  v_title := COALESCE(p_title, v_question.suggested_action, 'Failed inspection item: ' || v_question.question_text);

  INSERT INTO actions (
    organisation_id, site_id, action_type, priority,
    source_type, source_id, source_reference,
    title, description,
    assigned_to, assigned_by, assigned_at,
    due_date, verification_required, created_by
  ) VALUES (
    v_inspection.organisation_id, v_inspection.site_id, 'corrective', p_priority,
    'inspection', v_inspection.id, v_inspection.inspection_number,
    v_title, COALESCE(p_issue_description, v_title),
    p_assigned_to, auth.uid(), CASE WHEN p_assigned_to IS NOT NULL THEN now() END,
    p_due_date, true, auth.uid()
  )
  RETURNING id INTO v_action_id;

  INSERT INTO inspection_actions (inspection_id, response_id, action_id, organisation_id, issue_description, created_by)
  VALUES (v_inspection.id, p_response_id, v_action_id, v_inspection.organisation_id, p_issue_description, auth.uid());

  UPDATE inspection_responses SET action_created = true, updated_at = now() WHERE id = p_response_id;
  UPDATE inspections SET has_open_actions = true, updated_at = now() WHERE id = v_inspection.id;

  RETURN v_action_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.promote_hazard_to_risk(p_report_id uuid, p_title text, p_likelihood_score integer, p_consequence_score integer,
                                                         p_existing_controls text DEFAULT NULL, p_residual_likelihood integer DEFAULT NULL,
                                                         p_residual_consequence integer DEFAULT NULL, p_owner_id uuid DEFAULT NULL,
                                                         p_category_id uuid DEFAULT NULL, p_review_frequency text DEFAULT 'quarterly')
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_report    record;
  v_risk_id   uuid;
BEGIN
  SELECT * INTO v_report FROM hazard_reports WHERE id = p_report_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Hazard report not found'; END IF;

  -- Same roles risk_insert allows, in the report's own org
  IF auth.uid() IS NOT NULL AND (v_report.organisation_id IS DISTINCT FROM get_my_organisation_id() OR NOT is_supervisor_or_above()) THEN
    RAISE EXCEPTION 'insufficient_privilege' USING ERRCODE = '42501';
  END IF;

  IF v_report.status = 'promoted_to_risk' THEN
    RAISE EXCEPTION 'Hazard report has already been promoted';
  END IF;

  INSERT INTO risks (
    organisation_id, site_id, department_id, work_area_id,
    category_id, title, hazard_description,
    location_activity, people_at_risk,
    likelihood_score, consequence_score,
    existing_controls_summary,
    residual_likelihood_score, residual_consequence_score,
    owner_id, review_frequency,
    source_type, source_id, source_reference,
    created_by
  ) VALUES (
    v_report.organisation_id, v_report.site_id, v_report.department_id, v_report.work_area_id,
    p_category_id, p_title, v_report.description,
    v_report.location_details, '{}',
    p_likelihood_score, p_consequence_score,
    p_existing_controls,
    p_residual_likelihood, p_residual_consequence,
    COALESCE(p_owner_id, auth.uid()), p_review_frequency,
    'hazard_report', v_report.id, v_report.report_number,
    auth.uid()
  )
  RETURNING id INTO v_risk_id;

  UPDATE hazard_reports
  SET status              = 'promoted_to_risk',
      promoted_to_risk_id = v_risk_id,
      reviewed_by         = auth.uid(),
      reviewed_at         = now(),
      updated_at          = now()
  WHERE id = p_report_id;

  PERFORM create_notification(
    'risks.hazard_promoted',
    v_report.organisation_id, v_report.site_id,
    'risk', v_risk_id,
    jsonb_build_object(
      'risk_number',    (SELECT risk_number FROM risks WHERE id = v_risk_id),
      'risk_title',     p_title,
      'report_number',  v_report.report_number,
      'reporter_id',    v_report.reported_by
    )
  );

  RETURN v_risk_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.publish_document_version(p_document_id uuid, p_version_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_doc record;
BEGIN
  SELECT * INTO v_doc FROM documents WHERE id = p_document_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Document not found'; END IF;

  IF auth.uid() IS NOT NULL AND (v_doc.organisation_id IS DISTINCT FROM get_my_organisation_id() OR NOT is_safety_manager()) THEN
    RAISE EXCEPTION 'Insufficient permission to publish documents' USING ERRCODE = '42501';
  END IF;

  -- The version must belong to this document
  IF NOT EXISTS (SELECT 1 FROM document_versions WHERE id = p_version_id AND document_id = p_document_id) THEN
    RAISE EXCEPTION 'Version does not belong to document';
  END IF;

  UPDATE document_versions SET status = 'archived', is_current = false
  WHERE document_id = p_document_id AND is_current = true AND id != p_version_id;

  UPDATE document_versions
  SET status = 'published', is_current = true
  WHERE id = p_version_id;

  UPDATE documents
  SET current_version_id = p_version_id,
      published_at       = now(),
      published_by       = auth.uid(),
      updated_at         = now()
  WHERE id = p_document_id;

  IF v_doc.requires_acknowledgement THEN
    PERFORM create_notification(
      'documents.acknowledgement_required',
      v_doc.organisation_id, NULL,
      'document', p_document_id,
      jsonb_build_object('document_title', v_doc.title)
    );
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.submit_document_for_review(p_document_id uuid, p_version_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_doc         record;
  v_step        record;
  v_workflow_id uuid;
BEGIN
  SELECT d.*, dv.status AS ver_status
  INTO v_doc
  FROM documents d
  JOIN document_versions dv ON dv.id = p_version_id AND dv.document_id = d.id
  WHERE d.id = p_document_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Document version not found'; END IF;

  IF auth.uid() IS NOT NULL AND v_doc.organisation_id IS DISTINCT FROM get_my_organisation_id() THEN
    RAISE EXCEPTION 'insufficient_privilege' USING ERRCODE = '42501';
  END IF;

  v_workflow_id := v_doc.review_workflow_id;

  IF v_workflow_id IS NULL THEN
    -- No workflow — auto-approve
    UPDATE document_versions
    SET status = 'approved', approved_by = auth.uid(), approved_at = now()
    WHERE id = p_version_id;
    RETURN;
  END IF;

  UPDATE document_versions
  SET status = 'in_review', submitted_for_review_at = now(), submitted_by = auth.uid()
  WHERE id = p_version_id;

  FOR v_step IN
    SELECT * FROM document_review_workflow_steps WHERE workflow_id = v_workflow_id ORDER BY order_index
  LOOP
    INSERT INTO document_version_reviews (
      document_id, version_id, workflow_step_id, organisation_id,
      reviewer_id, decision
    ) VALUES (
      p_document_id, p_version_id, v_step.id, v_doc.organisation_id,
      v_step.assigned_user_id, 'pending'
    )
    ON CONFLICT (version_id, workflow_step_id) DO NOTHING;

    PERFORM create_notification(
      'documents.review_requested', v_doc.organisation_id, NULL,
      'document', p_document_id,
      jsonb_build_object(
        'document_title', v_doc.title,
        'step_name',      v_step.step_name,
        'reporter_id',    v_step.assigned_user_id
      )
    );
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.revoke_all_user_sessions(p_target_user_id uuid, p_revoke_reason text DEFAULT 'admin_revoke')
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count integer;
BEGIN
  -- Self, or a System Admin of the target's own organisation
  IF p_target_user_id <> auth.uid() AND NOT (
       is_system_admin()
       AND EXISTS (SELECT 1 FROM user_profiles WHERE id = p_target_user_id AND organisation_id = get_my_organisation_id())) THEN
    RAISE EXCEPTION 'insufficient_privilege' USING ERRCODE = '42501';
  END IF;

  UPDATE user_sessions
  SET is_active     = false,
      revoked_at    = now(),
      revoked_by    = auth.uid(),
      revoke_reason = p_revoke_reason
  WHERE user_id  = p_target_user_id
    AND is_active = true;

  GET DIAGNOSTICS v_count = ROW_COUNT;

  PERFORM log_auth_event(
    p_event_type := 'session_revoked',
    p_user_id    := p_target_user_id,
    p_metadata   := jsonb_build_object('sessions_revoked', v_count, 'reason', p_revoke_reason, 'revoked_by', auth.uid())
  );

  RETURN v_count;
END;
$$;

-- Internal / service-only: not callable by signed-in users
REVOKE EXECUTE ON FUNCTION public.log_auth_event(auth_event_type_enum, uuid, text, text, text, boolean, text, text, text, jsonb) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.lookup_api_key(text)                  FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.stamp_api_key_last_used(text)         FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.schedule_delivery_retry(uuid, text)   FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.log_auth_event(auth_event_type_enum, uuid, text, text, text, boolean, text, text, text, jsonb) TO service_role;
GRANT  EXECUTE ON FUNCTION public.lookup_api_key(text)                  TO service_role;
GRANT  EXECUTE ON FUNCTION public.stamp_api_key_last_used(text)         TO service_role;
GRANT  EXECUTE ON FUNCTION public.schedule_delivery_retry(uuid, text)   TO service_role;

-- Advisor 0014: unaccent lived in public (nothing in the schema uses it)
ALTER EXTENSION unaccent SET SCHEMA extensions;
