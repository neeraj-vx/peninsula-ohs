import type { Metadata } from 'next'
import Link from 'next/link'
import { DataLocationSentence, LEGAL, LegalPage, List, Mail, P, Table, type LegalSection } from '@/components/marketing/legal'

export const metadata: Metadata = {
  title: 'Data Processing Addendum — EXXIO',
  description: 'How EXXIO processes personal information on behalf of its customers.',
}

const sections: LegalSection[] = [
  {
    id: 'scope',
    title: 'Scope and roles',
    body: <>
      <P>
        This Data Processing Addendum (“DPA”) forms part of the <Link href="/legal/terms">Terms of Service</Link> between
        {' '}{LEGAL.legalName} (“EXXIO”) and the Customer. It applies to personal information in Customer Data that EXXIO
        processes for the Customer (“Customer Personal Information”).
      </P>
      <P>
        The Customer is the organization responsible for Customer Personal Information (the controller). EXXIO is its
        service provider (the processor) and processes Customer Personal Information only on the Customer’s behalf.
        If the Terms and this DPA conflict on the protection of personal information, this DPA prevails.
      </P>
    </>,
  },
  {
    id: 'details',
    title: 'What we process',
    body: <Table
      head={['Item', 'Details']}
      rows={[
        ['Individuals', 'The Customer’s employees, supervisors, contractors and their workers, visitors, job candidates, referees, and Users.'],
        ['Types of information', 'Identity and contact details; job, role, site and employment details; training, certificates and competencies; incident, injury and investigation records; hazard, inspection and permit records; signatures; documents the Customer uploads; and anything else the Customer chooses to enter.'],
        ['Sensitive information', 'Depending on the features the Customer uses: health, medical and return-to-work information; injury details; background-check results, including criminal record information; and confidential speak-up reports.'],
        ['Purpose', 'Providing, securing and supporting the Service as described in the Terms, and following the Customer’s documented instructions.'],
        ['Duration', 'The subscription term, plus the export and deletion periods in section 10.'],
      ]}
    />,
  },
  {
    id: 'instructions',
    title: 'Customer instructions',
    body: <>
      <P>
        EXXIO will process Customer Personal Information only on the Customer’s documented instructions. The Terms, this
        DPA, and the Customer’s configuration and use of the Service are those instructions. EXXIO will tell the Customer
        if it believes an instruction breaks the law.
      </P>
      <P>
        EXXIO will not sell Customer Personal Information, use it for its own purposes, or use it to train artificial
        intelligence models. EXXIO may create de-identified, aggregated statistics that cannot identify any individual or
        the Customer.
      </P>
      <P>
        The Customer is responsible for having a lawful basis and any consent or notice required for the Customer Personal
        Information it puts into the Service, and for the accuracy of that information.
      </P>
    </>,
  },
  {
    id: 'confidentiality',
    title: 'Our personnel',
    body: <P>
      EXXIO personnel who can access Customer Personal Information are bound by confidentiality obligations and access
      it only as needed to provide support the Customer asks for, keep the Service secure, or
      comply with law. Access by EXXIO staff through our administration tools is logged.
    </P>,
  },
  {
    id: 'security',
    title: 'Security measures',
    body: <>
      <P>EXXIO maintains administrative, technical and physical safeguards appropriate to the sensitivity of the information, including:</P>
      <List items={[
        'separation of each customer’s records by access rules enforced in the database, with automated tests that check every role against every table;',
        'role-based access within each customer, with sensitive records, such as confidential speak-up reports, background-check results and health records, restricted to the roles that handle them;',
        'encryption in transit, and encryption at rest provided by our hosting provider;',
        'two-step sign-in, required for administrators;',
        'audit trails of changes to records.',
      ]} />
      <P>EXXIO may update these measures as long as the overall level of protection is not reduced.</P>
    </>,
  },
  {
    id: 'subprocessors',
    title: 'Subprocessors',
    body: <>
      <P>
        The Customer authorizes EXXIO to use the subprocessors listed on our <Link href="/legal/subprocessors">Subprocessors</Link> page.
        EXXIO will:
      </P>
      <List items={[
        'have a written contract with each subprocessor that protects Customer Personal Information at least as well as this DPA;',
        'give account administrators at least 30 days’ notice before adding or replacing a subprocessor;',
        'remain responsible for its subprocessors’ performance.',
      ]} />
      <P>
        If the Customer objects to a new subprocessor on reasonable data-protection grounds, the parties will discuss it in
        good faith. If they cannot resolve it, the Customer may end the affected subscription and receive a refund of
        prepaid fees for the remaining term.
      </P>
    </>,
  },
  {
    id: 'location',
    title: 'Where information is processed',
    body: <P>
      <DataLocationSentence /> Subprocessors process information in the locations shown on the Subprocessors page. EXXIO
      will give the Customer the information it reasonably needs to assess transfers outside its province or outside
      Canada, including for a privacy impact assessment under Quebec law.
    </P>,
  },
  {
    id: 'breach',
    title: 'Security incidents',
    body: <>
      <P>
        If EXXIO becomes aware of unauthorized access to, or loss, use or disclosure of, Customer Personal Information
        (a “Security Incident”), it will notify the Customer without undue delay, and in any event within 72 hours of
        confirming it. The notice will describe, as far as known, what happened, the information and individuals affected,
        the steps taken, and a contact person.
      </P>
      <P>
        EXXIO will take reasonable steps to contain the incident and reduce harm, keep the Customer updated, keep a record
        of the incident, and help the Customer meet its own obligations to notify regulators and individuals. Unless the
        law requires otherwise, the Customer decides whether to notify its own employees and regulators.
      </P>
    </>,
  },
  {
    id: 'assistance',
    title: 'Helping the Customer',
    body: <List items={[
      'Requests from individuals: if EXXIO receives a request about Customer Personal Information, it will pass it to the Customer and will not respond itself except to say so. EXXIO will help the Customer respond, including by locating, exporting or correcting the information.',
      'Privacy impact assessments: EXXIO will provide reasonable information about the Service to help the Customer carry them out.',
      'Regulators: EXXIO will co-operate reasonably with inquiries from a privacy regulator about Customer Personal Information.',
      'Legal demands: if a public authority demands Customer Personal Information, EXXIO will notify the Customer, unless the law forbids it, and will disclose only what it is legally required to.',
    ]} />,
  },
  {
    id: 'deletion',
    title: 'Return and deletion',
    body: <P>
      When the subscription ends, the Customer may export Customer Personal Information for 30 days. EXXIO will then delete
      it from the live Service within a further 30 days, and from backups as they expire in the normal course, unless the
      law requires EXXIO to keep it. On request, EXXIO will confirm deletion in writing.
    </P>,
  },
  {
    id: 'audits',
    title: 'Information and audits',
    body: <P>
      On request, EXXIO will provide information reasonably needed to show compliance with this DPA, such as a description
      of its security measures, its subprocessor list and any independent audit or penetration-test summaries it has.
      If that is not enough, the Customer may, no more than once a year and with at least 30 days’ notice, audit EXXIO’s
      compliance at its own cost, in a way that does not disrupt the Service or compromise other customers’ information.
    </P>,
  },
  {
    id: 'contact',
    title: 'Contact',
    body: <P>
      Questions about this DPA, or about a Security Incident, go to <Mail to={LEGAL.privacyEmail} />. Report a suspected
      vulnerability to <Mail to={LEGAL.securityEmail} />.
    </P>,
  },
]

export default function DataProcessingPage() {
  return (
    <LegalPage
      title="Data Processing Addendum"
      current="/legal/data-processing"
      intro={<p>How we process your employees’, contractors’ and candidates’ personal information on your behalf. It forms part of our Terms of Service.</p>}
      sections={sections}
    />
  )
}
