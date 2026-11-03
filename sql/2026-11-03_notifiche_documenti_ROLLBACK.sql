-- Annulla 2026-11-03_notifiche_documenti.sql. I documenti caricati NON si toccano.
-- Prima del drop copia le notifiche in backup_notifiche_rollback (non accessibile dall'app).
begin;
create table public.backup_notifiche_rollback as select * from public.notifiche;
alter table public.backup_notifiche_rollback enable row level security;
revoke all on public.backup_notifiche_rollback from anon, authenticated;
drop trigger documenti_notifica on public.documenti_cantiere;
drop function public.notifica_documento();
drop function public.riceve_notifiche();
drop table public.notifiche;
alter table public.utenti drop column notifiche_documenti;
commit;
