import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/token_store.dart';
import 'package:syniastrolms_mobile/core/storage/preferences.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/shared/entitlements/entitlements.dart';
import 'package:syniastrolms_mobile/shared/widgets/navigation/app_nav_bar.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

/// Against the **real** API on the scratch database, whose seeded academy is served no plan.
const _password = 'syniastrolms123';

class _Token implements TokenStore {
  _Token(this.token);

  final String? token;

  @override
  Future<String?> read() async => token;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppConfig config;
  late SecureTokenStore tokens;

  setUp(() async {
    await initializeDateFormatting('en');
    config = AppConfig.fromEnvironment(Flavor.dev);
    tokens = SecureTokenStore(environment: config.flavor.name);
    await tokens.clear();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> launchAndSignIn(WidgetTester tester, String email) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final preferences = Preferences(await SharedPreferences.getInstance());
    await tester.pumpWidget(appRoot(config: config, preferences: preferences));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, email);
    await tester.enterText(find.byType(TextField).last, _password);
    await tester.tap(find.widgetWithText(AppButton, 'Sign in').last);
    await tester.pumpAndSettle();
  }

  /// `pumpAndSettle` waits for frames, not for the network; the plan is read after sign-in.
  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) return;
    }
  }

  /// What `GET /academy/plan` says of the seeded academy, read as the admin.
  Future<AcademyPlan> planOnServer() async {
    ApiClient client(String? token) => ApiClient(
      config: config,
      tokenStore: _Token(token),
      logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
      logRequests: false,
    );
    final login = await client(
      null,
    ).post('/auth/login', body: {'email': 'admin@syniastrolms.test', 'password': _password});
    return AcademyPlanApi(client((login! as Map)['token'] as String)).read();
  }

  testWidgets('an academy admin is shown the plan state only while plans are enforced', (
    tester,
  ) async {
    final plan = await planOnServer();
    await launchAndSignIn(tester, 'admin@syniastrolms.test');

    if (plan.needsOnboarding) {
      // A never-subscribed academy's admin lands on choose-a-plan instead of the dashboard.
      await waitFor(tester, find.text('Get started'));
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('Not now — go to the dashboard'), findsOneWidget);
    } else if (plan.restrictionBites) {
      // A lapsed plan: the restricted banner, once the plan is read after sign-in.
      await waitFor(tester, find.text('Your academy has no active plan'));
      expect(find.text('Your academy has no active plan'), findsOneWidget);
      expect(find.text('Review plan'), findsOneWidget);
    } else {
      // While the platform does not enforce plans nothing is refused, so nothing is warned of.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Your academy has no active plan'), findsNothing);
      expect(find.text('Get started'), findsNothing);
    }
  });

  testWidgets('an instructor never sees the academy\'s billing state', (tester) async {
    await launchAndSignIn(tester, 'meenakshi@syniastrolms.test');
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Your academy has no active plan'), findsNothing);
    expect(find.byType(AppNavBar), findsOneWidget);
  });

  testWidgets('a learner sees neither the banner nor any staff destination', (tester) async {
    await launchAndSignIn(tester, 'ananya@syniastrolms.test');

    expect(find.text('Your academy has no active plan'), findsNothing);
    expect(find.text('Dashboard'), findsNothing);
    expect(find.text('Home'), findsWidgets);
  });
}
