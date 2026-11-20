-- M2 development. Additive: no M1 identity, session, storage, or ledger replacement.
-- All mutations are serialized per student/period through guarded private code.
create table public.m2_periods (
 id text primary key, label text not null, starts_at timestamptz not null,
 ends_at timestamptz not null, registration_opens timestamptz not null,
 registration_closes timestamptz not null, krs_opens timestamptz not null,
 krs_closes timestamptz not null, max_credits int not null default 24,
 check (starts_at < ends_at and registration_opens < registration_closes and krs_opens < krs_closes),
 check (max_credits > 0)
);
create table public.m2_courses (
 code text primary key, curriculum text not null, name text not null,
 credits int not null check(credits between 1 and 12), semester int not null,
 required boolean not null, alternative_group text, prerequisites text[] not null default '{}'
);
create table public.m2_offerings (
 id text primary key, period_id text not null references public.m2_periods,
 course_code text not null references public.m2_courses, track text not null check(track in ('regular','employee')),
 class_code text not null, campus text not null, program text not null,
 lecturer text not null, mode text not null, room text not null,
 unique(period_id,course_code,track,class_code)
);
create table public.m2_slots (
 id text primary key, offering_id text not null references public.m2_offerings,
 weekday int not null check(weekday between 1 and 7), starts time not null, ends time not null,
 kind text not null default 'Teori', check(starts < ends)
);
create table public.m2_events (
 id text primary key, offering_id text not null references public.m2_offerings,
 kind text not null check(kind in ('class','uts','uas')), meeting int,
 starts_at timestamptz not null, ends_at timestamptz not null, room text not null, mode text not null,
 plan text not null, realization text, realized_at timestamptz,
 cancelled boolean not null default false, change_reason text,
 revision int not null default 1, published_at timestamptz not null default now(),
 check(starts_at < ends_at), check(meeting is null or meeting between 1 and 14),
 check((realization is null) = (realized_at is null))
);
create index m2_events_offering_time on public.m2_events(offering_id,starts_at);
create table public.m2_registrations (
 user_id uuid not null references public.students(user_id), period_id text not null references public.m2_periods,
 semester int not null check(semester > 0), entry_year int not null default 2026,
 curriculum text not null default '2026', campus text not null default 'Bekasi',
 program text not null default 'Teknik Informatika', track text check(track in ('regular','employee')),
 status text not null default 'inactive' check(status in ('inactive','active','leave_pending','leave_approved','auto_leave')),
 demo boolean not null default false, demo_now timestamptz,
 leave_eligible boolean not null default false, notice_at timestamptz, first_due timestamptz,
 initial_paid_at timestamptz, reason text, version int not null default 1,
 primary key(user_id,period_id), check(demo or demo_now is null),
 check((notice_at is null)=(first_due is null))
);
create table public.m2_leave_requests (
 id uuid primary key default gen_random_uuid(), user_id uuid not null, period_id text not null,
 reason text not null check(length(trim(reason)) between 3 and 2000),
 status text not null default 'submitted' check(status in ('submitted','approved','rejected')),
 decided_by uuid references public.profiles, decision_reason text, created_at timestamptz not null default now(), decided_at timestamptz,
 foreign key(user_id,period_id) references public.m2_registrations
);
create unique index m2_one_pending_leave on public.m2_leave_requests(user_id,period_id) where status='submitted';
create table public.m2_invoices (
 id uuid primary key default gen_random_uuid(), user_id uuid not null, period_id text not null,
 principal bigint not null check(principal > 0), plan int not null check(plan in (1,3,6)),
 cancelled boolean not null default false, created_at timestamptz not null default now(),
 foreign key(user_id,period_id) references public.m2_registrations
);
create unique index m2_one_invoice on public.m2_invoices(user_id,period_id) where not cancelled;
create table public.m2_installments (
 id uuid primary key default gen_random_uuid(), invoice_id uuid not null references public.m2_invoices,
 ordinal int not null check(ordinal > 0), amount bigint not null check(amount > 0), due_at timestamptz not null,
 unique(invoice_id,ordinal)
);
create table public.m2_payments (
 id uuid primary key default gen_random_uuid(), installment_id uuid not null references public.m2_installments,
 request_key uuid not null, channel text not null check(channel in ('qris','bca')),
 amount bigint not null check(amount > 0), currency text not null default 'IDR' check(currency='IDR'),
 status text not null default 'pending' check(status in ('pending','review','expired','failed','cancelled','paid','reconcile','rejected')),
 expires_at timestamptz not null, created_at timestamptz not null default now(),
 evidence text, bank_reference text, paid_at timestamptz, verified_by uuid references public.profiles,
 verification_reason text, unique(installment_id,request_key)
);
create unique index m2_bank_reference_once on public.m2_payments(bank_reference) where bank_reference is not null;
create table public.m2_allocations (
 installment_id uuid primary key references public.m2_installments,
 payment_id uuid not null unique references public.m2_payments, amount bigint not null check(amount > 0),
 allocated_at timestamptz not null default now()
);
create table public.m2_krs (
 user_id uuid not null, period_id text not null, status text not null default 'draft'
 check(status in ('draft','submitted','revision','approved')),
 version int not null default 1, reason text, decided_by uuid references public.profiles,
 updated_at timestamptz not null default now(), primary key(user_id,period_id),
 foreign key(user_id,period_id) references public.m2_registrations
);
create table public.m2_krs_items (
 user_id uuid not null, period_id text not null, offering_id text not null references public.m2_offerings,
 primary key(user_id,period_id,offering_id), foreign key(user_id,period_id) references public.m2_krs
);
create table public.m2_equivalences (
 user_id uuid not null references public.students(user_id), source_course text not null,
 target_course text not null references public.m2_courses, decision text not null,
 primary key(user_id,source_course,target_course)
);
create table public.m2_notifications (
 id uuid primary key default gen_random_uuid(), user_id uuid not null, period_id text not null,
 event_key text not null, title text not null, body text not null default '', target text not null,
 category text not null, created_at timestamptz not null, read_at timestamptz,
 unique(user_id,period_id,event_key), foreign key(user_id,period_id) references public.m2_registrations
);
create index m2_notifications_owner_time on public.m2_notifications(user_id,created_at desc);
create table private.m2_staff (
 user_id uuid not null references public.profiles, permission text not null
 check(permission in ('academic','validator','finance','reconcile')), primary key(user_id,permission)
);
create table private.m2_audit (
 id bigint generated always as identity primary key, actor uuid not null, user_id uuid not null,
 period_id text not null, action text not null, reason text, reference text, created_at timestamptz not null default now()
);
alter table private.m2_staff enable row level security;
alter table private.m2_audit enable row level security;
create table private.m2_configuration (
 singleton boolean primary key default true check(singleton),
 reminder_days int[] not null default array[3,1],
 class_lead interval not null default interval '1 hour', exam_lead interval not null default interval '1 day',
 qris_limit bigint not null default 10000000,
 standard_semesters int not null default 8 check(standard_semesters>0),
 standard_semester_fee bigint not null default 17500000 check(standard_semester_fee>0),
 extension_semester_fee bigint not null default 10000000 check(extension_semester_fee>0),
 demo_bank_account text not null default 'BCA-SIMULASI-BUKAN-REKENING'
);
alter table private.m2_configuration enable row level security;
insert into private.m2_configuration default values;
-- User-supplied budget, split evenly until an official component schedule exists.
-- Applies equally to both demo tracks; no invented employee surcharge.
create function private.m2_tuition(p_program text,p_semester int) returns bigint
language plpgsql stable set search_path='' as $$
declare cfg private.m2_configuration;
begin
 if p_program is distinct from 'Teknik Informatika' or p_semester is null or p_semester<1 then raise exception 'Tarif program/semester belum dikonfigurasi'; end if;
 select * into strict cfg from private.m2_configuration;
 return case when p_semester<=cfg.standard_semesters then cfg.standard_semester_fee else cfg.extension_semester_fee end;
