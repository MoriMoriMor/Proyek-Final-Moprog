# Audit desain dan sistem

## Pembaruan lanjutan 25 November 2026 — Kaca buram, foto nyata, maskot, dan pengamanan

- **Identitas logo & ikon seragam**: lambang Spots diperbarui dengan gradien biru-langit, tepi dalam bercahaya lembut, jalur rute putih dengan pin kuning dan koral, serta diekspor seragam ke SVG (`logo.svg`, `logo_light.svg`, `app_icon.svg`), ikon adaptif Android, ikon web (`Icon-192`, `Icon-512`, maskable, favicon), dan `app_icon.ico` Windows.
- **Lapisan kaca buram (frosted glass) fungsional**: komponen `FrostedSurface` memakai blur latar + garis tepi putih tipis pada bilah navigasi bawah, kartu apung peta, stiker kategori di atas foto, dan pil pengalih halaman tempat. Saat *reduced motion* aktif, blur dimatikan otomatis dan latar memakai permukaan putih pekat berkontras tinggi.
- **Halaman sambutan & web yang hangat dengan foto nyata**: latar gelap diganti kanvas langit terang (`#D6E6FF` → `#EEF4FF` → `#FFFFFF`) dengan foto dokumentasi nyata berlisensi terbuka dari Wikimedia Commons (`kuliner.jpg`, `nongkrong.jpg`, `taman.jpg`, `sate.jpg`) agar terasa jujur, netral, dan manusiawi tanpa klaim atau angka buatan.
- **Animasi pemuatan merek (`SpotsLogoLoader`)**: pembuka web (`mobile/web/index.html`) dan pemuatan awal beranda menampilkan kapsul kaca dengan lambang dan tulisan Spots yang bergerak halus, serta berhenti otomatis saat *reduced motion* aktif.
- **Maskot kenyal 3D & gerak ikutan**: seluruh 10 maskot diberi pantulan kapsul kiri-atas, pipi merona dengan titik kilau, mata biru-tua dengan dua pantulan cahaya, serta jeda fase (*follow-through*) pada telinga, lengan, dan atribut saat bernapas maupun melompat.
- **Optimasi tempat, media bersama, & keamanan pesanan**: pencarian nama tempat terdekat saat mengetik judul unggahan, penggabungan otomatis tempat bernama identik dalam radius 65 m (`resolve_or_create_place`), pembersihan tempat yatim bila unggah gagal, tab **Galeri bersama** untuk menelusuri seluruh foto/video pengunjung berdasarkan `viral_score`, indeks komposit database, serta pengamanan `place_order` dari integer overflow, akun terblokir, dan antrean pesanan berlebih.

## Pembaruan 25 November 2026

Antarmuka memakai identitas Spots yang sama, dengan fokus lebih besar pada tempat, foto, dan tindakan yang bisa dilakukan. Bagel dipakai untuk judul utama; judul bagian memakai Nunito agar daftar konten lebih mudah dipindai. Latar biru dan krem diberi garis lingkaran seperti peta. Warna kategori tetap ada pada ikon.

