-- Authorized development verification. ALL fixture changes roll back.
-- Exercises the deployed RPC as authenticated, not as its privileged owner.
-- The temporary session/role setup does not prove an Auth HTTP login.
begin;
set local statement_timeout = '30s';
do $$ declare u uuid; sid uuid; begin
 select p.id into strict u from public.profiles p join public.students s on s.user_id=p.id
 where p.full_name='Prismatine Dante Viergo' and s.program='Teknik Informatika';
 select id into strict sid from auth.sessions where user_id=u order by created_at desc limit 1;
 insert into private.app_sessions(session_id,user_id,started_at,expires_at)
 values(sid,u,now(),now()+interval '10 minutes')
 on conflict(session_id) do update set expires_at=excluded.expires_at,revoked_at=null;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'session_id',sid,'role','authenticated')::text,true);
 perform set_config('m2.test_user',u::text,true);
end $$;
set local role authenticated;
do $$ declare s jsonb; f jsonb; denied boolean:=false; begin
 assert private.profile_session_valid(), 'session fixture';
 s:=public.m2_snapshot(null);
 assert s->'registration'->>'semester'='1', 'Dante semester 1';
 assert s->'registration'->>'curriculum'='2026', 'curriculum 2026';
 assert s->'krs'->>'status'='approved', 'approved KRS';
 assert jsonb_array_length(s->'krs_items')=7, 'seven selected courses';
 assert (select sum(c.credits) from public.m2_krs_items k join public.m2_offerings o on o.id=k.offering_id join public.m2_courses c on c.code=o.course_code)=19, '19 credits through RLS';
 assert jsonb_array_length(s->'equivalences')=0, 'no equivalences';
 assert jsonb_array_length(s->'events')=112, 'KRS classes and exams';
 assert s->'tuition'->>'semester_fee'='17500000', 'tuition';
 f:=public.m2_finance();
 assert jsonb_array_length(f)=1 and f->0->>'paid'='17500000', 'finance projection';
 begin perform public.m2_command('verify_payment','2026-1','{}'); exception when insufficient_privilege then denied:=true; end;
 assert denied, 'student cannot verify'; denied:=false;
 begin perform public.m2_review(auth.uid(),'2026-1'); exception when insufficient_privilege then denied:=true; end;
 assert denied, 'student cannot review staff data'; denied:=false;
 begin update public.m2_registrations set status='active'; exception when insufficient_privilege then denied:=true; end;
 assert denied, 'direct write denied';
end $$;
reset role;
update public.m2_registrations set demo_now='2027-01-19 09:00+07'
 where user_id=current_setting('m2.test_user')::uuid;
set local role authenticated;
do $$ declare s jsonb; r jsonb; first jsonb; pay jsonb; begin
 s:=public.m2_snapshot(null);
 assert s->'period'->>'id'='2026-2', 'automatic semester transition';
 assert s->'registration'->>'status'='inactive', 'next semester inactive';
 assert (s->'registration'->>'first_due')::timestamptz='2027-02-19 09:00+07'::timestamptz, 'calendar month deadline';
 r:=public.m2_command('register','2026-2','{"track":"regular"}'); assert r->>'ok'='true', 'register';
 r:=public.m2_command('preview_plan','2026-2','{"count":3}'); assert r->>'principal'='17500000', 'preview total';
 assert not exists(select 1 from public.m2_invoices where period_id='2026-2'), 'preview creates no invoice';
 r:=public.m2_command('plan','2026-2','{"count":3}'); assert r->>'ok'='true', 'confirm plan';
 s:=public.m2_snapshot('2026-2'); first:=s->'invoices'->0->'installments'->0;
 assert first->>'amount'='5833334', 'exact integer rounding';
 pay:=public.m2_command('create_payment','2026-2',jsonb_build_object('installment_id',first->>'id','request_key','34bd3eb8-f7d5-40ab-8de1-789638aa9120','channel','bca'));
 assert pay->>'ok'='true', 'BCA simulation';
 r:=public.m2_command('create_payment','2026-2',jsonb_build_object('installment_id',first->>'id','request_key','34bd3eb8-f7d5-40ab-8de1-789638aa9120','channel','bca'));
 assert r->>'payment_id'=pay->>'payment_id', 'idempotent retry';
 perform set_config('m2.test_payment',pay->>'payment_id',true);
 r:=public.m2_command('submit_evidence','2026-2',jsonb_build_object('id',pay->>'payment_id','reference','SIM-CLOUD-SMOKE'));
 assert r->>'ok'='true', 'submit evidence';
 s:=public.m2_snapshot('2026-2');
 assert s->'registration'->>'status'='inactive', 'evidence is not payment';
end $$;
reset role;
-- Permission fixtures exist only inside this transaction, never on Dante's real session.
insert into private.m2_staff(user_id,permission)
 select current_setting('m2.test_user')::uuid,p from unnest(array['finance','validator','academic']) p;
