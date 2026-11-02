import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/up_navigation.dart';
import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/quiz.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/quiz_taker_controller.dart';
import 'quiz_result.dart';
import 'quiz_taker_parts.dart';

/// Taking one quiz, in place inside its lesson: what it is and where the learner stands, then an
/// attempt the server runs — its questions, its deadline, every answer saved as it changes — a
/// last look, and the server's result. Nothing here marks an answer or keeps time of its own.
class QuizTaker extends ConsumerStatefulWidget {
  const QuizTaker({
    required this.quiz,
    required this.courseId,
    required this.lessonId,
    super.key,
    this.best,
    this.onFinished,
  });

  /// The quiz as the lesson describes it. Its questions are never answered from: they come with
  /// the attempt the server starts.
  final LearnerQuiz quiz;
  final String courseId;
  final String lessonId;

  /// The learner's best percentage before this attempt.
  final int? best;

  /// Called once the server has handed the attempt in, so the lesson can be read again.
  final VoidCallback? onFinished;

  @override
  ConsumerState<QuizTaker> createState() => _QuizTakerState();
}

class _QuizTakerState extends ConsumerState<QuizTaker> {
  late final AppLifecycleListener _lifecycle;

  QuizRef get _ref => (courseId: widget.courseId, lessonId: widget.lessonId);

  QuizTakerController get _notifier => ref.read(quizTakerProvider(_ref).notifier);

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      // Back in front: the server's time and answers are read again.
      onResume: () => unawaited(_notifier.onAppResumed()),
      // Going to the background: what is unsaved goes now.
      onHide: () => _notifier.onAppPaused(),
      onPause: () => _notifier.onAppPaused(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifier.open(widget.quiz);
    });
  }

  @override
  void didUpdateWidget(QuizTaker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quiz != widget.quiz) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifier.open(widget.quiz);
      });
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = quizTakerProvider(_ref);
    final state = ref.watch(provider);

    ref.listen(provider, (previous, next) {
      if (previous?.phase != QuizPhase.result && next.phase == QuizPhase.result) {
        widget.onFinished?.call();
      }
      if (next.warning != null && next.warning != previous?.warning) {
        showAppSnackbar(
          context,
          next.warning == TimeWarning.oneMinute ? l10n.quizWarnOneMinute : l10n.quizWarnFiveMinutes,
        );
      }
    });
    // The network is back: whatever is waiting goes now.
    ref.listen(isOnlineProvider, (previous, next) {
      if (previous?.value == false && next.value == true) unawaited(_notifier.retrySave());
    });

    final body = switch (state.phase) {
      QuizPhase.loading => const DelayedLoading(skeleton: SkeletonCard(showMedia: false)),
      QuizPhase.intro => _Intro(quiz: widget.quiz, state: state, target: _ref, best: widget.best),
      QuizPhase.answering => _Attempt(state: state, target: _ref),
      QuizPhase.submitting when state.timeUp => _HandingIn(state: state, target: _ref),
      QuizPhase.review || QuizPhase.submitting => _Review(state: state, target: _ref),
      QuizPhase.result => _Result(state: state, target: _ref),
    };

    return PopScope(
      // Leaving an attempt is allowed, but said out loud: the server's clock keeps running.
      canPop: !state.inAttempt,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !context.mounted) return;
        final current = ref.read(provider);
        final leave = await showConfirmDialog(
          context,
          title: l10n.quizLeaveTitle,
          message: current.isTimed ? l10n.quizLeaveBodyTimed : l10n.quizLeaveBodyUntimed,
          consequences: current.hasUnsaved ? [l10n.quizLeaveUnsaved] : const [],
          confirmLabel: l10n.quizLeaveAction,
        );
        if (!leave || !context.mounted) return;
        unawaited(_notifier.flush());
        leavePage(context);
      },
      child: body,
    );
  }
}

