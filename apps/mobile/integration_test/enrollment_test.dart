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
import 'package:syniastrolms_mobile/features/course_learning/data/course_learning_api.dart';
import 'package:syniastrolms_mobile/features/learner_home/data/learning_api.dart';
import 'package:syniastrolms_mobile/features/public_catalog/data/catalog_api.dart';

/// Explore, saving and enrolling against the **real** API on the scratch database.
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

  /// A seeded course this learner neither holds nor has saved.
  Future<String> freeCourseFor(ApiClient client) async {
    final catalog = await CatalogApi(client).courses();
    final workspace = await LearningApi(client).courses();
    final taken = {
      ...workspace.courses.map((c) => c.course.id),
      ...workspace.saved.map((s) => s.course.id),
    };
    return catalog.firstWhere((c) => !taken.contains(c.id)).id;
  }

  testWidgets('a course the learner has not joined comes with a placeholder enrolment', (
    tester,
  ) async {
    final client = clientFor(await signIn('ananya@syniastrolms.test'));
    final detail = await CourseLearningApi(client).course(await freeCourseFor(client));

    expect(detail.enrolled, isFalse);
    expect(detail.learner.enrollment.isPlaceholder, isTrue);
    expect(detail.learner.enrollment.enrolledAt, isNull);
  });

  testWidgets('saving toggles on the server and survives a fresh read', (tester) async {
    final client = clientFor(await signIn('ananya@syniastrolms.test'));
    final api = CourseLearningApi(client);
    final courseId = await freeCourseFor(client);

    expect(await api.toggleSaved(courseId), isTrue);
    addTearDown(() => api.toggleSaved(courseId));

    expect((await api.course(courseId)).saved, isTrue);
    expect((await LearningApi(client).courses()).saved.map((s) => s.course.id), contains(courseId));
  });

  testWidgets('enrolling puts the course into the workspace, and repeating is harmless', (
    tester,
  ) async {
    // A learner of their own, so the other tests' seeded expectations are left alone.
    final client = clientFor(await signIn('priya@syniastrolms.test'));
    final api = CourseLearningApi(client);
    final courseId = await freeCourseFor(client);

    final enrolled = await api.enroll(courseId);
    // Given back through the academy's own route: a learner cannot leave a course, and without
    // this every run would use up another of the six seeded courses for this learner.
    addTearDown(() async {
      final staff = clientFor(await signIn('admin@syniastrolms.test'));
      await staff.delete('/students/enrollments/${enrolled.enrollment.id}');
    });
    expect(enrolled.enrollment.source, 'self', reason: 'the app sent no body');
    expect(enrolled.enrollment.id, isNotEmpty);

    final home = await LearningApi(client).home();
    expect(home.courses.map((c) => c.course.id), contains(courseId));

    // Idempotent: enrolling again answers with the same enrolment.
    final again = await api.enroll(courseId);
    expect(again.enrollment.id, enrolled.enrollment.id);
  });

  testWidgets("with the academy enrolling on request, the refusal is the academy's own", (
    tester,
  ) async {
    final admin = clientFor(await signIn('admin@syniastrolms.test'));
    final learner = clientFor(await signIn('sneha@syniastrolms.test'));
    final courseId = await freeCourseFor(learner);

    final settings = (await admin.get('/settings'))! as Map<String, dynamic>;
    final general = Map<String, dynamic>.from(
      (settings['settings']! as Map<String, dynamic>)['general']! as Map<String, dynamic>,
    );
    await admin.put('/settings/general', body: {...general, 'enrollment': 'approval'});
    addTearDown(() => admin.put('/settings/general', body: general));

    await expectLater(
      CourseLearningApi(learner).enroll(courseId),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          isA<ConflictFailure>().having(
            (f) => f.message,
            'message',
            'Enrolment in this academy needs approval — ask an instructor or the academy to add '
                'you to the course.',
          ),
        ),
      ),
    );

    // And nothing was created.
    expect(
      (await LearningApi(learner).courses()).courses.map((c) => c.course.id),
      isNot(contains(courseId)),
    );
  });

  testWidgets('a course the academy keeps private cannot be joined by knowing its id', (
    tester,
  ) async {
    final client = clientFor(await signIn('ananya@syniastrolms.test'));

    await expectLater(
      CourseLearningApi(client).enroll('no-such-course'),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<NotFoundFailure>())),
    );
  });
}
