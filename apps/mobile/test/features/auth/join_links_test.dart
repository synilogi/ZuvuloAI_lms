import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/app.dart';
import 'package:syniastrolms_mobile/app/routing/app_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/shared/widgets/navigation/app_nav_bar.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_adapter.dart';
import '../../helpers/fake_auth_repository.dart';

/// The links an Admin sends learners — an invitation, a course link and a join link — driven through
/// the real router and session controller, with the network scripted by [FakeAuthRepository]. Each
/// link names the LMS itself, so the app never asks for an address, never sends a tenant or a role,
/// and never attaches a link to whoever happens to be signed in.
const _learner = UserProfile(
  id: 'u1',
  name: 'Asha Verma',
  email: 'asha@syniastrolms.test',
  role: UserRole.student,
  descriptor: 'Learner',
);

const _instructor = UserProfile(
  id: 'u2',
  name: 'Dr. Meenakshi Iyer',
  email: 'meenakshi@syniastrolms.test',
  role: UserRole.instructor,
  descriptor: 'Instructor',
);

/// An invitation token as the API issues it: 64 hex characters.
const _token = '3f9a1c7e20b84d65af0e2d19c8b73540e6a92f14bc385d70a1fe6b29d4c80713';
const _courseId = 'cmudqd8g30035mmgzwtgr0mcl';

final _invitation = InvitationView(
  lms: const LmsSummary(name: 'Jyotish Vidya', slug: 'jyotish-vidya'),
  expiresAt: DateTime.utc(2026, 10, 12),
  open: true,
);

const _courseLink = CourseLinkView(
  lms: LmsSummary(name: 'Jyotish Vidya', slug: 'jyotish-vidya'),
  course: CourseLinkCourse(id: _courseId, title: 'Foundations of Vedic Astrology'),
  open: true,
);

