# Uji migrasi

Skrip di folder ini menjalankan semua migrasi di PostgreSQL lokal, lalu menguji aturannya:

- **marketplace**: persetujuan admin, akses lintas akun, toko offline, stok habis, harga berubah, permintaan ganda, alur status pesanan
- **sosial**: profil, username, follow, tag, feed per orang
- **tempat**: memilih tempat lama atau membuat tempat baru, feed per tempat, `nearby_places`

`supabase_stub.sql` hanya meniru bagian Supabase yang dibutuhkan (peran `anon`/`authenticated`, `auth.uid()`, dan skema storage). Jangan jalankan di proyek Supabase sungguhan.

```bash
createdb spots_test
psql -v ON_ERROR_STOP=1 -d spots_test \
  -f supabase/tests/supabase_stub.sql \
  -f supabase/migrations/202610050001_spots.sql \
  -f supabase/migrations/202611150001_marketplace.sql \
  -f supabase/migrations/202611160001_categories.sql \
  -f supabase/migrations/202611170001_profiles_social.sql \
  -f supabase/migrations/202611180001_streaks.sql \
  -f supabase/migrations/202611190001_places.sql \
  -f supabase/tests/marketplace_test.sql \
  -f supabase/tests/social_test.sql \
  -f supabase/tests/places_test.sql
dropdb spots_test
```

Kalau semua lulus, muncul `SEMUA UJI MARKETPLACE LULUS`, `SEMUA UJI SOSIAL LULUS`, dan `SEMUA UJI TEMPAT LULUS`.
