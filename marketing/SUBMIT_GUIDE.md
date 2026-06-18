# Beat Nusantara — iOS Submit Guide

Status of the release pipeline + the few steps that genuinely need a human
(Apple/Codemagic logins I can't perform from here).

## ✅ Done automatically
- App fully built & verified (Build APK green; tests + analyzer pass)
- **AdMob** wired: `google_mobile_ads`, App ID `ca-app-pub-1298950542115439~5662432931`
  injected into Android manifest + iOS `GADApplicationIdentifier`; rewarded unit
  `…/8932764961`; test units in dev (`USE_TEST_ADS`). Ads stay optional & disclosed.
- **Bundle ID `id.beatnusantara.beatnusantara`** registered on the Apple Developer
  account (so it appears in the "+ New App" dropdown).
- `codemagic.yaml` finalized for that bundle id + iOS AdMob config.
- **Metadata (ID + EN)** + the **5 screenshots** ready to auto-push via
  `tool/asc_push_beat.py` the moment the app record exists.
- Preview video rendered: `marketing/appstore/beat_nusantara_preview.mp4`.

## 🔴 Needs you (Apple/Codemagic don't allow this via API)

### 1) Create the app record — ~90 seconds (App Store Connect web)
Apple's API cannot create apps (verified: `apps` is GET/UPDATE only). Do it once:
- App Store Connect → **Apps** → **＋** → **New App**
- Platform: **iOS** · Name: **Beat Nusantara** · Primary language: **Indonesian**
- Bundle ID: pick **id.beatnusantara.beatnusantara** (already in the list)
- SKU: e.g. `BEATNUSANTARA2026` · Full access
- **Tell me when it's created** → I run `tool/asc_push_beat.py` and it fills all
  metadata (ID+EN) + uploads the 5 screenshots automatically.

### 2) Build & upload via Codemagic (their account; I can't trigger it)
- Connect this GitHub repo in Codemagic → it auto-detects `codemagic.yaml`.
- Add an **App Store Connect API key** integration with:
  - Issuer ID: `cdaa6ed4-07f4-4151-ac76-eb1e66b6effb`
  - Key ID: `DK5TAZT3F9`
  - Private key: the file `AuthKey_DK5TAZT3F9.p8` (in your Downloads)
- Run the `ios-release` workflow → it signs, builds the `.ipa`, and uploads to
  TestFlight / App Store Connect.

### 3) App Privacy + Submit (App Store Connect web)
- **App Privacy**: with the stub ad layer it's "Data Not Collected"; with **real
  AdMob enabled** declare *Identifiers* + *Usage Data* for **Third-Party Advertising**
  (+ add a privacy-policy URL). (See `docs/ADMOB_NOTES.md`.)
- Pricing: **Free**. Age rating: **4+**.
- Attach the build from step 2, (optional) drag in the preview `.mp4`, **Submit**.

> Reviewer notes: `docs/APP_STORE_REVIEW_NOTES.md` (no IAP, ads optional, all songs fictional).
