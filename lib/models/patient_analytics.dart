import 'analysis_result.dart';
import 'practice_session.dart';

/// Summary numbers for one user, worked out from their practice sessions
/// (therapist's user profile).
///
/// Every number comes from the automated results. The match % is agreement
/// between the detected and expected sound sequences, NOT speech health or
/// therapy progress (CLAUDE.md rule 1). Recordings that failed the quality
/// check are left out of the match numbers.
class PatientAnalytics {
  const PatientAnalytics._({
    required this.trend,
    required this.differences,
    required this.sounds,
    required this.words,
    required this.sessionCount,
    required this.wordsRecorded,
    required this.daysActive,
    required this.sessionsLast7Days,
    required this.lastPracticeAt,
  });

  /// [sessions] may be in any order.
  factory PatientAnalytics.from(
    List<PracticeSession> sessions, {
    DateTime? now,
  }) {
    now ??= DateTime.now();
    final oldestFirst = [...sessions]..sort((a, b) => a.at.compareTo(b.at));

    final trend = <TrendPoint>[];
    final differenceCounts = <DifferenceKey, int>{};
    final soundCounts = <String, (int, int)>{}; // sound -> (matched, total)
    final wordMatches = <String, List<double>>{};
    final days = <DateTime>{};
    var wordsRecorded = 0;

    for (final session in oldestFirst) {
      days.add(DateTime(session.at.year, session.at.month, session.at.day));
      final matches = <double>[];

      for (final attempt in session.attempts) {
        wordsRecorded++;
        final result = attempt.result;
        if (!result.quality.ok) continue;

        matches.add(result.matchPercent);
        (wordMatches[attempt.word.text] ??= []).add(result.matchPercent);

        for (final op in result.ops) {
          if (op.isDifference) {
            final key = DifferenceKey(op.kind, op.expected, op.predicted);
            differenceCounts[key] = (differenceCounts[key] ?? 0) + 1;
          }
          final sound = op.expected;
          if (sound != null) {
            final (matched, total) = soundCounts[sound] ?? (0, 0);
            soundCounts[sound] = (
              matched + (op.kind == OpKind.match ? 1 : 0),
              total + 1,
            );
          }
        }
      }

      if (matches.isNotEmpty) {
        trend.add(TrendPoint(session.at, _average(matches)));
      }
    }

    final differences = [
      for (final e in differenceCounts.entries) DifferenceCount(e.key, e.value),
    ]..sort((a, b) => b.count.compareTo(a.count));

    // Sounds with the lowest match rate first, then the most frequent.
    final sounds =
        [
          for (final e in soundCounts.entries)
            SoundStat(e.key, matched: e.value.$1, total: e.value.$2),
        ]..sort((a, b) {
          final byRate = a.rate.compareTo(b.rate);
          return byRate != 0 ? byRate : b.total.compareTo(a.total);
        });

    // Words with the lowest average match first.
    final words = [
      for (final e in wordMatches.entries)
        WordStat(
          e.key,
          attempts: e.value.length,
          averageMatch: _average(e.value),
          latestMatch: e.value.last,
        ),
    ]..sort((a, b) => a.averageMatch.compareTo(b.averageMatch));

    final weekAgo = now.subtract(const Duration(days: 7));
    return PatientAnalytics._(
      trend: trend,
      differences: differences,
      sounds: sounds,
      words: words,
      sessionCount: sessions.length,
      wordsRecorded: wordsRecorded,
      daysActive: days.length,
      sessionsLast7Days: sessions.where((s) => s.at.isAfter(weekAgo)).length,
      lastPracticeAt: oldestFirst.isEmpty ? null : oldestFirst.last.at,
    );
  }

  /// Average match per session, oldest first.
  final List<TrendPoint> trend;

  /// Possible differences (sub / del / ins), most frequent first.
  final List<DifferenceCount> differences;

  /// How often each expected sound was matched, lowest rate first.
  final List<SoundStat> sounds;

  /// Per practised word, lowest average match first.
  final List<WordStat> words;

  final int sessionCount;
  final int wordsRecorded;

  /// Distinct calendar days with at least one session.
  final int daysActive;
  final int sessionsLast7Days;
  final DateTime? lastPracticeAt;

  bool get isEmpty => sessionCount == 0;

  /// Average of all session averages (null when nothing was analysed).
  double? get averageMatch =>
      trend.isEmpty ? null : _average([for (final p in trend) p.matchPercent]);

  /// Latest session's match minus the first one's, in percentage points
  /// (null with fewer than two analysed sessions).
  double? get changeSinceFirst => trend.length < 2
      ? null
      : trend.last.matchPercent - trend.first.matchPercent;

  static double _average(List<double> values) =>
      values.reduce((a, b) => a + b) / values.length;
}

/// One point of the match chart.
class TrendPoint {
  const TrendPoint(this.at, this.matchPercent);

  final DateTime at;
  final double matchPercent;
}

/// What kind of difference: "l → r" (sub), "l missing" (del), "r added" (ins).
class DifferenceKey {
  const DifferenceKey(this.kind, this.expected, this.predicted);

  final OpKind kind;
  final String? expected;
  final String? predicted;

  /// Short label, e.g. "l → r".
  String get label => switch (kind) {
    OpKind.sub => '$expected → $predicted',
    OpKind.del => '$expected missing',
    OpKind.ins => '$predicted added',
    OpKind.match => '$expected',
  };

  @override
  bool operator ==(Object other) =>
      other is DifferenceKey &&
      other.kind == kind &&
      other.expected == expected &&
      other.predicted == predicted;

  @override
  int get hashCode => Object.hash(kind, expected, predicted);
}

class DifferenceCount {
  const DifferenceCount(this.key, this.count);

  final DifferenceKey key;
  final int count;
}

/// One expected sound: matched [matched] times out of [total].
class SoundStat {
  const SoundStat(this.sound, {required this.matched, required this.total});

  final String sound;
  final int matched;
  final int total;

  /// 0.0 - 1.0
  double get rate => total == 0 ? 0 : matched / total;
}

class WordStat {
  const WordStat(
    this.text, {
    required this.attempts,
    required this.averageMatch,
    required this.latestMatch,
  });

  final String text;
  final int attempts;
  final double averageMatch;
  final double latestMatch;
}
