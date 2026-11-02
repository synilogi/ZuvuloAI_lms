import 'package:flutter/material.dart';

import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/figures.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_instructors_controller.dart';

/// How an instructor's standing with the academy is drawn.
StatusKind instructorStatusKind(InstructorStatus status) => switch (status) {
  InstructorStatus.active => StatusKind.active,
  InstructorStatus.invited => StatusKind.invited,
  InstructorStatus.inactive || InstructorStatus.unknown => StatusKind.inactive,
};

/// The hue a section's mark is drawn in, by what the section is about — as the navigation draws
/// the same kinds (people green, courses blue, review orange, live pink, reports violet).
Color sectionHue(BuildContext context, IconData kind) =>
    context.colors.hue(AppNavIcons.of(kind).hue).solid;

/// One instructor in the directory: who they are and where they stand, then what they teach and
/// what is waiting for them — each fact on its own small icon.
class InstructorCard extends StatelessWidget {
  const InstructorCard({required this.row, required this.onOpen, super.key});

  final InstructorRow row;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final instructor = row.instructor;

    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarInitials(name: instructor.name, size: AvatarSizes.md),
              const SizedBox(width: Space.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(instructor.name, style: context.type.titleS),
                    if (instructor.title.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(instructor.title, style: context.type.bodyS.copyWith(color: c.muted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Space.s2),
              StatusBadge(instructorStatusKind(instructor.status)),
            ],
          ),
          const SizedBox(height: Space.s3),
          Wrap(
            spacing: Space.s4,
            runSpacing: Space.s1 + 2,
            children: [
              MetaItem(
                icon: AppIcons.courses,
                label: l10n.instructorsCourseCount(row.courses.length),
              ),
              MetaItem(icon: AppIcons.people, label: l10n.instructorsLearnerCount(row.students)),
              MetaItem(
                icon: AppIcons.rating,
                label: row.rating == null
                    ? l10n.instructorsNotRated
                    : l10n.instructorsRating(formatFigure(row.rating!), row.ratingCount),
              ),
              if (row.completion case final completion?)
                MetaItem(icon: AppIcons.success, label: l10n.instructorsCompletion(completion)),
            ],
          ),
          if (instructor.expertise.isNotEmpty) ...[
            const SizedBox(height: Space.s3),
            TagRow(tags: instructor.expertise),
          ],
          if (row.toReview > 0) ...[
            const SizedBox(height: Space.s3),
            Wrap(
              spacing: Space.s2,
              runSpacing: Space.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusBadge(
                  StatusKind.toReview,
                  labelOverride: l10n.instructorsToReview(row.toReview),
                ),
                if (row.overdue > 0)
                  StatusBadge(
                    StatusKind.overdueReview,
                    labelOverride: l10n.instructorsOverdue(row.overdue),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A row of small tags, for expertise and languages.
class TagRow extends StatelessWidget {
  const TagRow({required this.tags, super.key, this.onRemove});

  final List<String> tags;

  /// When given, each tag can be taken off again — the form uses this.
  final void Function(String tag)? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: Space.s2,
      runSpacing: Space.s2,
      children: [
        for (final tag in tags)
          if (onRemove == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: Space.s1),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Text(tag, style: context.type.caption),
            )
          else
            InputChip(
              label: Text(tag),
              onDeleted: () => onRemove!(tag),
              deleteIcon: const Icon(AppIcons.close, size: 16),
            ),
      ],
    );
  }
}

/// One course in an instructor's portfolio, drawn as the course lists draw one: a strip in the
/// courses hue with their part in it and the course's status, then its title and how it is doing.
class InstructorCourseCard extends StatelessWidget {
  const InstructorCourseCard({required this.course, required this.onOpen, super.key});

  final InstructorCourse course;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return StripCard(
      onTap: onOpen,
      strip: context.colors.hue(AppNavIcons.of(AppIcons.courses).hue),
      stripIcon: AppIcons.courses,
      stripLabel: [
        course.isLead ? l10n.instructorRoleLead : l10n.instructorRoleCo,
        course.levelTitle,
      ].where((part) => part.isNotEmpty).join(' · '),
      badge: StatusBadge(courseStatusKindOf(course.status)),
      title: course.title,
      facts: [
        MetaItem(icon: AppIcons.people, label: l10n.instructorCourseEnrolled(course.enrolled)),
        MetaItem(icon: AppIcons.rocket, label: l10n.instructorCourseActive(course.activeLearners)),
        MetaItem(icon: AppIcons.learning, label: l10n.instructorCourseLessons(course.lessons)),
        if (course.completion case final completion?)
          MetaItem(icon: AppIcons.success, label: l10n.instructorsCompletion(completion)),
        if (course.rating case final rating?)
          MetaItem(
            icon: AppIcons.rating,
            label: l10n.instructorsRating(formatFigure(rating), course.ratingCount ?? 0),
          ),
      ],
    );
  }
}

/// The course statuses an instructor's portfolio can hold, drawn as the rest of the app draws them.
StatusKind courseStatusKindOf(CourseStatus status) => switch (status) {
  CourseStatus.draft || CourseStatus.unknown => StatusKind.draft,
  CourseStatus.published => StatusKind.published,
  CourseStatus.archived => StatusKind.archived,
};

/// Enrolments month by month, as the academy labelled them.
class EnrolmentMonths extends StatelessWidget {
  const EnrolmentMonths({required this.months, super.key});

  final List<MonthCount> months;

  @override
  Widget build(BuildContext context) => ColumnChart(
    title: context.l10n.instructorEnrolmentsTitle,
    points: [
      for (final month in months)
        ChartPoint(month.label, month.value.toDouble(), '${month.detail}: ${month.value}'),
    ],
  );
}

/// The instructor's own work, newest first — the academy's own sentences.
class InstructorActivityList extends StatelessWidget {
  const InstructorActivityList({required this.events, super.key});

  final List<AdminEvent> events;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GroupedList(
      children: [
        for (final event in events)
          AppListTile(
            title: '${event.actor} ${event.summary}',
            subtitle: [?event.context, DatesIst.dateTime(context.l10n, event.at)].join(' · '),
            leading: AppIcon(AppIcons.list, size: IconSizes.md, color: c.muted),
          ),
      ],
    );
  }
}
