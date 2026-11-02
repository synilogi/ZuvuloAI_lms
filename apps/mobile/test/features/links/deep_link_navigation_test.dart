import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/core/links/deep_link.dart';
import 'package:syniastrolms_mobile/core/push/push_hint.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

/// A link resolved by [resolveDeepLink] has to be a route the app's own router actually answers. These
/// tests open the resolved route and check the right screen arrives — signed out for the public ones,
/// and signed in for the reader's own.
const _host = 'zuviloai.com';
const _credential = 'SA-JY-2026-00142';
const _id = 'cmumqihbi001rmmos6cypzr5m';

/// A reset token as the API issues it: 64 hex characters.
const _realToken = '3f9a1c7e20b84d65af0e2d19c8b73540e6a92f14bc385d70a1fe6b29d4c80713';

UserProfile _learner() => const UserProfile(
  id: 'u_learner',
  name: 'Ananya Rao',
  email: 'ananya@example.test',
  role: UserRole.student,
  descriptor: 'Beginner',
);

void main() {
  late FakeAdapter adapter;

  setUp(() {
    adapter = FakeAdapter();
    adapter.handler = (options) async => FakeAdapter.jsonResponse(const <String, Object?>{});
  });

  /// A router with a marker screen per route, so a test can see which one a link reached.
  Future<GoRouter> open(WidgetTester tester, String route, {UserProfile? signedInAs}) async {
    Widget marker(String name) => Scaffold(body: Center(child: Text('screen:$name')));
    final router = await pumpPublicRouter(
      tester,
      adapter: adapter,
      signedInAs: signedInAs,
      initialLocation: route,
      routes: [
        GoRoute(path: AppRoutes.welcome, builder: (_, _) => marker('welcome')),
        GoRoute(path: AppRoutes.resetPasswordPattern, builder: (_, _) => marker('reset')),
        GoRoute(path: AppRoutes.verifyCredentialPattern, builder: (_, _) => marker('verify')),
        GoRoute(path: AppRoutes.catalogCoursePattern, builder: (_, _) => marker('catalog')),
        GoRoute(path: AppRoutes.learnCoursePattern, builder: (_, _) => marker('learn')),
        GoRoute(path: AppRoutes.learnLessonPattern, builder: (_, _) => marker('lesson')),
        GoRoute(path: AppRoutes.notifications, builder: (_, _) => marker('notifications')),
        GoRoute(path: AppRoutes.notificationPattern, builder: (_, _) => marker('notification')),
        GoRoute(path: AppRoutes.invitePattern, builder: (_, _) => marker('invite')),
        GoRoute(path: AppRoutes.courseEnrolPattern, builder: (_, _) => marker('enrol')),
      ],
    );
    await tester.pumpAndSettle();
    return router;
  }

  group('a link the academy sent reaches its screen', () {
    testWidgets('a reset link, without signing in', (tester) async {
      final link = resolveDeepLink('https://$_host/reset-password/$_realToken');
      await open(tester, link.route!);

      expect(find.text('screen:reset'), findsOneWidget);
    });

    testWidgets('a verification link, without signing in', (tester) async {
      final link = resolveDeepLink('https://$_host/verify/$_credential');
      final router = await open(tester, link.route!);

      expect(find.text('screen:verify'), findsOneWidget);
      expect(locationOf(router), '/verify/$_credential');
    });

    testWidgets('a course link reaches the catalogue entry', (tester) async {
      final link = resolveDeepLink('https://$_host/courses/foundations-of-vedic-astrology');
      await open(tester, link.route!);

      expect(find.text('screen:catalog'), findsOneWidget);
    });

    testWidgets('a learning link reaches the course, for a signed-in reader', (tester) async {
      final link = resolveDeepLink('https://$_host/learn/$_id');
      expect(link.needsSignIn, isTrue);

      await open(tester, link.route!, signedInAs: _learner());

      expect(find.text('screen:learn'), findsOneWidget);
    });

    testWidgets('a lesson link reaches the lesson', (tester) async {
      final link = resolveDeepLink('https://$_host/learn/$_id/lessons/${_id}x');
      await open(tester, link.route!, signedInAs: _learner());

      expect(find.text('screen:lesson'), findsOneWidget);
    });

    testWidgets('a notification link reaches that notification', (tester) async {
      final link = resolveDeepLink('https://$_host/notifications/$_id');
      final router = await open(tester, link.route!, signedInAs: _learner());

      expect(find.text('screen:notification'), findsOneWidget);
      expect(locationOf(router), '/notifications/$_id');
    });

    testWidgets('an invitation, without signing in', (tester) async {
      final link = resolveDeepLink('https://$_host/invite/$_realToken');
      await open(tester, link.route!);

      expect(find.text('screen:invite'), findsOneWidget);
    });

    testWidgets('a course link, signed in or not', (tester) async {
      final link = resolveDeepLink('https://$_host/courses/$_id/enroll');
      final router = await open(tester, link.route!, signedInAs: _learner());

      expect(find.text('screen:enrol'), findsOneWidget);
      expect(locationOf(router), '/enrol/$_id');
    });

    testWidgets('the bare host reaches the welcome screen', (tester) async {
      final link = resolveDeepLink('https://$_host/');
      await open(tester, link.route!);

      expect(find.text('screen:welcome'), findsOneWidget);
    });
  });

  group('a push reaches the notification, and lets the API decide the rest', () {
    testWidgets('tapping one opens that notification\'s own screen', (tester) async {
      final hint = readPushHint(const {'notificationId': _id, 'category': 'live'})!;
      final router = await open(tester, hint.route, signedInAs: _learner());

      expect(find.text('screen:notification'), findsOneWidget);
      expect(
        locationOf(router),
        '/notifications/$_id',
        reason:
            'a live push does not jump to the class; the notification carries the academy\'s '
            'own action',
      );
    });
  });

  group('every route a link can resolve to is one the app answers', () {
    test('and none of them is a pattern with an unfilled parameter', () {
      final resolved = [
        resolveDeepLink('https://$_host/'),
        resolveDeepLink('https://$_host/reset-password/$_realToken'),
        resolveDeepLink('https://$_host/verify/$_credential'),
        resolveDeepLink('https://$_host/courses/a-course'),
        resolveDeepLink('https://$_host/learn/$_id'),
        resolveDeepLink('https://$_host/learn/$_id/lessons/${_id}x'),
        resolveDeepLink('https://$_host/notifications'),
        resolveDeepLink('https://$_host/notifications/$_id'),
        resolveDeepLink('https://$_host/invite/$_realToken'),
        resolveDeepLink('https://$_host/courses/$_id/enroll'),
      ];

      for (final link in resolved) {
        expect(link.isFollowed, isTrue);
        expect(link.route, startsWith('/'));
        expect(link.route, isNot(contains(':')), reason: link.route);
      }
    });
  });
}
