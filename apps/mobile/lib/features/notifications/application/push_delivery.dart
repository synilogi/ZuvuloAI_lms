import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/flavor.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/crash_reporter.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/push/push_hint.dart';
import '../../../core/push/push_platform.dart';
import '../../auth/auth.dart' show SecureTokenStore;
import '../data/dto/device.dart';
import '../data/notifications_api.dart';

/// Push, end to end on the device (FLUTTER-028 Part B): register the token after sign-in, and turn
/// each hint the academy sends into the notification it points at.
///
/// A hint carries an id and a category and nothing else (`push_hint.dart`). The app reads the
/// notification from the **unread list** — not `GET /notifications/:id`, which would mark it read
/// before the person has seen it — and shows its title and summary. One that is no longer unread
/// (read on the web while the hint waited out quiet hours) is not shown at all. When the API cannot
/// be reached, a plain "new notification" entry still says something arrived, and tapping it opens
/// the notification once the app can read it.

/// What a notification looks like when its own words could not be fetched.
const fallbackPushTitle = 'You have a new notification';
const fallbackPushBody = 'Tap to open it in ZuviloAI.';

/// How far down the unread list a hint is looked for. A hint is sent as its notification is made,
/// so it is almost always the newest.
const _unreadWindow = 20;

/// Shows the notification a hint points at. Used for hints that reach a running app and, through
/// [handleBackgroundPush], for ones that wake it.
Future<void> deliverPushHint(
  Map<String, Object?> data, {
  required NotificationsApi api,
  required PushDisplay display,
}) async {
  final hint = readPushHint(data);
  if (hint == null || payloadCarriesContent(data)) return;
  try {
    final page = await api.list(unreadOnly: true, limit: _unreadWindow);
    final match = page.rows.where((row) => row.id == hint.notificationId).firstOrNull;
    if (match == null) {
      // Not among the newest unread: read already, or removed. Nothing is left to point at.
      if (page.rows.length < _unreadWindow) return;
      await _showFallback(display, hint.notificationId);
      return;
    }
    final title = match.title.trim().isEmpty ? fallbackPushTitle : match.title.trim();
    final body = match.summary.trim().isEmpty ? null : match.summary.trim();
    await display.show(notificationId: hint.notificationId, title: title, body: body);
  } on ApiException {
    await _showFallback(display, hint.notificationId);
  }
}

Future<void> _showFallback(PushDisplay display, String notificationId) =>
    display.show(notificationId: notificationId, title: fallbackPushTitle, body: fallbackPushBody);

/// Where a hint that wakes the app in the background is read from: the build's flavor and server,
/// saved when the device registered. A separate isolate has no provider tree, and a plain
/// `flutter run` build has no defines to read them from again.
class PushContext {
  const PushContext._();

  static const _flavor = 'push.flavor';
  static const _apiBaseUrl = 'push.apiBaseUrl';
  static const _webBaseUrl = 'push.webBaseUrl';

  static Future<void> save(SharedPreferences prefs, AppConfig config) async {
    await prefs.setString(_flavor, config.flavor.name);
    await prefs.setString(_apiBaseUrl, config.apiBaseUrl.toString());
    await prefs.setString(_webBaseUrl, config.webBaseUrl.toString());
  }

  /// The saved configuration, or null on a device that never registered (or a value that no
  /// longer validates).
  static AppConfig? read(SharedPreferences prefs) {
    final flavor = Flavor.values.where((f) => f.name == prefs.getString(_flavor)).firstOrNull;
    final api = prefs.getString(_apiBaseUrl);
    final web = prefs.getString(_webBaseUrl);
    if (flavor == null || api == null || web == null) return null;
    try {
      return AppConfig.fromValues(
        flavor: flavor,
        envName: flavor.name,
        apiBaseUrl: api,
        webBaseUrl: web,
        pushEnabled: true,
      );
    } on ConfigException {
      return null;
    }
  }
}

