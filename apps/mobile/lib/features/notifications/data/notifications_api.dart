import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import '../../../shared/domain/notification.dart';
import 'dto/device.dart';

/// `apps/api/src/routes/notifications.ts` — the signed-in account's own notifications. A
/// `recipientId` in a query is ignored by the route, and the app never sends one (§7, §18).
class NotificationsApi {
  NotificationsApi(this._client);

  /// The most the route will return in one answer. It has no page parameter: a longer list is
  /// asked for by raising the limit (§12).
  static const maxLimit = 200;
  static const pageLimit = 50;

  final ApiClient _client;

  Future<NotificationPage> list({
    bool unreadOnly = false,
    NotificationCategory? category,
    int limit = pageLimit,
  }) async {
    const endpoint = 'GET /notifications';
    final body = await _client.get(
      '/notifications',
      query: {
        if (unreadOnly) 'unreadOnly': true,
        if (category != null && category != NotificationCategory.unknown) 'category': category.name,
        'limit': limit.clamp(1, maxLimit),
      },
    );
    return parseResponse(
      endpoint,
      body,
      (b) => NotificationPage.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Opening one **marks it read** — that is the route's own behaviour, and why the list is read
  /// again afterwards.
  Future<NotificationDetail> detail(String notificationId) async {
    const endpoint = 'GET /notifications/:id';
    final body = await _client.get(ApiPath.of(['notifications', ApiPath.id(notificationId)]));
    return parseResponse(
      endpoint,
      body,
      (b) => NotificationDetail.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Marks notifications read or unread. Answers `204`, so there is nothing to read back.
  Future<void> setRead({required List<String> ids, required bool read}) =>
      _client.post('/notifications/read', body: {'ids': ids, 'read': read});

  /// Marks everything read, or everything in one category. The route answers a **bare number** —
  /// how many it changed.
  Future<int> readAll({NotificationCategory? category}) async {
    const endpoint = 'POST /notifications/read-all';
    final body = await _client.post(
      '/notifications/read-all',
      body: {
        if (category != null && category != NotificationCategory.unknown) 'category': category.name,
      },
    );
    return parseResponse(endpoint, body, (b) => asCount(endpoint, b));
  }

  Future<void> remove(List<String> ids) =>
      _client.post('/notifications/remove', body: {'ids': ids});

  /// Puts removed notifications back exactly as they were — the undo behind a swipe. The whole
  /// object goes back, which is why the app keeps what it removed until the undo has gone.
  ///
  /// A field the notification does not have is **left out**, not sent as null: the route's schema
  /// marks them optional, and zod refuses a null where it expects a string.
  Future<void> restore(List<AppNotification> notifications) => _client.post(
    '/notifications/restore',
    body: {
      'notifications': [
        for (final n in notifications)
          {
            'id': n.id,
            'category': n.category.name,
            'title': n.title,
            'summary': n.summary,
            'body': n.body,
            'createdAt': n.createdAt.toUtc().toIso8601String(),
            'readAt': ?n.readAt?.toUtc().toIso8601String(),
            'important': n.important,
            'actor': ?n.actor,
            'facts': [for (final fact in n.facts) fact.toJson()],
            'action': ?n.action?.toJson(),
            'secondaryAction': ?n.secondaryAction?.toJson(),
          },
      ],
    },
  );

  /// Clears the list, or one category. Also a bare number.
  Future<int> clear({NotificationCategory? category, bool unreadOnly = false}) async {
    const endpoint = 'POST /notifications/clear';
    final body = await _client.post(
      '/notifications/clear',
      body: {
        if (category != null && category != NotificationCategory.unknown) 'category': category.name,
        if (unreadOnly) 'unreadOnly': true,
      },
    );
    return parseResponse(endpoint, body, (b) => asCount(endpoint, b));
  }

  Future<NotificationSettings> settings() async {
    const endpoint = 'GET /notifications/settings/me';
    final body = await _client.get('/notifications/settings/me');
    return parseResponse(
      endpoint,
      body,
      (b) => NotificationSettings.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Saves the settings. The answer leaves `smsNumber` out, so what was sent is kept for it.
  Future<NotificationSettings> saveSettings(NotificationSettings settings) async {
    const endpoint = 'PUT /notifications/settings/me';
    final body = await _client.put(
      '/notifications/settings/me',
      body: {
        'categories': [
          for (final row in settings.categories)
            {
              'category': row.category.name,
              'channels': {
                for (final channel in NotificationChannel.values) channel.name: row.on(channel),
              },
            },
        ],
        'emailDigest': settings.emailDigest.name,
        'quietHours': {
          'enabled': settings.quietHours.enabled,
          'from': settings.quietHours.from,
          'to': settings.quietHours.to,
        },
        'pausedUntil': ?settings.pausedUntil?.toUtc().toIso8601String(),
        'smsNumber': ?settings.smsNumber,
      },
    );
    final saved = parseResponse(
      endpoint,
      body,
      (b) => NotificationSettings.fromJson(asJsonObject(endpoint, b)),
    );
    return saved.copyWith(smsNumber: settings.smsNumber);
  }

  /// Registers this device for push, or moves an existing registration to this account. The token is a
  /// credential for the device: it is sent once and never held anywhere but the push SDK (§18).
  Future<RegisteredDevice> registerDevice({
    required String token,
    DevicePlatform platform = DevicePlatform.android,
  }) async {
    const endpoint = 'POST /notifications/devices';
    final body = await _client.post(
      '/notifications/devices',
      body: {'token': token.trim(), 'platform': platform.name},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => RegisteredDevice.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// The devices this account has registered. Each carries the last eight characters of its token and
  /// nothing more.
  Future<List<RegisteredDevice>> devices() async {
    const endpoint = 'GET /notifications/devices';
    final body = await _client.get('/notifications/devices');
    return parseResponse(endpoint, body, (b) {
      final rows = asJsonObject(endpoint, b)['devices'];
      return [
        for (final row in asJsonList(endpoint, rows))
          RegisteredDevice.fromJson(row as Map<String, dynamic>),
      ];
    });
  }

  /// Takes a device off the account — what sign-out does for the device it signs out of.
  Future<void> unregisterDevice(String deviceId) =>
      _client.delete(ApiPath.of(['notifications', 'devices', ApiPath.id(deviceId)]));
}

final notificationsApiProvider = Provider<NotificationsApi>(
  (ref) => NotificationsApi(ref.watch(apiClientProvider)),
);
