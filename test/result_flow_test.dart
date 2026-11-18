import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:sonus_app/data/mock_data.dart';
import 'package:sonus_app/features/history/history_screen.dart';
import 'package:sonus_app/features/home/user_shell.dart';
import 'package:sonus_app/features/profile/profile_screen.dart';
import 'package:sonus_app/features/result/result_screen.dart';
import 'package:sonus_app/features/result/result_text.dart';
import 'package:sonus_app/features/summary/session_summary_screen.dart';
import 'package:sonus_app/models/analysis_result.dart';
import 'package:sonus_app/theme/app_theme.dart';
import 'package:sonus_app/widgets/result_note.dart';

Widget _app(Widget child) => MaterialApp(theme: AppTheme.dark(), home: child);

const _sizes = {
  'phone': Size(402, 874),
  'small phone': Size(320, 568),
  'landscape': Size(874, 402),
  'tablet': Size(820, 1180),
};

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Words that must never appear in the UI (CLAUDE.md rule 1).
final _forbidden = RegExp(
  r'diagnos|disorder|incorrect|accuracy',
  caseSensitive: false,
);

void main() {
  final kamala = MockData.attemptFor(MockData.practiceWords[1]); // m -> n
  final mala = MockData.attemptFor(MockData.practiceWords[0]); // all match

  group('analysis JSON', () {
    test('parses the CLAUDE.md example', () {
      final result = AnalysisResult.fromJson({
        'quality': {'ok': true, 'reason': null, 'duration_s': 0.84},
        'expected': ['m', 'a', 'l', 'ə'],
        'predicted': ['m', 'a', 'r', 'ə'],
        'ops': [
          {'op': 'match', 'expected': 'm', 'predicted': 'm', 'position': 0},
          {'op': 'match', 'expected': 'a', 'predicted': 'a', 'position': 1},
          {'op': 'sub', 'expected': 'l', 'predicted': 'r', 'position': 2},
          {'op': 'match', 'expected': 'ə', 'predicted': 'ə', 'position': 3},
        ],
        'match_percent': 75.0,
        'model_version': 'mms300m-L12-bilstm-ctc',
        'g2p_version': 'inv-v1.1+cff96fb2',
      });

      expect(result.matchPercent, 75.0);
      expect(result.differences.single.kind, OpKind.sub);
      expect(
        ResultText.explanation(result),
        'The third sound may have been pronounced closer to /r/ than the expected /l/.',
      );
    });

    test('quality failure has empty phonemes and asks to record again', () {
      final result = AnalysisResult.fromJson({
        'quality': {'ok': false, 'reason': 'Too quiet.', 'duration_s': 0.2},
        'expected': [],
        'predicted': [],
        'ops': [],
      });
      expect(ResultText.title(result), 'Please record again');
      expect(ResultText.explanation(result), 'Too quiet.');
    });

    test('multi-code-point symbols stay whole', () {
      final json = MockData.analysisJsonFor('පොත');
      expect(json['expected'], ['p', 'o', 't̪', 'ə']);
    });
  });

  group('result screen', () {
    for (final entry in _sizes.entries) {
      testWidgets('fits on ${entry.key}', (tester) async {
        _setSize(tester, entry.value);
        await tester.pumpWidget(
          _app(ResultScreen(attempt: kamala, onNext: () {}, onTryAgain: () {})),
        );
        expect(find.text('Possible sound difference detected'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('always shows the result note', (tester) async {
      for (final attempt in [kamala, mala]) {
        await tester.pumpWidget(_app(ResultScreen(attempt: attempt)));
        expect(find.byType(ResultNote), findsOneWidget);
      }
    });

    testWidgets('a change is labelled in text, not colour only', (
      tester,
    ) async {
      await tester.pumpWidget(_app(ResultScreen(attempt: kamala)));
      expect(find.text('m → n, possible substitution'), findsOneWidget);
    });

    testWidgets('review mode hides the buttons', (tester) async {
      await tester.pumpWidget(_app(ResultScreen(attempt: mala)));
      expect(find.text('Next word'), findsNothing);
      expect(find.text('Try again'), findsNothing);
      expect(find.text('Sounds matched the expected sounds'), findsOneWidget);
    });
  });

  group('summary, history, profile', () {
    final session = MockData.sessions().first;

    for (final entry in _sizes.entries) {
      testWidgets('all fit on ${entry.key}', (tester) async {
        _setSize(tester, entry.value);
        for (final screen in [
          SessionSummaryScreen(session: session, justCompleted: true),
          HistoryScreen(sessions: MockData.sessions()),
          const Scaffold(body: ProfileScreen(profile: MockData.user)),
        ]) {
          await tester.pumpWidget(_app(screen));
          expect(tester.takeException(), isNull);
        }
      });
    }

    testWidgets('summary counts words with a possible difference', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(SessionSummaryScreen(session: session, justCompleted: true)),
      );
      expect(
        find.text(
          'You practiced 5 words. One recording may benefit from another listen.',
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('full flow: practice -> result -> ... -> summary', (
    tester,
  ) async {
    _setSize(tester, const Size(402, 874));
    await tester.pumpWidget(_app(const UserShell()));

    await tester.tap(find.text('Start practice'));
    await tester.pumpAndSettle();

    for (var i = 0; i < MockData.practiceWords.length; i++) {
      await tester.tap(find.byTooltip('Record'));
      await tester.pump(); // "Analysing…"
      await tester.pump(const Duration(seconds: 1)); // mock service answers
      await tester.pumpAndSettle();

      expect(find.text('Your result'), findsOneWidget);
      expect(find.textContaining(_forbidden), findsNothing);

      final next = i == MockData.practiceWords.length - 1
          ? 'See summary'
          : 'Next word';
      await tester.ensureVisible(find.text(next));
      await tester.tap(find.text(next));
      await tester.pumpAndSettle();
    }

    expect(find.text('SESSION COMPLETED'), findsOneWidget);
    // කමල and පොත have simulated differences in the mock data.
    expect(find.text('Possible difference'), findsNWidgets(2));

    await tester.ensureVisible(find.text('Return home'));
    await tester.tap(find.text('Return home'));
    await tester.pumpAndSettle();
    expect(find.text('Start practice'), findsOneWidget);
  });
}
