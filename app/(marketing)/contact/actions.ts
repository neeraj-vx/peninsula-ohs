'use server'

import { supabaseAdmin } from '@/lib/supabase/admin'
import {
  PROVINCES, EMPLOYEE_COUNTS, INTERESTS, LIMITS, EMAIL_RE,
  type ContactField, type ContactResult,
} from './options'

const ALLOWED_SOURCES = ['/contact', '/pricing', '/', '/how-it-works']

function str(fd: FormData, key: string): string {
  const v = fd.get(key)
  return typeof v === 'string' ? v.trim() : ''
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

export async function submitContact(formData: FormData): Promise<ContactResult> {
  // Honeypot: real people never see or fill this field. Pretend success for bots.
  if (str(formData, 'website') !== '') return { ok: true }

  const name = str(formData, 'name')
  const email = str(formData, 'email').toLowerCase()
  const company = str(formData, 'company')
  const province = str(formData, 'province').toUpperCase()
  const employeeCount = str(formData, 'employee_count')
  const interest = str(formData, 'interest')
  const message = str(formData, 'message')
  const sourceRaw = str(formData, 'source_page')
  const sourcePage = ALLOWED_SOURCES.includes(sourceRaw) ? sourceRaw : '/contact'

  const fieldErrors: Partial<Record<ContactField, string>> = {}
  if (!name) fieldErrors.name = 'Please enter your name.'
  else if (name.length > LIMITS.name) fieldErrors.name = `Please keep this under ${LIMITS.name} characters.`

  if (!email) fieldErrors.email = 'Please enter your work email.'
  else if (email.length > LIMITS.email || !EMAIL_RE.test(email)) fieldErrors.email = 'Please enter a valid email address.'

  if (company.length > LIMITS.company) fieldErrors.company = `Please keep this under ${LIMITS.company} characters.`
  if (province && !PROVINCES.some((p) => p.code === province)) fieldErrors.province = 'Please choose a province or territory.'
  if (employeeCount && !(EMPLOYEE_COUNTS as readonly string[]).includes(employeeCount)) fieldErrors.employee_count = 'Please choose an option.'
  if (interest && !INTERESTS.some((i) => i.value === interest)) fieldErrors.interest = 'Please choose an option.'
  if (message.length > LIMITS.message) fieldErrors.message = `Please keep this under ${LIMITS.message} characters.`

  if (Object.keys(fieldErrors).length > 0) {
    return { ok: false, error: 'Please check the highlighted fields.', fieldErrors }
  }

  const { error } = await supabaseAdmin.from('marketing_leads').insert({
    name,
    email,
    company: company || null,
    province: province || null,
    employee_count: employeeCount || null,
    interest: interest || null,
    message: message || null,
    source_page: sourcePage,
  })

  if (error) {
    console.error('[contact] failed to save lead:', error.message)
    return { ok: false, error: 'Sorry, something went wrong sending your message. Please try again in a moment.' }
  }

  // Notification email is best-effort: never fail the submission because of it.
  try {
    await notify({ name, email, company, province, employeeCount, interest, message, sourcePage })
  } catch (e) {
    console.error('[contact] notification email failed:', e instanceof Error ? e.message : e)
  }

  return { ok: true }
}

async function notify(lead: {
  name: string; email: string; company: string; province: string
  employeeCount: string; interest: string; message: string; sourcePage: string
}) {
  const apiKey = process.env.RESEND_API_KEY
  const to = process.env.CONTACT_NOTIFY_EMAIL
  if (!apiKey || !to) return

  const interestLabel = INTERESTS.find((i) => i.value === lead.interest)?.label ?? ''
  const rows: [string, string][] = [
    ['Name', lead.name],
    ['Email', lead.email],
    ['Company', lead.company],
    ['Province', lead.province],
    ['Employees', lead.employeeCount],
    ['Interest', interestLabel],
    ['Page', lead.sourcePage],
  ]

  const text = [
    'New contact form submission',
    '',
    ...rows.map(([k, v]) => `${k}: ${v || '—'}`),
    '',
    'Message:',
    lead.message || '—',
  ].join('\n')

  const html = `
    <p><strong>New contact form submission</strong></p>
    <table cellpadding="4" style="border-collapse:collapse;">
      ${rows.map(([k, v]) => `<tr><td style="color:#525252;">${k}</td><td>${escapeHtml(v || '—')}</td></tr>`).join('')}
    </table>
    <p style="color:#525252;margin-top:16px;">Message:</p>
    <p style="white-space:pre-wrap;">${escapeHtml(lead.message || '—')}</p>
  `

  // Strip line breaks so user input can't affect the subject header.
  const subjectName = (lead.company || lead.name).replace(/[\r\n]+/g, ' ').slice(0, 100)

  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      from: process.env.CONTACT_EMAIL_FROM ?? 'EXXIO <noreply@exxio.ai>',
      to: [to],
      reply_to: lead.email,
      subject: `New EXXIO enquiry${interestLabel ? ` (${interestLabel})` : ''} — ${subjectName}`,
      html,
      text,
    }),
  })

  if (!res.ok) {
    console.error('[contact] Resend error:', res.status, await res.text())
  }
}
