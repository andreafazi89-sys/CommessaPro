-- PROVA A VUOTO: esegue la migrazione, simula ogni utente reale e poi ANNULLA TUTTO.
-- Il risultato compare come errore "DRYRUN ...": e voluto.
-- Atteso: Andrea e Pamela vedono il tipo e scrivono; Antonella vede l'assenza senza tipo
-- e non scrive; direzione e operai non vedono nulla e non scrivono.
do $prova$
declare ris text := ''; r record; diretti int; da_fun int; tipo_visto text; scritto text;
begin


-- 1. Backup della tabella utenti prima di aggiungere la colonna
create table public.backup_utenti_20261023 as select * from public.utenti;
alter table public.backup_utenti_20261023 enable row level security;
revoke all on public.backup_utenti_20261023 from anon, authenticated;

-- 2. Abilitazione per utente (la cambia solo l'admin: policy utenti_update_admin)
alter table public.utenti add column gestisce_assenze boolean not null default false;
update public.utenti set gestisce_assenze = true where nome = 'Pamela Pierantoni';

-- 3. Tabella
create table public.assenze (
  id uuid primary key default gen_random_uuid(),
  persona text not null,                  -- nome come in griglia (operaio o amministrativo)
  dal date not null,
  al date not null,
  tipo text not null,
  ore numeric(4,1),                       -- solo PERMESSO a ore; vuoto = giornata intera
  note text,
  autore text,
  eliminato boolean not null default false,
  creato_il timestamptz not null default now(),
  timestamp timestamptz not null default now(),
  constraint assenze_tipo_valido check (tipo in ('MALATTIA', 'FERIE', 'PERMESSO')),
  constraint assenze_date_valide check (al >= dal),
  constraint assenze_ore_valide check (ore is null or (tipo = 'PERMESSO' and ore > 0 and ore < 8))
);
create index assenze_periodo on public.assenze (dal, al);

-- 4. gestisce_assenze(): admin, o utente attivo con l'abilitazione
create or replace function public.gestisce_assenze() returns boolean
  language sql stable security definer set search_path to 'public' as $f$
  select exists (select 1 from public.utenti where id = auth.uid() and coalesce(attivo, true)
                 and (ruolo = 'admin' or gestisce_assenze));
$f$;
revoke execute on function public.gestisce_assenze() from public, anon;
grant execute on function public.gestisce_assenze() to authenticated;

-- 5. Tabella: lettura e scrittura diretta solo per chi gestisce le assenze
alter table public.assenze enable row level security;
revoke all on public.assenze from anon;
grant select, insert, update on public.assenze to authenticated;
create policy assenze_select on public.assenze for select to authenticated using (public.gestisce_assenze());
create policy assenze_insert on public.assenze for insert to authenticated with check (public.gestisce_assenze());
create policy assenze_update on public.assenze for update to authenticated
  using (public.gestisce_assenze()) with check (public.gestisce_assenze());

-- 6. assenze_mese(): quello che vede il Riepilogo mese. Admin e ufficio;
--    tipo e note solo a chi gestisce le assenze.
create or replace function public.assenze_mese(p_dal date, p_al date)
  returns table (id uuid, persona text, dal date, al date, tipo text, ore numeric, note text)
  language sql stable security definer set search_path to 'public' as $f$
  select a.id, a.persona, a.dal, a.al,
         case when g.chiaro then a.tipo end, a.ore, case when g.chiaro then a.note end
    from public.assenze a, (select public.gestisce_assenze() as chiaro) g
   where not a.eliminato and a.dal <= p_al and a.al >= p_dal
     and public.mio_ruolo() = any (array['admin', 'ufficio'])
   order by a.creato_il desc;
$f$;
revoke execute on function public.assenze_mese(date, date) from public, anon;
grant execute on function public.assenze_mese(date, date) to authenticated;


  insert into public.assenze (persona, dal, al, tipo, note) values ('Prova', '2026-10-01', '2026-10-02', 'MALATTIA', 'nota');

  for r in select id, nome, ruolo from public.utenti order by ruolo, nome loop
    perform set_config('request.jwt.claims', json_build_object('sub', r.id, 'role', 'authenticated')::text, true);
    execute 'set local role authenticated';
    select count(*) into diretti from public.assenze;
    select count(*), max(coalesce(f.tipo, '-') || '/' || coalesce(f.note, '-')) into da_fun, tipo_visto
      from public.assenze_mese('2026-10-01', '2026-10-31') f;
    begin
      insert into public.assenze (persona, dal, al, tipo) values ('Prova ' || r.nome, '2026-10-05', '2026-10-05', 'FERIE');
      scritto := 'si';
    exception when others then scritto := 'no';
    end;
    execute 'reset role';
    ris := ris || r.nome || ' ' || r.ruolo || ': tabella ' || diretti || ', funzione ' || da_fun
               || ' ' || coalesce(tipo_visto, '') || ', scrive ' || scritto || ' ; ';
  end loop;
  raise exception 'DRYRUN %', ris;
end $prova$;
