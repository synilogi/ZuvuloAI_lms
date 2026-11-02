// A device UI tour for the redesign checklist (docs/ui-redesign-checklist.md): boots the real dev
// app on a device against a scratch API, signs in as one role, visits every screen that role has
// (opening a detail page by tapping the first item of its list, as a person would), and saves a
// screenshot of each. Layout errors (overflow, clipping) are collected and printed, not fatal, so
// one bad screen does not hide the rest.
//
// Not part of the test suites. Run with tool/ui_tour/run.sh.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/app/routing/app_router.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/storage/preferences.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

const _role = String.fromEnvironment('TOUR_ROLE', defaultValue: 'student');
const _theme = String.fromEnvironment('TOUR_THEME', defaultValue: 'light');
const _scale = String.fromEnvironment('TOUR_SCALE', defaultValue: '1');
const _only = String.fromEnvironment('TOUR_ONLY');
const _password = String.fromEnvironment('TOUR_PASSWORD');

/// Real tokens and ids from the scratch API (a reset link, an invitation, seeded records), put
/// into routes as `{name}`.
const _ids = {
  'reset': String.fromEnvironment('TOUR_RESET'),
  'invite': String.fromEnvironment('TOUR_INVITE'),
  'course': String.fromEnvironment('TOUR_COURSE'),
  'lessonVideo': String.fromEnvironment('TOUR_LESSON_VIDEO'),
  'lessonPractice': String.fromEnvironment('TOUR_LESSON_PRACTICE'),
  'lessonQuiz': String.fromEnvironment('TOUR_LESSON_QUIZ'),
  'lessonAssignment': String.fromEnvironment('TOUR_LESSON_ASSIGNMENT'),
  'lessonReading': String.fromEnvironment('TOUR_LESSON_READING'),
  'live': String.fromEnvironment('TOUR_LIVE'),
  'event': String.fromEnvironment('TOUR_EVENT'),
  'instructor': String.fromEnvironment('TOUR_INSTRUCTOR'),
  'assignment': String.fromEnvironment('TOUR_ASSIGNMENT'),
  'credential': String.fromEnvironment('TOUR_CREDENTIAL'),
  'slug': String.fromEnvironment('TOUR_SLUG'),
  'stamp': String.fromEnvironment('TOUR_STAMP'),
};

String _fill(String text) =>
    text.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => _ids[m[1]] ?? m[0]!);

const _accounts = {
  'student': 'ananya@syniastrolms.test',
  'instructor': 'meenakshi@syniastrolms.test',
  'admin': 'admin@syniastrolms.test',
  // The platform operator: the app has no workspace for this role and says so.
  'superadmin': 'ops@syniastrolms.test',
};

const _superadmin = [Stop('unsupported-role', '/unsupported-role')];

/// One stop: a route to open, and optionally a detail page reached by tapping the first item.
class Stop {
  const Stop(
    this.name,
    this.route, {
    this.openFirst = false,
    this.scroll = false,
    this.tapText,
    this.steps = const [],
  });

  /// A short script run after the first screenshot: `tap:<text>`, `first` (the first card or
  /// row), `type:<field index>:<text>`, `check` (the first checkbox), `shot:<name>`, `scroll`,
  /// `back` (close the open dialog or sheet), `tip:<tooltip>` (an icon button), `dismiss` (tap
  /// outside a menu), `unfocus` (hide the keyboard), `wait`.
  final List<String> steps;

  final String name;
  final String route;

  /// Also tap the first tappable card or row and capture what it opens.
  final bool openFirst;

  /// Also capture the page scrolled to its end.
  final bool scroll;

  /// Open what this text leads to (instead of the first item) and capture it.
  final String? tapText;
}

