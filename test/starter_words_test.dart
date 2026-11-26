import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:sonus_app/data/mock_data.dart';
import 'package:sonus_app/features/exercises/starter_words_screen.dart';
import 'package:sonus_app/features/practice/practice_screen.dart';
import 'package:sonus_app/models/practice_word.dart';
import 'package:sonus_app/services/g2p.dart';
import 'package:sonus_app/services/practice_repository.dart';
import 'package:sonus_app/services/reference_audio.dart';
import 'package:sonus_app/theme/app_theme.dart';

import 'fakes/fake_practice_repository.dart';
import 'fakes/fake_reference_player.dart';

Widget _app(Widget child) => MaterialApp(theme: AppTheme.dark(), home: child);

/// The real word list, read from the assets folder.
final _all = StarterWords.parse(
  File('assets/starter_words.tsv').readAsStringSync(),
);

void main() {
  late FakeReferencePlayer player;

  setUp(() {
    player = FakeReferencePlayer();
    referencePlayer = player;
    starterWords = _all;
  });
  tearDown(() => starterWords = StarterWords(const []));

  void phoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('word list', () {
    test('100 words, each with its recording', () {
      expect(_all.words, hasLength(100));
      expect(_all.words.map((w) => w.text).toSet(), hasLength(100));
      for (final word in _all.words) {
        expect(File(word.assetPath).existsSync(), isTrue, reason: word.id);
        expect(word.length, greaterThan(Duration.zero), reason: word.id);
      }
      expect(_all.lookup('මල')!.id, 'w001');
      expect(_all.lookup('no such word'), isNull);
    });

    test("the app's G2P agrees with the service's for every word", () {
      final different = [
        for (final word in _all.words)
          if (SinhalaG2p.convert(word.text).phonemes.join(' ') !=
              word.expected.join(' '))
            '${word.text}: app ${SinhalaG2p.convert(word.text).phonemes} '
                'service ${word.expected}',
      ];
      expect(different, isEmpty);
    });
  });

  group('practice screen', () {
    testWidgets('plays the computer voice for a starter word', (tester) async {
      phoneSize(tester);
      await tester.pumpWidget(
        _app(const PracticeScreen(words: MockData.practiceWords)), // මල
      );
      expect(find.text('The reference sound is a computer voice.'), findsOne);
      expect(find.text('Listen to the pronunciation'), findsOneWidget);

      await tester.tap(find.byTooltip('Play pronunciation'));
      await tester.pump();
      expect(player.played, ['assets/reference_audio/w001.wav']);
      expect(find.text('Playing reference'), findsOneWidget);

      player.finish();
      await tester.pump();
      expect(find.text('Listen to the pronunciation'), findsOneWidget);
    });

    testWidgets('a word without a recording says so', (tester) async {
      phoneSize(tester);
      await tester.pumpWidget(
        _app(
          const PracticeScreen(words: [PracticeWord(text: 'කමල')]),
        ),
      );
      expect(find.text('No reference sound for this word yet'), findsOne);
      expect(
        find.text('Your therapist has not added a reference sound yet.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('No reference sound for this word yet'));
      await tester.pump();
      expect(player.played, isEmpty);
    });
  });

  group('starter words screen', () {
    late FakePracticeRepository repo;

    setUp(() {
      repo = FakePracticeRepository.sample();
      practiceRepository = repo;
    });

    testWidgets('adds the chosen words to the library', (tester) async {
      phoneSize(tester);
      final before = repo.allExercises.length;
      await tester.pumpWidget(
        _app(
          const StarterWordsScreen(
            therapistId: 't1',
            alreadyAdded: {'මල'},
          ),
        ),
      );

      // Already in the library: shown, but can't be chosen again.
      expect(find.text('flower · already in your library'), findsOneWidget);

      await tester.tap(find.text('බර'));
      await tester.tap(find.text('ගල'));
      await tester.pump();
      expect(find.text('Add 2 exercises'), findsOneWidget);

      await tester.tap(find.byTooltip('Listen to බර'));
      await tester.pump();
      expect(player.played, ['assets/reference_audio/w003.wav']);
      player.finish();

      await tester.tap(find.text('Add 2 exercises'));
      await tester.pumpAndSettle();
      expect(repo.allExercises, hasLength(before + 2));
      final added = repo.allExercises.take(2).map((e) => e.text).toSet();
      expect(added, {'බර', 'ගල'});
      final bara = repo.allExercises.firstWhere((e) => e.text == 'බර');
      expect(bara.expectedPhonemes, ['b', 'a', 'r', 'ə']);
    });

    testWidgets('select all skips words already added', (tester) async {
      phoneSize(tester);
      await tester.pumpWidget(
        _app(
          const StarterWordsScreen(
            therapistId: 't1',
            alreadyAdded: {'මල', 'බර'},
          ),
        ),
      );
      await tester.tap(find.text('Select all'));
      await tester.pump();
      expect(find.text('Add 98 exercises'), findsOneWidget);
      expect(find.text('Clear selection'), findsOneWidget);
    });
  });
}
