import 'user_role.dart';

/// A person with an account (Firestore `users/{uid}`).
///
/// Fields in Firestore (all strings):
///   role, name, email, code           every account
///   inviteCode                        therapists: code a user enters to link
///   therapistId, linkedCode           users: set when they link to a therapist
class UserProfile {
  const UserProfile({
    this.id = '',
    required this.name,
    required this.email,
    required this.role,
    this.code,
    this.inviteCode,
    this.therapistId,
  });

  /// Builds a profile from a Firestore document.
  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.fromFirestore(data['role'] as String),
      code: data['code'] as String?,
      inviteCode: data['inviteCode'] as String?,
      therapistId: data['therapistId'] as String?,
    );
  }

  /// Firebase Auth uid (also the Firestore document ID). '' in mock data.
  final String id;

  final String name;
  final String email;
  final UserRole role;

  /// Short public ID shown to the therapist, e.g. "SN-2048".
  final String? code;

  /// Therapists only: the code they share with their users.
  final String? inviteCode;

  /// Users only: the uid of their linked therapist (null until linked).
  final String? therapistId;

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
