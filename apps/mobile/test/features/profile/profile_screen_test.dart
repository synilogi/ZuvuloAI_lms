import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/profile/profile.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

UserProfile _staff() => const UserProfile(
  id: 'u_staff',
  name: 'Kavita Menon',
  email: 'admin@example.test',
  role: UserRole.admin,
  descriptor: 'Admin',
);

void main() {
  late FakeAdapter adapter;
  late List<Uri> opened;

  setUp(() {
    adapter = FakeAdapter();
    opened = [];
  });

  /// Answers by path: the profile reads the activity feed, the rank ladder, the learner's courses
  /// and certificates together.
  void answering({Object? activity, Object? ladder, Object? error, int status = 200}) {
    adapter.handler = (options) async {
      if (error != null) return FakeAdapter.jsonResponse(error, status: status);
      if (options.path.contains('rank-ladder')) {
        return FakeAdapter.jsonResponse(ladder ?? fixture('learning/rank-ladder.json'));
      }
      if (options.path == '/learning/courses') {
        return FakeAdapter.jsonResponse(fixture('learning/courses.json'));
      }
      if (options.path == '/learning/certificates') {
        return FakeAdapter.jsonResponse(fixture('learning/certificates.json'));
      }
      return FakeAdapter.jsonResponse(activity ?? fixture('learning/activity.json'));
    };
  }

  Future<GoRouter> pumpProfile(WidgetTester tester, {UserProfile? signedInAs}) => pumpPublicRouter(
    tester,
    adapter: adapter,
    signedInAs: signedInAs ?? learner(),
    initialLocation: AppRoutes.profile,
    size: const Size(400, 2000),
    routes: [
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const Scaffold(body: SafeArea(child: ProfileScreen())),
      ),
      GoRoute(
        path: AppRoutes.profileSettings,
        builder: (_, _) => const Scaffold(body: SafeArea(child: AppSettingsScreen())),
      ),
      GoRoute(path: AppRoutes.notificationPreferences, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.staffNotificationPreferences, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.staffProfileSettings, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.help, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.staffHelp, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.privacy, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.terms, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.ranks, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.myLearningPattern, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.certificates, builder: (_, _) => const Placeholder()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, _) => const Placeholder()),
      GoRoute(
        path: AppRoutes.profileDeleteAccount,
        builder: (_, _) => const Scaffold(body: SafeArea(child: DeleteAccountScreen())),
      ),
    ],
    openExternalLink: (link) async => opened.add(link),
  );

  testWidgets('the profile is who the academy says is signed in', (tester) async {
    answering();

    await pumpProfile(tester);
    await tester.pumpAndSettle();

    expect(find.text('Ananya Rao'), findsOneWidget);
    expect(find.text('learner@example.test'), findsOneWidget);
    expect(find.text('Learner'), findsOneWidget);
    expect(find.text('Beginner'), findsWidgets, reason: 'the descriptor, as the web shows it');
  });

  testWidgets('a learner sees their standing and what they have been doing', (tester) async {
    answering();

    await pumpProfile(tester);
    await tester.pumpAndSettle();

    expect(find.text('Your standing'), findsOneWidget);
    expect(find.text('Rank I · Beginner'), findsOneWidget);
    expect(find.text('Recently'), findsOneWidget);
    expect(find.text('Star and sub lords'), findsOneWidget);
    expect(find.text('Lesson completed'), findsWidgets);
    expect(find.textContaining('minutes this week'), findsOneWidget);
  });

  testWidgets('a learner\'s figures are the server\'s own lists, counted, and open them', (
    tester,
  ) async {
    answering();

    final router = await pumpProfile(tester);
    await tester.pumpAndSettle();

    Finder labelled(String label) =>
        find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label);
    // Two active enrolments, one completed, one certificate issued.
    expect(labelled('In progress: 2'), findsOneWidget);
    expect(labelled('Completed: 1'), findsOneWidget);
    expect(labelled('Certificates: 1'), findsOneWidget);

    await tester.tap(labelled('Completed: 1'));
    await tester.pumpAndSettle();
    expect(locationOf(router), AppRoutes.myLearning(MyLearningTab.completed));
  });

  testWidgets('a staff member sees neither — those routes are the learner\'s', (tester) async {
    answering();

    await pumpProfile(tester, signedInAs: _staff());
    await tester.pumpAndSettle();

    expect(find.text('Kavita Menon'), findsOneWidget);
    expect(find.text('Admin'), findsWidgets);
    expect(find.text('Your standing'), findsNothing);
    expect(find.text('Recently'), findsNothing);
    expect(
      adapter.requests.map((r) => r.path),
      isNot(contains('/learning/activity')),
      reason: 'the route refuses anyone who is not a learner',
    );
  });

  testWidgets('About names the version the first time it is opened', (tester) async {
    // The version used to come from a provider nothing had loaded yet, so the first About had none
    // (LIVE E2E PROF-003).
    PackageInfo.setMockInitialValues(
      appName: 'ZuviloAI',
      packageName: 'com.shubhlms.mobile.dev',
      version: '1.0.0-dev',
      buildNumber: '7',
      buildSignature: '',
    );
    answering();
    await pumpProfile(tester);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('About this app'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Wholly on screen, not just its first pixels: the tap lands on the row's middle.
    await tester.ensureVisible(find.text('About this app'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About this app'));
    await tester.pumpAndSettle();

    expect(find.text('Version 1.0.0-dev (7)'), findsOneWidget);
  });

  testWidgets('changing a password is the reset link, prefilled — the only door there is', (
    tester,
  ) async {
    answering();

    final router = await pumpProfile(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'Change password'));
    await tester.pumpAndSettle();

    expect(locationOf(router), startsWith(AppRoutes.forgotPassword));
    expect(locationOf(router), contains(Uri.encodeQueryComponent('learner@example.test')));
  });

  testWidgets('the links go where they say', (tester) async {
    answering();

    final router = await pumpProfile(tester);
    await tester.pumpAndSettle();

    Future<void> tapLink(String label) async {
      await tester.scrollUntilVisible(
        find.text(label),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    await tapLink('App settings');
    expect(locationOf(router), AppRoutes.profileSettings);
    router.go(AppRoutes.profile);
    await tester.pumpAndSettle();

    await tapLink('Notification settings');
    expect(locationOf(router), AppRoutes.notificationPreferences);
  });

  testWidgets('signing out asks what it will do first', (tester) async {
    answering();

    await pumpProfile(tester);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(AppButton, 'Sign out'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(AppButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsOneWidget);
    expect(find.textContaining('cached pages on this device are removed'), findsOneWidget);
  });

  testWidgets('a learner with no activity yet is told what will appear', (tester) async {
    answering(activity: const {'week': <Object>[], 'events': <Object>[]});

    await pumpProfile(tester);
    await tester.pumpAndSettle();

    expect(find.text('What you do in your courses shows up here.'), findsOneWidget);
  });

  Future<void> tapScrolled(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 200, scrollable: find.byType(Scrollable).first);
    // Partly in view is enough to stop scrolling; the whole target must be in view to tap it.
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('contact support writes to the academy’s help address', (tester) async {
    answering();
    await pumpProfile(tester);
    await tester.pumpAndSettle();

    await tapScrolled(tester, find.text('Contact support'));

    expect(opened.single.scheme, 'mailto');
    expect(opened.single.path, 'synilogicteam@gmail.com');
  });

  group('deleting the account (Google Play policy)', () {
    testWidgets('a learner reaches the page that says what goes and what stays', (tester) async {
      answering();
      final router = await pumpProfile(tester);
      await tester.pumpAndSettle();

      await tapScrolled(tester, find.widgetWithText(AppButton, 'Delete account'));

      expect(locationOf(router), AppRoutes.profileDeleteAccount);
      expect(find.text('What is deleted'), findsOneWidget);
      expect(find.text('What is kept'), findsOneWidget);
    });

    testWidgets('a staff member is told their academy closes the account', (tester) async {
      answering();
      final router = await pumpProfile(tester, signedInAs: _staff());
      await tester.pumpAndSettle();

      await tapScrolled(tester, find.widgetWithText(AppButton, 'Delete account'));

      expect(locationOf(router), AppRoutes.profile);
      expect(find.text('Deleting a staff account'), findsOneWidget);
    });

    testWidgets('the password is asked, sent, and a refusal is shown in the dialog', (
      tester,
    ) async {
      answering();
      final router = await pumpProfile(tester);
      await tester.pumpAndSettle();
      router.go(AppRoutes.profileDeleteAccount);
      await tester.pumpAndSettle();

      await tapScrolled(tester, find.widgetWithText(AppButton, 'Delete my account'));
      expect(find.text('Delete your account?'), findsOneWidget);

      // Nothing is sent until the acknowledgement is ticked and a password given.
      await tester.tap(find.text('I understand my account is deleted for good.'));
      await tester.pump();
      await tester.tap(find.widgetWithText(AppButton, 'Delete my account').last);
      await tester.pumpAndSettle();
      expect(adapter.requests.where((r) => r.path.endsWith('/auth/delete-account')), isEmpty);

      adapter.handler = (options) async =>
          FakeAdapter.jsonResponse({'message': 'Your password is not correct.'}, status: 403);
      await tester.enterText(find.byType(TextField).last, 'wrong-password');
      await tester.tap(find.widgetWithText(AppButton, 'Delete my account').last);
      await tester.pumpAndSettle();

      final sent = adapter.requests.lastWhere((r) => r.path.endsWith('/auth/delete-account'));
      expect(sent.method, 'POST');
      expect(sent.data, {'password': 'wrong-password'});
      expect(find.text('Your password is not correct.'), findsOneWidget);
      expect(find.text('Delete your account?'), findsOneWidget, reason: 'the dialog stays open');
    });
  });

  group('app settings', () {
    testWidgets('the appearance choices are on screen and change at once', (tester) async {
      answering();

      final router = await pumpProfile(tester);
      await tester.pumpAndSettle();
      router.go(AppRoutes.profileSettings);
      await tester.pumpAndSettle();

      expect(find.text('Match my phone'), findsOneWidget);
      expect(find.text('Reduce motion'), findsOneWidget);
      expect(find.text('Text size'), findsOneWidget);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<AppRadioGroup<ThemeMode>>(find.byType(AppRadioGroup<ThemeMode>)).value,
        ThemeMode.dark,
      );
    });

    testWidgets('clearing the cached images is local, and says so', (tester) async {
      answering();

      final router = await pumpProfile(tester);
      await tester.pumpAndSettle();
      router.go(AppRoutes.profileSettings);
      await tester.pumpAndSettle();

      expect(
        find.text('Frees space on this device. Nothing is removed from your LMS.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(AppButton, 'Clear cached images'), findsOneWidget);
    });
  });
}
