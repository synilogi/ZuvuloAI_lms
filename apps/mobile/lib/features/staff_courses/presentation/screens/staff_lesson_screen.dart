import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/format/figures.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/platform/external_link.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/course.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/auth.dart';
import '../../../course_learning/course_learning.dart';
import '../../../media/media.dart';
import '../../application/staff_courses_controller.dart';
import '../widgets/course_parts.dart';
import 'staff_course_screen.dart';

/// `/staff/courses/:courseId/lessons/:lessonId` — the lesson as staff read it: what it holds and
/// where it sits. Read-only; a lesson is written on the web (§26). The route strips a quiz's and
/// an assignment's ids from the mirrored content, so no answer key can reach this screen.
class StaffLessonScreen extends ConsumerWidget {
  const StaffLessonScreen({required this.courseId, required this.lessonId, super.key});

  final String courseId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (courseId: courseId, lessonId: lessonId);
    return AsyncView<StaffLessonDetail>(
      value: ref.watch(staffLessonProvider(key)),
      onRetry: () => ref.invalidate(staffLessonProvider(key)),
      skeleton: const DelayedLoading(skeleton: SkeletonDetail()),
      notFound: NotFoundView(
        onBack: () => GoRouter.of(context).go(AppRoutes.staffCurriculum(courseId)),
      ),
      data: (detail) => _Lesson(courseId: courseId, detail: detail),
    );
  }
}

class _Lesson extends ConsumerWidget {
  const _Lesson({required this.courseId, required this.detail});

  final String courseId;
  final StaffLessonDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final lesson = detail.lesson;
    final type = LessonType.parse(lesson.type);
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;
    final stats = ref.watch(curriculumStatsProvider(courseId)).value;
    final role = ref.watch(currentUserProvider)?.role ?? UserRole.unknown;
    final webBase = ref.watch(appConfigProvider).webBaseUrl;

    void openLesson(String id) => GoRouter.of(context).go(AppRoutes.staffLesson(courseId, id));

    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HueTile(icon: lessonTypeIcon(type), hue: lessonHue(type)),
                  const SizedBox(width: Space.s3),
                  Expanded(
                    child: Text(
                      detail.chapterTitle,
                      style: context.type.caption.copyWith(color: c.muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: Space.s2),
                  StatusBadge(contentStatusKind(lesson.status)),
                ],
              ),
              const SizedBox(height: Space.s3),
              Semantics(header: true, child: Text(lesson.title, style: context.type.titleL)),
              const SizedBox(height: Space.s2),
              Wrap(
                spacing: Space.s4,
                runSpacing: Space.s1,
                children: [
                  MetaItem(icon: lessonTypeIcon(type), label: lessonTypeLabel(l10n, type)),
                  if (lesson.durationMin > 0)
                    MetaItem(
                      icon: AppIcons.duration,
                      label: AppDurations.minutes(l10n, lesson.durationMin),
                    ),
                  if (stats != null && stats.enrolled > 0)
                    MetaItem(
                      icon: AppIcons.chart,
                      label: l10n.staffCourseLessonCompleted(
                        formatFigure(stats.lessonPercent(lesson.id)),
                      ),
                    ),
                ],
              ),
              if (lesson.isPreview) ...[
                const SizedBox(height: Space.s3),
                const StatusBadge(StatusKind.freePreview),
              ],
            ],
          ),
        ),
        if (lesson.description case final description? when description.isNotEmpty) ...[
          const SizedBox(height: Space.s4),
          Text(description, style: context.type.bodyM),
        ],
        if (lesson.objectives.isNotEmpty) ...[
          const SizedBox(height: Space.sectionGap),
          SectionHeader(
            title: l10n.staffLessonObjectivesTitle,
            icon: AppIcons.success,
            iconColor: c.hue(Hue.green).solid,
          ),
          for (final objective in lesson.objectives)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(AppIcons.check, size: IconSizes.sm, color: c.accentInk),
                  const SizedBox(width: Space.s2),
                  Expanded(child: Text(objective, style: context.type.bodyM)),
                ],
              ),
            ),
        ],
        const SizedBox(height: Space.sectionGap),
        SectionHeader(
          title: l10n.staffLessonContentTitle,
          icon: lessonTypeIcon(type),
          iconColor: c.hue(lessonHue(type)).solid,
        ),
        _Content(lesson: lesson),
        const SizedBox(height: Space.s5),
        AppButton(
          label: l10n.staffLessonEditOnWeb,
          icon: AppIcons.external,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: () =>
              ref.read(openExternalLinkProvider)(courseEditUrl(webBase, role, courseId)),
        ),
        const SizedBox(height: Space.s4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppButton(
              label: l10n.actionPrevious,
              variant: AppButtonVariant.tertiary,
              onPressed: detail.previous == null ? null : () => openLesson(detail.previous!.id),
            ),
            AppButton(
              label: l10n.actionNext,
              variant: AppButtonVariant.tertiary,
              onPressed: detail.next == null ? null : () => openLesson(detail.next!.id),
            ),
          ],
        ),
      ],
    );
  }
}

