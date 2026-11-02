import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:syniastrolms_mobile/core/config/app_config.dart';
import 'package:syniastrolms_mobile/core/config/flavor.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/core/network/token_store.dart';
import 'package:syniastrolms_mobile/features/notifications/data/notifications_api.dart';
import 'package:syniastrolms_mobile/shared/domain/notification.dart';

/// The notification centre against the **real** API on the scratch database
/// (`tool/contract_server.sh start`). Every count shown is the academy's own.
const _password = 'syniastrolms123';
const _learner = 'ananya@syniastrolms.test';

class _Token implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppConfig config;
  final clients = <String, ApiClient>{};

  ApiClient clientFor(TokenStore store) => ApiClient(
    config: config,
    tokenStore: store,
    logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
    logRequests: false,
  );

  Future<ApiClient> signIn(String email) async {
    final cached = clients[email];
    if (cached != null) return cached;
    final store = _Token();
    final body = await clientFor(
      _Token(),
    ).post('/auth/login', body: {'email': email, 'password': _password});
    store.token = (body! as Map)['token'] as String;
    return clients[email] = clientFor(store);
  }

  setUpAll(() => config = AppConfig.fromEnvironment(Flavor.dev));

  /// A notification of this learner's own, unread, making one if the academy has sent none.
  Future<AppNotification> anUnreadOne(NotificationsApi api) async {
    final page = await api.list();
    final unread = page.rows.where((n) => n.unread).toList();
    if (unread.isNotEmpty) return unread.first;
    // Every seeded notice has been read by an earlier run; mark one unread again through the
    // route that does exactly that.
    await api.setRead(ids: [page.rows.first.id], read: false);
    return (await api.list()).rows.firstWhere((n) => n.id == page.rows.first.id);
  }

  testWidgets('the centre is this account\'s own, with the academy\'s counts', (tester) async {
    final api = NotificationsApi(await signIn(_learner));

    final page = await api.list();

    expect(page.rows, isNotEmpty);
    expect(page.total, greaterThanOrEqualTo(page.rows.length));
    expect(page.rows.every((n) => n.category != NotificationCategory.unknown), isTrue);
    expect(page.rows.every((n) => n.createdAt.isUtc), isTrue);
    // The unread count is across every category, whatever the filter.
    final unreadOnly = await api.list(unreadOnly: true);
    expect(unreadOnly.unread, page.unread);
    expect(unreadOnly.rows.every((n) => n.unread), isTrue);
    // And the per-category counts add up to it.
    final counted = notificationCategories.fold<int>(0, (sum, c) => sum + page.unreadIn(c));
    expect(counted, page.unread);
  });

  testWidgets('opening one marks it read, and the bell\'s number falls by one', (tester) async {
    final api = NotificationsApi(await signIn(_learner));
    final before = await api.list();
    final target = await anUnreadOne(api);
    final unreadBefore = (await api.list()).unread;

    final detail = await api.detail(target.id);

    expect(detail.notification.id, target.id);
    expect(detail.notification.unread, isFalse, reason: 'the route marks it read as it answers');
    expect(detail.channels.keys, containsAll(['app', 'email', 'sms']));

    final after = await api.list();
    expect(after.unread, unreadBefore - 1);
    expect(after.rows.firstWhere((n) => n.id == target.id).unread, isFalse);
    expect(after.total, before.total, reason: 'reading one does not remove it');
  });

  testWidgets('marking read and unread again is the same route, and the count follows', (
    tester,
  ) async {
    final api = NotificationsApi(await signIn(_learner));
    final row = (await api.list()).rows.first;

    await api.setRead(ids: [row.id], read: false);
    final unread = await api.list();
    expect(unread.rows.firstWhere((n) => n.id == row.id).unread, isTrue);

    await api.setRead(ids: [row.id], read: true);
    final read = await api.list();
    expect(read.rows.firstWhere((n) => n.id == row.id).unread, isFalse);
    expect(read.unread, unread.unread - 1);
  });

  testWidgets('removing one and undoing it puts the academy\'s own notice back', (tester) async {
    final api = NotificationsApi(await signIn(_learner));
    final row = (await api.list()).rows.first;
    final before = (await api.list()).total;

    await api.remove([row.id]);
    final gone = await api.list();
    expect(gone.total, before - 1);
    expect(gone.rows.map((n) => n.id), isNot(contains(row.id)));

    await api.restore([row]);
    final back = await api.list();
    final restored = back.rows.firstWhere((n) => n.id == row.id);
    expect(back.total, before);
    expect(restored.title, row.title);
    expect(restored.summary, row.summary);
    expect(restored.category, row.category);
    expect(restored.createdAt, row.createdAt);
    expect(restored.action?.to, row.action?.to);
    expect(restored.unread, row.unread, reason: 'even whether it had been read');
  });

  testWidgets('marking everything read answers a bare number and empties the bell', (tester) async {
    final api = NotificationsApi(await signIn(_learner));
    await anUnreadOne(api);
    final unread = (await api.list()).unread;
    expect(unread, greaterThan(0));

    final changed = await api.readAll();

    expect(changed, unread, reason: 'the route answers how many it changed');
    expect((await api.list()).unread, 0);
  });

  testWidgets('the settings round-trip, and the academy refuses what it will not allow', (
    tester,
  ) async {
    final api = NotificationsApi(await signIn(_learner));
    final original = await api.settings();
    addTearDown(() => api.saveSettings(original));

    final saved = await api.saveSettings(
      original.copyWith(
        emailDigest: EmailDigest.weekly,
        quietHours: const QuietHours(enabled: true, from: '21:30', to: '06:30'),
      ),
    );

    expect(saved.emailDigest, EmailDigest.weekly);
    expect(saved.quietHours.enabled, isTrue);
    expect(saved.quietHours.from, '21:30');
    // Read fresh, it is what the academy now holds.
    final reread = await api.settings();
    expect(reread.emailDigest, EmailDigest.weekly);
    expect(reread.quietHours.to, '06:30');

    // Account notices cannot be switched off — the app checks first, and so does the academy.
    final off = original.withCategory(
      original
          .forCategory(NotificationCategory.system)
          .withChannel(NotificationChannel.app, on: false),
    );
    expect(settingsIssues(off), isNotEmpty);
    await expectLater(
      api.saveSettings(off),
      throwsA(
        isA<ApiException>().having(
          (e) => (e.failure as ConflictFailure).message,
          'the academy\'s words',
          'Check your notification settings.',
        ),
      ),
    );

    // And quiet hours that start when they end.
    await expectLater(
      api.saveSettings(
        original.copyWith(
          quietHours: const QuietHours(enabled: true, from: '22:00', to: '22:00'),
        ),
      ),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<ConflictFailure>())),
    );
  });

  testWidgets('a notification of someone else\'s is not found', (tester) async {
    final mine = NotificationsApi(await signIn(_learner));
    final theirs = NotificationsApi(await signIn('karan@syniastrolms.test'));
    final row = (await mine.list()).rows.first;

    await expectLater(
      theirs.detail(row.id),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
    );
  });
}
