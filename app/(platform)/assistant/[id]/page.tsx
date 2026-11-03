import { notFound } from 'next/navigation'
import type { UIMessage } from 'ai'
import { listChatSessions } from '@/app/actions/ai-chat'
import { AssistantChat } from '@/components/assistant/AssistantChat'
import { createClient } from '@/lib/supabase/server'

export const metadata = { title: 'Assistant' }

export default async function AssistantSessionPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  const { data: session } = await supabase
    .from('ai_chat_sessions')
    .select('id, title, messages')
    .eq('id', id)
    .maybeSingle()
  if (!session) notFound()
  const sessions = await listChatSessions()
  return (
    <AssistantChat
      key={session.id}
      sessionId={session.id}
      initialMessages={(session.messages ?? []) as UIMessage[]}
      sessions={sessions}
      firstName="" userId={user!.id}
    />
  )
}
