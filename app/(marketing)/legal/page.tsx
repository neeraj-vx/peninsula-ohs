import type { Metadata } from 'next'
import Link from 'next/link'
import { ArrowRight } from '@carbon/icons-react'
import { BLUE, INK, MUTED } from '@/components/marketing/parts'
import { LEGAL, LEGAL_PAGES, Mail } from '@/components/marketing/legal'

export const metadata: Metadata = {
  title: 'Legal — EXXIO',
  description: 'EXXIO’s Terms of Service, Privacy Policy, Data Processing Addendum, subprocessors and other policies.',
}

export default function LegalIndexPage() {
  return (
    <>
      <section style={{ background: '#f4f4f4', borderBottom: '1px solid #e0e0e0' }}>
        <div style={{ maxWidth: '76rem', margin: '0 auto', padding: '3.5rem 1rem 2.5rem' }}>
          <p style={{ fontSize: '0.875rem', fontWeight: 600, color: BLUE, letterSpacing: '0.04em', textTransform: 'uppercase' }}>Legal</p>
          <h1 style={{ fontSize: 'clamp(2rem, 5vw, 3rem)', fontWeight: 300, color: INK, lineHeight: 1.1, marginTop: '0.75rem', maxWidth: '44rem' }}>
            Policies and agreements
          </h1>
          <p style={{ fontSize: '1.125rem', color: MUTED, lineHeight: 1.5, marginTop: '1.25rem', maxWidth: '44rem' }}>
            The documents that govern how you use EXXIO and how we look after the information you trust us with.
          </p>
        </div>
      </section>

      <section style={{ maxWidth: '76rem', margin: '0 auto', padding: '2.5rem 1rem 4.5rem' }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(18rem, 1fr))', gap: '1px', background: '#e0e0e0', border: '1px solid #e0e0e0' }}>
          {LEGAL_PAGES.map((p) => (
            <Link key={p.href} href={p.href} style={{ background: '#fff', padding: '1.5rem', textDecoration: 'none', display: 'flex', flexDirection: 'column', gap: '0.5rem', minHeight: '9rem' }}>
              <span style={{ fontSize: '1.125rem', fontWeight: 600, color: INK }}>{p.label}</span>
              <span style={{ fontSize: '0.9375rem', color: MUTED, lineHeight: 1.5, flex: 1 }}>{p.summary}</span>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.375rem', color: BLUE, fontSize: '0.875rem', fontWeight: 600 }}>
                Read <ArrowRight size={16} aria-hidden="true" />
              </span>
            </Link>
          ))}
        </div>
        <p style={{ fontSize: '0.9375rem', color: MUTED, lineHeight: 1.6, marginTop: '2rem', maxWidth: '44rem' }}>
          Questions? Email <Mail to={LEGAL.contactEmail} /> for legal matters, <Mail to={LEGAL.privacyEmail} /> for
          privacy and <Mail to={LEGAL.securityEmail} /> to report a security issue.
        </p>
      </section>
    </>
  )
}
