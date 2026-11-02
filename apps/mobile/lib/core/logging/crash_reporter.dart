import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'redactor.dart';

/// Where uncaught errors go (modules.md §16, §24). Firebase Crashlytics (`crashlytics_reporter.dart`)
/// when the build sets `CRASH_REPORTING_ENABLED`, otherwise [NoopCrashReporter]. Callers pass raw values — implementations must send only
/// what [CrashReport] holds, which is already redacted.
abstract interface class CrashReporter {
  Future<void> record(CrashReport report);
}

/// One redacted error report. Never carries a response body, a token or personal data.
class CrashReport {
  CrashReport({
    required Object error,
    this.stack,
    String? context,
    Map<String, Object?> fields = const {},
    this.fatal = false,
  }) : errorType = error.runtimeType.toString(),
       message = Redactor.redactText(error.toString()),
       context = context == null ? null : Redactor.redactText(context),
       fields = Redactor.redact(fields)! as Map<String, Object?>;

  final String errorType;
  final String message;
  final StackTrace? stack;
  final String? context;
  final Map<String, Object?> fields;
  final bool fatal;
}

/// Discards reports: the default until a crash-reporting vendor and account exist (C7).
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> record(CrashReport report) async {}
}

/// Forwards to whichever reporter start-up chose. The error hooks are installed before Firebase can start,
/// so they hold this and start-up points it at the real reporter once it exists.
class DeferredCrashReporter implements CrashReporter {
  CrashReporter target = const NoopCrashReporter();

  @override
  Future<void> record(CrashReport report) => target.record(report);
}

final crashReporterProvider = Provider<CrashReporter>((ref) => const NoopCrashReporter());
