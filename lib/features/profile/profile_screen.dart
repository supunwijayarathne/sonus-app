import 'package:material_ui/material_ui.dart';

import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/settings_group.dart';
import '../../widgets/sonus_logo.dart';

/// Profile tab: who is signed in, account and privacy settings, sign out.
///
/// The settings rows are placeholders until those screens exist.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.profile, this.onSignOut});

  final UserProfile profile;
  final VoidCallback? onSignOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Local only for now. Reminders would be local notifications, so no
  // third-party push or analytics SDK is needed (CLAUDE.md rule 3).
  bool _notifications = true;

  void _comingSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Coming soon.')));
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return ResponsivePage(
      builder: (context, scale) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          const Align(alignment: Alignment.centerLeft, child: SonusLogo()),
          const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
          Center(
            child: _Avatar(initials: profile.initials, onEdit: _comingSoon),
          ),
          const SizedBox(height: AppSpacing.md + 4),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: AppTypography.title.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            profile.email,
            textAlign: TextAlign.center,
            style: AppTypography.small.copyWith(fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.md - 4),
          Center(child: _RolePill(profile.role.label)),
          const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
          SettingsGroup(
            title: 'Account',
            tiles: [
              SettingsTile(
                icon: Icons.edit_outlined,
                title: 'Edit profile',
                subtitle: 'Name and email',
                onTap: _comingSoon,
              ),
              SettingsTile(
                icon: Icons.mic_none,
                title: 'Microphone access',
                subtitle: 'Allowed', // read from the OS permission later
                onTap: _comingSoon,
              ),
              SettingsTile(
                icon: Icons.notifications_none,
                title: 'Notifications',
                onTap: () => setState(() => _notifications = !_notifications),
                trailing: Switch(
                  value: _notifications,
                  onChanged: (value) => setState(() => _notifications = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SettingsGroup(
            title: 'Privacy',
            tiles: [
              SettingsTile(
                icon: Icons.shield_outlined,
                title: 'Privacy settings',
                subtitle: 'Recordings and data',
                onTap: _comingSoon,
              ),
              SettingsTile(
                icon: Icons.settings_outlined,
                title: 'Recording preferences',
                subtitle: 'Delete after 30 days',
                onTap: _comingSoon,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dangerSurface,
              foregroundColor: AppColors.record,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.onEdit});

  final String initials;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 80,
      child: Stack(
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.accentSurface,
              shape: BoxShape.circle,
            ),
            child: Text(
              initials,
              style: AppTypography.title.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(3),
              child: IconButton.filled(
                onPressed: onEdit,
                tooltip: 'Change photo',
                icon: const Icon(Icons.edit_outlined, size: 14),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                  fixedSize: const Size.square(26),
                  minimumSize: const Size.square(26),
                  padding: EdgeInsets.zero,
                  // Without this, Material grows the button to a 48 px
                  // tap area and the badge covers the initials.
                  // ("Edit profile" below is the large tap target.)
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.badge.copyWith(
          color: AppColors.accent,
          fontSize: 11,
        ),
      ),
    );
  }
}
