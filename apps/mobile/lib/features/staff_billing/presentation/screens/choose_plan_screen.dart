import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/auth/capabilities.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_billing_controller.dart';
import '../../application/trial_controller.dart';
import '../widgets/billing_parts.dart';
import '../widgets/checkout_parts.dart';
import '../widgets/onboarding_parts.dart';

/// `/staff/get-started` — a brand-new academy's first stop (onboarding). An admin signing in to an
/// academy that has never subscribed, while plans are enforced, lands here instead of the dashboard:
/// the plans on sale with their prices on the chosen cycle, trial lengths, main limits and features,
/// and the free trial the academy may start itself (`POST /tenant/billing/trial` — no payment, so it
/// is offered whatever this build's checkout setting). A plan is bought here only where this build
/// takes payments **and** the academy has a gateway; otherwise the screen says it is bought on the
/// web. Every price, trial and limit is the academy's.
class ChoosePlanScreen extends ConsumerWidget {
  const ChoosePlanScreen({super.key});

  /// Leaves for the dashboard, which this session will no longer swap for this screen.
  static void leave(BuildContext context, WidgetRef ref) {
    ref.read(onboardingDeferredProvider.notifier).defer();
    GoRouter.of(context).go(AppRoutes.staffDashboard);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    ref.listen(trialControllerProvider, (previous, next) {
      final failure = next.failure;
      if (next.stage != TrialStage.failed || failure == null || failure == previous?.failure) {
        return;
      }
      showAppSnackbar(context, trialFailureMessage(l10n, failure), tone: SnackTone.error);
      ref.read(trialControllerProvider.notifier).clearFailure();
    });
    // A purchase's refusal, where this build takes payments at all.
    ref.listen(billingActionProvider, (previous, next) {
      final failure = next.failure;
      if (failure == null || failure == previous?.failure) return;
      final kind = refusalKindOf(failure);
      showAppSnackbar(
        context,
        kind == null
            ? failure.message ?? l10n.stateErrorBody
            : refusalMessage(l10n, kind, serverMessage: failure.message),
        tone: SnackTone.error,
      );
      ref.read(billingActionProvider.notifier).clearAnswer();
    });

    final trial = ref.watch(trialControllerProvider);
    return Scaffold(
      appBar: CommonAppBar(automaticallyImplyLeading: false, title: l10n.onboardingAppBarTitle),
      body: SafeArea(
        top: false,
        child: trial.stage == TrialStage.started
            ? _TrialStarted(trial: trial)
            : RefreshIndicator(
                onRefresh: () => ref.refresh(tenantBillingProvider.future),
                child: AsyncView<TenantBilling>(
                  value: ref.watch(tenantBillingProvider),
                  onRetry: () => ref.invalidate(tenantBillingProvider),
                  skeleton: const DelayedLoading(skeleton: _ChoosePlanSkeleton()),
                  data: (billing) => billing.hasLiveSubscription
                      ? _AlreadyOnAPlan(billing: billing)
                      : _Choose(billing: billing),
                ),
              ),
      ),
    );
  }
}

class _Choose extends ConsumerStatefulWidget {
  const _Choose({required this.billing});

  final TenantBilling billing;

  @override
  ConsumerState<_Choose> createState() => _ChooseState();
}

class _ChooseState extends ConsumerState<_Choose> {
  BillingCycle? _cycle;

