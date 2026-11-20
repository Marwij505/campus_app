-- Operator-supplied dummy email must never receive a recovery message.
alter table private.m2_staff_identities add column email_delivery_enabled boolean not null default true;
create or replace function public.issue_password_reset(p_email text, p_key text, p_digest text, p_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare account_id uuid; saved_id uuid;
begin
  if length(p_email) > 254 then raise exception 'Invalid email'; end if;
  select u.id into account_id from auth.users u
  join public.profiles p on p.id = u.id and p.is_enabled
  where lower(u.email) = lower(p_email) and u.email_confirmed_at is not null
    and u.deleted_at is null and (u.banned_until is null or u.banned_until <= now())
    and not exists (select 1 from auth.mfa_factors f where f.user_id=u.id and f.status='verified')
    and not exists (select 1 from private.m2_staff_identities i where i.user_id=u.id and not i.email_delivery_enabled);
  delete from private.password_reset_challenges where expires_at < now() - interval '1 day';
  insert into private.password_reset_challenges(email_hash, challenge_id, user_id, code_hash)
  values(p_key, p_id, account_id, p_digest)
  on conflict(email_hash) do update set challenge_id=excluded.challenge_id,
    user_id=excluded.user_id, code_hash=excluded.code_hash, issued_at=now(),
    expires_at=now()+interval '10 minutes', attempts=0, consumed_at=null
  where private.password_reset_challenges.issued_at <= now()-interval '60 seconds'
  returning challenge_id into saved_id;
  return jsonb_build_object('accepted', saved_id is not null,
    'user_id', case when saved_id is not null then account_id else null end);
end $$;
revoke all on function public.issue_password_reset(text,text,text,uuid) from public,anon,authenticated;
grant execute on function public.issue_password_reset(text,text,text,uuid) to service_role;
