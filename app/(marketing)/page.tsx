import type { Metadata } from 'next'
import Link from 'next/link'
import {
  WarningAlt, Education, TaskComplete, Calendar, DocumentSigned, UserMultiple,
  Analytics, Construction, Alarm, Security, CheckmarkFilled, Locked, Activity,
} from '@carbon/icons-react'
import { BLUE, RED, INK, MUTED, CtaLink, Section, ProductPreview } from '@/components/marketing/parts'

export const metadata: Metadata = {
  title: 'EXXIO — Health & safety software for Canadian workplaces',
  description:
    'Report incidents, assign training, run inspections and stay on top of provincial OHS requirements in one simple platform built for Canadian employers.',
}

const OUTCOMES = [
  {
    icon: WarningAlt, colour: RED, title: 'Report it in seconds',
    text: 'Anyone can report an incident, a near miss or a hazard from their phone. The right people are told straight away.',
  },
  {
    icon: Calendar, colour: '#ff832b', title: 'Never miss a deadline',
    text: 'Due dates count business days and skip statutory holidays. Overdue inspections, tasks and training are flagged automatically.',
  },
  {
    icon: Education, colour: BLUE, title: 'Training that assigns itself',
    text: 'Decide once which courses each role needs. New starters are assigned automatically, and refreshers go out before certificates expire.',
  },
]

const FEATURES = [
  { icon: WarningAlt, title: 'Incidents and hazards', text: 'Report, triage and investigate, with corrective actions tracked to close.' },
  { icon: TaskComplete, title: 'Inspections and risks', text: 'Scheduled inspections, a risk register with ready-made templates, and job safety analyses.' },
  { icon: Education, title: 'Training and certificates', text: 'Required training by role, automatic assignments, expiry reminders and toolbox talks.' },
  { icon: UserMultiple, title: 'Hiring and background checks', text: 'Offer letters, onboarding checklists, consent and reference checks in one flow.' },
  { icon: DocumentSigned, title: 'Policies and sign-off', text: 'Publish procedures, run reviews and collect acknowledgements from staff.' },
  { icon: Construction, title: 'Contractors and permits', text: 'Contractor records, site sign-in, permits to work and lockout procedures.' },
  { icon: Alarm, title: 'Emergency readiness', text: 'Response plans, wardens, muster points and drill records.' },
  { icon: Analytics, title: 'Reports and KPIs', text: 'Injury rates (TRIR, LTIR), training compliance and trends for leadership.' },
]

const CANADA = [
  'Provincial OHS focus, starting with Ontario (BC, Alberta and Quebec content in progress)',
  'WHMIS 2015 chemical register with safety data sheets',
  'CSA standards for protective equipment',
  'Federal and provincial statutory holidays in every deadline',
  'Minimum wage and probation checks when you hire',
  'Canadian dates, currency, time zones and terminology',
]

const ROLES = [
  { title: 'Workers', text: 'Report something, see what is assigned to them, and keep their training up to date. Nothing else to learn.' },
  { title: 'Supervisors', text: 'Run inspections and toolbox talks, follow up on their team, and close out actions.' },
  { title: 'Health & safety leads', text: 'Manage risks, investigations, required training and the compliance calendar.' },
  { title: 'Leadership', text: 'See injury rates, overdue work and training compliance at a glance.' },
]

const SECURITY = [
  { icon: Locked, text: 'Each organisation’s data is isolated by access rules enforced in the database itself.' },
  { icon: UserMultiple, text: 'Role-based access: people only see what their role needs.' },
  { icon: Activity, text: 'An audit trail records who changed what, and when.' },
  { icon: Security, text: 'Confidential speak-up reports are visible only to the people who must handle them.' },
]

