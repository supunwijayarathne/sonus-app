import 'package:material_ui/material_ui.dart';

import '../../models/practice_session.dart';
import '../../models/practice_word.dart';
import '../../services/analysis_service.dart';
import '../result/result_screen.dart';
import '../summary/session_summary_screen.dart';
import 'practice_screen.dart';

/// Runs one practice session:
///
///   Practice (word 1) -> Result -> Practice (word 2) -> ... -> Summary
///
/// Each step *replaces* the previous screen, so the back button always
/// returns to Home instead of walking back through every word.
class PracticeFlow {
  PracticeFlow(this.words);

  final List<PracticeWord> words;

  /// Latest attempt for each word index (a retry replaces it in the summary;
  /// every attempt is still stored separately once Firestore is connected).
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
        onRecord: () => _analyse(context, index),
      ),
    );
  }

  Future<void> _analyse(BuildContext context, int index) async {
    final word = words[index];
    final result = await analysisService.analyze(
      text: word.text,
      audioPath: '', // real recording comes with the record package
    );
    final attempt = WordAttempt(
      word: word,
      result: result,
      recordingLength: Duration(
        milliseconds: (result.quality.durationS * 1000).round(),
      ),
      referenceLength: const Duration(seconds: 2),
    );
    _attempts[index] = attempt;

    if (!context.mounted) return;
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

  void _showSummary(BuildContext context) {
    final session = PracticeSession(
      at: _startedAt,
      attempts: [for (var i = 0; i < words.length; i++) ?_attempts[i]],
    );
    Navigator.pushReplacement(
      context,
      _route(SessionSummaryScreen(session: session, justCompleted: true)),
    );
  }
}
