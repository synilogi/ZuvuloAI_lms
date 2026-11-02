import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syniastrolms_mobile/app/app.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/app/routing/app_router.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/storage/preferences.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/features/auth/data/auth_repository.dart';
import 'package:syniastrolms_mobile/features/course_purchase/course_purchase.dart';
import 'package:syniastrolms_mobile/features/staff_billing/data/pending_payment_store.dart';

import 'fake_adapter.dart';
import 'test_config.dart';

/// Widget tests run on an 800×600 window by default, which is the tablet breakpoint; most of the
/// app's tests want a phone.
void useSurface(WidgetTester tester, {Size size = const Size(400, 800)}) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// The whole app with test dependencies: a fake token store and an overridable auth repository, so
/// a widget test can drive the real session controller without a network.
Future<Widget> testApp({
  required AuthRepository repository,
  Flavor flavor = Flavor.dev,
  Map<String, WidgetBuilder> devRoutes = const {},
  Map<String, Object> preferences = const {},
  FakeAdapter? adapter,
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  final prefs = Preferences(await SharedPreferences.getInstance());
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      // The platform's secure store has no implementation under test.
      pendingPaymentStoreProvider.overrideWithValue(MemoryPendingPaymentStore()),
      pendingPurchaseStoreProvider.overrideWithValue(MemoryPendingPurchaseStore()),
      appConfigProvider.overrideWithValue(
        AppConfig.fromValues(
          flavor: flavor,
          envName: flavor.name,
          apiBaseUrl: flavor == Flavor.dev ? 'http://10.0.2.2:4100' : 'https://api.test/api',
          webBaseUrl: 'https://web.test',
        ),
      ),
      preferencesProvider.overrideWithValue(prefs),
      tokenStoreProvider.overrideWithValue(FakeTokenStore()),
      // As `appRoot` does: shared code reads the signed-in person through this seam.
      currentUserProvider.overrideWith((ref) => ref.watch(sessionControllerProvider).user),
      authRepositoryProvider.overrideWithValue(repository),
      // The public screens talk to the real API client; a fake adapter answers it with captured
      // responses instead of the network.
      if (adapter != null)
        apiClientProvider.overrideWith(
          (ref) => ApiClient(
            config: ref.watch(appConfigProvider),
            tokenStore: ref.watch(tokenStoreProvider),
            logger: ref.watch(appLoggerProvider),
            adapter: adapter,
            logRequests: false,
          ),
        ),
      devRoutesProvider.overrideWithValue(devRoutes),
      ...overrides,
    ],
    child: SyniastroApp(flavor: flavor),
  );
}
