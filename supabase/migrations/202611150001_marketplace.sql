-- Marketplace Spots: pengajuan toko, katalog, dan pesanan.
-- Jalankan setelah 202610050001_spots.sql. Data dan feed lama tetap utuh.

-- Admin aplikasi. Tambahkan baris lewat Table Editor atau SQL Editor:
--   insert into public.app_admins (user_id) values ('<uuid akun admin>');
create table if not exists public.app_admins (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.app_admins where user_id = (select auth.uid()));
$$;

create table if not exists public.store_applications (
  id uuid primary key default gen_random_uuid(),
  applicant_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  store_name text not null check (char_length(store_name) between 2 and 80),
  category text not null check (category in ('kuliner', 'kafe', 'destinasi', 'lainnya')),
  address text not null check (char_length(address) between 5 and 200),
  lat double precision not null check (lat between -90 and 90),
  lng double precision not null check (lng between -180 and 180),
  contact text not null check (char_length(contact) between 5 and 80),
  relation text not null check (relation in ('pemilik', 'pengelola', 'keluarga', 'karyawan')),
  note text not null default '' check (char_length(note) <= 500),
  post_id uuid references public.posts(id) on delete set null,
  status text not null default 'menunggu' check (status in ('menunggu', 'disetujui', 'ditolak')),
  reject_reason text,
  store_id uuid,
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

-- Satu akun hanya boleh punya satu pengajuan yang masih menunggu.
create unique index if not exists store_applications_one_pending
  on public.store_applications (applicant_id) where status = 'menunggu';

create table if not exists public.stores (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  application_id uuid unique references public.store_applications(id) on delete set null,
  name text not null check (char_length(name) between 2 and 80),
  category text not null check (category in ('kuliner', 'kafe', 'destinasi', 'lainnya')),
  address text not null check (char_length(address) between 5 and 200),
  lat double precision not null check (lat between -90 and 90),
  lng double precision not null check (lng between -180 and 180),
  contact text not null check (char_length(contact) between 5 and 80),
  description text not null default '' check (char_length(description) <= 500),
  online_orders boolean not null default false,
  pickup boolean not null default true,
  delivery boolean not null default false,
  delivery_fee integer not null default 0 check (delivery_fee between 0 and 1000000),
  payment_info text not null default '' check (char_length(payment_info) <= 500),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  check (not online_orders or pickup or delivery)
);

alter table public.store_applications
  drop constraint if exists store_applications_store_id_fkey;
alter table public.store_applications
  add constraint store_applications_store_id_fkey
  foreign key (store_id) references public.stores(id) on delete set null;

-- Rekomendasi boleh menunjuk ke toko. Unggahan lama tetap tanpa toko.
alter table public.posts
  add column if not exists store_id uuid references public.stores(id) on delete set null;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 80),
  description text not null default '' check (char_length(description) <= 300),
  price integer not null check (price between 100 and 100000000),
  stock integer not null default 0 check (stock >= 0),
  image_path text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references public.profiles(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  request_key uuid not null,
  status text not null default 'menunggu' check (status in
    ('menunggu', 'diterima', 'ditolak', 'diproses', 'siap', 'selesai', 'dibatalkan')),
  payment_status text not null default 'belum' check (payment_status in
    ('belum', 'menunggu_konfirmasi', 'lunas')),
  fulfillment text not null check (fulfillment in ('ambil', 'kirim')),
  address text not null default '' check (char_length(address) <= 300),
  note text not null default '' check (char_length(note) <= 300),
  subtotal integer not null check (subtotal >= 0),
  shipping_fee integer not null default 0 check (shipping_fee >= 0),
  total integer not null check (total >= 0),
  reject_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (buyer_id, request_key)
);

create table if not exists public.order_items (
  order_id uuid not null references public.orders(id) on delete cascade,
  line smallint not null,
  product_id uuid references public.products(id) on delete set null,
  name text not null,
  unit_price integer not null check (unit_price >= 0),
  qty integer not null check (qty between 1 and 99),
  primary key (order_id, line)
);

