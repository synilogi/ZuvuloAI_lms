import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/course.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_courses_controller.dart';
import '../widgets/course_parts.dart';

/// `/staff/courses/:courseId/curriculum` — the chapters and lessons as the academy arranged them,
/// with how far the enrolled learners have got. The order, the statuses and every rate are the
/// server's; curriculum is edited on the web (§26).
class CourseCurriculumScreen extends ConsumerWidget {
  const CourseCurriculumScreen({required this.courseId, super.key});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;
    final course = ref.watch(staffCourseProvider(courseId));
    final stats = ref.watch(curriculumStatsProvider(courseId));

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(staffCourseProvider(courseId))
          ..invalidate(curriculumStatsProvider(courseId));
        await ref.read(staffCourseProvider(courseId).future);
      },
      child: AsyncView<Course>(
        value: course,
        onRetry: () => ref.invalidate(staffCourseProvider(courseId)),
        notFound: NotFoundView(onBack: () => GoRouter.of(context).go(AppRoutes.staffCourses)),
        data: (course) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
          children: [
            Semantics(header: true, child: Text(course.title, style: context.type.titleM)),
            const SizedBox(height: Space.s1),
            Wrap(
              spacing: Space.s3,
              runSpacing: Space.s1,
              children: [
                MetaItem(
                  icon: AppIcons.list,
                  label: context.l10n.staffCourseCurriculumFacts(
                    course.chapters.length,
                    course.lessons.length,
                  ),
                ),
                if (course.durationMin > 0)
                  MetaItem(
                    icon: AppIcons.duration,
                    label: AppDurations.minutes(context.l10n, course.durationMin),
                  ),
              ],
            ),
            const SizedBox(height: Space.s4),
            if (course.chapters.isEmpty)
              EmptyState(
                title: context.l10n.staffCourseCurriculumTitle,
                message: context.l10n.staffCourseCurriculumEmpty,
              )
            else
              for (final chapter in course.chapters) ...[
                CurriculumChapterCard(
                  chapter: chapter,
                  // The figures arrive after the outline; until then the outline stands alone.
                  stat: stats.value?.chapters[chapter.id],
                  stats: stats.value ?? const CurriculumStats(),
                  onOpenLesson: (lesson) =>
                      GoRouter.of(context).go(AppRoutes.staffLesson(course.id, lesson.id)),
                ),
                const SizedBox(height: Space.s3),
              ],
          ],
        ),
      ),
    );
  }
}
