'use client'

import { useState, useTransition } from 'react'
import { Button, InlineNotification } from '@carbon/react'
import { completeInvestigation } from '@/app/actions/investigations'

export function CompleteInvestigationButton({ id }: { id: string }) {
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)

  function handleClick() {
    setError(null)
    startTransition(async () => {
      const result = await completeInvestigation(id)
      if (result?.error) setError(result.error)
    })
  }

  return (
    <div>
      <Button kind="primary" size="sm" onClick={handleClick} disabled={isPending}>
        {isPending ? 'Saving…' : 'Mark Complete'}
      </Button>
      {error && (
        <InlineNotification
          kind="error"
          title="Could not complete"
          subtitle={error}
          onCloseButtonClick={() => setError(null)}
          style={{ marginTop: '0.5rem' }}
        />
      )}
    </div>
  )
}
