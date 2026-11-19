import 'package:material_ui/material_ui.dart';

import '../../models/patient_record.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/dashed_border.dart';
import '../../widgets/patient_tile.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/sonus_logo.dart';

/// "Assigned users" tab: search by name or ID, link a new user, list.
class UsersScreen extends StatefulWidget {
  const UsersScreen({
    super.key,
    required this.patients,
    this.onOpenPatient,
    this.onLinkUser,
  });

  final List<PatientRecord> patients;
  final ValueChanged<PatientRecord>? onOpenPatient;
  final VoidCallback? onLinkUser;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _query = '';

  List<PatientRecord> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.patients;
    return widget.patients.where((p) {
      final name = p.profile.name.toLowerCase();
      final code = (p.profile.code ?? '').toLowerCase();
      return name.contains(q) || code.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return ResponsivePage(
      builder: (context, scale) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SonusLogo(),
              IconButton.filled(
                onPressed: widget.onLinkUser,
                tooltip: 'Invite a user',
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  fixedSize: const Size.square(AppSpacing.iconButtonSize),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('CARE NETWORK', style: AppTypography.eyebrow),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Assigned users',
            style: AppTypography.scaled(AppTypography.headline, scale),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Only practice activity and review-relevant information is shown.',
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            style: AppTypography.input,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search by name or ID',
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _LinkUserCard(onTap: widget.onLinkUser),
          const SizedBox(height: AppSpacing.md + 4),
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'No users match "$_query".',
                textAlign: TextAlign.center,
                style: AppTypography.small,
              ),
            )
          else
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < results.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.fieldBorder),
                    PatientTile(
                      patient: results[i],
                      onTap: () => widget.onOpenPatient?.call(results[i]),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _LinkUserCard extends StatelessWidget {
  const _LinkUserCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.xl);
    return DashedBorder(
      color: AppColors.accentMuted,
      radius: AppRadius.xl,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg - 4),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.add, color: AppColors.accent),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invite a user',
                        style: AppTypography.sectionTitle.copyWith(
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        'Share your invite code',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