/// What the quiz is and where the learner stands, by the server: counts, marks, the limit, the
/// attempts used, the window — and either a way in or the academy's reason there is none.
class _Intro extends ConsumerWidget {
  const _Intro({required this.quiz, required this.state, required this.target, required this.best});

  final LearnerQuiz quiz;
  final QuizTakerState state;
  final QuizRef target;
  final int? best;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final settings = quiz.settings;
    final standing = state.standing;
    final notifier = ref.read(quizTakerProvider(target).notifier);
    final used = standing?.attemptsUsed ?? quiz.attemptsUsed;
    final allowed = standing?.attemptsAllowed ?? settings.attempts;
    final opensAt = standing?.opensAt ?? settings.opensAt;
    final closesAt = standing?.closesAt ?? settings.closesAt;
    final window = standing?.window ?? quiz.window;
    final openSession = standing?.openSession ?? quiz.openSession;
    final blocked = standing != null && !standing.canStart;
    final losesMarks = quiz.negativeMarking || quiz.questions.any((q) => q.losesMarks);
    final failure = state.failure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.quizIntroTitle, style: context.type.caption.copyWith(color: c.muted)),
              const SizedBox(height: Space.s1),
              Semantics(header: true, child: Text(quiz.title, style: context.type.titleM)),
              if (quiz.instructions.isNotEmpty) ...[
                const SizedBox(height: Space.s2),
                Text(quiz.instructions, style: context.type.bodyM),
              ],
              const SizedBox(height: Space.s3),
              InfoChips(
                items: [
                  (AppIcons.quiz, l10n.assessmentRowFacts(quiz.questionCount, settings.passMark)),
                  if (quiz.totalPoints > 0) (AppIcons.rank, l10n.quizTotalPoints(quiz.totalPoints)),
                  (
                    AppIcons.time,
                    settings.timeLimitMin == null
                        ? l10n.quizNoTimeLimit
                        : l10n.quizTimeLimit(settings.timeLimitMin!),
                  ),
                  (
                    AppIcons.list,
                    allowed > 0
                        ? l10n.quizAttemptsUsedOf(used, allowed)
                        : l10n.quizAttemptsUsedUnlimited(used),
                  ),
                ],
              ),
              if (opensAt != null && window == QuizWindow.upcoming) ...[
                const SizedBox(height: Space.s2),
                MetaItem(icon: AppIcons.calendar, label: l10n.quizOpensAt(quizTime(l10n, opensAt))),
              ],
              if (closesAt != null) ...[
                const SizedBox(height: Space.s2),
                MetaItem(
                  icon: AppIcons.calendar,
                  label: window == QuizWindow.closed
                      ? l10n.quizClosedAt(quizTime(l10n, closesAt))
                      : l10n.quizClosesAt(quizTime(l10n, closesAt)),
                ),
              ],
              if (settings.resultsRelease == ResultsRelease.afterClose) ...[
                const SizedBox(height: Space.s3),
                QuizNotice(text: l10n.quizResultsAfterClose, icon: AppIcons.calendar),
              ],
              if (losesMarks) ...[
                const SizedBox(height: Space.s3),
                QuizNotice(
                  text: l10n.quizNegativeMarkingNotice,
                  icon: AppIcons.warning,
                  tone: Tone.warn,
                ),
              ],
              if (best != null) ...[
                const SizedBox(height: Space.s3),
                Text(
                  l10n.quizBestScore(best!),
                  style: context.type.bodyS.copyWith(color: c.accentInk),
                ),
              ],
              if (standing?.passed ?? false) ...[
                const SizedBox(height: Space.s2),
                Text(l10n.quizPassedPractice, style: context.type.bodyS),
              ],
              if (state.refusal case final refusal?) ...[
                const SizedBox(height: Space.s3),
                QuizNotice(
                  text: state.opensAt == null
                      ? refusal
                      : l10n.quizNotOpenUntil(quizTime(l10n, state.opensAt!)),
                  icon: AppIcons.lock,
                  tone: Tone.warn,
                ),
              ] else if (failure != null) ...[
                const SizedBox(height: Space.s3),
                QuizNotice(
                  text: switch (failure) {
                    NotFoundFailure() => l10n.quizNoLongerOpen,
                    _ when standing == null => l10n.quizStandingFailed,
                    _ => l10n.quizStartFailed,
                  },
                  icon: AppIcons.error,
                  tone: Tone.danger,
                ),
                if (standing == null && failure is! NotFoundFailure) ...[
                  const SizedBox(height: Space.s2),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppButton(
                      label: l10n.actionRetry,
                      variant: AppButtonVariant.tertiary,
                      onPressed: () => unawaited(notifier.load()),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: Space.s4),
              if (blocked)
                QuizNotice(
                  text: standing.blockedReason ?? l10n.quizNoLongerOpen,
                  icon: AppIcons.lock,
                  tone: Tone.warn,
                )
              else ...[
                if (openSession != null)
                  Text(
                    l10n.quizAttemptUnderWay(openSession.attemptNo),
                    style: context.type.bodyS.copyWith(color: c.warnInk),
                  )
                else ...[
                  if (settings.timeLimitMin != null)
                    Text(l10n.quizStartTimedNotice, style: context.type.bodyS),
                  Text(
                    l10n.quizStartUsesAttempt,
                    style: context.type.caption.copyWith(color: c.muted),
                  ),
                ],
                const SizedBox(height: Space.s3),
                AppButton(
                  label: openSession != null ? l10n.actionResumeQuiz : l10n.actionStartQuiz,
                  size: AppButtonSize.lg,
                  expand: true,
                  busy: state.starting,
                  onPressed: () => unawaited(notifier.start()),
                ),
              ],
            ],
          ),
        ),
        if (state.history.isNotEmpty) ...[
          const SizedBox(height: Space.s4),
          QuizHistory(attempts: state.history),
        ],
      ],
    );
  }
}

