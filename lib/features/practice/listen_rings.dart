import 'package:material_ui/material_ui.dart';

import '../../theme/app_colors.dart';

/// Three soft concentric rings behind the play button.
class ListenRings extends StatelessWidget {
  const ListenRings({super.key, required this.size, required this.child});

  /// Diameter of the outer ring.
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ring(size, AppColors.surfaceSunken),
          _ring(size * 0.84, AppColors.surface),
          _ring(
            size * 0.7,
            AppColors.background,
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child,
        ],
      ),
    );
  }

  Widget _ring(double diameter, Color color, {BoxBorder? border}) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: border,
      ),
    );
  }
}
