import 'user_role.dart';

/// The signed-in person (Firestore `users/{uid}`).
class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final UserRole role;

  String get firstName => name.split(' ').first;

  /// "Nimali Perera" -> "NP".
  String get initials => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}