const _public = [
  Stop('welcome', '/welcome'),
  Stop('login', '/login'),
  Stop('register', '/register'),
  Stop('forgot', '/forgot-password'),
  Stop('catalog', '/catalog', openFirst: true, scroll: true),
  Stop('verify', '/verify'),
  Stop('help', '/help', openFirst: true),
  Stop('privacy', '/legal/privacy'),
  Stop('verify-result', '/verify/{credential}', scroll: true),
  Stop('preview-lesson', '/catalog/{slug}/preview/{lessonVideo}', scroll: true),
  Stop('reset-password', '/reset-password/{reset}'),
  Stop('invitation', '/invite/{invite}', scroll: true),
  Stop('enrol-link', '/enrol/{course}', scroll: true),
  Stop(
    'academy-signup',
    '/welcome',
    steps: [
      'tap:Create account',
      'shot:type',
      'tap:I want to teach',
      'shot:form',
      'type:0:Redesign Tour Academy {stamp}',
      'type:2:Tour Admin',
      'type:3:tour{stamp}@example.test',
      'type:4:syniastrolms123',
      'type:5:syniastrolms123',
      'unfocus',
      'check',
      'shot:filled',
      'tap:Continue',
      'wait',
      'shot:code',
    ],
  ),
  Stop(
    'login-error',
    '/login',
    steps: ['type:0:nobody@example.test', 'type:1:wrongpass1', 'tap:Sign in', 'wait', 'shot:error'],
  ),
];

const _student = [
  Stop('home', '/home', scroll: true),
  Stop('lesson', '/home', tapText: 'Resume'),
  Stop('lesson-video', '/learn/{course}/lessons/{lessonVideo}', scroll: true),
  Stop('lesson-reading', '/learn/{course}/lessons/{lessonReading}', scroll: true),
  Stop('lesson-practice', '/learn/{course}/lessons/{lessonPractice}', scroll: true),
  Stop('lesson-quiz', '/learn/{course}/lessons/{lessonQuiz}', scroll: true),
  Stop('lesson-assignment', '/learn/{course}/lessons/{lessonAssignment}', scroll: true),
  Stop(
    'curriculum-sheet',
    '/learn/{course}/lessons/{lessonReading}',
    steps: ['tap:Curriculum', 'shot:open', 'back'],
  ),
  Stop('sign-out-dialog', '/profile', steps: ['tap:Sign out', 'shot:open', 'back']),
  Stop('notification-menu', '/notifications', steps: ['tip:More', 'shot:open', 'dismiss']),
  Stop('not-found', '/learn/no-such-course'),
  Stop(
    'quiz-taker',
    '/learn/{course}/lessons/{lessonQuiz}',
    steps: ['tap:Start the quiz', 'wait', 'shot:open', 'scroll', 'shot:end'],
  ),
  Stop('my-learning', '/my-learning/in-progress', openFirst: true),
  Stop('my-learning-completed', '/my-learning/completed'),
  Stop('my-learning-saved', '/my-learning/saved'),
  Stop('explore', '/explore', openFirst: true, scroll: true),
  Stop('assignments', '/assignments', openFirst: true),
  Stop('assessments', '/assessments', openFirst: true),
  Stop('live', '/live', openFirst: true, scroll: true),
  Stop('certificates', '/certificates', openFirst: true, scroll: true),
  Stop('ranks', '/ranks', scroll: true),
  Stop('notifications', '/notifications', openFirst: true),
  Stop('notification-prefs', '/notifications/preferences', scroll: true),
  Stop('profile', '/profile', scroll: true),
  Stop('settings', '/profile/settings', scroll: true),
  Stop('delete-account', '/profile/delete-account', scroll: true),
  Stop('help', '/help', openFirst: true),
];

