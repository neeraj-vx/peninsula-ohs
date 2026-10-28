import type { Metadata } from 'next'
import Link from 'next/link'
import { Chat, Money, Education } from '@carbon/icons-react'
import { BLUE, INK, MUTED } from '@/components/marketing/parts'
import { ContactForm } from './ContactForm'

export const metadata: Metadata = {
  title: 'Contact us — EXXIO',
  description:
    'Talk to us about EXXIO for your workplace. Ask about pricing, book a demo or send us a question.',
}

const REASONS = [
  { icon: Money, title: 'Pricing', text: 'Get a quote based on your plan and the number of people you employ.' },
  { icon: Education, title: 'A demo', text: 'See how incidents, training and inspections work for a workplace like yours.' },
  { icon: Chat, title: 'Questions', text: 'Ask us anything about EXXIO and how it fits your safety program.' },
]

export default async function ContactPage({ searchParams }: { searchParams: Promise<{ interest?: string | string[] }> }) {
  const params = await searchParams
  const interest = typeof params.interest === 'string' ? params.interest : ''

  return (
    <section style={{ background: 'linear-gradient(180deg, #edf5ff 0%, #ffffff 40%)' }}>
      <div style={{
        maxWidth: '76rem', margin: '0 auto', padding: '4.5rem 1rem',
        display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(20rem, 1fr))', gap: '3rem', alignItems: 'start',
      }}>
        <div>
          <p style={{ fontSize: '0.875rem', fontWeight: 600, color: BLUE, letterSpacing: '0.04em', textTransform: 'uppercase' }}>
            Contact
          </p>
          <h1 style={{ fontSize: 'clamp(2rem, 5vw, 3.25rem)', fontWeight: 300, color: INK, lineHeight: 1.1, marginTop: '0.75rem' }}>
            Talk to us about EXXIO for your workplace.
          </h1>
          <p style={{ fontSize: '1.25rem', color: MUTED, lineHeight: 1.5, marginTop: '1.25rem', maxWidth: '34rem' }}>
            Send us a few details and a real person will get back to you by email.
          </p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem', marginTop: '2.5rem' }}>
            {REASONS.map(({ icon: Icon, title, text }) => (
              <div key={title} style={{ display: 'flex', gap: '0.875rem', alignItems: 'flex-start' }}>
                <Icon size={24} style={{ color: BLUE, flexShrink: 0 }} aria-hidden="true" />
                <div>
                  <h2 style={{ fontSize: '1.125rem', fontWeight: 600, color: INK }}>{title}</h2>
                  <p style={{ fontSize: '1rem', color: MUTED, lineHeight: 1.5, marginTop: '0.25rem' }}>{text}</p>
                </div>
              </div>
            ))}
          </div>
          <p style={{ fontSize: '0.9375rem', color: MUTED, marginTop: '2.5rem', lineHeight: 1.5 }}>
            Ready to try it yourself? <Link href="/register" style={{ color: BLUE, fontWeight: 600 }}>Create an account</Link>.
            {' '}See our <Link href="/pricing" style={{ color: BLUE, fontWeight: 600 }}>plans</Link>.
          </p>
        </div>

        <div style={{ background: '#fff', border: '1px solid #e0e0e0', borderTop: `4px solid ${BLUE}`, padding: 'clamp(1.25rem, 3vw, 2rem)', position: 'relative' }}>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 400, color: INK, marginBottom: '0.5rem' }}>Send us a message</h2>
          <p style={{ fontSize: '0.875rem', color: MUTED, marginBottom: '1.5rem' }}>Fields marked “required” must be filled in.</p>
          <ContactForm defaultInterest={interest} />
        </div>
      </div>
    </section>
  )
}
