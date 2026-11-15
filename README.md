# Spots

*Spots.* Tempat berbagi rekomendasi warung, kafe, dan tujuan jalan-jalan dari pengalaman orang lain. Tiap cerita punya foto atau video, titik lokasi, dan obrolan kecil di bawahnya.

Aplikasinya dibangun dengan **Flutter** untuk Android dan iOS (bisa juga dibuka di browser dan desktop). Akun, data, dan media disimpan di **Supabase**.

## Fitur

- Feed tempat dalam radius 20 km. Kalau lokasi belum diizinkan, yang muncul tempat populer.
- Tujuh kategori: Kuliner, Nongkrong, Wisata, Olahraga, Aktivitas, Belanja, dan Menginap. Bisa juga cari berdasarkan nama tempat atau kota.
- Peta dengan pin per kategori dan kartu yang bisa digeser.
- Unggah 1–5 foto atau video, tulis cerita, lalu tandai titiknya di peta.
- Suka, simpan, komentar, dan kasih bintang setelah masuk.
- Reels layar penuh: geser ke atas, ketuk dua kali untuk suka, tombol belanja kalau tempatnya punya toko.
- Streak harian, XP, level, dan misi harian.
- Sepuluh maskot hidup yang menemani tiap kategori dan momen penting.
- Bagikan spot, toko, undangan, dan pencapaian sebagai kartu story bergambar atau link.
- Market: daftar toko dengan persetujuan admin, katalog, keranjang satu toko, ambil atau kirim, dan konfirmasi bayar manual.
- Masuk dengan Google atau email.
- Profil ala Instagram: foto, username, bio, pengikut, grid spot, peta spot, tag teman, dan @mention.
- Profil juga berisi simpanan, pesanan, dan dashboard toko.

## Struktur

| Folder | Isi |
| --- | --- |
| [`mobile/`](mobile) | Aplikasi Flutter |
| [`supabase/`](supabase) | Migrasi SQL (spot dan marketplace), RLS, fungsi, dan uji lokal |
| [`site/`](site) | Halaman konfirmasi email dan tautan bagikan (GitHub Pages) |
| [`docs/`](docs) | Panduan setup Supabase dan [audit desain](docs/DESIGN_AUDIT.md) |

## Menjalankan

Butuh [Flutter](https://docs.flutter.dev/get-started/install) 3.47 dan Chrome. Dari folder repo:

| Perintah | Windows | macOS/Linux |
| --- | --- | --- |
| Mode demo (data contoh) | `.\run` | `./run.sh` |
| Data Supabase | `.\run live` | `./run.sh live` |
| Buat `config.json` | `.\run setup` | `./run.sh setup` |
| HP atau emulator | `.\run demo <ID>` | `./run.sh demo <ID>` |

ID perangkat bisa dilihat dengan `flutter devices`. Selama aplikasi berjalan, tekan `r` untuk memuat ulang dan `q` untuk keluar.

Untuk anggota tim: ikuti [panduan tim](docs/TIM.md) untuk menyambungkan ke Supabase dan alur branch serta pull request.

Mode `live` butuh `mobile/config.json`. Cara cepat membuatnya: `.\run setup` (Windows) atau `./run.sh setup`. Siapkan proyek Supabase lewat [panduan setup](docs/FLUTTER_SUPABASE.md), salin `mobile/config.example.json` menjadi `mobile/config.json`, lalu isi URL dan publishable key. File ini tidak masuk Git, jadi tiap anggota tim membuatnya sendiri.