create index if not exists stores_owner_idx on public.stores (owner_id);
create index if not exists stores_geo_idx on public.stores (lat, lng);
create index if not exists products_store_idx on public.products (store_id, active);
create index if not exists orders_buyer_idx on public.orders (buyer_id, created_at desc);
create index if not exists orders_store_idx on public.orders (store_id, created_at desc);
create index if not exists posts_store_idx on public.posts (store_id);

-- Hak akses dasar. Perubahan status selalu lewat fungsi di bawah.
revoke all on public.app_admins, public.store_applications, public.stores,
  public.products, public.orders, public.order_items from anon, authenticated;
grant select on public.app_admins to authenticated;
grant select on public.store_applications to authenticated;
grant insert (store_name, category, address, lat, lng, contact, relation, note, post_id)
  on public.store_applications to authenticated;
grant select on public.stores, public.products to anon, authenticated;
grant update (description, contact, online_orders, pickup, delivery, delivery_fee, payment_info)
  on public.stores to authenticated;
grant insert (store_id, name, description, price, stock, image_path, active)
  on public.products to authenticated;
grant update (name, description, price, stock, image_path, active)
  on public.products to authenticated;
grant delete on public.products to authenticated;
grant select on public.orders, public.order_items to authenticated;

alter table public.app_admins enable row level security;
alter table public.store_applications enable row level security;
alter table public.stores enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

create policy admins_read_self on public.app_admins for select to authenticated
  using (user_id = (select auth.uid()));

create policy applications_read on public.store_applications for select to authenticated
  using (applicant_id = (select auth.uid()) or (select public.is_admin()));
create policy applications_insert_self on public.store_applications for insert to authenticated
  with check (applicant_id = (select auth.uid()) and status = 'menunggu');

create policy stores_read on public.stores for select
  using (active or owner_id = (select auth.uid()));
create policy stores_update_owner on public.stores for update to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));

create policy products_read on public.products for select using (
  (active and exists (select 1 from public.stores s where s.id = store_id and s.active))
  or exists (select 1 from public.stores s where s.id = store_id and s.owner_id = (select auth.uid()))
);
create policy products_insert_owner on public.products for insert to authenticated
  with check (exists (select 1 from public.stores s where s.id = store_id and s.owner_id = (select auth.uid())));
create policy products_update_owner on public.products for update to authenticated
  using (exists (select 1 from public.stores s where s.id = store_id and s.owner_id = (select auth.uid())))
  with check (exists (select 1 from public.stores s where s.id = store_id and s.owner_id = (select auth.uid())));
create policy products_delete_owner on public.products for delete to authenticated
  using (exists (select 1 from public.stores s where s.id = store_id and s.owner_id = (select auth.uid())));

create policy orders_read on public.orders for select to authenticated using (
  buyer_id = (select auth.uid())
  or exists (select 1 from public.stores s where s.id = store_id and s.owner_id = (select auth.uid()))
);
create policy order_items_read on public.order_items for select to authenticated using (
  exists (select 1 from public.orders o where o.id = order_id and (
    o.buyer_id = (select auth.uid())
    or exists (select 1 from public.stores s where s.id = o.store_id and s.owner_id = (select auth.uid()))
  ))
);

-- Persetujuan toko oleh admin. Pemohon tidak bisa menyetujui pengajuannya sendiri.
create or replace function public.review_store_application(
  p_application uuid, p_approve boolean, p_reason text default null
) returns uuid language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  app public.store_applications;
  new_store uuid;
begin
  if not public.is_admin() then raise exception 'Hanya admin yang bisa meninjau pengajuan.'; end if;
  select * into app from public.store_applications where id = p_application for update;
  if not found then raise exception 'Pengajuan tidak ditemukan.'; end if;
  if app.status <> 'menunggu' then raise exception 'Pengajuan ini sudah diproses.'; end if;
  if app.applicant_id = me then raise exception 'Tidak bisa meninjau pengajuan sendiri.'; end if;

  if p_approve then
    insert into public.stores (owner_id, application_id, name, category, address, lat, lng, contact)
    values (app.applicant_id, app.id, app.store_name, app.category, app.address, app.lat, app.lng, app.contact)
    returning id into new_store;
    update public.store_applications
      set status = 'disetujui', store_id = new_store, reviewed_by = me, reviewed_at = now()
      where id = app.id;
    if app.post_id is not null then
      update public.posts set store_id = new_store where id = app.post_id and store_id is null;
    end if;
    return new_store;
  end if;

  if char_length(coalesce(trim(p_reason), '')) < 3 then
    raise exception 'Tulis alasan penolakan.';
  end if;
  update public.store_applications
    set status = 'ditolak', reject_reason = trim(p_reason), reviewed_by = me, reviewed_at = now()
    where id = app.id;
  return null;
