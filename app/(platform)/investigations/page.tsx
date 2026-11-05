import { createClient } from '@/lib/supabase/server'
import { Tile, Tag, Button } from '@carbon/react'
import { DataTableClient, type ColDef } from '@/components/table/DataTableClient'
import { PageIntro } from '@/components/page-intro/PageIntro'
import { INVESTIGATION_STATUS_TAGS } from './status'

function formatDate(iso: string | null) {
  if (!iso) return '—'
  return new Date(iso).toLocaleDateString('en-CA', { day: 'numeric', month: 'short', year: 'numeric' })
}

const columns: ColDef[] = [
  { key: 'investigation_number', header: 'Ref #' },
  { key: 'incident_title', header: 'Incident' },
  {
    key: 'status',
    header: 'Status',
    cellConfig: {
      as: 'tag',
      map: INVESTIGATION_STATUS_TAGS,
      transform: true,
    },
  },
  { key: 'investigator_name', header: 'Investigator' },
  { key: 'target_completion_date', header: 'Target Completion' },
  { key: 'view', header: '', cellConfig: { as: 'view_link', prefix: '/investigations/' } },
]

export default async function InvestigationsPage() {
  const supabase = await createClient()

  const { data: investigations } = await supabase
    .from('investigations')
    .select(`
      id, investigation_number, status, target_completion_date,
      incidents!incident_id(title),
      user_profiles!investigator_id(first_name, last_name)
    `)
    .order('created_at', { ascending: false })

  const rows = (investigations ?? []).map((inv) => {
    const incidentRaw = inv.incidents
    const profRaw = inv.user_profiles
    const incident = Array.isArray(incidentRaw) ? (incidentRaw[0] as { title: string } | undefined) ?? null : (incidentRaw as { title: string } | null)
    const prof = Array.isArray(profRaw) ? (profRaw[0] as { first_name: string; last_name: string } | undefined) ?? null : (profRaw as { first_name: string; last_name: string } | null)
    return {
      id: inv.id,
      investigation_number: inv.investigation_number ?? '—',
      incident_title: incident?.title ?? '—',
      status: inv.status,
      investigator_name: prof ? `${prof.first_name} ${prof.last_name}` : '—',
      target_completion_date: formatDate(inv.target_completion_date),
    }
  })

  return (
    <div style={{ padding: '2rem' }}>
      <div style={{ marginBottom: '2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <h1 style={{ fontSize: '1.75rem', fontWeight: 400, color: '#161616', marginBottom: '0.25rem' }}>
              Investigations
            </h1>
            <PageIntro screen="/investigations" />
          </div>
          <p style={{ fontSize: '0.875rem', color: '#525252' }}>{rows.length} investigation{rows.length !== 1 ? 's' : ''}</p>
        </div>
      </div>

      <Tile style={{ padding: 0 }}>
        {rows.length === 0 ? (
          <div style={{ padding: '4rem 2rem', textAlign: 'center', color: '#6f6f6f', fontSize: '0.875rem' }}>
            No investigations yet. Start one from an incident.
          </div>
        ) : (
          <DataTableClient
            id="investigations-table"
            rows={rows}
            columns={columns}
            searchPlaceholder="Search investigations…"
          />
        )}
      </Tile>
    </div>
  )
}
