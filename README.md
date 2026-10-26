# Lafzi

Lafzi adalah aplikasi pencari lafadz pada Al-Qur'an untuk Android, iOS, macOS,
dan web.
Aplikasi ini mendukung pencarian memakai aksara Latin berdasarkan pelafalan
bahasa Indonesia, pencarian teks Arab, serta pencarian suara. Proyek ini adalah
versi Flutter dari aplikasi Android Lafzi, dengan perilaku pencarian, database,
font, dan tampilan yang dipertahankan.

- Versi web: <https://lafzi.pages.dev>
- Source code: <https://github.com/xaepudin/lafzi>

## Fitur

- Pencarian lafadz Latin dengan dua mode: memperhitungkan huruf vokal atau
  mengabaikannya. Normalisasi fonetis dan pemeringkatan relevansi diporting
  langsung dari implementasi Android.
- Pencarian teks Arab memakai tabel FTS4 `quran_text` yang dibundel di database.
- Tombol kembali di app bar saat pencarian aktif; menekannya membersihkan
  kueri dan hasil, sama seperti tombol back sistem.
- Hasil berupa kartu ayat dengan penanda kuning pada bagian yang cocok,
  terjemahan Indonesia, dan penghitung hasil. Untuk hasil pencarian Latin,
  persentase relevansi (tingkat kesamaan) beserta bilah progres dapat
  ditampilkan lewat Pengaturan; defaultnya mati. Angka relevansi sama dengan
  persentase pada web Lafzi asli (misalnya `allahu samad`: 100%, 79%, 47%).
- Halaman detail dengan `PageView` untuk seluruh 6.236 ayat, tombol
  Sebelum/Berikut, serta pembagian teks atau gambar (JPEG) lewat lembar sistem.
  Gambar memuat nama surat, nomor surat, dan nomor ayat. Opsi "Unduh gambar"
  tersedia di semua platform: web mengunduh lewat peramban, Android/iOS membuka
  dialog simpan sistem, dan macOS menyimpan ke folder Downloads.
- Daftar contoh pencarian yang berganti otomatis setiap enam detik.
- Panduan awal (coach marks) dengan sorotan pada kolom pencarian, tombol suara,
  dan daftar contoh. Panduan dapat diputar ulang dari menu.
- Pengaturan untuk huruf vokal, terjemahan, dan tingkat kesamaan (persentase
  relevansi pada kartu hasil; default mati), tersimpan di perangkat.
- Tema Material 3 terang/gelap dengan palet hijau khas Lafzi.
- Splash screen hanya muncul saat database ±15 MB perlu disalin (peluncuran
  pertama atau setelah versi database berubah); peluncuran berikutnya langsung
  ke beranda.
- Pencarian suara: Android memakai `RecognizerIntent` sistem (jalur yang sama
  dengan versi Java); iOS/macOS memakai `speech_to_text` dengan locale Arab yang
  tersedia di perangkat.

## Platform

- **Android** — didukung dan diuji pada perangkat/emulator (API 24+).
- **iOS** — didukung; `flutter build ios --simulator` berhasil. Untuk perangkat
  fisik diperlukan signing/team Apple.
- **macOS** — didukung; `flutter run -d macos` dan `flutter build macos` berhasil.
  Aplikasi meminta izin mikrofon/pengenalan suara macOS.
- **Web** — didukung (Chrome, Edge, Firefox, dan Safari modern; diuji di
  Chrome). Database dibaca lewat SQLite WebAssembly dan dimuat ke memori dari
  aset, lalu dibuka read-only. `web/sqlite3.wasm` adalah build khusus dengan
  FTS3/FTS4 karena build bawaan `sqlite3` hanya berisi FTS5; lihat
  `tool/build_sqlite3_wasm.sh`. Pencarian suara disembunyikan di web karena
  dukungan Web Speech API tidak konsisten; panduan awal dan halaman bantuan
  otomatis tidak menampilkan langkah suara. Berbagi memakai Web Share API (di
  macOS Chrome/Safari tampil sebagai lembar berbagi sistem), dan tombol "Unduh
  gambar" mengunduh JPEG langsung karena lembar sistem tidak selalu
  menyediakan opsi simpan. Di Android/iOS tombol yang sama membuka dialog
  simpan, sedangkan di macOS file masuk ke folder Downloads. Splash web
  menampilkan persentase unduhan database (16 MB) sebelum aplikasi dibuka.
- **Linux/Windows** — belum dikonfigurasi. Windows memiliki dukungan suara dari
  `speech_to_text`, tetapi database perlu `sqflite_common_ffi` dengan SQLite
  ber-FTS4; Linux belum memiliki dukungan suara dari plugin tersebut.

