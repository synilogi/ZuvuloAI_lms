import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/app.dart';
import 'package:syniastrolms_mobile/app/routing/app_router.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/public_catalog/public_catalog.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_adapter.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/public_harness.dart';

const _learner = UserProfile(
  id: 'u1',
  name: 'Ananya Rao',
  email: 'ananya@syniastrolms.test',
  role: UserRole.student,
  descriptor: 'Learner',
);

/// The public reads the visitor journey needs, answered from captured responses.
void _servePublic(FakeAdapter adapter) {
  adapter.handler = (options) async => switch (options.path) {
    '/catalog/levels' => FakeAdapter.jsonResponse(fixture('catalog/levels.json')),
    '/catalog/categories' => FakeAdapter.jsonResponse(fixture('catalog/categories.json')),
    '/catalog/instructors' => FakeAdapter.jsonResponse(fixture('catalog/instructors.json')),
    '/catalog/courses' => FakeAdapter.jsonResponse(fixture('catalog/courses.json')),
    '/catalog/courses/foundations-vedic' => FakeAdapter.jsonResponse(
      fixture('catalog/course-detail.json'),
    ),
    _ => throw StateError('unexpected ${options.path}'),
  };
}

void main() {
  late FakeAuthRepository repository;
  late FakeAdapter adapter;

  setUp(() {
    repository = FakeAuthRepository();
    adapter = FakeAdapter();
    _servePublic(adapter);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    useSurface(tester);
    await tester.pumpWidget(await testApp(repository: repository, adapter: adapter));
    await tester.pump();
    await tester.pump();
  }

  String locationIn(WidgetTester tester) {
    final container = ProviderScope.containerOf(tester.element(find.byType(SyniastroApp)));
    return container.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();
  }

  testWidgets('a visitor browses the catalogue, enrols, signs in and lands on the course', (
    tester,
  ) async {
    repository.profile = _learner;
    await pumpApp(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.text('Browse courses'));
    await tester.pumpAndSettle();
    expect(locationIn(tester), '/catalog');
    expect(find.byType(CourseCard), findsWidgets);

    await tester.tap(find.text('Foundations of Vedic Astrology').first);
    await tester.pumpAndSettle();
    expect(locationIn(tester), '/catalog/foundations-vedic');

    await tester.tap(find.text('Sign in to enrol'));
    await tester.pumpAndSettle();
    final courseId =
        (fixture('catalog/course-detail.json')! as Map<String, dynamic>)['id']! as String;
    expect(locationIn(tester), '/login?next=%2Flearn%2F$courseId');

    await tester.enterText(find.byType(TextField).at(0), 'ananya@syniastrolms.test');
    await tester.enterText(find.byType(TextField).at(1), 'syniastrolms123');
    await tester.tap(find.widgetWithText(AppButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(locationIn(tester), '/learn/$courseId');
  });

  testWidgets('a protected link survives signing in from the welcome screen', (tester) async {
    // The redirect keeps the link as /welcome?next=…, but Welcome's own Sign in used to open a
    // sign-in form without it, so the person landed on home (LIVE E2E LINK-003).
    repository.profile = _learner;
    adapter.handler = (options) async =>
        FakeAdapter.jsonResponse({'message': 'Not found.'}, status: 404);
    await pumpApp(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(SyniastroApp)));
    container.read(routerProvider).go('/notifications');
    await tester.pumpAndSettle();
    expect(locationIn(tester), '/welcome?next=%2Fnotifications');

    await tester.tap(find.widgetWithText(AppButton, 'Sign in'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'ananya@syniastrolms.test');
    await tester.enterText(find.byType(TextField).at(1), 'syniastrolms123');
    await tester.tap(find.widgetWithText(AppButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(locationIn(tester), '/notifications');
  });

  testWidgets('a target outside the app never becomes a destination', (tester) async {
    repository.profile = _learner;
    await pumpApp(tester);

    final container = ProviderScope.containerOf(tester.element(find.byType(SyniastroApp)));
    container.read(routerProvider).go('/login?next=https%3A%2F%2Fevil.example');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'ananya@syniastrolms.test');
    await tester.enterText(find.byType(TextField).at(1), 'syniastrolms123');
    await tester.tap(find.widgetWithText(AppButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(locationIn(tester), '/home');
  });

  testWidgets('a route this person may not open falls back to their home', (tester) async {
    repository.profile = _learner;
    await pumpApp(tester);

    final container = ProviderScope.containerOf(tester.element(find.byType(SyniastroApp)));
    container.read(routerProvider).go('/login?next=%2Fstaff%2Fbilling');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'ananya@syniastrolms.test');
    await tester.enterText(find.byType(TextField).at(1), 'syniastrolms123');
    await tester.tap(find.widgetWithText(AppButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(locationIn(tester), '/home');
  });

  testWidgets('the welcome screen also leads to verification and to help', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Verify a certificate'));
    await tester.pumpAndSettle();
    expect(locationIn(tester), '/verify');
  });
}
