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
import 'package:syniastrolms_mobile/shared/widgets/navigation/app_nav_bar.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

/// The auth journeys against the **real** API on the scratch database
/// (`tool/contract_server.sh start`), from the emulator at http://10.0.2.2:4100.
///
/// Seeded accounts (`apps/api/prisma/seed.ts`) and the super admin created for this database all
/// use the demo password below; it is a local fixture, never a real credential.
const _password = 'syniastrolms123';
const _admin = 'admin@syniastrolms.test';
const _instructor = 'meenakshi@syniastrolms.test';
const _student = 'ananya@syniastrolms.test';
const _superAdmin = 'ops@syniastrolms.test';

class _AdminToken implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppConfig config;
  late SecureTokenStore tokens;

  setUpAll(() async => initializeDateFormatting('en'));

  setUp(() async {
    config = AppConfig.fromEnvironment(Flavor.dev);
    tokens = SecureTokenStore(environment: config.flavor.name);
    await tokens.clear();
    SharedPreferences.setMockInitialValues({});
  });

  /// Starts the app as a cold launch would, sharing the device's real secure storage. Tearing the
  /// tree down first matters: pumping another `appRoot` on its own would reuse the existing
  /// `ProviderScope`, keeping the session alive and never re-running the restore.
  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final preferences = Preferences(await SharedPreferences.getInstance());
    await tester.pumpWidget(appRoot(config: config, preferences: preferences));
    await tester.pumpAndSettle();
  }

  /// The shell's Profile tab, where signing out lives.
  Future<void> openProfile(WidgetTester tester) async {
    // A learner's Profile is a tab of the bar; staff reach theirs through "More".
    Finder inBar(String label) =>
        find.descendant(of: find.byType(AppNavBar), matching: find.text(label));
    if (inBar('More').evaluate().isNotEmpty) {
      await tester.tap(inBar('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile').last);
    } else {
      await tester.tap(inBar('Profile'));
    }
    await tester.pumpAndSettle();
  }

  /// Signing out from the profile, which says what it removes from the device first (§22.5).
  Future<void> signOut(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.widgetWithText(AppButton, 'Sign out'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    // Clear of the bottom navigation, which would otherwise take the tap.
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AppDialog), matching: find.text('Sign out')));
    await tester.pumpAndSettle();
  }

  Future<void> signIn(WidgetTester tester, String email) async {
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, email);
    await tester.enterText(find.byType(TextField).last, _password);
    await tester.tap(find.widgetWithText(AppButton, 'Sign in').last);
    await tester.pumpAndSettle();
  }

  ApiClient apiAs(TokenStore store) => ApiClient(
    config: config,
    tokenStore: store,
    logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
    logRequests: false,
  );

  testWidgets('each seeded role signs in and lands in the app', (tester) async {
    for (final account in [
      (_student, 'Ananya Rao'),
      (_instructor, 'Dr. Meenakshi Iyer'),
      (_admin, 'Kavita Menon'),
    ]) {
      await tokens.clear();
      await launch(tester);
      await signIn(tester, account.$1);

      expect(find.byType(AppNavBar), findsOneWidget, reason: account.$1);
      expect(await tokens.read(), isNotNull);

      await openProfile(tester);
      expect(find.text(account.$2), findsOneWidget, reason: account.$1);

      await signOut(tester);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(await tokens.read(), isNull, reason: 'signing out drops the token');
    }
  });

  testWidgets('a super admin is refused and no token is kept', (tester) async {
    await launch(tester);
    await signIn(tester, _superAdmin);

    expect(find.byType(UnsupportedRoleScreen), findsOneWidget);
    expect(await tokens.read(), isNull);
  });

  testWidgets('register, then a relaunch restores the session through /auth/me', (tester) async {
    final email = 'flutter+${DateTime.now().millisecondsSinceEpoch}@syniastrolms.test';
    await launch(tester);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I want to learn'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Flutter Learner');
    await tester.enterText(find.byType(TextField).at(1), email);
    await tester.enterText(find.byType(TextField).at(2), _password);
    await tester.tap(find.widgetWithText(AppButton, 'Create account').last);
    await tester.pumpAndSettle();

    expect(find.byType(AppNavBar), findsOneWidget);

    // Cold launch with the token still in secure storage.
    await launch(tester);
    expect(find.byType(AppNavBar), findsOneWidget);
    await openProfile(tester);
    expect(find.text('Flutter Learner'), findsOneWidget);
  });

  testWidgets('a tampered token ends the session on the next launch', (tester) async {
    await launch(tester);
    await signIn(tester, _student);
    expect(find.byType(AppNavBar), findsOneWidget);

    final stored = await tokens.read();
    await tokens.write('${stored!.substring(0, stored.length - 4)}0000');
    await launch(tester);

    debugPrint(
      'after relaunch: ${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).toList()}',
    );
    expect(find.text('Your session ended. Sign in again.'), findsOneWidget);
    expect(await tokens.read(), isNull);
  });

  testWidgets('a learner suspended by their admin is signed out with the server\'s message', (
    tester,
  ) async {
    final email = 'flutter+susp${DateTime.now().millisecondsSinceEpoch}@syniastrolms.test';
    await launch(tester);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I want to learn'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Suspended Learner');
    await tester.enterText(find.byType(TextField).at(1), email);
    await tester.enterText(find.byType(TextField).at(2), _password);
    await tester.tap(find.widgetWithText(AppButton, 'Create account').last);
    await tester.pumpAndSettle();
    expect(find.byType(AppNavBar), findsOneWidget);

    // Their admin suspends them, through the real API as the seeded admin.
    final adminStore = _AdminToken();
    final adminApi = apiAs(adminStore);
    final login = await adminApi.post(
      '/auth/login',
      body: {'email': _admin, 'password': _password},
    );
    adminStore.token = (login! as Map)['token'] as String;
    final roster = await adminApi.get('/students', query: {'search': email});
    final rows = (roster! as Map)['rows']! as List<dynamic>;
    // A roster row nests the learner under `student` (`routes/students.ts`).
    final studentId = ((rows.single as Map)['student']! as Map)['id'] as String;
    await adminApi.post('/students/$studentId/suspend', body: {'suspended': true});

    await launch(tester);

    expect(find.text('This account is suspended. Contact your admin to continue.'), findsOneWidget);
    expect(await tokens.read(), isNull);
  });
}
