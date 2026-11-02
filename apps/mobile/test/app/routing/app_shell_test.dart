import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syniastrolms_mobile/app/routing/nav_history.dart';
import 'package:syniastrolms_mobile/app/routing/routes.dart';
import 'package:syniastrolms_mobile/app/routing/shells/app_shell.dart';
import 'package:syniastrolms_mobile/core/connectivity/connectivity_service.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/shared/entitlements/entitlements.dart';
import 'package:syniastrolms_mobile/shared/widgets/navigation/app_nav_bar.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_repository.dart';

UserProfile _profile(UserRole role, {List<PermissionKey>? permissions}) => UserProfile(
  id: 'u1',
  name: role == UserRole.student ? 'Asha Verma' : 'Kavita Menon',
  email: 'a@syniastrolms.test',
  role: role,
  descriptor: 'x',
  // An academy admin is granted every key, as `permissions:backfill` leaves one.
  permissions:
      permissions ??
      (role == UserRole.admin
          ? PermissionKey.values.where((k) => k != PermissionKey.unknown).toList()
          : const []),
);

/// The academy's plan as the shell is told it, without a network.
class _StubPlan extends AcademyPlanNotifier {
  _StubPlan(this._plan);

  final AcademyPlan? _plan;

  @override
  Future<AcademyPlan?> build() async => _plan;
}

