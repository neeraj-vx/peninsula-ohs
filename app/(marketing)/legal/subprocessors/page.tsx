import type { Metadata } from 'next'
import Link from 'next/link'
import { LEGAL, LegalPage, P, Table, type LegalSection } from '@/components/marketing/legal'

export const metadata: Metadata = {
  title: 'Subprocessors — EXXIO',
  description: 'The service providers EXXIO uses to run the platform, what they do and where they process data.',
}

// Keep in step with docs/compliance-guide.md §4.3. Give customers 30 days'
// notice before adding or replacing an entry (Data Processing Addendum §6).
const SUBPROCESSORS = [
  {
    name: 'Supabase',
    purpose: 'Database, authentication, file storage and scheduled jobs',
    data: 'All Customer Data',
    location: LEGAL.dataRegion,
  },
  {
    name: 'Vercel',
    purpose: 'Web application hosting and server functions; AI Gateway, which routes AI assistant requests to the model provider',
    data: 'All Customer Data in transit; AI assistant prompts and the records needed to answer them',
    location: 'United States',
  },
  {
    name: 'Anthropic',
    purpose: 'AI model that powers the AI assistant, reached through Vercel AI Gateway',
    data: 'AI assistant prompts and the records needed to answer them',
    location: 'United States',
  },
  {
    name: 'Resend',
    purpose: 'Sending email, such as background-check consent requests, reference requests and enquiry notifications',
    data: 'Recipient names and email addresses, and the content of the email',
    location: 'United States',
  },
]

// Used only when a customer turns the feature on
const OPTIONAL = [
  {
    name: 'Certn',
    purpose: 'Background checks, when the customer orders them',
    data: 'Candidate identity details, consent records and check results',
    location: 'Canada (to be confirmed in the provider contract)',
  },
  {
    name: 'YouTube (Google) or Vimeo',
    purpose: 'Training videos that a customer chooses to embed in a course',
    data: 'Viewer’s IP address and browser details, collected by the video provider when the video plays',
    location: 'United States',
  },
]

const sections: LegalSection[] = [
  {
    id: 'core',
    title: 'Subprocessors for every customer',
    body: <Table
      head={['Provider', 'What it does', 'Data involved', 'Location']}
      rows={SUBPROCESSORS.map((s) => [<strong key={s.name}>{s.name}</strong>, s.purpose, s.data, s.location])}
    />,
  },
  {
    id: 'optional',
    title: 'Used only if you turn the feature on',
    body: <Table
      head={['Provider', 'What it does', 'Data involved', 'Location']}
      rows={OPTIONAL.map((s) => [<strong key={s.name}>{s.name}</strong>, s.purpose, s.data, s.location])}
    />,
  },
  {
    id: 'changes',
    title: 'Changes to this list',
    body: <P>
      We give account administrators at least 30 days’ notice before adding or replacing a subprocessor, as set out in
      our <Link href="/legal/data-processing">Data Processing Addendum</Link>. To be told about changes, email{' '}
      <a href={`mailto:${LEGAL.privacyEmail}`}>{LEGAL.privacyEmail}</a>.
    </P>,
  },
]

export default function SubprocessorsPage() {
  return (
    <LegalPage
      title="Subprocessors"
      current="/legal/subprocessors"
      intro={<p>The service providers that help us run EXXIO, what they do, and where they process your data.</p>}
      sections={sections}
    />
  )
}
