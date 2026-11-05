import type { Metadata } from 'next'
import { LEGAL, LegalPage, List, Mail, P, type LegalSection } from '@/components/marketing/legal'

export const metadata: Metadata = {
  title: 'Accessibility Statement — EXXIO',
  description: 'EXXIO’s commitment to accessibility and how to get help.',
}

const sections: LegalSection[] = [
  {
    id: 'commitment',
    title: 'Our commitment',
    body: <P>
      We want everyone in a workplace, including people with disabilities, to be able to report a hazard, complete
      training and find what they need in EXXIO. We aim to meet the Web Content Accessibility Guidelines (WCAG) 2.1 at
      level AA, the standard referenced by Ontario’s Accessibility for Ontarians with Disabilities Act (AODA).
    </P>,
  },
  {
    id: 'how',
    title: 'How we build for accessibility',
    body: <List items={[
      'EXXIO is built on the IBM Carbon design system, whose components are designed to meet WCAG 2.1 AA.',
      'We design pages to work with a keyboard and screen readers, with clear headings, labels and plain language.',
      'We design text and controls for sufficient colour contrast, and avoid showing status by colour alone.',
      'We design pages to adapt to small screens and to zoom up to 200%.',
    ]} />,
  },
  {
    id: 'status',
    title: 'Current status',
    body: <P>
      We have not yet completed an independent accessibility audit. Some parts of EXXIO, such as embedded training videos
      supplied by customers or third parties, and generated PDF documents, may not fully meet the standard. We are working
      to identify and fix gaps.
    </P>,
  },
  {
    id: 'help',
    title: 'Feedback and alternative formats',
    body: <P>
      If you have difficulty using any part of EXXIO, or need a document in another format, email <Mail to={LEGAL.supportEmail} />.
      Tell us the page and what you were trying to do. We will reply within 5 business days and work with you to provide
      the information in a way that works for you.
    </P>,
  },
]

export default function AccessibilityPage() {
  return (
    <LegalPage
      title="Accessibility Statement"
      current="/legal/accessibility"
      intro={<p>Our accessibility commitment, where we stand today, and how to get help.</p>}
      sections={sections}
    />
  )
}
