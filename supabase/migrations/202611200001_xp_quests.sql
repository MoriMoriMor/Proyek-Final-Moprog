-- Sinkronisasi XP, level, dan misi harian ke server.
-- Jalankan setelah 202611180001_streaks.sql. Aman dijalankan ulang.

create table if not exists public.user_game (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  xp integer not null default 0 check (xp >= 0),
  invite_claimed boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists public.quest_progress (
  user_id uuid not null references public.profiles(id) on delete cascade,
  day date not null,
  quest_key text not null,
  progress integer not null default 0 check (progress >= 0),
  claimed boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, day, quest_key)
);

revoke all on public.user_game, public.quest_progress from anon, authenticated;
grant select on public.user_game to anon, authenticated;
grant select on public.quest_progress to authenticated;

alter table public.user_game enable row level security;
alter table public.quest_progress enable row level security;

drop policy if exists user_game_read on public.user_game;
create policy user_game_read on public.user_game for select using (true);

drop policy if exists quest_progress_read_self on public.quest_progress;
create policy quest_progress_read_self on public.quest_progress
  for select to authenticated
  using (user_id = (select auth.uid()));

-- Ambil XP, streak, dan progres misi harian milik pengguna saat ini.
create or replace function public.get_game_state(p_day date default current_date)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_day date;
  v_xp integer := 0;
  v_streak integer := 0;
  v_best integer := 0;
  v_quests jsonb;
begin
  if v_uid is null then
    raise exception 'Masuk dulu ya.';
  end if;

  v_day := least(greatest(coalesce(p_day, current_date), current_date - 1), current_date + 1);

  select coalesce(g.xp, 0), coalesce(p.streak, 0), coalesce(p.best_streak, 0)
    into v_xp, v_streak, v_best
    from public.profiles p
    left join public.user_game g on g.user_id = p.id
    where p.id = v_uid;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'key', q.quest_key,
        'progress', q.progress,
        'claimed', q.claimed
      )
    ),
    '[]'::jsonb
  )
  into v_quests
  from public.quest_progress q
  where q.user_id = v_uid and q.day = v_day;

  return jsonb_build_object(
    'xp', v_xp,
    'streak', v_streak,
    'best_streak', v_best,
    'day', v_day::text,
    'quests', v_quests
  );
end;
$$;

-- Catat aksi pengguna, hitung XP dan penyelesaian misi di server.
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
  v_progress integer := 0;
  v_claimed boolean := false;
  v_finished text;
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

  insert into public.user_game (user_id)
  values (v_uid)
  on conflict (user_id) do nothing;

  if p_action = 'invited' then
    update public.user_game
      set invite_claimed = true,
          xp = xp + v_base,
          updated_at = now()
      where user_id = v_uid and invite_claimed = false
      returning xp into v_xp;

    if found then
      v_gained := v_base;
    else
      select xp into v_xp from public.user_game where user_id = v_uid;
    end if;

    return jsonb_build_object(
      'xp', coalesce(v_xp, 0),
      'gained', v_gained,
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

  update public.user_game
    set xp = xp + v_gained, updated_at = now()
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

revoke all on function public.get_game_state(date) from public, anon;
grant execute on function public.get_game_state(date) to authenticated;

revoke all on function public.record_game_action(text, date) from public, anon;
grant execute on function public.record_game_action(text, date) to authenticated;
