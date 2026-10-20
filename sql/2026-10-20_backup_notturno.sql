-- Backup notturno dentro Supabase (opzione B).
-- Ogni notte alle 02:00 UTC (03:00/04:00 ora di Roma) copia in backup.istantanee:
-- tutte le righe di dati, utenti, sal_foto e l'elenco dei file del bucket Foto (solo nomi, non le foto).
-- Tiene 30 giorni, poi cancella SOLO le istantanee piu vecchie. Non modifica nessun dato dell'app.
-- Schema "backup" separato: non esposto alle API, invisibile dall'app e dagli operai.
begin;

create extension if not exists pg_cron;

create schema if not exists backup;
revoke all on schema backup from public, anon, authenticated;

create table if not exists backup.istantanee (
  id        bigserial primary key,
  preso_il  timestamptz not null default now(),
  tabella   text not null,
  righe     int not null,
  contenuto jsonb not null
);
create index if not exists istantanee_preso_il on backup.istantanee (preso_il);
alter table backup.istantanee enable row level security;
revoke all on backup.istantanee from public, anon, authenticated;

create or replace function backup.fai_istantanea()
returns void language plpgsql security definer set search_path = '' as $$
declare
  adesso timestamptz := now();
begin
  insert into backup.istantanee (preso_il, tabella, righe, contenuto)
  select adesso, 'dati', count(*), coalesce(jsonb_agg(to_jsonb(t) order by t.chiave), '[]') from public.dati t
  union all
  select adesso, 'utenti', count(*), coalesce(jsonb_agg(to_jsonb(t) order by t.nome), '[]') from public.utenti t
  union all
  select adesso, 'sal_foto', count(*), coalesce(jsonb_agg(to_jsonb(t) order by t.data_caricamento), '[]') from public.sal_foto t
  union all
  select adesso, 'storage_foto', count(*),
         coalesce(jsonb_agg(jsonb_build_object('name', o.name, 'size', o.metadata->>'size', 'created_at', o.created_at) order by o.name), '[]')
  from storage.objects o where o.bucket_id = 'Foto';

  delete from backup.istantanee where preso_il < adesso - interval '30 days';
end $$;
revoke all on function backup.fai_istantanea() from public, anon, authenticated;

-- Prima istantanea subito, cosi si vede che funziona
select backup.fai_istantanea();

select cron.schedule('backup-notturno', '0 2 * * *', 'select backup.fai_istantanea()');

commit;

-- Controllo: select preso_il, tabella, righe from backup.istantanee order by preso_il desc, tabella;
--
-- Ripristino di una chiave di dati (esempio rapporti_v1 dall'istantanea di una data), da fare con Claude:
--   update public.dati d set valore = r->'valore'
--   from backup.istantanee i, jsonb_array_elements(i.contenuto) r
--   where i.tabella = 'dati' and i.preso_il::date = 'AAAA-MM-GG'
--     and r->>'chiave' = 'rapporti_v1' and d.chiave = 'rapporti_v1';
