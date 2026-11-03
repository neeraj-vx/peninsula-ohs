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
        className="exx-intro"
        aria-label={intro.title}
        onRequestClose={close}
        closeButtonLabel="Close"
      >
        <div
          className="exx-intro__hero"
          style={{ ['--accent' as string]: intro.accent ?? '#0f62fe' }}
        >
          <IntroPreview kind={intro.preview} accent={intro.accent} />
        </div>

        <div className="exx-intro__body">
          <p className="exx-intro__eyebrow">About this page</p>
          <h2 className="exx-intro__title">{intro.title}</h2>
          <p className="exx-intro__desc">{intro.description}</p>

          <div className="exx-intro__points">
            <p className="exx-intro__points-label">You can</p>
            <ul>
              {intro.points.map((point) => (
                <li key={point}>
                  <CheckmarkFilled size={16} style={{ fill: intro.accent ?? '#0f62fe' }} />
                  <span>{point}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>

        <div className="exx-intro__footer">
          <Button kind="primary" size="md" onClick={close} data-modal-primary-focus>
            Got it
          </Button>
        </div>
      </Modal>
    </>
  )
}
