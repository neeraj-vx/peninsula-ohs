// =============================================================
// Demo coverage check
// Lists every org-scoped table where the demo company has no rows,
// so new features don't show up empty in the login-page demo.
//
// Run: node --env-file=.env.local scripts/demo/check-coverage.mjs
// Exit code 1 if any table is empty (usable in CI).
//
// When you add a feature with new tables, add a seed file here
// (scripts/demo/NN_feature.sql, inserts for the demo org only) and
// re-run this check. Tables that should stay empty in the demo
// (logs, integrations, secrets) go in IGNORE below.
// =============================================================

import { createClient } from '@supabase/supabase-js'

const DEMO_ORG_ID = 'cf08b453-9d6a-4e70-919f-44a12a35502a'

const IGNORE = new Set([
  'api_keys', 'api_key_scopes', 'sso_providers', 'user_identity_links', 'user_sessions',
  'integrations', 'integration_field_mappings', 'integration_sync_logs',
  'webhook_endpoints', 'webhook_endpoint_subscriptions', 'webhook_deliveries',
  'report_execution_log', 'row_versions', 'reference_counters', 'auth_events',
  'user_invitations', 'dashboard_widget_configs', 'notification_preferences',
])

const sb = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
})

// Discover org-scoped tables from the PostgREST OpenAPI schema.
const res = await fetch(`${process.env.NEXT_PUBLIC_SUPABASE_URL}/rest/v1/`, {
  headers: { apikey: process.env.SUPABASE_SERVICE_ROLE_KEY, Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}` },
})
const spec = await res.json()
const tables = Object.entries(spec.definitions ?? {})
  .filter(([, def]) => def.properties?.organisation_id)
  .map(([name]) => name)
  .filter((t) => !IGNORE.has(t))
  .sort()

const empty = []
for (const t of tables) {
  const { count, error } = await sb.from(t).select('*', { count: 'exact', head: true }).eq('organisation_id', DEMO_ORG_ID)
  if (error) continue // views or tables without select access
  if (!count) empty.push(t)
}

if (empty.length) {
  console.log(`Demo company has no data in ${empty.length} table(s):\n`)
  for (const t of empty) console.log(`  - ${t}`)
  process.exit(1)
}
console.log(`All ${tables.length} demo tables have data.`)
