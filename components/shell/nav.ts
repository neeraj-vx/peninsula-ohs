import type { ComponentType } from 'react'
import {
  Home,
  TaskComplete,
  WarningAlt,
  Education,
  UserMultiple,
  Document,
  Apps,
  Settings,
} from '@carbon/icons-react'

// Who sees what. Roles come from user_roles → roles.name.
export type Audience = 'everyone' | 'supervisor' | 'manager' | 'admin'

export interface NavPage {
  label: string
  href: string
  /** Shown under the module only while the user is inside it */
  children?: { label: string; href: string }[]
  audience?: Audience
}

export interface NavSection {
  label: string
  icon: ComponentType<{ size?: number }>
  /** A single-page section renders as a plain link */
  href?: string
  pages?: NavPage[]
  audience?: Audience
  /** Collapsed unless the user is inside one of its pages */
  collapsed?: boolean
  /** Links to a launcher page; the sidebar lists only the page the user is in */
  launcher?: boolean
}

export const REPORT_OPTIONS = [
  { label: 'Report an incident', description: 'Injury, near miss or damage', href: '/incidents/new' },
  { label: 'Report a hazard', description: 'Something that could hurt someone', href: '/hazards/new' },
  { label: 'Raise a concern', description: 'Confidential speak-up report', href: '/speak-up/new' },
]

export interface ToolGroup {
  label: string
  tools: (NavPage & { description: string })[]
}

// Everything that isn't part of the everyday flow lives on /tools, grouped and
// described, instead of as a long list in the sidebar
export const TOOL_GROUPS: ToolGroup[] = [
  {
    label: 'Plan and control work',
    tools: [
      { label: 'Job safety analysis', href: '/jsa', description: 'Break a job into steps and plan controls for each hazard.' },
      { label: 'Permits to work', href: '/permits', description: 'Approve high-risk work such as hot work or confined spaces.' },
      { label: 'Lockout / tagout', href: '/loto', audience: 'supervisor', description: 'Isolation procedures for machinery and energy sources.' },
      { label: 'Toolbox talks', href: '/toolbox', description: 'Short safety briefings with attendance sign-off.' },
    ],
  },
  {
    label: 'Check and improve',
    tools: [
      { label: 'Investigations', href: '/investigations', audience: 'supervisor', description: 'Find root causes and agree corrective actions.' },
      { label: 'Audits', href: '/audits', audience: 'supervisor', description: 'Scheduled audits against your standards.' },
      { label: 'Speak-up reports', href: '/speak-up', audience: 'manager', description: 'Confidential concerns raised by staff.' },
      {
        label: 'Reports & KPIs', href: '/reports', audience: 'manager', description: 'Injury rates, trends and custom reports.',
        children: [{ label: 'Report builder', href: '/reports/builder' }],
      },
    ],
  },
  {
    label: 'Compliance',
    tools: [
      { label: 'Compliance calendar', href: '/compliance-calendar', audience: 'manager', description: 'Recurring legal obligations and due dates.' },
      { label: 'Regulatory library', href: '/regulatory', audience: 'manager', description: 'The legislation and regulators that apply to you.' },
      { label: 'Chemicals (WHMIS)', href: '/chemicals', description: 'Safety data sheets and chemical inventory.' },
    ],
  },
  {
    label: 'Equipment',
    tools: [
      { label: 'Assets', href: '/assets', audience: 'supervisor', description: 'Equipment register and inspection status.' },
      { label: 'Maintenance', href: '/maintenance', audience: 'supervisor', description: 'Servicing history and upcoming maintenance.' },
      { label: 'PPE', href: '/ppe', audience: 'supervisor', description: 'Protective equipment stock, issues and fit tests.' },
    ],
  },
  {
    label: 'Health and wellbeing',
    tools: [
      { label: 'Health surveillance', href: '/health', audience: 'manager', description: 'Medical monitoring for exposed workers.' },
      { label: 'Fatigue', href: '/fatigue', audience: 'supervisor', description: 'Hours-of-work rules and fatigue checks.' },
      { label: 'Wellbeing', href: '/wellbeing', description: 'Support resources for your people.' },
    ],
  },
  {
    label: 'Sites, contractors and emergencies',
    tools: [
      {
        label: 'Contractors', href: '/contractors', audience: 'supervisor', description: 'Contractor companies, their workers and site sign-in.',
        children: [
          { label: 'Contractor workers', href: '/contractors/workers' },
          { label: 'Site access log', href: '/contractors/access-log' },
        ],
      },
      {
        label: 'Emergency', href: '/emergency', description: 'Response plans, wardens, muster points and drills.',
        children: [
          { label: 'Response plans', href: '/emergency/plans' },
          { label: 'Drills', href: '/emergency/drills' },
          { label: 'Wardens', href: '/emergency/wardens' },
          { label: 'Muster points', href: '/emergency/muster-points' },
          { label: 'Activations', href: '/emergency/activations' },
        ],
      },
      { label: 'Environment', href: '/environment', audience: 'manager', description: 'Noise, dust and other monitoring results.' },
      { label: 'Environmental reporting', href: '/env-reporting', audience: 'manager', description: 'Regulatory environmental reports and deadlines.' },
    ],
  },
]

