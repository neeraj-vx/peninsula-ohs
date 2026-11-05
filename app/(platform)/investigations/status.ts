// Mirrors investigation_status_enum in the database.
export const INVESTIGATION_STATUSES = [
  'assigned',
  'in_progress',
  'rca_complete',
  'capa_in_progress',
  'pending_review',
  'complete',
] as const

export type InvestigationTagType = 'blue' | 'green' | 'gray' | 'purple' | 'teal' | 'cyan'

export const INVESTIGATION_STATUS_TAGS: Record<string, InvestigationTagType> = {
  assigned: 'blue',
  in_progress: 'purple',
  rca_complete: 'teal',
  capa_in_progress: 'cyan',
  pending_review: 'blue',
  complete: 'green',
}

export const RCA_METHODS: Record<string, string> = {
  five_whys: '5 Whys',
  fishbone: 'Fishbone',
  both: '5 Whys + Fishbone',
  none: 'None',
}

export function statusLabel(status: string) {
  if (status === 'rca_complete') return 'RCA complete'
  if (status === 'capa_in_progress') return 'CAPA in progress'
  const s = status.replace(/_/g, ' ')
  return s.charAt(0).toUpperCase() + s.slice(1)
}
