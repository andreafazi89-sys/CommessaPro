-- PROVA A VUOTO: esegue tutta la modifica, controlla i risultati e poi ANNULLA TUTTO.
-- Il risultato compare come errore "DRYRUN ...": e voluto.
do $$
declare ris text := ''; n int; prima jsonb;
begin
  select valore into prima from public.dati where chiave = 'cantieri_v1';

  create table public.backup_cantieri_v1_20261018 as
    select chiave, valore, ts, now() as salvato_il from public.dati where chiave = 'cantieri_v1';
  create table public.backup_dati_economici (cantiere_id text, commessa text, titolo text, cliente text,
    preventivo jsonb, tariffa jsonb, costi_materiali jsonb, salvato_il timestamptz default now());
  insert into public.backup_dati_economici (cantiere_id, commessa, titolo, cliente, preventivo, tariffa, costi_materiali)
  select c->>'id', c->>'commessa', c->>'titolo', c->>'cliente', c->'preventivo', c->'tariffa', c->'costiMateriali'
  from public.dati d, jsonb_array_elements(d.valore) c
  where d.chiave = 'cantieri_v1' and (c ? 'preventivo' or c ? 'tariffa' or c ? 'costiMateriali');
  alter table public.backup_cantieri_v1_20261018 enable row level security;
  alter table public.backup_dati_economici enable row level security;
  revoke all on public.backup_cantieri_v1_20261018, public.backup_dati_economici from anon, authenticated;

  create or replace function public.togli_dati_economici(arr jsonb)
  returns jsonb language sql immutable set search_path = public as $f$
    select case when jsonb_typeof(arr) = 'array'
      then coalesce((select jsonb_agg(case when jsonb_typeof(e) = 'object'
                                           then e - 'preventivo' - 'tariffa' - 'costiMateriali' else e end
                                      order by i)
                     from jsonb_array_elements(arr) with ordinality t(e, i)), '[]'::jsonb)
      else arr end
  $f$;
  update public.dati set valore = public.togli_dati_economici(valore) where chiave = 'cantieri_v1';
  create or replace function public.dati_scarta_economici()
  returns trigger language plpgsql set search_path = public as $f$
  begin
    if new.chiave = 'cantieri_v1' then new.valore := public.togli_dati_economici(new.valore); end if;
    return new;
  end $f$;
  create trigger dati_scarta_economici before insert or update on public.dati
    for each row execute function public.dati_scarta_economici();

  -- Verifiche
  select count(*) into n from public.backup_dati_economici; ris := ris || 'cantieri salvati nel backup: '||n||' (atteso 26)';
  select count(*) into n from public.backup_cantieri_v1_20261018; ris := ris || ' | backup completo: '||n||' riga (atteso 1)';
  select jsonb_array_length(valore) into n from public.dati where chiave = 'cantieri_v1'; ris := ris || ' | cantieri dopo: '||n||' (atteso 26)';
  select count(*) into n from public.dati d, jsonb_array_elements(d.valore) c
    where d.chiave = 'cantieri_v1' and (c ? 'preventivo' or c ? 'tariffa' or c ? 'costiMateriali');
  ris := ris || ' | con dati economici dopo: '||n||' (atteso 0)';
  select count(*) into n from public.dati d, jsonb_array_elements(d.valore) c, jsonb_array_elements(prima) p
    where d.chiave = 'cantieri_v1' and c->>'id' = p->>'id'
      and c = (p - 'preventivo' - 'tariffa' - 'costiMateriali');
  ris := ris || ' | altri dati identici: '||n||' (atteso 26)';
  -- simula una pagina vecchia che rimanda la tariffa
  update public.dati set valore = jsonb_set(valore, '{0,tariffa}', '25') where chiave = 'cantieri_v1';
  select count(*) into n from public.dati d, jsonb_array_elements(d.valore) c where d.chiave = 'cantieri_v1' and c ? 'tariffa';
  ris := ris || ' | tariffa rimandata e scartata: '||case when n = 0 then 'SI' else 'NO' end;

  raise exception 'DRYRUN %', ris;
end $$;
