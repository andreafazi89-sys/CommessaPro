-- Ripristina rapporti_v1 e cantieri_v1 dal backup del 26/10/2026.
-- ATTENZIONE: perde anche i rapportini inseriti dopo la migrazione. Usare solo subito dopo.
begin;
update dati d set valore = b.valore
from backup_dati_20261026_banta_boanta b
where d.chiave = b.chiave;
update utenti set nome = 'Vasile Banta' where nome = 'Vasile Boanta';
commit;
