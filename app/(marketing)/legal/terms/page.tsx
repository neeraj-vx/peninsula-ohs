import type { Metadata } from 'next'
import Link from 'next/link'
import { LEGAL, LegalPage, List, Mail, P, type LegalSection } from '@/components/marketing/legal'

export const metadata: Metadata = {
  title: 'Terms of Service — EXXIO',
  description: 'The terms that govern your organization’s use of EXXIO.',
}

const sections: LegalSection[] = [
  {
    id: 'agreement',
    title: 'About these Terms',
    body: <>
      <P>
        These Terms of Service (the “Terms”) are an agreement between {LEGAL.legalName} (“EXXIO”, “we”, “us”) and the
        organization that creates an account or signs an order form (the “Customer”, “you”). They govern your use of the
        EXXIO platform, including the web and mobile applications, the AI assistant and any related support (the “Service”).
      </P>
      <P>
        By creating an account, clicking to accept, or using the Service, you agree to these Terms on behalf of your
        organization and confirm you have authority to do so. If you sign an order form with us, the order form forms
        part of these Terms and prevails if the two conflict.
      </P>
      <P>
        These Terms include the <Link href="/legal/data-processing">Data Processing Addendum</Link>,
        the <Link href="/legal/acceptable-use">Acceptable Use Policy</Link> and
        the <Link href="/legal/disclaimer">Compliance Content Disclaimer</Link>.
      </P>
    </>,
  },
  {
    id: 'service',
    title: 'The Service',
    body: <>
      <P>
        EXXIO helps employers organize and evidence their health and safety and HR programs: incident and hazard
        reporting, risk assessments, inspections, training, hiring and onboarding workflows, background checks through
        third-party providers, and related reports.
      </P>
      <P>
        We may improve, change or remove features over time. If we remove a feature that is material to your use of the
        Service during a paid term, we will tell you in advance and, if you choose to end your subscription because of it,
        refund any prepaid fees for the remaining term.
      </P>
    </>,
  },
  {
    id: 'accounts',
    title: 'Accounts and users',
    body: <List items={[
      'You are responsible for the people you invite (“Users”), the roles you give them, and everything done under your account.',
      'Each User must have their own login. Keep passwords and authenticator codes confidential, and tell us promptly at ' + LEGAL.securityEmail + ' if you suspect unauthorized access.',
      'System administrators must use two-step sign-in where the Service requires it.',
      'You must give us accurate account and billing information and keep it up to date.',
    ]} />,
  },
  {
    id: 'your-responsibilities',
    title: 'Your responsibilities as the employer',
    body: <>
      <P>
        EXXIO is a tool. <strong>You remain the employer and remain responsible for your legal obligations</strong>, including
        under occupational health and safety, workers’ compensation, employment standards, human rights and privacy laws.
        In particular, you are responsible for:
      </P>
      <List items={[
        'reviewing any sample content, rules, templates and courses before relying on them, and adapting them to your workplace;',
        'filing reports with regulators, insurers and workers’ compensation boards on time, and in the required form;',
        'making employment decisions, including hiring, discipline and decisions based on background checks;',
        'having a lawful basis, and any consent or notice required, for the personal information you put into the Service, including your employees’, candidates’, contractors’ and referees’ information;',
        'the accuracy of the information you and your Users enter.',
      ]} />
      <P>See the <Link href="/legal/disclaimer">Compliance Content Disclaimer</Link> for more detail.</P>
    </>,
  },
  {
    id: 'customer-data',
    title: 'Your data',
    body: <>
      <P>
        “Customer Data” means the information you and your Users put into the Service, including your employees’ personal
        information. <strong>You own your Customer Data.</strong> You give us a limited permission to host, process and
        display it only to provide, secure and support the Service, and as described in
        the <Link href="/legal/data-processing">Data Processing Addendum</Link>.
      </P>
      <P>
        We may create de-identified, aggregated statistics about how the Service is used (for example, how many inspections
        are completed each month across all customers) to improve the Service. These statistics never identify you, your
        Users or any individual.
      </P>
      <P>We do not sell Customer Data, and we do not use it to train artificial intelligence models.</P>
    </>,
  },
  {
    id: 'ai',
    title: 'AI features',
    body: <>
      <P>
        The Service includes an AI assistant that can answer questions and, with a User’s approval, prepare or change
        records. It works only with the data the User is allowed to see.
      </P>
      <List items={[
        'AI output can be incomplete or wrong. Review it before acting on it. It is not legal, medical or professional advice.',
        'Actions that change records require a User to approve them, and are recorded in the audit trail as that User’s action.',
        'Prompts and the data needed to answer them are sent to our AI providers, listed on our Subprocessors page, only to generate the response.',
      ]} />
    </>,
  },
  {
    id: 'third-party',
    title: 'Background checks and other third-party services',
    body: <>
      <P>
        Some features connect to third-party services you choose to use, such as background-check providers, single
        sign-on or HR systems. Those services are provided by the third party under its own terms. We are not responsible
        for the accuracy of results a third party returns, or for its acts or omissions, but we will pass your instructions
        and data to it as you direct.
      </P>
      <P>
        If you order background checks, you are responsible for obtaining the candidate’s consent, using the results only
        for lawful, job-related purposes, and giving candidates any notice and opportunity to respond that the law requires.
      </P>
    </>,
  },
  {
    id: 'fees',
    title: 'Fees and payment',
    body: <List items={[
      'Fees are set out in your order form or on our pricing page, in Canadian dollars, and are billed in advance for each subscription term unless agreed otherwise.',
      'Fees exclude taxes. You will pay applicable GST/HST, PST or QST in addition to the fees.',
      'Invoices are due within 30 days. If an amount is more than 30 days overdue, we may suspend the Service after giving you at least 10 days’ written notice.',
      'Per-employee or per-user fees are based on the number in your order form; if you exceed it, we may invoice the difference for the rest of the term.',
      'We may change fees at renewal by telling you at least 60 days before the renewal date.',
      'Fees are non-refundable except where these Terms say otherwise.',
    ]} />,
  },
  {
    id: 'trials',
    title: 'Free trials and pilots',
    body: <P>
      If we give you a free trial or pilot, it lasts for the period we tell you. It is provided “as is”, without any
      service level, and we may end it at any time. Unless you subscribe, we may delete Customer Data from a trial 30
      days after it ends; export anything you want to keep before then.
    </P>,
  },
  {
    id: 'term',
    title: 'Term, renewal and termination',
    body: <List items={[
      'Your subscription runs for the term in your order form (or month to month if none is stated) and renews for the same length unless either party gives notice at least 30 days before the end of the term.',
      'Either party may end these Terms if the other materially breaches them and does not fix the breach within 30 days of written notice.',
      'We may suspend access immediately if needed to prevent harm to the Service, other customers or individuals, or to comply with law. We will tell you why and restore access as soon as the issue is resolved.',
      'When your subscription ends, you may export your Customer Data for 30 days. After that we will delete it from the live Service within a further 30 days, and from backups as they expire in the normal course, unless the law requires us to keep it.',
    ]} />,
  },
  {
    id: 'ip',
    title: 'Our intellectual property',
    body: <P>
      We own the Service, its software, design and our own content, including system templates, sample courses and rule
      content. While you subscribe, you may use them, and adapt the templates and content for your own workplace. You
      must not copy, resell or reverse-engineer the Service, except where the law expressly allows it. If you send us
      feedback, we may use it without obligation to you.
    </P>,
  },
  {
    id: 'confidentiality',
    title: 'Confidentiality',
    body: <P>
      Each party will keep the other’s confidential information confidential, use it only to perform these Terms, and
      protect it with at least reasonable care. This does not apply to information that is public, already known to the
      receiving party, independently developed, or lawfully received from someone else. A party may disclose confidential
      information if required by law, after giving the other party notice where it lawfully can.
    </P>,
  },
  {
    id: 'security',
    title: 'Security',
    body: <P>
      We use administrative, technical and physical safeguards appropriate to the sensitivity of Customer Data, including
      separation of each customer’s data enforced in the database, role-based access, encryption in transit, audit
      logging and two-step sign-in. More detail is in the <Link href="/legal/data-processing">Data Processing Addendum</Link>.
    </P>,
  },
  {
    id: 'warranties',
    title: 'Warranties and disclaimers',
    body: <>
      <P>
        We will provide the Service with reasonable skill and care and in line with these Terms. If it does not perform as
        promised, tell us and we will use reasonable efforts to fix it; if we cannot within a reasonable time, either of us
        may end the affected subscription and we will refund prepaid fees for the remaining term.
      </P>
      <P>
        Except as stated in these Terms, and to the extent the law allows, the Service is provided “as is”. We do not
        promise that it will be uninterrupted or error-free, or that sample content, rules, AI output or third-party results
        are complete, current or suitable for your workplace.
      </P>
    </>,
  },
  {
    id: 'liability',
    title: 'Limitation of liability',
    body: <>
      <P>To the extent the law allows:</P>
      <List items={[
        'neither party is liable for indirect, incidental, special or consequential losses, or for lost profits, revenue or goodwill;',
        'each party’s total liability arising out of these Terms is limited to the fees you paid or owe for the Service in the 12 months before the event that gave rise to the claim.',
      ]} />
      <P>
        These limits do not apply to your obligation to pay fees, to a party’s breach of confidentiality, to your breach of
        the Acceptable Use Policy, to indemnities under these Terms, or to liability that cannot be limited by law.
      </P>
    </>,
  },
  {
    id: 'indemnity',
    title: 'Indemnities',
    body: <>
      <P>
        We will defend you against a third-party claim that the Service infringes that party’s intellectual property rights,
        and pay the resulting damages and costs awarded or agreed in settlement. If such a claim is made or likely, we may
        modify the Service, get you the right to keep using it, or end the affected subscription and refund prepaid fees.
      </P>
      <P>
        You will defend us against a third-party claim arising from Customer Data you put into the Service without the
        required right, consent or notice, or from your use of the Service in breach of the Acceptable Use Policy, and pay
        the resulting damages and costs.
      </P>
      <P>The party seeking defence must notify the other promptly, give it control of the defence, and co-operate reasonably.</P>
    </>,
  },
  {
    id: 'changes',
    title: 'Changes to these Terms',
    body: <P>
      We may update these Terms. If a change is material, we will tell account administrators by email or in the Service
      at least 30 days before it takes effect. If you object, you may end your subscription before the change takes effect
      and we will refund prepaid fees for the remaining term. Continuing to use the Service after that date means you accept
      the updated Terms.
    </P>,
  },
  {
    id: 'general',
    title: 'General',
    body: <List items={[
      <>These Terms are governed by the laws of the Province of {LEGAL.governingProvince} and the federal laws of Canada that apply there. The courts of {LEGAL.governingProvince} have exclusive jurisdiction, except that either party may seek urgent relief in any court.</>,
      'Neither party is liable for delay caused by events beyond its reasonable control.',
      'You may not assign these Terms without our consent, except to a successor to your business. We may assign them to an affiliate or a successor to our business, and will tell you if we do.',
      <>Notices to us go to <Mail to={LEGAL.contactEmail} />. Notices to you go to the email address of your account administrator.</>,
      'If any part of these Terms is unenforceable, the rest remains in effect. A failure to enforce a right is not a waiver of it.',
      'These Terms, with any order form, are the entire agreement between us about the Service.',
      LEGAL.frenchVersionAvailable
        ? 'These Terms are available in French. If you are located in Quebec, you may choose which version applies.'
        : 'These Terms are written in English. If your organization is located in Quebec, contact us before subscribing so we can provide them in French.',
    ]} />,
  },
]

export default function TermsPage() {
  return (
    <LegalPage
      title="Terms of Service"
      current="/legal/terms"
      intro={<p>The agreement between your organization and EXXIO. Please read it before creating an account.</p>}
      sections={sections}
    />
  )
}
