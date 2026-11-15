-- Uji profil sosial. Jalankan setelah marketplace_test.sql (lihat README).
\set ON_ERROR_STOP on
\set QUIET on

create or replace function pg_temp.act(who uuid) returns void language plpgsql as $$
begin
  if who is null then
    perform set_config('request.jwt.claim.sub', '', false);
    execute 'set role anon';
  else
    perform set_config('request.jwt.claim.sub', who::text, false);
    execute 'set role authenticated';
  end if;
end $$;

create or replace function pg_temp.fails(statement text, expected text) returns void language plpgsql as $$
begin
  execute statement;
  raise exception 'SEHARUSNYA GAGAL: %', statement;
exception when others then
  if sqlerrm like 'SEHARUSNYA GAGAL%' then raise; end if;
  if position(lower(expected) in lower(sqlerrm)) = 0 then
    raise exception 'Pesan salah untuk "%": %', statement, sqlerrm;
  end if;
end $$;

\ir ../migrations/202611170001_profiles_social.sql

\echo '1. username otomatis'
do $$ begin
  if exists (select 1 from public.profiles where username is null) then raise exception 'username kosong'; end if;
end $$;
insert into auth.users (id, email, raw_user_meta_data)
  values ('00000000-0000-0000-0000-00000000000e', 'baru@spots.test', '{"display_name":"Nama Baru!"}');
do $$ begin
  if (select username from public.profiles where id = '00000000-0000-0000-0000-00000000000e') <> 'namabaru0000' then
    raise exception 'username baru salah: %', (select username from public.profiles where id = '00000000-0000-0000-0000-00000000000e');
  end if;
end $$;

\echo '2. ubah profil sendiri saja'
select pg_temp.act('00000000-0000-0000-0000-00000000000c');
update public.profiles set username = 'pembeli_kece', bio = 'Pemburu bakso.' where id = '00000000-0000-0000-0000-00000000000c';
select pg_temp.fails($$update public.profiles set username = 'PAKAI SPASI' where id = '00000000-0000-0000-0000-00000000000c'$$, 'profiles_username_format');
select pg_temp.fails($$update public.profiles set username = 'pembeli_kece' where id = '00000000-0000-0000-0000-00000000000c' and false; update public.profiles set username = (select username from public.profiles where id = '00000000-0000-0000-0000-00000000000b') where id = '00000000-0000-0000-0000-00000000000c'$$, 'duplicate');
update public.profiles set bio = 'dibajak' where id = '00000000-0000-0000-0000-00000000000b';
do $$ begin
  if (select bio from public.profiles where id = '00000000-0000-0000-0000-00000000000b') = 'dibajak' then
    raise exception 'mengubah profil orang lain';
  end if;
end $$;

\echo '3. ikuti'
insert into public.follows (follower_id, following_id)
  values ('00000000-0000-0000-0000-00000000000c', '00000000-0000-0000-0000-00000000000b');
select pg_temp.fails($$insert into public.follows (follower_id, following_id)
  values ('00000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-00000000000d')$$, 'row-level security');
select pg_temp.fails($$insert into public.follows (follower_id, following_id)
  values ('00000000-0000-0000-0000-00000000000c', '00000000-0000-0000-0000-00000000000c')$$, 'check');
do $$ begin
  if not (select is_following from public.profile_stats('00000000-0000-0000-0000-00000000000b')) then
    raise exception 'status ikuti salah';
  end if;
  if (select followers from public.profile_stats('00000000-0000-0000-0000-00000000000b')) <> 1 then
    raise exception 'jumlah pengikut salah';
  end if;
end $$;

\echo '4. tag teman'
select id as post_id from public.posts where owner_id = '00000000-0000-0000-0000-00000000000c' limit 1 \gset
insert into public.post_tags (post_id, user_id) values (:'post_id', '00000000-0000-0000-0000-00000000000b');
select pg_temp.act('00000000-0000-0000-0000-00000000000d');
select pg_temp.fails(format($$insert into public.post_tags (post_id, user_id) values (%L, '00000000-0000-0000-0000-00000000000d')$$, :'post_id'), 'row-level security');
select pg_temp.act(null);
do $$ begin
  if (select count(*) from public.feed_spots(null, null, 'tagged', null, null, 40, '00000000-0000-0000-0000-00000000000b')) <> 1 then
    raise exception 'feed tagged salah';
  end if;
  if (select count(*) from public.feed_spots(null, null, 'user', null, null, 40, '00000000-0000-0000-0000-00000000000c')) <> 1 then
    raise exception 'feed user salah';
  end if;
  if (select author_username from public.feed_spots(null, null, 'popular') limit 1) is null then
    raise exception 'username penulis kosong';
  end if;
end $$;

select pg_temp.act('00000000-0000-0000-0000-00000000000c');
do $$ begin
  if (select count(*) from public.feed_spots(null, null, 'following')) <> 0 then
    raise exception 'feed following salah';
  end if;
end $$;

reset role;
\echo 'SEMUA UJI SOSIAL LULUS'
