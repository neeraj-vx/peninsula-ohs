import { cache } from 'react'
import { createClient } from './server'

// Cached per request: layouts, pages and actions often all ask for it
export const getOrgId = cache(async (): Promise<string | null> => {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return null

  const { data: profile } = await supabase
    .from('user_profiles')
    .select('organisation_id')
    .eq('id', user.id)
    .single()
  return profile?.organisation_id ?? null
})
