# Game Design — Beat Nusantara

## Loop inti
Not jatuh vertikal menuju **hit line**. Pemain mengetuk lajur tepat waktu.
Timing dinilai → score + combo + akurasi + HP + fever. Lagu selesai → layar hasil
dengan grade. HP habis → tawaran **revive** (iklan opsional, sekali per lagu).

## Judgment & scoring
Window (± ms, bisa digeser oleh `calibrationMs`):

| Judgment | Window | Base | Bobot akurasi | HP |
|----------|--------|------|---------------|----|
| Perfect  | ±35    | 300  | 1.00          | +2 |
| Hebat    | ±70    | 200  | 0.66          | +1 |
| Oke      | ±110   | 100  | 0.33          | 0  |
| Lewat    | —      | 0    | 0.00          | −7 |

- **Score** = Σ `base × comboMult × feverMult` (golden ×2 base).
- **comboMult** = 1.0 + (combo÷10)×0.1, maksimal 2.0.
- **feverMult** = 2.0 saat Fever aktif, selain itu 1.0.
- **Akurasi** = Σ(bobot) / jumlah not dinilai × 100.
- **Grade**: SSS (≥99% + full combo), SS ≥96, S ≥92, A ≥85, B ≥75, C ≥60, D.
- **Fever**: terisi +0.04 per hit (−0.12 saat miss). Penuh → Fever 6 dtk (score ×2).
- **HP**: mulai 100. Habis → fail + tawaran revive (sekali).

Semua angka ada di `lib/core/constants.dart` (`K`).

## Jenis not
`tap` · `hold` (kepala+ekor) · `slide` (seperti hold, rasa horizontal) ·
`flick` (punya `direction`) · `double` (dua not simultan di lajur berbeda) ·
`golden` (×2 score) · `fever` (mengisi fever lebih cepat).

> Catatan jujur: deteksi gesture penuh untuk flick (arah swipe) dan pelepasan
> hold di-judge pada **kepala** not; ekor hold otomatis selesai di `endTimeMs`.
> Penyempurnaan gesture = Phase 2. Ini disengaja agar input mulus & bebas bug.

## Mode
Klasik (1.0×), Speed (1.4×), Santai (0.75×) — variasi kecepatan dari chart yang
sama. Jumlah lajur (4/5) ditentukan oleh chart. Scaffold Boss/Finale & Daily Mix
ada di katalog (tanpa FOMO).

## Format chart (beatmap JSON)
`assets/charts/<songId>__<difficulty>.json`:
```json
{
  "songId": "senja_jakarta",
  "difficulty": "Normal",
  "bpm": 88,
  "offsetMs": 0,
  "notes": [
    { "type": "tap",  "lane": 1, "startTimeMs": 1022 },
    { "type": "hold", "lane": 3, "startTimeMs": 1363, "endTimeMs": 2385 },
    { "type": "flick","lane": 1, "startTimeMs": 3409, "direction": "up" },
    { "type": "golden","lane": 2, "startTimeMs": 5113 }
  ]
}
```
- `lane` mulai dari 0. Jumlah lajur = lane maksimum + 1.
- `double` = cukup dua not dengan `startTimeMs` sama di lajur berbeda.
- Dimuat oleh `lib/game/chart_loader/chart_loader.dart` (gagal → null, tidak crash).

## Manifest lagu
`assets/song_manifest.json` → field per lagu: `id, title, artistDisplayName,
genre, regionTag, category, bpm, durationMs, audioAssetPath, coverAssetPath,
availableDifficulties, chartPaths{diff:path}, unlockType, unlockCost,
previewStartTimeMs, playable`.

`unlockType`: `free | coins | level | sessionAd | comingSoon` — semuanya
**bukan** mekanik waktu/FOMO.

## Generator aset (sumber kebenaran tunggal)
`tool/generate_assets.py` menempatkan ketukan audio **dan** not chart dari grid
beat yang sama, jadi ketukan yang terdengar = not yang diketuk. Jalankan ulang
kapan saja: `python3 tool/generate_assets.py`.
