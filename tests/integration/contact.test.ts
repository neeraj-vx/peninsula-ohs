import { afterAll, describe, expect, it } from 'vitest'
import { randomUUID } from 'node:crypto'
import { submitContact } from '@/app/(marketing)/contact/actions'
import { admin, anon } from './helpers'

// Marketing contact form: validation, honeypot, storage, and no public access
const marker = `zz-test-${randomUUID().slice(0, 8)}@example.com`

function form(fields: Record<string, string>) {
  const fd = new FormData()
  for (const [k, v] of Object.entries(fields)) fd.set(k, v)
  return fd
}

describe('contact form', () => {
  afterAll(async () => {
    await admin.from('marketing_leads').delete().eq('email', marker)
  })

  it('stores a valid submission', async () => {
    const result = await submitContact(form({
      name: 'Test Person', email: marker, company: 'Acme Inc.', province: 'ON',
      employee_count: '20–49', interest: 'pricing', message: 'Hello', source_page: '/pricing',
    }))
    expect(result).toEqual({ ok: true })

    const { data } = await admin.from('marketing_leads').select('name, province, interest, source_page, status').eq('email', marker)
    expect(data).toEqual([{ name: 'Test Person', province: 'ON', interest: 'pricing', source_page: '/pricing', status: 'new' }])
  })

  it('rejects bad input with field errors', async () => {
    const result = await submitContact(form({ name: '', email: 'not-an-email', province: 'ZZ' }))
    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(Object.keys(result.fieldErrors ?? {}).sort()).toEqual(['email', 'name', 'province'])
    }
  })

  it('silently drops honeypot submissions', async () => {
    const result = await submitContact(form({ name: 'Bot', email: marker, website: 'http://spam.example' }))
    expect(result).toEqual({ ok: true })
    const { count } = await admin.from('marketing_leads').select('id', { count: 'exact', head: true }).eq('email', marker)
    expect(count).toBe(1) // only the genuine submission above
  })

  it('leads are not readable or writable with the public key', async () => {
    const read = await anon().from('marketing_leads').select('id').limit(1)
    expect(read.error?.code).toBe('42501')
    const write = await anon().from('marketing_leads').insert({ name: 'x', email: 'x@example.com' })
    expect(write.error?.code).toBe('42501')
  })
})
