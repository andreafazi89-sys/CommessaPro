-- Notifiche dei documenti del cantiere (DDT, bolle, fatture).
-- Quando qualcuno carica un documento, una notifica arriva all'admin e agli utenti con
-- utenti.notifiche_documenti = true (oggi solo Pamela, che li archivia). Chi carica non
-- riceve la propria. Ognuno vede e segna come lette solo le sue notifiche.
-- Migrazione additiva: aggiunge una colonna a utenti (con backup), una tabella, un trigger.
-- Prima eseguire 2026-11-03_notifiche_documenti_PROVA.sql (non cambia nulla).
begin;

-- 1. Backup della tabella utenti prima di aggiungere la colonna
create table public.backup_utenti_20261103 as select * from public.utenti;
alter table public.backup_utenti_20261103 enable row level security;
revoke all on public.backup_utenti_20261103 from anon, authenticated;

-- 2. Chi riceve le notifiche dei documenti oltre all'admin (la spunta la cambia solo l'admin)
alter table public.utenti add column notifiche_documenti boolean not null default false;
update public.utenti set notifiche_documenti = true where nome = 'Pamela Pierantoni';

-- 3. Tabella: una riga per destinatario. Generica (tipo) per altre notifiche in futuro.
create table public.notifiche (
  id uuid primary key default gen_random_uuid(),
  destinatario uuid not null references public.utenti (id) on delete cascade,
  tipo text not null,
  cantiere_id text,
  documento_id uuid references public.documenti_cantiere (id),
  titolo text not null,
  testo text,
  autore_nome text,
  creato_il timestamptz not null default now(),
  letta_il timestamptz,
  constraint notifiche_tipo_valido check (tipo in ('DOCUMENTO'))
);
create index notifiche_destinatario on public.notifiche (destinatario, creato_il desc);

-- 4. Ognuno vede e segna come lette solo le proprie. Nessun insert dall'app (le crea
--    il trigger) e nessun delete. Utente disattivato: nulla.
alter table public.notifiche enable row level security;
revoke all on public.notifiche from anon, authenticated;
grant select on public.notifiche to authenticated;
grant update (letta_il) on public.notifiche to authenticated;
create policy notifiche_select on public.notifiche for select to authenticated
  using (destinatario = auth.uid() and public.utente_attivo());
create policy notifiche_update on public.notifiche for update to authenticated
  using (destinatario = auth.uid() and public.utente_attivo())
  with check (destinatario = auth.uid() and public.utente_attivo());

-- 5. Trigger: a ogni documento caricato, una notifica all'admin e a chi ha la spunta
--    (solo admin, direzione, ufficio attivi; non a chi l'ha caricato).
--    Se qualcosa va storto la notifica salta ma il documento si salva comunque.
create or replace function public.notifica_documento() returns trigger
  language plpgsql security definer set search_path to 'public' as $f$
declare cant text; tit text; txt text;
begin
  begin
    select nullif(concat_ws(' - ', nullif(c->>'commessa', ''), nullif(c->>'titolo', '')), '') into cant
      from public.dati d, jsonb_array_elements(case when jsonb_typeof(d.valore) = 'array' then d.valore else '[]'::jsonb end) c
     where d.chiave = 'cantieri_v1' and c->>'id' = new.cantiere_id
     limit 1;
    tit := case new.tipo when 'DDT' then 'DDT' when 'BOLLA' then 'Bolla' when 'FATTURA' then 'Fattura' else new.tipo end
           || coalesce(' n. ' || nullif(new.numero, ''), '')
           || coalesce(' del ' || to_char(new.data, 'DD/MM/YYYY'), '');
    txt := concat_ws(' - ', coalesce(cant, 'Cantiere ' || new.cantiere_id), nullif(new.fornitore, ''));
    insert into public.notifiche (destinatario, tipo, cantiere_id, documento_id, titolo, testo, autore_nome)
    select u.id, 'DOCUMENTO', new.cantiere_id, new.id, tit, txt, new.caricato_da_nome
      from public.utenti u
     where coalesce(u.attivo, true)
       and (u.ruolo = 'admin' or (u.notifiche_documenti and u.ruolo in ('direzione', 'ufficio')))
       and u.id is distinct from new.caricato_da;
  exception when others then
    raise warning 'notifica_documento: %', sqlerrm;
  end;
  return new;
end;
$f$;
revoke execute on function public.notifica_documento() from public, anon, authenticated;
create trigger documenti_notifica after insert on public.documenti_cantiere
  for each row execute function public.notifica_documento();

-- 6. riceve_notifiche(): la Home lo usa per mostrare la voce Notifiche
create or replace function public.riceve_notifiche() returns boolean
  language sql stable security definer set search_path to 'public' as $f$
  select exists (select 1 from public.utenti where id = auth.uid() and coalesce(attivo, true)
                 and (ruolo = 'admin' or (notifiche_documenti and ruolo in ('direzione', 'ufficio'))));
$f$;
revoke execute on function public.riceve_notifiche() from public, anon;
grant execute on function public.riceve_notifiche() to authenticated;

commit;
