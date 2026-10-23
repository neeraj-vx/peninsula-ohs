import { describe, expect, it } from 'vitest'
import { addBusinessDays, getDisputeWindowCloseDate } from '@/lib/background-checks/adverse-action'

const iso = (d: Date) => d.toISOString().slice(0, 10)

describe('addBusinessDays', () => {
  it('skips weekends', () => {
    // Fri 2026-10-23 + 1 business day = Mon 2026-10-26
    expect(iso(addBusinessDays(new Date('2026-10-23T12:00:00Z'), 1))).toBe('2026-10-26')
  })

  it('skips federal statutory holidays', () => {
    // Fri 2026-07-03 + 1 → Mon 2026-07-06; Thu 2026-12-24 + 1 skips 25, 26 (Sat), 27 (Sun)
    expect(iso(addBusinessDays(new Date('2026-07-03T12:00:00Z'), 1))).toBe('2026-07-06')
    expect(iso(addBusinessDays(new Date('2026-12-24T12:00:00Z'), 1))).toBe('2026-12-28')
  })

  it('skips Thanksgiving when counting from the Friday before', () => {
    // Fri 2026-10-09 + 1 → Tue 2026-10-13 (Mon 10-12 is Thanksgiving)
    expect(iso(addBusinessDays(new Date('2026-10-09T12:00:00Z'), 1))).toBe('2026-10-13')
  })

  it('gives the same calendar date regardless of the time of day (UTC)', () => {
    // Late-evening UTC must not roll into the next day in UTC+ server zones
    const late = addBusinessDays(new Date('2026-06-30T23:30:00Z'), 1)
    const early = addBusinessDays(new Date('2026-06-30T00:30:00Z'), 1)
    expect(iso(late)).toBe('2026-07-02') // 07-01 is Canada Day
    expect(iso(early)).toBe('2026-07-02')
  })
})

describe('getDisputeWindowCloseDate', () => {
  it('defaults to 5 business days', () => {
    // Mon 2026-11-09 + 5 business days, skipping Wed 11-11 Remembrance Day → Tue 2026-11-17
    expect(iso(getDisputeWindowCloseDate(new Date('2026-11-09T15:00:00Z')))).toBe('2026-11-17')
  })
})
