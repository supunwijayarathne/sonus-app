import 'package:material_ui/material_ui.dart';

import '../../models/patient_record.dart';
import '../../services/review_store.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/observation_card.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sonus_logo.dart';

/// "Reviews" tab: every observation from all assigned users,
/// awaiting review first, then reviewed. (No Figma design yet; built from
/// the observation card in the User profile design.)
class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({
    super.key,
    required this.patients,
    this.onOpenObservation,
  });

  final List<PatientRecord> patients;
  final ValueChanged<Observation>? onOpenObservation;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: reviewStore,
      builder: (context, _) {
        final all = [for (final p in patients) ...p.observations]
          ..sort((a, b) => b.session.at.compareTo(a.session.at));
        final awaiting = all
            .where((o) => !reviewStore.isReviewed(o.attempt.id))
            .toList();
        final reviewed = all
            .where((o) => reviewStore.isReviewed(o.attempt.id))
            .toList();

        return ResponsivePage(
          builder: (context, scale) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              const Align(alignment: Alignment.centerLeft, child: SonusLogo()),
              const SizedBox(height: AppSpacing.xxl),
              Text('REVIEW QUEUE', style: AppTypography.eyebrow),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Reviews',
                style: AppTypography.scaled(AppTypography.headline, scale),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Automated observations to confirm or reject. '
                'Your review is saved next to the original result.',
                style: AppTypography.body,
              ),
              ..._section('Awaiting review', awaiting, 'Nothing to review.'),
              if (reviewed.isNotEmpty) ..._section('Reviewed', reviewed, ''),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _section(String title, List<Observation> items, String empty) {
    return [
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(
        title,
        trailing: Text('${items.length}', style: AppTypography.small),
      ),
      const SizedBox(height: AppSpacing.md),
      if (items.isEmpty) Text(empty, style: AppTypography.small),
      for (final o in items) ...[
        ObservationCard(
          observation: o,
          showPatientName: true,
          onTap: () => onOpenObservation?.call(o),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
      ],
    ];
  }
}
