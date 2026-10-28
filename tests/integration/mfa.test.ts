import { afterAll, beforeAll, describe, expect, it } from 'vitest'
import { createHmac } from 'node:crypto'
import { createTestOrg, deleteTestOrg, ROLE_IDS, type TestOrg } from './helpers'

// Two-factor sign-in for System Admins: admin-only writes need an aal2 session
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

describe('admin two-factor sign-in', () => {
  let org: TestOrg

  beforeAll(async () => {
    org = await createTestOrg('mfa')
  })

  afterAll(async () => {
    await deleteTestOrg(org)
  })

  it('an admin without two-factor cannot grant roles', async () => {
    const { error } = await org.users.admin.client.from('user_roles').insert({
      user_id: org.users.worker.id, role_id: ROLE_IDS.supervisor, organisation_id: org.id,
    })
    expect(error?.code).toBe('42501')
  })

  it('other roles are not affected', async () => {
    // HSE Officers may assign sites without two-factor
    const { error } = await org.users.hse.client.from('user_site_assignments').insert({
      user_id: org.users.worker.id, site_id: org.siteId, organisation_id: org.id,
    })
    expect(error).toBeNull()
  })

  it('after enrolling and verifying a TOTP code, the admin can grant roles', async () => {
    const client = org.users.admin.client
    const enrolled = await client.auth.mfa.enroll({ factorType: 'totp', friendlyName: 'Test authenticator' })
    expect(enrolled.error).toBeNull()
    const factorId = enrolled.data!.id
    const secret = enrolled.data!.totp.secret

    const verified = await client.auth.mfa.challengeAndVerify({ factorId, code: totp(secret) })
    expect(verified.error).toBeNull()

    const aal = await client.auth.mfa.getAuthenticatorAssuranceLevel()
    expect(aal.data?.currentLevel).toBe('aal2')

    const { error } = await client.from('user_roles').insert({
      user_id: org.users.worker.id, role_id: ROLE_IDS.supervisor, organisation_id: org.id,
    })
    expect(error).toBeNull()
  })
})
