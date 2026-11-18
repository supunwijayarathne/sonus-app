import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Pill-shaped switch between a few options (e.g. "Adult user" / "Speech therapist").
///
/// The selected option is shown by a raised background *and* brighter text,
/// and screen readers announce it as selected (not colour alone).
class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  /// Value -> label, in display order.
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          for (final entry in options.entries)
            Expanded(child: _option(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _option(T optionValue, String label) {
    final selected = optionValue == value;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.surfaceRaised : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
          onTap: () => onChanged(optionValue),
          child: Container(
            height: AppSpacing.buttonHeight - 2 * AppSpacing.xs,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.option.copyWith(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
