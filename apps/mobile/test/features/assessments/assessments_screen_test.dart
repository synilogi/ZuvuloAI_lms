import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/assessments/assessments.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  Future<GoRouter> pumpList(WidgetTester tester) => pumpPublicRouter(
    tester,
    adapter: adapter,
    signedInAs: learner(),
    initialLocation: AppRoutes.assessments,
    routes: [
      GoRoute(
        path: AppRoutes.assessments,
        builder: (_, _) => const Scaffold(body: SafeArea(child: AssessmentsScreen())),
      ),
      GoRoute(path: AppRoutes.learnLessonPattern, builder: (_, _) => const Placeholder()),
    ],
  );

  testWidgets('shows each quiz with what it asks and where the learner stands', (tester) async {
    adapter.enqueueJson(fixture('learning/assessments-open.json'));

    await pumpList(tester);
    await tester.pumpAndSettle();

    expect(find.byType(AssessmentCard), findsNWidgets(2));
    expect(find.text('Magha to Moola: check your understanding'), findsOneWidget);
    expect(find.textContaining('4 questions · pass 70%'), findsOneWidget);
    expect(find.text('3 attempts left'), findsWidgets);
    expect(find.textContaining('Finish the other lessons'), findsOneWidget);
  });

  testWidgets(
    'the summary counts the server\'s own states, and only an open quiz offers a way in',
    (tester) async {
      adapter.enqueueJson(fixture('learning/assessments-open.json'));

      await pumpList(tester);
      await tester.pumpAndSettle();

      // One available, one locked, none passed — the figures as the summary says them.
      Finder labelled(String label) =>
          find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label);
      expect(labelled('Ready now: 1'), findsOneWidget);
      expect(labelled('Passed: 0'), findsOneWidget);
      expect(labelled('Locked: 1'), findsOneWidget);
      expect(find.text('Start the quiz'), findsOneWidget, reason: 'the locked quiz has no way in');
    },
  );

  testWidgets('an open quiz opens its lesson; a locked one does not', (tester) async {
    adapter.enqueueJson(fixture('learning/assessments-open.json'));

    final router = await pumpList(tester);
    await tester.pumpAndSettle();

    final cards = tester.widgetList<AssessmentCard>(find.byType(AssessmentCard)).toList();
    final locked = cards.firstWhere((c) => c.row.state == AssessmentState.locked);
    expect(
      tester
          .widget<AppCard>(
            find.descendant(of: find.byWidget(locked), matching: find.byType(AppCard)),
          )
          .onTap,
      isNull,
      reason: 'a locked quiz is not a door',
    );

    await tester.tap(find.text('Magha to Moola: check your understanding'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.toString(), startsWith('/learn/'));
  });

  testWidgets('a learner with no quizzes yet is told so', (tester) async {
    adapter.enqueueJson(const <Object>[]);

    await pumpList(tester);
    await tester.pumpAndSettle();

    expect(find.text('No quizzes yet'), findsOneWidget);
  });

  testWidgets('a failed read offers a retry', (tester) async {
    adapter
      ..enqueueJson({'message': 'Server error.'}, status: 500)
      ..enqueueJson(fixture('learning/assessments-open.json'));

    await pumpList(tester);
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(AssessmentCard), findsNWidgets(2));
  });

  group('timed and windowed quizzes', () {
    Map<String, dynamic> row(Map<String, Object?> changes) {
      final base = Map<String, dynamic>.from(
        (fixture('learning/assessment-row-quiz.json')! as List<dynamic>).single
            as Map<String, dynamic>,
      );
      for (final entry in changes.entries) {
        if (entry.value == null) {
          base.remove(entry.key);
        } else {
          base[entry.key] = entry.value;
        }
      }
      return base;
    }

    testWidgets('an attempt under way says when it must be handed in, and resumes', (tester) async {
      adapter.enqueueJson([
        row({'state': 'in-progress', 'deadlineAt': '2026-10-26T08:01:37.229Z', 'score': null}),
      ]);

      final router = await pumpList(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Hand in by'), findsOneWidget);
      expect(find.text('Resume the quiz'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
      await tester.tap(find.text('Integers: check your understanding'));
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.toString(), startsWith('/learn/'));
    });

    testWidgets('a quiz that has not opened says when it opens, and is not a door yet', (
      tester,
    ) async {
      adapter.enqueueJson([
        row({
          'state': 'available',
          'attemptsUsed': 0,
          'score': null,
          'window': 'upcoming',
          'opensAt': '2026-11-01T04:30:00.000Z',
        }),
      ]);

      await pumpList(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Opens '), findsOneWidget);
      expect(find.text('Start the quiz'), findsNothing);
      expect(
        tester.widget<AppCard>(find.byType(AppCard).last).onTap,
        isNull,
        reason: 'nothing to start until it opens',
      );
    });

    testWidgets('a score held until the quiz closes is not shown, and says when it will be', (
      tester,
    ) async {
      adapter.enqueueJson([
        row({
          'score': null,
          'closesAt': '2026-11-01T04:30:00.000Z',
          'resultsAt': '2026-11-01T04:30:00.000Z',
        }),
      ]);

      await pumpList(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Score shown 1 Nov 2026, 10:00 AM'), findsOneWidget);
      expect(find.textContaining('Best so far'), findsNothing);
      expect(find.textContaining('Closes 1 Nov 2026, 10:00 AM'), findsOneWidget, reason: 'IST');
    });

    testWidgets('a quiz with negative marking says so on its card', (tester) async {
      adapter.enqueueJson([
        row({'negativeMarking': true}),
      ]);

      await pumpList(tester);
      await tester.pumpAndSettle();

      expect(find.text('Negative marking: wrong answers lose marks'), findsOneWidget);
    });
  });
}