end $$;

create function private.m2_authorized(p_user uuid, p_permission text default null) returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and private.profile_session_valid() and
 case when p_permission is null then p_user=auth.uid()
 else exists(select 1 from private.m2_staff where user_id=auth.uid() and permission=p_permission) end;
$$;
revoke all on function private.m2_authorized(uuid,text) from public,anon;
grant execute on function private.m2_authorized(uuid,text) to authenticated;

-- Tables are read-only to clients. Financial/academic state can only change through RPC.
do $$ declare t text; begin
 foreach t in array array['m2_periods','m2_courses','m2_offerings','m2_slots','m2_events',
 'm2_registrations','m2_leave_requests','m2_invoices','m2_installments','m2_payments','m2_allocations',
 'm2_krs','m2_krs_items','m2_equivalences','m2_notifications'] loop
 execute format('alter table public.%I enable row level security',t);
 execute format('revoke all on public.%I from anon,authenticated',t);
 execute format('grant select on public.%I to authenticated',t);
 end loop;
 foreach t in array array['m2_registrations','m2_leave_requests','m2_invoices','m2_krs','m2_krs_items','m2_equivalences','m2_notifications'] loop
 execute format('create policy own_read on public.%I for select to authenticated using (user_id=(select auth.uid()) and (select private.profile_session_valid()))',t);
 end loop;
end $$;

-- Private definer is necessary: clients must never obtain direct UPDATE grants
-- on balances, registrations, approvals or schedule publication.
create function private.m2_command(p_action text,p_period text,p_data jsonb default '{}') returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=coalesce((p_data->>'student_id')::uuid,auth.uid()); r public.m2_registrations;
 per public.m2_periods; t timestamptz; inv public.m2_invoices; ins public.m2_installments;
 pay public.m2_payments; kr public.m2_krs; ev public.m2_events; lr public.m2_leave_requests;
 permission text; amount bigint; n int; j int; due timestamptz; ids text[]; x record; result jsonb:='{}';
