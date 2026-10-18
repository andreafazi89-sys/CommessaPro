-- ROLLBACK: rimette cantieri_v1 com'era prima della rimozione e toglie il trigger.
-- ATTENZIONE: le modifiche ai cantieri fatte dopo la rimozione (giornate, SAL, ecc.) andrebbero perse.
-- Usare solo subito dopo l'applicazione, se qualcosa non funziona.
begin;
drop trigger if exists dati_scarta_economici on public.dati;
drop function if exists public.dati_scarta_economici();
update public.dati d set valore = b.valore
  from public.backup_cantieri_v1_20261018 b
  where d.chiave = 'cantieri_v1' and b.chiave = 'cantieri_v1';
commit;
-- Le tabelle di backup restano: si cancellano a mano quando non servono piu.
