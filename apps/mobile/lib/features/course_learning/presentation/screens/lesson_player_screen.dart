import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/course.dart';
import '../../../../shared/domain/progress.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../assessments/assessments.dart';
import '../../../media/media.dart';
import '../../application/lesson_controller.dart';
import '../widgets/lesson_parts.dart';

/// `/learn/:courseId/lessons/:lessonId` — the lesson itself. Opening it records the visit on the
/// server; what may be seen, what completes it and when it is done are all the server's to say.
class LessonPlayerScreen extends ConsumerWidget {
  const LessonPlayerScreen({required this.courseId, required this.lessonId, super.key});

  final String courseId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = LessonRef(courseId: courseId, lessonId: lessonId);
    return AsyncView<LessonView>(
      value: ref.watch(lessonViewProvider(lesson)),
      onRetry: () => ref.invalidate(lessonViewProvider(lesson)),
      skeleton: const DelayedLoading(skeleton: SkeletonDetail(showMedia: true)),
      notFound: NotFoundView(
        onBack: () => GoRouter.of(context).go(AppRoutes.learnCourse(courseId)),
      ),
      data: (view) => _Player(lesson: lesson, view: view),
    );
  }
}

class _Player extends ConsumerWidget {
  const _Player({required this.lesson, required this.view});

  final LessonRef lesson;
  final LessonView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final actions = ref.watch(lessonActionsProvider);

    ref.listen(lessonActionsProvider, (previous, next) {
      final moment = next.moment;
      if (moment != null && moment != previous?.moment) {
        _showMoment(context, ref, moment);
      }
      final failure = next.failure;
      if (failure != null && failure != previous?.failure) {
        showAppSnackbar(context, failure.message ?? l10n.stateErrorBody, tone: SnackTone.error);
        ref.read(lessonActionsProvider.notifier).clearFailure();
      }
    });

    if (!view.isOpen) return _ClosedLesson(view: view, courseId: lesson.courseId);

    final bookmarked = actions.bookmarkedFor(view);
    final video = view.lesson.type == 'video';
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s6),
            children: [
              // A video is what the learner came for, so it leads; every other lesson opens on
              // its title, and the tools sit between the title and the content.
              if (video) ...[
                _LessonBody(lesson: lesson, view: view),
                const SizedBox(height: Space.s4),
              ],
              LessonHeader(view: view),
              const SizedBox(height: Space.s3),
              Row(
                // The button takes the width its label needs; the bookmark sits at the far end.
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: AppButton(
                      label: l10n.actionOpenCurriculum,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.sm,
                      icon: AppIcons.list,
                      onPressed: () => _openCurriculum(context, ref),
                    ),
                  ),
                  AppIconButton(
                    icon: bookmarked ? AppIcons.bookmarked : AppIcons.bookmark,
                    label: bookmarked ? l10n.actionRemoveBookmark : l10n.actionBookmarkLesson,
                    onPressed: () => ref
                        .read(lessonActionsProvider.notifier)
                        .toggleBookmark(lesson, current: bookmarked),
                  ),
                ],
              ),
              if (!video) ...[
                const SizedBox(height: Space.s4),
                _LessonBody(lesson: lesson, view: view),
              ],
              const SizedBox(height: Space.sectionGap),
              LessonNotes(lesson: lesson, initialText: view.note),
            ],
          ),
        ),
        LessonNavBar(
          completion: _completion(context, view, actions),
          busy: actions.completing,
          onPrevious: view.previous == null
              ? null
              : () => router.go(AppRoutes.learnLesson(lesson.courseId, view.previous!.id)),
          onNext: view.next == null || view.next!.locked
              ? null
              : () => router.go(AppRoutes.learnLesson(lesson.courseId, view.next!.id)),
          onMarkComplete: () => ref.read(lessonActionsProvider.notifier).complete(lesson),
        ),
      ],
    );
  }

  /// What the bar's middle says: already done, ready to mark, or what is still missing — the
  /// server's own sentence once it has refused, and the rule in words before that.
  CompletionAction _completion(BuildContext context, LessonView view, LessonActionState actions) {
    final l10n = context.l10n;
    if (view.state == ProgressState.completed) return const AlreadyComplete();
    if (actions.hint != null) return CompletionHint(actions.hint!);
    return switch (view.rule) {
      CompletionRule.watched => CompletionHint(l10n.ruleHintWatched(view.threshold)),
      CompletionRule.passed => CompletionHint(l10n.ruleHintPassed),
      CompletionRule.submitted when view.lesson.type == 'assignment' => CompletionHint(
        l10n.ruleHintSubmitted,
      ),
      _ => const CanComplete(),
    };
  }

  void _openCurriculum(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    unawaited(
      showAppBottomSheet<void>(
        context,
        builder: (sheetContext) => AppBottomSheet(
          title: l10n.courseCurriculumTitle,
          child: CurriculumTree(
            chapters: curriculumFrom(sheetContext, view),
            onLessonTap: (node) {
              if (node.state == LessonNodeState.locked) {
                showAppSnackbar(sheetContext, node.lockedReason ?? l10n.stateLockedLessonTitle);
                return;
              }
              Navigator.of(sheetContext).pop();
              router.go(AppRoutes.learnLesson(lesson.courseId, node.id));
            },
          ),
        ),
      ),
    );
  }

  /// A chapter or a course is only ever celebrated because the server said it was finished.
  void _showMoment(BuildContext context, WidgetRef ref, CompleteResult moment) {
    final l10n = context.l10n;
    ref.read(lessonActionsProvider.notifier).momentSeen();
    if (moment.courseCompleted) {
      unawaited(
        showConfirmDialog(
          context,
          title: l10n.courseCompleteTitle,
          message: l10n.courseCompleteBody,
          confirmLabel: l10n.actionDone,
        ),
      );
      return;
    }
    if (moment.chapterCompleted case final chapter?) {
      showAppSnackbar(
        context,
        '${l10n.chapterCompleteTitle} · ${l10n.chapterCompleteBody(chapter)}',
        tone: SnackTone.success,
      );
    }
  }
}

