# Screenshots — lokasi & cara taruh

Dua hal beda, jangan ketuker:

## 1) KODE screenshot-mode (Flutter) — sudah ada
`lib/features/screenshot/`
- `screenshot_gallery.dart` — peta 5 state + in-app gallery
- `demo_data.dart` — data fiktif deterministik (Andini, SSS, dll)
- `screenshot_gameplay.dart` — frame gameplay "perfect" beku

## 2) HASIL tangkapan (PNG) — taruh di SINI
`marketing/screenshots/<device>/<layar>.png`

Susun per ukuran device App Store, contoh:
```
marketing/screenshots/
  6.7/                 # iPhone 15/16 Pro Max (1290×2796) — WAJIB
    01-gameplay.png
    02-home.png
    03-library.png
    04-result.png
    05-reward.png
  5.5/                 # iPhone 8 Plus (1242×2208) — kalau diminta
    01-gameplay.png
    ...
  android/             # Play Store (1080×1920+)
    ...
```
Urutan 01..05 = urutan tampil di store (lihat `docs/SCREENSHOT_DIRECTION.md`).

## Cara nangkap
Jalankan app lalu buka state-nya:
```bash
flutter run --dart-define=SCREENSHOT=gameplay   # home | library | gameplay | result | reward
```
atau in-app (debug): Settings → Developer → Mode Screenshot,
atau via route: `/screenshot/home`, `/screenshot/gameplay`, dst.

Tangkap PNG (Simulator: Cmd+S / device: tombol screenshot), lalu pindahkan
file-nya ke folder di atas. **Result** tangkap ~0.8–1.5 dtk setelah muncul
(biar confetti masih turun & skornya udah penuh).

> Aset marketing final (latar/bingkai hasil olahan) nanti di `marketing/appstore/`.
> Folder ini khusus tangkapan UI ASLI dari app.
