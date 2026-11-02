-- Profil hanya berisi identitas yang sudah diberikan; data akademik boleh NULL.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (char_length(btrim(full_name)) between 1 and 150),
  preferred_name text check (preferred_name is null or char_length(btrim(preferred_name)) between 1 and 50),
  role text not null default 'student' check (role in ('student','bap','lecturer')),
  avatar_variant text not null default 'neutral' check (avatar_variant in ('male','female','neutral')),
  avatar_path text check (avatar_path is null or (avatar_path like id::text || '/%' and avatar_path !~ '\.\.')),
  phone text check (phone is null or phone ~ '^\+[1-9][0-9]{7,14}$'),
  is_enabled boolean not null default false,
  verification_status text not null default 'unverified' check (verification_status in ('unverified','verified')),
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.students (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  nim text not null unique check (nim ~ '^[0-9]{8,20}$'),
  university text not null,
  faculty text not null,
  program text not null,
  campus text,
  entry_year integer check (entry_year between 1900 and 2200),
  current_semester integer check (current_semester > 0),
  academic_status text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Setiap perangkat memiliki tenggat sendiri. Refresh token tidak membuat sesi baru.
create table private.app_sessions (
  session_id uuid primary key references auth.sessions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  started_at timestamptz not null,
  expires_at timestamptz not null,
  revoked_at timestamptz
);
create index app_sessions_user_id_idx on private.app_sessions(user_id);
create table private.login_limits (
  key_hash text primary key,
  window_start timestamptz not null default now(),
  attempts integer not null default 1
);
alter table public.profiles enable row level security;
alter table public.students enable row level security;
alter table private.app_sessions enable row level security;
alter table private.login_limits enable row level security;
revoke all on public.profiles, public.students from anon, authenticated;
grant select on public.profiles, public.students to authenticated;
grant update(preferred_name, phone, avatar_variant, avatar_path) on public.profiles to authenticated;

-- Definer hanya untuk pemeriksaan internal; tidak menerima UUID buatan klien.
create function private.profile_session_valid() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from private.app_sessions s join public.profiles p on p.id=s.user_id
    where s.session_id = nullif(auth.jwt()->>'session_id','')::uuid
      and s.user_id = auth.uid() and s.revoked_at is null
      and s.expires_at > now() and p.is_enabled
  );
$$;
revoke all on function private.profile_session_valid() from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.profile_session_valid() to authenticated;
create policy own_profile_read on public.profiles for select to authenticated
using (id=(select auth.uid()) and (select private.profile_session_valid()));
create policy own_profile_update on public.profiles for update to authenticated
using (id=(select auth.uid()) and (select private.profile_session_valid()))
with check (id=(select auth.uid()) and (select private.profile_session_valid()));
create policy own_student_read on public.students for select to authenticated
using (user_id=(select auth.uid()) and (select private.profile_session_valid()));

create function private.touch_profile() returns trigger language plpgsql
set search_path = '' as $$ begin new.updated_at=now(); return new; end; $$;
create trigger profile_updated before update on public.profiles for each row execute function private.touch_profile();
create trigger student_updated before update on public.students for each row execute function private.touch_profile();
revoke all on function private.touch_profile() from public, anon, authenticated;

-- Endpoint login memanggil fungsi administratif ini, bukan aplikasi Flutter.
create function public.resolve_student_login(p_nim text) returns text
language sql security definer set search_path = '' as $$
  select u.email from auth.users u join public.profiles p on p.id=u.id
  join public.students s on s.user_id=p.id where s.nim=p_nim and p.is_enabled and p.role='student';
$$;
create function public.consume_login_attempt(p_key text, p_limit integer) returns boolean
language plpgsql security definer set search_path = '' as $$
declare n integer;
begin
  -- Penghitung atomik: dua permintaan bersamaan tidak dapat melewati batas.
  delete from private.login_limits where window_start < now()-interval '1 day';
  insert into private.login_limits(key_hash) values(p_key)
  on conflict(key_hash) do update set
    attempts=case when login_limits.window_start < now()-interval '15 minutes' then 1 else login_limits.attempts+1 end,
    window_start=case when login_limits.window_start < now()-interval '15 minutes' then now() else login_limits.window_start end
  returning attempts into n;
  return n <= p_limit;
end; $$;
create function public.register_profile_session(p_session uuid, p_user uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare started timestamptz; expiry timestamptz;
begin
  select created_at into started from auth.sessions where id=p_session and user_id=p_user;
  if started is null then raise exception 'Session unavailable'; end if;
  expiry := started + interval '30 minutes';
  insert into private.app_sessions(session_id,user_id,started_at,expires_at)
  values(p_session,p_user,started,expiry) on conflict(session_id) do nothing;
  return jsonb_build_object('expires_at',expiry,'server_now',now());
end; $$;
revoke all on function public.resolve_student_login(text), public.consume_login_attempt(text,integer), public.register_profile_session(uuid,uuid) from public, anon, authenticated;
grant execute on function public.resolve_student_login(text), public.consume_login_attempt(text,integer), public.register_profile_session(uuid,uuid) to service_role;

-- Pemilik dapat mencabut sesinya sendiri, tetapi tidak memperpanjangnya.
create function public.revoke_profile_session() returns void language sql security definer set search_path = '' as $$
  update private.app_sessions set revoked_at=now()
  where session_id=nullif(auth.jwt()->>'session_id','')::uuid and user_id=auth.uid();
$$;
create function public.profile_session_status() returns jsonb language sql security definer set search_path = '' as $$
  select jsonb_build_object('expires_at',s.expires_at,'server_now',now()) from private.app_sessions s
  where s.session_id=nullif(auth.jwt()->>'session_id','')::uuid and s.user_id=auth.uid()
    and private.profile_session_valid();
$$;
revoke all on function public.revoke_profile_session(), public.profile_session_status() from public, anon;
grant execute on function public.revoke_profile_session(), public.profile_session_status() to authenticated;

-- Foto tidak publik. Unduhan terautentikasi tetap memeriksa tenggat sesi.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('student-avatars','student-avatars',false,2097152,array['image/png','image/jpeg']);
create policy avatar_read on storage.objects for select to authenticated
using(bucket_id='student-avatars' and (storage.foldername(name))[1]=(select auth.uid())::text
  and (select private.profile_session_valid()));
create policy avatar_insert on storage.objects for insert to authenticated
with check(bucket_id='student-avatars' and (storage.foldername(name))[1]=(select auth.uid())::text
  and (select private.profile_session_valid()));
create policy avatar_delete on storage.objects for delete to authenticated
using(bucket_id='student-avatars' and (storage.foldername(name))[1]=(select auth.uid())::text
  and (select private.profile_session_valid()));
