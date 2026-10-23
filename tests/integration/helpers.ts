import { randomUUID } from 'node:crypto'
import { createClient, type SupabaseClient } from '@supabase/supabase-js'

const url = process.env.NEXT_PUBLIC_SUPABASE_URL
const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!url || !anonKey || !serviceKey) {
  throw new Error('Integration tests need NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY in .env.local')
}

const noSession = { auth: { autoRefreshToken: false, persistSession: false } }

export const admin = createClient(url, serviceKey, noSession)
export const anon = () => createClient(url, anonKey, noSession)

// System roles are seeded with fixed ids (20260604000004_module1_seed)
export const ROLE_IDS = {
  worker:     '00000000-0000-0000-0000-000000000001',
  supervisor: '00000000-0000-0000-0000-000000000002',
  hse:        '00000000-0000-0000-0000-000000000003',
  executive:  '00000000-0000-0000-0000-000000000004',
  admin:      '00000000-0000-0000-0000-000000000005',
} as const

export type RoleKey = keyof typeof ROLE_IDS

export interface TestUser {
  id: string
  email: string
  client: SupabaseClient
}

export interface TestOrg {
  id: string
  name: string
  siteId: string
  users: Record<RoleKey, TestUser>
}

const RUN_ID = randomUUID().slice(0, 8)

export function must<T>(res: { data: T; error: { message: string } | null }, what: string): NonNullable<T> {
  if (res.error) throw new Error(`${what}: ${res.error.message}`)
  if (res.data === null || res.data === undefined) throw new Error(`${what}: no data`)
  return res.data as NonNullable<T>
}

/** Creates a zz-test-* organisation with one site and one signed-in user per system role. */
export async function createTestOrg(label: string): Promise<TestOrg> {
  const name = `zz-test-${RUN_ID}-${label}`
  const org = must(
    await admin.from('organisations').insert({ name, slug: name, subdomain: name, country_code: 'CA', province: 'ON' }).select('id').single(),
    'create organisation',
  )
  const site = must(
    await admin.from('sites').insert({ organisation_id: org.id, name: `${label} site` }).select('id').single(),
    'create site',
  )

  const users = {} as Record<RoleKey, TestUser>
  for (const role of Object.keys(ROLE_IDS) as RoleKey[]) {
    const email = `${name}-${role}@example.com`
    const password = `T3st!${randomUUID()}`
    const created = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      // handle_new_auth_user creates the user_profiles row from this
      user_metadata: { organisation_id: org.id, first_name: role, last_name: label },
    })
    if (created.error || !created.data.user) throw new Error(`create ${role} user: ${created.error?.message}`)
    const userId = created.data.user.id
    must(
      await admin.from('user_roles').insert({ user_id: userId, role_id: ROLE_IDS[role], organisation_id: org.id }).select('id').single(),
      `grant ${role}`,
    )

    const client = createClient(url!, anonKey!, noSession)
    const { error } = await client.auth.signInWithPassword({ email, password })
    if (error) throw new Error(`sign in ${role}: ${error.message}`)
    users[role] = { id: userId, email, client }
  }

  return { id: org.id, name, siteId: site.id, users }
}

export async function deleteTestOrg(org: TestOrg | undefined) {
  if (!org) return
  for (const u of Object.values(org.users)) await u.client.auth.signOut()
  const { error } = await admin.rpc('test_support_delete_org', { p_org_id: org.id })
  if (error) throw new Error(`test_support_delete_org: ${error.message}`)
  for (const u of Object.values(org.users)) await admin.auth.admin.deleteUser(u.id)
}

export async function securityReport(): Promise<{
  tables: string[]
  rls_disabled: string[]
  rls_without_policies: string[]
  anon_table_grants: number
  anon_executable_functions: string[]
  authenticated_executable_functions: string[]
  functions_without_search_path: string[]
  cron_jobs: { name: string; schedule: string; command: string; active: boolean }[]
}> {
  return must(await admin.rpc('platform_security_report'), 'platform_security_report')
}

export async function systemCourseId(): Promise<string> {
  const row = must(
    await admin.from('training_courses').select('id').is('organisation_id', null).limit(1).single(),
    'system course',
  )
  return row.id
}

export async function incidentTypeId(code: string): Promise<string> {
  return must(await admin.from('incident_types').select('id').eq('code', code).single(), `incident type ${code}`).id
}

/** Inserts an incident as the given user (exercises RLS, numbering and notification triggers). */
export async function createIncident(org: TestOrg, as: TestUser, overrides: Record<string, unknown> = {}) {
  return as.client
    .from('incidents')
    .insert({
      organisation_id: org.id,
      site_id: org.siteId,
      incident_type_id: await incidentTypeId('injury_illness'),
      title: 'Test incident',
      description: 'Created by the integration suite',
      incident_date: new Date().toISOString().slice(0, 10),
      status: 'submitted',
      submitted_by: as.id,
      ...overrides,
    })
    .select('id, incident_number')
    .single()
}
