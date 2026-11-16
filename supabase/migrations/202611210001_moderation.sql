-- Moderasi: lapor konten (spot, komentar, akun) dan blokir pengguna.
-- Jalankan setelah 202611190001_places.sql. Aman dijalankan ulang.

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('post', 'comment', 'user')),
  target_id uuid not null,
  reason text not null check (char_length(trim(reason)) between 3 and 200),
  status text not null default 'pending' check (status in ('pending', 'resolved', 'dismissed')),
  created_at timestamptz not null default now(),
  unique (reporter_id, target_type, target_id)
);

create index if not exists reports_status_idx on public.reports (status, created_at desc);

create table if not exists public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create index if not exists user_blocks_blocked_idx on public.user_blocks (blocked_id);

revoke all on public.reports, public.user_blocks from anon, authenticated;
grant select, insert on public.reports to authenticated;
grant select, insert, delete on public.user_blocks to authenticated;

alter table public.reports enable row level security;
alter table public.user_blocks enable row level security;

drop policy if exists reports_insert_self on public.reports;
create policy reports_insert_self on public.reports
  for insert to authenticated
  with check (reporter_id = (select auth.uid()));

drop policy if exists reports_read_self_or_admin on public.reports;
create policy reports_read_self_or_admin on public.reports
  for select to authenticated
  using (
    reporter_id = (select auth.uid())
    or exists (
      select 1 from public.app_admins a where a.user_id = (select auth.uid())
    )
  );

drop policy if exists user_blocks_self on public.user_blocks;
create policy user_blocks_self on public.user_blocks
  for all to authenticated
  using (blocker_id = (select auth.uid()))
  with check (blocker_id = (select auth.uid()));

-- Admin menyelesaikan atau menolak laporan.
create or replace function public.resolve_report(p_report uuid, p_status text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Masuk dulu ya.';
  end if;
  if not exists (select 1 from public.app_admins where user_id = auth.uid()) then
    raise exception 'Hanya admin yang bisa memproses laporan.';
  end if;
  if p_status not in ('resolved', 'dismissed') then
    raise exception 'Status laporan tidak valid.';
  end if;
  update public.reports set status = p_status where id = p_report;
end;
$$;

revoke all on function public.resolve_report(uuid, text) from public, anon;
grant execute on function public.resolve_report(uuid, text) to authenticated;

-- Perbarui feed_spots agar postingan dari pengguna yang diblokir tidak tampil.
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
    case when p_mode = 'place' then (r.likes * 3 + r.saves * 2 + r.comment_count * 2 + coalesce(r.rating, 0) * 2) end desc nulls last,
    case when p_mode = 'popular' then public.viral_score(r.likes, r.saves, r.comment_count, r.rating, r.created_at) end desc nulls last,
    r.created_at desc
  limit least(greatest(coalesce(p_limit, 40), 1), 60);
$$;