  /// Monthly unless no plan is sold monthly; the admin's choice once they make one.
  BillingCycle _cycleFor(List<PlanView> plans) {
    final chosen = _cycle;
    if (chosen != null) return chosen;
    return plans.any((p) => p.sellsMonthly) || plans.isEmpty
        ? BillingCycle.monthly
        : BillingCycle.annual;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final billing = widget.billing;
    final plans = billing.plans;
    final gutter = WindowSize.of(context).isCompact ? Space.s4 : Space.gutterMedium;
    final mayChange = watchCan(ref, Capability.changeBilling);
    final canPay = mayPayInApp(
      enabledInBuild: ref.watch(checkoutEnabledProvider),
      billing: billing,
    );
    final trial = ref.watch(trialControllerProvider);
    final cycle = _cycleFor(plans);
    final bothCycles = plans.any((p) => p.sellsMonthly) && plans.any((p) => p.sellsAnnual);

    bool sells(PlanView plan) =>
        cycle == BillingCycle.annual ? plan.sellsAnnual : plan.sellsMonthly;

    Future<void> buy(PlanView plan) async {
      if (!await ensureBillingDetails(context, ref) || !context.mounted) return;
      final controller = ref.read(billingActionProvider.notifier);
      final checkout = await controller.startPurchase(planId: plan.id, cycle: cycle);
      final start = ref.read(billingActionProvider).start;
      if (checkout == null || start == null || !context.mounted) return;
      await carryOutCheckout(context, ref, plan: checkout, start: start);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
      children: [
        Semantics(
          header: true,
          child: Text(
            billing.academy.name.isEmpty
                ? l10n.onboardingTitle
                : l10n.onboardingTitleAcademy(billing.academy.name),
            style: context.type.titleL,
          ),
        ),
        const SizedBox(height: Space.s2),
        Text(
          billing.trialAvailable && billing.trialPlans.isNotEmpty
              ? l10n.onboardingBodyTrial
              : l10n.onboardingBody,
          style: context.type.bodyM.copyWith(color: c.muted),
        ),
        if (!mayChange) ...[
          const SizedBox(height: Space.s3),
          BillingNotice(tone: Tone.info, message: l10n.onboardingNoBillingEdit),
        ] else if (!billing.trialAvailable && plans.any((p) => p.offersTrial)) ...[
          const SizedBox(height: Space.s3),
          BillingNotice(tone: Tone.info, message: l10n.onboardingTrialUsed),
        ],
        if (bothCycles) ...[
          const SizedBox(height: Space.s4),
          CycleToggle(cycle: cycle, onChanged: (value) => setState(() => _cycle = value)),
        ],
        const SizedBox(height: Space.s4),
        if (plans.isEmpty)
          EmptyState(title: l10n.onboardingNoPlansTitle, message: l10n.plansEmpty)
        else
          for (final plan in plans) ...[
            OnboardingPlanCard(
              plan: plan,
              cycle: cycle,
              billing: billing,
              trialBusy: trial.busy && trial.planId == plan.id,
              onStartTrial: mayChange && billing.trialAvailable && plan.offersTrial && sells(plan)
                  // While one trial is being started, no other may be asked for.
                  ? (trial.busy && trial.planId != plan.id
                        ? null
                        : () => ref
                              .read(trialControllerProvider.notifier)
                              .start(planId: plan.id, cycle: cycle))
                  : null,
              onBuy: mayChange && canPay && sells(plan) && !trial.busy ? () => buy(plan) : null,
            ),
            const SizedBox(height: Space.s3),
          ],
        if (plans.isNotEmpty && !canPay) ...[
          const SizedBox(height: Space.s1),
          Text(
            l10n.onboardingPaymentUnavailable,
            textAlign: TextAlign.center,
            style: context.type.caption.copyWith(color: c.muted),
          ),
        ],
        const SizedBox(height: Space.s4),
        AppButton(
          label: l10n.onboardingNotNow,
          variant: AppButtonVariant.tertiary,
          expand: true,
          onPressed: trial.busy ? null : () => ChoosePlanScreen.leave(context, ref),
        ),
      ],
    );
  }
}

/// The trial started: the academy said so, and the workspace's plan is being read again.
class _TrialStarted extends ConsumerWidget {
  const _TrialStarted({required this.trial});

  final TrialState trial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ends = trial.trial?.trialEndAt;
    final planName = ref
        .watch(tenantBillingProvider)
        .value
        ?.plans
        .where((p) => p.id == trial.planId)
        .firstOrNull
        ?.name;
    return Semantics(
      liveRegion: true,
      child: StateLayout(
        icon: AppIcons.success,
        tone: Tone.accent,
        title: l10n.onboardingTrialStartedTitle,
        message: ends == null
            ? l10n.onboardingTrialStartedBody
            : l10n.onboardingTrialStartedUntil(DatesIst.date(ends)),
        detail: planName,
        actionLabel: l10n.onboardingGoToDashboard,
        onAction: () => GoRouter.of(context).go(AppRoutes.staffDashboard),
      ),
    );
  }
}

/// Opened again once the academy is already on a plan (a stale link, a second device).
class _AlreadyOnAPlan extends ConsumerWidget {
  const _AlreadyOnAPlan({required this.billing});

  final TenantBilling billing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // A list, so the pull-to-refresh above it still works.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        StateLayout(
          icon: AppIcons.success,
          tone: Tone.accent,
          title: l10n.onboardingAlreadyOnPlanTitle,
          message: billing.plan?.name,
          actionLabel: l10n.onboardingGoToDashboard,
          onAction: () => ChoosePlanScreen.leave(context, ref),
        ),
      ],
    );
  }
}

class _ChoosePlanSkeleton extends StatelessWidget {
  const _ChoosePlanSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(Space.s4),
      children: const [
        SkeletonBox(height: 28, width: 220),
        SizedBox(height: Space.s3),
        SkeletonBox(height: 16),
        SizedBox(height: Space.s5),
        SkeletonCard(showMedia: false),
        SizedBox(height: Space.s3),
        SkeletonCard(showMedia: false),
      ],
    );
  }
}
