'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Tile, Button, TextInput, InlineNotification, Tag } from '@carbon/react'
import { CheckmarkFilled, Add } from '@carbon/icons-react'
import { createClient } from '@/lib/supabase/client'

interface Factor { id: string; name: string; createdAt: string }

export function TwoFactorSettings({ factors }: { factors: Factor[] }) {
  const router = useRouter()
  const [enrolment, setEnrolment] = useState<{ factorId: string; qr: string; secret: string } | null>(null)
  const [code, setCode] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function startEnrolment() {
    setBusy(true)
    setError(null)
    const supabase = createClient()
    // Clear any half-finished setup so the new one can use a fresh name
    const { data: existing } = await supabase.auth.mfa.listFactors()
    for (const f of existing?.all ?? []) {
      if (f.status === 'unverified') await supabase.auth.mfa.unenroll({ factorId: f.id })
    }
    const { data, error: enrolError } = await supabase.auth.mfa.enroll({
      factorType: 'totp',
      friendlyName: `Authenticator ${new Date().toISOString().slice(0, 10)}`,
    })
    setBusy(false)
    if (enrolError || !data) {
      setError(enrolError?.message ?? 'Could not start setup. Please try again.')
      return
    }
    setEnrolment({ factorId: data.id, qr: data.totp.qr_code, secret: data.totp.secret })
  }

  async function confirmEnrolment(e: React.FormEvent) {
    e.preventDefault()
    if (!enrolment) return
    setBusy(true)
    setError(null)
    const supabase = createClient()
    const { error: verifyError } = await supabase.auth.mfa.challengeAndVerify({ factorId: enrolment.factorId, code: code.trim() })
    setBusy(false)
    if (verifyError) {
      setError('That code didn’t match. Make sure your phone’s clock is right and try the newest code.')
      return
    }
    setEnrolment(null)
    setCode('')
    router.refresh()
  }

  async function remove(factorId: string) {
    setBusy(true)
    setError(null)
    const supabase = createClient()
    const { error: removeError } = await supabase.auth.mfa.unenroll({ factorId })
    setBusy(false)
    if (removeError) {
      setError(removeError.message)
      return
    }
    router.refresh()
  }

  return (
    <Tile>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '1rem', flexWrap: 'wrap' }}>
        <div>
          <h2 style={{ fontSize: '1rem', fontWeight: 600 }}>Two-step sign-in</h2>
          <p style={{ fontSize: '0.875rem', color: '#525252', marginTop: '0.25rem' }}>
            Optional, and recommended for administrators.
          </p>
        </div>
        {factors.length > 0
          ? <Tag type="green">On</Tag>
          : <Tag type="gray">Off</Tag>}
      </div>

      {factors.map((f) => (
        <div key={f.id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '1rem', padding: '1rem 0', borderTop: '1px solid #e0e0e0', marginTop: '1rem' }}>
          <span style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem' }}>
            <CheckmarkFilled size={16} style={{ color: '#24a148' }} />
            {f.name}
            <span style={{ color: '#6f6f6f' }}>· added {new Date(f.createdAt).toLocaleDateString('en-CA')}</span>
          </span>
          <Button kind="ghost" size="sm" disabled={busy} onClick={() => remove(f.id)}>Remove</Button>
        </div>
      ))}

      {!enrolment && (
        <div style={{ marginTop: '1.25rem' }}>
          <Button renderIcon={Add} disabled={busy} onClick={startEnrolment} kind={factors.length > 0 ? 'tertiary' : 'primary'}>
            {factors.length > 0 ? 'Add another authenticator' : 'Set up two-step sign-in'}
          </Button>
        </div>
      )}

      {enrolment && (
        <form onSubmit={confirmEnrolment} style={{ marginTop: '1.5rem', borderTop: '1px solid #e0e0e0', paddingTop: '1.5rem' }}>
          <ol style={{ paddingLeft: '1.25rem', listStyle: 'decimal', fontSize: '0.875rem', color: '#161616', lineHeight: 1.6 }}>
            <li>Open your authenticator app and add a new account.</li>
            <li>Scan this QR code, or type the key below.</li>
            <li>Enter the 6-digit code the app shows.</li>
          </ol>
          <div style={{ display: 'flex', gap: '1.5rem', alignItems: 'center', flexWrap: 'wrap', margin: '1rem 0' }}>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={enrolment.qr} alt="QR code for your authenticator app" width={176} height={176} style={{ background: '#fff', border: '1px solid #e0e0e0' }} />
            <div>
              <p style={{ fontSize: '0.75rem', color: '#6f6f6f' }}>Setup key</p>
              <code style={{ fontSize: '0.875rem', wordBreak: 'break-all' }}>{enrolment.secret}</code>
            </div>
          </div>
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'flex-end', flexWrap: 'wrap' }}>
            <div style={{ width: '12rem' }}>
              <TextInput
                id="totp-code"
                labelText="6-digit code"
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                inputMode="numeric"
                autoComplete="one-time-code"
              />
            </div>
            <Button type="submit" disabled={busy || code.length !== 6}>Turn on</Button>
            <Button kind="ghost" disabled={busy} onClick={() => { setEnrolment(null); setCode('') }}>Cancel</Button>
          </div>
        </form>
      )}

      {error && (
        <InlineNotification kind="error" title="Something went wrong" subtitle={error} lowContrast onClose={() => setError(null)} style={{ marginTop: '1rem', maxWidth: '100%' }} />
      )}
    </Tile>
  )
}
