import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/home/user_shell.dart';
import 'features/therapist/therapist_shell.dart';
import 'features/welcome/welcome_screen.dart';
import 'firebase_options.dart';
import 'models/user_profile.dart';
import 'models/user_role.dart';
import 'services/auth_repository.dart';
import 'services/firebase_auth_repository.dart';
import 'services/firebase_practice_repository.dart';
import 'services/practice_repository.dart';
import 'services/voice_recorder.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Firebase must be ready before the first screen uses Auth or Firestore.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  authRepository = FirebaseAuthRepository();
  practiceRepository = FirebasePracticeRepository();
  voiceRecorder = RecordVoiceRecorder();
  await RecordingFiles.init();
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
      home: const AuthGate(),
    );
  }
}

/// Shows the right first screen for the current sign-in state:
/// - waiting for Firebase  -> a plain loading screen
/// - signed out            -> Welcome
/// - signed in             -> the home for the account's role (from Firestore)
///
/// Signing in, signing up and signing out only change the auth state;
/// this widget rebuilds by itself (and Firebase keeps you signed in).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Created once: a new stream on every rebuild would re-subscribe.
  final Stream<UserProfile?> _profiles = authRepository.profileChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: _profiles,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const _ProfileError();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }
        final profile = snapshot.data;
        if (profile == null) return const _Welcome();
        return switch (profile.role) {
          UserRole.user => UserShell(profile: profile),
          UserRole.therapist => TherapistShell(profile: profile),
        };
      },
    );
  }
}

/// Shown when the signed-in profile cannot be loaded.
class _ProfileError extends StatelessWidget {
  const _ProfileError();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your profile could not be loaded. Please check your '
                  'connection, or sign out and sign in again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => authRepository.signOut(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Welcome -> Sign up / Log in. After a successful sign-in the auth screens
/// close and [AuthGate] shows the home underneath.
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

  /// Closes the auth screens so the new home (from [AuthGate]) is visible.
  static void _closeAuthScreens(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  static Widget _logIn() {
    return Builder(
      builder: (context) => LoginScreen(
        // The role comes from the account; the toggle is only a hint.
        onSignIn: (role, email, password) async {
          await authRepository.signIn(email: email, password: password);
          if (context.mounted) _closeAuthScreens(context);
        },
        onCreateAccount: () => _swap(context, _signUp()),
      ),
    );
  }

  static Widget _signUp() {
    return Builder(
      builder: (context) => SignUpScreen(
        onCreateAccount: (role, name, email, password) async {
          await authRepository.signUp(
            role: role,
            name: name,
            email: email,
            password: password,
          );
          if (context.mounted) _closeAuthScreens(context);
        },
        onSignIn: () => _swap(context, _logIn()),
      ),
    );
  }
}
