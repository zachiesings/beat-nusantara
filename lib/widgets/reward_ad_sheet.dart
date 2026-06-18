import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../services/ads/ads_service.dart';
import 'gradient_button.dart';
import 'glass_panel.dart';

/// Shows an HONEST rewarded-ad disclosure. The user always sees EXACTLY what
/// they get before any ad plays, the decline option is always visible, and the
/// ad is never auto-triggered. Returns true only if the user opted in AND the
/// (stub/real) ad completed.
///
/// This single component is the only place ads are initiated app-wide, so the
/// ethical rules are enforced in one spot.
Future<bool> showRewardAdSheet(
  BuildContext context, {
  required RewardKind kind,
  required String title,
  required String reward,
}) async {
  final ads = context.read<AdsService>();
  if (!ads.available) return false;

  final opted = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _RewardSheet(title: title, reward: reward),
  );
  if (opted != true) return false;
  if (!context.mounted) return false;

  // Show a lightweight "ad playing" overlay while the (stub) ad runs.
  final granted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PlayingAdDialog(),
    // kick off the ad and close when done
  ).then((v) => v ?? false);

  return granted;
}

class _RewardSheet extends StatelessWidget {
  final String title;
  final String reward;
  const _RewardSheet({required this.title, required this.reward});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GlassPanel(
          tint: AppColors.surface,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.slow_motion_video, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textLo),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard, color: AppColors.cyan, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Kamu akan dapat: $reward',
                          style: const TextStyle(color: AppColors.textHi, fontSize: 14)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Menonton iklan ini sepenuhnya opsional. Kamu tetap bisa bermain '
                'gratis tanpa menonton. Tidak ada batas waktu atau paksaan.',
                style: TextStyle(color: AppColors.textLo, fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Tonton Iklan',
                icon: Icons.play_arrow_rounded,
                onTap: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Nanti saja',
                      style: TextStyle(color: AppColors.textLo)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayingAdDialog extends StatefulWidget {
  const _PlayingAdDialog();
  @override
  State<_PlayingAdDialog> createState() => _PlayingAdDialogState();
}

class _PlayingAdDialogState extends State<_PlayingAdDialog> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final ads = context.read<AdsService>();
    final granted = await ads.showRewarded(RewardKind.bonusCoins);
    if (mounted) Navigator.pop(context, granted);
  }

  @override
  Widget build(BuildContext context) {
    return const Dialog(
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.cyan),
            SizedBox(height: 18),
            Text('Memutar iklan…',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            SizedBox(height: 6),
            Text('(Mode pengembangan: iklan contoh)',
                style: TextStyle(color: AppColors.textLo, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
