import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/config/flavor.dart';
import '../core/logging/crash_reporter.dart';
import '../core/logging/crashlytics_reporter.dart';
import '../core/network/api_client.dart';
import '../core/push/push_platform.dart';
import '../core/storage/preferences.dart';
import '../features/auth/auth.dart';
import '../features/notifications/notifications.dart' show handleBackgroundPush;
import '../shared/widgets/errors/error_boundary.dart';
import 'app.dart';
import 'config_error_app.dart';
import 'error_hooks.dart';
import 'routing/app_router.dart';

/// Shared start-up for every flavor's entry point: validate the build config, install the error
/// hooks, load preferences, and run the app inside a guarded zone. [readConfig] replaces reading
/// the flavor's dart-defines (`lib/main.dart` falls back to local dev values).
Future<void> bootstrap(
  Flavor flavor, {
  Map<String, WidgetBuilder> devRoutes = const {},
  AppConfig Function()? readConfig,
}) async {
  // Discards until the build config says otherwise and Firebase has started (below).
  final reporter = DeferredCrashReporter();
  final hooks = ErrorHooks(reporter);

  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    hooks.install();
    ErrorBoundary.install();

    final AppConfig config;
    try {
      config = readConfig?.call() ?? AppConfig.fromEnvironment(flavor);
    } on ConfigException catch (e) {
      runApp(ConfigErrorApp(message: e.message, showDetail: flavor == Flavor.dev));
      return;
    }

    reporter.target = await createCrashReporter(enabled: config.crashReportingEnabled);
    // Hints that arrive while the app is closed are shown from their own isolate. Registered before
    // the app runs, as Firebase Messaging requires; a build without push never touches Firebase.
    if (config.pushEnabled && !kIsWeb) {
      try {
        await ensureFirebase();
        FirebaseMessaging.onBackgroundMessage(handleBackgroundPush);
      } on Object catch (e) {
        debugPrint('Push notifications are off: Firebase did not start (${e.runtimeType}).');
      }
    }

    // Date formatting (core/format/dates_ist.dart) may run before MaterialApp's localizations load.
    await initializeDateFormatting('en');
    final preferences = Preferences(await SharedPreferences.getInstance());
    runApp(
      appRoot(config: config, preferences: preferences, reporter: reporter, devRoutes: devRoutes),
    );
  }, hooks.handleUncaught);
}

/// The app with its start-up dependencies provided — used by [bootstrap] and by integration tests,
/// which must not replace the test binding's error hooks.
Widget appRoot({
  required AppConfig config,
  required Preferences preferences,
  CrashReporter reporter = const NoopCrashReporter(),
  Map<String, WidgetBuilder> devRoutes = const {},
}) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      appConfigProvider.overrideWithValue(config),
      crashReporterProvider.overrideWithValue(reporter),
      preferencesProvider.overrideWithValue(preferences),
      devRoutesProvider.overrideWithValue(devRoutes),
      // The API client reads the token from secure storage, and a 401 on a request that carried one
      // ends the session exactly once (§6).
      tokenStoreProvider.overrideWith((ref) => ref.watch(secureTokenStoreProvider)),
      // Shared code reads the signed-in person through this seam rather than the auth feature (§26).
      currentUserProvider.overrideWith((ref) => ref.watch(sessionControllerProvider).user),
      sessionExpiredHandlerProvider.overrideWith(
        (ref) =>
            () => unawaited(ref.read(sessionControllerProvider.notifier).handleSessionExpired()),
      ),
      // The platform suspended or closed the account's LMS: the session ends with the reason (§6).
      accountClosedHandlerProvider.overrideWith(
        (ref) =>
            (failure) => unawaited(
              ref.read(sessionControllerProvider.notifier).handleAccountClosed(failure),
            ),
      ),
    ],
    child: SyniastroApp(flavor: config.flavor),
  );
}

/// Riverpod 3 retries a failed async provider on its own — up to ten times with backoff, for any
/// error that is not an `Error` — which would hide a refusal behind half a minute of silence and
/// stack on top of the API client's own retry policy. The app keeps one automatic policy
/// (`RetryInterceptor`: idempotent reads, 502/503/504, twice) and one deliberate one: the person
/// pressing "Try again" (§10.2, §17).
Duration? noProviderRetry(int retryCount, Object error) => null;
