import 'package:flutter/foundation.dart';

import '../core/logging/crash_reporter.dart';

/// Routes every uncaught error to the [CrashReporter], redacted (§16): framework errors
/// (`FlutterError.onError`), platform-dispatcher errors, and the guarded zone's errors.
class ErrorHooks {
  ErrorHooks(this._reporter);

  final CrashReporter _reporter;

  void install() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (kDebugMode) previous?.call(details);
      handleFlutterError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      handleUncaught(error, stack);
      return true;
    };
  }

  void handleFlutterError(FlutterErrorDetails details) {
    _reporter.record(
      CrashReport(
        error: details.exception,
        stack: details.stack,
        context: details.context?.toDescription(),
        fields: {'library': details.library},
        fatal: false,
      ),
    );
  }

  /// Zone and platform errors. Debug builds also print them — with no crash vendor yet, the
  /// reporter discards reports, and a start-up failure must not vanish silently for developers.
  void handleUncaught(Object error, StackTrace stack) {
    if (kDebugMode) {
      FlutterError.presentError(
        FlutterErrorDetails(exception: error, stack: stack, library: 'uncaught (zone)'),
      );
    }
    _reporter.record(CrashReport(error: error, stack: stack, fatal: true));
  }
}
