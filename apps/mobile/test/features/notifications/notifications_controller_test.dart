import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/app/bootstrap.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/features/notifications/notifications.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/public_harness.dart';

/// The captured list, with the unread count the bell would show.
Map<String, dynamic> _page({int unread = 5}) {
  final raw = Map<String, dynamic>.from(
    fixture('notifications/list.json')! as Map<String, dynamic>,
  );
  return {...raw, 'unread': unread};
}

void main() {
  late FakeAdapter adapter;
  late ProviderContainer container;

  /// Answers by path, so a test never depends on the order providers settle in — the bell polls
  /// whenever it likes.
  void answering({int unread = 5, int? count, Object? settings, int status = 200, Object? error}) {
    adapter.handler = (options) async {
      if (error != null && options.method != 'GET') {
        return FakeAdapter.jsonResponse(error, status: status);
      }
      if (options.path.contains('/settings/me')) {
        return FakeAdapter.jsonResponse(settings ?? fixture('notifications/settings.json'));
      }
      if (options.path.endsWith('/read-all') || options.path.endsWith('/clear')) {
        return FakeAdapter.jsonResponse(count ?? 0);
      }
      if (options.method == 'POST') return FakeAdapter.noContent();
      return FakeAdapter.jsonResponse(_page(unread: unread));
    };
  }

  setUp(() {
    adapter = FakeAdapter();
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: publicScope(
        adapter: adapter,
        signedInAs: learner(),
        child: const SizedBox(),
      ).overrides,
    );
    // Disposed by whichever test needs the bell's timer stopped inside its own body; disposing
    // twice is harmless.
    addTearDown(container.dispose);
  });

  AppNotification firstRow() => NotificationPage.fromJson(
    fixture('notifications/list.json')! as Map<String, dynamic>,
  ).rows.first;

  test('the list is read for the filter on screen, and a category narrows it', () async {
    answering();
    container.listen(notificationsProvider, (_, _) {});

    await container.read(notificationsProvider.future);
    expect(adapter.lastRequest.queryParameters, {'limit': 50});

    container.read(notificationFilterProvider.notifier)
      ..showUnreadOnly()
      ..inCategory(NotificationCategory.live);
    await container.read(notificationsProvider.future);

    expect(adapter.lastRequest.queryParameters, {
      'unreadOnly': true,
      'category': 'live',
      'limit': 50,
    });
  });

  test('asking for older raises the limit, because the route has no pages', () async {
    answering();
    container.listen(notificationsProvider, (_, _) {});
    await container.read(notificationsProvider.future);

    container.read(notificationFilterProvider.notifier).showMore();
    await container.read(notificationsProvider.future);

    expect(adapter.lastRequest.queryParameters['limit'], 100);
  });

  test('removing keeps the notification whole so the undo can put it back', () async {
    final row = firstRow();
    answering();
    container.listen(notificationActionProvider, (_, _) {});
    final actions = container.read(notificationActionProvider.notifier);

    expect(await actions.remove(row), isTrue);
    expect(container.read(notificationActionProvider).canUndo, isTrue);
    expect((adapter.requests.first.data! as Map)['ids'], [row.id]);

    expect(await actions.undo(), isTrue);
    final restored =
        (adapter.requests.firstWhere((r) => r.path.endsWith('/restore')).data!
                as Map)['notifications']!
            as List;
    expect((restored.single as Map)['id'], row.id);
    expect(container.read(notificationActionProvider).canUndo, isFalse);
  });

  test('a failed removal leaves nothing to undo, and says what the academy said', () async {
    answering(error: {'message': 'Notification not found.'}, status: 404);
    container.listen(notificationActionProvider, (_, _) {});

    expect(await container.read(notificationActionProvider.notifier).remove(firstRow()), isFalse);

    final state = container.read(notificationActionProvider);
    expect(state.canUndo, isFalse);
    expect(state.failure, isA<NotFoundFailure>());
    expect(state.failure!.message, 'Notification not found.');
  });

  test('marking everything read answers with the academy\'s own count', () async {
    answering(count: 9, unread: 0);
    // The bell is listened to as the shell does, so its own read belongs to this test.
    container
      ..listen(notificationActionProvider, (_, _) {})
      ..listen(unreadCountProvider, (_, _) {});

    final changed = await container.read(notificationActionProvider.notifier).readAll();

    expect(changed, 9);
    expect(adapter.requests.map((r) => r.path), contains('/notifications/read-all'));
    await waitFor(() => container.read(unreadCountProvider) == 0);
    container.dispose();
  });

  testWidgets('the bell asks again every minute while the app is in front', (tester) async {
    answering(unread: 3);
    container.listen(unreadCountProvider, (_, _) {});

    await tester.pumpAndSettle();
    expect(container.read(unreadCountProvider), 3);
    final reads = adapter.requests.length;
    expect(adapter.lastRequest.queryParameters['limit'], 1, reason: 'the count is all it needs');

    answering(unread: 1);
    await tester.pump(unreadPollInterval);
    await tester.pumpAndSettle();

    expect(container.read(unreadCountProvider), 1);
    expect(adapter.requests.length, greaterThan(reads));
    // The bell polls for as long as it is watched; the test stops watching before it ends.
    container.dispose();
  });

  testWidgets('a failed poll leaves the last count alone', (tester) async {
    answering(unread: 2);
    container.listen(unreadCountProvider, (_, _) {});
    await tester.pumpAndSettle();
    expect(container.read(unreadCountProvider), 2);

    adapter.handler = (_) async =>
        FakeAdapter.jsonResponse({'message': 'Server error.'}, status: 500);
    unawaited(container.read(unreadCountProvider.notifier).refresh());
    await tester.pumpAndSettle();

    expect(container.read(unreadCountProvider), 2, reason: 'the bell is not where errors are told');
    container.dispose();
  });

  group('the preferences draft', () {
    NotificationSettings settings() => NotificationSettings.fromJson(
      fixture('notifications/settings.json')! as Map<String, dynamic>,
    );

    test('nothing is dirty until something is changed', () async {
      answering();
      container.listen(notificationSettingsDraftProvider, (_, _) {});
      await container.read(notificationSettingsProvider.future);

      expect(container.read(notificationSettingsDraftProvider).dirty, isFalse);

      container
          .read(notificationSettingsDraftProvider.notifier)
          .edit(settings().copyWith(emailDigest: EmailDigest.weekly));

      expect(container.read(notificationSettingsDraftProvider).dirty, isTrue);
    });

    test('the academy\'s own rules are checked before anything is sent', () async {
      answering();
      container.listen(notificationSettingsDraftProvider, (_, _) {});
      await container.read(notificationSettingsProvider.future);
      final sentSoFar = adapter.requests.length;

      container
          .read(notificationSettingsDraftProvider.notifier)
          .edit(
            settings().copyWith(
              quietHours: const QuietHours(enabled: true, from: '22:00', to: '22:00'),
            ),
          );
      expect(await container.read(notificationSettingsDraftProvider.notifier).save(), isFalse);

      expect(adapter.requests.length, sentSoFar, reason: 'nothing was sent');
      expect(container.read(notificationSettingsDraftProvider).issues, [
        const SettingsIssue('quietHours', 'Quiet hours need different start and end times.'),
      ]);
    });

    test('the academy\'s refusal is shown against its own field', () async {
      adapter.handler = (options) async => options.method == 'PUT'
          ? FakeAdapter.jsonResponse({
              'message': 'Check your notification settings.',
              'issues': [
                {
                  'field': 'quietHours',
                  'message': 'Quiet hours need different start and end times.',
                },
              ],
            }, status: 409)
          : FakeAdapter.jsonResponse(fixture('notifications/settings.json'));
      container.listen(notificationSettingsDraftProvider, (_, _) {});
      await container.read(notificationSettingsProvider.future);

      // Something the app would allow, which the server refuses anyway.
      container
          .read(notificationSettingsDraftProvider.notifier)
          .edit(settings().copyWith(emailDigest: EmailDigest.off));
      expect(await container.read(notificationSettingsDraftProvider.notifier).save(), isFalse);

      final state = container.read(notificationSettingsDraftProvider);
      expect(state.issues, [
        const SettingsIssue('quietHours', 'Quiet hours need different start and end times.'),
      ]);
      expect(state.failure, isNull, reason: 'a refusal is not an error banner');
      expect(state.dirty, isTrue, reason: 'the change is still on screen to fix');
    });

    test('a saved change becomes what the academy holds', () async {
      answering();
      container.listen(notificationSettingsDraftProvider, (_, _) {});
      await container.read(notificationSettingsProvider.future);

      answering(
        settings: {
          ...fixture('notifications/settings.json')! as Map<String, dynamic>,
          'emailDigest': 'weekly',
        },
      );
      container
          .read(notificationSettingsDraftProvider.notifier)
          .edit(settings().copyWith(emailDigest: EmailDigest.weekly));
      expect(await container.read(notificationSettingsDraftProvider.notifier).save(), isTrue);

      final state = container.read(notificationSettingsDraftProvider);
      expect(state.saved!.emailDigest, EmailDigest.weekly);
      expect(state.dirty, isFalse);
      expect(state.issues, isEmpty);
    });
  });
}
