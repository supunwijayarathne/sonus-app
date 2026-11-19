import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/home/user_shell.dart';
import 'features/therapist/therapist_shell.dart';
import 'features/welcome/welcome_screen.dart';
import 'firebase_options.dart';
import 'models/user_role.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Firebase must be ready before the first screen uses Auth or Firestore.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

/// Welcome -> Sign up / Log in -> home for the role. Sign out returns here.
///
/// Sign-in and sign-up are simulated until Firebase Auth is connected.
class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    return WelcomeScreen(
      onGetStarted: () => _push(context, _signUp()),
      onLogIn: () => _push(context, _logIn()),
    );
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  /// Swaps log-in <-> sign-up without stacking them.
  static void _swap(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
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

  static Widget _logIn() {
    return Builder(
      builder: (context) => LoginScreen(
        onSignIn: (role, email, password) =>
            _replaceAll(context, _homeFor(role)),
        onCreateAccount: () => _swap(context, _signUp()),
      ),
    );
  }

  static Widget _signUp() {
    return Builder(
      builder: (context) => SignUpScreen(
        onCreateAccount: (role, name, email, password) =>
            _replaceAll(context, _homeFor(role)),
        onSignIn: () => _swap(context, _logIn()),
      ),
    );
  }

  static Widget _homeFor(UserRole role) {
    return Builder(
      builder: (context) {
        void signOut() => _replaceAll(context, const _Welcome());
        return switch (role) {
          UserRole.user => UserShell(onSignOut: signOut),
          UserRole.therapist => TherapistShell(onSignOut: signOut),
        };
      },
    );
  }
}
