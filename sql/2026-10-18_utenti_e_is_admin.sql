-- 1. is_admin(): solo admin (non piu segretaria), riconosciuto per ID come mio_ruolo().
--    Usata da: sal_foto (update/delete) e storage Foto/sal (update/delete).
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.utenti where id = auth.uid() and ruolo = 'admin' and coalesce(attivo, true));
$$;
revoke execute on function public.is_admin() from public, anon;
revoke execute on function public.mio_ruolo() from public, anon;
grant execute on function public.is_admin(), public.mio_ruolo() to authenticated;

-- 2. utenti: ognuno legge solo la propria riga, l'admin legge tutti.
alter policy utenti_select_authenticated on public.utenti
  using (id = auth.uid() or public.mio_ruolo() = 'admin');
alter policy utenti_select_authenticated on public.utenti rename to utenti_select_propria_o_admin;
