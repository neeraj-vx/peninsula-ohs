import type { Metadata } from 'next'
import Link from 'next/link'
import { Checkmark, CheckmarkFilled } from '@carbon/icons-react'
import { BLUE, INK, MUTED, CtaLink, Section } from '@/components/marketing/parts'
import { PLANS, COMPARISON, formatCad, type Plan } from '@/components/marketing/pricing'

export const metadata: Metadata = {
  title: 'Pricing — EXXIO',
  description:
    'EXXIO plans for Canadian employers: Essentials, Professional and Enterprise. Pricing is based on your plan and number of employees. Talk to us for a quote.',
}

const FAQ = [
  {
    q: 'How is pricing worked out?',
    a: 'It depends on the plan you choose and how many employees you have. Tell us a little about your workplace and we will give you a clear quote.',
  },
  {
    q: 'Can we change plans later?',
    a: 'Yes. You can move up or down a plan as your needs change. Your records stay where they are.',
  },
  {
    q: 'Is there a setup fee?',
    a: 'Talk to us. It depends on how much help you want getting set up, and we will be upfront about any costs before you commit.',
  },
  {
    q: 'Which plan is right for us?',
    a: 'If you are not sure, start a conversation with us. We will ask about your sites, your team and what you need to track, and suggest the plan that fits.',
  },
]

function Price({ plan }: { plan: Plan }) {
  if (plan.priceMonthlyCad === null) {
    return (
      <p style={{ fontSize: '1.5rem', fontWeight: 300, color: INK, lineHeight: 1.2 }}>
        Contact us for pricing
      </p>
    )
  }
  return (
    <p style={{ color: INK, lineHeight: 1.2 }}>
      <span style={{ fontSize: '2.25rem', fontWeight: 300 }}>{formatCad(plan.priceMonthlyCad)}</span>
      <span style={{ display: 'block', fontSize: '0.875rem', color: MUTED, marginTop: '0.25rem' }}>{plan.unit}</span>
    </p>
  )
}

function PlanCard({ plan }: { plan: Plan }) {
  return (
    <div style={{
      background: '#fff',
      border: plan.featured ? `2px solid ${BLUE}` : '1px solid #e0e0e0',
      borderTop: `4px solid ${plan.featured ? BLUE : INK}`,
      padding: '1.75rem 1.5rem',
      display: 'flex', flexDirection: 'column', gap: '1.25rem',
      position: 'relative',
    }}>
      {plan.featured && (
        <span style={{
          position: 'absolute', top: '1rem', right: '1rem', background: BLUE, color: '#fff',
          fontSize: '0.75rem', fontWeight: 600, padding: '0.25rem 0.5rem', letterSpacing: '0.02em',
        }}>
          Recommended
        </span>
      )}
      <div>
        <h2 style={{ fontSize: '1.5rem', fontWeight: 600, color: INK }}>{plan.name}</h2>
        <p style={{ fontSize: '1rem', color: MUTED, marginTop: '0.5rem', lineHeight: 1.5, paddingRight: plan.featured ? '5.5rem' : 0 }}>
          {plan.tagline}
        </p>
      </div>
      <Price plan={plan} />
      <ul style={{ listStyle: 'none', padding: 0, margin: 0, display: 'flex', flexDirection: 'column', gap: '0.625rem', flex: 1 }}>
        {plan.highlights.map((h) => (
          <li key={h} style={{ display: 'flex', gap: '0.5rem', alignItems: 'flex-start', fontSize: '1rem', color: INK, lineHeight: 1.4 }}>
            <CheckmarkFilled size={16} style={{ color: BLUE, flexShrink: 0, marginTop: 3 }} aria-hidden="true" />
            <span>{h}</span>
          </li>
        ))}
      </ul>
      <CtaLink href={plan.cta.href} variant={plan.featured ? 'primary' : 'secondary'}>{plan.cta.label}</CtaLink>
    </div>
  )
}

const cell: React.CSSProperties = { padding: '0.75rem 1rem', borderBottom: '1px solid #e0e0e0', fontSize: '0.9375rem' }

