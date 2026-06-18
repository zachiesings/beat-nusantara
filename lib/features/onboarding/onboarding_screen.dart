import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../state/game_state.dart';
import '../../widgets/gradient_button.dart';
import '../home/home_screen.dart';

class _Page {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _Page(this.icon, this.title, this.body, this.color);
}

const _pages = [
  _Page(Icons.music_note, 'Selamat datang di Beat Nusantara',
      'Game ritme premium dengan rasa lokal — pop, koplo, gamelan elektronik, dan lebih banyak lagi.',
      AppColors.violet),
  _Page(Icons.touch_app, 'Ketuk mengikuti irama',
      'Not jatuh ke garis. Ketuk lajur tepat waktu untuk PERFECT. Tahan, geser, dan kejar combo!',
      AppColors.pink),
  _Page(Icons.favorite, 'Adil & tanpa tekanan',
      'Tidak ada lagu yang hilang, tidak ada hitung mundur menakutkan. Iklan 100% opsional — main gratis sepuasnya.',
      AppColors.cyan),
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

  void _next() {
    if (_i < _pages.length) {
      _pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _finish() {
    final gs = context.read<GameState>();
    if (_nameCtrl.text.trim().isNotEmpty) gs.setName(_nameCtrl.text);
    gs.completeOnboarding();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const HomeScreen()));
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
                  onPressed: _finish,
                  child: const Text('Lewati', style: TextStyle(color: AppColors.textLo)),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pc,
                  onPageChanged: (i) => setState(() => _i = i),
                  children: [
                    ..._pages.map((p) => _PageView(p)),
                    _namePage(),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length + 1, (i) {
                  final on = i == _i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.all(4),
                    width: on ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: on ? AppColors.cyan : AppColors.glassBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: GradientButton(
                  label: _i < _pages.length ? 'Lanjut' : 'Mulai Main',
                  icon: _i < _pages.length ? Icons.arrow_forward : Icons.play_arrow_rounded,
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
          const Icon(Icons.badge, size: 64, color: AppColors.cyan),
          const SizedBox(height: 20),
          const Text('Siapa namamu?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Buat papan skormu lebih personal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLo)),
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
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                  colors: [p.color.withValues(alpha: 0.5), Colors.transparent]),
            ),
            child: Icon(p.icon, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text(p.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 14),
          Text(p.body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLo, fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}
