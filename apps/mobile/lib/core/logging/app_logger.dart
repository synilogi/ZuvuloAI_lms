import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'crash_reporter.dart';
import 'redactor.dart';

enum LogLevel { debug, info, warn, error }

/// The app's only logger (§18): every message and field is redacted; release builds keep warnings
/// and errors only; errors are forwarded to the [CrashReporter].
class AppLogger {
  AppLogger({
    required CrashReporter reporter,
    LogLevel? minLevel,
    void Function(String line, LogLevel level)? sink,
  }) : _reporter = reporter,
       minLevel = minLevel ?? (kReleaseMode ? LogLevel.warn : LogLevel.debug),
       _sink = sink ?? _developerSink;

  final CrashReporter _reporter;
  final LogLevel minLevel;
  final void Function(String line, LogLevel level) _sink;

  static void _developerSink(String line, LogLevel level) => developer.log(
    line,
    name: 'syniastro',
    level: switch (level) {
      LogLevel.debug => 500,
      LogLevel.info => 800,
      LogLevel.warn => 900,
      LogLevel.error => 1000,
    },
  );

  void debug(String message, [Map<String, Object?> fields = const {}]) =>
      _write(LogLevel.debug, message, fields);

  void info(String message, [Map<String, Object?> fields = const {}]) =>
      _write(LogLevel.info, message, fields);

  void warn(String message, [Map<String, Object?> fields = const {}]) =>
      _write(LogLevel.warn, message, fields);

  /// Logs and reports [error]. [fields] must never include a response body.
  void error(
    String message, {
    Object? error,
    StackTrace? stack,
    Map<String, Object?> fields = const {},
  }) {
    _write(LogLevel.error, message, {...fields, if (error != null) 'error': error.toString()});
    if (error != null) {
      _reporter.record(CrashReport(error: error, stack: stack, context: message, fields: fields));
    }
  }

  void _write(LogLevel level, String message, Map<String, Object?> fields) {
    if (level.index < minLevel.index) return;
    final safeFields = fields.isEmpty ? '' : ' ${Redactor.redact(fields)}';
    _sink('[${level.name}] ${Redactor.redactText(message)}$safeFields', level);
  }
}

final appLoggerProvider = Provider<AppLogger>(
  (ref) => AppLogger(reporter: ref.watch(crashReporterProvider)),
);
