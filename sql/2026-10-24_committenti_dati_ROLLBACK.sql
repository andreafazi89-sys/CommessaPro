-- Annulla 2026-10-24_committenti_dati.sql. ATTENZIONE: cancella anche i dati inseriti.
-- Prima del drop li copia in backup_committenti_dati_rollback (non accessibile dall'app).
begin;
create table public.backup_committenti_dati_rollback as select * from public.committenti_dati;
alter table public.backup_committenti_dati_rollback enable row level security;
revoke all on public.backup_committenti_dati_rollback from anon, authenticated;
drop table public.committenti_dati;
commit;
