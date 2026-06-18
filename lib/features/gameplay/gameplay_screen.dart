import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../core/haptics.dart';
import '../../game/chart_loader/chart_loader.dart';
import '../../game/engine/game_engine.dart';
import '../../game/models/chart.dart';
import '../../game/models/song.dart';
import '../../game/rendering/note_painter.dart';
import '../../game/scoring/judgment.dart';
import '../../services/ads/ads_service.dart';
import '../../services/audio/audio_service.dart';
import '../../state/game_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/reward_ad_sheet.dart';
import 'game_hud.dart';
import '../results/result_screen.dart';

class GameplayScreen extends StatefulWidget {
  final Song song;
  final String difficulty;
  final String chartPath;
  final double speedMult;
  final String modeLabel;
  const GameplayScreen({
    super.key,
    required this.song,
    required this.difficulty,
    required this.chartPath,
    this.speedMult = 1.0,
    this.modeLabel = 'Klasik',
  });

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with SingleTickerProviderStateMixin {
  final Stopwatch _sw = Stopwatch();
  final ValueNotifier<int> _frame = ValueNotifier(0);
  final Map<int, int> _laneFlash = {};
  late final Ticker _ticker;

  Chart? _chart;
  GameEngine? _engine;
  late double _approachMs;
  late AudioService _audio;

  bool _loading = true;
  bool _running = false;
  bool _paused = false;
  bool _showRevive = false;
  bool _navigated = false;
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _audio = context.read<AudioService>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final gs = context.read<GameState>();
    final chart = await ChartLoader.load(widget.chartPath);
    if (!mounted) return;
    if (chart == null || chart.notes.isEmpty) {
      _failLoad();
      return;
    }
    _approachMs = K.approachMs / (widget.speedMult * gs.noteSpeed);
    final engine = GameEngine(chart, calibrationMs: gs.calibrationMs)
      ..onJudge = _onJudge
      ..onFail = _onFail
      ..onFinish = _onFinish;
    setState(() {
      _chart = chart;
      _engine = engine;
      _loading = false;
    });
    await _runCountdown();
  }

  void _failLoad() {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chart tidak dapat dimuat.')));
    Navigator.pop(context);
  }

