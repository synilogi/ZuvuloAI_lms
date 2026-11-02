import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/core/errors/app_failure.dart';
import 'package:syniastrolms_mobile/core/network/api_exception.dart';
import 'package:syniastrolms_mobile/features/auth/auth.dart';
import 'package:syniastrolms_mobile/shared/entitlements/entitlements.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/entitlements/$name').readAsStringSync()) as Map<String, dynamic>;

class _FakeAcademyPlanApi implements AcademyPlanApi {
  AppFailure? failure;
  String answer = 'academy-plan-new.json';
  int calls = 0;

  @override
  Future<AcademyPlan> read() async {
    calls++;
    if (failure != null) throw ApiException(failure!);
    return AcademyPlan.fromJson(_fixture(answer));
  }
}

UserProfile _profile(
  UserRole role, {
  String id = 'u1',
  List<PermissionKey> permissions = const [],
}) => UserProfile(
  id: id,
  name: 'A',
  email: 'a@b.test',
  role: role,
  descriptor: 'x',
  permissions: permissions,
);

/// The signed-in person, changeable mid-test.
class _Who extends Notifier<UserProfile?> {
  @override
  UserProfile? build() => _profile(UserRole.admin);

  void become(UserProfile? profile) => state = profile;
}

void main() {
  late _FakeAcademyPlanApi api;

  ProviderContainer containerFor(UserProfile? profile) {
    final container = ProviderContainer(
      overrides: [
        academyPlanApiProvider.overrideWithValue(api),
        currentUserProvider.overrideWithValue(profile),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => api = _FakeAcademyPlanApi());

  group('who reads the academy plan', () {
    test('an academy admin does — any admin, not only one who can read billing', () async {
      final plan = await containerFor(_profile(UserRole.admin)).read(academyPlanProvider.future);

      expect(api.calls, 1);
      expect(plan, isNotNull);
      expect(plan!.needsOnboarding, isTrue, reason: 'the fixture is a brand-new academy');
    });

    test('an instructor does too: plan-gated modules are in their shell', () async {
      api.answer = 'academy-plan-trialing.json';

      final plan = await containerFor(
        _profile(UserRole.instructor),
      ).read(academyPlanProvider.future);

      expect(api.calls, 1);
      expect(plan!.trialing, isTrue);
    });

    test('a learner, a super admin and a signed-out app never ask', () async {
      for (final profile in [_profile(UserRole.student), _profile(UserRole.superadmin), null]) {
        final plan = await containerFor(profile).read(academyPlanProvider.future);

        expect(plan, isNull, reason: '${profile?.role}');
      }
      expect(api.calls, 0);
    });
  });

  group('a plan that cannot be read is not known, never shut', () {
    for (final failure in const <AppFailure>[
      PermissionFailure(message: 'Not allowed'),
      ForbiddenFailure(),
      UnauthenticatedFailure(),
      NotFoundFailure(),
    ]) {
      test('${failure.runtimeType} leaves it unknown rather than an error', () async {
        api.failure = failure;

        final plan = await containerFor(_profile(UserRole.admin)).read(academyPlanProvider.future);

        expect(plan, isNull);
        // Unknown opens every module: the server's refusal is what decides.
        expect(moduleAccess(plan, WorkspaceModule.courses), ModuleAccess.open);
      });
    }

    test('a network failure surfaces as an error the shell treats as unknown', () async {
      api.failure = const NetworkFailure(NetworkProblem.offline);
      final container = containerFor(_profile(UserRole.admin));

      container.listen(academyPlanProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final state = container.read(academyPlanProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<ApiException>());
      expect(state.value, isNull);
    });
  });

  group('refreshIfStale', () {
    test('does nothing inside the cache window and re-reads after it', () async {
      final container = containerFor(_profile(UserRole.admin));
      await container.read(academyPlanProvider.future);
      expect(api.calls, 1);

      await container.read(academyPlanProvider.notifier).refreshIfStale();
      expect(api.calls, 1, reason: 'still fresh');

      api.answer = 'academy-plan-trialing.json';
      await container
          .read(academyPlanProvider.notifier)
          .refreshIfStale(now: DateTime.now().add(AcademyPlanNotifier.cacheFor * 2));
      expect(api.calls, 2);
      expect(container.read(academyPlanProvider).value!.trialing, isTrue);
    });

    test('a refused read also waits out the cache window', () async {
      api.failure = const NotFoundFailure();
      final container = containerFor(_profile(UserRole.admin));
      await container.read(academyPlanProvider.future);
      expect(api.calls, 1);

      await container.read(academyPlanProvider.notifier).refreshIfStale();
      expect(api.calls, 1, reason: 'a route that is gone is not asked on every resume');
    });

    test('never asks for a learner', () async {
      final container = containerFor(_profile(UserRole.student));
      await container.read(academyPlanProvider.future);

      await container
          .read(academyPlanProvider.notifier)
          .refreshIfStale(now: DateTime.now().add(const Duration(days: 1)));

      expect(api.calls, 0);
    });
  });

  group('"Not now" on onboarding', () {
    test('holds for the session and is forgotten when the person changes', () {
      final current = NotifierProvider<_Who, UserProfile?>(_Who.new);
      final container = ProviderContainer(
        overrides: [currentUserProvider.overrideWith((ref) => ref.watch(current))],
      );
      addTearDown(container.dispose);
      container.listen(onboardingDeferredProvider, (_, _) {});

      expect(container.read(onboardingDeferredProvider), isFalse);
      container.read(onboardingDeferredProvider.notifier).defer();
      expect(container.read(onboardingDeferredProvider), isTrue);

      container.read(current.notifier).become(_profile(UserRole.admin, id: 'u2'));
      expect(container.read(onboardingDeferredProvider), isFalse);
    });
  });
}
