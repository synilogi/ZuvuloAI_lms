import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/format/money.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/level.dart';
import '../../../../shared/domain/user_profile.dart';
import '../../../../shared/session/current_user.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/catalog_providers.dart';
import '../widgets/course_card.dart';
import '../widgets/course_store_parts.dart';
import '../widgets/instructor_row.dart';

/// `/catalog/:slug` — the public course page: what the course is, what it covers, who teaches it,
/// and the one way in. Lesson bodies arrive only for published free previews.
class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(catalogCourseProvider(slug));
    return UpPopScope(
      fallback: AppRoutes.catalog,
      child: Scaffold(
        appBar: CommonAppBar(leading: upButton(context, fallback: AppRoutes.catalog)),
        body: AsyncView<Course>(
          value: course,
          onRetry: () => ref.invalidate(catalogCourseProvider(slug)),
          skeleton: const DelayedLoading(skeleton: SkeletonDetail(showMedia: true)),
          notFound: NotFoundView(onBack: () => GoRouter.of(context).go(AppRoutes.catalog)),
          data: (value) => _CourseBody(course: value),
        ),
        // The price and the way in stay at the bottom while the page scrolls.
        bottomNavigationBar: switch (course.value) {
          final value? => _EnrolBar(course: value),
          null => null,
        },
      ),
    );
  }
}

