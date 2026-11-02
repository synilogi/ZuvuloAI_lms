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
import 'package:syniastrolms_mobile/features/learner_home/data/learning_api.dart';
import 'package:syniastrolms_mobile/shared/domain/progress.dart';

/// The learner's workspace against the **real** API on the scratch database
/// (`tool/contract_server.sh start`).
const _password = 'syniastrolms123';

class _Token implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppConfig config;

  ApiClient clientFor(TokenStore store) => ApiClient(
    config: config,
    tokenStore: store,
    logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
    logRequests: false,
  );

  setUpAll(() => config = AppConfig.fromEnvironment(Flavor.dev));

  Future<_Token> signIn(String email) async {
    final store = _Token();
    final body = await clientFor(
      _Token(),
    ).post('/auth/login', body: {'email': email, 'password': _password});
    store.token = (body! as Map)['token'] as String;
    return store;
  }

  Future<LearningApi> learnerApi() async =>
      LearningApi(clientFor(await signIn('ananya@syniastrolms.test')));

  testWidgets('home is the seeded learner\'s own: courses, progress and next lesson', (
    tester,
  ) async {
    final home = await (await learnerApi()).home();

    expect(home.firstName, 'Ananya');
    expect(home.courses, isNotEmpty);
    expect(home.week, hasLength(7));

    final open = home.courses.firstWhere(
      (c) => c.enrollment.status == EnrollmentStatus.active && c.next != null,
    );
    expect(open.progress.total, greaterThan(0));
    expect(open.progress.percent, inInclusiveRange(1, 99));
    // The lesson Resume opens is one of this course's own, and not one already finished.
    expect(open.course.lessons.map((l) => l.id), contains(open.next!.id));
    expect(open.snapshot.stateOf(open.next!.id), isNot(ProgressState.completed));
  });

  testWidgets('the percentage is weighted by minutes, so it is not the lesson count', (
    tester,
  ) async {
    final home = await (await learnerApi()).home();
    final course = home.courses.firstWhere((c) => c.progress.state == ProgressState.inProgress);

    final byCount = (course.progress.completed / course.progress.total * 100).round();
    expect(course.progress.percent, isNot(byCount), reason: 'the server weights by duration');
    expect(course.progress.remainingMin, greaterThan(0));
  });

  testWidgets('a finished course carries no next lesson', (tester) async {
    final home = await (await learnerApi()).home();
    final done = home.courses.where((c) => c.enrollment.status == EnrollmentStatus.completed);

    expect(done, isNotEmpty);
    expect(done.every((c) => c.next == null && c.progress.percent == 100), isTrue);
  });

  testWidgets('every upcoming item points at a path the app can map', (tester) async {
    final home = await (await learnerApi()).home();

    expect(home.upcoming, isNotEmpty);
    expect(home.upcoming.length, lessThanOrEqualTo(6));
    expect(
      home.upcoming.every((i) => i.to.startsWith('/')),
      isTrue,
      reason: 'the server sends web paths, which the app maps',
    );
  });

  testWidgets('saving a course puts it in the saved list and nowhere else', (tester) async {
    final token = await signIn('ananya@syniastrolms.test');
    final client = clientFor(token);
    final api = LearningApi(client);
    final catalog = (await client.get('/catalog/courses'))! as List<dynamic>;
    final enrolled = (await api.courses()).courses.map((c) => c.course.id).toSet();
    final target = catalog.cast<Map<String, dynamic>>().firstWhere(
      (c) => !enrolled.contains(c['id']),
    );
    final courseId = target['id']! as String;

    final saved = await client.post('/learning/courses/$courseId/save');
    expect((saved! as Map)['saved'], isTrue);
    addTearDown(() => client.post('/learning/courses/$courseId/save'));

    final after = await api.courses();
    expect(after.saved.map((s) => s.course.id), contains(courseId));
    expect(after.courses.map((c) => c.course.id), isNot(contains(courseId)));
  });

  testWidgets('a member of staff has no learning workspace, and is told nothing more', (
    tester,
  ) async {
    final instructor = await signIn('meenakshi@syniastrolms.test');

    await expectLater(
      LearningApi(clientFor(instructor)).home(),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<ValidationFailure>())),
    );
  });

  testWidgets('a signed-out request is refused', (tester) async {
    await expectLater(
      LearningApi(clientFor(_Token())).home(),
      throwsA(
        isA<ApiException>().having((e) => e.failure, 'failure', isA<UnauthenticatedFailure>()),
      ),
    );
  });
}
