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
import 'package:syniastrolms_mobile/features/live/data/live_api.dart';
import 'package:syniastrolms_mobile/shared/domain/live_class.dart';

/// Live classes against the **real** API on the scratch database
/// (`tool/contract_server.sh start`). The academy schedules and seats; the app asks and shows.
const _password = 'syniastrolms123';
const _instructor = 'meenakshi@syniastrolms.test';
const _learner = 'ananya@syniastrolms.test';
const _courseSlug = 'maths-foundations';

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

  testWidgets('the schedule is the learner\'s own, in the academy\'s three groups', (tester) async {
    final client = await signIn(_learner);

    final schedule = await LiveApi(client).schedule();

    expect(schedule.isEmpty, isFalse);
    for (final row in schedule.all) {
      expect(row.courseTitle, isNotEmpty);
      expect(row.instructorName, isNotEmpty);
      expect(row.phase, isNot(LivePhase.unknown));
      expect(row.liveClass.startsAt.isUtc, isTrue);
    }
    // The server's own phase and the app's reading of the clock agree on arrival.
    final now = DateTime.now().toUtc();
    for (final row in schedule.upcoming) {
      expect(row.phaseAt(now), anyOf(LivePhase.upcoming, LivePhase.startingSoon));
    }
    for (final row in schedule.recordings) {
      expect(row.liveClass.recording, isNotNull);
    }
  });

  testWidgets('a seat is taken and given up again, and the academy counts what is left', (
    tester,
  ) async {
    final client = await signIn(_learner);
    final api = LiveApi(client);
    final row = (await api.schedule()).upcoming.first;
    final capacity = row.liveClass.capacity!;

    // Whatever an earlier run left, start from no seat.
    if (row.registered) await api.register(row.liveClass.id, registered: false);

    final taken = await api.register(row.liveClass.id, registered: true);
    // Asking again for what is already held changes nothing: the wish is sent, not a flip.
    final again = await api.register(row.liveClass.id, registered: true);
    expect(again.registered, isTrue);
    expect(again.spotsLeft, taken.spotsLeft);
    expect(taken.registered, isTrue);
    expect(taken.spotsLeft, lessThan(capacity));
    expect(taken.isUnlimited, isFalse);

    // The schedule says so too, which is where the screen reads it from.
    final after = (await api.schedule()).upcoming.firstWhere(
      (r) => r.liveClass.id == row.liveClass.id,
    );
    expect(after.registered, isTrue);

    final given = await api.register(row.liveClass.id, registered: false);
    expect(given.registered, isFalse);
    expect(given.spotsLeft, taken.spotsLeft + 1);
    final back = (await api.schedule()).upcoming.firstWhere(
      (r) => r.liveClass.id == row.liveClass.id,
    );
    expect(back.registered, isFalse);
  });

  testWidgets('a class in a course the learner has not joined is not theirs to take', (
    tester,
  ) async {
    // Vikram is not enrolled in every course; a class he cannot see cannot be registered for.
    final outsider = await signIn('vikram@syniastrolms.test');
    final learner = await signIn(_learner);
    final theirs = (await LiveApi(learner).schedule()).all.map((r) => r.liveClass.id).toSet();
    final mine = (await LiveApi(outsider).schedule()).all.map((r) => r.liveClass.id).toSet();
    final notMine = theirs.difference(mine);
    if (notMine.isEmpty) {
      markTestSkipped('Both learners are enrolled in the same courses on this database.');
      return;
    }

    await expectLater(
      LiveApi(outsider).register(notMine.first, registered: true),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          anyOf(isA<ForbiddenFailure>(), isA<NotFoundFailure>(), isA<PermissionFailure>()),
        ),
      ),
    );
  });

  testWidgets('a class ten minutes away opens its room, and the link is the academy\'s', (
    tester,
  ) async {
    final staff = await signIn(_instructor);
    final learner = await signIn(_learner);
    final course =
        (await clientFor(_Token()).get('/catalog/courses/$_courseSlug'))! as Map<String, dynamic>;
    final instructorId = (course['instructorIds']! as List<dynamic>).first as String;

    // The write path reads `meeting.link`, although the route's own schema names `url` — sending
    // only `url` is refused by the academy's own validation (finding 15, clarification A1).
    await expectLater(
      staff.post(
        '/live',
        body: {
          'courseId': course['id'],
          'title': 'Contract check — url instead of link',
          'instructorId': instructorId,
          'startsAt': DateTime.now().toUtc().add(const Duration(hours: 2)).toIso8601String(),
          'durationMin': 30,
          'meeting': {'kind': 'external', 'url': 'https://meet.example.com/wrong-field'},
        },
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => (e.failure as ConflictFailure).message,
          'the academy\'s words',
          contains('Check the class details'),
        ),
      ),
    );

    final created =
        (await staff.post(
              '/live',
              body: {
                'courseId': course['id'],
                'title': 'Contract check — joining ten minutes ahead',
                'instructorId': instructorId,
                'startsAt': DateTime.now()
                    .toUtc()
                    .add(const Duration(minutes: 10))
                    .toIso8601String(),
                'durationMin': 30,
                'capacity': 5,
                'meeting': {'kind': 'external', 'link': 'https://meet.example.com/fractions'},
              },
            ))!
            as Map<String, dynamic>;
    final liveId = created['id']! as String;
    // Cancelling is the only way to take it back: there is no delete, and a cancelled class is in
    // none of the learner's three buckets (finding 18), so a rerun starts clean.
    addTearDown(
      () => staff.post('/live/$liveId/cancel', body: {'reason': 'Contract check finished.'}),
    );

    final row = (await LiveApi(learner).schedule()).rowFor(liveId)!;

    expect(row.phase, LivePhase.startingSoon, reason: 'the server reads the window the same way');
    expect(row.phaseAt(DateTime.now().toUtc()), LivePhase.startingSoon);
    expect(canJoinPhase(row.phaseAt(DateTime.now().toUtc())), isTrue);
    expect(row.liveClass.meeting.kind, MeetingKind.external);
    // A learner's schedule names the meeting's site, never its link.
    expect(row.liveClass.meeting.link, isNull);
    expect(row.liveClass.meeting.host, 'meet.example.com');

    // And a seat on it is counted against the capacity the academy set.
    final seat = await LiveApi(learner).register(liveId, registered: true);
    expect(seat.registered, isTrue);
    expect(seat.spotsLeft, 4);

    // The link comes from joining, inside the window: the link the academy stored, over https.
    final join = await LiveApi(learner).join(liveId);
    expect(join.kind, MeetingKind.external);
    expect(
      safeMeetingLink(join.link).toString(),
      'https://meet.example.com/fractions',
      reason: 'the link the academy stored is the link the app opens, over https only',
    );
  });

  testWidgets('a cancelled class leaves the learner\'s schedule altogether', (tester) async {
    final staff = await signIn(_instructor);
    final learner = await signIn(_learner);
    final course =
        (await clientFor(_Token()).get('/catalog/courses/$_courseSlug'))! as Map<String, dynamic>;
    final created =
        (await staff.post(
              '/live',
              body: {
                'courseId': course['id'],
                'title': 'Contract check — cancelled class',
                'instructorId': (course['instructorIds']! as List<dynamic>).first,
                'startsAt': DateTime.now().toUtc().add(const Duration(days: 3)).toIso8601String(),
                'durationMin': 30,
              },
            ))!
            as Map<String, dynamic>;
    final liveId = created['id']! as String;
    expect((await LiveApi(learner).schedule()).rowFor(liveId), isNotNull);

    await staff.post('/live/$liveId/cancel', body: {'reason': 'The instructor is unwell.'});

    // Finding 18: the route buckets live, upcoming and ended only, so nothing tells the learner
    // it was called off — it simply disappears.
    expect((await LiveApi(learner).schedule()).rowFor(liveId), isNull);
  });

  testWidgets('a class that has ended will not take another seat', (tester) async {
    final client = await signIn(_learner);
    final api = LiveApi(client);
    final ended = (await api.schedule()).recordings.first;

    await expectLater(
      api.register(ended.liveClass.id, registered: true),
      throwsA(
        isA<ApiException>().having(
          (e) => (e.failure as ConflictFailure).message,
          'the academy\'s words',
          'This class has already ended.',
        ),
      ),
    );
  });
}
