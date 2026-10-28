import { afterAll, beforeAll, describe, expect, it } from 'vitest'
import { createTestOrg, deleteTestOrg, securityReport, type RoleKey, type TestOrg } from './helpers'

// Gate for RLS (Step 2.7): every role must be able to query every table
// without a policy error (e.g. 42P17 infinite recursion, 42501, 42703).
// An empty result is fine; an error is not.
describe('RLS smoke: every role can query every table', () => {
  let org: TestOrg
  let tables: string[]

  beforeAll(async () => {
    org = await createTestOrg('smoke')
    tables = (await securityReport()).tables
  })

  afterAll(async () => {
    await deleteTestOrg(org)
  })

  for (const role of ['worker', 'supervisor', 'hse', 'executive', 'admin'] as RoleKey[]) {
    it(`${role}`, { timeout: 180_000 }, async () => {
      const failures: string[] = []
      const client = org.users[role].client
      for (let i = 0; i < tables.length; i += 25) {
        const batch = tables.slice(i, i + 25)
        const query = (table: string) => client.from(table).select('*', { head: true, count: 'exact' }).limit(1)
        const results = await Promise.all(
          batch.map(async (table) => {
            const first = await query(table)
            // A network blip has no Postgres error code; retry once. Policy errors always have one.
            return first.error && !first.error.code ? query(table) : first
          }),
        )
        results.forEach(({ error }, j) => {
          if (error) failures.push(`${batch[j]}: ${error.code} ${error.message}`)
        })
      }
      expect(failures).toEqual([])
    })
  }
})
