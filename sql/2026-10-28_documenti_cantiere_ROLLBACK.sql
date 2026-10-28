-- ROLLBACK di 2026-10-28_documenti_cantiere.sql
-- ATTENZIONE: cancella l'elenco dei documenti. Prima esportare la tabella se contiene righe.
-- I file nel bucket Documenti vanno svuotati dal pannello Storage prima di eliminare il bucket.
begin;
drop policy if exists "Documenti select" on storage.objects;
drop policy if exists "Documenti insert" on storage.objects;
delete from storage.buckets where id = 'Documenti';
drop table if exists public.documenti_cantiere;
drop function if exists public.vede_documenti();
commit;
