# Arsitektur

Catatan teknis tentang cara kerja Lafzi. Untuk menyiapkan lingkungan build lihat
[development.md](development.md).

## Database

Database dihasilkan oleh proyek
[`lafzi-indexer`](https://github.com/lafzi/lafzi-indexer): teks Tanzil diubah
menjadi kode fonetis, diindeks, lalu diekspor ke SQLite.

`assets/databases/lafzi.sqlite` dibundel sebagai aset dan disalin ke direktori
database aplikasi pada peluncuran pertama (atau saat versi aset berubah).
Database dibuka secara read-only.

Di web tidak ada penyalinan ke disk: aset diunduh, ditulis ke virtual file
system SQLite di memori, lalu dibuka read-only. Splash menutupi proses ini dan
database dimuat ulang pada setiap pemuatan halaman. Karena database bersifat
statis dan read-only, tidak ada data pengguna yang perlu disimpan di browser
selain pengaturan dan status panduan (`shared_preferences`).

Tabel utama:

| Tabel | Isi |
| --- | --- |
| `ayat_quran` | 6.236 ayat: nomor surat, nama surat, nomor ayat, teks Arab, terjemahan Indonesia |
| `vocal_index` | Posting trigram untuk pencarian yang memperhitungkan huruf vokal |
| `nonvocal_index` | Posting trigram untuk pencarian tanpa huruf vokal |
| `quran_text` | Tabel FTS4 untuk pencarian teks Arab |
| `quran_text_*` | Tabel bayangan FTS4 (`content`, `segments`, `segdir`, `docsize`, `stat`) |

## Pencarian Latin

Pencarian Latin menormalkan kueri, memecahnya menjadi trigram, mengambil posting
dari `vocal_index`/`nonvocal_index`, lalu memeringkat dokumen dengan skor
kecocokan trigram dan kedekatan posisi. `vocal_mapping_position` dan
`nonvocal_mapping_position` memetakan posisi fonetis ke indeks karakter Arab,
sama seperti versi Android, sehingga penanda hasil menunjuk karakter yang benar.

Persentase relevansi yang ditampilkan sama dengan persentase pada web Lafzi
asli; misalnya `allahu samad` menghasilkan 100%, 79%, dan 47%.

Implementasi Dart diuji terhadap keluaran referensi Java untuk banyak kueri:
jumlah hasil, urutan dokumen, skor, dan rentang highlight identik.

## Pencarian Arab

Pencarian Arab memakai `MATCH` pada tabel FTS4, lalu memetakan offset hasil
kembali ke teks ayat untuk penanda. Karena build `sqlite3` bawaan hanya memuat
FTS5, `web/sqlite3.wasm` dibangun khusus dengan FTS3/FTS4 — lihat
`tool/build_sqlite3_wasm.sh`.

## Pencarian suara

- **Android** memakai `RecognizerIntent` sistem (jalur yang sama dengan versi
  Java), lewat method channel `com.xaepudin.lafzi/speech` di `MainActivity.kt`.
- **iOS dan macOS** memakai paket `speech_to_text` dengan locale Arab pertama
  yang didukung perangkat (`ar-AE`, `ar-SA`, `ar-EG`, lalu locale `ar*`
  lainnya).
- **Web** tidak menampilkan tombol suara. Implementasinya tetap ada di balik
  `PlatformCapabilities.voiceSearch`, tetapi `speech_to_text` memakai Web Speech
  API yang dukungan locale Arab-nya tidak konsisten antarperamban. Bila nanti
  diaktifkan lagi, halaman harus disajikan lewat HTTPS atau `localhost`, dan
  panduan/bantuan akan otomatis menampilkan langkah suara kembali.

Aplikasi meminta izin mikrofon dan pengenalan suara. Selama sesi berjalan,
banner "Mendengarkan…" tampil di atas kolom pencarian dan dapat diketuk untuk
berhenti. Jika sesi gagal, aplikasi membedakan izin ditolak, layanan tidak
tersedia, dan mikrofon gagal, lalu menampilkan pesan yang sesuai.

Pengenalan suara Apple memerlukan koneksi internet kecuali perangkat mendukung
pengenalan luring. Di Simulator iOS, audio input harus aktif (I/O → Audio Input)
dan Simulator harus diizinkan memakai mikrofon Mac; tanpa itu sesi berhenti
dengan pesan gagal, bukan hasil kosong.

## Mode luring (web)

`web/sw.js` adalah service worker sendiri, terpisah dari
`flutter_service_worker.js` bawaan Flutter (yang hanya mencabut registrasi
lama). `web/flutter_bootstrap.js` mematikan pendaftaran service worker Flutter
agar keduanya tidak berebut satu scope yang sama.

- Saat instalasi, service worker menyimpan kerangka aplikasi (HTML, bootstrap,
  manifest, ikon). Berkas lain disimpan saat halaman yang sudah dikendalikan
  memintanya, jadi tidak ada daftar aset yang perlu disinkronkan dengan hasil
  build.
- `index.html` baru memuat Flutter setelah service worker mengendalikan
  halaman, sehingga kunjungan pertama pun sudah mengisi cache. Dengan begitu
  aplikasi bisa dibuka luring setelah sekali dibuka saat daring.
- Database (16 MB) disimpan di cache terpisah. Perubahan deploy dideteksi lewat
  ETag `main.dart.js` (kerangka diambil ulang) dan ETag `lafzi.sqlite`
  (database diambil ulang), jadi tidak perlu menaikkan versi cache manual.
- Ukuran cache setelah sekali kunjungan sekitar 25 MB (16 MB database, sisanya
  CanvasKit dan kode aplikasi).
- Bila service worker gagal dipasang, halaman tetap memuat aplikasi seperti
  biasa setelah 4 detik; mode luring saja yang tidak aktif.
- Service worker butuh HTTPS (atau `localhost`); Cloudflare Pages sudah
  memenuhinya.

## Berbagi dan unduh gambar

Berbagi memakai Web Share API di web (di macOS Chrome/Safari tampil sebagai
lembar berbagi sistem), dan tombol "Unduh gambar" mengunduh JPEG langsung karena
lembar sistem tidak selalu menyediakan opsi simpan. Di Android/iOS tombol yang
sama membuka dialog simpan sistem, sedangkan di macOS file masuk ke folder
Downloads.
