import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/capabilities.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_billing_controller.dart';
import '../widgets/billing_parts.dart';
import '../widgets/checkout_parts.dart';

/// `/staff/billing/plans` — the plans the academy has on sale, with its own prices, limits and
/// features. An academy running on a plan **asks** for a change: the academy previews it first (the
/// credit, the charge, the tax, or the date it applies) and quotes it only once confirmed. An academy
/// with no plan running subscribes instead, after giving its billing details. Every figure is the
/// academy's arithmetic (§18, §11). A shell body.
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    ref.listen(billingActionProvider, (previous, next) {
      if (next.quote != null && next.quote != previous?.quote) {
        showAppSnackbar(context, l10n.plansQuoted, tone: SnackTone.success);
        return;
      }
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

    return RefreshIndicator(
      onRefresh: () => ref.refresh(tenantBillingProvider.future),
      child: AsyncView<TenantBilling>(
        value: ref.watch(tenantBillingProvider),
        onRetry: () => ref.invalidate(tenantBillingProvider),
        data: (billing) => _Plans(billing: billing),
      ),
    );
  }
}

class _Plans extends ConsumerWidget {
  const _Plans({required this.billing});

  final TenantBilling billing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final gutter = WindowSize.of(context).isCompact ? Space.s4 : Space.gutterMedium;
    final mayChange = watchCan(ref, Capability.changeBilling);
    final controller = ref.read(billingActionProvider.notifier);
    final subscription = billing.subscription;
    final live = billing.hasLiveSubscription;
    final currentPlanId = live ? billing.plan?.id : null;
    final canPay = mayPayInApp(
      enabledInBuild: ref.watch(checkoutEnabledProvider),
      billing: billing,
    );

    /// A change is previewed first, and asked for only from the preview.
    Future<void> change(PlanView plan, BillingCycle cycle) async {
      final quote = await showPlanChangeSheet(context, plan: plan, cycle: cycle, billing: billing);
      if (quote == null || !context.mounted) return;
      // An upgrade waits for its payment; this build pays it only where it takes payments at all.
      if (quote.change.awaitsPayment && canPay) {
        final checkout = await controller.startPlanChangePayment(quote.change.id);
        final start = ref.read(billingActionProvider).start;
        if (checkout == null || start == null || !context.mounted) return;
        await carryOutCheckout(context, ref, plan: checkout, start: start);
      }
    }

    /// A first subscription: billing details first, then the academy issues the invoice.
    Future<void> subscribe(PlanView plan, BillingCycle cycle) async {
      if (!await ensureBillingDetails(context, ref) || !context.mounted) return;
      final checkout = await controller.startPurchase(planId: plan.id, cycle: cycle);
      final start = ref.read(billingActionProvider).start;
      if (checkout == null || start == null || !context.mounted) return;
      await carryOutCheckout(context, ref, plan: checkout, start: start);
    }

    /// Whether [plan] on [cycle] is something to ask for: any other plan, or the plan the academy is
    /// on billed the other way. A first purchase needs a gateway the academy has connected, or the
    /// academy would only refuse it.
    VoidCallback? choice(PlanView plan, BillingCycle cycle) {
      if (!mayChange) return null;
      // No plan yet, or a trial: a first purchase, offered only where payment can be taken here.
      if (billing.buysPlan) return canPay ? () => subscribe(plan, cycle) : null;
      if (plan.id == currentPlanId && subscription?.cycle == cycle) return null;
      return () => change(plan, cycle);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
      children: [
        Text(l10n.plansTitle, style: context.type.titleL),
        const SizedBox(height: Space.s4),
        if (billing.plans.isEmpty)
          EmptyState(title: l10n.plansTitle, message: l10n.plansEmpty)
        else
          for (final plan in billing.plans) ...[
            PlanOfferCard(
              plan: plan,
              isCurrent: plan.id == currentPlanId,
              onChooseMonthly: choice(plan, BillingCycle.monthly),
              onChooseAnnual: choice(plan, BillingCycle.annual),
              monthlyLabel: billing.buysPlan ? l10n.plansSubscribeMonthly : null,
              annualLabel: billing.buysPlan ? l10n.plansSubscribeAnnual : null,
            ),
            const SizedBox(height: Space.s3),
          ],
        if (!canPay) ...[
          const SizedBox(height: Space.s2),
          Text(
            l10n.billingPaymentUnavailable,
            style: context.type.caption.copyWith(color: context.colors.muted),
          ),
        ],
      ],
    );
  }
}
