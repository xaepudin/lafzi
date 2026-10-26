# Deployment

Lafzi web disajikan lewat Cloudflare Pages, dan artefak Android/iOS/macOS
dibangun oleh GitHub Actions. Dokumen ini menjelaskan alur tersebut.

## Cloudflare Pages

| Item | Nilai |
| --- | --- |
| Proyek | `lafzi` |
| URL | <https://lafzi.pages.dev> |
| Production branch | `main` |
| Perintah build | `flutter build web --release --no-web-resources-cdn` |
| Direktori keluaran | `build/web` |

Flag `--no-web-resources-cdn` wajib dipakai, karena CanvasKit dan font harus
disajikan dari origin sendiri agar bisa di-cache service worker. Lihat
[architecture.md](architecture.md#mode-luring-web).

Pengaturan proyek yang perlu dijaga:

- **Production branch** harus `main`. Kalau tidak, `wrangler pages deploy` akan
  membuat *preview* deployment dan `lafzi.pages.dev` tetap menyajikan versi lama.
- **Not Found handling** = `404-page`, memakai `web/404.html`. Tanpa ini,
  Cloudflare menyajikan `index.html` dengan status 200 untuk semua alamat yang
  tidak ada.
- `.wasm` harus dikirim sebagai `application/wasm`; Cloudflare Pages sudah
  melakukannya secara otomatis.

Deploy manual (biasanya tidak perlu, karena workflow sudah melakukannya):

```bash
flutter build web --release --no-web-resources-cdn
npx wrangler pages deploy build/web --project-name lafzi
```

## GitHub Actions

Tiga workflow, semuanya memakai Flutter 3.47.7:

| Workflow | Pemicu | Yang dilakukan |
| --- | --- | --- |
| `.github/workflows/ci.yml` | push ke `main`, pull request | `flutter analyze` dan `flutter test` |
| `.github/workflows/web.yml` | push ke `main` yang menyentuh `lib/`, `web/`, `assets/`, `pubspec.*` | analyze, test, build web, deploy ke Cloudflare Pages |
| `.github/workflows/release.yml` | tag `v*` atau manual | APK per-ABI, AAB, DMG macOS, IPA iOS (unsigned); pada tag juga membuat GitHub Release |

Repositori privat memakai kuota menit Actions (macOS dihitung 10x); repositori
publik tidak memakai kuota.

## Secret yang diperlukan

Untuk deploy web (wajib):

- `CLOUDFLARE_API_TOKEN` — token dengan izin **Cloudflare Pages: Edit**
  (My Profile → API Tokens → Create Token, atau custom dengan
  `Account → Cloudflare Pages → Edit`).
- `CLOUDFLARE_ACCOUNT_ID` — terlihat di dashboard Cloudflare atau dari
  `npx wrangler whoami`.

Untuk APK/AAB yang bisa diunggah ke Play (opsional; tanpa ini artefak
ditandatangani debug key dan ditolak Play):

- `ANDROID_KEYSTORE_BASE64` — isi `upload-keystore.jks` dalam base64:
  `base64 -i upload-keystore.jks | pbcopy`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Membuat keystore upload (simpan di tempat aman, jangan di repositori):

```bash
keytool -genkeypair -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 4096 -validity 10000 -alias upload
```

JDK modern membuat keystore PKCS12, sehingga `keyPassword` harus sama dengan
`storePassword`. Lihat [development.md](development.md#android) untuk memakai
keystore tersebut saat build lokal.

## Merilis

```bash
# naikkan version di pubspec.yaml (mis. 2.2.1+18), commit, lalu:
git tag v2.2.1
git push origin main --tags
```

Hanya **tag** yang memicu workflow rilis secara otomatis; push biasa ke `main`
tidak. Menjalankan manual dari tab Actions tetap menghasilkan artefak, tetapi
tanpa GitHub Release, sehingga tiap artefak diunduh sebagai zip.

Pada tag, job `publish` membuat GitHub Release dengan setiap berkas sebagai aset
terpisah, jadi APK per arsitektur bisa diunduh langsung:

| Berkas | Untuk |
| --- | --- |
| `lafzi-<versi>-arm64-v8a.apk` | HP Android modern |
| `lafzi-<versi>-armeabi-v7a.apk` | Perangkat lama 32-bit |
| `lafzi-<versi>-x86_64.apk` | Emulator |
| `lafzi-<versi>.aab` | Unggahan Play Store |
| `Lafzi-<versi>.dmg` | macOS |
| `Lafzi-<versi>-unsigned.ipa` | iOS (perlu ditandatangani ulang) |

Catatan tentang artefak:

- **IPA bersifat unsigned.** Bisa dipasang lewat alat sideloading yang
  menandatangani ulang, tetapi unggahan App Store memerlukan sertifikat dan
  provisioning profile dari akun Apple Developer.
- **DMG macOS ditandatangani ad-hoc dan belum dinotarisasi.** Pengguna perlu
  membukanya lewat System Settings → Privacy & Security. Notarisasi memerlukan
  akun Apple Developer.
- Job `publish` bergantung pada ketiga job build; jika salah satu gagal, GitHub
  Release tidak dibuat.
