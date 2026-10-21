-- Ripristina funzioni e policy come prima del 21/10/2026.
begin;
create or replace function public.mio_ruolo() returns text
  language sql stable security definer set search_path to 'public' as $$
  select ruolo from public.utenti where id = auth.uid();
$$;
alter policy dati_select_authenticated on public.dati using (true);
alter policy "sal_foto select autenticati" on public.sal_foto using (true);
alter policy "sal_foto insert autenticati" on public.sal_foto with check (uploaded_by = auth.uid());
alter policy "Foto autenticati select" on storage.objects using (bucket_id = 'Foto');
alter policy "Foto autenticati insert" on storage.objects with check (bucket_id = 'Foto');
alter policy "Foto autenticati update" on storage.objects using (bucket_id = 'Foto') with check (bucket_id = 'Foto');
alter policy "Foto autenticati delete" on storage.objects using (bucket_id = 'Foto');
drop function if exists public.utente_attivo();
commit;
