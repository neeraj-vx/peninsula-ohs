'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'

// Mirrors investigation_status_enum in the database.
const INVESTIGATION_STATUSES = [
  'assigned',
  'in_progress',
  'rca_complete',
  'capa_in_progress',
  'pending_review',
  'complete',
] as const

const RCA_METHODS = ['five_whys', 'fishbone', 'both', 'none'] as const

function today() {
  return new Date().toISOString().slice(0, 10)
}

function text(formData: FormData, key: string) {
  return (formData.get(key) as string | null)?.trim() || null
}

export async function createInvestigation(incidentId: string): Promise<{ error?: string }> {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return { error: 'Not authenticated' }

  const { data: profile } = await supabase
    .from('user_profiles')
    .select('organisation_id')
    .eq('id', user.id)
    .single()
  if (!profile) return { error: 'User profile not found' }

  const { data: existing } = await supabase
    .from('investigations')
    .select('id')
    .eq('incident_id', incidentId)
    .maybeSingle()

  if (existing) {
    redirect(`/investigations/${existing.id}`)
  }

  const { data: inv, error } = await supabase
    .from('investigations')
    .insert({
      organisation_id: profile.organisation_id,
      incident_id: incidentId,
      investigator_id: user.id,
      status: 'in_progress',
      start_date: today(),
      created_by: user.id,
    })
    .select('id')
    .single()

  if (error) {
    if (error.code === '42501') {
      return { error: 'Only HSE officers and administrators can start an investigation.' }
    }
    return { error: error.message }
  }

  // The DB only syncs incident status on investigation status *updates*, so
  // move the incident forward here for a newly started investigation.
  await supabase
    .from('incidents')
    .update({ status: 'under_investigation', updated_at: new Date().toISOString() })
    .eq('id', incidentId)
    .in('status', ['submitted', 'triaged'])

  revalidatePath(`/incidents/${incidentId}`)
  revalidatePath('/incidents')
  revalidatePath('/investigations')
  redirect(`/investigations/${inv.id}`)
}

export async function updateInvestigation(id: string, formData: FormData): Promise<{ error?: string }> {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return { error: 'Not authenticated' }

  const status = formData.get('status') as string
  if (!INVESTIGATION_STATUSES.includes(status as (typeof INVESTIGATION_STATUSES)[number])) {
    return { error: 'Invalid status' }
  }

  const rcaMethod = text(formData, 'rca_method')
  if (rcaMethod && !RCA_METHODS.includes(rcaMethod as (typeof RCA_METHODS)[number])) {
    return { error: 'Invalid RCA method' }
  }

  const updates: Record<string, unknown> = {
    status,
    investigator_id: text(formData, 'investigator_id'),
    rca_method: rcaMethod,
    start_date: text(formData, 'start_date'),
    target_completion_date: text(formData, 'target_completion_date'),
    background: text(formData, 'background'),
    contributing_factors: text(formData, 'contributing_factors'),
    investigation_summary: text(formData, 'investigation_summary'),
    lessons_learned: text(formData, 'lessons_learned'),
    actual_completion_date: status === 'complete' ? text(formData, 'actual_completion_date') ?? today() : null,
  }

  const { error } = await supabase
    .from('investigations')
    .update(updates)
    .eq('id', id)

  if (error) return { error: error.message }

  revalidatePath(`/investigations/${id}`)
  revalidatePath('/investigations')
  redirect(`/investigations/${id}`)
}

export async function completeInvestigation(id: string): Promise<{ error?: string }> {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return { error: 'Not authenticated' }

  const { error } = await supabase
    .from('investigations')
    .update({ status: 'complete', actual_completion_date: today() })
    .eq('id', id)

  if (error) return { error: error.message }

  revalidatePath(`/investigations/${id}`)
  revalidatePath('/investigations')
  return {}
}
