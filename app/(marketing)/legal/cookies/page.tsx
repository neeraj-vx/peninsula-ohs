import type { Metadata } from 'next'
import { LegalPage, P, Table, type LegalSection } from '@/components/marketing/legal'

export const metadata: Metadata = {
  title: 'Cookie Notice — EXXIO',
  description: 'The cookies and similar storage EXXIO uses.',
}

const sections: LegalSection[] = [
  {
    id: 'summary',
    title: 'In short',
    body: <P>
      EXXIO uses only the cookies and browser storage needed to sign you in, keep your session secure, and remember small
      preferences. We do not use advertising cookies, cross-site tracking or third-party analytics. Because these are all
      strictly necessary for the service you ask for, we do not show a cookie banner.
    </P>,
  },
  {
    id: 'list',
    title: 'What we use',
    body: <Table
      head={['Name', 'Type', 'Why', 'How long']}
      rows={[
        [<code key="sb">sb-…-auth-token</code>, 'Cookie (necessary)', 'Keeps you signed in and protects your session.', 'Until you sign out or the session expires'],
        [<code key="sa">exxio_sa_token</code>, 'Cookie (necessary)', 'Signs in EXXIO staff to our administration console. Customers never receive it.', 'Until the staff session ends'],
        [<code key="im">exxio_impersonating</code>, 'Cookie (necessary)', 'Set only while an EXXIO staff member is viewing an account to provide support, so the session is clearly marked and logged.', 'Until support ends'],
        [<code key="pi">exxio.intro.…</code>, 'Browser storage (preference)', 'Remembers which first-time help panels you have closed.', 'Until you clear your browser storage'],
        [<code key="pw">pwa-install-dismissed</code>, 'Browser storage (preference)', 'Remembers that you closed the “install app” prompt.', 'Until you close the browser tab'],
      ]}
    />,
  },
  {
    id: 'third-party',
    title: 'Third-party content',
    body: <P>
      If your organization embeds a YouTube or Vimeo video in a training course, that provider may set its own cookies when
      the video plays, under its own privacy policy.
    </P>,
  },
  {
    id: 'control',
    title: 'Your choices',
    body: <P>
      You can block or delete cookies in your browser settings. If you block the necessary cookies, you will not be able to
      sign in. We will update this notice before we add any cookie that is not strictly necessary, and ask for your consent
      where the law requires it.
    </P>,
  },
]

export default function CookiesPage() {
  return (
    <LegalPage
      title="Cookie Notice"
      current="/legal/cookies"
      intro={<p>The cookies and similar storage EXXIO uses, and why.</p>}
      sections={sections}
    />
  )
}
