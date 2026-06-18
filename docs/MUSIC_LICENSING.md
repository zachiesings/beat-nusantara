# Music & Licensing

## Status sekarang
- **Tidak ada lagu/artis berhak cipta** di repo ini.
- Audio demo (`assets/audio/songs/*.wav`) **dihasilkan secara prosedural** oleh
  `tool/generate_assets.py` (sintesis nada murni stdlib Python) — 100% orisinal.
- Semua judul & nama artis di `song_manifest.json` **fiktif**.
- SFX (`assets/audio/sfx/*`) juga di-generate.

## Aturan emas
Jangan pernah menambahkan lagu populer, nama artis asli, sampul album, lirik,
atau audio dari YouTube/Spotify/Apple Music **kecuali** kamu memegang lisensi
tertulis. Tandai aset berlisensi dengan jelas saat menambahkannya.

## Mengganti placeholder dengan audio berlisensi
1. Dapatkan lisensi (sync/mechanical) untuk lagu + hak distribusi di app store.
2. Taruh file audio di `assets/audio/songs/<id>.<ext>` (mp3/m4a/wav didukung
   audioplayers). Taruh cover di `assets/images/<id>.png`.
3. Buat chart `assets/charts/<id>__<diff>.json` (format di GAME_DESIGN.md).
   - Untuk akurasi, samakan `bpm` & `offsetMs` dengan audio.
4. Edit entri di `assets/song_manifest.json`:
   ```json
   {
     "id": "<id>",
     "title": "<judul berlisensi>",
     "artistDisplayName": "<artis berlisensi>",
     "audioAssetPath": "assets/audio/songs/<id>.mp3",
     "coverAssetPath": "assets/images/<id>.png",
     "availableDifficulties": ["Normal","Hard"],
     "chartPaths": { "Normal": "assets/charts/<id>__normal.json" },
     "unlockType": "free",
     "playable": true,
     "_licensed": "asset provided & licensed by user"
   }
   ```
5. `pubspec.yaml` sudah meng-include folder `assets/audio/songs/`,
   `assets/charts/`, `assets/images/` — tidak perlu tambah path satu-satu.
6. Build ulang. Tidak ada perubahan kode.

## Catatan App Store
Apple/Google bisa meminta bukti hak atas musik. Simpan dokumen lisensi.
Jangan kirim build dengan musik berhak cipta tanpa izin (alasan penolakan umum).
