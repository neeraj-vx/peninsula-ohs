import type { Metadata } from 'next'
import Link from 'next/link'
import { DataLocationSentence, LEGAL, LegalPage, List, Mail, P, Table, type LegalSection } from '@/components/marketing/legal'

export const metadata: Metadata = {
  title: 'Privacy Policy — EXXIO',
  description: 'How EXXIO collects, uses, shares and protects personal information.',
}

const sections: LegalSection[] = [
  {
    id: 'who',
    title: 'Who this policy covers',
    body: <>
      <P>
        This policy explains how {LEGAL.legalName} (“EXXIO”, “we”) handles personal information when you visit our
        website, contact us, or use the EXXIO platform as an account holder or User.
      </P>
      <P>
        <strong>If you are an employee, contractor, job candidate or referee of one of our customers</strong>, your
        employer or the hiring organization decides what information about you goes into EXXIO and why. They are
        responsible for it, and we process it on their behalf under our <Link href="/legal/data-processing">Data
        Processing Addendum</Link>. Please contact that organization first with questions or requests; we will help
        them respond. If you contact us, we will pass your request to them.
      </P>
    </>,
  },
  {
    id: 'collect',
    title: 'Information we collect',
    body: <Table
      head={['When', 'What we collect']}
      rows={[
        ['You contact us or request a demo', 'Name, work email, company, province or territory, number of employees, what you are interested in, your message, and which page you sent it from.'],
        ['You create an account or are invited', 'Name, work email, password (stored only as a secure hash by our authentication provider), organization, role, and two-step sign-in settings if you set them up.'],
        ['You use the platform', 'The records you create, sign-in events, session details such as IP address, browser and device type, and an audit trail of changes you make.'],
        ['You use the AI assistant', 'Your questions, the assistant’s answers and the records it looked at to answer them. Conversations are saved so you can return to them.'],
        ['You email or call us', 'Your contact details and what you tell us.'],
      ]}
    />,
  },
  {
    id: 'use',
    title: 'How we use it',
    body: <List items={[
      'To provide, secure and support the platform, including signing you in, sending notifications you or your organization have set up, and keeping audit trails.',
      'To reply to enquiries, arrange demos and send quotes.',
      'To manage customer accounts, billing and our contracts.',
      'To detect, investigate and prevent fraud, abuse and security incidents.',
      'To understand how the platform is used, using de-identified, aggregated statistics, so we can improve it.',
      'To meet legal obligations and enforce our agreements.',
    ]} />,
  },
  {
    id: 'consent',
    title: 'Consent and choices',
    body: <>
      <P>
        We collect, use and share personal information with your knowledge and consent, except where the law allows
        otherwise. When you send us an enquiry or create an account, you consent to the uses described here for that
        purpose. You may withdraw consent at any time, subject to legal or contractual limits; if you do, we may not be
        able to provide some or all of the service.
      </P>
      <P>
        We only send marketing email where the law allows it, and every marketing email includes a way to unsubscribe.
        Service messages, such as security notices and notifications your organization has set up, are not marketing.
      </P>
    </>,
  },
  {
    id: 'share',
    title: 'Who we share it with',
    body: <>
      <P><strong>We do not sell personal information</strong>, and we do not share it for advertising. We share it only:</P>
      <List items={[
        <>with service providers that help us run EXXIO, such as hosting, email and AI providers, under contracts that limit their use of it. They are listed on our <Link href="/legal/subprocessors">Subprocessors</Link> page;</>,
        'with third-party services your organization chooses to connect, such as a background-check provider;',
        'within your organization, according to the roles your administrator sets;',
        'with professional advisers, such as lawyers and auditors, under a duty of confidentiality;',
        'if required by law, a court order or a lawful request from a public authority;',
        'with a buyer or successor if our business is sold or reorganized, under equivalent protections.',
      ]} />
    </>,
  },
  {
    id: 'location',
    title: 'Where your information is stored',
    body: <>
      <P>
        <DataLocationSentence /> Some of our service providers process information in the United States and other
        countries, as listed on our <Link href="/legal/subprocessors">Subprocessors</Link> page. While it is outside
        Canada, information is subject to the laws of those countries and may be accessible to their courts, law
        enforcement and national security authorities.
      </P>
      <P>
        We require providers to protect it to a standard comparable to Canadian law. If your organization is in Quebec, we
        will provide the information you need for your own privacy impact assessment before information is transferred
        outside Quebec.
      </P>
    </>,
  },
  {
    id: 'protect',
    title: 'How we protect it',
    body: <List items={[
      'Each customer’s records are kept separate by access rules enforced in the database, and these rules are tested for every role.',
      'Role-based access, so people see only what their role needs.',
      'Encryption in transit, and encryption at rest provided by our hosting provider.',
      'Two-step sign-in, which is required for administrators.',
      'Audit trails of changes, and logging of any access by our staff.',
      'Staff access to customer information only to provide support you ask for, keep the service secure, or comply with the law.',
    ]} />,
  },
  {
    id: 'retention',
    title: 'How long we keep it',
    body: <>
      <P>We keep personal information only as long as we need it for the purposes above, or as the law requires. In general:</P>
      <List items={[
        'enquiries and demo requests: for up to 2 years after our last contact, unless you become a customer;',
        'account and platform information: for the life of the subscription, then deleted as described in our Terms of Service;',
        'records we must keep for legal, tax or accounting reasons: for the period the law requires.',
      ]} />
      <P>When we no longer need information, we delete it or anonymize it.</P>
    </>,
  },
  {
    id: 'rights',
    title: 'Your rights',
    body: <>
      <P>Depending on where you live, you may have the right to:</P>
      <List items={[
        'ask whether we hold personal information about you, and get access to it;',
        'ask us to correct information that is inaccurate or incomplete;',
        'withdraw consent;',
        'in Quebec, ask for computerized information you provided to be given to you or someone you choose in a commonly used format, and ask us to stop disseminating it or de-index it where the law allows;',
        'make a complaint about how we handled your information.',
      ]} />
      <P>
        Email <Mail to={LEGAL.privacyEmail} />. We will respond within 30 days, and may need to confirm your identity
        first. Requests about information an employer or hiring organization put into EXXIO are passed to that organization.
      </P>
      <P>
        We do not make decisions about you based solely on automated processing. The AI assistant and the platform’s
        compliance checks assist people; a person at your organization makes the decision.
      </P>
    </>,
  },
  {
    id: 'cookies',
    title: 'Cookies',
    body: <P>
      We use only the cookies and similar storage needed to sign you in and run the platform, and to remember small
      preferences. We do not use advertising or cross-site tracking cookies. See our <Link href="/legal/cookies">Cookie Notice</Link>.
    </P>,
  },
  {
    id: 'breach',
    title: 'If something goes wrong',
    body: <P>
      If a breach of security safeguards involving personal information creates a real risk of significant harm, we will
      notify affected individuals and the relevant privacy regulator as the law requires, keep a record of the incident,
      and, where we hold the information for a customer, notify that customer without undue delay.
    </P>,
  },
  {
    id: 'children',
    title: 'Children',
    body: <P>
      EXXIO is a service for businesses and is not directed to children. We do not knowingly collect information directly
      from children. Employers may record information about young workers where the law permits; the employer is
      responsible for that information.
    </P>,
  },
  {
    id: 'officer',
    title: 'Privacy officer and complaints',
    body: <>
      <P>
        Our privacy officer{LEGAL.privacyOfficerName ? <>, {LEGAL.privacyOfficerName},</> : null} is responsible for our
        compliance with this policy. Contact them at <Mail to={LEGAL.privacyEmail} />
        {LEGAL.address ? <> or by mail at {LEGAL.legalName}, {LEGAL.address}</> : null}.
      </P>
      <P>If you are not satisfied with our response, you may complain to:</P>
      <List items={[
        <>the <a href="https://www.priv.gc.ca/" target="_blank" rel="noreferrer">Office of the Privacy Commissioner of Canada</a>;</>,
        <>in Quebec, the <a href="https://www.cai.gouv.qc.ca/" target="_blank" rel="noreferrer">Commission d’accès à l’information</a>;</>,
        <>in Alberta, the <a href="https://oipc.ab.ca/" target="_blank" rel="noreferrer">Office of the Information and Privacy Commissioner of Alberta</a>;</>,
        <>in British Columbia, the <a href="https://www.oipc.bc.ca/" target="_blank" rel="noreferrer">Office of the Information and Privacy Commissioner for BC</a>.</>,
      ]} />
    </>,
  },
  {
    id: 'changes',
    title: 'Changes to this policy',
    body: <P>
      We will post any changes here and update the date at the top. If a change materially affects how we use information
      we already hold, we will tell account administrators before it takes effect and ask for consent where the law requires it.
    </P>,
  },
]

export default function PrivacyPage() {
  return (
    <LegalPage
      title="Privacy Policy"
      current="/legal/privacy"
      intro={<p>How we collect, use, share and protect personal information, and how to reach our privacy officer.</p>}
      sections={sections}
    />
  )
}
