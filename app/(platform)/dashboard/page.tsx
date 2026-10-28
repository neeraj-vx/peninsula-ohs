import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { Grid, Column, Tile, Tag } from '@carbon/react'
import {
  WarningAlt,
  Warning,
  Education,
  TaskComplete,
  CheckmarkFilled,
  CircleDash,
  ArrowRight,
} from '@carbon/icons-react'
import { audienceFor, canSee } from '@/components/shell/nav'

type Supabase = Awaited<ReturnType<typeof createClient>>

const OPEN_ACTION_STATUSES = ['open', 'in_progress', 'overdue', 'reopened']
const CLOSED_INCIDENT_STATUSES = '(draft,closed,cancelled)'
const HIGH_RISK_LEVELS = '(High,Critical,Extreme,Very High)'

async function getMyTasks(supabase: Supabase, userId: string) {
  const { data } = await supabase
    .from('actions')
    .select('id, action_number, title, due_date, status')
    .eq('assigned_to', userId)
    .in('status', OPEN_ACTION_STATUSES)
    .order('due_date', { ascending: true, nullsFirst: false })
    .limit(5)
  return data ?? []
}

// Assigned courses first, then certificates that are expiring or expired
async function getMyTraining(supabase: Supabase, userId: string) {
  const [{ data: assigned }, { data: expiring }] = await Promise.all([
    supabase
      .from('training_assignments')
      .select('id, due_date, status, training_courses(name)')
      .eq('worker_id', userId)
      .in('status', ['assigned', 'overdue'])
      .order('due_date', { ascending: true })
      .limit(5),
    supabase
      .from('training_records')
      .select('id, expiry_date, status, training_courses(name)')
      .eq('worker_id', userId)
      .in('status', ['expiring_soon', 'expired'])
      .order('expiry_date', { ascending: true })
      .limit(5),
  ])
  const courseName = (c: unknown) => (c as { name: string } | null)?.name ?? 'Training'
  return [
    ...(assigned ?? []).map((a) => ({
      id: a.id, name: courseName(a.training_courses), href: '/training',
      urgent: a.status === 'overdue', label: a.status === 'overdue' ? `Overdue · ${formatDate(a.due_date)}` : `Due ${formatDate(a.due_date)}`,
    })),
    ...(expiring ?? []).map((r) => ({
      id: r.id, name: courseName(r.training_courses), href: '/training/records',
      urgent: r.status === 'expired', label: r.status === 'expired' ? 'Expired' : `Expires ${formatDate(r.expiry_date)}`,
    })),
  ].slice(0, 5)
}

async function getTeamNumbers(supabase: Supabase) {
  const [incidents, overdue, risks, training] = await Promise.all([
    supabase.from('incidents').select('id', { count: 'exact', head: true }).not('status', 'in', CLOSED_INCIDENT_STATUSES),
    supabase.from('actions').select('id', { count: 'exact', head: true }).eq('status', 'overdue'),
    supabase.from('risks').select('id', { count: 'exact', head: true })
      .eq('status', 'active').eq('is_template', false)
      .or(`residual_risk_level.in.${HIGH_RISK_LEVELS},and(residual_risk_level.is.null,inherent_risk_level.in.${HIGH_RISK_LEVELS})`),
    supabase.from('training_records').select('id', { count: 'exact', head: true }).in('status', ['expiring_soon', 'expired']),
  ])
  return {
    openIncidents: incidents.count ?? 0,
    overdueActions: overdue.count ?? 0,
    highRisks: risks.count ?? 0,
    trainingDue: training.count ?? 0,
  }
}

async function getRecentIncidents(supabase: Supabase) {
  const { data } = await supabase
    .from('incidents')
    .select('id, incident_number, title, status, incident_date')
    .not('status', 'in', '(draft,cancelled)')
    .order('created_at', { ascending: false })
    .limit(5)
  return data ?? []
}

