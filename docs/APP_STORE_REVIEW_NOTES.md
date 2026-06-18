# App Store Review Notes — Beat Nusantara

Catatan untuk reviewer & untuk kita sebelum submit. Pelajaran dari penolakan
sebelumnya (Guideline 2.1, dll) sudah diterapkan.

## Ringkasan untuk reviewer (tempel di App Review Information → Notes)
> Beat Nusantara is a rhythm music game. All songs, titles, and artist names are
> fictional/original; demo audio is procedurally generated (no copyrighted music).
> The base catalog of songs is fully free to play. There are NO in-app purchases.
> Rewarded ads are 100% optional, never auto-triggered, always skippable, and the
> reward is disclosed before viewing. The build can be made fully ad-free for
> review by setting `K.adsEnabled = false`.

## Checklist sebelum submit
- [ ] **Tanpa placeholder/coming-soon yang menghalangi**: lagu "Segera" hanya 1
      entri finale dan tidak menutupi fungsi inti; 3 lagu demo bisa dimainkan penuh.
- [ ] **Gratis = benar-benar gratis**: katalog dasar bisa dimainkan tanpa bayar/iklan.
- [ ] **Tanpa IAP**: tidak ada `in_app_purchase`. Tidak ada mata uang berbayar.
- [ ] **Iklan jujur**: opsional, ada tombol tolak, hadiah jelas, tidak otomatis,
      tidak ada interstitial saat gameplay. (Lihat ADMOB_NOTES.md.)
- [ ] **Musik**: tidak ada lagu/artis berhak cipta. Simpan bukti kalau pakai
      aset berlisensi. (Lihat MUSIC_LICENSING.md.)
- [ ] **Privasi**: isi App Privacy. Stub ads = tidak mengumpulkan data. Saat
      AdMob asli aktif → deklarasikan pengumpulan data iklan & tambahkan link
      kebijakan privasi.
- [ ] **Fungsi minimum**: game punya banyak layar, progres, scoring nyata — bukan
      web wrapper / app kosong.
- [ ] **Build pipeline nyata**: IPA dibangun via Codemagic, bukan binari kosong.
- [ ] **Kinerja**: tidak ada red screen / crash aset hilang (audio hilang =
      fallback senyap, game tetap jalan).

## Mode review bebas iklan
Set di `lib/core/constants.dart`:
```dart
static const bool adsEnabled = false;
```
Semua titik iklan akan menonaktifkan dirinya (tombol tidak muncul / no-op).

## Privasi (App Privacy questionnaire)
- Saat **stub** (default): "Data Not Collected".
- Saat **AdMob asli**: deklarasikan *Identifiers* & *Usage Data* untuk
  "Third-Party Advertising"; sediakan URL kebijakan privasi (wajib AdMob).

## Klasifikasi
- Kategori: Games → Music / Arcade.
- Rating: cocok untuk semua umur (tidak ada konten sensitif). Jika ada iklan
  pihak ketiga, set kuesioner umur sesuai.
