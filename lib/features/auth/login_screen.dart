import 'package:material_ui/material_ui.dart';

import '../../models/user_role.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/labeled_text_field.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/round_back_button.dart';
import '../../widgets/segmented_toggle.dart';

/// Called when the form is valid and the user taps "Sign in".
typedef SignInCallback = void Function(
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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSignIn?.call(_role, _email.text.trim(), _password.text);
  }

  static String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email.';
    // Simple shape check; Firebase does the real check.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'That email doesn\'t look right.';
    }
    return null;
  }

  static String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password.';
    return null;
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
                'This prototype uses simulated authentication.',
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
                validator: _validateEmail,
              ),
              const SizedBox(height: AppSpacing.lg),
              LabeledTextField(
                label: 'Password',
                controller: _password,
                obscureText: _hidePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: _validatePassword,
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
              FilledButton(
                onPressed: _submit,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Sign in'),
                    SizedBox(width: AppSpacing.md),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
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
              // Wording follows CLAUDE.md rule 1 (no "diagnosis" in the UI).
              Text(
                'By continuing, you acknowledge that Sonus offers practice '
                'suggestions for your therapist to review, not a medical assessment.',
                textAlign: TextAlign.center,
                style: AppTypography.caption,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
