import { InlineNotification } from '@carbon/react'
import { createClient } from '@/lib/supabase/server'
import { TwoFactorSettings } from './TwoFactorSettings'

export default async function SecurityPage({ searchParams }: { searchParams: Promise<{ required?: string }> }) {
  const { required } = await searchParams
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  const [{ data: factors }, { data: adminRole }] = await Promise.all([
    supabase.auth.mfa.listFactors(),
    supabase
      .from('user_roles')
      .select('id, roles!inner(name)')
      .eq('user_id', user?.id ?? '')
      .eq('is_active', true)
      .eq('roles.name', 'System Admin')
      .limit(1),
  ])
  const verified = (factors?.totp ?? []).filter((f) => f.status === 'verified')
  const isAdmin = (adminRole ?? []).length > 0

  return (
    <div style={{ padding: '2rem', maxWidth: '44rem' }}>
      <h1 style={{ fontSize: '1.75rem', fontWeight: 400, color: '#161616' }}>Security &amp; sign-in</h1>
      <p style={{ fontSize: '0.875rem', color: '#525252', marginTop: '0.25rem', marginBottom: '2rem' }}>
        Two-step sign-in asks for a code from an authenticator app (such as Google Authenticator, Microsoft
        Authenticator or 1Password) as well as your password.
      </p>

      {required === '1' && verified.length === 0 && (
        <InlineNotification
          kind="warning"
          lowContrast
          hideCloseButton
          title="Set up two-step sign-in to continue."
          subtitle="Administrators can change users, roles and settings, so EXXIO requires a second sign-in step for this account."
          style={{ maxWidth: '100%', marginBottom: '1.5rem' }}
        />
      )}

      <TwoFactorSettings
        factors={verified.map((f) => ({ id: f.id, name: f.friendly_name ?? 'Authenticator app', createdAt: f.created_at }))}
        isAdmin={isAdmin}
      />
    </div>
  )
}
