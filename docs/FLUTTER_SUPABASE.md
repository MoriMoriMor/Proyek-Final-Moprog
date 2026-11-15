# Flutter dan Supabase

Aplikasi Flutter Spots ada di folder [`mobile`](../mobile). Datanya memakai Supabase Postgres. Akun dikelola Supabase Auth, sedangkan foto dan video berada di bucket Storage `spot-media`.

## Siapkan proyek

1. Buat proyek di [Supabase Dashboard](https://supabase.com/dashboard).
2. Buka **SQL Editor**, buat query baru, salin isi [`202610050001_spots.sql`](../supabase/migrations/202610050001_spots.sql), lalu jalankan sekali.
3. Buka **Table Editor**. Tabel `profiles`, `posts`, `post_media`, `reactions`, `ratings`, dan `comments` seharusnya terlihat.
4. Buka **Storage**. Bucket publik `spot-media` seharusnya terlihat. Upload hanya diizinkan ke folder yang diawali ID akun sendiri.
5. Buka **Connect** untuk mengambil Project URL dan publishable key. Salin [`config.example.json`](../mobile/config.example.json) ke `mobile/config.json` dan isi dua nilainya.
6. Di `mobile`, jalankan `flutter pub get`, lalu `flutter run --dart-define-from-file=config.json`.

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

Postingan tampil di feed jika memiliki baris `posts` dan media yang sesuai di `post_media`. Untuk menyunting data melalui Table Editor, gunakan akun admin dashboard. Mengubah baris secara langsung melewati alur aplikasi, jadi periksa relasi sebelum menghapus data.

## Cara kerja feed

RPC `feed_spots` membatasi respons ke paling banyak 40 tempat. Mode `near` mengambil titik dalam radius 20 km dari GPS. Saat lokasi tidak tersedia, aplikasi menampilkan hasil populer. Mode `popular` mengurutkan hasil jauh dengan bobot suka, simpan, komentar, dan rating. Mode `saved` dan `mine` menampilkan daftar pribadi berdasarkan akun yang sedang masuk.

Peta memakai tile OpenStreetMap dan koordinat dari post. Jika aplikasi dipakai publik dalam skala besar, siapkan penyedia tile dengan batas penggunaan yang sesuai.

## Izin perangkat

Android meminta internet, lokasi, dan kamera melalui manifest. Untuk membangun APK di Windows, siapkan JDK 17 atau lebih baru dan Android SDK command-line tools. iOS sudah memiliki deskripsi izin kamera, mikrofon, galeri, dan lokasi di `Info.plist`. Build iOS membutuhkan macOS dan Xcode. Sebelum rilis Android, ganti konfigurasi debug signing dengan keystore rilis milik proyek.
