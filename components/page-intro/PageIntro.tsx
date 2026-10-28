'use client'

import { useEffect, useState } from 'react'
import { Button, IconButton, Modal } from '@carbon/react'
import { Information, CheckmarkFilled } from '@carbon/icons-react'
import { PAGE_INTROS } from './content'
import { IntroPreview } from './IntroPreview'

const STORAGE_PREFIX = 'exxio.intro.'

function hasSeen(screen: string): boolean {
  try {
    return window.localStorage.getItem(STORAGE_PREFIX + screen) === '1'
  } catch {
    // Storage blocked (private mode, policy). Treat as seen so we never nag.
    return true
  }
}

function markSeen(screen: string) {
  try {
    window.localStorage.setItem(STORAGE_PREFIX + screen, '1')
  } catch {
    // Ignore: storage unavailable
  }
}

/**
 * Info button that sits beside a page heading. Opens a short explanation of the
 * screen automatically on the first visit, and again whenever it is clicked.
 */
export function PageIntro({ screen }: { screen: string }) {
  const intro = PAGE_INTROS[screen]
  const [open, setOpen] = useState(false)

  useEffect(() => {
    if (!intro) return
    if (!hasSeen(screen)) {
      setOpen(true)
      markSeen(screen)
    }
  }, [intro, screen])

  if (!intro) return null

  const close = () => setOpen(false)

  return (
    <>
      <IconButton
        kind="ghost"
        size="sm"
        label="About this page"
        align="bottom"
        onClick={() => setOpen(true)}
      >
        <Information size={20} />
      </IconButton>

      <Modal
        open={open}
        passiveModal
        size="sm"
        modalLabel="About this page"
        modalHeading={intro.title}
        onRequestClose={close}
        closeButtonLabel="Close"
      >
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '1rem' }}>
          <IntroPreview kind={intro.preview} accent={intro.accent} />
        </div>
        <p style={{ fontSize: '0.875rem', lineHeight: 1.5, color: '#161616', marginBottom: '1rem' }}>
          {intro.description}
        </p>
        <p style={{ fontSize: '0.75rem', fontWeight: 600, color: '#525252', marginBottom: '0.5rem', textTransform: 'uppercase', letterSpacing: '0.02em' }}>
          You can
        </p>
        <ul style={{ listStyle: 'none', padding: 0, margin: '0 0 1.5rem 0', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
          {intro.points.map((point) => (
            <li key={point} style={{ display: 'flex', gap: '0.5rem', alignItems: 'flex-start', fontSize: '0.875rem', lineHeight: 1.4, color: '#161616' }}>
              <CheckmarkFilled size={16} style={{ fill: intro.accent ?? '#0f62fe', flexShrink: 0, marginTop: '0.1rem' }} />
              <span>{point}</span>
            </li>
          ))}
        </ul>
        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
          <Button kind="primary" size="md" onClick={close} data-modal-primary-focus>
            Got it
          </Button>
        </div>
      </Modal>
    </>
  )
}