| Area | Temuan | Perubahan |
| --- | --- | --- |
| Beranda | Kartu level bersaing dengan tempat yang ingin ditemukan | Konten viral dan toko muncul lebih dulu; misi harian tetap bisa dibuka dari kartu level dan streak |
| Penemuan tempat | Akses peta hanya berupa ikon | Ada tindakan berlabel “Buka peta sekitar” di sapaan beranda |
| Feed | Semua kartu dibuat sekaligus | Daftar memakai sliver yang membangun baris sesuai viewport, satu kolom di HP dan dua kolom saat ruang cukup |
| Izin lokasi | Feed menunggu jawaban GPS sebelum mengambil konten | Tempat populer dimuat segera; hasil terdekat diperbarui setelah lokasi tersedia |
| Reaksi | Kartu yang dibuat ulang perlu membawa status suka terbaru | Hasil reaksi memperbarui model spot di feed, tanpa mengambil ulang seluruh daftar untuk setiap suka |
| Kategori | Setiap pilihan memakai warna dan bayangan yang sama kuat | Pilihan aktif memakai biru Spots; warna kategori menjadi aksen ikon |
| Kartu | Banyak garis tebal dan bayangan keras | Garis permukaan ditipiskan dan bayangan kartu disatukan |
| Market | Lebar toko mengikuti ukuran layar keseluruhan | Kolom mengikuti ruang konten yang benar-benar tersedia, termasuk saat sidebar terbuka |
| Media | Foto besar didekode penuh pada thumbnail | `SpotImage` menyesuaikan lebar decode dengan layar, dibatasi 1600 px, dengan fade setelah frame tersedia |
| Avatar | Fallback foto dapat merujuk kembali ke widget gambar | Kegagalan foto langsung menampilkan inisial |
| Video | Kegagalan pemuatan berakhir dengan indikator tanpa akhir | Ada status video tidak tersedia; pemutar Reels dijeda saat halaman tidak aktif atau aplikasi di latar |
| Desktop | Kontrol kustom mengandalkan klik | Tombol dan kartu interaktif mendukung Tab, Enter, Space, kursor, serta garis fokus |
| Aksesibilitas | Beberapa gerak dekoratif tetap berulang | Shimmer, maskot, penanda lokasi, petunjuk geser, dan pembuka mengikuti reduced motion |

### Gerak dan pemuatan

- Respons tombol memakai 140 ms; pergantian konten 280 ms; kemunculan kartu 380 ms.
- Jeda antar kartu 35 ms, dibatasi empat langkah supaya daftar panjang tetap cepat digunakan.
- Latar muncul selama 900 ms lalu berhenti. Gerak tidak dijadikan syarat untuk membaca atau memakai kontrol.
- Saat tab berganti, konten lama tidak menerima sentuhan atau fokus pembaca layar dan tickernya dihentikan selama keluar.
- Foto mempertahankan bidangnya saat dimuat. Gambar, maskot, dan latar yang bergerak dicat terpisah dari konten sekitarnya.
- Web menampilkan logo dan indikator ringan sebelum frame Flutter pertama, sehingga pengguna mendapat respons saat aplikasi mulai dimuat.
- Petunjuk Reels dilepas setelah selesai. Tombol belanja memberi gerak pengenal satu kali.
- Pilihan warna teks tombol dihitung dari luminans agar memenuhi rasio kontras 4,5 banding 1 terhadap warna tombol.

### Pemeriksaan

Audit ukuran mencakup layar masuk, setup, enam tab utama, detail spot dan tempat, pencarian teman, rute, unggah, profil, toko, keranjang, pesanan, pengajuan toko, penjual, admin, autentikasi, dan misi. Matriksnya memakai 12 ukuran dari 320 px sampai 1920 px, termasuk landscape, dengan skala teks 1 dan 1,3.

Tes layout memakai font aplikasi yang sebenarnya dan menggagalkan pemeriksaan bila laporan overflow berisi temuan. Tes tambahan memeriksa kontrol keyboard, reduced motion, kontras tombol, serta status suka setelah kartu dibuat ulang. Pratinjau Beranda, Market, dan Profil diperiksa pada lebar 390 px dan 1440 px.

Hasil pemeriksaan 25 November 2026 dengan Flutter 3.47.2 dan Dart 3.13.2

- `flutter analyze --no-pub` bersih.
- `flutter test --no-pub` meloloskan 84 tes, termasuk audit layout. Laporan `build/layout_audit.txt` kosong, dengan 0 overflow.
- Build web rilis berhasil. Pembuka web, feed tamu tanpa menunggu izin lokasi, dan navigasi Market diperiksa langsung di browser, termasuk lebar 390 px.
- Tes regresi membuktikan feed tetap dimuat saat permintaan izin lokasi belum dijawab dan status suka bertahan setelah kartu dibuat ulang.

