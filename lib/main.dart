import 'package:material_ui/material_ui.dart';

import 'features/auth/login_screen.dart';
import 'features/home/user_shell.dart';
import 'features/welcome/welcome_screen.dart';
import 'models/user_role.dart';
import 'theme/app_theme.dart';
import 'widgets/coming_soon_screen.dart';

void main() {
  runApp(const SonusApp());
}

class SonusApp extends StatelessWidget {
  const SonusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sonus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      // Simple navigation for now; switches to go_router with the auth flow.
      home: const _Welcome(),
    );
  }
}

/// Welcome -> Log in -> home for the chosen role. Sign out returns here.
class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    return WelcomeScreen(
      onGetStarted: () {}, // sign-up screen: next
      onLogIn: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (loginContext) => LoginScreen(
            // Simulated sign-in until Firebase Auth is connected.
            onSignIn: (role, email, password) =>
                _replaceAll(loginContext, _homeFor(role)),
            onCreateAccount: () {}, // sign-up screen: next
          ),
        ),
      ),
    );
  }

  /// Opens [screen] and clears the back stack (no "back" into a signed-out
  /// or signed-in area).
  static void _replaceAll(BuildContext context, Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (_) => false,
    );
  }

  static Widget _homeFor(UserRole role) {
    return switch (role) {
      UserRole.user => Builder(
        builder: (context) =>
            UserShell(onSignOut: () => _replaceAll(context, const _Welcome())),
      ),
      UserRole.therapist => const Scaffold(body: ComingSoon('Therapist home')),
    };
  }
}
