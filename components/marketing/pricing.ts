// =============================================================
// PRICING CONFIG — this is where prices go.
//
// Set `priceMonthlyCad` to a number (in Canadian dollars, e.g. 8 or 7.5)
// to show a price on the /pricing page. While it is `null`, the plan card
// shows "Contact us for pricing" instead.
//
// Keep `highlights` and `COMPARISON` honest: list only features that exist
// in the product today.
// =============================================================

export type PlanId = 'essentials' | 'professional' | 'enterprise'

export interface Plan {
  id: PlanId
  name: string
  tagline: string
  /** Price in CAD per `unit`. `null` = not published yet ("Contact us for pricing"). */
  priceMonthlyCad: number | null
  unit: string
  highlights: string[]
  cta: { label: string; href: string }
  featured?: boolean
}

export const PLANS: Plan[] = [
  {
    id: 'essentials',
    name: 'Essentials',
    tagline: 'The core of a health and safety program, done properly.',
    priceMonthlyCad: null,
    unit: 'per employee / month',
    highlights: [
      'Incident, near-miss and hazard reporting',
      'Corrective actions tracked to close',
      'Scheduled inspections',
      'Documents, policies and staff sign-off',
      'Required training by role and certificate tracking',
      'Works on phones, tablets and desktops',
    ],
    cta: { label: 'Talk to us', href: '/contact?interest=pricing' },
  },
  {
    id: 'professional',
    name: 'Professional',
    tagline: 'For workplaces running a full safety program.',
    priceMonthlyCad: null,
    unit: 'per employee / month',
    highlights: [
      'Everything in Essentials',
      'Risk register with ready-made templates',
      'Job safety analyses (JSA)',
      'Permits to work and toolbox talks',
      'Contractor records',
      'Emergency planning and drills',
      'WHMIS chemical register and PPE',
      'KPIs including TRIR and LTIR',
    ],
    cta: { label: 'Talk to us', href: '/contact?interest=pricing' },
    featured: true,
  },
  {
    id: 'enterprise',
    name: 'Enterprise',
    tagline: 'Safety and HR together, across several sites.',
    priceMonthlyCad: null,
    unit: 'per employee / month',
    highlights: [
      'Everything in Professional',
      'Hiring and onboarding',
      'Background and reference checks',
      'Multiple sites',
      'Audit trail of who changed what',
      'Priority support and help getting set up',
    ],
    cta: { label: 'Talk to us', href: '/contact?interest=pricing' },
  },
]

/** Feature rows for the comparison table: which plans include each feature. */
export const COMPARISON: { feature: string; plans: PlanId[] }[] = [
  { feature: 'Incidents, near misses and hazards', plans: ['essentials', 'professional', 'enterprise'] },
  { feature: 'Corrective actions', plans: ['essentials', 'professional', 'enterprise'] },
  { feature: 'Inspections', plans: ['essentials', 'professional', 'enterprise'] },
  { feature: 'Documents and sign-off', plans: ['essentials', 'professional', 'enterprise'] },
  { feature: 'Required training and certificates', plans: ['essentials', 'professional', 'enterprise'] },
  { feature: 'Risk register and templates', plans: ['professional', 'enterprise'] },
  { feature: 'Job safety analyses', plans: ['professional', 'enterprise'] },
  { feature: 'Permits and toolbox talks', plans: ['professional', 'enterprise'] },
  { feature: 'Contractors', plans: ['professional', 'enterprise'] },
  { feature: 'Emergency planning', plans: ['professional', 'enterprise'] },
  { feature: 'WHMIS chemicals and PPE', plans: ['professional', 'enterprise'] },
  { feature: 'KPIs (TRIR, LTIR)', plans: ['professional', 'enterprise'] },
  { feature: 'Hiring and onboarding', plans: ['enterprise'] },
  { feature: 'Background checks', plans: ['enterprise'] },
  { feature: 'Multiple sites', plans: ['enterprise'] },
  { feature: 'Audit trail', plans: ['enterprise'] },
  { feature: 'Priority support and setup help', plans: ['enterprise'] },
]

const CAD = new Intl.NumberFormat('en-CA', { style: 'currency', currency: 'CAD' })

export function formatCad(amount: number): string {
  return CAD.format(amount)
}
