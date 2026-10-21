-- PROVA A VUOTO: esegue la modifica, simula gli utenti reali e poi ANNULLA TUTTO.
-- Il risultato compare come errore "DRYRUN ...": e voluto.
-- Per ogni utente: ruolo e attivo prima/dopo (devono coincidere), e la simulazione
-- dello stesso utente disattivato (deve dare ruolo vuoto e attivo=false).
do $$
declare ris text := ''; r record; ruolo_dopo text; att_dopo boolean; ruolo_dis text; att_dis boolean;
begin
  create or replace function public.utente_attivo() returns boolean
    language sql stable security definer set search_path to 'public' as $f$
    select exists (select 1 from public.utenti where id = auth.uid() and coalesce(attivo, true));
  $f$;
  create or replace function public.mio_ruolo() returns text
    language sql stable security definer set search_path to 'public' as $f$
    select ruolo from public.utenti where id = auth.uid() and coalesce(attivo, true);
  $f$;
  alter policy dati_select_authenticated on public.dati using (public.utente_attivo());
  alter policy "sal_foto select autenticati" on public.sal_foto using (public.utente_attivo());
  alter policy "sal_foto insert autenticati" on public.sal_foto
    with check (uploaded_by = auth.uid() and public.utente_attivo());
  alter policy "Foto autenticati select" on storage.objects using (bucket_id = 'Foto' and public.utente_attivo());
  alter policy "Foto autenticati insert" on storage.objects with check (bucket_id = 'Foto' and public.utente_attivo());
  alter policy "Foto autenticati update" on storage.objects
    using (bucket_id = 'Foto' and public.utente_attivo()) with check (bucket_id = 'Foto' and public.utente_attivo());
  alter policy "Foto autenticati delete" on storage.objects using (bucket_id = 'Foto' and public.utente_attivo());

  for r in select id, nome, ruolo, attivo from public.utenti order by ruolo, nome loop
    perform set_config('request.jwt.claims', json_build_object('sub', r.id)::text, true);
    ruolo_dopo := public.mio_ruolo();
    att_dopo := public.utente_attivo();
    update public.utenti set attivo = false where id = r.id;
    ruolo_dis := public.mio_ruolo();
    att_dis := public.utente_attivo();
    update public.utenti set attivo = r.attivo where id = r.id;
    ris := ris || r.nome || ' ' || r.ruolo || '/' || coalesce(ruolo_dopo, '-') || ' att=' || att_dopo
               || ' disattivato=' || coalesce(ruolo_dis, '-') || '/' || att_dis || ' ; ';
  end loop;
  raise exception 'DRYRUN %', ris;
end $$;
