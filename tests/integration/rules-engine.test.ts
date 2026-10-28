import { afterAll, beforeAll, describe, expect, it } from 'vitest'
import { admin, createTestOrg, deleteTestOrg, must, type TestOrg } from './helpers'

// Rules engine R1: hiring rules evaluated in the database
type Result = { rule_key: string; rule_label: string; severity: string; passed: boolean; message: string }

describe('rules engine — hiring rules', () => {
  let a: TestOrg
  let b: TestOrg

  beforeAll(async () => {
    a = await createTestOrg('rules-a')   // province ON
    b = await createTestOrg('rules-b')
  })

  afterAll(async () => {
    await deleteTestOrg(a)
    await deleteTestOrg(b)
  })

  async function hire(fields: Record<string, unknown>) {
    return must(
      await admin.from('hires').insert({
        organisation_id: a.id, current_step: 3, status: 'in_progress', is_fixed_term: false,
        overtime_eligible: false, all_signatures_collected: false, checklist_completed: false, bgc_required: false,
        candidate_first_name: 'Test', candidate_last_name: 'Hire', employment_type: 'full_time',
        ...fields,
      }).select('id').single(),
      'hire',
    ).id
  }

  async function evaluate(hireId: string, as = a.users.hse.client): Promise<Result[]> {
    return must(await as.rpc('evaluate_hire_rules', { p_hire_id: hireId }), 'evaluate') as Result[]
  }

  const find = (results: Result[], key: string) => results.find((r) => r.rule_key === key)

  it('blocks an hourly rate below today\'s Ontario minimum wage', async () => {
    const results = await evaluate(await hire({ pay_frequency: 'hourly', hourly_rate: 15, start_date: '2026-11-02' }))
    const wage = find(results, 'min_wage_general')!
    expect(wage.severity).toBe('error')
    expect(wage.passed).toBe(false)
    expect(wage.message).toContain('$17.95')
  })

  it('uses the rules in force on the start date', async () => {
    // $17.50 was legal before 1 Oct 2026 ($17.20) but not after ($17.95)
    const before = await evaluate(await hire({ pay_frequency: 'hourly', hourly_rate: 17.5, start_date: '2026-09-15' }))
    expect(find(before, 'min_wage_general')).toMatchObject({ severity: 'info', passed: true })
    const after = await evaluate(await hire({ pay_frequency: 'hourly', hourly_rate: 17.5, start_date: '2026-10-15' }))
    expect(find(after, 'min_wage_general')).toMatchObject({ severity: 'error', passed: false })
  })

  it('warns (does not block) when probation runs past the no-notice period', async () => {
    const results = await evaluate(await hire({ probation_period_days: 120, start_date: '2026-11-02' }))
    expect(find(results, 'notice_free_period')).toMatchObject({ severity: 'warning', passed: false })
    expect(results.some((r) => r.severity === 'error')).toBe(false)
  })

  it('requires an end date for fixed-term contracts', async () => {
    const results = await evaluate(await hire({ is_fixed_term: true, start_date: '2026-11-02' }))
    expect(find(results, 'fixed_term_end_date')).toMatchObject({ severity: 'error', passed: false })
  })

  it('lists Ontario required documents and vacation pay', async () => {
    const results = await evaluate(await hire({ start_date: '2026-11-02' }))
    expect(results.filter((r) => r.rule_key === 'esa_poster' || r.rule_key === 'ohsa_awareness')).toHaveLength(2)
    expect(find(results, 'vacation_pay')?.message).toContain('4% vacation pay')
  })

  it('a safety manager can mark a rule not applicable, with a reason', async () => {
    const rule = must(await admin.from('rules').select('id').eq('code', 'ESA.ON.min_wage_general').single(), 'rule')
    must(
      await a.users.hse.client.from('rule_org_settings').insert({
        organisation_id: a.id, rule_id: rule.id, not_applicable: true, reason: 'No hourly employees',
      }).select('rule_id').single(),
      'mark n/a',
    )
    const results = await evaluate(await hire({ pay_frequency: 'hourly', hourly_rate: 1, start_date: '2026-11-02' }))
    expect(find(results, 'min_wage_general')).toBeUndefined()
  })

  it('another organisation cannot evaluate this organisation\'s hires', async () => {
    const id = await hire({ start_date: '2026-11-02' })
    const { error } = await b.users.admin.client.rpc('evaluate_hire_rules', { p_hire_id: id })
    expect(error?.code).toBe('42501')
  })

  it('only one published version of a rule can be in force on a date', async () => {
    const rule = must(await admin.from('rules').select('id').eq('code', 'ESA.ON.min_wage_general').single(), 'rule')
    const { error } = await admin.from('rule_versions').insert({
      rule_id: rule.id, version: 99, label: 'Overlapping', parameters: {}, effective_from: '2026-12-01', review_status: 'published',
    })
    expect(error?.code).toBe('23P01')
  })

  it('a rule version cannot be published by the person who drafted it', async () => {
    const rule = must(await admin.from('rules').select('id').eq('code', 'ESA.ON.notice_less_1_yr').single(), 'rule')
    const { error } = await admin.from('rule_versions').insert({
      rule_id: rule.id, version: 98, label: 'Self-approved', parameters: {}, effective_from: '2099-01-01',
      review_status: 'published', drafted_by: a.users.admin.id, reviewed_by: a.users.admin.id,
    })
    expect(error?.code).toBe('42501')
  })
})
