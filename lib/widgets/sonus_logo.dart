import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Sonus logo mark + "sonus" wordmark.
///
/// The mark is drawn in code for now (two rounded lobes joined by a bar).
/// Replace it with the exported SVG from Figma when available.
class SonusLogo extends StatelessWidget {
  const SonusLogo({super.key, this.size = 28});

  /// Height of the mark; the wordmark scales with it.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: Size(size * 0.75, size), painter: _MarkPainter()),
        SizedBox(width: size * 0.55),
        Text(
          'sonus',
          style: AppTypography.scaled(AppTypography.brand, size / 28),
        ),
      ],
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.accent;
    final w = size.width;
    final h = size.height;

    // Left lobe (a bit shorter), right lobe (full height), bar between them.
    canvas.drawOval(Rect.fromLTRB(0, h * 0.14, w * 0.44, h * 0.86), paint);
    canvas.drawOval(Rect.fromLTRB(w * 0.52, 0, w, h), paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.3, h * 0.44, w * 0.7, h * 0.56),
        Radius.circular(h * 0.06),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
