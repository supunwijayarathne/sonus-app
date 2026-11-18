import 'package:material_ui/material_ui.dart';

import '../../models/analysis_result.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'result_text.dart';

/// "Expected" and "Detected" rows of sound chips, one column per alignment step.
///
/// Differences are shown with colour AND text (CLAUDE.md):
/// - substitution: the detected chip is highlighted,
/// - omission: the expected chip is struck through, the detected chip shows "–",
/// - addition: the expected chip shows "+",
/// and a line under the chips spells each change out ("m → n, possible substitution").
class PhonemeComparison extends StatelessWidget {
  const PhonemeComparison({super.key, required this.ops});

  final List<PhonemeOp> ops;

  @override
  Widget build(BuildContext context) {
    final changes = ops.where((op) => op.isDifference).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg - 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Row labels.
              ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rowLabel('Expected'),
                    const SizedBox(height: AppSpacing.md - 4),
                    _rowLabel('Detected'),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Chips: scroll sideways for long phrases.
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final op in ops)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: _column(op),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (changes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (final op in changes)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        ResultText.change(op),
                        style: AppTypography.small.copyWith(
                          color: AppColors.warning,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _rowLabel(String text) {
    return SizedBox(
      height: _Chip.height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: AppTypography.small.copyWith(fontSize: 13)),
      ),
    );
  }

  Widget _column(PhonemeOp op) {
    return Semantics(
      label: 'Sound ${op.position + 1}: ${ResultText.change(op)}',
      excludeSemantics: true,
      child: Column(
        children: [
          _Chip(
            text: op.expected ?? '+',
            highlighted: op.kind == OpKind.ins,
            struckThrough: op.kind == OpKind.del,
          ),
          const SizedBox(height: AppSpacing.md - 4),
          _Chip(text: op.predicted ?? '–', highlighted: op.isDifference),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    this.highlighted = false,
    this.struckThrough = false,
  });

  static const double height = 29;

  final String text;
  final bool highlighted;
  final bool struckThrough;

  @override
  Widget build(BuildContext context) {
    final changed = highlighted || struckThrough;
    return Container(
      height: height,
      constraints: const BoxConstraints(minWidth: height),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: changed ? AppColors.warningSurface : AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: changed ? Border.all(color: AppColors.warningBorder) : null,
      ),
      child: Text(
        text,
        style: AppTypography.option.copyWith(
          color: changed ? AppColors.warning : AppColors.textPrimary,
          decoration: struckThrough ? TextDecoration.lineThrough : null,
          decorationColor: AppColors.warning,
        ),
      ),
    );
  }
}
