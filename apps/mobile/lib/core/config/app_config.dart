import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'flavor.dart';

/// The server a plain `flutter run` / `flutter build apk` from `lib/main.dart` talks to when no
/// `--dart-define-from-file` is passed. Change these two lines to point the app at another server.
/// The API is mounted under `/api`; the bare domain serves the web app.
const String kDefaultApiBaseUrl = 'https://zuviloai.com/api';
const String kDefaultWebBaseUrl = 'https://zuviloai.com';

/// Thrown at start-up when the build's `--dart-define-from-file` values are missing or unsafe.
class ConfigException implements Exception {
  const ConfigException(this.message);

  final String message;

  @override
  String toString() => 'ConfigException: $message';
}

/// The build's public configuration (modules.md §24), read once at start-up from
/// `--dart-define-from-file=config/<flavor>.json` and validated before the app runs.
class AppConfig {
  const AppConfig._({
    required this.flavor,
    required this.apiBaseUrl,
    required this.webBaseUrl,
    required this.billingCheckoutEnabled,
    required this.courseCheckoutEnabled,
    required this.crashReportingEnabled,
    required this.pushEnabled,
  });

  /// Reads the compile-time defines for [flavor] and validates them.
  factory AppConfig.fromEnvironment(Flavor flavor) => AppConfig.fromValues(
    flavor: flavor,
    envName: const String.fromEnvironment('ENV_NAME'),
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
    webBaseUrl: const String.fromEnvironment('WEB_BASE_URL'),
    billingCheckoutEnabled: const bool.fromEnvironment('BILLING_CHECKOUT_ENABLED'),
    courseCheckoutEnabled: const bool.fromEnvironment('COURSE_CHECKOUT_ENABLED'),
    crashReportingEnabled: const bool.fromEnvironment('CRASH_REPORTING_ENABLED'),
    pushEnabled: const bool.fromEnvironment('PUSH_ENABLED'),
  );

  /// The dev config for `lib/main.dart`, the default entry point a plain `flutter run` (or the IDE's
  /// `main.dart` configuration) uses. A define file passed to it still wins and is validated as
  /// usual (`config/dev.json` for the local contract server); with none, it targets
  /// [kDefaultApiBaseUrl] and [kDefaultWebBaseUrl]. Built
  /// with any other `--flavor` it refuses, so a staging or prod app id never runs dev code.
  factory AppConfig.devFromEnvironmentOrLocal() {
    if (appFlavor != null && appFlavor != Flavor.dev.name) {
      throw const ConfigException(
        'lib/main.dart is the dev entry point, but this is a $appFlavor build. Run with '
        '-t lib/main_$appFlavor.dart --dart-define-from-file=config/$appFlavor.json.',
      );
    }
    return const bool.hasEnvironment('ENV_NAME')
        ? AppConfig.fromEnvironment(Flavor.dev)
        : AppConfig.fromValues(
            flavor: Flavor.dev,
            envName: 'dev',
            apiBaseUrl: kDefaultApiBaseUrl,
            webBaseUrl: kDefaultWebBaseUrl,
            pushEnabled: true,
          );
  }

  /// Validates raw values: both URLs absolute http(s) with a host, HTTPS required outside dev,
  /// no query or fragment, and `ENV_NAME` matching the entry point's flavor (so a staging config
  /// can never be paired with the prod entry point).
  factory AppConfig.fromValues({
    required Flavor flavor,
    required String envName,
    required String apiBaseUrl,
    required String webBaseUrl,
    bool billingCheckoutEnabled = false,
    bool courseCheckoutEnabled = false,
    bool crashReportingEnabled = false,
    bool pushEnabled = false,
  }) {
    if (envName != flavor.name) {
      throw ConfigException(
        'ENV_NAME is "$envName" but this is the ${flavor.name} entry point. Run with '
        '--dart-define-from-file=config/${flavor.name}.json.',
      );
    }
    return AppConfig._(
      flavor: flavor,
      apiBaseUrl: _url('API_BASE_URL', apiBaseUrl, flavor),
      webBaseUrl: _url('WEB_BASE_URL', webBaseUrl, flavor),
      billingCheckoutEnabled: billingCheckoutEnabled,
      courseCheckoutEnabled: courseCheckoutEnabled,
      crashReportingEnabled: crashReportingEnabled,
      pushEnabled: pushEnabled,
    );
  }

  static Uri _url(String name, String value, Flavor flavor) {
    if (value.isEmpty) {
      throw ConfigException(
        '$name is not set. Run with --dart-define-from-file=config/${flavor.name}.json.',
      );
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw ConfigException('$name must be an absolute URL, got "$value".');
    }
    if (uri.scheme != 'https' && !(flavor == Flavor.dev && uri.scheme == 'http')) {
      throw ConfigException('$name must use https outside the dev flavor, got "$value".');
    }
    if (uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) {
      throw ConfigException('$name must not carry a query, fragment or credentials.');
    }
    // Normalise: no trailing slash, so paths join as base + '/path'.
    final path = uri.path.endsWith('/') ? uri.path.substring(0, uri.path.length - 1) : uri.path;
    return uri.replace(path: path);
  }

  final Flavor flavor;

  /// The API root, e.g. `https://host/api` (production mounts the API under `/api`).
  final Uri apiBaseUrl;

  /// The web app, for "open on the web" and certificate verification links.
  final Uri webBaseUrl;

  /// In-app SaaS checkout (§11.5); false until store-policy approval (C4).
  final bool billingCheckoutEnabled;

  /// A learner buying a paid course in the app (`COURSE_CHECKOUT_ENABLED`, off when absent). Online
  /// courses are digital content, which Google Play and the App Store sell only through their own
  /// billing, so every build that reaches production keeps it off: there a paid course shows its
  /// price and a neutral line, and nothing else. On in the dev configs, where the flow is built and
  /// tried.
  final bool courseCheckoutEnabled;

  /// Crash reporting (§24); false until a vendor is chosen (C7).
  final bool crashReportingEnabled;

  /// Push notifications (FLUTTER-028 Part B): the device registers its Firebase token after sign-in
  /// and shows the academy's notifications when a push hint arrives. Off in tests and in a build
  /// without the flag, where nothing touches Firebase Messaging.
  final bool pushEnabled;

  bool get isDev => flavor == Flavor.dev;
}

/// The validated configuration; overridden by `bootstrap` (and by tests).
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw StateError('appConfigProvider must be overridden at start-up'),
);
