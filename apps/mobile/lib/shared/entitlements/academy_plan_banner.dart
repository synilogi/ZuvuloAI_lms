import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/routes.dart';
import '../../core/auth/capabilities.dart';
import '../../core/platform/clock.dart';
import '../../core/theme/theme.dart';
import '../../l10n/l10n.dart';
import '../session/current_user.dart';
import '../widgets/widgets.dart';
import 'academy_plan_provider.dart';
import 'dto/entitlements.dart';
import 'module_access.dart';

/// Which academy-wide notice an admin sees, if any — **one at a time**, by priority:
///
/// 1. **past due** — a payment failed and is owed, whether or not plans are enforced;
/// 2. **restricted** — no plan is served **and** plans are enforced (restricted alone refuses
///    nothing, so it is not warned of);
/// 3. **trial** — the academy is on a free trial; says how long is left.
enum AcademyNotice { pastDue, restricted, trial }

/// The notice [plan] calls for, or null. Pure, so the priority is tested on its own.
AcademyNotice? academyNoticeFor(AcademyPlan? plan) {
  if (plan == null) return null;
  if (plan.pastDue) return AcademyNotice.pastDue;
  if (plan.restrictionBites) return AcademyNotice.restricted;
  if (plan.trialing && plan.trialEndsAt != null) return AcademyNotice.trial;
  return null;
}

/// The academy-wide notice about the plan (§9.2), shown in the staff shell only to an admin who can
/// read billing — the person who can act on it — and only on the server's own word.
class AcademyPlanBanner extends ConsumerWidget {
  const AcademyPlanBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProvider);
    if (!can(profile, Capability.viewBilling)) return const SizedBox.shrink();
    final plan = ref.watch(academyPlanProvider).value;
    final notice = academyNoticeFor(plan);
    if (plan == null || notice == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    switch (notice) {
      case AcademyNotice.pastDue:
        return PlanNoticeBar(
          key: const ValueKey('banner-past-due'),
          tone: Tone.warn,
          title: l10n.pastDueBannerTitle,
          body: l10n.pastDueBannerBody,
          action: l10n.actionOpenBilling,
          route: AppRoutes.staffBilling,
        );
      case AcademyNotice.restricted:
        // A brand-new academy chooses its first plan; one whose plan ended reviews it.
        return PlanNoticeBar(
          key: const ValueKey('banner-restricted'),
          tone: Tone.warn,
          title: l10n.restrictedBannerTitle,
          body: plan.neverSubscribed ? l10n.restrictedBannerBodyNew : l10n.restrictedBannerBody,
          action: plan.neverSubscribed ? l10n.actionChoosePlan : l10n.actionReviewPlan,
          route: plan.neverSubscribed ? AppRoutes.staffGetStarted : AppRoutes.staffBilling,
        );
      case AcademyNotice.trial:
        final days = plan.trialDaysLeft(ref.watch(clockProvider)()) ?? 0;
        return PlanNoticeBar(
          key: const ValueKey('banner-trial'),
          // The last few days are worth a stronger nudge; before that it is information.
          tone: days <= 3 ? Tone.warn : Tone.info,
          title: l10n.trialBannerTitle(days),
          body: plan.plan == null
              ? l10n.trialBannerBody
              : l10n.trialBannerBodyPlan(plan.plan!.name),
          action: l10n.actionChoosePlan,
          route: AppRoutes.staffBillingPlans,
        );
    }
  }
}

/// A one-line notice above a page: a title, one sentence and one action that goes to [route].
class PlanNoticeBar extends StatelessWidget {
  const PlanNoticeBar({
    required this.tone,
    required this.title,
    required this.body,
    super.key,
    this.action,
    this.route,
  });

