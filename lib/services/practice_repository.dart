import '../models/exercise.dart';
import '../models/patient_record.dart';
import '../models/practice_session.dart';

/// Everything the app reads and writes about practice: the therapist's
/// exercise library, assignments, linked users and practice sessions.
///
/// The app uses [FirebasePracticeRepository]; widget tests use a fake with
/// sample data. Screens only talk to this interface.
abstract class PracticeRepository {
  // --- therapist ---------------------------------------------------------

  /// The therapist's exercise library, newest first.
  Stream<List<Exercise>> exercises(String therapistId);

  /// Saves a new exercise. [text] must already be cleaned by G2P.
  Future<void> createExercise({
    required String therapistId,
    required String text,
    required String romanized,
    required List<String> expectedPhonemes,
  });

  /// Deletes an exercise and takes it off every user it was assigned to.
  Future<void> deleteExercise(Exercise exercise);

  /// Users linked to the therapist, with their practice sessions.
  Stream<List<PatientRecord>> patients(String therapistId);

  /// What this therapist assigned to one user.
  Stream<List<Assignment>> assignmentsFrom(String therapistId, String userId);

  /// Assigns [add] to the user and removes [remove], in one write.
  Future<void> updateAssignments({
    required String therapistId,
    required String userId,
    required List<Exercise> add,
    required List<Assignment> remove,
  });

  // --- adult user --------------------------------------------------------

  /// Everything assigned to the user, oldest first (the practice order).
  Stream<List<Assignment>> assignmentsFor(String userId);

  /// The user's practice sessions, newest first.
  Stream<List<PracticeSession>> sessions(String userId);

  /// A new, unique attempt ID (also names the recording file).
  String newAttemptId();

  /// Stores one attempt and its automated result. Write-once: an attempt is
  /// never changed afterwards (CLAUDE.md rule 2). The audio is not uploaded.
  /// [therapistId] is null for a user without a therapist (self-practice);
  /// only they can read it.
  Future<void> saveAttempt({
    required String userId,
    required String? therapistId,
    required String sessionId,
    required WordAttempt attempt,
  });
}

/// A save or load that failed, with a message for the screen.
class DataFailure implements Exception {
  const DataFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Set in main() (and in tests, to a fake).
late PracticeRepository practiceRepository;
