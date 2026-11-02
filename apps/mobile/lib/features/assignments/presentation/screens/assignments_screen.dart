import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/assignment_controller.dart';

/// `/assignments` — every piece of coursework across the learner's courses, in the order the
/// server put them: by deadline, soonest first. A shell body.
class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(assignmentsProvider.future),
      child: AsyncView<List<LearnerAssignment>>(
        value: ref.watch(assignmentsProvider),
        onRetry: () => ref.invalidate(assignmentsProvider),
        data: (rows) => rows.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 360,
                    child: EmptyState(
                      title: l10n.assignmentsEmptyTitle,
                      message: l10n.assignmentsEmptyBody,
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s6),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.s3),
                itemBuilder: (context, i) => AssignmentCard(row: rows[i]),
              ),
      ),
    );
  }
}

/// One assignment, laid out like the tests beside it: its icon on the assignment hue (red once it
/// is late), the course, the title, when it is due for this learner, the grade when there is one,
/// and what tapping it does.
class AssignmentCard extends StatelessWidget {
  const AssignmentCard({required this.row, super.key, this.now});

  final LearnerAssignment row;

  /// Overridable so a test does not depend on the clock.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final due = row.dueAt;
    final status = assignmentStateBadge(row);
    final late = status == StatusKind.overdue;
    final colors = late ? c.tone(Tone.danger) : c.hue(Hue.orange);
    return AppCard(
      onTap: () => goWithin(context, AppRoutes.assignment(row.assignment.id)),
      padding: const EdgeInsets.all(Space.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PracticeThumb(icon: AppIcons.assignment, colors: colors),
              const SizedBox(width: Space.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            row.courseTitle,
                            style: type.caption.copyWith(color: c.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (status != null) ...[
                          const SizedBox(width: Space.s2),
                          StatusBadge(status),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row.assignment.title,
                      style: type.titleS,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Space.s1),
                    MetaItem(
                      icon: AppIcons.date,
                      color: late ? c.dangerInk : null,
                      label: due == null
                          ? l10n.assignmentNoDeadline
                          : l10n.assignmentDueRelative(
                              DatesIst.relative(l10n, due, now ?? DateTime.now()),
                            ),
                    ),
                    if (row.submission?.review.gradedScore case final score?) ...[
                      const SizedBox(height: Space.s1),
                      Text(
                        l10n.assignmentScore(_points(score), row.assignment.totalPoints),
                        style: type.bodyS.copyWith(
                          color: c.hue(Hue.green).ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s3),
          CardActionBar(label: l10n.actionOpenAssignment, colors: colors),
        ],
      ),
    );
  }
}

/// The badge an assignment carries. A submission the reviewer sent back reads as `draft`, so the
/// review's own status is what decides (`routes/learning.ts`).
StatusKind? assignmentStateBadge(LearnerAssignment row) {
  if (row.isReturned) return StatusKind.resubmissionRequested;
  return switch (row.state) {
    AssignmentState.notStarted => StatusKind.notStarted,
    AssignmentState.draft => StatusKind.draftSaved,
    AssignmentState.submitted => StatusKind.submitted,
    AssignmentState.underReview => StatusKind.underReview,
    AssignmentState.graded => StatusKind.graded,
    AssignmentState.overdue => StatusKind.overdue,
    AssignmentState.closed => StatusKind.closed,
    AssignmentState.unknown => null,
  };
}

/// A score the server sent as a number, written the way a person reads it.
String _points(num value) =>
    value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);

/// The same, for the detail screen.
String pointsLabel(num value) => _points(value);
