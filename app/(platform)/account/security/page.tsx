import { createClient } from '@/lib/supabase/server'
import { TwoFactorSettings } from './TwoFactorSettings'

export default async function SecurityPage() {
  const supabase = await createClient()

  const { data: factors } = await supabase.auth.mfa.listFactors()
  const verified = (factors?.totp ?? []).filter((f) => f.status === 'verified')

  return (
    <div style={{ padding: '2rem', maxWidth: '44rem' }}>
      <h1 style={{ fontSize: '1.75rem', fontWeight: 400, color: '#161616' }}>Security &amp; sign-in</h1>
      <p style={{ fontSize: '0.875rem', color: '#525252', marginTop: '0.25rem', marginBottom: '2rem' }}>
        Two-step sign-in asks for a code from an authenticator app (such as Google Authenticator, Microsoft
        Authenticator or 1Password) as well as your password.
      </p>

      <TwoFactorSettings
        factors={verified.map((f) => ({ id: f.id, name: f.friendly_name ?? 'Authenticator app', createdAt: f.created_at }))}
      />
    </div>
  )
}
