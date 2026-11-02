import 'package:flutter/material.dart';

import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/figures.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_students_controller.dart';

/// The badge for the status the academy derived.
StatusKind studentStatusKind(StudentStatus status) => switch (status) {
  StudentStatus.active || StudentStatus.unknown => StatusKind.active,
  StudentStatus.atRisk => StatusKind.atRisk,
  StudentStatus.inactive => StatusKind.inactive,
  StudentStatus.suspended => StatusKind.suspended,
};

/// The badge for one enrolment's own state.
StatusKind enrollmentStatusKind(EnrollmentStatus status) => switch (status) {
  EnrollmentStatus.active || EnrollmentStatus.unknown => StatusKind.inProgress,
  EnrollmentStatus.completed => StatusKind.completed,
  EnrollmentStatus.paused => StatusKind.paused,
  EnrollmentStatus.expired => StatusKind.expired,
};

/// One learner in the roster. Selecting them is how a message reaches several at once, so the whole
/// row is a checkbox while the roster is selecting.
class RosterCard extends StatelessWidget {
  const RosterCard({
    required this.row,
    required this.onOpen,
    super.key,
    this.selecting = false,
    this.selected = false,
    this.onToggle,
  });

  final RosterRow row;
  final VoidCallback onOpen;
  final bool selecting;
  final bool selected;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final student = row.student;
    final quiet = student.lastActiveAt == null
        ? null
        : DateTime.now().toUtc().difference(student.lastActiveAt!).inDays;

    return AppCard(
      onTap: selecting ? onToggle : onOpen,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selecting)
            Padding(
              padding: const EdgeInsets.only(right: Space.s2),
              child: Checkbox(
                value: selected,
                onChanged: onToggle == null ? null : (_) => onToggle!(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: Space.s3),
              child: AvatarInitials(name: student.name, size: AvatarSizes.md),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The name and where they stand, side by side; the badge drops beneath the name
                // only when the text is too large for both.
                Wrap(
                  spacing: Space.s2,
                  runSpacing: Space.s1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(student.name, style: context.type.titleS),
                    StatusBadge(studentStatusKind(row.status)),
                  ],
                ),
                const SizedBox(height: Space.s1),
                Text(
                  [student.email, if (student.city.isNotEmpty) student.city].join(' · '),
                  style: context.type.bodyS.copyWith(color: c.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Space.s2),
                Wrap(
                  spacing: Space.s4,
                  runSpacing: Space.s1,
                  children: [
                    MetaItem(
                      icon: AppIcons.courses,
                      label: l10n.studentsCourseCount(row.courses.length),
                    ),
                    MetaItem(
                      icon: AppIcons.chart,
                      label: l10n.studentsProgressLabel(formatFigure(row.progress)),
                    ),
                    if (quiet != null)
                      MetaItem(icon: AppIcons.time, label: l10n.studentsQuietDays(quiet)),
                  ],
                ),
              ],
            ),
          ),
          if (!selecting) ...[
            const SizedBox(width: Space.s2),
            AppIcon(AppIcons.chevronRight, size: IconSizes.sm, color: c.faint),
          ],
        ],
      ),
    );
  }
}

/// One of the learner's enrolments, with what the academy lets staff do about it: a course card
/// with its level on the strip, its own state at the strip's end, and how far through it they are.
class EnrollmentCard extends StatelessWidget {
  const EnrollmentCard({
    required this.row,
    super.key,
    this.onPause,
    this.onRemove,
    this.busy = false,
  });

  final StudentEnrollment row;

  /// Null when this account may not change enrolments, or the enrolment is already finished.
  final VoidCallback? onPause;
  final VoidCallback? onRemove;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final enrollment = row.enrollment;
    final paused = enrollment.status == EnrollmentStatus.paused;
    final badge = StatusBadge(enrollmentStatusKind(enrollment.status));
    // At the largest text sizes the badge no longer fits on the strip beside the level, so it
    // leads the facts instead.
    final badgeOnStrip = MediaQuery.textScalerOf(context).scale(1) <= 1.3;

    return StripCard(
      strip: c.hue(AppNavIcons.of(AppIcons.courses).hue),
      stripIcon: AppIcons.courses,
      stripLabel: row.levelTitle.isEmpty ? l10n.staffStudentsEnrolmentLabel : row.levelTitle,
      badge: badgeOnStrip ? badge : null,
      title: row.courseTitle,
      subtitle: row.instructorNames.isEmpty
          ? null
          : l10n.studentTaughtBy(row.instructorNames.join(', ')),
      facts: [
        if (!badgeOnStrip) Align(alignment: Alignment.centerLeft, child: badge),
        MetaItem(
          icon: AppIcons.lessonReading,
          label: l10n.studentCourseFacts(
            row.chapters.done,
            row.chapters.total,
            row.lessons.done,
            row.lessons.total,
          ),
        ),
        if (row.lastLessonTitle case final title?)
          MetaItem(icon: AppIcons.lessonVideo, label: l10n.studentNextUp(title)),
        if (enrollment.enrolledAt case final at?)
          MetaItem(icon: AppIcons.date, label: l10n.studentJoinedOn(DatesIst.date(at))),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProgressBar(value: (enrollment.progress / 100).clamp(0, 1).toDouble()),
          if (onPause != null || onRemove != null) ...[
            const SizedBox(height: Space.s3),
            Wrap(
              spacing: Space.s2,
              runSpacing: Space.s2,
              children: [
                if (onPause != null)
                  AppButton(
                    label: paused ? l10n.studentResumeAction : l10n.studentPauseAction,
                    variant: AppButtonVariant.secondary,
                    busy: busy,
                    onPressed: onPause,
                  ),
                if (onRemove != null)
                  AppButton(
                    label: l10n.studentRemoveAction,
                    variant: AppButtonVariant.destructiveOutline,
                    busy: busy,
                    onPressed: onRemove,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
