# Beat Nusantara 🎵🇮🇩

Game ritme (音ゲー) premium dengan rasa Nusantara — dibangun dengan Flutter,
dirancang untuk App Store & Play Store. Modern arcade × neon-budaya lokal.

> Semua lagu, judul, dan nama artis di sini **fiktif/orisinal**. Audio demo
> dihasilkan secara prosedural — tidak ada lagu/artis berhak cipta. Lihat
> [docs/MUSIC_LICENSING.md](docs/MUSIC_LICENSING.md).

## Apa yang sudah jalan (Phase 1)

- Game ritme penuh: not jatuh, judgment **Perfect/Hebat/Oke/Lewat**, combo,
  akurasi, grade **SSS–D**, HP, **Fever mode**, dan **revive** lewat iklan opsional.
- 7 jenis not: tap, hold, slide, flick, double, golden, fever.
- Mode: Klasik, Speed, Santai (4 & 5 lajur).
- **3 lagu demo yang benar-benar bisa dimainkan**, dengan audio orisinal yang
  **selaras dengan chart** (ketukan = nada yang terdengar).
- Katalog **20+ lagu** lintas genre (pop, koplo, gamelan electronic, EDM,
  J/K-pop inspired, lo-fi, phonk, hyperpop, dst) — siap ekspansi via manifest.
- 12 layar premium: splash, onboarding, home, perpustakaan, detail lagu,
  gameplay, hasil, hadiah/kosmetik, pengaturan, kalibrasi, profil, tentang/legal.
- Penyimpanan lokal: profil, skor terbaik, unlock, favorit, koin, kalibrasi,
  kosmetik, onboarding.
- Iklan berhadiah dengan **disclosure jujur** (opsional, bisa ditolak, tidak
  pernah otomatis) — saat ini **stub** aman; AdMob asli tinggal di-drop-in.
- **Anti-FOMO by design**: tidak ada streak, hitung mundur, atau lagu yang hilang.
- CI/CD: GitHub Actions (APK/AAB) + Codemagic (iOS).

## Arsitektur singkat

```
lib/
  app/         tema neon + MaterialApp
  core/        konstanta, haptics
  game/
    models/    Note, Chart, Song
    engine/    GameEngine (konduktor: clock, input, fever, HP, fail/revive)
    scoring/   ScoreBoard, Judgment, Grade
    rendering/ NotePainter (CustomPainter playfield)
    chart_loader/
  data/        SongCatalog (manifest), missions
  services/    ads (abstraksi + stub), audio (audioplayers), storage (prefs)
  state/       GameState (ChangeNotifier, provider)
  features/    satu folder per layar
  widgets/     GlassPanel, GradientButton, SongCard, reward_ad_sheet
assets/
  audio/songs  3 WAV orisinal (di-generate)
  audio/sfx    hit/perfect/miss
  charts/      7 beatmap JSON
  images/      cover + icon
  fonts/       Plus Jakarta Sans (OFL)
  song_manifest.json
tool/          generator audio+chart & gambar (Python, no deps)
docs/          desain, lisensi, AdMob, review App Store, Codemagic
```

**Timing model:** master clock = `Stopwatch` (bukan posisi audio, agar bebas
jitter); audio diputar berbarengan. `calibrationMs` menggeser window judge.

## Menjalankan / build

Repo ini **hanya menyimpan `lib/` + `assets/`**. Folder native (`android/`,
`ios/`) sengaja tidak di-commit dan **di-generate otomatis** saat build.

```bash
# lokal (kalau punya Flutter):
flutter create --org com.beatnusantara --project-name beat_nusantara --platforms=android,ios .
flutter pub get
dart run flutter_launcher_icons
flutter run                 # mainkan di device/emulator
flutter test                # unit test scoring
flutter build apk --release # APK

# regenerate aset audio/chart/gambar (opsional):
python3 tool/generate_assets.py
python3 tool/generate_images.py
```

**Tanpa Flutter lokal?** Push ke GitHub → tab **Actions** → unduh artifact
`beat-nusantara-apk`. iOS lewat **Codemagic** (lihat docs/CODEMAGIC_SETUP.md).

## Menambah lagu (data-driven)

1. Taruh audio di `assets/audio/songs/`, cover di `assets/images/`.
2. Buat chart JSON di `assets/charts/` (format di docs/GAME_DESIGN.md).
3. Tambah entri di `assets/song_manifest.json`, set `"playable": true`.

Tidak perlu ubah kode. Untuk lagu berlisensi, lihat docs/MUSIC_LICENSING.md.

## Screenshot & marketing

Mode screenshot deterministik (widget asli, data fiktif stabil) untuk App Store:

```bash
flutter run --dart-define=SCREENSHOT=gameplay   # home | library | gameplay | result | reward
```
Atau in-app (debug): **Settings → Developer → Mode Screenshot**.

Pratinjau cepat tanpa build: buka **`docs/mockup/index.html`** di browser
(mockup HTML semua layar). Aturan visual & prompt Nano Banana ada di docs.

## Dokumentasi

- [GAME_DESIGN.md](docs/GAME_DESIGN.md) — mekanik, format chart, scoring
- [MUSIC_LICENSING.md](docs/MUSIC_LICENSING.md) — ganti audio placeholder → berlisensi
- [ADMOB_NOTES.md](docs/ADMOB_NOTES.md) — aktifkan AdMob asli (kode drop-in)
- [APP_STORE_REVIEW_NOTES.md](docs/APP_STORE_REVIEW_NOTES.md) — catatan untuk review Apple
- [CODEMAGIC_SETUP.md](docs/CODEMAGIC_SETUP.md) — build iOS di cloud
- [AI_VISUAL_WORKFLOW.md](docs/AI_VISUAL_WORKFLOW.md) — aturan visual (real vs AI)
- [SCREENSHOT_DIRECTION.md](docs/SCREENSHOT_DIRECTION.md) — apa & bagaimana menangkap
- [APP_ICON_DIRECTION.md](docs/APP_ICON_DIRECTION.md) — arah ikon final
- [PROMO_ASSET_PROMPTS.md](docs/PROMO_ASSET_PROMPTS.md) — prompt Nano Banana (dekoratif)
