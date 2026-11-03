'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import {
  Button,
  Form,
  Stack,
  TextInput,
  InlineNotification,
  PasswordInput,
  Tile,
} from '@carbon/react'
import { createClient } from '@/lib/supabase/client'

const DEMO_PASSWORD = 'DemoPass123!'
const DEMO_ACCOUNTS = [
  { email: 'sarah@peninsula.health', name: 'Sarah Chen',     role: 'System Admin' },
  { email: 'david@peninsula.health', name: 'David Patel',    role: 'Executive' },
  { email: 'james@peninsula.health', name: 'James Nguyen',   role: 'HSE Officer' },
  { email: 'michael@peninsula.health', name: 'Michael Torres', role: 'Supervisor' },
  { email: 'emma@peninsula.health', name: 'Emma Wilson',    role: 'Worker' },
]

export default function LoginPage() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function signIn(loginEmail: string, loginPassword: string) {
    setLoading(true)
    setError(null)

    const supabase = createClient()
    const { error } = await supabase.auth.signInWithPassword({ email: loginEmail, password: loginPassword })

    if (error) {
      setError(error.message)
      setLoading(false)
      return
    }

    router.push('/assistant')
    router.refresh()
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    await signIn(email, password)
  }

  return (
    <div style={{
      minHeight: '100vh',
      backgroundColor: '#f4f4f4',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '1rem',
    }}>
      <div style={{ width: '100%', maxWidth: '400px' }}>
        {/* Brand */}
        <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
          <div style={{
            width: '48px',
            height: '48px',
            backgroundColor: '#0f62fe',
            borderRadius: '2px',
            margin: '0 auto 1rem',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}>
            <svg viewBox="0 0 24 24" fill="white" width="28" height="28">
              <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" stroke="white" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
          <h1 style={{ fontSize: '1.5rem', fontWeight: 600, color: '#161616', marginBottom: '0.25rem' }}>
            EXXIO
          </h1>
          <p style={{ fontSize: '0.875rem', color: '#525252' }}>
            Health &amp; Safety Platform
          </p>
        </div>

        <Tile style={{ padding: '2rem' }}>
          {error && (
            <InlineNotification
              kind="error"
              title="Sign in failed"
              subtitle={error}
              lowContrast
              style={{ marginBottom: '1.5rem', maxWidth: '100%' }}
            />
          )}

          <Form onSubmit={handleSubmit}>
            <Stack gap={6}>
              <TextInput
                id="email"
                labelText="Email address"
                type="email"
                placeholder="you@company.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
              />
              <PasswordInput
                id="password"
                labelText="Password"
                placeholder="••••••••"
                value={password}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => setPassword(e.target.value)}
                required
                autoComplete="current-password"
              />
              <div>
                <Button
                  type="submit"
                  disabled={loading}
                  style={{ width: '100%', maxWidth: '100%' }}
                >
                  {loading ? 'Signing in…' : 'Sign in'}
                </Button>
              </div>
              <p style={{ textAlign: 'center', fontSize: '0.875rem' }}>
                <a
                  href="/forgot-password"
                  style={{ color: '#0f62fe', textDecoration: 'none' }}
                >
                  Forgot your password?
                </a>
              </p>
            </Stack>
          </Form>
        </Tile>

        <Tile style={{ padding: '1.5rem', marginTop: '1rem' }}>
          <h2 style={{ fontSize: '1rem', fontWeight: 600, color: '#161616', marginBottom: '0.25rem' }}>
            Explore the demo
          </h2>
          <p style={{ fontSize: '0.8125rem', color: '#525252', marginBottom: '1rem' }}>
            Sign in to a sample company with realistic data. Pick a role to see what that person sees.
          </p>
          <Stack gap={3}>
            {DEMO_ACCOUNTS.map((a) => (
              <Button
                key={a.email}
                kind="tertiary"
                size="md"
                disabled={loading}
                onClick={() => signIn(a.email, DEMO_PASSWORD)}
                style={{ width: '100%', maxWidth: '100%' }}
              >
                {a.role} — {a.name}
              </Button>
            ))}
          </Stack>
        </Tile>

        <p style={{ textAlign: 'center', marginTop: '1.25rem', fontSize: '0.875rem', color: '#525252' }}>
          Don&apos;t have an account?{' '}
          <a href="/register" style={{ color: '#0f62fe', textDecoration: 'none' }}>Create one</a>
        </p>

        <p style={{ textAlign: 'center', marginTop: '1rem', fontSize: '0.75rem', color: '#6f6f6f' }}>
          © {new Date().getFullYear()} EXXIO. All rights reserved.
        </p>
      </div>
    </div>
  )
}
