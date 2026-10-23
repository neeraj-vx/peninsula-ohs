import { afterAll, beforeAll, describe, expect, it } from 'vitest'
import { admin, createIncident, createTestOrg, deleteTestOrg, must, systemCourseId, type TestOrg } from './helpers'

// D2 / D3 / D12 / D18 regressions — users must never see or change another tenant's data
describe('tenant isolation', () => {
  let a: TestOrg
  let b: TestOrg
  let bIncidentId: string
  let courseId: string

  beforeAll(async () => {
    a = await createTestOrg('iso-a')
    b = await createTestOrg('iso-b')
    courseId = await systemCourseId()

    bIncidentId = must(await createIncident(b, b.users.hse), 'org B incident').id
    must(
      await admin.from('training_records').insert({
        organisation_id: b.id, worker_id: b.users.worker.id, course_id: courseId,
        completed_date: '2026-01-15', expiry_date: '2027-01-15',
      }).select('id').single(),
      'org B training record',
    )
    const module = await admin.from('training_course_modules').select('id').eq('course_id', courseId).limit(1).maybeSingle()
    if (module.data) {
      must(
        await admin.from('training_module_completions').insert({
          organisation_id: b.id, worker_id: b.users.worker.id, module_id: module.data.id, completed_at: new Date().toISOString(),
        }).select('id').single(),
        'org B module completion',
      )
    }
  })

  afterAll(async () => {
    await deleteTestOrg(a)
    await deleteTestOrg(b)
  })

  for (const table of ['incidents', 'training_records', 'training_module_completions', 'user_profiles', 'hires', 'risks']) {
    it(`org A admin sees no org B rows in ${table}`, async () => {
      const { data, error } = await a.users.admin.client.from(table).select('organisation_id').eq('organisation_id', b.id)
      expect(error).toBeNull()
      expect(data).toEqual([])
    })
  }

  it('org A worker cannot read org B module completions (D2)', async () => {
    const { data } = await a.users.worker.client.from('training_module_completions').select('id').eq('organisation_id', b.id)
    expect(data ?? []).toEqual([])
  })

  it('org A admin cannot update an org B incident', async () => {
    const { data } = await a.users.admin.client.from('incidents').update({ title: 'hijacked' }).eq('id', bIncidentId).select('id')
    expect(data ?? []).toEqual([])
    const row = must(await admin.from('incidents').select('title').eq('id', bIncidentId).single(), 'reload incident')
    expect(row.title).toBe('Test incident')
  })

  it('no user can edit a system risk template (D3)', async () => {
    const tpl = await admin.from('risks').select('id, title').is('organisation_id', null).eq('is_template', true).limit(1).maybeSingle()
    if (!tpl.data) return
    const { data } = await a.users.admin.client.from('risks').update({ title: 'hijacked' }).eq('id', tpl.data.id).select('id')
    expect(data ?? []).toEqual([])
    const row = must(await admin.from('risks').select('title').eq('id', tpl.data.id).single(), 'reload template')
    expect(row.title).toBe(tpl.data.title)
  })

  it('system risk templates are still readable', async () => {
    const { data, error } = await a.users.worker.client.from('risks').select('id').is('organisation_id', null).eq('is_template', true).limit(1)
    expect(error).toBeNull()
    expect((data ?? []).length).toBeGreaterThan(0)
  })

  it('no user can edit a system training course', async () => {
    const before = must(await admin.from('training_courses').select('name').eq('id', courseId).single(), 'course')
    const { data } = await a.users.admin.client.from('training_courses').update({ name: 'hijacked' }).eq('id', courseId).select('id')
    expect(data ?? []).toEqual([])
    const after = must(await admin.from('training_courses').select('name').eq('id', courseId).single(), 'course')
    expect(after.name).toBe(before.name)
  })

  it('a user cannot move themselves into another organisation (D30)', async () => {
    const { error } = await a.users.worker.client.from('user_profiles').update({ organisation_id: b.id }).eq('id', a.users.worker.id)
    expect(error?.code).toBe('42501')
    const row = must(await admin.from('user_profiles').select('organisation_id').eq('id', a.users.worker.id).single(), 'profile')
    expect(row.organisation_id).toBe(a.id)
  })

  it('speak-up reports are only readable by safety managers (D29)', async () => {
    const filed = await a.users.worker.client.from('speak_up_reports').insert({
      organisation_id: a.id, description: 'Confidential concern', status: 'received',
    })
    expect(filed.error).toBeNull()

    const asWorker = await a.users.worker.client.from('speak_up_reports').select('id').eq('organisation_id', a.id)
    expect(asWorker.data ?? []).toEqual([])
    const asHse = await a.users.hse.client.from('speak_up_reports').select('id').eq('organisation_id', a.id)
    expect((asHse.data ?? []).length).toBe(1)
  })

  it('users cannot file speak-up reports into another organisation (D29)', async () => {
    const { error } = await a.users.worker.client.from('speak_up_reports').insert({
      organisation_id: b.id, description: 'Cross-tenant', status: 'received',
    })
    expect(error?.code).toBe('42501')
  })

  it('a user cannot raise notifications in another organisation', async () => {
    const { error } = await a.users.admin.client.rpc('create_notification', {
      p_trigger_event: 'incidents.submitted', p_organisation_id: b.id,
    })
    expect(error?.code).toBe('42501')
  })
})
