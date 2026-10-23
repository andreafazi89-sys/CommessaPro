-- Assenze (malattia, ferie, permesso) per il Riepilogo mese dei Rapportini.
-- Tabella a parte e non una chiave di dati: la malattia e' un dato sanitario e dati
-- e' leggibile da tutti gli utenti loggati, operai compresi.
-- Qui leggono e scrivono solo admin e ufficio (mio_ruolo() e' vuoto per gli utenti disattivati).
-- Nessuna cancellazione: si marca eliminato = true, come per gli altri record.
-- Tabella nuova: nessun dato esistente viene toccato, non serve backup.
begin;

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

alter table public.assenze enable row level security;
revoke all on public.assenze from anon;
grant select, insert, update on public.assenze to authenticated;

create policy assenze_select on public.assenze for select to authenticated
  using (public.mio_ruolo() = any (array['admin', 'ufficio']));
create policy assenze_insert on public.assenze for insert to authenticated
  with check (public.mio_ruolo() = any (array['admin', 'ufficio']));
create policy assenze_update on public.assenze for update to authenticated
  using (public.mio_ruolo() = any (array['admin', 'ufficio']))
  with check (public.mio_ruolo() = any (array['admin', 'ufficio']));

commit;
