-- PROVA (sola lettura): cosa conterrebbe un'istantanea e quanto pesa.
-- 30 istantanee = circa 30 volte il totale qui sotto. Limite piano Free: 500 MB di database.
select 'dati' as tabella, count(*) as righe, pg_size_pretty(sum(pg_column_size(to_jsonb(t)))::bigint) as peso from public.dati t
union all
select 'utenti', count(*), pg_size_pretty(sum(pg_column_size(to_jsonb(t)))::bigint) from public.utenti t
union all
select 'sal_foto', count(*), pg_size_pretty(sum(pg_column_size(to_jsonb(t)))::bigint) from public.sal_foto t
union all
select 'storage_foto (solo elenco)', count(*), pg_size_pretty(sum(pg_column_size(o.name))::bigint) from storage.objects o where o.bucket_id = 'Foto';