begin
 permission:=case p_action when 'decide_leave' then 'academic' when 'decide_krs' then 'validator'
 when 'verify_payment' then 'finance' when 'reconcile' then 'reconcile' when 'publish_event' then 'academic' end;
 if not private.m2_authorized(u,permission) then raise exception 'Accès interdit / sesi tidak valid' using errcode='42501'; end if;
 select * into strict r from public.m2_registrations where user_id=u and period_id=p_period for update;
 select * into strict per from public.m2_periods where id=p_period;
 perform private.m2_sync(u,p_period);
 select * into strict r from public.m2_registrations where user_id=u and period_id=p_period; t:=private.m2_now(r);
 -- Domain rejection rolls back this command, but retains deadline reconciliation above.
 begin
 if p_action='read_notification' then
  update public.m2_notifications set read_at=coalesce(read_at,t) where user_id=u and period_id=p_period and id=(p_data->>'id')::uuid;
 elsif p_action in ('register','request_leave') then
  if t<per.registration_opens or t>=per.registration_closes or r.status in ('auto_leave','leave_approved','leave_pending') then raise exception 'Registrasi ditutup atau tertahan cuti'; end if;
  if r.initial_paid_at is not null then raise exception 'Perubahan setelah pembayaran harus ditangani petugas'; end if;
  if exists(select 1 from public.m2_payments pay0 join public.m2_installments ins0 on ins0.id=pay0.installment_id join public.m2_invoices inv0 on inv0.id=ins0.invoice_id
   where inv0.user_id=u and inv0.period_id=p_period and pay0.status in ('pending','review','paid','reconcile')) then raise exception 'Selesaikan/batalkan transaksi sebelum mengganti pilihan'; end if;
  if p_action='request_leave' then
   if not r.leave_eligible then raise exception 'Fixture ini tidak memenuhi kelayakan cuti demo'; end if;
   insert into public.m2_leave_requests(user_id,period_id,reason,created_at) values(u,p_period,p_data->>'reason',t);
   update public.m2_registrations set status='leave_pending',version=version+1 where user_id=u and period_id=p_period;
   update public.m2_invoices set cancelled=true where user_id=u and period_id=p_period;
   perform private.m2_notify(u,p_period,'leave-request:'||r.version,'Pengajuan cuti diterima','','Registrasi','registration',t);
  else
   if p_data->>'track' not in ('regular','employee') or p_data->>'track' is null then raise exception 'Pilih Reguler/Karyawan'; end if;
   if r.track is distinct from p_data->>'track' then
    update public.m2_invoices set cancelled=true where user_id=u and period_id=p_period;
   end if;
   update public.m2_registrations set track=p_data->>'track',reason=null,version=version+1 where user_id=u and period_id=p_period;
  end if;
 elsif p_action='decide_leave' then
  select * into strict lr from public.m2_leave_requests where id=(p_data->>'id')::uuid and user_id=u and period_id=p_period for update;
  if lr.status<>'submitted' then return jsonb_build_object('ok',true); end if;
  if p_data->>'decision' not in ('approved','rejected') or length(trim(coalesce(p_data->>'reason','')))<3 then raise exception 'Keputusan dan alasan wajib'; end if;
  update public.m2_leave_requests set status=p_data->>'decision',decided_by=auth.uid(),decision_reason=p_data->>'reason',decided_at=t where id=lr.id;
  update public.m2_registrations set status=case when p_data->>'decision'='approved' then 'leave_approved' when status='auto_leave' then 'auto_leave' else 'inactive' end,
   reason=p_data->>'reason',version=version+1 where user_id=u and period_id=p_period;
  perform private.m2_notify(u,p_period,'leave-decision:'||lr.id,'Keputusan cuti: '||(p_data->>'decision'),p_data->>'reason','Registrasi','registration',t);
 elsif p_action in ('plan','preview_plan') then
  n:=(p_data->>'count')::int;
  if n is null or n not in (1,3,6) or r.track is null or r.status<>'inactive' or r.initial_paid_at is not null
   or t<per.registration_opens or t>=per.registration_closes then raise exception 'Skema tidak tersedia atau sudah terkunci'; end if;
  select * into inv from public.m2_invoices where user_id=u and period_id=p_period and not cancelled;
  if inv.id is not null and inv.plan=n and p_action='plan' then return jsonb_build_object('ok',true,'invoice_id',inv.id); end if;
  if exists(select 1 from public.m2_payments pay0 join public.m2_installments ins0 on ins0.id=pay0.installment_id where ins0.invoice_id=inv.id and pay0.status in ('pending','review','paid','reconcile')) then raise exception 'Transaksi harus diselesaikan/dibatalkan dahulu'; end if;
  if p_action='plan' then update public.m2_invoices set cancelled=true where user_id=u and period_id=p_period and not cancelled; end if;
  amount:=private.m2_tuition(r.program,r.semester);
  due:=coalesce(r.first_due,per.registration_closes);
  if p_action='preview_plan' then
   return jsonb_build_object('ok',true,'principal',amount,'fee',0,'count',n,'installments',
    (select jsonb_agg(jsonb_build_object('ordinal',k,'amount',amount/n+case when k<=amount%n then 1 else 0 end,'due_at',private.m2_month(due,k-1)) order by k) from generate_series(1,n) k));
  end if;
  insert into public.m2_invoices(user_id,period_id,principal,plan,created_at) values(u,p_period,amount,n,t) returning * into inv;
  for j in 1..n loop
   insert into public.m2_installments(invoice_id,ordinal,amount,due_at) values(inv.id,j,amount/n+case when j<=amount%n then 1 else 0 end,private.m2_month(due,j-1));
  end loop;
  perform private.m2_notify(u,p_period,'invoice:'||inv.id,'Tagihan simulasi terbit','Skema '||n||' kali; biaya kanal Rp0.','Pembayaran','payment',t);
  result:=jsonb_build_object('invoice_id',inv.id);
 elsif p_action='create_payment' then
  if not r.demo then raise exception 'Pembayaran hanya tersedia pada fixture simulasi yang diotorisasi'; end if;
  select i.* into strict ins from public.m2_installments i join public.m2_invoices v on v.id=i.invoice_id
   where i.id=(p_data->>'installment_id')::uuid and v.user_id=u and v.period_id=p_period and not v.cancelled;
  select * into pay from public.m2_payments where installment_id=ins.id and request_key=(p_data->>'request_key')::uuid;
  if pay.id is not null then
   if pay.channel is distinct from p_data->>'channel' then raise exception 'Kunci permintaan sudah dipakai untuk kanal lain'; end if;
   return jsonb_build_object('ok',true,'payment_id',pay.id);
  end if;
  if r.status in ('auto_leave','leave_pending','leave_approved') or (ins.ordinal=1 and t>=coalesce(r.first_due,per.registration_closes)) then raise exception 'Pembayaran pertama ditutup; hubungi petugas'; end if;
  if exists(select 1 from public.m2_allocations where installment_id=ins.id) then raise exception 'Cicilan sudah dibayar'; end if;
  if exists(select 1 from public.m2_installments i where i.invoice_id=ins.invoice_id and i.ordinal<ins.ordinal and not exists(select 1 from public.m2_allocations a where a.installment_id=i.id)) then raise exception 'Bayar cicilan sebelumnya dahulu'; end if;
  if p_data->>'channel'='qris' and ins.amount>(select qris_limit from private.m2_configuration) then raise exception 'Nominal melebihi batas simulator QRIS; gunakan BCA'; end if;
  insert into public.m2_payments(installment_id,request_key,channel,amount,expires_at,created_at)
   values(ins.id,(p_data->>'request_key')::uuid,p_data->>'channel',ins.amount,least(t+interval '30 minutes',case when ins.ordinal=1 then coalesce(r.first_due,per.registration_closes) else t+interval '30 minutes' end),t)
   on conflict(installment_id,request_key) do nothing returning * into pay;
  if pay.id is null then select * into pay from public.m2_payments where installment_id=ins.id and request_key=(p_data->>'request_key')::uuid; end if;
  result:=jsonb_build_object('payment_id',pay.id);
 elsif p_action in ('submit_evidence','cancel_payment','fail_payment','verify_payment','reconcile') then
  select pay0.* into strict pay from public.m2_payments pay0 join public.m2_installments i on i.id=pay0.installment_id join public.m2_invoices v on v.id=i.invoice_id
   where pay0.id=(p_data->>'id')::uuid and v.user_id=u and v.period_id=p_period for update of pay0;
  select * into strict ins from public.m2_installments where id=pay.installment_id;
  select * into strict inv from public.m2_invoices where id=ins.invoice_id;
  if not r.demo then raise exception 'Penyedia produksi/sandbox belum dikonfigurasi'; end if;
  if p_action in ('cancel_payment','fail_payment') then
   if pay.status<>'pending' then raise exception 'Transaksi tidak dapat dibatalkan/digagalkan'; end if;
   if p_action='fail_payment' and pay.channel<>'qris' then raise exception 'Hanya simulator QRIS'; end if;
   update public.m2_payments set status=case p_action when 'cancel_payment' then 'cancelled' else 'failed' end where id=pay.id;
   perform private.m2_notify(u,p_period,p_action||':'||pay.id,'Transaksi simulasi '||case p_action when 'cancel_payment' then 'dibatalkan' else 'gagal' end,'','Pembayaran','payment',t);
  elsif p_action='submit_evidence' then
   if pay.channel<>'bca' or pay.status not in ('pending','review') or length(trim(coalesce(p_data->>'reference','')))<3 then raise exception 'Bukti/referensi BCA tidak valid'; end if;
   update public.m2_payments set status='review',evidence=p_data->>'reference' where id=pay.id;
   perform private.m2_notify(u,p_period,'review:'||pay.id,'BCA menunggu verifikasi','Bukti bukan pelunasan.','Pembayaran','payment',t);
  else
   if pay.status='paid' then return jsonb_build_object('ok',true); end if;
   if length(trim(coalesce(p_data->>'reason','')))<3 then raise exception 'Alasan verifikasi wajib'; end if;
   if p_data->>'decision'='rejected' and p_action='verify_payment' then
    if pay.status not in ('pending','review') then raise exception 'Status tidak dapat ditolak'; end if;
    update public.m2_payments set status='rejected',verification_reason=p_data->>'reason',verified_by=auth.uid() where id=pay.id;
    perform private.m2_notify(u,p_period,'rejected:'||pay.id,'Pembayaran ditolak',p_data->>'reason','Pembayaran','payment',t);
   else
    if p_data->>'decision' is distinct from 'approved' or (p_data->>'amount')::bigint is distinct from pay.amount or p_data->>'currency' is distinct from 'IDR'
     or p_data->>'reference' is distinct from pay.id::text or length(trim(coalesce(p_data->>'bank_reference','')))<3 then raise exception 'Nominal/mata uang/referensi tidak cocok'; end if;
    due:=(p_data->>'paid_at')::timestamptz;
    if due is null or due>t or due<pay.created_at then raise exception 'Waktu pembayaran tidak valid'; end if;
    if pay.status in ('cancelled','failed','rejected') then raise exception 'Status final tidak menerima pembayaran; investigasi diperlukan'; end if;
    if p_action='reconcile' and pay.status<>'reconcile' then raise exception 'Tidak ada rekonsiliasi tertunda'; end if;
    if p_action='reconcile' and (pay.paid_at is distinct from due or pay.bank_reference is distinct from p_data->>'bank_reference') then raise exception 'Rekonsiliasi harus mempertahankan bukti terverifikasi'; end if;
    update public.m2_payments set bank_reference=p_data->>'bank_reference',paid_at=due,verified_by=auth.uid(),verification_reason=p_data->>'reason' where id=pay.id;
    if inv.cancelled or exists(select 1 from public.m2_allocations where installment_id=ins.id)
     or (p_action<>'reconcile' and ((ins.ordinal=1 and (t>=coalesce(r.first_due,per.registration_closes) or r.status<>'inactive')) or due>=pay.expires_at)) then
     update public.m2_payments set status='reconcile' where id=pay.id;
     perform private.m2_notify(u,p_period,'reconcile:'||pay.id,'Pembayaran perlu rekonsiliasi','Saldo belum dibukukan ganda.','Pembayaran','payment',t);
    else
     insert into public.m2_allocations(installment_id,payment_id,amount,allocated_at) values(ins.id,pay.id,pay.amount,t);
     update public.m2_payments set status='paid' where id=pay.id;
     if ins.ordinal=1 and due<coalesce(r.first_due,per.registration_closes) and r.status not in ('leave_pending','leave_approved') then
      update public.m2_registrations set status='active',initial_paid_at=due,reason=null,version=version+1 where user_id=u and period_id=p_period;
      perform private.m2_notify(u,p_period,'activated','Semester aktif','Cicilan pertama terverifikasi. Sisa kewajiban tetap berlaku.','KRS','registration',t);
     end if;
     perform private.m2_notify(u,p_period,'paid:'||pay.id,'Pembayaran terverifikasi','','Pembayaran','payment',t);
     if not exists(select 1 from public.m2_installments i where i.invoice_id=inv.id and not exists(select 1 from public.m2_allocations a where a.installment_id=i.id)) then
      perform private.m2_notify(u,p_period,'settled:'||inv.id,'Tagihan lunas','Hapus pengingat lama dari kalender perangkat.','Pembayaran','payment',t);
     end if;
    end if;
   end if;
  end if;
 elsif p_action in ('save_krs','submit_krs','decide_krs') then
  select * into kr from public.m2_krs where user_id=u and period_id=p_period;
  if p_action='save_krs' then
   if kr.status in ('submitted','approved') then raise exception 'KRS terkunci'; end if;
   if coalesce(kr.version,0) is distinct from (p_data->>'version')::int then raise exception 'KRS berubah; muat ulang'; end if;
   select array_agg(value) into ids from jsonb_array_elements_text(p_data->'offering_ids');
   perform private.m2_validate_krs(u,p_period,ids);
   insert into public.m2_krs(user_id,period_id,updated_at) values(u,p_period,t)
    on conflict(user_id,period_id) do update set status='draft',version=m2_krs.version+1,updated_at=t;
   delete from public.m2_krs_items where user_id=u and period_id=p_period;
   insert into public.m2_krs_items(user_id,period_id,offering_id) select u,p_period,unnest(ids);
  else
   if kr.version is distinct from (p_data->>'version')::int then raise exception 'KRS berubah; muat ulang'; end if;
   select array_agg(offering_id) into ids from public.m2_krs_items where user_id=u and period_id=p_period;
   perform private.m2_validate_krs(u,p_period,ids);
   if p_action='submit_krs' then
    if kr.status not in ('draft','revision') then raise exception 'KRS tidak dapat diajukan'; end if;
    update public.m2_krs set status='submitted',version=version+1,updated_at=t where user_id=u and period_id=p_period;
    perform private.m2_notify(u,p_period,'krs-submitted:'||kr.version,'Pengajuan KRS diterima','','KRS','krs',t);
   else
    if kr.status<>'submitted' or p_data->>'decision' not in ('approved','revision') or length(trim(coalesce(p_data->>'reason','')))<3 then raise exception 'Keputusan KRS tidak valid'; end if;
    update public.m2_krs set status=p_data->>'decision',reason=p_data->>'reason',decided_by=auth.uid(),version=version+1,updated_at=t where user_id=u and period_id=p_period;
    perform private.m2_notify(u,p_period,'krs-decided:'||kr.version,'KRS '||case when p_data->>'decision'='approved' then 'sah' else 'dikembalikan untuk revisi' end,p_data->>'reason','KRS','krs',t);
   end if;
  end if;
 elsif p_action='publish_event' then
  select e.* into strict ev from public.m2_events e join public.m2_offerings o on o.id=e.offering_id where e.id=p_data->>'id' and o.period_id=p_period for update of e;
  if ev.revision is distinct from (p_data->>'revision')::int or length(trim(coalesce(p_data->>'reason','')))<3 then raise exception 'Versi/alasan perubahan jadwal tidak valid'; end if;
  if (p_data->>'starts_at')::timestamptz<per.starts_at or (p_data->>'ends_at')::timestamptz>per.ends_at then raise exception 'Jadwal harus berada dalam periode akademik'; end if;
  update public.m2_events set starts_at=(p_data->>'starts_at')::timestamptz,ends_at=(p_data->>'ends_at')::timestamptz,
   room=p_data->>'room',mode=p_data->>'mode',cancelled=coalesce((p_data->>'cancelled')::boolean,false),change_reason=p_data->>'reason',revision=revision+1,published_at=t where id=ev.id;
  for x in select i.user_id from public.m2_krs_items i join public.m2_krs k using(user_id,period_id) where i.offering_id=ev.offering_id and k.status='approved' loop
   perform private.m2_notify(x.user_id,p_period,'changed:'||ev.id||':'||(ev.revision+1),'Jadwal berubah/dibatalkan','Perbarui atau hapus salinan kalender perangkat.','Jadwal Kuliah','schedule',t);
  end loop;
 else raise exception 'Aksi tidak dikenal';
 end if;
 insert into private.m2_audit(actor,user_id,period_id,action,reason,reference)
 values(auth.uid(),u,p_period,p_action,p_data->>'reason',coalesce(p_data->>'id',result->>'payment_id',result->>'invoice_id',p_period));
 return jsonb_build_object('ok',true)||result;
 exception when others then return jsonb_build_object('ok',false,'error',case when sqlstate='23505' then 'Referensi sudah dipakai; muat ulang untuk rekonsiliasi' when sqlstate in ('P0001','P0002') then sqlerrm else 'Data tidak valid atau operasi gagal' end);
 end;
