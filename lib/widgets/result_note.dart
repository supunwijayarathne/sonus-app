import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The note shown on EVERY result screen (CLAUDE.md rule 1):
/// the result is a suggestion, and the match measures sound-sequence
/// agreement, not speech health or therapy progress.
class ResultNote extends StatelessWidget {
  const ResultNote({super.key});

  static const text =
      'This automated result compares your sounds with the expected sounds. '
      'It is a suggestion for practice and for your therapist to review, '
      'not a measure of speech health or progress.';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.noteSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.accent, size: 22),
          const SizedBox(width: AppSpacing.md - 4),
          Expanded(
            child: Text(text, style: AppTypography.small.copyWith(height: 1.5)),
          ),
        ],
      ),
    );
  }
}
