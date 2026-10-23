-- Annulla 2026-10-23_assenze.sql. ATTENZIONE: cancella anche le assenze inserite.
-- Prima del drop le copia in backup_assenze_rollback (non accessibile dall'app).
begin;
create table public.backup_assenze_rollback as select * from public.assenze;
alter table public.backup_assenze_rollback enable row level security;
revoke all on public.backup_assenze_rollback from anon, authenticated;
drop function public.assenze_mese(date, date);
drop table public.assenze;
drop function public.gestisce_assenze();
alter table public.utenti drop column gestisce_assenze;
commit;
