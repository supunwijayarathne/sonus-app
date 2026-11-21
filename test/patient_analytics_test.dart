import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:sonus_app/data/mock_data.dart';
import 'package:sonus_app/features/therapist/patient_analytics_section.dart';
import 'package:sonus_app/features/therapist/patient_profile_screen.dart';
import 'package:sonus_app/models/analysis_result.dart';
import 'package:sonus_app/models/patient_analytics.dart';
import 'package:sonus_app/models/practice_session.dart';
import 'package:sonus_app/models/practice_word.dart';
import 'package:sonus_app/services/practice_repository.dart';
import 'package:sonus_app/theme/app_theme.dart';

import 'fakes/fake_practice_repository.dart';

/// One attempt at [text]: [ops] as (op, expected, predicted).
WordAttempt _attempt(
  String text,
  List<(String, String?, String?)> ops, {
  bool qualityOk = true,
}) {
  final matches = ops.where((o) => o.$1 == 'match').length;
  return WordAttempt(
    id: '$text-${ops.hashCode}',
    word: PracticeWord(text: text),
    result: AnalysisResult.fromJson({
      'quality': {'ok': qualityOk, 'reason': null, 'duration_s': 1.0},
      'expected': [for (final o in ops) ?o.$2],
      'predicted': [for (final o in ops) ?o.$3],
      'ops': [
        for (var i = 0; i < ops.length; i++)
          {
            'op': ops[i].$1,
            'expected': ops[i].$2,
            'predicted': ops[i].$3,
            'position': i,
          },
      ],
      'match_percent': qualityOk ? 100 * matches / ops.length : 0,
      'model_version': 'test',
      'g2p_version': 'test',
    }),
    recordingLength: const Duration(seconds: 1),
    referenceLength: const Duration(seconds: 1),
  );
}

// මල with l -> r (75 %) and මල matched (100 %).
final _malaSub = _attempt('මල', [
  ('match', 'm', 'm'),
  ('match', 'a', 'a'),
  ('sub', 'l', 'r'),
  ('match', 'ə', 'ə'),
]);
final _malaOk = _attempt('මල', [
  ('match', 'm', 'm'),
  ('match', 'a', 'a'),
  ('match', 'l', 'l'),
  ('match', 'ə', 'ə'),
]);
// ගස with s deleted (2 of 3 = 67 %).
final _gasaDel = _attempt('ගස', [
  ('match', 'ɡ', 'ɡ'),
  ('match', 'a', 'a'),
  ('del', 's', null),
]);

void main() {
  final now = DateTime(2026, 11, 19, 12);

  group('PatientAnalytics', () {
    test('no sessions: empty', () {
      final a = PatientAnalytics.from(const [], now: now);
      expect(a.isEmpty, isTrue);
      expect(a.averageMatch, isNull);
      expect(a.changeSinceFirst, isNull);
      expect(a.lastPracticeAt, isNull);
    });

    test('trend, differences, sounds, words and activity', () {
      final sessions = [
        // Newest first, as the repository gives them.
        PracticeSession(
          at: DateTime(2026, 11, 18, 9),
          attempts: [_malaOk, _malaOk],
        ),
        PracticeSession(
          at: DateTime(2026, 11, 1, 9),
          attempts: [_malaSub, _gasaDel],
        ),
        PracticeSession(at: DateTime(2026, 11, 1, 18), attempts: [_malaSub]),
      ];
      final a = PatientAnalytics.from(sessions, now: now);

      // Oldest first; one point per session (session average).
      expect([for (final p in a.trend) p.matchPercent.round()], [71, 75, 100]);
      expect(a.changeSinceFirst!.round(), 29);

      expect(a.differences.first.key.label, 'l → r');
      expect(a.differences.first.count, 2);
      expect(a.differences.last.key.label, 's missing');

      // s: 0 of 1 matched comes before l: 2 of 4.
      expect(a.sounds.first.sound, 's');
      final l = a.sounds.firstWhere((s) => s.sound == 'l');
      expect((l.matched, l.total), (2, 4));

      expect(a.words.first.text, 'ගස');
      final mala = a.words.firstWhere((w) => w.text == 'මල');
      expect(mala.attempts, 4);
      expect(mala.averageMatch, 87.5);

      expect(a.sessionCount, 3);
      expect(a.wordsRecorded, 5);
      expect(a.daysActive, 2); // two sessions on Nov 1
      expect(a.sessionsLast7Days, 1);
      expect(a.lastPracticeAt, DateTime(2026, 11, 18, 9));
    });

    test('recordings that failed the quality check are left out', () {
      final failed = _attempt('මල', [('sub', 'm', 'n')], qualityOk: false);
      final a = PatientAnalytics.from([
        PracticeSession(at: now, attempts: [failed, _malaOk]),
      ], now: now);

      expect(a.wordsRecorded, 2);
      expect(a.trend.single.matchPercent, 100);
      expect(a.differences, isEmpty);
    });
  });

  group('analytics on the user profile', () {
    setUp(() => practiceRepository = FakePracticeRepository.sample());

    Widget app(Widget child) =>
        MaterialApp(theme: AppTheme.dark(), home: child);

    testWidgets('shows the chart, differences and the note', (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        app(
          PatientProfileScreen(
            patient: MockData.patients.first, // Nimali: කමල m -> n
            therapistId: MockData.therapist.id,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Practice analytics'), findsOneWidget);
      expect(find.text('Match with expected sounds'), findsOneWidget);
      expect(find.text('m → n'), findsOneWidget);
      expect(find.text('Words recorded'), findsOneWidget);
      await tester.ensureVisible(find.text(PatientAnalyticsSection.note));
      expect(tester.takeException(), isNull);

      // CLAUDE.md rule 1: no "accuracy", "progress" only inside the note.
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .where((t) => t != PatientAnalyticsSection.note);
      for (final t in texts) {
        expect(
          t,
          isNot(
            matches(RegExp('accura|progress|diagnos', caseSensitive: false)),
          ),
        );
      }
    });

    testWidgets('a user without sessions gets a short message', (tester) async {
      await tester.pumpWidget(
        app(
          SingleChildScrollView(
            child: PatientAnalyticsSection(
              analytics: PatientAnalytics.from(const []),
            ),
          ),
        ),
      );
      expect(find.textContaining('after the first practice'), findsOneWidget);
      expect(find.text('Match with expected sounds'), findsNothing);
    });
  });
}
