# Lisensi dan atribusi

## Lisensi proyek

Lafzi dilisensikan di bawah **GNU General Public License v3.0** (GPL-3.0). Teks
lengkap ada di [`LICENSE`](../LICENSE).

## Karya asal

Versi Flutter ini adalah **port (karya turunan) dari Lafzi Android**:

- Nama: Lafzi Android — <https://github.com/lafzi/lafzi-android>
- Hak cipta: Copyright (C) 2017–2019 proyek Lafzi dan para kontributornya,
  termasuk Alfat Saputra Harun dan Muhammad Abrari.
- Lisensi: GPL-3.0 (sama dengan proyek ini).
- Lafzi Android sendiri didasarkan pada hasil penelitian skripsi Departemen
  Ilmu Komputer, Fakultas MIPA, Institut Pertanian Bogor.

Aplikasi ini bukan aplikasi asli, dan para penulis asli tidak bertanggung jawab
atas perubahan yang dibuat di sini. Rincian perubahan ada di [`NOTICE`](../NOTICE).

## Karya turunan

- Nama: Lafzi — <https://github.com/xaepudin/lafzi>
- Versi web: <https://lafzi.pages.dev>
- Hak cipta: Copyright (C) 2026 Asep Saepudin.
- Perubahan (Oktober 2026): ditulis ulang dari Java/Android ke Dart/Flutter,
  ditambah target iOS/macOS/web, logika pencarian dan pemeringkatan
  diimplementasikan ulang di Dart dan diuji terhadap implementasi Java asli,
  akses SQLite ditulis ulang, serta UI, pengaturan, panduan awal, berbagi
  gambar, dan pencarian suara di iOS/macOS dibuat baru.

## Kewajiban saat mendistribusikan

Siapa pun yang menerima versi biner aplikasi ini berhak mendapatkan source
code-nya. Jika Anda membagikan APK/IPA/build web, sertakan tautan ke
<https://github.com/xaepudin/lafzi> (atau tawarkan source code-nya) di deskripsi
toko aplikasi maupun di layar **Tentang** di dalam aplikasi.

Source code tidak boleh dilisensikan ulang dengan lisensi yang lebih ketat:
karya turunan GPL-3.0 harus tetap GPL-3.0.

## Aset pihak ketiga

Aset berikut dibundel dari proyek asal dan memiliki ketentuan masing-masing:

| Aset | Keterangan |
| --- | --- |
| `assets/databases/lafzi.sqlite` | Teks Al-Qur'an, terjemahan Indonesia, dan indeks pencarian dari Lafzi Android. Sumber dan ketentuan terjemahan belum terdokumentasi; pastikan sebelum mendistribusikan ulang. |
| `assets/fonts/me_quran.ttf` | "Me Quran" oleh Meor Ridzuan: *"Typeface and data © 2005, Meor Ridzuan. Free for non commercial use."* Lisensi ini tidak kompatibel dengan GPL-3.0 dan membatasi distribusi, sehingga font ini perlu diganti — misalnya dengan font berlisensi OFL seperti Amiri, Scheherazade New, atau KFGQPC Uthmanic Hafs — sebelum distribusi publik. |
| `assets/images/logo_lafzi_small.png`, `assets/images/app_icon.png` | Logo dan ikon dari proyek Lafzi Android. |
| `assets/images/github_mark.png` | Logo GitHub (Octocat), merek dagang GitHub, Inc., dipakai untuk menautkan ke repositori sumber. |

Untuk detail perubahan dan atribusi lengkap lihat [`NOTICE`](../NOTICE).