end;
$$;

-- Pesanan baru. Harga dan total dihitung dari database, bukan dari aplikasi.
-- p_request_key membuat permintaan yang terkirim ulang tidak membuat pesanan ganda.
create or replace function public.place_order(
  p_store uuid,
  p_items jsonb,
  p_fulfillment text,
  p_request_key uuid,
  p_address text default '',
  p_note text default '',
  p_expected_total integer default null
) returns uuid language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  shop public.stores;
  existing uuid;
  order_id uuid;
  line record;
  n smallint := 0;
  sub integer := 0;
  fee integer := 0;
begin
  if me is null then raise exception 'Masuk dulu untuk memesan.'; end if;
  select id into existing from public.orders where buyer_id = me and request_key = p_request_key;
  if existing is not null then return existing; end if;

  select * into shop from public.stores where id = p_store and active;
  if not found then raise exception 'Toko tidak ditemukan.'; end if;
  if not shop.online_orders then raise exception 'Toko ini hanya melayani pembelian di lokasi.'; end if;
  if shop.owner_id = me then raise exception 'Tidak bisa memesan di toko sendiri.'; end if;
  if p_fulfillment = 'ambil' and not shop.pickup then raise exception 'Toko ini tidak melayani ambil di lokasi.'; end if;
  if p_fulfillment = 'kirim' and not shop.delivery then raise exception 'Toko ini tidak melayani pengiriman.'; end if;
  if p_fulfillment not in ('ambil', 'kirim') then raise exception 'Pilih ambil atau kirim.'; end if;
  if p_fulfillment = 'kirim' and char_length(coalesce(trim(p_address), '')) < 10 then
    raise exception 'Tulis alamat pengiriman yang lengkap.';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) not between 1 and 30 then
    raise exception 'Keranjang kosong atau terlalu banyak barang.';
  end if;

  create temp table if not exists _cart (product_id uuid, qty integer) on commit drop;
  truncate _cart;
  insert into _cart
    select (item ->> 'product_id')::uuid, sum((item ->> 'qty')::integer)
    from jsonb_array_elements(p_items) item
    group by 1;

  for line in
    select c.qty, p.id, p.name, p.price, p.stock, p.active, p.store_id
    from _cart c left join public.products p on p.id = c.product_id
  loop
    if line.id is null or line.store_id <> shop.id or not line.active then
      raise exception 'Ada produk yang sudah tidak dijual. Cek keranjang lagi.';
    end if;
    if line.qty not between 1 and 99 then raise exception 'Jumlah barang tidak valid.'; end if;
    if line.stock < line.qty then raise exception 'Stok % tinggal %.', line.name, line.stock; end if;
    sub := sub + line.price * line.qty;
  end loop;

  fee := case when p_fulfillment = 'kirim' then shop.delivery_fee else 0 end;
  if p_expected_total is not null and p_expected_total <> sub + fee then
    raise exception 'Harga ada yang berubah. Cek keranjang lagi.';
  end if;

  insert into public.orders (buyer_id, store_id, request_key, fulfillment, address, note,
    subtotal, shipping_fee, total)
  values (me, shop.id, p_request_key, p_fulfillment,
    case when p_fulfillment = 'kirim' then left(trim(p_address), 300) else '' end,
    left(coalesce(trim(p_note), ''), 300), sub, fee, sub + fee)
  on conflict (buyer_id, request_key) do nothing
  returning id into order_id;
  if order_id is null then
    select id into order_id from public.orders where buyer_id = me and request_key = p_request_key;
    return order_id;
  end if;

  for line in
    select c.qty, p.id, p.name, p.price
    from _cart c join public.products p on p.id = c.product_id order by p.name
  loop
    n := n + 1;
    insert into public.order_items (order_id, line, product_id, name, unit_price, qty)
    values (order_id, n, line.id, line.name, line.price, line.qty);
  end loop;
  return order_id;