end $$;
create policy catalog_read on public.m2_courses for select to authenticated using ((select private.profile_session_valid()));
create policy period_read on public.m2_periods for select to authenticated using (exists(select 1 from public.m2_registrations r where r.period_id=id));
create policy offering_read on public.m2_offerings for select to authenticated using (
 exists(select 1 from public.m2_registrations r where r.period_id=m2_offerings.period_id
 and r.program=m2_offerings.program and r.campus=m2_offerings.campus and r.track=m2_offerings.track));
create policy slot_read on public.m2_slots for select to authenticated using (exists(select 1 from public.m2_offerings o where o.id=offering_id));
create policy event_read on public.m2_events for select to authenticated using (
 exists(select 1 from public.m2_krs_items i join public.m2_krs k using(user_id,period_id)
 where i.offering_id=m2_events.offering_id and k.status='approved'));
create policy installment_read on public.m2_installments for select to authenticated using (exists(select 1 from public.m2_invoices i where i.id=invoice_id));
create policy payment_read on public.m2_payments for select to authenticated using (exists(select 1 from public.m2_installments i where i.id=installment_id));
create policy allocation_read on public.m2_allocations for select to authenticated using (exists(select 1 from public.m2_installments i where i.id=installment_id));

create function private.m2_now(r public.m2_registrations) returns timestamptz
language sql stable set search_path='' as $$ select case when r.demo then coalesce(r.demo_now,now()) else now() end $$;
create function private.m2_month(t timestamptz,n int) returns timestamptz
language sql immutable set search_path='' as $$ select ((t at time zone 'Asia/Jakarta') + make_interval(months=>n)) at time zone 'Asia/Jakarta' $$;
create function private.m2_notify(u uuid,p text,k text,title text,body text,target text,category text,t timestamptz) returns void
language sql set search_path='' as $$
 insert into public.m2_notifications(user_id,period_id,event_key,title,body,target,category,created_at)
 values(u,p,k,title,body,target,category,t) on conflict(user_id,period_id,event_key) do nothing;
