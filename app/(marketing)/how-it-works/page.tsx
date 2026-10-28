import type { Metadata } from 'next'
import Link from 'next/link'
import { ArrowRight, CheckmarkFilled } from '@carbon/icons-react'
import { BLUE, RED, INK, MUTED, CtaLink, Section } from '@/components/marketing/parts'

export const metadata: Metadata = {
  title: 'How EXXIO works — Health & safety software for Canadian workplaces',
  description:
    'See how EXXIO takes you from setup to a running safety program: sites and team, required training, reporting, follow-up and results.',
}

const STEPS = [
  {
    title: 'Set up your workplace',
    text: 'Add your organisation, province and work sites, then invite your team. Each person gets a role (worker, supervisor, health & safety lead or administrator) that decides what they see.',
    detail: 'A short checklist on your home page walks you through it.',
  },
  {
    title: 'Choose the training each role needs',
    text: 'Pick a course and the role that must take it, for example WHMIS 2015 for everyone. Everyone in that role is assigned it with a due date, and new starters are assigned it when they join.',
    detail: 'Refreshers are assigned automatically before a certificate expires.',
  },
  {
    title: 'Report and respond',
    text: 'Anyone can report an incident, near miss or hazard in under a minute. The health & safety lead and administrators are notified, and follow-up actions are assigned to named people with due dates.',
    detail: 'Confidential concerns go only to the people who must handle them.',
  },
  {
    title: 'Stay on schedule',
    text: 'Inspections are created on schedule, overdue tasks are flagged every night, and reminders go out before deadlines. Due dates count business days and skip statutory holidays.',
    detail: 'Each person’s home page shows exactly what needs doing next.',
  },
  {
    title: 'See where you stand',
    text: 'Leadership sees open incidents, overdue work, high risks and training compliance at a glance, with injury rates (TRIR and LTIR) calculated from your records.',
    detail: 'Every change is kept in an audit trail.',
  },
]

const INCIDENT_FLOW = [
  { label: 'Reported', note: 'by anyone, from any device' },
  { label: 'Triaged', note: 'severity and next steps set' },
  { label: 'Investigated', note: 'root causes found' },
  { label: 'Actions', note: 'assigned with due dates' },
  { label: 'Closed', note: 'once actions are verified' },
]

const AUTOMATIC = [
  'Reference numbers for every record (for example INC-2026-00001)',
  'Notifications to the right people when something is reported or assigned',
  'Training assigned to new starters and refreshers before expiry',
  'Overdue tasks, inspections and training flagged every night',
  'Scheduled inspections created ahead of their due date',
  'Expiry reminders for certificates and documents',
  'Injury rates and training compliance recalculated daily',
  'An audit trail of who changed what, and when',
]

const DAY = [
  { role: 'Worker', items: ['Sees their tasks and training on the home page', 'Reports a hazard from their phone', 'Logs a completed course'] },
  { role: 'Supervisor', items: ['Runs a toolbox talk and records who attended', 'Completes a site inspection', 'Closes out actions for their team'] },
  { role: 'Health & safety lead', items: ['Triages new incidents', 'Assigns corrective actions', 'Adds a new required course for a role'] },
  { role: 'Leadership', items: ['Checks open incidents and overdue work', 'Reviews injury rates and training compliance'] },
]

const FAQ = [
  {
    q: 'Which provinces does EXXIO support?',
    a: 'EXXIO is built for Canadian workplaces and starts with Ontario. Federal and Ontario statutory holidays are built in, and content for British Columbia, Alberta and Quebec is in progress.',
  },
  {
    q: 'Do my workers need training to use it?',
    a: 'No. Workers see only a few things: report something, their tasks and their training. Every screen also has a short explanation the first time it is opened.',
  },
  {
    q: 'Does it work on phones?',
    a: 'Yes. EXXIO works in any modern browser on phones, tablets and computers, and can be added to a phone’s home screen like an app.',
  },
  {
    q: 'Does EXXIO make us compliant?',
    a: 'EXXIO helps you organise, track and evidence your health and safety program. It does not replace legal advice. Your obligations depend on your province and industry, so confirm them with your regulator or a qualified advisor.',
  },
]