## Persyaratan

- Flutter 3.47 atau lebih baru (Dart 3.13+)
- Android SDK 36 dan JDK 17+ untuk target Android
- Xcode 27 dan CocoaPods untuk target iOS
- Perangkat/emulator Android 7.0 (API 24) atau lebih baru
- Untuk web: server yang menyajikan berkas `.wasm` dengan tipe
  `application/wasm` (server pengembangan Flutter sudah melakukannya)

## Menjalankan

```bash
flutter pub get
flutter run
```

Untuk perangkat tertentu:

```bash
flutter devices
flutter run -d <device-id>
```

Untuk web:

```bash
flutter run -d chrome
```

## Build

Application ID Android adalah `com.xaepudin.lafzi`, berbeda dari aplikasi
Android asli (`org.lafzi.lafzi`), sehingga keduanya dapat dipasang berdampingan.
Nama aplikasi yang tampil di launcher adalah "Lafzi". Bundle ID iOS dan macOS
juga memakai `com.xaepudin.lafzi`.


APK debug:

```bash
flutter build apk --debug
```

APK release:

```bash
flutter build apk --release
```

Build release otomatis memakai keystore dari `android/key.properties` bila
berkas itu ada; tanpa berkas tersebut build memakai debug key (lihat bagian
CI/CD untuk mengisinya lewat secret). R8/code shrinking dimatikan (`shrink=false`)
karena versi Android asli juga tidak memakainya dan plugin Flutter memerlukan
signature Kotlin yang utuh untuk pemanggilan reflektif.

APK release per arsitektur (lebih kecil untuk distribusi):

```bash
flutter build apk --release --split-per-abi
```

Build iOS (simulator):

```bash
flutter build ios --simulator
```

Build web:

```bash
flutter build web --release --no-web-resources-cdn
```

Flag `--no-web-resources-cdn` wajib dipakai: tanpa itu CanvasKit dan font
bawaan diambil dari CDN Google, sehingga tidak bisa disimpan oleh service
worker dan aplikasi gagal tampil saat luring.

Hasilnya ada di `build/web`. Deployment produksi memakai Cloudflare Pages di
<https://lafzi.pages.dev>, dengan penanganan 404 kustom dari `web/404.html`
sehingga alamat yang tidak ada mengembalikan status 404, bukan halaman
aplikasi. Sajikan direktori itu sebagai situs statis dan
pastikan `.wasm` dikirim sebagai `application/wasm`, karena modul SQLite dimuat
dengan `WebAssembly.instantiateStreaming`. Pada kunjungan pertama, halaman
mengunduh `lafzi.sqlite` (16 MB; sekitar 4,8 MB bila server mengaktifkan gzip)
lalu menyalinnya ke memori.

### Mode luring (web)

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

Berkas `web/sqlite3.wasm` sudah disertakan di repositori. Jika versi paket
`sqlite3` di `pubspec.yaml` dinaikkan, bangun ulang dengan:

```bash
tool/build_sqlite3_wasm.sh
```

## Tes

```bash
flutter analyze
flutter test
```

Tes integrasi di perangkat/emulator Android:

```bash
flutter test integration_test/app_test.dart -d <device-id>
```

Tes unit mencakup normalisasi kueri (vektor uji dari versi Android), trigram,
pemeringkatan, penanda hasil, pencarian Latin dan Arab terhadap database asli,
serta widget kartu hasil dan daftar contoh. `test/sqlite3_database_test.dart`
menjalankan adapter SQL yang dipakai web (di atas SQLite sistem yang memiliki
FTS4) dan membandingkan hasilnya dengan adapter `sqflite`: id, skor, dan rentang
highlight harus identik. Tes integrasi memverifikasi pencarian Latin, pencarian
Arab FTS4, dan pembukaan halaman detail di Android.

## Struktur proyek

```
lib/
  app.dart                 MaterialApp, tema, dan delegate lokalisasi
  main.dart                Titik masuk; memuat pengaturan
  core/                    Warna, tema, string Indonesia, scope pengaturan
  data/                    Salinan database, adapter SQL, DAO, pengaturan
  models/                  Model ayat, hasil pencarian, dan highlight
  search/                  Normalisasi, trigram, skor, highlight, FTS Arab
  screens/                 Splash, beranda, detail, pengaturan, bantuan, about
  share/                   Pembagian teks dan gambar
  widgets/                 Kartu ayat, daftar contoh, sorotan panduan, gambar share
assets/
  databases/lafzi.sqlite   Database Al-Qur'an dan indeks pencarian
  fonts/me_quran.ttf       Font Qur'an
  images/                  Logo dan ikon aplikasi
tool/
  build_sqlite3_wasm.sh    Build SQLite WebAssembly dengan FTS3/FTS4
web/
  index.html               Layar peluncuran statis dan pendaftaran service worker
  flutter_bootstrap.js     Bootstrap kustom (CanvasKit lokal, SW Flutter mati)
  sw.js                    Service worker: cache kerangka dan database
  404.html                 Halaman 404 untuk Cloudflare Pages
  sqlite3.wasm             SQLite WebAssembly (build khusus, di-commit)
```

