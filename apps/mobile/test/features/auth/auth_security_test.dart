import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/features/auth/data/auth_api.dart';
import 'package:syniastrolms_mobile/features/auth/data/secure_token_store.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/test_config.dart';

const _jwt =
    'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1MSIsInJvbGUiOiJzdHVkZW50In0.s1gnatur3s1gnatur3s1gnatur3';
const _password = 'syniastrolms123';
const _resetToken = '0123456789abcdef0123456789abcdef';

void main() {
  group('nothing secret reaches the log', () {
    test('signing in, restoring and resetting a password log no token or password', () async {
      final lines = <String>[];
      final adapter = FakeAdapter();
      final tokens = FakeTokenStore(_jwt);
      final client = ApiClient(
        config: testConfig(),
        tokenStore: tokens,
        logger: AppLogger(
          reporter: const NoopCrashReporter(),
          minLevel: LogLevel.debug,
          sink: (line, _) => lines.add(line),
        ),
        adapter: adapter,
        logRequests: true,
      );
      final api = AuthApi(client);
      const profile = {
        'id': 'u1',
        'name': 'Asha Verma',
        'email': 'asha@syniastrolms.test',
        'role': 'student',
        'descriptor': 'Learner',
        'permissions': <String>[],
      };
      adapter
        ..enqueueJson({'token': _jwt, 'user': profile})
        ..enqueueJson({'user': profile})
        ..enqueueJson({'valid': true})
        ..enqueueJson({'ok': true});

      await api.login(email: 'asha@syniastrolms.test', password: _password);
      await api.me();
      await api.isResetTokenValid(_resetToken);
      await api.resetPassword(token: _resetToken, password: _password);

      final log = lines.join('\n');
      expect(log, isNotEmpty, reason: 'the requests were logged at all');
      expect(log, isNot(contains(_password)));
      expect(log, isNot(contains(_jwt)));
      expect(log, isNot(contains(_resetToken)));
      expect(log, isNot(contains('Bearer ')));
      expect(log, isNot(contains('Authorization')));
    });

    test('a logged reset link is masked', () {
      final lines = <String>[];
      AppLogger(
        reporter: const NoopCrashReporter(),
        minLevel: LogLevel.debug,
        sink: (line, _) => lines.add(line),
      ).debug('opened https://academy.test/reset-password/$_resetToken');

      expect(lines.single, contains('/reset-password/[redacted]'));
      expect(lines.single, isNot(contains(_resetToken)));
    });
  });

  group('SecureTokenStore', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('writes, reads and clears the token', () async {
      final store = SecureTokenStore(environment: 'dev', storage: const FlutterSecureStorage());

      expect(await store.read(), isNull);
      await store.write(_jwt);
      expect(await store.read(), _jwt);
      await store.clear();
      expect(await store.read(), isNull);
    });

    test('a token stored for one environment is not read by another', () async {
      const storage = FlutterSecureStorage();
      await SecureTokenStore(environment: 'staging', storage: storage).write(_jwt);

      expect(await SecureTokenStore(environment: 'prod', storage: storage).read(), isNull);
      expect(await SecureTokenStore(environment: 'staging', storage: storage).read(), _jwt);
    });

    test('an empty stored value reads as no token', () async {
      FlutterSecureStorage.setMockInitialValues({'session.token.dev': ''});

      expect(
        await SecureTokenStore(environment: 'dev', storage: const FlutterSecureStorage()).read(),
        isNull,
      );
    });
  });
}
