import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Round avatar with a person's initials ("NP").
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.initials, {super.key, this.size = 44});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.accentSurface,
          shape: BoxShape.circle,
        ),
        child: Text(
          initials,
          style: AppTypography.small.copyWith(
            color: AppColors.accent,
            fontSize: size * 0.34,
          ),
        ),
      ),
    );
  }
}