/// Plans enforced; the plan serves courses and assessments, and live classes were on the last one.
const _starterPlan = AcademyPlan(
  enforced: true,
  status: SubscriptionState.active,
  features: [FeatureKey.coursesManage, FeatureKey.assessmentsManage],
);
const _lapsedPlan = AcademyPlan(
  enforced: true,
  status: SubscriptionState.expired,
  restricted: true,
  lastFeatures: [FeatureKey.liveClasses, FeatureKey.coursesManage],
);

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  String locationOf(WidgetTester tester) => GoRouter.of(
    tester.element(find.byType(Scaffold).first),
  ).routerDelegate.currentConfiguration.uri.toString();

  Future<void> pumpSignedIn(
    WidgetTester tester,
    UserRole role, {
    Size size = const Size(400, 800),
    List<PermissionKey>? permissions,
    List<Override> overrides = const [],
  }) async {
    repository
      ..profile = _profile(role, permissions: permissions)
      ..token = 'stored';
    useSurface(tester, size: size);
    await tester.pumpWidget(await testApp(repository: repository, overrides: overrides));
    await tester.pumpAndSettle();
  }

  group('home header', () {
    for (final (role, first, profileRoute) in [
      (UserRole.student, 'Asha', '/profile'),
      (UserRole.admin, 'Kavita', '/staff/profile'),
    ]) {
      testWidgets(
        '${role.name}: the first tab greets by first name; the avatar opens the profile',
        (tester) async {
          await pumpSignedIn(tester, role);
          final header = find.byType(AppBar);
          expect(
            find.descendant(of: header, matching: find.textContaining(', $first')),
            findsOneWidget,
          );
          expect(
            find.descendant(of: header, matching: find.text('x')),
            findsOneWidget,
            reason: 'the descriptor, as the server sends it',
          );
          await tester.tap(find.byType(ProfileAvatarButton));
          await tester.pumpAndSettle();
          expect(locationOf(tester), profileRoute);
          expect(find.descendant(of: header, matching: find.text('Profile')), findsOneWidget);
          // Profile is the last button: the learner's own tab, or the staff "More" it opens from.
          final bar = tester.widget<AppNavBar>(find.byType(AppNavBar));
          expect(bar.selectedIndex, bar.destinations.length - 1);
        },
      );
    }
  });

  group('adaptive navigation (§20)', () {
    testWidgets('a phone shows the bottom navigation bar', (tester) async {
      await pumpSignedIn(tester, UserRole.student);

      expect(find.byType(AppNavBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('a tablet shows the rail instead', (tester) async {
      await pumpSignedIn(tester, UserRole.student, size: const Size(900, 1000));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(AppNavBar), findsNothing);
    });

    testWidgets('a wide window extends the rail', (tester) async {
      await pumpSignedIn(tester, UserRole.student, size: const Size(1200, 900));

      expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).extended, isTrue);
    });
  });

  group('learner shell', () {
    AppNavBar bar(WidgetTester tester) => tester.widget<AppNavBar>(find.byType(AppNavBar));
    Finder inBar(String label) =>
        find.descendant(of: find.byType(AppNavBar), matching: find.text(label));

    testWidgets('has Home, Courses, Live, Tests and Profile, and no More', (tester) async {
      await pumpSignedIn(tester, UserRole.student);

      for (final label in ['Home', 'Courses', 'Live', 'Tests', 'Profile']) {
        expect(inBar(label), findsOneWidget, reason: label);
      }
      expect(inBar('More'), findsNothing);
      expect(bar(tester).destinations, hasLength(5));
    });

    testWidgets('switching tabs changes the screen and keeps each tab\'s stack', (tester) async {
      await pumpSignedIn(tester, UserRole.student);

      await tester.tap(inBar('Live'));
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/live');

      await tester.tap(inBar('Tests'));
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/assessments');

      await tester.tap(inBar('Profile'));
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/profile');

      await tester.tap(inBar('Courses'));
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/explore');

      await tester.tap(inBar('Home'));
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/home');
    });

    testWidgets('Tests holds quizzes and assignments, one switch apart', (tester) async {
      await pumpSignedIn(tester, UserRole.student);
      final appBarBack = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(BackButton),
      );

      await tester.tap(inBar('Tests'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppFilterChip, 'Assignments'));
      await tester.pumpAndSettle();

      expect(locationOf(tester), '/assignments');
      expect(bar(tester).selectedIndex, 3, reason: 'still the Tests tab');
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Assignments')),
        findsOneWidget,
      );
      expect(appBarBack, findsNothing, reason: 'a half of the tab, not a page beneath it');

      await tester.tap(find.widgetWithText(AppFilterChip, 'Tests'));
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/assessments');
    });
  });

  group('staff shell', () {
    testWidgets('an instructor is offered what the backend lets them have', (tester) async {
      await pumpSignedIn(tester, UserRole.instructor);

      // The learner's order: Home, Courses, Live, then the instructor's own Review.
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Courses'), findsWidgets);
      expect(find.text('Live'), findsWidgets);
      expect(find.text('Review'), findsWidgets);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('Students'), findsOneWidget);
      // instructors.view, reports.view and certificates.issue are staff keys.
      expect(find.text('Instructors'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Certificates'), findsOneWidget);
      // Billing is requirePermission('settings.view') — admins only.
      expect(find.text('Billing'), findsNothing);
    });

    testWidgets('an admin with no grants still gets a usable shell', (tester) async {
      // NavigationBar needs two destinations; the first tab is kept so the shell can render while
      // the grants cover nothing (and while signing out, when the profile is briefly null).
      await pumpSignedIn(tester, UserRole.admin, permissions: const []);

      expect(find.byType(AppNavBar), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('More'), findsWidgets);
    });

    testWidgets('an admin is offered only what their grants cover', (tester) async {
      await pumpSignedIn(
        tester,
        UserRole.admin,
        permissions: const [PermissionKey.reportsView, PermissionKey.catalogView],
      );

      // Home needs reports.view; Courses needs catalog.view; People needs learners.view.
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Courses'), findsWidgets);
      expect(find.text('People'), findsNothing);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Billing'), findsNothing);
      expect(find.text('Instructors'), findsNothing);
    });

    testWidgets('an academy admin leads with People and keeps the admin destinations', (
      tester,
    ) async {
      await pumpSignedIn(tester, UserRole.admin);

      expect(find.text('People'), findsWidgets);
      expect(find.text('Live'), findsWidgets);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      // Review heads the admin's More sheet, under Teaching; the academy's own pages follow.
      for (final label in ['Review', 'Instructors', 'Certificates', 'Reports']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('a staff form names itself in the app bar, not the tab that holds it', (
      tester,
    ) async {
      await pumpSignedIn(tester, UserRole.admin);
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      final header = find.byType(AppBar);
      for (final (route, title) in [
        ('/staff/live/new', 'Schedule a class'),
        ('/staff/live/l1/edit', 'Edit the class'),
        ('/staff/calendar/new', 'Add to the calendar'),
        ('/staff/instructors/invite', 'Invite an instructor'),
        ('/staff/instructors/i1/edit', 'Edit the instructor'),
      ]) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: header.first, matching: find.text(title)),
          findsOneWidget,
          reason: route,
        );
      }
      // A page that is not a form keeps its tab's name.
      router.go('/staff/live');
      await tester.pumpAndSettle();
      expect(find.descendant(of: header.first, matching: find.text('Live')), findsOneWidget);
    });

    testWidgets('an overflow destination with its own tab switches to that tab', (tester) async {
      await pumpSignedIn(tester, UserRole.admin);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();

      expect(locationOf(tester), '/staff/review');
    });
  });

  group('back behaviour (§5.5)', () {
    testWidgets('back returns to the first tab, then leaves the app', (tester) async {
      await pumpSignedIn(tester, UserRole.student);
      await tester.tap(find.text('Live'));
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/live');

      final popped = <bool>[];
      Future<void> back() async {
        popped.add(await tester.binding.handlePopRoute());
        await tester.pumpAndSettle();
      }

      await back();
      expect(locationOf(tester), '/home', reason: 'back leaves the tab');

      await back();
      expect(popped.last, isFalse, reason: 'on the first tab, back exits the app');
    });

    testWidgets("a tab's own page has no back arrow; a page opened from Home goes back to Home", (
      tester,
    ) async {
      await pumpSignedIn(tester, UserRole.student);
      final appBarBack = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(BackButton),
      );
      expect(appBarBack, findsNothing, reason: 'home is a destination of its own');

      // An assignment lives in the Tests tab, but this one was opened from Home.
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/assignments/a1');
      await tester.pumpAndSettle();
      expect(appBarBack, findsOneWidget);

      await tester.tap(appBarBack);
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/home', reason: 'Back returns to where it was opened from');
      expect(appBarBack, findsNothing);
    });

    testWidgets('Android Back returns to where the page was opened from too', (tester) async {
      await pumpSignedIn(tester, UserRole.student);
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/assignments/a1');
      await tester.pumpAndSettle();

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(handled, isTrue);
      expect(locationOf(tester), '/home');
    });

    testWidgets('across tabs, Back walks back the way the learner came', (tester) async {
      await pumpSignedIn(tester, UserRole.student);
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      // Home → a course (Courses tab) → one of its lessons.
      router.go('/learn/c1');
      await tester.pumpAndSettle();
      router.go('/learn/c1/lessons/l1');
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/learn/c1');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/home', reason: 'not the catalogue: the course came from Home');

      // The Courses tab still opens on the catalogue, not on the lesson left in its stack.
      await tester.tap(find.descendant(of: find.byType(AppNavBar), matching: find.text('Courses')));
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/explore');
    });

    testWidgets('with nothing to go back to (a link from outside), Back goes up', (tester) async {
      await pumpSignedIn(tester, UserRole.student);
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      // A fresh start, as a notification or a deep link opens the app on the page.
      NavHistory.of(router).resetNext();
      router.go('/assignments/a1');
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/assignments', reason: 'up is the list');
    });
  });

  group('pages reached from inside a tab (LIVE E2E NAV-003, NAV-004)', () {
    Finder inAppBar(String text) =>
        find.descendant(of: find.byType(AppBar), matching: find.text(text));

    testWidgets('the app bar names the page, and the bar marks the tab that holds it (§5.2)', (
      tester,
    ) async {
      await pumpSignedIn(tester, UserRole.student);
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/certificates');
      await tester.pumpAndSettle();

      expect(inAppBar('Certificates'), findsOneWidget);
      expect(inAppBar('Profile'), findsNothing);
      expect(tester.widget<AppNavBar>(find.byType(AppNavBar)).selectedIndex, 4);

      await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byType(BackButton)));
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/home', reason: 'it was opened from Home');

      // Opened from Profile, the same page goes back to Profile.
      await tester.tap(find.descendant(of: find.byType(AppNavBar), matching: find.text('Profile')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Certificates'));
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/certificates');
      await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byType(BackButton)));
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/profile');
    });

    testWidgets('Courses is the catalogue, and a tab root: no back arrow', (tester) async {
      await pumpSignedIn(tester, UserRole.student);
      await tester.tap(find.descendant(of: find.byType(AppNavBar), matching: find.text('Courses')));
      await tester.pumpAndSettle();

      expect(locationOf(tester), '/explore');
      expect(inAppBar('Courses'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.byType(BackButton)),
        findsNothing,
      );
    });

    testWidgets('My Courses opens from Profile, and Back goes up to Profile', (tester) async {
      await pumpSignedIn(tester, UserRole.student);
      await tester.tap(find.descendant(of: find.byType(AppNavBar), matching: find.text('Profile')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Courses'));
      await tester.pumpAndSettle();

      expect(locationOf(tester), '/my-learning/in-progress');
      expect(inAppBar('My Courses'), findsOneWidget);
      expect(tester.widget<AppNavBar>(find.byType(AppNavBar)).selectedIndex, 4);

      // Another of its tabs keeps the name and the place.
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/my-learning/completed');
      expect(inAppBar('My Courses'), findsOneWidget);

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(handled, isTrue, reason: 'the app handles Back here; it does not exit');
      expect(locationOf(tester), '/profile');
    });

    testWidgets(
      "Home's shortcut pages name themselves, stay on Home's tab, and Back returns Home",
      (tester) async {
        await pumpSignedIn(tester, UserRole.student);
        for (final (path, title) in [
          ('/home/my-learning/in-progress', 'My Courses'),
          ('/home/assignments', 'Assignments'),
          ('/home/certificates', 'Certificates'),
          ('/home/ranks', 'Rank ladder'),
        ]) {
          GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
          await tester.pumpAndSettle();
          expect(inAppBar(title), findsOneWidget, reason: path);
          expect(
            tester.widget<AppNavBar>(find.byType(AppNavBar)).selectedIndex,
            0,
            reason: '$path is on the Home tab',
          );

          final handled = await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(handled, isTrue, reason: path);
          expect(locationOf(tester), '/home', reason: 'Back from $path returns to Home');
        }
      },
    );

    testWidgets('a page opened from Home keeps its own links in Home, so Back walks back to Home', (
      tester,
    ) async {
      await pumpSignedIn(tester, UserRole.student);
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));

      // My Courses' other tab stays in Home.
      router.go('/home/my-learning/in-progress');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/home/my-learning/completed');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/home');

      // Tests and Assignments switch within Home too.
      router.go('/home/assignments');
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byWidgetPredicate((w) => w is FilterChipBar),
          matching: find.text('Tests'),
        ),
      );
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/home/assessments');

      // A detail goes back to its list in Home, then to Home.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/home');
      router.go('/home/certificates');
      await tester.pumpAndSettle();
      router.go('/home/certificates/c1');
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byType(BackButton)));
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/home/certificates');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(locationOf(tester), '/home');
    });

    testWidgets('staff: a More page names itself, and Back returns to the first tab', (
      tester,
    ) async {
      await pumpSignedIn(tester, UserRole.admin);
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calendar').last);
      await tester.pumpAndSettle();

      expect(locationOf(tester), '/staff/calendar');
      expect(inAppBar('Calendar'), findsOneWidget);
      expect(inAppBar('Dashboard'), findsNothing);
      final bar = tester.widget<AppNavBar>(find.byType(AppNavBar));
      expect(bar.selectedIndex, bar.destinations.length - 1, reason: 'More is marked');

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(handled, isTrue);
      expect(locationOf(tester), '/staff');
    });
  });

  testWidgets('Android is told the app handles Back away from the first tab (predictive back)', (
    tester,
  ) async {
    // Android 13+ with predictive back only gives Back to the app when the framework has said it
    // will handle it; the tab navigators alone keep saying no, and Android closed the app from the
    // Live tab (LIVE E2E NAV-002).
    final reported = <bool>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
        reported.add(call.arguments as bool);
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    // The app only reports this once it is running in the foreground, as on a device.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpSignedIn(tester, UserRole.student);

    await tester.tap(find.text('Live'));
    await tester.pumpAndSettle();

    expect(reported, isNotEmpty);
    expect(reported.last, isTrue, reason: 'on the Live tab Back belongs to the app (§5.5)');
  });

  testWidgets('the offline banner reaches assistive technology, not only the screen', (
    tester,
  ) async {
    // Every page in a tab sits on its route's ModalBarrier, whose BlockSemantics used to hide the
    // banners painted before the tab from TalkBack — on screen, absent from the accessibility tree
    // (LIVE E2E CORE-001).
    final semantics = tester.ensureSemantics();
    await pumpSignedIn(
      tester,
      UserRole.student,
      overrides: [isOnlineProvider.overrideWith((ref) => Stream.value(false))],
    );

    expect(find.text("You're offline. Showing what was loaded."), findsOneWidget);
    expect(
      tester.getSemantics(find.text("You're offline. Showing what was loaded.")),
      matchesSemantics(label: "You're offline. Showing what was loaded.", isLiveRegion: true),
    );
    semantics.dispose();
  });

  testWidgets('the shell shows the notification bell', (tester) async {
    await pumpSignedIn(tester, UserRole.student);

    expect(find.byTooltip('Notifications'), findsOneWidget);
  });

  group('plan-aware navigation', () {
    testWidgets('a module the plan does not include is marked locked, and still opens', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpSignedIn(
        tester,
        UserRole.instructor,
        overrides: [academyPlanProvider.overrideWith(() => _StubPlan(_starterPlan))],
      );

      // The instructor's tabs: Dashboard, Review, Courses, Live — Live is not in this plan.
      expect(find.bySemanticsLabel(RegExp('Locked. Upgrade the plan to use it.')), findsOneWidget);
      expect(find.byIcon(AppIcons.lock), findsOneWidget);

      await tester.tap(find.text('Live'));
      await tester.pumpAndSettle();

      expect(locationOf(tester), '/staff/live');
      expect(find.text('Not included in your LMS plan'), findsOneWidget);
      expect(find.text('Ask your admin to upgrade the plan.'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a read-only module is marked read-only, and its page says so', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpSignedIn(
        tester,
        UserRole.instructor,
        overrides: [academyPlanProvider.overrideWith(() => _StubPlan(_lapsedPlan))],
      );

      // Courses and Live were on the last plan; Review (assessments) was not.
      expect(find.bySemanticsLabel(RegExp('Read-only')), findsNWidgets(2));
      expect(find.bySemanticsLabel(RegExp('Locked')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('the More sheet marks what the plan does not open', (tester) async {
      await pumpSignedIn(
        tester,
        UserRole.instructor,
        overrides: [academyPlanProvider.overrideWith(() => _StubPlan(_starterPlan))],
      );

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      // Quizzes is in the plan; Certificates and Reports are not. Students needs no plan feature.
      expect(find.widgetWithText(AppListTile, 'Certificates'), findsOneWidget);
      expect(
        find.descendant(
          of: find.widgetWithText(AppListTile, 'Certificates'),
          matching: find.byType(PlanAccessBadge),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.widgetWithText(AppListTile, 'Quizzes'),
          matching: find.byType(PlanAccessBadge),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.widgetWithText(AppListTile, 'Students'),
          matching: find.byType(PlanAccessBadge),
        ),
        findsNothing,
      );
      expect(find.text('Upgrade'), findsNWidgets(2));
    });

    testWidgets('nothing is marked while plans are not enforced, or the plan is not known', (
      tester,
    ) async {
      for (final plan in [const AcademyPlan(status: SubscriptionState.expired), null]) {
        await pumpSignedIn(
          tester,
          UserRole.instructor,
          overrides: [academyPlanProvider.overrideWith(() => _StubPlan(plan))],
        );
        expect(find.byType(Badge), findsNothing, reason: '$plan');
      }
    });

    testWidgets('a trialing academy\'s admin sees the trial banner in the shell', (tester) async {
      await pumpSignedIn(
        tester,
        UserRole.admin,
        overrides: [
          academyPlanProvider.overrideWith(
            () => _StubPlan(
              AcademyPlan(
                enforced: true,
                status: SubscriptionState.trialing,
                features: const [FeatureKey.coursesManage],
                trialEndsAt: DateTime.now().toUtc().add(const Duration(days: 5, hours: 1)),
              ),
            ),
          ),
        ],
      );

      expect(find.text('Free trial · 6 days left'), findsOneWidget);
      expect(find.text('Choose a plan'), findsOneWidget);
    });
  });

  group('onboarding', () {
    testWidgets('an admin whose plan says never subscribed still stays on the dashboard', (
      tester,
    ) async {
      await pumpSignedIn(
        tester,
        UserRole.admin,
        overrides: [
          academyPlanProvider.overrideWith(
            () => _StubPlan(const AcademyPlan(enforced: true, restricted: true)),
          ),
        ],
      );

      expect(locationOf(tester), '/staff');
      expect(find.text('Get started'), findsNothing);
    });

    testWidgets('while plans are not enforced the admin stays on the dashboard', (tester) async {
      await pumpSignedIn(
        tester,
        UserRole.admin,
        overrides: [
          academyPlanProvider.overrideWith(() => _StubPlan(const AcademyPlan(restricted: true))),
        ],
      );

      expect(locationOf(tester), '/staff');
    });

    testWidgets('an instructor of a brand-new academy is never sent there', (tester) async {
      await pumpSignedIn(
        tester,
        UserRole.instructor,
        overrides: [
          academyPlanProvider.overrideWith(
            () => _StubPlan(const AcademyPlan(enforced: true, restricted: true)),
          ),
        ],
      );

      expect(locationOf(tester), '/staff');
      await tester.tap(find.text('Courses'));
      await tester.pumpAndSettle();
      expect(find.text('Your LMS is being set up'), findsOneWidget);
    });
  });

  group('AppRoutes.within', () {
    test('a page Home holds links to what Home also holds, in Home', () {
      expect(AppRoutes.within('/home/certificates', '/certificates/c1'), '/home/certificates/c1');
      expect(AppRoutes.within('/home/assignments', '/assessments'), '/home/assessments');
      expect(
        AppRoutes.within('/home/my-learning/in-progress', '/my-learning/completed'),
        '/home/my-learning/completed',
      );
    });

    test('anything else is left as it is', () {
      // Home does not hold courses: a course opens in the Courses tab from anywhere.
      expect(AppRoutes.within('/home/my-learning/in-progress', '/learn/c1'), '/learn/c1');
      // Opened from Profile, the page stays in Profile.
      expect(AppRoutes.within('/certificates', '/certificates/c1'), '/certificates/c1');
      expect(AppRoutes.within('/home', '/certificates'), '/certificates');
    });
  });
}
