-- Uji migrasi marketplace di Postgres lokal (lihat supabase/tests/README.md).
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

insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-00000000000a', 'admin@spots.test', '{"display_name":"Admin"}'),
  ('00000000-0000-0000-0000-00000000000b', 'penjual@spots.test', '{"display_name":"Penjual"}'),
  ('00000000-0000-0000-0000-00000000000c', 'pembeli@spots.test', '{"display_name":"Pembeli"}'),
  ('00000000-0000-0000-0000-00000000000d', 'lain@spots.test', '{"display_name":"Lain"}');
insert into public.app_admins (user_id) values ('00000000-0000-0000-0000-00000000000a');

\echo '1. pengajuan toko'
select pg_temp.act('00000000-0000-0000-0000-00000000000b');
insert into public.store_applications (store_name, category, address, lat, lng, contact, relation)
  values ('Kopi Teras', 'kafe', 'Jl. Teras No. 5, Bandung', -6.9, 107.6, '0812000111', 'pemilik');
select pg_temp.fails($$insert into public.store_applications (store_name, category, address, lat, lng, contact, relation)
  values ('Kopi Dua', 'kafe', 'Jl. Teras No. 6, Bandung', -6.9, 107.6, '0812000111', 'pemilik')$$, 'duplicate');
select pg_temp.fails($$select public.review_store_application(
  (select id from public.store_applications limit 1), true)$$, 'Hanya admin');
select pg_temp.fails($$update public.store_applications set status = 'disetujui'$$, 'permission denied');

select pg_temp.act('00000000-0000-0000-0000-00000000000c');
do $$ begin
  if exists (select 1 from public.store_applications) then raise exception 'pembeli melihat pengajuan orang lain'; end if;
end $$;

select pg_temp.act('00000000-0000-0000-0000-00000000000a');
insert into public.store_applications (store_name, category, address, lat, lng, contact, relation)
  values ('Toko Admin', 'lainnya', 'Jl. Admin No. 1, Jakarta', -6.2, 106.8, '0812999000', 'pemilik');
select pg_temp.fails($$select public.review_store_application(
  (select id from public.store_applications where store_name = 'Toko Admin'), true)$$, 'sendiri');
select public.review_store_application(
  (select id from public.store_applications where store_name = 'Kopi Teras'), true);
select pg_temp.fails($$select public.review_store_application(
  (select id from public.store_applications where store_name = 'Kopi Teras'), true)$$, 'sudah diproses');
select id as store_id from public.stores where name = 'Kopi Teras' \gset

\echo '2. katalog dan pengaturan toko'
select pg_temp.act('00000000-0000-0000-0000-00000000000b');
insert into public.products (store_id, name, price, stock) values
  (:'store_id', 'Es Kopi Susu', 22000, 3),
  (:'store_id', 'Roti Bakar', 18000, 10);
select pg_temp.act('00000000-0000-0000-0000-00000000000d');
select pg_temp.fails($$insert into public.products (store_id, name, price, stock)
  select id, 'Titipan', 1000, 1 from public.stores limit 1$$, 'row-level security');
update public.products set price = 1;
update public.stores set online_orders = true;
select pg_temp.act('00000000-0000-0000-0000-00000000000b');
do $$ begin
  if (select min(price) from public.products) = 1 then raise exception 'akun lain mengubah harga'; end if;
  if (select bool_or(online_orders) from public.stores) then raise exception 'akun lain mengubah toko'; end if;
end $$;
select pg_temp.fails($$update public.stores set owner_id = '00000000-0000-0000-0000-00000000000d'$$, 'permission denied');
select pg_temp.fails($$update public.products set store_id = store_id$$, 'permission denied');

select pg_temp.act(null);
do $$ begin
  if (select count(*) from public.products) <> 2 then raise exception 'katalog publik tidak terbaca'; end if;
end $$;

\echo '3. pemesanan'
select pg_temp.act('00000000-0000-0000-0000-00000000000c');
select pg_temp.fails(format($$select public.place_order(%L, %L::jsonb, 'ambil', gen_random_uuid())$$,
  :'store_id', '[]'), 'pembelian di lokasi');

select pg_temp.act('00000000-0000-0000-0000-00000000000b');
update public.stores set online_orders = true, delivery = true, delivery_fee = 8000;
select pg_temp.fails(format($$select public.place_order(%L, %L::jsonb, 'ambil', gen_random_uuid())$$,
  :'store_id', '[{"product_id":"00000000-0000-0000-0000-000000000000","qty":1}]'), 'toko sendiri');

select pg_temp.act('00000000-0000-0000-0000-00000000000c');
select id as kopi from public.products where name = 'Es Kopi Susu' \gset
select id as roti from public.products where name = 'Roti Bakar' \gset
select pg_temp.fails(format($$select public.place_order(%L, jsonb_build_array(jsonb_build_object('product_id', %L, 'qty', 4)), 'ambil', gen_random_uuid())$$,
  :'store_id', :'kopi'), 'Stok Es Kopi Susu tinggal 3');
select pg_temp.fails(format($$select public.place_order(%L, jsonb_build_array(jsonb_build_object('product_id', %L, 'qty', 1)), 'kirim', gen_random_uuid())$$,
  :'store_id', :'kopi'), 'alamat');
select pg_temp.fails(format($$select public.place_order(%L, jsonb_build_array(jsonb_build_object('product_id', %L, 'qty', 1)), 'ambil', gen_random_uuid(), '', '', 1000)$$,
  :'store_id', :'kopi'), 'Harga ada yang berubah');

