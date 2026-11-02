import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/assignments/assignments.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_review/staff_review.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(jsonEncode(fixture('staff/$name.json'))) as Map<String, dynamic>;

UserProfile _admin() => UserProfile(
  id: 'u_admin',
  name: 'Kavita Menon',
  email: 'admin@example.test',
  role: UserRole.admin,
  descriptor: 'Admin',
  permissions: PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

/// An admin who may read the queue but not mark anything.
UserProfile _reader() => const UserProfile(
  id: 'u_reader',
  name: 'Reader',
  email: 'reader@example.test',
  role: UserRole.admin,
  descriptor: 'Admin',
  permissions: [PermissionKey.assessmentView],
);

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  void answering({
    Map<String, dynamic>? submissions,
    String detail = 'submission',
    Map<String, dynamic>? detailJson,
    Object? review,
    int reviewStatus = 200,
    Object? remind,
    int remindStatus = 200,
  }) {
    adapter.handler = (options) async {
      if (options.method == 'POST') {
        if (options.path.endsWith('/remind')) {
          return FakeAdapter.jsonResponse(remind ?? const {'sent': 3}, status: remindStatus);
        }
        return FakeAdapter.jsonResponse(
          review ?? (detailJson ?? _json(detail))['submission'],
          status: reviewStatus,
        );
      }
      if (options.path == '/assignments/review') {
        return FakeAdapter.jsonResponse(_json('review-queue'));
      }
      if (options.path == '/assignments') {
        return FakeAdapter.jsonResponse(_json('assignments'));
      }
      if (options.path.startsWith('/assignments/submissions/')) {
        return FakeAdapter.jsonResponse(detailJson ?? _json(detail));
      }
      return FakeAdapter.jsonResponse(submissions ?? _json('submissions'));
    };
  }

  Future<GoRouter> pump(
    WidgetTester tester, {
    required String at,
    UserProfile? signedInAs,
    Size size = const Size(400, 4000),
    double textScale = 1,
  }) => pumpPublicRouter(
    tester,
    adapter: adapter,
    signedInAs: signedInAs ?? _admin(),
    initialLocation: at,
    size: size,
    textScale: textScale,
    routes: [
      GoRoute(
        path: AppRoutes.staffReview,
        builder: (_, _) => const Scaffold(body: SafeArea(child: ReviewQueueScreen())),
      ),
      GoRoute(
        path: AppRoutes.staffSubmissionsPattern,
        builder: (_, state) => Scaffold(
          body: SafeArea(
            child: AssignmentSubmissionsScreen(
              assignmentId: state.pathParameters['assignmentId'] ?? '',
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.staffSubmissionPattern,
        builder: (_, state) => Scaffold(
          body: SafeArea(
            child: SubmissionReviewScreen(submissionId: state.pathParameters['submissionId'] ?? ''),
          ),
        ),
      ),
    ],
  );

  String firstSubmissionId() =>
      ((_json('submissions')['rows']! as List).first as Map<String, dynamic>)['id'] as String;

  group('the queue', () {
    testWidgets('leads with the academy\'s own two numbers', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffReview);
      await tester.pumpAndSettle();

      expect(find.text('To review'), findsWidgets);
      expect(find.text('Overdue'), findsWidgets);
      expect(find.text('3'), findsWidgets, reason: 'three waiting, as the route counted');
      expect(find.byType(SubmissionCard), findsWidgets);
    });

    testWidgets('each hand-in says who, what and where it stands', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffReview);
      await tester.pumpAndSettle();

      expect(find.textContaining('Foundations of Vedic Astrology'), findsWidgets);
      expect(find.widgetWithText(StripCard, 'Gaurav Joshi'), findsOneWidget);
      expect(find.textContaining('Handed in'), findsWidgets);
    });

    testWidgets('an overdue hand-in is marked as such on its strip', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffReview);
      await tester.pumpAndSettle();

      final cards = tester.widgetList<StripCard>(find.byType(StripCard));
      expect(cards.where((c) => c.stripIcon == AppIcons.warning), hasLength(1));
      expect(
        cards.firstWhere((c) => c.stripIcon == AppIcons.warning).title,
        'Ananya Rao',
        reason: 'the one row the academy counts overdue',
      );
    });

    testWidgets('the sort lives in the Filters sheet, and travels with the request', (
      tester,
    ) async {
      answering();

      await pump(tester, at: AppRoutes.staffReview);
      await tester.pumpAndSettle();
      expect(find.text('Sort by'), findsNothing, reason: 'not above the list any more');

      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppSelectField<String>, 'Sort by'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Newest first').last);
      await tester.pumpAndSettle();

      expect(
        adapter.requests
            .where((r) => r.path == '/assignments/submissions')
            .last
            .queryParameters['sort'],
        'newest',
      );
    });

    testWidgets('the queue fits a small phone at the largest text size', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffReview, size: const Size(360, 9000), textScale: 2);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SubmissionCard), findsWidgets);
    });

    testWidgets('a tab asks the academy for that filter alone', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffReview);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Graded').first);
      await tester.pumpAndSettle();

      expect(
        adapter.requests
            .where((r) => r.path == '/assignments/submissions')
            .last
            .queryParameters['filter'],
        'graded',
      );
    });

    testWidgets('searching narrows it by learner', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffReview);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'ananya');
      await tester.pumpAndSettle();

      expect(
        adapter.requests
            .where((r) => r.path == '/assignments/submissions')
            .last
            .queryParameters['search'],
        'ananya',
      );
    });

    testWidgets('an empty queue is good news, not an empty screen', (tester) async {
      answering(
        submissions: {
          'rows': const <Object>[],
          'total': 0,
          'counts': const {'all': 0, 'to-review': 0, 'graded': 0, 'returned': 0, 'missing': 0},
        },
      );

      await pump(tester, at: AppRoutes.staffReview);
      await tester.pumpAndSettle();

      expect(find.text('Nothing to review'), findsOneWidget);
    });

    testWidgets('a learner who has not handed in is listed but cannot be reviewed', (tester) async {
      answering(submissions: _json('submissions-missing'));

      final router = await pump(tester, at: AppRoutes.staffReview);
      await tester.pumpAndSettle();

      expect(find.text('Nothing handed in yet'), findsWidgets);
      await tester.tap(find.byType(SubmissionCard).first);
      await tester.pumpAndSettle();

      expect(locationOf(router), AppRoutes.staffReview, reason: 'there is nothing to open');
    });

    testWidgets('opening a hand-in goes to its review', (tester) async {
      answering();

      final router = await pump(tester, at: AppRoutes.staffReview);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SubmissionCard).first);
      await tester.pumpAndSettle();

      expect(locationOf(router), AppRoutes.staffSubmission(firstSubmissionId()));
    });

    testWidgets('on a tablet the review sits beside the queue', (tester) async {
      answering();

      final router = await pump(tester, at: AppRoutes.staffReview, size: const Size(1200, 2400));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SubmissionCard).first);
      await tester.pumpAndSettle();

      expect(locationOf(router), AppRoutes.staffReview, reason: 'the pane changed, not the route');
      expect(find.byType(RubricScorer), findsNothing, reason: 'this assignment has no rubric');
      expect(find.text('Feedback for the learner'), findsWidgets);
      expect(find.byType(SubmissionCard), findsWidgets, reason: 'the queue is still there');
    });
  });

  group('the review', () {
    testWidgets('shows the learner, the hand-in and where the pass mark lies', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffSubmission('s1'));
      await tester.pumpAndSettle();

      expect(find.text('Ananya Rao'), findsOneWidget);
      expect(find.textContaining('through the course'), findsOneWidget);
      expect(find.text('The score'), findsOneWidget);
      expect(find.textContaining('the LMS works out the final score'), findsWidgets);
      expect(find.textContaining('Below the pass mark of 60'), findsOneWidget);
    });

    testWidgets('the brief is there when it is wanted, not before', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffSubmission('s1'));
      await tester.pumpAndSettle();
      expect(find.byType(AssignmentBrief), findsNothing);

      await tester.tap(find.text('The brief'));
      await tester.pumpAndSettle();

      expect(find.byType(AssignmentBrief), findsOneWidget);
    });

    testWidgets('a rubric is scored criterion by criterion, with a running total', (tester) async {
      answering(detail: 'submission-rubric');

      await pump(tester, at: AppRoutes.staffSubmission('s1'));
      await tester.pumpAndSettle();

      expect(find.byType(RubricScorer), findsOneWidget);
      expect(find.text('Lagna reading'), findsOneWidget);
      expect(find.text('Moon sign reading'), findsOneWidget);
      // Nothing scored yet: the estimate is zero out of the rubric's own total.
      expect(find.textContaining('About 0 of 50'), findsWidgets);
    });

    testWidgets('scoring moves the estimate the app shows', (tester) async {
      answering(detail: 'submission-rubric');

      await pump(tester, at: AppRoutes.staffSubmission('s1'));
      await tester.pumpAndSettle();

      // Each criterion has an add button; one tap gives it a point.
      await tester.tap(find.byIcon(AppIcons.add).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('About 1 of 50'), findsWidgets);
    });

    testWidgets('grading is confirmed with what it would come to', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffSubmission('s1'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '72');
      await tester.enterText(
        // The label sits above the box, so the field is found through its AppTextField.
        find.descendant(
          of: find.widgetWithText(AppTextField, 'Feedback for the learner'),
          matching: find.byType(TextField),
        ),
        'Clear and well argued throughout.',
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.widgetWithText(AppButton, 'Grade'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(AppButton, 'Grade'));
      await tester.pumpAndSettle();

      expect(find.text('Send this grade to the learner?'), findsOneWidget);
      expect(find.textContaining('About 72 of 100'), findsWidgets);

      await tester.tap(find.widgetWithText(AppButton, 'Grade').last);
      await tester.pumpAndSettle();

      final sent = adapter.requests.where((r) => r.method == 'POST').last;
      expect(sent.path, endsWith('/review'));
      expect((sent.data! as Map)['decision'], 'graded');
      expect((sent.data! as Map)['points'], 72);
    });

    testWidgets('a refused grade is shown against the fields the academy named', (tester) async {
      answering(review: fixture('errors/review-refused.json'), reviewStatus: 409);

      await pump(tester, at: AppRoutes.staffSubmission('s1'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(AppButton, 'Grade'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(AppButton, 'Grade'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Grade').last);
      await tester.pumpAndSettle();

      expect(find.text('Give a score from 0 to 100.'), findsOneWidget);
      expect(find.text('Leave the learner a line of feedback with their grade.'), findsOneWidget);
    });

    testWidgets('returning it asks first, and says what happens to the learner', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffSubmission('s1'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(AppButton, 'Return for changes'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(AppButton, 'Return for changes'));
      await tester.pumpAndSettle();

      expect(find.text('Ask for another attempt?'), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, 'Return for changes').last);
      await tester.pumpAndSettle();

      expect(
        (adapter.requests.where((r) => r.method == 'POST').last.data! as Map)['decision'],
        'returned',
      );
    });

    testWidgets('the private note says who sees it', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffSubmission('s1'));
      await tester.pumpAndSettle();

      expect(find.text('Only staff see this. The learner never does.'), findsOneWidget);
    });

    testWidgets('someone who may not mark work is offered no decision', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffSubmission('s1'), signedInAs: _reader());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppButton, 'Grade'), findsNothing);
      expect(find.widgetWithText(AppButton, 'Return for changes'), findsNothing);
      expect(find.text('What the learner handed in'), findsOneWidget);
    });

    testWidgets('a hand-in that is not this account\'s reads as not found', (tester) async {
      adapter.handler = (options) async =>
          FakeAdapter.jsonResponse(const {'message': 'Submission not found.'}, status: 404);

      await pump(tester, at: AppRoutes.staffSubmission('someone-elses'));
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundView), findsOneWidget);
    });

    testWidgets('a late hand-in says the academy may take something off', (tester) async {
      final late = _json('submission');
      (late['submission']! as Map<String, dynamic>)['late'] = true;
      answering(detailJson: late);

      await pump(tester, at: AppRoutes.staffSubmission('s1'));
      await tester.pumpAndSettle();

      expect(find.textContaining('was late'), findsOneWidget);
      expect(find.textContaining('10%'), findsOneWidget);
    });

    testWidgets('everything still fits at the largest text size', (tester) async {
      answering(detail: 'submission-rubric');

      await pump(
        tester,
        at: AppRoutes.staffSubmission('s1'),
        size: const Size(400, 9000),
        textScale: 2,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('one assignment\'s hand-ins', () {
    testWidgets('lists them with the counts the route sent', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffSubmissions('a1'));
      await tester.pumpAndSettle();

      expect(find.byType(SubmissionCard), findsWidgets);
      expect(find.text('Missing'), findsWidgets);
      expect(
        adapter.requests.last.path,
        '/assignments/a1/submissions',
        reason: 'the assignment is the path',
      );
    });

    testWidgets('reminding who is missing asks first, then says how many were reached', (
      tester,
    ) async {
      answering();

      await pump(tester, at: AppRoutes.staffSubmissions('a1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remind who is missing'));
      await tester.pumpAndSettle();
      expect(find.text('Remind the learners who owe this?'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Remind who is missing').last);
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.method == 'POST').last.path, '/assignments/a1/remind');
      expect(find.text('3 learners were reminded'), findsOneWidget);
    });

    testWidgets('someone who may not message learners is not offered the reminder', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffSubmissions('a1'), signedInAs: _reader());
      await tester.pumpAndSettle();

      expect(find.text('Remind who is missing'), findsNothing);
    });
  });
}
