import 'user_role.dart';

/// A person with an account (Firestore `users/{uid}`).
class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.role,
    this.code,
  });

  final String name;
  final String email;
  final UserRole role;

  /// Short public ID shown to the therapist, e.g. "SN-2048".
  final String? code;

  /// First name, skipping a title: "Dr. Amaya Silva" -> "Amaya".
  String get firstName {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length > 1 && parts.first.endsWith('.')) return parts[1];
    return parts.isEmpty ? '' : parts.first;
  }

  /// "Nimali Perera" -> "NP", "Dr. Amaya Silva" -> "AS".
  String get initials => name
      .split(' ')
      .where((part) => part.isNotEmpty && !part.endsWith('.'))
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}
