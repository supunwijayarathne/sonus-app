import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Round "back" button in the top-left corner of a screen.
class RoundBackButton extends StatelessWidget {
  const RoundBackButton({super.key, this.onPressed});

  /// Defaults to going back one screen.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      tooltip: 'Back',
      icon: const Icon(Icons.chevron_left, size: 26),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        fixedSize: const Size.square(AppSpacing.iconButtonSize),
      ),
    );
  }
}
