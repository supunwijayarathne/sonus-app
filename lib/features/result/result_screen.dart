import 'package:material_ui/material_ui.dart';

import '../../models/practice_session.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/audio_row.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/result_note.dart';
import '../../widgets/round_back_button.dart';
import '../../widgets/status_label.dart';
import 'phoneme_comparison.dart';
import 'result_text.dart';

/// Automated result for one recorded word.
///
/// Used in two ways:
/// - right after recording: shows "Next word" and "Try again",
/// - when reviewing a past session: both callbacks are null, buttons hidden.
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.attempt,
    this.onNext,
    this.onTryAgain,
    this.nextLabel = 'Next word',
  });

  final WordAttempt attempt;
  final VoidCallback? onNext;
  final VoidCallback? onTryAgain;

  /// "Next word", or "See summary" after the last word.
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final result = attempt.result;

    return ResponsivePage(
      builder: (context, scale) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const SizedBox(
                width: 64,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: RoundBackButton(),
                ),
              ),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Your result',
                    textAlign: TextAlign.center,
                    style: AppTypography.barTitle,
                  ),
                ),
              ),
              const SizedBox(width: 64),
            ],
          ),
          const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
          if (result.quality.ok)
            Center(
              child: StatusLabel(
                hasDifference: result.hasDifference,
                showDot: true,
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'TARGET WORD',
            textAlign: TextAlign.center,
            style: AppTypography.fieldLabel.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            attempt.word.text,
            textAlign: TextAlign.center,
            style: AppTypography.scaled(
              AppTypography.sinhalaWord,
              scale * 0.85,
            ),
          ),
          Text(
            attempt.word.romanized,
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            ResultText.title(result),
            textAlign: TextAlign.center,
            style: AppTypography.scaled(AppTypography.cardTitle, scale * 0.95),
          ),
          const SizedBox(height: AppSpacing.md - 4),
          Text(
            ResultText.explanation(result),
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (result.quality.ok) ...[
            PhonemeComparison(ops: result.ops),
            const SizedBox(height: AppSpacing.md),
          ],
          const ResultNote(),
          const SizedBox(height: AppSpacing.md),
          AudioRow(
            icon: Icons.volume_up_outlined,
            title: 'Reference audio',
            length: attempt.referenceLength,
          ),
          const SizedBox(height: AppSpacing.md - 4),
          AudioRow(
            icon: Icons.mic_none,
            title: 'Your recording',
            length: attempt.recordingLength,
          ),
          if (onNext != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onNext, child: Text(nextLabel)),
          ],
          if (onTryAgain != null) ...[
            const SizedBox(height: AppSpacing.md - 4),
            OutlinedButton(
              onPressed: onTryAgain,
              child: const Text('Try again'),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
