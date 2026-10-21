-- Utente disattivato (utenti.attivo = false) = nessun permesso, anche con una sessione ancora aperta.
-- Prima: mio_ruolo() non guardava attivo, quindi direzione/ufficio/operai disattivati potevano
-- ancora scrivere su dati; lettura di dati, sal_foto e bucket Foto era aperta a ogni utente loggato.
-- Utenti attivi: nessun cambiamento (stessi ruoli, stesse policy).
-- La riga propria in utenti resta leggibile: login.html e index.html la usano per fare logout.
begin;

-- 1. Backup delle definizioni attuali (serve al rollback e come traccia)
create table public.backup_rls_20261021 as
  select 'policy' as tipo, schemaname || '.' || tablename || ' / ' || policyname as nome,
         cmd, qual, with_check, null::text as definizione, now() as salvato_il
    from pg_policies
   where (schemaname = 'public' and tablename in ('dati', 'sal_foto'))
      or (schemaname = 'storage' and tablename = 'objects' and policyname like 'Foto autenticati%')
  union all
  select 'funzione', 'public.mio_ruolo', null, null, null,
         pg_get_functiondef('public.mio_ruolo()'::regprocedure), now();
alter table public.backup_rls_20261021 enable row level security;
revoke all on public.backup_rls_20261021 from anon, authenticated;

-- 2. utente_attivo(): l'utente loggato esiste in utenti ed e' attivo (stessa regola di is_admin)
create or replace function public.utente_attivo() returns boolean
  language sql stable security definer set search_path to 'public' as $$
  select exists (select 1 from public.utenti where id = auth.uid() and coalesce(attivo, true));
$$;
revoke execute on function public.utente_attivo() from public, anon;
grant execute on function public.utente_attivo() to authenticated;

-- 3. mio_ruolo(): nessun ruolo se disattivato. Copre tutte le policy di scrittura su dati
--    (admin/direzione/ufficio e operai su rapporti_v1) e la gestione utenti.
create or replace function public.mio_ruolo() returns text
  language sql stable security definer set search_path to 'public' as $$
  select ruolo from public.utenti where id = auth.uid() and coalesce(attivo, true);
$$;

-- 4. Lettura di dati: solo utenti attivi
alter policy dati_select_authenticated on public.dati using (public.utente_attivo());

-- 5. sal_foto: lettura e inserimento solo utenti attivi (update/delete restano is_admin)
alter policy "sal_foto select autenticati" on public.sal_foto using (public.utente_attivo());
alter policy "sal_foto insert autenticati" on public.sal_foto
  with check (uploaded_by = auth.uid() and public.utente_attivo());

-- 6. Bucket Foto: solo utenti attivi. Le 3 policy RESTRICTIVE su sal/ restano invariate.
alter policy "Foto autenticati select" on storage.objects using (bucket_id = 'Foto' and public.utente_attivo());
alter policy "Foto autenticati insert" on storage.objects with check (bucket_id = 'Foto' and public.utente_attivo());
alter policy "Foto autenticati update" on storage.objects
  using (bucket_id = 'Foto' and public.utente_attivo()) with check (bucket_id = 'Foto' and public.utente_attivo());
alter policy "Foto autenticati delete" on storage.objects using (bucket_id = 'Foto' and public.utente_attivo());

commit;
