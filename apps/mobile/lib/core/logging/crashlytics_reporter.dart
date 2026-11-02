import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'crash_reporter.dart';

/// Sends redacted crash reports to Firebase Crashlytics (C7). Only what [CrashReport] holds leaves the
/// device — its type, its redacted message and context, and the stack — never a body, token or personal
/// data, and no user identifier is ever set.
class CrashlyticsReporter implements CrashReporter {
  CrashlyticsReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> record(CrashReport report) => _crashlytics.recordError(
    _Reported(report.errorType, report.message),
    report.stack,
    reason: report.context,
    information: [for (final entry in report.fields.entries) '${entry.key}: ${entry.value}'],
    fatal: report.fatal,
  );
}

/// What Crashlytics groups and shows: the original type and the already-redacted message.
class _Reported implements Exception {
  const _Reported(this.type, this.message);

  final String type;
  final String message;

  @override
  String toString() => '$type: $message';
}

/// The reporter for this build. Crash reporting is opt-in per build (`CRASH_REPORTING_ENABLED`, off in
/// every flavor config until the privacy policy and the store's data-safety answers say crash data is
/// collected); collection is also off in the Android manifest, so nothing is sent before this turns it on.
/// A Firebase start-up failure never stops the app: it falls back to discarding reports.
Future<CrashReporter> createCrashReporter({required bool enabled}) async {
  if (!enabled || kIsWeb) return const NoopCrashReporter();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(true);
    return CrashlyticsReporter(crashlytics);
  } on Object catch (e) {
    debugPrint('Crash reporting is off: Firebase did not start (${e.runtimeType}).');
    return const NoopCrashReporter();
  }
}