export default function HowItWorksPage() {
  return (
    <>
      <section style={{ background: 'linear-gradient(180deg, #edf5ff 0%, #ffffff 100%)' }}>
        <div style={{ maxWidth: '76rem', margin: '0 auto', padding: '4.5rem 1rem 3rem' }}>
          <p style={{ fontSize: '0.875rem', fontWeight: 600, color: BLUE, letterSpacing: '0.04em', textTransform: 'uppercase' }}>How it works</p>
          <h1 style={{ fontSize: 'clamp(2rem, 5vw, 3rem)', fontWeight: 300, color: INK, lineHeight: 1.1, marginTop: '0.75rem', maxWidth: '44rem' }}>
            From setup to a safety program that runs itself, in five steps.
          </h1>
          <p style={{ fontSize: '1.25rem', color: MUTED, lineHeight: 1.5, marginTop: '1.25rem', maxWidth: '40rem' }}>
            You decide what matters once. EXXIO assigns the work, reminds people and keeps the record.
          </p>
        </div>
      </section>

      {/* Steps */}
      <section style={{ background: '#fff' }}>
        <ol style={{ maxWidth: '56rem', margin: '0 auto', padding: '1rem 1rem 4rem', listStyle: 'none' }}>
          {STEPS.map((s, i) => (
            <li key={s.title} style={{ display: 'flex', gap: '1.5rem', paddingBottom: i < STEPS.length - 1 ? '2.5rem' : 0, position: 'relative' }}>
              {i < STEPS.length - 1 && (
                <span aria-hidden="true" style={{ position: 'absolute', left: '1.25rem', top: '2.75rem', bottom: '0.25rem', width: 2, background: '#d0e2ff' }} />
              )}
              <span style={{
                width: '2.5rem', height: '2.5rem', borderRadius: '50%', background: BLUE, color: '#fff', flexShrink: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 600, fontSize: '1.125rem', position: 'relative',
              }}>
                {i + 1}
              </span>
              <div>
                <h2 style={{ fontSize: '1.375rem', fontWeight: 600, color: INK, marginTop: '0.25rem' }}>{s.title}</h2>
                <p style={{ fontSize: '1.0625rem', color: MUTED, lineHeight: 1.6, marginTop: '0.5rem' }}>{s.text}</p>
                <p style={{ fontSize: '0.9375rem', color: INK, marginTop: '0.5rem', display: 'flex', gap: '0.5rem' }}>
                  <CheckmarkFilled size={18} style={{ color: '#24a148', flexShrink: 0, marginTop: 2 }} />{s.detail}
                </p>
              </div>
            </li>
          ))}
        </ol>
      </section>

      {/* Incident lifecycle */}
      <Section tone="grey" title="What happens when something goes wrong" intro="Every incident follows the same clear path, so nothing is left hanging.">
        <div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'stretch', gap: '0.5rem' }}>
          {INCIDENT_FLOW.map((stage, i) => (
            <div key={stage.label} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', flex: '1 1 10rem' }}>
              <div style={{ flex: 1, background: '#fff', padding: '1rem', borderTop: `3px solid ${i === 0 ? RED : i === INCIDENT_FLOW.length - 1 ? '#24a148' : BLUE}` }}>
                <p style={{ fontSize: '1rem', fontWeight: 600, color: INK }}>{stage.label}</p>
                <p style={{ fontSize: '0.875rem', color: MUTED, marginTop: '0.25rem' }}>{stage.note}</p>
              </div>
              {i < INCIDENT_FLOW.length - 1 && <ArrowRight size={20} style={{ color: '#8d8d8d', flexShrink: 0 }} aria-hidden="true" />}
            </div>
          ))}
        </div>
      </Section>

      {/* Automatic */}
      <Section title="What EXXIO does for you automatically" intro="The routine work that usually lives in spreadsheets and calendar reminders.">
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(20rem, 1fr))', gap: '1rem 2rem' }}>
          {AUTOMATIC.map((item) => (
            <p key={item} style={{ display: 'flex', gap: '0.75rem', fontSize: '1rem', color: INK, lineHeight: 1.5 }}>
              <CheckmarkFilled size={20} style={{ color: '#24a148', flexShrink: 0, marginTop: 2 }} />{item}
            </p>
          ))}
        </div>
      </Section>

      {/* A day in EXXIO */}
      <Section tone="grey" title="A day in EXXIO" intro="Everyone has a short, clear list. Nobody has to learn the whole system.">
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(15rem, 1fr))', gap: '1.5rem' }}>
          {DAY.map((d) => (
            <div key={d.role} style={{ background: '#fff', padding: '1.5rem', borderLeft: `3px solid ${BLUE}` }}>
              <h3 style={{ fontSize: '1.125rem', fontWeight: 600, color: INK }}>{d.role}</h3>
              <ul style={{ marginTop: '0.75rem', paddingLeft: '1.125rem', listStyle: 'disc' }}>
                {d.items.map((item) => (
                  <li key={item} style={{ fontSize: '0.9375rem', color: MUTED, lineHeight: 1.5, marginBottom: '0.375rem' }}>{item}</li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </Section>

      {/* FAQ */}
      <Section title="Common questions">
        <div style={{ maxWidth: '48rem' }}>
          {FAQ.map((f) => (
            <details key={f.q} style={{ borderBottom: '1px solid #e0e0e0', padding: '1.25rem 0' }}>
              <summary style={{ fontSize: '1.125rem', fontWeight: 600, color: INK, cursor: 'pointer' }}>{f.q}</summary>
              <p style={{ fontSize: '1rem', color: MUTED, lineHeight: 1.6, marginTop: '0.75rem' }}>{f.a}</p>
            </details>
          ))}
        </div>
      </Section>

      <section style={{ background: BLUE }}>
        <div style={{ maxWidth: '76rem', margin: '0 auto', padding: '4rem 1rem', display: 'flex', flexWrap: 'wrap', gap: '2rem', alignItems: 'center', justifyContent: 'space-between' }}>
          <h2 style={{ fontSize: 'clamp(1.5rem, 3vw, 2.25rem)', fontWeight: 300, color: '#fff', lineHeight: 1.2, maxWidth: '36rem' }}>
            Ready to set up your workplace?
          </h2>
          <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
            <CtaLink href="/register" variant="inverse">Get started</CtaLink>
            <Link href="/contact" style={{ color: '#fff', alignSelf: 'center', fontWeight: 600, textDecoration: 'underline' }}>
              Talk to us
            </Link>
          </div>
        </div>
      </section>
    </>
  )
}
