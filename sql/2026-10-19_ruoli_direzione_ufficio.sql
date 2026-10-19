-- Nuovi ruoli: admin, direzione, ufficio, operaio (il ruolo segretaria sparisce).
--   direzione: Fabio Pierantoni, Rino Lenti
--   ufficio:   Pamela Pierantoni, Antonella Ventrella
-- Eseguire SUBITO DOPO il deploy su main del codice che riconosce i nuovi ruoli.
begin;

-- 1. Backup della tabella utenti (serve al rollback)
create table public.backup_utenti_20261019 as
  select id, email, nome, ruolo, attivo, permessi, now() as salvato_il from public.utenti;
alter table public.backup_utenti_20261019 enable row level security;
revoke all on public.backup_utenti_20261019 from anon, authenticated;

-- 2. Nuovi ruoli (per nome: sono 4 persone note)
update public.utenti set ruolo = 'direzione' where ruolo = 'segretaria' and nome in ('Fabio Pierantoni', 'Rino Lenti');
update public.utenti set ruolo = 'ufficio'   where ruolo = 'segretaria' and nome in ('Pamela Pierantoni', 'Antonella Ventrella');

-- 3. Solo i quattro ruoli previsti (fallisce se resta qualcuno "segretaria": la transazione si annulla)
alter table public.utenti add constraint utenti_ruolo_valido
  check (ruolo in ('admin', 'direzione', 'ufficio', 'operaio'));

-- 4. dati: scrittura completa per admin, direzione e ufficio (prima admin e segretaria)
alter policy dati_write_admin_segretaria on public.dati
  using (public.mio_ruolo() = any (array['admin', 'direzione', 'ufficio']))
  with check (public.mio_ruolo() = any (array['admin', 'direzione', 'ufficio']));
alter policy dati_write_admin_segretaria on public.dati rename to dati_write_admin_direzione_ufficio;

commit;
