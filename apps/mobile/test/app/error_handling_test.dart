import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/app/config_error_app.dart';
import 'package:syniastrolms_mobile/app/error_hooks.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/storage/preferences.dart';
import 'package:syniastrolms_mobile/l10n/l10n.dart';
import 'package:syniastrolms_mobile/shared/widgets/errors/error_boundary.dart';

import '../helpers/pump.dart';

class _FakeReporter implements CrashReporter {
  final reports = <CrashReport>[];

  @override
  Future<void> record(CrashReport report) async => reports.add(report);
}

class _Exploding extends StatelessWidget {
  const _Exploding();

  @override
  Widget build(BuildContext context) =>
      throw StateError('render failed for Bearer abcdefghijklmnop');
}

void main() {
  group('ErrorBoundary', () {
    testWidgets('a crashed widget shows the friendly view with Go home, never the error', (
      tester,
    ) async {
      final original = ErrorWidget.builder;
      // Restored inside the body: the binding checks ErrorWidget.builder before tear-downs run.
      try {
        var wentHome = false;
        ErrorBoundary.install(onGoHome: (_) => wentHome = true);

        await tester.pumpWidget(themedHarness(const _Exploding(), scroll: false));
        expect(tester.takeException(), isA<StateError>());

        expect(find.text('This screen stopped working'), findsOneWidget);
        expect(find.textContaining('StateError'), findsNothing);
        expect(find.textContaining('Bearer'), findsNothing);
        await tester.tap(find.text('Go home'));
        expect(wentHome, isTrue);
      } finally {
        ErrorWidget.builder = original;
      }
    });

    testWidgets('renders even above the app\'s theme and localizations', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(),
            child: Material(child: ErrorBoundary()),
          ),
        ),
      );
      expect(find.text('This screen stopped working'), findsOneWidget);
    });
  });

  test('uncaught framework and zone errors reach the crash reporter, redacted', () {
    final reporter = _FakeReporter();
    final hooks = ErrorHooks(reporter);
    hooks.handleFlutterError(
      FlutterErrorDetails(
        exception: StateError('token=abcdef123456 leaked'),
        library: 'widgets library',
        context: ErrorDescription('while building LessonScreen'),
      ),
    );
    hooks.handleUncaught(Exception('Authorization: Bearer abcdefghijklmnop'), StackTrace.empty);

    expect(reporter.reports, hasLength(2));
    expect(reporter.reports.first.message, contains('token=[redacted]'));
    expect(reporter.reports.first.context, 'while building LessonScreen');
    expect(reporter.reports.first.fatal, isFalse);
    expect(reporter.reports.last.message, contains('Bearer [redacted]'));
    expect(reporter.reports.last.fatal, isTrue);
  });

  group('ConfigErrorApp', () {
    testWidgets('shows the reason in dev builds', (tester) async {
      await tester.pumpWidget(
        const ConfigErrorApp(message: 'API_BASE_URL is not set.', showDetail: true),
      );
      expect(find.text("This build isn't set up correctly"), findsOneWidget);
      expect(find.text('API_BASE_URL is not set.'), findsOneWidget);
    });

    testWidgets('hides the reason in other builds', (tester) async {
      await tester.pumpWidget(
        const ConfigErrorApp(message: 'API_BASE_URL is not set.', showDetail: false),
      );
      expect(find.text('API_BASE_URL is not set.'), findsNothing);
    });
  });

  testWidgets('appRoot provides the config, reporter and preferences', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = Preferences(await SharedPreferences.getInstance());
    final config = AppConfig.fromValues(
      flavor: Flavor.prod,
      envName: 'prod',
      apiBaseUrl: 'https://academy.example/api',
      webBaseUrl: 'https://academy.example',
    );
    await tester.pumpWidget(appRoot(config: config, preferences: preferences));
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold)));
    expect(container.read(appConfigProvider).apiBaseUrl.host, 'academy.example');
    expect(container.read(crashReporterProvider), isA<NoopCrashReporter>());
    expect(container.read(preferencesProvider), same(preferences));
  });

  testWidgets('a localized string renders through the generated localizations', (tester) async {
    await tester.pumpWidget(
      themedHarness(Builder(builder: (context) => Text(context.l10n.actionRetry)), scroll: false),
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
  });
}
