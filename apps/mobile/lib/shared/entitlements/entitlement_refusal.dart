import 'package:flutter/material.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/theme.dart';
import '../../l10n/l10n.dart';
import '../widgets/widgets.dart';

/// Why the server refused, in the app's terms (§9.1). The backend decides; this only chooses what
/// the person is told and whether a "Review plan" action makes sense for them.
enum RefusalKind {
  /// 403 `PERMISSION_DENIED` — this account lacks the permission key.
  permission,

  /// 402 `SUBSCRIPTION_REQUIRED` / no code — the academy has no plan to act on.
  subscriptionRequired,

  /// 402 `SUBSCRIPTION_EXPIRED` (or past due) — the plan has lapsed.
  subscriptionExpired,

  /// 403 `FEATURE_NOT_INCLUDED` — the plan does not include this.
  featureNotIncluded,

  /// 403 `LIMIT_REACHED` — the plan's allowance is used up.
  limitReached,
}

/// Recognises the refusals §9 lists. Anything else is an ordinary failure the screen handles as
/// usual — this never guesses.
RefusalKind? refusalKindOf(AppFailure failure) => switch (failure) {
  PermissionFailure() => RefusalKind.permission,
  EntitlementFailure(problem: EntitlementProblem.subscriptionRequired) =>
    RefusalKind.subscriptionRequired,
  EntitlementFailure(problem: EntitlementProblem.subscriptionExpired) ||
  EntitlementFailure(
    problem: EntitlementProblem.subscriptionPastDue,
  ) => RefusalKind.subscriptionExpired,
  EntitlementFailure(problem: EntitlementProblem.featureNotIncluded) =>
    RefusalKind.featureNotIncluded,
  EntitlementFailure(problem: EntitlementProblem.limitReached) => RefusalKind.limitReached,
  _ => null,
};

/// A short line for a snackbar or an inline row, when a whole page would be too much.
String refusalMessage(AppLocalizations l10n, RefusalKind kind, {String? serverMessage}) {
  final title = switch (kind) {
    RefusalKind.permission => l10n.permissionDeniedInline,
    RefusalKind.subscriptionRequired => l10n.stateSubscriptionRequiredTitle,
    RefusalKind.subscriptionExpired => l10n.stateSubscriptionExpiredTitle,
    RefusalKind.featureNotIncluded => l10n.stateFeatureUnavailableTitle,
    RefusalKind.limitReached => l10n.entitlementLimitReachedTitle,
  };
  // The server writes its message for people; it is the detail, never the whole explanation.
  return serverMessage == null || serverMessage.isEmpty ? title : '$title $serverMessage';
}

/// The full-page view for a refusal (§22.6). [onReviewPlan] is passed only for an academy admin who
/// may read billing — everyone else is told to contact their academy, never shown plan details.
class RefusalView extends StatelessWidget {
  const RefusalView({required this.kind, super.key, this.serverMessage, this.onReviewPlan});

  final RefusalKind kind;
  final String? serverMessage;
  final VoidCallback? onReviewPlan;

  /// Builds the view for [failure], or null when it is not one of §9's refusals.
  static Widget? forFailure(AppFailure failure, {VoidCallback? onReviewPlan}) {
    final kind = refusalKindOf(failure);
    if (kind == null) return null;
    return RefusalView(kind: kind, serverMessage: failure.message, onReviewPlan: onReviewPlan);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (kind) {
      RefusalKind.permission => PermissionDeniedView(detail: serverMessage),
      RefusalKind.subscriptionRequired => SubscriptionStateView(
        problem: SubscriptionProblem.required,
        detail: serverMessage,
        onReviewPlan: onReviewPlan,
      ),
      RefusalKind.subscriptionExpired => SubscriptionStateView(
        problem: SubscriptionProblem.expired,
        detail: serverMessage,
        onReviewPlan: onReviewPlan,
      ),
      RefusalKind.featureNotIncluded => FeatureUnavailableView(
        detail: serverMessage,
        onReviewPlan: onReviewPlan,
      ),
      RefusalKind.limitReached => StateLayout(
        icon: AppIcons.warning,
        tone: Tone.warn,
        title: l10n.entitlementLimitReachedTitle,
        message: onReviewPlan == null
            ? l10n.stateFeatureUnavailableBodyMember
            : l10n.entitlementLimitReachedBody,
        detail: serverMessage,
        actionLabel: onReviewPlan == null ? null : l10n.actionReviewPlan,
        onAction: onReviewPlan,
      ),
    };
  }
}
