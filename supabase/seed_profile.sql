-- Template administrator; bukan migrasi otomatis atau endpoint publik.
-- Buat Auth user dahulu, kemudian ganti placeholder email. Jangan simpan password.
begin;
do $$
declare
  v_email text := 'GANTI_EMAIL_AKUN_YANG_SUDAH_DIBUAT';
  v_user uuid;
begin
  select id into v_user from auth.users where lower(email)=lower(v_email);
  if v_user is null then raise exception 'Buat akun Auth dan isi email yang benar terlebih dahulu'; end if;
  -- Profil yang sudah berjalan tidak ditimpa tanpa tinjauan pengelola.
  if exists(select 1 from public.profiles where id=v_user) then
    raise exception 'Profil sudah tersedia; provisioning tidak diulang';
  end if;
  insert into public.profiles(id,full_name,preferred_name,role,avatar_variant,is_enabled,verification_status)
  values(v_user,'Prismatine Dante Viergo','Dante','student','male',true,'unverified');
  insert into public.students(user_id,nim,university,faculty,program)
  values(v_user,'20240801001','Universitas Esa Unggul','FASILKOM','Teknik Informatika');
  -- Informasi yang belum diberikan sengaja tetap NULL.
end $$;
commit;
