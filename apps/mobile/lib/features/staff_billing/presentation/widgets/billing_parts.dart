import 'package:flutter/material.dart';

import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/figures.dart';
import '../../../../core/format/money.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_billing_controller.dart';

/// How a subscription's standing is drawn. Each is the academy's own word for it.
StatusKind subscriptionStatusKind(SubscriptionStatus status) => switch (status) {
  SubscriptionStatus.trial => StatusKind.trial,
  SubscriptionStatus.active => StatusKind.subscriptionActive,
  SubscriptionStatus.pastDue => StatusKind.pastDue,
  SubscriptionStatus.canceling => StatusKind.canceling,
  SubscriptionStatus.canceled => StatusKind.canceled,
  SubscriptionStatus.paused => StatusKind.subscriptionPaused,
  SubscriptionStatus.expired || SubscriptionStatus.unknown => StatusKind.expired,
};

/// How an invoice's standing is drawn.
StatusKind invoiceStatusKind(InvoiceStatus status) => switch (status) {
  InvoiceStatus.paid => StatusKind.paid,
  InvoiceStatus.pending => StatusKind.pending,
  InvoiceStatus.failed => StatusKind.failed,
  InvoiceStatus.refunded => StatusKind.refunded,
  InvoiceStatus.voided || InvoiceStatus.unknown => StatusKind.voided,
};

/// How an invoice's standing reads.
String invoiceStatusLabel(AppLocalizations l10n, InvoiceStatus status) => switch (status) {
  InvoiceStatus.paid => l10n.invoiceStatusPaid,
  InvoiceStatus.pending => l10n.invoiceStatusPending,
  InvoiceStatus.failed => l10n.invoiceStatusFailed,
  InvoiceStatus.refunded => l10n.invoiceStatusRefunded,
  InvoiceStatus.voided || InvoiceStatus.unknown => l10n.invoiceStatusVoid,
};

/// An amount the academy fixed, formatted and never recomputed.
String money(int minor, String currency) => Money.format(minor, currency);

/// What a plan limit is called: the academy's own label where its usage names the limit, otherwise
/// the app's name for a catalogue limit. A limit this build does not know keeps the academy's key.
String limitLabel(AppLocalizations l10n, String key, {List<UsageLine> usage = const []}) {
  final named = usage.where((line) => line.limit == key).firstOrNull?.label;
  if (named != null && named.isNotEmpty) return named;
  return switch (key) {
    'learners.max' => l10n.limitLearners,
    'instructors.max' => l10n.limitInstructors,
    'courses.max' => l10n.limitCourses,
    'storage.bytes' => l10n.limitStorage,
    'live_classes.max' => l10n.limitLiveClasses,
    'admin_accounts.max' => l10n.limitAdminAccounts,
    _ => key,
  };
}

/// A plan limit's value as a person reads it: "Unlimited" for no ceiling, storage in GB or MB, and
/// counts with the academy's grouping.
String limitValue(AppLocalizations l10n, String key, int? value) {
  if (value == null) return l10n.plansLimitUnlimited;
  if (key == 'storage.bytes') {
    const mb = 1024 * 1024;
    const gb = 1024 * mb;
    if (value >= gb) return l10n.limitStorageGb(formatFigure(value / gb));
    return l10n.limitStorageMb(formatFigure(value / mb));
  }
  return formatCount(value);
}

/// The limits a plan card lists, most telling first; a limit the academy added later follows.
const _limitOrder = [
  'learners.max',
  'instructors.max',
  'courses.max',
  'storage.bytes',
  'live_classes.max',
  'admin_accounts.max',
];

/// [limits] in the order a card lists them.
List<MapEntry<String, int?>> orderedLimits(Map<String, int?> limits) {
  int rank(String key) {
    final at = _limitOrder.indexOf(key);
    return at == -1 ? _limitOrder.length : at;
  }

  return limits.entries.toList()..sort((a, b) => rank(a.key).compareTo(rank(b.key)));
}

/// The plan card: what the academy is on, what it costs, and what its status means right now.
class PlanCard extends StatelessWidget {
  const PlanCard({required this.billing, required this.now, super.key});