void main() {
  late FakeAuthRepository repository;
  late FakeAdapter adapter;

  setUp(() {
    repository = FakeAuthRepository();
    // The learner shell and the course reach the real API client; nothing here depends on them.
    adapter = FakeAdapter()
      ..handler = (options) async =>
          FakeAdapter.jsonResponse(const {'message': 'Not found.'}, status: 404);
  });

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(SyniastroApp)));

  String locationIn(WidgetTester tester) =>
      containerOf(tester).read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

  /// Starts the app (signed in when the repository holds a token) and opens [route].
  Future<void> open(WidgetTester tester, String route) async {
    useSurface(tester);
    await tester.pumpWidget(await testApp(repository: repository, adapter: adapter));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    containerOf(tester).read(routerProvider).go(route);
    await tester.pumpAndSettle();
  }

  group('an invitation', () {
    testWidgets('names the LMS, creates the account there and lands in the learner shell', (
      tester,
    ) async {
      repository
        ..invitationView = _invitation
        ..profile = _learner;
      await open(tester, AppRoutes.invite(_token));

      expect(find.text('Join Jyotish Vidya'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'Asha Verma');
      await tester.enterText(find.byType(TextField).at(1), 'asha@syniastrolms.test');
      await tester.enterText(find.byType(TextField).at(2), 'syniastrolms123');
      await tester.tap(find.widgetWithText(AppButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('registerWithInvitation:asha@syniastrolms.test'));
      expect(find.byType(AppNavBar), findsOneWidget, reason: 'the learner shell is up');
      expect(locationIn(tester), AppRoutes.home);
      expect(repository.token, isNotNull);
    });

    testWidgets('bound to one address shows it read-only and sends only that address', (
      tester,
    ) async {
      repository
        ..invitationView = _invitation.copyWith(email: 'invited@syniastrolms.test')
        ..profile = _learner;
      await open(tester, AppRoutes.invite(_token));

      final email = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(email.enabled, isFalse);
      expect(find.text('invited@syniastrolms.test'), findsOneWidget);
      expect(find.text('This invitation is for this email address.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Asha Verma');
      await tester.enterText(find.byType(TextField).at(2), 'syniastrolms123');
      await tester.tap(find.widgetWithText(AppButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('registerWithInvitation:invited@syniastrolms.test'));
    });

    testWidgets('that is invalid, expired or used says so and offers no form', (tester) async {
      await open(tester, AppRoutes.invite(_token));

      expect(find.text("This invitation link isn't valid"), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('for an LMS that is not open takes nobody', (tester) async {
      repository.invitationView = _invitation.copyWith(open: false);
      await open(tester, AppRoutes.invite(_token));

      expect(find.text("This LMS isn't accepting new learners right now"), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('signing in with an account of another LMS is explained, not attached', (
      tester,
    ) async {
      repository.invitationView = _invitation;
      await open(tester, AppRoutes.invite(_token));

      await tester.tap(find.widgetWithText(TextButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(
        find.text('Sign in with the account you already have at Jyotish Vidya.'),
        findsOneWidget,
      );

      repository.failure = const ConflictFailure(
        message:
            'This account belongs to another LMS, so this invitation can’t be used with it. '
            'Create a new account with a different email instead.',
      );
      await tester.enterText(find.byType(TextField).at(0), 'asha@syniastrolms.test');
      await tester.enterText(find.byType(TextField).at(1), 'syniastrolms123');
      await tester.tap(find.widgetWithText(AppButton, 'Sign in and join'));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('signInWithInvitation:asha@syniastrolms.test'));
      expect(find.text('This account belongs to another LMS'), findsOneWidget);
      expect(find.byType(AppNavBar), findsNothing);
      expect(repository.token, isNull);
    });

    testWidgets('a different address is refused in the app\'s words', (tester) async {
      repository
        ..invitationView = _invitation
        ..failure = const ForbiddenFailure(
          message:
              'This invitation is for a different email address. Use the address it was sent to.',
        );
      await open(tester, AppRoutes.invite(_token));

      await tester.enterText(find.byType(TextField).at(0), 'Asha Verma');
      await tester.enterText(find.byType(TextField).at(1), 'other@syniastrolms.test');
      await tester.enterText(find.byType(TextField).at(2), 'syniastrolms123');
      await tester.tap(find.widgetWithText(AppButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('This invitation is for a different email address'), findsOneWidget);
    });

    testWidgets('while someone is signed in is never attached to their session', (tester) async {
      repository
        ..token = 'stored'
        ..profile = _learner
        ..invitationView = _invitation;
      await open(tester, AppRoutes.invite(_token));

      expect(find.text("You're signed in as Asha Verma"), findsOneWidget);
      expect(find.byType(TextField), findsNothing, reason: 'no form while a session is open');

      await tester.tap(find.widgetWithText(AppButton, 'Sign out and continue'));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('logout'));
      expect(repository.token, isNull);
      expect(locationIn(tester), AppRoutes.invite(_token), reason: 'the link stays open');
      expect(find.text('Join Jyotish Vidya'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
    });
  });

  group('a course link', () {
    testWidgets('signed out: creates the account in the course\'s LMS and opens the course', (
      tester,
    ) async {
      repository
        ..courseLinkView = _courseLink
        ..profile = _learner;
      await open(tester, AppRoutes.courseEnrol(_courseId));

      expect(find.text('Foundations of Vedic Astrology'), findsOneWidget);
      expect(find.text('Create your learner account at Jyotish Vidya to enrol.'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'Asha Verma');
      await tester.enterText(find.byType(TextField).at(1), 'asha@syniastrolms.test');
      await tester.enterText(find.byType(TextField).at(2), 'syniastrolms123');
      await tester.tap(find.widgetWithText(AppButton, 'Create account and enrol'));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('joinFromCourseLink:$_courseId:asha@syniastrolms.test'));
      expect(locationIn(tester), AppRoutes.learnCourse(_courseId));
    });

    testWidgets('signed out, an LMS that enrols by approval: the account is ready, and why', (
      tester,
    ) async {
      repository
        ..courseLinkView = _courseLink
        ..profile = _learner
        ..courseJoinEnrolled = false
        ..courseJoinEnrolment =
            'Enrolment in this LMS needs approval — ask an instructor or your admin to add you to '
            'the course.';
      await open(tester, AppRoutes.courseEnrol(_courseId));

      await tester.enterText(find.byType(TextField).at(0), 'Asha Verma');
      await tester.enterText(find.byType(TextField).at(1), 'asha@syniastrolms.test');
      await tester.enterText(find.byType(TextField).at(2), 'syniastrolms123');
      await tester.tap(find.widgetWithText(AppButton, 'Create account and enrol'));
      await tester.pumpAndSettle();

      expect(find.text('Your account is ready'), findsOneWidget);
      expect(find.textContaining('needs approval'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Enrol'), findsNothing);
    });

    testWidgets('signed in, a course of another LMS is explained, not enrolled', (tester) async {
      repository
        ..token = 'stored'
        ..profile = _learner
        ..courseLinkView = _courseLink;
      adapter.handler = (options) async {
        if (options.method == 'POST' && options.path == '/learning/courses/$_courseId/enroll') {
          return FakeAdapter.jsonResponse(const {
            'message': 'This course belongs to another LMS. Sign in with that LMS’s account.',
          }, status: 404);
        }
        return FakeAdapter.jsonResponse(const {'message': 'Not found.'}, status: 404);
      };
      await open(tester, AppRoutes.courseEnrol(_courseId));

      expect(find.byType(TextField), findsNothing, reason: 'no account is created when signed in');
      await tester.tap(find.widgetWithText(AppButton, 'Enrol'));
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path == '/learning/courses/$_courseId/enroll'),
        hasLength(1),
      );
      expect(find.text('This course belongs to another LMS'), findsOneWidget);
      expect(
        find.text('This course belongs to another LMS. Sign in with that LMS’s account.'),
        findsOneWidget,
      );
      expect(locationIn(tester), AppRoutes.courseEnrol(_courseId));
    });

    testWidgets('signed in as staff: the link is for learners', (tester) async {
      repository
        ..token = 'stored'
        ..profile = _instructor
        ..courseLinkView = _courseLink;
      await open(tester, AppRoutes.courseEnrol(_courseId));

      expect(find.text('Course links are for learners'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Enrol'), findsNothing);
    });

    testWidgets('that names no course says so', (tester) async {
      await open(tester, AppRoutes.courseEnrol(_courseId));

      expect(find.text("This course link isn't available"), findsOneWidget);
    });
  });
}
