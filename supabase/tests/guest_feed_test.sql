\ir ../migrations/202611230001_fix_guest_feed.sql
-- Uji tamu (role anon): feed_spots dan comments harus bisa dibaca tanpa error permission denied,
-- namun isi tabel user_blocks tetap tidak bisa dilihat oleh tamu.

-- Buat satu spot dan komentar oleh pengguna c agar ada data uji.
select pg_temp.act('00000000-0000-0000-0000-00000000000c');
insert into public.posts (id, owner_id, title, city, category, story, lat, lng)
  values ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-00000000000c',
    'Spot tamu', 'Surabaya', 'kuliner', 'Bisa dilihat tamu.', -7.25, 112.75);
insert into public.comments (post_id, user_id, body)
  values ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-00000000000c', 'Komentar untuk tamu.');
insert into public.user_blocks (blocker_id, blocked_id)
  values ('00000000-0000-0000-0000-00000000000c', '00000000-0000-0000-0000-00000000000a');

-- Beralih ke mode tamu (role anon, auth.uid() = null).
set local role anon;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claim.role', 'anon', true);

do $$ begin
  if not exists (
    select 1 from public.feed_spots(null, null, 'popular', null, 'Spot tamu', 40, null)
  ) then
    raise exception 'Tamu harus bisa memuat feed_spots';
  end if;
  if not exists (
    select 1 from public.comments where post_id = '11111111-1111-1111-1111-111111111111'
  ) then
    raise exception 'Tamu harus bisa membaca komentar';
  end if;
  if exists (select 1 from public.user_blocks) then
    raise exception 'Tamu tidak boleh melihat isi user_blocks';
  end if;
end $$;

\echo 'SEMUA UJI TAMU LULUS'
