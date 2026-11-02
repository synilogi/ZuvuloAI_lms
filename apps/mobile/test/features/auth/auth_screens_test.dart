import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/shared/widgets/navigation/app_nav_bar.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';

const _learner = UserProfile(
  id: 'u1',
  name: 'Asha Verma',
  email: 'asha@syniastrolms.test',
  role: UserRole.student,
  descriptor: 'Learner',
);

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  Future<void> pump(WidgetTester tester, {Flavor flavor = Flavor.dev}) async {
    useSurface(tester);
    await tester.pumpWidget(await testApp(repository: repository, flavor: flavor));
    await tester.pump();
    await tester.pump();
  }

  Future<void> openSignIn(WidgetTester tester) async {
    await pump(tester);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
  }

  group('session state decides the screen', () {
    testWidgets('restoring shows the splash until /auth/me answers', (tester) async {
      repository
        ..token = 'stored'
        ..profile = _learner
        ..meGate = Completer<void>();
      useSurface(tester);
      await tester.pumpWidget(await testApp(repository: repository));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);

      repository.meGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(AppNavBar), findsOneWidget, reason: 'the learner shell is up');
    });

    testWidgets('offline shows the splash with Retry and keeps the token', (tester) async {
      repository
        ..token = 'stored'
        ..meFailure = const NetworkFailure(NetworkProblem.offline);
      await pump(tester);

      expect(find.text("Can't reach ZuviloAI"), findsOneWidget);
      expect(repository.token, 'stored');

      repository
        ..meFailure = null
        ..profile = _learner;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.byType(AppNavBar), findsOneWidget);
    });

    testWidgets('an expired session lands on sign-in with the session-ended message', (
      tester,
    ) async {
      repository
        ..token = 'stale'
        ..meFailure = const UnauthenticatedFailure();
      await pump(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Your session ended. Sign in again.'), findsOneWidget);
    });

    testWidgets('a refused account shows the server\'s message on sign-in', (tester) async {
      repository
        ..token = 'stored'
        ..meFailure = const ForbiddenFailure(
          message: 'This account is suspended. Contact your admin to continue.',
        );
      await pump(tester);

      expect(
        find.text('This account is suspended. Contact your admin to continue.'),
        findsOneWidget,
      );
    });

    testWidgets('a super admin is sent to the web and holds no token', (tester) async {
      repository.profile = const UserProfile(
        id: 'sa',
        name: 'Platform',
        email: 'ops@syniastrolms.test',
        role: UserRole.superadmin,
        descriptor: 'Super admin',
      );
      repository.token = 'stored';
      await pump(tester);

      expect(find.byType(UnsupportedRoleScreen), findsOneWidget);
      expect(find.text('Platform administration is on the web'), findsOneWidget);
      expect(repository.token, isNull);
    });
  });

  group('sign in', () {
    testWidgets('validates before sending anything', (tester) async {
      await openSignIn(tester);

      await tester.tap(find.widgetWithText(AppButton, 'Sign in').last);
      await tester.pump();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      expect(repository.calls, isNot(contains(startsWith('signIn'))));
    });

    testWidgets('signs in and lands in the app', (tester) async {
      repository.profile = _learner;
      await openSignIn(tester);

      await tester.enterText(find.byType(TextField).first, 'asha@syniastrolms.test');
      await tester.enterText(find.byType(TextField).last, 'syniastrolms123');
      await tester.tap(find.widgetWithText(AppButton, 'Sign in').last);
      await tester.pumpAndSettle();

      expect(find.byType(AppNavBar), findsOneWidget, reason: 'the learner shell is up');
      expect(repository.calls, contains('signIn:asha@syniastrolms.test'));
    });

    testWidgets('shows the server\'s refusal and stays on the form', (tester) async {
      repository.failure = const UnauthenticatedFailure(message: 'Incorrect email or password.');
      await openSignIn(tester);

      await tester.enterText(find.byType(TextField).first, 'asha@syniastrolms.test');
      await tester.enterText(find.byType(TextField).last, 'wrong-password');
      await tester.tap(find.widgetWithText(AppButton, 'Sign in').last);
      await tester.pumpAndSettle();

      expect(find.text("We couldn't sign you in."), findsOneWidget);
      expect(find.text('Incorrect email or password.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('a suspended LMS is said plainly, not as a failed sign-in', (tester) async {
      repository.failure = const AccountClosedFailure(
        archived: false,
        message: 'This account is suspended. Contact ZuviloAI support to restore access.',
      );
      await openSignIn(tester);

      await tester.enterText(find.byType(TextField).first, 'asha@syniastrolms.test');
      await tester.enterText(find.byType(TextField).last, 'right-password');
      await tester.tap(find.widgetWithText(AppButton, 'Sign in').last);
      await tester.pumpAndSettle();

      expect(find.text('This account is suspended'), findsOneWidget);
      expect(find.text("We couldn't sign you in."), findsNothing);
      expect(
        find.text('This account is suspended. Contact ZuviloAI support to restore access.'),
        findsOneWidget,
      );
    });

    testWidgets('maps server issues onto the fields', (tester) async {
      repository.failure = const ValidationFailure(
        message: 'Check the request and try again.',
        issues: [FieldIssue(path: 'password', message: 'Password must be at least 8 characters.')],
      );
      await openSignIn(tester);

      await tester.enterText(find.byType(TextField).first, 'asha@syniastrolms.test');
      await tester.enterText(find.byType(TextField).last, 'short');
      await tester.tap(find.widgetWithText(AppButton, 'Sign in').last);
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters.'), findsOneWidget);
    });
  });

  group('register', () {
    /// A join link opened from outside the app → the form for what it names.
    Future<void> openJoinLink(WidgetTester tester) async {
      await pump(tester);
      GoRouter.of(tester.element(find.byType(WelcomeScreen))).go('/join/jyotish-vidya');
      await tester.pumpAndSettle();
    }

    /// Welcome → Create account → I want to learn.
    Future<void> openWithoutLink(WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I want to learn'));
      await tester.pumpAndSettle();
    }

    testWidgets('with no link the form opens at once, under the brand, looking nothing up', (
      tester,
    ) async {
      await openWithoutLink(tester);

      expect(find.text('Join ZuviloAI'), findsOneWidget);
      expect(find.text('LMS address'), findsNothing);
      expect(find.byType(TextField), findsNWidgets(3));
      expect(repository.calls.where((c) => c.startsWith('lmsJoinPage')), isEmpty);
    });

    testWidgets('with no link the learner is created with no address', (tester) async {
      repository.profile = _learner;
      await openWithoutLink(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Asha Verma');
      await tester.enterText(find.byType(TextField).at(1), 'asha@syniastrolms.test');
      await tester.enterText(find.byType(TextField).at(2), 'syniastrolms123');
      await tester.tap(find.widgetWithText(AppButton, 'Create account').last);
      await tester.pumpAndSettle();

      expect(find.byType(AppNavBar), findsOneWidget);
      expect(repository.calls, contains('register:asha@syniastrolms.test@'));
    });

    testWidgets('a join link names the LMS from the server, then creates the learner there', (
      tester,
    ) async {
      repository
        ..profile = _learner
        ..joinPage = const LmsJoinPage(name: 'Jyotish Vidya', slug: 'jyotish-vidya', open: true);
      await openJoinLink(tester);

      expect(repository.calls, contains('lmsJoinPage:jyotish-vidya'));
      expect(find.text('Join Jyotish Vidya'), findsOneWidget);
      expect(find.text('LMS address'), findsNothing, reason: 'the address is not editable');

      await tester.enterText(find.byType(TextField).at(0), 'Asha Verma');
      await tester.enterText(find.byType(TextField).at(1), 'asha@syniastrolms.test');
      await tester.enterText(find.byType(TextField).at(2), 'syniastrolms123');
      await tester.tap(find.widgetWithText(AppButton, 'Create account').last);
      await tester.pumpAndSettle();

      expect(find.byType(AppNavBar), findsOneWidget);
      expect(repository.calls, contains('register:asha@syniastrolms.test@jyotish-vidya'));
    });

    testWidgets('a join link for no LMS says so and offers no form', (tester) async {
      await openJoinLink(tester);

      expect(find.text('No LMS has this address'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('a full LMS is explained in the app\'s words', (tester) async {
      repository
        ..joinPage = const LmsJoinPage(name: 'Jyotish Vidya', slug: 'jyotish-vidya', open: true)
        ..failure = const EntitlementFailure(
          EntitlementProblem.limitReached,
          message: 'This LMS has reached its learner limit.',
        );
      await openJoinLink(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Asha Verma');
      await tester.enterText(find.byType(TextField).at(1), 'asha@syniastrolms.test');
      await tester.enterText(find.byType(TextField).at(2), 'syniastrolms123');
      await tester.tap(find.widgetWithText(AppButton, 'Create account').last);
      await tester.pumpAndSettle();

      expect(find.text("This LMS isn't accepting new learners right now."), findsOneWidget);
    });
  });

  group('create account', () {
    Future<void> openAccountTypes(WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
    }

    testWidgets('offers learner and instructor registration, and no new academy', (tester) async {
      await openAccountTypes(tester);

      expect(find.text('I want to learn'), findsOneWidget);
      expect(find.text('I want to teach — start my LMS'), findsNothing);
      expect(find.text("I'm an instructor"), findsOneWidget);

      // The instructor card now opens instructor registration (D34).
      await tester.tap(find.text("I'm an instructor"));
      await tester.pumpAndSettle();
      expect(find.byType(InstructorSignupScreen), findsOneWidget);
    });
  });

  group('instructor registration (D34)', () {
    Future<void> openInstructorForm(WidgetTester tester) async {
      repository.joinPage = const LmsJoinPage(
        name: 'Jyotish Vidya',
        slug: 'jyotish-vidya',
        open: true,
      );
      await pump(tester);
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text("I'm an instructor"));
      await tester.pumpAndSettle();
    }

    testWidgets('the instructor card opens registration for the platform workspace', (
      tester,
    ) async {
      await openInstructorForm(tester);

      expect(find.byType(InstructorSignupScreen), findsOneWidget);
      expect(find.text('Teach at Jyotish Vidya'), findsOneWidget);
      expect(repository.calls, contains('lmsJoinPage:default'));
    });

    testWidgets('checks the form before sending anything', (tester) async {
      await openInstructorForm(tester);
      await tester.ensureVisible(find.widgetWithText(AppButton, 'Submit registration'));
      await tester.tap(find.widgetWithText(AppButton, 'Submit registration'));
      await tester.pumpAndSettle();

      expect(repository.calls.where((c) => c.startsWith('requestInstructorAccess')), isEmpty);
    });

    testWidgets('submits, signs nobody in, and says the account waits for the Admin', (
      tester,
    ) async {
      await openInstructorForm(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Ravi Shastri');
      await tester.enterText(find.byType(TextField).at(2), 'ravi@example.test');
      await tester.enterText(find.byType(TextField).at(3), 'syniastrolms123');
      await tester.enterText(find.byType(TextField).at(4), 'syniastrolms123');
      await tester.ensureVisible(find.widgetWithText(AppButton, 'Submit registration'));
      await tester.tap(find.widgetWithText(AppButton, 'Submit registration'));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('requestInstructorAccess:ravi@example.test@jyotish-vidya'));
      expect(find.byType(InstructorPendingScreen), findsOneWidget);
      expect(find.text('Registration submitted successfully.'), findsOneWidget);
      expect(find.textContaining('pending Admin approval'), findsOneWidget);
      expect(repository.token, isNull, reason: 'nobody is signed in');
      expect(repository.calls.where((c) => c.startsWith('signIn')), isEmpty);

      await tester.tap(find.widgetWithText(AppButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('signing in before approval says so, in the server\'s words', (tester) async {
      repository.failure = const InstructorApprovalFailure(
        rejected: false,
        message: 'Your instructor account is pending Admin approval.',
      );
      await openSignIn(tester);
      await tester.enterText(find.byType(TextField).at(0), 'ravi@example.test');
      await tester.enterText(find.byType(TextField).at(1), 'syniastrolms123');
      await tester.tap(find.widgetWithText(AppButton, 'Sign in').last);
      await tester.pumpAndSettle();

      expect(find.text('Waiting for Admin approval'), findsOneWidget);
      expect(find.text('Your instructor account is pending Admin approval.'), findsOneWidget);
      expect(find.byType(AppNavBar), findsNothing);
    });

    testWidgets('a rejected registration is told plainly', (tester) async {
      repository.failure = const InstructorApprovalFailure(
        rejected: true,
        message: 'Your instructor registration was not approved by the LMS Admin.',
      );
      await openSignIn(tester);
      await tester.enterText(find.byType(TextField).at(0), 'ravi@example.test');
      await tester.enterText(find.byType(TextField).at(1), 'syniastrolms123');
      await tester.tap(find.widgetWithText(AppButton, 'Sign in').last);
      await tester.pumpAndSettle();

      expect(find.text('Registration not approved'), findsOneWidget);
    });
  });

  group('forgot password', () {
    testWidgets('shows the same confirmation whether or not the account exists', (tester) async {
      await openSignIn(tester);
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'nobody@syniastrolms.test');
      await tester.tap(find.widgetWithText(AppButton, 'Send link').last);
      await tester.pumpAndSettle();

      expect(find.text('Check your email'), findsOneWidget);
      expect(
        find.text("If an account exists for that email, we've sent a link. It works for one hour."),
        findsOneWidget,
      );
    });
  });

  testWidgets('signing out from the profile tab returns to the welcome screen', (tester) async {
    repository
      ..token = 'stored'
      ..profile = _learner;
    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: find.byType(AppNavBar), matching: find.text('Profile')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Asha Verma'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithText(AppButton, 'Sign out'),
      200,
      // The page itself — the activity card inside it has a scrollable of its own.
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(AppButton, 'Sign out'));
    await tester.pumpAndSettle();
    // Signing out says what it removes from the device first (§22.5).
    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(AppDialog), matching: find.text('Sign out')));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(repository.token, isNull);
  });
}
