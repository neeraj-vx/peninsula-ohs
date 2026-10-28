// Shared option lists for the contact form (used by the form and the server action).

export const PROVINCES = [
  { code: 'AB', name: 'Alberta' },
  { code: 'BC', name: 'British Columbia' },
  { code: 'MB', name: 'Manitoba' },
  { code: 'NB', name: 'New Brunswick' },
  { code: 'NL', name: 'Newfoundland and Labrador' },
  { code: 'NS', name: 'Nova Scotia' },
  { code: 'NT', name: 'Northwest Territories' },
  { code: 'NU', name: 'Nunavut' },
  { code: 'ON', name: 'Ontario' },
  { code: 'PE', name: 'Prince Edward Island' },
  { code: 'QC', name: 'Quebec' },
  { code: 'SK', name: 'Saskatchewan' },
  { code: 'YT', name: 'Yukon' },
] as const

export const EMPLOYEE_COUNTS = ['1–19', '20–49', '50–199', '200–999', '1000+'] as const

export const INTERESTS = [
  { value: 'pricing', label: 'Pricing' },
  { value: 'demo', label: 'Demo' },
  { value: 'general', label: 'General question' },
] as const

export type ContactField = 'name' | 'email' | 'company' | 'province' | 'employee_count' | 'interest' | 'message'

export type ContactResult =
  | { ok: true }
  | { ok: false; error: string; fieldErrors?: Partial<Record<ContactField, string>> }

export const LIMITS = { name: 200, email: 320, company: 200, message: 5000 } as const

export const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
