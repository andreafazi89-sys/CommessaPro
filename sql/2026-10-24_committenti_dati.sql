-- Dati del committente per le annotazioni del foglio ore ("Dove hanno lavorato" nei Rapportini):
-- ragione sociale, CF, P.IVA, sede, importo lavori, fine lavori prevista.
-- Tabella a parte e non in dati: dati e' leggibile da tutti gli utenti loggati e cantieri_v1
-- finisce sui telefoni degli operai. Importi e codici fiscali li vedono e li scrivono solo
-- l'admin e chi gestisce le assenze (oggi Pamela), scelta di Andrea del 24/10/2026.
-- Usa la funzione gestisce_assenze() creata da 2026-10-23_assenze.sql.
-- Nessun dato esistente viene toccato: non serve backup.
begin;

create table public.committenti_dati (
  chiave text primary key,                -- nome del committente come nell'app, maiuscolo (es. 'SQUARE SPV')
  ragione_sociale text,                   -- nome completo per il foglio (es. 'Square SPV s.r.l.')
  cf text,
  piva text,
  sede text,                              -- indirizzo del committente
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

commit;
