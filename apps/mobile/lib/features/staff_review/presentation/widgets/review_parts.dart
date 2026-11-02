import 'package:flutter/material.dart';

import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/figures.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_review_controller.dart';

/// The badge a hand-in carries, from the academy's own review status. An overdue one says so first:
/// it is the thing that needs doing.
StatusKind submissionStatusKind(SubmissionRow row) {
  if (row.isMissing) return StatusKind.notSubmitted;
  if (row.overdue) return StatusKind.overdueReview;
  return switch (row.submission!.review.status) {
    ReviewStatus.waiting => StatusKind.toReview,
    ReviewStatus.inReview => StatusKind.draftReview,
    ReviewStatus.graded => StatusKind.graded,
    ReviewStatus.returned => StatusKind.resubmissionRequested,
    ReviewStatus.unknown => StatusKind.toReview,
  };
}

/// One hand-in in the queue: who, what, when, and where it stands. The strip is the review's own
/// orange, or red while the academy counts it overdue. A row with nothing handed in is not a door —
/// there is no review to open.
class SubmissionCard extends StatelessWidget {
  const SubmissionCard({required this.row, required this.onOpen, super.key, this.selected = false});

  final SubmissionRow row;
  final VoidCallback? onOpen;

  /// Drawn as the one being reviewed, in the two-pane layout.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final submission = row.submission;
    final score = submission?.review.gradedScore;
    final badge = StatusBadge(submissionStatusKind(row));
    // At the largest text sizes the badge no longer fits on the strip beside the course, so it
    // leads the facts instead.
    final badgeOnStrip = MediaQuery.textScalerOf(context).scale(1) <= 1.3;

    final card = StripCard(
      strip: row.overdue ? c.tone(Tone.danger) : c.hue(AppNavIcons.of(AppIcons.review).hue),
      stripIcon: row.overdue ? AppIcons.warning : AppIcons.review,
      stripLabel: row.courseTitle,
      badge: badgeOnStrip ? badge : null,
      title: row.student.name,
      subtitle: row.assignmentTitle,
      facts: [
        if (!badgeOnStrip) Align(alignment: Alignment.centerLeft, child: badge),
        if (submission == null)
          MetaItem(icon: AppIcons.time, label: l10n.reviewNotHandedIn)
        else ...[
          MetaItem(
            icon: AppIcons.date,
            label: [
              l10n.reviewSubmittedOn(DatesIst.dateTime(l10n, submission.submittedAt)),
              if (submission.attempt > 1) l10n.reviewAttemptNumber(submission.attempt),
            ].join(' · '),
          ),
          if (score != null)
            MetaItem(
              icon: AppIcons.rating,
              label: l10n.reviewScoreOf(formatFigure(score), formatFigure(row.maxScore)),
            ),
          if (submission.late)
            const Align(alignment: Alignment.centerLeft, child: StatusBadge(StatusKind.late)),
        ],
      ],
      onTap: onOpen,
    );
    if (!selected) return card;
    return Semantics(
      selected: true,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: c.accent, width: 2),
        ),
        child: card,
      ),
    );
  }
}

/// Where this hand-in sits among those still waiting, and the way to the next one.
class ReviewQueueNav extends StatelessWidget {
  const ReviewQueueNav({
    required this.queue,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final ReviewQueuePosition queue;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // A Wrap, not a Row: at the largest text size the two buttons and the count do not fit on one
    // line, and nothing here may be cut off (§20).
    return Wrap(
      spacing: Space.s2,
      runSpacing: Space.s2,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppButton(
          label: l10n.actionPrevious,
          variant: AppButtonVariant.tertiary,
          onPressed: onPrevious,
        ),
        if (queue.isInQueue)
          Text(
            l10n.reviewQueuePosition(queue.position, queue.total),
            style: context.type.caption.copyWith(color: context.colors.muted),
          ),
        AppButton(
          label: l10n.reviewNextInQueue,
          variant: AppButtonVariant.tertiary,
          onPressed: onNext,
        ),
      ],
    );
  }
}
