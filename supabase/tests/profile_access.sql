-- Jalankan sebagai administrator di database pengembangan dengan profil Dante tersedia.
-- Seluruh perubahan berada di transaksi dan di-ROLLBACK, termasuk sesi/benda uji.
begin;
-- Identitas pembanding hanya hidup dalam transaksi, tanpa password atau email login.
insert into auth.users(id) values('33333333-3333-4333-8333-333333333333');
insert into public.profiles(id,full_name,is_enabled) values('33333333-3333-4333-8333-333333333333','Pembanding tes RLS',true);
insert into public.students(user_id,nim,university,faculty,program)
values('33333333-3333-4333-8333-333333333333','99999999999999999999','Uji','Uji','Uji');
insert into auth.sessions(id,user_id,created_at,updated_at)
values('44444444-4444-4444-8444-444444444444','33333333-3333-4333-8333-333333333333',now(),now());
select public.register_profile_session('44444444-4444-4444-8444-444444444444','33333333-3333-4333-8333-333333333333');
insert into auth.sessions(id,user_id,created_at,updated_at)
select 'e5c6c061-4894-4bbe-9732-87fdb93a4d35',user_id,now(),now()
from public.students where nim='20240801001';
select public.register_profile_session('e5c6c061-4894-4bbe-9732-87fdb93a4d35',user_id)
from public.students where nim='20240801001';
select set_config('request.jwt.claims',jsonb_build_object(
  'sub',user_id,'session_id','e5c6c061-4894-4bbe-9732-87fdb93a4d35',
  'role','authenticated','user_metadata',jsonb_build_object('role','admin'))::text,true)
from public.students where nim='20240801001';
set local role authenticated;
do $$ begin
  if (select count(*) from public.profiles) <> 1 then raise exception 'own profile read failed'; end if;
  if (select count(*) from public.students) <> 1 then raise exception 'own student read failed'; end if;
  update public.profiles set preferred_name='Uji transaksi',avatar_variant='female' where id=auth.uid();
  if not found then raise exception 'own update failed'; end if;
  begin
    update public.profiles set role='bap' where id=auth.uid();
    raise exception 'role escalation unexpectedly allowed';
  exception when insufficient_privilege then null; end;
  begin
    update public.profiles set full_name='Palsu',is_enabled=true,verification_status='verified' where id=auth.uid();
    raise exception 'official identity edit unexpectedly allowed';
  exception when insufficient_privilege then null; end;
  begin
    update public.students set nim='99999999999' where user_id=auth.uid();
    raise exception 'nim edit unexpectedly allowed';
  exception when insufficient_privilege then null; end;
  begin
    perform public.resolve_student_login('20240801001');
    raise exception 'email lookup unexpectedly allowed';
  exception when insufficient_privilege then null; end;
  begin
    perform public.register_profile_session('e5c6c061-4894-4bbe-9732-87fdb93a4d35',auth.uid());
    raise exception 'session renewal unexpectedly allowed';
  exception when insufficient_privilege then null; end;
  begin
    update public.profiles set avatar_variant='unknown' where id=auth.uid();
    raise exception 'invalid avatar accepted';
  exception when check_violation then null; end;
  insert into storage.objects(bucket_id,name) values('student-avatars',auth.uid()::text||'/test-policy.png');
  if (select count(*) from storage.objects where name like '%/test-policy.png')<>1 then raise exception 'own storage read failed'; end if;
  begin
    insert into storage.objects(bucket_id,name) values('student-avatars','someone-else/test-policy.png');
    raise exception 'foreign storage write unexpectedly allowed';
  exception when insufficient_privilege then null; end;
end $$;
-- Lima bagian biodata boleh ditulis pemilik; data resmi/keuangan tetap read-only.
do $$ declare t text; n integer; begin
  foreach t in array array['student_biodata','student_education','student_family','student_employment','student_accessibility'] loop
    execute format('insert into public.%I(user_id) values(auth.uid()) on conflict do nothing',t);
    execute format('select count(*) from public.%I',t) into n;
    if n<>1 then raise exception 'own section read failed: %',t; end if;
    begin
      execute format('insert into public.%I(user_id) values(''33333333-3333-4333-8333-333333333333'')',t);
      raise exception 'foreign section insert allowed: %',t;
    exception when insufficient_privilege then null; end;
    begin
      execute format('update public.%I set user_id=''33333333-3333-4333-8333-333333333333'' where user_id=auth.uid()',t);
      raise exception 'owner change allowed: %',t;
    exception when insufficient_privilege then null; end;
  end loop;
  update public.student_biodata set phone='+6281234567890',birth_date='2004-02-29' where user_id=auth.uid();
  if not exists(select 1 from public.profiles where phone='+6281234567890') then raise exception 'phone sync failed'; end if;
  begin
    update public.student_biodata set nik='123' where user_id=auth.uid();
    raise exception 'invalid NIK accepted';
  exception when check_violation then null; end;
  begin
    update public.students set campus_email='changed@example.com' where user_id=auth.uid();
    raise exception 'campus email edit allowed';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.student_finance(user_id,period,category,description,amount,billed_on)
    values(auth.uid(),'Uji','Uji','Uji',1,current_date);
    raise exception 'student finance insert allowed';
  exception when insufficient_privilege then null; end;
  insert into public.student_documents(user_id,kind,path,file_name,mime_type,size_bytes)
  values(auth.uid(),'passport',auth.uid()::text||'/rls-test.pdf','rls-test.pdf','application/pdf',100)
  on conflict(user_id,kind) do update set path=excluded.path,file_name=excluded.file_name;
  begin
    update public.student_documents set path='someone-else/a.pdf' where user_id=auth.uid();
    raise exception 'foreign document path allowed';
  exception when check_violation then null; end;
  insert into storage.objects(bucket_id,name) values('student-documents',auth.uid()::text||'/rls-test.pdf');
  if not exists(select 1 from storage.objects where bucket_id='student-documents') then raise exception 'own document storage unreadable'; end if;
  begin
    insert into storage.objects(bucket_id,name) values('student-documents','someone-else/a.pdf');
    raise exception 'foreign document upload allowed';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
