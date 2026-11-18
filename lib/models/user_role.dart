/// The two kinds of account in Sonus. Stored in Firestore as `users/{uid}.role`.
enum UserRole {
  user('user', 'Adult user'),
  therapist('therapist', 'Speech therapist');

  const UserRole(this.firestoreValue, this.label);

  /// Value saved in Firestore ("user" / "therapist").
  final String firestoreValue;

  /// Text shown in the UI.
  final String label;
}
