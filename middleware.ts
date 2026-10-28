import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'
import { validateSuperAdminSession } from '@/lib/super-admin/session'
import { mfaRequirement } from '@/lib/supabase/mfa'

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })

  const { pathname } = request.nextUrl
  const isPublicAsset = pathname.startsWith('/_next') || pathname.includes('.')

  if (isPublicAsset) return supabaseResponse

  // ── Super admin routes (/admin/*) ────────────────────────────────────────
  if (pathname.startsWith('/admin')) {
    if (pathname === '/admin/login') return supabaseResponse
    const saToken = request.cookies.get('exxio_sa_token')?.value
    if (!saToken) {
      return NextResponse.redirect(new URL('/admin/login', request.url))
    }
    const admin = await validateSuperAdminSession(saToken)
    if (!admin) {
      const response = NextResponse.redirect(new URL('/admin/login', request.url))
      response.cookies.delete('exxio_sa_token')
      return response
    }
    return supabaseResponse
  }

  // ── Platform routes — Supabase auth ──────────────────────────────────────
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet: Array<{ name: string; value: string; options?: Record<string, unknown> }>) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options as Parameters<typeof supabaseResponse.cookies.set>[2])
          )
        },
      },
    }
  )

  const { data: { user } } = await supabase.auth.getUser()

  const isAuthRoute =
    pathname.startsWith('/login') ||
    pathname.startsWith('/register') ||
    pathname.startsWith('/forgot-password') ||
    pathname.startsWith('/auth')

  // Candidate consent and referee pages are reached by emailed token links;
  // the token is checked server-side by the page itself
  const isTokenRoute =
    pathname.startsWith('/bgc-consent/') ||
    pathname.startsWith('/bgc-reference/')

  if (isTokenRoute) return supabaseResponse

  // Public marketing pages; signed-in users opening / go to their dashboard
  const isMarketingRoute = pathname === '/' || pathname === '/how-it-works' || pathname === '/pricing' || pathname === '/contact'
  if (isMarketingRoute) {
    return user && pathname === '/'
      ? NextResponse.redirect(new URL('/dashboard', request.url))
      : supabaseResponse
  }

  if (!user) {
    return isAuthRoute ? supabaseResponse : NextResponse.redirect(new URL('/login', request.url))
  }

  // ── Two-factor sign-in ───────────────────────────────────────────────────
  // Users with an authenticator must enter a code each session; System Admins
  // must set one up. Onboarding and API routes are left alone so a brand-new
  // admin can finish setting up their organisation first.
  const isMfaPage = pathname === '/mfa'
  const isSecurityPage = pathname.startsWith('/account/security')
  const mfaExempt = pathname.startsWith('/api') || pathname.startsWith('/onboarding') || pathname.startsWith('/auth')
  if (!mfaExempt) {
    const nonAdminCookie = `${user.id}:non-admin`
    const knownNonAdmin = request.cookies.get('exxio_mfa_role')?.value === nonAdminCookie
    const { requirement, isAdmin } = await mfaRequirement(supabase, user.id, knownNonAdmin)

    if (requirement === 'verify' && !isMfaPage) {
      const url = new URL('/mfa', request.url)
      url.searchParams.set('next', pathname)
      return NextResponse.redirect(url)
    }
    if (requirement === 'enrol' && !isSecurityPage) {
      return NextResponse.redirect(new URL('/account/security?required=1', request.url))
    }
    if (requirement === null && isMfaPage) {
      return NextResponse.redirect(new URL('/dashboard', request.url))
    }
    if (isAdmin === false && !knownNonAdmin) {
      supabaseResponse.cookies.set('exxio_mfa_role', nonAdminCookie, { maxAge: 600, httpOnly: true, sameSite: 'lax', path: '/' })
    }
  }

  if (isAuthRoute) {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  return supabaseResponse
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
}
