// Plain-language introductions shown the first time someone opens a screen.
// Keyed by route. Keep descriptions to 2–3 short sentences and 2–4 points.

export type IntroPreview =
  | 'table'
  | 'list'
  | 'form'
  | 'cards'
  | 'calendar'
  | 'checklist'
  | 'chart'
  | 'matrix'
  | 'steps'
  | 'pipeline'
  | 'settings'
  | 'people'
  | 'dashboard'

export interface PageIntroContent {
  title: string
  description: string
  points: string[]
  preview: IntroPreview
  /** Accent colour used in the preview. Defaults to Carbon blue. */
  accent?: string
}

const RED = '#da1e28'
const ORANGE = '#ff832b'
const BLUE = '#0f62fe'
const GREEN = '#198038'
const PURPLE = '#8a3ffc'
const TEAL = '#007d79'
const MAGENTA = '#d02670'
const GREY = '#525252'

export const PAGE_INTROS: Record<string, PageIntroContent> = {
  // ── Everyday ───────────────────────────────────────────────
  '/dashboard': {
    title: 'Your home page',
    description:
      'This is where you start each day. It shows the tasks waiting for you and what has been happening on site lately.',
    points: [
      'See the tasks assigned to you',
      'Report an incident, hazard or concern in a couple of clicks',
      'Check the latest incidents and open items',
    ],
    preview: 'dashboard',
    accent: BLUE,
  },
  '/actions': {
    title: 'My tasks',
    description:
      'Every follow-up job lands here, whether it came from an incident, an inspection or a meeting. Each task has an owner and a due date so nothing gets forgotten.',
    points: [
      'See what you need to do and by when',
      'Mark a task as done or update its progress',
      'Add a new task for yourself or someone else',
    ],
    preview: 'checklist',
    accent: BLUE,
  },

  // ── Safety ─────────────────────────────────────────────────
  '/incidents': {
    title: 'Incidents',
    description:
      'An incident is anything that went wrong: someone got hurt, nearly got hurt (a near miss), or property was damaged. Reporting it quickly helps stop it happening again and meets your provincial OHS reporting duties.',
    points: [
      'Report an injury, near miss or damage',
      'Track each incident from report to closed',
      'Open an incident to see details, actions and investigation',
    ],
    preview: 'table',
    accent: RED,
  },
  '/hazards': {
    title: 'Hazard reports',
    description:
      'A hazard is something that could hurt someone but has not yet, like a spill, a broken guard or a frayed cord. Anyone can report one, and a supervisor makes sure it gets fixed.',
    points: [
      'Report a hazard you have spotted',
      'See which hazards are still open',
      'Follow up on what was done to fix them',
    ],
    preview: 'list',
    accent: ORANGE,
  },
  '/risks': {
    title: 'Risk register',
    description:
      'A list of the known risks in your workplace, how likely and how serious each one is, and what you do to control it. It helps you focus on the biggest dangers first.',
    points: [
      'Add a risk and rate it on likelihood and severity',
      'Record the controls that keep people safe',
      'Review risks regularly and see which are rated high',
    ],
    preview: 'matrix',
    accent: ORANGE,
  },
  '/risks/templates': {
    title: 'Risk templates',
    description:
      'Ready-made starting points for common risks, with typical hazards, controls and ratings already filled in. Pick one, then adjust it to suit your site.',
    points: [
      'Browse templates by category',
      'Start a new risk from a template',
      'Save time instead of starting from a blank page',
    ],
    preview: 'cards',
    accent: ORANGE,
  },
  '/inspections': {
    title: 'Inspections',
    description:
      'Regular walk-around checks of your site, equipment or vehicles using a checklist. Problems found during an inspection can be turned into tasks to fix.',
    points: [
      'Start an inspection from a checklist',
      'See past inspections and their results',
      'Follow up on items that failed',
    ],
    preview: 'checklist',
    accent: TEAL,
  },
  '/inspections/schedules': {
    title: 'Inspection schedules',
    description:
      'Set inspections to repeat automatically, such as a weekly forklift check or a monthly first aid kit check. The right person is reminded when one is due.',
    points: [
      'Create a repeating inspection',
      'Choose how often and who does it',
      'See what is coming up and what is overdue',
    ],
    preview: 'calendar',
    accent: TEAL,
  },
  '/inspections/templates': {
    title: 'Inspection checklists',
    description:
      'The checklists used for inspections. Build them once, then use them every time so everyone checks the same things.',
    points: [
      'Create or edit a checklist',
      'Add questions, pass/fail items and photo prompts',
      'Turn a checklist on or off',
    ],
    preview: 'form',
    accent: TEAL,
  },

  // ── Training ───────────────────────────────────────────────
  '/training': {
    title: 'Training overview',
    description:
      'A quick look at who is trained, what is coming up and what is about to expire. It helps you keep everyone qualified for the work they do.',
    points: [
      'See overdue and expiring training at a glance',
      'Log training someone has completed',
      'Jump to records, courses and inductions',
    ],
    preview: 'dashboard',
    accent: PURPLE,
  },
  '/training/records': {
    title: 'Training records',
    description:
      'Proof of the training each person has done, with dates and certificates. Inspectors and auditors often ask to see these.',
    points: [
      'Log completed training and attach a certificate',
      'Search records by person or course',
      'Spot certificates that are about to expire',
    ],
    preview: 'table',
    accent: PURPLE,
  },
  '/training/courses': {
    title: 'Course library',
    description:
      'All the courses people can take, including common Canadian ones like WHMIS 2015 and first aid, plus any you add yourself.',
    points: [
      'Browse the built-in courses for your province',
      'Add your own in-house course',
      'Set how long a certificate stays valid',
    ],
    preview: 'cards',
    accent: PURPLE,
  },
  '/training/inductions': {
    title: 'Inductions',
    description:
      'An induction is the safety introduction a new worker or visitor gets before starting, like where the exits are and the site rules. Set up a program once and use it for every new starter.',
    points: [
      'Create an induction program',
      'Choose the topics it covers',
      'Track who has completed it',
    ],
    preview: 'steps',
    accent: PURPLE,
  },
  '/training/requirements': {
    title: 'Training requirements',
    description:
      'Decide which courses each role must complete. Everyone in that role is assigned the course, and refreshers are assigned before certificates expire.',
    points: [
      'Link a course to a job role',
      'Assign training automatically to new starters',
      'Keep refresher training on schedule',
    ],
    preview: 'checklist',
    accent: PURPLE,
  },

  // ── People ─────────────────────────────────────────────────
  '/workers': {
    title: 'Workers',
    description:
      'A profile for each person who works for you. It brings together their role, site, training and safety history in one place.',
    points: [
      'Add a new worker',
      'Search for someone and open their profile',
      'See their training and certificates',
    ],
    preview: 'people',
    accent: BLUE,
  },
  '/hiring': {
    title: 'Hiring',
    description:
      'Follow each new hire from offer to first day. EXXIO knows the rules for your province and prepares the paperwork for you.',
    points: [
      'Start a new hire',
      'See where each candidate is in the process',
      'Create offer letters and other documents',
    ],
    preview: 'pipeline',
    accent: BLUE,
  },
  '/hiring/onboarding': {
    title: 'Onboarding',
    description:
      'The checklist of things a new starter needs to finish in their first days and weeks, like signing forms and doing their induction.',
    points: [
      'See each new starter’s progress',
      'Tick off onboarding steps as they are done',
      'Spot anyone who is falling behind',
    ],
    preview: 'checklist',
    accent: BLUE,
  },
  '/hiring/templates': {
    title: 'HR document templates',
    description:
      'Templates for offer letters, contracts and other hiring paperwork. EXXIO fills in the person’s details for you.',
    points: [
      'Use the built-in templates',
      'Create your own template',
      'Edit the wording to suit your organisation',
    ],
    preview: 'form',
    accent: BLUE,
  },
  '/hiring/onboarding/templates': {
    title: 'Onboarding templates',
    description:
      'A standard set of onboarding steps you can reuse for every new hire, so each person gets the same good start.',
    points: [
      'Create an onboarding template',
      'Add the steps and who is responsible',
      'Use different templates for different roles',
    ],
    preview: 'steps',
    accent: BLUE,
  },
  '/background-checks': {
    title: 'Background checks',
    description:
      'Checks done before or during employment, such as criminal record, reference and licence checks. Only people who need to see the results can.',
    points: [
      'See the status of every check',
      'Spot checks that are waiting or flagged',
      'Open a check to see the result',
    ],
    preview: 'table',
    accent: GREY,
  },
  '/background-checks/packages': {
    title: 'Check packages',
    description:
      'A package is the group of checks ordered for one candidate. Packages are created for you when you start a new hire.',
    points: [
      'See every package and its progress',
      'Open a package to see each check inside it',
    ],
    preview: 'list',
    accent: GREY,
  },
  '/background-checks/reference-checks': {
    title: 'Reference checks',
    description:
      'Short questionnaires sent to the referees a candidate gave you. Answers come back here so you can review them in one place.',
    points: [
      'See which references are waiting and which are back',
      'Read the referee’s answers',
      'Manage the questions you send',
    ],
    preview: 'list',
    accent: GREY,
  },
  '/background-checks/licences': {
    title: 'Worker licences',
    description:
      'Keep track of the licences and tickets people need for their job, like a driver’s licence or forklift ticket. You are warned before one expires.',
    points: [
      'See which licences are valid, expiring or expired',
      'Add or update a licence',
      'Get reminders before expiry',
    ],
    preview: 'table',
    accent: GREY,
  },
  '/background-checks/settings': {
    title: 'Background check settings',
    description:
      'Choose which checks each role needs, which provider runs them and how often they are repeated.',
    points: [
      'Connect a background check provider',
      'Set required checks for each role',
      'Set how often checks are redone',
    ],
    preview: 'settings',
    accent: GREY,
  },

  // ── Documents ──────────────────────────────────────────────
  '/documents': {
    title: 'Documents',
    description:
      'Your safety policies, procedures and forms, all in one place. Everyone sees the latest approved version, so nobody works from an old copy.',
    points: [
      'Find and open a document',
      'Upload a new document',
      'See when each document is due for review',
    ],
    preview: 'list',
    accent: BLUE,
  },
  '/documents/workflows': {
    title: 'Review workflows',
    description:
      'A workflow sets who has to check and approve a document before it is published. It keeps important documents reviewed on time.',
    points: [
      'Create an approval workflow',
      'Choose the reviewers and the order',
      'See which reviews are in progress',
    ],
    preview: 'steps',
    accent: BLUE,
  },

  // ── Tools: plan and control work ───────────────────────────
  '/jsa': {
    title: 'Job safety analysis (JSA)',
    description:
      'A JSA breaks a job into simple steps, lists what could go wrong at each step, and how you will keep people safe. Do one before risky or unfamiliar work.',
    points: [
      'Create a JSA for a job',
      'List the steps, hazards and controls',
      'Have the crew review and sign it',
    ],
    preview: 'steps',
    accent: ORANGE,
  },
  '/permits': {
    title: 'Permits to work',
    description:
      'A permit is written approval to do high-risk work, like welding (hot work), working at heights or entering a confined space. It makes sure the right checks are done first.',
    points: [
      'Request a permit for a job',
      'Approve, extend or close permits',
      'See which permits are active right now',
    ],
    preview: 'form',
    accent: RED,
  },
  '/loto': {
    title: 'Lockout / tagout (LOTO)',
    description:
      'LOTO is how you shut off and lock a machine’s power so it cannot start while someone is working on it. This screen holds the step-by-step procedure for each machine, in line with CSA Z460.',
    points: [
      'Create a lockout procedure for a machine',
      'List each energy source and how to isolate it',
      'Print or share the procedure for the crew',
    ],
    preview: 'steps',
    accent: RED,
  },
  '/toolbox': {
    title: 'Toolbox talks',
    description:
      'A toolbox talk is a short safety chat with the crew, usually at the start of a shift. Record who attended so you have proof it happened.',
    points: [
      'Deliver a talk and take attendance',
      'Pick a topic from the template library',
      'Schedule talks ahead of time',
    ],
    preview: 'cards',
    accent: GREEN,
  },
  '/toolbox/history': {
    title: 'Talk history',
    description: 'Every toolbox talk that has been given, with the date, topic and who attended.',
    points: ['Find a past talk', 'See who attended', 'Show proof of training to an inspector'],
    preview: 'table',
    accent: GREEN,
  },
  '/toolbox/schedule': {
    title: 'Talk schedule',
    description: 'Plan toolbox talks ahead of time so the right topics are covered regularly.',
    points: ['Schedule an upcoming talk', 'Choose who will lead it', 'See what is planned this week'],
    preview: 'calendar',
    accent: GREEN,
  },
  '/toolbox/templates': {
    title: 'Talk templates',
    description: 'Ready-to-use talk topics with key points, so anyone can lead a good safety chat.',
    points: ['Browse talk topics', 'Write your own topic', 'Turn topics on or off'],
    preview: 'cards',
    accent: GREEN,
  },

  // ── Tools: check and improve ───────────────────────────────
  '/investigations': {
    title: 'Investigations',
    description:
      'After a serious incident, an investigation looks for why it really happened (the root cause), not just who was involved. The goal is to fix the cause so it does not happen again.',
    points: [
      'See open and closed investigations',
      'Record what happened and why',
      'Agree corrective actions and assign them',
    ],
    preview: 'steps',
    accent: RED,
  },
  '/audits': {
    title: 'Audits',
    description:
      'An audit is a planned, more detailed check that your safety program is working as it should. Findings become tasks to improve.',
    points: [
      'Schedule an audit',
      'Complete it using a template',
      'Track the findings to closure',
    ],
    preview: 'checklist',
    accent: TEAL,
  },
  '/audits/templates': {
    title: 'Audit templates',
    description: 'The question sets used for audits. Build them once so every audit checks the same standard.',
    points: ['Create an audit template', 'Add sections and questions', 'Reuse it for future audits'],
    preview: 'form',
    accent: TEAL,
  },
  '/speak-up': {
    title: 'Speak-up reports',
    description:
      'A safe, confidential way for people to raise a concern, such as unsafe work, harassment or wrongdoing. Reporters can stay anonymous, and only authorised people can see the reports.',
    points: [
      'Raise a concern confidentially',
      'Review and respond to reports',
      'Track each report until it is resolved',
    ],
    preview: 'list',
    accent: MAGENTA,
  },
  '/reports': {
    title: 'Reports and KPIs',
    description:
      'Numbers and charts that show how safety is going over time, such as incident counts and injury rates (TRIR and LTIR). Use them to spot trends and report to leadership.',
    points: [
      'See key safety numbers at a glance',
      'Look at trends month by month',
      'Export or schedule reports',
    ],
    preview: 'chart',
    accent: BLUE,
  },
  '/reports/builder': {
    title: 'Report builder',
    description: 'Make your own report by choosing the information and filters you need. Save it to run again any time.',
    points: ['Create a custom report', 'Choose columns and filters', 'Save and rerun reports'],
    preview: 'form',
    accent: BLUE,
  },

  // ── Tools: compliance ──────────────────────────────────────
  '/compliance-calendar': {
    title: 'Compliance calendar',
    description:
      'The legal tasks you must do on a regular basis, like joint health and safety committee meetings or equipment certifications, with their due dates.',
    points: [
      'Add a recurring obligation',
      'See what is due soon or overdue',
      'Mark an obligation as complete',
    ],
    preview: 'calendar',
    accent: PURPLE,
  },
  '/regulatory': {
    title: 'Regulatory library',
    description:
      'The provincial OHS laws, regulations and CSA standards that apply to your organisation, and who the regulator is. A handy reference when you are unsure what the rules say.',
    points: [
      'Browse the laws and standards that apply to you',
      'Add a standard your organisation follows',
      'Link to the official text',
    ],
    preview: 'list',
    accent: PURPLE,
  },
  '/chemicals': {
    title: 'Chemicals (WHMIS)',
    description:
      'A list of the chemicals on site with their safety data sheets (SDS). Under WHMIS 2015, workers must be able to find the SDS for any hazardous product they use.',
    points: [
      'Add a chemical and attach its SDS',
      'See where each chemical is stored',
      'Check hazards and safe handling advice',
    ],
    preview: 'table',
    accent: ORANGE,
  },

  // ── Tools: equipment ───────────────────────────────────────
  '/assets': {
    title: 'Assets',
    description:
      'A register of your equipment, tools and vehicles. See what you have, where it is and whether it is safe to use.',
    points: [
      'Add a piece of equipment',
      'See inspection and service status',
      'Take equipment out of service when it is unsafe',
    ],
    preview: 'table',
    accent: TEAL,
  },
  '/maintenance': {
    title: 'Maintenance',
    description:
      'Records of servicing and repairs on your equipment, and what is coming up next. Well-maintained equipment is safer equipment.',
    points: [
      'Log a service or repair',
      'See upcoming and overdue maintenance',
      'Look up an asset’s history',
    ],
    preview: 'calendar',
    accent: TEAL,
  },
  '/ppe': {
    title: 'PPE',
    description:
      'PPE means personal protective equipment, like hard hats, safety boots, gloves and respirators. Track what is issued to whom and when fit tests are due, following CSA standards.',
    points: [
      'Record PPE issued to a worker',
      'Track respirator fit tests',
      'Keep an eye on stock levels',
    ],
    preview: 'table',
    accent: ORANGE,
  },

  // ── Tools: health and wellbeing ────────────────────────────
  '/health': {
    title: 'Health surveillance',
    description:
      'Regular medical checks for people exposed to things like noise, dust or chemicals, such as hearing tests. It helps catch health effects early.',
    points: [
      'Record a health check',
      'See who is due for their next check',
      'Keep results private and secure',
    ],
    preview: 'table',
    accent: MAGENTA,
  },
  '/fatigue': {
    title: 'Fatigue',
    description:
      'Tired workers make more mistakes. Log shifts and hours so you can spot when someone has worked too long without rest.',
    points: [
      'Log a shift or hours worked',
      'Check against hours-of-work rules',
      'Spot people at risk of fatigue',
    ],
    preview: 'chart',
    accent: MAGENTA,
  },
  '/wellbeing': {
    title: 'Wellbeing',
    description:
      'Support for mental and physical health at work. Find help resources and share how you are feeling through anonymous check-ins.',
    points: [
      'Find support and help lines',
      'Do an anonymous wellbeing check-in',
      'See overall team wellbeing trends',
    ],
    preview: 'cards',
    accent: MAGENTA,
  },

  // ── Tools: sites, contractors and emergencies ──────────────
  '/environment': {
    title: 'Environmental monitoring',
    description:
      'Results from measuring things like noise, dust and air quality at your sites. Compare them with safe limits to protect people.',
    points: [
      'Record a monitoring reading',
      'See readings that are over the limit',
      'Track results over time',
    ],
    preview: 'chart',
    accent: GREEN,
  },
  '/env-reporting': {
    title: 'Environmental reporting',
    description:
      'Reports you must send to environmental regulators and their due dates, so you never miss a deadline.',
    points: [
      'Add a reporting obligation',
      'See what is due soon',
      'Record when a report was submitted',
    ],
    preview: 'calendar',
    accent: GREEN,
  },
  '/contractors': {
    title: 'Contractors',
    description:
      'The outside companies that work on your sites. Check they have the right insurance, WSIB/WCB coverage and training before they start.',
    points: [
      'Add a contractor company',
      'Check their documents are current',
      'See their workers and site visits',
    ],
    preview: 'cards',
    accent: BLUE,
  },
  '/contractors/workers': {
    title: 'Contractor workers',
    description:
      'Everyone who works for your contractors, across all companies. To add someone, open their company’s profile.',
    points: ['Find a contractor worker', 'Check their inductions and tickets', 'Open their company profile'],
    preview: 'people',
    accent: BLUE,
  },
  '/contractors/access-log': {
    title: 'Site access log',
    description:
      'A record of contractor workers signing in and out of your sites. In an emergency, it tells you who is on site.',
    points: ['Sign a contractor in or out', 'See who is on site right now', 'Look back at past visits'],
    preview: 'list',
    accent: BLUE,
  },
  '/emergency': {
    title: 'Emergency management',
    description:
      'Everything you need to be ready for an emergency like a fire, spill or medical event. Plans, wardens, muster points and drills are all here.',
    points: [
      'Check that your plans are up to date',
      'See your wardens and muster points',
      'Record drills and real emergencies',
    ],
    preview: 'dashboard',
    accent: RED,
  },
  '/emergency/plans': {
    title: 'Emergency response plans',
    description: 'Written plans that say what to do in each kind of emergency, and who does what.',
    points: ['Create or update a plan', 'Set a review date', 'Share the plan with your team'],
    preview: 'list',
    accent: RED,
  },
  '/emergency/drills': {
    title: 'Emergency drills',
    description:
      'Practice runs, like a fire drill, so people know what to do for real. Record how it went and what to improve.',
    points: ['Schedule a drill', 'Record the results and timing', 'Note lessons learned'],
    preview: 'calendar',
    accent: RED,
  },
  '/emergency/wardens': {
    title: 'Emergency wardens',
    description:
      'Wardens are the people who guide everyone to safety during an emergency. Make sure every area has one.',
    points: ['Assign a warden to an area', 'See who covers each site', 'Check their training is current'],
    preview: 'people',
    accent: RED,
  },
  '/emergency/muster-points': {
    title: 'Muster points',
    description:
      'A muster point is the safe place everyone gathers after leaving the building, so you can count heads.',
    points: ['Add a muster point for a site', 'Describe where it is', 'Keep the list up to date'],
    preview: 'cards',
    accent: RED,
  },
  '/emergency/activations': {
    title: 'Emergency activations',
    description: 'A record of real emergencies: when they started, what happened and when they were over.',
    points: ['Start an emergency activation', 'Record what happened', 'Close it when the emergency is over'],
    preview: 'list',
    accent: RED,
  },

  // ── Settings ───────────────────────────────────────────────
  '/settings/organisation': {
    title: 'Organisation settings',
    description:
      'Your organisation’s basic details, like its name, industry, province and contact information. Many other screens use these settings.',
    points: ['Update your organisation name and industry', 'Set your province or territory and time zone', 'Keep contact details current'],
    preview: 'settings',
    accent: GREY,
  },
  '/settings/sites': {
    title: 'Sites and departments',
    description: 'The places you work and the teams within them. Incidents, workers and inspections are linked to these.',
    points: ['Add a site or department', 'Edit site details', 'Organise teams by site'],
    preview: 'list',
    accent: GREY,
  },
  '/settings/users': {
    title: 'Users and roles',
    description:
      'Who can log in to EXXIO and what they are allowed to do. A role, like Supervisor or HSE Officer, decides which screens a person sees.',
    points: ['Invite a new user', 'Change someone’s role', 'Remove access when someone leaves'],
    preview: 'people',
    accent: GREY,
  },
  '/settings/notifications': {
    title: 'Notifications',
    description: 'Choose which events send an alert, like a new incident, and who gets told.',
    points: ['Turn alerts on or off', 'Choose who receives each alert', 'Pick email or in-app alerts'],
    preview: 'settings',
    accent: GREY,
  },
  '/settings/documents': {
    title: 'Document settings',
    description: 'How documents and e-signatures work for your organisation.',
    points: ['Choose how documents must be signed', 'Set how e-signatures work for your team'],
    preview: 'settings',
    accent: GREY,
  },
  '/settings/integrations': {
    title: 'Integrations',
    description: 'Connect EXXIO to other systems you use, such as HR software. This is usually set up by your IT team.',
    points: ['See which systems are connected', 'Manage webhooks (automatic messages to other systems)', 'Create or remove API keys'],
    preview: 'settings',
    accent: GREY,
  },

  // ── Launcher ───────────────────────────────────────────────
  '/tools': {
    title: 'More tools',
    description:
      'Everything else EXXIO can do, grouped by purpose. You will not need most of these every day, so open one when it fits your work.',
    points: [
      'Browse tools by group',
      'Read a one-line description of each tool',
      'Open a tool to get started',
    ],
    preview: 'cards',
    accent: BLUE,
  },
}
