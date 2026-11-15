-- Spot Surabaya + 6 akun warga. Aman dijalankan ulang.
create extension if not exists http with schema extensions;
create or replace function pg_temp.wiki_img(titles text[]) returns text
language plpgsql as $f$
declare t text; res record; u text;
begin
  foreach t in array titles loop
    begin
      select * into res from extensions.http((
        'GET',
        'https://' || split_part(t, ':', 1) || '.wikipedia.org/api/rest_v1/page/summary/'
          || replace(substr(t, position(':' in t) + 1), ' ', '_'),
        array[extensions.http_header('User-Agent', 'spots-seed/1.0 (student project)')],
        null, null)::extensions.http_request);
      if res.status = 200 then
        u := res.content::jsonb #>> '{originalimage,source}';
        if u like 'https://upload.wikimedia.org/%' and u ~* '\.(jpe?g|png)$' then
          return u;
        end if;
      end if;
    exception when others then null;
    end;
  end loop;
  return null;
end $f$;

do $$
declare pid uuid; img text; posts uuid[] := array[]::uuid[];
begin
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  values ('00000000-0000-0000-0000-000000000000', 'a5b0c000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'nadiamakan@seed.spots.local', '', '{"provider":"email","providers":["email"]}', jsonb_build_object('display_name', 'Nadia Putri'), now() - interval '37 days', now())
  on conflict (id) do nothing;
  update public.profiles set username = 'nadiamakan', display_name = 'Nadia Putri', bio = 'kalau lapar, tanya aku 🍜 sby', streak = 41, best_streak = 41, streak_day = current_date, created_at = now() - interval '37 days' where id = 'a5b0c000-0000-4000-8000-000000000001';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  values ('00000000-0000-0000-0000-000000000000', 'a5b0c000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'dimas.jalan@seed.spots.local', '', '{"provider":"email","providers":["email"]}', jsonb_build_object('display_name', 'Dimas Arya'), now() - interval '44 days', now())
  on conflict (id) do nothing;
  update public.profiles set username = 'dimas.jalan', display_name = 'Dimas Arya', bio = 'suka bangunan tua & jalan kaki', streak = 17, best_streak = 17, streak_day = current_date, created_at = now() - interval '44 days' where id = 'a5b0c000-0000-4000-8000-000000000002';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  values ('00000000-0000-0000-0000-000000000000', 'a5b0c000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', 'rara.sby@seed.spots.local', '', '{"provider":"email","providers":["email"]}', jsonb_build_object('display_name', 'Rara Ayu'), now() - interval '51 days', now())
  on conflict (id) do nothing;
  update public.profiles set username = 'rara.sby', display_name = 'Rara Ayu', bio = 'anak tunjungan. belanja dulu, mikir belakangan', streak = 9, best_streak = 9, streak_day = current_date, created_at = now() - interval '51 days' where id = 'a5b0c000-0000-4000-8000-000000000003';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  values ('00000000-0000-0000-0000-000000000000', 'a5b0c000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', 'bayulari@seed.spots.local', '', '{"provider":"email","providers":["email"]}', jsonb_build_object('display_name', 'Bayu Pratama'), now() - interval '58 days', now())
  on conflict (id) do nothing;
  update public.profiles set username = 'bayulari', display_name = 'Bayu Pratama', bio = '5K tiap sore, persebaya tiap minggu', streak = 63, best_streak = 63, streak_day = current_date, created_at = now() - interval '58 days' where id = 'a5b0c000-0000-4000-8000-000000000004';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  values ('00000000-0000-0000-0000-000000000000', 'a5b0c000-0000-4000-8000-000000000005', 'authenticated', 'authenticated', 'sekarwulan@seed.spots.local', '', '{"provider":"email","providers":["email"]}', jsonb_build_object('display_name', 'Sekar Wulan'), now() - interval '65 days', now())
  on conflict (id) do nothing;
  update public.profiles set username = 'sekarwulan', display_name = 'Sekar Wulan', bio = 'ngajak ponakan keliling kota', streak = 5, best_streak = 5, streak_day = current_date, created_at = now() - interval '65 days' where id = 'a5b0c000-0000-4000-8000-000000000005';
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  values ('00000000-0000-0000-0000-000000000000', 'a5b0c000-0000-4000-8000-000000000006', 'authenticated', 'authenticated', 'fajarngopi@seed.spots.local', '', '{"provider":"email","providers":["email"]}', jsonb_build_object('display_name', 'Fajar'), now() - interval '72 days', now())
  on conflict (id) do nothing;
  update public.profiles set username = 'fajarngopi', display_name = 'Fajar', bio = 'nongkrong itu ibadah', streak = 120, best_streak = 120, streak_day = current_date, created_at = now() - interval '72 days' where id = 'a5b0c000-0000-4000-8000-000000000006';
  delete from public.posts where owner_id in ('a5b0c000-0000-4000-8000-000000000001', 'a5b0c000-0000-4000-8000-000000000002', 'a5b0c000-0000-4000-8000-000000000003', 'a5b0c000-0000-4000-8000-000000000004', 'a5b0c000-0000-4000-8000-000000000005', 'a5b0c000-0000-4000-8000-000000000006');
  img := pg_temp.wiki_img(array['id:Rawon', 'en:Rawon']);
  insert into public.posts (owner_id, title, city, category, story, lat, lng, created_at)
  values ('a5b0c000-0000-4000-8000-000000000001', 'Rawon Setan Mbak Endang', 'Surabaya', 'kuliner', 'Rawonnya hitam pekat, dagingnya empuk, sambalnya jangan diremehkan. Paling enak datang malam, sekalian lihat antreannya yang nggak ada habisnya. Tambah telur asin sama kerupuk udang, wajib.

Foto: Wikipedia / Wikimedia Commons', -7.2614, 112.7386, now() - interval '2 days 2 hours')
  returning id into pid;
  posts := posts || pid;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000002', pid, 'like') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000002', pid, 4) on conflict do nothing;
  insert into public.comments (post_id, user_id, body, created_at) values (pid, 'a5b0c000-0000-4000-8000-000000000002', 'baru tau ada ini', now() - interval '42 hours');
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000003', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000003', pid, 'save') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000003', pid, 5) on conflict do nothing;
  insert into public.comments (post_id, user_id, body, created_at) values (pid, 'a5b0c000-0000-4000-8000-000000000003', 'fotonya bikin pengen', now() - interval '43 hours');
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000005', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000006', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000006', pid, 'save') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000006', pid, 5) on conflict do nothing;
  if img is not null then insert into public.post_media (post_id, position, storage_path, media_type) values (pid, 0, img, 'image'); end if;
  img := pg_temp.wiki_img(array['id:Sate klopo', 'id:Sate', 'en:Satay']);
  insert into public.posts (owner_id, title, city, category, story, lat, lng, created_at)
  values ('a5b0c000-0000-4000-8000-000000000001', 'Sate Klopo Ondomohen', 'Surabaya', 'kuliner', 'Satenya dibalur kelapa parut sebelum dibakar, jadi gurih dan agak garing di luar. Asapnya kecium dari ujung jalan. Pesan campur sapi + ayam biar nggak bingung.

Foto: Wikipedia / Wikimedia Commons', -7.2585, 112.7471, now() - interval '9 days 5 hours')
  returning id into pid;
  posts := posts || pid;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000003', pid, 'like') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000003', pid, 4) on conflict do nothing;
  insert into public.comments (post_id, user_id, body, created_at) values (pid, 'a5b0c000-0000-4000-8000-000000000003', 'langganan dari SMA 😭', now() - interval '183 hours');
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000004', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000004', pid, 'save') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000004', pid, 5) on conflict do nothing;
  insert into public.comments (post_id, user_id, body, created_at) values (pid, 'a5b0c000-0000-4000-8000-000000000004', 'parkirnya gampang ga?', now() - interval '184 hours');
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000006', pid, 'like') on conflict do nothing;
  if img is not null then insert into public.post_media (post_id, position, storage_path, media_type) values (pid, 0, img, 'image'); end if;
  img := pg_temp.wiki_img(array['id:Taman Bungkul', 'en:Bungkul Park']);
  insert into public.posts (owner_id, title, city, category, story, lat, lng, created_at)
  values ('a5b0c000-0000-4000-8000-000000000006', 'Taman Bungkul', 'Surabaya', 'kafe', 'Tempat nongkrong sejuta umat. Sore-sore duduk di bawah pohon, jajan di sentra PKL belakang, terus jalan muter taman. Minggu pagi rame banget sama yang olahraga.

Foto: Wikipedia / Wikimedia Commons', -7.2913, 112.7398, now() - interval '1 days 8 hours')
  returning id into pid;
  posts := posts || pid;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000001', pid, 'like') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000001', pid, 5) on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000002', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000002', pid, 'save') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000002', pid, 5) on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000004', pid, 'like') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000004', pid, 4) on conflict do nothing;
  insert into public.comments (post_id, user_id, body, created_at) values (pid, 'a5b0c000-0000-4000-8000-000000000004', 'minggu lalu ke sini, rame bgt', now() - interval '24 hours');
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000005', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000005', pid, 'save') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000005', pid, 5) on conflict do nothing;
  insert into public.comments (post_id, user_id, body, created_at) values (pid, 'a5b0c000-0000-4000-8000-000000000005', 'wajib nyoba', now() - interval '25 hours');
  if img is not null then insert into public.post_media (post_id, position, storage_path, media_type) values (pid, 0, img, 'image'); end if;
  img := pg_temp.wiki_img(array['id:Tugu Pahlawan', 'en:Heroes Monument']);
  insert into public.posts (owner_id, title, city, category, story, lat, lng, created_at)
  values ('a5b0c000-0000-4000-8000-000000000002', 'Tugu Pahlawan', 'Surabaya', 'destinasi', 'Ikonnya Surabaya. Di bawah tanahnya ada Museum 10 Nopember, isinya lumayan bikin merinding. Datang pas sore biar foto tugunya kena cahaya hangat.

Foto: Wikipedia / Wikimedia Commons', -7.2458, 112.7378, now() - interval '14 days 11 hours')
  returning id into pid;
  posts := posts || pid;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000001', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000003', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000003', pid, 'save') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000003', pid, 5) on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000005', pid, 'like') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000005', pid, 4) on conflict do nothing;
  insert into public.comments (post_id, user_id, body, created_at) values (pid, 'a5b0c000-0000-4000-8000-000000000005', 'sambalnya pedes beneran wkwk', now() - interval '285 hours');
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000006', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000006', pid, 'save') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000006', pid, 5) on conflict do nothing;
  insert into public.comments (post_id, user_id, body, created_at) values (pid, 'a5b0c000-0000-4000-8000-000000000006', 'besok ke sini ah', now() - interval '286 hours');
  if img is not null then insert into public.post_media (post_id, position, storage_path, media_type) values (pid, 0, img, 'image'); end if;
  img := pg_temp.wiki_img(array['en:House of Sampoerna', 'id:House of Sampoerna']);
  insert into public.posts (owner_id, title, city, category, story, lat, lng, created_at)
  values ('a5b0c000-0000-4000-8000-000000000002', 'House of Sampoerna', 'Surabaya', 'destinasi', 'Bangunan kolonialnya cakep dari luar sampai dalam. Masuk museumnya gratis, dan dari lantai atas bisa lihat proses linting kretek. Kawasan kota lamanya enak buat jalan kaki.

Foto: Wikipedia / Wikimedia Commons', -7.231, 112.7342, now() - interval '6 days 14 hours')
  returning id into pid;
  posts := posts || pid;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000003', pid, 'like') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000003', pid, 5) on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000004', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000004', pid, 'save') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000004', pid, 5) on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000006', pid, 'like') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000006', pid, 4) on conflict do nothing;
  insert into public.comments (post_id, user_id, body, created_at) values (pid, 'a5b0c000-0000-4000-8000-000000000006', 'baru tau ada ini', now() - interval '126 hours');
  if img is not null then insert into public.post_media (post_id, position, storage_path, media_type) values (pid, 0, img, 'image'); end if;
  img := pg_temp.wiki_img(array['id:Stadion Gelora Bung Tomo', 'en:Gelora Bung Tomo Stadium']);
  insert into public.posts (owner_id, title, city, category, story, lat, lng, created_at)
  values ('a5b0c000-0000-4000-8000-000000000004', 'Gelora Bung Tomo', 'Surabaya', 'olahraga', 'Kandangnya Persebaya. Kalau lagi nggak ada pertandingan, area luarnya sering dipakai lari sore sama sepedaan. Pas ada laga, suasananya beda level.

Foto: Wikipedia / Wikimedia Commons', -7.2245, 112.623, now() - interval '3 days 17 hours')
  returning id into pid;
  posts := posts || pid;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000001', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000001', pid, 'save') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000001', pid, 5) on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000003', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000005', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000005', pid, 'save') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000005', pid, 5) on conflict do nothing;
  if img is not null then insert into public.post_media (post_id, position, storage_path, media_type) values (pid, 0, img, 'image'); end if;
  img := pg_temp.wiki_img(array['id:Monumen Kapal Selam', 'en:Submarine Monument']);
  insert into public.posts (owner_id, title, city, category, story, lat, lng, created_at)
  values ('a5b0c000-0000-4000-8000-000000000005', 'Monumen Kapal Selam', 'Surabaya', 'aktivitas', 'Kapal selam beneran yang bisa dimasukin, dari ruang torpedo sampai ruang kemudi. Sempit, panas, tapi seru. Cocok buat bawa adik atau ponakan.

Foto: Wikipedia / Wikimedia Commons', -7.2653, 112.7502, now() - interval '11 days 20 hours')
  returning id into pid;
  posts := posts || pid;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000001', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000002', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000002', pid, 'save') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000002', pid, 5) on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000004', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000006', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000006', pid, 'save') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000006', pid, 5) on conflict do nothing;
  if img is not null then insert into public.post_media (post_id, position, storage_path, media_type) values (pid, 0, img, 'image'); end if;
  img := pg_temp.wiki_img(array['id:Kebun Binatang Surabaya', 'en:Surabaya Zoo']);
  insert into public.posts (owner_id, title, city, category, story, lat, lng, created_at)
  values ('a5b0c000-0000-4000-8000-000000000005', 'Kebun Binatang Surabaya', 'Surabaya', 'aktivitas', 'Klasik, tapi tetap asik buat jalan pagi. Sapa komodonya, terus foto di patung Suro dan Boyo di depan. Datang lebih awal biar belum terlalu terik.

Foto: Wikipedia / Wikimedia Commons', -7.2959, 112.7365, now() - interval '4 days 23 hours')
  returning id into pid;
  posts := posts || pid;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000002', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000003', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000003', pid, 'save') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000003', pid, 5) on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000006', pid, 'like') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000006', pid, 5) on conflict do nothing;
  if img is not null then insert into public.post_media (post_id, position, storage_path, media_type) values (pid, 0, img, 'image'); end if;
  img := pg_temp.wiki_img(array['id:Pasar Atom', 'id:Tunjungan Plaza', 'en:Tunjungan Plaza']);
  insert into public.posts (owner_id, title, city, category, story, lat, lng, created_at)
  values ('a5b0c000-0000-4000-8000-000000000003', 'Pasar Atom', 'Surabaya', 'belanja', 'Surganya kain, jajanan, sama barang serba ada. Lantai bawah buat camilan, lantai atas buat bahan baju. Siap-siap nawar dan siap-siap nyasar.

Foto: Wikipedia / Wikimedia Commons', -7.24, 112.7428, now() - interval '8 days 26 hours')
  returning id into pid;
  posts := posts || pid;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000001', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000001', pid, 'save') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000001', pid, 5) on conflict do nothing;
  insert into public.comments (post_id, user_id, body, created_at) values (pid, 'a5b0c000-0000-4000-8000-000000000001', 'besok ke sini ah', now() - interval '161 hours');
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000004', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000004', pid, 'save') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000004', pid, 5) on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000006', pid, 'like') on conflict do nothing;
  if img is not null then insert into public.post_media (post_id, position, storage_path, media_type) values (pid, 0, img, 'image'); end if;
  img := pg_temp.wiki_img(array['id:Hotel Majapahit', 'en:Hotel Majapahit']);
  insert into public.posts (owner_id, title, city, category, story, lat, lng, created_at)
  values ('a5b0c000-0000-4000-8000-000000000003', 'Hotel Majapahit', 'Surabaya', 'menginap', 'Hotel bersejarah di Jalan Tunjungan, tempat insiden perobekan bendera tahun 1945. Taman dalamnya tenang banget, kayak lupa lagi di tengah kota. Malamnya tinggal jalan ke Tunjungan.

Foto: Wikipedia / Wikimedia Commons', -7.2604, 112.7392, now() - interval '18 days 29 hours')
  returning id into pid;
  posts := posts || pid;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000001', pid, 'like') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000001', pid, 4) on conflict do nothing;
  insert into public.comments (post_id, user_id, body, created_at) values (pid, 'a5b0c000-0000-4000-8000-000000000001', 'baru tau ada ini', now() - interval '361 hours');
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000002', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000002', pid, 'save') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000002', pid, 5) on conflict do nothing;
  insert into public.comments (post_id, user_id, body, created_at) values (pid, 'a5b0c000-0000-4000-8000-000000000002', 'fotonya bikin pengen', now() - interval '362 hours');
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000004', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000005', pid, 'like') on conflict do nothing;
  insert into public.reactions (user_id, post_id, kind) values ('a5b0c000-0000-4000-8000-000000000005', pid, 'save') on conflict do nothing;
  insert into public.ratings (user_id, post_id, score) values ('a5b0c000-0000-4000-8000-000000000005', pid, 5) on conflict do nothing;
  if img is not null then insert into public.post_media (post_id, position, storage_path, media_type) values (pid, 0, img, 'image'); end if;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000001', 'a5b0c000-0000-4000-8000-000000000003') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000001', 'a5b0c000-0000-4000-8000-000000000004') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000001', 'a5b0c000-0000-4000-8000-000000000006') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000002', 'a5b0c000-0000-4000-8000-000000000003') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000002', 'a5b0c000-0000-4000-8000-000000000005') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000002', 'a5b0c000-0000-4000-8000-000000000006') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000003', 'a5b0c000-0000-4000-8000-000000000001') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000003', 'a5b0c000-0000-4000-8000-000000000002') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000003', 'a5b0c000-0000-4000-8000-000000000004') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000003', 'a5b0c000-0000-4000-8000-000000000005') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000004', 'a5b0c000-0000-4000-8000-000000000001') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000004', 'a5b0c000-0000-4000-8000-000000000003') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000004', 'a5b0c000-0000-4000-8000-000000000006') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000005', 'a5b0c000-0000-4000-8000-000000000002') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000005', 'a5b0c000-0000-4000-8000-000000000003') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000005', 'a5b0c000-0000-4000-8000-000000000006') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000006', 'a5b0c000-0000-4000-8000-000000000001') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000006', 'a5b0c000-0000-4000-8000-000000000002') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000006', 'a5b0c000-0000-4000-8000-000000000004') on conflict do nothing;
  insert into public.follows (follower_id, following_id) values ('a5b0c000-0000-4000-8000-000000000006', 'a5b0c000-0000-4000-8000-000000000005') on conflict do nothing;
end
$$;
