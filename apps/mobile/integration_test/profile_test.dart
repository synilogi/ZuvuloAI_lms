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
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/core/network/token_store.dart';
import 'package:syniastrolms_mobile/core/storage/preferences.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/profile/data/activity_api.dart';
import 'package:syniastrolms_mobile/shared/widgets/navigation/app_nav_bar.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

/// The profile, the app's own settings, and what signing out leaves behind — against the **real**
/// API on the scratch database, driving the app itself.
const _password = 'syniastrolms123';
const _learner = 'ananya@syniastrolms.test';
const _instructor = 'meenakshi@syniastrolms.test';

class _Token implements TokenStore {
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

  ApiClient clientFor(TokenStore store) => ApiClient(
    config: config,
    tokenStore: store,
    logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
    logRequests: false,
  );

  Future<ApiClient> signedInApi(String email) async {
    final store = _Token();
    final body = await clientFor(
      _Token(),
    ).post('/auth/login', body: {'email': email, 'password': _password});
    store.token = (body! as Map)['token'] as String;
    return clientFor(store);
  }

  /// A cold launch, sharing the device's real secure storage.
  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final preferences = Preferences(await SharedPreferences.getInstance());
    await tester.pumpWidget(appRoot(config: config, preferences: preferences));
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

  /// Scrolls [finder] onto the middle of the profile's own list — the **first** scrollable, not the
  /// last, which is the rank ladder's horizontal strip. The bottom navigation would take a tap aimed
  /// at the last item, and a blind extra drag can push a nearly-visible one off the other edge, so
  /// the item is landed on the midline whichever side it came from.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
    await tester.pumpAndSettle();
    final delta = tester.getRect(scrollable).center.dy - tester.getCenter(finder).dy;
    // A drag shorter than the gesture slop reads as a **tap**, which would open the very tile this
    // is trying to reach — and the item is already on the midline anyway, so leave the list alone.
    if (delta.abs() > kDragSlopDefault) {
      await tester.drag(scrollable, Offset(0, delta));
      await tester.pumpAndSettle();
    }
  }

  Future<void> signOut(WidgetTester tester) async {
    await reveal(tester, find.widgetWithText(AppButton, 'Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AppDialog), matching: find.text('Sign out')));
    await tester.pumpAndSettle();
  }

  testWidgets('the activity feed is the learner\'s own, and nobody else may read it', (
    tester,
  ) async {
    final activity = await ActivityApi(await signedInApi(_learner)).activity();

    expect(activity.week, hasLength(7));
    expect(activity.events, isNotEmpty);
    expect(activity.events.every((e) => e.title.isNotEmpty), isTrue);
    expect(activity.events.every((e) => e.at.isUtc), isTrue);

    // The route is a learner's; the academy refuses everyone else rather than answering emptily.
    await expectLater(
      ActivityApi(await signedInApi(_instructor)).activity(),
      throwsA(isA<ApiException>()),
    );
  });

  testWidgets('the profile is what the academy answers for, and signing out empties the device', (
    tester,
  ) async {
    await launch(tester);
    await signIn(tester, _learner);
    await openProfile(tester);

    // `GET /auth/me`, not anything the app kept.
    expect(find.text('Ananya Rao'), findsOneWidget);
    expect(find.text(_learner), findsOneWidget);
    expect(find.text('Learner'), findsOneWidget);
    expect(find.text('Your standing'), findsOneWidget);
    expect(await tokens.read(), isNotNull);

    await signOut(tester);

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(await tokens.read(), isNull, reason: 'the token is gone from the device');
  });

  testWidgets('signing in as someone else shows none of the last person\'s profile', (
    tester,
  ) async {
    await launch(tester);
    await signIn(tester, _learner);
    await openProfile(tester);
    expect(find.text('Ananya Rao'), findsOneWidget);
    await signOut(tester);

    await signIn(tester, _instructor);
    await openProfile(tester);

    expect(find.text('Dr. Meenakshi Iyer'), findsOneWidget);
    expect(find.text('Ananya Rao'), findsNothing);
    expect(find.text(_learner), findsNothing);
    // A staff profile has no learner standing or activity at all.
    expect(find.text('Your standing'), findsNothing);
    expect(find.text('Recently'), findsNothing);
  });

  testWidgets('the app\'s own settings are the device\'s, and survive signing out', (tester) async {
    await launch(tester);
    await signIn(tester, _learner);
    await openProfile(tester);

    await reveal(tester, find.text('App settings'));
    await tester.tap(find.text('App settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Dark'))).brightness,
      Brightness.dark,
      reason: 'the choice applies at once, across the whole app',
    );

    // It belongs to the device, so signing out leaves it alone. The settings are a shell body,
    // so the way back is the shell's own Profile destination.
    await openProfile(tester);
    await signOut(tester);

    final prefs = Preferences(await SharedPreferences.getInstance());
    expect(prefs.themeMode, ThemeMode.dark);
  });
}