$$;

-- Runs on every snapshot and command, so delayed jobs cannot bypass the deadline.
create function private.m2_sync(u uuid,p text) returns void language plpgsql set search_path='' as $$
declare r public.m2_registrations; per public.m2_periods; t timestamptz; x record; days int; cfg private.m2_configuration;
begin
 select * into strict r from public.m2_registrations where user_id=u and period_id=p for update;
 select * into strict per from public.m2_periods where id=p; t:=private.m2_now(r);
 select * into strict cfg from private.m2_configuration;
 if r.semester>1 and r.notice_at is null and t>=per.registration_opens then
  -- First actual personal publication starts the one-calendar-month budget once.
  update public.m2_registrations set notice_at=t,first_due=private.m2_month(t,1) where user_id=u and period_id=p returning * into r;
  perform private.m2_notify(u,p,'first-open','Pembayaran pertama dibuka','Tenggat: '||to_char(r.first_due at time zone 'Asia/Jakarta','DD Mon YYYY HH24:MI')||' WIB','Pembayaran','registration',t);
 end if;
 if r.first_due is not null and t>=r.first_due and r.initial_paid_at is null and r.status not in ('active','leave_approved','auto_leave') then
  update public.m2_registrations set status='auto_leave',reason='Tenggat Pembayaran Terlewat',version=version+1 where user_id=u and period_id=p returning * into r;
  perform private.m2_notify(u,p,'auto-leave','Cuti Otomatis — Tenggat Pembayaran Terlewat','Hubungi petugas akademik untuk rekonsiliasi.','Registrasi','registration',t);
  insert into private.m2_audit(actor,user_id,period_id,action,reason,reference)
  values(auth.uid(),u,p,'auto_leave','Tenggat pembayaran pertama terlewat',p);
 end if;
 for x in update public.m2_payments pay set status='expired'
  from public.m2_installments ins,public.m2_invoices inv where pay.installment_id=ins.id and ins.invoice_id=inv.id
  and inv.user_id=u and inv.period_id=p and pay.channel='qris' and pay.status='pending' and pay.expires_at<=t returning pay.id loop
  perform private.m2_notify(u,p,'expired:'||x.id,'QRIS simulasi kedaluwarsa','','Pembayaran','payment',t);
 end loop;
 for x in select ins.*,inv.cancelled,a.payment_id from public.m2_installments ins join public.m2_invoices inv on inv.id=ins.invoice_id
 left join public.m2_allocations a on a.installment_id=ins.id where inv.user_id=u and inv.period_id=p and not inv.cancelled and a.payment_id is null loop
  if x.ordinal=1 and r.status in ('auto_leave','leave_approved') then continue; end if;
  if t>=x.due_at then
   perform private.m2_notify(u,p,'overdue:'||x.id,'Pembayaran tertunggak','Saldo masih terutang; periksa tagihan.','Pembayaran','payment',t);
  else
   foreach days in array cfg.reminder_days loop
    if t>=x.due_at-make_interval(days=>days) then
     perform private.m2_notify(u,p,'due:'||x.id||':'||days,'Tenggat pembayaran mendekat','','Pembayaran','payment',t);
    end if;
   end loop;
  end if;
 end loop;
 if r.status not in ('leave_pending','leave_approved','auto_leave') then
  if t>=per.registration_opens and t<per.registration_closes and r.status<>'active' then
   perform private.m2_notify(u,p,'reg-open','Registrasi semester dibuka','','Registrasi','registration',t);
   foreach days in array cfg.reminder_days loop
    if t>=per.registration_closes-make_interval(days=>days) then
     perform private.m2_notify(u,p,'reg-close:'||days,'Registrasi segera ditutup','','Registrasi','registration',t);
    end if;
    if r.first_due is not null and t<r.first_due and t>=r.first_due-make_interval(days=>days) then
     perform private.m2_notify(u,p,'first-due:'||days,'Tenggat pembayaran pertama mendekat','','Pembayaran','payment',t);
    end if;
   end loop;
  end if;
  if r.status='active' and t>=per.krs_opens and t<per.krs_closes and not exists(select 1 from public.m2_krs where user_id=u and period_id=p and status='approved') then
   perform private.m2_notify(u,p,'krs-open','Pengisian KRS dibuka','','KRS','krs',t);
   foreach days in array cfg.reminder_days loop
    if t>=per.krs_closes-make_interval(days=>days) then
     perform private.m2_notify(u,p,'krs-close:'||days,'Pengisian KRS segera ditutup','','KRS','krs',t);
    end if;
   end loop;
  end if;
  if exists(select 1 from public.m2_krs where user_id=u and period_id=p and status='approved') then
   perform private.m2_notify(u,p,'schedule-published','Jadwal pribadi diterbitkan','Rencana/realisasi dan ujian tersedia sesuai KRS sah.','Jadwal Kuliah','schedule',t);
  end if;
  for x in select e.* from public.m2_events e join public.m2_krs_items i on i.offering_id=e.offering_id
   join public.m2_krs k using(user_id,period_id) where i.user_id=u and i.period_id=p and k.status='approved' and not e.cancelled
   and e.published_at<=t and e.starts_at>t and e.starts_at<=t+case when e.kind='class' then cfg.class_lead else cfg.exam_lead end loop
   perform private.m2_notify(u,p,'event:'||x.id||':'||x.revision,'Pengingat '||case when x.kind='class' then 'kuliah' else upper(x.kind) end,'Lihat jadwal terbaru.','Jadwal Kuliah','schedule',t);
  end loop;
 end if;