const _staff = [
  Stop('dashboard', '/staff', scroll: true),
  // The grouped More sheet (Teaching, Academy, Account).
  Stop('more-sheet', '/staff', steps: ['tap:More', 'shot:open', 'scroll', 'shot:end', 'back']),
  Stop('courses', '/staff/courses', openFirst: true, scroll: true),
  Stop('review', '/staff/review', openFirst: true, scroll: true),
  Stop('submission', '/staff/review', tapText: 'Ananya Rao'),
  Stop('submissions', '/staff/assignments/{assignment}/submissions', scroll: true),
  Stop('curriculum', '/staff/courses/{course}/curriculum', scroll: true),
  Stop('staff-lesson', '/staff/courses/{course}/lessons/{lessonReading}', scroll: true),
  Stop('live-edit', '/staff/live/{live}/edit', scroll: true),
  Stop(
    'live-cancel-dialog',
    '/staff/live/{live}',
    steps: ['tap:Cancel the class', 'shot:open', 'back'],
  ),
  Stop('event', '/staff/calendar/{event}', scroll: true),
  Stop('event-edit', '/staff/calendar/{event}/edit', scroll: true),
  Stop('instructor-edit', '/staff/instructors/{instructor}/edit', scroll: true),
  Stop('invoice', '/staff/billing/invoices/none'),
  Stop('get-started', '/staff/get-started', scroll: true),
  Stop(
    'unpublish-dialog',
    '/staff/courses/{course}',
    steps: ['tap:Unpublish', 'shot:open', 'back'],
  ),
  Stop(
    'message-sheet',
    '/staff/students',
    steps: ['tap:Select', 'shot:selected', 'tap:Message', 'shot:open', 'back'],
  ),
  Stop('suspend-dialog', '/staff/students', steps: ['first', 'tap:Suspend', 'shot:open', 'back']),
  Stop('report-filters', '/staff/reports', steps: ['tap:Filters', 'shot:open', 'back']),
  Stop('quizzes', '/staff/quizzes', openFirst: true),
  Stop('students', '/staff/students', openFirst: true, scroll: true),
  Stop('live', '/staff/live', openFirst: true, scroll: true),
  Stop('live-new', '/staff/live/new', scroll: true),
  Stop('calendar', '/staff/calendar', openFirst: true, scroll: true),
  Stop('calendar-new', '/staff/calendar/new', scroll: true),
  Stop('instructors', '/staff/instructors', openFirst: true),
  Stop('instructor-invite', '/staff/instructors/invite', scroll: true),
  Stop('certificates', '/staff/certificates', openFirst: true),
  Stop('reports', '/staff/reports', scroll: true),
  Stop('reports-courses', '/staff/reports/courses', openFirst: true),
  Stop('reports-learners', '/staff/reports/learners', scroll: true),
  Stop('reports-instructors', '/staff/reports/instructors', scroll: true),
  Stop('reports-enrolments', '/staff/reports/enrolments', scroll: true),
  Stop('billing', '/staff/billing', scroll: true),
  Stop('billing-plans', '/staff/billing/plans', scroll: true),
  Stop('notifications', '/staff/notifications', openFirst: true),
  Stop('notification-prefs', '/staff/notifications/preferences'),
  Stop('profile', '/staff/profile', scroll: true),
  Stop('settings', '/staff/profile/settings'),
  Stop('help', '/staff/help'),
];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => initializeDateFormatting('en'));

  testWidgets('UI tour: $_role, $_theme, text ×$_scale', (tester) async {
    final problems = <String>[];
    var current = 'launch';
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString().split('\n').first;
      problems.add('[$current] $text');
      debugPrint('TOUR-PROBLEM [$current] $text');
      // The app's own frames, so a problem can be traced without a debugger attached.
      for (final frame
          in (details.stack?.toString() ?? '')
              .split('\n')
              .where((line) => line.contains('package:syniastrolms_mobile'))
              .take(8)) {
        debugPrint('TOUR-TRACE [$current] ${frame.trim()}');
      }
    };

    Future<void> settle([Duration max = const Duration(seconds: 6)]) async {
      try {
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          max,
        );
      } on FlutterError {
        // A page with a perpetual animation (a live dot, a busy spinner) never settles; it has had
        // its time.
      }
    }

    var converted = false;
    Future<void> shot(String name) async {
      await settle();
      if (!converted) {
        await binding.convertFlutterSurfaceToImage();
        converted = true;
        await settle();
      }
      await binding.takeScreenshot('${_role}_${_theme}_x${_scale}_$name');
    }

    final config = AppConfig.fromEnvironment(Flavor.dev);
    await SecureTokenStore(environment: config.flavor.name).clear();
    // The dev install's own preferences on the device: the tour's theme and text size.
    final preferences = Preferences(await SharedPreferences.getInstance());
    await preferences.setThemeMode(_theme == 'dark' ? ThemeMode.dark : ThemeMode.light);
    await preferences.setTextScalePreview(double.parse(_scale));
    await tester.pumpWidget(appRoot(config: config, preferences: preferences));
    await settle(const Duration(seconds: 10));

    ProviderContainer container() =>
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    Future<void> go(String route) async {
      container().read(routerProvider).go(route);
      await settle();
    }

    if (_role != 'public') {
      await go('/login');
      await tester.enterText(find.byType(TextField).first, _accounts[_role]!);
      await tester.enterText(find.byType(TextField).last, _password);
      final signIn = find.widgetWithText(AppButton, 'Sign in').last;
      // Large text pushes the button below the fold; the keyboard may cover it too.
      FocusManager.instance.primaryFocus?.unfocus();
      await settle();
      await tester.ensureVisible(signIn);
      await settle();
      await tester.tap(signIn, warnIfMissed: false);
      await settle(const Duration(seconds: 12));
      final at = container().read(routerProvider).routerDelegate.currentConfiguration.uri.path;
      if (at == '/login' || at == '/welcome') {
        debugPrint('TOUR-PROBLEM sign-in did not complete (still at $at)');
        problems.add('[sign-in] did not complete (still at $at)');
        await shot('signin_failed');
        for (final t in find.byType(Text).evaluate().take(40)) {
          debugPrint('TOUR-TEXT ${(t.widget as Text).data}');
        }
      }
    }

    final stops = switch (_role) {
      'public' => _public,
      'student' => _student,
      'superadmin' => _superadmin,
      _ => _staff,
    };

    for (final stop in stops) {
      if (_only.isNotEmpty && !_only.split(',').contains(stop.name)) continue;
      current = stop.name;
      await go(_fill(stop.route));
      await shot(stop.name);
      for (final step in stop.steps) {
        final parts = step.split(':');
        switch (parts.first) {
          case 'tap':
            final label = parts.sublist(1).join(':');
            Finder lookup() {
              final exact = find.text(label);
              return exact.evaluate().isNotEmpty ? exact : find.textContaining(label);
            }

            var hits = lookup();
            // A long list builds lazily: look further down the page before giving up.
            for (var i = 0; i < 4 && hits.evaluate().isEmpty; i++) {
              final page = _page();
              if (page == null) break;
              try {
                await tester.drag(page, const Offset(0, -500));
              } on Object {
                break;
              }
              await settle();
              hits = lookup();
            }
            if (hits.evaluate().isEmpty) {
              debugPrint('TOUR-NOTE [${stop.name}] "$step" not found');
              continue;
            }
            await tester.ensureVisible(hits.last);
            await settle();
            await tester.tap(hits.last, warnIfMissed: false);
            await settle();
          case 'first':
            if (_firstItem() case final item?) {
              await tester.ensureVisible(item);
              await settle();
              await tester.tap(item, warnIfMissed: false);
              await settle(const Duration(seconds: 8));
            } else {
              debugPrint('TOUR-NOTE [${stop.name}] nothing to open');
            }
          case 'type':
            final fields = find.byType(EditableText);
            final index = int.parse(parts[1]);
            if (fields.evaluate().length <= index) {
              debugPrint('TOUR-NOTE [${stop.name}] no field $index');
              continue;
            }
            await tester.ensureVisible(fields.at(index));
            await tester.enterText(fields.at(index), _fill(parts.sublist(2).join(':')));
            await settle();
          case 'check':
            final box = find.byType(Checkbox);
            if (box.evaluate().isNotEmpty) {
              await tester.ensureVisible(box.first);
              await tester.tap(box.first, warnIfMissed: false);
              await settle();
            }
          case 'shot':
            await shot('${stop.name}_${parts[1]}');
          case 'scroll':
            if (_page() case final page?) {
              try {
                await tester.fling(page, const Offset(0, -3000), 3000);
              } on Object {
                // Nothing to scroll.
              }
            }
          case 'back':
            // Closes the open dialog or sheet only — never the page itself, which on a top-level
            // route would send the app to the background.
            final popup = find.byWidgetPredicate(
              (w) => w is Dialog || w is AlertDialog || w is BottomSheet,
            );
            if (popup.evaluate().isNotEmpty) {
              Navigator.of(tester.element(popup.last)).pop();
              await settle();
            }
          case 'tip':
            // An icon button by its tooltip, ignoring the navigation bar's own "More".
            final tips = find.byTooltip(parts.sublist(1).join(':')).evaluate().where((e) {
              var inBar = false;
              e.visitAncestorElements((a) {
                inBar = a.widget is NavigationBar;
                return !inBar;
              });
              return !inBar;
            }).toList();
            if (tips.isEmpty) {
              debugPrint('TOUR-NOTE [${stop.name}] "$step" not found');
              continue;
            }
            final first = tips.first;
            await tester.tap(find.byElementPredicate((e) => identical(e, first)));
            await settle();
          case 'dismiss':
            // Taps the barrier behind a menu.
            await tester.tapAt(const Offset(8, 400));
            await settle();
          case 'unfocus':
            FocusManager.instance.primaryFocus?.unfocus();
            await settle();
          case 'wait':
            await settle(const Duration(seconds: 10));
        }
      }
      if (stop.scroll) {
        final scrollable = _page();
        if (scrollable != null) {
          try {
            await tester.fling(scrollable, const Offset(0, -3000), 3000);
          } on Object {
            // Nothing to scroll.
          }
          await shot('${stop.name}_end');
        }
      }
      if (stop.tapText case final text?) {
        current = '${stop.name}/open';
        await go(_fill(stop.route));
        // Back to the top: the same route may still be scrolled from the stop before.
        if (_page() case final page?) {
          try {
            await tester.fling(page, const Offset(0, 3000), 3000);
          } on Object {
            // Already at the top.
          }
          await settle();
        }
        final target = find.text(text);
        if (target.evaluate().isNotEmpty) {
          await tester.ensureVisible(target.first);
          await settle();
          await tester.tap(target.first, warnIfMissed: false);
          await settle(const Duration(seconds: 8));
          await shot('${stop.name}_open');
          final scrollable = _page();
          if (scrollable != null) {
            try {
              await tester.fling(scrollable, const Offset(0, -3000), 3000);
            } on Object {
              // Nothing to scroll.
            }
            await shot('${stop.name}_open_end');
          }
        } else {
          debugPrint('TOUR-NOTE [${stop.name}] "$text" not found');
        }
      }
      if (stop.openFirst) {
        current = '${stop.name}/detail';
        await go(_fill(stop.route));
        final target = _firstItem();
        if (target != null) {
          await tester.ensureVisible(target);
          await settle();
          await tester.tap(target, warnIfMissed: false);
          await settle(const Duration(seconds: 8));
          await shot('${stop.name}_detail');
          final scrollable = _page();
          if (scrollable != null) {
            try {
              await tester.fling(scrollable, const Offset(0, -3000), 3000);
            } on Object {
              // Nothing to scroll.
            }
            await shot('${stop.name}_detail_end');
          }
        } else {
          debugPrint('TOUR-NOTE [${stop.name}] nothing to open');
        }
      }
    }

    FlutterError.onError = previous;
    debugPrint('TOUR-DONE ${problems.length} problem(s)');
    for (final p in problems) {
      debugPrint('TOUR-SUMMARY $p');
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}

