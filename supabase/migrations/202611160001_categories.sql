-- Tujuh kategori besar untuk spot dan toko.
-- Kunci lama tetap dipakai: kafe tampil sebagai "Nongkrong", destinasi sebagai "Wisata".
-- Jalankan setelah 202611150001_marketplace.sql.

alter table public.posts drop constraint if exists posts_category_check;
alter table public.stores drop constraint if exists stores_category_check;
alter table public.store_applications drop constraint if exists store_applications_category_check;

-- Kategori "lainnya" pada toko lama digabung ke belanja.
update public.stores set category = 'belanja' where category = 'lainnya';
update public.store_applications set category = 'belanja' where category = 'lainnya';

alter table public.posts add constraint posts_category_check check (category in
  ('kuliner', 'kafe', 'destinasi', 'olahraga', 'aktivitas', 'belanja', 'menginap'));
alter table public.stores add constraint stores_category_check check (category in
  ('kuliner', 'kafe', 'destinasi', 'olahraga', 'aktivitas', 'belanja', 'menginap'));
alter table public.store_applications add constraint store_applications_category_check check (category in
  ('kuliner', 'kafe', 'destinasi', 'olahraga', 'aktivitas', 'belanja', 'menginap'));