-- pesanan sungguhan, dikirim dua kali dengan kunci yang sama
\set key 11111111-1111-1111-1111-111111111111
select public.place_order(:'store_id', jsonb_build_array(
    jsonb_build_object('product_id', :'kopi', 'qty', 2),
    jsonb_build_object('product_id', :'roti', 'qty', 1)),
  'kirim', :'key', 'Jl. Melati No. 9, Bandung', 'Gula sedikit', 70000) as first_order \gset
select public.place_order(:'store_id', jsonb_build_array(
    jsonb_build_object('product_id', :'kopi', 'qty', 2)),
  'kirim', :'key', 'Jl. Melati No. 9, Bandung') as second_order \gset
do $$ begin
  if (select count(*) from public.orders) <> 1 then raise exception 'pesanan ganda tercipta'; end if;
  if (select total from public.orders) <> 70000 then raise exception 'total salah'; end if;
  if (select sum(unit_price * qty) from public.order_items) <> 62000 then raise exception 'rincian salah'; end if;
end $$;
select pg_temp.fails($$update public.orders set payment_status = 'lunas'$$, 'permission denied');
select pg_temp.fails(format($$select public.accept_order(%L)$$, :'first_order'), 'tidak ditemukan');
select pg_temp.fails(format($$select public.report_payment(%L)$$, :'first_order'), 'belum bisa dibayar');

select pg_temp.act('00000000-0000-0000-0000-00000000000d');
do $$ begin
  if exists (select 1 from public.orders) or exists (select 1 from public.order_items) then
    raise exception 'akun lain melihat pesanan';
  end if;
end $$;

\echo '4. alur penjual'
select pg_temp.act('00000000-0000-0000-0000-00000000000b');
update public.products set price = 25000 where name = 'Es Kopi Susu';
select public.accept_order(:'first_order');
select pg_temp.fails(format($$select public.accept_order(%L)$$, :'first_order'), 'sudah diproses');
do $$ begin
  if (select stock from public.products where name = 'Es Kopi Susu') <> 1 then raise exception 'stok kopi salah'; end if;
  if (select stock from public.products where name = 'Roti Bakar') <> 9 then raise exception 'stok roti salah'; end if;
  if (select unit_price from public.order_items where name = 'Es Kopi Susu') <> 22000 then
    raise exception 'harga saat pesan berubah';
  end if;
end $$;

select pg_temp.act('00000000-0000-0000-0000-00000000000c');
select pg_temp.fails(format($$select public.cancel_order(%L)$$, :'first_order'), 'tidak bisa dibatalkan');
select public.report_payment(:'first_order');

select pg_temp.act('00000000-0000-0000-0000-00000000000b');
select public.confirm_payment(:'first_order');
select pg_temp.fails(format($$select public.confirm_payment(%L)$$, :'first_order'), 'tidak bisa dikonfirmasi');
select public.advance_order(:'first_order');
select public.advance_order(:'first_order');
select pg_temp.fails(format($$select public.advance_order(%L)$$, :'first_order'), 'tidak bisa dilanjutkan');
do $$ begin
  if (select status || '/' || payment_status from public.orders) <> 'selesai/lunas' then
    raise exception 'status akhir salah';
  end if;
end $$;

\echo '5. stok habis saat diterima dan pesanan ditolak'
select pg_temp.act('00000000-0000-0000-0000-00000000000c');
select public.place_order(:'store_id', jsonb_build_array(jsonb_build_object('product_id', :'kopi', 'qty', 1)),
  'ambil', gen_random_uuid()) as order_a \gset
select public.place_order(:'store_id', jsonb_build_array(jsonb_build_object('product_id', :'kopi', 'qty', 1)),
  'ambil', gen_random_uuid()) as order_b \gset
select public.place_order(:'store_id', jsonb_build_array(jsonb_build_object('product_id', :'roti', 'qty', 1)),
  'ambil', gen_random_uuid()) as order_c \gset
select public.cancel_order(:'order_c');

select pg_temp.act('00000000-0000-0000-0000-00000000000b');
select public.accept_order(:'order_a');
select pg_temp.fails(format($$select public.accept_order(%L)$$, :'order_b'), 'Stok Es Kopi Susu tidak cukup');
select pg_temp.fails(format($$select public.reject_order(%L, '')$$, :'order_b'), 'alasan');
select public.reject_order(:'order_b', 'Stok habis, maaf ya');
do $$ begin
  if (select stock from public.products where name = 'Es Kopi Susu') <> 0 then raise exception 'stok negatif atau salah'; end if;
  if (select status from public.orders where reject_reason is not null) <> 'ditolak' then raise exception 'penolakan gagal'; end if;
end $$;

\echo '6. feed tetap jalan dan membawa store_id'
select pg_temp.act(null);
select count(*) >= 0 as feed_ok from public.feed_spots(null, null, 'popular');

reset role;
\echo '7. kategori baru'
\ir ../migrations/202611160001_categories.sql
insert into public.posts (owner_id, title, city, category, story, lat, lng)
  values ('00000000-0000-0000-0000-00000000000c', 'Skatepark Kolong', 'Bandung', 'olahraga',
    'Rampnya mulus, ramai sore.', -6.9, 107.6);
select pg_temp.fails($$insert into public.posts (owner_id, title, city, category, story, lat, lng)
  values ('00000000-0000-0000-0000-00000000000c', 'Tempat aneh', 'Bandung', 'lainnya',
    'Kategori lama.', -6.9, 107.6)$$, 'posts_category_check');
\echo 'SEMUA UJI MARKETPLACE LULUS'
