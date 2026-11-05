import type { Metadata } from 'next'
import Link from 'next/link'
import { ArrowRight, CheckmarkFilled } from '@carbon/icons-react'
import { BLUE, RED, INK, MUTED, CtaLink, Section } from '@/components/marketing/parts'

export const metadata: Metadata = {
  title: 'How EXXIO works — Health & safety software for Canadian workplaces',
  description:
    'See how EXXIO works, from creating your account and setting up your workplace to everyday reporting, follow-up, training and hiring.',
}

// Grid columns that never overflow a phone screen
const cols = (min: string) => `repeat(auto-fit, minmax(min(${min}, 100%), 1fr))`

const GETTING_STARTED = [
  {
    title: 'Create your account',
    text: 'Two short screens. First your name, work email and a password. Then your company name, industry and time zone, and a web address for your company, such as yourco.exxio.ai. You become your company’s administrator.',
    detail: 'Your company’s records are kept separate from every other company’s.',
  },
  {
    title: 'Set up your workplace',
    text: 'A setup wizard opens straight away and takes you through five steps:',
    steps: [
      'Your first site: its name, type and province',
      'A department (optional)',
      'Your team, with a role for each person',
      'Starter templates for your industry, such as inspection checklists and risk categories (optional)',
      'Done. You land on the Assistant.',
    ],
    detail: 'The rest of EXXIO opens once setup is finished.',
  },
  {
    title: 'Sign in each day',
    text: 'Sign in with your email and password. Two-step sign-in adds a code from an authenticator app, and administrators must use it. You start on the Assistant, where you can ask about your records in plain language or go straight to any area.',
    detail: 'Each person sees only the areas their role needs.',
  },
]

const AREAS = [
  { name: 'Assistant', text: 'Ask a question, find a record or start a task in plain language.' },
  { name: 'Home', text: 'Your dashboard, with open work and key numbers at a glance.' },
  { name: 'My tasks', text: 'Every action assigned to you, with its due date.' },
  { name: 'Safety', text: 'Incidents, hazards, risks and inspections.' },
  { name: 'Training', text: 'Courses, required training for each role, inductions and records.' },
  { name: 'People', text: 'Workers, hiring and onboarding, and background checks.', who: 'Managers' },
  { name: 'Documents', text: 'Policies and procedures, with review workflows and sign-off.' },
  { name: 'More tools', text: 'Job safety analysis, permits, lockout/tagout, toolbox talks, audits, contractors, emergency plans, chemicals (WHMIS), PPE and more.' },
  { name: 'Settings', text: 'Company details, sites and departments, users and roles, and notifications.', who: 'Administrators' },
]

const SAFETY_LOOP = [
  { label: 'Report', note: 'An incident, near miss or hazard, by anyone, from any device' },
  { label: 'Investigate', note: 'A supervisor starts an investigation and finds the cause' },
  { label: 'Assign actions', note: 'Fixes go to named people with due dates' },
  { label: 'My tasks', note: 'Each person sees what is theirs until it is done' },
  { label: 'Close', note: 'The record is closed and kept' },
]

const FLOWS = [
  {
    title: 'Training',
    intro: 'Decide once which training each role needs. EXXIO does the rest.',
    steps: [
      'Set a rule: the course a role must take, for example WHMIS for everyone.',
      'Everyone in that role is assigned it with a due date, including new starters when they join.',
      'Overdue training is flagged.',
      'Refreshers are prompted before a certificate expires.',
      'Attending a toolbox talk is recorded as training automatically.',
    ],
  },
  {
    title: 'Hiring',
    intro: 'Bring a new person on board with the right paperwork for their province.',
    steps: [
      'Start a new hire with their role, site and start date.',
      'Create the employment contract and documents from your templates, checked against the rules for their province.',
      'The new hire signs electronically.',
      'Work through the pre-start checklist.',
      'Finish the hire, and they become a worker in EXXIO.',
    ],
    note: 'Background checks can be requested from People. The candidate gives consent through a secure emailed link.',
  },
]

