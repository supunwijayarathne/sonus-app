import 'package:material_ui/material_ui.dart';

import '../../models/patient_record.dart';
import '../../models/user_profile.dart';
import '../../services/review_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/format.dart';
import '../../widgets/dashed_action_card.dart';
import '../../widgets/initials_avatar.dart';
import '../../widgets/observation_card.dart';
import '../../widgets/patient_tile.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sonus_logo.dart';
import '../../widgets/stat_tile.dart';
import '../result/result_text.dart';

/// Therapist home: counts, the newest observation awaiting review,
/// and the most recently active users.
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({
    super.key,
    required this.therapist,
    required this.patients,
    this.onOpenPatient,
    this.onOpenObservation,
    this.onViewAllUsers,
    this.onLinkUser,
  });

  final UserProfile therapist;
  final List<PatientRecord> patients;
  final ValueChanged<PatientRecord>? onOpenPatient;
  final ValueChanged<Observation>? onOpenObservation;
  final VoidCallback? onViewAllUsers;
  final VoidCallback? onLinkUser;

  /// "8" -> "08", as in the design.
  static String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final greeting = '${greetingFor(DateTime.now())}, ${therapist.firstName}';

    // Rebuild when a review is saved, so the counts stay right.
    return ListenableBuilder(
      listenable: reviewStore,
      builder: (context, _) {
        final awaiting = [
          for (final p in patients)
            for (final o in p.observations)
              if (!reviewStore.isReviewed(o.attempt.id)) o,
        ]..sort((a, b) => b.session.at.compareTo(a.session.at));

        return ResponsivePage(
          builder: (context, scale) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SonusLogo(),
                  InitialsAvatar(therapist.initials, size: 40),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(greeting.toUpperCase(), style: AppTypography.eyebrow),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Clinical overview',
                style: AppTypography.scaled(AppTypography.headline, scale),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'A concise view of your assigned users and pending observations.',
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.people_outline,
                      value: _twoDigits(patients.length),
                      label: 'Assigned users',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Expanded(
                    child: StatTile(
                      icon: Icons.assignment_outlined,
                      value: _twoDigits(awaiting.length),
                      label: 'Awaiting review',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl + AppSpacing.xs),
              SectionHeader(
                'Needs attention',
                trailing: awaiting.isEmpty
                    ? null
                    : Text(
                        _capitalised(relativeDay(awaiting.first.session.at)),
                        style: AppTypography.small,
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              awaiting.isEmpty
                  ? Text(
                      patients.every((p) => p.observations.isEmpty)
                          ? 'Observations appear here once your users practise.'
                          : 'All observations are reviewed.',
                      style: AppTypography.small,
                    )
                  : _AttentionCard(
                      observation: awaiting.first,
                      onTap: () => onOpenObservation?.call(awaiting.first),
                    ),
              const SizedBox(height: AppSpacing.xl + AppSpacing.xs),
              SectionHeader(
                'Assigned users',
                trailing: patients.isEmpty
                    ? null
                    : TextButton(
                        onPressed: onViewAllUsers,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          textStyle: AppTypography.small.copyWith(fontSize: 15),
                        ),
                        child: const Text('View all'),
                      ),
              ),
              if (patients.isEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No users yet. Share your invite code so users can link '
                  'to you.',
                  style: AppTypography.small,
                ),
                const SizedBox(height: AppSpacing.md),
                DashedActionCard(
                  title: 'Invite a user',
                  subtitle: 'Share your invite code',
                  onTap: onLinkUser,
                ),
              ],
              // The two most recently active users.
              for (final patient in patients.take(2)) ...[
                PatientTile(
                  patient: patient,
                  onTap: () => onOpenPatient?.call(patient),
                ),
                const Divider(height: 1, color: AppColors.fieldBorder),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  static String _capitalised(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

/// Highlighted card for the newest observation awaiting review.
class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.observation, this.onTap});

  final Observation observation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final result = observation.attempt.result;
    final diffs = result.differences;
    final summary = diffs.length == 1
        ? 'Possible ${ResultText.shortChange(diffs.single)} '
              '${ResultText.kindName(diffs.single.kind)} in one word.'
        : '${diffs.length} possible differences in one word.';
    final name = observation.patient.profile.name;

    return Semantics(
      button: true,
      label: 'New observation. $name. $summary',
      excludeSemantics: true,
      child: Material(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.attentionTop, AppColors.attentionBottom],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl + AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ReviewStatusLabel(
                          text: 'New observation',
                          awaiting: true,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          name,
                          style: AppTypography.status.copyWith(fontSize: 26),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(summary, style: AppTypography.small),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: AppColors.onAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
