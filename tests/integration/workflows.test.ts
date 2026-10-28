import { afterAll, beforeAll, describe, expect, it } from 'vitest'
import { admin, createIncident, createTestOrg, deleteTestOrg, must, ROLE_IDS, systemCourseId, type TestOrg } from './helpers'

const year = new Date().getUTCFullYear()

// D1 / D4 / D7 / D8 / D23 regressions, exercised through each user's own session
describe('core workflows under RLS', () => {
  let a: TestOrg
  let b: TestOrg
  let courseId: string

  beforeAll(async () => {
    a = await createTestOrg('wf-a')
    b = await createTestOrg('wf-b')
    courseId = await systemCourseId()
  })

  afterAll(async () => {
    await deleteTestOrg(a)
    await deleteTestOrg(b)
  })

  it('training records get sequential per-org, per-year numbers (D1)', async () => {
    const insert = (org: TestOrg) =>
      org.users.hse.client.from('training_records').insert({
        organisation_id: org.id, worker_id: org.users.worker.id, course_id: courseId, completed_date: `${year}-01-10`,
      }).select('record_number').single()

    const first = must(await insert(a), 'record 1')
    const second = must(await insert(a), 'record 2')
    const otherOrg = must(await insert(b), 'org B record 1')
    expect(first.record_number).toBe(`TRN-${year}-00001`)
    expect(second.record_number).toBe(`TRN-${year}-00002`)
    expect(otherOrg.record_number).toBe(`TRN-${year}-00001`)
  })

  it('training changes are written to the audit log and visible to the HSE Officer (D15)', async () => {
    const rec = must(
      await a.users.hse.client.from('training_records').insert({
        organisation_id: a.id, worker_id: a.users.worker.id, course_id: courseId, completed_date: `${year}-03-01`,
      }).select('id').single(),
      'audited record',
    )
    const asHse = await a.users.hse.client.from('audit_logs').select('action, changed_by').eq('table_name', 'training_records').eq('record_id', rec.id)
    expect(asHse.data).toEqual([{ action: 'INSERT', changed_by: a.users.hse.id }])
    const asWorker = await a.users.worker.client.from('audit_logs').select('id').eq('record_id', rec.id)
    expect(asWorker.data ?? []).toEqual([])
  })

  it('a worker can log their own training record but not someone else\'s', async () => {
    const own = await a.users.worker.client.from('training_records').insert({
      organisation_id: a.id, worker_id: a.users.worker.id, course_id: courseId, completed_date: `${year}-02-01`,
    }).select('id').single()
    expect(own.error).toBeNull()

    const other = await a.users.worker.client.from('training_records').insert({
      organisation_id: a.id, worker_id: a.users.supervisor.id, course_id: courseId, completed_date: `${year}-02-01`,
    }).select('id').single()
    expect(other.error?.code).toBe('42501')
  })

  it('two organisations can map the same role to the same system course (D8)', async () => {
    for (const org of [a, b]) {
      const { error } = await org.users.admin.client.from('training_needs_matrix').insert({
        organisation_id: org.id, role_id: ROLE_IDS.worker, course_id: courseId,
      })
      expect(error, org.name).toBeNull()
    }
  })

  it('new organisations get default notification rules (D7)', async () => {
    const { count } = await admin.from('notification_rules').select('id', { count: 'exact', head: true }).eq('organisation_id', a.id)
    expect(count).toBeGreaterThan(0)
  })

  it('a worker can report an incident and read it back, as createIncident does (D28)', async () => {
    const res = await createIncident(a, a.users.worker)
    expect(res.error).toBeNull()
    expect(res.data?.incident_number).toBeTruthy()
  })

  it('the first incident in a second organisation does not collide with another org\'s number (D27)', async () => {
    const inA = must(await createIncident(a, a.users.hse), 'org A incident')
    const inB = must(await createIncident(b, b.users.hse), 'org B incident')
    expect(inA.incident_number).toMatch(/^INC-\d{4}-\d{5}$/)
    expect(inB.incident_number).toMatch(/^INC-\d{4}-\d{5}$/)
  })

  it('a submitted incident is numbered and notifies the HSE Officer and System Admin (D7, D23)', async () => {
    const incident = must(await createIncident(a, a.users.supervisor), 'incident')
    expect(incident.incident_number).toBeTruthy()

    const notes = must(
      await admin.from('notifications').select('recipient_user_id').eq('trigger_entity_id', incident.id),
      'notifications',
    )
    const recipients = notes.map(n => n.recipient_user_id)
    expect(recipients).toContain(a.users.hse.id)
    expect(recipients).toContain(a.users.admin.id)
    expect(recipients).not.toContain(b.users.admin.id)
  })

  it('TRIR/LTIR (200k base), TRIFR/LTIFR and severity use the real incident columns (D4, C10)', async () => {
    const start = `${year}-01-01`
    const end = `${year}-12-31`
    const incident = must(await createIncident(a, a.users.hse, { incident_date: `${year}-03-03` }), 'kpi incident')
    const person = must(
      await admin.from('incident_people_involved').insert({
        incident_id: incident.id, organisation_id: a.id, user_id: a.users.worker.id,
        person_type: 'employee', full_name: 'Test Worker', was_injured: true,
      }).select('id').single(),
      'person involved',
    )
    must(
      await admin.from('incident_medical').insert({
        incident_id: incident.id, organisation_id: a.id, person_involved_id: person.id,
        treatment_provided: 'medical_treatment', lost_time_days: 3,
      }).select('id').single(),
      'incident medical',
    )
    must(
      await admin.from('workforce_hours_logs').insert({
        organisation_id: a.id, period_start: start, period_end: end, hours_worked: 100000,
      }).select('id').single(),
      'hours',
    )

    const kpi = async (key: string) =>
      Number(must(await admin.rpc('compute_kpi_snapshot', {
        p_formula_key: key, p_org_id: a.id, p_site_id: null, p_period_type: 'yearly', p_period_start: start, p_period_end: end,
      }), key))

    expect(await kpi('trir')).toBe(2)            // 1 × 200,000 / 100,000 (C10)
    expect(await kpi('ltir')).toBe(2)
    expect(await kpi('trifr')).toBe(10)          // 1 × 1,000,000 / 100,000
    expect(await kpi('ltifr')).toBe(10)
    expect(await kpi('severity_rate')).toBe(30)  // 3 days × 1,000,000 / 100,000
  })
})
