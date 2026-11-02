import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';

/// Every status the app shows, ported from the web's `statusRegistry.tsx` and the per-domain
/// `*Meta.tsx` badges. Features map their backend values onto these; a status is always label +
/// icon (or dot) + tone, never colour alone (§19).
enum StatusKind {
  // Learning journey (statusRegistry)
  locked,
  notEnrolled,
  enrolled,
  inProgress,
  completed,
  upcoming,
  live,
  expired,
  submitted,
  underReview,
  passed,
  notPassed,
  eligible,
  notEligible,
  notStarted,
  draftSaved,
  overdue,
  startingSoon,
  cancelled,
  // Course, content, quiz
  draft,
  published,
  archived,
  freePreview,
  // Assignment and review
  closed,
  notSubmitted,
  overdueReview,
  toReview,
  draftReview,
  resubmissionRequested,
  graded,
  late,
  // Certificate
  issued,
  readyToIssue,
  revoked,
  // Live class and calendar
  scheduled,
  ended,
  recordingExpired,
  done,
  dueSoon,
  closesSoon,
  // People
  active,
  atRisk,
  suspended,
  inactive,
  paused,
  invited,
  hidden,
  // Subscription and payments
  trial,
  subscriptionActive,
  pastDue,
  canceling,
  canceled,
  subscriptionPaused,
  paid,
  pending,
  failed,
  refunded,
  voided,
  // Notifications
  important,
}

/// How a status is drawn.
@immutable
class StatusStyle {
  const StatusStyle(this.tone, {this.icon, this.dot = false, this.pulse = false});

  final Tone tone;
  final IconData? icon;

  /// A small filled dot instead of an icon (the web's `dot` badges).
  final bool dot;

  /// The one animated state ("Live now"); static under reduced motion.
  final bool pulse;
}

