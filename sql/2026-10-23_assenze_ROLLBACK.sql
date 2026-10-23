-- Annulla 2026-10-23_assenze.sql. ATTENZIONE: cancella anche le assenze inserite.
-- Prima del drop le copia in backup_assenze_rollback (non accessibile dall'app).
begin;
create table public.backup_assenze_rollback as select * from public.assenze;
alter table public.backup_assenze_rollback enable row level security;
revoke all on public.backup_assenze_rollback from anon, authenticated;
drop table public.assenze;
commit;
