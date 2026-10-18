-- Ripristina is_admin() e la lettura utenti come prima del 18/10/2026.
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from utenti where lower(email) = lower(auth.email())
                 and ruolo in ('admin','segretaria') and coalesce(attivo, true) = true);
$$;
grant execute on function public.is_admin(), public.mio_ruolo() to anon, authenticated;
alter policy utenti_select_propria_o_admin on public.utenti using (true);
alter policy utenti_select_propria_o_admin on public.utenti rename to utenti_select_authenticated;
