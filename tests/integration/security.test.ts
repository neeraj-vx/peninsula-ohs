import { describe, expect, it } from 'vitest'
import { anon, securityReport } from './helpers'

// D18 / D19 / D10 regressions — schema-level facts from platform_security_report()
describe('platform security', () => {
  it('anon cannot read tenant tables', async () => {
    const { data, error } = await anon().from('incidents').select('id').limit(1)
    expect(data ?? []).toHaveLength(0)
    expect(error?.code).toBe('42501')
  })

  it('anon cannot wipe an organisation through cleanup_demo_org', async () => {
    const { error } = await anon().rpc('cleanup_demo_org', { p_org_name: 'nonexistent' })
    expect(error).not.toBeNull()
  })

  it('anon has no table grants or callable functions in public', async () => {
    const report = await securityReport()
    expect(report.anon_table_grants).toBe(0)
    expect(report.anon_executable_functions).toEqual([])
  })

  it('every public table has RLS enabled', async () => {
    const report = await securityReport()
    expect(report.rls_disabled).toEqual([])
  })

  it('tables without policies are only the service-role-only ones', async () => {
    const report = await securityReport()
    expect(report.rls_without_policies.sort()).toEqual(
      ['bgc_consent_tokens', 'marketing_leads', 'reference_counters', 'super_admin_audit_log', 'super_admin_sessions', 'super_admins'].sort(),
    )
  })

  it('batch and destructive functions are not callable by signed-in users', async () => {
    const report = await securityReport()
    const forbidden = [
      'cleanup_demo_org', 'test_support_delete_org', 'platform_security_report',
      'seed_default_notification_rules', 'refresh_training_record_statuses',
      'create_due_scheduled_inspections', 'process_due_escalations',
      'compute_all_kpi_snapshots', 'compute_kpi_snapshot',
      'mark_overdue_actions', 'mark_overdue_capas', 'mark_overdue_inspections', 'mark_overdue_asset_inspections',
      'mark_overdue_risk_reviews', 'mark_overdue_health_checks', 'mark_expired_permits',
      'check_expiring_training', 'check_hiring_compliance_alerts', 'run_licence_expiry_alerts',
      'run_reverification_due_checks', 'fire_escalation_step', 'create_scheduled_inspection',
    ]
    expect(report.authenticated_executable_functions.filter(f => forbidden.includes(f))).toEqual([])
  })

  it('every function pins its search_path', async () => {
    const report = await securityReport()
    expect(report.functions_without_search_path).toEqual([])
  })

  it('scheduled jobs are registered and active', async () => {
    const report = await securityReport()
    const names = report.cron_jobs.filter(j => j.active).map(j => j.name)
    for (const job of [
      'bgc-licence-expiry-alerts', 'bgc-reverification-due',
      'check-training-expiry', 'check-hiring-compliance-alerts', 'refresh-training-statuses',
      'mark-overdue-actions', 'mark-overdue-capas', 'mark-overdue-inspections', 'mark-overdue-asset-inspections',
      'mark-overdue-risk-reviews', 'mark-overdue-health-checks', 'mark-expired-permits',
      'create-scheduled-inspections', 'process-escalations', 'compute-kpi-snapshots',
      'notify-sds-review-due', 'notify-upcoming-health-checks', 'notify-expiring-documents', 'notify-env-reporting-due',
    ]) {
      expect(names, job).toContain(job)
    }
  })
})
