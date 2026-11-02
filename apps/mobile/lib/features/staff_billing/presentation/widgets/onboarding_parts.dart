import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/auth/capabilities.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/format/money.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/session/current_user.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_billing_controller.dart';
import '../../application/trial_controller.dart';
import 'billing_parts.dart';

/// What the onboarding screen says when the academy refuses a trial. The academy's code decides
/// which; its own words follow where it sent any.
String trialFailureMessage(AppLocalizations l10n, AppFailure failure) =>
    switch (trialRefusalOf(failure)) {
      TrialRefusal.planUnavailable => l10n.trialErrorPlanUnavailable,
      TrialRefusal.alreadySubscribed => l10n.trialErrorAlreadySubscribed,
      TrialRefusal.other => switch (refusalKindOf(failure)) {
        final kind? => refusalMessage(l10n, kind, serverMessage: failure.message),
        null => failure.message ?? l10n.stateErrorBody,
      },
    };

/// What a plan feature is called: the academy's own label where the billing page names it,
/// otherwise the app's name for a catalogue feature. One this build does not know is not listed.
String? featureLabel(AppLocalizations l10n, String key, {List<FeatureLine> lines = const []}) {
  final named = lines.where((line) => line.key == key).firstOrNull?.label;
  if (named != null && named.isNotEmpty) return named;
  return switch (FeatureKey.parse(key)) {
    FeatureKey.coursesManage => l10n.featureCoursesManage,
    FeatureKey.assessmentsManage => l10n.featureAssessmentsManage,
    FeatureKey.certificatesManage => l10n.featureCertificatesManage,
    FeatureKey.liveClasses => l10n.featureLiveClasses,
    FeatureKey.reportsBasic => l10n.featureReportsBasic,
    FeatureKey.reportsAdvanced => l10n.featureReportsAdvanced,
    FeatureKey.analyticsAdvanced => l10n.featureAnalyticsAdvanced,
    FeatureKey.customBranding => l10n.featureCustomBranding,
    FeatureKey.prioritySupport => l10n.featurePrioritySupport,
    FeatureKey.unknown => null,
  };
}

/// Monthly or yearly, for a screen that shows every plan's price on one cycle. Offered only when the
/// plans on sale are sold both ways; otherwise the one cycle there is needs no choice.
class CycleToggle extends StatelessWidget {
  const CycleToggle({required this.cycle, required this.onChanged, super.key});

  final BillingCycle cycle;
  final ValueChanged<BillingCycle> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      label: l10n.onboardingCycleLabel,
      container: true,
      child: SegmentedButton<BillingCycle>(
        segments: [
          ButtonSegment(value: BillingCycle.monthly, label: Text(l10n.onboardingCycleMonthly)),
          ButtonSegment(value: BillingCycle.annual, label: Text(l10n.onboardingCycleAnnual)),
        ],
        selected: {cycle},
        showSelectedIcon: false,
        onSelectionChanged: (values) => onChanged(values.first),
      ),
    );
  }
}

/// A plan on the choose-a-plan screen: its price on the chosen cycle, its trial, its main limits and
/// what it includes — every figure the academy's — and the actions this admin may take on it.
class OnboardingPlanCard extends StatelessWidget {
  const OnboardingPlanCard({
    required this.plan,
    required this.cycle,
    required this.billing,
    super.key,
    this.onStartTrial,
    this.trialBusy = false,
    this.onBuy,
  });

  final PlanView plan;
  final BillingCycle cycle;

  /// For the academy's own names of limits and features.
  final TenantBilling billing;

  /// Given only where this academy may start this plan's trial on [cycle].
  final VoidCallback? onStartTrial;
  final bool trialBusy;

  /// Given only where this build takes payments and the academy has a gateway connected.
  final VoidCallback? onBuy;

