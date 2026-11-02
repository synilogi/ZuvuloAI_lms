import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';

/// The two plugins push needs, behind seams the tests replace: Firebase Messaging for the device's
/// token and the hints that arrive, and the local-notification plugin for what the phone shows.
///
/// The academy's push is **data-only** (`apps/api/src/lib/push.ts`): Android shows nothing by itself,
/// so the app fetches the notification through the API and shows it here (`push_delivery.dart`).

/// Starts Firebase once per isolate. On Android it reads `google-services.json`, which holds one
/// client per application id, so the dev and staging builds register under their own ids rather
/// than borrowing the production app's.
Future<void> ensureFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  if (defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp();
  } else {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}

/// The device's push identity and the hints that reach a running app.
abstract interface class PushMessaging {
  /// The device token, or null when the platform will not give one (no Play services, offline).
  Future<String?> token();

  /// A new token, whenever Firebase rotates the old one.
  Stream<String> get tokenRefreshes;

  /// Hints that arrive while the app is in front. Ones that arrive behind it go to
  /// `handleBackgroundPush` instead.
  Stream<Map<String, Object?>> get foregroundMessages;
}

class FirebasePushMessaging implements PushMessaging {
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  Future<String?> token() async {
    await ensureFirebase();
    return _messaging.getToken();
  }

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Stream<Map<String, Object?>> get foregroundMessages =>
      FirebaseMessaging.onMessage.map((message) => message.data);
}

/// What the phone shows. One channel, "Academy notifications", which the person can silence from
/// the system settings like any other app's.
abstract interface class PushDisplay {
  /// Sets the plugin up. [onOpen] receives the notification id of one the person tapped while the
  /// app was running; a tap that launched the app is read with [launchNotificationId].
  Future<void> initialize({void Function(String notificationId)? onOpen});

  /// The notification id whose tap launched the app, once — or null.
  Future<String?> launchNotificationId();

  /// Asks to show notifications (Android 13+, iOS). True when allowed.
  Future<bool> requestPermission();

  Future<void> show({required String notificationId, required String title, String? body});
}

class LocalPushDisplay implements PushDisplay {
  LocalPushDisplay([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const channel = AndroidNotificationChannel(
    'academy',
    'Academy notifications',
    description: 'Classes, assignments, results and messages from your school or coaching.',
    importance: Importance.high,
  );

  /// `res/drawable-*/ic_stat_notification.png`, kept by `res/raw/keep.xml` from resource shrinking.
  static const icon = 'ic_stat_notification';

  @override
  Future<void> initialize({void Function(String notificationId)? onOpen}) async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(icon),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: onOpen == null
          ? null
          : (response) {
              final id = response.payload;
              if (id != null && id.isNotEmpty) onOpen(id);
            },
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    _ready = true;
  }

  bool _launchRead = false;

  @override
  Future<String?> launchNotificationId() async {
    if (_launchRead) return null;
    _launchRead = true;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    final id = details.notificationResponse?.payload;
    return (id == null || id.isEmpty) ? null : id;
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return false;
  }

  @override
  Future<void> show({required String notificationId, required String title, String? body}) async {
    await initialize();
    await _plugin.show(
      id: pushDisplayId(notificationId),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: icon,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: body == null ? null : BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: notificationId,
    );
  }
}

/// One shade entry per academy notification, the same number in every isolate and on every run
/// (FNV-1a, 31 bits), so a hint delivered twice replaces its entry instead of stacking a copy.
int pushDisplayId(String notificationId) {
  var hash = 0x811c9dc5;
  for (final unit in notificationId.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}
