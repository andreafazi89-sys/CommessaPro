-- PROVA A VUOTO: esegue la migrazione, simula ogni utente reale e poi ANNULLA TUTTO.
-- Il risultato compare come errore "DRYRUN ...": e voluto.
-- Atteso: admin, direzione e ufficio vedono la riga di prova, ne aggiungono una e caricano
-- il file; operai e utenti disattivati non vedono nulla e non scrivono.
do $prova$
declare ris text := ''; r record; visti int; scritto text; file_ok text; pubblico boolean;
begin


-- 1. vede_documenti(): admin, direzione o ufficio attivo (mio_ruolo e' vuoto se disattivato)
create or replace function public.vede_documenti() returns boolean
  language sql stable security definer set search_path to 'public' as $f$
  select coalesce(public.mio_ruolo() = any (array['admin', 'direzione', 'ufficio']), false);
$f$;
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


  select public into pubblico from storage.buckets where id = 'Documenti';
  ris := 'bucket pubblico: ' || pubblico || ' ; ';
  insert into public.documenti_cantiere (cantiere_id, tipo, path, caricato_da)
    values ('prova', 'FATTURA', 'cant_prova/0.jpg', (select id from public.utenti where ruolo = 'admin' limit 1));
  for r in select id, nome, ruolo, coalesce(attivo, true) attivo from public.utenti order by ruolo, nome loop
    perform set_config('request.jwt.claims', json_build_object('sub', r.id, 'role', 'authenticated')::text, true);
    execute 'set local role authenticated';
    select count(*) into visti from public.documenti_cantiere where path = 'cant_prova/0.jpg';
    begin
      insert into public.documenti_cantiere (cantiere_id, tipo, path) values ('prova', 'DDT', 'cant_prova/' || r.id || '.jpg');
      scritto := 'si';
    exception when others then scritto := 'no';
    end;
    begin
      insert into storage.objects (bucket_id, name, owner) values ('Documenti', 'cant_prova/' || r.id || '.jpg', r.id);
      file_ok := 'si';
    exception when others then file_ok := 'no (' || left(sqlerrm, 50) || ')';
    end;
    execute 'reset role';
    ris := ris || r.nome || ' ' || r.ruolo || case when r.attivo then '' else ' (disattivato)' end
               || ': vede ' || visti || ', scrive ' || scritto || ', carica file ' || file_ok || ' ; ';
  end loop;
  raise exception 'DRYRUN %', ris;
end $prova$;
