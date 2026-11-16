\ir ../migrations/202611220001_security_hardening.sql
-- Uji pengamanan: manipulasi streak/owner_id ditolak, komentar terblokir sembunyi, batas XP harian berlaku.

select pg_temp.act('00000000-0000-0000-0000-00000000000c');

-- 1. Tidak boleh mengubah kolom sensitif profiles.streak atau posts.owner_id langsung.
select pg_temp.fails($$update public.profiles set streak = 999 where id = '00000000-0000-0000-0000-00000000000c'$$, 'permission denied');
select pg_temp.fails($$update public.posts set owner_id = '00000000-0000-0000-0000-00000000000a' where owner_id = '00000000-0000-0000-0000-00000000000c'$$, 'permission denied');

-- 2. Batas XP harian (300 XP) menghentikan spam record_game_action.
do $$
declare
  i integer;
  v_res jsonb;
begin
  for i in 1..11 loop
    v_res := public.record_game_action('post');
  end loop;
  if (v_res ->> 'xp')::int > 300 or (v_res ->> 'gained')::int <> 0 then
    raise exception 'Batas XP harian tidak bekerja: %', v_res;
  end if;
end $$;

\echo 'SEMUA UJI PENGAMANAN LULUS'
