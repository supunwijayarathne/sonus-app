import 'package:material_ui/material_ui.dart';

import '../models/patient_record.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/format.dart';
import 'initials_avatar.dart';

/// Row for one assigned user: avatar, name, "SN-2048 · 12 sessions",
/// "Last session today", chevron.
class PatientTile extends StatelessWidget {
  const PatientTile({super.key, required this.patient, this.onTap});

  final PatientRecord patient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final profile = patient.profile;
    final last = patient.lastSessionAt;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            InitialsAvatar(profile.initials),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: AppTypography.sectionTitle.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${profile.code} · ${plural(patient.sessions.length, 'session')}',
                    style: AppTypography.small.copyWith(fontSize: 13),
                  ),
                  Text(
                    last == null
                        ? 'No sessions yet'
                        : 'Last session ${relativeDay(last)}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
