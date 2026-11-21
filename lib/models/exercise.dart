import 'package:cloud_firestore/cloud_firestore.dart';

import 'practice_word.dart';

/// A word or short phrase a therapist created (Firestore `exercises/{id}`).
///
/// Exercises are never edited: a typo is fixed by deleting and creating a
/// new one, so results always point to the text that was practised.
class Exercise {
  const Exercise({
    required this.id,
    required this.therapistId,
    required this.text,
    this.romanized = '',
    required this.expectedPhonemes,
    required this.g2pVersion,
    this.createdAt,
  });

  factory Exercise.fromMap(String id, Map<String, dynamic> data) {
    return Exercise(
      id: id,
      therapistId: data['therapistId'] as String,
      text: data['text'] as String,
      romanized: data['romanized'] as String? ?? '',
      expectedPhonemes: List<String>.from(data['expectedPhonemes'] as List),
      g2pVersion: data['g2pVersion'] as String? ?? '',
      createdAt: _date(data['createdAt']),
    );
  }

  final String id;
  final String therapistId;

  /// Sinhala, NFC (e.g. කමල).
  final String text;

  /// Optional Latin reading aid (e.g. "kamala"); '' when not given.
  final String romanized;

  /// From G2P, one IPA symbol per item (e.g. [k, a, m, a, l, ə]).
  final List<String> expectedPhonemes;
  final String g2pVersion;

  /// Null for a moment after creating it (set by the server).
  final DateTime? createdAt;

  PracticeWord get word =>
      PracticeWord(text: text, romanized: romanized, exerciseId: id);
}

/// An exercise given to one user (Firestore `assignments/{userId}_{exerciseId}`).
///
/// It keeps a copy of the exercise's text and phonemes, so the user can read
/// their assignments without access to the therapist's exercise library.
class Assignment {
  const Assignment({
    required this.therapistId,
    required this.userId,
    required this.exerciseId,
    required this.text,
    this.romanized = '',
    required this.expectedPhonemes,
    this.createdAt,
  });

  factory Assignment.fromMap(Map<String, dynamic> data) {
    return Assignment(
      therapistId: data['therapistId'] as String,
      userId: data['userId'] as String,
      exerciseId: data['exerciseId'] as String,
      text: data['text'] as String,
      romanized: data['romanized'] as String? ?? '',
      expectedPhonemes: List<String>.from(data['expectedPhonemes'] as List),
      createdAt: _date(data['createdAt']),
    );
  }

  /// One document per user and exercise, so the same exercise can't be
  /// assigned twice.
  static String idFor(String userId, String exerciseId) =>
      '${userId}_$exerciseId';

  String get id => idFor(userId, exerciseId);

  final String therapistId;
  final String userId;
  final String exerciseId;
  final String text;
  final String romanized;
  final List<String> expectedPhonemes;
  final DateTime? createdAt;

  PracticeWord get word =>
      PracticeWord(text: text, romanized: romanized, exerciseId: exerciseId);
}

/// Firestore Timestamp -> DateTime (null while the server time is pending).
DateTime? _date(Object? value) => value is Timestamp ? value.toDate() : null;
