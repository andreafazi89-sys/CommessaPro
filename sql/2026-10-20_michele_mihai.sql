-- Sostituisce "Michele Poveste" con "Mihai Poveste" in rapporti_v1 e cantieri_v1.
-- Prima fa il backup delle due righe di dati. Aggiorna il timestamp dei soli record toccati.
begin;
create table if not exists backup_dati_20261020_michele_mihai as
  select * from dati where chiave in ('rapporti_v1','cantieri_v1');
alter table backup_dati_20261020_michele_mihai enable row level security;

update dati d
set valore = (
  select jsonb_agg(
    case when e::text like '%"Michele Poveste"%'
      then replace(e::text, '"Michele Poveste"', '"Mihai Poveste"')::jsonb
           || jsonb_build_object('timestamp', to_char(now() at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'))
      else e end
    order by ord)
  from jsonb_array_elements(d.valore) with ordinality as t(e, ord)
)
where d.chiave in ('rapporti_v1','cantieri_v1')
  and d.valore::text like '%"Michele Poveste"%';

-- Controllo: deve restituire 0
select count(*) as rimasti from dati, jsonb_array_elements(valore) e
where chiave in ('rapporti_v1','cantieri_v1') and e::text like '%"Michele Poveste"%';
commit;
