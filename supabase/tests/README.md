# Uji migrasi

Skrip di folder ini menjalankan kedua migrasi di PostgreSQL lokal lalu menguji aturan marketplace: persetujuan admin, akses lintas akun, toko offline, stok habis, harga berubah, permintaan ganda, dan alur status pesanan.

`supabase_stub.sql` hanya meniru bagian Supabase yang dibutuhkan (peran `anon`/`authenticated`, `auth.uid()`, dan skema storage). Jangan jalankan di proyek Supabase sungguhan.

```bash
createdb spots_test
psql -v ON_ERROR_STOP=1 -d spots_test \
  -f supabase/tests/supabase_stub.sql \
  -f supabase/migrations/202610050001_spots.sql \
  -f supabase/migrations/202611150001_marketplace.sql \
  -f supabase/tests/marketplace_test.sql
dropdb spots_test
```

Kalau semua lulus, baris terakhir berbunyi `SEMUA UJI MARKETPLACE LULUS`.
