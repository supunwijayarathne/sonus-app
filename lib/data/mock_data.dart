import '../models/analysis_result.dart';
import '../models/home_summary.dart';
import '../models/patient_record.dart';
import '../models/practice_session.dart';
import '../models/practice_word.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

/// Sample data for building the UI before Firebase and the analysis service
/// are connected. Everything that reads from here will read from Firestore
/// (or the service) later.
///
/// The phoneme sequences are illustrative only; real ones come from G2P.
class MockData {
  MockData._();

  static const UserProfile user = UserProfile(
    name: 'Nimali Perera',
    email: 'nimali@example.com',
    role: UserRole.user,
    code: 'SN-2048',
  );

  static const List<PracticeWord> practiceWords = [
    PracticeWord(text: 'මල', romanized: 'mala'),
    PracticeWord(text: 'කමල', romanized: 'kamala'),
    PracticeWord(text: 'ගස', romanized: 'gasa'),
    PracticeWord(text: 'පොත', romanized: 'pota'),
    PracticeWord(text: 'රස', romanized: 'rasa'),
  ];

  /// Expected phonemes per word (space-separated, as G2P returns them).
  static const Map<String, String> _expected = {
    'මල': 'm a l ə',
    'කමල': 'k a m a l ə',
    'ගස': 'ɡ a s ə',
    'පොත': 'p o t̪ ə',
    'රස': 'r a s ə',
  };

  /// Simulated detections: word -> {position: detected sound}.
  static const Map<String, Map<int, String>> _substitutions = {
    'කමල': {2: 'n'},
    'පොත': {2: 'ʈ'},
  };

  /// Mock `POST /analyze` response for [text] (same JSON shape as CLAUDE.md).
  static Map<String, dynamic> analysisJsonFor(String text) {
    // Split on spaces, never per character (t̪ is two code points).
    final expected = (_expected[text] ?? 'a').split(' ');
    final subs = _substitutions[text] ?? const {};

    final ops = <Map<String, dynamic>>[];
    final predicted = <String>[];
    for (var i = 0; i < expected.length; i++) {
      final detected = subs[i] ?? expected[i];
      predicted.add(detected);
      ops.add({
        'op': detected == expected[i] ? 'match' : 'sub',
        'expected': expected[i],
        'predicted': detected,
        'position': i,
      });
    }
    final matches = ops.where((op) => op['op'] == 'match').length;

    return {
      'quality': {'ok': true, 'reason': null, 'duration_s': 0.84},
      'expected': expected,
      'predicted': predicted,
      'ops': ops,
      'match_percent': 100 * matches / expected.length,
      'model_version': 'mms300m-L12-bilstm-ctc',
      'g2p_version': 'inv-v1.1+cff96fb2',
    };
  }

  static WordAttempt attemptFor(PracticeWord word, {String? id}) {
    return WordAttempt(
      id: id ?? 'attempt-${word.romanized}',
      word: word,
      result: AnalysisResult.fromJson(analysisJsonFor(word.text)),
      recordingLength: const Duration(seconds: 3),
      referenceLength: const Duration(seconds: 2),
    );
  }

  /// Builds sessions for one user. Each plan entry is
  /// (how long before today 00:00 (negative = later today), word indexes).
  static List<PracticeSession> _sessionsFor(
    String userCode,
    List<(Duration, List<int>)> plan,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      for (var s = 0; s < plan.length; s++)
        PracticeSession(
          at: today.subtract(plan[s].$1),
          attempts: [
            for (var w = 0; w < plan[s].$2.length; w++)
              attemptFor(practiceWords[plan[s].$2[w]], id: '$userCode-s$s-w$w'),
          ],
        ),
    ];
  }

  /// Nimali's past sessions, newest first (built once, so IDs stay stable).
  static List<PracticeSession> sessions() => _nimaliSessions;

  static final List<PracticeSession> _nimaliSessions = _sessionsFor('SN-2048', [
    (const Duration(hours: -18, minutes: -42), [0, 1, 2, 4, 2]),
    (const Duration(days: 2, hours: 4, minutes: 45), [0, 2, 4, 0, 2]),
    (const Duration(days: 5, hours: 5, minutes: 30), [1, 3, 0, 2, 4]),
    (const Duration(days: 34, hours: 6, minutes: 5), [3, 0, 2, 4, 0]),
  ]);

  // ---------------------------------------------------------------------------
  // Therapist side

  static const UserProfile therapist = UserProfile(
    name: 'Dr. Amaya Silva',
    email: 'amaya@sonus.care',
    role: UserRole.therapist,
  );

  /// Users assigned to [therapist], most recent activity first.
  static final List<PatientRecord> patients = _buildPatients();

  static List<PatientRecord> _buildPatients() {
    final now = DateTime.now();
    PatientRecord patient(
      String name,
      String code,
      int linkedDaysAgo,
      List<PracticeSession> sessions,
    ) {
      return PatientRecord(
        profile: UserProfile(
          name: name,
          email: '${name.split(' ').first.toLowerCase()}@example.com',
          role: UserRole.user,
          code: code,
        ),
        linkedAt: now.subtract(Duration(days: linkedDaysAgo)),
        sessions: sessions,
      );
    }

    return [
      patient('Nimali Perera', 'SN-2048', 300, _nimaliSessions),
      patient(
        'Kasun Jayasuriya',
        'SN-1984',
        200,
        _sessionsFor('SN-1984', [
          (const Duration(hours: 4), [0, 2, 4]),
          (const Duration(days: 4, hours: 5), [3, 0, 2]),
        ]),
      ),
      patient(
        'Dinithi Fernando',
        'SN-1762',
        150,
        _sessionsFor('SN-1762', [
          (const Duration(days: 8, hours: 6), [3, 4, 0, 2]),
        ]),
      ),
      patient(
        'Ruwan Karunaratne',
        'SN-1655',
        90,
        _sessionsFor('SN-1655', [
          (const Duration(days: 12, hours: 7), [0, 2, 4, 0]),
        ]),
      ),
    ];
  }

  /// Home data for [profile]; the week and sessions are still sample data.
  static HomeSummary homeSummary([UserProfile profile = user]) {
    final today = DateTime.now().weekday; // 1 = Monday .. 7 = Sunday

    // Done on the days before today, then "today", then open days.
    final week = [
      for (var day = 1; day <= 7; day++)
        day < today
            ? DayStatus.done
            : (day == today ? DayStatus.today : DayStatus.open),
    ];

    return HomeSummary(
      firstName: profile.firstName,
      initials: profile.initials,
      week: week,
      sessionsDone: week.where((d) => d == DayStatus.done).length.clamp(0, 4),
      sessionsPlanned: 4,
      recent: sessions().first,
    );
  }
}
