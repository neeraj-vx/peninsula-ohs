'use client'

import { useRef, useState } from 'react'
import {
  Button, Select, SelectItem, TextInput, TextArea, InlineNotification, InlineLoading,
} from '@carbon/react'
import { CheckmarkFilled } from '@carbon/icons-react'
import { submitContact } from './actions'
import {
  PROVINCES, EMPLOYEE_COUNTS, INTERESTS, LIMITS, EMAIL_RE, type ContactField,
} from './options'

type Errors = Partial<Record<ContactField, string>>

function validate(fd: FormData): Errors {
  const get = (k: string) => String(fd.get(k) ?? '').trim()
  const errors: Errors = {}
  const name = get('name')
  const email = get('email')
  if (!name) errors.name = 'Please enter your name.'
  else if (name.length > LIMITS.name) errors.name = `Please keep this under ${LIMITS.name} characters.`
  if (!email) errors.email = 'Please enter your work email.'
  else if (email.length > LIMITS.email || !EMAIL_RE.test(email)) errors.email = 'Please enter a valid email address.'
  if (get('company').length > LIMITS.company) errors.company = `Please keep this under ${LIMITS.company} characters.`
  if (get('message').length > LIMITS.message) errors.message = `Please keep this under ${LIMITS.message} characters.`
  return errors
}

export function ContactForm({ defaultInterest = '' }: { defaultInterest?: string }) {
  const formRef = useRef<HTMLFormElement>(null)
  const [errors, setErrors] = useState<Errors>({})
  const [formError, setFormError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [sent, setSent] = useState(false)

  function clearError(field: ContactField) {
    if (errors[field]) setErrors((e) => ({ ...e, [field]: undefined }))
  }

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setFormError(null)
    const fd = new FormData(e.currentTarget)
    const clientErrors = validate(fd)
    setErrors(clientErrors)
    if (Object.keys(clientErrors).length > 0) {
      const first = Object.keys(clientErrors)[0]
      formRef.current?.querySelector<HTMLElement>(`[name="${first}"]`)?.focus()
      return
    }
    setLoading(true)
    try {
      const result = await submitContact(fd)
      if (result.ok) {
        setSent(true)
      } else {
        setErrors(result.fieldErrors ?? {})
        setFormError(result.error)
      }
    } catch {
      setFormError('Sorry, something went wrong sending your message. Please try again in a moment.')
    } finally {
      setLoading(false)
    }
  }

  if (sent) {
    return (
      <div role="status" style={{ background: '#defbe6', borderLeft: '4px solid #24a148', padding: '1.5rem' }}>
        <p style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '1.25rem', fontWeight: 600, color: '#161616' }}>
          <CheckmarkFilled size={20} style={{ color: '#24a148' }} aria-hidden="true" />
          Thanks — we&rsquo;ll be in touch.
        </p>
        <p style={{ fontSize: '1rem', color: '#525252', marginTop: '0.5rem', lineHeight: 1.5 }}>
          Your message has been sent. We usually reply by email.
        </p>
      </div>
    )
  }

  const gap = { marginBottom: '1.25rem' }
  const validInterest = INTERESTS.some((i) => i.value === defaultInterest) ? defaultInterest : ''

  return (
    <form ref={formRef} onSubmit={handleSubmit} noValidate aria-describedby={formError ? 'contact-form-error' : undefined}>
      {formError && (
        <div id="contact-form-error" role="alert" style={gap}>
          <InlineNotification kind="error" title="Not sent" subtitle={formError} onCloseButtonClick={() => setFormError(null)} lowContrast />
        </div>
      )}

      {/* Honeypot: hidden from people and screen readers; bots tend to fill it. */}
      <div aria-hidden="true" style={{ position: 'absolute', left: '-10000px', width: 1, height: 1, overflow: 'hidden' }}>
        <label htmlFor="contact-website">Website</label>
        <input id="contact-website" name="website" type="text" tabIndex={-1} autoComplete="off" defaultValue="" />
      </div>
      <input type="hidden" name="source_page" value="/contact" />

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(16rem, 1fr))', columnGap: '1.5rem' }}>
        <div style={gap}>
          <TextInput
            id="contact-name" name="name" labelText="Name (required)" autoComplete="name" required
            maxLength={LIMITS.name} invalid={!!errors.name} invalidText={errors.name}
            onChange={() => clearError('name')}
          />
        </div>
        <div style={gap}>
          <TextInput
            id="contact-email" name="email" type="email" labelText="Work email (required)" autoComplete="email" required
            maxLength={LIMITS.email} invalid={!!errors.email} invalidText={errors.email}
            onChange={() => clearError('email')}
          />
        </div>
        <div style={gap}>
          <TextInput
            id="contact-company" name="company" labelText="Company" autoComplete="organization"
            maxLength={LIMITS.company} invalid={!!errors.company} invalidText={errors.company}
            onChange={() => clearError('company')}
          />
        </div>
        <div style={gap}>
          <Select id="contact-province" name="province" labelText="Province or territory" defaultValue=""
            invalid={!!errors.province} invalidText={errors.province} onChange={() => clearError('province')}>
            <SelectItem value="" text="Choose one" />
            {PROVINCES.map((p) => <SelectItem key={p.code} value={p.code} text={p.name} />)}
          </Select>
        </div>
        <div style={gap}>
          <Select id="contact-employees" name="employee_count" labelText="Number of employees" defaultValue=""
            invalid={!!errors.employee_count} invalidText={errors.employee_count} onChange={() => clearError('employee_count')}>
            <SelectItem value="" text="Choose one" />
            {EMPLOYEE_COUNTS.map((c) => <SelectItem key={c} value={c} text={c} />)}
          </Select>
        </div>
        <div style={gap}>
          <Select id="contact-interest" name="interest" labelText="I'm interested in" defaultValue={validInterest}
            invalid={!!errors.interest} invalidText={errors.interest} onChange={() => clearError('interest')}>
            <SelectItem value="" text="Choose one" />
            {INTERESTS.map((i) => <SelectItem key={i.value} value={i.value} text={i.label} />)}
          </Select>
        </div>
      </div>

      <div style={{ marginBottom: '1.5rem' }}>
        <TextArea
          id="contact-message" name="message" labelText="Message" rows={5}
          helperText="Tell us about your workplace and what you'd like to know."
          maxLength={LIMITS.message} invalid={!!errors.message} invalidText={errors.message}
          onChange={() => clearError('message')}
        />
      </div>

      {loading
        ? <InlineLoading description="Sending…" />
        : <Button kind="primary" type="submit">Send message</Button>}
    </form>
  )
}
