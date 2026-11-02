import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../actions/app_button.dart';
import '../icons/app_icons.dart';

/// The layout every full-page state shares: visual, title, one sentence, one action (§22.6).
class StateLayout extends StatelessWidget {
  const StateLayout({
    required this.title,
    super.key,
    this.icon,
    this.illustration,
    this.message,
    this.detail,
    this.actionLabel,
    this.onAction,
    this.tone = Tone.neutral,
  });

  final String title;
  final IconData? icon;
  final Widget? illustration;
  final String? message;

  /// A small secondary line (the server's message where useful).
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Space.s5, vertical: Space.s6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Space.authMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?illustration,
              if (illustration == null && icon != null) ToneMark(icon: icon!, tone: tone),
              const SizedBox(height: Space.s4),
              Semantics(
                header: true,
                child: Text(title, textAlign: TextAlign.center, style: context.type.titleM),
              ),
              if (message != null) ...[
                const SizedBox(height: Space.s2),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: context.type.bodyM.copyWith(color: c.muted),
                ),
              ],
              if (detail != null) ...[
                const SizedBox(height: Space.s2),
                Text(
                  detail!,
                  textAlign: TextAlign.center,
                  style: context.type.bodyS.copyWith(color: c.muted),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: Space.s5),
                AppButton(label: actionLabel!, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Nothing here yet. [searchEmpty] drops the illustration and offers "Clear filters" (§22.6).
class EmptyState extends StatelessWidget {
  const EmptyState({required this.title, super.key, this.message, this.actionLabel, this.onAction})
    : searchEmpty = false;

  const EmptyState.noMatches({super.key, this.message, VoidCallback? onClearFilters})
    : title = null,
      actionLabel = null,
      onAction = onClearFilters,
      searchEmpty = true;

  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool searchEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (searchEmpty) {
      return StateLayout(
        title: l10n.stateNoMatchesTitle,
        message: message ?? l10n.stateNoMatchesBody,
        actionLabel: onAction == null ? null : l10n.actionClearFilters,
        onAction: onAction,
      );
    }
    return StateLayout(
      title: title!,
      message: message,
      illustration: const ConstellationArt(),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

/// A load failed. The app's copy is the title; the server's message may be the [detail].
class ErrorState extends StatelessWidget {
  const ErrorState({required this.onRetry, super.key, this.title, this.message, this.detail});

  final VoidCallback? onRetry;
  final String? title;
  final String? message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StateLayout(
      icon: AppIcons.error,
      tone: Tone.danger,
      title: title ?? l10n.stateErrorTitle,
      message: message ?? l10n.stateErrorBody,
      detail: detail,
      actionLabel: l10n.actionRetry,
      onAction: onRetry,
    );
  }
}

/// The shell's offline banner (§17).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: c.warnSoft,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s2),
            child: Row(
              children: [
                AppIcon(AppIcons.offline, size: IconSizes.sm, color: c.warnInk),
                const SizedBox(width: Space.s2),
                Expanded(
                  child: Text(
                    context.l10n.stateOfflineBanner,
                    style: context.type.bodyS.copyWith(color: c.warnInk),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The server refused for lack of a permission (§22.6).
class PermissionDeniedView extends StatelessWidget {
  const PermissionDeniedView({super.key, this.detail});

  final String? detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StateLayout(
      icon: AppIcons.lock,
      title: l10n.statePermissionDeniedTitle,
      message: l10n.statePermissionDeniedBody,
      detail: detail,
    );
  }
}

/// The academy's plan does not include this. Admins who can view billing get "Review plan";
/// everyone else is told to contact their academy (never billing details).
class FeatureUnavailableView extends StatelessWidget {
  const FeatureUnavailableView({super.key, this.detail, this.onReviewPlan});

  final String? detail;

  /// Set only for admins with billing access.
  final VoidCallback? onReviewPlan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final admin = onReviewPlan != null;
    return StateLayout(
      icon: AppIcons.featureOff,
      tone: Tone.warn,
      title: l10n.stateFeatureUnavailableTitle,
      message: admin
          ? l10n.stateFeatureUnavailableBodyAdmin
          : l10n.stateFeatureUnavailableBodyMember,
      detail: detail,
      actionLabel: admin ? l10n.actionReviewPlan : null,
      onAction: onReviewPlan,
    );
  }
}

enum SubscriptionProblem { required, expired }

/// The academy has no active subscription (402). Existing content stays available.
class SubscriptionStateView extends StatelessWidget {
  const SubscriptionStateView({required this.problem, super.key, this.detail, this.onReviewPlan});

  final SubscriptionProblem problem;
  final String? detail;
  final VoidCallback? onReviewPlan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final admin = onReviewPlan != null;
    return StateLayout(
      icon: AppIcons.subscription,
      tone: Tone.warn,
      title: problem == SubscriptionProblem.required
          ? l10n.stateSubscriptionRequiredTitle
          : l10n.stateSubscriptionExpiredTitle,
      message: admin ? l10n.stateSubscriptionBody : l10n.stateSubscriptionBodyMember,
      detail: detail,
      actionLabel: admin ? l10n.actionReviewPlan : null,
      onAction: onReviewPlan,
    );
  }
}

/// Not found or out of scope — never distinguishes "exists but not yours" (§7).
class NotFoundView extends StatelessWidget {
  const NotFoundView({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StateLayout(
      icon: AppIcons.notFound,
      title: l10n.stateNotFoundTitle,
      message: l10n.stateNotFoundBody,
      actionLabel: onBack == null ? null : l10n.actionBack,
      onAction: onBack,
    );
  }
}

/// A lesson the server reports as locked, with the server's `lockedReason`.
class UnavailableLessonView extends StatelessWidget {
  const UnavailableLessonView({required this.lockedReason, super.key, this.onOpenCurriculum});

  final String lockedReason;
  final VoidCallback? onOpenCurriculum;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StateLayout(
      icon: AppIcons.lock,
      title: l10n.stateLockedLessonTitle,
      message: lockedReason,
      actionLabel: onOpenCurriculum == null ? null : l10n.actionOpenCurriculum,
      onAction: onOpenCurriculum,
    );
  }
}

/// The empty-state illustration: small constellation line art in the palette (§22.6).
class ConstellationArt extends StatelessWidget {
  const ConstellationArt({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _ConstellationPainter(
          line: context.colors.accent.withValues(alpha: 0.45),
          star: context.colors.accent,
          gold: context.colors.warn,
        ),
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter({required this.line, required this.star, required this.gold});

  final Color line;
  final Color star;
  final Color gold;

  static const _points = [
    Offset(0.12, 0.62),
    Offset(0.32, 0.38),
    Offset(0.52, 0.5),
    Offset(0.7, 0.22),
    Offset(0.88, 0.42),
    Offset(0.66, 0.78),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [for (final p in _points) Offset(p.dx * size.width, p.dy * size.height)];
    final stroke = Paint()
      ..color = line
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (final p in pts.sublist(1, 5)) {
      path.lineTo(p.dx, p.dy);
    }
    path
      ..moveTo(pts[2].dx, pts[2].dy)
      ..lineTo(pts[5].dx, pts[5].dy);
    canvas.drawPath(path, stroke);
    for (var i = 0; i < pts.length; i++) {
      final r = i == 3 ? size.width * 0.045 : size.width * 0.03;
      canvas.drawCircle(pts[i], r, Paint()..color = i == 3 ? gold : star);
    }
    canvas.drawCircle(
      pts[3],
      size.width * 0.085,
      Paint()
        ..color = gold.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final sparkle = Paint()..color = star.withValues(alpha: 0.35);
    for (final s in const [Offset(0.2, 0.18), Offset(0.9, 0.82), Offset(0.42, 0.88)]) {
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height),
        math.max(1, size.width * 0.012),
        sparkle,
      );
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter old) =>
      old.line != line || old.star != star || old.gold != gold;
}

/// A state's large mark: an icon on a tinted circle in one of the five tones (success, a lock, a
/// refusal). Decorative — the heading beside it says what it means.
class ToneMark extends StatelessWidget {
  const ToneMark({required this.icon, super.key, this.tone = Tone.accent});

  final IconData icon;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.colors.tone(tone);
    const size = AvatarSizes.xl - Space.s2;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: t.soft, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: AppIcon(icon, size: IconSizes.hero - Space.s1, color: t.ink),
    );
  }
}
