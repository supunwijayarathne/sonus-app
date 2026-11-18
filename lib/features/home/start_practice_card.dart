import 'package:material_ui/material_ui.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/outline_pill.dart';

/// Big "Start practice" card on the home screen. The whole card is tappable.
class StartPracticeCard extends StatelessWidget {
  const StartPracticeCard({super.key, required this.scale, this.onTap});

  final double scale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.xl);

    return Semantics(
      button: true,
      label: 'Start practice. Listen, record, and understand each sound.',
      excludeSemantics: true,
      child: Material(
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.heroCardTop, AppColors.heroCardBottom],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: CustomPaint(
              painter: _CardDecorationPainter(),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    const OutlinePill('5 minute session', fontSize: 11),
                    SizedBox(height: AppSpacing.xxl * scale),
                    Text(
                      'Start practice',
                      style: AppTypography.scaled(
                        AppTypography.cardTitle,
                        scale,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            'Listen, record, and understand each sound.',
                            style: AppTypography.body.copyWith(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        // Visual only: the whole card is the button.
                        Container(
                          width: 48 * scale,
                          height: 48 * scale,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            color: AppColors.onAccent,
                            size: 22 * scale,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft circles in the bottom-right corner and a small waveform top-right.
class _CardDecorationPainter extends CustomPainter {
  // Bar heights of the little waveform (fractions of its max height).
  static const _bars = [
    0.3,
    0.5,
    0.35,
    0.7,
    0.45,
    0.85,
    1.0,
    0.6,
    0.9,
    0.5,
    0.75,
    0.4,
    0.55,
    0.3,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.98, h * 1.0);

    // Filled circles, slightly lighter than the card.
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.025);
    canvas.drawCircle(center, h * 0.72, fill);
    canvas.drawCircle(center, h * 0.6, fill);

    // Thin accent outline.
    final line = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, h * 0.52, line);

    // Waveform, top-right.
    final bar = Paint()
      ..color = AppColors.accentMuted
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    const gap = 5.6;
    const maxHeight = 30.0;
    final startX = w - AppSpacing.lg - (_bars.length - 1) * gap;
    final midY = AppSpacing.lg + maxHeight / 2;
    for (var i = 0; i < _bars.length; i++) {
      final half = maxHeight * _bars[i] / 2;
      final x = startX + i * gap;
      canvas.drawLine(Offset(x, midY - half), Offset(x, midY + half), bar);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
