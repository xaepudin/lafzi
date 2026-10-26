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

## Sumber data

Basis data `lafzi.sqlite` dibangun dengan
[`lafzi/lafzi-indexer`](https://github.com/lafzi/lafzi-indexer) — proyek PHP yang
mengubah teks Al-Qur'an menjadi kode fonetis, mengindeksnya, lalu mengekspor ke
SQLite. Repositori itu menyatakan GPL-3.0 di README-nya, meskipun tidak memuat
berkas LICENSE tersendiri. Proyek tersebut mengolah dua sumber:

- **Teks Al-Qur'an (rasm Utsmani)** dari [tanzil.net](https://tanzil.net), yang
  memiliki ketentuan penggunaan tersendiri; cantumkan atribusi Tanzil bila
  mendistribusikan ulang teksnya.
- **Terjemahan Indonesia** dari `data/trans-indonesian.txt` di repositori yang
  sama. Isinya sesuai terjemahan Kementerian Agama; berkas tersebut tidak
  memuat keterangan lisensi, jadi sumber dan ketentuannya perlu dipastikan
  sebelum distribusi ulang.

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
| `assets/databases/lafzi.sqlite` | Dibangun dengan `lafzi-indexer` (GPL-3.0) dari teks Tanzil dan terjemahan Indonesia; lihat [Sumber data](#sumber-data). |
| `assets/fonts/me_quran.ttf` | "Me Quran" oleh Meor Ridzuan: *"Typeface and data © 2005, Meor Ridzuan. Free for non commercial use."* Lisensi ini tidak kompatibel dengan GPL-3.0 dan membatasi distribusi, sehingga font ini perlu diganti — misalnya dengan font berlisensi OFL seperti Amiri, Scheherazade New, atau KFGQPC Uthmanic Hafs — sebelum distribusi publik. |
| `assets/images/logo_lafzi_small.png`, `assets/images/app_icon.png` | Logo dan ikon dari proyek Lafzi Android. |
| `assets/images/github_mark.png` | Logo GitHub (Octocat), merek dagang GitHub, Inc., dipakai untuk menautkan ke repositori sumber. |

Untuk detail perubahan dan atribusi lengkap lihat [`NOTICE`](../NOTICE).
