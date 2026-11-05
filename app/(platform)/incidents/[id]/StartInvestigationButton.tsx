'use client'

import { useState, useTransition } from 'react'
import { Button, InlineNotification } from '@carbon/react'
import { createInvestigation } from '@/app/actions/investigations'

export function StartInvestigationButton({ incidentId }: { incidentId: string }) {
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)

  function handleClick() {
    setError(null)
    startTransition(async () => {
      // On success the action redirects to the new investigation.
      const result = await createInvestigation(incidentId)
      if (result?.error) setError(result.error)
    })
  }

  return (
    <div>
      {error && (
        <InlineNotification
          kind="error"
          title="Could not start investigation"
          subtitle={error}
          onCloseButtonClick={() => setError(null)}
          style={{ marginBottom: '1rem', maxWidth: '100%' }}
        />
      )}
      <Button kind="tertiary" size="md" onClick={handleClick} disabled={isPending}>
        {isPending ? 'Starting…' : 'Start Investigation'}
      </Button>
    </div>
  )
}