export default function MarketingHomePage() {
  return (
    <>
      {/* Hero */}
      <section style={{ background: 'linear-gradient(180deg, #edf5ff 0%, #ffffff 100%)' }}>
        <div style={{
          maxWidth: '76rem', margin: '0 auto', padding: '4.5rem 1rem 4rem',
          display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(20rem, 1fr))', gap: '3rem', alignItems: 'center',
        }}>
          <div>
            <p style={{ fontSize: '0.875rem', fontWeight: 600, color: BLUE, letterSpacing: '0.04em', textTransform: 'uppercase' }}>
              Health &amp; safety for Canadian workplaces
            </p>
            <h1 style={{ fontSize: 'clamp(2rem, 5vw, 3.25rem)', fontWeight: 300, color: INK, lineHeight: 1.1, marginTop: '0.75rem' }}>
              Keep your people safe without the paperwork.
            </h1>
            <p style={{ fontSize: '1.25rem', color: MUTED, lineHeight: 1.5, marginTop: '1.25rem', maxWidth: '34rem' }}>
              Incidents, training, inspections, hiring and compliance in one simple place, built around
              provincial health and safety law.
            </p>
            <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap', marginTop: '2rem' }}>
              <CtaLink href="/register">Get started</CtaLink>
              <CtaLink href="/how-it-works" variant="secondary">See how it works</CtaLink>
            </div>
            <p style={{ fontSize: '0.875rem', color: MUTED, marginTop: '1rem' }}>
              Set up your workplace in minutes. No training course needed to use it.
            </p>
          </div>
          <div style={{ display: 'flex', justifyContent: 'center' }}>
            <ProductPreview />
          </div>
        </div>
      </section>

      {/* Outcomes */}
      <Section title="Less chasing. Fewer surprises." intro="EXXIO does the remembering for you, so your team can focus on the work.">
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(16rem, 1fr))', gap: '1.5rem' }}>
          {OUTCOMES.map(({ icon: Icon, colour, title, text }) => (
            <div key={title} style={{ borderTop: `3px solid ${colour}`, background: '#f4f4f4', padding: '1.5rem' }}>
              <Icon size={24} style={{ color: colour }} />
              <h3 style={{ fontSize: '1.25rem', fontWeight: 600, color: INK, marginTop: '0.75rem' }}>{title}</h3>
              <p style={{ fontSize: '1rem', color: MUTED, lineHeight: 1.5, marginTop: '0.5rem' }}>{text}</p>
            </div>
          ))}
        </div>
      </Section>

      {/* Features */}
      <Section id="features" tone="grey" title="Everything your safety program needs" intro="Start with the basics. Turn on the rest when you need it.">
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(16rem, 1fr))', gap: '1px', background: '#e0e0e0', border: '1px solid #e0e0e0' }}>
          {FEATURES.map(({ icon: Icon, title, text }) => (
            <div key={title} style={{ background: '#fff', padding: '1.5rem' }}>
              <Icon size={20} style={{ color: BLUE }} />
              <h3 style={{ fontSize: '1rem', fontWeight: 600, color: INK, marginTop: '0.75rem' }}>{title}</h3>
              <p style={{ fontSize: '0.9375rem', color: MUTED, lineHeight: 1.5, marginTop: '0.375rem' }}>{text}</p>
            </div>
          ))}
        </div>
      </Section>

      {/* Canada */}
      <Section id="canada" title="Built for Canada, not adapted for it" intro="Rules, terms and deadlines follow Canadian law and practice.">
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(18rem, 1fr))', gap: '1rem 2rem' }}>
          {CANADA.map((item) => (
            <p key={item} style={{ display: 'flex', gap: '0.75rem', fontSize: '1rem', color: INK, lineHeight: 1.5 }}>
              <CheckmarkFilled size={20} style={{ color: '#24a148', flexShrink: 0, marginTop: 2 }} />
              {item}
            </p>
          ))}
        </div>
      </Section>

      {/* Roles */}
      <Section tone="grey" title="Simple for every role" intro="Each person sees only what they need, so first-time users know exactly what to do.">
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(15rem, 1fr))', gap: '1.5rem' }}>
          {ROLES.map(({ title, text }) => (
            <div key={title} style={{ background: '#fff', padding: '1.5rem', borderLeft: `3px solid ${BLUE}` }}>
              <h3 style={{ fontSize: '1.125rem', fontWeight: 600, color: INK }}>{title}</h3>
              <p style={{ fontSize: '0.9375rem', color: MUTED, lineHeight: 1.5, marginTop: '0.5rem' }}>{text}</p>
            </div>
          ))}
        </div>
      </Section>

      {/* Security */}
      <Section id="security" title="Your data stays yours" intro="Health and safety records are sensitive. EXXIO is built to keep them private.">
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(16rem, 1fr))', gap: '1.5rem' }}>
          {SECURITY.map(({ icon: Icon, text }) => (
            <div key={text} style={{ display: 'flex', gap: '0.75rem' }}>
              <Icon size={24} style={{ color: BLUE, flexShrink: 0 }} />
              <p style={{ fontSize: '1rem', color: INK, lineHeight: 1.5 }}>{text}</p>
            </div>
          ))}
        </div>
      </Section>

      {/* Closing CTA */}
      <section style={{ background: BLUE }}>
        <div style={{ maxWidth: '76rem', margin: '0 auto', padding: '4rem 1rem', display: 'flex', flexWrap: 'wrap', gap: '2rem', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ maxWidth: '38rem' }}>
            <h2 style={{ fontSize: 'clamp(1.5rem, 3vw, 2.25rem)', fontWeight: 300, color: '#fff', lineHeight: 1.2 }}>
              Set up your workplace today.
            </h2>
            <p style={{ fontSize: '1.125rem', color: '#d0e2ff', marginTop: '0.75rem', lineHeight: 1.5 }}>
              Add your sites, invite your team and choose required training. EXXIO handles the reminders from there.
            </p>
          </div>
          <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
            <CtaLink href="/register" variant="inverse">Get started</CtaLink>
            <Link href="/how-it-works" style={{ color: '#fff', alignSelf: 'center', fontWeight: 600, textDecoration: 'underline' }}>
              How it works
            </Link>
            <Link href="/contact" style={{ color: '#fff', alignSelf: 'center', fontWeight: 600, textDecoration: 'underline' }}>
              Talk to us
            </Link>
          </div>
        </div>
      </section>
    </>
  )
}
