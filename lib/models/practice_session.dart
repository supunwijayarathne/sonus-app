import 'analysis_result.dart';
import 'practice_word.dart';

/// One recorded word and its automated result (Firestore `attempts/{id}`).
class WordAttempt {
  const WordAttempt({
    required this.id,
    required this.word,
    required this.result,
    required this.recordingLength,
    required this.referenceLength,
    this.audioPath,
  });

  final String id;
  final PracticeWord word;

  /// The automated result. Write-once: never changed after it is stored.
  final AnalysisResult result;

  final Duration recordingLength;
  final Duration referenceLength;

  /// The recording on THIS phone, or null (other phone, or sample data).
  /// Recordings are never uploaded (Spark plan: no Firebase Storage).
  final String? audioPath;
}

/// A practice session: the words recorded in one sitting.
class PracticeSession {
  const PracticeSession({
    this.id = '',
    required this.at,
    required this.attempts,
  });

  /// Groups the attempts of one sitting (`sessionId` on each attempt).
  final String id;

  final DateTime at;
  final List<WordAttempt> attempts;

  int get wordsPracticed => attempts.length;

  /// Starter words the user chose themselves (not assigned by a therapist).
  bool get isSelfPractice =>
      attempts.isNotEmpty && attempts.every((a) => a.word.isSelfPractice);

  /// Number of *words* with at least one possible difference.
  int get possibleDifferences =>
      attempts.where((a) => a.result.hasDifference).length;
}
