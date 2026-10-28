import type { SupabaseClient } from '@supabase/supabase-js'

export type MfaRequirement = 'verify' | 'enrol' | null

/**
 * What the signed-in user still has to do for two-factor sign-in:
 * - 'verify': they have an authenticator set up but this session hasn't entered a code
 * - 'enrol':  they are a System Admin with no authenticator yet (required)
 * - null:     nothing
 * The assurance level comes from the session itself (no network call). The
 * admin-role lookup is skipped when the caller already knows the user isn't one.
 */
export async function mfaRequirement(
  supabase: SupabaseClient,
  userId: string,
  knownNonAdmin = false,
): Promise<{ requirement: MfaRequirement; isAdmin: boolean | null }> {
  const { data: aal } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel()
  if (!aal || aal.currentLevel === 'aal2') return { requirement: null, isAdmin: null }
  if (aal.nextLevel === 'aal2') return { requirement: 'verify', isAdmin: null }
  if (knownNonAdmin) return { requirement: null, isAdmin: false }

  const { data: adminRole } = await supabase
    .from('user_roles')
    .select('id, roles!inner(name)')
    .eq('user_id', userId)
    .eq('is_active', true)
    .eq('roles.name', 'System Admin')
    .limit(1)
  const isAdmin = !!adminRole && adminRole.length > 0
  return { requirement: isAdmin ? 'enrol' : null, isAdmin }
}
