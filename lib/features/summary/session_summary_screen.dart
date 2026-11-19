import 'package:material_ui/material_ui.dart';

import '../../models/practice_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/format.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/sonus_logo.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/status_label.dart';
import '../result/result_screen.dart';

/// Summary of one session: counts and one row per word.
/// Shown after the last word, and when opening a session from history.
class SessionSummaryScreen extends StatelessWidget {
  const SessionSummaryScreen({
    super.key,
    required this.session,
    this.justCompleted = false,
  });

  final PracticeSession session;

  /// True right after practising (shows the "Session completed" heading).
  final bool justCompleted;

  void _openResult(BuildContext context, WordAttempt attempt) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultScreen(attempt: attempt)),
    );
  }

  /// First word with a possible difference (or the first word).
  WordAttempt get _firstToReview => session.attempts.firstWhere(
    (a) => a.result.hasDifference,
    orElse: () => session.attempts.first,
  );

  String get _sentence {
    final words = plural(session.wordsPracticed, 'word');
    final n = session.possibleDifferences;
    if (n == 0) {
      return 'You practiced $words. '
          'All recordings matched the expected sounds.';
    }
    final recordings = n == 1 ? 'recording' : 'recordings';
    return 'You practiced $words. '
        '${numberWord(n)} $recordings may benefit from another listen.';
  }

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      builder: (context, scale) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          Stack(
            alignment: Alignment.center,
            children: [
              const Align(alignment: Alignment.centerLeft, child: SonusLogo()),
              Semantics(
                header: true,
                child: Text('Session summary', style: AppTypography.barTitle),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.onSuccess,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg + 4),
          Text(
            justCompleted
                ? 'SESSION COMPLETED'
                : sessionTime(session.at).toUpperCase(),
            style: AppTypography.eyebrow,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'A calm step\nforward.',
            style: AppTypography.scaled(AppTypography.headline, scale),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(_sentence, style: AppTypography.body),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '${session.wordsPracticed}',
                  label: 'Words practiced',
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: StatTile(
                  value: '${session.possibleDifferences}',
                  label: 'Possible differences',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg + 2),
          _WordList(
            attempts: session.attempts,
            onTap: (attempt) => _openResult(context, attempt),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => _openResult(context, _firstToReview),
            child: const Text('Review results'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              child: const Text('Return home'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// One row per word: Sinhala text + romanization, and its status.
class _WordList extends StatelessWidget {
  const _WordList({required this.attempts, required this.onTap});

  final List<WordAttempt> attempts;
  final ValueChanged<WordAttempt> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < attempts.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.fieldBorder),
            InkWell(
              onTap: () => onTap(attempts[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md + 2,
                  vertical: AppSpacing.md - 4,
                ),
                // Word on the left, status on the right; both shrink
                // (ellipsis) on narrow screens or with large system text.
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              attempts[i].word.text,
                              style: AppTypography.sinhalaWord.copyWith(
                                fontSize: 20,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md - 4),
                          Flexible(
                            child: Text(
                              attempts[i].word.romanized,
                              style: AppTypography.small,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: StatusLabel(
                        hasDifference: attempts[i].result.hasDifference,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
