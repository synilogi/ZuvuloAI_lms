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
import 'package:syniastrolms_mobile/features/staff_dashboard/data/dashboard_api.dart';
import 'package:syniastrolms_mobile/shared/domain/dashboard.dart';

/// The staff dashboard against the **real** API on the scratch database. Every figure asserted
/// here is the server's own; nothing is recomputed.
const _password = 'syniastrolms123';
const _admin = 'admin@syniastrolms.test';
const _instructor = 'meenakshi@syniastrolms.test';
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

  testWidgets('the academy\'s dashboard is the academy\'s own figures', (tester) async {
    final api = DashboardApi(await signIn(_admin));

    final snapshot = await api.snapshot(scope: 'academy');

    expect(snapshot.scope.isAcademy, isTrue);
    expect(snapshot.generatedAt.isUtc, isTrue);
    expect(snapshot.kpis.courses.value, greaterThan(0));
    expect(snapshot.kpis.students.value, greaterThan(0));
    expect(snapshot.kpis.completionRate.unit, KpiUnit.percent);
    expect(snapshot.enrollments, hasLength(12));
    expect(snapshot.activity, hasLength(28));
    expect(snapshot.courses, isNotEmpty);
    // Every course the academy teaches, named by the staff list the app reads beside it.
    final titles = await api.courseTitles();
    for (final course in snapshot.courses) {
      expect(titles[course.courseId], isNotNull, reason: course.courseId);
    }
  });

  testWidgets('an instructor sees their own scope, whatever is asked for', (tester) async {
    final api = DashboardApi(await signIn(_instructor));

    final asked = await api.snapshot();
    // Even asking for the academy gets their own: the route decides from the account (§7).
    final insisted = await api.snapshot(scope: 'academy');

    expect(asked.scope.isAcademy, isFalse);
    expect(asked.scope.instructorId, isNotEmpty);
    expect(insisted.scope.instructorId, asked.scope.instructorId);
    expect(insisted.scope.isAcademy, isFalse);
    // Their third figure is the review queue, and their courses are the ones they teach.
    expect(asked.kpis.third.unit, KpiUnit.count);
    expect(asked.courses.length, lessThanOrEqualTo(6));
  });

  testWidgets('an admin may read one instructor\'s figures, and they differ from the academy\'s', (
    tester,
  ) async {
    final api = DashboardApi(await signIn(_admin));
    final instructors = await api.instructors();
    expect(instructors, isNotEmpty);

    final academy = await api.snapshot(scope: 'academy');
    final one = await api.snapshot(scope: 'instructor', instructorId: instructors.first.id);

    expect(one.scope.isAcademy, isFalse);
    expect(one.scope.instructorId, instructors.first.id);
    expect(
      one.kpis.courses.value,
      lessThanOrEqualTo(academy.kpis.courses.value),
      reason: 'one instructor teaches a part of the academy',
    );
  });

  testWidgets('every place the dashboard points is a path, not a URL', (tester) async {
    final snapshot = await DashboardApi(await signIn(_admin)).snapshot(scope: 'academy');

    final targets = [
      ...snapshot.attention.map((a) => a.to),
      ...snapshot.events.map((e) => e.to).nonNulls,
    ];
    expect(targets, isNotEmpty);
    for (final target in targets) {
      expect(target, startsWith('/'));
      expect(Uri.parse(target).hasScheme, isFalse);
    }
  });

  testWidgets('the change the app shows is the change the academy\'s own rule gives', (
    tester,
  ) async {
    final snapshot = await DashboardApi(await signIn(_admin)).snapshot(scope: 'academy');

    final completion = kpiChange(snapshot.kpis.completionRate);
    expect(completion.isPoints, isTrue, reason: 'a rate moves in points');
    expect(
      completion.amount,
      ((snapshot.kpis.completionRate.value - snapshot.kpis.completionRate.previous).abs() * 10)
              .round() /
          10,
    );

    final students = kpiChange(snapshot.kpis.students);
    expect(students.isPoints, isFalse, reason: 'a count moves in percent');
  });

  testWidgets('a learner has no dashboard at all', (tester) async {
    final api = DashboardApi(await signIn(_learner));

    await expectLater(
      api.snapshot(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          anyOf(isA<ForbiddenFailure>(), isA<PermissionFailure>()),
        ),
      ),
    );
  });
}
