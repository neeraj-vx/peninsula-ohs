import { afterAll, beforeAll, describe, expect, it } from 'vitest'
import { createHmac } from 'node:crypto'
import { createClient } from '@supabase/supabase-js'
import { createTestOrg, deleteTestOrg, ROLE_IDS, type TestOrg } from './helpers'

// Optional two-step sign-in: once an admin turns it on, admin-only writes need an aal2 session
function base32Decode(input: string): Buffer {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'
  let bits = ''
  for (const ch of input.replace(/=+$/, '').toUpperCase()) bits += alphabet.indexOf(ch).toString(2).padStart(5, '0')
  const bytes = []
  for (let i = 0; i + 8 <= bits.length; i += 8) bytes.push(parseInt(bits.slice(i, i + 8), 2))
  return Buffer.from(bytes)
}

// RFC 6238 TOTP (SHA-1, 30-second step, 6 digits): what an authenticator app shows
export function totp(secret: string, at = Date.now()): string {
  const counter = Buffer.alloc(8)
  counter.writeBigUInt64BE(BigInt(Math.floor(at / 1000 / 30)))
  const hmac = createHmac('sha1', base32Decode(secret)).update(counter).digest()
  const offset = hmac[hmac.length - 1] & 0xf
  const code = (hmac.readUInt32BE(offset) & 0x7fffffff) % 1_000_000
  return code.toString().padStart(6, '0')
}

describe('optional two-step sign-in', () => {
  let org: TestOrg

  beforeAll(async () => {
    org = await createTestOrg('mfa')
  })

  afterAll(async () => {
    await deleteTestOrg(org)
  })

  it('an admin without an authenticator is not blocked', async () => {
    const { error } = await org.users.admin.client.from('user_roles').insert({
      user_id: org.users.worker.id, role_id: ROLE_IDS.supervisor, organisation_id: org.id,
    })
    expect(error).toBeNull()
  })

  it('once an admin sets one up, a session without the code cannot make admin changes', async () => {
    const client = org.users.admin.client
    const enrolled = await client.auth.mfa.enroll({ factorType: 'totp', friendlyName: 'Test authenticator' })
    expect(enrolled.error).toBeNull()
    const factorId = enrolled.data!.id
    const secret = enrolled.data!.totp.secret
    expect((await client.auth.mfa.challengeAndVerify({ factorId, code: totp(secret) })).error).toBeNull()

    // A fresh password-only sign-in (aal1) now owes a code
    const fresh = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, { auth: { persistSession: false } })
    await fresh.auth.signInWithPassword({ email: org.users.admin.email, password: org.users.admin.password! })
    const blocked = await fresh.from('user_roles').insert({
      user_id: org.users.worker.id, role_id: ROLE_IDS.hse, organisation_id: org.id,
    })
    expect(blocked.error?.code).toBe('42501')

    expect((await fresh.auth.mfa.challengeAndVerify({ factorId, code: totp(secret) })).error).toBeNull()
    const allowed = await fresh.from('user_roles').insert({
      user_id: org.users.worker.id, role_id: ROLE_IDS.hse, organisation_id: org.id,
    })
    expect(allowed.error).toBeNull()
  })
})
