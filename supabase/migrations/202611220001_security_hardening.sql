-- Pengamanan celah eksploitasi: batasi kolom update profiles & posts,
-- sembunyikan komentar dari akun terblokir, dan batasi XP harian per akun.
-- Jalankan setelah 202611210001_moderation.sql. Aman dijalankan ulang.

-- 1. Pengguna hanya boleh mengubah kolom profil publik, bukan streak/best_streak/streak_day.
revoke update on public.profiles from authenticated;
grant update (display_name, username, bio, avatar_path) on public.profiles to authenticated;

-- 2. Pemilik spot hanya boleh mengubah isi spot, bukan owner_id/store_id/place_id.
revoke update on public.posts from authenticated;
grant update (title, story, city, category) on public.posts to authenticated;

-- 3. Komentar dari pengguna yang diblokir tidak tampil lewat RLS.
drop policy if exists comments_read on public.comments;
create policy comments_read on public.comments for select using (
  not exists (
    select 1 from public.user_blocks b
    where b.blocker_id = (select auth.uid()) and b.blocked_id = user_id
  )
);

-- 4. Batasi perolehan XP harian (maksimal 300 XP/hari) untuk mencegah spam RPC.
alter table public.user_game add column if not exists xp_day date;
alter table public.user_game add column if not exists daily_xp integer not null default 0;

create or replace function public.record_game_action(
  p_action text,
  p_day date default current_date
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_day date;
  v_base integer;
  v_target integer := 0;
  v_bonus integer := 0;
  v_gained integer := 0;
  v_xp integer := 0;
  v_daily integer := 0;
  v_xp_day date;
  v_progress integer := 0;
  v_claimed boolean := false;
  v_finished text;
  v_cap constant integer := 300;
begin
  if v_uid is null then
    raise exception 'Masuk dulu ya.';
  end if;

  v_day := least(greatest(coalesce(p_day, current_date), current_date - 1), current_date + 1);

  v_base := case p_action
    when 'reel' then 1
    when 'like' then 2
    when 'save' then 3
    when 'rate' then 3
    when 'comment' then 5
    when 'post' then 30
    when 'order' then 20
    when 'store' then 25
    when 'share' then 5
    when 'invited' then 30
    when 'follow' then 1
    else null
  end;

  if v_base is null then
    raise exception 'Aksi tidak dikenal.';
  end if;

  insert into public.user_game (user_id, xp_day, daily_xp)
  values (v_uid, v_day, 0)
  on conflict (user_id) do nothing;

  select xp, xp_day, daily_xp into v_xp, v_xp_day, v_daily
  from public.user_game
  where user_id = v_uid
  for update;

  if v_xp_day is distinct from v_day then
    v_daily := 0;
  end if;

  if p_action = 'invited' then
    update public.user_game
      set invite_claimed = true,
          xp = xp + least(v_base, greatest(v_cap - v_daily, 0)),
          xp_day = v_day,
          daily_xp = v_daily + least(v_base, greatest(v_cap - v_daily, 0)),
          updated_at = now()
      where user_id = v_uid and invite_claimed = false
      returning xp, least(v_base, greatest(v_cap - v_daily, 0)) into v_xp, v_gained;

    if not found then
      v_gained := 0;
    end if;

    return jsonb_build_object(
      'xp', coalesce(v_xp, 0),
      'gained', coalesce(v_gained, 0),
      'finished_quest', null,
      'day', v_day::text
    );
  end if;

  v_gained := v_base;

  case p_action
    when 'reel' then v_target := 5; v_bonus := 20;
    when 'like' then v_target := 3; v_bonus := 15;
    when 'save' then v_target := 1; v_bonus := 10;
    when 'comment' then v_target := 1; v_bonus := 15;
    when 'share' then v_target := 1; v_bonus := 25;
    else v_target := 0;
  end case;

  if v_target > 0 then
    insert into public.quest_progress (user_id, day, quest_key, progress, claimed)
    values (v_uid, v_day, p_action, 1, false)
    on conflict (user_id, day, quest_key) do update
      set progress = case
            when public.quest_progress.claimed then public.quest_progress.progress
            else public.quest_progress.progress + 1
          end,
          updated_at = now()
      returning progress, claimed into v_progress, v_claimed;

    if not v_claimed and v_progress >= v_target then
      update public.quest_progress
        set claimed = true, updated_at = now()
        where user_id = v_uid and day = v_day and quest_key = p_action;
      v_gained := v_gained + v_bonus;
      v_finished := p_action;
    end if;
  end if;

  v_gained := least(v_gained, greatest(v_cap - v_daily, 0));

  update public.user_game
    set xp = xp + v_gained,
        xp_day = v_day,
        daily_xp = v_daily + v_gained,
        updated_at = now()
    where user_id = v_uid
    returning xp into v_xp;

  return jsonb_build_object(
    'xp', coalesce(v_xp, 0),
    'gained', v_gained,
    'finished_quest', v_finished,
    'day', v_day::text
  );
end;
$$;
