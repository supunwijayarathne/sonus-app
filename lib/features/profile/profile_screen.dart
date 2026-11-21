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
import 'link_therapist_dialog.dart';

/// Profile tab: who is signed in, therapist link / invite code, name, sign out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.profile, this.onSignOut});

  final UserProfile profile;
  final VoidCallback? onSignOut;

  Future<void> _editName(BuildContext context) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EditNameDialog(name: profile.name),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name saved.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = profile.role == UserRole.user;

    return ResponsivePage(
      builder: (context, scale) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          const Align(alignment: Alignment.centerLeft, child: SonusLogo()),
          const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
          Center(child: _Avatar(initials: profile.initials)),
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
            title: isUser ? 'Therapist' : 'Invite',
            tiles: [
              if (!isUser)
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
                  onTap: () => showLinkTherapistDialog(context),
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
                subtitle: 'Your name',
                onTap: () => _editName(context),
              ),
              // Information only (CLAUDE.md rule 3).
              SettingsTile(
                icon: Icons.shield_outlined,
                title: 'Your data',
                subtitle: isUser
                    ? 'Only you and your linked therapist see your practice.'
                    : 'You see only the users linked to you.',
                trailing: const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            // AuthGate shows Welcome once the user is signed out.
            onPressed: onSignOut ?? () => authRepository.signOut(),
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

/// Dialog to change the display name.
class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.name});

  final String name;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final _name = TextEditingController(text: widget.name);
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await authRepository.updateName(_name.text);
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
      title: Text('Edit profile', style: AppTypography.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              style: AppTypography.input,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: AuthValidators.name,
              onFieldSubmitted: (_) => _save(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              FormError(_error!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _busy ? null : _save,
          style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          child: const Text('Save'),
        ),
      ],
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
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
