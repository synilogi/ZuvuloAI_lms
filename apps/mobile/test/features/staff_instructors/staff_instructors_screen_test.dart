import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/staff_certificates/staff_certificates.dart';
import 'package:syniastrolms_mobile/features/staff_instructors/staff_instructors.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(jsonEncode(fixture('staff/$name.json'))) as Map<String, dynamic>;

Map<String, dynamic> _firstRowField(String name, String field) {
  final rows = _json(name)['rows']! as List<dynamic>;
  return (rows.first as Map<String, dynamic>)[field]! as Map<String, dynamic>;
}

UserProfile _admin({List<PermissionKey>? permissions}) => UserProfile(
  id: 'u_admin',
  name: 'Kavita Menon',
  email: 'admin@example.test',
  role: UserRole.admin,
  descriptor: 'Admin',
  permissions:
      permissions ?? PermissionKey.values.where((k) => k != PermissionKey.unknown).toList(),
);

UserProfile _instructor() => const UserProfile(
  id: 'u_instructor',
  name: 'Meenakshi Iyer',
  email: 'meenakshi@example.test',
  role: UserRole.instructor,
  descriptor: 'Instructor',
  permissions: [PermissionKey.instructorsView, PermissionKey.certificatesIssue],
);

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  void answering({Map<String, dynamic>? certificate, Object? write, int writeStatus = 200}) {
    adapter.handler = (options) async {
      if (options.method != 'GET') {
        return FakeAdapter.jsonResponse(
          write ?? _firstRowField('instructors', 'instructor'),
          status: writeStatus,
        );
      }
      if (options.path == '/courses') {
        return FakeAdapter.jsonResponse(fixture('staff/courses.json'));
      }
      if (options.path.startsWith('/instructors/')) {
        return FakeAdapter.jsonResponse(_json('instructor'));
      }
      if (options.path == '/instructors') {
        return FakeAdapter.jsonResponse(_json('instructors'));
      }
      if (options.path.startsWith('/certificates/')) {
        return FakeAdapter.jsonResponse(certificate ?? _json('certificate'));
      }
      return FakeAdapter.jsonResponse(_json('certificates'));
    };
  }

  /// Pumps and settles: `pumpPublicRouter` pumps a single frame, so without settling the screen is
  /// still on its skeleton and nothing the academy sent has been drawn yet.
  Future<GoRouter> pump(
    WidgetTester tester, {
    required String at,
    UserProfile? signedInAs,
    Size size = const Size(400, 6000),
  }) async {
    final router = await pumpPublicRouter(
      tester,
      adapter: adapter,
      signedInAs: signedInAs ?? _admin(),
      initialLocation: at,
      size: size,
      routes: [
        GoRoute(
          path: AppRoutes.staffInstructors,
          builder: (_, _) => const Scaffold(body: SafeArea(child: InstructorsScreen())),
        ),
        GoRoute(
          path: AppRoutes.staffInstructorInvite,
          builder: (_, _) => const Scaffold(body: SafeArea(child: InstructorFormScreen())),
        ),
        GoRoute(
          path: AppRoutes.staffInstructorPattern,
          builder: (_, state) => Scaffold(
            body: SafeArea(
              child: InstructorScreen(instructorId: state.pathParameters['instructorId'] ?? ''),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.staffInstructorEditPattern,
          builder: (_, state) => Scaffold(
            body: SafeArea(
              child: InstructorFormScreen(instructorId: state.pathParameters['instructorId'] ?? ''),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.staffCertificates,
          builder: (_, _) => const Scaffold(body: SafeArea(child: CertificatesRegisterScreen())),
        ),
        GoRoute(
          path: AppRoutes.staffCertificatePattern,
          builder: (_, state) => Scaffold(
            body: SafeArea(
              child: StaffCertificateScreen(
                certificateId: state.pathParameters['certificateId'] ?? '',
              ),
            ),
          ),
        ),
        GoRoute(path: AppRoutes.staffCoursePattern, builder: (_, _) => const Placeholder()),
        GoRoute(path: AppRoutes.staffStudentPattern, builder: (_, _) => const Placeholder()),
      ],
    );
    await tester.pumpAndSettle();
    return router;
  }

  group('the instructor directory', () {
    testWidgets('lists the academy\'s instructors with its own counts and figures', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffInstructors);

      expect(find.text('Acharya Vinod Shastri'), findsOneWidget);
      expect(find.text('Predictive Astrologer'), findsOneWidget);
      // The tab count is the route's, not the length of the page.
      expect(find.textContaining('All'), findsWidgets);
      expect(find.text('23 learners'), findsOneWidget);
      expect(find.text('4.6 from 433 ratings'), findsOneWidget);
    });

    testWidgets('an admin is offered the invitation; an instructor is not', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffInstructors);
      expect(find.text('Invite an instructor'), findsOneWidget);

      await pump(tester, at: AppRoutes.staffInstructors, signedInAs: _instructor());

      expect(
        find.text('Invite an instructor'),
        findsNothing,
        reason: 'adding an instructor needs instructors.manage, which an instructor never has',
      );
    });

    testWidgets('opening a row goes to that instructor', (tester) async {
      answering();
      final router = await pump(tester, at: AppRoutes.staffInstructors);

      await tester.tap(find.text('Acharya Vinod Shastri'));
      await tester.pumpAndSettle();

      expect(locationOf(router), startsWith('/staff/instructors/'));
    });

    testWidgets('the sort sits in the Filters sheet, and the button counts it once on', (
      tester,
    ) async {
      answering();
      await pump(tester, at: AppRoutes.staffInstructors);

      // Search and the status tabs stay in view; the sort is behind the Filters button.
      expect(find.text('Sort by'), findsNothing);
      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();
      expect(find.text('Sort by'), findsOneWidget);

      await tester.tap(find.text('Name').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Most learners').last);
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/instructors').last.queryParameters['sort'],
        'students',
      );
      expect(find.byTooltip('Filters, 1 on'), findsOneWidget);
    });

    testWidgets('a narrowed list that finds nobody offers to clear the filters', (tester) async {
      answering();
      adapter.handler = (options) async => options.path == '/instructors'
          ? FakeAdapter.jsonResponse(const {
              'rows': <Object?>[],
              'counts': {'all': 0, 'active': 0, 'invited': 0, 'inactive': 0},
              'expertise': ['Transits'],
            })
          : FakeAdapter.jsonResponse(fixture('staff/courses.json'));
      await pump(tester, at: AppRoutes.staffInstructors);

      await tester.enterText(find.byType(TextField).first, 'nobody');
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
    });
  });

  group('one instructor', () {
    testWidgets('shows the record, their reach and the academy comparison', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffInstructor('i1'));

      expect(find.text('Acharya Vinod Shastri'), findsOneWidget);
      expect(find.text('Varanasi'), findsWidgets);
      // The overview tab is open first.
      expect(find.text('Their learners'), findsOneWidget);
      expect(find.text('23'), findsWidgets);

      await tester.tap(find.text('Performance'));
      await tester.pumpAndSettle();

      expect(find.text('Rating'), findsWidgets);
      expect(find.text('vs the platform'), findsWidgets);
      expect(find.text('Median turnaround'), findsOneWidget);
    });

    testWidgets('their courses list opens the course it names', (tester) async {
      answering();
      final router = await pump(tester, at: AppRoutes.staffInstructor('i1'));

      await tester.tap(find.text('Courses'));
      await tester.pumpAndSettle();
      expect(find.text('Reading the Dasha System'), findsOneWidget);

      await tester.tap(find.text('Reading the Dasha System'));
      await tester.pumpAndSettle();

      expect(locationOf(router), startsWith('/staff/courses/'));
    });

    testWidgets('an active instructor is not offered another invitation', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffInstructor('i1'));

      expect(find.text('Edit details'), findsOneWidget);
      expect(find.text('Make inactive'), findsOneWidget);
      expect(
        find.text('Send the invitation again'),
        findsNothing,
        reason: 'only someone still waiting on an invitation needs another',
      );
    });

    testWidgets('an invited instructor can be sent theirs again', (tester) async {
      final invited = _json('instructor');
      (invited['instructor']! as Map<String, dynamic>)['status'] = 'invited';
      adapter.handler = (options) async {
        if (options.method != 'GET') {
          return FakeAdapter.jsonResponse(const {'sentTo': 'vinod@example.test'});
        }
        if (options.path == '/courses') {
          return FakeAdapter.jsonResponse(fixture('staff/courses.json'));
        }
        return FakeAdapter.jsonResponse(invited);
      };
      await pump(tester, at: AppRoutes.staffInstructor('i1'));

      await tester.tap(find.text('Send the invitation again'));
      await tester.pumpAndSettle();

      // The address reported is the academy's answer, not the one on screen.
      expect(find.textContaining('vinod@example.test'), findsOneWidget);
    });

    testWidgets('making one inactive asks first, and says what it costs them', (tester) async {
      answering(write: {..._firstRowField('instructors', 'instructor'), 'status': 'inactive'});
      await pump(tester, at: AppRoutes.staffInstructor('i1'));

      await tester.tap(find.text('Make inactive'));
      await tester.pumpAndSettle();

      expect(find.text('Make this instructor inactive?'), findsOneWidget);
      expect(find.textContaining('no longer be able to sign in'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Make inactive').last);
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.path.endsWith('/status')), hasLength(1));
    });
  });

  group('the invite form', () {
    testWidgets('will not offer to send until the academy would take it', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffInstructorInvite);

      final send = find.widgetWithText(AppButton, 'Send the invitation');
      expect(tester.widget<AppButton>(send).onPressed, isNull);

      await tester.enterText(_field(tester, 'Full name'), 'Vinod Shastri');
      await tester.enterText(_field(tester, 'Professional title'), 'Predictive Astrologer');
      await tester.enterText(_field(tester, 'Email'), 'vinod@example.test');
      await tester.enterText(_field(tester, 'Add an area of expertise'), 'Transits');
      await tester.tap(find.widgetWithText(AppButton, 'Add').first);
      await tester.pumpAndSettle();
      await tester.enterText(_field(tester, 'Add a language'), 'Hindi');
      await tester.tap(find.widgetWithText(AppButton, 'Add').last);
      await tester.pumpAndSettle();

      expect(tester.widget<AppButton>(send).onPressed, isNotNull);
    });

    testWidgets('a refusal puts the academy\'s words on the field it names', (tester) async {
      answering(
        write: const {
          'message': 'Check the instructor details.',
          'issues': [
            {'field': 'email', 'message': 'Another instructor already uses this email.'},
          ],
        },
        writeStatus: 409,
      );
      await pump(tester, at: AppRoutes.staffInstructorInvite);

      await tester.enterText(_field(tester, 'Full name'), 'Vinod Shastri');
      await tester.enterText(_field(tester, 'Professional title'), 'Predictive Astrologer');
      await tester.enterText(_field(tester, 'Email'), 'taken@example.test');
      await tester.enterText(_field(tester, 'Add an area of expertise'), 'Transits');
      await tester.tap(find.widgetWithText(AppButton, 'Add').first);
      await tester.pumpAndSettle();
      await tester.enterText(_field(tester, 'Add a language'), 'Hindi');
      await tester.tap(find.widgetWithText(AppButton, 'Add').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Send the invitation'));
      await tester.pumpAndSettle();

      expect(find.text('Another instructor already uses this email.'), findsOneWidget);
    });

    testWidgets('an edit opens on the record the academy holds', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffInstructorEdit('i1'));

      // The shell's app bar names the form; the body does not say it again.
      expect(find.text('Edit the instructor'), findsNothing);
      expect(find.widgetWithText(AppButton, 'Save the instructor'), findsOneWidget);
      expect(find.text('Acharya Vinod Shastri'), findsOneWidget);
      expect(find.text('Transits'), findsWidgets);
    });
  });

  group('the credential register', () {
    testWidgets('lists the credentials with the academy\'s counts', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffCertificates);

      expect(find.text('Ananya Rao'), findsWidgets);
      expect(find.textContaining('SA-JY-2026-00142'), findsOneWidget);
      expect(find.text('The 27 Nakshatras in Depth'), findsWidgets);
    });

    testWidgets('opening a row goes to that certificate', (tester) async {
      answering();
      final router = await pump(tester, at: AppRoutes.staffCertificates);

      await tester.tap(find.text('Ananya Rao').first);
      await tester.pumpAndSettle();

      expect(locationOf(router), startsWith('/staff/certificates/'));
    });
  });

  group('one certificate', () {
    testWidgets('draws the canvas and offers to issue a pending one', (tester) async {
      answering();
      await pump(tester, at: AppRoutes.staffCertificate('cert1'));

      expect(find.byType(CertificateCanvas), findsOneWidget);
      expect(find.text('Vikram Singh'), findsWidgets);
      expect(find.textContaining('Not issued yet'), findsOneWidget);
      expect(find.text('Issue the certificate'), findsOneWidget);
      expect(find.text('Revoke'), findsNothing);
    });

    testWidgets('issuing asks first, and says what the academy did', (tester) async {
      final pendingCertificate = _json('certificate');
      final issued = {
        ...pendingCertificate['certificate']! as Map<String, dynamic>,
        'status': 'issued',
      };
      answering(write: issued);
      await pump(tester, at: AppRoutes.staffCertificate('cert1'));

      await tester.tap(find.text('Issue the certificate'));
      await tester.pumpAndSettle();
      expect(find.text('Issue this certificate?'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Issue the certificate').last);
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.path.endsWith('/issue')), hasLength(1));
      expect(find.text('Certificate issued.'), findsOneWidget);
    });

    testWidgets('an issued certificate offers revoking, which insists on a reason', (tester) async {
      final detail = _json('certificate');
      (detail['certificate']! as Map<String, dynamic>)
        ..['status'] = 'issued'
        ..['issuedAt'] = '2026-09-01T00:00:00.000Z';
      answering(certificate: detail, write: detail['certificate']);
      await pump(tester, at: AppRoutes.staffCertificate('cert1'));

      expect(find.text('Issue the certificate'), findsNothing);
      await tester.tap(find.text('Revoke'));
      await tester.pumpAndSettle();

      // Two characters is below what the route will take, so the button stays off.
      await tester.enterText(_field(tester, 'Reason'), 'no');
      await tester.pumpAndSettle();
      final confirm = find.widgetWithText(AppButton, 'Revoke').last;
      expect(tester.widget<AppButton>(confirm).onPressed, isNull);

      await tester.enterText(_field(tester, 'Reason'), 'Issued in error.');
      await tester.pumpAndSettle();
      expect(tester.widget<AppButton>(confirm).onPressed, isNotNull);
    });

    testWidgets('a revoked certificate shows the academy\'s reason and offers restoring', (
      tester,
    ) async {
      final detail = _json('certificate');
      (detail['certificate']! as Map<String, dynamic>)
        ..['status'] = 'revoked'
        ..['issuedAt'] = '2026-09-01T00:00:00.000Z'
        ..['revokedAt'] = '2026-09-20T00:00:00.000Z'
        ..['revokedReason'] = 'Issued against the wrong course.';
      answering(certificate: detail, write: detail['certificate']);
      await pump(tester, at: AppRoutes.staffCertificate('cert1'));

      expect(find.text('Issued against the wrong course.'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);
      expect(find.text('Revoke'), findsNothing);
    });

    testWidgets('an instructor may issue but never revoke', (tester) async {
      final detail = _json('certificate');
      (detail['certificate']! as Map<String, dynamic>)
        ..['status'] = 'issued'
        ..['issuedAt'] = '2026-09-01T00:00:00.000Z';
      answering(certificate: detail);
      await pump(tester, at: AppRoutes.staffCertificate('cert1'), signedInAs: _instructor());

      expect(
        find.text('Revoke'),
        findsNothing,
        reason: 'revoking is certificates.revoke, an admin key',
      );
    });
  });
}

/// An [AppTextField] carries its label in the decoration, and `required: true` appends " · Required"
/// to what is drawn — so the field is found by the label it was *given*, not by the text on screen.
Finder _field(WidgetTester tester, String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is AppTextField && w.label == label),
  matching: find.byType(TextField),
);
