-- Storage buckets the app uses. These were created by hand in the original
-- project; this makes a fresh project match it.
insert into storage.buckets (id, name, public, file_size_limit) values
  ('org-documents',   'org-documents',   false, 52428800),
  ('documents',       'documents',       true,  null),
  ('certificates',    'certificates',    true,  10485760),
  ('sds-documents',   'sds-documents',   true,  null),
  ('hazard-evidence', 'hazard-evidence', true,  null),
  ('signatures',      'signatures',      true,  null)
on conflict (id) do nothing;

-- Public buckets: same policies as the original project
do $$
declare b text;
begin
  foreach b in array array['documents', 'certificates', 'sds-documents', 'signatures', 'hazard-evidence'] loop
    if not exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'public_read_' || b) then
      execute format('create policy %I on storage.objects for select using (bucket_id = %L)', 'public_read_' || b, b);
    end if;
    if not exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'anon_insert_' || b) then
      execute format('create policy %I on storage.objects for insert with check (bucket_id = %L)', 'anon_insert_' || b, b);
    end if;
  end loop;
end $$;
