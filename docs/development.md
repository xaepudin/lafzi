# Pengembangan

Panduan untuk menyiapkan lingkungan, menjalankan, membangun, dan menguji Lafzi.
Untuk gambaran arsitektur lihat [architecture.md](architecture.md); untuk
deployment dan rilis lihat [deployment.md](deployment.md).

## Persyaratan

- Flutter 3.47 atau lebih baru (Dart 3.13+)
- Android SDK 36 dan JDK 17+ untuk target Android
- Xcode 27 dan CocoaPods untuk target iOS/macOS
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

## Identitas aplikasi

| Item | Nilai |
| --- | --- |
| Application ID Android | `com.xaepudin.lafzi` |
| Namespace Android | `com.xaepudin.lafzi` |
| Bundle ID iOS/macOS | `com.xaepudin.lafzi` |
| Nama di launcher | `Lafzi` |
| Method channel suara | `com.xaepudin.lafzi/speech` |

Application ID berbeda dari aplikasi Android asli (`org.lafzi.lafzi`), sehingga
keduanya dapat dipasang berdampingan. Jika identitas ini diubah, ikuti seluruh
tempat berikut: `android/app/build.gradle.kts`, `MainActivity.kt` beserta
folder `kotlin/`, `ios/Runner.xcodeproj/project.pbxproj`,
`macos/Runner/Configs/AppInfo.xcconfig`, `macos/Runner.xcodeproj/project.pbxproj`,
dan `lib/search/speech_service.dart` (nama method channel).

## Build

### Android

```bash
flutter build apk --debug
flutter build apk --release
flutter build apk --release --split-per-abi   # lebih kecil untuk distribusi
flutter build appbundle --release             # untuk Play Store
```

Build release memakai keystore dari `android/key.properties` bila berkas itu
ada; tanpa berkas tersebut build memakai debug key. Isi `key.properties` seperti
ini (berkas ini diabaikan git):

```properties
storeFile=/jalur/ke/upload-keystore.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

R8/code shrinking dimatikan (`shrink=false`) karena versi Android asli juga
tidak memakainya, dan plugin Flutter memerlukan signature Kotlin yang utuh
untuk pemanggilan reflektif.

### iOS dan macOS

```bash
flutter build ios --simulator
flutter build ios --release --no-codesign
flutter build macos --release
```

Untuk perangkat iOS fisik atau unggahan App Store, diperlukan sertifikat dan
provisioning profile dari akun Apple Developer. macOS memakai tanda tangan
ad-hoc (`CODE_SIGN_IDENTITY = "-"`) sehingga bisa dibangun tanpa tim Apple,
tetapi belum dinotarisasi.

### Web

```bash
flutter build web --release --no-web-resources-cdn
```

Flag `--no-web-resources-cdn` **wajib** dipakai. Tanpa flag itu CanvasKit dan
font bawaan diambil dari CDN Google, tidak bisa disimpan service worker, dan
aplikasi gagal tampil saat luring. Lihat [architecture.md](architecture.md) untuk
cara kerja cache luring.

Hasilnya ada di `build/web`. Sajikan direktori itu sebagai situs statis dan
pastikan `.wasm` dikirim sebagai `application/wasm`, karena modul SQLite dimuat
dengan `WebAssembly.instantiateStreaming`.

`web/sqlite3.wasm` adalah build khusus dengan FTS3/FTS4. Jika versi paket
`sqlite3` di `pubspec.yaml` dinaikkan, bangun ulang dengan:

```bash
tool/build_sqlite3_wasm.sh
```

## Platform lain

Linux dan Windows belum dikonfigurasi. Windows memiliki dukungan suara dari
`speech_to_text`, tetapi database memerlukan `sqflite_common_ffi` dengan SQLite
ber-FTS4; Linux belum memiliki dukungan suara dari plugin tersebut.

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
  images/                  Logo, ikon aplikasi, dan mark GitHub
docs/                      Dokumentasi teknis
tool/
  build_sqlite3_wasm.sh    Build SQLite WebAssembly dengan FTS3/FTS4
web/
  index.html               Layar peluncuran statis dan pendaftaran service worker
  flutter_bootstrap.js     Bootstrap kustom (CanvasKit lokal, SW Flutter mati)
  sw.js                    Service worker: cache kerangka dan database
  404.html                 Halaman 404 untuk Cloudflare Pages
  sqlite3.wasm             SQLite WebAssembly (build khusus, di-commit)
```
