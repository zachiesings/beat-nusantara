import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../state/game_state.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/mascot.dart';
import '../shell/main_shell.dart';

class _Page {
  final Mood mood;
  final Color color;
  final String title;
  final String body;
  const _Page(this.mood, this.color, this.title, this.body);
}

const _pages = [
  _Page(Mood.cheer, AppColors.cyan, 'Halo! Aku Melodi 👋',
      'Selamat datang di Beat Nusantara — game ritme premium dengan rasa lokal: pop, koplo, gamelan elektronik, dan banyak lagi!'),
  _Page(Mood.happy, AppColors.pink, 'Ketuk mengikuti irama 🎵',
      'Not jatuh ke garis. Ketuk lajur tepat waktu untuk PERFECT. Tahan, geser, kejar combo, dan nyalakan FEVER!'),
  _Page(Mood.wink, AppColors.gold, 'Adil & tanpa tekanan 💛',
      'Tidak ada lagu yang hilang, tidak ada hitung mundur menakutkan. Iklan 100% opsional — main gratis sepuasnya.'),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _i = 0;
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _pc.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _next() => _pc.nextPage(duration: AppDur.med, curve: Curves.easeOutCubic);

  void _finish() {
    final gs = context.read<GameState>();
    if (_nameCtrl.text.trim().isNotEmpty) gs.setName(_nameCtrl.text);
    gs.completeOnboarding();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                    onPressed: _finish, child: const Text('Lewati', style: TextStyle(color: AppColors.textLo))),
              ),
              Expanded(
                child: PageView(
                  controller: _pc,
                  onPageChanged: (i) => setState(() => _i = i),
                  children: [..._pages.map((p) => _PageView(p)), _namePage()],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length + 1, (i) {
                  final on = i == _i;
                  return AnimatedContainer(
                    duration: AppDur.fast,
                    margin: const EdgeInsets.all(4),
                    width: on ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: on ? AppColors.brandGradient : null,
                      color: on ? null : AppColors.glassBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: GradientButton(
                  label: _i < _pages.length ? 'Lanjut' : 'Mulai Main!',
                  icon: _i < _pages.length ? Icons.arrow_forward_rounded : Icons.play_arrow_rounded,
                  onTap: _i < _pages.length ? _next : _finish,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _namePage() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Mascot(size: 120, mood: Mood.cheer, color: AppColors.mint),
          const SizedBox(height: 20),
          Text('Siapa namamu?', style: AppText.title.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          const Text('Biar papan skormu makin personal ✨',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLo)),
          const SizedBox(height: 24),
          TextField(
            controller: _nameCtrl,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Pemain',
              filled: true,
              fillColor: AppColors.glass,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  final _Page p;
  const _PageView(this.p);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Mascot(size: 150, mood: p.mood, color: p.color),
          const SizedBox(height: 28),
          Text(p.title, textAlign: TextAlign.center, style: AppText.title.copyWith(fontSize: 26)),
          const SizedBox(height: 14),
          Text(p.body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLo, fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}
