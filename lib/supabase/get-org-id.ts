import { createClient } from './server'

export async function getOrgId(): Promise<string | null> {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return null

  const { data: profile } = await supabase
    .from('user_profiles')
    .select('organisation_id')
    .eq('id', user.id)
    .single()
  return profile?.organisation_id ?? null
}
