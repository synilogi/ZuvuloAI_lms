import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/auth/capabilities.dart';
import '../../../../core/format/money.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/session/current_user.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_billing_controller.dart';
import '../widgets/billing_parts.dart';

/// Wraps every page of a plan-gated module (the router puts it there) and decides how the module
/// appears under the academy's plan, read from `GET /academy/plan`:
///
/// - **open** — the page itself;
/// - **read-only** — the page, under a persistent notice that nothing new can be added (the page's
///   own creation controls are disabled where it has them);
/// - **locked** — [PlanGateScreen] instead of the page.
///
/// UX only: a plan that could not be read leaves the page open, and the server's refusal decides.
class PlanGate extends ConsumerWidget {
  const PlanGate({required this.module, required this.child, super.key});

  final WorkspaceModule module;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(academyPlanProvider);
    // The first read is still on its way: a skeleton, rather than the page and then a gate over it.
    if (plan.isLoading && !plan.hasValue) {
      return const DelayedLoading(skeleton: SkeletonList());
    }
    final value = plan.value;
    return switch (moduleAccess(value, module)) {
      ModuleAccess.open => child,
      ModuleAccess.readOnly => Column(
        children: [
          ReadOnlyModuleBanner(module: module),
          Expanded(child: child),
        ],
      ),
      // moduleAccess answers locked only for a plan it has read.
      ModuleAccess.locked => PlanGateScreen(module: module, plan: value!),
    };
  }
}

/// What a module the academy's plan does not open says (a shell body): its name, what it does, and
/// the way to it. An admin who can read billing sees which plans on sale include it, from
/// `/tenant/billing`, and is taken to the plans — or, for an academy that has never subscribed, to
/// choose its first plan. Anyone else is told to ask their academy admin, and never shown prices.
/// An instructor of a brand-new academy sees that the academy is being set up, not an error.
class PlanGateScreen extends ConsumerWidget {
  const PlanGateScreen({required this.module, required this.plan, super.key});

  final WorkspaceModule module;
  final AcademyPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final admin = can(ref.watch(currentUserProvider), Capability.viewBilling);
    if (!admin && plan.neverSubscribed) return AcademySetupView(module: module);

    final gutter = WindowSize.of(context).isCompact ? Space.s4 : Space.gutterMedium;
    final name = moduleName(l10n, module);
    final warn = c.tone(Tone.warn);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, Space.s6, gutter, Space.s6),
      children: [
        const Center(
          child: ToneMark(icon: AppIcons.lock, tone: Tone.warn),
        ),
        const SizedBox(height: Space.s4),
        Semantics(
          header: true,
          child: Text(name, textAlign: TextAlign.center, style: context.type.titleL),
        ),
        const SizedBox(height: Space.s2),
        Text(
          l10n.planGateLockedTitle,
          textAlign: TextAlign.center,
          style: context.type.titleS.copyWith(color: warn.ink),
        ),
        const SizedBox(height: Space.s2),
        Text(
          moduleDescription(l10n, module),
          textAlign: TextAlign.center,
          style: context.type.bodyM.copyWith(color: c.muted),
        ),
        const SizedBox(height: Space.s5),
        if (admin)
          _IncludingPlans(module: module, plan: plan)
        else
          BillingNotice(tone: Tone.info, message: l10n.planGateAskAdmin),
      ],
    );
  }
}

/// The plans on sale that include the module, and the way to them. Its own loading, empty and error
/// states: the rest of the gate does not wait on the billing page.
class _IncludingPlans extends ConsumerWidget {
  const _IncludingPlans({required this.module, required this.plan});

  final WorkspaceModule module;
  final AcademyPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final billing = ref.watch(tenantBillingProvider);
    // A brand-new academy chooses its first plan; one with a plan changes it.
    final target = plan.neverSubscribed ? AppRoutes.staffGetStarted : AppRoutes.staffBillingPlans;
    final action = AppButton(
      label: plan.neverSubscribed ? l10n.actionChoosePlan : l10n.actionSeePlans,
      expand: true,
      onPressed: () => GoRouter.of(context).go(target),
    );

    final Widget plans = switch (billing) {
      AsyncData(:final value) => () {
        final including = [
          for (final offer in value.plans)
            if (offer.includesFeature(module.feature.wire)) offer,
        ];
        if (including.isEmpty) {
          return Text(
            l10n.planGateNoPlanIncludes,
            style: context.type.bodyS.copyWith(color: c.muted),
          );
        }
        return GroupedList(
          title: l10n.planGateIncludedIn,
          children: [
            for (final offer in including)
              AppListTile(
                title: offer.name,
                subtitle: _priceLine(l10n, offer),
                meta: offer.offersTrial ? l10n.plansTrial(offer.trialDays) : null,
              ),
          ],
        );
      }(),
      AsyncError(:final error) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BillingNotice(
            tone: Tone.warn,
            message: failureOf(error)?.message ?? l10n.planGatePlansUnavailable,
          ),
          const SizedBox(height: Space.s2),
          AppButton(
            label: l10n.actionRetry,
            variant: AppButtonVariant.tertiary,
            onPressed: () => ref.invalidate(tenantBillingProvider),
          ),
        ],
      ),
      _ => const SkeletonCard(showMedia: false),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        plans,
        const SizedBox(height: Space.s4),
        action,
      ],
    );
  }

  /// "₹1,499 a month", or the yearly price for a plan sold only yearly.
  static String? _priceLine(AppLocalizations l10n, PlanView offer) {
    if (offer.sellsMonthly) {
      return l10n.plansPerMonth(
        Money.format(offer.monthlyPrice, offer.currency, dropZeroFraction: true),
      );
    }
    if (offer.sellsAnnual) {
      return l10n.plansPerYear(
        Money.format(offer.annualPrice, offer.currency, dropZeroFraction: true),
      );
    }
    return null;
  }
}
