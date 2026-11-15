-- Snapshot dan simpan telepon bersama harus memakai satu transaksi server.
-- SECURITY INVOKER mempertahankan RLS dan privilege kolom pemanggil.
create function public.load_student_biodata() returns jsonb
language sql stable security invoker set search_path = '' as $$
  select coalesce(to_jsonb(b), '{}'::jsonb)
    || jsonb_build_object('phone', p.phone, '_profile_version', p.updated_at)
  from public.profiles p left join public.student_biodata b on b.user_id=p.id
  where p.id=(select auth.uid());
$$;

create function public.save_student_biodata(
  p_values jsonb,
  p_expected_profile_version timestamptz,
  p_expected_biodata_version timestamptz
) returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare
  owner_id uuid := auth.uid();
  profile_version timestamptz;
  v public.student_biodata;
  saved public.student_biodata;
begin
  if owner_id is null then
    raise exception using errcode='42501', message='Account access denied';
  end if;
  if jsonb_typeof(p_values) is distinct from 'object' or exists (
    select 1 from jsonb_object_keys(p_values) k
    where k not in ('nik', 'passport_number', 'gender', 'religion', 'blood_type', 'birth_place', 'birth_date', 'street', 'rt', 'rw', 'village', 'district', 'province', 'city', 'postal_code', 'phone', 'private_email', 'marital_status', 'citizenship')
  ) then
    raise exception using errcode='22023', message='Invalid biodata fields';
  end if;

  -- Urutan profil lalu biodata mencegah dua editor memakai versi kolom bersama berbeda.
  select updated_at into profile_version from public.profiles
  where id=owner_id for update;
  if not found or p_expected_profile_version is null
     or profile_version is distinct from p_expected_profile_version then
    raise exception using errcode='40001', message='Profile version conflict';
  end if;
  v := jsonb_populate_record(null::public.student_biodata, p_values);
  if p_expected_biodata_version is null then
    -- PK menolak editor yang masih mengira baris belum ada; tidak ada upsert.
    insert into public.student_biodata (user_id, nik, passport_number, gender, religion, blood_type, birth_place, birth_date, street, rt, rw, village, district, province, city, postal_code, phone, private_email, marital_status, citizenship)
    values (owner_id, v.nik, v.passport_number, v.gender, v.religion, v.blood_type, v.birth_place, v.birth_date, v.street, v.rt, v.rw, v.village, v.district, v.province, v.city, v.postal_code, v.phone, v.private_email, v.marital_status, v.citizenship) returning * into saved;
  else
    update public.student_biodata set
      nik=v.nik,
      passport_number=v.passport_number,
      gender=v.gender,
      religion=v.religion,
      blood_type=v.blood_type,
      birth_place=v.birth_place,
      birth_date=v.birth_date,
      street=v.street,
      rt=v.rt,
      rw=v.rw,
      village=v.village,
      district=v.district,
      province=v.province,
      city=v.city,
      postal_code=v.postal_code,
      phone=v.phone,
      private_email=v.private_email,
      marital_status=v.marital_status,
      citizenship=v.citizenship
    where user_id=owner_id and updated_at=p_expected_biodata_version
    returning * into saved;
    if not found then
      raise exception using errcode='40001', message='Biodata version conflict';
    end if;
  end if;
  -- Trigger sinkronisasi phone berjalan sebelum hasil dikirim. Jika gagal,
  -- transaksi PostgreSQL membatalkan kedua tabel sekaligus.
  select updated_at into profile_version from public.profiles where id=owner_id;
  return to_jsonb(saved) || jsonb_build_object('_profile_version', profile_version);
exception when unique_violation then
  raise exception using errcode='40001', message='Biodata version conflict';
end;
$$;

revoke all on function public.load_student_biodata() from public, anon;
revoke all on function public.save_student_biodata(jsonb,timestamptz,timestamptz) from public, anon;
grant execute on function public.load_student_biodata() to authenticated;
grant execute on function public.save_student_biodata(jsonb,timestamptz,timestamptz) to authenticated;
