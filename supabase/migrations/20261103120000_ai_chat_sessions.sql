-- AI assistant chat sessions. Each user sees only their own sessions.
create table if not exists public.ai_chat_sessions (
  id uuid primary key default gen_random_uuid(),
  organisation_id uuid not null references public.organisations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'New chat',
  messages jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists ai_chat_sessions_user_updated_idx
  on public.ai_chat_sessions (user_id, updated_at desc);

alter table public.ai_chat_sessions enable row level security;

create policy ai_chat_sessions_select_own on public.ai_chat_sessions
  for select to authenticated using (user_id = (select auth.uid()));
create policy ai_chat_sessions_insert_own on public.ai_chat_sessions
  for insert to authenticated with check (
    user_id = (select auth.uid())
    and organisation_id = (select organisation_id from public.user_profiles where id = (select auth.uid()))
  );
create policy ai_chat_sessions_update_own on public.ai_chat_sessions
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy ai_chat_sessions_delete_own on public.ai_chat_sessions
  for delete to authenticated using (user_id = (select auth.uid()));
