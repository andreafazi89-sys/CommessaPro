-- Rimozione dati economici (preventivo, tariffa, costiMateriali) da cantieri_v1.
-- Eseguire DOPO il deploy del codice che non li usa piu.
begin;

-- 1. Backup completo della riga cantieri_v1 (serve al rollback)
create table public.backup_cantieri_v1_20261018 as
  select chiave, valore, ts, now() as salvato_il from public.dati where chiave = 'cantieri_v1';

-- 2. Copia leggibile dei dati economici, una riga per cantiere
create table public.backup_dati_economici (
  cantiere_id     text,
  commessa        text,
  titolo          text,
  cliente         text,
  preventivo      jsonb,
  tariffa         jsonb,
  costi_materiali jsonb,
  salvato_il      timestamptz default now()
);
insert into public.backup_dati_economici (cantiere_id, commessa, titolo, cliente, preventivo, tariffa, costi_materiali)
select c->>'id', c->>'commessa', c->>'titolo', c->>'cliente', c->'preventivo', c->'tariffa', c->'costiMateriali'
from public.dati d, jsonb_array_elements(d.valore) c
where d.chiave = 'cantieri_v1' and (c ? 'preventivo' or c ? 'tariffa' or c ? 'costiMateriali');

-- Tabelle di backup: RLS attiva e nessuna policy = invisibili dall'app, leggibili solo da dashboard/SQL Editor
alter table public.backup_cantieri_v1_20261018 enable row level security;
alter table public.backup_dati_economici enable row level security;
revoke all on public.backup_cantieri_v1_20261018, public.backup_dati_economici from anon, authenticated;

-- 3. Funzione che toglie i 3 campi da un array di cantieri
create or replace function public.togli_dati_economici(arr jsonb)
returns jsonb language sql immutable set search_path = public as $$
  select case when jsonb_typeof(arr) = 'array'
    then coalesce((select jsonb_agg(case when jsonb_typeof(e) = 'object'
                                         then e - 'preventivo' - 'tariffa' - 'costiMateriali' else e end
                                    order by i)
                   from jsonb_array_elements(arr) with ordinality t(e, i)), '[]'::jsonb)
    else arr end
$$;

-- 4. Pulizia dei dati attuali
update public.dati set valore = public.togli_dati_economici(valore) where chiave = 'cantieri_v1';

-- 5. Rete di sicurezza: se una pagina vecchia in cache rimanda i campi, il database li scarta
create or replace function public.dati_scarta_economici()
returns trigger language plpgsql set search_path = public as $$
begin
  if new.chiave = 'cantieri_v1' then
    new.valore := public.togli_dati_economici(new.valore);
  end if;
  return new;
end $$;

create trigger dati_scarta_economici
  before insert or update on public.dati
  for each row execute function public.dati_scarta_economici();

commit;
