-- PROVA A VUOTO: crea la tabella, simula ogni utente reale e poi ANNULLA TUTTO.
-- Il risultato compare come errore "DRYRUN ...": e' voluto.
-- Atteso: Andrea e Pamela leggono 1 riga e scrivono; tutti gli altri leggono 0 righe e non scrivono.
do $prova$
declare ris text := ''; r record; letti int; scritto text;
begin

create table public.committenti_dati (
  chiave text primary key,                -- nome del committente come nell'app, maiuscolo (es. 'SQUARE SPV')
  importo text,                           -- testo libero: '€ 11.993,10', 'A consuntivo (c.a. € 10.000,00)'
  fine_prevista date,
  note text,
  autore text,
  timestamp timestamptz not null default now()
);

-- Lettura e scrittura solo per l'admin e chi gestisce le assenze (oggi Pamela).
-- Niente delete: un dato sbagliato si corregge, un campo vuoto si svuota.
alter table public.committenti_dati enable row level security;
revoke all on public.committenti_dati from anon;
revoke all on public.committenti_dati from authenticated;
grant select, insert, update on public.committenti_dati to authenticated;
create policy committenti_dati_select on public.committenti_dati for select to authenticated using (public.gestisce_assenze());
create policy committenti_dati_insert on public.committenti_dati for insert to authenticated with check (public.gestisce_assenze());
create policy committenti_dati_update on public.committenti_dati for update to authenticated
  using (public.gestisce_assenze()) with check (public.gestisce_assenze());

  insert into public.committenti_dati (chiave, importo) values ('PROVA', '€ 1.000,00');

  for r in select id, nome, ruolo from public.utenti order by ruolo, nome loop
    perform set_config('request.jwt.claims', json_build_object('sub', r.id, 'role', 'authenticated')::text, true);
    execute 'set local role authenticated';
    select count(*) into letti from public.committenti_dati;
    begin
      insert into public.committenti_dati (chiave, importo) values ('PROVA ' || r.id, '€ 2,00');
      scritto := 'si';
    exception when others then scritto := 'no';
    end;
    execute 'reset role';
    ris := ris || r.nome || ' ' || r.ruolo || ': legge ' || letti || ', scrive ' || scritto || ' ; ';
  end loop;
  raise exception 'DRYRUN %', ris;
end $prova$;
