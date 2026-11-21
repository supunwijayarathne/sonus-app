import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:sonus_app/data/mock_data.dart';
import 'package:sonus_app/features/auth/signup_screen.dart';
import 'package:sonus_app/features/exercises/create_exercise_screen.dart';
import 'package:sonus_app/features/therapist/patient_profile_screen.dart';
import 'package:sonus_app/features/therapist/session_review_screen.dart';
import 'package:sonus_app/features/therapist/therapist_shell.dart';
import 'package:sonus_app/features/therapist/users_screen.dart';
import 'package:sonus_app/models/review.dart';
import 'package:sonus_app/models/user_role.dart';
import 'package:sonus_app/services/review_store.dart';
import 'package:sonus_app/services/auth_repository.dart';
import 'package:sonus_app/services/practice_repository.dart';
import 'package:sonus_app/theme/app_theme.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_practice_repository.dart';

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
  r'diagnos|disorder|(in)?correct speech|accuracy',
  caseSensitive: false,
);

void main() {
  late FakePracticeRepository repo;

  setUp(() {
    reviewStore.clearForTest();
    authRepository = FakeAuthRepository();
    repo = FakePracticeRepository.sample();
    practiceRepository = repo;
  });

  final nimali = MockData.patients.first;
  final observation = nimali.observations.first; // කමල, m -> n

  group('sign up', () {
    for (final entry in _sizes.entries) {
      testWidgets('fits on ${entry.key}', (tester) async {
        _setSize(tester, entry.value);
        await tester.pumpWidget(_app(const SignUpScreen()));
        expect(find.text('Begin with Sonus.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('checks the form, then creates a therapist account', (
      tester,
    ) async {
      _setSize(tester, const Size(402, 874));
      UserRole? role;
      String? name;
      await tester.pumpWidget(
        _app(
          SignUpScreen(
            onCreateAccount: (r, n, _, _) async => (role, name) = (r, n),
          ),
        ),
      );

      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pump();
      expect(find.text('Please enter your name.'), findsOneWidget);
      expect(role, isNull);

      await tester.tap(find.text('Speech therapist'));
      await tester.pump();
      expect(find.text('Dr. Amaya Silva'), findsOneWidget); // role-based hint

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Dr. Amaya Silva');
      await tester.enterText(fields.at(1), 'amaya@example.com');
      await tester.enterText(fields.at(2), 'short');
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pump();
      expect(find.text('Use at least 8 characters.'), findsOneWidget);

      await tester.enterText(fields.at(2), 'long-enough');
      await tester.tap(find.text('Create account'));
      await tester.pump();
      expect(role, UserRole.therapist);
      expect(name, 'Dr. Amaya Silva');
    });
  });

  group('therapist screens', () {
    for (final entry in _sizes.entries) {
      testWidgets('all tabs fit on ${entry.key}', (tester) async {
        _setSize(tester, entry.value);
        await tester.pumpWidget(_app(const TherapistShell()));
        await tester.pump(); // data from the fake repository
        expect(find.text('Clinical overview'), findsOneWidget);

        for (final tab in ['Users', 'Exercises', 'Reviews', 'Profile']) {
          await tester.tap(find.text(tab).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: tab);
        }
      });

      testWidgets('user profile and review fit on ${entry.key}', (
        tester,
      ) async {
        _setSize(tester, entry.value);
        await tester.pumpWidget(
          _app(
            PatientProfileScreen(
              patient: nimali,
              therapistId: MockData.therapist.id,
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          _app(CreateExerciseScreen(therapistId: MockData.therapist.id)),
        );
        await tester.enterText(find.byType(TextFormField).first, 'කමල');
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          _app(
            SessionReviewScreen(
              observation: observation,
              therapistName: 'Dr. Amaya Silva',
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('therapist profile hides recording settings', (tester) async {
      _setSize(tester, const Size(402, 874));
      await tester.pumpWidget(_app(const TherapistShell()));
      await tester.pump(); // data from the fake repository
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      expect(find.text('SPEECH THERAPIST'), findsOneWidget);
      expect(find.text('Microphone access'), findsNothing);
      expect(find.text('Recording preferences'), findsNothing);
    });

    testWidgets('search filters by name or ID', (tester) async {
      _setSize(tester, const Size(402, 874));
      await tester.pumpWidget(
        _app(Scaffold(body: UsersScreen(patients: MockData.patients))),
      );
      expect(find.text('Kasun Jayasuriya'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'SN-2048');
      await tester.pump();
      expect(find.text('Nimali Perera'), findsOneWidget);
      expect(find.text('Kasun Jayasuriya'), findsNothing);

      await tester.enterText(find.byType(TextField), 'dini');
      await tester.pump();
      expect(find.text('Dinithi Fernando'), findsOneWidget);
    });

    testWidgets('uses suggestion wording only', (tester) async {
      _setSize(tester, const Size(402, 874));
      await tester.pumpWidget(_app(const TherapistShell()));
      await tester.pump(); // data from the fake repository
      for (final tab in ['Overview', 'Users', 'Exercises', 'Reviews']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(find.textContaining(_forbidden), findsNothing, reason: tab);
      }
      await tester.pumpWidget(
        _app(SessionReviewScreen(observation: observation, therapistName: 'T')),
      );
      expect(find.textContaining(_forbidden), findsNothing);
    });
  });

  group('session review (CLAUDE.md rule 2)', () {
    testWidgets('save is disabled until a decision is chosen', (tester) async {
      _setSize(tester, const Size(402, 874));
      await tester.pumpWidget(
        _app(SessionReviewScreen(observation: observation, therapistName: 'T')),
      );

      FilledButton save() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save review'),
      );
      expect(save().onPressed, isNull);

      await tester.ensureVisible(find.text('Mark as incorrect'));
      await tester.tap(find.text('Mark as incorrect'));
      await tester.pump();
      expect(save().onPressed, isNotNull);
    });

    testWidgets('saving adds a separate review and keeps the result', (
      tester,
    ) async {
      _setSize(tester, const Size(402, 874));
      final attempt = observation.attempt;
      final opsBefore = [
        for (final op in attempt.result.ops) '${op.kind}:${op.predicted}',
      ];

      await tester.pumpWidget(
        _app(
          SessionReviewScreen(
            observation: observation,
            therapistName: 'Dr. Amaya Silva',
          ),
        ),
      );
      await tester.ensureVisible(find.text('Confirm observation'));
      await tester.tap(find.text('Confirm observation'));
      await tester.pump();
      await tester.enterText(
        find.byType(TextFormField),
        'Practise /m/ in the middle of words.',
      );
      await tester.ensureVisible(find.text('Save review'));
      await tester.tap(find.text('Save review'));
      await tester.pump();

      final reviews = reviewStore.allFor(attempt.id);
      expect(reviews, hasLength(1));
      expect(reviews.single.decision, ReviewDecision.confirmed);
      expect(reviews.single.note, 'Practise /m/ in the middle of words.');

      // The automated result is untouched.
      final opsAfter = [
        for (final op in attempt.result.ops) '${op.kind}:${op.predicted}',
      ];
      expect(opsAfter, opsBefore);
    });

    testWidgets('a reviewed observation leaves the overview count', (
      tester,
    ) async {
      _setSize(tester, const Size(402, 874));
      await tester.pumpWidget(_app(const TherapistShell()));
      await tester.pump(); // data from the fake repository
      final before = MockData.patients
          .expand((p) => p.observations)
          .length
          .toString()
          .padLeft(2, '0');
      expect(find.text(before), findsOneWidget);

      reviewStore.add(
        Review(
          attemptId: observation.attempt.id,
          therapistName: 'T',
          decision: ReviewDecision.rejected,
          note: '',
          createdAt: DateTime.now(),
        ),
      );
      await tester.pump();

      final after = (int.parse(before) - 1).toString().padLeft(2, '0');
      expect(find.text(after), findsWidgets);
    });
  });

  group('exercises', () {
    testWidgets('new exercise shows the sounds while typing, then saves', (
      tester,
    ) async {
      _setSize(tester, const Size(402, 874));
      await tester.pumpWidget(_app(const TherapistShell()));
      await tester.pump();
      await tester.tap(find.text('Exercises').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('New exercise').first);
      await tester.pumpAndSettle();
      expect(find.text('Sounds appear here as you type.'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'hello');
      await tester.pump();
      expect(find.text('Please type in Sinhala letters only.'), findsWidgets);

      await tester.enterText(find.byType(TextFormField).first, 'ගෙදර');
      await tester.pump();
      for (final sound in ['ɡ', 'e', 'd̪', 'ə', 'r']) {
        expect(find.text(sound), findsWidgets, reason: sound);
      }

      await tester.ensureVisible(find.text('Save exercise'));
      await tester.tap(find.text('Save exercise'));
      await tester.pumpAndSettle();

      expect(find.text('EXERCISE LIBRARY'), findsOneWidget);
      expect(find.text('ගෙදර'), findsOneWidget);
      expect(repo.allExercises.first.expectedPhonemes, [
        'ɡ',
        'e',
        'd̪',
        'ə',
        'r',
        'ə',
      ]);
    });

    testWidgets('a long sentence is refused', (tester) async {
      _setSize(tester, const Size(402, 874));
      await tester.pumpWidget(
        _app(CreateExerciseScreen(therapistId: MockData.therapist.id)),
      );
      await tester.enterText(
        find.byType(TextFormField).first,
        'මම අද උදේ ගෙදර සිට පාසලට ගියා',
      );
      await tester.ensureVisible(find.text('Save exercise'));
      await tester.tap(find.text('Save exercise'));
      await tester.pump();
      expect(find.textContaining('up to 4 words'), findsOneWidget);
      expect(repo.allExercises, hasLength(MockData.exercises.length));
    });

    testWidgets('assign exercises to a user from their profile', (
      tester,
    ) async {
      _setSize(tester, const Size(402, 874));
      final kasun = MockData.patients[1];
      await tester.pumpWidget(
        _app(
          PatientProfileScreen(
            patient: kasun,
            therapistId: MockData.therapist.id,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Nothing assigned yet'), findsOneWidget);

      await tester.tap(find.text('Assign'));
      await tester.pumpAndSettle();
      // Inside the sheet (ගස is also in the analytics word list).
      await tester.tap(
        find.descendant(
          of: find.byType(CheckboxListTile),
          matching: find.text('ගස'),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing assigned yet'), findsNothing);
      expect(find.text('ගස'), findsNWidgets(2)); // chip + analytics
      expect(
        repo.allAssignments.where((a) => a.userId == kasun.profile.id),
        hasLength(1),
      );
    });

    testWidgets('a new therapist sees how to invite users', (tester) async {
      _setSize(tester, const Size(402, 874));
      practiceRepository = FakePracticeRepository(); // no users yet
      await tester.pumpWidget(_app(const TherapistShell()));
      await tester.pump();

      expect(find.textContaining('No users yet'), findsOneWidget);
      expect(find.text('Invite a user'), findsOneWidget);

      await tester.tap(find.text('Exercises').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('No exercises yet'), findsOneWidget);
    });
  });
}
