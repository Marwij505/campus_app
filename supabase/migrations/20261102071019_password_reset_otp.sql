-- OTP disimpan sebagai HMAC, bukan kode asli. Hanya Edge Function boleh mengaksesnya.
create table private.password_reset_challenges (
  email_hash text primary key check (email_hash ~ '^[a-f0-9]{64}$'),
  challenge_id uuid not null,
  user_id uuid references auth.users(id) on delete cascade,
  code_hash text not null check (code_hash ~ '^[a-f0-9]{64}$'),
  issued_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '10 minutes',
  attempts integer not null default 0 check (attempts between 0 and 5),
  consumed_at timestamptz
);
alter table private.password_reset_challenges enable row level security;
revoke all on private.password_reset_challenges from public, anon, authenticated;
create index password_reset_expiry_idx on private.password_reset_challenges(expires_at);
create index password_reset_user_idx on private.password_reset_challenges(user_id);

-- Alamat yang tidak terdaftar tetap mendapat cooldown serupa, tanpa mengirim email.
create function public.issue_password_reset(p_email text, p_key text, p_digest text, p_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare account_id uuid; saved_id uuid;
begin
  if length(p_email) > 254 then raise exception 'Invalid email'; end if;
  select u.id into account_id from auth.users u
  join public.profiles p on p.id = u.id and p.is_enabled
  where lower(u.email) = lower(p_email) and u.email_confirmed_at is not null
    and u.deleted_at is null and (u.banned_until is null or u.banned_until <= now())
    -- Pemulihan email tidak boleh menjadi jalan pintas melewati MFA.
    and not exists (select 1 from auth.mfa_factors f where f.user_id=u.id and f.status='verified');
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

-- Kunci baris membuat dua permintaan bersamaan tidak dapat memakai OTP yang sama.
create function public.consume_password_reset(p_email text, p_key text, p_digest text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare challenge private.password_reset_challenges%rowtype; account_id uuid;
begin
  select * into challenge from private.password_reset_challenges where email_hash=p_key for update;
  if not found or challenge.consumed_at is not null or challenge.expires_at <= now()
    or challenge.attempts >= 5 then return null; end if;
  update private.password_reset_challenges set attempts=attempts+1 where email_hash=p_key;
  if challenge.code_hash <> p_digest then return null; end if;
  update private.password_reset_challenges set consumed_at=now() where email_hash=p_key;
  select u.id into account_id from auth.users u join public.profiles p on p.id=u.id and p.is_enabled
  where u.id=challenge.user_id and lower(u.email)=lower(p_email)
    and u.email_confirmed_at is not null and u.deleted_at is null
    and (u.banned_until is null or u.banned_until <= now())
    and not exists (select 1 from auth.mfa_factors f where f.user_id=u.id and f.status='verified');
  return account_id;
end $$;

-- Kegagalan pengiriman hanya membatalkan kode milik pengiriman tersebut.
create function public.cancel_password_reset(p_key text, p_id uuid)
returns void language sql security definer set search_path = '' as $$
  update private.password_reset_challenges set consumed_at=now()
  where email_hash=p_key and challenge_id=p_id;
$$;

-- JWT lama mungkin belum kedaluwarsa; RLS aplikasi menolaknya melalui revoked_at.
create function public.revoke_password_reset_sessions(p_user uuid)
returns void language sql security definer set search_path = '' as $$
  update private.app_sessions set revoked_at=now() where user_id=p_user and revoked_at is null;
  update private.password_reset_challenges set consumed_at=now() where user_id=p_user and consumed_at is null;
$$;
revoke all on function public.issue_password_reset(text,text,text,uuid) from public, anon, authenticated;
revoke all on function public.consume_password_reset(text,text,text) from public, anon, authenticated;
revoke all on function public.cancel_password_reset(text,uuid) from public, anon, authenticated;
revoke all on function public.revoke_password_reset_sessions(uuid) from public, anon, authenticated;
grant execute on function public.issue_password_reset(text,text,text,uuid) to service_role;
grant execute on function public.consume_password_reset(text,text,text) to service_role;
grant execute on function public.cancel_password_reset(text,uuid) to service_role;
grant execute on function public.revoke_password_reset_sessions(uuid) to service_role;
