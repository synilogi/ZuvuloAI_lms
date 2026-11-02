import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/assignments/assignments.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

/// A deep copy of a captured response, so a test may vary one field without touching the file.
Map<String, dynamic> _detail(String name) =>
    jsonDecode(jsonEncode(fixture('learning/$name.json'))) as Map<String, dynamic>;

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  /// Lets the autosave run and answers it, so no draft is left outstanding when the widget tree
  /// goes away — which is what the screen does on the way out.
  Future<void> letTheDraftSave(WidgetTester tester) async {
    adapter.enqueueJson({'savedAt': '2026-09-29T06:10:00.000Z'});
    await tester.pump(AssignmentWorkController.autosave);
    await tester.pumpAndSettle();
  }

  Future<GoRouter> pumpDetail(WidgetTester tester, {String id = 'a1'}) => pumpPublicRouter(
    tester,
    adapter: adapter,
    signedInAs: learner(),
    initialLocation: AppRoutes.assignment(id),
    size: const Size(400, 1400),
    routes: [
      GoRoute(
        path: AppRoutes.assignmentPattern,
        builder: (_, state) => Scaffold(
          body: SafeArea(
            child: AssignmentDetailScreen(assignmentId: state.pathParameters['assignmentId'] ?? ''),
          ),
        ),
      ),
      GoRoute(path: AppRoutes.assignments, builder: (_, _) => const Placeholder()),
    ],
  );

  testWidgets('a written assignment shows the brief, the deadline and a word count', (
    tester,
  ) async {
    adapter.enqueueJson(_detail('assignment-not-started'));

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('Timing exercise'), findsOneWidget);
    expect(find.text('The brief'), findsOneWidget);
    expect(find.textContaining('calculate the current mahadasha'), findsOneWidget);
    expect(find.text('Out of 100 points'), findsWidgets);
    // Past its deadline, and the academy takes a tenth off late work.
    expect(find.textContaining('10% off a late hand-in'), findsOneWidget);
    expect(find.text('0 words'), findsOneWidget);
    expect(find.byType(AssignmentTextArea), findsOneWidget);
    expect(find.byType(AssignmentChartForm), findsNothing);
  });

  testWidgets('an empty hand-in cannot be sent, and one with an answer can', (tester) async {
    adapter.enqueueJson(_detail('assignment-not-started'));

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    AppButton submitButton() => tester.widget<AppButton>(find.widgetWithText(AppButton, 'Submit'));
    expect(submitButton().onPressed, isNull, reason: 'the server refuses an empty hand-in');

    await tester.enterText(find.byType(TextFormField), 'Jupiter mahadasha, Saturn antardasha.');
    await tester.pump();

    expect(find.text('4 words'), findsOneWidget);
    expect(submitButton().onPressed, isNotNull);
    await letTheDraftSave(tester);
    expect(find.textContaining('Draft saved'), findsOneWidget);
  });

  testWidgets('a word limit the academy set is counted against, and blocks a longer answer', (
    tester,
  ) async {
    final row = _detail('assignment-not-started');
    (row['assignment']! as Map<String, dynamic>)['wordLimit'] = 3;
    adapter.enqueueJson(row);

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'one two three four');
    await tester.pump();

    expect(find.text('4 of 3 words'), findsOneWidget);
    expect(find.textContaining('Keep your answer to 3 words'), findsOneWidget);
    expect(
      tester.widget<AppButton>(find.widgetWithText(AppButton, 'Submit')).onPressed,
      isNull,
      reason: 'the route enforces the limit too',
    );
    await letTheDraftSave(tester);
  });

  testWidgets('a chart assignment asks for the birth details and an interpretation', (
    tester,
  ) async {
    final row = _detail('assignment-returned')..remove('submission');
    row['state'] = 'not-started';
    adapter.enqueueJson(row);

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.byType(AssignmentChartForm), findsOneWidget);
    for (final label in ['Whose chart', 'Date of birth', 'Lagna', 'Nakshatra']) {
      expect(find.textContaining(label), findsWidgets, reason: label);
    }
    expect(find.textContaining('Your interpretation'), findsWidgets);
    expect(
      tester.widget<AppButton>(find.widgetWithText(AppButton, 'Submit')).onPressed,
      isNull,
      reason: 'the chart is not filled in yet',
    );
  });

  testWidgets('a file assignment offers the uploader and names the limit', (tester) async {
    // The seed has no file-format assignment; the rest of this response is as the API sent it.
    final row = _detail('assignment-not-started');
    (row['assignment']! as Map<String, dynamic>)['format'] = 'file';
    adapter.enqueueJson(row);

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.byType(AssignmentFilesArea), findsOneWidget);
    expect(find.text('No files yet.'), findsOneWidget);
    expect(
      find.text('Up to 3 files.'),
      findsOneWidget,
      reason: 'the limit is guidance, not a telling-off, before anything is attached',
    );
    expect(find.text('Choose a file'), findsOneWidget);
    expect(find.byType(AssignmentTextArea), findsNothing);
  });

  testWidgets('a graded hand-in shows the score and the feedback, and no work area', (
    tester,
  ) async {
    adapter.enqueueJson(_detail('assignment-graded'));

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('What you handed in'), findsOneWidget);
    expect(find.text('Your review'), findsOneWidget);
    expect(find.text('82 of 100'), findsOneWidget);
    expect(find.text('Pass mark 60'), findsWidgets);
    expect(find.textContaining('Clear reading of the ascendant'), findsOneWidget);
    expect(find.byType(StickyActionBar), findsNothing);
    expect(find.byType(AssignmentTextArea), findsNothing);
  });

  testWidgets('a hand-in still with the instructor says so', (tester) async {
    adapter.enqueueJson(_detail('assignment-submitted'));

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('With your instructor.'), findsOneWidget);
    expect(find.byType(StickyActionBar), findsNothing);
    expect(
      find.textContaining(RegExp(r'\d+ of 100')),
      findsNothing,
      reason: 'nothing has been marked yet',
    );
  });

  testWidgets('a returned hand-in can be written again and sent again', (tester) async {
    adapter.enqueueJson(_detail('assignment-returned'));

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('Returned for changes'), findsOneWidget);
    expect(find.textContaining('add the Moon’s nakshatra pada'), findsOneWidget);
    // The work area starts from what was sent back.
    expect(find.textContaining('Sun in Leo in the 10th house'), findsWidgets);
    expect(find.widgetWithText(AppButton, 'Submit again'), findsOneWidget);
  });

  testWidgets('handing in asks first, names the late penalty, and sends it', (tester) async {
    adapter.enqueueJson(_detail('assignment-draft'));

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Hand this in?'), findsOneWidget);
    // This one is past its deadline, so the dialog says what that costs.
    expect(find.textContaining('10% is taken off work handed in late.'), findsOneWidget);

    adapter
      ..enqueueJson(_detail('assignment-submitted'))
      ..enqueueJson(_detail('assignment-submitted'));
    await tester.tap(find.descendant(of: find.byType(AppDialog), matching: find.text('Submit')));
    await tester.pumpAndSettle();

    expect(
      adapter.requests.map((r) => r.path),
      contains(endsWith('/submit')),
      reason: 'the hand-in went to the academy',
    );
    expect(find.text('With your instructor.'), findsOneWidget);
  });

  testWidgets('the academy\'s refusal is shown as it worded it', (tester) async {
    adapter.enqueueJson(_detail('assignment-draft'));

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'Submit'));
    await tester.pumpAndSettle();
    adapter.enqueueJson(fixture('errors/assignment-empty.json'), status: 409);
    await tester.tap(find.descendant(of: find.byType(AppDialog), matching: find.text('Submit')));
    await tester.pumpAndSettle();

    expect(find.text('Add your work before submitting.'), findsOneWidget);
  });

  testWidgets('an assignment that is not there offers the way back', (tester) async {
    adapter.enqueueJson({'message': 'Assignment not found.'}, status: 404);

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundView), findsOneWidget);
  });
}
