import { listChatSessions } from '@/app/actions/ai-chat'
import { AssistantChat } from '@/components/assistant/AssistantChat'
import { createClient } from '@/lib/supabase/server'

export const metadata = { title: 'Assistant' }

export default async function AssistantPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  const { data: profile } = await supabase.from('user_profiles').select('first_name').eq('id', user!.id).maybeSingle()
  const sessions = await listChatSessions()
  return <AssistantChat key="new" sessions={sessions} userId={user!.id} firstName={profile?.first_name ?? ''} />
}