end;
$$;

create or replace function public._owned_order(p_order uuid)
returns public.orders language plpgsql security definer set search_path = '' as $$
declare
  result public.orders;
begin
  select o.* into result from public.orders o
    join public.stores s on s.id = o.store_id
    where o.id = p_order and s.owner_id = auth.uid()
    for update of o;
  if not found then raise exception 'Pesanan tidak ditemukan.'; end if;
  return result;
end;
$$;

-- Menerima pesanan memotong stok satu kali. Pesanan yang bukan "menunggu" ditolak,
-- jadi ketukan ganda atau permintaan ulang tidak memotong stok dua kali.
create or replace function public.accept_order(p_order uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  current_order public.orders := public._owned_order(p_order);
  item record;
begin
  if current_order.status <> 'menunggu' then raise exception 'Pesanan ini sudah diproses.'; end if;
  for item in
    select oi.product_id, sum(oi.qty)::integer as qty, min(oi.name) as name
    from public.order_items oi where oi.order_id = p_order
    group by oi.product_id order by oi.product_id
  loop
    perform 1 from public.products where id = item.product_id for update;
    update public.products set stock = stock - item.qty
      where id = item.product_id and stock >= item.qty;
    if not found then raise exception 'Stok % tidak cukup.', item.name; end if;
  end loop;
  update public.orders set status = 'diterima', updated_at = now() where id = p_order;
end;
$$;

create or replace function public.reject_order(p_order uuid, p_reason text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  current_order public.orders := public._owned_order(p_order);
begin
  if current_order.status <> 'menunggu' then raise exception 'Pesanan ini sudah diproses.'; end if;
  if char_length(coalesce(trim(p_reason), '')) < 3 then raise exception 'Tulis alasan penolakan.'; end if;
  update public.orders set status = 'ditolak', reject_reason = trim(p_reason), updated_at = now()
    where id = p_order;
end;
$$;

create or replace function public.confirm_payment(p_order uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  current_order public.orders := public._owned_order(p_order);
begin
  if current_order.status <> 'diterima' or current_order.payment_status = 'lunas' then
    raise exception 'Pembayaran pesanan ini tidak bisa dikonfirmasi.';
  end if;
  update public.orders set payment_status = 'lunas', status = 'diproses', updated_at = now()
    where id = p_order;
end;
$$;

create or replace function public.advance_order(p_order uuid)
returns text language plpgsql security definer set search_path = '' as $$
declare
  current_order public.orders := public._owned_order(p_order);
  next_status text;
begin
  next_status := case current_order.status when 'diproses' then 'siap' when 'siap' then 'selesai' end;
  if next_status is null then raise exception 'Status pesanan tidak bisa dilanjutkan.'; end if;
  update public.orders set status = next_status, updated_at = now() where id = p_order;
  return next_status;
end;
$$;

create or replace function public.report_payment(p_order uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  update public.orders set payment_status = 'menunggu_konfirmasi', updated_at = now()
    where id = p_order and buyer_id = auth.uid()
      and status = 'diterima' and payment_status = 'belum';
  if not found then raise exception 'Pesanan ini belum bisa dibayar.'; end if;
end;
$$;

create or replace function public.cancel_order(p_order uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  update public.orders set status = 'dibatalkan', updated_at = now()
    where id = p_order and buyer_id = auth.uid() and status = 'menunggu';
  if not found then raise exception 'Pesanan yang sudah diterima toko tidak bisa dibatalkan.'; end if;
end;
$$;

revoke all on function public.review_store_application(uuid, boolean, text),
  public.place_order(uuid, jsonb, text, uuid, text, text, integer),
  public._owned_order(uuid), public.accept_order(uuid), public.reject_order(uuid, text),
  public.confirm_payment(uuid), public.advance_order(uuid), public.report_payment(uuid),
  public.cancel_order(uuid)
  from public, anon;
grant execute on function public.review_store_application(uuid, boolean, text),
  public.place_order(uuid, jsonb, text, uuid, text, text, integer),
  public.accept_order(uuid), public.reject_order(uuid, text),
  public.confirm_payment(uuid), public.advance_order(uuid), public.report_payment(uuid),
  public.cancel_order(uuid)
  to authenticated;

-- Feed yang sama seperti sebelumnya, ditambah store_id agar detail bisa membuka katalog.
drop function if exists public.feed_spots(double precision, double precision, text, text, text, integer);
create function public.feed_spots(
  p_lat double precision default null,
  p_lng double precision default null,
  p_mode text default 'near',
  p_category text default null,
  p_query text default null,
  p_limit integer default 40
)
returns table (
  id uuid, owner_id uuid, author text, title text, city text, country text,
  category text, story text, lat double precision, lng double precision,
  created_at timestamptz, distance_km double precision, likes bigint,
  saves bigint, comment_count bigint, rating numeric, liked boolean,
  saved boolean, media jsonb, store_id uuid
)
language sql stable set search_path = '' as $$
  with candidates as (
    select p.*,
      case when p_lat is null or p_lng is null then null::double precision else
        6371 * acos(least(1.0, greatest(-1.0,
          sin(radians(p.lat)) * sin(radians(p_lat)) +
          cos(radians(p.lat)) * cos(radians(p_lat)) * cos(radians(p.lng - p_lng))
        ))) end as distance_km
    from public.posts p
    where (p_category is null or p.category = p_category)
      and (p_query is null or p_query = '' or p.title ilike '%' || p_query || '%'
        or p.city ilike '%' || p_query || '%')
      and (p_mode <> 'mine' or p.owner_id = (select auth.uid()))
      and (p_mode <> 'saved' or exists
        (select 1 from public.reactions saved_reaction where saved_reaction.post_id = p.id
          and saved_reaction.user_id = (select auth.uid()) and saved_reaction.kind = 'save'))
      and (p_mode <> 'near' or (p_lat is not null and p_lng is not null
        and p.lat between p_lat - 0.181 and p_lat + 0.181
        and p.lng between p_lng - 0.2 and p_lng + 0.2))
  ), ranked as (
    select c.*, pr.display_name as author,
      (select count(*) from public.reactions r where r.post_id = c.id and r.kind = 'like') as likes,
      (select count(*) from public.reactions r where r.post_id = c.id and r.kind = 'save') as saves,
      (select count(*) from public.comments cm where cm.post_id = c.id) as comment_count,
      (select round(avg(rt.score)::numeric, 1) from public.ratings rt where rt.post_id = c.id) as rating,
      exists(select 1 from public.reactions r where r.post_id = c.id and r.user_id = (select auth.uid()) and r.kind = 'like') as liked,
      exists(select 1 from public.reactions r where r.post_id = c.id and r.user_id = (select auth.uid()) and r.kind = 'save') as saved,
      coalesce((select jsonb_agg(jsonb_build_object('path', m.storage_path, 'type', m.media_type) order by m.position)
        from public.post_media m where m.post_id = c.id), '[]'::jsonb) as media
    from candidates c join public.profiles pr on pr.id = c.owner_id
    where p_mode <> 'near' or c.distance_km <= 20
  )
  select r.id, r.owner_id, r.author, r.title, r.city, r.country, r.category,
    r.story, r.lat, r.lng, r.created_at, r.distance_km, r.likes, r.saves,
    r.comment_count, r.rating, r.liked, r.saved, r.media, r.store_id
  from ranked r
  order by case when p_mode = 'near' then r.distance_km end asc nulls last,
    case when p_mode <> 'near' then (r.likes * 3 + r.saves * 2 + r.comment_count * 2 + coalesce(r.rating, 0) * 2) end desc nulls last,
    r.created_at desc
  limit least(greatest(coalesce(p_limit, 40), 1), 40);
$$;

grant execute on function public.feed_spots(double precision, double precision, text, text, text, integer)
  to anon, authenticated;
