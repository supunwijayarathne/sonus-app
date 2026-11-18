import 'package:material_ui/material_ui.dart';

import '../../models/practice_session.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/format.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/section_header.dart';
import '../../widgets/session_card.dart';
import '../../widgets/sonus_logo.dart';

/// History tab: past sessions grouped by month, newest first.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.sessions, this.onOpenSession});

  /// Newest first.
  final List<PracticeSession> sessions;
  final ValueChanged<PracticeSession>? onOpenSession;

  @override
  Widget build(BuildContext context) {
    // Group by "March 2026"; a LinkedHashMap keeps the newest month first.
    final byMonth = <String, List<PracticeSession>>{};
    for (final session in sessions) {
      byMonth.putIfAbsent(monthYear(session.at), () => []).add(session);
    }

    return ResponsivePage(
      builder: (context, scale) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          const Align(alignment: Alignment.centerLeft, child: SonusLogo()),
          const SizedBox(height: AppSpacing.xxl),
          Text('PRACTICE ARCHIVE', style: AppTypography.eyebrow),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your history',
            style: AppTypography.scaled(AppTypography.headline, scale),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Review previous sessions and revisit individual words.',
            style: AppTypography.body,
          ),
          if (sessions.isEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'No sessions yet. Your practice sessions will appear here.',
              style: AppTypography.small,
            ),
          ],
          for (final month in byMonth.entries) ...[
            const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
            SectionHeader(month.key),
            const SizedBox(height: AppSpacing.md),
            for (final session in month.value) ...[
              SessionCard(
                session: session,
                onTap: () => onOpenSession?.call(session),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
            ],
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
