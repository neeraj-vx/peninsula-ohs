'use client'

import { useTransition } from 'react'
import { Button } from '@carbon/react'
import { setTrainingRuleActive } from '@/app/actions/training'

export function RequirementToggle({ ruleId, isActive }: { ruleId: string; isActive: boolean }) {
  const [isPending, startTransition] = useTransition()
  return (
    <Button
      kind="ghost"
      size="sm"
      disabled={isPending}
      onClick={() => startTransition(async () => { await setTrainingRuleActive(ruleId, !isActive) })}
    >
      {isActive ? 'Pause' : 'Resume'}
    </Button>
  )
}
