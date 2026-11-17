-- Izinkan role anon mengevaluasi pengecekan user_blocks di feed_spots dan comments.
-- Kebijakan RLS user_blocks tetap hanya untuk authenticated, sehingga tamu tidak bisa melihat data blokir.
-- Jalankan setelah 202611220001_security_hardening.sql. Aman dijalankan ulang.

grant select on public.user_blocks to anon;
