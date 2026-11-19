import 'practice_session.dart';
import 'user_profile.dart';

/// An adult user as their therapist sees them: profile + practice sessions.
/// Only practice activity and review-relevant information (privacy rule 3).
class PatientRecord {
  const PatientRecord({
    required this.profile,
    required this.linkedAt,
    required this.sessions,
  });

  final UserProfile profile;
  final DateTime linkedAt;

  /// Newest first.
  final List<PracticeSession> sessions;

  DateTime? get lastSessionAt => sessions.isEmpty ? null : sessions.first.at;

  /// Every recorded word with a possible difference, newest first.
  List<Observation> get observations => [
    for (final session in sessions)
      for (final attempt in session.attempts)
        if (attempt.result.hasDifference)
          Observation(patient: this, session: session, attempt: attempt),
  ];
}

/// One attempt seen from the therapist's side: who, which session, which word.
class Observation {
  const Observation({
    required this.patient,
    required this.session,
    required this.attempt,
  });

  final PatientRecord patient;
  final PracticeSession session;
  final WordAttempt attempt;
}
