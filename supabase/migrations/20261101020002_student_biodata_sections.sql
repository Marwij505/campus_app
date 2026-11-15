-- Bagian pribadi dipisahkan dari identitas akademik yang hanya dikelola kampus.
alter table public.students add column campus_email text check (campus_email is null or campus_email ~ '^[^\s@]+@[^\s@]+\.[^\s@]+$');
alter table public.students add column advisor_name text, add column advisor_code text, add column enrollment_period text, add column study_basis text, add column admission_wave text, add column admission_status text;
create table public.student_biodata (
  user_id uuid primary key references public.students(user_id) on delete cascade,
  nik text check (nik is null or (char_length(nik) between 1 and 150 and nik ~ '^[0-9]{16}$')),
  passport_number text check (passport_number is null or (char_length(passport_number) between 1 and 150)),
  gender text check (gender is null or (char_length(gender) between 1 and 150 and gender in ('Laki-laki', 'Perempuan'))),
  religion text check (religion is null or (char_length(religion) between 1 and 150 and religion in ('Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu', 'Kepercayaan lainnya'))),
  blood_type text check (blood_type is null or (char_length(blood_type) between 1 and 150 and blood_type in ('A', 'B', 'AB', 'O', 'Tidak diketahui'))),
  birth_place text check (birth_place is null or (char_length(birth_place) between 1 and 150)),
  birth_date date check (birth_date is null or (birth_date between date '1900-01-01' and current_date)),
  street text check (street is null or (char_length(street) between 1 and 1000)),
  rt text check (rt is null or (char_length(rt) between 1 and 150 and rt ~ '^[0-9]{1,3}$')),
  rw text check (rw is null or (char_length(rw) between 1 and 150 and rw ~ '^[0-9]{1,3}$')),
  village text check (village is null or (char_length(village) between 1 and 150)),
  district text check (district is null or (char_length(district) between 1 and 150)),
  province text check (province is null or (char_length(province) between 1 and 150)),
  city text check (city is null or (char_length(city) between 1 and 150)),
  postal_code text check (postal_code is null or (char_length(postal_code) between 1 and 150 and postal_code ~ '^[0-9]{5}$')),
  phone text check (phone is null or (char_length(phone) between 1 and 150 and phone ~ '^\+[1-9][0-9]{7,14}$')),
  private_email text check (private_email is null or (char_length(private_email) between 1 and 150 and private_email ~ '^[^\s@]+@[^\s@]+\.[^\s@]+$')),
  marital_status text check (marital_status is null or (char_length(marital_status) between 1 and 150 and marital_status in ('Belum menikah', 'Menikah', 'Cerai hidup', 'Cerai mati'))),
  citizenship text check (citizenship is null or (char_length(citizenship) between 1 and 150 and citizenship in ('Warga Negara Indonesia', 'Warga Negara Asing'))),
  updated_at timestamptz not null default now()
);
alter table public.student_biodata enable row level security;
revoke all on public.student_biodata from anon, authenticated;
grant select on public.student_biodata to authenticated;
grant insert(user_id, nik, passport_number, gender, religion, blood_type, birth_place, birth_date, street, rt, rw, village, district, province, city, postal_code, phone, private_email, marital_status, citizenship), update(nik, passport_number, gender, religion, blood_type, birth_place, birth_date, street, rt, rw, village, district, province, city, postal_code, phone, private_email, marital_status, citizenship) on public.student_biodata to authenticated;
create policy own_read on public.student_biodata for select to authenticated using (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create policy own_insert on public.student_biodata for insert to authenticated with check (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create policy own_update on public.student_biodata for update to authenticated using (user_id=(select auth.uid()) and (select private.profile_session_valid())) with check (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create trigger touch_updated before update on public.student_biodata for each row execute function private.touch_profile();

create table public.student_education (
  user_id uuid primary key references public.students(user_id) on delete cascade,
  school_name text check (school_name is null or (char_length(school_name) between 1 and 150)),
  school_address text check (school_address is null or (char_length(school_address) between 1 and 1000)),
  school_phone text check (school_phone is null or (char_length(school_phone) between 1 and 150 and school_phone ~ '^\+[1-9][0-9]{7,14}$')),
  average_score numeric(5,2) check (average_score is null or (average_score between 0 and 100)),
  nisn text check (nisn is null or (char_length(nisn) between 1 and 150 and nisn ~ '^[0-9]{10}$')),
  diploma_number text check (diploma_number is null or (char_length(diploma_number) between 1 and 150)),
  updated_at timestamptz not null default now()
);
alter table public.student_education enable row level security;
revoke all on public.student_education from anon, authenticated;
grant select on public.student_education to authenticated;
grant insert(user_id, school_name, school_address, school_phone, average_score, nisn, diploma_number), update(school_name, school_address, school_phone, average_score, nisn, diploma_number) on public.student_education to authenticated;
create policy own_read on public.student_education for select to authenticated using (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create policy own_insert on public.student_education for insert to authenticated with check (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create policy own_update on public.student_education for update to authenticated using (user_id=(select auth.uid()) and (select private.profile_session_valid())) with check (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create trigger touch_updated before update on public.student_education for each row execute function private.touch_profile();

create table public.student_family (
  user_id uuid primary key references public.students(user_id) on delete cascade,
  father_name text check (father_name is null or (char_length(father_name) between 1 and 150)),
  mother_name text check (mother_name is null or (char_length(mother_name) between 1 and 150)),
  street text check (street is null or (char_length(street) between 1 and 1000)),
  rt text check (rt is null or (char_length(rt) between 1 and 150 and rt ~ '^[0-9]{1,3}$')),
  rw text check (rw is null or (char_length(rw) between 1 and 150 and rw ~ '^[0-9]{1,3}$')),
  village text check (village is null or (char_length(village) between 1 and 150)),
  district text check (district is null or (char_length(district) between 1 and 150)),
  province text check (province is null or (char_length(province) between 1 and 150)),
  city text check (city is null or (char_length(city) between 1 and 150)),
  postal_code text check (postal_code is null or (char_length(postal_code) between 1 and 150 and postal_code ~ '^[0-9]{5}$')),
  phone text check (phone is null or (char_length(phone) between 1 and 150 and phone ~ '^\+[1-9][0-9]{7,14}$')),
  father_education text check (father_education is null or (char_length(father_education) between 1 and 150 and father_education in ('Tidak sekolah', 'SD', 'SMP', 'SMA', 'SMK', 'D1', 'D2', 'D3', 'D4', 'S1', 'S2', 'S3'))),
  mother_education text check (mother_education is null or (char_length(mother_education) between 1 and 150 and mother_education in ('Tidak sekolah', 'SD', 'SMP', 'SMA', 'SMK', 'D1', 'D2', 'D3', 'D4', 'S1', 'S2', 'S3'))),
  father_job text check (father_job is null or (char_length(father_job) between 1 and 150)),
  mother_job text check (mother_job is null or (char_length(mother_job) between 1 and 150)),
  emergency_name text check (emergency_name is null or (char_length(emergency_name) between 1 and 150)),
  emergency_phone text check (emergency_phone is null or (char_length(emergency_phone) between 1 and 150 and emergency_phone ~ '^\+[1-9][0-9]{7,14}$')),
  updated_at timestamptz not null default now()
);
alter table public.student_family enable row level security;
revoke all on public.student_family from anon, authenticated;
grant select on public.student_family to authenticated;
grant insert(user_id, father_name, mother_name, street, rt, rw, village, district, province, city, postal_code, phone, father_education, mother_education, father_job, mother_job, emergency_name, emergency_phone), update(father_name, mother_name, street, rt, rw, village, district, province, city, postal_code, phone, father_education, mother_education, father_job, mother_job, emergency_name, emergency_phone) on public.student_family to authenticated;
create policy own_read on public.student_family for select to authenticated using (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create policy own_insert on public.student_family for insert to authenticated with check (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create policy own_update on public.student_family for update to authenticated using (user_id=(select auth.uid()) and (select private.profile_session_valid())) with check (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create trigger touch_updated before update on public.student_family for each row execute function private.touch_profile();

create table public.student_employment (
  user_id uuid primary key references public.students(user_id) on delete cascade,
  employment_status text check (employment_status is null or (char_length(employment_status) between 1 and 150 and employment_status in ('Belum kerja', 'Bekerja', 'Wiraswasta'))),
  occupation text check (occupation is null or (char_length(occupation) between 1 and 150)),
  company text check (company is null or (char_length(company) between 1 and 150)),
  institution_type text check (institution_type is null or (char_length(institution_type) between 1 and 150 and institution_type in ('Pemerintah', 'Swasta', 'BUMN', 'BUMD', 'Organisasi nirlaba', 'Usaha sendiri', 'Lainnya'))),
  company_address text check (company_address is null or (char_length(company_address) between 1 and 1000)),
  province text check (province is null or (char_length(province) between 1 and 150)),
  city text check (city is null or (char_length(city) between 1 and 150)),
  company_phone text check (company_phone is null or (char_length(company_phone) between 1 and 150 and company_phone ~ '^\+[1-9][0-9]{7,14}$')),
  position text check (position is null or (char_length(position) between 1 and 150)),
  funding_party text check (funding_party is null or (char_length(funding_party) between 1 and 150)),
  updated_at timestamptz not null default now()
);
alter table public.student_employment enable row level security;
revoke all on public.student_employment from anon, authenticated;
grant select on public.student_employment to authenticated;
grant insert(user_id, employment_status, occupation, company, institution_type, company_address, province, city, company_phone, position, funding_party), update(employment_status, occupation, company, institution_type, company_address, province, city, company_phone, position, funding_party) on public.student_employment to authenticated;
create policy own_read on public.student_employment for select to authenticated using (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create policy own_insert on public.student_employment for insert to authenticated with check (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create policy own_update on public.student_employment for update to authenticated using (user_id=(select auth.uid()) and (select private.profile_session_valid())) with check (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create trigger touch_updated before update on public.student_employment for each row execute function private.touch_profile();

create table public.student_accessibility (
  user_id uuid primary key references public.students(user_id) on delete cascade,
  has_disability text check (has_disability is null or (char_length(has_disability) between 1 and 150 and has_disability in ('Ya', 'Tidak', 'Tidak ingin menyampaikan'))),
  description text check (description is null or (char_length(description) between 1 and 1000)),
  accommodations text check (accommodations is null or (char_length(accommodations) between 1 and 1000)),
  updated_at timestamptz not null default now()
);
alter table public.student_accessibility enable row level security;
revoke all on public.student_accessibility from anon, authenticated;
grant select on public.student_accessibility to authenticated;
grant insert(user_id, has_disability, description, accommodations), update(has_disability, description, accommodations) on public.student_accessibility to authenticated;
create policy own_read on public.student_accessibility for select to authenticated using (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create policy own_insert on public.student_accessibility for insert to authenticated with check (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create policy own_update on public.student_accessibility for update to authenticated using (user_id=(select auth.uid()) and (select private.profile_session_valid())) with check (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create trigger touch_updated before update on public.student_accessibility for each row execute function private.touch_profile();

create function private.sync_biodata_phone() returns trigger language plpgsql security invoker set search_path='' as $$
begin
  update public.profiles set phone=new.phone where id=new.user_id;
  return new;
end; $$;
revoke all on function private.sync_biodata_phone() from public, anon, authenticated;
create trigger sync_phone after insert or update of phone on public.student_biodata for each row execute function private.sync_biodata_phone();

-- Catatan biaya hanya ditulis pengelola; mahasiswa tidak bisa mengubah tagihannya.
create table public.student_finance (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.students(user_id) on delete cascade,
  period text not null check (char_length(period) between 1 and 150),
  category text not null check (char_length(category) between 1 and 150),
  description text not null check (char_length(description) between 1 and 250),
  amount numeric(14,2) not null check (amount >= 0),
  paid numeric(14,2) not null default 0 check (paid >= 0 and paid <= amount),
  billed_on date not null, due_on date, paid_on date
);
create index student_finance_owner_date on public.student_finance(user_id,billed_on desc);
alter table public.student_finance enable row level security;
revoke all on public.student_finance from anon, authenticated;
grant select on public.student_finance to authenticated;
create policy own_read on public.student_finance for select to authenticated using (user_id=(select auth.uid()) and (select private.profile_session_valid()));

-- Metadata berkas dan isi berkas sama-sama privat; tidak memakai URL publik.
create table public.student_documents (
  user_id uuid not null references public.students(user_id) on delete cascade,
  kind text not null check (kind in ('ktp','kk','diploma','payment_statement','passport')),
  path text not null check (path like user_id::text || '/%' and path !~ '\.\.'),
  file_name text not null check (char_length(file_name) between 1 and 200),
  mime_type text not null check (mime_type in ('application/pdf','image/jpeg','image/png','application/msword')),
  size_bytes integer not null check (size_bytes between 1 and 524288),
  updated_at timestamptz not null default now(),
  primary key(user_id,kind)
);
alter table public.student_documents enable row level security;
revoke all on public.student_documents from anon, authenticated;
grant select, delete on public.student_documents to authenticated;
grant insert(user_id,kind,path,file_name,mime_type,size_bytes), update(path,file_name,mime_type,size_bytes) on public.student_documents to authenticated;
create policy own_read on public.student_documents for select to authenticated using (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create policy own_insert on public.student_documents for insert to authenticated with check (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create policy own_update on public.student_documents for update to authenticated using (user_id=(select auth.uid()) and (select private.profile_session_valid())) with check (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create policy own_delete on public.student_documents for delete to authenticated using (user_id=(select auth.uid()) and (select private.profile_session_valid()));
create trigger touch_updated before update on public.student_documents for each row execute function private.touch_profile();
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('student-documents','student-documents',false,524288,array['application/pdf','image/jpeg','image/png','application/msword']);
create policy document_read on storage.objects for select to authenticated using(bucket_id='student-documents' and (storage.foldername(name))[1]=(select auth.uid())::text and (select private.profile_session_valid()));
create policy document_insert on storage.objects for insert to authenticated with check(bucket_id='student-documents' and (storage.foldername(name))[1]=(select auth.uid())::text and (select private.profile_session_valid()));
create policy document_delete on storage.objects for delete to authenticated using(bucket_id='student-documents' and (storage.foldername(name))[1]=(select auth.uid())::text and (select private.profile_session_valid()));