/// The timer, the save state and — when it matters — the network, above every attempt screen.
class _AttemptStatus extends ConsumerWidget {
  const _AttemptStatus({required this.state, required this.target});

  final QuizTakerState state;
  final QuizRef target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final offline = ref.watch(isOnlineProvider).value == false;
    final notifier = ref.read(quizTakerProvider(target).notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Space.s2,
          runSpacing: Space.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (state.remaining case final remaining?) QuizTimerChip(remaining: remaining),
            if (!state.timeUp)
              QuizSaveChip(status: state.save, onRetry: () => unawaited(notifier.retrySave())),
          ],
        ),
        if (state.save == QuizSaveStatus.failed && state.saveFailure?.message != null) ...[
          const SizedBox(height: Space.s2),
          QuizNotice(text: state.saveFailure!.message!, icon: AppIcons.warning, tone: Tone.danger),
        ],
        if (offline) ...[
          const SizedBox(height: Space.s2),
          QuizNotice(text: l10n.quizOfflineBanner, icon: AppIcons.offline, tone: Tone.warn),
        ],
        if (state.timeUp) ...[
          const SizedBox(height: Space.s2),
          QuizNotice(text: l10n.quizTimeUp, icon: AppIcons.time, tone: Tone.danger),
        ],
      ],
    );
  }
}

class _Attempt extends ConsumerWidget {
  const _Attempt({required this.state, required this.target});

