import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:sonus_app/data/mock_data.dart';
import 'package:sonus_app/features/home/user_shell.dart';
import 'package:sonus_app/features/practice/practice_screen.dart';
import 'package:sonus_app/services/audio_quality.dart';
import 'package:sonus_app/services/auth_repository.dart';
import 'package:sonus_app/services/practice_repository.dart';
import 'package:sonus_app/services/voice_recorder.dart';
import 'package:sonus_app/theme/app_theme.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_practice_repository.dart';
import 'fakes/fake_voice_recorder.dart';

Widget _app(Widget child) => MaterialApp(theme: AppTheme.dark(), home: child);

void main() {
  late FakeVoiceRecorder recorder;
  late FakePracticeRepository repo;

  setUp(() {
    authRepository = FakeAuthRepository();
    repo = FakePracticeRepository.sample();
    practiceRepository = repo;
    recorder = FakeVoiceRecorder();
    voiceRecorder = recorder;
  });

  void phoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// A practice screen that remembers what reached the analysis step.
  Future<List<String>> pumpPractice(WidgetTester tester) async {
    final analysed = <String>[];
    await tester.pumpWidget(
      _app(
        PracticeScreen(
          words: MockData.practiceWords,
          onRecorded: (id, recording, quality) async => analysed.add(id),
        ),
      ),
    );
    return analysed;
  }

  testWidgets('tap to record, tap to stop', (tester) async {
    phoneSize(tester);
    final analysed = await pumpPractice(tester);

    await tester.tap(find.byTooltip('Record'));
    await tester.pump();
    expect(find.byTooltip('Stop recording'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Recording 0:02'), findsOneWidget);

    await tester.tap(find.byTooltip('Stop recording'));
    await tester.pumpAndSettle();
    expect(analysed, hasLength(1));
    expect(recorder.kept, hasLength(1)); // saved at playback level
    expect(find.text('Tap to record'), findsOneWidget);
  });

  testWidgets('a near-silent recording is not analysed', (tester) async {
    phoneSize(tester);
    recorder.nextWav = testWav(level: 0);
    final analysed = await pumpPractice(tester);

    await tester.tap(find.byTooltip('Record'));
    await tester.pump();
    await tester.tap(find.byTooltip('Stop recording'));
    await tester.pumpAndSettle();

    expect(analysed, isEmpty);
    expect(find.text(AudioQuality.tooQuiet), findsOneWidget);
    expect(recorder.discarded, hasLength(1)); // the file is deleted
    expect(recorder.kept, isEmpty);
    expect(find.byTooltip('Record'), findsOneWidget); // record again
  });

  testWidgets('a too-short recording asks to record again', (tester) async {
    phoneSize(tester);
    recorder.nextWav = testWav(seconds: 0.1);
    final analysed = await pumpPractice(tester);

    await tester.tap(find.byTooltip('Record'));
    await tester.pump();
    await tester.tap(find.byTooltip('Stop recording'));
    await tester.pumpAndSettle();

    expect(analysed, isEmpty);
    expect(find.text(AudioQuality.tooShort), findsOneWidget);
  });

  testWidgets('stops by itself before 15 seconds', (tester) async {
    phoneSize(tester);
    final analysed = await pumpPractice(tester);

    await tester.tap(find.byTooltip('Record'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();
    expect(analysed, hasLength(1));
  });

  testWidgets('no microphone access: explains, does not record', (
    tester,
  ) async {
    phoneSize(tester);
    recorder.allowed = false;
    final analysed = await pumpPractice(tester);

    await tester.tap(find.byTooltip('Record'));
    await tester.pumpAndSettle();
    expect(find.textContaining('needs the microphone'), findsOneWidget);
    expect(find.byTooltip('Stop recording'), findsNothing);
    expect(analysed, isEmpty);
  });

  testWidgets('every analysed attempt is saved, in one session', (
    tester,
  ) async {
    phoneSize(tester);
    await tester.pumpWidget(_app(const UserShell()));
    await tester.pump();
    final before = repo.allSessions[MockData.user.id]!.length;

    await tester.tap(find.text('Start practice'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byTooltip('Record'));
      await tester.pump();
      await tester.tap(find.byTooltip('Stop recording'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // mock service
      await tester.pumpAndSettle();
      expect(find.text('Your result'), findsOneWidget);
      await tester.ensureVisible(find.text('Next word'));
      await tester.tap(find.text('Next word'));
      await tester.pumpAndSettle();
    }

    final sessions = repo.allSessions[MockData.user.id]!;
    expect(sessions, hasLength(before + 1));
    expect(sessions.first.attempts.map((a) => a.word.text), ['මල', 'කමල']);
  });
}
