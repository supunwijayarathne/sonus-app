import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:sonus_app/features/auth/login_screen.dart';
import 'package:sonus_app/models/user_role.dart';
import 'package:sonus_app/theme/app_theme.dart';

Widget _app(Widget child) => MaterialApp(theme: AppTheme.dark(), home: child);

void main() {
  const sizes = {
    'phone': Size(402, 874),
    'small phone': Size(320, 568),
    'landscape': Size(874, 402),
    'tablet': Size(820, 1180),
  };

  for (final entry in sizes.entries) {
    testWidgets('login screen fits on ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(const LoginScreen()));

      expect(find.text('Continue your practice.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('empty form shows errors and does not sign in', (tester) async {
    var called = false;
    await tester.pumpWidget(
      _app(LoginScreen(onSignIn: (_, _, _) => called = true)),
    );

    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Please enter your email.'), findsOneWidget);
    expect(find.text('Please enter your password.'), findsOneWidget);
    expect(called, isFalse);
  });

  testWidgets('valid form signs in with the chosen role', (tester) async {
    UserRole? role;
    String? email;
    await tester.pumpWidget(
      _app(
        LoginScreen(
          onSignIn: (r, e, _) {
            role = r;
            email = e;
          },
        ),
      ),
    );

    await tester.tap(find.text('Speech therapist'));
    await tester.enterText(
      find.byType(TextFormField).at(0),
      ' nimali@example.com ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(role, UserRole.therapist);
    expect(email, 'nimali@example.com'); // trimmed
  });

  testWidgets('UI never says "diagnosis" (CLAUDE.md rule 1)', (tester) async {
    await tester.pumpWidget(_app(const LoginScreen()));
    expect(
      find.textContaining(RegExp('diagnos', caseSensitive: false)),
      findsNothing,
    );
  });
}
