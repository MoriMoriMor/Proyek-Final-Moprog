-- Streak harian tampil di profil supaya bisa dilihat orang lain.
-- Jalankan setelah 202611170001_profiles_social.sql. Aman dijalankan ulang.

alter table public.profiles add column if not exists streak integer not null default 0;
alter table public.profiles add column if not exists best_streak integer not null default 0;
alter table public.profiles add column if not exists streak_day date;

alter table public.profiles drop constraint if exists profiles_streak_range;
alter table public.profiles add constraint profiles_streak_range
  check (streak between 0 and 3650 and best_streak between 0 and 3650);

-- Pengguna hanya memperbarui streak miliknya sendiri. Rekor tidak bisa turun.
create or replace function public.sync_streak(p_streak integer)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Masuk dulu ya.'; end if;
  update public.profiles
    set streak = least(greatest(p_streak, 0), 3650),
        best_streak = greatest(best_streak, least(greatest(p_streak, 0), 3650)),
        streak_day = current_date
    where id = auth.uid();
end;
$$;

revoke all on function public.sync_streak(integer) from public, anon;
grant execute on function public.sync_streak(integer) to authenticated;
