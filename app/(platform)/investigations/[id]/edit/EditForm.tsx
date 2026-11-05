'use client'

import { useState, useTransition } from 'react'
import { Grid, Column, Tile, Button, TextArea, Form, FormGroup, InlineNotification } from '@carbon/react'
import { Select, SelectItem, TextInput } from '@/components/ui/controls'
import { updateInvestigation } from '@/app/actions/investigations'
import { INVESTIGATION_STATUSES, RCA_METHODS, statusLabel } from '../../status'

interface Worker { id: string; first_name: string; last_name: string }

interface InitialData {
  status: string
  investigator_id: string | null
  rca_method: string | null
  start_date: string | null
  target_completion_date: string | null
  actual_completion_date: string | null
  background: string | null
  contributing_factors: string | null
  investigation_summary: string | null
  lessons_learned: string | null
}

interface Props {
  id: string
  initialData: InitialData
  workers: Worker[]
}

export function EditInvestigationForm({ id, initialData, workers }: Props) {
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setError(null)
    const formData = new FormData(e.currentTarget)
    startTransition(async () => {
      const result = await updateInvestigation(id, formData)
      if (result?.error) setError(result.error)
    })
  }

  return (
    <div style={{ paddingBottom: '2rem' }}>
      {error && (
        <InlineNotification kind="error" title="Error" subtitle={error} onCloseButtonClick={() => setError(null)} style={{ marginBottom: '1.5rem', maxWidth: '100%' }} />
      )}
      <Form onSubmit={handleSubmit}>
        <Grid>
          <Column sm={4} md={8} lg={12}>
            <Tile style={{ padding: 0, marginBottom: '1rem' }}>
              <div style={{ padding: '1rem 1.5rem', borderBottom: '1px solid #e0e0e0' }}>
                <h2 style={{ fontSize: '0.875rem', fontWeight: 600, color: '#161616' }}>Investigation Details</h2>
              </div>
              <div style={{ padding: '1.5rem' }}>
                <Grid condensed>
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '1rem' }}>
                    <FormGroup legendText="">
                      <Select id="status" name="status" labelText="Status" defaultValue={initialData.status}>
                        {INVESTIGATION_STATUSES.map((s) => <SelectItem key={s} value={s} text={statusLabel(s)} />)}
                      </Select>
                    </FormGroup>
                  </Column>
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '1rem' }}>
                    <Select id="investigator_id" name="investigator_id" labelText="Investigator" defaultValue={initialData.investigator_id ?? ''}>
                      <SelectItem value="" text="Unassigned" />
                      {workers.map((w) => <SelectItem key={w.id} value={w.id} text={`${w.first_name} ${w.last_name}`} />)}
                    </Select>
                  </Column>
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '1rem' }}>
                    <Select id="rca_method" name="rca_method" labelText="RCA Method" defaultValue={initialData.rca_method ?? ''}>
                      <SelectItem value="" text="Not set" />
                      {Object.entries(RCA_METHODS).map(([value, label]) => <SelectItem key={value} value={value} text={label} />)}
                    </Select>
                  </Column>
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '1rem' }}>
                    <TextInput id="start_date" name="start_date" labelText="Start Date" type="date" defaultValue={initialData.start_date ?? ''} />
                  </Column>
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '1rem' }}>
                    <TextInput id="target_completion_date" name="target_completion_date" labelText="Target Completion" type="date" defaultValue={initialData.target_completion_date ?? ''} />
                  </Column>
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '1rem' }}>
                    <TextInput id="actual_completion_date" name="actual_completion_date" labelText="Completed On (when status is Complete)" type="date" defaultValue={initialData.actual_completion_date ?? ''} />
                  </Column>
                  <Column sm={4} md={8} lg={16} style={{ marginBottom: '1rem' }}>
                    <TextArea id="background" name="background" labelText="Background" defaultValue={initialData.background ?? ''} rows={3} />
                  </Column>
                  <Column sm={4} md={8} lg={16} style={{ marginBottom: '1rem' }}>
                    <TextArea id="contributing_factors" name="contributing_factors" labelText="Contributing Factors" defaultValue={initialData.contributing_factors ?? ''} rows={3} />
                  </Column>
                  <Column sm={4} md={8} lg={16} style={{ marginBottom: '1rem' }}>
                    <TextArea id="investigation_summary" name="investigation_summary" labelText="Investigation Summary" defaultValue={initialData.investigation_summary ?? ''} rows={4} />
                  </Column>
                  <Column sm={4} md={8} lg={16} style={{ marginBottom: '1rem' }}>
                    <TextArea id="lessons_learned" name="lessons_learned" labelText="Lessons Learned" defaultValue={initialData.lessons_learned ?? ''} rows={3} />
                  </Column>
                </Grid>
              </div>
            </Tile>

            <div style={{ display: 'flex', gap: '1rem' }}>
              <Button type="submit" disabled={isPending}>{isPending ? 'Saving…' : 'Save Changes'}</Button>
              <Button kind="ghost" href={`/investigations/${id}`}>Cancel</Button>
            </div>
          </Column>
        </Grid>
      </Form>
    </div>
  )
}
