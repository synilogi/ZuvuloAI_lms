import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/push/push_platform.dart';
import 'package:syniastrolms_mobile/features/notifications/notifications.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/test_config.dart';

/// FLUTTER-028 Part B: a push is a hint (an id and a category). The app reads the notification it
/// points at from the unread list — never the detail route, which marks it read — and shows that.
const _id = 'ntf_4f9a2c7e1b';
const _token = 'fMEP0vJqSy2tXQ7bN4cR8wZ3kD6hG9jL1mV5nA0pT7xB2yC4eF6gH8iJ0kL2mN4oP6qR8sT0uV2wX4yZ6a';

Map<String, dynamic> _row(String id, {String title = 'Live class at 6 PM', String summary = ''}) =>
    {
      'id': id,
      'category': 'live',
      'title': title,
      'summary': summary,
      'createdAt': '2026-10-22T10:00:00.000Z',
    };

Map<String, dynamic> _page(List<Map<String, dynamic>> rows) => {
  'rows': rows,
  'total': rows.length,
  'unread': rows.length,
};

class _Shown {
  const _Shown(this.id, this.title, this.body);
  final String id;
  final String title;
  final String? body;
}

class _FakeDisplay implements PushDisplay {
  final shown = <_Shown>[];
  int permissionRequests = 0;
  String? launched;
  void Function(String)? onOpen;

  @override
  Future<void> initialize({void Function(String notificationId)? onOpen}) async =>
      this.onOpen = onOpen;

  @override
  Future<String?> launchNotificationId() async => launched;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<void> show({required String notificationId, required String title, String? body}) async =>
      shown.add(_Shown(notificationId, title, body));
}

class _FakeMessaging implements PushMessaging {
  String? value = _token;
  // Closed by each test's tearDown.
  // ignore: close_sinks
  final refreshes = StreamController<String>.broadcast();
  // ignore: close_sinks
  final messages = StreamController<Map<String, Object?>>.broadcast();

  @override
  Future<String?> token() async => value;

  @override
  Stream<String> get tokenRefreshes => refreshes.stream;

  @override
  Stream<Map<String, Object?>> get foregroundMessages => messages.stream;
}

Map<String, dynamic> _device() => {
  'id': 'dev_1',
  'platform': 'android',
  'tokenEnd': _token.substring(_token.length - 8),
  'current': true,
  'createdAt': '2026-10-22T10:00:00.000Z',
  'lastSeenAt': '2026-10-22T10:00:00.000Z',
};