/// Tone and glyph per status — exhaustive, so a new kind cannot ship without a style.
StatusStyle statusStyle(StatusKind kind) => switch (kind) {
  StatusKind.locked => const StatusStyle(Tone.neutral, icon: PhosphorIconsFill.lockSimple),
  StatusKind.notEnrolled => const StatusStyle(Tone.neutral, icon: PhosphorIconsFill.circleDashed),
  StatusKind.enrolled => const StatusStyle(Tone.info, icon: PhosphorIconsFill.bookmarkSimple),
  StatusKind.inProgress => const StatusStyle(Tone.accent, icon: PhosphorIconsFill.circleHalf),
  StatusKind.completed => const StatusStyle(Tone.accent, icon: PhosphorIconsFill.checkCircle),
  StatusKind.upcoming => const StatusStyle(Tone.info, icon: PhosphorIconsFill.calendarBlank),
  StatusKind.live => const StatusStyle(Tone.danger, dot: true, pulse: true),
  StatusKind.expired => const StatusStyle(
    Tone.neutral,
    icon: PhosphorIconsFill.clockCounterClockwise,
  ),
  StatusKind.submitted => const StatusStyle(Tone.info, icon: PhosphorIconsFill.paperPlaneTilt),
  StatusKind.underReview => const StatusStyle(Tone.warn, icon: PhosphorIconsFill.hourglassMedium),
  StatusKind.passed => const StatusStyle(Tone.accent, icon: PhosphorIconsFill.sealCheck),
  StatusKind.notPassed => const StatusStyle(Tone.danger, icon: PhosphorIconsFill.xCircle),
  StatusKind.eligible => const StatusStyle(Tone.accent, icon: PhosphorIconsFill.certificate),
  StatusKind.notEligible => const StatusStyle(Tone.neutral, icon: PhosphorIconsFill.certificate),
  StatusKind.notStarted => const StatusStyle(Tone.neutral, icon: PhosphorIconsFill.circle),
  StatusKind.draftSaved => const StatusStyle(Tone.accent, icon: PhosphorIconsFill.pencilSimpleLine),
  StatusKind.overdue => const StatusStyle(Tone.danger, icon: PhosphorIconsFill.warningCircle),
  StatusKind.startingSoon => const StatusStyle(Tone.info, icon: PhosphorIconsFill.timer),
  StatusKind.cancelled => const StatusStyle(Tone.neutral, icon: PhosphorIconsFill.prohibit),
  StatusKind.draft => const StatusStyle(Tone.warn, icon: PhosphorIconsFill.pencilSimpleLine),
  StatusKind.published => const StatusStyle(Tone.accent, icon: PhosphorIconsFill.checkCircle),
  StatusKind.archived => const StatusStyle(Tone.neutral, icon: PhosphorIconsFill.archive),
  StatusKind.freePreview => const StatusStyle(Tone.info, icon: PhosphorIconsFill.eye),
  StatusKind.closed => const StatusStyle(Tone.neutral, icon: PhosphorIconsFill.lockSimple),
  StatusKind.notSubmitted => const StatusStyle(Tone.neutral, icon: PhosphorIconsFill.circleDashed),
  StatusKind.overdueReview => const StatusStyle(Tone.danger, icon: PhosphorIconsBold.warningCircle),
  StatusKind.toReview => const StatusStyle(Tone.info, icon: PhosphorIconsFill.hourglassMedium),
  StatusKind.draftReview => const StatusStyle(Tone.info, icon: PhosphorIconsFill.notePencil),
  StatusKind.resubmissionRequested => const StatusStyle(
    Tone.warn,
    icon: PhosphorIconsFill.arrowCounterClockwise,
  ),
  StatusKind.graded => const StatusStyle(Tone.accent, icon: PhosphorIconsFill.checkCircle),
  StatusKind.late => const StatusStyle(Tone.warn, icon: PhosphorIconsFill.clock),
  StatusKind.issued => const StatusStyle(Tone.accent, icon: PhosphorIconsFill.sealCheck),
  StatusKind.readyToIssue => const StatusStyle(Tone.warn, icon: PhosphorIconsFill.hourglassMedium),
  StatusKind.revoked => const StatusStyle(Tone.danger, icon: PhosphorIconsFill.prohibit),
  StatusKind.scheduled => const StatusStyle(Tone.info, icon: PhosphorIconsFill.calendarBlank),
  StatusKind.ended => const StatusStyle(Tone.accent, icon: PhosphorIconsFill.checkCircle),
  StatusKind.recordingExpired => const StatusStyle(
    Tone.neutral,
    icon: PhosphorIconsFill.clockCounterClockwise,
  ),
  StatusKind.done => const StatusStyle(Tone.accent, icon: PhosphorIconsFill.checkCircle),
  StatusKind.dueSoon => const StatusStyle(Tone.warn, icon: PhosphorIconsFill.timer),
  StatusKind.closesSoon => const StatusStyle(Tone.warn, icon: PhosphorIconsFill.timer),
  StatusKind.active => const StatusStyle(Tone.accent, dot: true),
  StatusKind.atRisk => const StatusStyle(Tone.warn, icon: PhosphorIconsBold.warningCircle),
  StatusKind.suspended => const StatusStyle(Tone.danger, icon: PhosphorIconsBold.prohibit),
  StatusKind.inactive => const StatusStyle(Tone.neutral, icon: PhosphorIconsFill.moon),
  StatusKind.paused => const StatusStyle(Tone.warn, icon: PhosphorIconsFill.pause),
  StatusKind.invited => const StatusStyle(Tone.info, icon: PhosphorIconsFill.envelopeSimple),
  StatusKind.hidden => const StatusStyle(Tone.neutral, icon: PhosphorIconsFill.eyeSlash),
  StatusKind.trial => const StatusStyle(Tone.info, icon: PhosphorIconsFill.hourglassMedium),
  StatusKind.subscriptionActive => const StatusStyle(
    Tone.accent,
    icon: PhosphorIconsFill.checkCircle,
  ),
  StatusKind.pastDue => const StatusStyle(Tone.danger, icon: PhosphorIconsFill.warningCircle),
  StatusKind.canceling => const StatusStyle(Tone.warn, icon: PhosphorIconsFill.clockCountdown),
  StatusKind.canceled => const StatusStyle(Tone.neutral, icon: PhosphorIconsFill.xCircle),
  StatusKind.subscriptionPaused => const StatusStyle(
    Tone.neutral,
    icon: PhosphorIconsFill.pauseCircle,
  ),
  StatusKind.paid => const StatusStyle(Tone.accent, icon: PhosphorIconsFill.checkCircle),
  StatusKind.pending => const StatusStyle(Tone.info, icon: PhosphorIconsFill.hourglassMedium),
  StatusKind.failed => const StatusStyle(Tone.danger, icon: PhosphorIconsFill.xCircle),
  StatusKind.refunded => const StatusStyle(Tone.warn, icon: PhosphorIconsFill.arrowUUpLeft),
  StatusKind.voided => const StatusStyle(Tone.neutral, icon: PhosphorIconsFill.prohibit),
  StatusKind.important => const StatusStyle(Tone.danger, icon: PhosphorIconsFill.warningCircle),
};

