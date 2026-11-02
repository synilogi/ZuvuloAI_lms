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

/// A learner or an instructor who registers themselves enters the 6-digit code emailed to them before
/// any account exists — on Create account, a request to teach, an invitation and a course link.
const _learner = UserProfile(
  id: 'u1',
  name: 'Asha Verma',
  email: 'asha@syniastrolms.test',
  role: UserRole.student,
  descriptor: 'Learner',
);

const _joinPage = LmsJoinPage(name: 'Jyotish Vidya', slug: 'jyotish-vidya', open: true);

const _token = '3f9a1c7e20b84d65af0e2d19c8b73540e6a92f14bc385d70a1fe6b29d4c80713';
const _courseId = 'cmudqd8g30035mmgzwtgr0mcl';

void main() {
  late FakeAuthRepository repository;
  late FakeAdapter adapter;

  setUp(() {
    repository = FakeAuthRepository()
      ..accountVerification = true
      ..profile = _learner;
    adapter = FakeAdapter()
      ..handler = (options) async =>
          FakeAdapter.jsonResponse(const {'message': 'Not found.'}, status: 404);
  });

  Future<void> pump(WidgetTester tester) async {
    useSurface(tester);
    await tester.pumpWidget(await testApp(repository: repository, adapter: adapter));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  Future<void> go(WidgetTester tester, String route) async {
    await pump(tester);
    ProviderScope.containerOf(
      tester.element(find.byType(SyniastroApp)),
    ).read(routerProvider).go(route);
    await tester.pumpAndSettle();
  }

  /// Welcome → Create account → I want to learn.
  Future<void> openLearnerRegistration(WidgetTester tester) async {
    await pump(tester);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I want to learn'));
    await tester.pumpAndSettle();
  }

  Future<void> fillLearner(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), 'Asha Verma');
    await tester.enterText(find.byType(TextField).at(1), 'asha@syniastrolms.test');
    await tester.enterText(find.byType(TextField).at(2), 'syniastrolms123');
  }

  /// Through a join link to Jyotish Vidya's code step.
  Future<void> reachLearnerCode(WidgetTester tester) async {
    repository.joinPage = _joinPage;
    await go(tester, AppRoutes.registerFor('jyotish-vidya'));
    await fillLearner(tester);
    await tester.tap(find.widgetWithText(AppButton, 'Create account').last);
    await tester.pumpAndSettle();
  }

  Future<void> enterCode(WidgetTester tester, String action) async {
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.tap(find.widgetWithText(AppButton, action));
    await tester.pumpAndSettle();
  }

  group('Create account', () {
    testWidgets('with no link the form opens at once and looks nothing up', (tester) async {
      await openLearnerRegistration(tester);

      expect(find.text('Join ZuviloAI'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
      expect(repository.calls.where((c) => c.startsWith('lmsJoinPage')), isEmpty);
    });

    testWidgets('waits for the emailed code, then signs the learner in', (tester) async {
      await reachLearnerCode(tester);

      expect(repository.calls, contains('register:asha@syniastrolms.test@jyotish-vidya'));
      expect(find.text('Check your email'), findsOneWidget);
      expect(
        find.text(
          'We sent a 6-digit code to asha@syniastrolms.test. Enter it to finish joining '
          'Jyotish Vidya.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('The code works for'), findsOneWidget);
      expect(repository.token, isNull, reason: 'nothing that can sign in exists yet');
      expect(find.byType(AppNavBar), findsNothing);

      await enterCode(tester, 'Verify and create my account');

      expect(repository.calls, contains('verifyAccount:verification-1:123456'));
      expect(find.byType(AppNavBar), findsOneWidget, reason: 'the learner shell is up');
    });

    testWidgets('a wrong code is said on the field, and the step stays', (tester) async {
      repository.verifyFailure = const ValidationFailure(
        message: 'That code is not right. 4 tries left.',
        issues: [FieldIssue(field: 'code', message: 'That code is not right. 4 tries left.')],
      );
      await reachLearnerCode(tester);
      await enterCode(tester, 'Verify and create my account');

      expect(find.text('That code is not right. 4 tries left.'), findsOneWidget);
      expect(find.text('Check your email'), findsOneWidget);
      expect(repository.token, isNull);
    });

    testWidgets('a closed registration offers Start again, back to the details as typed', (
      tester,
    ) async {
      repository.verifyFailure = const NotFoundFailure(
        message: 'This registration is no longer open. Start again.',
      );
      await reachLearnerCode(tester);
      await enterCode(tester, 'Verify and create my account');

      expect(find.text('This registration is no longer open'), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, 'Start again'));
      await tester.pumpAndSettle();

      expect(find.text('Join Jyotish Vidya'), findsOneWidget);
      expect(find.text('Asha Verma'), findsOneWidget);
      expect(find.text('asha@syniastrolms.test'), findsOneWidget);
    });

    testWidgets('a new code can be asked for', (tester) async {
      await reachLearnerCode(tester);

      await tester.tap(find.widgetWithText(AppButton, 'Send a new code'));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('resendAccountCode:verification-1'));
      expect(find.text('A new code is on its way.'), findsOneWidget);
    });

    testWidgets('an invitation-only LMS says so and offers no form', (tester) async {
      repository.joinPage = _joinPage.copyWith(invitationOnly: true);
      await go(tester, AppRoutes.registerFor('jyotish-vidya'));

      expect(find.text('Invitation needed'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('an invitation-only refusal is named in the banner', (tester) async {
      repository
        ..joinPage = _joinPage
        ..failure = const InvitationRequiredFailure(
          message: 'This LMS adds learners by invitation only.',
        );
      await go(tester, AppRoutes.registerFor('jyotish-vidya'));
      await fillLearner(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Create account').last);
      await tester.pumpAndSettle();

      expect(find.text('Invitation needed'), findsOneWidget);
      expect(find.text('This LMS adds learners by invitation only.'), findsOneWidget);
    });
  });

  group('a request to teach', () {
    Future<void> fillInstructor(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField).at(0), 'Ravi Shastri');
      await tester.enterText(find.byType(TextField).at(2), 'ravi@example.test');
      await tester.enterText(find.byType(TextField).at(3), 'syniastrolms123');
      await tester.enterText(find.byType(TextField).at(4), 'syniastrolms123');
      await tester.ensureVisible(find.widgetWithText(AppButton, 'Submit registration'));
      await tester.tap(find.widgetWithText(AppButton, 'Submit registration'));
      await tester.pumpAndSettle();
    }

    testWidgets('without a link it reads the platform workspace and opens the form', (tester) async {
      repository.joinPage = _joinPage;
      await pump(tester);
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text("I'm an instructor"));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('lmsJoinPage:default'));
      expect(find.text('Teach at Jyotish Vidya'), findsOneWidget);
    });

    testWidgets('a teaching link opens the form; the code sends the request, nobody signs in', (
      tester,
    ) async {
      repository.joinPage = _joinPage;
      await go(tester, '/join/jyotish-vidya/teach');

      expect(find.byType(InstructorSignupScreen), findsOneWidget);
      expect(find.text('Teach at Jyotish Vidya'), findsOneWidget);

      await fillInstructor(tester);
      expect(repository.calls, contains('requestInstructorAccess:ravi@example.test@jyotish-vidya'));
      expect(
        find.text(
          'We sent a 6-digit code to ravi@example.test. Enter it to send your request to teach '
          'at Jyotish Vidya.',
        ),
        findsOneWidget,
      );

      await enterCode(tester, 'Verify and send my request');

      expect(find.byType(InstructorPendingScreen), findsOneWidget);
      expect(find.text('Registration submitted successfully.'), findsOneWidget);
      expect(repository.token, isNull, reason: 'nobody is signed in');
    });

    testWidgets('the server\'s issue on the title is shown on that field', (tester) async {
      repository
        ..joinPage = _joinPage
        ..failure = const ValidationFailure(
          message: 'Check the form.',
          issues: [FieldIssue(path: 'title', message: 'Keep the title under 120 characters.')],
        );
      await go(tester, '/join/jyotish-vidya/teach');
      await fillInstructor(tester);

      expect(find.text('Keep the title under 120 characters.'), findsOneWidget);
    });
  });

  group('the links an Admin sends', () {
    testWidgets('an invitation\'s new account waits for the code, then goes home', (tester) async {
      repository.invitationView = InvitationView(
        lms: const LmsSummary(name: 'Jyotish Vidya', slug: 'jyotish-vidya'),
        expiresAt: DateTime.utc(2030),
        open: true,
      );
      await go(tester, AppRoutes.invite(_token));
      await fillLearner(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Check your email'), findsOneWidget);
      await enterCode(tester, 'Verify and create my account');

      expect(find.byType(AppNavBar), findsOneWidget);
      expect(repository.token, isNotNull);
    });

    testWidgets('a course link\'s account waits for the code, then says why it was not enrolled', (
      tester,
    ) async {
      repository
        ..courseLinkView = const CourseLinkView(
          lms: LmsSummary(name: 'Jyotish Vidya', slug: 'jyotish-vidya'),
          course: CourseLinkCourse(id: _courseId, title: 'Class 10 Mathematics'),
          open: true,
        )
        ..courseJoinEnrolled = false
        ..courseJoinEnrolment = 'Enrolment in this LMS needs approval.';
      await go(tester, AppRoutes.courseEnrol(_courseId));
      await fillLearner(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Create account and enrol'));
      await tester.pumpAndSettle();

      expect(find.text('Check your email'), findsOneWidget);
      await enterCode(tester, 'Verify and create my account');

      expect(find.text('Enrolment in this LMS needs approval.'), findsOneWidget);
    });
  });
}