## Database dan pencarian

Database `lafzi.sqlite` dibundel sebagai aset dan disalin ke direktori database
aplikasi pada peluncuran pertama (atau saat versi aset berubah). Database dibuka
secara read-only.

Di web tidak ada penyalinan ke disk: aset diunduh, ditulis ke virtual file
system SQLite di memori, lalu dibuka read-only. Splash menutupi proses ini dan
database dimuat ulang pada setiap pemuatan halaman. Karena database bersifat
statis dan read-only, tidak ada data pengguna yang perlu disimpan di browser
selain pengaturan dan status panduan (`shared_preferences`).

- Pencarian Latin menormalkan kueri, memecahnya menjadi trigram, mengambil
  posting dari `vocal_index`/`nonvocal_index`, lalu memeringkat dokumen dengan
  skor kecocokan trigram dan kedekatan posisi.
- Pencarian Arab memakai `MATCH` pada tabel FTS4, lalu memetakan offset hasil
  kembali ke teks ayat untuk penanda.
- `vocal_mapping_position`/`nonvocal_mapping_position` memetakan posisi fonetis
  ke indeks karakter Arab, sama seperti versi Android.

Implementasi Dart diuji terhadap keluaran referensi Java untuk banyak kueri:
jumlah hasil, urutan dokumen, skor, dan rentang highlight identik.

## Pencarian suara

Android memakai `RecognizerIntent` sistem (jalur yang sama dengan versi Java).
iOS dan macOS memakai paket `speech_to_text` dengan locale Arab pertama yang
didukung perangkat (`ar-AE`, `ar-SA`, `ar-EG`, lalu locale `ar*` lainnya).
Di web, tombol mikrofon tidak ditampilkan. Implementasinya tetap ada di balik
`PlatformCapabilities.voiceSearch`, tetapi `speech_to_text` memakai Web Speech
API yang dukungan locale Arab-nya tidak konsisten antarperamban, sehingga fitur
ini sengaja dinonaktifkan. Bila nanti diaktifkan lagi, halaman harus disajikan
lewat HTTPS atau localhost dan panduan/bantuan akan otomatis menampilkan
langkah suara kembali.
Aplikasi meminta izin mikrofon dan pengenalan suara; selama sesi berjalan,
banner "Mendengarkan…" tampil di atas kolom pencarian dan dapat diketuk untuk
berhenti. Jika sesi gagal, aplikasi membedakan izin ditolak, layanan tidak
tersedia, dan mikrofon gagal, lalu menampilkan pesan yang sesuai.

Pengenalan suara Apple memerlukan koneksi internet kecuali perangkat mendukung
pengenalan luring. Di Simulator iOS, audio input harus aktif (I/O > Audio Input)
dan Simulator harus diizinkan memakai mikrofon Mac; tanpa itu sesi berhenti
dengan pesan gagal, bukan hasil kosong.

## Lisensi dan atribusi

Proyek ini dilisensikan di bawah **GNU General Public License v3.0**
(GPL-3.0). Teks lisensi lengkap ada di berkas [LICENSE](LICENSE).

### Karya asal

Versi Flutter ini adalah **port (karya turunan) dari Lafzi Android**:

- Nama: Lafzi Android — <https://github.com/lafzi/lafzi-android>
- Hak cipta: Copyright (C) 2017–2019 proyek Lafzi dan para kontributornya,
  termasuk Alfat Saputra Harun dan Muhammad Abrari.
- Lisensi: GPL-3.0 (sama dengan proyek ini).
- Lafzi Android sendiri didasarkan pada hasil penelitian skripsi Departemen
  Ilmu Komputer, Fakultas MIPA, Institut Pertanian Bogor.

Aplikasi ini bukan aplikasi asli, dan para penulis asli tidak bertanggung jawab
atas perubahan yang dibuat di sini. Rincian perubahan dan atribusi lengkap ada
di berkas [NOTICE](NOTICE).

### Karya turunan

