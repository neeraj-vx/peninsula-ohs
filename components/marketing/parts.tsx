import Link from 'next/link'

export const BLUE = '#0f62fe'
export const RED = '#da1e28'
export const INK = '#161616'
export const MUTED = '#525252'

export function BrandMark({ size = 32 }: { size?: number }) {
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.625rem' }}>
      <span style={{
        width: size, height: size, backgroundColor: BLUE, borderRadius: 2,
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <svg viewBox="0 0 24 24" width={size * 0.6} height={size * 0.6} aria-hidden="true">
          <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" stroke="white" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </span>
      <span style={{ fontSize: '1.125rem', fontWeight: 600, color: INK, letterSpacing: '0.02em' }}>EXXIO</span>
    </span>
  )
}

export function CtaLink({ href, children, variant = 'primary' }: {
  href: string
  children: React.ReactNode
  variant?: 'primary' | 'secondary' | 'inverse'
}) {
  const styles: Record<string, React.CSSProperties> = {
    primary: { background: BLUE, color: '#fff', border: `1px solid ${BLUE}` },
    secondary: { background: 'transparent', color: BLUE, border: `1px solid ${BLUE}` },
    inverse: { background: '#fff', color: BLUE, border: '1px solid #fff' },
  }
  return (
    <Link
      href={href}
      style={{
        ...styles[variant],
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        minHeight: '3rem', padding: '0 1.5rem', fontSize: '1rem', fontWeight: 600,
        textDecoration: 'none', whiteSpace: 'nowrap',
      }}
    >
      {children}
    </Link>
  )
}

const NAV_LINKS = [
  { href: '/how-it-works', label: 'How it works' },
  { href: '/#features', label: 'Features' },
  { href: '/#canada', label: 'Built for Canada' },
  { href: '/pricing', label: 'Pricing' },
]

export function MarketingHeader() {
  return (
    <header style={{ borderBottom: '1px solid #e0e0e0', background: '#fff', position: 'sticky', top: 0, zIndex: 10 }}>
      <div style={{
        maxWidth: '76rem', margin: '0 auto', padding: '0.75rem 1rem',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '1rem', flexWrap: 'wrap',
      }}>
        <Link href="/" style={{ textDecoration: 'none' }} aria-label="EXXIO home"><BrandMark /></Link>
        <nav aria-label="Main" style={{ display: 'flex', alignItems: 'center', gap: '1.5rem', flexWrap: 'wrap' }}>
          {NAV_LINKS.map((l) => (
            <Link key={l.href} href={l.href} style={{ fontSize: '0.9375rem', color: INK, textDecoration: 'none' }}>{l.label}</Link>
          ))}
          <Link href="/login" style={{ fontSize: '0.9375rem', color: BLUE, textDecoration: 'none', fontWeight: 600 }}>Sign in</Link>
          <CtaLink href="/register">Get started</CtaLink>
        </nav>
      </div>
    </header>
  )
}

export function MarketingFooter() {
  return (
    <footer style={{ background: INK, color: '#c6c6c6', marginTop: '0' }}>
      <div style={{
        maxWidth: '76rem', margin: '0 auto', padding: '3rem 1rem 2rem',
        display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(14rem, 1fr))', gap: '2rem',
      }}>
        <div>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.625rem' }}>
            <span style={{ width: 28, height: 28, background: BLUE, borderRadius: 2, display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
              <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true">
                <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" stroke="white" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </span>
            <span style={{ color: '#fff', fontWeight: 600 }}>EXXIO</span>
          </span>
          <p style={{ fontSize: '0.875rem', marginTop: '0.75rem', lineHeight: 1.5 }}>
            Health, safety and HR compliance for Canadian workplaces.
          </p>
        </div>
        <div>
          <p style={{ color: '#fff', fontWeight: 600, fontSize: '0.875rem', marginBottom: '0.75rem' }}>Product</p>
          {[['/how-it-works', 'How it works'], ['/#features', 'Features'], ['/#canada', 'Built for Canada'], ['/#security', 'Security'], ['/pricing', 'Pricing'], ['/contact', 'Contact']].map(([href, label]) => (
            <Link key={href} href={href} style={{ display: 'block', color: '#c6c6c6', textDecoration: 'none', fontSize: '0.875rem', marginBottom: '0.5rem' }}>{label}</Link>
          ))}
        </div>
        <div>
          <p style={{ color: '#fff', fontWeight: 600, fontSize: '0.875rem', marginBottom: '0.75rem' }}>Account</p>
          {[['/register', 'Create an account'], ['/login', 'Sign in']].map(([href, label]) => (
            <Link key={href} href={href} style={{ display: 'block', color: '#c6c6c6', textDecoration: 'none', fontSize: '0.875rem', marginBottom: '0.5rem' }}>{label}</Link>
          ))}
        </div>
      </div>
      <div style={{ maxWidth: '76rem', margin: '0 auto', padding: '1.5rem 1rem 2rem', borderTop: '1px solid #393939', fontSize: '0.75rem', lineHeight: 1.6 }}>
        EXXIO helps you organise and evidence your health and safety program. It does not replace legal advice;
        confirm your obligations with your provincial regulator or a qualified advisor.
        <br />© {new Date().getFullYear()} EXXIO. All rights reserved.
      </div>
    </footer>
  )
}

export function Section({ id, title, intro, children, tone = 'white' }: {
  id?: string
  title: string
  intro?: string
  children: React.ReactNode
  tone?: 'white' | 'grey'
}) {
  return (
    <section id={id} style={{ background: tone === 'grey' ? '#f4f4f4' : '#fff', scrollMarginTop: '5rem' }}>
      <div style={{ maxWidth: '76rem', margin: '0 auto', padding: '4.5rem 1rem' }}>
        <h2 style={{ fontSize: 'clamp(1.5rem, 3vw, 2.25rem)', fontWeight: 400, color: INK, lineHeight: 1.2, maxWidth: '40rem' }}>{title}</h2>
        {intro && <p style={{ fontSize: '1.125rem', color: MUTED, marginTop: '0.75rem', maxWidth: '44rem', lineHeight: 1.5 }}>{intro}</p>}
        <div style={{ marginTop: '2.5rem' }}>{children}</div>
      </div>
    </section>
  )
}

// Illustrative product preview (not real data)
export function ProductPreview() {
  const bar = (w: string, c = '#c6c6c6') => <span style={{ display: 'block', height: 8, width: w, background: c, borderRadius: 2 }} />
  return (
    <div aria-hidden="true" style={{ background: '#fff', border: '1px solid #e0e0e0', boxShadow: '0 12px 32px rgba(0,0,0,0.12)', display: 'flex', minHeight: '20rem', maxWidth: '36rem', width: '100%' }}>
      <div style={{ width: '28%', borderRight: '1px solid #e0e0e0', padding: '1rem 0.75rem', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
        <span style={{ display: 'block', height: 22, background: RED, borderRadius: 2 }} />
        {['70%', '55%', '80%', '60%', '75%', '50%'].map((w, i) => <span key={i}>{bar(w, i === 0 ? INK : '#c6c6c6')}</span>)}
      </div>
      <div style={{ flex: 1, padding: '1.25rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
        {bar('45%', INK)}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '0.5rem' }}>
          {[RED, '#ff832b', BLUE].map((c) => (
            <div key={c} style={{ borderTop: `3px solid ${c}`, background: '#f4f4f4', padding: '0.625rem', display: 'flex', flexDirection: 'column', gap: 6 }}>
              {bar('70%', '#8d8d8d')}{bar('90%')}
            </div>
          ))}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 1, background: '#e0e0e0', border: '1px solid #e0e0e0' }}>
          {['2', '0', '1', '4'].map((n, i) => (
            <div key={i} style={{ background: '#fff', padding: '0.5rem' }}>
              <span style={{ fontSize: '1.25rem', fontWeight: 300, color: i === 3 ? RED : INK }}>{n}</span>
              {bar('80%', '#e0e0e0')}
            </div>
          ))}
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
          {['85%', '70%', '78%'].map((w, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid #f4f4f4', paddingBottom: '0.5rem' }}>
              {bar(w)}<span style={{ width: 44, height: 14, background: i === 0 ? '#ffd7d9' : '#defbe6', borderRadius: 8, marginLeft: 8, flexShrink: 0 }} />
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
