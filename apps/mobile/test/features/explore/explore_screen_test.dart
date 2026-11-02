import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/explore/explore.dart';
import 'package:syniastrolms_mobile/features/learner_home/learner_home.dart';
import 'package:syniastrolms_mobile/features/public_catalog/public_catalog.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

void _serve(FakeAdapter adapter, {Object? courses, Object? workspace}) {
  adapter.handler = (options) async => switch (options.path) {
    '/catalog/levels' => FakeAdapter.jsonResponse(fixture('catalog/levels.json')),
    '/catalog/categories' => FakeAdapter.jsonResponse(fixture('catalog/categories.json')),
    '/catalog/instructors' => FakeAdapter.jsonResponse(fixture('catalog/instructors.json')),
    '/catalog/courses' => FakeAdapter.jsonResponse(courses ?? fixture('catalog/courses.json')),
    '/learning/courses' => FakeAdapter.jsonResponse(
      workspace ?? fixture('learning/courses-with-saved.json'),
    ),
    _ => throw StateError('unexpected ${options.path}'),
  };
}

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  Future<GoRouter> pumpExplore(WidgetTester tester) => pumpPublicRouter(
    tester,
    adapter: adapter,
    signedInAs: learner(),
    initialLocation: AppRoutes.explore,
    routes: [
      GoRoute(
        path: AppRoutes.explore,
        builder: (_, _) => const Scaffold(body: SafeArea(child: ExploreScreen())),
      ),
      GoRoute(path: AppRoutes.learnCoursePattern, builder: (_, _) => const Placeholder()),
    ],
  );

  testWidgets('shows the academy\'s courses and marks the ones already held', (tester) async {
    _serve(adapter);

    await pumpExplore(tester);
    await tester.pumpAndSettle();

    expect(find.byType(CourseBatchCard), findsWidgets);
    expect(find.text('Foundations of Vedic Astrology'), findsOneWidget);
    // Only the rows on screen are built, so at least the first held course is marked.
    expect(find.text('Enrolled'), findsWidgets);
  });

  testWidgets('opening a course goes to the learner\'s own view, not the public page', (
    tester,
  ) async {
    _serve(adapter);
    final router = await pumpExplore(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Foundations of Vedic Astrology'));
    await tester.pumpAndSettle();

    expect(locationOf(router), startsWith('/learn/'));
  });

  testWidgets('a level narrows the list on the server', (tester) async {
    _serve(adapter);

    await pumpExplore(tester);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(FilterChipBar<String?>).first,
        matching: find.text('Beginner'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      adapter.requests.lastWhere((r) => r.path == '/catalog/courses').queryParameters['levelId'],
      isNotNull,
    );
  });

  testWidgets('a search with no matches offers to clear it', (tester) async {
    _serve(adapter);

    await pumpExplore(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();

    expect(find.text('No matches'), findsOneWidget);
  });

  testWidgets('an academy with nothing published says so', (tester) async {
    _serve(adapter, courses: const <Object>[]);

    await pumpExplore(tester);
    await tester.pumpAndSettle();

    expect(find.text('No courses published yet'), findsOneWidget);
  });

  testWidgets('a refused workspace read still leaves Explore usable', (tester) async {
    adapter.handler = (options) async => switch (options.path) {
      '/catalog/levels' => FakeAdapter.jsonResponse(fixture('catalog/levels.json')),
      '/catalog/categories' => FakeAdapter.jsonResponse(fixture('catalog/categories.json')),
      '/catalog/instructors' => FakeAdapter.jsonResponse(fixture('catalog/instructors.json')),
      '/catalog/courses' => FakeAdapter.jsonResponse(fixture('catalog/courses.json')),
      _ => FakeAdapter.jsonResponse({'message': 'Server error.'}, status: 500),
    };

    await pumpExplore(tester);
    await tester.pumpAndSettle();

    expect(find.byType(CourseBatchCard), findsWidgets);
    expect(find.text('Enrolled'), findsNothing, reason: 'nothing is marked on a guess');
  });

  testWidgets('the marked ids are the workspace\'s, never a guess', (tester) async {
    _serve(adapter);
    await pumpExplore(tester);
    await tester.pumpAndSettle();
    final element = tester.element(find.byType(ExploreScreen));
    final container = ProviderScope.containerOf(element);
    final workspace = container.read(learnerCoursesProvider).value;
    final expected = LearnerCourses.fromJson(
      fixture('learning/courses-with-saved.json')! as Map<String, dynamic>,
    );

    expect(enrolledCourseIds(workspace), expected.courses.map((c) => c.course.id).toSet());
    expect(savedCourseIds(workspace), expected.saved.map((s) => s.course.id).toSet());
    expect(enrolledCourseIds(null), isEmpty, reason: 'nothing is marked on a guess');
  });
}
