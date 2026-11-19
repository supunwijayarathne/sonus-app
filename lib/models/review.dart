/// What the therapist decided about an automated observation.
enum ReviewDecision {
  confirmed('Confirmed'),
  rejected('Marked incorrect');

  const ReviewDecision(this.label);
  final String label;
}

/// A therapist's review of one attempt (Firestore `attempts/{id}/reviews/{id}`).
///
/// CLAUDE.md rule 2: this is a SEPARATE record. The automated result on the
/// attempt is never changed; a newer review is added next to older ones.
class Review {
  const Review({
    required this.attemptId,
    required this.therapistName,
    required this.decision,
    required this.note,
    required this.createdAt,
  });

  final String attemptId;
  final String therapistName;
  final ReviewDecision decision;

  /// Optional clinical note ('' when empty).
  final String note;
  final DateTime createdAt;
}
