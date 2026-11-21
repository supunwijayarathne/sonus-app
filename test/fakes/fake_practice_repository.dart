import 'dart:async';

import 'package:sonus_app/data/mock_data.dart';
import 'package:sonus_app/models/exercise.dart';
import 'package:sonus_app/models/patient_record.dart';
import 'package:sonus_app/models/practice_session.dart';
import 'package:sonus_app/services/practice_repository.dart';

/// In-memory [PracticeRepository] for widget tests (no Firebase).
class FakePracticeRepository implements PracticeRepository {
  FakePracticeRepository({
    List<Exercise>? exercises,
    List<Assignment>? assignments,
    List<PatientRecord>? patients,
    Map<String, List<PracticeSession>>? sessions,
  }) : allExercises = exercises ?? [],
       allAssignments = assignments ?? [],
       allPatients = patients ?? [],
       allSessions = sessions ?? {};

  /// The sample therapist, users, exercises and sessions from [MockData].
  factory FakePracticeRepository.sample() => FakePracticeRepository(
    exercises: List.of(MockData.exercises),
    assignments: List.of(MockData.assignments),
    patients: List.of(MockData.patients),
    sessions: {MockData.user.id: List.of(MockData.sessions())},
  );

  final List<Exercise> allExercises;
  final List<Assignment> allAssignments;
  final List<PatientRecord> allPatients;
  final Map<String, List<PracticeSession>> allSessions;

  final _changes = StreamController<void>.broadcast();

  /// The current value, then a new one after every change.
  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  void _changed() => _changes.add(null);

  @override
  Stream<List<Exercise>> exercises(String therapistId) => _watch(
    () => allExercises.where((e) => e.therapistId == therapistId).toList(),
  );

  @override
  Future<void> createExercise({
    required String therapistId,
    required String text,
    required String romanized,
    required List<String> expectedPhonemes,
  }) async {
    allExercises.insert(
      0,
      Exercise(
        id: 'exercise-new-${allExercises.length}',
        therapistId: therapistId,
        text: text,
        romanized: romanized,
        expectedPhonemes: expectedPhonemes,
        g2pVersion: 'test',
        createdAt: DateTime.now(),
      ),
    );
    _changed();
  }

  @override
  Future<void> deleteExercise(Exercise exercise) async {
    allExercises.removeWhere((e) => e.id == exercise.id);
    allAssignments.removeWhere((a) => a.exerciseId == exercise.id);
    _changed();
  }

  @override
  Stream<List<PatientRecord>> patients(String therapistId) => _watch(
    () =>
        allPatients.where((p) => p.profile.therapistId == therapistId).toList(),
  );

  @override
  Stream<List<Assignment>> assignmentsFrom(String therapistId, String userId) =>
      _watch(
        () => allAssignments
            .where((a) => a.therapistId == therapistId && a.userId == userId)
            .toList(),
      );

  @override
  Future<void> updateAssignments({
    required String therapistId,
    required String userId,
    required List<Exercise> add,
    required List<Assignment> remove,
  }) async {
    final removeIds = {for (final a in remove) a.id};
    allAssignments.removeWhere((a) => removeIds.contains(a.id));
    for (final e in add) {
      allAssignments.add(
        Assignment(
          therapistId: therapistId,
          userId: userId,
          exerciseId: e.id,
          text: e.text,
          romanized: e.romanized,
          expectedPhonemes: e.expectedPhonemes,
          createdAt: DateTime.now(),
        ),
      );
    }
    _changed();
  }

  @override
  Stream<List<Assignment>> assignmentsFor(String userId) =>
      _watch(() => allAssignments.where((a) => a.userId == userId).toList());

  @override
  Stream<List<PracticeSession>> sessions(String userId) =>
      _watch(() => List.of(allSessions[userId] ?? const <PracticeSession>[]));

  var _nextId = 0;

  @override
  String newAttemptId() => 'attempt-${_nextId++}';

  @override
  Future<void> saveAttempt({
    required String userId,
    required String therapistId,
    required String sessionId,
    required WordAttempt attempt,
  }) async {
    final sessions = allSessions[userId] ??= [];
    final i = sessions.indexWhere((s) => s.id == sessionId);
    if (i == -1) {
      sessions.insert(
        0,
        PracticeSession(id: sessionId, at: DateTime.now(), attempts: [attempt]),
      );
    } else {
      final s = sessions[i];
      sessions[i] = PracticeSession(
        id: s.id,
        at: s.at,
        attempts: [...s.attempts, attempt],
      );
    }
    _changed();
  }
}
