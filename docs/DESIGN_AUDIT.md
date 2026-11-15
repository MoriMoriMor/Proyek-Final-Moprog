# Audit desain dan sistem

Acuan: tiga referensi yang dipakai tim, yaitu aplikasi aktivitas luar ruang bernuansa lime dengan rombongan maskot, aplikasi kulkas pintar dengan stiker dan karakter 3D, dan aplikasi kencan bernuansa biru langit dengan tombol pil hitam. Tujuannya tetap sama: Spots terasa seru tapi rapi, dan mudah dipakai semua umur.

## Yang sudah diperbaiki

### Maskot

| Sebelum | Sesudah |
| --- | --- |
| Satu maskot (Piko), hanya naik-turun dan berkedip | Sepuluh maskot dengan peran jelas |
| Gambar SVG statis | Digambar dengan kode: bernapas, melirik ke kiri dan kanan, berkedip acak (kadang dua kali), melambai, melompat saat disentuh, dan mengikuti kursor di desktop |
| Ekspresi terbatas | Tujuh ekspresi: senang, tertawa, kaget, mengantuk, mengedip, jatuh cinta, kacamata keren |
| Garis luar gelap tebal dan pupil kecil terasa seram | Gaya datar tanpa garis luar, gradasi lembut, topeng wajah terang, mata besar dengan pupil abu tua ke tengah, kaki oranye seragam |

| Maskot | Peran |
| --- | --- |
| Piko | Pemandu utama, login, keadaan kosong umum |
| Mimi, Jojo, Gugu, Bobi, Tika, Tote, Rumi | Satu untuk tiap kategori |
| Pino | Peta dan tautan |
| Cici | XP, misi, level, streak |

Tempat maskot muncul: onboarding, sapaan di Beranda, halaman detail, Reels, Peta, Market, halaman toko, status pesanan (berubah sesuai status), keadaan kosong, perayaan, dan kartu bagikan. Semua gerak berhenti jika perangkat meminta gerak minimal.

### Kategori

Tiga kategori lama terlalu sempit, sementara daftar lengkap (12+) membingungkan. Hasil audit: **7 kategori besar**, masing-masing dengan contoh singkat di bawahnya. Pemilih kategori memakai ikon supaya ringkas; tiap kategori tetap punya maskot pendamping di halaman detail, Reels, dan perayaan.

| Kategori | Mencakup |
| --- | --- |
| Kuliner | Resto, warung, jajanan, street food |
| Nongkrong | Kafe, taman, rooftop, spot sunset |
| Wisata | Alam, pantai, museum, seni & budaya |
| Olahraga | Lapangan, skatepark, jogging track, gym |
| Aktivitas | Workshop, karaoke, arcade, kelas |
| Belanja | Thrift, pasar, toko lokal, oleh-oleh |
| Menginap | Glamping, villa, homestay |

Kunci di database `kafe` dan `destinasi` tidak diganti supaya data lama tetap cocok. Migrasi `202611160001_categories.sql` memperluas aturan kategori dan memindahkan toko berkategori `lainnya` ke `belanja`.

### Tampilan dan keterjangkauan

| Temuan | Perbaikan |
| --- | --- |
| Navbar hanya memberi label pada tab aktif, membingungkan pengguna baru dan orang tua | Semua tab selalu berlabel |
| Ukuran huruf sistem yang besar bisa merusak tata letak | Tetap dihormati, dibatasi sampai 1,3× |
| Beranda terasa datar di bagian atas | Gradasi lembut di latar, sapaan sesuai waktu, dan Piko melambai |
| Tidak ada perkenalan aplikasi | Onboarding 3 layar dengan rombongan maskot dan tombol pil hitam |
| Kartu "Lagi viral" kurang menonjol | Stiker HOT pada peringkat 1 |
| Label kategori bisa terpotong | Lebar kartu disesuaikan |

### Sistem berbagi

Supaya mudah viral, setiap hal yang menarik bisa dibagikan dalam dua ketukan:

- **Spot:** tombol bagikan di kartu feed, detail, dan Reels.
- **Toko:** tombol di halaman toko.
- **Ajak teman:** kartu "Ajak squad-mu" di Profil, berisi kode undangan dari ID akun.
- **Pencapaian:** tombol "Pamerin" di Profil dan di perayaan naik level atau streak.

Lembar bagikan selalu menampilkan pratinjau **kartu story 9:16** yang dirender jadi gambar PNG, siap untuk Instagram Story atau WhatsApp. Pilihannya: kirim gambar, salin link, atau bagikan teks. Membagikan memberi XP, dan ada misi harian "Bagikan 1 spot".

Tautan berbentuk `https://spots.app/s/<id>` (spot), `/t/<id>` (toko), dan `/i/<kode>` (undangan). Domainnya bisa diganti lewat `--dart-define=SHARE_BASE_URL=...`. Versi web langsung membuka spot, toko, atau undangan dari tautan tersebut. Orang yang datang lewat undangan mendapat bonus XP satu kali.

## Yang masih terbuka

1. **Domain dan deep link ponsel.** Tautan baru bisa dibuka langsung di versi web. Agar tautan membuka aplikasi Android/iOS, tim perlu domain sendiri, file `assetlinks.json` dan `apple-app-site-association`, serta konfigurasi intent filter dan associated domains.
2. **Undangan belum tercatat di server.** Kode undangan dan bonus XP baru disimpan di perangkat. Untuk hadiah pengundang atau papan peringkat, perlu tabel `invites` dan fungsi klaim di Supabase.
3. **Statistik berbagi.** Jumlah share per spot belum disimpan. Ini berguna untuk peringkat "Lagi viral".
4. **XP dan streak antar perangkat.** Masih tersimpan lokal. Pindahkan ke Supabase jika ingin papan peringkat antar teman.
5. **Uji perangkat nyata.** Animasi maskot, render gambar share, dan lembar bagikan bawaan perlu dicoba di Android dan iPhone sungguhan, termasuk HP kelas bawah untuk mengecek kelancaran animasi.
6. **Uji keterbacaan.** Coba dengan beberapa pengguna di luar tim (termasuk orang tua) untuk memastikan label, ukuran tombol, dan alur pesanan mudah dipahami.
