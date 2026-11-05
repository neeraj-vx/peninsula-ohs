import Link from 'next/link'
import { BLUE, INK, MUTED } from '@/components/marketing/parts'

// ─────────────────────────────────────────────────────────────────────────────
// LEGAL CONFIG — company details shown on every legal page.
//
// These pages are drafts written from how the platform actually handles data
// (see docs/compliance-guide.md). They have NOT been reviewed by a lawyer.
// Before launch: have counsel review every page, then fill in the fields
// marked TODO and update `lastUpdated`.
// ─────────────────────────────────────────────────────────────────────────────
export const LEGAL = {
  /** TODO: the registered legal entity that contracts with customers. */
  legalName: 'EXXIO',
  /** TODO: registered business address. Hidden while null. */
  address: null as string | null,
  /** Province whose laws govern the Terms. */
  governingProvince: 'Ontario',
  contactEmail: 'legal@exxio.ai',
  privacyEmail: 'privacy@exxio.ai',
  securityEmail: 'security@exxio.ai',
  supportEmail: 'support@exxio.ai',
  /** TODO: name of the person appointed as privacy officer (Quebec Law 25, PIPEDA accountability). */
  privacyOfficerName: null as string | null,
  /** Where the primary database is hosted. Update after the move to Canada (production-readiness I1). */
  dataRegion: 'Singapore (Amazon Web Services, ap-southeast-1 region)',
  dataInCanada: false,
  /** Set to true once French versions of these documents exist (Quebec, Bill 96). */
  frenchVersionAvailable: false,
  lastUpdated: '3 November 2026',
}

export const LEGAL_PAGES = [
  { href: '/legal/terms', label: 'Terms of Service', summary: 'The agreement between your organization and us for using EXXIO.' },
  { href: '/legal/privacy', label: 'Privacy Policy', summary: 'What personal information we handle, why, and your choices.' },
  { href: '/legal/data-processing', label: 'Data Processing Addendum', summary: 'How we process your employees’ information on your behalf.' },
  { href: '/legal/subprocessors', label: 'Subprocessors', summary: 'The service providers that help us run EXXIO, and where they are.' },
  { href: '/legal/acceptable-use', label: 'Acceptable Use Policy', summary: 'What you may and may not do with the service.' },
  { href: '/legal/cookies', label: 'Cookie Notice', summary: 'The cookies and similar storage EXXIO uses.' },
  { href: '/legal/disclaimer', label: 'Compliance Content Disclaimer', summary: 'Why our sample content is not legal advice.' },
  { href: '/legal/accessibility', label: 'Accessibility Statement', summary: 'Our accessibility commitment and how to get help.' },
] as const

export type LegalSection = { id: string; title: string; body: React.ReactNode }