/// The visible label for [kind], from the ARB file.
String statusLabel(AppLocalizations l10n, StatusKind kind) => switch (kind) {
  StatusKind.locked => l10n.statusLocked,
  StatusKind.notEnrolled => l10n.statusNotEnrolled,
  StatusKind.enrolled => l10n.statusEnrolled,
  StatusKind.inProgress => l10n.statusInProgress,
  StatusKind.completed => l10n.statusCompleted,
  StatusKind.upcoming => l10n.statusUpcoming,
  StatusKind.live => l10n.statusLive,
  StatusKind.expired => l10n.statusExpired,
  StatusKind.submitted => l10n.statusSubmitted,
  StatusKind.underReview => l10n.statusUnderReview,
  StatusKind.passed => l10n.statusPassed,
  StatusKind.notPassed => l10n.statusNotPassed,
  StatusKind.eligible => l10n.statusEligible,
  StatusKind.notEligible => l10n.statusNotEligible,
  StatusKind.notStarted => l10n.statusNotStarted,
  StatusKind.draftSaved => l10n.statusDraftSaved,
  StatusKind.overdue => l10n.statusOverdue,
  StatusKind.startingSoon => l10n.statusStartingSoon,
  StatusKind.cancelled => l10n.statusCancelled,
  StatusKind.draft => l10n.statusDraft,
  StatusKind.published => l10n.statusPublished,
  StatusKind.archived => l10n.statusArchived,
  StatusKind.freePreview => l10n.statusFreePreview,
  StatusKind.closed => l10n.statusClosed,
  StatusKind.notSubmitted => l10n.statusNotSubmitted,
  StatusKind.overdueReview => l10n.statusOverdueReview,
  StatusKind.toReview => l10n.statusToReview,
  StatusKind.draftReview => l10n.statusDraftReview,
  StatusKind.resubmissionRequested => l10n.statusResubmissionRequested,
  StatusKind.graded => l10n.statusGraded,
  StatusKind.late => l10n.statusLate,
  StatusKind.issued => l10n.statusIssued,
  StatusKind.readyToIssue => l10n.statusReadyToIssue,
  StatusKind.revoked => l10n.statusRevoked,
  StatusKind.scheduled => l10n.statusScheduled,
  StatusKind.ended => l10n.statusEnded,
  StatusKind.recordingExpired => l10n.statusRecordingExpired,
  StatusKind.done => l10n.statusDone,
  StatusKind.dueSoon => l10n.statusDueSoon,
  StatusKind.closesSoon => l10n.statusClosesSoon,
  StatusKind.active => l10n.statusActive,
  StatusKind.atRisk => l10n.statusAtRisk,
  StatusKind.suspended => l10n.statusSuspended,
  StatusKind.inactive => l10n.statusInactive,
  StatusKind.paused => l10n.statusPaused,
  StatusKind.invited => l10n.statusInvited,
  StatusKind.hidden => l10n.statusHidden,
  StatusKind.trial => l10n.statusTrial,
  StatusKind.subscriptionActive => l10n.statusActive,
  StatusKind.pastDue => l10n.statusPastDue,
  StatusKind.canceling => l10n.statusCanceling,
  StatusKind.canceled => l10n.statusCanceled,
  StatusKind.subscriptionPaused => l10n.statusPaused,
  StatusKind.paid => l10n.statusPaid,
  StatusKind.pending => l10n.statusPending,
  StatusKind.failed => l10n.statusFailed,
  StatusKind.refunded => l10n.statusRefunded,
  StatusKind.voided => l10n.statusVoided,
  StatusKind.important => l10n.statusImportant,
};

enum StatusBadgeSize { sm, md }

/// A status pill: tinted background, ink text, icon or dot. [labelOverride] replaces the label
/// where a screen words the same state differently ("Starts in 10 min").
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.kind, {super.key, this.size = StatusBadgeSize.sm, this.labelOverride});

  final StatusKind kind;
  final StatusBadgeSize size;
  final String? labelOverride;

  @override
  Widget build(BuildContext context) {
    final style = statusStyle(kind);
    final tone = context.colors.tone(style.tone);
    final label = labelOverride ?? statusLabel(context.l10n, kind);
    final iconSize = size == StatusBadgeSize.md ? 14.0 : 12.0;
    final textStyle = (size == StatusBadgeSize.md ? context.type.bodyS : context.type.caption)
        .copyWith(color: tone.ink, fontWeight: FontWeight.w600);

    Widget glyph;
    if (style.dot) {
      glyph = _Dot(color: tone.solid, pulse: style.pulse && !context.reduceMotion);
    } else {
      glyph = Icon(style.icon, size: iconSize, color: tone.ink);
    }

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: size == StatusBadgeSize.md ? Space.s3 : Space.s2,
          vertical: size == StatusBadgeSize.md ? Space.s1 : 2,
        ),
        decoration: BoxDecoration(
          color: tone.soft,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            glyph,
            const SizedBox(width: Space.s1 + 2),
            Flexible(child: Text(label, style: textStyle)),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.pulse});

  final Color color;
  final bool pulse;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    if (widget.pulse) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Dot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulse && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    if (!widget.pulse) return dot;
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.35).animate(_controller),
      child: dot,
    );
  }
}
