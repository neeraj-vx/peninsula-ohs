import {
  convertToModelMessages,
  createIdGenerator,
  createUIMessageStreamResponse,
  generateText,
  stepCountIs,
  streamText,
  toUIMessageStream,
  validateUIMessages,
  type UIMessage,
} from 'ai'
import { createClient } from '@/lib/supabase/server'
import { loadAssistantContext, buildInstructions } from '@/lib/ai/context'
import { buildTools, WRITE_TOOLS } from '@/lib/ai/tools'
import { gateway, CHAT_MODEL, TITLE_MODEL } from '@/lib/ai/model'

export const maxDuration = 60

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

function textOf(m: UIMessage): string {
  return m.parts.map((p) => (p.type === 'text' ? p.text : '')).join(' ').trim()
}

export async function POST(req: Request) {
  const supabase = await createClient()
  const ctx = await loadAssistantContext(supabase)
  if (!ctx) return new Response('Unauthorized', { status: 401 })

  const { id, messages } = (await req.json()) as { id: string; messages: UIMessage[] }
  if (!UUID_RE.test(id ?? '')) return new Response('Invalid chat id', { status: 400 })

  // The session must belong to this user (RLS only returns their own)
  const { data: session } = await supabase.from('ai_chat_sessions').select('id, title').eq('id', id).maybeSingle()
  if (!session) return new Response('Chat not found', { status: 404 })

  const tools = buildTools(supabase, ctx)

  let validated: UIMessage[]
  try {
    validated = await validateUIMessages({ messages, tools })
  } catch {
    return new Response('Invalid messages', { status: 400 })
  }

  const result = streamText({
    model: gateway(CHAT_MODEL),
    instructions: buildInstructions(ctx),
    messages: await convertToModelMessages(validated, { tools, ignoreIncompleteToolCalls: true }),
    tools,
    toolApproval: Object.fromEntries(WRITE_TOOLS.map((t) => [t, 'user-approval' as const])),
    stopWhen: stepCountIs(12),
  })

  return createUIMessageStreamResponse({
    stream: toUIMessageStream({
      stream: result.stream,
      tools,
      originalMessages: validated,
      generateMessageId: createIdGenerator({ prefix: 'msg', size: 16 }),
      onError: (error) => {
        console.error('[ai/chat]', error)
        return 'The assistant ran into a problem. Please try again.'
      },
      onEnd: async ({ messages: all }) => {
        let title = session.title
        if (title === 'New chat') {
          const firstUser = all.find((m) => m.role === 'user')
          if (firstUser) {
            try {
              const { text } = await generateText({
                model: gateway(TITLE_MODEL),
                prompt: `Write a short title (max 6 words, no quotes or trailing punctuation) for a chat that starts with:\n\n${textOf(firstUser).slice(0, 1000)}`,
              })
              title = text.trim().replace(/^["']|["'.]$/g, '').slice(0, 80) || title
            } catch {
              title = textOf(firstUser).slice(0, 60) || title
            }
          }
        }
        await supabase
          .from('ai_chat_sessions')
          .update({ messages: all, title, updated_at: new Date().toISOString() })
          .eq('id', id)
      },
    }),
  })
}
