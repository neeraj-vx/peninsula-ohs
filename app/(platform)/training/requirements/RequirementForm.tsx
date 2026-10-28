'use client'

import { useState, useTransition } from 'react'
import { Tile, Select, SelectItem, NumberInput, Button, InlineNotification } from '@carbon/react'
import { Add } from '@carbon/icons-react'
import { createTrainingRule } from '@/app/actions/training'

interface Props {
  courses: { id: string; name: string; sample: boolean }[]
  roles: { id: string; name: string }[]
  sites: { id: string; name: string }[]
}

export function RequirementForm({ courses, roles, sites }: Props) {
  const [isPending, startTransition] = useTransition()
  const [message, setMessage] = useState<{ kind: 'success' | 'error'; text: string } | null>(null)
  const [formKey, setFormKey] = useState(0)

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    const formData = new FormData(e.currentTarget)
    setMessage(null)
    startTransition(async () => {
      const result = await createTrainingRule(formData)
      if (result.error) {
        setMessage({ kind: 'error', text: result.error })
        return
      }
      const n = result.assigned ?? 0
      setMessage({
        kind: 'success',
        text: n > 0
          ? `Requirement added. ${n} ${n === 1 ? 'person has' : 'people have'} been assigned this training.`
          : 'Requirement added. Everyone it applies to has already completed this training.',
      })
      setFormKey((k) => k + 1)
    })
  }

  return (
    <Tile>
      <h2 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: '1rem' }}>Add a requirement</h2>
      <form key={formKey} onSubmit={handleSubmit}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(13rem, 1fr))', gap: '1rem', alignItems: 'end' }}>
          <Select id="course_id" name="course_id" labelText="Course" defaultValue="" required>
            <SelectItem value="" text="Choose a course" />
            {courses.map((c) => (
              <SelectItem key={c.id} value={c.id} text={c.sample ? `${c.name} (sample)` : c.name} />
            ))}
          </Select>
          <Select id="role_id" name="role_id" labelText="Who must take it" defaultValue="">
            <SelectItem value="" text="Everyone" />
            {roles.map((r) => <SelectItem key={r.id} value={r.id} text={`${r.name}s`} />)}
          </Select>
          {sites.length > 1 && (
            <Select id="site_id" name="site_id" labelText="Where" defaultValue="">
              <SelectItem value="" text="All sites" />
              {sites.map((s) => <SelectItem key={s.id} value={s.id} text={s.name} />)}
            </Select>
          )}
          <NumberInput
            id="due_within_days"
            name="due_within_days"
            label="Due within (business days)"
            min={0}
            max={365}
            step={1}
            defaultValue={30}
            hideSteppers
          />
        </div>
        <div style={{ marginTop: '1rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <Button type="submit" renderIcon={Add} disabled={isPending}>
            {isPending ? 'Adding…' : 'Add requirement'}
          </Button>
          <span style={{ fontSize: '0.75rem', color: '#6f6f6f' }}>
            Courses marked (sample) are starter content. Check them against your provincial requirements.
          </span>
        </div>
      </form>
      {message && (
        <InlineNotification
          kind={message.kind}
          title={message.kind === 'success' ? 'Done' : 'Could not add'}
          subtitle={message.text}
          lowContrast
          onClose={() => setMessage(null)}
          style={{ marginTop: '1rem', maxWidth: '100%' }}
        />
      )}
    </Tile>
  )
}