/// The body, by lesson type. Only what the server sent is shown; it strips everything a learner
/// may not open, so there is nothing here to guess at.
class _LessonBody extends ConsumerWidget {
  const _LessonBody({required this.lesson, required this.view});

  final LessonRef lesson;
  final LessonView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final content = view.lesson.content;
    final type = view.lesson.type;

    if (type == 'video') {
      final url = content?.video?.file?.url;
      if (url == null) return _nothingYet(context);
      // Taken now, not in the callback: the player reports its last position from its own
      // dispose, when this widget's ref can no longer be read — the position was being lost.
      final actions = ref.read(lessonActionsProvider.notifier);
      return AppVideoPlayer(
        url: url,
        startAt: view.lessonProgress?.positionSec == null
            ? null
            : Duration(seconds: view.lessonProgress!.positionSec!),
        markers: [
          for (final marker in content?.video?.markers ?? const <LessonVideoMarker>[])
            VideoMarker(
              position: Duration(seconds: marker.atSec),
              label: marker.title,
            ),
        ],
        onPosition: (position, fraction) =>
            actions.reportPosition(lesson, positionSec: position.inSeconds, fraction: fraction),
      );
    }
    if (type == 'reading' || type == 'practice') {
      final body = content?.article?.body ?? '';
      if (body.isEmpty && type == 'reading') return _nothingYet(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (body.isNotEmpty) ArticleBody(body: body, onOpenLink: _openLink),
          if (view.assignment case final assignment?) ...[
            const SizedBox(height: Space.s4),
            AssignmentSummaryCard(
              summary: assignment,
              onOpen: () => GoRouter.of(context).go(AppRoutes.assignment(assignment.id)),
            ),
          ],
        ],
      );
    }
    if (type == 'document') {
      final mediaId = content?.document?.file?.id;
      if (mediaId == null) return _nothingYet(context);
      return Align(
        alignment: Alignment.centerLeft,
        child: AppButton(
          label: l10n.actionOpenDocument,
          icon: AppIcons.filePdf,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PdfViewerScreen(mediaId: mediaId, title: view.lesson.title),
            ),
          ),
        ),
      );
    }
    if (type == 'assessment') {
      final quiz = view.quiz;
      if (quiz == null) return _nothingYet(context);
      return QuizTaker(
        quiz: quiz,
        courseId: lesson.courseId,
        lessonId: lesson.lessonId,
        best: view.quizBest,
        // Passing a quiz can complete the lesson, its chapter and the course, so the lesson is
        // read again and the server's own verdict is what the page then shows.
        onFinished: () => ref.invalidate(lessonViewProvider(lesson)),
      );
    }
    if (type == 'assignment') {
      final assignment = view.assignment;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (content?.assignment?.brief.isNotEmpty ?? false)
            Text(content!.assignment!.brief, style: context.type.bodyM),
          if (assignment != null) ...[
            const SizedBox(height: Space.s4),
            AssignmentSummaryCard(
              summary: assignment,
              onOpen: () => GoRouter.of(context).go(AppRoutes.assignment(assignment.id)),
            ),
          ],
        ],
      );
    }
    if (type == 'live') {
      final live = content?.live;
      return live == null ? _nothingYet(context) : LiveSummaryCard(live: live);
    }
    return _nothingYet(context);
  }

  Widget _nothingYet(BuildContext context) => StateLayout(
    icon: AppIcons.empty,
    title: context.l10n.previewMissingTitle,
    message: context.l10n.previewMissingBody,
  );

  Future<void> _openLink(Uri url) async {
    if (url.scheme != 'https') return;
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

/// A lesson that is not open: locked, not enrolled, or no longer available. The reason is the
/// academy's own, and the app adds nothing to it.
class _ClosedLesson extends StatelessWidget {
  const _ClosedLesson({required this.view, required this.courseId});

  final LessonView view;
  final String courseId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (String title, String? message) = switch (view.access) {
      LessonAccess.locked => (l10n.lessonLockedTitle, view.lockedReason),
      LessonAccess.notEnrolled => (l10n.lessonNotEnrolledTitle, l10n.lessonNotEnrolledBody),
      _ => (l10n.lessonUnavailableTitle, view.lockedReason),
    };
    return StateLayout(
      icon: AppIcons.lock,
      title: title,
      message: message,
      actionLabel: l10n.actionOpenCurriculum,
      onAction: () => GoRouter.of(context).go(AppRoutes.learnCourse(courseId)),
    );
  }
}