void main() {
  late FakeAdapter adapter;
  late NotificationsApi api;
  late _FakeDisplay display;

  setUp(() {
    adapter = FakeAdapter();
    display = _FakeDisplay();
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

  group('a hint becomes the notification it points at', () {
    test('its title and summary are read from the unread list, which leaves it unread', () async {
      adapter.enqueueJson(
        _page([_row('ntf_other_001'), _row(_id, summary: 'RAS polity, join from the Live tab.')]),
      );

      await deliverPushHint(
        const {'notificationId': _id, 'category': 'live'},
        api: api,
        display: display,
      );

      expect(adapter.lastRequest.path, '/notifications');
      expect(adapter.lastRequest.queryParameters['unreadOnly'], true);
      expect(display.shown.single.id, _id);
      expect(display.shown.single.title, 'Live class at 6 PM');
      expect(display.shown.single.body, 'RAS polity, join from the Live tab.');
    });

    test('one read already (not among a short unread list) is not shown', () async {
      adapter.enqueueJson(_page([_row('ntf_other_001')]));

      await deliverPushHint(const {'notificationId': _id}, api: api, display: display);

      expect(display.shown, isEmpty);
    });

    test(
      'when the academy cannot be reached, a plain entry still says something arrived',
      () async {
        adapter.enqueueError(DioExceptionType.connectionError);

        await deliverPushHint(const {'notificationId': _id}, api: api, display: display);

        expect(display.shown.single.id, _id, reason: 'tapping it opens the notification later');
        expect(display.shown.single.title, fallbackPushTitle);
      },
    );

    test('a payload that is not the academy\'s hint is dropped without asking the API', () async {
      await deliverPushHint(const {'category': 'live'}, api: api, display: display);
      await deliverPushHint(
        const {'notificationId': _id, 'title': 'Pay now to keep your seat'},
        api: api,
        display: display,
      );

      expect(adapter.requests, isEmpty);
      expect(display.shown, isEmpty);
    });
  });

  group('the background isolate reads what the app saved', () {
    test('flavor and servers round-trip through preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(PushContext.read(prefs), isNull, reason: 'a device that never registered');

      await PushContext.save(prefs, testConfig());
      final config = PushContext.read(prefs)!;

      expect(config.flavor, Flavor.prod);
      expect(config.apiBaseUrl.toString(), 'https://api.test/api');
      expect(config.webBaseUrl.toString(), 'https://web.test');
    });
  });

  group('registration follows the signed-in person', () {
    late _FakeMessaging messaging;
    late List<String> opened;
    late int arrivals;

    PushRegistration registration() => PushRegistration(
      config: testConfig(),
      messaging: messaging,
      display: display,
      api: () => api,
      onOpen: opened.add,
      onArrived: () => arrivals++,
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      messaging = _FakeMessaging();
      addTearDown(messaging.refreshes.close);
      addTearDown(messaging.messages.close);
      opened = [];
      arrivals = 0;
    });

    test('signing in asks once, then registers the token', () async {
      adapter.enqueueJson(_device());
      final push = registration();

      await push.signedInAs('usr_1');

      expect(display.permissionRequests, 1);
      expect(adapter.lastRequest.method, 'POST');
      expect(adapter.lastRequest.path, '/notifications/devices');
      expect((adapter.lastRequest.data! as Map)['token'], _token);

      // The next person on this phone registers it again, without a second system prompt.
      adapter.enqueueJson(_device());
      await push.signedInAs(null);
      await push.signedInAs('usr_2');
      expect(display.permissionRequests, 1);
      expect(adapter.requests.where((r) => r.path == '/notifications/devices'), hasLength(2));
    });

    test('a rotated token is registered again while signed in, and not after sign-out', () async {
      adapter.enqueueJson(_device());
      final push = registration();
      await push.signedInAs('usr_1');

      adapter.enqueueJson(_device());
      messaging.refreshes.add('${_token}rotated');
      await pumpEventQueue();
      expect((adapter.lastRequest.data! as Map)['token'], '${_token}rotated');

      await push.signedInAs(null);
      final before = adapter.requests.length;
      messaging.refreshes.add('${_token}again');
      await pumpEventQueue();
      expect(adapter.requests, hasLength(before));
    });

    test('no token (no Play services) registers nothing and does not throw', () async {
      messaging.value = null;
      await registration().signedInAs('usr_1');

      expect(adapter.requests, isEmpty);
    });

    test('a hint reaching the running app updates the bell and shows the notification', () async {
      adapter.enqueueJson(_device());
      final push = registration();
      await push.signedInAs('usr_1');

      adapter.enqueueJson(_page([_row(_id)]));
      messaging.messages.add(const {'notificationId': _id, 'category': 'live'});
      await pumpEventQueue();

      expect(arrivals, 1);
      expect(display.shown.single.id, _id);
    });

    test('a tap that launched the app opens that notification', () async {
      display.launched = _id;
      await registration().start();

      expect(opened, [_id]);
      display.onOpen!('ntf_tapped_002');
      expect(opened, [_id, 'ntf_tapped_002']);
    });
  });

  test('a notification has the same shade id in every isolate', () {
    expect(pushDisplayId(_id), pushDisplayId(_id));
    expect(pushDisplayId(_id), isNot(pushDisplayId('ntf_other_001')));
    expect(pushDisplayId(_id), inInclusiveRange(0, 0x7fffffff));
  });
}
