import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/preferences.dart';
import '../../../shared/entitlements/academy_plan_provider.dart';
import '../data/staff_billing_api.dart';
import 'staff_billing_controller.dart';

/// How far starting a free trial has got.
enum TrialStage {
  idle,

  /// Asking the academy to start it.
  starting,

  /// The academy started it. What the academy is now served is in the re-read, not here.
  started,

  /// The academy refused, or the request did not arrive.
  failed,
}

/// Why the academy refused a trial, in the terms the onboarding screen explains.
enum TrialRefusal {
  /// 409 `PLAN_UNAVAILABLE` — this plan has no free trial (any more).
  planUnavailable,

  /// 409 `INVALID_SUBSCRIPTION_STATE` — the academy already has a subscription, or used its trial.
  alreadySubscribed,

  /// Anything else: a permission refusal, a network failure, a server error.
  other,
}

/// Reads the refusal behind [failure]. The code is the academy's; the app never guesses one.
TrialRefusal trialRefusalOf(AppFailure failure) => switch (failure) {
  ConflictFailure(code: 'PLAN_UNAVAILABLE') => TrialRefusal.planUnavailable,
  ConflictFailure(code: 'INVALID_SUBSCRIPTION_STATE') => TrialRefusal.alreadySubscribed,
  _ => TrialRefusal.other,
};

@immutable
class TrialState {
  const TrialState({this.stage = TrialStage.idle, this.planId, this.trial, this.failure});

  final TrialStage stage;

  /// The plan being started (or last tried), so its card alone shows as busy.
  final String? planId;

  /// What the academy answered once the trial started.
  final StartedTrial? trial;
  final AppFailure? failure;

  bool get busy => stage == TrialStage.starting;
}

/// Starts an academy's free trial from the onboarding screen (`POST /tenant/billing/trial`).
///
/// The app sends a plan and a cycle and nothing else; the academy decides whether a trial may start,
/// how long it runs and what it serves. After it starts, the billing page and the academy's plan are
/// read again — the workspace opens because the server now says so, never because the app flipped it.
class TrialController extends Notifier<TrialState> {
  @override
  TrialState build() => const TrialState();

  Future<bool> start({required String planId, required BillingCycle cycle}) async {
    if (state.busy) return false;
    state = TrialState(stage: TrialStage.starting, planId: planId);
    try {
      final trial = await ref
          .read(staffBillingApiProvider)
          .startTrial(planId: planId, cycle: cycle);
      if (!ref.mounted) return true;
      state = TrialState(stage: TrialStage.started, planId: planId, trial: trial);
      _reread();
      // The dashboard is where the admin goes next; it must not send them straight back here
      // while the re-read is still on its way.
      ref.read(onboardingDeferredProvider.notifier).defer();
      return true;
    } on ApiException catch (e) {
      if (!ref.mounted) return false;
      state = TrialState(stage: TrialStage.failed, planId: planId, failure: e.failure);
      // A 409 means the academy's state moved under the screen — the trial was used, or the plan
      // withdrew it — so what is on offer is read again rather than offered as it was.
      if (e.failure is ConflictFailure) _reread();
      return false;
    }
  }

  /// The screen has shown the refusal.
  void clearFailure() {
    if (state.stage == TrialStage.failed) state = const TrialState();
  }

  void _reread() {
    ref
      ..invalidate(tenantBillingProvider)
      ..invalidate(academyPlanProvider);
  }
}

final trialControllerProvider = NotifierProvider<TrialController, TrialState>(
  TrialController.new,
  isAutoDispose: true,
);

/// Whether the admin closed the dashboard's free-trial card. Kept on the device for the signed-in
/// person and forgotten on sign-out, like the other person-scoped preferences.
class TrialOfferDismissal extends Notifier<bool> {
  @override
  bool build() => ref.watch(preferencesProvider).trialOfferDismissed;

  Future<void> dismiss() async {
    state = true;
    await ref.read(preferencesProvider).setTrialOfferDismissed();
  }
}

final trialOfferDismissedProvider = NotifierProvider<TrialOfferDismissal, bool>(
  TrialOfferDismissal.new,
);
