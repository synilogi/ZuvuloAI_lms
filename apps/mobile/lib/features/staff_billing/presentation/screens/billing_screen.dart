import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/auth/capabilities.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/platform/clock.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_billing_controller.dart';
import '../widgets/billing_parts.dart';
import '../widgets/checkout_parts.dart';

/// `/staff/billing` — the academy's own subscription (SaaS §24). Every figure, date and status is the
/// academy's; the app formats them and never computes a total. Changing anything needs
/// `settings.edit`, and a payment control exists only where this build offers one **and** the academy
/// has a gateway connected. A shell body.
class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

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

    return RefreshIndicator(
      onRefresh: () => ref.refresh(tenantBillingProvider.future),
      child: AsyncView<TenantBilling>(
        value: ref.watch(tenantBillingProvider),
        onRetry: () => ref.invalidate(tenantBillingProvider),
        data: (billing) => _Billing(billing: billing),
      ),
    );
  }
}

class _Billing extends ConsumerWidget {
  const _Billing({required this.billing});

  final TenantBilling billing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final gutter = WindowSize.of(context).isCompact ? Space.s4 : Space.gutterMedium;
    final now = ref.watch(clockProvider)();
    final mayChange = watchCan(ref, Capability.changeBilling);
    final canPay = mayPayInApp(
      enabledInBuild: ref.watch(checkoutEnabledProvider),
      billing: billing,
    );
    // Anything owed that this build will not take is paid from the web dashboard — said where the
    // button would be, so there is never a dead one.
    final payOnWeb = !canPay;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
      children: [
        Text(l10n.billingTitle, style: context.type.titleL),
        const SizedBox(height: Space.s3),
        PlanCard(billing: billing, now: now),
        const SizedBox(height: Space.s3),
        BillingStateNotice(billing: billing, now: now),
        // Said only while the platform does not enforce plans, so nothing warns of a block that
        // will not happen.
        if (!billing.enforced) ...[
          const SizedBox(height: Space.s3),
          Text(l10n.billingNotEnforcedNote, style: context.type.caption.copyWith(color: c.muted)),
        ],
        if (billing.openChange case final change?) ...[
          const SizedBox(height: Space.s3),
          _OpenChangeCard(change: change, mayChange: mayChange, canPay: canPay, payOnWeb: payOnWeb),
        ],
        const SizedBox(height: Space.sectionGap),
        Wrap(
          spacing: Space.s2,
          runSpacing: Space.s2,
          children: [
            // On a free trial, or with no plan, the way on is to buy one (D33): said plainly, as the
            // primary action, where the academy can pay here; otherwise the plans are only shown.
            AppButton(
              label: billing.buysPlan && canPay && mayChange
                  ? l10n.billingUpgradeAction
                  : billing.hasLiveSubscription
                  ? l10n.billingChangePlanAction
                  : l10n.billingSeePlans,
              variant: billing.hasLiveSubscription && !(billing.buysPlan && canPay && mayChange)
                  ? AppButtonVariant.secondary
                  : AppButtonVariant.primary,
              onPressed: () => GoRouter.of(context).go(AppRoutes.staffBillingPlans),
            ),
            // Cancelling and resuming are the same button in two states, and only for someone the
            // academy lets change its billing.
            if (mayChange)
              if (billing.subscription case final subscription?)
                if (subscription.isCanceling)
                  _ResumeButton(subscription: subscription)
                else if (subscription.status == SubscriptionStatus.active || subscription.isTrial)
                  _CancelButton(subscription: subscription),
          ],
        ),
        // The academy has no gateway connected, so nothing here offers to take money.
        if (!billing.checkoutAvailable) ...[
          const SizedBox(height: Space.s3),
          Text(
            l10n.billingPaymentUnavailable,
            style: context.type.caption.copyWith(color: c.muted),
          ),
        ],
        const SizedBox(height: Space.sectionGap),
        SectionHeader(
          title: l10n.billingUsageTitle,
          icon: AppIcons.chart,
          iconColor: c.hue(Hue.violet).solid,
        ),
        if (billing.usage.isEmpty)
          Text(l10n.reportsNoFigure, style: context.type.bodyS.copyWith(color: c.muted))
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Space.cardPadding, vertical: Space.s2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < billing.usage.length; i++) ...[
                  if (i > 0) const AppDivider(),
                  UsageMeter(line: billing.usage[i]),
                ],
              ],
            ),
          ),
        const SizedBox(height: Space.sectionGap),
        SectionHeader(
          title: l10n.billingFeaturesTitle,
          icon: AppIcons.success,
          iconColor: c.hue(Hue.green).solid,
        ),
        GroupedList(
          children: [
            for (final feature in billing.features)
              AppListTile(
                title: feature.label,
                subtitle: feature.isPlanned
                    ? l10n.billingFeaturePlanned
                    : feature.included
                    ? l10n.billingFeatureIncluded
                    : l10n.billingFeatureNotIncluded,
                trailing: AppIcon(
                  feature.included ? AppIcons.success : AppIcons.close,
                  size: IconSizes.md,
                  color: feature.included ? c.success : c.faint,
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.sectionGap),
        SectionHeader(
          title: l10n.billingInvoicesTitle,
          icon: AppIcons.subscription,
          iconColor: c.hue(AppNavIcons.of(AppIcons.billing).hue).solid,
        ),
        if (billing.invoices.isEmpty)
          Text(l10n.billingInvoicesEmpty, style: context.type.bodyS.copyWith(color: c.muted))
        else
          GroupedList(
            children: [
              for (final invoice in billing.invoices)
                AppListTile(
                  title: invoice.number,
                  subtitle: [
                    money(invoice.amounts?.total ?? 0, invoice.currency),
                    DatesIst.date(invoice.issuedAt),
                    if (invoice.isPayable && payOnWeb) l10n.billingPaymentNotOffered,
                  ].join(' · '),
                  trailing: StatusBadge(
                    invoiceStatusKind(invoice.status),
                    labelOverride: invoiceStatusLabel(l10n, invoice.status),
                  ),
                  onTap: () => GoRouter.of(context).go(AppRoutes.staffInvoice(invoice.id)),
                ),
            ],
          ),
        const SizedBox(height: Space.sectionGap),
        SectionHeader(
          title: l10n.billingPaymentsTitle,
          icon: AppIcons.billing,
          iconColor: c.hue(Hue.blue).solid,
        ),
        if (billing.payments.isEmpty)
          Text(l10n.billingPaymentsEmpty, style: context.type.bodyS.copyWith(color: c.muted))
        else
          GroupedList(
            children: [
              for (final payment in billing.payments)
                AppListTile(
                  title: money(payment.amount, payment.currency),
                  subtitle: [
                    ?payment.invoiceNumber,
                    ?payment.method,
                    DatesIst.date(payment.at),
                    ?payment.failureMessage,
                  ].join(' · '),
                ),
            ],
          ),
      ],
    );
  }
}

