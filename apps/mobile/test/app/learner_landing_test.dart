import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/app.dart';
import 'package:syniastrolms_mobile/app/routing/app_router.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/learner_home/learner_home.dart';
import 'package:syniastrolms_mobile/shared/widgets/navigation/app_nav_bar.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_adapter.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/public_harness.dart';

const _learner = UserProfile(
  id: 'u1',
  name: 'Ananya Rao',
  email: 'ananya@syniastrolms.test',
  role: UserRole.student,
  descriptor: 'Learner',
);

void main() {
  late FakeAuthRepository repository;
  late FakeAdapter adapter;

  setUp(() {
    repository = FakeAuthRepository()..profile = _learner;
    adapter = FakeAdapter()
      ..handler = (options) async => switch (options.path) {
        '/learning/home' => FakeAdapter.jsonResponse(fixture('learning/home.json')),
        '/learning/courses' => FakeAdapter.jsonResponse(
          fixture('learning/courses-with-saved.json'),
        ),
        _ => throw StateError('unexpected ${options.path}'),
      };
  });

  String locationIn(WidgetTester tester) {
    final container = ProviderScope.containerOf(tester.element(find.byType(SyniastroApp)));
    return container.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();
  }

  Future<void> signIn(WidgetTester tester) async {
    useSurface(tester);
    await tester.pumpWidget(await testApp(repository: repository, adapter: adapter));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'ananya@syniastrolms.test');
    await tester.enterText(find.byType(TextField).at(1), 'syniastrolms123');
    await tester.tap(find.widgetWithText(AppButton, 'Sign in'));
    await tester.pumpAndSettle();
  }

  testWidgets('a learner signing in lands on their own home inside the shell', (tester) async {
    await signIn(tester);

    expect(locationIn(tester), '/home');
    expect(find.byType(LearnerHomeScreen), findsOneWidget);
    expect(find.textContaining('Ananya'), findsWidgets);
    expect(find.text('Continue learning'), findsOneWidget);
    // The shell draws the frame: one scaffold, one app bar, the navigation bar.
    expect(find.byType(AppNavBar), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('My Courses, from Profile, opens its first tab and switches between them', (
    tester,
  ) async {
    await signIn(tester);

    await tester.tap(
      find.descendant(of: find.byType(AppNavBar), matching: find.text('Profile')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Courses'));
    await tester.pumpAndSettle();
    expect(locationIn(tester), '/my-learning/in-progress');

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(locationIn(tester), '/my-learning/completed');
    expect(find.text('The 27 Nakshatras in Depth'), findsOneWidget);
  });
}
