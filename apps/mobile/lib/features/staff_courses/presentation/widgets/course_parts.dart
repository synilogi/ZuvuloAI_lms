import 'package:flutter/material.dart';

import '../../../../core/format/durations.dart';
import '../../../../core/format/figures.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/course.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_courses_controller.dart';

/// The badge for a course's own status, as the academy set it.
StatusKind courseStatusKind(CourseStatus status) => switch (status) {
  CourseStatus.draft || CourseStatus.unknown => StatusKind.draft,
  CourseStatus.published => StatusKind.published,
  CourseStatus.archived => StatusKind.archived,
};

StatusKind contentStatusKind(ContentStatus status) =>
    status == ContentStatus.published ? StatusKind.published : StatusKind.draft;

String visibilityLabel(AppLocalizations l10n, CourseVisibility visibility) => switch (visibility) {
  CourseVisibility.public || CourseVisibility.unknown => l10n.staffCourseVisibilityPublic,
  CourseVisibility.unlisted => l10n.staffCourseVisibilityUnlisted,
  CourseVisibility.private => l10n.staffCourseVisibilityPrivate,
};

/// The width of a course's square cover in a list row — the learner's course row uses the same.
const double courseThumbSize = AvatarSizes.xl + Space.s4;

/// One course in the staff list, drawn like a learner's course row: the cover, the title and
/// subtitle, where it stands, and how big it is — every figure the server's.
class StaffCourseCard extends StatelessWidget {
  const StaffCourseCard({required this.course, required this.onOpen, super.key});

  final Course course;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;

    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(Space.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: courseThumbSize,
            child: CourseCover(
              motif: CoverMotif.parse(course.coverMotif),
              imageUrl: course.coverImageUrl,
              semanticLabel: l10n.courseCoverLabel,
              aspectRatio: 1,
            ),
          ),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, Space.s1, Space.s2, Space.s1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusBadge(courseStatusKind(course.status)),
                  const SizedBox(height: Space.s2),
                  Text(
                    course.title,
                    style: type.titleS,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (course.subtitle.isNotEmpty) ...[
                    const SizedBox(height: Space.s1),
                    Text(
                      course.subtitle,
                      style: type.bodyS.copyWith(color: c.muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: Space.s2),
                  Wrap(
                    spacing: Space.s3,
                    runSpacing: Space.s1,
                    children: [
                      MetaItem(
                        icon: AppIcons.people,
                        label: l10n.staffCourseLearners(course.enrolledCount),
                      ),
                      MetaItem(
                        icon: AppIcons.lessonReading,
                        label: l10n.staffCourseLessons(course.lessons.length),
                      ),
                      if (course.durationMin > 0)
                        MetaItem(
                          icon: AppIcons.duration,
                          label: AppDurations.minutes(l10n, course.durationMin),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The academy's own publish checklist, exactly as a refused publish sent it: every line, met or
/// not, in the academy's words. The app decides nothing about readiness (§18).
class PublishChecklistView extends StatelessWidget {
  const PublishChecklistView({required this.checklist, super.key});

  final List<PublishCheck> checklist;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.staffCourseChecklistBody, style: context.type.bodyM.copyWith(color: c.muted)),
        const SizedBox(height: Space.s3),
        for (final check in checklist)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s2),
            child: Semantics(
              label:
                  '${check.label}, '
                  '${check.met ? l10n.staffCourseChecklistMet : l10n.staffCourseChecklistUnmet}',
              child: ExcludeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(
                      check.met ? AppIcons.check : AppIcons.close,
                      size: IconSizes.sm,
                      color: check.met ? c.accentInk : c.dangerInk,
                    ),
                    const SizedBox(width: Space.s2),
                    Expanded(child: Text(check.label, style: context.type.bodyM)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Shows the checklist the academy answered a refused publish with.
Future<void> showPublishChecklist(BuildContext context, List<PublishCheck> checklist) {
  final l10n = context.l10n;
  return showDialog<void>(
    context: context,
    barrierColor: context.colors.scrim,
    builder: (_) => AlertDialog(
      title: Text(l10n.staffCourseChecklistTitle),
      content: SingleChildScrollView(child: PublishChecklistView(checklist: checklist)),
      actions: [
        AppButton(
          label: l10n.actionClose,
          variant: AppButtonVariant.tertiary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

/// One chapter of the curriculum as staff read it: its lessons, and how far the enrolled learners
/// have got with each — the server's figures, never the app's.
class CurriculumChapterCard extends StatelessWidget {
  const CurriculumChapterCard({
    required this.chapter,
    required this.stat,
    required this.stats,
    required this.onOpenLesson,
    super.key,
  });

  final Chapter chapter;
  final ChapterProgressStat? stat;
  final CurriculumStats stats;
  final void Function(Lesson lesson) onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final progress = stat;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s4, Space.s4, Space.s4, Space.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HueTile(icon: AppIcons.list, hue: Hue.blue),
                    const SizedBox(width: Space.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(chapter.title, style: context.type.titleS),
                          ),
                          const SizedBox(height: Space.s1),
                          MetaItem(
                            icon: AppIcons.lessonReading,
                            label: l10n.staffCourseChapterLessons(chapter.lessons.length),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Space.s2),
                    StatusBadge(contentStatusKind(chapter.status)),
                  ],
                ),
                if (progress != null) ...[
                  const SizedBox(height: Space.s3),
                  Text(
                    l10n.staffCourseChapterProgress(
                      formatFigure(progress.startedRate),
                      formatFigure(progress.completionRate),
                    ),
                    style: context.type.caption.copyWith(color: c.muted),
                  ),
                  const SizedBox(height: Space.s2),
                  ProgressBar(value: (progress.completionRate / 100).clamp(0, 1).toDouble()),
                ],
              ],
            ),
          ),
          if (chapter.lessons.isNotEmpty) const AppDivider(),
          for (final lesson in chapter.lessons)
            AppListTile(
              title: lesson.title,
              subtitle: [
                lessonTypeLabel(l10n, LessonType.parse(lesson.type)),
                if (lesson.durationMin > 0) AppDurations.minutes(l10n, lesson.durationMin),
              ].join(' · '),
              meta: stats.enrolled == 0
                  ? null
                  : l10n.staffCourseLessonCompleted(formatFigure(stats.lessonPercent(lesson.id))),
              leading: LessonTypeIcon(LessonType.parse(lesson.type)),
              trailing: Wrap(
                spacing: Space.s1,
                children: [
                  if (lesson.isPreview) const StatusBadge(StatusKind.freePreview),
                  if (lesson.status != ContentStatus.published)
                    StatusBadge(contentStatusKind(lesson.status)),
                ],
              ),
              showChevron: true,
              onTap: () => onOpenLesson(lesson),
            ),
        ],
      ),
    );
  }
}
