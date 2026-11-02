import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/assignments/assignments.dart';
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
    initialLocation: AppRoutes.assignments,
    routes: [
      GoRoute(
        path: AppRoutes.assignments,
        builder: (_, _) => const Scaffold(body: SafeArea(child: AssignmentsScreen())),
      ),
      GoRoute(path: AppRoutes.assignmentPattern, builder: (_, _) => const Placeholder()),
    ],
  );

  testWidgets('every piece of coursework shows its course, deadline and where it stands', (
    tester,
  ) async {
    adapter.enqueueJson(fixture('learning/assignments.json'));

    await pumpList(tester);
    await tester.pumpAndSettle();

    expect(find.byType(AssignmentCard), findsWidgets);
    expect(find.text('Timing exercise'), findsOneWidget);
    expect(find.text('Reading the Dasha System'), findsOneWidget);
    expect(find.textContaining('Due '), findsWidgets);
    expect(find.text('Overdue'), findsWidgets);
  });

  testWidgets('tapping one opens it', (tester) async {
    adapter.enqueueJson(fixture('learning/assignments.json'));

    final router = await pumpList(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Timing exercise'));
    await tester.pumpAndSettle();

    expect(locationOf(router), startsWith('/assignments/'));
  });

  testWidgets('a graded hand-in shows its score, and a returned one does not', (tester) async {
    adapter.enqueueJson([fixture('learning/assignment-graded.json')]);

    await pumpList(tester);
    await tester.pumpAndSettle();

    expect(find.text('82 of 100'), findsOneWidget);
    expect(find.text('Graded'), findsOneWidget);
  });

  testWidgets('a hand-in the reviewer sent back asks for another attempt', (tester) async {
    adapter.enqueueJson([fixture('learning/assignment-returned.json')]);

    await pumpList(tester);
    await tester.pumpAndSettle();

    // The server calls it a draft; the review is what says it came back.
    expect(find.text('Resubmission requested'), findsOneWidget);
    expect(
      find.textContaining(' of 100'),
      findsNothing,
      reason: 'a returned review is not a grade',
    );
  });

  testWidgets('a learner with no coursework yet is told so', (tester) async {
    adapter.enqueueJson(const <Object>[]);

    await pumpList(tester);
    await tester.pumpAndSettle();

    expect(find.text('No assignments yet'), findsOneWidget);
  });

  testWidgets('a failed read offers a retry', (tester) async {
    adapter
      ..enqueueJson({'message': 'Server error.'}, status: 500)
      ..enqueueJson(fixture('learning/assignments.json'));

    await pumpList(tester);
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(AssignmentCard), findsWidgets);
  });
}
