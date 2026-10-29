-- Documenti del cantiere (DDT, bolle, fatture): foto caricate dalla scheda Cantiere.
-- Le fatture sono dati economici: bucket PRIVATO (niente link pubblici, a differenza di Foto)
-- e tabella a parte, non una chiave di dati (dati e' leggibile anche dagli operai).
-- Vedono, caricano e correggono solo admin, direzione e ufficio attivi. Operai: nulla.
-- Nessuna cancellazione: si marca eliminato = true, il file resta nel bucket.
-- Migrazione solo additiva: non tocca tabelle o file esistenti, quindi nessun backup da fare.
begin;

-- 1. vede_documenti(): admin, direzione o ufficio attivo (mio_ruolo e' vuoto se disattivato)
create or replace function public.vede_documenti() returns boolean
  language sql stable security definer set search_path to 'public' as $$
  select coalesce(public.mio_ruolo() = any (array['admin', 'direzione', 'ufficio']), false);
$$;
revoke execute on function public.vede_documenti() from public, anon;
grant execute on function public.vede_documenti() to authenticated;

-- 2. Tabella
create table public.documenti_cantiere (
  id uuid primary key default gen_random_uuid(),
  cantiere_id text not null,              -- id del record in cantieri_v1
  tipo text not null,
  data date,                              -- data scritta sul documento
  fornitore text,
  numero text,
  note text,
  path text not null unique,              -- oggetto nel bucket Documenti
  caricato_da uuid not null default auth.uid(),
  caricato_da_nome text,
  creato_il timestamptz not null default now(),
  eliminato boolean not null default false,
  timestamp timestamptz not null default now(),
  constraint documenti_tipo_valido check (tipo in ('DDT', 'BOLLA', 'FATTURA'))
);
create index documenti_cantiere_cant on public.documenti_cantiere (cantiere_id);

alter table public.documenti_cantiere enable row level security;
revoke all on public.documenti_cantiere from anon;
grant select, insert, update on public.documenti_cantiere to authenticated;
create policy documenti_select on public.documenti_cantiere for select to authenticated
  using (public.vede_documenti());
create policy documenti_insert on public.documenti_cantiere for insert to authenticated
  with check (public.vede_documenti() and caricato_da = auth.uid());
create policy documenti_update on public.documenti_cantiere for update to authenticated
  using (public.vede_documenti()) with check (public.vede_documenti());

-- 3. Bucket privato: solo immagini, max 10 MB
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('Documenti', 'Documenti', false, 10485760, array['image/jpeg', 'image/png', 'image/webp']);

-- 4. Storage: lettura e caricamento per chi vede i documenti. Niente update e delete:
--    un file caricato non si sovrascrive e non si cancella dall'app.
create policy "Documenti select" on storage.objects for select to authenticated
  using (bucket_id = 'Documenti' and public.vede_documenti());
create policy "Documenti insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'Documenti' and public.vede_documenti());

commit;