export const NAV: NavSection[] = [
  { label: 'Home', icon: Home, href: '/dashboard' },
  { label: 'My tasks', icon: TaskComplete, href: '/actions' },
  {
    label: 'Safety',
    icon: WarningAlt,
    pages: [
      { label: 'Incidents', href: '/incidents' },
      { label: 'Hazards', href: '/hazards' },
      { label: 'Risks', href: '/risks', audience: 'supervisor', children: [{ label: 'Risk templates', href: '/risks/templates' }] },
      { label: 'Inspections', href: '/inspections', audience: 'supervisor' },
    ],
  },
  {
    label: 'Training',
    icon: Education,
    collapsed: true,
    pages: [
      { label: 'Overview', href: '/training' },
      { label: 'Training records', href: '/training/records' },
      { label: 'Required training', href: '/training/requirements', audience: 'manager' },
      { label: 'Courses', href: '/training/courses', audience: 'manager' },
      { label: 'Inductions', href: '/training/inductions', audience: 'manager' },
    ],
  },
  {
    label: 'People',
    icon: UserMultiple,
    audience: 'manager',
    collapsed: true,
    pages: [
      { label: 'Workers', href: '/workers' },
      {
        label: 'Hiring', href: '/hiring',
        children: [
          { label: 'Onboarding', href: '/hiring/onboarding' },
          { label: 'Document templates', href: '/hiring/templates' },
          { label: 'Onboarding templates', href: '/hiring/onboarding/templates' },
        ],
      },
      {
        label: 'Background checks', href: '/background-checks',
        children: [
          { label: 'Packages', href: '/background-checks/packages' },
          { label: 'References', href: '/background-checks/reference-checks' },
          { label: 'Licences', href: '/background-checks/licences' },
          { label: 'Settings', href: '/background-checks/settings' },
        ],
      },
    ],
  },
  {
    label: 'Documents',
    icon: Document,
    collapsed: true,
    pages: [
      { label: 'All documents', href: '/documents' },
      { label: 'Review workflows', href: '/documents/workflows', audience: 'manager' },
    ],
  },
  {
    label: 'More tools',
    icon: Apps,
    href: '/tools',
    launcher: true,
    pages: TOOL_GROUPS.flatMap((g) => g.tools),
  },
  {
    label: 'Settings',
    icon: Settings,
    audience: 'admin',
    collapsed: true,
    pages: [
      { label: 'Organisation', href: '/settings/organisation' },
      { label: 'Sites & departments', href: '/settings/sites' },
      { label: 'Users & roles', href: '/settings/users' },
      { label: 'Notifications', href: '/settings/notifications' },
      { label: 'Document settings', href: '/settings/documents' },
      { label: 'Integrations', href: '/settings/integrations' },
    ],
  },
]

export function audienceFor(roles: string[]): Audience {
  if (roles.includes('System Admin')) return 'admin'
  if (roles.includes('HSE Officer') || roles.includes('Executive')) return 'manager'
  if (roles.includes('Supervisor')) return 'supervisor'
  return 'everyone'
}

const RANK: Record<Audience, number> = { everyone: 0, supervisor: 1, manager: 2, admin: 3 }

export function canSee(user: Audience, required: Audience = 'everyone') {
  return RANK[user] >= RANK[required]
}

export function isUnder(pathname: string, href: string) {
  return pathname === href || pathname.startsWith(href + '/')
}
