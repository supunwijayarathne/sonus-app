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

/// Called when the form is valid and the user taps "Sign in".
/// Throws [AuthFailure] with a message to show when it fails.
typedef SignInCallback = Future<void> Function(
  UserRole role,
  String email,
  String password,
);

/// Log-in screen: role toggle, email, password, "Sign in".
///
/// The screen only collects and checks the input; signing in itself
/// (Firebase Auth) is done by whoever passes [onSignIn].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onSignIn, this.onCreateAccount});

  final SignInCallback? onSignIn;
  final VoidCallback? onCreateAccount;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  UserRole _role = UserRole.user;
  bool _hidePassword = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
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
      await widget.onSignIn?.call(_role, _email.text.trim(), _password.text);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Text('WELCOME BACK', style: AppTypography.eyebrow),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Continue your practice.',
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
                label: 'Email',
                controller: _email,
                hint: 'nimali@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: AuthValidators.email,
              ),
              const SizedBox(height: AppSpacing.lg),
              LabeledTextField(
                label: 'Password',
                controller: _password,
                obscureText: _hidePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: AuthValidators.password,
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
                    : const ArrowLabel('Sign in'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: widget.onCreateAccount,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                  ),
                  child: const Text('New to Sonus? Create account'),
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