end $$;

create function private.m2_validate_krs(u uuid,p text,ids text[]) returns void language plpgsql set search_path='' as $$
declare r public.m2_registrations; per public.m2_periods; t timestamptz;
begin
 select * into strict r from public.m2_registrations where user_id=u and period_id=p;
 select * into strict per from public.m2_periods where id=p; t:=private.m2_now(r);
 if r.status<>'active' or r.initial_paid_at is null or t<per.krs_opens or t>=per.krs_closes then
  raise exception 'Aktivasi/pembayaran pertama belum terpenuhi atau jendela KRS tutup' using errcode='P0001'; end if;
 if coalesce(cardinality(ids),0)=0 or cardinality(ids)<> (select count(distinct x) from unnest(ids) x) then raise exception 'Pilih kelas tanpa duplikasi'; end if;
 if exists(select 1 from unnest(ids) x left join public.m2_offerings o on o.id=x
  left join public.m2_courses c on c.code=o.course_code where o.id is null or o.period_id<>p or o.track<>r.track
  or o.campus<>r.campus or o.program<>r.program or c.curriculum<>r.curriculum) then raise exception 'Penawaran tidak sesuai periode/jalur/kurikulum'; end if;
 if (select sum(c.credits) from public.m2_offerings o join public.m2_courses c on c.code=o.course_code where o.id=any(ids))>per.max_credits then raise exception 'Batas SKS terlampaui'; end if;
 if exists(select o.course_code from public.m2_offerings o where o.id=any(ids) group by o.course_code having count(*)>1)
 or exists(select c.alternative_group from public.m2_offerings o join public.m2_courses c on c.code=o.course_code where o.id=any(ids) and c.alternative_group is not null group by c.alternative_group having count(*)>1)
 then raise exception 'Mata kuliah atau kelompok agama ganda'; end if;
 if exists(select 1 from public.m2_slots a join public.m2_slots b on a.weekday=b.weekday and a.starts<b.ends and b.starts<a.ends
  where a.offering_id=any(ids) and b.offering_id=any(ids) and a.offering_id<>b.offering_id) then raise exception 'Jadwal bentrok termasuk praktikum'; end if;
 if exists(select 1 from public.m2_offerings o join public.m2_courses c on c.code=o.course_code cross join lateral unnest(c.prerequisites) pre
  where o.id=any(ids) and not exists(select 1 from public.m2_equivalences eq where eq.user_id=u and eq.target_course=pre)) then raise exception 'Prasyarat belum terpenuhi'; end if;
