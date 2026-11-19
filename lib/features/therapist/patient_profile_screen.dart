import 'package:material_ui/material_ui.dart';

import '../../models/patient_record.dart';
import '../../models/practice_session.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/format.dart';
import '../../widgets/initials_avatar.dart';
import '../../widgets/observation_card.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/round_back_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/session_card.dart';
import '../../widgets/stat_tile.dart';

/// One assigned user, as their therapist sees them: counts, recent
/// observations and session history (practice activity only).
class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({
    super.key,
    required this.patient,
    this.onOpenObservation,
  });

  final PatientRecord patient;
  final ValueChanged<Observation>? onOpenObservation;

  /// A session opens the review of its first word with a possible
  /// difference (or its first word when nothing differed).
  Observation _observationFor(PracticeSession session) {
    final attempt = session.attempts.firstWhere(
      (a) => a.result.hasDifference,
      orElse: () => session.attempts.first,
    );
    return Observation(patient: patient, session: session, attempt: attempt);
  }

  @override
  Widget build(BuildContext context) {
    final profile = patient.profile;
    final observations = patient.observations;

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
                    'User profile',
                    textAlign: TextAlign.center,
                    style: AppTypography.barTitle,
                  ),
                ),
              ),
              const SizedBox(width: 64),
            ],
          ),
          const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
          Row(
            children: [
              InitialsAvatar(profile.initials, size: 64),
              const SizedBox(width: AppSpacing.lg - 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: AppTypography.scaled(
                        AppTypography.headline,
                        scale * 0.7,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${profile.code} · Linked ${shortMonthYear(patient.linkedAt)}',
                      style: AppTypography.caption.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '${patient.sessions.length}',
                  label: 'Completed sessions',
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: StatTile(
                  value: '${observations.length}',
                  label: 'Recent observations',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl + AppSpacing.xs),
          const SectionHeader('Recent observations'),
          const SizedBox(height: AppSpacing.md),
          if (observations.isEmpty)
            Text('No possible differences so far.', style: AppTypography.small),
          for (final o in observations.take(3)) ...[
            ObservationCard(
              observation: o,
              onTap: () => onOpenObservation?.call(o),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
          ],
          const SizedBox(height: AppSpacing.xl - AppSpacing.sm),
          const SectionHeader('Session history'),
          const SizedBox(height: AppSpacing.md),
          for (final session in patient.sessions) ...[
            SessionCard(
              session: session,
              onTap: () => onOpenObservation?.call(_observationFor(session)),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
