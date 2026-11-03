'use server'

import { createClient } from '@/lib/supabase/server'

export interface ChatSessionSummary {
  id: string
  title: string
  updated_at: string
}

export async function listChatSessions(): Promise<ChatSessionSummary[]> {
  const supabase = await createClient()
  const { data } = await supabase
    .from('ai_chat_sessions')
    .select('id, title, updated_at')
    .order('updated_at', { ascending: false })
    .limit(100)
  return data ?? []
}

export async function createChatSession(id?: string): Promise<{ id?: string; error?: string }> {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return { error: 'Not signed in.' }
  const { data: profile } = await supabase.from('user_profiles').select('organisation_id').eq('id', user.id).single()
  if (!profile) return { error: 'Profile not found.' }

  const { data, error } = await supabase
    .from('ai_chat_sessions')
    .insert({ ...(id ? { id } : {}), user_id: user.id, organisation_id: profile.organisation_id })
    .select('id')
    .single()
  if (error) return { error: error.message }
  return { id: data.id }
}

export async function renameChatSession(id: string, title: string): Promise<{ error?: string }> {
  const clean = title.trim().slice(0, 80)
  if (!clean) return { error: 'Title is required.' }
  const supabase = await createClient()
  const { error } = await supabase.from('ai_chat_sessions').update({ title: clean }).eq('id', id)
  return error ? { error: error.message } : {}
}

export async function deleteChatSession(id: string): Promise<{ error?: string }> {
  const supabase = await createClient()
  const { error } = await supabase.from('ai_chat_sessions').delete().eq('id', id)
  return error ? { error: error.message } : {}
}
