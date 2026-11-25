-- Optimasi tempat, media multi-pengguna, indeks performa, dan pengamanan pesanan/pembayaran.
-- Jalankan setelah 202611230001_fix_guest_feed.sql. Aman dijalankan ulang.

-- Pastikan role anon tetap punya izin baca user_blocks untuk evaluasi RLS feed & komentar.
grant select on public.user_blocks to anon;

-- Normalisasi nama tempat untuk mencegah duplikasi tempat yang sama persis di titik berdekatan.
create or replace function public.normalize_place_name(p_name text)
returns text
language sql
immutable
set search_path = ''
as $$
  select lower(regexp_replace(trim(coalesce(p_name, '')), '\s+', ' ', 'g'));
$$;

grant execute on function public.normalize_place_name(text) to anon, authenticated;

-- Indeks komposit untuk mempercepat agregasi media, reaksi, komentar, rating, dan tempat.
create index if not exists posts_place_created_idx on public.posts (place_id, created_at desc);
create index if not exists post_media_post_pos_idx on public.post_media (post_id, position);
create index if not exists reactions_post_kind_idx on public.reactions (post_id, kind);
create index if not exists comments_post_created_idx on public.comments (post_id, created_at desc);
create index if not exists ratings_post_idx on public.ratings (post_id);
create index if not exists places_norm_name_idx on public.places (public.normalize_place_name(name));

