import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/quiz.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/quiz_taker_controller.dart';
import 'quiz_taker_parts.dart';

/// The server's result for one handed-in attempt, cut to what the academy shows: the score and
/// pass mark, each question's outcome only when the server sent it, and why anything is missing —
/// the answers held back while the quiz can still be taken for credit, or the whole result held
/// until the quiz closes. Nothing here is worked out on the phone.
class QuizResultView extends StatelessWidget {
  const QuizResultView({
    required this.review,
    super.key,
    this.expired = false,
    this.questions = const [],
  });

  final AttemptReview review;
  final bool expired;

  /// The attempt's questions, when this screen still holds them, to name each one and its options.
  final List<LearnerQuizQuestion> questions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final held = review.held;
    final showsScore = review.hasScore && review.showResults != ResultsVisibility.hidden;
    final kind = held
        ? StatusKind.submitted
        : review.passed
        ? StatusKind.passed
        : StatusKind.notPassed;
    final title = held
        ? l10n.quizReceivedTitle
        : review.passed
        ? l10n.quizPassedTitle
        : l10n.quizNotPassedTitle;
    final points = review.points;
    final max = review.max;
    final breakdown = review.questions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(children: [StatusBadge(kind, size: StatusBadgeSize.md)]),
        const SizedBox(height: Space.s3),
        Semantics(header: true, liveRegion: true, child: Text(title, style: context.type.titleM)),
        if (showsScore) ...[
          const SizedBox(height: Space.s2),
          Semantics(
            label: l10n.quizResultSemantics(
              review.percent!,
              quizMarks(points ?? 0),
              quizMarks(max ?? 0),
            ),
            excludeSemantics: true,
            child: Wrap(
              spacing: Space.s3,
              runSpacing: Space.s1,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Text(
                  l10n.quizResultPercent(review.percent!),
                  style: context.type.numeral.copyWith(
                    fontSize: context.type.titleL.fontSize,
                    color: review.passed ? c.accentInk : c.text,
                  ),
                ),
                if (points != null && max != null)
                  Text(
                    l10n.quizResultPoints(quizMarks(points), quizMarks(max)),
                    style: context.type.bodyM,
                  ),
              ],
            ),
          ),
          if (review.passMark case final passMark?)
            Text(
              l10n.quizResultPassMark(passMark),
              style: context.type.bodyS.copyWith(color: c.muted),
            ),
        ],
        if (expired || review.expired) ...[
          const SizedBox(height: Space.s3),
          QuizNotice(text: l10n.quizExpiredNotice, icon: AppIcons.time, tone: Tone.warn),
        ],
        if (held && review.resultsAt != null) ...[
          const SizedBox(height: Space.s3),
          QuizNotice(
            text: l10n.quizResultsHeldUntil(quizTime(l10n, review.resultsAt!)),
            icon: AppIcons.calendar,
          ),
        ] else if (review.showResults == ResultsVisibility.hidden) ...[
          const SizedBox(height: Space.s3),
          QuizNotice(text: l10n.quizResultsHidden, icon: AppIcons.info),
        ],
        if (showsScore && (points ?? 0) < 0) ...[
          const SizedBox(height: Space.s3),
          QuizNotice(text: l10n.quizNegativeScoreNote, icon: AppIcons.info),
        ],
        if (review.keyWithheld) ...[
          const SizedBox(height: Space.s3),
          QuizNotice(text: l10n.quizKeyWithheld, icon: AppIcons.lock),
        ],
        if (!held && breakdown != null && breakdown.isNotEmpty) ...[
          const SizedBox(height: Space.s4),
          SectionHeader(title: l10n.quizBreakdownTitle),
          ..._breakdown(context, breakdown),
        ],
      ],
    );
  }

  /// One row per question, in the attempt's order when this screen still holds it.
  List<Widget> _breakdown(BuildContext context, Map<String, ReviewedQuestion> breakdown) {
    final byId = {for (final q in questions) q.id: q};
    final ids = [
      for (final q in questions)
        if (breakdown.containsKey(q.id)) q.id,
      for (final id in breakdown.keys)
        if (!byId.containsKey(id)) id,
    ];
    return [
      for (var i = 0; i < ids.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.s2),
          child: _ReviewedRow(number: i + 1, question: byId[ids[i]], outcome: breakdown[ids[i]]!),
        ),
    ];
  }
}

