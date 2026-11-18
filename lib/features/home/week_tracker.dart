import 'package:material_ui/material_ui.dart';

import '../../models/home_summary.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// "This week" card: one circle per day and a short message.
///
/// Days are told apart by shape and icon, not colour alone:
/// done = filled + check mark, today = outlined ring, open = plain dot.
class WeekTracker extends StatelessWidget {
  const WeekTracker({
    super.key,
    required this.week,
    required this.sessionsDone,
    required this.sessionsPlanned,
  });

  final List<DayStatus> week;
  final int sessionsDone;
  final int sessionsPlanned;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String get _message {
    final left = sessionsPlanned - sessionsDone;
    if (left <= 0) return 'You completed your weekly plan.';
    if (left == 1) return 'One more session to reach your weekly plan.';
    return '$left more sessions to reach your weekly plan.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 7; i++) Expanded(child: _day(i, week[i])),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: AppTypography.small.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _day(int index, DayStatus status) {
    final description = switch (status) {
      DayStatus.done => 'practiced',
      DayStatus.today => 'today',
      DayStatus.open => 'not yet',
    };

    return Semantics(
      label: '${_names[index]}, $description',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            _letters[index],
            style: AppTypography.small.copyWith(fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          // Shrinks on narrow screens so 7 circles always fit in one row.
          LayoutBuilder(
            builder: (context, constraints) {
              final size = (constraints.maxWidth - 6).clamp(20.0, 28.0);
              return _circle(status, size);
            },
          ),
        ],
      ),
    );
  }

  Widget _circle(DayStatus status, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (status) {
          DayStatus.done => AppColors.success,
          DayStatus.today => AppColors.surfaceRaised,
          DayStatus.open => AppColors.surfaceRaised,
        },
        border: status == DayStatus.today
            ? Border.all(color: AppColors.accent, width: 1.5)
            : null,
      ),
      child: status == DayStatus.done
          ? Icon(Icons.check, size: size * 0.5, color: AppColors.onSuccess)
          : null,
    );
  }
}
