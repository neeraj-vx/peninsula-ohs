import { describe, expect, it } from 'vitest'
import { admin, must } from './helpers'

// D11 — statutory holidays and business-day arithmetic in SQL
const addBusinessDays = async (start: string, days: number, jurisdiction = 'CA') =>
  must(await admin.rpc('add_business_days', { p_start: start, p_days: days, p_jurisdiction: jurisdiction }), 'add_business_days')

describe('business days', () => {
  it('skips weekends', async () => {
    expect(await addBusinessDays('2026-10-23', 1)).toBe('2026-10-26')
  })

  it('skips federal holidays, including observed Boxing Day', async () => {
    expect(await addBusinessDays('2026-06-30', 1)).toBe('2026-07-02')      // Canada Day
    expect(await addBusinessDays('2026-12-24', 1)).toBe('2026-12-29')      // 25th, weekend, 28th observed
    expect(await addBusinessDays('2026-11-09', 5)).toBe('2026-11-17')      // Remembrance Day
  })

  it('applies the province\'s own holidays', async () => {
    // Family Day is an Ontario holiday but not a federal one
    expect(await addBusinessDays('2026-02-13', 1, 'CA-ON')).toBe('2026-02-17')
    expect(await addBusinessDays('2026-02-13', 1, 'CA')).toBe('2026-02-16')
    // Remembrance Day is federal but not an Ontario ESA public holiday
    expect(await addBusinessDays('2026-11-10', 1, 'CA-ON')).toBe('2026-11-11')
  })

  it('falls back to federal holidays for a province that is not seeded yet', async () => {
    expect(await addBusinessDays('2026-06-30', 1, 'CA-MB')).toBe('2026-07-02')  // Canada Day
  })

  it('reports holidays as non-business days', async () => {
    const isBusinessDay = async (d: string) =>
      must(await admin.rpc('is_business_day', { p_date: d, p_jurisdiction: 'CA' }), 'is_business_day')
    expect(await isBusinessDay('2026-09-30')).toBe(false)  // Truth and Reconciliation
    expect(await isBusinessDay('2026-10-13')).toBe(true)
  })
})