class _CourseBody extends ConsumerWidget {
  const _CourseBody({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final levels = ref.watch(catalogLevelsProvider).value ?? const <Level>[];
    final instructors = instructorsOf(
      course,
      ref.watch(catalogInstructorsProvider).value ?? const <Instructor>[],
    );
    final levelName = levels.where((l) => l.id == course.levelId).map((l) => l.name).firstOrNull;
    // Staff have no way in to offer, so no bar: their price stays with the title.
    final profile = ref.watch(currentUserProvider);
    final hasBar = profile == null || profile.role == UserRole.student;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s6),
        children: [
          CourseCover(
            motif: CoverMotif.parse(course.coverMotif),
            imageUrl: course.coverImageUrl,
            semanticLabel: course.title,
          ),
          const SizedBox(height: Space.s4),
          Semantics(header: true, child: Text(course.title, style: type.displayM)),
          if (course.subtitle.isNotEmpty) ...[
            const SizedBox(height: Space.s2),
            Text(course.subtitle, style: type.bodyL.copyWith(color: c.muted)),
          ],
          if (!hasBar || (course.rating != null && course.ratingCount != null)) ...[
            const SizedBox(height: Space.s3),
            Row(
              children: [
                if (!hasBar)
                  Text(
                    coursePriceLabel(l10n, course),
                    style: type.titleL.copyWith(color: c.accentInk),
                  ),
                const Spacer(),
                if (course.rating != null && course.ratingCount != null)
                  CourseRating(rating: course.rating!, count: course.ratingCount!),
              ],
            ),
          ],
          if (course.previewCount > 0) ...[
            const SizedBox(height: Space.s3),
            Row(
              children: [
                const StatusBadge(StatusKind.freePreview),
                const SizedBox(width: Space.s2),
                Expanded(
                  child: Text(
                    l10n.coursePreviewNote(course.previewCount),
                    style: type.caption.copyWith(color: c.muted),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Space.sectionGap),
          FactStrip(
            facts: [
              if (levelName != null)
                Fact(icon: AppIcons.level, value: levelName, label: l10n.courseLevelLabel),
              Fact(
                icon: AppIcons.lessonReading,
                value: formatCount(course.lessons.length),
                label: l10n.courseLessonsLabel,
              ),
              if (course.durationMin > 0)
                Fact(
                  icon: AppIcons.duration,
                  value: _length(l10n, course),
                  label: l10n.courseDurationLabel,
                  tone: Tone.info,
                ),
              if (course.enrolledCount > 0)
                Fact(
                  icon: AppIcons.people,
                  value: formatCount(course.enrolledCount),
                  label: l10n.courseEnrolledLabel,
                  tone: Tone.warn,
                ),
            ],
          ),
          const SizedBox(height: Space.s3),
          InfoChips(
            items: [
              (AppIcons.format, courseFormatLabel(l10n, course.format)),
              if (course.language.isNotEmpty) (AppIcons.language, course.language),
            ],
          ),
          // What the course holds — live classes and the certificate among it.
          if (CourseIncludes.linesFor(l10n, course).isNotEmpty) ...[
            const SizedBox(height: Space.sectionGap),
            CourseIncludes(course: course),
          ],
          if (course.description.isNotEmpty) ...[
            const SizedBox(height: Space.sectionGap),
            SectionHeader(title: l10n.courseAboutTitle),
            const SizedBox(height: Space.s2),
            Text(course.description, style: type.bodyM),
          ],
          if (course.outcomes.isNotEmpty) ...[
            const SizedBox(height: Space.sectionGap),
            SectionHeader(title: l10n.courseOutcomesTitle),
            const SizedBox(height: Space.s2),
            for (final outcome in course.outcomes)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(AppIcons.check, size: IconSizes.sm, color: c.accent),
                    const SizedBox(width: Space.s2),
                    Expanded(child: Text(outcome, style: type.bodyM)),
                  ],
                ),
              ),
          ],
          if (course.chapters.isNotEmpty) ...[
            const SizedBox(height: Space.sectionGap),
            SectionHeader(title: l10n.courseCurriculumTitle),
            const SizedBox(height: Space.s2),
            CurriculumTree(
              chapters: _outline(context, course),
              onLessonTap: (lesson) =>
                  GoRouter.of(context).go(AppRoutes.catalogPreview(course.slug, lesson.id)),
            ),
          ],
          if (instructors.isNotEmpty) ...[
            const SizedBox(height: Space.sectionGap),
            SectionHeader(title: l10n.courseInstructorsTitle),
            for (final instructor in instructors) InstructorRow(instructor: instructor),
          ],
        ],
      ),
    );
  }

  /// "6h 20m · 8 weeks" — the lesson minutes the server sent, and the academy's suggested pace.
  String _length(AppLocalizations l10n, Course course) {
    final duration = AppDurations.minutes(l10n, course.durationMin);
    final weeks = course.estimatedWeeks;
    return weeks == null || weeks <= 0 ? duration : '$duration \u00b7 ${l10n.courseWeeks(weeks)}';
  }

  /// The outline a visitor sees: a published free preview is open, every other lesson is locked
  /// with the reason — the server decides which is which, the app never guesses (§18).
  List<CurriculumChapterNode> _outline(BuildContext context, Course course) {
    final l10n = context.l10n;
    return [
      for (var ci = 0; ci < course.chapters.length; ci++)
        CurriculumChapterNode(
          id: course.chapters[ci].id,
          title: course.chapters[ci].title,
          lessons: [
            for (var li = 0; li < course.chapters[ci].lessons.length; li++)
              () {
                final lesson = course.chapters[ci].lessons[li];
                final open = lesson.isPlayablePreview;
                return CurriculumLessonNode(
                  id: lesson.id,
                  title: lesson.title,
                  type: LessonType.parse(lesson.type),
                  state: open ? LessonNodeState.available : LessonNodeState.locked,
                  numberLabel: '${ci + 1}.${li + 1}',
                  durationLabel: lesson.durationMin > 0
                      ? AppDurations.minutes(l10n, lesson.durationMin)
                      : null,
                  lockedReason: open ? null : l10n.previewLockedTitle,
                );
              }(),
          ],
        ),
    ];
  }
}

/// The price and the one way in, by who is signed in: a visitor signs in first and comes back to
/// the course, a learner opens it, and staff are not enrolling in anything (no bar).
class _EnrolBar extends ConsumerWidget {
  const _EnrolBar({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(currentUserProvider);
    final learnerPath = AppRoutes.learnCourse(course.id);

    if (profile != null && profile.role != UserRole.student) return const SizedBox.shrink();
    return StickyActionBar(
      leading: PriceTag(course: course),
      primary: profile == null
          ? AppButton(
              label: l10n.actionSignInToEnrol,
              size: AppButtonSize.lg,
              onPressed: () => GoRouter.of(
                context,
              ).go(Uri(path: AppRoutes.login, queryParameters: {'next': learnerPath}).toString()),
            )
          : AppButton(
              label: l10n.actionOpenCourse,
              size: AppButtonSize.lg,
              onPressed: () => GoRouter.of(context).go(learnerPath),
            ),
    );
  }
}
