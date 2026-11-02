import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/format/money.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/learning.dart';
import '../../../../shared/domain/progress.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../course_purchase/course_purchase.dart' show CoursePurchaseBar;
import '../../../public_catalog/public_catalog.dart';
import '../../application/course_overview_controller.dart';
import '../widgets/lesson_parts.dart';

/// `/learn/:courseId` — the learner's view of one course. Before enrolling it is the overview:
/// what the course is, what it covers, who teaches it, and the two things to do — Enrol and Save.
/// Once enrolled, FLUTTER-011 takes over the body; until then the same page shows progress.
class CourseOverviewScreen extends ConsumerWidget {
  const CourseOverviewScreen({required this.courseId, super.key});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(learnerCourseProvider(courseId));
    return AsyncView<LearnerCourseDetail>(
      value: detail,
      onRetry: () => ref.invalidate(learnerCourseProvider(courseId)),
      skeleton: const DelayedLoading(skeleton: SkeletonDetail(showMedia: true)),
      notFound: NotFoundView(onBack: () => GoRouter.of(context).go(AppRoutes.explore)),
      data: (value) => _Overview(courseId: courseId, detail: value),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview({required this.courseId, required this.detail});

  final String courseId;
  final LearnerCourseDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final course = detail.learner.course;
    final instructors = ref.watch(catalogInstructorsProvider).value ?? const <Instructor>[];
    final teaching = instructorsOf(course, instructors);
    final actions = ref.watch(courseActionsProvider);
    final previews = [
      for (final lesson in course.lessons)
        if (lesson.isPlayablePreview) lesson,
    ];

    ref.listen(courseActionsProvider, (previous, next) {
      final failure = next.failure;
      if (failure == null || failure == previous?.failure) return;
      showAppSnackbar(context, failure.message ?? l10n.stateErrorBody, tone: SnackTone.error);
      ref.read(courseActionsProvider.notifier).clearFailure();
    });

    Widget header(String title, IconData icon, Hue hue) => Padding(
      padding: const EdgeInsets.only(top: Space.sectionGap, bottom: Space.s2),
      child: SectionHeader(title: title, icon: icon, iconColor: c.hue(hue).solid),
    );

    final learning = <Widget>[
      if (detail.enrolled && detail.learner.next != null) ...[
        header(l10n.courseNextLessonTitle, AppIcons.play, Hue.violet),
        _NextLessonCard(detail: detail),
      ],
      if (course.chapters.isNotEmpty) ...[
        header(l10n.courseCurriculumTitle, AppIcons.list, Hue.blue),
        CurriculumTree(
          chapters: outlineFor(context, detail),
          onLessonTap: (lesson) => _openLesson(context, lesson),
          cards: true,
        ),
      ],
      if (detail.enrolled && detail.assignments.isNotEmpty) ...[
        header(l10n.courseAssignmentsTitle, AppIcons.assignment, Hue.orange),
        for (final assignment in detail.assignments) ...[
          AssignmentSummaryCard(
            summary: assignment,
            onOpen: () => GoRouter.of(context).go(AppRoutes.assignment(assignment.id)),
          ),
          const SizedBox(height: Space.s3),
        ],
      ],
      if (detail.certificate case final certificate?
          when detail.enrolled && certificate.criteria.isNotEmpty) ...[
        header(l10n.courseCertificateLabel, AppIcons.certificate, Hue.gold),
        _CertificateProgress(certificate: certificate),
      ],
    ];
    final about = <Widget>[
      // What the course holds — live classes and the certificate among it.
      if (CourseIncludes.linesFor(l10n, course).isNotEmpty) ...[
        header(l10n.courseIncludesTitle, AppIcons.success, Hue.green),
        _Features(course: course, enrolled: detail.enrolled),
      ],
      // Before enrolling, the lessons the academy opens to everyone, to try the course on.
      if (!detail.enrolled && previews.isNotEmpty) ...[
        header(l10n.courseFreePreviewsTitle, AppIcons.play, Hue.pink),
        for (final lesson in previews) ...[
          _PreviewCard(
            lesson: lesson,
            onOpen: () => GoRouter.of(context).go(AppRoutes.catalogPreview(course.slug, lesson.id)),
          ),
          const SizedBox(height: Space.s3),
        ],
      ],
      if (course.description.isNotEmpty) ...[
        header(l10n.courseAboutTitle, AppIcons.info, Hue.violet),
        Text(course.description, style: type.bodyM),
      ],
      if (course.outcomes.isNotEmpty) ...[
        header(l10n.courseOutcomesTitle, AppIcons.check, Hue.green),
        for (final outcome in course.outcomes)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(AppIcons.check, size: IconSizes.sm, color: c.hue(Hue.green).solid),
                const SizedBox(width: Space.s2),
                Expanded(child: Text(outcome, style: type.bodyM)),
              ],
            ),
          ),
      ],
    ];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: Space.s6),
            children: [
              _Hero(
                detail: detail,
                previews: previews.length,
                // Before enrolling, saving it for later sits by the title; the price and Enrol
                // are in the bar at the bottom.
                save: detail.enrolled
                    ? null
                    : _SaveButton(courseId: courseId, detail: detail, actions: actions),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Enrolled, the page is for learning: where to carry on, the outline and what
                    // is due come first, and what the course is about follows. Before enrolling
                    // it is the other way round — what it is, then what it covers.
                    if (detail.enrolled) ...[...learning, ...about] else ...[...about, ...learning],
                    if (teaching.isNotEmpty) ...[
                      header(l10n.courseInstructorsTitle, AppIcons.instructor, Hue.blue),
                      for (final instructor in teaching) InstructorRow(instructor: instructor),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!detail.enrolled) _EnrolBar(courseId: courseId, detail: detail, actions: actions),
      ],
    );
  }

  /// An enrolled learner opens the lesson itself. Before enrolling only a free preview opens, and
  /// it opens the public preview screen — the learner lesson route would be refused by the server.
  void _openLesson(BuildContext context, CurriculumLessonNode lesson) {
    final course = detail.learner.course;
    if (detail.enrolled) {
      GoRouter.of(context).go(AppRoutes.learnLesson(course.id, lesson.id));
      return;
    }
    final preview = course.lessons.where((l) => l.id == lesson.id).firstOrNull;
    if (preview != null && preview.isPlayablePreview) {
      GoRouter.of(context).go(AppRoutes.catalogPreview(course.slug, lesson.id));
      return;
    }
    showAppSnackbar(context, context.l10n.courseEnrolToUnlock);
  }
}