-- Ambil tempat lama atau gunakan tempat berdekatan (<65 m) bila namanya sama persis,
-- supaya beberapa orang yang mengunggah spot baru di lokasi yang sama tetap tergabung rapi.
create or replace function public.resolve_or_create_place(
  p_place_id uuid,
  p_name text,
  p_category text,
  p_city text,
  p_lat double precision,
  p_lng double precision
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_id uuid;
  v_norm text := public.normalize_place_name(p_name);
begin
  if v_uid is null then
    raise exception 'Masuk dulu untuk membagikan spot.';
  end if;
  if char_length(v_norm) < 2 or char_length(trim(p_name)) > 100 then
    raise exception 'Nama tempat harus 2 sampai 100 huruf.';
  end if;

  if p_place_id is not null then
    select id into v_id from public.places where id = p_place_id;
    if v_id is not null then
      return v_id;
    end if;
  end if;

  -- Cek apakah sudah ada tempat bernama sama dalam radius 65 meter.
  select pl.id into v_id
  from public.places pl
  where pl.lat between p_lat - 0.001 and p_lat + 0.001
    and pl.lng between p_lng - 0.001 and p_lng + 0.001
    and public.normalize_place_name(pl.name) = v_norm
    and 6371000 * acos(least(1.0, greatest(-1.0,
      sin(radians(pl.lat)) * sin(radians(p_lat)) +
      cos(radians(pl.lat)) * cos(radians(p_lat)) * cos(radians(pl.lng - p_lng))
    ))) <= 65
  order by pl.created_at asc
  limit 1;

  if v_id is not null then
    return v_id;
  end if;

  insert into public.places (name, category, city, lat, lng, created_by)
  values (trim(p_name), p_category, left(trim(coalesce(p_city, '')), 70), p_lat, p_lng, v_uid)
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.resolve_or_create_place(uuid, text, text, text, double precision, double precision) from public, anon;
grant execute on function public.resolve_or_create_place(uuid, text, text, text, double precision, double precision) to authenticated;

-- Perbarui nearby_places: dukung radius lebih luas saat mencari nama, saring blokir,
-- urutkan sampul memakai viral_score, dan sembunyikan baris tempat yatim tanpa postingan.
create or replace function public.nearby_places(
  p_lat double precision,
  p_lng double precision,
  p_radius_m integer default 300,
  p_query text default null
)
returns table (
  id uuid, name text, category text, city text, lat double precision,
  lng double precision, distance_m double precision, posts bigint,
  people bigint, cover text
)
language sql stable set search_path = '' as $$
  with params as (
    select
      case
        when p_query is not null and trim(p_query) <> ''
          then least(greatest(coalesce(p_radius_m, 1500), 300), 2500)
        else least(greatest(coalesce(p_radius_m, 300), 50), 1000)
      end as max_m,
      case
        when p_query is not null and trim(p_query) <> '' then 0.025
        else 0.01
      end as deg
  ), box as (
    select pl.*, 6371000 * acos(least(1.0, greatest(-1.0,
      sin(radians(pl.lat)) * sin(radians(p_lat)) +
      cos(radians(pl.lat)) * cos(radians(p_lat)) * cos(radians(pl.lng - p_lng))
    ))) as distance_m, pa.max_m
    from public.places pl cross join params pa
    where pl.lat between p_lat - pa.deg and p_lat + pa.deg
      and pl.lng between p_lng - pa.deg and p_lng + pa.deg
  ), stats as (
    select b.*,
      (select count(*) from public.posts po
        where po.place_id = b.id
          and not exists (
            select 1 from public.user_blocks ub
            where ub.blocker_id = (select auth.uid()) and ub.blocked_id = po.owner_id
          )) as post_count,
      (select count(distinct po.owner_id) from public.posts po
        where po.place_id = b.id
          and not exists (
            select 1 from public.user_blocks ub
            where ub.blocker_id = (select auth.uid()) and ub.blocked_id = po.owner_id
          )) as people_count,
      (select m.storage_path from public.posts po
         join public.post_media m on m.post_id = po.id and m.media_type = 'image'
         where po.place_id = b.id
           and not exists (
             select 1 from public.user_blocks ub
             where ub.blocker_id = (select auth.uid()) and ub.blocked_id = po.owner_id
           )
         order by public.viral_score(
           (select count(*) from public.reactions r where r.post_id = po.id and r.kind = 'like'),
           (select count(*) from public.reactions r where r.post_id = po.id and r.kind = 'save'),
           (select count(*) from public.comments cm where cm.post_id = po.id),
           (select avg(rt.score)::numeric from public.ratings rt where rt.post_id = po.id),
           po.created_at
         ) desc, m.position asc
         limit 1) as cover_path
    from box b
    where b.distance_m <= b.max_m
      and (p_query is null or trim(p_query) = '' or b.name ilike '%' || trim(p_query) || '%')
  )
  select s.id, s.name, s.category, s.city, s.lat, s.lng, s.distance_m,
    s.post_count as posts, s.people_count as people, s.cover_path as cover
  from stats s
  where s.post_count > 0 or s.created_at > now() - interval '10 minutes'
  order by
    case when p_query is not null and trim(p_query) <> ''
      and public.normalize_place_name(s.name) = public.normalize_place_name(p_query)
      then 0 else 1 end,
    s.distance_m asc
  limit 12;
$$;

-- Perbarui feed_spots agar mode 'place' mengurutkan dokumentasi berdasarkan viral_score terbaru.
create or replace function public.feed_spots(
  p_lat double precision default null,
  p_lng double precision default null,
  p_mode text default 'near',
  p_category text default null,
  p_query text default null,
  p_limit integer default 40,
  p_user uuid default null
)
returns table (
  id uuid, owner_id uuid, author text, title text, city text, country text,
  category text, story text, lat double precision, lng double precision,
  created_at timestamptz, distance_km double precision, likes bigint,
  saves bigint, comment_count bigint, rating numeric, liked boolean,
  saved boolean, media jsonb, store_id uuid,
  author_username text, author_avatar text, place_id uuid
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
      and (p_mode <> 'user' or p.owner_id = p_user)
      and (p_mode <> 'tagged' or exists
        (select 1 from public.post_tags t where t.post_id = p.id and t.user_id = p_user))
      and (p_mode <> 'following' or exists
        (select 1 from public.follows f where f.follower_id = (select auth.uid()) and f.following_id = p.owner_id))
      and (p_mode <> 'saved' or exists
        (select 1 from public.reactions saved_reaction where saved_reaction.post_id = p.id
          and saved_reaction.user_id = (select auth.uid()) and saved_reaction.kind = 'save'))
      and (p_mode <> 'place' or p.place_id = p_user)
      and (p_mode <> 'near' or (p_lat is not null and p_lng is not null
        and p.lat between p_lat - 0.181 and p_lat + 0.181
        and p.lng between p_lng - 0.2 and p_lng + 0.2))
      and not exists (
        select 1 from public.user_blocks b
        where b.blocker_id = (select auth.uid()) and b.blocked_id = p.owner_id
      )
  ), ranked as (
    select c.*, pr.display_name as author, pr.username as author_username,
      pr.avatar_path as author_avatar,
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
    r.comment_count, r.rating, r.liked, r.saved, r.media, r.store_id,
    r.author_username, r.author_avatar, r.place_id
  from ranked r
  order by case when p_mode = 'near' then r.distance_km end asc nulls last,
    case when p_mode in ('user', 'tagged', 'following', 'mine', 'saved') then r.created_at end desc nulls last,
    case when p_mode in ('place', 'popular') then public.viral_score(r.likes, r.saves, r.comment_count, r.rating, r.created_at) end desc nulls last,
    r.created_at desc
  limit least(greatest(coalesce(p_limit, 40), 1), 60);
$$;

-- Pengamanan place_order: cegah integer overflow (bigint), tolak pesanan antar akun terblokir,
-- dan batasi maksimal 5 pesanan menunggu per pembeli di toko yang sama (anti-spam antrean).
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
  sub bigint := 0;
  fee bigint := 0;
  pending_count integer := 0;
begin
  if me is null then raise exception 'Masuk dulu untuk memesan.'; end if;
  select id into existing from public.orders where buyer_id = me and request_key = p_request_key;
  if existing is not null then return existing; end if;

  select * into shop from public.stores where id = p_store and active;
  if not found then raise exception 'Toko tidak ditemukan.'; end if;
  if not shop.online_orders then raise exception 'Toko ini hanya melayani pembelian di lokasi.'; end if;
  if shop.owner_id = me then raise exception 'Tidak bisa memesan di toko sendiri.'; end if;
  if exists (
    select 1 from public.user_blocks b
    where (b.blocker_id = shop.owner_id and b.blocked_id = me)
       or (b.blocker_id = me and b.blocked_id = shop.owner_id)
  ) then
    raise exception 'Tidak dapat membuat pesanan ke toko ini.';
  end if;

  select count(*) into pending_count
  from public.orders
  where buyer_id = me and store_id = shop.id and status = 'menunggu';
  if pending_count >= 5 then
    raise exception 'Masih ada beberapa pesanan menunggu konfirmasi di toko ini.';
  end if;

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
    sub := sub + (line.price::bigint * line.qty::bigint);
  end loop;

  fee := case when p_fulfillment = 'kirim' then shop.delivery_fee else 0 end;
  if sub + fee > 500000000 then
    raise exception 'Total pesanan melebihi batas transaksi.';
  end if;
  if p_expected_total is not null and p_expected_total::bigint <> sub + fee then
    raise exception 'Harga ada yang berubah. Cek keranjang lagi.';
  end if;

  insert into public.orders (buyer_id, store_id, request_key, fulfillment, address, note,
    subtotal, shipping_fee, total)
  values (me, shop.id, p_request_key, p_fulfillment,
    case when p_fulfillment = 'kirim' then left(trim(p_address), 300) else '' end,
    left(coalesce(trim(p_note), ''), 300), sub::integer, fee::integer, (sub + fee)::integer)
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