  final QuizTakerState state;
  final QuizRef target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(quizTakerProvider(target).notifier);
    final questions = state.questions;
    if (questions.isEmpty) return const SizedBox.shrink();
    final index = state.index.clamp(0, questions.length - 1);
    final question = questions[index];
    final answer = state.answers[question.id];
    final last = index == questions.length - 1;
    final marks = l10n.quizQuestionMarks(question.points);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AttemptStatus(state: state, target: target),
        if (questions.any((q) => q.losesMarks)) ...[
          const SizedBox(height: Space.s2),
          QuizNotice(text: l10n.quizNegativeMarkingNotice, icon: AppIcons.warning, tone: Tone.warn),
        ],
        const SizedBox(height: Space.s3),
        QuizPalette(questions: questions, state: state, onSelect: notifier.goTo),
        const SizedBox(height: Space.s3),
        ProgressBar(value: (index + 1) / questions.length),
        const SizedBox(height: Space.s4),
        QuizQuestionCard(
          key: ValueKey('${state.session?.id}-${question.id}'),
          number: index + 1,
          total: questions.length,
          prompt: question.prompt,
          kind: questionKindOf(question.type),
          options: [for (final option in question.options) QuestionOption(option.id, option.text)],
          selectedIds: _selected(answer),
          textAnswer: answer is String ? answer : null,
          note: question.losesMarks
              ? l10n.quizQuestionNegative(marks, quizMarks(question.negativePoints!))
              : marks,
          enabled: !state.locked,
          // The card hands back the whole selection; a multiple-choice answer is that list, and
          // every other kind is the one option chosen.
          onSelectionChanged: (ids) => question.isMultiple
              ? notifier.answerMany(question.id, ids.toList())
              : notifier.answerOne(question.id, ids.isEmpty ? '' : ids.first),
          onTextChanged: (text) => notifier.writeAnswer(question.id, text),
        ),
        const SizedBox(height: Space.s4),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: Space.s2,
          runSpacing: Space.s2,
          children: [
            AppButton(
              label: l10n.actionPrevious,
              variant: AppButtonVariant.tertiary,
              onPressed: index == 0 ? null : notifier.previous,
            ),
            AppButton(
              label: last ? l10n.actionReviewAnswers : l10n.actionNext,
              onPressed: last ? notifier.review : notifier.next,
            ),
          ],
        ),
      ],
    );
  }

  Set<String> _selected(Object? answer) => switch (answer) {
    final List<String> ids => ids.toSet(),
    final String id when id.isNotEmpty => {id},
    _ => const {},
  };
}

/// The last look: every question, answered or not and saved or not, then handing in.
class _Review extends ConsumerWidget {
  const _Review({required this.state, required this.target});

  final QuizTakerState state;
  final QuizRef target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final notifier = ref.read(quizTakerProvider(target).notifier);
    final unanswered = state.unansweredCount;
    final offline = ref.watch(isOnlineProvider).value == false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AttemptStatus(state: state, target: target),
        const SizedBox(height: Space.s3),
        SectionHeader(title: l10n.quizReviewTitle),
        const SizedBox(height: Space.s2),
        Semantics(
          liveRegion: true,
          child: Text(
            unanswered == 0 ? l10n.quizAllAnswered : l10n.quizUnansweredWarning(unanswered),
            style: context.type.bodyS.copyWith(color: unanswered == 0 ? c.muted : c.warnInk),
          ),
        ),
        const SizedBox(height: Space.s3),
        GroupedList(
          children: [
            for (var i = 0; i < state.questions.length; i++)
              AppListTile(
                title: state.questions[i].prompt,
                meta: !state.answered(state.questions[i])
                    ? l10n.quizUnansweredLabel
                    : state.savedOnServer(state.questions[i])
                    ? l10n.quizAnsweredLabel
                    : l10n.quizAnsweredNotSaved,
                showChevron: true,
                onTap: state.busy ? null : () => notifier.goTo(i),
              ),
          ],
        ),
        if (state.refusal case final refusal?) ...[
          const SizedBox(height: Space.s3),
          QuizNotice(text: refusal, icon: AppIcons.lock, tone: Tone.warn),
        ],
        if (state.failure != null) ...[
          const SizedBox(height: Space.s3),
          QuizNotice(text: l10n.quizSubmitFailed, icon: AppIcons.error, tone: Tone.danger),
        ],
        if (offline) ...[
          const SizedBox(height: Space.s3),
          Text(l10n.quizSubmitOffline, style: context.type.bodyS.copyWith(color: c.muted)),
        ],
        const SizedBox(height: Space.s4),
        AppButton(
          label: l10n.actionSubmitQuiz,
          size: AppButtonSize.lg,
          expand: true,
          busy: state.busy,
          onPressed: () async {
            final confirmed = await showConfirmDialog(
              context,
              title: l10n.quizSubmitConfirmTitle,
              message: l10n.quizSubmitConfirmBody,
              consequences: unanswered == 0 ? const [] : [l10n.quizUnansweredWarning(unanswered)],
              confirmLabel: l10n.actionSubmitQuiz,
            );
            if (!confirmed) return;
            await notifier.submit();
          },
        ),
        const SizedBox(height: Space.s2),
        AppButton(
          label: l10n.actionBackToQuestions,
          variant: AppButtonVariant.tertiary,
          expand: true,
          onPressed: state.busy ? null : () => notifier.goTo(state.index),
        ),
      ],
    );
  }
}