  Future<void> _runCountdown() async {
    for (var i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      Haptics.select();
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
    if (!mounted) return;
    setState(() => _countdown = 0);
    _begin();
  }

  void _begin() {
    _running = true;
    _sw.start();
    _ticker.start();
    _audio.playSong(widget.song.audioAssetPath);
  }

  void _onTick(Duration _) {
    if (!_running || _paused) return;
    final ms = _sw.elapsedMilliseconds;
    _engine!.update(ms);
    _frame.value++;
  }

  void _onJudge(Judgment j, int lane) {
    _laneFlash[lane] = _sw.elapsedMilliseconds;
    switch (j) {
      case Judgment.perfect:
        _audio.playSfx('perfect');
        Haptics.light();
      case Judgment.great:
      case Judgment.good:
        _audio.playSfx('hit');
        Haptics.light();
      case Judgment.miss:
        _audio.playSfx('miss');
    }
  }

  void _press(int lane) {
    final e = _engine;
    if (e == null || !_running || _paused) return;
    e.songTimeMs = _sw.elapsedMilliseconds; // tighten input timing
    e.pressLane(lane);
  }

  // ---- pause / resume ----
  void _pause() {
    if (!_running || _paused) return;
    setState(() => _paused = true);
    _engine!.paused = true;
    _sw.stop();
    _audio.pauseSong();
  }

  void _resume() {
    if (!_paused) return;
    setState(() => _paused = false);
    _engine!.paused = false;
    _sw.start();
    _audio.resumeSong();
  }

  // ---- fail / revive (one rewarded revive per attempt) ----
  void _onFail() {
    _running = false;
    _sw.stop();
    _audio.pauseSong();
    Haptics.heavy();
    setState(() => _showRevive = true);
  }

  Future<void> _reviveViaAd() async {
    final granted = await showRewardAdSheet(
      context,
      kind: RewardKind.revive,
      title: 'Bangkit lagi?',
      reward: 'Lanjutkan lagu ini dari titik sekarang (HP dipulihkan)',
    );
    if (!mounted) return;
    if (granted) {
      _engine!.revive();
      setState(() => _showRevive = false);
      _running = true;
      _sw.start();
      _audio.resumeSong();
    }
  }

  void _giveUp() {
    setState(() => _showRevive = false);
    _engine!.giveUp();
  }

  void _onFinish() {
    if (_navigated) return;
    _navigated = true;
    _running = false;
    _sw.stop();
    _audio.stopSong();
    final gs = context.read<GameState>();
    final result = _engine!.buildResult();
    gs.recordResult(widget.song.id, widget.difficulty, result);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          song: widget.song,
          difficulty: widget.difficulty,
          result: result,
        ),
      ),
    );
  }

  Future<void> _confirmExit() async {
    final wasRunning = _running && !_paused;
    if (wasRunning) _pause();
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Keluar dari lagu?'),
        content: const Text('Progres lagu ini tidak akan disimpan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Lanjut main')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Keluar', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (leave == true && mounted) {
      _audio.stopSong();
      Navigator.pop(context);
    } else if (wasRunning && mounted) {
      _resume();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    _audio.stopSong();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.read<GameState>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: _loading || _engine == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
            : Stack(
                children: [
                  // playfield
                  Positioned.fill(
                    child: CustomPaint(
                      painter: NotePainter(
                        engine: _engine!,
                        approachMs: _approachMs,
                        laneCount: _engine!.laneCount,
                        laneFlash: _laneFlash,
                        reduceEffects: gs.reduceEffects,
                        highContrast: gs.highContrast,
                        repaint: _frame,
                      ),
                    ),
                  ),
                  // touch lanes
                  Positioned.fill(child: _inputLanes(gs)),
                  // HUD
                  _hud(),
                  _judgmentPopup(),
                  if (_countdown > 0) _countdownOverlay(),
                  if (_paused) _pauseOverlay(),
                  if (_showRevive) _reviveOverlay(),
                ],
              ),
      ),
    );
  }

  Widget _inputLanes(GameState gs) {
    final n = _engine!.laneCount;
    final hitFromBottom = MediaQuery.of(context).size.height * K.hitLineFromBottom;
    final pad = gs.largerHitZone ? 40.0 : 0.0;
    return Padding(
      padding: EdgeInsets.only(bottom: (hitFromBottom - 60 - pad).clamp(0.0, 400.0).toDouble()),
      child: Row(
        children: List.generate(n, (i) {
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _press(i),
              child: const SizedBox.expand(),
            ),
          );
        }),
      ),
    );
  }

  Widget _hud() {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _frame,
        builder: (_, __) {
          final e = _engine!;
          final b = e.board;
          return GameHud(
            title: widget.song.title,
            difficulty: widget.difficulty,
            mode: widget.modeLabel,
            score: b.score,
            accuracy: b.accuracy,
            combo: b.combo,
            hp: b.hp / K.hpMax,
            fever: e.fever,
            feverActive: e.feverActive,
            progress: e.progress,
            onPause: _pause,
          );
        },
      ),
    );
  }

  Widget _judgmentPopup() {
    return AnimatedBuilder(
      animation: _frame,
      builder: (_, __) {
        final e = _engine!;
        final j = e.lastJudgment;
        if (j == null) return const SizedBox.shrink();
        final age = _sw.elapsedMilliseconds - e.lastJudgmentAt;
        if (age < 0 || age > 400) return const SizedBox.shrink();
        final t = 1 - age / 400;
        final hitY = MediaQuery.of(context).size.height * (1 - K.hitLineFromBottom);
        return Positioned(
          top: hitY - 90,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Opacity(
              opacity: t.clamp(0.0, 1.0).toDouble(),
              child: Transform.translate(
                offset: Offset(0, -10 * (1 - t)),
                child: Center(
                  child: Text(
                    j.labelId,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: j.color,
                      shadows: [Shadow(color: j.color.withValues(alpha: 0.6), blurRadius: 12)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _countdownOverlay() => Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: Text('$_countdown',
            style: const TextStyle(
                fontSize: 96, fontWeight: FontWeight.w800, color: AppColors.cyan)),
      );

  Widget _pauseOverlay() => Container(
        color: Colors.black87,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Jeda',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              GradientButton(label: 'Lanjut', icon: Icons.play_arrow_rounded, onTap: _resume),
              const SizedBox(height: 10),
              TextButton(
                  onPressed: _confirmExit,
                  child: const Text('Keluar', style: TextStyle(color: AppColors.danger))),
            ],
          ),
        ),
      );

  Widget _reviveOverlay() => Container(
        color: Colors.black87,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassPanel(
            tint: AppColors.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.heart_broken, size: 56, color: AppColors.danger),
                const SizedBox(height: 12),
                const Text('HP habis!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  _engine!.reviveUsed
                      ? 'Revive sudah dipakai untuk lagu ini.'
                      : 'Bangkit sekali lagi lewat iklan opsional, atau akhiri lagu.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textLo),
                ),
                const SizedBox(height: 20),
                if (!_engine!.reviveUsed)
                  GradientButton(
                    label: 'Bangkit (iklan)',
                    icon: Icons.favorite,
                    onTap: _reviveViaAd,
                  ),
                const SizedBox(height: 10),
                TextButton(
                    onPressed: _giveUp,
                    child: const Text('Akhiri & lihat skor',
                        style: TextStyle(color: AppColors.textLo))),
              ],
            ),
          ),
        ),
      );
}
