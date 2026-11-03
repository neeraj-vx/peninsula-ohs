import type { SupabaseClient } from '@supabase/supabase-js'
import { supabaseAdmin } from '@/lib/supabase/admin'

// Records that can have an uploaded file, and where the file reference lives
export const FILE_SOURCES = {
  documents: { ref: ['file_url', 'storage_path'], name: 'file_name', mime: 'file_mime_type', route: '/documents/{id}' },
  chemicals: { ref: ['sds_file_url'], name: 'sds_file_name', mime: null, route: '/chemicals/{id}' },
  training_records: { ref: ['certificate_file_url'], name: 'certificate_file_name', mime: null, route: undefined },
  hazard_reports: { ref: ['evidence_file_url'], name: 'evidence_file_name', mime: null, route: '/hazards/{id}' },
  emergency_response_plans: { ref: ['file_url'], name: 'file_name', mime: null, route: undefined },
  toolbox_talk_deliveries: { ref: ['photo_url'], name: 'photo_file_name', mime: null, route: undefined },
} as const

export type FileSource = keyof typeof FILE_SOURCES

const MAX_TEXT = 80_000
const MAX_BYTES = 25 * 1024 * 1024
const MAX_INLINE_BYTES = 8 * 1024 * 1024 // PDFs/images passed straight to the model
const MAX_IMAGES = 10

const IMAGE_TYPES: Record<string, string> = { png: 'image/png', jpg: 'image/jpeg', jpeg: 'image/jpeg', gif: 'image/gif', webp: 'image/webp' }
const TEXT_EXT = new Set(['txt', 'csv', 'tsv', 'md', 'json', 'xml', 'html', 'htm', 'log', 'yaml', 'yml'])
const OFFICE_EXT = new Set(['docx', 'doc', 'pptx', 'xlsx', 'odt', 'odp', 'ods', 'rtf', 'pdf'])

export interface FileReadResult {
  error?: string
  file?: { name: string; extension: string; bytes: number }
  text?: string
  truncated?: boolean
  /** Files handed to the model directly (PDF pages, images, slide pictures) */
  attachments?: { mediaType: string; data: string }[]
  note?: string
  _link?: string
}

function extOf(name: string) {
  const clean = name.split('?')[0]
  const i = clean.lastIndexOf('.')
  return i >= 0 ? clean.slice(i + 1).toLowerCase() : ''
}

async function download(ref: string): Promise<Buffer | { error: string }> {
  const ownHost = new URL(process.env.NEXT_PUBLIC_SUPABASE_URL!).host
  let bucket: string | null = null
  let path = ref

  if (/^https?:\/\//i.test(ref)) {
    const url = new URL(ref)
    // Only our own Supabase storage — never fetch arbitrary URLs
    if (url.host !== ownHost) return { error: 'The file is stored outside this workspace and cannot be opened.' }
    const m = url.pathname.match(/\/storage\/v1\/object\/(?:public|sign|authenticated)\/([^/]+)\/(.+)$/)
    if (!m) return { error: 'Unrecognised file location.' }
    bucket = m[1]
    path = decodeURIComponent(m[2])
  }

  for (const b of bucket ? [bucket] : ['org-documents', 'documents']) {
    const { data, error } = await supabaseAdmin.storage.from(b).download(path)
    if (!error && data) return Buffer.from(await data.arrayBuffer())
  }
  return { error: 'The file could not be found in storage — it may never have been uploaded.' }
}

async function extract(buf: Buffer, ext: string, mime: string | null): Promise<Omit<FileReadResult, 'file' | '_link'>> {
  const imageType = IMAGE_TYPES[ext] ?? (mime?.startsWith('image/') ? mime : null)
  if (imageType) {
    if (buf.length > MAX_INLINE_BYTES) return { error: 'Image is too large to read (over 8 MB).' }
    return { attachments: [{ mediaType: imageType, data: buf.toString('base64') }] }
  }

  if (TEXT_EXT.has(ext) || mime?.startsWith('text/')) {
    const text = buf.toString('utf8')
    return { text: text.slice(0, MAX_TEXT), truncated: text.length > MAX_TEXT }
  }

  if (!OFFICE_EXT.has(ext)) return { error: `Files of type .${ext || 'unknown'} can't be read yet.` }

  const { parseOffice } = await import('officeparser')
  const ast = await parseOffice(buf, { fileType: ext, extractAttachments: true } as never)
  const { value } = await ast.to('text', { includeImages: false, textConfig: { preserveLayout: false } } as never)
  const text = String(value ?? '').trim()

  if (text.replace(/\s+/g, '').length >= 200) {
    return { text: text.slice(0, MAX_TEXT), truncated: text.length > MAX_TEXT }
  }

  // Little or no text: scanned PDF, or slides/pages that are pictures — let the model look at them
  if (ext === 'pdf' && buf.length <= MAX_INLINE_BYTES) {
    return { text: text || undefined, attachments: [{ mediaType: 'application/pdf', data: buf.toString('base64') }], note: 'Little text layer — the PDF itself is attached for visual reading.' }
  }
  const images = ((ast as unknown as { attachments?: { type: string; mimeType: string; data: string }[] }).attachments ?? [])
    .filter((a) => a.type === 'image' && /^image\/(png|jpe?g|gif|webp)$/.test(a.mimeType))
  let budget = MAX_INLINE_BYTES
  const picked: { mediaType: string; data: string }[] = []
  for (const img of images) {
    const size = (img.data.length * 3) / 4
    if (picked.length >= MAX_IMAGES || size > budget) break
    budget -= size
    picked.push({ mediaType: img.mimeType, data: img.data })
  }
  if (!picked.length) return { text: text || '(No readable text found in this file.)' }
  return {
    text: text || undefined,
    attachments: picked,
    note: `The content is mostly images; ${picked.length} of ${images.length} attached for visual reading.`,
  }
}

export async function readRecordFile(supabase: SupabaseClient, table: FileSource, id: string): Promise<FileReadResult> {
  const src = FILE_SOURCES[table]
  const cols = ['id', ...src.ref, src.name, src.mime].filter(Boolean).join(',')
  // The user's own client: row-level security decides whether they may see this record
  const { data: row, error } = await supabase.from(table).select(cols).eq('id', id).maybeSingle()
  if (error) return { error: error.message }
  if (!row) return { error: 'Record not found, or you do not have access to it.' }

  const r = row as unknown as Record<string, string | null>
  const ref = src.ref.map((c) => r[c]).find((v) => !!v)
  if (!ref) return { error: 'This record has no file attached.' }

  const name = (src.name && r[src.name]) || decodeURIComponent(ref.split('/').pop() ?? 'file')
  const ext = extOf(name) || extOf(ref)
  const _link = src.route?.replace('{id}', id)

  const bytes = await download(ref)
  if (!Buffer.isBuffer(bytes)) return { ...bytes, _link }
  if (bytes.length > MAX_BYTES) return { error: 'File is larger than 25 MB.', _link }

  try {
    const content = await extract(bytes, ext, src.mime ? r[src.mime] : null)
    return { file: { name, extension: ext, bytes: bytes.length }, ...content, _link }
  } catch (e) {
    return { error: `Could not read the file: ${(e as Error).message}`, file: { name, extension: ext, bytes: bytes.length }, _link }
  }
}
