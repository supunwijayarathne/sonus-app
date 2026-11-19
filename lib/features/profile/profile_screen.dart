import 'package:material_ui/material_ui.dart';

import '../../models/user_profile.dart';
import '../../models/user_role.dart';
import '../../services/auth_repository.dart';
import '../auth/auth_common.dart';
import '../therapist/invite_code_sheet.dart';
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

  Future<void> _openLinkDialog() async {
    final linked = await showDialog<bool>(
      context: context,
      builder: (_) => const _LinkTherapistDialog(),
    );
    if (linked == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Linked to your therapist.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final records = profile.role == UserRole.user;

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
          // Linking (CLAUDE.md: therapist linking by invite code).
          SettingsGroup(
            title: records ? 'Therapist' : 'Invite',
            tiles: [
              if (!records)
                SettingsTile(
                  icon: Icons.qr_code_2,
                  title: 'Your invite code',
                  subtitle: profile.inviteCode ?? '—',
                  onTap: () => showInviteCodeSheet(context, profile.inviteCode),
                )
              else if (profile.therapistId == null)
                SettingsTile(
                  icon: Icons.link,
                  title: 'Link your therapist',
                  subtitle: 'Enter their invite code',
                  onTap: _openLinkDialog,
                )
              else
                SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Your therapist',
                  subtitle: 'Linked',
                  trailing: _TherapistName(profile.therapistId!),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SettingsGroup(
            title: 'Account',
            tiles: [
              SettingsTile(
                icon: Icons.edit_outlined,
                title: 'Edit profile',
                subtitle: 'Name and email',
                onTap: _comingSoon,
              ),
              // Only adult users record, so only they see recording rows.
              if (records)
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
              // "Recording preferences / Delete after 30 days" removed:
              // automatic deletion needs Cloud Functions (not on Spark plan).
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            // AuthGate shows Welcome once the user is signed out.
            onPressed: widget.onSignOut ?? () => authRepository.signOut(),
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

/// Shows the linked therapist's name (read from Firestore).
class _TherapistName extends StatelessWidget {
  const _TherapistName(this.therapistId);

  final String therapistId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: authRepository.nameOf(therapistId),
      builder: (context, snapshot) => Text(
        snapshot.data ?? '',
        style: AppTypography.small.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

/// Dialog where an adult user types their therapist's invite code.
class _LinkTherapistDialog extends StatefulWidget {
  const _LinkTherapistDialog();

  @override
  State<_LinkTherapistDialog> createState() => _LinkTherapistDialogState();
}

class _LinkTherapistDialogState extends State<_LinkTherapistDialog> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    if (_code.text.trim().isEmpty) {
      setState(() => _error = 'Please enter the code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await authRepository.linkTherapist(_code.text);
      if (mounted) Navigator.pop(context, true);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('Link your therapist', style: AppTypography.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your therapist can see your practice sessions and review them. '
            'Ask them for their 6-character invite code.',
            style: AppTypography.small,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            style: AppTypography.input.copyWith(letterSpacing: 3),
            decoration: const InputDecoration(hintText: 'K7MPQ4'),
            onSubmitted: (_) => _link(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            FormError(_error!),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _busy ? null : _link,
          style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          child: const Text('Link'),
        ),
      ],
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
