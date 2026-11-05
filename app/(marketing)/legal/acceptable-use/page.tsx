import type { Metadata } from 'next'
import { LEGAL, LegalPage, List, Mail, P, type LegalSection } from '@/components/marketing/legal'

export const metadata: Metadata = {
  title: 'Acceptable Use Policy — EXXIO',
  description: 'What you may and may not do when using EXXIO.',
}

const sections: LegalSection[] = [
  {
    id: 'purpose',
    title: 'Purpose',
    body: <P>
      This policy forms part of our Terms of Service. It applies to every organization and User of EXXIO, and is there to
      keep the service safe and reliable for everyone, and to protect the people whose information is in it.
    </P>,
  },
  {
    id: 'not-allowed',
    title: 'You must not',
    body: <List items={[
      'use EXXIO to break the law, including employment standards, human rights, privacy and anti-spam laws;',
      'put personal information into EXXIO without the right, consent or notice the law requires;',
      'use background checks or health information for any purpose that is not lawful and related to the job;',
      'retaliate against, or try to identify, a person who made a confidential or anonymous speak-up report;',
      'upload malicious code, or content that is unlawful, defamatory, harassing or infringes someone else’s rights;',
      'try to access another organization’s data, or any part of EXXIO you are not authorized to use;',
      'probe, scan or test the security of EXXIO without our written permission (see below);',
      'interfere with or overload EXXIO, or get around usage limits or access controls;',
      'share logins, or let anyone use EXXIO under another person’s identity;',
      'copy, resell, or build a competing product from EXXIO, its content or its design;',
      'use automated tools to extract data from EXXIO, except through features or interfaces we provide for that purpose;',
      'use the AI assistant to produce content that is unlawful or deceptive, or to make decisions about people without human review.',
    ]} />,
  },
  {
    id: 'security-research',
    title: 'Reporting security issues',
    body: <P>
      If you think you have found a security vulnerability, please email <Mail to={LEGAL.securityEmail} /> with details
      and do not access, change or delete other people’s data. We will acknowledge your report and keep you updated.
    </P>,
  },
  {
    id: 'enforcement',
    title: 'What happens if this policy is broken',
    body: <P>
      We may remove content, suspend Users, or suspend or end an account that breaks this policy, as set out in the Terms
      of Service. Where we can, we will tell you first and give you a chance to fix the problem. To report misuse, email{' '}
      <Mail to={LEGAL.contactEmail} />.
    </P>,
  },
]

export default function AcceptableUsePage() {
  return (
    <LegalPage
      title="Acceptable Use Policy"
      current="/legal/acceptable-use"
      intro={<p>What you may and may not do with EXXIO.</p>}
      sections={sections}
    />
  )
}
