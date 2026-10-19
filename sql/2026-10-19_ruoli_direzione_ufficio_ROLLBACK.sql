-- Ripristina ruoli e policy come prima del 19/10/2026 (tutti i non admin/operai tornano segretaria).
-- Da eseguire insieme al revert del codice su main.
begin;
alter table public.utenti drop constraint if exists utenti_ruolo_valido;
update public.utenti u set ruolo = b.ruolo
  from public.backup_utenti_20261019 b where b.id = u.id;
alter policy dati_write_admin_direzione_ufficio on public.dati
  using (public.mio_ruolo() = any (array['admin', 'segretaria']))
  with check (public.mio_ruolo() = any (array['admin', 'segretaria']));
alter policy dati_write_admin_direzione_ufficio on public.dati rename to dati_write_admin_segretaria;
commit;