/// What the lesson delivers, drawn with the same renderers a learner sees — without any of the
/// learner's own state, and without anything the route did not send.
class _Content extends StatelessWidget {
  const _Content({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final content = lesson.content;
    if (content == null || content.isEmpty) return _nothingYet(context);

    switch (LessonType.parse(lesson.type)) {
      case LessonType.video:
        final url = content.video?.file?.url;
        if (url == null) return _nothingYet(context);
        return AppVideoPlayer(
          url: url,
          markers: [
            for (final marker in content.video?.markers ?? const <LessonVideoMarker>[])
              VideoMarker(
                position: Duration(seconds: marker.atSec),
                label: marker.title,
              ),
          ],
        );
      case LessonType.reading:
      case LessonType.practice:
      case LessonType.unknown:
        final body = content.article?.body ?? '';
        if (body.isEmpty) return _nothingYet(context);
        return ArticleBody(body: body, onOpenLink: _openLink);
      case LessonType.document:
        final mediaId = content.document?.file?.id;
        if (mediaId == null) return _nothingYet(context);
        return Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: l10n.actionOpenDocument,
            icon: AppIcons.filePdf,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PdfViewerScreen(mediaId: mediaId, title: lesson.title),
              ),
            ),
          ),
        );
      case LessonType.assessment:
        final quiz = content.quiz;
        if (quiz == null) return _nothingYet(context);
        return _Delivers(
          lines: [
            l10n.quizSummaryFacts(quiz.questions, quiz.passMark),
            l10n.quizAttemptsAllowed(quiz.attempts),
            if (quiz.timeLimitMin case final limit?) l10n.quizTimeLimit(limit),
          ],
        );
      case LessonType.assignment:
        final assignment = content.assignment;
        if (assignment == null) return _nothingYet(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (assignment.brief.isNotEmpty) ...[
              Text(assignment.brief, style: context.type.bodyM),
              const SizedBox(height: Space.s3),
            ],
            _Delivers(
              lines: [
                l10n.assignmentRubricPoints(assignment.maxScore),
                l10n.staffLessonDueAfterDays(assignment.dueAfterDays),
              ],
            ),
          ],
        );
      case LessonType.live:
        final live = content.live;
        return live == null ? _nothingYet(context) : LiveSummaryCard(live: live);
    }
  }

  Widget _nothingYet(BuildContext context) =>
      StateLayout(icon: AppIcons.empty, title: context.l10n.staffLessonContentUnavailable);

  Future<void> _openLink(Uri url) async {
    if (url.scheme != 'https') return;
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

/// What a quiz or an assignment lesson delivers, mirrored from the linked item — the settings the
/// academy set, never the questions or the answer key.
class _Delivers extends StatelessWidget {
  const _Delivers({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.staffLessonDeliversTitle, style: context.type.label),
        const SizedBox(height: Space.s2),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s1),
            child: Text(line, style: context.type.bodyM),
          ),
      ],
    ),
  );
}
