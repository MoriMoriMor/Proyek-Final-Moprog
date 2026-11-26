-- Tes SQL: keunikan email dan username pada auth.users & public.profiles.
-- Jalankan di transaksi uji (otomatis rollback di akhir).

begin;

do $$
declare
  u1 uuid := 'f7000000-0000-4000-8000-000000000001';
  u2 uuid := 'f7000000-0000-4000-8000-000000000002';
  u3 uuid := 'f7000000-0000-4000-8000-000000000003';
  u4 uuid := 'f7000000-0000-4000-8000-000000000004';
  rejected boolean := false;
begin
  -- 1. Buat pengguna pertama dengan username eksplisit
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) values (
    '00000000-0000-0000-0000-000000000000', u1, 'authenticated', 'authenticated',
    'unik.satu@test.spots.local', '',
    '{"provider":"email"}', '{"display_name":"Sari Satu","username":"sari.unik"}',
    now(), now()
  );

  if public.is_username_available('sari.unik') then
    raise exception 'seharusnya sari.unik sudah tidak tersedia';
  end if;

  -- 2. Harus ditolak: pendaftaran dengan email sama (beda huruf besar/kecil)
  rejected := false;
  begin
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) values (
      '00000000-0000-0000-0000-000000000000', u2, 'authenticated', 'authenticated',
      'UNIK.SATU@test.spots.local', '',
      '{"provider":"email"}', '{"display_name":"Sari Dua","username":"sari.dua"}',
      now(), now()
    );
  exception when unique_violation then
    rejected := true;
  end;
  if not rejected then
    raise exception 'email ganda tidak ditolak';
  end if;

  -- 3. Harus ditolak: pendaftaran dengan username sama
  rejected := false;
  begin
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) values (
      '00000000-0000-0000-0000-000000000000', u3, 'authenticated', 'authenticated',
      'unik.tiga@test.spots.local', '',
      '{"provider":"email"}', '{"display_name":"Sari Tiga","username":"SARI.UNIK"}',
      now(), now()
    );
  exception when unique_violation then
    rejected := true;
  end;
  if not rejected then
    raise exception 'username ganda saat daftar tidak ditolak';
  end if;

  -- 4. Harus ditolak: ubah profil ke username milik pengguna lain
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) values (
    '00000000-0000-0000-0000-000000000000', u4, 'authenticated', 'authenticated',
    'unik.empat@test.spots.local', '',
    '{"provider":"email"}', '{"display_name":"Sari Satu"}',
    now(), now()
  );

  rejected := false;
  begin
    update public.profiles set username = 'sari.unik' where id = u4;
  exception when unique_violation then
    rejected := true;
  end;
  if not rejected then
    raise exception 'update username ganda tidak ditolak';
  end if;
end $$;

rollback;
