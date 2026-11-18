import 'package:material_ui/material_ui.dart';

import '../../theme/app_colors.dart';

/// Decorative row of slanted dashes (a "sound wave") that fades in from the left.
/// Purely visual, so it is hidden from screen readers.
class SoundDashes extends StatelessWidget {
  const SoundDashes({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(painter: _DashesPainter(), size: Size.infinite),
    );
  }
}

class _DashesPainter extends CustomPainter {
  static const double _gap = 13; // distance between dashes
  static const double _dashWidth = 9;
  static const double _slant = 4; // how far each dash leans

  @override
  void paint(Canvas canvas, Size size) {
    final count = (size.width / _gap).floor();
    final y = size.height / 2;

    for (var i = 0; i < count; i++) {
      final x = i * _gap;
      final t = i / (count - 1); // 0 at the left, 1 at the right
      final paint = Paint()
        ..color = AppColors.accentMuted.withValues(alpha: 0.25 + 0.75 * t)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, y + _slant / 2),
        Offset(x + _dashWidth, y - _slant / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
