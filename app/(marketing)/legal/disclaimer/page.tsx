import type { Metadata } from 'next'
import Link from 'next/link'
import { LegalPage, List, P, type LegalSection } from '@/components/marketing/legal'

export const metadata: Metadata = {
  title: 'Compliance Content Disclaimer — EXXIO',
  description: 'EXXIO’s sample content, rules and AI answers are not legal advice.',
}

const sections: LegalSection[] = [
  {
    id: 'not-advice',
    title: 'EXXIO is not legal advice',
    body: <P>
      EXXIO provides tools and sample content to help employers manage health, safety and HR obligations. Sample content is
      provided for convenience, may not reflect the law in every province or territory or the latest changes, and is not
      legal, medical or professional advice. Using EXXIO does not create a lawyer–client or adviser relationship.
    </P>,
  },
  {
    id: 'what',
    title: 'What this covers',
    body: <List items={[
      'sample training courses, quizzes and certificates;',
      'hiring and employment rules, such as minimum wages, notice periods and probation guidance, and the compliance checks that use them;',
      'templates, including offer letters, contracts, policies, consent forms and notices;',
      'risk assessment, inspection and job safety templates;',
      'reporting deadlines, statutory holiday calendars and business-day calculations;',
      'answers and drafts produced by the AI assistant.',
    ]} />,
  },
  {
    id: 'your-role',
    title: 'You remain responsible',
    body: <>
      <P>
        The customer remains responsible for its legal obligations, including reviewing content before relying on it,
        meeting reporting deadlines, and making employment decisions. In particular:
      </P>
      <List items={[
        'check sample content against the law and regulator guidance for your province or territory and your industry;',
        'training that a law requires to be delivered by an approved provider, such as Ontario’s Working at Heights training, must be taken from an approved provider; a course in EXXIO does not replace it unless it says it is approved;',
        'report incidents to your regulator and workers’ compensation board in the time and form they require, even if a deadline in EXXIO differs;',
        'get advice from a lawyer or qualified health and safety professional when you are unsure.',
      ]} />
    </>,
  },
  {
    id: 'currency',
    title: 'Keeping content current',
    body: <P>
      Laws and rates change. We review system content periodically and record when each item was last reviewed, but we
      cannot guarantee that every item is current on the day you use it. If you notice something out of date, please tell
      us through the <Link href="/contact">contact page</Link>.
    </P>,
  },
]

export default function DisclaimerPage() {
  return (
    <LegalPage
      title="Compliance Content Disclaimer"
      current="/legal/disclaimer"
      intro={<p>Our sample content, rules and AI answers help you do the work. They do not replace legal advice.</p>}
      sections={sections}
    />
  )
}