/// The first tappable card or list row on the page, below the app bar.
Finder? _firstItem() {
  final cards = find.byWidgetPredicate(
    (w) => (w is AppCard && w.onTap != null) || (w is AppListTile && w.onTap != null),
  );
  final inBody = cards.evaluate().where((e) {
    var inBar = false;
    e.visitAncestorElements((a) {
      if (a.widget is AppBar || a.widget is NavigationBar || a.widget is BottomSheet) {
        inBar = true;
        return false;
      }
      return true;
    });
    return !inBar;
  }).toList();
  if (inBody.isEmpty) return null;
  return find.byElementPredicate((e) => identical(e, inBody.first));
}

/// The page's own scroll view: the tallest vertical scrollable on screen.
Finder? _page() {
  Element? best;
  var bestHeight = 0.0;
  for (final e in find.byType(Scrollable).evaluate()) {
    final w = e.widget as Scrollable;
    if (w.axisDirection != AxisDirection.down) continue;
    final box = e.renderObject as RenderBox?;
    final h = box == null || !box.hasSize ? 0.0 : box.size.height;
    if (h > bestHeight) {
      best = e;
      bestHeight = h;
    }
  }
  if (best == null) return null;
  final chosen = best;
  return find.byElementPredicate((e) => identical(e, chosen));
}
