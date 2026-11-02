import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/features/notifications/notifications.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/public_harness.dart';
import '../helpers/test_config.dart';

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

  test('the list is read for whoever is signed in, with the filter as query', () async {
    adapter.enqueueJson(fixture('notifications/list.json'));

    await api.list(unreadOnly: true, category: NotificationCategory.assignment, limit: 120);

    expect(adapter.lastRequest.method, 'GET');
    expect(adapter.lastRequest.path, '/notifications');
    expect(adapter.lastRequest.queryParameters, {
      'unreadOnly': true,
      'category': 'assignment',
      'limit': 120,
    });
  });

  test(
    'an unfiltered list sends only the limit, and never asks for more than the route gives',
    () async {
      adapter
        ..enqueueJson(fixture('notifications/list.json'))
        ..enqueueJson(fixture('notifications/list.json'));

      await api.list();
      expect(adapter.lastRequest.queryParameters, {'limit': 50});

      await api.list(limit: 5000);
      expect(adapter.lastRequest.queryParameters, {'limit': NotificationsApi.maxLimit});
    },
  );

  test('marking read answers 204, which is not a shape to parse', () async {
    adapter.enqueue((_) async => FakeAdapter.noContent());

    await api.setRead(ids: ['n1', 'n2'], read: true);

    expect(adapter.lastRequest.method, 'POST');
    expect(adapter.lastRequest.path, '/notifications/read');
    expect(adapter.lastRequest.data, {
      'ids': ['n1', 'n2'],
      'read': true,
    });
  });

  test('mark-all and clear answer a bare number, and it is read as the count', () async {
    adapter
      ..enqueueJson(7)
      ..enqueueJson(3);

    expect(await api.readAll(category: NotificationCategory.live), 7);
    expect(adapter.lastRequest.data, {'category': 'live'});

    expect(await api.clear(unreadOnly: true), 3);
    expect(adapter.lastRequest.data, {'unreadOnly': true});
  });

  test('a mark-all answer that is not a number is a contract failure, not a crash', () async {
    adapter.enqueueJson({'count': 7});

    await expectLater(
      api.readAll(),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<ContractFailure>())),
    );
  });

  test('an undo sends back the whole notification, as the restore route takes it', () async {
    final page = NotificationPage.fromJson(
      fixture('notifications/list.json')! as Map<String, dynamic>,
    );
    adapter.enqueue((_) async => FakeAdapter.noContent());

    await api.restore([page.rows.first]);

    expect(adapter.lastRequest.path, '/notifications/restore');
    final sent = ((adapter.lastRequest.data! as Map)['notifications']! as List).single as Map;
    expect(sent['id'], page.rows.first.id);
    expect(sent['category'], 'certificate');
    expect(sent['title'], page.rows.first.title);
    expect(sent['body'], isA<List<dynamic>>());
    expect(sent.keys, isNot(contains('recipientId')), reason: 'the route fills it in itself');
    // The route's schema marks these optional, and refuses a null where it expects a string.
    expect(sent.keys, isNot(contains('readAt')), reason: 'this one had not been read');
    expect(sent.keys, isNot(contains('actor')), reason: 'nobody caused it');
    expect(sent['createdAt'], endsWith('Z'));
  });

  test(
    'the settings are sent in the shape the route takes, and sms is kept from what was sent',
    () async {
      final settings = NotificationSettings.fromJson(
        fixture('notifications/settings.json')! as Map<String, dynamic>,
      );
      // The write answers without `smsNumber`.
      adapter.enqueueJson({
        'categories': [
          {
            'category': 'course',
            'channels': {'app': true, 'email': false, 'sms': false},
          },
        ],
        'emailDigest': 'daily',
        'quietHours': {'enabled': true, 'from': '22:00', 'to': '07:00'},
      });

      final saved = await api.saveSettings(
        settings.copyWith(
          emailDigest: EmailDigest.daily,
          quietHours: const QuietHours(enabled: true, from: '22:00', to: '07:00'),
          smsNumber: '+919876543210',
        ),
      );

      expect(adapter.lastRequest.method, 'PUT');
      expect(adapter.lastRequest.path, '/notifications/settings/me');
      final body = adapter.lastRequest.data! as Map;
      expect((body['categories']! as List), hasLength(7));
      expect(((body['categories']! as List).first as Map)['channels'], {
        'app': true,
        'email': true,
        'sms': false,
      });
      expect(body['emailDigest'], 'daily');
      expect(body['quietHours'], {'enabled': true, 'from': '22:00', 'to': '07:00'});
      expect(body.containsKey('pausedUntil'), isFalse, reason: 'nothing is paused');
      expect(body['smsNumber'], '+919876543210');
      expect(saved.emailDigest, EmailDigest.daily);
      expect(saved.smsNumber, '+919876543210', reason: 'the answer leaves it out');
    },
  );

  test('a pause is sent as an instant, in UTC', () async {
    final settings = NotificationSettings.fromJson(
      fixture('notifications/settings.json')! as Map<String, dynamic>,
    );
    adapter.enqueueJson(fixture('notifications/settings.json'));

    await api.saveSettings(settings.copyWith(pausedUntil: DateTime.utc(2026, 10, 5, 9, 30)));

    expect((adapter.lastRequest.data! as Map)['pausedUntil'], '2026-10-05T09:30:00.000Z');
  });
}