set local role authenticated;
do $$ declare r jsonb; s jsonb; evidence jsonb; ids jsonb; note jsonb; n int; begin
 evidence:=jsonb_build_object('id',current_setting('m2.test_payment'),'amount',5833334,'currency','IDR',
 'reference',current_setting('m2.test_payment'),'bank_reference','SIM-CLOUD-SMOKE','paid_at','2027-01-19 09:00+07','decision','approved','reason','Cloud smoke test; transaction rolled back');
 r:=public.m2_command('verify_payment','2026-2',evidence||'{"amount":1}'); assert r->>'ok'='false', 'mismatch rejected';
 r:=public.m2_command('verify_payment','2026-2',evidence); assert r->>'ok'='true', 'verified first installment';
 r:=public.m2_command('verify_payment','2026-2',evidence); assert r->>'ok'='true', 'verification retry';
 s:=public.m2_snapshot('2026-2');
 assert s->'registration'->>'status'='active', 'first installment activates';
 assert s->'invoices'->0->>'paid'='5833334', 'no duplicate allocation';
 select jsonb_agg(id order by id) into ids from public.m2_offerings where period_id='2026-2' and track='regular';
 r:=public.m2_command('save_krs','2026-2',jsonb_build_object('version',0,'offering_ids',ids)); assert r->>'ok'='true', 'save KRS';
 r:=public.m2_command('save_krs','2026-2',jsonb_build_object('version',0,'offering_ids',ids)); assert r->>'ok'='false', 'stale version rejected';
 r:=public.m2_command('submit_krs','2026-2','{"version":1}'); assert r->>'ok'='true', 'submit KRS';
 s:=public.m2_snapshot('2026-2'); assert jsonb_array_length(s->'events')=0, 'unapproved KRS has no schedule';
 r:=public.m2_command('decide_krs','2026-2','{"version":2,"decision":"approved","reason":"Cloud smoke verification"}'); assert r->>'ok'='true', 'approve KRS';
 s:=public.m2_snapshot('2026-2'); assert jsonb_array_length(s->'events')=98, 'approved schedule';
 r:=public.m2_command('publish_event','2026-2','{"id":"2026-2-regular-CIE201-m1","revision":1,"reason":"Cloud smoke revision","starts_at":"2027-02-08 09:00+07","ends_at":"2027-02-08 11:00+07","room":"Ruang Uji","mode":"Daring","cancelled":true}');
 assert r->>'ok'='true', 'publish schedule cancellation';
 s:=public.m2_review(auth.uid(),'2026-2'); assert jsonb_array_length(s->'events')=98, 'academic staff review events';
 s:=public.m2_snapshot('2026-2');
 assert exists(select 1 from jsonb_array_elements(s->'events') e where e->>'id'='2026-2-regular-CIE201-m1' and e->>'cancelled'='true' and e->>'revision'='2'), 'latest revision returned';
 note:=s->'notifications'->0; n:=jsonb_array_length(s->'notifications');
 r:=public.m2_command('read_notification',note->>'period_id',jsonb_build_object('id',note->>'id')); assert r->>'ok'='true', 'mark read';
 s:=public.m2_snapshot('2026-2'); assert jsonb_array_length(s->'notifications')=n, 'notifications deduplicated';
 assert exists(select 1 from jsonb_array_elements(s->'notifications') v where v->>'id'=note->>'id' and v->>'read_at' is not null), 'read persists';
end $$;
reset role;
-- Staff context: temporary profile/identity changes are rolled back with this test.
update public.profiles set role='lecturer' where id=current_setting('m2.test_user')::uuid;
insert into private.m2_staff_identities values(current_setting('m2.test_user')::uuid,'9999999999');
delete from private.m2_staff where user_id=current_setting('m2.test_user')::uuid and permission='finance';
set local role authenticated;
do $$ declare s jsonb; r jsonb; denied boolean:=false; begin
 s:=public.m2_snapshot(null);
 assert s->>'staff'='true', 'lecturer context';
 assert s->'registration'='{}'::jsonb, 'staff has no fabricated academic context';
 assert jsonb_array_length(s->'periods')=2, 'staff period selection';
 assert public.m2_staff_identity()->>'login_id'='9999999999', 'owner NIDN identity';
 r:=public.m2_review_student('20240801001','2026-1');
 assert r->'student'->>'user_id'=auth.uid()::text, 'NIM resolves the reviewed student';
 assert jsonb_array_length(r->'payments')=0, 'academic permissions hide financial transactions';
 begin perform public.m2_command('verify_payment','2026-1','{}'); exception when insufficient_privilege then denied:=true; end;
 assert denied, 'lecturer cannot approve payment';
end $$;
reset role;
-- JWT/session-owner mismatch cannot read protected data.
do $$ begin perform set_config('request.jwt.claims',(current_setting('request.jwt.claims')::jsonb||jsonb_build_object('sub',gen_random_uuid()))::text,true); end $$;
set local role authenticated;
do $$ declare denied boolean:=false; begin
 assert not private.profile_session_valid(), 'session-owner mismatch';
 assert (select count(*) from public.m2_registrations)=0, 'cross-owner rows hidden';
 begin perform public.m2_snapshot(null); exception when insufficient_privilege then denied:=true; end;
 assert denied, 'mismatched session RPC denied';
end $$;
reset role;
set local role anon;
do $$ declare denied boolean:=false; begin
 begin perform public.m2_snapshot(null); exception when insufficient_privilege then denied:=true; end;
 assert denied, 'anonymous RPC denied';
end $$;
reset role;
select 'PASS: deployed RPC, owner/session RLS, finance, KRS, transition, schedule, notifications; all test writes rolled back' as result;
rollback;
