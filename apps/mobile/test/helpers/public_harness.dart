import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/platform/clock.dart';
import 'package:syniastrolms_mobile/core/platform/external_link.dart';
import 'package:syniastrolms_mobile/core/platform/live_room.dart';
import 'package:syniastrolms_mobile/core/platform/share.dart';
import 'package:syniastrolms_mobile/core/storage/preferences.dart';
import 'package:syniastrolms_mobile/core/theme/theme.dart';
import 'package:syniastrolms_mobile/features/course_purchase/course_purchase.dart';
import 'package:syniastrolms_mobile/features/staff_billing/application/staff_billing_controller.dart';
import 'package:syniastrolms_mobile/features/staff_billing/data/pending_payment_store.dart';
import 'package:syniastrolms_mobile/l10n/l10n.dart';
import 'package:syniastrolms_mobile/shared/domain/user_profile.dart';
import 'package:syniastrolms_mobile/shared/session/current_user.dart';

import 'fake_adapter.dart';
import 'test_config.dart';

/// A captured response from the real API, read straight from `test/fixtures/`.
Object? fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

/// The public screens run on the real API client, answered by [adapter] with real captured
/// responses — so a widget test exercises decoding as well as layout.
ProviderScope publicScope({
  required FakeAdapter adapter,
  required Widget child,
  UserProfile? signedInAs,
  ShareText? shareText,
  OpenExternalLink? openExternalLink,
  OpenLiveRoom? openLiveRoom,
  Clock? clock,
  MonotonicClock? monotonicClock,
  Preferences? preferences,
  AppConfig? config,
  NativeCheckoutRunner? checkoutRunner,
  PendingPaymentStore? pendingPayments,
  CourseCheckoutRunner? courseCheckoutRunner,
  PendingPurchaseStore? pendingPurchases,
}) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      // The platform's secure store has no implementation under test.
      pendingPaymentStoreProvider.overrideWithValue(pendingPayments ?? MemoryPendingPaymentStore()),
      // Nor does the Razorpay SDK: a test scripts what the gateway answers, or none runs.
      nativeCheckoutRunnerProvider.overrideWithValue(checkoutRunner),
      // The same for a course: the secure store and the Razorpay SDK are scripted, or absent.
      pendingPurchaseStoreProvider.overrideWithValue(
        pendingPurchases ?? MemoryPendingPurchaseStore(),
      ),
      courseCheckoutRunnerProvider.overrideWithValue(courseCheckoutRunner),
      // No real waiting on the bank under test.
      purchasePollingProvider.overrideWithValue((interval: Duration.zero, attempts: 3)),
      // Riverpod 3 does not export the `Override` type, so the seams a test needs are named
      // parameters rather than a list it could pass in.
      if (shareText != null) shareTextProvider.overrideWithValue(shareText),
      if (openExternalLink != null) openExternalLinkProvider.overrideWithValue(openExternalLink),
      // The live room is a native activity: a test sees what would open, never a camera.
      openLiveRoomProvider.overrideWithValue(openLiveRoom ?? (_, {onClosed}) async {}),
      if (clock != null) clockProvider.overrideWithValue(clock),
      if (monotonicClock != null) monotonicClockProvider.overrideWithValue(monotonicClock),
      if (preferences != null) preferencesProvider.overrideWithValue(preferences),
      appConfigProvider.overrideWithValue(config ?? testConfig()),
      apiClientProvider.overrideWith(
        (ref) => ApiClient(
          config: testConfig(),
          tokenStore: FakeTokenStore(signedInAs == null ? null : 'jwt'),
          logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
          adapter: adapter,
          logRequests: false,
          // The retry policy is still exercised; only its wall-clock backoff is removed, so a
          // test never depends on how busy the machine is.
          retryDelay: (_) async {},
        ),
      ),
      currentUserProvider.overrideWithValue(signedInAs),
    ],
    child: child,
  );
}

/// Pumps [child] inside the app's theme, localizations and a router that only needs to exist for
/// the screen's own `go` calls to be testable.
Future<void> pumpPublic(
  WidgetTester tester,
  Widget child, {
  required FakeAdapter adapter,
  UserProfile? signedInAs,
  Size size = const Size(400, 900),
  ShareText? shareText,
  OpenExternalLink? openExternalLink,
  OpenLiveRoom? openLiveRoom,
  Clock? clock,
  MonotonicClock? monotonicClock,
  Map<String, Object> preferences = const {},
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final prefs = await testPreferences(preferences);
  await tester.pumpWidget(
    publicScope(
      adapter: adapter,
      signedInAs: signedInAs,
      shareText: shareText,
      openExternalLink: openExternalLink,
      openLiveRoom: openLiveRoom,
      clock: clock,
      monotonicClock: monotonicClock,
      preferences: prefs,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        // Skeletons shimmer on a repeating animation, so `pumpAndSettle` would never settle while
        // one is on screen. Tests run with motion off, as the component matrix does.
        builder: (context, app) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: app!),
        home: child,
      ),
    ),
  );
  await tester.pump();
}

/// A seeded learner, for the screens that change when someone is signed in.
UserProfile learner({String id = 'u_learner'}) => UserProfile(
  id: id,
  name: 'Ananya Rao',
  email: 'learner@example.test',
  role: UserRole.student,
  descriptor: 'Beginner',
);

/// Pumps a small router over the public screens, for the tests that follow a `go` call.
Future<GoRouter> pumpPublicRouter(
  WidgetTester tester, {
  required FakeAdapter adapter,
  required List<RouteBase> routes,
  String initialLocation = '/',
  UserProfile? signedInAs,
  Size size = const Size(400, 900),
  double textScale = 1,
  ShareText? shareText,
  OpenExternalLink? openExternalLink,
  OpenLiveRoom? openLiveRoom,
  Clock? clock,
  Map<String, Object> preferences = const {},
  AppConfig? config,
  NativeCheckoutRunner? checkoutRunner,
  CourseCheckoutRunner? courseCheckoutRunner,
  PendingPurchaseStore? pendingPurchases,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final prefs = await testPreferences(preferences);
  final router = GoRouter(initialLocation: initialLocation, routes: routes);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    publicScope(
      adapter: adapter,
      signedInAs: signedInAs,
      shareText: shareText,
      openExternalLink: openExternalLink,
      openLiveRoom: openLiveRoom,
      clock: clock,
      preferences: prefs,
      config: config,
      checkoutRunner: checkoutRunner,
      courseCheckoutRunner: courseCheckoutRunner,
      pendingPurchases: pendingPurchases,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            // As above: a repeating shimmer would stop `pumpAndSettle` ever settling.
            disableAnimations: true,
          ),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  return router;
}

/// Where the router is now.
String locationOf(GoRouter router) => router.routerDelegate.currentConfiguration.uri.toString();

/// Waits until [condition] holds. Debounced work runs on a real timer, so a test waits for the
/// thing it is about rather than for a fixed margin a loaded machine can overshoot — which is what
/// made the note and draft autosave tests flake under a full parallel run.
Future<void> waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail(reason ?? 'Timed out after ${timeout.inSeconds}s waiting for the expected state.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

/// The device's own preferences, in memory, so a screen that reads them works in a test and
/// nothing is written to a real device.
Future<Preferences> testPreferences([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return Preferences(await SharedPreferences.getInstance());
}