export default function PricingPage() {
  return (
    <>
      {/* Hero */}
      <section style={{ background: 'linear-gradient(180deg, #edf5ff 0%, #ffffff 100%)' }}>
        <div style={{ maxWidth: '76rem', margin: '0 auto', padding: '4.5rem 1rem 2rem' }}>
          <p style={{ fontSize: '0.875rem', fontWeight: 600, color: BLUE, letterSpacing: '0.04em', textTransform: 'uppercase' }}>
            Pricing
          </p>
          <h1 style={{ fontSize: 'clamp(2rem, 5vw, 3.25rem)', fontWeight: 300, color: INK, lineHeight: 1.1, marginTop: '0.75rem', maxWidth: '44rem' }}>
            Plans that grow with your workplace.
          </h1>
          <p style={{ fontSize: '1.25rem', color: MUTED, lineHeight: 1.5, marginTop: '1.25rem', maxWidth: '40rem' }}>
            Pricing is based on your plan and the number of people you employ. Tell us about your workplace
            and we will put together a clear quote, in Canadian dollars.
          </p>
        </div>
      </section>

      {/* Plans */}
      <section style={{ background: '#fff' }}>
        <div style={{
          maxWidth: '76rem', margin: '0 auto', padding: '2rem 1rem 4.5rem',
          display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(18rem, 1fr))', gap: '1.5rem', alignItems: 'stretch',
        }}>
          {PLANS.map((p) => <PlanCard key={p.id} plan={p} />)}
        </div>
      </section>

      {/* Comparison */}
      <Section tone="grey" title="Compare plans" intro="Every plan includes the same Canadian focus: provincial OHS content, statutory holidays in deadlines, and Canadian dates and terminology.">
        <div style={{ overflowX: 'auto', background: '#fff', border: '1px solid #e0e0e0' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: '36rem' }}>
            <caption style={{ position: 'absolute', width: 1, height: 1, overflow: 'hidden', clip: 'rect(0 0 0 0)' }}>
              Features included in each EXXIO plan
            </caption>
            <thead>
              <tr style={{ background: '#e0e0e0' }}>
                <th scope="col" style={{ ...cell, textAlign: 'left', fontWeight: 600, color: INK }}>Feature</th>
                {PLANS.map((p) => (
                  <th key={p.id} scope="col" style={{ ...cell, textAlign: 'center', fontWeight: 600, color: p.featured ? BLUE : INK }}>{p.name}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {COMPARISON.map((row) => (
                <tr key={row.feature}>
                  <th scope="row" style={{ ...cell, textAlign: 'left', fontWeight: 400, color: INK }}>{row.feature}</th>
                  {PLANS.map((p) => {
                    const included = row.plans.includes(p.id)
                    return (
                      <td key={p.id} style={{ ...cell, textAlign: 'center' }}>
                        {included
                          ? <Checkmark size={20} style={{ color: BLUE }} aria-label="Included" />
                          : <span style={{ color: '#a8a8a8' }} aria-label="Not included">—</span>}
                      </td>
                    )
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Section>

      {/* FAQ */}
      <Section title="Questions about pricing">
        <div style={{ maxWidth: '48rem' }}>
          {FAQ.map((f) => (
            <details key={f.q} style={{ borderBottom: '1px solid #e0e0e0', padding: '1.25rem 0' }}>
              <summary style={{ fontSize: '1.125rem', fontWeight: 600, color: INK, cursor: 'pointer' }}>{f.q}</summary>
              <p style={{ fontSize: '1rem', color: MUTED, lineHeight: 1.6, marginTop: '0.75rem' }}>{f.a}</p>
            </details>
          ))}
        </div>
      </Section>

      {/* Closing CTA */}
      <section style={{ background: BLUE }}>
        <div style={{ maxWidth: '76rem', margin: '0 auto', padding: '4rem 1rem', display: 'flex', flexWrap: 'wrap', gap: '2rem', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ maxWidth: '38rem' }}>
            <h2 style={{ fontSize: 'clamp(1.5rem, 3vw, 2.25rem)', fontWeight: 300, color: '#fff', lineHeight: 1.2 }}>
              Get a quote for your workplace.
            </h2>
            <p style={{ fontSize: '1.125rem', color: '#d0e2ff', marginTop: '0.75rem', lineHeight: 1.5 }}>
              Tell us how many people you employ and what you need to track. We will reply with a plan and a price.
            </p>
          </div>
          <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
            <CtaLink href="/contact?interest=pricing" variant="inverse">Talk to us</CtaLink>
            <Link href="/register" style={{ color: '#fff', alignSelf: 'center', fontWeight: 600, textDecoration: 'underline' }}>
              Create an account
            </Link>
          </div>
        </div>
      </section>
    </>
  )
}
