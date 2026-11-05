import { createClient } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'
import {
  Grid, Column, Tile, Tag, Breadcrumb, BreadcrumbItem, Button,
} from '@carbon/react'
import { INVESTIGATION_STATUS_TAGS, RCA_METHODS, statusLabel } from '../status'
import { CompleteInvestigationButton } from './CompleteInvestigationButton'

function formatDate(iso: string | null) {
  if (!iso) return '—'
  return new Date(iso).toLocaleDateString('en-CA', { day: 'numeric', month: 'short', year: 'numeric' })
}

function DetailRow({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div style={{ marginBottom: '1rem' }}>
      <p style={{ fontSize: '0.75rem', color: '#6f6f6f', letterSpacing: '0.32px', marginBottom: '0.25rem', textTransform: 'uppercase' }}>{label}</p>
      <div style={{ fontSize: '0.875rem', color: '#161616' }}>{children}</div>
    </div>
  )
}

function TextTile({ title, body }: { title: string; body: string }) {
  return (
    <Tile style={{ padding: 0, marginBottom: '1rem' }}>
      <div style={{ padding: '1rem 1.5rem', borderBottom: '1px solid #e0e0e0' }}>
        <h2 style={{ fontSize: '0.875rem', fontWeight: 600, color: '#161616' }}>{title}</h2>
      </div>
      <div style={{ padding: '1.5rem' }}>
        <p style={{ fontSize: '0.875rem', color: '#161616', lineHeight: 1.6, whiteSpace: 'pre-wrap' }}>{body}</p>
      </div>
    </Tile>
  )
}

interface PageProps { params: Promise<{ id: string }> }

export default async function InvestigationDetailPage({ params }: PageProps) {
  const { id } = await params
  const supabase = await createClient()

  const [{ data: inv }, { data: fiveWhys }, { data: fishbone }] = await Promise.all([
    supabase
      .from('investigations')
      .select(`
        id, investigation_number, status, rca_method,
        start_date, target_completion_date, actual_completion_date,
        background, contributing_factors, investigation_summary, lessons_learned,
        created_at,
        incidents!incident_id(id, incident_number, title),
        user_profiles!investigator_id(first_name, last_name, email)
      `)
      .eq('id', id)
      .single(),
    supabase.from('rca_five_whys').select('identified_root_cause').eq('investigation_id', id).maybeSingle(),
    supabase.from('rca_fishbone').select('identified_root_cause').eq('investigation_id', id).maybeSingle(),
  ])

  if (!inv) notFound()

  const incidentRaw = inv.incidents
  const profRaw = inv.user_profiles
  const incident = Array.isArray(incidentRaw) ? (incidentRaw[0] as { id: string; incident_number: string; title: string } | undefined) ?? null : (incidentRaw as { id: string; incident_number: string; title: string } | null)
  const prof = Array.isArray(profRaw) ? (profRaw[0] as { first_name: string; last_name: string; email: string } | undefined) ?? null : (profRaw as { first_name: string; last_name: string; email: string } | null)

  const rootCauses = [fiveWhys?.identified_root_cause, fishbone?.identified_root_cause].filter(
    (c): c is string => !!c,
  )
  const canComplete = inv.status !== 'complete'
  const hasFindings = inv.background || inv.contributing_factors || rootCauses.length > 0 || inv.lessons_learned

  return (
    <div style={{ padding: '2rem' }}>
      <Breadcrumb style={{ marginBottom: '1.5rem' }}>
        <BreadcrumbItem href="/investigations">Investigations</BreadcrumbItem>
        <BreadcrumbItem isCurrentPage>{inv.investigation_number ?? id.slice(0, 8)}</BreadcrumbItem>
      </Breadcrumb>

      <div style={{ marginBottom: '2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '1rem' }}>
        <div>
          <p style={{ fontSize: '0.75rem', color: '#6f6f6f', letterSpacing: '0.32px', marginBottom: '0.25rem', textTransform: 'uppercase' }}>
            {inv.investigation_number ?? '—'}
          </p>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 400, color: '#161616', marginBottom: '0.75rem' }}>
            {incident ? `Investigation: ${incident.title}` : 'Investigation'}
          </h1>
          <Tag type={INVESTIGATION_STATUS_TAGS[inv.status] ?? 'gray'} size="md">{statusLabel(inv.status)}</Tag>
        </div>
        <div style={{ display: 'flex', gap: '0.5rem', flexShrink: 0, alignItems: 'flex-start' }}>
          <Button kind="ghost" href={`/investigations/${id}/edit`} size="sm">Edit</Button>
          {canComplete && <CompleteInvestigationButton id={id} />}
        </div>
      </div>

      <Grid condensed>
        <Column sm={4} md={8} lg={8}>
          <Tile style={{ padding: 0, marginBottom: '1rem' }}>
            <div style={{ padding: '1rem 1.5rem', borderBottom: '1px solid #e0e0e0' }}>
              <h2 style={{ fontSize: '0.875rem', fontWeight: 600, color: '#161616' }}>Details</h2>
            </div>
            <div style={{ padding: '1.5rem' }}>
              {incident && (
                <DetailRow label="Linked Incident">
                  <a href={`/incidents/${incident.id}`} style={{ color: '#0f62fe', textDecoration: 'none' }}>
                    {incident.incident_number} — {incident.title}
                  </a>
                </DetailRow>
              )}
              <DetailRow label="Investigator">
                {prof ? `${prof.first_name} ${prof.last_name} (${prof.email})` : '—'}
              </DetailRow>
              <DetailRow label="RCA Method">{inv.rca_method ? RCA_METHODS[inv.rca_method] ?? inv.rca_method : '—'}</DetailRow>
              <DetailRow label="Started">{formatDate(inv.start_date)}</DetailRow>
              <DetailRow label="Target Completion">{formatDate(inv.target_completion_date)}</DetailRow>
              <DetailRow label="Completed">{formatDate(inv.actual_completion_date)}</DetailRow>
            </div>
          </Tile>

          {inv.investigation_summary && <TextTile title="Summary" body={inv.investigation_summary} />}
        </Column>

        <Column sm={4} md={8} lg={8}>
          {inv.background && <TextTile title="Background" body={inv.background} />}
          {inv.contributing_factors && <TextTile title="Contributing Factors" body={inv.contributing_factors} />}
          {rootCauses.length > 0 && <TextTile title="Root Cause" body={rootCauses.join('\n\n')} />}
          {inv.lessons_learned && <TextTile title="Lessons Learned" body={inv.lessons_learned} />}
          {!hasFindings && (
            <Tile style={{ padding: '2rem', textAlign: 'center' }}>
              <p style={{ fontSize: '0.875rem', color: '#6f6f6f' }}>
                No findings recorded yet.{' '}
                <a href={`/investigations/${id}/edit`} style={{ color: '#0f62fe', textDecoration: 'none' }}>Add findings →</a>
              </p>
            </Tile>
          )}
        </Column>
      </Grid>
    </div>
  )
}
