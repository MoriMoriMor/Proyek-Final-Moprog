-- Tempat (places) dan skor viral yang ikut umur postingan.
--
-- Satu tempat bisa didokumentasikan banyak orang. Saat membuat spot,
-- pengguna memilih sendiri: bergabung ke tempat yang sudah ada di dekatnya,
-- atau membuat tempat baru. Pengelompokan hanya berdasarkan pilihan itu,
-- bukan jarak, karena dua lokasi berdekatan bisa saja tempat berbeda.
-- Aman dijalankan ulang.

create table if not exists public.places (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 100),
  category text not null check (category in
    ('kuliner', 'kafe', 'destinasi', 'olahraga', 'aktivitas', 'belanja', 'menginap')),
  city text not null default '' check (char_length(city) <= 70),
  lat double precision not null check (lat between -90 and 90),
  lng double precision not null check (lng between -180 and 180),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists places_geo_idx on public.places (lat, lng);

alter table public.posts add column if not exists place_id uuid
  references public.places(id) on delete set null;
create index if not exists posts_place_idx on public.posts (place_id);

alter table public.places enable row level security;
revoke all on public.places from anon, authenticated;
grant select on public.places to anon, authenticated;
grant insert on public.places to authenticated;
drop policy if exists places_read on public.places;
create policy places_read on public.places for select using (true);
drop policy if exists places_insert_self on public.places;
create policy places_insert_self on public.places for insert to authenticated
  with check (created_by = (select auth.uid()));

-- Postingan lama: setiap postingan menjadi tempatnya sendiri.
do $$
declare p record; new_id uuid;
begin
  for p in select id, title, category, city, lat, lng, owner_id from public.posts where place_id is null loop
    insert into public.places (name, category, city, lat, lng, created_by)
    values (left(p.title, 100), p.category, left(p.city, 70), p.lat, p.lng, p.owner_id)
    returning id into new_id;
    update public.posts set place_id = new_id where id = p.id;
  end loop;
end $$;

-- Tempat terdaftar di sekitar titik, untuk ditawarkan saat membuat spot.
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
  with box as (
    select pl.*, 6371000 * acos(least(1.0, greatest(-1.0,
      sin(radians(pl.lat)) * sin(radians(p_lat)) +
      cos(radians(pl.lat)) * cos(radians(p_lat)) * cos(radians(pl.lng - p_lng))
    ))) as distance_m
    from public.places pl
    where pl.lat between p_lat - 0.01 and p_lat + 0.01
      and pl.lng between p_lng - 0.01 and p_lng + 0.01
  )
  select b.id, b.name, b.category, b.city, b.lat, b.lng, b.distance_m,
    (select count(*) from public.posts po where po.place_id = b.id) as posts,
    (select count(distinct po.owner_id) from public.posts po where po.place_id = b.id) as people,
    (select m.storage_path from public.posts po
       join public.post_media m on m.post_id = po.id and m.media_type = 'image'
       where po.place_id = b.id
       order by (select count(*) from public.reactions r where r.post_id = po.id and r.kind = 'like') desc,
         m.position limit 1) as cover
  from box b
  where b.distance_m <= least(greatest(coalesce(p_radius_m, 300), 50), 1000)
    and (p_query is null or p_query = '' or b.name ilike '%' || p_query || '%')
  order by b.distance_m
  limit 12;
$$;
grant execute on function public.nearby_places(double precision, double precision, integer, text)
  to anon, authenticated;

create or replace function public.viral_score(
  p_likes bigint, p_saves bigint, p_comments bigint, p_rating numeric, p_created timestamptz
) returns double precision
language sql stable set search_path = '' as $$
  select (p_likes * 3 + p_saves * 2 + p_comments * 2 + coalesce(p_rating, 0) * 2 + 1)::double precision
    / power(greatest(extract(epoch from (now() - p_created)) / 86400.0, 0) + 2, 0.7);
$$;
grant execute on function public.viral_score(bigint, bigint, bigint, numeric, timestamptz) to anon, authenticated;

drop function if exists public.feed_spots(double precision, double precision, text, text, text, integer, uuid);
-- Mode 'place': p_user diisi id tempat (tanda tangan fungsi sengaja tetap
-- sama supaya tidak ada dua versi feed_spots).
create function public.feed_spots(
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
    case when p_mode = 'place' then (r.likes * 3 + r.saves * 2 + r.comment_count * 2 + coalesce(r.rating, 0) * 2) end desc nulls last,
    case when p_mode = 'popular' then public.viral_score(r.likes, r.saves, r.comment_count, r.rating, r.created_at) end desc nulls last,
    r.created_at desc
  limit least(greatest(coalesce(p_limit, 40), 1), 60);
$$;

grant execute on function public.feed_spots(double precision, double precision, text, text, text, integer, uuid)
  to anon, authenticated;
