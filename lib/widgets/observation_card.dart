import 'package:material_ui/material_ui.dart';

import '../features/result/result_text.dart';
import '../models/patient_record.dart';
import '../services/review_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';

/// Card for one observation: review status, "Potential /m/ → /n/",
/// "Today · කමල". Rebuilds when a review is saved.
class ObservationCard extends StatelessWidget {
  const ObservationCard({
    super.key,
    required this.observation,
    this.showPatientName = false,
    this.onTap,
  });

  final Observation observation;

  /// The Reviews tab lists several users, so it adds the name.
  final bool showPatientName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final attempt = observation.attempt;
    final day = relativeDay(observation.session.at);
    final when = '${day[0].toUpperCase()}${day.substring(1)}';
    final subtitle = [
      if (showPatientName) observation.patient.profile.name,
      when,
      attempt.word.text,
    ].join(' · ');

    return ListenableBuilder(
      listenable: reviewStore,
      builder: (context, _) {
        final review = reviewStore.latestFor(attempt.id);
        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg - 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ReviewStatusLabel(
                          text: review == null
                              ? 'Awaiting review'
                              : 'Reviewed · ${review.decision.label}',
                          awaiting: review == null,
                        ),
                        const SizedBox(height: AppSpacing.md - 4),
                        Text(
                          ResultText.observationTitle(attempt.result),
                          style: AppTypography.status,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(subtitle, style: AppTypography.caption),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dot + text: amber "Awaiting review" / green "Reviewed · Confirmed".
class ReviewStatusLabel extends StatelessWidget {
  const ReviewStatusLabel({
    super.key,
    required this.text,
    required this.awaiting,
  });

  final String text;
  final bool awaiting;

  @override
  Widget build(BuildContext context) {
    final color = awaiting ? AppColors.warning : AppColors.success;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: AppTypography.small.copyWith(color: color, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
