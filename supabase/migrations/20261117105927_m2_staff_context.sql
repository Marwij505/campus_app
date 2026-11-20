-- Separate NIDN identity: staff never require a fictitious student/enrollment.
create table private.m2_staff_identities (
 user_id uuid primary key references public.profiles(id),
 login_id text not null unique check(login_id ~ '^[0-9]{8,20}$')
);
alter table private.m2_staff_identities enable row level security;
revoke all on private.m2_staff_identities from public,anon,authenticated;

create function private.m2_staff_identity() returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 if not private.profile_session_valid() then raise exception 'Sesi tidak valid' using errcode='42501'; end if;
 return (select jsonb_build_object('user_id',i.user_id,'login_id',i.login_id)
 from private.m2_staff_identities i join public.profiles p on p.id=i.user_id
 where i.user_id=auth.uid() and p.role in ('lecturer','bap') and p.is_enabled
 and exists(select 1 from private.m2_staff s where s.user_id=i.user_id));
end $$;
create function public.m2_staff_identity() returns jsonb
language sql security invoker set search_path='' as $$ select private.m2_staff_identity() $$;
revoke all on function private.m2_staff_identity(),public.m2_staff_identity() from public,anon;
grant execute on function private.m2_staff_identity(),public.m2_staff_identity() to authenticated;

-- Keep the M1 Edge Function contract and its rate limits/session lifetime.
create function private.m2_resolve_login(p_nim text) returns text
language sql security definer set search_path='' as $$
 select coalesce(
  (select u.email from auth.users u join public.profiles p on p.id=u.id
   join public.students s on s.user_id=p.id where s.nim=p_nim and p.is_enabled and p.role='student'),
  (select u.email from auth.users u join public.profiles p on p.id=u.id
   join private.m2_staff_identities i on i.user_id=p.id
   where i.login_id=p_nim and p.is_enabled and p.role in ('lecturer','bap')
   and exists(select 1 from private.m2_staff s where s.user_id=p.id))
 );
$$;
revoke all on function private.m2_resolve_login(text) from public,anon,authenticated;
grant usage on schema private to service_role;
grant execute on function private.m2_resolve_login(text) to service_role;
create or replace function public.resolve_student_login(p_nim text) returns text
language sql security invoker set search_path='' as $$ select private.m2_resolve_login(p_nim) $$;
revoke all on function public.resolve_student_login(text) from public,anon,authenticated;
grant execute on function public.resolve_student_login(text) to service_role;

alter function private.m2_snapshot(text) rename to m2_student_snapshot;
revoke all on function private.m2_student_snapshot(text) from public,anon,authenticated;
create function private.m2_snapshot(p_period text default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare per public.m2_periods; permissions jsonb;
begin
 if not private.m2_authorized(auth.uid()) then raise exception 'Sesi tidak valid' using errcode='42501'; end if;
 if private.m2_staff_identity() is null then return private.m2_student_snapshot(p_period); end if;
 select coalesce(jsonb_agg(permission),'[]') into permissions from private.m2_staff where user_id=auth.uid();
 if p_period is not null then
  select * into strict per from public.m2_periods where id=p_period;
 else
  select * into per from public.m2_periods
  order by case when now()>=starts_at and now()<ends_at then 0
   when now()>=registration_opens and now()<starts_at then 1 else 2 end,starts_at desc limit 1;
 end if;
 return jsonb_build_object('available',true,'server_now',now(),'staff',true,'stage','Layanan akademik petugas',
  'period',case when per.id is not null then to_jsonb(per) else '{}'::jsonb end,
  'periods',(select coalesce(jsonb_agg(to_jsonb(p) order by starts_at),'[]') from public.m2_periods p),
  'permissions',permissions,'registration','{}'::jsonb,'notifications','[]'::jsonb);
end $$;
revoke all on function private.m2_snapshot(text) from public,anon;
grant execute on function private.m2_snapshot(text) to authenticated;

-- Staff search by the academic identifier; internal UUIDs stay out of the form.
create function private.m2_review_student(p_identity text,p_period text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid; result jsonb;
begin
 if not private.profile_session_valid() or not exists(select 1 from private.m2_staff where user_id=auth.uid()) then
  raise exception 'Akses staf diperlukan' using errcode='42501';
 end if;
 select user_id into strict u from public.students where nim=trim(p_identity) or user_id::text=trim(p_identity);
 result:=private.m2_review(u,p_period);
 return result||jsonb_build_object('student',(select jsonb_build_object('user_id',s.user_id,'nim',s.nim,'name',p.full_name)
  from public.students s join public.profiles p on p.id=s.user_id where s.user_id=u));
end $$;
create function public.m2_review_student(p_identity text,p_period text) returns jsonb
language sql security invoker set search_path='' as $$ select private.m2_review_student(p_identity,p_period) $$;
revoke all on function private.m2_review_student(text,text),public.m2_review_student(text,text) from public,anon;
grant execute on function private.m2_review_student(text,text),public.m2_review_student(text,text) to authenticated;
