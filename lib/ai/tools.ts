import { tool } from 'ai'
import { z } from 'zod'
import type { SupabaseClient } from '@supabase/supabase-js'
import { TABLES, TABLE_NAMES } from './catalogue'
import type { AssistantContext } from './context'
import { FILE_SOURCES, readRecordFile, type FileReadResult } from './files'
import { textToPdf } from './pdf'
import { supabaseAdmin } from '@/lib/supabase/admin'
import { getStoragePath } from '@/lib/storage/paths'

const MAX_ROWS = 100

const filterSchema = z.object({
  column: z.string().describe('Column name. For an embedded table use "table.column".'),
  op: z.enum(['eq', 'neq', 'gt', 'gte', 'lt', 'lte', 'like', 'ilike', 'in', 'is', 'contains']),
  value: z
    .union([z.string(), z.number(), z.boolean(), z.null(), z.array(z.union([z.string(), z.number()]))])
    .describe('For "in"/"contains" pass an array. For "is" pass null, true or false. ilike uses % wildcards.'),
})
type Filter = z.infer<typeof filterSchema>

const tableEnum = z.enum(TABLE_NAMES)

// Columns and select strings: identifiers, commas, embeds like incident_types(name), aliases and "*"
const SELECT_RE = /^[a-zA-Z0-9_,:*()!.\s]+$/
const COLUMN_RE = /^[a-zA-Z0-9_.]+$/

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function applyFilters(query: any, filters: Filter[] = []) {
  for (const f of filters) {
    if (!COLUMN_RE.test(f.column)) throw new Error(`Invalid column: ${f.column}`)
    switch (f.op) {
      case 'in':
        query = query.in(f.column, Array.isArray(f.value) ? f.value : [f.value])
        break
      case 'contains':
        query = query.contains(f.column, Array.isArray(f.value) ? f.value : [f.value])
        break
      case 'is':
        query = query.is(f.column, f.value as null | boolean)
        break
      default:
        query = query[f.op](f.column, f.value)
    }
  }
  return query
}

function link(table: string, id: unknown): string | undefined {
  const route = TABLES[table]?.route
  return route && typeof id === 'string' ? route.replace('{id}', id) : undefined
}

function withLinks(table: string, rows: Record<string, unknown>[]) {
  if (!TABLES[table]?.route) return rows
  return rows.map((r) => ({ ...r, _link: link(table, r.id) }))
}

function today() {
  return new Date().toISOString().slice(0, 10)
}

