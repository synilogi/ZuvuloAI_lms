import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_students/staff_students.dart';
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
  descriptor: 'Academy admin',
  permissions: PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

/// An admin who may read the roster and nothing more.
UserProfile _reader() => const UserProfile(
  id: 'u_reader',
  name: 'Reader',
  email: 'reader@example.test',
  role: UserRole.admin,
  descriptor: 'Academy admin',
  permissions: [PermissionKey.learnersView],
);

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  void answering({
    Map<String, dynamic>? roster,
    Map<String, dynamic>? profile,
    Object? rosterError,
    int rosterStatus = 200,
    Object? action,
    int actionStatus = 200,
  }) {
    adapter.handler = (options) async {
      if (options.method != 'GET') {
        return FakeAdapter.jsonResponse(
          action ?? (profile ?? _json('student'))['student'],
          status: actionStatus,
        );
      }
      if (options.path == '/courses') {
        return FakeAdapter.jsonResponse(fixture('staff/courses.json'));
      }
      if (options.path.endsWith('/progress')) {
        return FakeAdapter.jsonResponse(_json('student-progress'));
      }
      if (options.path.endsWith('/activity')) {
        return FakeAdapter.jsonResponse(_json('student-activity'));
      }
      if (options.path == '/students') {
        return rosterError == null
            ? FakeAdapter.jsonResponse(roster ?? _json('students'))
            : FakeAdapter.jsonResponse(rosterError, status: rosterStatus);
      }
      return FakeAdapter.jsonResponse(profile ?? _json('student'));
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
        path: AppRoutes.staffStudents,
        builder: (_, _) => const Scaffold(body: SafeArea(child: StudentsScreen())),
      ),
      GoRoute(
        path: AppRoutes.staffStudentPattern,
        builder: (_, state) => Scaffold(
          body: SafeArea(child: StudentScreen(studentId: state.pathParameters['studentId'] ?? '')),
        ),
      ),
    ],
  );

  String firstId() =>
      (((_json('students')['rows']! as List).first as Map<String, dynamic>)['student']!
              as Map<String, dynamic>)['id']
          as String;

  group('the roster', () {
    testWidgets('shows the learners with the academy\'s status and counts', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffStudents);
      await tester.pumpAndSettle();

      expect(find.byType(RosterCard), findsWidgets);
      expect(find.text('Arjun Das'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
      expect(find.textContaining('through'), findsWidgets);
    });

    testWidgets('a status tab asks the academy for that status alone', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffStudents);
      await tester.pumpAndSettle();

      await tester.tap(find.text('At risk').first);
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/students').last.queryParameters['status'],
        'at-risk',
      );
    });

    testWidgets('searching narrows it by name or email', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffStudents);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'ananya');
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/students').last.queryParameters['search'],
        'ananya',
      );
    });

    testWidgets('an academy with no learners is told where they come from', (tester) async {
      answering(
        roster: {
          'rows': const <Object>[],
          'total': 0,
          'counts': const {'all': 0, 'active': 0, 'at-risk': 0, 'inactive': 0, 'suspended': 0},
        },
      );

      await pump(tester, at: AppRoutes.staffStudents);
      await tester.pumpAndSettle();

      expect(find.text('No learners yet'), findsOneWidget);
    });

    testWidgets('a failed read offers a retry', (tester) async {
      answering(rosterError: const {'message': 'Server error.'}, rosterStatus: 500);

      await pump(tester, at: AppRoutes.staffStudents);
      await tester.pumpAndSettle();
      expect(find.byType(ErrorState), findsOneWidget);

      answering();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.byType(RosterCard), findsWidgets);
    });

    testWidgets('a long roster is paged, and the page travels with the request', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffStudents);
      await tester.pumpAndSettle();

      expect(find.text('Page 1 of 3'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Next'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.path == '/students').last.queryParameters['page'], 2);
    });

    testWidgets('the sort and the course live in the Filters sheet', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffStudents);
      await tester.pumpAndSettle();
      expect(find.text('Sort by'), findsNothing, reason: 'not above the roster any more');

      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppSelectField<String>, 'Course'), findsOneWidget);
      await tester.tap(find.widgetWithText(AppSelectField<String>, 'Sort by'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name').last);
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/students').last.queryParameters['sort'],
        'name',
      );
    });

    testWidgets('the roster fits a small phone at the largest text size', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffStudents, size: const Size(360, 9000), textScale: 2);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RosterCard), findsWidgets);
    });

    testWidgets('opening a learner goes to their own screen', (tester) async {
      answering();

      final router = await pump(tester, at: AppRoutes.staffStudents);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(RosterCard).first);
      await tester.pumpAndSettle();

      expect(locationOf(router), AppRoutes.staffStudent(firstId()));
    });

    testWidgets('picking learners offers a message, and says how many', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffStudents);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Select'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();

      expect(find.text('1 learner selected'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Message'), findsOneWidget);
    });

    testWidgets('a message the academy takes reports its own count', (tester) async {
      answering(action: const {'sent': 1});

      await pump(tester, at: AppRoutes.staffStudents);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Select'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Message'));
      await tester.pumpAndSettle();

      expect(find.text('Message the learners you picked'), findsOneWidget);
      // The button waits for a subject and enough of a message.
      expect(tester.widget<AppButton>(find.widgetWithText(AppButton, 'Send')).onPressed, isNull);

      // The sheet's own two fields: the label sits in the decoration, not in the field's subtree.
      final fields = find.descendant(
        of: find.byType(AppBottomSheet),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), 'Next week');
      await tester.enterText(fields.at(1), 'The live class moves to Thursday. Bring your charts.');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Send'));
      await tester.pumpAndSettle();

      final sent = adapter.requests.where((r) => r.method == 'POST').last;
      expect(sent.path, '/students/message');
      expect((sent.data! as Map)['channels'], const ['app']);
      expect(find.text('Sent to 1 learner'), findsOneWidget);
    });

    testWidgets('someone who may not message learners cannot pick them', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffStudents, signedInAs: _reader());
      await tester.pumpAndSettle();

      expect(find.text('Select'), findsNothing);
      expect(find.byType(RosterCard), findsWidgets);
    });
  });

  group('one learner', () {
    testWidgets('leads with who they are and where they stand', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffStudent('s1'));
      await tester.pumpAndSettle();

      expect(find.text('Ananya Rao'), findsOneWidget);
      // The rank and how quiet they have been read as one line.
      expect(find.textContaining('Rank I'), findsOneWidget);
      expect(find.textContaining('Active today'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Courses'), findsWidgets);
    });

    testWidgets('the overview shows the academy\'s figures and says who sees the details', (
      tester,
    ) async {
      answering();

      await pump(tester, at: AppRoutes.staffStudent('s1'));
      await tester.pumpAndSettle();

      expect(find.text('Contact details are shown to staff only.'), findsOneWidget);
      expect(find.text('How they are doing'), findsOneWidget);
      expect(find.text('3'), findsWidgets, reason: 'three enrolments');
      expect(find.text('51%'), findsWidgets, reason: 'their average progress');
      expect(find.textContaining('SA-'), findsOneWidget, reason: 'the credential they hold');
    });

    testWidgets('a course they are on says how much is done and what is next', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffStudent('s1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Courses').last);
      await tester.pumpAndSettle();

      expect(find.byType(EnrollmentCard), findsWidgets);
      expect(find.textContaining('chapters ·'), findsWidgets);
      expect(find.textContaining('Up next:'), findsWidgets);
    });

    testWidgets('pausing an enrolment is confirmed first', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffStudent('s1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Courses').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Pause').first);
      await tester.pumpAndSettle();
      expect(find.text('Pause this enrolment?'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Pause').last);
      await tester.pumpAndSettle();

      final sent = adapter.requests.where((r) => r.method == 'PATCH').last;
      expect(sent.path, startsWith('/students/enrollments/'));
      expect((sent.data! as Map)['status'], 'paused');
    });

    testWidgets('removing an enrolment asks for an acknowledgement', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffStudent('s1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Courses').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Remove').first);
      await tester.pumpAndSettle();

      expect(find.text('Remove this enrolment?'), findsOneWidget);
      final confirm = find.widgetWithText(AppButton, 'Remove').last;
      expect(tester.widget<AppButton>(confirm).onPressed, isNull, reason: 'not yet acknowledged');

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(tester.widget<AppButton>(confirm).onPressed, isNotNull);
    });

    testWidgets('the progress tab breaks each course down by chapter', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffStudent('s1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();

      expect(find.text('The Nine Planets · 3/3'), findsOneWidget);
      expect(find.text('Quizzes'), findsWidgets);
      expect(find.textContaining('Best 83% of a pass mark of 70%'), findsOneWidget);
      expect(find.text('Hand-ins'), findsWidgets);
    });

    testWidgets('the activity tab reads as the academy recorded it, and filters by kind', (
      tester,
    ) async {
      answering();

      await pump(tester, at: AppRoutes.staffStudent('s1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      expect(find.text('Everything'), findsOneWidget);
      expect(find.text('Lesson completed'), findsWidgets);

      await tester.tap(find.text('Enrolled').first);
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path.endsWith('/activity')).last.queryParameters['kind'],
        'enrolled',
      );
    });

    testWidgets('an admin who may suspend is offered it, with an acknowledgement', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffStudent('s1'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(AppButton, 'Suspend'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(AppButton, 'Suspend'));
      await tester.pumpAndSettle();

      expect(find.text('Suspend this learner?'), findsOneWidget);
      expect(find.textContaining('cannot sign in'), findsOneWidget);
      expect(find.text('Why (only staff see this)'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Suspend').last);
      await tester.pumpAndSettle();

      final sent = adapter.requests.where((r) => r.method == 'POST').last;
      expect(sent.path, endsWith('/suspend'));
      expect((sent.data! as Map)['suspended'], isTrue);
    });

    testWidgets('a suspended learner is offered a restore instead', (tester) async {
      final suspended = _json('student');
      (suspended['student']! as Map<String, dynamic>)['suspended'] = true;
      suspended['status'] = 'suspended';
      answering(profile: suspended);

      await pump(tester, at: AppRoutes.staffStudent('s1'));
      await tester.pumpAndSettle();

      expect(find.text('Suspended'), findsWidgets);
      await tester.scrollUntilVisible(
        find.widgetWithText(AppButton, 'Restore'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.widgetWithText(AppButton, 'Suspend'), findsNothing);
    });

    testWidgets('someone who may not act is offered no action at all', (tester) async {
      answering();

      await pump(tester, at: AppRoutes.staffStudent('s1'), signedInAs: _reader());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppButton, 'Suspend'), findsNothing);
      await tester.tap(find.text('Courses').last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppButton, 'Pause'), findsNothing);
      expect(find.widgetWithText(AppButton, 'Remove'), findsNothing);
      expect(find.widgetWithText(AppButton, 'Enrol in a course'), findsNothing);
    });

    testWidgets('their courses fit a small phone at the largest text size', (tester) async {
      answering();

      await pump(
        tester,
        at: AppRoutes.staffStudent('s1'),
        size: const Size(360, 9000),
        textScale: 2,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Courses').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(EnrollmentCard), findsWidgets);
    });

    testWidgets('a learner who is not this account\'s reads as not found', (tester) async {
      adapter.handler = (options) async =>
          FakeAdapter.jsonResponse(const {'message': 'Student not found.'}, status: 404);

      await pump(tester, at: AppRoutes.staffStudent('someone-elses'));
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundView), findsOneWidget);
    });

    testWidgets('everything still fits at the largest text size', (tester) async {
      answering();

      await pump(
        tester,
        at: AppRoutes.staffStudent('s1'),
        size: const Size(400, 9000),
        textScale: 2,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
