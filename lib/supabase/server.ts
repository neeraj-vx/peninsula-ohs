import { cache } from 'react'
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

// One client per request, shared by the layout, the page and every helper.
// getUser() is a network call to Supabase Auth, so the first successful answer
// is reused for the rest of the request instead of asking again each time.
export const createClient = cache(async () => {
  const cookieStore = await cookies()
  const client = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet: Array<{ name: string; value: string; options?: Record<string, unknown> }>) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options as Parameters<typeof cookieStore.set>[2])
            )
          } catch {}
        },
      },
    }
  )

  const auth = client.auth
  const getUser = auth.getUser.bind(auth)
  let pending: ReturnType<typeof getUser> | null = null
  auth.getUser = ((jwt?: string) => {
    if (jwt) return getUser(jwt)
    if (!pending) {
      pending = getUser()
      // Don't hold on to a failed or signed-out answer
      pending.then((r) => { if (!r.data.user) pending = null }, () => { pending = null })
    }
    return pending
  }) as typeof auth.getUser
  // Signing in or out changes who the user is
  for (const name of ['signOut', 'signInWithPassword', 'verifyOtp', 'exchangeCodeForSession'] as const) {
    const original = (auth[name] as (...a: unknown[]) => Promise<unknown>).bind(auth)
    ;(auth as unknown as Record<string, unknown>)[name] = (...args: unknown[]) => {
      pending = null
      return original(...args)
    }
  }

  return client
})
