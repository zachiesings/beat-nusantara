import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../widgets/glass_panel.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        motif: BatikMotif.ceplok,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              Row(children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context)),
                const Text('Tentang & Legal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 12),
              Center(
                child: Column(children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                        gradient: AppColors.brandGradient, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text(K.appName,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const Text('Versi 1.0.0', style: TextStyle(color: AppColors.textLo)),
                ]),
              ),
              const SizedBox(height: 20),
              _card('Desain yang adil', Icons.favorite, [
                'Tidak ada lagu yang menghilang atau event terbatas waktu.',
                'Tidak ada hukuman streak harian.',
                'Iklan 100% opsional — tidak pernah otomatis, selalu bisa ditolak.',
                'Tidak ada pembelian dalam aplikasi. Tidak ada mata uang berbayar.',
                'Semua lagu dasar bisa dimainkan gratis.',
              ]),
              _card('Musik & lisensi', Icons.library_music, [
                'Semua lagu, judul, dan nama artis dalam game ini fiktif/orisinal.',
                'Audio demo dihasilkan secara prosedural (bukan lagu berhak cipta).',
                'Lagu berlisensi akan ditambahkan lewat manifest tanpa mengubah game.',
              ]),
              _card('Kredit', Icons.code, [
                'Font: Plus Jakarta Sans (SIL Open Font License).',
                'Audio & seni placeholder: dibuat khusus untuk game ini.',
                'Dibuat dengan Flutter.',
              ]),
              GlassPanel(
                onTap: () => _reportAd(context),
                child: Row(children: const [
                  Icon(Icons.flag, color: AppColors.danger),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Laporkan iklan tidak pantas',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textLo),
                ]),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('© 2026 Beat Nusantara',
                    style: TextStyle(color: AppColors.textLo, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String title, IconData icon, List<String> points) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: AppColors.cyan, size: 20),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ]),
              const SizedBox(height: 10),
              ...points.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('• ', style: TextStyle(color: AppColors.cyan)),
                      Expanded(
                          child: Text(p,
                              style: const TextStyle(color: AppColors.textLo, fontSize: 13, height: 1.4))),
                    ]),
                  )),
            ],
          ),
        ),
      );

  void _reportAd(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Laporkan iklan'),
        content: const Text(
            'Saat AdMob aktif, laporan diteruskan ke jaringan iklan. Pada build '
            'pengembangan ini, iklan masih berupa contoh (stub) sehingga tidak ada '
            'iklan nyata untuk dilaporkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mengerti')),
        ],
      ),
    );
  }
}
