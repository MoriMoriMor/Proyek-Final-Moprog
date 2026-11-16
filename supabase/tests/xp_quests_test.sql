\ir ../migrations/202611200001_xp_quests.sql
-- Uji sinkronisasi XP & misi harian: catat aksi, selesaikan misi, tolak manipulasi langsung & aksi tak dikenal.

-- 1. Pengguna tidak boleh mengubah XP atau progres misi secara langsung lewat tabel.
select pg_temp.act('00000000-0000-0000-0000-00000000000c');
select pg_temp.fails($$insert into public.user_game (user_id, xp) values ('00000000-0000-0000-0000-00000000000c', 9999)$$, 'permission denied');
select pg_temp.fails($$insert into public.quest_progress (user_id, day, quest_key, progress, claimed) values ('00000000-0000-0000-0000-00000000000c', current_date, 'share', 1, true)$$, 'permission denied');

-- 2. Aksi tidak dikenal harus ditolak.
select pg_temp.fails($$select public.record_game_action('cheat_xp')$$, 'Aksi tidak dikenal');

-- 3. Catat aksi komentar: base 5 XP + bonus misi comment 15 XP = 20 XP.
do $$
declare
  v_res jsonb;
  v_state jsonb;
begin
  v_res := public.record_game_action('comment');
  if (v_res ->> 'xp')::int <> 20 or (v_res ->> 'gained')::int <> 20 or (v_res ->> 'finished_quest') <> 'comment' then
    raise exception 'Hasil aksi comment salah: %', v_res;
  end if;

  -- Komentar kedua tidak mengklaim bonus misi lagi: hanya +5 XP.
  v_res := public.record_game_action('comment');
  if (v_res ->> 'xp')::int <> 25 or (v_res ->> 'gained')::int <> 5 or (v_res ->> 'finished_quest') is not null then
    raise exception 'Bonus misi comment tidak boleh ganda: %', v_res;
  end if;

  -- Undangan hanya memberi +30 XP sekali per akun.
  v_res := public.record_game_action('invited');
  if (v_res ->> 'xp')::int <> 55 or (v_res ->> 'gained')::int <> 30 then
    raise exception 'Klaim undangan pertama salah: %', v_res;
  end if;

  v_res := public.record_game_action('invited');
  if (v_res ->> 'xp')::int <> 55 or (v_res ->> 'gained')::int <> 0 then
    raise exception 'Klaim undangan kedua harus 0 XP: %', v_res;
  end if;

  v_state := public.get_game_state();
  if (v_state ->> 'xp')::int <> 55 then
    raise exception 'get_game_state XP salah: %', v_state;
  end if;
end $$;

\echo 'SEMUA UJI XP & MISI LULUS'
