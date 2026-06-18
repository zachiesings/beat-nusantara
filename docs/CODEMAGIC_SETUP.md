# Codemagic Setup — iOS build tanpa Mac

`codemagic.yaml` di root sudah siap. Pola sama dengan GoNihon: signing pakai
**App Store Connect API key** lewat environment variables (tanpa integrasi UI).

## 1. Hubungkan repo
Codemagic → Add application → pilih repo GitHub `beat-nusantara` → pilih
"flutter-app" / gunakan `codemagic.yaml` yang ada.

## 2. Environment variables (group, encrypted)
Buat group (mis. `appstore`) berisi:

| Variable | Isi |
|----------|-----|
| `APP_STORE_CONNECT_PRIVATE_KEY` | isi file `.p8` (AuthKey_XXXX.p8) |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | Key ID (mis. `DK5TAZT3F9`) |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID dari App Store Connect |
| `CERTIFICATE_PRIVATE_KEY` | private key sertifikat distribusi (PEM) |

Tandai semua **Secure**. Jangan commit nilai apa pun.
Referensikan group di workflow bila perlu (`environment: groups: [appstore]`).

## 3. Bundle ID
`codemagic.yaml` mem-*force* `PRODUCT_BUNDLE_IDENTIFIER` ke `$BUNDLE_ID`
(default `com.beatnusantara.beatnusantara`) lewat langkah `sed`, lalu
`fetch-signing-files "$BUNDLE_ID" --create`. **Samakan** `BUNDLE_ID` dengan
record app di App Store Connect (buat app baru dengan bundle id ini bila belum
ada). Ubah satu tempat di blok `vars`.

## 4. Trigger build
Push ke `main`, atau Start new build → workflow **ios-appstore**. Hasil:
- IPA di artifacts,
- otomatis dikirim ke **TestFlight** (`submit_to_testflight: true`),
- `submit_to_app_store: false` (submit final dilakukan manual setelah metadata
  & data bisnis final — lihat catatan boss).

## 5. Catatan platform generate
Karena repo hanya menyimpan `lib/` + `assets/`, workflow menjalankan
`flutter create … .` lebih dulu untuk membuat `ios/` & `android/`, lalu
`flutter pub get`, launcher icons, baru build. Kalau nanti kamu mulai
meng-commit folder `ios/` asli (mis. untuk Info.plist AdMob), hapus langkah
`flutter create` agar tidak menimpa konfigurasi.

## 6. Android (Play Store)
APK/AAB dibangun gratis di **GitHub Actions** (`.github/workflows/build-apk.yml`)
— unduh dari tab Actions. Untuk rilis Play, signing AAB diatur terpisah.