- Nama: Lafzi — <https://github.com/xaepudin/lafzi>
- Versi web: <https://lafzi.pages.dev>
- Hak cipta: Copyright (C) 2026 Asep Saepudin.
- Perubahan (Oktober 2026): ditulis ulang dari Java/Android ke Dart/Flutter,
  ditambah target iOS/macOS/web, logika pencarian dan pemeringkatan
  diimplementasikan ulang di Dart dan diuji terhadap implementasi Java asli,
  akses SQLite ditulis ulang, serta UI, pengaturan, panduan awal, berbagi
  gambar, dan pencarian suara di iOS/macOS dibuat baru.

### Kewajiban saat mendistribusikan

Siapa pun yang menerima versi biner aplikasi ini berhak mendapatkan source
code-nya. Jika Anda membagikan APK/IPA/build web, sertakan tautan ke
<https://github.com/xaepudin/lafzi> (atau tawarkan source code-nya) di deskripsi
toko aplikasi
maupun di layar **Tentang** di dalam aplikasi. Source code tidak boleh
dilisensikan ulang dengan lisensi yang lebih ketat: karya turunan GPL-3.0 harus
tetap GPL-3.0.

Aset yang dibundel (`assets/databases/lafzi.sqlite`, `assets/fonts/me_quran.ttf`,
dan logo) berasal dari proyek asal dan memiliki ketentuan masing-masing; lihat
[NOTICE](NOTICE) sebelum mendistribusikan ulang.

## CI/CD (GitHub Actions)

Tiga workflow berjalan di GitHub Actions, semuanya memakai Flutter 3.47.7:

| Workflow | Pemicu | Yang dilakukan |
| --- | --- | --- |
| `.github/workflows/ci.yml` | push ke `main`, pull request | `flutter analyze` dan `flutter test` |
| `.github/workflows/web.yml` | push ke `main` yang menyentuh `lib/`, `web/`, `assets/`, `pubspec.*` | analyze, test, `flutter build web --release --no-web-resources-cdn`, lalu deploy ke Cloudflare Pages (`lafzi`) |
| `.github/workflows/release.yml` | tag `v*` atau manual | APK per-ABI (satu artefak per arsitektur), AAB, DMG macOS, IPA iOS (unsigned); pada tag juga membuat GitHub Release |

### Secret yang diperlukan

Untuk deploy web (wajib):

- `CLOUDFLARE_API_TOKEN` — token dengan izin **Cloudflare Pages: Edit**
  (My Profile → API Tokens → Create Token → template "Edit Cloudflare Workers"
  atau custom dengan `Account → Cloudflare Pages → Edit`).
- `CLOUDFLARE_ACCOUNT_ID` — terlihat di dashboard Cloudflare atau dari
  `npx wrangler whoami`.

Untuk APK/AAB yang bisa diunggah ke Play (opsional, tanpa ini artefak
ditandatangani debug key dan ditolak Play):

- `ANDROID_KEYSTORE_BASE64` — isi `upload-keystore.jks` yang di-encode base64:
  `base64 -i upload-keystore.jks | pbcopy`.
- `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.

Membuat keystore upload (simpan di tempat aman, jangan di repositori):

```bash
keytool -genkeypair -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 4096 -validity 10000 -alias upload
```

### Merilis

```bash
# naikkan version di pubspec.yaml (mis. 2.2.1+18), commit, lalu:
git tag v2.2.1
git push origin main --tags
```

Hanya **tag** yang memicu workflow ini secara otomatis — push biasa ke `main`
tidak. Menjalankan manual dari tab Actions tetap menghasilkan artefak, tetapi
tanpa GitHub Release, sehingga tiap artefak diunduh sebagai zip.

Pada tag, workflow `publish` membuat GitHub Release dan menaruh setiap berkas
sebagai aset terpisah, jadi APK per arsitektur bisa diunduh langsung tanpa
membongkar zip:

- `lafzi-<versi>-arm64-v8a.apk` — HP Android modern
- `lafzi-<versi>-armeabi-v7a.apk` — perangkat lama 32-bit
- `lafzi-<versi>-x86_64.apk` — emulator
- `lafzi-<versi>.aab` — unggahan Play Store
- `Lafzi-<versi>.dmg` — macOS
- `Lafzi-<versi>-unsigned.ipa` — iOS (perlu ditandatangani ulang)

Catatan: IPA yang dihasilkan **unsigned** — bisa dipasang lewat alat sideloading
yang menandatangani ulang, tetapi unggah ke App Store memerlukan sertifikat dan
provisioning profile. DMG macOS ditandatangani ad-hoc dan belum dinotarisasi,
jadi pengguna perlu membuka lewat System Settings → Privacy & Security.
Repositori privat memakai kuota menit Actions (macOS dihitung 10x); repositori
publik gratis.