export function LegalPage({ title, intro, current, sections }: {
  title: string
  intro?: React.ReactNode
  current: string
  sections: LegalSection[]
}) {
  return (
    <>
      <section style={{ background: '#f4f4f4', borderBottom: '1px solid #e0e0e0' }}>
        <div style={{ maxWidth: '76rem', margin: '0 auto', padding: '3.5rem 1rem 2.5rem' }}>
          <p style={{ fontSize: '0.875rem', fontWeight: 600, color: BLUE, letterSpacing: '0.04em', textTransform: 'uppercase' }}>
            <Link href="/legal" style={{ color: BLUE, textDecoration: 'none' }}>Legal</Link>
          </p>
          <h1 style={{ fontSize: 'clamp(2rem, 5vw, 3rem)', fontWeight: 300, color: INK, lineHeight: 1.1, marginTop: '0.75rem', maxWidth: '44rem' }}>
            {title}
          </h1>
          <p style={{ fontSize: '0.875rem', color: MUTED, marginTop: '1rem' }}>Last updated: {LEGAL.lastUpdated}</p>
          {intro && <div style={{ fontSize: '1.125rem', color: MUTED, lineHeight: 1.5, marginTop: '1.25rem', maxWidth: '44rem' }}>{intro}</div>}
        </div>
      </section>

      <div style={{
        maxWidth: '76rem', margin: '0 auto', padding: '2.5rem 1rem 4.5rem',
        display: 'flex', flexWrap: 'wrap', gap: '3rem', alignItems: 'flex-start',
      }}>
        <article style={{ flex: '1 1 30rem', minWidth: 0, maxWidth: '46rem' }}>
          {sections.length > 3 && (
            <nav aria-label="On this page" style={{ borderLeft: `3px solid ${BLUE}`, padding: '0.25rem 0 0.25rem 1rem', marginBottom: '2.5rem' }}>
              <p style={{ fontSize: '0.875rem', fontWeight: 600, color: INK, marginBottom: '0.5rem' }}>On this page</p>
              <ol style={{ margin: 0, paddingLeft: '1.25rem', display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
                {sections.map((s) => (
                  <li key={s.id} style={{ fontSize: '0.9375rem' }}>
                    <a href={`#${s.id}`} style={{ color: BLUE, textDecoration: 'none' }}>{s.title}</a>
                  </li>
                ))}
              </ol>
            </nav>
          )}
          {sections.map((s, i) => (
            <section key={s.id} id={s.id} style={{ scrollMarginTop: '5rem', marginBottom: '2.25rem' }}>
              <h2 style={{ fontSize: '1.375rem', fontWeight: 600, color: INK, lineHeight: 1.3, marginBottom: '0.75rem' }}>
                {sections.length > 3 ? `${i + 1}. ` : ''}{s.title}
              </h2>
              <div className="legal-body">{s.body}</div>
            </section>
          ))}
          <ContactBlock />
        </article>

        <aside style={{ flex: '0 1 16rem', minWidth: '14rem', position: 'sticky', top: '5.5rem' }}>
          <p style={{ fontSize: '0.875rem', fontWeight: 600, color: INK, marginBottom: '0.75rem' }}>Legal documents</p>
          <nav aria-label="Legal documents" style={{ display: 'flex', flexDirection: 'column', borderTop: '1px solid #e0e0e0' }}>
            {LEGAL_PAGES.map((p) => {
              const active = p.href === current
              return (
                <Link
                  key={p.href}
                  href={p.href}
                  aria-current={active ? 'page' : undefined}
                  style={{
                    display: 'block', padding: '0.625rem 0.75rem', fontSize: '0.9375rem', textDecoration: 'none',
                    borderBottom: '1px solid #e0e0e0', borderLeft: `3px solid ${active ? BLUE : 'transparent'}`,
                    color: active ? INK : MUTED, fontWeight: active ? 600 : 400, background: active ? '#f4f4f4' : 'transparent',
                  }}
                >
                  {p.label}
                </Link>
              )
            })}
          </nav>
        </aside>
      </div>
    </>
  )
}

function ContactBlock() {
  return (
    <div style={{ background: '#f4f4f4', borderLeft: `3px solid ${INK}`, padding: '1.25rem 1.5rem', marginTop: '3rem' }}>
      <p style={{ fontSize: '1rem', fontWeight: 600, color: INK }}>Questions about this document?</p>
      <p style={{ fontSize: '0.9375rem', color: MUTED, lineHeight: 1.6, marginTop: '0.5rem' }}>
        Email <Mail to={LEGAL.contactEmail} /> for legal questions or <Mail to={LEGAL.privacyEmail} /> for privacy questions.
        {LEGAL.address && <><br />{LEGAL.legalName}, {LEGAL.address}</>}
      </p>
    </div>
  )
}

export function Mail({ to }: { to: string }) {
  return <a href={`mailto:${to}`} style={{ color: BLUE }}>{to}</a>
}

export function P({ children }: { children: React.ReactNode }) {
  return <p>{children}</p>
}

export function List({ items }: { items: React.ReactNode[] }) {
  return <ul>{items.map((item, i) => <li key={i}>{item}</li>)}</ul>
}

export function Table({ head, rows }: { head: string[]; rows: React.ReactNode[][] }) {
  return (
    <div style={{ overflowX: 'auto', margin: '0.5rem 0 1rem' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.9375rem', minWidth: '32rem' }}>
        <thead>
          <tr>
            {head.map((h) => (
              <th key={h} scope="col" style={{ textAlign: 'left', padding: '0.625rem 0.75rem', background: '#e0e0e0', color: INK, fontWeight: 600 }}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => (
            <tr key={i}>
              {r.map((c, j) => (
                <td key={j} style={{ padding: '0.625rem 0.75rem', borderBottom: '1px solid #e0e0e0', verticalAlign: 'top', color: INK, lineHeight: 1.5 }}>{c}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

/** One sentence describing where data is stored, used by several pages. */
export function DataLocationSentence() {
  return LEGAL.dataInCanada
    ? <>Our primary database and file storage are hosted in {LEGAL.dataRegion}.</>
    : <>Our primary database and file storage are currently hosted outside Canada, in {LEGAL.dataRegion}.</>
}
