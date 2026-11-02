import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/features/notifications/notifications.dart';

/// Contract tests (§23) for the notification centre, against what the real API returned.
Object? _fixture(String path) => jsonDecode(File('test/fixtures/$path').readAsStringSync());

void main() {
  group('GET /notifications', () {
    late NotificationPage page;

    setUp(
      () => page = NotificationPage.fromJson(
        _fixture('notifications/list.json')! as Map<String, dynamic>,
      ),
    );

    test('the page carries the rows, the totals and the academy\'s own counts', () {
      expect(page.rows, hasLength(5));
      expect(page.total, 5);
      expect(page.unread, 5);
      expect(page.hasMore, isFalse);
      // The counts are per category and unread-only, as the route builds them.
      expect(page.unreadIn(NotificationCategory.certificate), 1);
      expect(page.unreadIn(NotificationCategory.assignment), 1);
      expect(page.unreadIn(NotificationCategory.quiz), 0);
    });

    test('every row is read whole, newest first', () {
      expect(page.rows.map((r) => r.category), [
        NotificationCategory.certificate,
        NotificationCategory.enrollment,
        NotificationCategory.assignment,
        NotificationCategory.course,
        NotificationCategory.live,
      ]);
      final dates = page.rows.map((r) => r.createdAt).toList();
      final newestFirst = [...dates]..sort((DateTime a, DateTime b) => b.compareTo(a));
      expect(dates, orderedEquals(newestFirst));
      expect(page.rows.every((r) => r.createdAt.isUtc), isTrue);
      expect(page.rows.every((r) => r.unread), isTrue);
      expect(page.rows.where((r) => r.important), isNotEmpty);
    });

    test('a notification that points somewhere carries a **web** path, not a URL', () {
      final actions = [for (final row in page.rows) row.action].nonNulls;

      expect(actions, isNotEmpty);
      for (final action in actions) {
        expect(action.to, startsWith('/'));
        expect(action.label, isNotEmpty);
        expect(Uri.parse(action.to).hasScheme, isFalse);
      }
    });

    test('the recipient id is dropped, though the route sends it', () {
      final raw =
          ((_fixture('notifications/list.json')! as Map<String, dynamic>)['rows']! as List<dynamic>)
                  .first
              as Map<String, dynamic>;

      expect(raw.containsKey('recipientId'), isTrue);
      expect(page.rows.first.toJson().keys, isNot(contains('recipientId')));
    });
  });

  test('GET /notifications/:id — the notice in full, now read, with its channels', () {
    final detail = NotificationDetail.fromJson(
      _fixture('notifications/detail.json')! as Map<String, dynamic>,
    );
    final n = detail.notification;

    expect(n.category, NotificationCategory.assignment);
    expect(n.title, contains('has been graded'));
    expect(n.summary, 'You scored 84 / 100 — passed.');
    expect(n.body, hasLength(1));
    expect(n.actor, 'Dr. Meenakshi Iyer');
    expect(n.facts.map((f) => f.label), ['Score', 'Pass mark', 'Course']);
    expect(n.facts.first.value, '84 / 100');
    expect(n.action!.to, startsWith('/assignments/'));
    // Opening it is what marked it read; the route answers with the date it just set.
    expect(n.readAt, isNotNull);
    expect(n.unread, isFalse);
    expect(detail.sendsOn(NotificationChannel.app), isTrue);
    expect(detail.sendsOn(NotificationChannel.email), isTrue);
    expect(detail.sendsOn(NotificationChannel.sms), isFalse);
  });

  test('a staff notice points into the staff side of the app', () {
    final staff = NotificationPage.fromJson(
      _fixture('notifications/staff-list.json')! as Map<String, dynamic>,
    );

    expect(staff.rows, isNotEmpty);
    expect(staff.rows.first.category, NotificationCategory.assignment);
    expect(staff.rows.first.action!.to, startsWith('/teach/assignments/submissions/'));
  });

  group('GET /notifications/settings/me', () {
    late NotificationSettings settings;

    setUp(
      () => settings = NotificationSettings.fromJson(
        _fixture('notifications/settings.json')! as Map<String, dynamic>,
      ),
    );

    test('every category the academy sends has its three channels', () {
      expect(settings.categories.map((c) => c.category), notificationCategories);
      for (final row in settings.categories) {
        expect(row.on(NotificationChannel.app), isTrue);
        expect(row.on(NotificationChannel.email), isTrue);
        expect(row.on(NotificationChannel.sms), isFalse);
      }
      expect(settings.emailDigest, EmailDigest.instant);
      expect(settings.quietHours.enabled, isFalse);
      expect(settings.quietHours.from, '22:00');
      expect(settings.pausedUntil, isNull);
      expect(settings.smsNumber, '');
    });

    test('account notices cannot be switched off, and the app checks before the server does', () {
      expect(isLockedChannel(NotificationCategory.system, NotificationChannel.app), isTrue);
      expect(isLockedChannel(NotificationCategory.system, NotificationChannel.email), isTrue);
      expect(isLockedChannel(NotificationCategory.system, NotificationChannel.sms), isFalse);
      expect(isLockedChannel(NotificationCategory.course, NotificationChannel.app), isFalse);

      final off = settings.withCategory(
        settings
            .forCategory(NotificationCategory.system)
            .withChannel(NotificationChannel.app, on: false),
      );
      expect(settingsIssues(off), [
        const SettingsIssue(
          'categories',
          'Account and security notices stay on in the app and by email.',
        ),
      ]);
    });

    test('quiet hours need two different, real times', () {
      NotificationSettings quiet(String from, String to) => settings.copyWith(
        quietHours: QuietHours(enabled: true, from: from, to: to),
      );

      expect(settingsIssues(quiet('22:00', '07:00')), isEmpty);
      expect(settingsIssues(quiet('22:00', '22:00')), [
        const SettingsIssue('quietHours', 'Quiet hours need different start and end times.'),
      ]);
      expect(settingsIssues(quiet('25:00', '07:00')), [
        const SettingsIssue('quietHours', 'Choose when quiet hours start and end.'),
      ]);
      // Switched off, the times are not checked at all — as the server reads them.
      expect(
        settingsIssues(
          settings.copyWith(
            quietHours: const QuietHours(from: '9', to: '9'),
          ),
        ),
        isEmpty,
      );
    });
  });
}
