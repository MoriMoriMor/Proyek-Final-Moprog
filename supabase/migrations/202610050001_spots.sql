-- Spots mobile schema. Run once in the Supabase SQL Editor.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 2 and 60),
  created_at timestamptz not null default now()
);

create or replace function public.create_profile_for_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, left(case
    when char_length(coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), '')) >= 2
      then new.raw_user_meta_data ->> 'display_name'
    when char_length(coalesce(split_part(new.email, '@', 1), '')) >= 2
      then split_part(new.email, '@', 1)
    else 'Traveler' end, 60));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_spots on auth.users;
create trigger on_auth_user_created_spots after insert on auth.users
for each row execute function public.create_profile_for_user();

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 3 and 100),
  city text not null check (char_length(city) between 2 and 70),
  country text not null default 'Indonesia',
  category text not null check (category in ('kuliner', 'kafe', 'destinasi')),
  story text not null check (char_length(story) between 5 and 2000),
  lat double precision not null check (lat between -90 and 90),
  lng double precision not null check (lng between -180 and 180),
  created_at timestamptz not null default now()
);

create table if not exists public.post_media (
  post_id uuid not null references public.posts(id) on delete cascade,
  position smallint not null check (position between 0 and 4),
  storage_path text not null,
  media_type text not null check (media_type in ('image', 'video')),
  primary key (post_id, position)
);

create table if not exists public.reactions (
  user_id uuid not null references public.profiles(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  kind text not null check (kind in ('like', 'save')),
  created_at timestamptz not null default now(),
  primary key (user_id, post_id, kind)
);

create table if not exists public.ratings (
  user_id uuid not null references public.profiles(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  score smallint not null check (score between 1 and 5),
  created_at timestamptz not null default now(),
  primary key (user_id, post_id)
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 500),
  created_at timestamptz not null default now()
);

create index if not exists spots_posts_created_idx on public.posts (created_at desc);
create index if not exists spots_posts_category_idx on public.posts (category, created_at desc);
create index if not exists spots_posts_geo_idx on public.posts (lat, lng);
create index if not exists spots_media_post_idx on public.post_media (post_id, position);
create index if not exists spots_reactions_post_idx on public.reactions (post_id, kind);
create index if not exists spots_ratings_post_idx on public.ratings (post_id);
create index if not exists spots_comments_post_idx on public.comments (post_id, created_at desc);

revoke all on public.profiles, public.posts, public.post_media,
  public.reactions, public.ratings, public.comments from anon, authenticated;
grant select on public.profiles, public.posts, public.post_media,
  public.reactions, public.ratings, public.comments to anon, authenticated;
grant update on public.profiles to authenticated;
grant insert, update, delete on public.posts to authenticated;
grant insert, delete on public.post_media, public.reactions, public.comments to authenticated;
grant insert, update on public.ratings to authenticated;

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.post_media enable row level security;
alter table public.reactions enable row level security;
alter table public.ratings enable row level security;
alter table public.comments enable row level security;

create policy profiles_read on public.profiles for select using (true);
create policy profiles_update_self on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy posts_read on public.posts for select using (true);
create policy posts_insert_self on public.posts for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy posts_update_self on public.posts for update to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
create policy posts_delete_self on public.posts for delete to authenticated
  using (owner_id = (select auth.uid()));
create policy media_read on public.post_media for select using (true);
create policy media_insert_owner on public.post_media for insert to authenticated
  with check (
    exists (select 1 from public.posts p where p.id = post_id and p.owner_id = (select auth.uid()))
    and storage_path like (select auth.uid())::text || '/' || post_id::text || '/%'
  );
create policy media_delete_owner on public.post_media for delete to authenticated
  using (exists (select 1 from public.posts p where p.id = post_id and p.owner_id = (select auth.uid())));
create policy reactions_read on public.reactions for select using (true);
create policy reactions_insert_self on public.reactions for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy reactions_delete_self on public.reactions for delete to authenticated
  using (user_id = (select auth.uid()));
create policy ratings_read on public.ratings for select using (true);
create policy ratings_insert_self on public.ratings for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy ratings_update_self on public.ratings for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy comments_read on public.comments for select using (true);
create policy comments_insert_self on public.comments for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy comments_delete_self on public.comments for delete to authenticated
  using (user_id = (select auth.uid()));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('spot-media', 'spot-media', true, 41943040,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'video/mp4', 'video/quicktime', 'video/webm'])
on conflict (id) do nothing;

create policy spot_media_public_read on storage.objects for select
  using (bucket_id = 'spot-media');
create policy spot_media_upload_self on storage.objects for insert to authenticated
  with check (bucket_id = 'spot-media' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy spot_media_delete_self on storage.objects for delete to authenticated
  using (bucket_id = 'spot-media' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- Feed returns a bounded nearby set; distant results are selected by engagement.
create or replace function public.feed_spots(
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
  saved boolean, media jsonb
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
    r.comment_count, r.rating, r.liked, r.saved, r.media
  from ranked r
  order by case when p_mode = 'near' then r.distance_km end asc nulls last,
    case when p_mode <> 'near' then (r.likes * 3 + r.saves * 2 + r.comment_count * 2 + coalesce(r.rating, 0) * 2) end desc nulls last,
    r.created_at desc
  limit least(greatest(coalesce(p_limit, 40), 1), 40);
$$;

grant execute on function public.feed_spots(double precision, double precision, text, text, text, integer)
  to anon, authenticated;
