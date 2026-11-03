'use client'

import { useEffect, useRef, useState } from 'react'
import { usePathname, useSearchParams } from 'next/navigation'

// Slim bar across the top of the page while a new page loads.
// Starts when an internal link is clicked, finishes when the URL changes.
export function TopLoadingBar() {
  const pathname = usePathname()
  const searchParams = useSearchParams()
  const [progress, setProgress] = useState(0)
  const [visible, setVisible] = useState(false)
  const timer = useRef<ReturnType<typeof setInterval> | null>(null)

  const stopTimer = () => {
    if (timer.current) clearInterval(timer.current)
    timer.current = null
  }

  // Finish when the new page has arrived
  useEffect(() => {
    if (!timer.current) return
    stopTimer()
    setProgress(100)
    const hide = setTimeout(() => { setVisible(false); setProgress(0) }, 250)
    return () => clearTimeout(hide)
  }, [pathname, searchParams])

  // Start on clicks to internal links
  useEffect(() => {
    const onClick = (e: MouseEvent) => {
      if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return
      const a = (e.target as HTMLElement).closest('a')
      if (!a || a.target === '_blank' || a.hasAttribute('download')) return
      const url = new URL(a.href, location.href)
      if (url.origin !== location.origin) return
      if (url.pathname === location.pathname && url.search === location.search) return
      stopTimer()
      setVisible(true)
      setProgress(10)
      // Creep towards 90% until the page arrives
      timer.current = setInterval(() => {
        setProgress((p) => (p < 90 ? p + (90 - p) * 0.1 : p))
      }, 200)
    }
    document.addEventListener('click', onClick, true)
    return () => { document.removeEventListener('click', onClick, true); stopTimer() }
  }, [])

  return (
    <div
      aria-hidden="true"
      style={{
        position: 'fixed', top: 0, left: 0, height: 2, zIndex: 10000,
        width: `${progress}%`,
        background: 'var(--cds-interactive, #0f62fe)',
        opacity: visible ? 1 : 0,
        transition: 'width 200ms ease-out, opacity 250ms ease',
        pointerEvents: 'none',
      }}
    />
  )
}
