import 'package:material_ui/material_ui.dart';

import '../../models/user_role.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/arrow_label.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/round_back_button.dart';
import '../../widgets/segmented_toggle.dart';
import '../../services/auth_repository.dart';
import 'auth_common.dart';

/// Called when the form is valid and the user taps "Create account".
/// Throws [AuthFailure] with a message to show when it fails.
typedef SignUpCallback = Future<void> Function(
  UserRole role,
  String name,
  String email,
  String password,
);

/// Sign-up screen: role (chosen once, stored on the account), name, email,
/// password. Creating the account itself (Firebase Auth + `users/{uid}`)
/// is done by whoever passes [onCreateAccount].
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.onCreateAccount, this.onSignIn});

  final SignUpCallback? onCreateAccount;

  /// "Already have an account? Sign in".
  final VoidCallback? onSignIn;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  UserRole _role = UserRole.user;
  bool _hidePassword = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onCreateAccount?.call(
        _role,
        _name.text.trim(),
        _email.text.trim(),
        _password.text,
      );
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTherapist = _role == UserRole.therapist;

    return ResponsivePage(
      builder: (context, scale) => Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              const Align(
                alignment: Alignment.centerLeft,
                child: RoundBackButton(),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text('CREATE YOUR ACCOUNT', style: AppTypography.eyebrow),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Begin with Sonus.',
                style: AppTypography.scaled(AppTypography.headline, scale),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "Research prototype: please use a password you don't use elsewhere.",
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.xl),
              SegmentedToggle<UserRole>(
                options: {for (final role in UserRole.values) role: role.label},
                value: _role,
                onChanged: (role) => setState(() => _role = role),
              ),
              const SizedBox(height: AppSpacing.xl),
              LabeledTextField(
                label: 'Full name',
                controller: _name,
                // Example changes with the role, as in the design.
                hint: isTherapist ? 'Dr. Amaya Silva' : 'Nimali Perera',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: AuthValidators.name,
              ),
              const SizedBox(height: AppSpacing.lg),
              LabeledTextField(
                label: 'Email',
                controller: _email,
                hint: isTherapist ? 'amaya@example.com' : 'nimali@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: AuthValidators.email,
              ),
              const SizedBox(height: AppSpacing.lg),
              LabeledTextField(
                label: 'Password',
                controller: _password,
                hint: 'At least 8 characters',
                obscureText: _hidePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: AuthValidators.newPassword,
                onFieldSubmitted: (_) => _submit(),
                suffixIcon: IconButton(
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  color: AppColors.textTertiary,
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                ),
              ),
              const SizedBox(height: AppSpacing.lg + 2),
              if (_error != null) ...[
                FormError(_error!),
                const SizedBox(height: AppSpacing.md),
              ],
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const ButtonSpinner()
                    : const ArrowLabel('Create account'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: widget.onSignIn,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                  ),
                  child: const Text('Already have an account? Sign in'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const AuthFootnote(),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
