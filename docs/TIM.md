# Panduan tim

Cara menjalankan Spots versi development di laptop masing-masing, tersambung ke Supabase yang sama, dan ikut memperbaiki kode tanpa saling menimpa.

## Persiapan (sekali saja)

1. **Pasang alat:**
   - [Git](https://git-scm.com/downloads)
   - [Flutter 3.47](https://docs.flutter.dev/get-started/install) (cek dengan `flutter --version`)
   - Google Chrome
   - [VS Code](https://code.visualstudio.com/) dengan ekstensi Flutter (disarankan)
2. **Terima undangan kolaborator** di https://github.com/MoriMoriMor/Proyek-Final-Moprog/invitations, lalu login dengan `gh auth login` (pilih HTTPS dan login lewat browser).
3. **Clone repo** di folder di luar OneDrive, misalnya `C:\Projects`:

   ```powershell
   cd C:\Projects
   git clone https://github.com/MoriMoriMor/Proyek-Final-Moprog.git
   cd Proyek-Final-Moprog
   ```

4. **Atur identitas Git** dengan nama dan email akun GitHub masing-masing:

   ```powershell
   git config user.name "Nama Kamu"
   git config user.email "email-github-kamu@example.com"
   ```

5. **Sambungkan ke Supabase.** Minta *Project URL* dan *publishable key* ke ketua tim lewat chat pribadi, lalu jalankan:

   ```powershell
   .\run setup
   ```

   Notepad akan terbuka. Tempel kedua nilai itu, simpan, lalu tutup. File `mobile\config.json` sengaja tidak masuk Git, jadi tiap orang membuatnya sendiri. Jangan pernah membagikan `service_role` key atau password database.

## Menjalankan versi terbaru

```powershell
git pull
.\run live
```

Chrome akan terbuka dengan aplikasi yang memakai data Supabase tim. Selama aplikasi berjalan:

| Tombol di terminal | Fungsi |
| --- | --- |
| `r` | Muat ulang setelah mengubah kode |
| `R` | Restart penuh |
| `q` | Keluar |

Mau coba tanpa menyentuh data tim? Pakai mode demo: `.\run`.

Untuk HP Android, sambungkan dengan kabel USB dan nyalakan *USB debugging*, lalu jalankan `flutter devices` untuk melihat ID-nya dan `.\run live ID-HP`.

## Alur kerja harian

Supaya kerjaan tidak saling menimpa, setiap perubahan dibuat di branch sendiri, lalu digabung lewat pull request.

1. **Ambil versi terbaru:**

   ```powershell
   git checkout main
   git pull
   ```

2. **Buat branch** dengan nama yang menjelaskan isinya:

   ```powershell
   git checkout -b perbaiki-tombol-simpan
   ```

3. **Ubah kode**, coba dengan `.\run live`, lalu cek sebelum commit:

   ```powershell
   cd mobile
   flutter analyze
   flutter test
   cd ..
   ```

4. **Commit dan push:**

   ```powershell
   git add -A
   git commit -m "Perbaiki tombol simpan di detail spot"
   git push -u origin perbaiki-tombol-simpan
   ```

5. **Buat pull request.** Buka repo di GitHub, klik **Compare & pull request**, tulis singkat apa yang diubah, lalu minta satu teman untuk review.
6. **Setelah disetujui, klik Merge.** Semua orang lalu menjalankan `git checkout main` dan `git pull` untuk mendapat versi terbaru.

Kalau `git pull` memunculkan konflik, jangan dipaksa. Tanyakan ke yang mengubah file yang sama, atau minta bantuan di grup.

## Mengubah database

Perubahan tabel, aturan akses, atau fungsi Supabase dibuat sebagai file baru di `supabase/migrations/` dengan awalan tanggal, misalnya `202611200001_nama_perubahan.sql`. Jangan mengubah file migrasi lama yang sudah dijalankan.

Setelah pull request-nya di-merge, satu orang yang punya akses dashboard menjalankan file itu di **SQL Editor**, lalu memberi kabar di grup. Uji lokalnya ada di [`supabase/tests`](../supabase/tests/README.md).

## Akses dashboard Supabase

Teman yang perlu melihat tabel, akun, atau log bisa diundang oleh pemilik proyek Supabase:

1. Buka **Organization settings → Team**.
2. Klik **Invite member**, isi email teman, lalu pilih peran **Developer**.

Peran Developer bisa membaca dan mengubah data di Table Editor tanpa bisa menghapus proyek atau mengubah tagihan.
