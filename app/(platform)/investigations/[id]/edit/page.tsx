import { createClient } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'
import { Breadcrumb, BreadcrumbItem, Grid, Column } from '@carbon/react'
import { EditInvestigationForm } from './EditForm'

interface PageProps { params: Promise<{ id: string }> }

export default async function EditInvestigationPage({ params }: PageProps) {
  const { id } = await params
  const supabase = await createClient()

  const [{ data: inv }, { data: workers }] = await Promise.all([
    supabase
      .from('investigations')
      .select('status, investigator_id, rca_method, start_date, target_completion_date, actual_completion_date, background, contributing_factors, investigation_summary, lessons_learned')
      .eq('id', id)
      .single(),
    supabase.from('user_profiles').select('id, first_name, last_name').eq('is_active', true).order('last_name'),
  ])

  if (!inv) notFound()

  return (
    <div style={{ padding: '2rem' }}>
      <Grid>
        <Column sm={4} md={8} lg={16}>
          <Breadcrumb style={{ marginBottom: '1.5rem' }}>
            <BreadcrumbItem href="/investigations">Investigations</BreadcrumbItem>
            <BreadcrumbItem href={`/investigations/${id}`}>Details</BreadcrumbItem>
            <BreadcrumbItem isCurrentPage>Edit</BreadcrumbItem>
          </Breadcrumb>
          <div style={{ marginBottom: '2rem' }}>
            <h1 style={{ fontSize: '1.75rem', fontWeight: 400, color: '#161616', marginBottom: '0.25rem' }}>Edit Investigation</h1>
          </div>
        </Column>
      </Grid>
      <EditInvestigationForm id={id} initialData={inv} workers={workers ?? []} />
    </div>
  )
}
