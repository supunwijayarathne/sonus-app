import '../models/user_profile.dart';
import '../models/user_role.dart';

/// Everything the app needs from accounts. Screens only use this interface;
/// [FirebaseAuthRepository] is the real one, tests use a fake.
abstract class AuthRepository {
  /// The signed-in person's profile: null when signed out. Emits again when
  /// the profile changes (e.g. after linking a therapist).
  Stream<UserProfile?> profileChanges();

  Future<void> signUp({
    required UserRole role,
    required String name,
    required String email,
    required String password,
  });

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  /// Users only: link to the therapist who owns [inviteCode].
  Future<void> linkTherapist(String inviteCode);

  /// Changes the signed-in person's display name.
  Future<void> updateName(String name);

  /// The display name of another account the rules let us read
  /// (e.g. the user's own therapist). Null if not found.
  Future<String?> nameOf(String uid);
}

/// A friendly, already-worded error for the UI.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// The repository the app uses (set in main.dart; tests set a fake).
late AuthRepository authRepository;
