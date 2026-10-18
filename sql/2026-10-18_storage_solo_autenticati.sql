-- Bucket Foto: accesso solo a utenti loggati. Le 3 policy RESTRICTIVE su sal/ restano invariate.
-- Le policy sul bucket 'foto' minuscolo puntano a un bucket inesistente: rimosse.
drop policy if exists "Give anon users access to JPG images in folder 1b290_0" on storage.objects;
drop policy if exists "Give anon users access to JPG images in folder 1b290_1" on storage.objects;
drop policy if exists "Give anon users access to JPG images in folder 1b290_2" on storage.objects;
drop policy if exists "Give anon users access to JPG images in folder 1b290_3" on storage.objects;
drop policy if exists "allow all" on storage.objects;
drop policy if exists "allow all operation 1b290_0" on storage.objects;
drop policy if exists "allow all operation 1b290_1" on storage.objects;
drop policy if exists "allow all operation 1b290_2" on storage.objects;
drop policy if exists "allow all operation 1b290_3" on storage.objects;
create policy "Foto autenticati select" on storage.objects for select to authenticated using (bucket_id = 'Foto');
create policy "Foto autenticati insert" on storage.objects for insert to authenticated with check (bucket_id = 'Foto');
create policy "Foto autenticati update" on storage.objects for update to authenticated using (bucket_id = 'Foto') with check (bucket_id = 'Foto');
create policy "Foto autenticati delete" on storage.objects for delete to authenticated using (bucket_id = 'Foto');
