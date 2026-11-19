import 'package:material_ui/material_ui.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Pieces shared by the log-in and sign-up screens.
class AuthValidators {
  AuthValidators._();

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email.';
    // Simple shape check; Firebase does the real check.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'That email doesn\'t look right.';
    }
    return null;
  }

  /// Log in: any non-empty password.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password.';
    return null;
  }

  /// Sign up: at least 8 characters (Firebase's minimum is 6).
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please choose a password.';
    if (value.length < 8) return 'Use at least 8 characters.';
    return null;
  }

  static String? name(String? value) {
    if ((value?.trim() ?? '').isEmpty) return 'Please enter your name.';
    return null;
  }
}

/// Error from the server (e.g. "Email or password is not right.").
/// Icon + text, and announced by screen readers.
class FormError extends StatelessWidget {
  const FormError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.small.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small spinner shown inside a button while waiting for the server.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: AppColors.onAccent,
      ),
    );
  }
}

/// Small print under the auth forms.
/// Wording follows CLAUDE.md rule 1 (no "diagnosis" in the UI).
class AuthFootnote extends StatelessWidget {
  const AuthFootnote({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'By continuing, you acknowledge that Sonus offers practice '
      'suggestions for your therapist to review, not a medical assessment.',
      textAlign: TextAlign.center,
      style: AppTypography.caption,
    );
  }
}
