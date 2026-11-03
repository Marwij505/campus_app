-- Tes memakai identitas acak dalam transaksi; akun dan sesi pengguna nyata tidak disentuh.
-- Bila salah satu pemeriksaan gagal, Postgres menghentikan transaksi. Semua data di-rollback.
begin;
do $$
declare
  uid uuid := gen_random_uuid(); sid uuid := gen_random_uuid(); cid uuid := gen_random_uuid();
  email text := gen_random_uuid()::text || '@example.invalid';
  k text := encode(extensions.digest(gen_random_uuid()::text,'sha256'),'hex');
  h text := repeat('a',64); bad text := repeat('b',64); r jsonb; n integer;
begin
  insert into auth.users(id,email,email_confirmed_at) values(uid,email,now());
  insert into public.profiles(id,full_name,is_enabled) values(uid,'Fixture OTP sementara',true);
  insert into auth.sessions(id,user_id,created_at,updated_at) values(sid,uid,now(),now());
  perform public.register_profile_session(sid,uid);

  -- Hanya server boleh menerbitkan, memakai, membatalkan kode, dan mencabut sesi.
  if has_function_privilege('anon','public.issue_password_reset(text,text,text,uuid)','EXECUTE')
    or has_function_privilege('authenticated','public.consume_password_reset(text,text,text)','EXECUTE')
    or has_function_privilege('authenticated','public.cancel_password_reset(text,uuid)','EXECUTE')
    or has_function_privilege('authenticated','public.revoke_password_reset_sessions(uuid)','EXECUTE')
    or has_table_privilege('authenticated','private.password_reset_challenges','SELECT')
    or not has_function_privilege('service_role','public.consume_password_reset(text,text,text)','EXECUTE')
    or not (select relrowsecurity from pg_class where oid='private.password_reset_challenges'::regclass)
  then raise exception 'OTP access boundary failed'; end if;

  r := public.issue_password_reset(email,k,h,cid);
  if (r->>'user_id')::uuid is distinct from uid or not (r->>'accepted')::boolean
  then raise exception 'eligible account issue failed'; end if;
  r := public.issue_password_reset(email,k,bad,gen_random_uuid());
  if (r->>'accepted')::boolean then raise exception 'cooldown bypassed'; end if;
  if public.consume_password_reset(email,k,bad) is not null then raise exception 'wrong code accepted'; end if;
  if public.consume_password_reset(email,k,h) is distinct from uid then raise exception 'valid code rejected'; end if;
  if public.consume_password_reset(email,k,h) is not null then raise exception 'replay accepted'; end if;

  -- Lima kesalahan mengunci kode tersebut, termasuk jika percobaan berikutnya benar.
  update private.password_reset_challenges set issued_at=now()-interval '61 seconds' where email_hash=k;
  perform public.issue_password_reset(email,k,h,gen_random_uuid());
  for n in 1..5 loop perform public.consume_password_reset(email,k,bad); end loop;
  if public.consume_password_reset(email,k,h) is not null then raise exception 'attempt cap bypassed'; end if;
  if (select attempts from private.password_reset_challenges where email_hash=k)<>5 then raise exception 'attempt counter invalid'; end if;

  -- Kirim ulang mengganti kode lama; pembatalan pengiriman lama tidak mematikan kode baru.
  update private.password_reset_challenges set issued_at=now()-interval '61 seconds' where email_hash=k;
  perform public.issue_password_reset(email,k,bad,gen_random_uuid());
  perform public.cancel_password_reset(k,cid);
  if public.consume_password_reset(email,k,h) is not null then raise exception 'old code after resend accepted'; end if;
  if public.consume_password_reset(email,k,bad) is distinct from uid then raise exception 'new code cancelled by old delivery'; end if;

  update private.password_reset_challenges set issued_at=now()-interval '61 seconds' where email_hash=k;
  cid := gen_random_uuid();
  perform public.issue_password_reset(email,k,h,cid);
  perform public.cancel_password_reset(k,cid);
  if public.consume_password_reset(email,k,h) is not null then raise exception 'cancelled delivery usable'; end if;

  update private.password_reset_challenges set issued_at=now()-interval '61 seconds' where email_hash=k;
  perform public.issue_password_reset(email,k,h,gen_random_uuid());
  update private.password_reset_challenges set expires_at=now() where email_hash=k;
  if public.consume_password_reset(email,k,h) is not null then raise exception 'expired code accepted'; end if;

  update private.password_reset_challenges set issued_at=now()-interval '61 seconds' where email_hash=k;
  perform public.issue_password_reset(email,k,h,gen_random_uuid());
  update auth.users u set email='changed-'||u.email where id=uid;
  if public.consume_password_reset(email,k,h) is not null then raise exception 'old email accepted'; end if;
  update auth.users u set email=substring(u.email from 9) where id=uid;

  update private.password_reset_challenges set issued_at=now()-interval '61 seconds' where email_hash=k;
  update public.profiles set is_enabled=false where id=uid;
  r := public.issue_password_reset(email,k,h,gen_random_uuid());
  if r->>'user_id' is not null then raise exception 'disabled account issued code'; end if;
  update public.profiles set is_enabled=true where id=uid;

  -- Tidak terdaftar: tetap tercatat untuk cooldown, tetapi tidak punya penerima.
  update private.password_reset_challenges set issued_at=now()-interval '61 seconds' where email_hash=k;
  r := public.issue_password_reset('unknown-'||email,k,h,gen_random_uuid());
  if r->>'user_id' is not null or not (r->>'accepted')::boolean then raise exception 'unknown handling failed'; end if;
  if public.consume_password_reset('unknown-'||email,k,h) is not null then raise exception 'unknown reset succeeded'; end if;

  -- MFA aktif tidak boleh dilewati oleh pemulihan email saja.
  insert into auth.mfa_factors(id,user_id,factor_type,status,created_at,updated_at)
  values(gen_random_uuid(),uid,'totp','verified',now(),now());
  update private.password_reset_challenges set issued_at=now()-interval '61 seconds' where email_hash=k;
  r := public.issue_password_reset(email,k,h,gen_random_uuid());
  if r->>'user_id' is not null then raise exception 'MFA bypass issued'; end if;

  perform public.revoke_password_reset_sessions(uid);
  if exists(select 1 from private.app_sessions where user_id=uid and revoked_at is null)
  then raise exception 'old app session still active'; end if;
end $$;
select 'PASS: OTP permissions, cooldown, wrong code, replay, attempt cap, resend, cancel, expiry, email change, disabled/unknown/MFA, session revocation; fixtures rolled back' as result;
rollback;