/// A hint that arrived while the app was in the background or closed. Runs in its own isolate, so
/// it builds the one API client it needs from [PushContext] and the session token in secure
/// storage — the same token the app itself sends, under the same environment key.
@pragma('vm:entry-point')
Future<void> handleBackgroundPush(RemoteMessage message) async {
  try {
    final config = PushContext.read(await SharedPreferences.getInstance());
    if (config == null) return;
    final client = ApiClient(
      config: config,
      tokenStore: SecureTokenStore(environment: config.flavor.name),
      logger: AppLogger(reporter: const NoopCrashReporter()),
    );
    await deliverPushHint(message.data, api: NotificationsApi(client), display: LocalPushDisplay());
  } on Object catch (e) {
    // A background isolate has nowhere to report to; the notification stays in the app's list.
    debugPrint('A push hint could not be shown (${e.runtimeType}).');
  }
}

/// Registers this device for the signed-in person and keeps the registration current.
///
/// Signing out needs nothing from here: ending the session on the server removes the devices that
/// session registered (`apps/api/src/lib/sessions.ts`), so the next person to sign in on the phone
/// registers it afresh.
class PushRegistration {
  PushRegistration({
    required this.config,
    required this.messaging,
    required this.display,
    required this.api,
    required this.onOpen,
    required this.onArrived,
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  final AppConfig config;
  final Future<SharedPreferences> Function() _preferences;
  final PushMessaging messaging;
  final PushDisplay display;
  final NotificationsApi Function() api;

  /// Opens a notification the person tapped.
  final void Function(String notificationId) onOpen;

  /// A hint reached the running app: the bell's count is out of date.
  final void Function() onArrived;

  static const _permissionAsked = 'push.permissionAsked';

  String? _userId;
  bool _started = false;
  StreamSubscription<String>? _refreshes;
  StreamSubscription<Map<String, Object?>>? _foreground;

  /// Sets up the display and opens the notification whose tap launched the app. The router holds
  /// it through the session restore, and sends a signed-out person to sign in first.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      await display.initialize(onOpen: onOpen);
      final launched = await display.launchNotificationId();
      if (launched != null) onOpen(launched);
    } on Object catch (e) {
      debugPrint('Push notifications are off: the display did not start (${e.runtimeType}).');
    }
  }

  /// The signed-in person changed: [userId] is who is signed in now, or null.
  Future<void> signedInAs(String? userId) async {
    if (userId == _userId) return;
    _userId = userId;
    if (userId == null) {
      await _stopListening();
      return;
    }
    try {
      await _askOnce();
      final token = await messaging.token();
      if (token == null || !deviceTokenIsUsable(token)) return;
      await PushContext.save(await _preferences(), config);
      await _register(token);
      await _stopListening();
      _refreshes = messaging.tokenRefreshes.listen((fresh) {
        if (_userId == userId && deviceTokenIsUsable(fresh)) unawaited(_register(fresh));
      });
      _foreground = messaging.foregroundMessages.listen((data) {
        if (_userId != userId) return;
        onArrived();
        unawaited(deliverPushHint(data, api: api(), display: display));
      });
    } on Object catch (e) {
      // No Play services, no network, Firebase not set up for this build: the app works without
      // push, and the bell still counts what arrived.
      debugPrint('This device is not registered for push (${e.runtimeType}).');
    }
  }

  /// The system asks once per install; after that the choice is the person's, in system settings.
  Future<void> _askOnce() async {
    final preferences = await _preferences();
    if (preferences.getBool(_permissionAsked) ?? false) return;
    await preferences.setBool(_permissionAsked, true);
    await display.requestPermission();
  }

  Future<void> _register(String token) async {
    try {
      await api().registerDevice(
        token: token,
        platform: defaultTargetPlatform == TargetPlatform.iOS
            ? DevicePlatform.ios
            : DevicePlatform.android,
      );
    } on ApiException catch (e) {
      debugPrint('The academy did not take this device for push (${e.runtimeType}).');
    }
  }

  Future<void> _stopListening() async {
    await _refreshes?.cancel();
    await _foreground?.cancel();
    _refreshes = null;
    _foreground = null;
  }

  Future<void> dispose() => _stopListening();
}
