import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/logging/app_logger.dart';
import 'package:syniastrolms_mobile/core/logging/crash_reporter.dart';
import 'package:syniastrolms_mobile/core/network/api_client.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/shared/entitlements/entitlements.dart';

import '../helpers/fake_adapter.dart';
import '../helpers/public_harness.dart';
import '../helpers/test_config.dart';

void main() {
  late FakeAdapter adapter;
  late AcademyPlanApi api;

  setUp(() {
    adapter = FakeAdapter();
    api = AcademyPlanApi(
      ApiClient(
        config: testConfig(),
        tokenStore: FakeTokenStore('jwt'),
        logger: AppLogger(reporter: const NoopCrashReporter(), sink: (_, _) {}),
        adapter: adapter,
        logRequests: false,
      ),
    );
  });

  test('reads GET /academy/plan, with no query and no body', () async {
    adapter.enqueueJson(fixture('entitlements/academy-plan-trialing.json'));

    final plan = await api.read();

    expect(adapter.lastRequest.method, 'GET');
    expect(adapter.lastRequest.path, '/academy/plan');
    expect(adapter.lastRequest.queryParameters, isEmpty);
    expect(adapter.lastRequest.data, isNull);
    expect(plan.trialing, isTrue);
  });

  test('a learner\'s refusal is a permission failure the provider reads as "not known"', () async {
    adapter.enqueueJson(const {'message': 'Forbidden'}, status: 403);

    await expectLater(
      api.read(),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<ForbiddenFailure>())),
    );
  });

  test('a body that is not the plan is a contract failure, never a guess', () async {
    adapter.enqueueJson(const ['not', 'an', 'object']);

    await expectLater(
      api.read(),
      throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<ContractFailure>())),
    );
  });

  test(
    'an object without the route\'s keys is a contract failure, not "never subscribed"',
    () async {
      // Read leniently, `{}` would be "not enforced, never subscribed" — a guess about the academy.
      adapter.enqueueJson(const {'rows': <Object>[]});

      await expectLater(
        api.read(),
        throwsA(isA<ApiException>().having((e) => e.failure, 'failure', isA<ContractFailure>())),
      );
    },
  );
}
