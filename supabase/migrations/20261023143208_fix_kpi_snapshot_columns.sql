-- =============================================================
-- D4: compute_kpi_snapshot referenced columns that don't exist
-- (incidents.occurred_at, incident_medical.days_lost / treatment_type).
-- Real columns: incident_date, lost_time_days, treatment_provided.
-- treatment_provided is free text with no app writer yet, so an
-- injury is recordable when any of these hold:
--   treatment_provided in (medical_treatment, hospitalisation, fatality)
--   hospital_admission = true
--   lost_time_days > 0
-- Base stays 1,000,000 hours (TRIR/LTIR on 200k is decision C10).
-- =============================================================

CREATE OR REPLACE FUNCTION public.compute_kpi_snapshot(p_formula_key text, p_org_id uuid, p_site_id uuid, p_period_type text, p_period_start date, p_period_end date)
 RETURNS numeric
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_kpi_id     uuid;
  v_value      decimal(18,4) := NULL;
  v_numer      decimal(18,4) := NULL;
  v_denom      decimal(18,4) := NULL;
  v_hours      decimal(18,4);
BEGIN
  SELECT id INTO v_kpi_id FROM kpi_definitions WHERE formula_key = p_formula_key;
  IF NOT FOUND THEN RETURN NULL; END IF;

  -- Helper: sum hours worked for the scope and period
  SELECT COALESCE(SUM(whl.hours_worked), 0)
  INTO v_hours
  FROM workforce_hours_logs whl
  WHERE whl.organisation_id = p_org_id
    AND (p_site_id IS NULL OR whl.site_id = p_site_id)
    AND whl.period_start >= p_period_start
    AND whl.period_end   <= p_period_end;

  CASE p_formula_key

    -- =========================================================
    -- TRIFR — Total Recordable Injury Frequency Rate
    -- (Recordable incidents × 1,000,000) / Hours worked
    -- =========================================================
    WHEN 'trifr' THEN
      SELECT COUNT(DISTINCT i.id)
      INTO v_numer
      FROM incidents i
      JOIN incident_medical im ON im.incident_id = i.id
      WHERE i.organisation_id = p_org_id
        AND (p_site_id IS NULL OR i.site_id = p_site_id)
        AND i.incident_date BETWEEN p_period_start AND p_period_end
        AND (im.treatment_provided IN ('medical_treatment','hospitalisation','fatality')
             OR im.hospital_admission
             OR COALESCE(im.lost_time_days, 0) > 0);

      v_denom := NULLIF(v_hours, 0);
      IF v_denom IS NOT NULL THEN
        v_value := ROUND((v_numer * 1000000.0) / v_denom, 4);
      END IF;

    -- =========================================================
    -- LTIFR — Lost Time Injury Frequency Rate
    -- (Lost time incidents × 1,000,000) / Hours worked
    -- =========================================================
    WHEN 'ltifr' THEN
      SELECT COUNT(DISTINCT i.id)
      INTO v_numer
      FROM incidents i
      JOIN incident_medical im ON im.incident_id = i.id
      WHERE i.organisation_id = p_org_id
        AND (p_site_id IS NULL OR i.site_id = p_site_id)
        AND i.incident_date BETWEEN p_period_start AND p_period_end
        AND im.lost_time_days > 0;

      v_denom := NULLIF(v_hours, 0);
      IF v_denom IS NOT NULL THEN
        v_value := ROUND((v_numer * 1000000.0) / v_denom, 4);
      END IF;

    -- =========================================================
    -- Severity Rate — days lost per million hours worked
    -- =========================================================
    WHEN 'severity_rate' THEN
      SELECT COALESCE(SUM(im.lost_time_days), 0)
      INTO v_numer
      FROM incidents i
      JOIN incident_medical im ON im.incident_id = i.id
      WHERE i.organisation_id = p_org_id
        AND (p_site_id IS NULL OR i.site_id = p_site_id)
        AND i.incident_date BETWEEN p_period_start AND p_period_end
        AND im.lost_time_days IS NOT NULL;

      v_denom := NULLIF(v_hours, 0);
      IF v_denom IS NOT NULL THEN
        v_value := ROUND((v_numer * 1000000.0) / v_denom, 4);
      END IF;

    -- =========================================================
    -- Near Miss Rate
    -- =========================================================
    WHEN 'near_miss_rate' THEN
      SELECT COUNT(i.id)
      INTO v_numer
      FROM incidents i
      JOIN incident_types it ON it.id = i.incident_type_id
      WHERE i.organisation_id = p_org_id
        AND (p_site_id IS NULL OR i.site_id = p_site_id)
        AND i.incident_date BETWEEN p_period_start AND p_period_end
        AND it.code = 'near_miss';

      v_denom := NULLIF(v_hours, 0);
      IF v_denom IS NOT NULL THEN
        v_value := ROUND((v_numer * 1000000.0) / v_denom, 4);
      END IF;

    -- =========================================================
    -- Inspection Completion Rate — % of scheduled inspections
    -- completed on or before their scheduled date
    -- =========================================================
    WHEN 'inspection_completion_rate' THEN
      SELECT
        COUNT(*) FILTER (WHERE i.status = 'submitted' AND i.submitted_at::date <= is2.next_due_at::date),
        COUNT(*)
      INTO v_numer, v_denom
      FROM inspection_schedules is2
      JOIN inspections i ON i.schedule_id = is2.id
      WHERE is2.organisation_id = p_org_id
        AND (p_site_id IS NULL OR is2.site_id = p_site_id)
        AND i.scheduled_date BETWEEN p_period_start AND p_period_end;

      IF COALESCE(v_denom, 0) > 0 THEN
        v_value := ROUND((v_numer / v_denom) * 100.0, 2);
      END IF;

    -- =========================================================
    -- Action Closure Rate — % of CAPA actions closed on or
    -- before their due date within the period
    -- =========================================================
    WHEN 'action_closure_rate' THEN
      SELECT
        COUNT(*) FILTER (
          WHERE a.status IN ('verified','closed')
            AND COALESCE(a.verified_at, a.completed_at)::date
                  <= COALESCE(a.extended_due_date, a.due_date)
        ),
        COUNT(*)
      INTO v_numer, v_denom
      FROM actions a
      WHERE a.organisation_id = p_org_id
        AND (p_site_id IS NULL OR a.site_id = p_site_id)
        AND a.due_date BETWEEN p_period_start AND p_period_end;

      IF COALESCE(v_denom, 0) > 0 THEN
        v_value := ROUND((v_numer / v_denom) * 100.0, 2);
      END IF;

    -- =========================================================
    -- Audit Score — average conformance % across completed audits
    -- =========================================================
    WHEN 'audit_score' THEN
      SELECT
        ROUND(AVG(
          CASE WHEN a.total_criteria > 0
               THEN (a.conformance_count::decimal / a.total_criteria) * 100
          END
        ), 2),
        COUNT(*)
      INTO v_value, v_numer
      FROM audits a
      WHERE a.organisation_id = p_org_id
        AND (p_site_id IS NULL OR p_site_id = ANY(a.site_ids))
        AND a.status = 'completed'
        AND a.actual_end_date BETWEEN p_period_start AND p_period_end;

      v_denom := v_numer;

    -- =========================================================
    -- Hazard Report Rate
    -- (Hazard reports × 1,000,000) / Hours worked
    -- =========================================================
    WHEN 'hazard_report_rate' THEN
      SELECT COUNT(hr.id)
      INTO v_numer
      FROM hazard_reports hr
      WHERE hr.organisation_id = p_org_id
        AND (p_site_id IS NULL OR hr.site_id = p_site_id)
        AND hr.created_at::date BETWEEN p_period_start AND p_period_end;

      v_denom := NULLIF(v_hours, 0);
      IF v_denom IS NOT NULL THEN
        v_value := ROUND((v_numer * 1000000.0) / v_denom, 4);
      END IF;

    ELSE
      v_value := NULL;
  END CASE;

  -- Mark previous snapshots for this scope as not current
  UPDATE kpi_snapshots
  SET is_current = false
  WHERE kpi_definition_id = v_kpi_id
    AND organisation_id   = p_org_id
    AND (site_id          = p_site_id OR (site_id IS NULL AND p_site_id IS NULL))
    AND period_type       = p_period_type
    AND period_start      = p_period_start;

  -- Upsert the new snapshot
  INSERT INTO kpi_snapshots (
    kpi_definition_id, organisation_id, site_id, period_type,
    period_start, period_end, value, numerator, denominator,
    is_current, computed_at
  ) VALUES (
    v_kpi_id, p_org_id, p_site_id, p_period_type,
    p_period_start, p_period_end, v_value, v_numer, v_denom,
    true, now()
  )
  ON CONFLICT (kpi_definition_id, organisation_id, site_id, period_type, period_start)
  DO UPDATE
    SET value       = EXCLUDED.value,
        numerator   = EXCLUDED.numerator,
        denominator = EXCLUDED.denominator,
        is_current  = true,
        computed_at = now();

  RETURN v_value;
END;
$function$;
