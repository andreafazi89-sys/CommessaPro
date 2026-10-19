-- PROVA A VUOTO: esegue tutta la modifica, controlla i risultati e poi ANNULLA TUTTO.
-- Il risultato compare come errore "DRYRUN ...": e voluto.
do $$
declare ris text;
begin
  create table public.backup_utenti_20261019 as
    select id, email, nome, ruolo, attivo, permessi, now() as salvato_il from public.utenti;
  alter table public.backup_utenti_20261019 enable row level security;
  revoke all on public.backup_utenti_20261019 from anon, authenticated;

  update public.utenti set ruolo = 'direzione' where ruolo = 'segretaria' and nome in ('Fabio Pierantoni', 'Rino Lenti');
  update public.utenti set ruolo = 'ufficio'   where ruolo = 'segretaria' and nome in ('Pamela Pierantoni', 'Antonella Ventrella');

  alter table public.utenti add constraint utenti_ruolo_valido
    check (ruolo in ('admin', 'direzione', 'ufficio', 'operaio'));

  alter policy dati_write_admin_segretaria on public.dati
    using (public.mio_ruolo() = any (array['admin', 'direzione', 'ufficio']))
    with check (public.mio_ruolo() = any (array['admin', 'direzione', 'ufficio']));
  alter policy dati_write_admin_segretaria on public.dati rename to dati_write_admin_direzione_ufficio;

  select string_agg(nome || '=' || ruolo, ', ' order by ruolo, nome) into ris from public.utenti;
  ris := ris || ' | backup righe: ' || (select count(*) from public.backup_utenti_20261019)
             || ' | policy: ' || (select qual from pg_policies where tablename = 'dati' and policyname = 'dati_write_admin_direzione_ufficio');
  raise exception 'DRYRUN %', ris;
end $$;