/// The top of the page, on a tinted band: the cover, the level beside how the course runs, the
/// title, the course's own figures — then, enrolled, how far the learner is; before enrolling, how
/// much of it is free to try.
class _Hero extends StatelessWidget {
  const _Hero({required this.detail, required this.previews, this.save});

  final LearnerCourseDetail detail;
  final int previews;
  final Widget? save;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final course = detail.learner.course;
    final level = detail.learner.levelTitle;
    final soft = c.hue(Hue.violet).soft;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [soft, soft.withValues(alpha: 0)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.s4, Space.s4, Space.s4, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.xl),
                boxShadow: dark ? null : context.shadows.e2,
              ),
              child: CourseCover(
                motif: CoverMotif.parse(course.coverMotif),
                imageUrl: course.coverImageUrl,
                semanticLabel: course.title,
                radius: Radii.xl,
              ),
            ),
            const SizedBox(height: Space.s4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    level,
                    style: type.bodyS.copyWith(
                      color: c.hue(Hue.orange).ink,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Space.s2),
                OutlinePill(label: courseFormatLabel(l10n, course.format)),
              ],
            ),
            const SizedBox(height: Space.s1),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Semantics(header: true, child: Text(course.title, style: type.displayM)),
                ),
                if (save != null) ...[const SizedBox(width: Space.s2), save!],
              ],
            ),
            if (course.subtitle.isNotEmpty) ...[
              const SizedBox(height: Space.s1),
              Text(course.subtitle, style: type.bodyM.copyWith(color: c.muted)),
            ],
            const SizedBox(height: Space.s4),
            _Stats(course: course),
            if (course.language.isNotEmpty) ...[
              const SizedBox(height: Space.s3),
              InfoChips(items: [(AppIcons.language, course.language)]),
            ],
            if (detail.enrolled) ...[
              const SizedBox(height: Space.s4),
              _EnrolledSummary(learner: detail.learner),
            ] else if (previews > 0) ...[
              const SizedBox(height: Space.s4),
              _PreviewPill(label: l10n.courseIncludesPreviews(previews)),
            ],
          ],
        ),
      ),
    );
  }
}