end $$;

create function private.m2_snapshot(p_period text default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); p text:=p_period; r public.m2_registrations; per public.m2_periods;
 t timestamptz; stage text; x record; result jsonb;
begin
 if not private.m2_authorized(u) then raise exception 'Sesi tidak valid' using errcode='42501'; end if;
 -- Refresh all owned periods; old unpaid obligations remain visible in history.
 for x in select period_id from public.m2_registrations where user_id=u order by period_id loop
  perform private.m2_sync(u,x.period_id);
 end loop;
 if p is null then
  select a.period_id into p from public.m2_registrations a join public.m2_periods b on b.id=a.period_id where a.user_id=u
  order by case when private.m2_now(a)>=b.starts_at and private.m2_now(a)<b.ends_at then 0
   when private.m2_now(a)>=b.registration_opens and private.m2_now(a)<b.starts_at then 1
   when b.starts_at>private.m2_now(a) then 2 else 3 end,b.starts_at desc limit 1;
 end if;
 if p is null then return jsonb_build_object('available',true,'periods','[]'::jsonb,'message','Belum ada periode akademik untuk akun ini','server_now',now()); end if;
 select * into strict r from public.m2_registrations where user_id=u and period_id=p;
 select * into strict per from public.m2_periods where id=p; t:=private.m2_now(r);
 stage:=case when t>=per.ends_at then 'Libur semester'
  when r.status='auto_leave' then 'Cuti Otomatis — Tenggat Pembayaran Terlewat'
  when r.status='leave_approved' then 'Cuti disetujui' when r.status='leave_pending' then 'Cuti menunggu keputusan'
  when r.status<>'active' then 'Semester belum aktif' when t<per.starts_at then 'Aktif — perkuliahan belum dimulai' else 'Semester aktif' end;
 result:=jsonb_build_object('available',true,'server_now',t,'demo',r.demo,'stage',stage,'registration',to_jsonb(r),'period',to_jsonb(per),
 'periods',(select coalesce(jsonb_agg(to_jsonb(b) order by b.starts_at),'[]') from public.m2_periods b join public.m2_registrations a on a.period_id=b.id where a.user_id=u),
 'permissions',(select coalesce(jsonb_agg(permission),'[]') from private.m2_staff where user_id=u),
 'courses',(select coalesce(jsonb_agg(to_jsonb(c) order by c.semester,c.code),'[]') from public.m2_courses c where c.curriculum=r.curriculum),
 'offerings',(select coalesce(jsonb_agg(to_jsonb(o)||jsonb_build_object('slots',(select coalesce(jsonb_agg(to_jsonb(s) order by s.weekday,s.starts),'[]') from public.m2_slots s where s.offering_id=o.id)) order by o.course_code),'[]') from public.m2_offerings o
  where o.period_id=p and o.track=r.track and o.campus=r.campus and o.program=r.program),
 'krs',(select to_jsonb(k) from public.m2_krs k where k.user_id=u and k.period_id=p),
 'krs_items',(select coalesce(jsonb_agg(i.offering_id),'[]') from public.m2_krs_items i where i.user_id=u and i.period_id=p),
 'equivalences',(select coalesce(jsonb_agg(to_jsonb(e)),'[]') from public.m2_equivalences e where e.user_id=u),
 'leave_requests',(select coalesce(jsonb_agg(to_jsonb(l) order by l.created_at desc),'[]') from public.m2_leave_requests l where l.user_id=u and l.period_id=p),
 'notifications',(select coalesce(jsonb_agg(to_jsonb(n) order by n.created_at desc,n.event_key),'[]') from public.m2_notifications n where n.user_id=u),
 'events',(select coalesce(jsonb_agg(to_jsonb(e)||jsonb_build_object('realization',case when e.realized_at<=t then e.realization end,'realized_at',case when e.realized_at<=t then e.realized_at end,'course_code',o.course_code,'class_code',o.class_code,'lecturer',o.lecturer,'title',c.name) order by e.starts_at,e.id),'[]')
  from public.m2_events e join public.m2_offerings o on o.id=e.offering_id join public.m2_courses c on c.code=o.course_code
  join public.m2_krs_items i on i.offering_id=o.id join public.m2_krs k on k.user_id=i.user_id and k.period_id=i.period_id
  where i.user_id=u and i.period_id=p and k.status='approved' and e.published_at<=t),
 'invoices',(select coalesce(jsonb_agg(to_jsonb(v)||jsonb_build_object(
  'paid',coalesce((select sum(a.amount) from public.m2_allocations a join public.m2_installments s on s.id=a.installment_id where s.invoice_id=v.id),0),
  'installments',(select coalesce(jsonb_agg(to_jsonb(s)||jsonb_build_object('paid',a.amount is not null) order by s.ordinal),'[]') from public.m2_installments s left join public.m2_allocations a on a.installment_id=s.id where s.invoice_id=v.id)
 ) order by v.created_at desc),'[]') from public.m2_invoices v where v.user_id=u and v.period_id=p),
 'tuition',(select jsonb_build_object('semester_fee',private.m2_tuition(r.program,r.semester),'standard_semesters',standard_semesters,'standard_total',standard_semester_fee*standard_semesters,'extension_semester_fee',extension_semester_fee,'basis','Konfigurasi pengguna: pembagian rata, bukan rincian tarif resmi kampus') from private.m2_configuration),
 'payment_instructions',jsonb_build_object('bank','BCA','account',(select demo_bank_account from private.m2_configuration),'qris_limit',(select qris_limit from private.m2_configuration),'recipient','Institusi Demo — bukan rekening nyata','fee',0),
 'payments',(select coalesce(jsonb_agg(to_jsonb(pay)||jsonb_build_object('qr_payload',case when pay.channel='qris' and r.demo then 'CAMPUS-SIMULATION-NO-PAYMENT:'||pay.id end) order by pay.created_at desc),'[]') from public.m2_payments pay join public.m2_installments s on s.id=pay.installment_id join public.m2_invoices v on v.id=s.invoice_id where v.user_id=u and v.period_id=p));
 return result;
