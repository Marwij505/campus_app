-- Authorized M2 demo staff. Run after the operator creates Herman and Yanto in Auth.
-- No Auth account/password is created here; the supplied email is a dummy.
begin;
do $$ declare u uuid; begin
 select id into strict u from auth.users where lower(email)=lower('hermansuyanto5@gmail.com');
 if exists(select 1 from public.students where user_id=u) then raise exception 'Staff must not be provisioned as a student'; end if;
 if exists(select 1 from public.profiles where id=u and (role<>'lecturer' or full_name<>'Herman')) then raise exception 'Existing profile differs; no overwrite'; end if;
 insert into public.profiles(id,full_name,role,is_enabled,verification_status)
 values(u,'Herman','lecturer',true,'unverified') on conflict do nothing;
 insert into private.m2_staff_identities(user_id,login_id,email_delivery_enabled)
 values(u,'0221028503',false) on conflict(user_id) do update set email_delivery_enabled=false
 where m2_staff_identities.login_id=excluded.login_id;
 if not exists(select 1 from private.m2_staff_identities where user_id=u and login_id='0221028503' and not email_delivery_enabled) then raise exception 'Identity conflict'; end if;
 insert into private.m2_staff(user_id,permission) values(u,'academic'),(u,'validator') on conflict do nothing;
 -- Fill only the previously empty advisor fields, never overwrite an advisor.
 update public.students set advisor_name='Herman',advisor_code='0221028503'
 where user_id=(select id from public.profiles where full_name='Prismatine Dante Viergo')
 and advisor_name is null and advisor_code is null;
end $$;
do $$ declare u uuid; begin
 select id into strict u from auth.users where lower(email)=lower('yantokurniawan7@gmail.com');
 if exists(select 1 from public.students where user_id=u) then raise exception 'Staff must not be provisioned as a student'; end if;
 if exists(select 1 from public.profiles where id=u and (role<>'bap' or full_name<>'Yanto')) then raise exception 'Existing profile differs; no overwrite'; end if;
 insert into public.profiles(id,full_name,role,is_enabled,verification_status)
 values(u,'Yanto','bap',true,'unverified') on conflict do nothing;
 insert into private.m2_staff_identities(user_id,login_id,email_delivery_enabled)
 values(u,'112233',false) on conflict(user_id) do update set email_delivery_enabled=false
 where m2_staff_identities.login_id=excluded.login_id;
 if not exists(select 1 from private.m2_staff_identities where user_id=u and login_id='112233' and not email_delivery_enabled) then raise exception 'Identity conflict'; end if;
 if exists(select 1 from private.m2_staff where user_id=u and permission not in ('finance','reconcile')) then raise exception 'Unexpected staff permissions'; end if;
 insert into private.m2_staff(user_id,permission) values(u,'finance'),(u,'reconcile') on conflict do nothing;
end $$;
commit;
