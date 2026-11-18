import 'package:material_ui/material_ui.dart';

import '../../models/home_summary.dart';
import '../../models/practice_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/format.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sonus_logo.dart';
import '../../widgets/session_card.dart';
import 'start_practice_card.dart';
import 'week_tracker.dart';

/// Adult user's home tab: greeting, "Start practice", this week, recent session.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.summary,
    this.onStartPractice,
    this.onViewHistory,
    this.onOpenSession,
  });

  final HomeSummary summary;
  final VoidCallback? onStartPractice;
  final VoidCallback? onViewHistory;
  final ValueChanged<PracticeSession>? onOpenSession;

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
          StartPracticeCard(scale: scale, onTap: onStartPractice),
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
