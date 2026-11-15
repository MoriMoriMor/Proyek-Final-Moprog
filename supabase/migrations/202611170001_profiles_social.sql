-- Profil sosial: username, bio, foto profil, ikuti, dan tag teman di postingan.
-- Jalankan setelah 202611160001_categories.sql.

alter table public.profiles add column if not exists username text;
alter table public.profiles add column if not exists bio text not null default '';
alter table public.profiles add column if not exists avatar_path text;

alter table public.profiles drop constraint if exists profiles_bio_length;
alter table public.profiles add constraint profiles_bio_length check (char_length(bio) <= 150);

-- Username awal: nama tanpa simbol + 4 karakter dari id, supaya unik.
create or replace function public.default_username(p_name text, p_id uuid)
returns text language sql immutable set search_path = '' as $$
  select left(
    coalesce(nullif(lower(regexp_replace(coalesce(p_name, ''), '[^a-zA-Z0-9]+', '', 'g')), ''), 'spot'),
    14
  ) || substr(replace(p_id::text, '-', ''), 1, 4);
$$;

update public.profiles
  set username = public.default_username(display_name, id)
  where username is null;

alter table public.profiles alter column username set not null;
alter table public.profiles drop constraint if exists profiles_username_format;
alter table public.profiles add constraint profiles_username_format
  check (username ~ '^[a-z0-9_.]{3,20}$');
create unique index if not exists profiles_username_key on public.profiles (username);

create or replace function public.create_profile_for_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  name text := left(case
    when char_length(coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), '')) >= 2
      then new.raw_user_meta_data ->> 'display_name'
    when char_length(coalesce(split_part(new.email, '@', 1), '')) >= 2
      then split_part(new.email, '@', 1)
    else 'Traveler' end, 60);
begin
  insert into public.profiles (id, display_name, username)
  values (new.id, name, public.default_username(name, new.id));
  return new;
end;
$$;

-- Ikuti
create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);
create index if not exists follows_following_idx on public.follows (following_id, created_at desc);

-- Tag teman di postingan
create table if not exists public.post_tags (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);
create index if not exists post_tags_user_idx on public.post_tags (user_id, created_at desc);

revoke all on public.follows, public.post_tags from anon, authenticated;
grant select on public.follows, public.post_tags to anon, authenticated;
grant insert, delete on public.follows, public.post_tags to authenticated;

alter table public.follows enable row level security;
alter table public.post_tags enable row level security;

drop policy if exists follows_read on public.follows;
create policy follows_read on public.follows for select using (true);
drop policy if exists follows_insert_self on public.follows;
create policy follows_insert_self on public.follows for insert to authenticated
  with check (follower_id = (select auth.uid()));
drop policy if exists follows_delete_self on public.follows;
create policy follows_delete_self on public.follows for delete to authenticated
  using (follower_id = (select auth.uid()));

drop policy if exists post_tags_read on public.post_tags;
create policy post_tags_read on public.post_tags for select using (true);
drop policy if exists post_tags_insert_owner on public.post_tags;
create policy post_tags_insert_owner on public.post_tags for insert to authenticated
  with check (exists (select 1 from public.posts p where p.id = post_id and p.owner_id = (select auth.uid())));
-- Pemilik postingan atau orang yang ditandai boleh melepas tag.
drop policy if exists post_tags_delete on public.post_tags;
create policy post_tags_delete on public.post_tags for delete to authenticated
  using (
    user_id = (select auth.uid())
    or exists (select 1 from public.posts p where p.id = post_id and p.owner_id = (select auth.uid()))
  );

-- Angka di halaman profil.
create or replace function public.profile_stats(p_user uuid)
returns table (
  posts bigint, followers bigint, following bigint,
  likes bigint, saves bigint, cities bigint, is_following boolean
)
language sql stable set search_path = '' as $$
  select
    (select count(*) from public.posts where owner_id = p_user),
    (select count(*) from public.follows where following_id = p_user),
    (select count(*) from public.follows where follower_id = p_user),
    (select count(*) from public.reactions r join public.posts p on p.id = r.post_id
      where p.owner_id = p_user and r.kind = 'like'),
    (select count(*) from public.reactions r join public.posts p on p.id = r.post_id
      where p.owner_id = p_user and r.kind = 'save'),
    (select count(distinct lower(trim(city))) from public.posts where owner_id = p_user),
    exists (select 1 from public.follows where follower_id = (select auth.uid()) and following_id = p_user);
$$;
grant execute on function public.profile_stats(uuid) to anon, authenticated;

-- Feed dengan mode baru: user (postingan seseorang), tagged (tempat ia ditandai),
-- dan following (dari akun yang diikuti). Mode lama tetap sama.
drop function if exists public.feed_spots(double precision, double precision, text, text, text, integer);
drop function if exists public.feed_spots(double precision, double precision, text, text, text, integer, uuid);
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
  author_username text, author_avatar text
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
    r.author_username, r.author_avatar
  from ranked r
  order by case when p_mode = 'near' then r.distance_km end asc nulls last,
    case when p_mode in ('user', 'tagged', 'following', 'mine', 'saved') then r.created_at end desc nulls last,
    case when p_mode = 'popular' then (r.likes * 3 + r.saves * 2 + r.comment_count * 2 + coalesce(r.rating, 0) * 2) end desc nulls last,
    r.created_at desc
  limit least(greatest(coalesce(p_limit, 40), 1), 60);
$$;

grant execute on function public.feed_spots(double precision, double precision, text, text, text, integer, uuid)
  to anon, authenticated;
