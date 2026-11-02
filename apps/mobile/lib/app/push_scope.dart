import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/push/push_platform.dart';
import '../features/notifications/notifications.dart';
import '../shared/session/current_user.dart';
import 'routing/app_router.dart';
import 'routing/routes.dart';

/// The plugins behind push; tests replace them.
final pushMessagingProvider = Provider<PushMessaging>((ref) => FirebasePushMessaging());
final pushDisplayProvider = Provider<PushDisplay>((ref) => LocalPushDisplay());

/// Push for this build, or null when it is off (`PUSH_ENABLED`) or on the web. Follows the signed-in
/// person: registers the device for whoever signs in, and stops listening when they sign out.
final pushRegistrationProvider = Provider<PushRegistration?>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.pushEnabled || kIsWeb) return null;
  final registration = PushRegistration(
    config: config,
    messaging: ref.watch(pushMessagingProvider),
    display: ref.watch(pushDisplayProvider),
    api: () => ref.read(notificationsApiProvider),
    // The notification's own screen reads it (marking it read) and offers the academy's action.
    onOpen: (id) => ref.read(routerProvider).go(AppRoutes.notification(id)),
    onArrived: () => unawaited(ref.read(unreadCountProvider.notifier).refresh()),
  );
  unawaited(registration.start());
  ref.listen<String?>(
    currentUserProvider.select((profile) => profile?.id),
    (_, userId) => unawaited(registration.signedInAs(userId)),
    fireImmediately: true,
  );
  ref.onDispose(() => unawaited(registration.dispose()));
  return registration;
});

/// Keeps push alive for as long as the app root is. Called from the root's build.
void listenForPush(WidgetRef ref) => ref.watch(pushRegistrationProvider);
