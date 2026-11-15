# Spots Mobile

Aplikasi Flutter untuk Android, iOS, dan web. Backend memakai Supabase Auth, Postgres, dan Storage.

## Menjalankan

1. Buat proyek Supabase dan jalankan [migrasi SQL](../supabase/migrations/202610050001_spots.sql) di SQL Editor.
2. Salin `config.example.json` ke `config.json`. Isi Project URL dan publishable key dari halaman **Connect** di dashboard Supabase.
3. Jalankan perintah berikut dari folder `mobile`.

```bash
flutter pub get
flutter run --dart-define-from-file=config.json
```

Untuk browser: `flutter run -d chrome --dart-define-from-file=config.json`.

Belum punya proyek Supabase? Jalankan mode demo. Datanya contoh dan cuma tersimpan di memori:

```bash
flutter run --dart-define=SPOTS_DEMO=true
```

Tanpa `config.json`, layar awal juga menampilkan tombol **Coba mode demo**.

`config.json` tidak masuk Git. Kunci `service_role` dan password database tidak boleh diletakkan di aplikasi.

## Fitur

- Feed tempat dekat pengguna dalam radius 20 km dan jelajah tempat populer di kota lain.
- Postingan berisi sampai lima foto atau video, lokasi GPS, cerita, dan kategori.
- Peta dengan pin, rating, suka, komentar, serta tautan petunjuk arah.
- Akun, komentar, rating, suka, simpan, dan daftar cerita pribadi.
- Data dapat diperiksa langsung dari Supabase Dashboard melalui Table Editor, Authentication, dan Storage.

Lihat [panduan setup Supabase](../docs/FLUTTER_SUPABASE.md) untuk rincian tabel, Storage, dan izin perangkat.

## Tampilan

Komponen visual ada di `lib/ui/`:

| Berkas | Isi |
| --- | --- |
| `theme.dart` | Warna, kategori, dan gaya teks (Nunito untuk isi, Bagel Fat One untuk judul) |
| `spot_icons.dart` | Ikon Spots yang digambar sendiri dalam SVG |
| `piko.dart` | Piko, maskot yang bisa berkedip dan berganti ekspresi |
| `motion.dart` | Tombol tebal, efek pantul, animasi muncul, skeleton, dan konfeti |
| `widgets.dart` | Stiker kategori, avatar, keadaan kosong, dan pesan galat |

Animasi otomatis dikurangi jika pengaturan aksesibilitas perangkat meminta gerak minimal. Font memakai lisensi SIL Open Font License.

