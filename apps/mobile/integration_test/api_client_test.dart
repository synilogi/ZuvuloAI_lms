import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/core/network/json.dart';
import 'package:syniastrolms_mobile/core/network/token_store.dart';
import 'package:syniastrolms_mobile/shared/domain/level.dart';

class _NoToken implements TokenStore {
  @override
  Future<String?> read() async => null;
}

/// Runs against the **real** API on the scratch database (`tool/contract_server.sh start`), reached
/// from the emulator at http://10.0.2.2:4100 (workflow §7.3).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient client;

  setUp(() {
    client = ApiClient(
      config: AppConfig.fromEnvironment(Flavor.dev),
      tokenStore: _NoToken(),
      logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
      logRequests: false,
    );
  });

  testWidgets('GET /health answers {ok: true}', (tester) async {
    expect(await client.get('/health'), {'ok': true});
  });

  testWidgets('GET /catalog/levels parses into the Level model', (tester) async {
    final body = await client.get('/catalog/levels');

    final levels = [
      for (final row in asJsonList('/catalog/levels', body))
        Level.fromJson(row as Map<String, dynamic>),
    ];
    expect(levels, isNotEmpty);
    expect(levels.first.order, 1);
  });

  testWidgets('an unauthenticated protected route is decoded as 401', (tester) async {
    await expectLater(
      client.get('/auth/me'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          isA<UnauthenticatedFailure>().having((f) => f.message, 'message', 'Sign in required'),
        ),
      ),
    );
  });

  testWidgets('an unknown course is decoded as not found', (tester) async {
    await expectLater(
      client.get('/catalog/courses/does-not-exist'),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
    );
  });
}