// First-run checklist for administrators; hidden once every step is done
async function getSetupSteps(supabase: Supabase, orgId: string) {
  const [sites, users, matrix, documents] = await Promise.all([
    supabase.from('sites').select('id', { count: 'exact', head: true }).eq('organisation_id', orgId),
    supabase.from('user_profiles').select('id', { count: 'exact', head: true }).eq('organisation_id', orgId),
    supabase.from('training_assignment_rules').select('id', { count: 'exact', head: true }).eq('organisation_id', orgId).eq('is_active', true),
    supabase.from('documents').select('id', { count: 'exact', head: true }).eq('organisation_id', orgId),
  ])
  return [
    { label: 'Add your work sites', hint: 'Where your people work, so reports can be filed against a location.', href: '/settings/sites', done: (sites.count ?? 0) > 0 },
    { label: 'Invite your team', hint: 'Give supervisors and workers their own login.', href: '/settings/users', done: (users.count ?? 0) > 1 },
    { label: 'Choose required training', hint: 'Pick which courses each role must complete.', href: '/training/requirements', done: (matrix.count ?? 0) > 0 },
    { label: 'Upload your safety policy', hint: 'Your OHS policy and procedures, ready for staff to acknowledge.', href: '/documents/new', done: (documents.count ?? 0) > 0 },
  ]
}

const incidentStatusTag: Record<string, 'red' | 'purple' | 'blue' | 'cyan' | 'green' | 'gray'> = {
  submitted: 'red',
  triaged: 'blue',
  under_investigation: 'purple',
  capa_in_progress: 'cyan',
  pending_approval: 'cyan',
  closed: 'green',
}

function formatDate(iso: string | null) {
  if (!iso) return 'No due date'
  return new Date(iso + (iso.length === 10 ? 'T12:00:00' : '')).toLocaleDateString('en-CA', { day: 'numeric', month: 'short', year: 'numeric' })
}

function isPast(iso: string | null) {
  return !!iso && iso < new Date().toISOString().slice(0, 10)
}

const QUICK_ACTIONS = [
  { label: 'Report an incident', description: 'Someone was hurt, nearly hurt, or something was damaged.', href: '/incidents/new', icon: Warning, accent: '#da1e28' },
  { label: 'Report a hazard', description: 'Spotted something that could cause harm? Flag it before it does.', href: '/hazards/new', icon: WarningAlt, accent: '#ff832b' },
  { label: 'Log training', description: 'Record a course or certificate you or your team completed.', href: '/training/records/new', icon: Education, accent: '#0f62fe' },
]

