import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:sonus_app/main.dart';
import 'package:sonus_app/models/user_role.dart';
import 'package:sonus_app/services/auth_repository.dart';

import 'fakes/fake_auth_repository.dart';

/// The whole account flow through AuthGate, with fake accounts.
void main() {
  late FakeAuthRepository fake;

  setUp(() {
    fake = FakeAuthRepository();
    authRepository = fake;
  });

  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SonusApp());
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets('signed out shows Welcome', (tester) async {
    await start(tester);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('sign up as adult user opens the user home', (tester) async {
    await start(tester);
    await tapText(tester, 'Get started');

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Nimali Perera');
    await tester.enterText(fields.at(1), 'nimali@example.com');
    await tester.enterText(fields.at(2), 'password1');
    await tapText(tester, 'Create account');

    expect(find.textContaining(', NIMALI'), findsOneWidget); // greeting
    expect(find.text('Start practice'), findsOneWidget);
  });

  testWidgets('wrong password shows a message and stays on log in', (
    tester,
  ) async {
    await fake.signUp(
      role: UserRole.user,
      name: 'Nimali Perera',
      email: 'nimali@example.com',
      password: 'password1',
    );
    await fake.signOut();
    await start(tester);

    await tapText(tester, 'I already have an account');
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'nimali@example.com');
    await tester.enterText(fields.at(1), 'wrong-pass');
    await tapText(tester, 'Sign in');

    expect(find.text('Email or password is not right.'), findsOneWidget);
    expect(find.text('Continue your practice.'), findsOneWidget);
  });

  testWidgets('log in as therapist opens the therapist home by stored role', (
    tester,
  ) async {
    await fake.signUp(
      role: UserRole.therapist,
      name: 'Dr. Amaya Silva',
      email: 'amaya@example.com',
      password: 'password1',
    );
    await fake.signOut();
    await start(tester);

    await tapText(tester, 'I already have an account');
    // The toggle stays on "Adult user": the stored role decides the home.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'amaya@example.com');
    await tester.enterText(fields.at(1), 'password1');
    await tapText(tester, 'Sign in');

    expect(find.text('Clinical overview'), findsOneWidget);
  });

  testWidgets('user links to a therapist with the invite code', (tester) async {
    await fake.signUp(
      role: UserRole.therapist,
      name: 'Dr. Amaya Silva',
      email: 'amaya@example.com',
      password: 'password1',
    );
    await fake.signUp(
      role: UserRole.user,
      name: 'Nimali Perera',
      email: 'nimali@example.com',
      password: 'password1',
    );
    await start(tester);

    await tapText(tester, 'Profile');
    await tapText(tester, 'Link your therapist');

    await tester.enterText(find.byType(TextField).last, 'nope');
    await tapText(tester, 'Link');
    expect(find.text('That invite code wasn\'t found.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'inv0');
    await tapText(tester, 'Link');
    expect(find.text('Your therapist'), findsOneWidget);
    expect(find.text('Dr. Amaya Silva'), findsOneWidget);
  });

  testWidgets('sign out returns to Welcome', (tester) async {
    await fake.signUp(
      role: UserRole.user,
      name: 'Nimali Perera',
      email: 'nimali@example.com',
      password: 'password1',
    );
    await start(tester);

    await tapText(tester, 'Profile');
    await tapText(tester, 'Sign out');
    expect(find.text('Get started'), findsOneWidget);
  });
}
