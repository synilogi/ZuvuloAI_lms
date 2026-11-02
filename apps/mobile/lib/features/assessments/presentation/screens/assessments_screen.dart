import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/quiz.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/quiz_taker_controller.dart';
import '../widgets/quiz_taker_parts.dart';

/// `/assessments` — every quiz across the learner's courses, in the order the server put them:
/// what can be taken first, then what has been failed, then what is locked, then what is passed.
class AssessmentsScreen extends ConsumerWidget {
  const AssessmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(assessmentsProvider.future),
      child: AsyncView<List<AssessmentRow>>(
        value: ref.watch(assessmentsProvider),
        onRetry: () => ref.invalidate(assessmentsProvider),
        data: (rows) => rows.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 360,
                    child: EmptyState(
                      title: l10n.assessmentsEmptyTitle,
                      message: l10n.assessmentsEmptyBody,
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s6),
                // Where the learner stands across their quizzes, then the quizzes themselves.
                itemCount: rows.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: Space.s3),
                itemBuilder: (context, i) =>
                    i == 0 ? _TestsSummary(rows: rows) : AssessmentCard(row: rows[i - 1]),
              ),
      ),
    );
  }
}

/// The learner's quizzes at a glance on a warm card: how many are ready to take, passed and
/// locked — each counted from the server's own state for the quiz, never worked out here.
class _TestsSummary extends StatelessWidget {
  const _TestsSummary({required this.rows});

  final List<AssessmentRow> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final figures = [
      (rows.where((r) => r.isOpen).length, l10n.upcomingReadyNow, c.hue(Hue.pink)),
      (
        rows.where((r) => r.state == AssessmentState.passed).length,
        l10n.statusPassed,
        c.hue(Hue.green),
      ),
      (
        rows.where((r) => r.state == AssessmentState.locked).length,
        l10n.statusLocked,
        c.tone(Tone.neutral),
      ),
    ];
    return AppCard(
      color: c.hue(Hue.gold).soft,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < figures.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                  width: Space.s4,
                  color: c.hue(Hue.gold).solid.withValues(alpha: 0.3),
                ),
              Expanded(
                child: Semantics(
                  label: '${figures[i].$2}: ${figures[i].$1}',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      Text(
                        '${figures[i].$1}',
                        style: context.type.numeral.copyWith(
                          fontSize: context.type.titleL.fontSize,
                          color: figures[i].$3.ink,
                        ),
                      ),
                      Text(
                        figures[i].$2,
                        textAlign: TextAlign.center,
                        style: context.type.caption.copyWith(color: c.text),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One quiz, laid out like a test on a store's shelf: its icon on the quiz hue, the course, the
/// title, what it asks and how many tries are left, the best score so far — and, when it is open,
/// what tapping it does; when locked, why, in the server's words.
class AssessmentCard extends StatelessWidget {
  const AssessmentCard({required this.row, super.key});

  final AssessmentRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = context.type;
    final attemptsLeft = row.attemptsLeft;
    final failed = row.state == AssessmentState.failed;
    final status = row.window == QuizWindow.upcoming && !row.inProgress
        ? StatusKind.upcoming
        : row.window == QuizWindow.closed &&
              !row.inProgress &&
              (row.state == AssessmentState.available || row.state == AssessmentState.failed)
        ? StatusKind.closed
        : assessmentStatusOf(row.state);
    // Every quiz the learner can reach opens: to start or resume it, or — passed, used up or closed — to read its
    // results and attempts. Only a locked one, or one not open yet, has nothing to show.
    final reachable = row.state != AssessmentState.locked && row.window != QuizWindow.upcoming;
    return AppCard(
      onTap: reachable
          ? () => GoRouter.of(context).go(AppRoutes.learnLesson(row.courseId, row.lessonId))
          : null,
      padding: const EdgeInsets.all(Space.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PracticeThumb(
                icon: AppIcons.quiz,
                colors: failed ? c.tone(Tone.danger) : c.hue(Hue.pink),
              ),
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
                      row.title,
                      style: type.titleS,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Space.s1),
                    Text(
                      [
                        l10n.assessmentRowFacts(row.questions, row.passMark),
                        if (row.durationMin > 0) AppDurations.minutes(l10n, row.durationMin),
                      ].join(' · '),
                      style: type.caption.copyWith(color: c.muted),
                    ),
                    Text(
                      attemptsLeft == null
                          ? l10n.assessmentAttemptsUnlimited
                          : l10n.assessmentAttemptsLeft(attemptsLeft),
                      style: type.caption.copyWith(color: c.muted),
                    ),
                    if (row.deadlineAt case final deadline? when row.inProgress) ...[
                      const SizedBox(height: Space.s1),
                      MetaItem(
                        icon: AppIcons.time,
                        label: l10n.assessmentInProgressDeadline(quizTime(l10n, deadline)),
                        color: c.warnInk,
                      ),
                    ] else if (row.closesAt case final closes?
                        when row.window != QuizWindow.upcoming) ...[
                      const SizedBox(height: Space.s1),
                      MetaItem(
                        icon: AppIcons.calendar,
                        label: row.window == QuizWindow.closed
                            ? l10n.assessmentClosedAt(quizTime(l10n, closes))
                            : l10n.assessmentClosesAt(quizTime(l10n, closes)),
                      ),
                    ],
                    if (row.negativeMarking) ...[
                      const SizedBox(height: Space.s1),
                      MetaItem(icon: AppIcons.warning, label: l10n.assessmentNegativeMarking),
                    ],
                    if (row.resultsHeld) ...[
                      const SizedBox(height: Space.s1),
                      MetaItem(
                        icon: AppIcons.lock,
                        label: l10n.assessmentResultsHeldUntil(quizTime(l10n, row.resultsAt!)),
                      ),
                    ],
                    if (row.score case final score?) ...[
                      const SizedBox(height: Space.s1),
                      Row(
                        children: [
                          AppIcon(AppIcons.rank, size: IconSizes.sm, color: c.hue(Hue.green).solid),
                          const SizedBox(width: Space.s1),
                          Flexible(
                            child: Text(
                              l10n.quizBestScore(score),
                              style: type.bodyS.copyWith(
                                color: c.hue(Hue.green).ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (row.lockedReason case final reason?) ...[
            const SizedBox(height: Space.s3),
            CardNote(text: reason, icon: AppIcons.lock),
          ] else if (row.window == QuizWindow.upcoming && !row.inProgress) ...[
            const SizedBox(height: Space.s3),
            CardNote(
              text: row.opensAt == null
                  ? statusLabel(l10n, StatusKind.upcoming)
                  : l10n.assessmentOpensAt(quizTime(l10n, row.opensAt!)),
              icon: AppIcons.calendar,
            ),
          ] else if (row.isOpen) ...[
            const SizedBox(height: Space.s3),
            CardActionBar(
              label: row.inProgress
                  ? l10n.actionResumeQuiz
                  : failed
                  ? l10n.actionTryAgain
                  : l10n.actionStartQuiz,
            ),
          ],
        ],
      ),
    );
  }
}

/// The badge for the server's own assessment state.
StatusKind? assessmentStatusOf(AssessmentState state) => switch (state) {
  AssessmentState.available => StatusKind.notStarted,
  AssessmentState.inProgress => StatusKind.inProgress,
  AssessmentState.failed => StatusKind.notPassed,
  AssessmentState.locked => StatusKind.locked,
  AssessmentState.passed => StatusKind.passed,
  AssessmentState.submitted => StatusKind.submitted,
  AssessmentState.unknown => null,
};
