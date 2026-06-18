# AI Visual Workflow — aturan & alur

Dokumen ini mengikat. Tujuannya: visual marketing yang menarik **tanpa**
menyesatkan reviewer App Store atau melanggar hak cipta.

## Prinsip wajib
1. **Screenshot asli HARUS ditangkap dari aplikasi Flutter yang benar-benar
   berjalan** (mode screenshot deterministik atau gameplay nyata). Bukan gambar.
2. **AI generatif (Nano Banana / Google AI Studio) HANYA boleh** untuk elemen
   **dekoratif**: frame/bingkai, latar belakang, konsep ikon, splash art, dan
   komposisi marketing (mis. feature graphic, latar di belakang screenshot asli).
3. **DILARANG** membuat UI palsu atau screenshot gameplay palsu dengan AI.
   Setiap piksel yang menampilkan UI/gameplay harus berasal dari app asli.
4. **DILARANG** memakai lagu berhak cipta, artis asli, sampul album asli, atau
   aset bermerek dagang — termasuk di gambar AI (jangan minta logo/artis nyata).
5. **Screenshot final App Store harus mencerminkan pengalaman app yang nyata.**
   Boleh ditempel di atas latar AI, tapi UI di dalamnya tidak boleh diubah.

## Alur kerja
```
                 ┌─ Tangkap screenshot ASLI dari app (mode screenshot)
                 │     → docs/SCREENSHOT_DIRECTION.md
 Aset final  ←───┤
                 │  ┌─ (opsional) Latar/bingkai/komposisi DEKORATIF via Nano Banana
                 └──┤     → docs/PROMO_ASSET_PROMPTS.md
                    └─ Tempel screenshot asli DI ATAS latar (tanpa ubah UI)
```

### Langkah
1. Jalankan app di simulator iPhone ukuran resmi (lihat SCREENSHOT_DIRECTION.md).
2. Buka layar mode screenshot (`--dart-define=SCREENSHOT=<nama>` atau
   Settings → Developer → Mode Screenshot).
3. Tangkap PNG (Cmd+S di Simulator / screenshot device fisik).
4. (Opsional) Buat latar/bingkai dekoratif di Nano Banana dgn prompt di
   PROMO_ASSET_PROMPTS.md.
5. Susun di Figma/Canva: latar AI di belakang, **screenshot asli di depan**,
   tambah teks fitur. Jangan menutupi/memalsukan UI.
6. Ekspor sesuai ukuran App Store.

## Ikon aplikasi
Ikon placeholder asli sudah ada (`assets/icon/app_icon.png`, di-generate
prosedural). Untuk versi final yang lebih artistik, lihat APP_ICON_DIRECTION.md —
boleh pakai Nano Banana untuk konsep, lalu rapikan & ekspor 1024×1024 (tanpa
alpha untuk iOS).

## Checklist kepatuhan sebelum submit
- [ ] Semua screenshot menampilkan UI app asli (dari mode screenshot/gameplay).
- [ ] Tidak ada UI/gameplay hasil AI.
- [ ] Tidak ada lagu/artis/logo berhak cipta di gambar mana pun.
- [ ] Latar AI hanya dekoratif, tidak mengklaim fitur yang tidak ada.
- [ ] Teks marketing jujur (mis. "lagu demo", bukan klaim katalog raksasa).