  final Tone tone;
  final String title;
  final String body;
  final String? action;
  final String? route;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors.tone(tone);
    final target = route;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: colors.soft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.s4, Space.s1, Space.s1, Space.s1),
          child: Row(
            children: [
              AppIcon(
                tone == Tone.info ? AppIcons.info : AppIcons.subscription,
                size: IconSizes.sm,
                color: colors.ink,
              ),
              const SizedBox(width: Space.s2),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.s1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.type.bodyS.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(body, style: context.type.caption.copyWith(color: colors.ink)),
                    ],
                  ),
                ),
              ),
              if (action != null && target != null)
                TextButton(
                  onPressed: () => GoRouter.of(context).go(target),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.ink,
                    textStyle: context.type.label,
                    minimumSize: const Size(Space.minTap, Space.minTap),
                  ),
                  child: Text(action!),
                )
              else
                const SizedBox(width: Space.s3),
            ],
          ),
        ),
      ),
    );
  }
}

/// Persistent on every page of a read-only module: the plan that included it has ended, what was
/// made stays readable, and adding new needs a plan. An admin who can read billing is offered the
/// plans; anyone else is told who can renew.
class ReadOnlyModuleBanner extends ConsumerWidget {
  const ReadOnlyModuleBanner({required this.module, super.key});

  final WorkspaceModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final admin = can(ref.watch(currentUserProvider), Capability.viewBilling);
    return PlanNoticeBar(
      tone: Tone.info,
      title: l10n.readOnlyBannerTitle(moduleName(l10n, module)),
      body: admin ? l10n.readOnlyBannerBodyAdmin : l10n.readOnlyBannerBodyMember,
      action: admin ? l10n.actionSeePlans : null,
      route: admin ? AppRoutes.staffBillingPlans : null,
    );
  }
}

/// What a disabled creation control says about why, while its module is read-only.
String readOnlyActionReason(AppLocalizations l10n, WorkspaceModule module) =>
    l10n.readOnlyActionReason(moduleName(l10n, module));

/// A destination's icon in the bottom bar or rail, marked when its module is not open: a lock for
/// **locked** (with "Upgrade" in what a screen reader says) and an eye for **read-only**. It stays
/// tappable — the page behind it explains.
class PlanAwareNavIcon extends StatelessWidget {
  const PlanAwareNavIcon({
    required this.icon,
    required this.access,
    super.key,
    this.size = IconSizes.md,
  });

  final IconData icon;
  final ModuleAccess access;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (access == ModuleAccess.open) return AppIcon(icon, size: size);
    final l10n = context.l10n;
    final c = context.colors;
    final locked = access == ModuleAccess.locked;
    final tone = c.tone(locked ? Tone.warn : Tone.neutral);
    return Semantics(
      label: locked ? l10n.navLockedHint : l10n.navReadOnlyHint,
      child: Badge(
        backgroundColor: tone.ink,
        offset: const Offset(6, -4),
        label: Icon(locked ? AppIcons.lock : AppIcons.eye, size: 10, color: c.surface),
        child: AppIcon(icon, size: size),
      ),
    );
  }
}

/// The pill beside a destination in the "More" sheet: "Upgrade" with a lock, or "Read-only".
class PlanAccessBadge extends StatelessWidget {
  const PlanAccessBadge({required this.access, super.key});

  final ModuleAccess access;

  @override
  Widget build(BuildContext context) {
    if (access == ModuleAccess.open) return const SizedBox.shrink();
    final l10n = context.l10n;
    final locked = access == ModuleAccess.locked;
    final tone = context.colors.tone(locked ? Tone.warn : Tone.neutral);
    final label = locked ? l10n.navUpgradeBadge : l10n.navReadOnlyBadge;
    return Semantics(
      label: locked ? l10n.navLockedHint : l10n.navReadOnlyHint,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: 2),
        decoration: BoxDecoration(
          color: tone.soft,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(locked ? AppIcons.lock : AppIcons.eye, size: 12, color: tone.ink),
            const SizedBox(width: Space.s1),
            Text(
              label,
              style: context.type.caption.copyWith(color: tone.ink, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// What an instructor (or an admin who cannot read billing) sees on a plan-gated module while a
/// brand-new academy has not chosen its first plan: not an error, a page that says what is coming.
class AcademySetupView extends StatelessWidget {
  const AcademySetupView({required this.module, super.key});

  final WorkspaceModule module;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StateLayout(
      icon: AppIcons.rocket,
      tone: Tone.accent,
      title: l10n.academySetupTitle,
      message: l10n.academySetupBody(moduleName(l10n, module)),
    );
  }
}