class _ReviewedRow extends StatelessWidget {
  const _ReviewedRow({required this.number, required this.question, required this.outcome});

  final int number;
  final LearnerQuizQuestion? question;
  final ReviewedQuestion outcome;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final (String label, Tone tone) = switch (outcome.state) {
      AnswerState.correct => (l10n.quizAnswerCorrect, Tone.accent),
      AnswerState.partial => (l10n.quizAnswerPartial, Tone.warn),
      AnswerState.incorrect => (l10n.quizAnswerIncorrect, Tone.danger),
      AnswerState.unanswered || AnswerState.unknown => (l10n.quizAnswerUnanswered, Tone.neutral),
    };
    final colors = c.tone(tone);
    final yours = _text(outcome.answer);
    final right = [...?outcome.correct?.map(_optionText), ...?outcome.acceptedAnswers].join(', ');
    return AppCard(
      padding: const EdgeInsets.all(Space.s3),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: Space.s2,
              runSpacing: Space.s1,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.quizQuestionNumber(number),
                  style: context.type.label.copyWith(color: c.muted),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.soft,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: 2),
                    child: Text(label, style: context.type.caption.copyWith(color: colors.ink)),
                  ),
                ),
                Text(
                  l10n.quizQuestionScored(quizMarks(outcome.points)),
                  style: context.type.caption.copyWith(color: c.muted),
                ),
              ],
            ),
            if (question != null) ...[
              const SizedBox(height: Space.s1),
              Text(question!.prompt, style: context.type.bodyM),
            ],
            if (yours.isNotEmpty) ...[
              const SizedBox(height: Space.s1),
              Text(l10n.quizYourAnswer(yours), style: context.type.bodyS),
            ],
            if (right.isNotEmpty) ...[
              const SizedBox(height: Space.s1),
              Text(
                l10n.quizRightAnswer(right),
                style: context.type.bodyS.copyWith(color: c.accentInk),
              ),
            ],
            if (outcome.explanation case final explanation? when explanation.isNotEmpty) ...[
              const SizedBox(height: Space.s1),
              Text(explanation, style: context.type.bodyS.copyWith(color: c.muted)),
            ],
          ],
        ),
      ),
    );
  }

  String _optionText(String id) {
    final option = question?.options.where((o) => o.id == id).firstOrNull;
    return option?.text ?? id;
  }

  String _text(Object? answer) => switch (answer) {
    final String text => text.trim(),
    final List<Object?> ids => ids.whereType<String>().map(_optionText).join(', '),
    _ => '',
  };
}

/// The learner's attempts at this quiz, newest first, each as the server cut it.
class QuizHistory extends StatelessWidget {
  const QuizHistory({required this.attempts, super.key});

  final List<AttemptReview> attempts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (attempts.isEmpty) return const SizedBox.shrink();
    return GroupedList(
      title: l10n.quizHistoryTitle,
      children: [
        for (var i = 0; i < attempts.length; i++)
          AppListTile(
            title: l10n.quizHistoryAttempt(attempts[i].attemptNo ?? attempts.length - i),
            subtitle: quizTime(l10n, attempts[i].submittedAt),
            meta: [
              if (attempts[i].held)
                l10n.quizHistoryHeld
              else if (attempts[i].hasScore &&
                  attempts[i].showResults != ResultsVisibility.hidden) ...[
                l10n.quizResultPercent(attempts[i].percent!),
                attempts[i].passed ? l10n.quizPassedTitle : l10n.quizNotPassedTitle,
              ] else
                l10n.quizHistoryReceived,
              if (attempts[i].expired) l10n.quizHistoryExpired,
            ].join(' · '),
          ),
      ],
    );
  }
}
