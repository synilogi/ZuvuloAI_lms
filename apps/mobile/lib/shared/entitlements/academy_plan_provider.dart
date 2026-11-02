import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/network/api_exception.dart';
import '../domain/user_profile.dart';
import '../session/current_user.dart';
import 'academy_plan_api.dart';
import 'dto/entitlements.dart';

/// Whether [profile] reads the academy's plan: every admin and instructor does (the staff shell
/// shows plan-gated modules to both); a learner, a super admin and a signed-out app never ask.
bool readsAcademyPlan(UserProfile? profile) =>
    profile?.role == UserRole.admin || profile?.role == UserRole.instructor;

/// The academy's plan as `GET /academy/plan` reports it, read once per 5 minutes (§9.2).
///
/// `null` means **not read** — a learner, a refusal, or a server that has no such route — and every
/// screen then treats every module as open: the server's refusal is what decides. A network failure
/// is an error the shell ignores in the same way.
class AcademyPlanNotifier extends AsyncNotifier<AcademyPlan?> {
  DateTime? _loadedAt;

  static const cacheFor = Duration(minutes: 5);

  @override
  Future<AcademyPlan?> build() async {
    final profile = ref.watch(currentUserProvider);
    if (!readsAcademyPlan(profile)) return null;
    return _read();
  }

  /// Re-reads when the cache has expired (shell entry, app resume).
  Future<void> refreshIfStale({DateTime? now}) async {
    final at = _loadedAt;
    final moment = now ?? DateTime.now();
    if (at != null && moment.difference(at) < cacheFor) return;
    if (!readsAcademyPlan(ref.read(currentUserProvider))) return;
    state = AsyncData(await _read());
  }

  Future<AcademyPlan?> _read() async {
    // Stamped first: a refused or failed read waits out the cache too, so a route the server no
    // longer answers is not asked again on every resume.
    _loadedAt = DateTime.now();
    try {
      final plan = await ref.read(academyPlanApiProvider).read();
      return plan;
    } on ApiException catch (e) {
      // A refusal here is not an error the person needs to see: the app just does not know the plan
      // and lets each screen's own refusal speak.
      if (e.failure is PermissionFailure ||
          e.failure is ForbiddenFailure ||
          e.failure is UnauthenticatedFailure ||
          e.failure is NotFoundFailure) {
        return null;
      }
      rethrow;
    }
  }
}

final academyPlanProvider = AsyncNotifierProvider<AcademyPlanNotifier, AcademyPlan?>(
  AcademyPlanNotifier.new,
);

/// "Not now" on the choose-a-plan screen: for the rest of this session the admin's dashboard is not
/// replaced by it. Forgotten when the signed-in person changes.
class OnboardingDeferral extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(currentUserProvider.select((profile) => profile?.id));
    return false;
  }

  void defer() => state = true;
}

final onboardingDeferredProvider = NotifierProvider<OnboardingDeferral, bool>(
  OnboardingDeferral.new,
);
