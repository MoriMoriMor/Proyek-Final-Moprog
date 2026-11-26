-- Pastikan tidak ada dua pengguna dengan username yang sama maupun email yang sama.
-- Aman dijalankan ulang setelah 202611240001_places_media_payment_opt.sql.

-- 1. Rapikan nilai username lama menjadi huruf kecil tanpa spasi tepi.
update public.profiles
set username = lower(btrim(username))
where username <> lower(btrim(username));

alter table public.profiles drop constraint if exists profiles_username_normalized;
alter table public.profiles add constraint profiles_username_normalized
  check (username = lower(btrim(username)));

-- Indeks unik tanpa membedakan huruf besar/kecil.
create unique index if not exists profiles_username_lower_key
  on public.profiles (lower(btrim(username)));

-- 2. Fungsi bantu cek ketersediaan username.
create or replace function public.is_username_available(
  p_username text,
  p_exclude uuid default null
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    p_username is not null
    and lower(btrim(p_username)) ~ '^[a-z0-9_.]{3,20}$'
    and not exists (
      select 1
      from public.profiles p
      where lower(btrim(p.username)) = lower(btrim(p_username))
        and (p_exclude is null or p.id <> p_exclude)
    );
$$;

revoke all on function public.is_username_available(text, uuid) from public;
grant execute on function public.is_username_available(text, uuid) to anon, authenticated;

-- 3. Perketat pembuatan profil saat pendaftaran akun baru:
--    - Tolak email ganda (tanpa membedakan huruf besar/kecil).
--    - Tolak username pilihan pengguna jika sudah dipakai akun lain.
--    - Pastikan username bawaan otomatis bebas bentrok.
create or replace function public.create_profile_for_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  clean_email text := lower(btrim(coalesce(new.email, '')));
  requested_username text := lower(btrim(coalesce(new.raw_user_meta_data ->> 'username', '')));
  name text := left(case
    when char_length(coalesce(nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''), '')) >= 2
      then btrim(new.raw_user_meta_data ->> 'display_name')
    when char_length(coalesce(split_part(clean_email, '@', 1), '')) >= 2
      then split_part(clean_email, '@', 1)
    else 'Traveler' end, 60);
  base_handle text;
  final_handle text;
  suffix int := 0;
begin
  if clean_email <> '' and exists (
    select 1
    from auth.users u
    where u.id <> new.id
      and u.email is not null
      and lower(btrim(u.email)) = clean_email
  ) then
    raise exception 'Email ini sudah terdaftar.' using errcode = '23505';
  end if;

  if requested_username <> '' then
    if requested_username !~ '^[a-z0-9_.]{3,20}$' then
      raise exception 'Username 3-20 karakter: huruf kecil, angka, titik, atau _.'
        using errcode = '22023';
    end if;
    if exists (
      select 1
      from public.profiles p
      where lower(btrim(p.username)) = requested_username
    ) then
      raise exception 'Username sudah dipakai.' using errcode = '23505';
    end if;
    final_handle := requested_username;
  else
    base_handle := public.default_username(name, new.id);
    final_handle := base_handle;
    while exists (
      select 1
      from public.profiles p
      where lower(btrim(p.username)) = final_handle
    ) loop
      suffix := suffix + 1;
      final_handle := left(base_handle, 17) || lpad(suffix::text, 3, '0');
    end loop;
  end if;

  insert into public.profiles (id, display_name, username)
  values (new.id, name, final_handle);
  return new;
end;
$$;
