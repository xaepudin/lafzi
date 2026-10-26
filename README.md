# Lafzi

Lafzi membantu Anda menemukan ayat Al-Qur'an hanya dengan mengetikkan lafadz
seperti yang Anda dengar atau ucapkan — misalnya `allahu samad` — tanpa perlu
bisa menulis huruf Arab. Tersedia untuk Android, iOS, macOS, dan web.

**Coba sekarang:** <https://lafzi.pages.dev>

## Fitur

- **Cari dengan ejaan Latin.** Ketik lafadz sesuai pelafalan bahasa Indonesia;
  ejaan Arab yang tepat tidak diperlukan.
- **Cari dengan teks Arab.** Tempel atau ketik ayat dalam huruf Arab.
- **Cari dengan suara.** Ucapkan lafadz yang dicari (Android, iOS, macOS).
- **Terjemahan Indonesia** pada setiap hasil.
- **Sorotan kuning** pada bagian ayat yang cocok dengan pencarian.
- **Halaman detail** untuk seluruh 6.236 ayat, dengan tombol Sebelum/Berikut.
- **Bagikan** ayat sebagai teks atau gambar.
- **Contoh pencarian** yang bergantian di halaman awal, untuk inspirasi.
- **Panduan awal** yang menunjukkan kolom pencarian, tombol suara, dan daftar
  contoh; bisa diputar ulang dari menu.
- **Pengaturan**: perhitungkan huruf vokal, tampilkan terjemahan, dan tampilkan
  tingkat kesamaan pada hasil.
- **Tema terang dan gelap** dengan palet hijau khas Lafzi.
- **Bisa dipakai tanpa internet** di web, setelah halaman dibuka sekali.

## Cara mencari

1. Ketik lafadz pada kolom di bawah, misalnya `bismillah`, `allahu samad`, atau
   `yabunayya`.
2. Tekan tombol cari. Hasil diurutkan dari yang paling cocok; bagian yang cocok
   ditandai kuning.
3. Ketuk salah satu hasil untuk membuka halaman ayat, lalu gunakan tombol
   Sebelum/Berikut atau bagikan ayatnya.

Ingin mencari dengan suara? Ketuk ikon mikrofon di kanan atas, lalu ucapkan
lafadz yang dicari. Fitur ini belum tersedia di web.

## Di mana Lafzi bisa dipakai

| Platform | Cara mendapatkan | Catatan |
| --- | --- | --- |
| **Web** | <https://lafzi.pages.dev> | Tidak perlu memasang apa pun; bisa dibuka luring setelah sekali dibuka |
| **Android** | Unduh APK dari halaman [Releases](https://github.com/xaepudin/lafzi/releases) | Pilih APK sesuai perangkat: `arm64-v8a` untuk HP modern, `armeabi-v7a` untuk perangkat lama |
| **iOS** | `Lafzi-*-unsigned.ipa` dari Releases | Berkas ini belum ditandatangani, jadi perlu dipasang lewat aplikasi sideloading yang menandatangani ulang |
| **macOS** | `Lafzi-*.dmg` dari Releases | Belum dinotarisasi; saat pertama dibuka, izinkan lewat System Settings → Privacy & Security |

Aplikasi Android ini bisa dipasang berdampingan dengan aplikasi Lafzi Android
asli, karena keduanya memakai nama paket yang berbeda.

## Tips

- **Hasil kosong?** Pastikan lafadznya memang ada di dalam Al-Qur'an — bukan
  hadits, doa, atau nama surat. Coba juga ejaan lain, atau matikan
  *Perhitungkan huruf vokal* di Pengaturan agar pencarian lebih luas
  (`munafiqun` akan ikut menemukan `munafiqin`).
- **Hasil terlalu banyak?** Tambahkan kata lain pada pencarian.
- **Ingin melihat seberapa cocok hasilnya?** Aktifkan *Tampilkan tingkat
  kesamaan* di Pengaturan; persentase dan bilahnya muncul di setiap kartu hasil.
- **Pencarian suara** memerlukan koneksi internet pada sebagian perangkat,
  karena memakai layanan pengenalan suara bawaan sistem.
- **Di web**, ikon mikrofon diganti tautan ke kode sumber, karena dukungan
  pengenalan suara Arab di peramban belum konsisten.

## Lisensi dan kredit

Lafzi adalah perangkat lunak bebas di bawah **GNU General Public License v3.0**.
Teks lisensi lengkap ada di [LICENSE](LICENSE).

Proyek ini merupakan versi Flutter dari [Lafzi Android](https://github.com/lafzi/lafzi-android)
karya proyek Lafzi dan para kontributornya (Copyright © 2017–2019), termasuk
Alfat Saputra Harun dan Muhammad Abrari. Rincian perubahan, atribusi, dan
ketentuan aset pihak ketiga ada di [NOTICE](NOTICE) dan
[docs/licensing.md](docs/licensing.md).

Kode sumber: <https://github.com/xaepudin/lafzi>

## Untuk pengembang

Dokumentasi teknis dipindahkan ke folder `docs/`:

- [docs/development.md](docs/development.md) — menyiapkan lingkungan,
  menjalankan, membangun, dan menguji aplikasi.
- [docs/architecture.md](docs/architecture.md) — cara kerja pencarian Latin,
  pencarian Arab, pencarian suara, dan mode luring di web.
- [docs/deployment.md](docs/deployment.md) — Cloudflare Pages, GitHub Actions,
  secret yang diperlukan, dan cara merilis.
- [docs/licensing.md](docs/licensing.md) — lisensi, atribusi, dan kewajiban
  saat mendistribusikan ulang.

Masukan dan laporan bug sangat diterima lewat
[Issues](https://github.com/xaepudin/lafzi/issues).
