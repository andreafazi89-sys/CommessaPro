-- PROVA A VUOTO: crea la tabella, simula ogni utente reale e poi ANNULLA TUTTO.
-- Il risultato compare come errore "DRYRUN ...": e voluto.
-- Atteso: admin e ufficio leggono e scrivono; direzione e operai non vedono nulla e non scrivono.
do $$
declare ris text := ''; r record; visti int; scritto text;
begin
  create table public.assenze (
    id uuid primary key default gen_random_uuid(),
    persona text not null, dal date not null, al date not null, tipo text not null,
    ore numeric(4,1), note text, autore text,
    eliminato boolean not null default false,
    creato_il timestamptz not null default now(), timestamp timestamptz not null default now(),
    constraint assenze_tipo_valido check (tipo in ('MALATTIA', 'FERIE', 'PERMESSO')),
    constraint assenze_date_valide check (al >= dal),
    constraint assenze_ore_valide check (ore is null or (tipo = 'PERMESSO' and ore > 0 and ore < 8))
  );
  alter table public.assenze enable row level security;
  grant select, insert, update on public.assenze to authenticated;
  create policy assenze_select on public.assenze for select to authenticated
    using (public.mio_ruolo() = any (array['admin', 'ufficio']));
  create policy assenze_insert on public.assenze for insert to authenticated
    with check (public.mio_ruolo() = any (array['admin', 'ufficio']));
  create policy assenze_update on public.assenze for update to authenticated
    using (public.mio_ruolo() = any (array['admin', 'ufficio']))
    with check (public.mio_ruolo() = any (array['admin', 'ufficio']));
  insert into public.assenze (persona, dal, al, tipo) values ('Prova', '2026-10-01', '2026-10-02', 'FERIE');

  for r in select id, nome, ruolo from public.utenti order by ruolo, nome loop
    perform set_config('request.jwt.claims', json_build_object('sub', r.id, 'role', 'authenticated')::text, true);
    execute 'set local role authenticated';
    select count(*) into visti from public.assenze;
    begin
      insert into public.assenze (persona, dal, al, tipo) values ('Prova ' || r.nome, '2026-10-05', '2026-10-05', 'MALATTIA');
      scritto := 'si';
    exception when others then scritto := 'no';
    end;
    execute 'reset role';
    ris := ris || r.nome || ' ' || r.ruolo || ': legge ' || visti || ', scrive ' || scritto || ' ; ';
  end loop;
  raise exception 'DRYRUN %', ris;
end $$;