  bool get _sold => cycle == BillingCycle.annual ? plan.sellsAnnual : plan.sellsMonthly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final price = Money.format(plan.priceFor(cycle), plan.currency, dropZeroFraction: true);
    final features = [
      for (final key in plan.features) ?featureLabel(l10n, key, lines: billing.features),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HueTile(icon: AppIcons.subscription, hue: AppNavIcons.of(AppIcons.billing).hue),
              const SizedBox(width: Space.s3),
              Expanded(
                child: Semantics(header: true, child: Text(plan.name, style: context.type.titleM)),
              ),
              if (plan.offersTrial)
                StatusBadge(StatusKind.trial, labelOverride: l10n.plansTrial(plan.trialDays)),
            ],
          ),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: Space.s1),
            Text(plan.description, style: context.type.bodyS.copyWith(color: c.muted)),
          ],
          const SizedBox(height: Space.s3),
          if (_sold)
            Text(
              cycle == BillingCycle.annual ? l10n.plansPerYear(price) : l10n.plansPerMonth(price),
              style: context.type.titleL.copyWith(color: c.accentInk),
            )
          else
            Text(
              cycle == BillingCycle.annual
                  ? l10n.onboardingNotSoldAnnual
                  : l10n.onboardingNotSoldMonthly,
              style: context.type.bodyS.copyWith(color: c.muted),
            ),
          if (plan.limits.isNotEmpty) ...[
            const SizedBox(height: Space.s3),
            KeyValueTable(
              rows: [
                for (final entry in orderedLimits(plan.limits).take(4))
                  (
                    limitLabel(l10n, entry.key, usage: billing.usage),
                    limitValue(l10n, entry.key, entry.value),
                  ),
              ],
            ),
          ],
          if (features.isNotEmpty) ...[
            const SizedBox(height: Space.s3),
            Text(l10n.plansFeaturesTitle, style: context.type.label),
            const SizedBox(height: Space.s1),
            for (final feature in features)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(AppIcons.check, size: IconSizes.sm, color: c.accentInk),
                    const SizedBox(width: Space.s2),
                    Expanded(child: Text(feature, style: context.type.bodyS)),
                  ],
                ),
              ),
          ],
          if (onStartTrial != null || onBuy != null) ...[
            const SizedBox(height: Space.s4),
            if (onStartTrial != null)
              AppButton(
                label: l10n.onboardingStartTrial(plan.trialDays),
                icon: AppIcons.rocket,
                busy: trialBusy,
                expand: true,
                onPressed: onStartTrial,
              ),
            if (onStartTrial != null && onBuy != null) const SizedBox(height: Space.s2),
            if (onBuy != null)
              AppButton(
                label: l10n.onboardingBuy(price),
                variant: onStartTrial == null
                    ? AppButtonVariant.primary
                    : AppButtonVariant.secondary,
                expand: true,
                onPressed: onBuy,
              ),
          ],
        ],
      ),
    );
  }
}

/// The dashboard's offer of a free trial while plans are **not** enforced and the academy has never
/// subscribed: nothing is refused yet, so nothing is forced — the admin may start a trial, or close
/// the card for good. Shown only to an admin who may start one, and only when the academy says a
/// trial is available. Quiet while the billing page loads or fails: it is an offer, not a page.
class TrialOfferCard extends ConsumerWidget {
  const TrialOfferCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!can(ref.watch(currentUserProvider), Capability.changeBilling)) {
      return const SizedBox.shrink();
    }
    final plan = ref.watch(academyPlanProvider).value;
    if (plan == null || plan.enforced || !plan.neverSubscribed) return const SizedBox.shrink();
    if (ref.watch(trialOfferDismissedProvider)) return const SizedBox.shrink();
    final trialPlans = ref.watch(tenantBillingProvider).value?.trialPlans ?? const [];
    if (trialPlans.isEmpty) return const SizedBox.shrink();

    final l10n = context.l10n;
    final c = context.colors;
    final days = trialPlans.map((p) => p.trialDays).reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s4),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HueTile(icon: AppIcons.rocket, hue: AppNavIcons.of(AppIcons.billing).hue),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(l10n.trialOfferTitle(days), style: context.type.titleS),
                      ),
                      const SizedBox(height: Space.s1),
                      Text(l10n.trialOfferBody, style: context.type.bodyS.copyWith(color: c.muted)),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: AppIcons.close,
                  label: l10n.trialOfferDismiss,
                  onPressed: () => ref.read(trialOfferDismissedProvider.notifier).dismiss(),
                ),
              ],
            ),
            const SizedBox(height: Space.s3),
            AppButton(
              label: l10n.trialOfferAction,
              expand: true,
              onPressed: () => GoRouter.of(context).go(AppRoutes.staffGetStarted),
            ),
          ],
        ),
      ),
    );
  }
}
