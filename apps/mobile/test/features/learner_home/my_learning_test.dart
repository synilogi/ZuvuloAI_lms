import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/learner_home/learner_home.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _courses() =>
    jsonDecode(jsonEncode(fixture('learning/courses-with-saved.json'))) as Map<String, dynamic>;

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  Future<GoRouter> pumpTab(WidgetTester tester, MyLearningTab tab) => pumpPublicRouter(
    tester,
    adapter: adapter,
    signedInAs: learner(),
    initialLocation: AppRoutes.myLearning(tab),
    routes: [
      GoRoute(
        path: AppRoutes.myLearningPattern,
        builder: (_, state) => Scaffold(
          body: SafeArea(
            child: MyLearningScreen(tab: MyLearningTab.parse(state.pathParameters['tab'])),
          ),
        ),
      ),
      GoRoute(path: AppRoutes.explore, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.learnCoursePattern, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.catalogCoursePattern, builder: (_, _) => const Placeholder()),
    ],
  );

  testWidgets('In progress holds the courses the server has not marked complete', (tester) async {
    adapter.handler = (_) async => FakeAdapter.jsonResponse(_courses());

    await pumpTab(tester, MyLearningTab.inProgress);
    await tester.pumpAndSettle();

    final data = LearnerCourses.fromJson(_courses());
    final open = coursesForTab(data, MyLearningTab.inProgress);
    expect(open, isNotEmpty);
    for (final course in open) {
      expect(find.text(course.course.title), findsOneWidget);
    }
    final done = coursesForTab(data, MyLearningTab.completed).single;
    expect(find.text(done.course.title), findsNothing);
  });

  testWidgets('Completed holds exactly the finished course', (tester) async {
    adapter.handler = (_) async => FakeAdapter.jsonResponse(_courses());

    await pumpTab(tester, MyLearningTab.completed);
    await tester.pumpAndSettle();

    expect(find.text('The 27 Nakshatras in Depth'), findsOneWidget);
    expect(find.byType(LearnerCourseCard), findsOneWidget);
    expect(find.text('Completed'), findsWidgets);
  });

  testWidgets('Saved holds the saved course, which opens its catalogue page', (tester) async {
    adapter.handler = (_) async => FakeAdapter.jsonResponse(_courses());

    final router = await pumpTab(tester, MyLearningTab.saved);
    await tester.pumpAndSettle();

    expect(find.byType(SavedCourseRow), findsOneWidget);
    await tester.tap(find.text('Jaimini Astrology: Chara Karakas'));
    await tester.pumpAndSettle();

    expect(locationOf(router), '/catalog/jaimini-chara-karakas');
  });

  testWidgets('switching tab changes the route, not just the view', (tester) async {
    adapter.handler = (_) async => FakeAdapter.jsonResponse(_courses());

    final router = await pumpTab(tester, MyLearningTab.inProgress);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();

    expect(locationOf(router), '/my-learning/saved');
  });

  testWidgets('opening a course goes to its learner view', (tester) async {
    adapter.handler = (_) async => FakeAdapter.jsonResponse(_courses());

    final router = await pumpTab(tester, MyLearningTab.inProgress);
    await tester.pumpAndSettle();

    final first = coursesForTab(
      LearnerCourses.fromJson(_courses()),
      MyLearningTab.inProgress,
    ).first;
    await tester.tap(find.text(first.course.title));
    await tester.pumpAndSettle();

    expect(locationOf(router), '/learn/${first.course.id}');
  });

  testWidgets('an expired enrolment stays visible, with the date access ended', (tester) async {
    final raw = _courses();
    final course = (raw['courses']! as List<dynamic>).first as Map<String, dynamic>;
    (course['enrollment']! as Map<String, dynamic>)
      ..['status'] = 'expired'
      ..['expiresAt'] = '2026-09-01T00:00:00.000Z';
    adapter.handler = (_) async => FakeAdapter.jsonResponse(raw);

    await pumpTab(tester, MyLearningTab.inProgress);
    await tester.pumpAndSettle();

    expect(find.text('Access ended on 1 Sep 2026'), findsOneWidget);
    expect(find.text('Expired'), findsWidgets);
  });

  testWidgets('each tab has its own empty state', (tester) async {
    adapter.handler = (_) async =>
        FakeAdapter.jsonResponse({'courses': <Object>[], 'saved': <Object>[]});

    await pumpTab(tester, MyLearningTab.completed);
    await tester.pumpAndSettle();
    expect(find.text('No courses completed yet'), findsOneWidget);

    await pumpTab(tester, MyLearningTab.saved);
    await tester.pumpAndSettle();
    expect(find.text('Nothing saved'), findsOneWidget);

    await pumpTab(tester, MyLearningTab.inProgress);
    await tester.pumpAndSettle();
    expect(find.text('Nothing in progress'), findsOneWidget);
  });

  testWidgets('a failed read offers a retry', (tester) async {
    var attempt = 0;
    adapter.handler = (_) async {
      attempt++;
      return attempt == 1
          ? FakeAdapter.jsonResponse({'message': 'Server error.'}, status: 500)
          : FakeAdapter.jsonResponse(_courses());
    };

    await pumpTab(tester, MyLearningTab.inProgress);
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(LearnerCourseCard), findsWidgets);
  });
}
