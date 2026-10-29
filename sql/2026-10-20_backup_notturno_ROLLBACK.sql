-- Toglie il backup notturno: ferma il job e cancella lo schema backup con tutte le istantanee.
-- Non tocca i dati dell'app. pg_cron resta installato (innocuo, nessun altro job).
begin;
select cron.unschedule('backup-notturno');
drop schema if exists backup cascade;
commit;