Kelancaran frame, penggunaan memori, konsumsi baterai, dan jaringan lambat tetap perlu diukur di Android dan iPhone fisik. Build web dan widget test memberi bukti kompilasi serta tata letak, sementara pengukuran perangkat diperlukan untuk menetapkan batas performa rilis.

Pemeriksaan manual VoiceOver dan TalkBack masih diperlukan, terutama label pada kontrol yang bertingkat. Build web juga masih mengeluarkan peringatan keluarga font ikon Cupertino bawaan Flutter; ikon antarmuka Spots memakai SVG sendiri. Peringatan ini perlu diperiksa saat menguji widget sistem di iOS.

---

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

Tempat maskot muncul: halaman sambutan, sapaan di Beranda, halaman detail, Reels, Peta, Market, halaman toko, status pesanan (berubah sesuai status), keadaan kosong, perayaan, dan kartu bagikan. Semua gerak berhenti jika perangkat meminta gerak minimal.

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
| Tidak ada perkenalan aplikasi | Halaman sambutan bergaya kolase dengan tombol Google dan email |
| Kartu "Lagi viral" kurang menonjol | Stiker HOT pada peringkat 1 |
| Label kategori bisa terpotong | Lebar kartu disesuaikan |

### Sistem berbagi

Supaya mudah viral, setiap hal yang menarik bisa dibagikan dalam dua ketukan:

- **Spot:** tombol bagikan di kartu feed, detail, dan Reels.
- **Toko:** tombol di halaman toko.
- **Ajak teman:** kartu "Ajak squad-mu" di Profil, berisi kode undangan dari ID akun.
- **Pencapaian:** tombol "Pamerin" di Profil dan di perayaan naik level atau streak.

Lembar bagikan selalu menampilkan pratinjau **kartu story 9:16** yang dirender jadi gambar PNG, siap untuk Instagram Story atau WhatsApp. Pilihannya: kirim gambar, salin link, atau bagikan teks. Membagikan memberi XP, dan ada misi harian "Bagikan 1 spot".

Tautan berbentuk `https://morimorimor.github.io/Proyek-Final-Moprog/s/<id>` (spot), `/t/<id>` (toko), `/u/<username>` (profil), dan `/i/<kode>` (undangan). Kalau dibuka di browser, tautan ini disambut halaman Spots di `site/404.html`. Domainnya bisa diganti lewat `--dart-define=SHARE_BASE_URL=...`. Versi web langsung membuka spot, toko, atau undangan dari tautan tersebut. Orang yang datang lewat undangan mendapat bonus XP satu kali.

## Yang masih terbuka

1. **Domain dan deep link ponsel.** Tautan baru bisa dibuka langsung di versi web. Agar tautan membuka aplikasi Android/iOS, tim perlu domain sendiri, file `assetlinks.json` dan `apple-app-site-association`, serta konfigurasi intent filter dan associated domains.
2. **Undangan belum tercatat di server.** Kode undangan dan bonus XP baru disimpan di perangkat. Untuk hadiah pengundang atau papan peringkat, perlu tabel `invites` dan fungsi klaim di Supabase.
3. **Statistik berbagi.** Jumlah share per spot belum disimpan. Ini berguna untuk peringkat "Lagi viral".
4. **XP dan streak antar perangkat.** Masih tersimpan lokal. Pindahkan ke Supabase jika ingin papan peringkat antar teman.
5. **Uji perangkat nyata.** Animasi maskot, render gambar share, dan lembar bagikan bawaan perlu dicoba di Android dan iPhone sungguhan, termasuk HP kelas bawah untuk mengecek kelancaran animasi.
6. **Uji keterbacaan.** Coba dengan beberapa pengguna di luar tim (termasuk orang tua) untuk memastikan label, ukuran tombol, dan alur pesanan mudah dipahami.
