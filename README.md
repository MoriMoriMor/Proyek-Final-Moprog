# Spots

*Spots to Go to before we Die.* Tempat berbagi rekomendasi warung, kafe, dan tujuan jalan-jalan dari pengalaman orang lain. Tiap cerita punya foto atau video, titik lokasi, dan obrolan kecil di bawahnya.

Aplikasinya dibangun dengan **Flutter** untuk Android dan iOS (bisa juga dibuka di browser dan desktop). Akun, data, dan media disimpan di **Supabase**.

## Fitur

- Feed tempat dalam radius 20 km. Kalau lokasi belum diizinkan, yang muncul tempat populer.
- Jelajah per kategori (kuliner, kafe, destinasi) dan cari berdasarkan nama tempat atau kota.
- Peta dengan pin per kategori dan kartu yang bisa digeser.
- Unggah 1–5 foto atau video, tulis cerita, lalu tandai titiknya di peta.
- Suka, simpan, komentar, dan kasih bintang setelah masuk.
- Reels layar penuh: geser ke atas, ketuk dua kali untuk suka, tombol belanja kalau tempatnya punya toko.
- Streak harian, XP, level, dan misi harian.
- Market: daftar toko dengan persetujuan admin, katalog, keranjang satu toko, ambil atau kirim, dan konfirmasi bayar manual.
- Profil berisi spot sendiri, simpanan, pesanan, dan dashboard toko.

## Struktur

| Folder | Isi |
| --- | --- |
| [`mobile/`](mobile) | Aplikasi Flutter |
| [`supabase/`](supabase) | Migrasi SQL (spot dan marketplace), RLS, fungsi, dan uji lokal |
| [`docs/`](docs) | Panduan setup Supabase |

## Menjalankan

```bash
cd mobile
flutter pub get
flutter run --dart-define=SPOTS_DEMO=true
```

Perintah di atas memakai data contoh. Untuk data asli, siapkan proyek Supabase lewat [panduan setup](docs/FLUTTER_SUPABASE.md), isi `mobile/config.json`, lalu jalankan `flutter run --dart-define-from-file=config.json`.
