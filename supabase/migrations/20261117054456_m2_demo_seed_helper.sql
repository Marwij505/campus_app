-- REVIEW ONLY. Apply only with explicit authorization to development.
-- Install this administrator-only helper, then invoke it with the EXISTING
-- Dante UUID. It refuses missing users and never creates/updates Auth or M1 data.
create or replace function private.m2_seed_dante(p_user uuid,p_religion text default 'MKU102') returns void
language plpgsql security invoker set search_path='' as $$
declare code text; o text; track text; i int; m int; day_offset int; at_time timestamptz;
 inv uuid; ins uuid; pay uuid; newly_created int; tuition bigint;
begin
 if not exists(select 1 from public.students where user_id=p_user) then raise exception 'Existing student required'; end if;
 if p_religion not in ('MKU101','MKU102','MKU103','MKU104','MKU105') then raise exception 'One valid religion course required'; end if;
 insert into public.m2_periods(id,label,starts_at,ends_at,registration_opens,registration_closes,krs_opens,krs_closes)
 values('2026-1','Ganjil 2026/2027','2026-09-21 00:00+07','2027-01-18 00:00+07','2026-08-20 00:00+07','2026-09-20 00:00+07','2026-08-20 00:00+07','2026-09-20 00:00+07'),
 ('2026-2','Genap 2026/2027','2027-02-08 00:00+07','2027-06-21 00:00+07','2027-01-19 00:00+07','2027-03-01 00:00+07','2027-01-19 00:00+07','2027-03-01 00:00+07') on conflict do nothing;
 insert into public.m2_courses(code,curriculum,name,credits,semester,required,alternative_group) values
 ('CSF101','2026','Dasar Sistem Informasi',3,1,true,null),
 ('CSF102','2026','Algoritma dan Pemrograman',3,1,true,null),
 ('CSF103','2026','Aljabar Linier dan Matriks',3,1,true,null),
 ('CSF104','2026','Matematika Diskrit',3,1,true,null),
 ('MKU101','2026','Pendidikan Agama Islam',2,1,true,'agama'),
 ('MKU102','2026','Pendidikan Agama Kristen',2,1,true,'agama'),
 ('MKU103','2026','Pendidikan Agama Katolik',2,1,true,'agama'),
 ('MKU104','2026','Pendidikan Agama Hindu',2,1,true,'agama'),
 ('MKU105','2026','Pendidikan Agama Budha',2,1,true,'agama'),
 ('MKU107','2026','Pendidikan Pancasila',2,1,true,null),
 ('MKU111','2026','General English',3,1,true,null),
 ('MKU112','2026','English Composition 1',3,1,false,null),
 ('CIE201','2026','Bahasa Pemrograman',3,2,true,null),
 ('CIE202','2026','Kalkulus 1',3,2,true,null),
 ('CSF201','2026','Struktur Data',3,2,true,null),
 ('CSF202','2026','Organisasi dan Arsitektur Komputer',3,2,true,null),
 ('MKU108','2026','Pendidikan Kewarganegaraan',2,2,true,null),
 ('MKU109','2026','Bahasa Indonesia',2,2,true,null),
 ('MKU201','2026','Academic English',3,2,true,null) on conflict do nothing;
 foreach track in array array['regular','employee'] loop
  i:=0;
  for code in select c.code from public.m2_courses c where semester=1 order by c.code loop
   day_offset:=case when code like 'CSF%' then right(code,1)::int-1 when code between 'MKU101' and 'MKU105' then 4 when code='MKU107' then 4 when code='MKU111' then 5 else 5 end;
   o:='2026-1-'||track||'-'||code;
   insert into public.m2_offerings values(o,'2026-1',code,track,'DEMO-'||upper(left(track,1)),'Bekasi','Teknik Informatika','Dosen Simulasi '||(i+1),'Tatap muka','Ruang Demo '||(i+1)) on conflict do nothing;
   at_time:='2026-09-21 08:00+07'::timestamptz+make_interval(days=>day_offset)+case when code in ('MKU107','MKU112') then interval '3 hours' else interval '0 hours' end+case when track='employee' then interval '10 hours' else interval '0 hours' end;
   insert into public.m2_slots(id,offering_id,weekday,starts,ends) values(o||'-theory',o,day_offset+1,(at_time at time zone 'Asia/Jakarta')::time,((at_time+interval '2 hours') at time zone 'Asia/Jakarta')::time) on conflict do nothing;
   for m in 1..14 loop
    insert into public.m2_events(id,offering_id,kind,meeting,starts_at,ends_at,room,mode,plan,realization,realized_at,published_at)
     values(o||'-m'||m,o,'class',m,at_time+make_interval(days=>(m-1+case when m>=8 then 1 else 0 end)*7),at_time+make_interval(days=>(m-1+case when m>=8 then 1 else 0 end)*7)+interval '2 hours',
     'Ruang Demo '||(i+1),'Tatap muka','Rencana demo pertemuan '||m,
     case when m<=7 then 'Realisasi demo: materi pertemuan '||m||' terlaksana; bukan presensi mahasiswa' end,
     case when m<=7 then at_time+make_interval(days=>(m-1)*7)+interval '2 hours' end,'2026-09-01 00:00+07') on conflict do nothing;
   end loop;
   insert into public.m2_events(id,offering_id,kind,starts_at,ends_at,room,mode,plan,published_at) values
    (o||'-uts',o,'uts',at_time+interval '49 days',at_time+interval '49 days 2 hours','Ruang Ujian Demo','Tatap muka','UTS simulasi','2026-09-01 00:00+07'),
    (o||'-uas',o,'uas',at_time+interval '105 days',at_time+interval '105 days 2 hours','Ruang Ujian Demo','Tatap muka','UAS simulasi','2026-09-01 00:00+07') on conflict do nothing;
   i:=i+1;
  end loop;
  i:=0;
  for code in select c.code from public.m2_courses c where semester=2 order by c.code loop
   o:='2026-2-'||track||'-'||code;
   insert into public.m2_offerings values(o,'2026-2',code,track,'DEMO-'||upper(left(track,1)),'Bekasi','Teknik Informatika','Dosen Simulasi '||(i+1),'Tatap muka','Ruang Demo '||(i+1)) on conflict do nothing;
   at_time:='2027-02-08 08:00+07'::timestamptz+make_interval(days=>i%5)+make_interval(hours=>(i/5)*3+case when track='employee' then 10 else 0 end);
   insert into public.m2_slots values(o||'-theory',o,i%5+1,(at_time at time zone 'Asia/Jakarta')::time,((at_time+interval '2 hours') at time zone 'Asia/Jakarta')::time,'Teori') on conflict do nothing;
   for m in 1..14 loop
    insert into public.m2_events(id,offering_id,kind,meeting,starts_at,ends_at,room,mode,plan,published_at)
     values(o||'-m'||m,o,'class',m,at_time+make_interval(days=>(m-1)*7),at_time+make_interval(days=>(m-1)*7)+interval '2 hours','Ruang Demo','Tatap muka','Rencana demo','2027-01-19 00:00+07') on conflict do nothing;
   end loop;
   i:=i+1;
  end loop;
 end loop;
 insert into public.m2_registrations(user_id,period_id,semester,track,status,demo,demo_now,initial_paid_at)
 values(p_user,'2026-1',1,'regular','active',true,'2026-11-15 12:00+07','2026-09-01 09:00+07') on conflict do nothing;
 get diagnostics newly_created=row_count;
 if newly_created=1 then
  tuition:=private.m2_tuition('Teknik Informatika',1);
  insert into public.m2_invoices(user_id,period_id,principal,plan,created_at) values(p_user,'2026-1',tuition,1,'2026-09-01 08:00+07') returning id into inv;
  insert into public.m2_installments(invoice_id,ordinal,amount,due_at) values(inv,1,tuition,'2026-09-20 00:00+07') returning id into ins;
  insert into public.m2_payments(installment_id,request_key,channel,amount,status,expires_at,created_at,paid_at,bank_reference,verification_reason)
   values(ins,gen_random_uuid(),'bca',tuition,'paid','2026-09-01 10:00+07','2026-09-01 08:00+07','2026-09-01 09:00+07','SIM-SEED-'||p_user,'Snapshot simulasi utama disetujui sebelum pertemuan pertama') returning id into pay;
  insert into public.m2_allocations values(ins,pay,tuition,'2026-09-01 09:00+07');
  insert into public.m2_krs(user_id,period_id,status,updated_at,reason) values(p_user,'2026-1','approved','2026-09-02 09:00+07','Snapshot KRS demo, bukan keputusan resmi');
  insert into public.m2_krs_items select p_user,'2026-1',off.id from public.m2_offerings off where off.period_id='2026-1' and off.track='regular' and off.course_code=any(array['CSF101','CSF102','CSF103','CSF104',p_religion,'MKU107','MKU111']);
 end if;
 -- Upcoming period is isolated. No overwrite on rerun, including test clock.
 insert into public.m2_registrations(user_id,period_id,semester,demo,demo_now,leave_eligible)
 values(p_user,'2026-2',2,true,'2026-11-15 12:00+07',true) on conflict do nothing;
end $$;
revoke all on function private.m2_seed_dante(uuid,text) from public,anon,authenticated;
-- Invocation intentionally omitted. Approve target and existing student UUID first.