/// The course's own figures as three coloured tiles: how many lessons, how long they take, and
/// over how many weeks. A figure the course does not have is left out.
class _Stats extends StatelessWidget {
  const _Stats({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final weeks = course.estimatedWeeks ?? 0;
    final tiles = [
      _StatTile(
        hue: Hue.violet,
        icon: AppIcons.lessonReading,
        value: formatCount(course.lessons.length),
        label: l10n.courseLessonsLabel,
      ),
      if (course.durationMin > 0)
        _StatTile(
          hue: Hue.blue,
          icon: AppIcons.duration,
          value: AppDurations.minutes(l10n, course.durationMin),
          label: l10n.courseDurationLabel,
        ),
      if (weeks > 0)
        _StatTile(
          hue: Hue.green,
          icon: AppIcons.date,
          value: l10n.courseWeeks(weeks),
          label: l10n.courseScheduleLabel,
        ),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: Space.s2),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.hue,
    required this.icon,
    required this.value,
    required this.label,
  });

  final Hue hue;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final h = context.colors.hue(hue);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: h.soft, borderRadius: BorderRadius.circular(Radii.lg)),
        child: Padding(
          padding: const EdgeInsets.all(Space.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(icon, size: IconSizes.md, color: h.solid),
              const SizedBox(height: Space.s2),
              Text(value, style: context.type.titleS.copyWith(color: h.ink)),
              Text(label, style: context.type.caption.copyWith(color: context.colors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// "1 lesson free to preview" as a soft pill under the figures — the course says how much of it
/// anyone may try before enrolling.
class _PreviewPill extends StatelessWidget {
  const _PreviewPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final h = context.colors.hue(Hue.blue);
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(color: h.soft, borderRadius: BorderRadius.circular(Radii.pill)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: Space.s2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(AppIcons.play, size: IconSizes.sm, color: h.solid),
              const SizedBox(width: Space.s2),
              Flexible(
                child: Text(
                  label,
                  style: context.type.bodyS.copyWith(color: h.ink, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the course holds, one line each on a coloured tile — counted from its own outline.
class _Features extends StatelessWidget {
  const _Features({required this.course, required this.enrolled});

  final Course course;

  /// An enrolled learner holds every lesson: how many are free to preview says nothing to them.
  final bool enrolled;

  /// Each kind of content keeps its hue across the app (a video is blue on Home too).
  static Hue _hueOf(IconData icon) => switch (icon) {
    AppIcons.lessonVideo => Hue.blue,
    AppIcons.lessonReading => Hue.violet,
    AppIcons.filePdf => Hue.orange,
    AppIcons.quiz => Hue.pink,
    AppIcons.assignment => Hue.gold,
    AppIcons.live => Hue.blue,
    AppIcons.play => Hue.green,
    AppIcons.certificate => Hue.gold,
    _ => Hue.violet,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lines = [
      for (final line in CourseIncludes.linesFor(context.l10n, course))
        if (!enrolled || line.$1 != AppIcons.play) line,
    ];
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s1),
      child: Column(
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const AppDivider(indent: Sizes.iconTile + Space.s3),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.s3 - 2),
              child: Row(
                children: [
                  Container(
                    width: Sizes.iconTile,
                    height: Sizes.iconTile,
                    decoration: BoxDecoration(
                      color: c.hue(_hueOf(lines[i].$1)).soft,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    alignment: Alignment.center,
                    child: AppIcon(
                      lines[i].$1,
                      size: IconSizes.md,
                      color: c.hue(_hueOf(lines[i].$1)).solid,
                    ),
                  ),
                  const SizedBox(width: Space.s3),
                  Expanded(child: Text(lines[i].$2, style: context.type.bodyM)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One lesson anyone may open before enrolling: its kind, title and length, and the way in.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.lesson, required this.onOpen});

  final Lesson lesson;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = LessonType.parse(lesson.type);
    final h = c.hue(lessonHue(type));
    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(Space.s3),
      semanticLabel: '${lessonTypeLabel(l10n, type)}. ${lesson.title}. ${l10n.actionPreviewLesson}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: AvatarSizes.lg,
                height: AvatarSizes.lg,
                decoration: BoxDecoration(
                  color: h.soft,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                alignment: Alignment.center,
                child: LessonTypeIcon(type, size: IconSizes.xl, color: h.solid),
              ),
              const SizedBox(width: Space.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lessonTypeLabel(l10n, type).toUpperCase(),
                      style: context.type.micro.copyWith(
                        color: h.ink,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lesson.title,
                      style: context.type.titleS,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lesson.durationMin > 0)
                      Text(
                        AppDurations.minutes(l10n, lesson.durationMin),
                        style: context.type.caption.copyWith(color: c.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s3),
          // Drawn, not a second button: the card is the one tap target.
          Container(
            constraints: const BoxConstraints(minHeight: Sizes.buttonSm + Space.s1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(AppIcons.play, size: IconSizes.sm, color: c.text),
                const SizedBox(width: Space.s2),
                Text(
                  l10n.actionPreviewLesson,
                  style: context.type.bodyS.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The outline: once enrolled the server's own lesson states, and before that everything locked
/// except the free previews it already opened. A lesson the server locked for an enrolled learner
/// says why in the server's own terms (`apps/api/src/lib/learning.ts`, `lockedReason`): the
/// chapter before is unfinished, or a chapter's quiz waits on its other lessons.
List<CurriculumChapterNode> outlineFor(BuildContext context, LearnerCourseDetail detail) {
  final l10n = context.l10n;
  final snapshot = detail.learner.snapshot;
  final chapters = detail.learner.course.chapters;
  String lockedReason(int chapterIndex, Lesson lesson) {
    if (!detail.enrolled) return l10n.courseEnrolToUnlock;
    final previous = chapterIndex > 0 ? chapters[chapterIndex - 1] : null;
    final previousOpen =
        previous == null ||
        previous.lessons
            .where((l) => l.status == ContentStatus.published && l.type != 'assignment')
            .every((l) => snapshot.stateOf(l.id) == ProgressState.completed);
    if (!previousOpen) return l10n.courseLockedChapter(previous.title);
    if (lesson.type == 'assessment') return l10n.courseLockedQuiz(chapters[chapterIndex].title);
    return l10n.courseLockedInOrder;
  }

  return [
    for (var ci = 0; ci < chapters.length; ci++)
      CurriculumChapterNode(
        id: chapters[ci].id,
        title: chapters[ci].title,
        lessons: [
          for (var li = 0; li < chapters[ci].lessons.length; li++)
            () {
              final lesson = chapters[ci].lessons[li];
              final state = detail.enrolled
                  ? switch (snapshot.stateOf(lesson.id)) {
                      ProgressState.completed => LessonNodeState.completed,
                      ProgressState.inProgress => LessonNodeState.inProgress,
                      ProgressState.locked => LessonNodeState.locked,
                      _ => LessonNodeState.available,
                    }
                  : lesson.isPlayablePreview
                  ? LessonNodeState.available
                  : LessonNodeState.locked;
              return CurriculumLessonNode(
                id: lesson.id,
                title: lesson.title,
                type: LessonType.parse(lesson.type),
                state: state,
                numberLabel: '${ci + 1}.${li + 1}',
                durationLabel: lesson.durationMin > 0
                    ? AppDurations.minutes(l10n, lesson.durationMin)
                    : null,
                lockedReason: state == LessonNodeState.locked ? lockedReason(ci, lesson) : null,
                isCurrent: detail.learner.next?.id == lesson.id,
              );
            }(),
        ],
      ),
  ];
}

/// What an enrolled learner sees instead of a price: how far they are, and what is left.
class _EnrolledSummary extends StatelessWidget {
  const _EnrolledSummary({required this.learner});

  final LearnerCourse learner;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return AppCard(
      child: Row(
        children: [
          ProgressRing(value: learner.progress.fraction, size: 44),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.curriculumProgress(learner.progress.completed, learner.progress.total),
                  style: context.type.titleS,
                ),
                if (learner.progress.remainingMin > 0)
                  Text(
                    l10n.courseRemaining(AppDurations.minutes(l10n, learner.progress.remainingMin)),
                    style: context.type.caption.copyWith(color: c.muted),
                  ),
              ],
            ),
          ),
          const StatusBadge(StatusKind.enrolled),
        ],
      ),
    );
  }
}

/// The price and the way in, kept at the bottom while the page scrolls — by how the course is
/// joined: Enrol for a free course, the purchase bar for a paid one, and a plain line for one the
/// academy has not opened yet. Enrol is disabled offline, with the reason said out loud (§17).
class _EnrolBar extends ConsumerWidget {
  const _EnrolBar({required this.courseId, required this.detail, required this.actions});

  final String courseId;
  final LearnerCourseDetail detail;
  final CourseActionState actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final course = detail.learner.course;
    final offline = ref.watch(isOnlineProvider).value == false;

    switch (course.sale) {
      case PaidCourseSale(:final price):
        return CoursePurchaseBar(course: course, price: price);
      case UnavailableCourseSale():
        return StickyActionBar(
          primary: Text(
            l10n.courseSaleUnavailable,
            style: context.type.bodyM.copyWith(color: context.colors.muted),
            textAlign: TextAlign.center,
          ),
        );
      case FreeCourseSale():
        return StickyActionBar(
          leading: PriceTag(course: course),
          primary: AppButton(
            label: l10n.actionEnrol,
            size: AppButtonSize.lg,
            busy: actions.enrolling,
            onPressed: offline ? null : () => _enrol(context, ref),
          ),
        );
    }
  }

  Future<void> _enrol(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    // The confirmation says what enrolling does, not how long access lasts — only the server
    // knows that, and it says so in the enrolment it returns.
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.enrolConfirmTitle,
      message: l10n.enrolConfirmBody,
      confirmLabel: l10n.actionEnrol,
    );
    if (!confirmed || !context.mounted) return;

    final done = await ref.read(courseActionsProvider.notifier).enroll(courseId);
    if (!done || !context.mounted) return;

    final enrolment = ref.read(learnerCourseProvider(courseId)).value?.learner.enrollment;
    final expires = enrolment?.expiresAt;
    showAppSnackbar(
      context,
      expires == null
          ? l10n.enrolDoneMessage
          : '${l10n.enrolDoneMessage} ${l10n.enrolAccessEnds(DatesIst.date(expires))}',
      tone: SnackTone.success,
    );
  }
}

/// Saving the course for later. It moves at once and goes back if the academy refuses; disabled
/// offline (§17).
class _SaveButton extends ConsumerWidget {
  const _SaveButton({required this.courseId, required this.detail, required this.actions});

  final String courseId;
  final LearnerCourseDetail detail;
  final CourseActionState actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final offline = ref.watch(isOnlineProvider).value == false;
    final saved = actions.savedFor(detail);
    return AppIconButton(
      icon: saved ? AppIcons.bookmarked : AppIcons.bookmark,
      label: saved ? l10n.actionUnsaveCourse : l10n.actionSaveCourse,
      onPressed: offline || actions.busy
          ? null
          : () => ref.read(courseActionsProvider.notifier).toggleSaved(courseId),
    );
  }
}

/// Where the learner carries on: the lesson the **server** named as next.
class _NextLessonCard extends StatelessWidget {
  const _NextLessonCard({required this.detail});

  final LearnerCourseDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final next = detail.learner.next!;
    final type = LessonType.parse(next.type);
    final h = c.hue(lessonHue(type));
    void open() =>
        GoRouter.of(context).go(AppRoutes.learnLesson(detail.learner.course.id, next.id));
    final started = detail.learner.progress.completed > 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: AvatarSizes.lg - Space.s1,
                height: AvatarSizes.lg - Space.s1,
                decoration: BoxDecoration(
                  color: h.soft,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                alignment: Alignment.center,
                child: LessonTypeIcon(type, size: IconSizes.lg, color: h.solid),
              ),
              const SizedBox(width: Space.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(next.title, style: context.type.titleS),
                    const SizedBox(height: Space.s1),
                    Text(
                      '${next.lessonNumber} \u00b7 ${AppDurations.minutes(l10n, next.durationMin)}',
                      style: context.type.caption.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s4),
          // The page's one primary action: pick up where the academy says the learner is.
          AppButton(
            label: started ? l10n.actionResume : l10n.actionStart,
            icon: AppIcons.play,
            expand: true,
            onPressed: open,
          ),
        ],
      ),
    );
  }
}

/// How close the certificate is, criterion by criterion, exactly as the academy counts them.
class _CertificateProgress extends StatelessWidget {
  const _CertificateProgress({required this.certificate});

  final CertificateRecord certificate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(certificate.title, style: context.type.titleS),
          const SizedBox(height: Space.s3),
          for (final criterion in certificate.criteria) ...[
            Row(
              children: [
                AppIcon(
                  criterion.met ? AppIcons.check : AppIcons.time,
                  size: IconSizes.sm,
                  color: criterion.met ? c.hue(Hue.green).solid : c.muted,
                ),
                const SizedBox(width: Space.s2),
                Expanded(child: Text(criterion.label, style: context.type.bodyS)),
                Text(
                  '${_number(criterion.current)}/${_number(criterion.needed)}'
                  '${criterion.unit ?? ''}',
                  style: context.type.caption.copyWith(color: c.muted),
                ),
              ],
            ),
            const SizedBox(height: Space.s2),
            ProgressBar(value: criterion.fraction, height: 4),
            const SizedBox(height: Space.s3),
          ],
        ],
      ),
    );
  }

  static String _number(double value) =>
      value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);
}
