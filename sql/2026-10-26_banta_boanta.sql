-- Sostituisce "Vasile Banta" con "Vasile Boanta" in rapporti_v1 e cantieri_v1.
-- Prima fa il backup delle due righe di dati. Aggiorna il timestamp dei soli record toccati.
begin;
create table if not exists backup_dati_20261026_banta_boanta as
  select * from dati where chiave in ('rapporti_v1','cantieri_v1');
alter table backup_dati_20261026_banta_boanta enable row level security;

update dati d
set valore = (
  select jsonb_agg(
    case when e::text like '%"Vasile Banta"%'
      then replace(e::text, '"Vasile Banta"', '"Vasile Boanta"')::jsonb
           || jsonb_build_object('timestamp', to_char(now() at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'))
      else e end
    order by ord)
  from jsonb_array_elements(d.valore) with ordinality as t(e, ord)
)
where d.chiave in ('rapporti_v1','cantieri_v1')
  and d.valore::text like '%"Vasile Banta"%';

-- Nome dell'account in utenti (l'email di accesso non cambia)
update utenti set nome = 'Vasile Boanta' where nome = 'Vasile Banta';

-- Controllo: deve restituire 0
select count(*) as rimasti from dati, jsonb_array_elements(valore) e
where chiave in ('rapporti_v1','cantieri_v1') and e::text like '%"Vasile Banta"%';
commit;
