import type { SupabaseClient } from '@supabase/supabase-js'

/**
 * True when the user has an authenticator set up but this session hasn't
 * entered a code yet. Two-step sign-in is optional; once someone turns it on,
 * every new session must verify. Read from the session itself (no network call).
 */
export async function needsMfaCode(supabase: SupabaseClient): Promise<boolean> {
  const { data: aal } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel()
  return !!aal && aal.currentLevel !== 'aal2' && aal.nextLevel === 'aal2'
}