end $$;

-- Finance reads a projection of the M2 allocation ledger, never duplicate balances.
create function public.m2_finance() returns jsonb language sql security invoker set search_path='' as $$
 select coalesce(jsonb_agg(row_data order by billed_on desc),'[]') from (
 select f.billed_on,to_jsonb(f) row_data from public.student_finance f
 union all
 select v.created_at::date,jsonb_build_object('id',v.id,'user_id',v.user_id,'description','Simulasi M2 — '||p.label,
  'amount',v.principal,'paid',coalesce((select sum(a.amount) from public.m2_allocations a join public.m2_installments s on s.id=a.installment_id where s.invoice_id=v.id),0),
  'billed_on',(v.created_at at time zone 'Asia/Jakarta')::date)
 from public.m2_invoices v join public.m2_periods p on p.id=v.period_id where not v.cancelled
 ) rows;
$$;
create function public.m2_snapshot(p_period text default null) returns jsonb
language sql security invoker set search_path='' as $$ select private.m2_snapshot(p_period) $$;
create function public.m2_command(p_action text,p_period text,p_data jsonb default '{}') returns jsonb
language sql security invoker set search_path='' as $$ select private.m2_command(p_action,p_period,p_data) $$;

-- Explicit allowlist. Helpers and fixture setup are never publicly executable.
do $$ declare f record; begin
 for f in select p.oid::regprocedure signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='private' and p.proname like 'm2_%' loop
  execute format('revoke all on function %s from public,anon,authenticated',f.signature);
 end loop;
end $$;
grant execute on function private.m2_authorized(uuid,text),private.m2_snapshot(text),private.m2_command(text,text,jsonb) to authenticated;
revoke all on function public.m2_snapshot(text),public.m2_command(text,text,jsonb),public.m2_finance() from public,anon;
grant execute on function public.m2_snapshot(text),public.m2_command(text,text,jsonb),public.m2_finance() to authenticated;

create function private.m2_review(p_user uuid,p_period text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare finance boolean; academic boolean; validator boolean; reconciler boolean;
begin
 finance:=private.m2_authorized(p_user,'finance'); academic:=private.m2_authorized(p_user,'academic');
 validator:=private.m2_authorized(p_user,'validator'); reconciler:=private.m2_authorized(p_user,'reconcile');
 if not (finance or academic or validator or reconciler) then raise exception 'Akses staf diperlukan' using errcode='42501'; end if;
 perform private.m2_sync(p_user,p_period);
 return jsonb_build_object(
  'registration',(select to_jsonb(r) from public.m2_registrations r where user_id=p_user and period_id=p_period),
  'krs',case when validator then (select to_jsonb(k) from public.m2_krs k where user_id=p_user and period_id=p_period) end,
  'leave_requests',case when academic then (select coalesce(jsonb_agg(to_jsonb(l)),'[]') from public.m2_leave_requests l where user_id=p_user and period_id=p_period) else '[]'::jsonb end,
  'events',case when academic then (select coalesce(jsonb_agg(to_jsonb(e) order by e.starts_at),'[]') from public.m2_events e join public.m2_krs_items i on i.offering_id=e.offering_id where i.user_id=p_user and i.period_id=p_period) else '[]'::jsonb end,
  'payments',case when finance or reconciler then (select coalesce(jsonb_agg(to_jsonb(pay)),'[]') from public.m2_payments pay join public.m2_installments s on s.id=pay.installment_id join public.m2_invoices v on v.id=s.invoice_id where v.user_id=p_user and v.period_id=p_period) else '[]'::jsonb end);
end $$;
create function public.m2_review(p_user uuid,p_period text) returns jsonb
language sql security invoker set search_path='' as $$ select private.m2_review(p_user,p_period) $$;
revoke all on function private.m2_review(uuid,text),public.m2_review(uuid,text) from public,anon;
grant execute on function private.m2_review(uuid,text),public.m2_review(uuid,text) to authenticated;