/// A change the academy has quoted and not yet carried out.
class _OpenChangeCard extends ConsumerWidget {
  const _OpenChangeCard({
    required this.change,
    required this.mayChange,
    required this.canPay,
    required this.payOnWeb,
  });

  final OpenPlanChange change;
  final bool mayChange;
  final bool canPay;
  final bool payOnWeb;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final action = ref.watch(billingActionProvider);
    final controller = ref.read(billingActionProvider.notifier);

    Future<void> pay() async {
      final checkout = await controller.startPlanChangePayment(change.id);
      final start = ref.read(billingActionProvider).start;
      if (checkout == null || start == null || !context.mounted) return;
      await carryOutCheckout(context, ref, plan: checkout, start: start);
    }

    Future<void> giveUp() async {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.billingOpenChangeGiveUpTitle,
        message: l10n.billingOpenChangeGiveUpBody,
        confirmLabel: l10n.billingOpenChangeGiveUp,
      );
      if (!confirmed) return;
      if (await controller.cancelPlanChange(change.id) && context.mounted) {
        showAppSnackbar(context, l10n.billingOpenChangeGaveUp, tone: SnackTone.success);
      }
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            change.awaitsPayment
                ? l10n.billingOpenChangeUpgradeTitle(change.toPlanName)
                : l10n.billingOpenChangeScheduledTitle(
                    change.toPlanName,
                    change.effectiveAt == null ? '' : DatesIst.date(change.effectiveAt!),
                  ),
            style: context.type.titleS,
          ),
          if (change.charge > 0) ...[
            const SizedBox(height: Space.s2),
            Text(
              l10n.billingOpenChangeCharge(money(change.charge, change.currency)),
              style: context.type.bodyM,
            ),
          ],
          if (change.credit > 0) ...[
            const SizedBox(height: Space.s1),
            Text(
              l10n.billingOpenChangeCredit(money(change.credit, change.currency)),
              style: context.type.caption.copyWith(color: context.colors.muted),
            ),
          ],
          if (payOnWeb && change.awaitsPayment) ...[
            const SizedBox(height: Space.s2),
            Text(
              l10n.billingPaymentNotOffered,
              style: context.type.caption.copyWith(color: context.colors.muted),
            ),
          ],
          const SizedBox(height: Space.s3),
          Wrap(
            spacing: Space.s2,
            runSpacing: Space.s2,
            children: [
              // Offered only where this build takes payments and the academy has a gateway.
              if (canPay && change.awaitsPayment && mayChange)
                AppButton(label: l10n.billingPayChangeAction, busy: action.busy, onPressed: pay),
              if (mayChange)
                AppButton(
                  label: l10n.billingOpenChangeGiveUp,
                  variant: AppButtonVariant.tertiary,
                  busy: action.busy,
                  onPressed: giveUp,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CancelButton extends ConsumerWidget {
  const _CancelButton({required this.subscription});

  final SubscriptionView subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final action = ref.watch(billingActionProvider);
    final controller = ref.read(billingActionProvider.notifier);

    Future<void> cancel() async {
      final reason = await showCancelReasonSheet(context);
      if (reason == null || !context.mounted) return;
      if (await controller.cancelSubscription(reason: reason) && context.mounted) {
        showAppSnackbar(context, l10n.billingCanceled, tone: SnackTone.success);
      }
    }

    return AppButton(
      label: l10n.billingCancelAction,
      variant: AppButtonVariant.destructiveOutline,
      busy: action.busy,
      onPressed: cancel,
    );
  }
}

class _ResumeButton extends ConsumerWidget {
  const _ResumeButton({required this.subscription});

  final SubscriptionView subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final action = ref.watch(billingActionProvider);
    final controller = ref.read(billingActionProvider.notifier);

    Future<void> resume() async {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.billingResumeTitle,
        message: l10n.billingResumeBody,
        confirmLabel: l10n.billingResumeAction,
      );
      if (!confirmed) return;
      if (await controller.resumeSubscription() && context.mounted) {
        showAppSnackbar(context, l10n.billingResumed, tone: SnackTone.success);
      }
    }

    return AppButton(label: l10n.billingResumeAction, busy: action.busy, onPressed: resume);
  }
}

/// Asks for the reason the academy keeps on its record. Under three characters it is not sent.
Future<String?> showCancelReasonSheet(BuildContext context) =>
    showAppBottomSheet<String>(context, builder: (_) => const _CancelSheet());

class _CancelSheet extends StatefulWidget {
  const _CancelSheet();

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  String _reason = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.billingCancelTitle, style: context.type.titleM),
          const SizedBox(height: Space.s2),
          Text(l10n.billingCancelBody, style: context.type.bodyM),
          const SizedBox(height: Space.s4),
          AppTextField(
            label: l10n.billingCancelReasonLabel,
            required: true,
            minLines: 3,
            maxLines: 6,
            maxLength: maxCancelReason,
            helperText: l10n.billingCancelReasonHelp,
            onChanged: (text) => setState(() => _reason = text),
          ),
          const SizedBox(height: Space.s4),
          AppButton(
            label: l10n.billingCancelAction,
            variant: AppButtonVariant.destructive,
            onPressed: cancelReasonIsEnough(_reason)
                ? () => Navigator.of(context).pop(_reason.trim())
                : null,
          ),
        ],
      ),
    );
  }
}