-- Baris keuangan uji hanya hidup sampai rollback, bukan tagihan mahasiswa nyata.
insert into public.student_finance(user_id,period,category,description,amount,billed_on)
select user_id,'Uji transaksi','Uji','Uji RLS',1,current_date from public.students where nim='20240801001';
set local role authenticated;
do $$ begin
 if (select count(*) from public.student_finance where period='Uji transaksi')<>1 then raise exception 'own finance unreadable'; end if;
end $$;
-- Memalsukan sub atau metadata admin tidak membuka profil orang lain.
reset role;
select set_config('request.jwt.claims','{"sub":"33333333-3333-4333-8333-333333333333","session_id":"e5c6c061-4894-4bbe-9732-87fdb93a4d35","role":"authenticated","user_metadata":{"role":"admin"}}',true);
set local role authenticated;
do $$ begin
  if exists(select 1 from public.profiles) or exists(select 1 from public.students)
    or exists(select 1 from storage.objects where bucket_id='student-avatars') then
    raise exception 'foreign identity access unexpectedly allowed';
  end if;
end $$;
reset role;
-- Pengguna kedua dengan sesi sah pun tidak dapat melihat/mengubah Dante.
select set_config('request.jwt.claims','{"sub":"33333333-3333-4333-8333-333333333333","session_id":"44444444-4444-4444-8444-444444444444","role":"authenticated"}',true);
set local role authenticated;
do $$ begin
  if (select count(*) from public.profiles)<>1 then raise exception 'second user own read failed'; end if;
  if exists(select 1 from public.students where nim='20240801001') then raise exception 'second user sees Dante'; end if;
  update public.profiles set preferred_name='Lintas akun' where id<>'33333333-3333-4333-8333-333333333333';
  if found then raise exception 'cross account update allowed'; end if;
  if exists(select 1 from storage.objects where bucket_id='student-avatars') then raise exception 'cross account photo readable'; end if;
  if exists(select 1 from public.student_biodata) or exists(select 1 from public.student_education)
    or exists(select 1 from public.student_family) or exists(select 1 from public.student_employment)
    or exists(select 1 from public.student_accessibility) or exists(select 1 from public.student_documents)
    or exists(select 1 from public.student_finance) or exists(select 1 from storage.objects where bucket_id='student-documents')
    then raise exception 'cross account biodata/documents/finance readable'; end if;
  delete from public.student_documents where user_id<>auth.uid();
  if found then raise exception 'cross account document deletion allowed'; end if;

end $$;
reset role;
-- Profil dinonaktifkan menutup sesi aktif; metadata JWT tidak dapat membukanya.
update public.profiles set is_enabled=false where id='33333333-3333-4333-8333-333333333333';
set local role authenticated;
do $$ begin
  if exists(select 1 from public.profiles) or public.profile_session_status() is not null then
    raise exception 'disabled profile still accessible';
  end if;
end $$;
reset role;
select set_config('request.jwt.claims',jsonb_build_object('sub',user_id,'session_id','e5c6c061-4894-4bbe-9732-87fdb93a4d35','role','authenticated')::text,true)
from public.students where nim='20240801001';
-- Sesi lewat tenggat tidak dapat membaca ataupun menulis meskipun JWT masih valid.
update private.app_sessions set expires_at=now()-interval '1 second'
where session_id='e5c6c061-4894-4bbe-9732-87fdb93a4d35';
set local role authenticated;
do $$ begin
  if exists(select 1 from public.profiles) or exists(select 1 from storage.objects where bucket_id='student-avatars') then
    raise exception 'expired session still readable';
  end if;
  update public.profiles set preferred_name='Sesudah habis' where id=auth.uid();
  if found then raise exception 'expired session still writable'; end if;
  if public.profile_session_status() is not null then raise exception 'expired status still valid'; end if;
  if exists(select 1 from public.student_biodata) or exists(select 1 from public.student_education)
    or exists(select 1 from public.student_family) or exists(select 1 from public.student_employment)
    or exists(select 1 from public.student_accessibility) or exists(select 1 from public.student_documents)
    or exists(select 1 from public.student_finance) or exists(select 1 from storage.objects where bucket_id='student-documents')
    then raise exception 'expired biodata/documents/finance readable'; end if;
  update public.student_biodata set street='Expired edit' where user_id=auth.uid();
  if found then raise exception 'expired biodata writable'; end if;

end $$;
reset role;
-- Uji pencabutan terpisah dari kedaluwarsa.
update private.app_sessions set expires_at=now()+interval '10 minutes'
where session_id='e5c6c061-4894-4bbe-9732-87fdb93a4d35';
set local role authenticated;
select public.revoke_profile_session();
do $$ begin
  if exists(select 1 from public.profiles) then raise exception 'revoked session still readable'; end if;
end $$;
reset role;
set local role anon;
do $$ begin
  begin
    perform * from public.profiles;
    raise exception 'anonymous read unexpectedly allowed';
  exception when insufficient_privilege then null; end;
  begin
    perform public.profile_session_status();
    raise exception 'anonymous session RPC unexpectedly allowed';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
rollback;
select 'PASS: own read/edit, column grants, foreign identity, storage policy, expiry, revocation, anonymous denial' as result;
