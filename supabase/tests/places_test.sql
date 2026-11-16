\ir ../migrations/202611190001_places.sql
-- Uji tempat: pilih tempat lama atau buat tempat baru, dan feed per tempat.
select pg_temp.act('00000000-0000-0000-0000-00000000000c');
insert into public.places (name, category, city, lat, lng, created_by)
  values ('Taman Uji', 'destinasi', 'Bandung', -6.91, 107.61, '00000000-0000-0000-0000-00000000000c');
select pg_temp.fails($$insert into public.places (name, category, city, lat, lng, created_by)
  values ('Tempat orang', 'destinasi', 'Bandung', -6.91, 107.61, '00000000-0000-0000-0000-00000000000a')$$, 'row-level security');
insert into public.posts (owner_id, title, city, category, story, lat, lng, place_id)
  select '00000000-0000-0000-0000-00000000000c', 'Taman Uji', 'Bandung', 'destinasi', 'Sore di taman.', -6.91, 107.61, id
  from public.places where name = 'Taman Uji';
select pg_temp.act('00000000-0000-0000-0000-00000000000a');
insert into public.posts (owner_id, title, city, category, story, lat, lng, place_id)
  select '00000000-0000-0000-0000-00000000000a', 'Taman Uji pagi', 'Bandung', 'destinasi', 'Pagi juga bagus.', -6.9101, 107.6101, id
  from public.places where name = 'Taman Uji';
insert into public.posts (owner_id, title, city, category, story, lat, lng)
  values ('00000000-0000-0000-0000-00000000000a', 'Kafe sebelah', 'Bandung', 'destinasi', 'Beda tempat.', -6.9101, 107.6101);
do $$ begin
  if (select count(*) from public.feed_spots(null, null, 'place', null, null, 40,
      (select id from public.places where name = 'Taman Uji'))) <> 2 then
    raise exception 'feed tempat harus berisi 2 dokumentasi';
  end if;
  if (select people from public.nearby_places(-6.91, 107.61, 300, null) where name = 'Taman Uji') <> 2 then
    raise exception 'nearby_places harus menghitung 2 orang';
  end if;
end $$;
\echo 'SEMUA UJI TEMPAT LULUS'
