import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/notifications/notifications.dart';

/// Contract test (§23) for the device registry, against what the real API returned after a device was
/// registered through `POST /notifications/devices` and then taken off again —
/// `test/fixtures/learner/devices.json`, captured with `tool/capture_fixture.sh`.
Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

void main() {
  test('a registered device carries the end of its token and nothing more', () {
    final body = _fixture('learner/devices.json')! as Map<String, dynamic>;
    final devices = [
      for (final row in body['devices']! as List<dynamic>)
        RegisteredDevice.fromJson(row as Map<String, dynamic>),
    ];

    expect(devices, hasLength(1));
    final device = devices.single;
    expect(device.id, isNotEmpty);
    expect(device.platform, 'android');
    // The token is a credential for the device. The route sends eight characters of it, and that is
    // all the app ever sees of it again (§18).
    expect(device.tokenEnd, hasLength(8));
    expect(device.createdAt.isUtc, isTrue);
    expect(device.lastSeenAt.isUtc, isTrue);
  });

  test('`current` is the session that registered it, not merely the account', () {
    // The fixture was captured from a second sign-in, so the device is the account's but not this
    // session's — which is exactly the distinction the route draws.
    final body = _fixture('learner/devices.json')! as Map<String, dynamic>;
    final device = RegisteredDevice.fromJson(
      (body['devices']! as List<dynamic>).first as Map<String, dynamic>,
    );

    expect(device.current, isFalse);
  });

  test('the platforms the app may name are the ones the route accepts', () {
    expect(DevicePlatform.values.map((p) => p.name), ['android', 'ios', 'web']);
  });
}