/// Time ran out: the answers are locked and the attempt is on its way in.
class _HandingIn extends ConsumerWidget {
  const _HandingIn({required this.state, required this.target});

  final QuizTakerState state;
  final QuizRef target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AttemptStatus(state: state, target: target),
        const SizedBox(height: Space.s4),
        AppCard(
          child: Semantics(
            liveRegion: true,
            child: Row(
              children: [
                const SizedBox.square(
                  dimension: IconSizes.md,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: Text(
                    state.failure == null ? l10n.quizHandingIn : l10n.quizHandInRetrying,
                    style: context.type.bodyM,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (state.refusal case final refusal?) ...[
          const SizedBox(height: Space.s3),
          QuizNotice(text: refusal, icon: AppIcons.lock, tone: Tone.warn),
        ],
      ],
    );
  }
}

/// The server's result, what can happen next, and every attempt so far.
class _Result extends ConsumerWidget {
  const _Result({required this.state, required this.target});

  final QuizTakerState state;
  final QuizRef target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(quizTakerProvider(target).notifier);
    final review = state.result;
    final standing = state.standing;
    final older = review == null
        ? state.history
        : state.history.where((a) => a.attemptId != review.attemptId).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (review != null)
                QuizResultView(review: review, expired: state.expired, questions: state.questions)
              else ...[
                const Wrap(children: [StatusBadge(StatusKind.submitted, size: StatusBadgeSize.md)]),
                const SizedBox(height: Space.s3),
                Text(l10n.quizResultUnavailable, style: context.type.bodyM),
                if (state.expired) ...[
                  const SizedBox(height: Space.s3),
                  QuizNotice(text: l10n.quizExpiredNotice, icon: AppIcons.time, tone: Tone.warn),
                ],
                const SizedBox(height: Space.s2),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppButton(
                    label: l10n.actionRetry,
                    variant: AppButtonVariant.tertiary,
                    onPressed: () => unawaited(notifier.reloadResult()),
                  ),
                ),
              ],
              if (standing != null) ...[
                const SizedBox(height: Space.s4),
                if (standing.canStart)
                  AppButton(
                    label: l10n.actionTryAgain,
                    variant: AppButtonVariant.secondary,
                    expand: true,
                    onPressed: notifier.retake,
                  )
                else if (standing.blockedReason case final reason?)
                  QuizNotice(text: reason, icon: AppIcons.lock),
              ],
            ],
          ),
        ),
        if (older.isNotEmpty) ...[const SizedBox(height: Space.s4), QuizHistory(attempts: older)],
      ],
    );
  }
}

/// The domain's question type as the card's kind.
QuestionKind questionKindOf(QuestionType type) => switch (type) {
  QuestionType.multiple => QuestionKind.multiple,
  QuestionType.trueFalse => QuestionKind.trueFalse,
  QuestionType.short => QuestionKind.shortAnswer,
  _ => QuestionKind.single,
};
