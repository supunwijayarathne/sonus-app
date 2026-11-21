import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../models/analysis_result.dart';
import '../../models/practice_session.dart';
import '../../models/practice_word.dart';
import '../../services/analysis_service.dart';
import '../../services/practice_repository.dart';
import '../../services/voice_recorder.dart';
import '../result/result_screen.dart';
import '../summary/session_summary_screen.dart';
import 'practice_screen.dart';

/// Runs one practice session:
///
///   Practice (word 1) -> Result -> Practice (word 2) -> ... -> Summary
///
/// Each step *replaces* the previous screen, so the back button always
/// returns to Home instead of walking back through every word.
///
/// Every analysed attempt (retries too) is saved to Firestore straight away,
/// with the same session ID, so leaving early keeps what was recorded.
class PracticeFlow {
  PracticeFlow(this.words, {required this.userId, required this.therapistId})
    : _sessionId = '$userId-${DateTime.now().millisecondsSinceEpoch}';

  final List<PracticeWord> words;

  /// Whose session this is, and their therapist (stored on each attempt).
  final String userId;
  final String therapistId;

  final String _sessionId;

  /// Latest attempt for each word index (a retry replaces it in the summary).
  final Map<int, WordAttempt> _attempts = {};
  final DateTime _startedAt = DateTime.now();

  void start(BuildContext context) {
    Navigator.push(context, _route(_practice(0)));
  }

  MaterialPageRoute<void> _route(Widget screen) =>
      MaterialPageRoute(builder: (_) => screen);

  Widget _practice(int index) {
    return Builder(
      builder: (context) => PracticeScreen(
        words: words,
        index: index,
        onRecorded: (id, recording, quality) =>
            _analyse(context, index, id, recording, quality),
      ),
    );
  }

  Future<void> _analyse(
    BuildContext context,
    int index,
    String attemptId,
    Recording recording,
    QualityCheck quality,
  ) async {
    final word = words[index];
    final result = await analysisService.analyze(
      text: word.text,
      audioPath: recording.path,
    );
    final attempt = WordAttempt(
      id: attemptId,
      word: word,
      result: result,
      recordingLength: Duration(
        milliseconds: (quality.durationS * 1000).round(),
      ),
      referenceLength: const Duration(seconds: 2),
      audioPath: recording.path,
    );
    _attempts[index] = attempt;

    if (!context.mounted) return;
    _save(context, attempt);

    final isLast = index == words.length - 1;
    Navigator.pushReplacement(
      context,
      _route(
        Builder(
          builder: (resultContext) => ResultScreen(
            attempt: attempt,
            nextLabel: isLast ? 'See summary' : 'Next word',
            onNext: () => isLast
                ? _showSummary(resultContext)
                : Navigator.pushReplacement(
                    resultContext,
                    _route(_practice(index + 1)),
                  ),
            onTryAgain: () => Navigator.pushReplacement(
              resultContext,
              _route(_practice(index)),
            ),
          ),
        ),
      ),
    );
  }

  /// Saves without waiting: offline, Firestore keeps the write and sends it
  /// later, so the user can go on practising. A refused save is shown.
  void _save(BuildContext context, WordAttempt attempt) {
    final messenger = ScaffoldMessenger.of(context);
    unawaited(
      practiceRepository
          .saveAttempt(
            userId: userId,
            therapistId: therapistId,
            sessionId: _sessionId,
            attempt: attempt,
          )
          .catchError((Object e) {
            messenger.showSnackBar(
              SnackBar(content: Text('This attempt was not saved. $e')),
            );
          }),
    );
  }

  void _showSummary(BuildContext context) {
    final session = PracticeSession(
      id: _sessionId,
      at: _startedAt,
      attempts: [for (var i = 0; i < words.length; i++) ?_attempts[i]],
    );
    Navigator.pushReplacement(
      context,
      _route(SessionSummaryScreen(session: session, justCompleted: true)),
    );
  }
}
