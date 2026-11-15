-- RPC publik tetap biasa; akses tabel sesi hanya melalui fungsi privat terikat JWT.
alter function public.revoke_profile_session() set schema private;
alter function public.profile_session_status() set schema private;
create function public.revoke_profile_session() returns void
language sql security invoker set search_path = ''
as $$ select private.revoke_profile_session(); $$;
create function public.profile_session_status() returns jsonb
language sql security invoker set search_path = ''
as $$ select private.profile_session_status(); $$;
revoke all on function public.revoke_profile_session(), public.profile_session_status() from public, anon;
grant execute on function public.revoke_profile_session(), public.profile_session_status() to authenticated;
