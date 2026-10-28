import Link from 'next/link'
import { PageIntro } from '@/components/page-intro/PageIntro'
import { Tile, Tag } from '@carbon/react'
import { createClient } from '@/lib/supabase/server'
import { getOrgId } from '@/lib/supabase/get-org-id'
import { RequirementForm } from './RequirementForm'
import { RequirementToggle } from './RequirementToggle'

type Named = { name: string } | null

export default async function TrainingRequirementsPage() {
  const supabase = await createClient()
  const orgId = await getOrgId()
  if (!orgId) return <div style={{ padding: '2rem' }}><p>No organisation found.</p></div>

  const [{ data: rules }, { data: courses }, { data: roles }, { data: sites }, { data: openCounts }] = await Promise.all([
    supabase
      .from('training_assignment_rules')
      .select('id, due_within_days, is_active, created_at, training_courses(name), roles(name), sites(name)')
      .eq('organisation_id', orgId)
      .order('is_active', { ascending: false })
      .order('created_at', { ascending: false }),
    supabase
      .from('training_courses')
      .select('id, name, is_sample_content, organisation_id')
      .eq('is_active', true)
      .order('name'),
    supabase.from('roles').select('id, name').eq('is_system_role', true).eq('is_active', true).order('name'),
    supabase.from('sites').select('id, name').eq('organisation_id', orgId).eq('is_active', true).order('name'),
    supabase
      .from('training_assignments')
      .select('rule_id, status')
      .eq('organisation_id', orgId)
      .in('status', ['assigned', 'overdue']),
  ])

  const openByRule = new Map<string, number>()
  for (const a of openCounts ?? []) {
    if (a.rule_id) openByRule.set(a.rule_id, (openByRule.get(a.rule_id) ?? 0) + 1)
  }

  return (
    <div style={{ padding: '2rem', maxWidth: '64rem' }}>
      <p style={{ fontSize: '0.875rem', marginBottom: '0.5rem' }}>
        <Link href="/training" style={{ color: '#0f62fe', textDecoration: 'none' }}>Training</Link>
      </p>
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
        <h1 style={{ fontSize: '1.75rem', fontWeight: 400, color: '#161616' }}>Required training</h1>
        <PageIntro screen="/training/requirements" />
      </div>
      <p style={{ fontSize: '0.875rem', color: '#525252', marginTop: '0.25rem', marginBottom: '2rem', maxWidth: '44rem' }}>
        Decide which courses each role must complete. Everyone in that role is assigned the course straight away,
        new starters are assigned it when they join, and a refresher is assigned before a certificate expires.
      </p>

      <RequirementForm
        courses={(courses ?? []).map((c) => ({ id: c.id, name: c.name, sample: c.is_sample_content }))}
        roles={roles ?? []}
        sites={sites ?? []}
      />

      <h2 style={{ fontSize: '1rem', fontWeight: 600, margin: '2rem 0 0.75rem' }}>Current requirements</h2>
      {(rules ?? []).length === 0 ? (
        <Tile>
          <p style={{ fontSize: '0.875rem', color: '#525252' }}>
            No requirements yet. Start with the training your province requires for everyone, for example
            Worker Health and Safety Awareness and WHMIS 2015 in Ontario.
          </p>
        </Tile>
      ) : (
        <Tile style={{ padding: 0 }}>
          {(rules ?? []).map((r, i) => {
            const course = (r.training_courses as unknown as Named)?.name ?? 'Course'
            const role = (r.roles as unknown as Named)?.name
            const site = (r.sites as unknown as Named)?.name
            const open = openByRule.get(r.id) ?? 0
            return (
              <div key={r.id} style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '1rem',
                padding: '1rem 1.5rem', borderTop: i === 0 ? 'none' : '1px solid #e0e0e0',
                opacity: r.is_active ? 1 : 0.55,
              }}>
                <div style={{ minWidth: 0 }}>
                  <p style={{ fontSize: '0.875rem', fontWeight: 600, color: '#161616' }}>{course}</p>
                  <p style={{ fontSize: '0.8125rem', color: '#525252', marginTop: '0.125rem' }}>
                    {role ? `Everyone with the ${role} role` : 'Everyone'}{site ? ` at ${site}` : ''}
                    {' · '}due within {r.due_within_days} business day{r.due_within_days === 1 ? '' : 's'}
                  </p>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', flexShrink: 0 }}>
                  {r.is_active
                    ? <Tag type={open > 0 ? 'warm-gray' : 'green'} size="sm">{open > 0 ? `${open} still to complete` : 'All complete'}</Tag>
                    : <Tag type="gray" size="sm">Paused</Tag>}
                  <RequirementToggle ruleId={r.id} isActive={r.is_active} />
                </div>
              </div>
            )
          })}
        </Tile>
      )}
    </div>
  )
}