  final TenantBilling billing;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subscription = billing.subscription;
    final plan = billing.plan;

    if (subscription == null) {
      return DetailHeader(
        icon: AppIcons.subscription,
        tone: Tone.warn,
        title: l10n.billingNoPlanTitle,
        footer: [Text(l10n.billingNoPlanBody, style: context.type.bodyM)],
      );
    }

    return DetailHeader(
      icon: AppIcons.subscription,
      badge: StatusBadge(subscriptionStatusKind(subscription.status)),
      title: plan?.name ?? l10n.billingTitle,
      facts: [
        MetaItem(
          icon: AppIcons.billing,
          label: [
            money(subscription.amount, subscription.currency),
            subscription.cycle == BillingCycle.annual
                ? l10n.billingPlanCycleAnnual
                : l10n.billingPlanCycleMonthly,
          ].join(' · '),
        ),
        MetaItem(
          icon: AppIcons.date,
          label: subscription.isCanceling
              ? l10n.billingEndsOn(DatesIst.date(subscription.renewsAt))
              : l10n.billingRenewsOn(DatesIst.date(subscription.renewsAt)),
        ),
        if (subscription.paymentMethod.brand.isNotEmpty)
          MetaItem(
            icon: AppIcons.billing,
            label: '${l10n.billingPaymentMethod}: ${subscription.paymentMethod.label}',
          ),
      ],
    );
  }
}

/// What the academy's status means for the reader now — a trial running out, a payment that failed, a
/// plan ending. Every date and amount is the academy's.
class BillingStateNotice extends StatelessWidget {
  const BillingStateNotice({required this.billing, required this.now, super.key});

  final TenantBilling billing;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subscription = billing.subscription;
    if (subscription == null) return const SizedBox.shrink();

    if (subscription.trialDaysLeft(now) case final days?) {
      return BillingNotice(tone: Tone.info, message: l10n.billingTrialDaysLeft(days));
    }
    if (subscription.isPastDue) {
      final due = subscription.amountDue ?? 0;
      final grace = subscription.graceEndsAt;
      return BillingNotice(
        tone: Tone.warn,
        title: l10n.billingPastDueTitle,
        message: [
          if (grace != null)
            l10n.billingPastDueBody(money(due, subscription.currency), DatesIst.date(grace)),
          if (subscription.nextRetryAt case final retry?) l10n.billingRetryOn(DatesIst.date(retry)),
        ].join(' '),
      );
    }
    if (subscription.isCanceling) {
      return BillingNotice(
        tone: Tone.warn,
        title: l10n.billingCancelingTitle(DatesIst.date(subscription.renewsAt)),
        message: l10n.billingCancelingBody,
      );
    }
    if (subscription.isPaused) {
      return BillingNotice(
        tone: Tone.info,
        title: l10n.billingPausedTitle,
        message: subscription.resumesAt == null
            ? ''
            : l10n.billingPausedResumes(DatesIst.date(subscription.resumesAt!)),
      );
    }
    if (subscription.status == SubscriptionStatus.expired ||
        subscription.status == SubscriptionStatus.canceled) {
      return BillingNotice(
        tone: Tone.warn,
        title: l10n.billingExpiredTitle,
        message: l10n.billingExpiredBody,
      );
    }
    return const SizedBox.shrink();
  }
}

/// One limit and how much of it is used. A limit with no ceiling reads "Unlimited" and draws no meter:
/// there is nothing to be a share of.
class UsageMeter extends StatelessWidget {
  const UsageMeter({required this.line, super.key});

