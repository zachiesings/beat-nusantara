# App Icon Direction

Ikon placeholder asli sudah ada: `assets/icon/app_icon.png` (1024×1024,
di-generate `tool/generate_images.py`). Ini sah dipakai rilis. Dokumen ini untuk
membuat versi final yang lebih artistik.

## Konsep
Gradien neon ungu→pink→cyan, cincin pulse (gelombang ritme), empat bilah lajur
yang "jatuh", dan segitiga play di tengah. Rasa: arcade modern × senja Nusantara.
Hindari kesan kekanak-kanakan; tetap fun tapi premium.

## Spesifikasi teknis
- **1024×1024 px**, sRGB, PNG.
- iOS: **tanpa alpha/transparansi**, sudut jangan dibulatkan sendiri (Apple yang
  membulatkan). Background solid (mis. `#0B0B18`).
- Android adaptif: sediakan foreground (safe zone tengah ~66%) + background solid.
- Hindari teks kecil; ikon harus terbaca di 48px.

## Memakai Nano Banana untuk KONSEP (lalu rapikan manual)
Gambar AI = sumber inspirasi/konsep, bukan langsung jadi ikon final. Setelah
dapat konsep, rapikan di vector (Figma/Illustrator), pastikan tajam & sesuai
spesifikasi, lalu ekspor.

Prompt konsep (lihat juga PROMO_ASSET_PROMPTS.md):
```
A premium mobile rhythm-game app icon, neon violet-to-pink-to-cyan gradient,
concentric glowing "pulse" rings like sound waves, four vertical neon lane bars
falling toward a center, a clean white play triangle in the middle, subtle
Indonesian batik diamond texture in the background, dark deep-indigo base
(#0B0B18), flat modern, high contrast, no text, no rounded corners, centered,
1:1, app-store quality.
```

## Menerapkan ikon ke build
1. Ganti `assets/icon/app_icon.png` dengan versi final (1024², tanpa alpha iOS).
2. Konfigurasi sudah ada di `pubspec.yaml` (`flutter_launcher_icons`).
3. Generate: `dart run flutter_launcher_icons` (di CI sudah otomatis).

## Variasi yang berguna
- Versi monokrom/tinted untuk iOS 18 "tinted icon".
- Versi feature-graphic (lihat PROMO_ASSET_PROMPTS.md) untuk Play Store.
