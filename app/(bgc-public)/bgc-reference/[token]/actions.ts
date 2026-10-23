'use server'

import { createHash } from 'crypto'
import { supabaseAdmin } from '@/lib/supabase/admin'

// Referees are not logged in, so the token is the only credential: it is
// re-validated here instead of trusting the request id sent by the browser.
export async function submitReference(token: string, answers: Record<string, unknown>): Promise<{ error?: string }> {
  const tokenHash = createHash('sha256').update(token).digest('hex')

  const { data: request } = await supabaseAdmin
    .from('bgc_reference_requests')
    .select('id, status, expires_at')
    .eq('token_hash', tokenHash)
    .single()

  if (!request) return { error: 'This reference link is not valid.' }
  if (request.status === 'completed') return { error: 'This reference has already been submitted.' }
  if (request.expires_at && new Date(request.expires_at) < new Date()) return { error: 'This reference link has expired.' }

  const rows = Object.entries(answers).map(([questionId, value]) => ({
    request_id:     request.id,
    question_id:    questionId,
    response_value: JSON.stringify(value),
  }))

  const { error } = await supabaseAdmin.from('bgc_reference_responses').insert(rows)
  if (error) return { error: error.message }

  await supabaseAdmin
    .from('bgc_reference_requests')
    .update({ status: 'completed', completed_at: new Date().toISOString() })
    .eq('id', request.id)
  return {}
}