  final UsageLine line;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(line.label, style: context.type.label)),
              Text(
                line.isUnlimited
                    ? l10n.billingUsageOf('${line.used}', l10n.billingUnlimited)
                    : l10n.billingUsageOf('${line.used}', '${line.allowed}'),
                style: context.type.caption.copyWith(color: c.muted),
              ),
            ],
          ),
          if (line.share case final share?) ...[
            const SizedBox(height: Space.s1),
            Semantics(
              label: line.label,
              child: ProgressBar(value: share),
            ),
            const SizedBox(height: Space.s1),
            Text(
              line.isFull ? l10n.billingUsageFull : l10n.billingUsageRemaining(line.remaining ?? 0),
              style: context.type.caption.copyWith(color: line.isFull ? c.warnInk : c.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// A plan on sale, with its own prices, limits and features — all the academy's.
class PlanOfferCard extends StatelessWidget {
  const PlanOfferCard({
    required this.plan,
    required this.isCurrent,
    super.key,
    this.onChooseMonthly,
    this.onChooseAnnual,
    this.monthlyLabel,
    this.annualLabel,
  });

  final PlanView plan;
  final bool isCurrent;

  /// Given only where the academy allows a change — or a first subscription — to be asked for.
  final VoidCallback? onChooseMonthly;
  final VoidCallback? onChooseAnnual;

  /// What the choices say: "Choose …" for a change by default, "Subscribe …" for a first purchase.
  final String? monthlyLabel;
  final String? annualLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HueTile(icon: AppIcons.subscription, hue: AppNavIcons.of(AppIcons.billing).hue),
              const SizedBox(width: Space.s3),
              Expanded(child: Text(plan.name, style: context.type.titleM)),
              if (isCurrent)
                StatusBadge(StatusKind.subscriptionActive, labelOverride: l10n.plansCurrentPlan),
            ],
          ),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: Space.s2),
            Text(plan.description, style: context.type.bodyS.copyWith(color: c.muted)),
          ],
          const SizedBox(height: Space.s3),
          if (plan.sellsMonthly)
            Text(
              l10n.plansPerMonth(
                Money.format(plan.monthlyPrice, plan.currency, dropZeroFraction: true),
              ),
              style: context.type.titleL.copyWith(color: c.accentInk),
            ),
          if (plan.sellsAnnual)
            Text(
              l10n.plansPerYear(
                Money.format(plan.annualPrice, plan.currency, dropZeroFraction: true),
              ),
              style: context.type.bodyM.copyWith(fontWeight: FontWeight.w600),
            ),
          if (plan.trialEnabled && plan.trialDays > 0) ...[
            const SizedBox(height: Space.s2),
            StatusBadge(StatusKind.trial, labelOverride: l10n.plansTrial(plan.trialDays)),
          ],
          if (plan.limits.isNotEmpty) ...[
            const SizedBox(height: Space.s3),
            Text(l10n.plansLimitsTitle, style: context.type.label.copyWith(color: c.muted)),
            KeyValueTable(
              rows: [
                for (final entry in orderedLimits(plan.limits))
                  (limitLabel(l10n, entry.key), limitValue(l10n, entry.key, entry.value)),
              ],
            ),
          ],
          if (onChooseMonthly != null || onChooseAnnual != null) ...[
            const SizedBox(height: Space.s3),
            Wrap(
              spacing: Space.s2,
              runSpacing: Space.s2,
              children: [
                if (onChooseMonthly != null && plan.sellsMonthly)
                  AppButton(
                    label: monthlyLabel ?? l10n.plansChooseMonthly,
                    variant: AppButtonVariant.secondary,
                    onPressed: onChooseMonthly,
                  ),
                if (onChooseAnnual != null && plan.sellsAnnual)
                  AppButton(
                    label: annualLabel ?? l10n.plansChooseAnnual,
                    onPressed: onChooseAnnual,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A short notice in the academy's own words, toned as the situation calls for.
class BillingNotice extends StatelessWidget {
  const BillingNotice({required this.tone, required this.message, super.key, this.title});

  final Tone tone;
  final String? title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (background, ink) = switch (tone) {
      Tone.warn => (c.warnSoft, c.warnInk),
      Tone.danger => (c.dangerSoft, c.dangerInk),
      _ => (c.accentSoft, c.accentInk),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Space.s3),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(Radii.lg)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title case final title? when title.isNotEmpty)
              Text(title, style: context.type.titleS.copyWith(color: ink)),
            if (message.isNotEmpty) Text(message, style: context.type.bodyS.copyWith(color: ink)),
          ],
        ),
      ),
    );
  }
}
