'use client'

import { useEffect, useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { Suspense } from 'react'
import { Button, Form, Stack, TextInput, InlineNotification, Tile } from '@carbon/react'
import { createClient } from '@/lib/supabase/client'

function safeNext(next: string | null) {
  // Only same-site paths
  return next && next.startsWith('/') && !next.startsWith('//') ? next : '/dashboard'
}

function MfaForm() {
  const router = useRouter()
  const params = useSearchParams()
  const [code, setCode] = useState('')
  const [factorId, setFactorId] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const supabase = createClient()
    supabase.auth.mfa.listFactors().then(({ data }) => {
      const factor = data?.totp.find((f) => f.status === 'verified')
      if (factor) setFactorId(factor.id)
      else router.replace('/account/security')
    })
  }, [router])

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!factorId) return
    setLoading(true)
    setError(null)
    const supabase = createClient()
    const { error: verifyError } = await supabase.auth.mfa.challengeAndVerify({ factorId, code: code.trim() })
    if (verifyError) {
      setError('That code didn’t work. Check your authenticator app and try again.')
      setLoading(false)
      return
    }
    router.replace(safeNext(params.get('next')))
    router.refresh()
  }

  async function handleSignOut() {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.replace('/login')
  }

  return (
    <Tile style={{ padding: '2rem' }}>
      <h2 style={{ fontSize: '1.25rem', fontWeight: 600, marginBottom: '0.5rem' }}>Enter your sign-in code</h2>
      <p style={{ fontSize: '0.875rem', color: '#525252', marginBottom: '1.5rem' }}>
        Open your authenticator app and enter the 6-digit code for EXXIO.
      </p>
      <Form onSubmit={handleSubmit}>
        <Stack gap={5}>
          <TextInput
            id="code"
            labelText="6-digit code"
            value={code}
            onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
            inputMode="numeric"
            autoComplete="one-time-code"
            autoFocus
            required
          />
          {error && <InlineNotification kind="error" title="Not verified" subtitle={error} lowContrast hideCloseButton />}
          <Button type="submit" disabled={loading || code.length !== 6 || !factorId} style={{ width: '100%', maxWidth: '100%' }}>
            {loading ? 'Checking…' : 'Verify'}
          </Button>
        </Stack>
      </Form>
      <button
        onClick={handleSignOut}
        style={{ marginTop: '1.5rem', background: 'none', border: 'none', color: '#0f62fe', cursor: 'pointer', padding: 0, fontSize: '0.875rem' }}
      >
        Sign out
      </button>
    </Tile>
  )
}

export default function MfaPage() {
  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#f4f4f4', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1rem' }}>
      <div style={{ width: '100%', maxWidth: '400px' }}>
        <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
          <h1 style={{ fontSize: '1.5rem', fontWeight: 600, color: '#161616' }}>EXXIO</h1>
          <p style={{ fontSize: '0.875rem', color: '#525252' }}>Two-step sign-in</p>
        </div>
        <Suspense>
          <MfaForm />
        </Suspense>
      </div>
    </div>
  )
}
