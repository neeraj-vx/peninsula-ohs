import { afterAll, beforeAll, describe, expect, it } from 'vitest'
import { admin, createTestOrg, deleteTestOrg, must, ROLE_IDS, type TestOrg } from './helpers'

// Step 3 — training assignment rules, assignments, expiry, refreshers,
// overdue handling, toolbox credit and the compliance KPI
const today = () => new Date().toISOString().slice(0, 10)
const monthsAgo = (n: number) => {
  const d = new Date()
  d.setUTCMonth(d.getUTCMonth() - n)
  return d.toISOString().slice(0, 10)
}

async function courseByCode(code: string) {
  return must(
    await admin.from('training_courses').select('id, name, validity_period_months').is('organisation_id', null).eq('code', code).single(),
    `course ${code}`,
  )
}

describe('training assignments', () => {
  let a: TestOrg
  let b: TestOrg
  let whmis: { id: string; name: string; validity_period_months: number | null }
  let hvp: { id: string; name: string; validity_period_months: number | null }
  let workerAssignmentId: string

  beforeAll(async () => {
    a = await createTestOrg('trn-a')
    b = await createTestOrg('trn-b')
    whmis = await courseByCode('WHMIS-2015')   // 12-month validity
    hvp = await courseByCode('HVP-101')        // 24-month validity

    // Supervisor already holds HVP, expiring in about a month
    must(
      await admin.from('training_records').insert({
        organisation_id: a.id, worker_id: a.users.supervisor.id, course_id: hvp.id, completed_date: monthsAgo(23),
      }).select('id').single(),
      'old HVP record',
    )
  })

  afterAll(async () => {
    await deleteTestOrg(a)
    await deleteTestOrg(b)
  })

  it('only safety managers can create assignment rules', async () => {
    const { error } = await a.users.worker.client.from('training_assignment_rules').insert({
      organisation_id: a.id, course_id: whmis.id, role_id: ROLE_IDS.worker,
    })
    expect(error?.code).toBe('42501')
  })

  it('a role rule assigns the course to that role only, due in business days', async () => {
    must(
      await a.users.hse.client.from('training_assignment_rules').insert({
        organisation_id: a.id, course_id: whmis.id, role_id: ROLE_IDS.worker, due_within_days: 10,
      }).select('id').single(),
      'rule',
    )

    const rows = must(
      await admin.from('training_assignments').select('id, worker_id, due_date, source, status').eq('organisation_id', a.id).eq('course_id', whmis.id),
      'assignments',
    )
    expect(rows.map((r) => r.worker_id)).toEqual([a.users.worker.id])
    expect(rows[0].status).toBe('assigned')
    expect(rows[0].source).toBe('rule')

    const expectedDue = must(await admin.rpc('add_business_days', { p_start: today(), p_days: 10, p_jurisdiction: 'CA-ON' }), 'due')
    expect(rows[0].due_date).toBe(expectedDue)
    workerAssignmentId = rows[0].id
  })

  it('workers see their own assignments; supervisors see the team', async () => {
    const own = await a.users.worker.client.from('training_assignments').select('id')
    expect((own.data ?? []).map((r) => r.id)).toEqual([workerAssignmentId])
    const team = await a.users.supervisor.client.from('training_assignments').select('id').eq('id', workerAssignmentId)
    expect(team.data ?? []).toHaveLength(1)
    const otherOrg = await b.users.admin.client.from('training_assignments').select('id').eq('id', workerAssignmentId)
    expect(otherOrg.data ?? []).toEqual([])
  })

  it('logging the training completes the assignment and derives the expiry date', async () => {
    const rec = must(
      await a.users.worker.client.from('training_records').insert({
        organisation_id: a.id, worker_id: a.users.worker.id, course_id: whmis.id, completed_date: today(),
      }).select('id, expiry_date, assignment_id').single(),
      'record',
    )
    const expected = new Date(today() + 'T00:00:00Z')
    expected.setUTCMonth(expected.getUTCMonth() + (whmis.validity_period_months ?? 0))
    expect(rec.expiry_date).toBe(expected.toISOString().slice(0, 10))
    expect(rec.assignment_id).toBe(workerAssignmentId)

    const asg = must(await admin.from('training_assignments').select('status, completed_record_id').eq('id', workerAssignmentId).single(), 'assignment')
    expect(asg).toEqual({ status: 'completed', completed_record_id: rec.id })

    // Valid for a year, so regenerating creates nothing new
    expect(must(await a.users.hse.client.rpc('generate_training_assignments', { p_organisation_id: a.id }), 'regen')).toBe(0)
  })

  it('a certificate expiring within 60 days gets a refresher due on its expiry date', async () => {
    must(
      await a.users.hse.client.from('training_assignment_rules').insert({
        organisation_id: a.id, course_id: hvp.id, role_id: ROLE_IDS.supervisor, due_within_days: 30,
      }).select('id').single(),
      'HVP rule',
    )
    const rec = must(
      await admin.from('training_records').select('expiry_date').eq('worker_id', a.users.supervisor.id).eq('course_id', hvp.id).single(),
      'HVP record',
    )
    const asg = must(
      await admin.from('training_assignments').select('source, due_date').eq('worker_id', a.users.supervisor.id).eq('course_id', hvp.id).single(),
      'refresher',
    )
    expect(asg).toEqual({ source: 'refresher', due_date: rec.expiry_date })
  })

  it('past-due assignments become overdue and the worker is notified', async () => {
    const asg = must(
      await admin.from('training_assignments').select('id').eq('worker_id', a.users.supervisor.id).eq('course_id', hvp.id).single(),
      'refresher',
    )
    must(await admin.from('training_assignments').update({ due_date: '2026-01-05' }).eq('id', asg.id).select('id').single(), 'backdate')
    expect(must(await admin.rpc('mark_overdue_training_assignments'), 'mark overdue')).toBeGreaterThanOrEqual(1)

    const row = must(await admin.from('training_assignments').select('status').eq('id', asg.id).single(), 'reload')
    expect(row.status).toBe('overdue')
    const notes = must(
      await admin.from('notifications').select('recipient_user_id, title').eq('trigger_entity_id', asg.id).eq('trigger_event', 'training.overdue'),
      'overdue notifications',
    )
    expect(notes.map((n) => n.recipient_user_id)).toContain(a.users.supervisor.id)
    expect(notes[0].title).toContain(hvp.name)
  })

  it('an organisation cannot generate assignments for another', async () => {
    const { error } = await b.users.admin.client.rpc('generate_training_assignments', { p_organisation_id: a.id })
    expect(error?.code).toBe('42501')
  })

  it('acknowledging a linked toolbox talk records the training', async () => {
    const tpl = must(
      await admin.from('toolbox_talk_templates').insert({ organisation_id: a.id, title: 'Ladder safety', training_course_id: hvp.id }).select('id').single(),
      'template',
    )
    const delivery = must(
      await admin.from('toolbox_talk_deliveries').insert({
        organisation_id: a.id, template_id: tpl.id, title: 'Ladder safety', delivered_by: a.users.supervisor.id, delivered_at: new Date().toISOString(),
      }).select('id').single(),
      'delivery',
    )
    must(
      await admin.from('toolbox_talk_attendees').insert({
        delivery_id: delivery.id, worker_id: a.users.worker.id, attendee_name: 'Worker', acknowledged_at: new Date().toISOString(),
      }).select('id').single(),
      'attendee',
    )
    const recs = must(
      await admin.from('training_records').select('delivery_method').eq('worker_id', a.users.worker.id).eq('course_id', hvp.id),
      'toolbox record',
    )
    expect(recs).toEqual([{ delivery_method: 'toolbox_talk' }])
  })

  it('training compliance KPI counts on-time completions', async () => {
    const value = await admin.rpc('compute_kpi_snapshot', {
      p_formula_key: 'training_compliance', p_org_id: a.id, p_site_id: null, p_period_type: 'yearly',
      p_period_start: '2026-01-01', p_period_end: '2026-12-31',
    })
    // Only the backdated HVP assignment is due so far, and it is overdue: 0 of 1
    expect(value.error).toBeNull()
    expect(Number(value.data)).toBe(0)
  })
})
