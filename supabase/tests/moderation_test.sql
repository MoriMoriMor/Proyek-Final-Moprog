\ir ../migrations/202611210001_moderation.sql
-- Uji moderasi: lapor konten, blokir pengguna menyembunyikan feed, non-admin ditolak memproses laporan.

-- 1. Pengguna tidak boleh memblokir diri sendiri atau menyisipkan blokir atas nama orang lain.
select pg_temp.act('00000000-0000-0000-0000-00000000000c');
select pg_temp.fails($$insert into public.user_blocks (blocker_id, blocked_id) values ('00000000-0000-0000-0000-00000000000c', '00000000-0000-0000-0000-00000000000c')$$, 'check constraint');
select pg_temp.fails($$insert into public.user_blocks (blocker_id, blocked_id) values ('00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000c')$$, 'row-level security');

-- 2. Pengguna bisa melapor, namun non-admin tidak boleh memproses laporan.
insert into public.reports (reporter_id, target_type, target_id, reason)
  values ('00000000-0000-0000-0000-00000000000c', 'user', '00000000-0000-0000-0000-00000000000a', 'Akun spam');
select pg_temp.fails($$select public.resolve_report((select id from public.reports limit 1), 'resolved')$$, 'Hanya admin');

-- 3. Blokir menyembunyikan spot milik pengguna yang diblokir dari feed_spots.
insert into public.posts (owner_id, title, city, category, story, lat, lng)
  values ('00000000-0000-0000-0000-00000000000a', 'Spot terblokir', 'Bandung', 'kuliner', 'Tes blokir.', -6.91, 107.61);

insert into public.user_blocks (blocker_id, blocked_id)
  values ('00000000-0000-0000-0000-00000000000c', '00000000-0000-0000-0000-00000000000a');

do $$ begin
  if exists (
    select 1 from public.feed_spots(null, null, 'popular', null, 'Spot terblokir', 40, null)
  ) then
    raise exception 'Spot dari pengguna yang diblokir harus tersembunyi';
  end if;
end $$;

\echo 'SEMUA UJI MODERASI LULUS'
