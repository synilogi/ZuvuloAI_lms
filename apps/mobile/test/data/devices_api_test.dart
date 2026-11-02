import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/features/notifications/notifications.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/test_config.dart';

/// `POST|GET|DELETE /notifications/devices` (SAAS-021, B4). The token is a credential for the device:
/// it is sent once and the route never echoes it back, so nothing the app holds afterwards could leak
/// it (§18).
const _token = 'fMEP0vJqSy2tXQ7bN4cR8wZ3kD6hG9jL1mV5nA0pT7xB2yC4eF6gH8iJ0kL2mN4oP6qR8sT0uV2wX4yZ6a';

Map<String, dynamic> _device({bool current = true}) => {
  'id': 'dev_1',
  'platform': 'android',
  'tokenEnd': _token.substring(_token.length - 8),
  'current': current,
  'createdAt': '2026-09-30T10:00:00.000Z',
  'lastSeenAt': '2026-09-30T13:00:00.000Z',
};

void main() {
  late FakeAdapter adapter;
  late NotificationsApi api;

  setUp(() {
    adapter = FakeAdapter();
    api = NotificationsApi(
      ApiClient(
        config: testConfig(),
        tokenStore: FakeTokenStore('jwt'),
        logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
        adapter: adapter,
        logRequests: false,
      ),
    );
  });

  test('registering sends the token and the platform, and nothing else', () async {
    adapter.enqueueJson(_device());

    final device = await api.registerDevice(token: '  $_token  ');

    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.path, '/notifications/devices');
    final body = adapter.lastRequest.data! as Map<String, Object?>;
    expect(body.keys.toSet(), {'token', 'platform'});
    expect(body['token'], _token, reason: 'trimmed, as the route trims it');
    expect(body['platform'], 'android');
    // The account is the token's; the app never says whose device it is (§7).
    expect(body.containsKey('userId'), isFalse);
    expect(body.containsKey('tenantId'), isFalse);
    expect(device.id, 'dev_1');
  });

  test('the answer carries the end of the token and never the token', () async {
    adapter.enqueueJson(_device());

    final device = await api.registerDevice(token: _token);

    expect(device.tokenEnd, hasLength(8));
    expect(device.tokenEnd, _token.substring(_token.length - 8));
    expect(device.toString(), isNot(contains(_token)));
    expect(device.current, isTrue);
  });

  test('another platform travels by its own word', () async {
    adapter.enqueueJson({..._device(), 'platform': 'ios'});

    await api.registerDevice(token: _token, platform: DevicePlatform.ios);

    expect((adapter.lastRequest.data! as Map)['platform'], 'ios');
  });

  test('the devices on an account are listed, newest seen first as the route sends them', () async {
    adapter.enqueueJson({
      'devices': [
        _device(),
        {..._device(current: false), 'id': 'dev_2', 'lastSeenAt': '2026-09-29T13:00:00.000Z'},
      ],
    });

    final devices = await api.devices();

    expect(adapter.lastRequest.method, 'GET');
    expect(adapter.lastRequest.path, '/notifications/devices');
    expect(devices, hasLength(2));
    expect(devices.first.current, isTrue);
    expect(devices.last.current, isFalse);
  });

  test('unregistering is a delete on the device, with no body', () async {
    adapter.enqueue((_) async => FakeAdapter.noContent());

    await api.unregisterDevice('dev 1');

    expect(adapter.lastRequest.method, 'DELETE');
    expect(adapter.lastRequest.path, '/notifications/devices/dev%201');
    expect(adapter.lastRequest.data, isNull);
  });

  test('a token the route would refuse is recognised before it is sent', () async {
    // The route's schema takes 20 to 4096 characters.
    expect(deviceTokenIsUsable(''), isFalse);
    expect(deviceTokenIsUsable('too-short'), isFalse);
    expect(deviceTokenIsUsable('  ${'a' * 19}  '), isFalse);
    expect(deviceTokenIsUsable('a' * minDeviceToken), isTrue);
    expect(deviceTokenIsUsable('a' * maxDeviceToken), isTrue);
    expect(deviceTokenIsUsable('a' * (maxDeviceToken + 1)), isFalse);
  });
}