function SectionCard({ title, link, children }: { title: string; link?: { href: string; label: string }; children: React.ReactNode }) {
  return (
    <Tile style={{ padding: 0, height: '100%' }}>
      <div style={{ padding: '1rem 1.5rem', borderBottom: '1px solid #e0e0e0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h2 style={{ fontSize: '1rem', fontWeight: 600 }}>{title}</h2>
        {link && <Link href={link.href} style={{ fontSize: '0.875rem', color: '#0f62fe', textDecoration: 'none' }}>{link.label}</Link>}
      </div>
      {children}
    </Tile>
  )
}

function EmptyState({ text }: { text: string }) {
  return <div style={{ padding: '2rem 1.5rem', textAlign: 'center', color: '#6f6f6f', fontSize: '0.875rem' }}>{text}</div>
}

function Row({ href, primary, secondary, right }: { href: string; primary: string; secondary?: string; right?: React.ReactNode }) {
  return (
    <Link href={href} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '1rem', padding: '0.875rem 1.5rem', borderBottom: '1px solid #f4f4f4', textDecoration: 'none', color: 'inherit' }}>
      <div style={{ minWidth: 0 }}>
        <p style={{ fontSize: '0.875rem', fontWeight: 600, color: '#161616', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{primary}</p>
        {secondary && <p style={{ fontSize: '0.75rem', color: '#525252', marginTop: '0.125rem' }}>{secondary}</p>}
      </div>
      <div style={{ flexShrink: 0, textAlign: 'right' }}>{right}</div>
    </Link>
  )
}

export default async function DashboardPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return null

  const [{ data: profile }, { data: roleRows }] = await Promise.all([
    supabase.from('user_profiles').select('first_name, organisation_id').eq('id', user.id).single(),
    supabase.from('user_roles').select('roles(name)').eq('user_id', user.id).eq('is_active', true),
  ])
  const roles = (roleRows ?? []).map((r) => (r.roles as unknown as { name: string } | null)?.name).filter((n): n is string => !!n)
  const audience = audienceFor(roles)
  const isLead = canSee(audience, 'supervisor')

  const [tasks, myTraining, numbers, recentIncidents, setupSteps] = await Promise.all([
    getMyTasks(supabase, user.id),
    getMyTraining(supabase, user.id),
    isLead ? getTeamNumbers(supabase) : Promise.resolve(null),
    isLead ? getRecentIncidents(supabase) : Promise.resolve([]),
    audience === 'admin' && profile ? getSetupSteps(supabase, profile.organisation_id) : Promise.resolve([]),
  ])

  const hour = new Date().getHours()
  const greeting = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening'
  const setupRemaining = setupSteps.filter((s) => !s.done).length

  return (
    <div style={{ padding: '2rem', maxWidth: '80rem' }}>
      <div style={{ marginBottom: '2rem' }}>
        <h1 style={{ fontSize: '1.75rem', fontWeight: 400, color: '#161616' }}>
          {greeting}{profile?.first_name ? `, ${profile.first_name}` : ''}
        </h1>
        <p style={{ fontSize: '0.875rem', color: '#525252', marginTop: '0.25rem' }}>
          {tasks.length > 0
            ? `You have ${tasks.length === 5 ? '5 or more' : tasks.length} open task${tasks.length === 1 ? '' : 's'}.`
            : 'You have no open tasks. Here’s what you can do.'}
        </p>
      </div>

      {setupRemaining > 0 && (
        <Tile style={{ marginBottom: '2rem', borderLeft: '4px solid #0f62fe' }}>
          <h2 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: '0.25rem' }}>Get your workplace set up</h2>
          <p style={{ fontSize: '0.875rem', color: '#525252', marginBottom: '1rem' }}>
            {setupSteps.length - setupRemaining} of {setupSteps.length} done. Finish these and your team can start using EXXIO.
          </p>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(16rem, 1fr))', gap: '0.75rem' }}>
            {setupSteps.map((step) => (
              <Link key={step.label} href={step.href} style={{ display: 'flex', gap: '0.75rem', padding: '0.75rem', border: '1px solid #e0e0e0', textDecoration: 'none', color: 'inherit', background: step.done ? '#f4f4f4' : '#fff' }}>
                {step.done ? <CheckmarkFilled size={20} style={{ color: '#24a148', flexShrink: 0 }} /> : <CircleDash size={20} style={{ color: '#8d8d8d', flexShrink: 0 }} />}
                <span>
                  <span style={{ display: 'block', fontSize: '0.875rem', fontWeight: 600, color: step.done ? '#6f6f6f' : '#161616', textDecoration: step.done ? 'line-through' : 'none' }}>{step.label}</span>
                  {!step.done && <span style={{ display: 'block', fontSize: '0.75rem', color: '#525252', marginTop: '0.125rem' }}>{step.hint}</span>}
                </span>
              </Link>
            ))}
          </div>
        </Tile>
      )}

      <h2 style={{ fontSize: '0.875rem', fontWeight: 600, color: '#525252', marginBottom: '0.75rem' }}>What do you need to do?</h2>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(16rem, 1fr))', gap: '1rem', marginBottom: '2rem' }}>
        {QUICK_ACTIONS.map(({ label, description, href, icon: Icon, accent }) => (
            <Link key={href} href={href} style={{ textDecoration: 'none', color: 'inherit' }}>
              <Tile style={{ height: '100%', borderTop: `3px solid ${accent}`, cursor: 'pointer' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.5rem', color: accent }}>
                  <Icon size={20} />
                  <span style={{ fontSize: '1rem', fontWeight: 600, color: '#161616' }}>{label}</span>
                </div>
                <p style={{ fontSize: '0.875rem', color: '#525252', lineHeight: 1.4 }}>{description}</p>
                <p style={{ fontSize: '0.875rem', color: '#0f62fe', marginTop: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                  Start <ArrowRight size={14} />
                </p>
              </Tile>
            </Link>
        ))}
      </div>

      {numbers && (
        <>
          <h2 style={{ fontSize: '0.875rem', fontWeight: 600, color: '#525252', marginBottom: '0.75rem' }}>Your workplace at a glance</h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(12rem, 1fr))', gap: '1px', background: '#e0e0e0', border: '1px solid #e0e0e0', marginBottom: '2rem' }}>
            {[
              { label: 'Incidents still open', value: numbers.openIncidents, href: '/incidents', alert: numbers.openIncidents > 0 },
              { label: 'Tasks past their due date', value: numbers.overdueActions, href: '/actions', alert: numbers.overdueActions > 0 },
              { label: 'High risks to control', value: numbers.highRisks, href: '/risks', alert: numbers.highRisks > 0 },
              { label: 'Training expiring or expired', value: numbers.trainingDue, href: '/training/records', alert: numbers.trainingDue > 0 },
            ].map((n) => (
              <Link key={n.label} href={n.href} style={{ background: '#fff', padding: '1rem 1.25rem', textDecoration: 'none' }}>
                <p style={{ fontSize: '2rem', fontWeight: 300, color: n.alert ? '#da1e28' : '#161616', lineHeight: 1.1 }}>{n.value}</p>
                <p style={{ fontSize: '0.875rem', color: '#525252', marginTop: '0.25rem' }}>{n.label}</p>
              </Link>
            ))}
          </div>
        </>
      )}

      <Grid condensed style={{ paddingLeft: 0, paddingRight: 0, marginLeft: 0, marginRight: 0 }}>
        <Column sm={4} md={8} lg={8} style={{ marginBottom: '1rem' }}>
          <SectionCard title="My tasks" link={{ href: '/actions', label: 'See all' }}>
            {tasks.length === 0 ? (
              <EmptyState text="Nothing assigned to you right now." />
            ) : (
              tasks.map((t) => (
                <Row
                  key={t.id}
                  href={`/actions/${t.id}`}
                  primary={t.title}
                  secondary={t.action_number}
                  right={
                    <span style={{ fontSize: '0.75rem', color: isPast(t.due_date) || t.status === 'overdue' ? '#da1e28' : '#525252', display: 'inline-flex', alignItems: 'center', gap: '0.25rem' }}>
                      <TaskComplete size={14} />
                      {t.status === 'overdue' || isPast(t.due_date) ? 'Overdue · ' : 'Due '}{formatDate(t.due_date)}
                    </span>
                  }
                />
              ))
            )}
          </SectionCard>
        </Column>

        <Column sm={4} md={8} lg={8} style={{ marginBottom: '1rem' }}>
          {isLead ? (
            <SectionCard title="Latest incidents" link={{ href: '/incidents', label: 'See all' }}>
              {recentIncidents.length === 0 ? (
                <EmptyState text="No incidents reported. Good news." />
              ) : (
                recentIncidents.map((i) => (
                  <Row
                    key={i.id}
                    href={`/incidents/${i.id}`}
                    primary={i.title ?? i.incident_number}
                    secondary={`${i.incident_number} · ${formatDate(i.incident_date)}`}
                    right={<Tag type={incidentStatusTag[i.status] ?? 'gray'} size="sm">{String(i.status).replace(/_/g, ' ')}</Tag>}
                  />
                ))
              )}
            </SectionCard>
          ) : (
            <SectionCard title="My training" link={{ href: '/training', label: 'See all' }}>
              {myTraining.length === 0 ? (
                <EmptyState text="Nothing assigned and nothing expiring. You’re up to date." />
              ) : (
                myTraining.map((t) => (
                  <Row key={t.id} href={t.href} primary={t.name} right={<Tag type={t.urgent ? 'red' : 'warm-gray'} size="sm">{t.label}</Tag>} />
                ))
              )}
            </SectionCard>
          )}
        </Column>
      </Grid>
    </div>
  )
}
