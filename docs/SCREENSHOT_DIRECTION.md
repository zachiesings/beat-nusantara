# Screenshot Direction — App Store

Screenshot diambil dari **mode screenshot deterministik** (widget asli + data
fiktif stabil). Tidak ada gambar mock.

## Cara membuka layar screenshot
**A. Launch langsung (paling rapi untuk otomatisasi):**
```bash
flutter run --dart-define=SCREENSHOT=home      # atau library / gameplay / result / reward
```
**B. Dari dalam app (debug build):** Settings → Developer → **Mode Screenshot** →
pilih layar.

Route yang tersedia: `screenshot/home`, `screenshot/library`,
`screenshot/gameplay`, `screenshot/result`, `screenshot/reward`.

## Perangkat & ukuran (wajib Apple)
Tangkap minimal dua ukuran:
| Device (Simulator) | Resolusi portrait | Dipakai untuk |
|--------------------|-------------------|---------------|
| iPhone 15 Pro Max / 16 Pro Max (6.7–6.9") | 1290×2796 | slot 6.7" |
| iPhone 8 Plus (5.5") | 1242×2208 | slot 5.5" (jika diminta) |

Simulator: **File → Save Screen** (Cmd+S) menyimpan PNG resolusi penuh.

## 5 tangkapan & pesan tiap layar
Urutkan begini di App Store (kiri→kanan):

1. **screenshot/gameplay** — "Ketuk mengikuti irama"
   Frame beku: not jatuh di 5 lajur, COMBO 247, FEVER aktif, PERFECT muncul.
   *Headline saran:* "Rasakan ritme Nusantara".
2. **screenshot/home** — "Hub yang rapi & personal"
   Sapaan, Level 7, koin, misi, baris "Untuk Kamu", kategori.
   *Headline:* "Pop, Koplo, Gamelan — semua ada".
3. **screenshot/library** — "20+ lagu lintas genre"
   Kartu lagu premium, badge grade, filter.
   *Headline:* "Jelajahi katalog yang terus tumbuh".
4. **screenshot/result** — "Kejar grade SSS"
   Reveal grade SSS, akurasi 98.64%, Full Combo, koin/XP.
   *Headline:* "Perfect, Hebat, Full Combo!".
5. **screenshot/reward** — "Adil tanpa tekanan"
   Kosmetik (skin lajur, efek), lencana. Tegaskan tanpa IAP.
   *Headline:* "Hadiah dari bermain — bukan dari dompet".

## Aturan teks overlay (jujur)
- Boleh: "Lagu demo orisinal", "Tanpa pembelian dalam aplikasi", "Iklan opsional".
- Hindari: klaim lagu populer/artis nyata, jumlah lagu berlebihan, "gratis"
  yang menyesatkan.

## Timing tangkapan (penting)
- **Home / Library / Gameplay** = state statis → aman ditangkap kapan pun.
- **Result** = ada animasi sekali jalan: **tangkap ~0.8–1.5 dtk** setelah layar
  muncul supaya **confetti masih turun** dan angka skor (count-up) sudah berhenti
  di nilai final. Terlalu cepat = skor belum penuh; terlalu lambat = confetti habis
  (tinggal buka ulang route-nya).
- **Reward** = tile glow halus, aman kapan pun.

## Data demo (sudah di-art-direct)
Semua shot konsisten satu "cerita": pemain **Andini · Lv 7 · 2.450 koin**, lagu
sorotan **Koplo Neon (Expert)** tampil di Gameplay (combo 188, FEVER) lalu Result
(**SSS, Full Combo, 1.180.400**). Library penuh badge grade + favorit; Reward
menampilkan tiga state (Dipakai / beli koin / tonton iklan). Atur di
`lib/features/screenshot/demo_data.dart`.

## Tips kualitas
- Status bar bersih (Simulator → Features → Toggle Appearance untuk dark; waktu
  default Apple 9:41 otomatis di Simulator screenshot bila pakai `xcrun simctl
  status_bar`).
- Jangan crop UI penting; sisakan ruang untuk headline di atas/bawah.