/// The course outline as the player shows it, straight from the server's snapshot.
List<CurriculumChapterNode> curriculumFrom(BuildContext context, LessonView view) {
  final l10n = context.l10n;
  return [
    for (var ci = 0; ci < view.course.chapters.length; ci++)
      CurriculumChapterNode(
        id: view.course.chapters[ci].id,
        title: view.course.chapters[ci].title,
        lessons: [
          for (var li = 0; li < view.course.chapters[ci].lessons.length; li++)
            () {
              final lesson = view.course.chapters[ci].lessons[li];
              return CurriculumLessonNode(
                id: lesson.id,
                title: lesson.title,
                type: LessonType.parse(lesson.type),
                state: nodeStateFor(view.snapshot.stateOf(lesson.id)),
                numberLabel: '${ci + 1}.${li + 1}',
                durationLabel: lesson.durationMin > 0
                    ? AppDurations.minutes(l10n, lesson.durationMin)
                    : null,
                lockedReason: view.snapshot.stateOf(lesson.id) == ProgressState.locked
                    ? l10n.stateLockedLessonTitle
                    : null,
                isCurrent: lesson.id == view.lesson.id,
              );
            }(),
        ],
      ),
  ];
}

/// The server's progress state as the tree's node state. Nothing is inferred.
LessonNodeState nodeStateFor(ProgressState state) => switch (state) {
  ProgressState.completed => LessonNodeState.completed,
  ProgressState.inProgress => LessonNodeState.inProgress,
  ProgressState.locked => LessonNodeState.locked,
  _ => LessonNodeState.available,
};
