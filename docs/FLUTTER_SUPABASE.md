# Flutter dan Supabase

Aplikasi Flutter Spots ada di folder [`mobile`](../mobile). Datanya memakai Supabase Postgres. Akun dikelola Supabase Auth, sedangkan foto dan video berada di bucket Storage `spot-media`.

## Siapkan proyek

1. Buat proyek di [Supabase Dashboard](https://supabase.com/dashboard).
2. Buka **SQL Editor**, buat query baru, salin isi [`202610050001_spots.sql`](../supabase/migrations/202610050001_spots.sql), lalu jalankan sekali.
3. Buka **Table Editor**. Tabel `profiles`, `posts`, `post_media`, `reactions`, `ratings`, dan `comments` seharusnya terlihat.
4. Buka **Storage**. Bucket publik `spot-media` seharusnya terlihat. Upload hanya diizinkan ke folder yang diawali ID akun sendiri.
5. Jalankan juga [`202611150001_marketplace.sql`](../supabase/migrations/202611150001_marketplace.sql) sekali untuk toko, katalog, dan pesanan. Urutannya harus setelah migrasi pertama. Lalu jalankan [`202611160001_categories.sql`](../supabase/migrations/202611160001_categories.sql) untuk tujuh kategori dan [`202611170001_profiles_social.sql`](../supabase/migrations/202611170001_profiles_social.sql) untuk username, foto profil, ikuti, dan tag teman.
6. Buka **Connect** untuk mengambil Project URL dan publishable key. Salin [`config.example.json`](../mobile/config.example.json) ke `mobile/config.json` dan isi dua nilainya.
7. Di `mobile`, jalankan `flutter pub get`, lalu `flutter run --dart-define-from-file=config.json`.

Jangan memakai `service_role`, secret key, password Postgres, atau connection string di Flutter. RLS mengatur siapa yang boleh menulis postingan dan interaksi. SQL Editor hanya dipakai saat memasang atau mengubah skema.

## Akses data

| Data | Tempat melihat dan mengedit |
| --- | --- |
| Akun | Authentication → Users |
| Profil pengguna | Table Editor → `profiles` |
| Tempat dan koordinat | Table Editor → `posts` |
| Urutan foto/video | Table Editor → `post_media` |
| Suka dan simpan | Table Editor → `reactions` |
| Rating | Table Editor → `ratings` |
| Komentar | Table Editor → `comments` |
| Berkas media | Storage → `spot-media` |
| Admin aplikasi | Table Editor → `app_admins` |
| Pengajuan toko | Table Editor → `store_applications` |
| Toko dan pengaturan online | Table Editor → `stores` |
| Katalog | Table Editor → `products` |
| Pesanan dan rinciannya | Table Editor → `orders`, `order_items` |
| Ikuti | Table Editor → `follows` |
| Tag teman di postingan | Table Editor → `post_tags` |

Postingan tampil di feed jika memiliki baris `posts` dan media yang sesuai di `post_media`. Untuk menyunting data melalui Table Editor, gunakan akun admin dashboard. Mengubah baris secara langsung melewati alur aplikasi, jadi periksa relasi sebelum menghapus data.

## Konfirmasi email

Halaman tujuan link konfirmasi ada di [`site/confirm`](../site/confirm/index.html) dan dipasang otomatis ke GitHub Pages oleh workflow [`pages.yml`](../.github/workflows/pages.yml).

1. Pemilik repo membuka **Settings → Pages**, lalu memilih **Source: GitHub Actions**. Setelah push ke `main`, situs tersedia di `https://morimorimor.github.io/Proyek-Final-Moprog/`.
2. Di Supabase, buka **Authentication → URL Configuration**:
   - **Site URL:** `https://morimorimor.github.io/Proyek-Final-Moprog/confirm/`
   - **Redirect URLs:** tambahkan URL yang sama, ditambah `io.spots.app://login-callback` untuk login Google di HP.
3. Buka **Authentication → Emails → Confirm signup**. Ganti subjek menjadi `Satu langkah lagi buat gabung Spots`, lalu tempel isi [`confirm_signup.html`](../supabase/templates/confirm_signup.html).

Aplikasi mengirim alamat konfirmasi lewat `emailRedirectTo`. Kalau situsnya pindah domain, build dengan `--dart-define=CONFIRM_URL=https://domain-baru/confirm/`.

## Login dengan Google

1. Di [Google Cloud Console](https://console.cloud.google.com/), buat project, lalu buka **APIs & Services → OAuth consent screen** dan isi nama aplikasi Spots.
2. Buka **Credentials → Create credentials → OAuth client ID**, pilih **Web application**. Pada **Authorized redirect URIs**, isi `https://<id-proyek>.supabase.co/auth/v1/callback` (ada di halaman provider Google di Supabase).
3. Di Supabase, buka **Authentication → Sign In / Providers → Google**, aktifkan, lalu tempel Client ID dan Client Secret dari langkah 2.
4. Pastikan `io.spots.app://login-callback` sudah ada di Redirect URLs (lihat bagian konfirmasi email).

Android dan iOS sudah dikonfigurasi untuk membuka aplikasi lagi lewat skema `io.spots.app`. Di versi web, aplikasi kembali ke alamat yang sedang dibuka.

## Profil

Setiap akun punya username unik (huruf kecil, angka, titik, garis bawah), bio maksimal 150 karakter, dan foto profil yang disimpan di bucket `spot-media` pada folder `<id akun>/avatar/`. Akun lama otomatis mendapat username dari namanya. Fungsi `profile_stats` menghitung jumlah spot, pengikut, mengikuti, suka, simpanan, dan kota. Feed punya mode `user`, `tagged`, dan `following`.

## Marketplace

**Menjadikan akun sebagai admin.** Admin meninjau pengajuan toko langsung dari aplikasi (Profil → Review pengajuan toko). Ambil UUID akun di Authentication → Users, lalu jalankan di SQL Editor:

```sql
insert into public.app_admins (user_id) values ('UUID-AKUN-ADMIN');
```

**Alurnya:**

1. Pengguna membuka Profil → Daftarkan toko, lalu mengisi data dan pin lokasi. Status awalnya *menunggu*.
2. Admin menyetujui atau menolak dengan alasan. Persetujuan membuat baris `stores` atas nama pemohon. Pemohon tidak bisa meninjau pengajuannya sendiri.
3. Pemilik toko mengisi produk dan mengatur pesanan online, ambil/kirim, ongkir, dan cara bayar.
4. Pembeli memesan dari satu toko per pesanan. Fungsi `place_order` menghitung total dari harga di database, mengecek stok, dan menolak pesanan ganda dengan kunci permintaan yang sama.
5. Toko menerima pesanan (`accept_order` memotong stok satu kali) atau menolaknya. Pembeli membayar sesuai instruksi, toko mengonfirmasi lunas, lalu pesanan diproses, siap, dan selesai.

Status pesanan dan status pembayaran disimpan terpisah. Aplikasi tidak bisa mengubah harga, stok, atau status lunas secara langsung; semuanya lewat fungsi yang memeriksa pemilik toko. Payment gateway dan pelacakan kurir belum termasuk.

Foto produk disimpan di bucket `spot-media` pada folder `<id akun>/products/`.

**Menguji migrasi tanpa Supabase.** Lihat [`supabase/tests/README.md`](../supabase/tests/README.md).

## Cara kerja feed

RPC `feed_spots` membatasi respons ke paling banyak 40 tempat. Mode `near` mengambil titik dalam radius 20 km dari GPS. Saat lokasi tidak tersedia, aplikasi menampilkan hasil populer. Mode `popular` mengurutkan hasil jauh dengan bobot suka, simpan, komentar, dan rating. Mode `saved` dan `mine` menampilkan daftar pribadi berdasarkan akun yang sedang masuk.

Peta memakai tile OpenStreetMap dan koordinat dari post. Jika aplikasi dipakai publik dalam skala besar, siapkan penyedia tile dengan batas penggunaan yang sesuai.

## Izin perangkat

Android meminta internet, lokasi, dan kamera melalui manifest. Untuk membangun APK di Windows, siapkan JDK 17 atau lebih baru dan Android SDK command-line tools. iOS sudah memiliki deskripsi izin kamera, mikrofon, galeri, dan lokasi di `Info.plist`. Build iOS membutuhkan macOS dan Xcode. Sebelum rilis Android, ganti konfigurasi debug signing dengan keystore rilis milik proyek.
