import 'analysis_result.dart';
import 'practice_word.dart';

/// One recorded word and its automated result.
class WordAttempt {
  const WordAttempt({
    required this.word,
    required this.result,
    required this.recordingLength,
    required this.referenceLength,
  });

  final PracticeWord word;
  final AnalysisResult result;
  final Duration recordingLength;
  final Duration referenceLength;
}

/// A practice session: the words recorded in one sitting.
class PracticeSession {
  const PracticeSession({required this.at, required this.attempts});

  final DateTime at;
  final List<WordAttempt> attempts;

  int get wordsPracticed => attempts.length;

  /// Number of *words* with at least one possible difference.
  int get possibleDifferences =>
      attempts.where((a) => a.result.hasDifference).length;
}
