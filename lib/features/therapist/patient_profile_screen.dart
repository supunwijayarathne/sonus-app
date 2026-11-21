import 'package:material_ui/material_ui.dart';

import '../../models/exercise.dart';
import '../../models/patient_analytics.dart';
import '../../models/patient_record.dart';
import '../../models/practice_session.dart';
import '../../services/practice_repository.dart';
import '../../theme/app_colors.dart';
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
import '../exercises/assign_exercises_sheet.dart';
import 'patient_analytics_section.dart';

/// One assigned user, as their therapist sees them: counts, assigned
/// exercises, practice analytics, recent observations and session history (practice activity only).
class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({
    super.key,
    required this.patient,
    required this.therapistId,
    this.onOpenObservation,
  });

  final PatientRecord patient;
  final String therapistId;
  final ValueChanged<Observation>? onOpenObservation;

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  late final Stream<List<Assignment>> _assignments = practiceRepository
      .assignmentsFrom(widget.therapistId, widget.patient.profile.id);

  PatientRecord get patient => widget.patient;

  /// Worked out once from the sessions (they don't change on this screen).
  late final PatientAnalytics _analytics = PatientAnalytics.from(
    widget.patient.sessions,
  );
  ValueChanged<Observation>? get onOpenObservation => widget.onOpenObservation;

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
          StreamBuilder<List<Assignment>>(
            stream: _assignments,
            builder: (context, snapshot) => _AssignedExercises(
              assignments: snapshot.data,
              onAssign: snapshot.data == null
                  ? null
                  : () => showAssignExercisesSheet(
                      context,
                      therapistId: widget.therapistId,
                      user: patient.profile,
                      current: snapshot.data!,
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl + AppSpacing.xs),
          PatientAnalyticsSection(analytics: _analytics),
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
          if (patient.sessions.isEmpty)
            Text('No sessions yet.', style: AppTypography.small),
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

/// "Exercises" section: what this user practises, and the assign button.
class _AssignedExercises extends StatelessWidget {
  const _AssignedExercises({required this.assignments, this.onAssign});

  /// Null while loading.
  final List<Assignment>? assignments;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    final assignments = this.assignments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Exercises',
          trailing: TextButton.icon(
            onPressed: onAssign,
            icon: const Icon(Icons.playlist_add, size: 18),
            label: const Text('Assign'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              textStyle: AppTypography.small.copyWith(fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (assignments == null)
          const SizedBox(height: AppSpacing.lg)
        else if (assignments.isEmpty)
          Text(
            'Nothing assigned yet. Tap Assign to choose exercises.',
            style: AppTypography.small,
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final a in assignments)
                Chip(
                  label: Text(
                    a.text,
                    style: AppTypography.scaled(
                      AppTypography.sinhalaWord,
                      0.36,
                    ),
                  ),
                  backgroundColor: AppColors.surface,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
