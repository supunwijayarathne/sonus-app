import 'package:material_ui/material_ui.dart';

import '../../models/home_summary.dart';
import '../../models/practice_session.dart';
import '../../models/practice_word.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/format.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sonus_logo.dart';
import '../../widgets/session_card.dart';
import 'start_practice_card.dart';
import 'week_tracker.dart';

/// Adult user's home tab: greeting, "Start practice" (or what to do first),
/// assigned exercises, this week, recent session.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.summary,
    required this.linked,
    required this.words,
    this.onStartPractice,
    this.onPractiseWord,
    this.onLinkTherapist,
    this.onViewHistory,
    this.onOpenSession,
  });

  final HomeSummary summary;

  /// Whether the user has linked a therapist (who assigns the words).
  final bool linked;

  /// Assigned words in practice order; null while loading.
  final List<PracticeWord>? words;

  final VoidCallback? onStartPractice;
  final ValueChanged<PracticeWord>? onPractiseWord;
  final VoidCallback? onLinkTherapist;
  final VoidCallback? onViewHistory;
  final ValueChanged<PracticeSession>? onOpenSession;

  /// The practice card, or what to do first, then the assigned words.
  List<Widget> _practice(double scale) {
    final words = this.words;
    if (!linked) {
      return [
        EmptyStateCard(
          icon: Icons.link,
          title: 'Link your therapist',
          message:
              'Your therapist chooses the words you practise. Ask them for '
              'their invite code.',
          actionLabel: 'Enter invite code',
          onAction: onLinkTherapist,
        ),
      ];
    }
    if (words != null && words.isEmpty) {
      return [
        const EmptyStateCard(
          icon: Icons.hourglass_empty,
          title: 'No exercises yet',
          message:
              'Your therapist hasn\'t assigned any words yet. They will '
              'appear here.',
        ),
      ];
    }
    return [
      StartPracticeCard(
        scale: scale,
        wordCount: words?.length,
        onTap: words == null ? null : onStartPractice,
      ),
      if (words != null) ...[
        const SizedBox(height: AppSpacing.xl + AppSpacing.xs),
        SectionHeader(
          'Your exercises',
          trailing: Text('${words.length}', style: AppTypography.small),
        ),
        const SizedBox(height: AppSpacing.md),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < words.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: AppColors.fieldBorder),
                _WordTile(
                  word: words[i],
                  onTap: () => onPractiseWord?.call(words[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final greeting = '${greetingFor(DateTime.now())}, ${summary.firstName}';

    return ResponsivePage(
      builder: (context, scale) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SonusLogo(),
              _Avatar(initials: summary.initials),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(greeting.toUpperCase(), style: AppTypography.eyebrow),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Ready for your\nnext practice?',
            style: AppTypography.scaled(AppTypography.headline, scale),
          ),
          const SizedBox(height: AppSpacing.xl + AppSpacing.xs),
          ..._practice(scale),
          const SizedBox(height: AppSpacing.xl + AppSpacing.xs),
          SectionHeader(
            'This week',
            trailing: Text(
              '${summary.sessionsDone} of ${plural(summary.sessionsPlanned, 'session')}',
              style: AppTypography.small,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          WeekTracker(
            week: summary.week,
            sessionsDone: summary.sessionsDone,
            sessionsPlanned: summary.sessionsPlanned,
          ),
          if (summary.recent != null) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              'Recent session',
              trailing: TextButton(
                onPressed: onViewHistory,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  textStyle: AppTypography.small.copyWith(fontSize: 15),
                ),
                child: const Text('View history'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SessionCard(
              session: summary.recent!,
              onTap: () => onOpenSession?.call(summary.recent!),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// One assigned word; tapping it practises only that word.
class _WordTile extends StatelessWidget {
  const _WordTile({required this.word, this.onTap});

  final PracticeWord word;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.text,
                    style: AppTypography.scaled(AppTypography.sinhalaWord, 0.5),
                  ),
                  if (word.romanized.isNotEmpty)
                    Text(word.romanized, style: AppTypography.small),
                ],
              ),
            ),
            Icon(
              Icons.mic_none,
              color: AppColors.accent,
              semanticLabel: 'Practise ${word.text}',
            ),
          ],
        ),
      ),
    );
  }
}

/// Round avatar with the user's initials.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        initials,
        style: AppTypography.small.copyWith(
          color: AppColors.accent,
          fontSize: 15,
        ),
      ),
    );
  }
}