const AUTOMATIC = [
  'Reference numbers for every record (for example INC-2026-00001)',
  'Notifications to the right people when something is reported or assigned',
  'Training assigned to new starters and refreshers before expiry',
  'Overdue tasks, inspections and training flagged every night',
  'Scheduled inspections created ahead of their due date',
  'Expiry reminders for certificates and documents',
  'Due dates that count business days and skip statutory holidays',
  'An audit trail of who changed what, and when',
]

const DAY = [
  { role: 'Worker', items: ['Sees their tasks and training', 'Reports a hazard from their phone', 'Signs off a toolbox talk or a new procedure'] },
  { role: 'Supervisor', items: ['Runs a toolbox talk and records who attended', 'Completes a site inspection', 'Investigates an incident and assigns the fixes'] },
  { role: 'Manager', items: ['Sets the training each role needs', 'Hires and onboards new people', 'Keeps the compliance calendar up to date'] },
  { role: 'Administrator', items: ['Adds sites, departments and users', 'Chooses who is notified about what', 'Reviews injury rates and overdue work'] },
]

const FAQ = [
  {
    q: 'How long does setup take?',
    a: 'Creating your account takes two short screens, and the setup wizard has five steps, two of them optional. You can add more sites, people and templates at any time afterwards.',
  },
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
    a: 'EXXIO helps you organize, track and evidence your health and safety program. It does not replace legal advice. Your obligations depend on your province and industry, so confirm them with your regulator or a qualified advisor.',
  },
]

function NumberBadge({ n }: { n: number }) {
  return (
    <span style={{
      width: '2.5rem', height: '2.5rem', background: BLUE, color: '#fff', flexShrink: 0,
      display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 600, fontSize: '1.125rem', position: 'relative',
    }}>
      {n}
    </span>
  )
}

