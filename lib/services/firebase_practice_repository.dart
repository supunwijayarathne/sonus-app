import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/analysis_result.dart';
import '../models/exercise.dart';
import '../models/patient_record.dart';
import '../models/practice_session.dart';
import '../models/practice_word.dart';
import '../models/user_profile.dart';
import 'g2p.dart';
import 'practice_repository.dart';
import 'voice_recorder.dart';

/// [PracticeRepository] on Cloud Firestore:
///
///   exercises/{id}                       therapistId, text, romanized?,
///                                        expectedPhonemes[], g2pVersion, createdAt
///   assignments/{userId}_{exerciseId}    therapistId, userId, exerciseId,
///                                        text, romanized?, expectedPhonemes[], createdAt
///   attempts/{id}                        userId, therapistId, exerciseId, sessionId,
///                                        text, romanized?, recordingMs, createdAt,
///                                        result{...}  (write-once)
///
/// A practice session is the attempts that share a `sessionId`.
/// Recordings stay on the user's phone (see [RecordingFiles]).
///
/// Who may read or write what is enforced by firestore.rules.
class FirebasePracticeRepository implements PracticeRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _exercises =>
      _db.collection('exercises');
  CollectionReference<Map<String, dynamic>> get _assignments =>
      _db.collection('assignments');
  CollectionReference<Map<String, dynamic>> get _attempts =>
      _db.collection('attempts');

  // --- therapist ---------------------------------------------------------

  @override
  Stream<List<Exercise>> exercises(String therapistId) {
    return _exercises
        .where('therapistId', isEqualTo: therapistId)
        .snapshots()
        .map((snapshot) {
          final list = [
            for (final doc in snapshot.docs)
              Exercise.fromMap(doc.id, doc.data()),
          ];
          // Sorted here: ordering in the query would need an extra index.
          list.sort((a, b) => _newestFirst(a.createdAt, b.createdAt));
          return list;
        });
  }

  @override
  Future<void> createExercise({
    required String therapistId,
    required String text,
    required String romanized,
    required List<String> expectedPhonemes,
  }) {
    return _write(
      _exercises.add({
        'therapistId': therapistId,
        'text': text,
        if (romanized.isNotEmpty) 'romanized': romanized,
        'expectedPhonemes': expectedPhonemes,
        'g2pVersion': SinhalaG2p.version,
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  @override
  Future<void> deleteExercise(Exercise exercise) async {
    await _write(() async {
      final assigned = await _assignments
          .where('therapistId', isEqualTo: exercise.therapistId)
          .where('exerciseId', isEqualTo: exercise.id)
          .get();
      final batch = _db.batch();
      for (final doc in assigned.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_exercises.doc(exercise.id));
      await batch.commit();
    }());
  }

  /// The users linked to the therapist, each with their sessions.
  ///
  /// Two kinds of query are combined: the linked users, and one attempts
  /// query per user (the rules check, per user, that they are still linked,
  /// so "all my users' attempts" can't be one query).
  @override
  Stream<List<PatientRecord>> patients(String therapistId) {
    late final StreamController<List<PatientRecord>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? usersListener;
    final attemptListeners = <String, StreamSubscription<void>>{};
    final sessionsOf = <String, List<PracticeSession>>{};
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? users;

    void emit() {
      if (users == null) return;
      final list = [
        for (final doc in users!)
          PatientRecord(
            profile: UserProfile.fromMap(doc.id, doc.data()),
            linkedAt:
                _toDate(doc.data()['linkedAt']) ??
                _toDate(doc.data()['createdAt']) ??
                DateTime.now(),
            sessions: sessionsOf[doc.id] ?? const [],
          ),
      ];
      list.sort((a, b) => a.profile.name.compareTo(b.profile.name));
      controller.add(list);
    }

    void onUsers(QuerySnapshot<Map<String, dynamic>> snapshot) {
      users = snapshot.docs;
      final ids = {for (final doc in snapshot.docs) doc.id};
      // Stop following users who unlinked; start following new ones.
      for (final id in attemptListeners.keys.toList()) {
        if (!ids.contains(id)) {
          attemptListeners.remove(id)!.cancel();
          sessionsOf.remove(id);
        }
      }
      for (final id in ids) {
        attemptListeners[id] ??=
            _sessionsQuery(
              _attempts
                  .where('therapistId', isEqualTo: therapistId)
                  .where('userId', isEqualTo: id),
            ).listen(
              (sessions) {
                sessionsOf[id] = sessions;
                emit();
              },
              // e.g. the user just unlinked: their attempts are hidden again.
              onError: (Object _) => sessionsOf.remove(id),
            );
      }
      emit();
    }

    controller = StreamController(
      onListen: () => usersListener = _db
          .collection('users')
          .where('therapistId', isEqualTo: therapistId)
          .snapshots()
          .listen(onUsers, onError: controller.addError),
      onCancel: () async {
        await usersListener?.cancel();
        for (final listener in attemptListeners.values) {
          await listener.cancel();
        }
      },
    );
    return controller.stream;
  }

  @override
  Stream<List<Assignment>> assignmentsFrom(String therapistId, String userId) {
    // Both filters are needed: the rules only allow queries that can only
    // return the therapist's own assignments.
    return _assignmentsQuery(
      _assignments
          .where('therapistId', isEqualTo: therapistId)
          .where('userId', isEqualTo: userId),
    );
  }

  @override
  Future<void> updateAssignments({
    required String therapistId,
    required String userId,
    required List<Exercise> add,
    required List<Assignment> remove,
  }) async {
    // The rules read the exercise for every new assignment, and a batch may
    // read at most 20 documents, so large changes are saved 10 at a time.
    for (var start = 0; start < add.length || start == 0; start += 10) {
      final chunk = add.skip(start).take(10).toList();
      await _saveAssignments(
        therapistId: therapistId,
        userId: userId,
        add: chunk,
        remove: start == 0 ? remove : const [],
      );
    }
  }

  Future<void> _saveAssignments({
    required String therapistId,
    required String userId,
    required List<Exercise> add,
    required List<Assignment> remove,
  }) {
    final batch = _db.batch();
    for (final exercise in add) {
      batch.set(_assignments.doc(Assignment.idFor(userId, exercise.id)), {
        'therapistId': therapistId,
        'userId': userId,
        'exerciseId': exercise.id,
        'text': exercise.text,
        if (exercise.romanized.isNotEmpty) 'romanized': exercise.romanized,
        'expectedPhonemes': exercise.expectedPhonemes,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    for (final assignment in remove) {
      batch.delete(_assignments.doc(assignment.id));
    }
    return _write(batch.commit());
  }

  // --- adult user --------------------------------------------------------

  @override
  Stream<List<Assignment>> assignmentsFor(String userId) =>
      _assignmentsQuery(_assignments.where('userId', isEqualTo: userId));

  Stream<List<Assignment>> _assignmentsQuery(
    Query<Map<String, dynamic>> query,
  ) {
    return query.snapshots().map((snapshot) {
      final list = [
        for (final doc in snapshot.docs) Assignment.fromMap(doc.data()),
      ];
      list.sort((a, b) => -_newestFirst(a.createdAt, b.createdAt));
      return list;
    });
  }

  @override
  Stream<List<PracticeSession>> sessions(String userId) =>
      _sessionsQuery(_attempts.where('userId', isEqualTo: userId));

  @override
  String newAttemptId() => _attempts.doc().id;

  @override
  Future<void> saveAttempt({
    required String userId,
    required String therapistId,
    required String sessionId,
    required WordAttempt attempt,
  }) {
    return _write(
      _attempts.doc(attempt.id).set({
        'userId': userId,
        'therapistId': therapistId,
        'exerciseId': attempt.word.exerciseId,
        'sessionId': sessionId,
        'text': attempt.word.text,
        if (attempt.word.romanized.isNotEmpty)
          'romanized': attempt.word.romanized,
        'recordingMs': attempt.recordingLength.inMilliseconds,
        'createdAt': FieldValue.serverTimestamp(),
        'result': attempt.result.toJson(),
      }),
    );
  }

  /// Attempts grouped into sessions (by `sessionId`), newest first.
  Stream<List<PracticeSession>> _sessionsQuery(
    Query<Map<String, dynamic>> query,
  ) {
    return query.snapshots().map((snapshot) {
      final bySession = <String, List<(DateTime, WordAttempt)>>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        // A just-saved attempt has no server time yet: use the phone's.
        final at = _toDate(data['createdAt']) ?? DateTime.now();
        final key = data['sessionId'] as String? ?? doc.id;
        (bySession[key] ??= []).add((at, _attemptFrom(doc.id, data)));
      }
      final sessions = [
        for (final entry in bySession.entries) _session(entry.key, entry.value),
      ];
      sessions.sort((a, b) => b.at.compareTo(a.at));
      return sessions;
    });
  }

  static PracticeSession _session(
    String id,
    List<(DateTime, WordAttempt)> attempts,
  ) {
    attempts.sort((a, b) => a.$1.compareTo(b.$1)); // in the order recorded
    return PracticeSession(
      id: id,
      at: attempts.first.$1,
      attempts: [for (final a in attempts) a.$2],
    );
  }

  static WordAttempt _attemptFrom(String id, Map<String, dynamic> data) {
    return WordAttempt(
      id: id,
      word: PracticeWord(
        text: data['text'] as String? ?? '',
        romanized: data['romanized'] as String? ?? '',
        exerciseId: data['exerciseId'] as String? ?? '',
      ),
      result: AnalysisResult.fromJson(
        Map<String, dynamic>.from(data['result'] as Map),
      ),
      recordingLength: Duration(
        milliseconds: (data['recordingMs'] as num? ?? 0).toInt(),
      ),
      referenceLength: const Duration(seconds: 2), // no reference audio yet
      audioPath: RecordingFiles.existing(id), // only on the user's phone
    );
  }

  // --- helpers -------------------------------------------------------------

  /// Waits for a write and turns a Firestore error into a short message.
  static Future<void> _write(Future<void> write) async {
    try {
      await write;
    } on FirebaseException catch (e) {
      throw DataFailure(
        e.code == 'permission-denied'
            ? 'You don\'t have permission to do that.'
            : 'Could not save. Please check your connection.',
      );
    }
  }

  static DateTime? _toDate(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  /// Newest first; a just-created item (no server time yet) comes first.
  static int _newestFirst(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return b.compareTo(a);
  }
}
