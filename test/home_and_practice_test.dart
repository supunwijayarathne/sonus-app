import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:sonus_app/data/mock_data.dart';
import 'package:sonus_app/features/home/user_shell.dart';
import 'package:sonus_app/features/practice/practice_screen.dart';
import 'package:sonus_app/theme/app_theme.dart';
import 'package:sonus_app/utils/format.dart';

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
  group('home', () {
    for (final entry in _sizes.entries) {
      testWidgets('fits on ${entry.key}', (tester) async {
        _setSize(tester, entry.value);
        await tester.pumpWidget(_app(const UserShell()));

        expect(find.text('Ready for your\nnext practice?'), findsOneWidget);
        expect(find.text('Start practice'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('start practice opens the practice screen', (tester) async {
      _setSize(tester, const Size(402, 874));
      await tester.pumpWidget(_app(const UserShell()));

      await tester.tap(find.text('Start practice'));
      await tester.pumpAndSettle();

      expect(find.text('TARGET WORD'), findsOneWidget);
    });

    testWidgets('Practice nav item is a quick link to practice', (
      tester,
    ) async {
      _setSize(tester, const Size(402, 874));
      await tester.pumpWidget(_app(const UserShell()));

      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();
      expect(find.text('TARGET WORD'), findsOneWidget);

      // Back returns to Home, which is still the selected tab.
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Start practice'), findsOneWidget);
    });

    testWidgets('uses suggestion wording only', (tester) async {
      await tester.pumpWidget(_app(const UserShell()));
      expect(find.textContaining(_forbidden), findsNothing);
    });
  });

  group('practice', () {
    for (final entry in _sizes.entries) {
      testWidgets('fits on ${entry.key}', (tester) async {
        _setSize(tester, entry.value);
        await tester.pumpWidget(
          _app(const PracticeScreen(words: MockData.practiceWords, index: 1)),
        );

        expect(find.text('කමල'), findsOneWidget);
        expect(find.text('2 of 5'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('play shows "Playing reference", then returns', (tester) async {
      _setSize(tester, const Size(402, 874));
      await tester.pumpWidget(
        _app(const PracticeScreen(words: MockData.practiceWords)),
      );

      expect(find.text('Listen to the pronunciation'), findsOneWidget);
      await tester.tap(find.byTooltip('Play pronunciation'));
      await tester.pump();
      expect(find.text('Playing reference'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2)); // simulated audio ends
      expect(find.text('Listen to the pronunciation'), findsOneWidget);
    });
  });

  group('format', () {
    test('session time', () {
      final now = DateTime(2026, 11, 18, 20);
      expect(
        sessionTime(DateTime(2026, 11, 18, 18, 42), now: now),
        'Today, 6:42 PM',
      );
      expect(
        sessionTime(DateTime(2026, 11, 17, 0, 5), now: now),
        'Yesterday, 12:05 AM',
      );
      expect(
        sessionTime(DateTime(2026, 11, 2, 12, 0), now: now),
        'Nov 2, 12:00 PM',
      );
    });

    test('greeting', () {
      expect(greetingFor(DateTime(2026, 1, 1, 9)), 'Good morning');
      expect(greetingFor(DateTime(2026, 1, 1, 14)), 'Good afternoon');
      expect(greetingFor(DateTime(2026, 1, 1, 19)), 'Good evening');
    });
  });
}