export default function HowItWorksPage() {
  return (
    <>
      <section style={{ background: '#edf5ff', borderBottom: '1px solid #d0e2ff' }}>
        <div style={{ maxWidth: '76rem', margin: '0 auto', padding: '4.5rem 1rem 3rem' }}>
          <p style={{ fontSize: '0.875rem', fontWeight: 600, color: BLUE, letterSpacing: '0.04em', textTransform: 'uppercase' }}>How it works</p>
          <h1 style={{ fontSize: 'clamp(2rem, 5vw, 3rem)', fontWeight: 300, color: INK, lineHeight: 1.1, marginTop: '0.75rem', maxWidth: '44rem' }}>
            From sign-up to a safety program that runs every day.
          </h1>
          <p style={{ fontSize: '1.25rem', color: MUTED, lineHeight: 1.5, marginTop: '1.25rem', maxWidth: '40rem' }}>
            Set up your company in a few minutes. EXXIO then guides reporting, follow-up, training and hiring, and keeps the record.
          </p>
          <nav aria-label="On this page" style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem 1.5rem', marginTop: '2rem' }}>
            {[
              ['#getting-started', 'Getting started'],
              ['#areas', 'What your team sees'],
              ['#safety-loop', 'The everyday safety loop'],
              ['#training-hiring', 'Training and hiring'],
            ].map(([href, label]) => (
              <a key={href} href={href} style={{ color: BLUE, fontWeight: 600, fontSize: '0.9375rem', textDecoration: 'none', borderBottom: `2px solid ${BLUE}` }}>
                {label}
              </a>
            ))}
          </nav>
        </div>
      </section>

      {/* Getting started */}
      <Section id="getting-started" title="Getting started" intro="Three stages take you from a new account to everyday use.">
        <ol style={{ maxWidth: '56rem', listStyle: 'none', padding: 0, margin: 0 }}>
          {GETTING_STARTED.map((s, i) => (
            <li key={s.title} style={{ display: 'flex', gap: '1.5rem', paddingBottom: i < GETTING_STARTED.length - 1 ? '2.5rem' : 0, position: 'relative' }}>
              {i < GETTING_STARTED.length - 1 && (
                <span aria-hidden="true" style={{ position: 'absolute', left: '1.25rem', top: '2.75rem', bottom: '0.25rem', width: 2, background: '#d0e2ff' }} />
              )}
              <NumberBadge n={i + 1} />
              <div style={{ minWidth: 0 }}>
                <h3 style={{ fontSize: '1.375rem', fontWeight: 600, color: INK, marginTop: '0.25rem' }}>{s.title}</h3>
                <p style={{ fontSize: '1.0625rem', color: MUTED, lineHeight: 1.6, marginTop: '0.5rem' }}>{s.text}</p>
                {s.steps && (
                  <ol style={{ margin: '0.75rem 0 0', padding: 0, listStyle: 'none', borderLeft: `3px solid ${BLUE}`, background: '#f4f4f4' }}>
                    {s.steps.map((step, j, all) => (
                      <li key={step} style={{
                        display: 'flex', gap: '0.75rem', padding: '0.625rem 1rem', fontSize: '1rem', color: INK, lineHeight: 1.5,
                        borderBottom: j < all.length - 1 ? '1px solid #e0e0e0' : 'none',
                      }}>
                        <span style={{ fontWeight: 600, color: BLUE, flexShrink: 0, minWidth: '1rem' }}>{j + 1}</span>{step}
                      </li>
                    ))}
                  </ol>
                )}
                <p style={{ fontSize: '0.9375rem', color: INK, marginTop: '0.75rem', display: 'flex', gap: '0.5rem' }}>
                  <CheckmarkFilled size={18} style={{ color: '#24a148', flexShrink: 0, marginTop: 2 }} />{s.detail}
                </p>
              </div>
            </li>
          ))}
        </ol>
      </Section>

      {/* Areas */}
      <Section
        id="areas" tone="grey" title="What your team sees"
        intro="Everyone uses the same menu, but each person sees only what their role allows: worker, supervisor, manager or administrator."
      >
        <div style={{ display: 'grid', gridTemplateColumns: cols('16rem'), gap: '1rem' }}>
          {AREAS.map((a) => (
            <div key={a.name} style={{ background: '#fff', padding: '1.25rem 1.5rem', borderTop: `3px solid ${BLUE}` }}>
              <div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'baseline', justifyContent: 'space-between', gap: '0.5rem' }}>
                <h3 style={{ fontSize: '1.125rem', fontWeight: 600, color: INK }}>{a.name}</h3>
                {a.who && (
                  <span style={{ fontSize: '0.75rem', fontWeight: 600, color: MUTED, background: '#e0e0e0', padding: '0.125rem 0.5rem' }}>
                    {a.who}
                  </span>
                )}
              </div>
              <p style={{ fontSize: '0.9375rem', color: MUTED, lineHeight: 1.5, marginTop: '0.5rem' }}>{a.text}</p>
            </div>
          ))}
        </div>
      </Section>

      {/* Safety loop */}
      <Section
        id="safety-loop" title="The everyday safety loop"
        intro="Anyone can report. EXXIO makes sure someone follows up and that the fix gets done."
      >
        <ol style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'stretch', gap: '0.5rem', listStyle: 'none', padding: 0, margin: 0 }}>
          {SAFETY_LOOP.map((stage, i) => (
            <li key={stage.label} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', flex: '1 1 11rem' }}>
              <div style={{
                flex: 1, alignSelf: 'stretch', background: '#f4f4f4', padding: '1rem',
                borderTop: `3px solid ${i === 0 ? RED : i === SAFETY_LOOP.length - 1 ? '#24a148' : BLUE}`,
              }}>
                <p style={{ fontSize: '0.75rem', fontWeight: 600, color: MUTED }}>Step {i + 1}</p>
                <p style={{ fontSize: '1rem', fontWeight: 600, color: INK, marginTop: '0.125rem' }}>{stage.label}</p>
                <p style={{ fontSize: '0.875rem', color: MUTED, marginTop: '0.25rem', lineHeight: 1.45 }}>{stage.note}</p>
              </div>
              {i < SAFETY_LOOP.length - 1 && <ArrowRight size={20} style={{ color: '#8d8d8d', flexShrink: 0 }} aria-hidden="true" />}
            </li>
          ))}
        </ol>
        <div style={{ display: 'grid', gridTemplateColumns: cols('20rem'), gap: '1rem 2rem', marginTop: '2rem' }}>
          <p style={{ fontSize: '1rem', color: INK, lineHeight: 1.6 }}>
            <strong style={{ fontWeight: 600 }}>Planned work runs alongside.</strong>{' '}
            <span style={{ color: MUTED }}>Inspections from templates, audits, job safety analyses, permits to work and toolbox talks.</span>
          </p>
          <p style={{ fontSize: '1rem', color: INK, lineHeight: 1.6 }}>
            <strong style={{ fontWeight: 600 }}>Managers see the whole picture.</strong>{' '}
            <span style={{ color: MUTED }}>Reports and KPIs show injury rates and trends, and the compliance calendar shows what is due.</span>
          </p>
          <p style={{ fontSize: '1rem', color: INK, lineHeight: 1.6 }}>
            <strong style={{ fontWeight: 600 }}>Concerns stay confidential.</strong>{' '}
            <span style={{ color: MUTED }}>Speak-up reports go only to the people who must handle them.</span>
          </p>
        </div>
      </Section>

      {/* Training and hiring */}
      <Section id="training-hiring" tone="grey" title="Training and hiring, step by step">
        <div style={{ display: 'grid', gridTemplateColumns: cols('22rem'), gap: '1.5rem' }}>
          {FLOWS.map((f) => (
            <div key={f.title} style={{ background: '#fff', padding: '1.5rem', borderLeft: `3px solid ${BLUE}` }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 600, color: INK }}>{f.title}</h3>
              <p style={{ fontSize: '1rem', color: MUTED, lineHeight: 1.5, marginTop: '0.375rem' }}>{f.intro}</p>
              <ol style={{ listStyle: 'none', padding: 0, margin: '1rem 0 0' }}>
                {f.steps.map((step, i) => (
                  <li key={step} style={{ display: 'flex', gap: '0.75rem', padding: '0.625rem 0', borderTop: '1px solid #e0e0e0', fontSize: '0.9375rem', color: INK, lineHeight: 1.5 }}>
                    <span style={{
                      width: '1.5rem', height: '1.5rem', background: '#d0e2ff', color: BLUE, fontWeight: 600, fontSize: '0.8125rem',
                      display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                    }}>
                      {i + 1}
                    </span>
                    {step}
                  </li>
                ))}
              </ol>
              {f.note && <p style={{ fontSize: '0.875rem', color: MUTED, lineHeight: 1.5, marginTop: '0.75rem' }}>{f.note}</p>}
            </div>
          ))}
        </div>
      </Section>

      {/* Automatic */}
      <Section title="What EXXIO does for you automatically" intro="The routine work that usually lives in spreadsheets and calendar reminders.">
        <div style={{ display: 'grid', gridTemplateColumns: cols('20rem'), gap: '1rem 2rem' }}>
          {AUTOMATIC.map((item) => (
            <p key={item} style={{ display: 'flex', gap: '0.75rem', fontSize: '1rem', color: INK, lineHeight: 1.5 }}>
              <CheckmarkFilled size={20} style={{ color: '#24a148', flexShrink: 0, marginTop: 2 }} />{item}
            </p>
          ))}
        </div>
      </Section>

      {/* A day in EXXIO */}
      <Section tone="grey" title="A day in EXXIO" intro="Everyone has a short, clear list. Nobody has to learn the whole system.">
        <div style={{ display: 'grid', gridTemplateColumns: cols('15rem'), gap: '1.5rem' }}>
          {DAY.map((d) => (
            <div key={d.role} style={{ background: '#fff', padding: '1.5rem', borderLeft: `3px solid ${BLUE}` }}>
              <h3 style={{ fontSize: '1.125rem', fontWeight: 600, color: INK }}>{d.role}</h3>
              <ul style={{ marginTop: '0.75rem', paddingLeft: '1.125rem', listStyle: 'square' }}>
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