export function buildTools(supabase: SupabaseClient, ctx: AssistantContext) {
  return {
    queryRecords: tool({
      description:
        'Read records from any table in the data catalogue. Runs with the user\'s own permissions. Use embeds in `select` to resolve lookups, e.g. "id,title,status,incident_types(name),severity_levels(name)". Rows include a _link to open the record in the app when one exists.',
      inputSchema: z.object({
        table: tableEnum,
        select: z.string().optional().describe('PostgREST select string. Defaults to all columns.'),
        filters: z.array(filterSchema).optional(),
        orderBy: z.string().optional(),
        ascending: z.boolean().optional(),
        limit: z.number().int().min(1).max(MAX_ROWS).optional().describe('Default 25, max 100.'),
      }),
      execute: async ({ table, select, filters, orderBy, ascending, limit }) => {
        // _link is added to results, not a real column
        select = select?.split(',').map((c) => c.trim()).filter((c) => c && c !== '_link').join(',') || undefined
        if (select && !SELECT_RE.test(select)) return { error: 'Invalid select string.' }
        if (orderBy && !COLUMN_RE.test(orderBy)) return { error: 'Invalid orderBy column.' }
        try {
          let q = supabase.from(table).select(select || '*', { count: 'exact' })
          q = applyFilters(q, filters)
          if (orderBy) q = q.order(orderBy, { ascending: ascending ?? false })
          const { data, error, count } = await q.limit(limit ?? 25)
          if (error) return { error: error.message, hint: error.hint ?? undefined }
          const rows = (data ?? []) as unknown as Record<string, unknown>[]
          return { totalMatching: count, returned: rows.length, rows: withLinks(table, rows) }
        } catch (e) {
          return { error: (e as Error).message }
        }
      },
    }),

    countRecords: tool({
      description:
        'Count records in a table, optionally grouped by one column (e.g. status, priority, severity_level_id). Use this for statistics, trends and dashboards instead of fetching rows.',
      inputSchema: z.object({
        table: tableEnum,
        filters: z.array(filterSchema).optional(),
        groupBy: z.string().optional().describe('A plain column on the table.'),
      }),
      execute: async ({ table, filters, groupBy }) => {
        try {
          if (!groupBy) {
            const { count, error } = await applyFilters(supabase.from(table).select('id', { count: 'exact', head: true }), filters)
            if (error) return { error: error.message }
            return { count }
          }
          if (!COLUMN_RE.test(groupBy)) return { error: 'Invalid groupBy column.' }
          const { data, error } = await applyFilters(supabase.from(table).select(groupBy), filters).limit(5000)
          if (error) return { error: error.message }
          const groups: Record<string, number> = {}
          for (const row of (data ?? []) as Record<string, unknown>[]) {
            const key = String(row[groupBy] ?? '(none)')
            groups[key] = (groups[key] ?? 0) + 1
          }
          return { total: (data ?? []).length, groups, note: (data ?? []).length === 5000 ? 'Capped at 5000 rows.' : undefined }
        } catch (e) {
          return { error: (e as Error).message }
        }
      },
    }),

    getRecord: tool({
      description: 'Fetch one record by id with all columns, plus optional embeds of related tables.',
      inputSchema: z.object({
        table: tableEnum,
        id: z.string().uuid(),
        select: z.string().optional(),
      }),
      execute: async ({ table, id, select }) => {
        if (select && !SELECT_RE.test(select)) return { error: 'Invalid select string.' }
        const { data, error } = await supabase.from(table).select(select || '*').eq('id', id).maybeSingle()
        if (error) return { error: error.message }
        if (!data) return { error: 'Not found, or you do not have access.' }
        return { record: data, _link: link(table, id) }
      },
    }),

    findPeople: tool({
      description: 'Find people in the organisation by name, email or job title. Use to resolve a name to a user id before assigning or filtering.',
      inputSchema: z.object({ query: z.string().min(1) }),
      execute: async ({ query }) => {
        const term = `%${query.replace(/[%,()]/g, ' ').trim()}%`
        const { data, error } = await supabase
          .from('user_profiles')
          .select('id, first_name, last_name, email, job_title, is_active')
          .or(`first_name.ilike.${term},last_name.ilike.${term},email.ilike.${term},job_title.ilike.${term},display_name.ilike.${term}`)
          .limit(15)
        if (error) return { error: error.message }
        return { people: withLinks('user_profiles', (data ?? []) as Record<string, unknown>[]) }
      },
    }),

    getMyWork: tool({
      description: "A snapshot of what needs the current user's attention: their open/overdue actions, outstanding training, unread notifications, and organisation-wide open incidents and hazards.",
      inputSchema: z.object({}),
      execute: async () => {
        const t = today()
        const [actions, overdue, training, notes, incidents, hazards] = await Promise.all([
          supabase.from('actions').select('id,action_number,title,priority,status,due_date').eq('assigned_to', ctx.userId).in('status', ['open', 'in_progress', 'reopened', 'overdue']).order('due_date').limit(20),
          supabase.from('actions').select('id', { count: 'exact', head: true }).eq('assigned_to', ctx.userId).in('status', ['open', 'in_progress', 'reopened', 'overdue']).lt('due_date', t),
          supabase.from('training_assignments').select('id,status,due_date,training_courses(name)').eq('worker_id', ctx.userId).not('status', 'in', '(completed,waived)').order('due_date').limit(20),
          supabase.from('notifications').select('id,title,body,created_at').eq('recipient_user_id', ctx.userId).eq('is_read', false).order('created_at', { ascending: false }).limit(10),
          supabase.from('incidents').select('id', { count: 'exact', head: true }).not('status', 'in', '(closed,cancelled)'),
          supabase.from('hazard_reports').select('id', { count: 'exact', head: true }).in('status', ['submitted', 'under_review']),
        ])
        return {
          myOpenActions: withLinks('actions', (actions.data ?? []) as Record<string, unknown>[]),
          myOverdueActionCount: overdue.count ?? 0,
          myOutstandingTraining: training.data ?? [],
          unreadNotifications: notes.data ?? [],
          orgOpenIncidentCount: incidents.count ?? 0,
          orgHazardsAwaitingReview: hazards.count ?? 0,
        }
      },
    }),

    createHazardReport: tool({
      description: 'Report a hazard on behalf of the user. The user is asked to approve before it is saved.',
      inputSchema: z.object({
        title: z.string().min(3),
        description: z.string().min(3),
        location_details: z.string().optional(),
        severity_perception: z.enum(['low', 'medium', 'high']).default('medium'),
        hazard_category: z.enum(['physical', 'chemical', 'electrical', 'biological', 'ergonomic', 'psychosocial', 'fire', 'environmental', 'other']).optional(),
        immediate_risk_to_people: z.boolean().default(false),
        suggested_control: z.string().optional(),
        site_id: z.string().uuid().optional(),
      }),
      execute: async (input) => {
        const { data, error } = await supabase
          .from('hazard_reports')
          .insert({ ...input, organisation_id: ctx.organisationId, reported_by: ctx.userId, observed_at: new Date().toISOString() })
          .select('id, report_number')
          .single()
        if (error) return { error: error.message }
        return { created: true, id: data.id, reportNumber: data.report_number, _link: `/hazards/${data.id}` }
      },
    }),

    createIncident: tool({
      description:
        'Submit an incident report. First look up a valid incident_type_id (and optionally severity_level_id) from incident_types / severity_levels. The user is asked to approve before it is saved.',
      inputSchema: z.object({
        title: z.string().min(3),
        description: z.string().min(3),
        incident_type_id: z.string().uuid(),
        severity_level_id: z.string().uuid().optional(),
        incident_date: z.string().describe('YYYY-MM-DD'),
        incident_time: z.string().optional().describe('HH:MM'),
        exact_location: z.string().optional(),
        immediate_actions_taken: z.string().optional(),
        was_injury_involved: z.boolean().default(false),
        site_id: z.string().uuid().optional().describe('Defaults to the first site.'),
      }),
      execute: async ({ site_id, ...input }) => {
        const siteId = site_id ?? ctx.sites[0]?.id
        if (!siteId) return { error: 'No site is configured. Add one under Settings > Sites first.' }
        const now = new Date().toISOString()
        const { data, error } = await supabase
          .from('incidents')
          .insert({
            ...input,
            organisation_id: ctx.organisationId,
            site_id: siteId,
            status: 'submitted',
            submitted_by: ctx.userId,
            submitted_at: now,
            created_by: ctx.userId,
          })
          .select('id, incident_number')
          .single()
        if (error) return { error: error.message }
        return { created: true, id: data.id, incidentNumber: data.incident_number, _link: `/incidents/${data.id}` }
      },
    }),

    createAction: tool({
      description: 'Create an action item (task), optionally assigned to someone (resolve names with findPeople first). The user is asked to approve before it is saved.',
      inputSchema: z.object({
        title: z.string().min(3),
        description: z.string().min(3),
        action_type: z.enum(['corrective', 'preventive', 'immediate', 'long_term']),
        priority: z.enum(['low', 'medium', 'high', 'critical']).default('medium'),
        due_date: z.string().describe('YYYY-MM-DD'),
        assigned_to: z.string().uuid().optional(),
        source_type: z.string().optional().describe('e.g. incident, hazard_report, inspection, audit, standalone'),
        source_id: z.string().uuid().optional(),
        verification_required: z.boolean().default(false),
      }),
      execute: async ({ assigned_to, source_type, ...input }) => {
        const { data, error } = await supabase
          .from('actions')
          .insert({
            ...input,
            organisation_id: ctx.organisationId,
            source_type: source_type ?? 'standalone',
            status: 'open',
            created_by: ctx.userId,
            ...(assigned_to ? { assigned_to, assigned_by: ctx.userId, assigned_at: new Date().toISOString() } : {}),
          })
          .select('id, action_number')
          .single()
        if (error) return { error: error.message }
        return { created: true, id: data.id, actionNumber: data.action_number, _link: `/actions/${data.id}` }
      },
    }),

    updateActionStatus: tool({
      description: 'Change the status of an action (e.g. start it, complete it with notes). The user is asked to approve.',
      inputSchema: z.object({
        id: z.string().uuid(),
        status: z.enum(['open', 'in_progress', 'completed', 'cancelled', 'reopened']),
        completion_notes: z.string().optional(),
      }),
      execute: async ({ id, status, completion_notes }) => {
        const patch: Record<string, unknown> = { status }
        if (status === 'completed') {
          patch.completed_at = new Date().toISOString()
          patch.completed_by = ctx.userId
          if (completion_notes) patch.completion_notes = completion_notes
        }
        const { data, error } = await supabase.from('actions').update(patch).eq('id', id).select('id, action_number, status').maybeSingle()
        if (error) return { error: error.message }
        if (!data) return { error: 'Action not found, or you do not have permission to change it.' }
        return { updated: true, ...data, _link: `/actions/${id}` }
      },
    }),

    readFile: tool({
      description:
        'Open and read the file uploaded to a record: documents (policies, procedures, SOPs, plans — PDF, Word, PowerPoint, Excel, text, images), chemical safety data sheets, training certificates, hazard evidence photos, emergency plans and toolbox talk photos. Find the record id first with queryRecords. Use this whenever the user asks what a document says, to summarise it, compare it, or check it against regulations.',
      inputSchema: z.object({
        table: z.enum(Object.keys(FILE_SOURCES) as [keyof typeof FILE_SOURCES, ...(keyof typeof FILE_SOURCES)[]]),
        id: z.string().uuid(),
      }),
      execute: async ({ table, id }) => readRecordFile(supabase, table, id),
      toModelOutput: ({ output }) => {
        const o = output as FileReadResult
        const { attachments, text, ...meta } = o
        const parts: ({ type: 'text'; text: string } | { type: 'file'; mediaType: string; data: { type: 'data'; data: string } })[] = [
          { type: 'text', text: JSON.stringify(meta) },
        ]
        if (text) parts.push({ type: 'text', text: `--- File content${o.truncated ? ' (truncated)' : ''} ---\n${text}` })
        for (const a of attachments ?? []) parts.push({ type: 'file', mediaType: a.mediaType, data: { type: 'data', data: a.data } })
        return { type: 'content', value: parts }
      },
    }),

    createDocument: tool({
      description:
        'Create a new document in the document register (policy, procedure, SWP, SOP, plan, form, etc.). Write the full document body yourself in markdown (headings, bullets) — it is saved as an attached PDF. Look up document_type_id from document_types first when the type is clear. Saved as a draft. The user is asked to approve before it is saved.',
      inputSchema: z.object({
        title: z.string().min(3),
        description: z.string().optional().describe('One or two sentence summary.'),
        content: z.string().min(20).describe('Full document body in markdown.'),
        document_type_id: z.string().uuid().optional(),
        category: z.string().optional(),
        owner_id: z.string().uuid().optional().describe('Defaults to the current user.'),
        version_number: z.string().default('1.0'),
        review_due_date: z.string().optional().describe('YYYY-MM-DD'),
        expiry_date: z.string().optional().describe('YYYY-MM-DD'),
        requires_acknowledgement: z.boolean().default(false),
      }),
      execute: async ({ content, version_number, owner_id, ...input }) => {
        const { data: draft } = await supabase.from('document_statuses').select('id').eq('code', 'draft').maybeSingle()
        const { data: doc, error } = await supabase
          .from('documents')
          .insert({
            ...input,
            organisation_id: ctx.organisationId,
            status_id: draft?.id ?? null,
            owner_id: owner_id ?? ctx.userId,
            version: version_number,
            version_number,
            created_by: ctx.userId,
          })
          .select('id, document_number')
          .single()
        if (error) return { error: error.message }

        // Attach the drafted body as a PDF, the same way the upload form stores files
        let attached = false
        try {
          const pdf = textToPdf(input.title, content, `Version ${version_number} · Draft · ${new Date().toISOString().slice(0, 10)}`)
          const fileName = `${input.title.replace(/[^a-zA-Z0-9 _-]/g, '').trim().slice(0, 80) || 'document'}.pdf`
          const path = getStoragePath(ctx.organisationId, 'documents', doc.id, fileName)
          const up = await supabaseAdmin.storage.from('documents').upload(path, pdf, { contentType: 'application/pdf' })
          if (!up.error) {
            const { data: pub } = supabaseAdmin.storage.from('documents').getPublicUrl(path)
            await supabase
              .from('documents')
              .update({ file_url: pub.publicUrl, file_name: fileName, file_size_bytes: pdf.length, file_mime_type: 'application/pdf' })
              .eq('id', doc.id)
            attached = true
          }
        } catch {
          // The record still exists; the user can attach a file on its page
        }
        return {
          created: true,
          id: doc.id,
          documentNumber: doc.document_number,
          fileAttached: attached,
          _link: `/documents/${doc.id}`,
        }
      },
    }),

    markNotificationsRead: tool({
      description: "Mark the current user's notifications as read (all, or specific ids).",
      inputSchema: z.object({ ids: z.array(z.string().uuid()).optional() }),
      execute: async ({ ids }) => {
        let q = supabase.from('notifications').update({ is_read: true, read_at: new Date().toISOString() }).eq('recipient_user_id', ctx.userId).eq('is_read', false)
        if (ids?.length) q = q.in('id', ids)
        const { error } = await q
        return error ? { error: error.message } : { updated: true }
      },
    }),
  }
}

export type AssistantTools = ReturnType<typeof buildTools>

/** Tools that change data and need the user to approve each call */
export const WRITE_TOOLS = ['createHazardReport', 'createIncident', 'createAction', 'updateActionStatus', 'createDocument'] as const
