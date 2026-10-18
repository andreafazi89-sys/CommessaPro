-- ROLLBACK: ripristina le policy storage come erano il 18/10/2026 prima della migrazione.
-- Da eseguire SOLO se la migrazione 2026-10-18_storage_solo_autenticati.sql crea problemi.
begin;
drop policy if exists "Foto autenticati select" on storage.objects;
drop policy if exists "Foto autenticati insert" on storage.objects;
drop policy if exists "Foto autenticati update" on storage.objects;
drop policy if exists "Foto autenticati delete" on storage.objects;
create policy "Give anon users access to JPG images in folder 1b290_0" on storage.objects as PERMISSIVE for SELECT to public using ((bucket_id = 'foto'::text));
create policy "Give anon users access to JPG images in folder 1b290_1" on storage.objects as PERMISSIVE for INSERT to public with check ((bucket_id = 'foto'::text));
create policy "Give anon users access to JPG images in folder 1b290_2" on storage.objects as PERMISSIVE for UPDATE to public using ((bucket_id = 'foto'::text));
create policy "Give anon users access to JPG images in folder 1b290_3" on storage.objects as PERMISSIVE for DELETE to public using ((bucket_id = 'foto'::text));
create policy "allow all" on storage.objects as PERMISSIVE for ALL to public using ((bucket_id = 'foto'::text)) with check ((bucket_id = 'foto'::text));
create policy "allow all operation 1b290_0" on storage.objects as PERMISSIVE for SELECT to public using ((bucket_id = 'Foto'::text));
create policy "allow all operation 1b290_1" on storage.objects as PERMISSIVE for INSERT to public with check ((bucket_id = 'Foto'::text));
create policy "allow all operation 1b290_2" on storage.objects as PERMISSIVE for UPDATE to public using ((bucket_id = 'Foto'::text));
create policy "allow all operation 1b290_3" on storage.objects as PERMISSIVE for DELETE to public using ((bucket_id = 'Foto'::text));
commit;
