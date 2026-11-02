import 'package:flutter/material.dart';

import '../../../../core/format/figures.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/quiz.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_quizzes_controller.dart';

StatusKind quizStatusKind(StaffQuizStatus status) => switch (status) {
  StaffQuizStatus.published => StatusKind.published,
  // Kept with every result, but no learner starts it again.
  StaffQuizStatus.archived => StatusKind.archived,
  StaffQuizStatus.draft || StaffQuizStatus.unknown => StatusKind.draft,
};

String resultsVisibilityLabel(AppLocalizations l10n, ResultsVisibility visibility) =>
    switch (visibility) {
      ResultsVisibility.scoreAndAnswers ||
      ResultsVisibility.unknown => l10n.staffQuizResultsScoreAndAnswers,
      ResultsVisibility.scoreOnly => l10n.staffQuizResultsScoreOnly,
      ResultsVisibility.hidden => l10n.staffQuizResultsHidden,
    };

/// One quiz in the staff list: where it lives, how big it is, and how it is going. A rate the
/// academy has nothing to count yet is a dash, never a zero.
class StaffQuizCard extends StatelessWidget {
  const StaffQuizCard({required this.row, required this.onOpen, super.key});

  final StaffQuizRow row;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StripCard(
      onTap: onOpen,
      strip: context.colors.hue(AppNavIcons.of(AppIcons.quiz).hue),
      stripIcon: AppIcons.quiz,
      stripLabel: [row.courseTitle, ?row.chapterTitle].join(' · '),
      badge: StatusBadge(quizStatusKind(row.quiz.status)),
      title: row.quiz.title,
      facts: [
        MetaItem(
          icon: AppIcons.list,
          label: [
            l10n.staffQuizQuestions(row.quiz.questions.length),
            l10n.staffQuizPoints(row.points),
            l10n.staffQuizAttempts(row.attempts),
          ].join(' · '),
        ),
        if (row.attempts > 0)
          MetaItem(
            icon: AppIcons.chart,
            label:
                '${l10n.staffQuizStatPassRate}: ${formatFigure(row.passRate ?? 0)}% · '
                '${l10n.staffQuizStatAvgScore}: ${formatFigure(row.avgScore ?? 0)}%',
          ),
      ],
    );
  }
}

/// One question as staff read it: the prompt, every option with the answer marked, and how the
/// learners did on it. The answer key is here because only staff ever see this screen (§18).
class StaffQuizQuestionCard extends StatelessWidget {
  const StaffQuizQuestionCard({
    required this.question,
    required this.number,
    required this.total,
    super.key,
    this.stat,
  });

  final StaffQuizQuestion question;
  final int number;
  final int total;
  final QuestionStat? stat;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final wrongId = stat?.commonWrongOptionId;
    final wrong = question.options.where((o) => o.id == wrongId).firstOrNull;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l10n.quizQuestionCount(number, total),
                  style: context.type.label.copyWith(color: c.muted),
                ),
              ),
              LessonTypeIcon(LessonType.assessment, size: IconSizes.sm, color: c.faint),
            ],
          ),
          const SizedBox(height: Space.s2),
          Text(question.prompt, style: context.type.bodyL),
          const SizedBox(height: Space.s2),
          Wrap(
            spacing: Space.s2,
            runSpacing: Space.s1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.staffQuizPoints(question.points),
                style: context.type.caption.copyWith(color: c.muted),
              ),
              if (!question.needed)
                Text(
                  l10n.staffQuizOptionalQuestion,
                  style: context.type.caption.copyWith(color: c.muted),
                ),
              if (stat case final stat?)
                Text(
                  l10n.staffQuizCorrectRate(formatFigure(stat.correctRate)),
                  style: context.type.caption.copyWith(color: c.muted),
                ),
            ],
          ),
          if (question.options.isNotEmpty) ...[
            const SizedBox(height: Space.s3),
            for (final option in question.options)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(
                      question.correct.contains(option.id) ? AppIcons.check : AppIcons.close,
                      size: IconSizes.sm,
                      color: question.correct.contains(option.id) ? c.accentInk : c.faint,
                      semanticLabel: question.correct.contains(option.id)
                          ? l10n.staffQuizCorrectAnswer
                          : null,
                    ),
                    const SizedBox(width: Space.s2),
                    Expanded(child: Text(option.text, style: context.type.bodyM)),
                  ],
                ),
              ),
          ],
          if (question.acceptedAnswers.isNotEmpty) ...[
            const SizedBox(height: Space.s2),
            Text(
              l10n.staffQuizAcceptedAnswers(question.acceptedAnswers.join(', ')),
              style: context.type.bodyM,
            ),
          ],
          if (wrong != null) ...[
            const SizedBox(height: Space.s2),
            Text(
              l10n.staffQuizCommonWrong(wrong.text),
              style: context.type.caption.copyWith(color: c.warnInk),
            ),
          ],
          if (question.explanation case final explanation? when explanation.trim().isNotEmpty) ...[
            const SizedBox(height: Space.s3),
            Text(l10n.staffQuizExplanationLabel, style: context.type.label),
            const SizedBox(height: Space.s1),
            Text(explanation, style: context.type.bodyM.copyWith(color: c.muted)),
          ],
        ],
      ),
    );
  }
}
