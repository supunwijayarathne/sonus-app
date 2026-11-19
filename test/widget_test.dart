import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:sonus_app/main.dart';
import 'package:sonus_app/services/auth_repository.dart';

import 'fakes/fake_auth_repository.dart';

void main() {
  setUp(() => authRepository = FakeAuthRepository()); // signed out

  // Phone, small phone, landscape, tablet: no layout overflow on any of them.
  const sizes = {
    'phone': Size(402, 874),
    'small phone': Size(320, 568),
    'landscape': Size(874, 402),
    'tablet': Size(820, 1180),
  };

  for (final entry in sizes.entries) {
    testWidgets('welcome screen fits on ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const SonusApp());
      await tester.pump(); // first auth state

      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('I already have an account'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
