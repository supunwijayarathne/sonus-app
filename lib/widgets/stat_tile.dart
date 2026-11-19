import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Card with a big number and a label ("5 / Words practiced").
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
  });

  final String value;
  final String label;

  /// Optional icon above the number (therapist overview).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.accent, size: 22),
              const SizedBox(height: AppSpacing.xl),
            ],
            Text(
              value,
              style: AppTypography.cardTitle.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: AppTypography.small),
          ],
        ),
      ),
    );
  }
}
