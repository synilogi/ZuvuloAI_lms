import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/format/figures.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/platform/external_link.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/auth.dart';
import '../../../staff_courses/staff_courses.dart';
import '../../application/staff_quizzes_controller.dart';
import '../widgets/quiz_parts.dart';

/// `/staff/quizzes/:quizId` — one quiz: how it is set up, what it asks (with the answers, since
/// only staff read this) and how the learners did. Every figure is the academy's, counted over
/// attempts rather than learners, and nothing here is editable (§26).
class StaffQuizScreen extends ConsumerWidget {
  const StaffQuizScreen({required this.quizId, super.key});

  final String quizId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView<StaffQuiz>(
      value: ref.watch(staffQuizProvider(quizId)),
      onRetry: () => ref.invalidate(staffQuizProvider(quizId)),
      skeleton: const DelayedLoading(skeleton: SkeletonDetail()),
      notFound: NotFoundView(onBack: () => GoRouter.of(context).go(AppRoutes.staffQuizzes)),
      data: (quiz) => _Quiz(quiz: quiz),
    );
  }
}

class _Quiz extends ConsumerWidget {
  const _Quiz({required this.quiz});

  final StaffQuiz quiz;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;
    final stats = ref.watch(quizStatsProvider(quiz.id));
    final role = ref.watch(currentUserProvider)?.role ?? UserRole.unknown;
    final webBase = ref.watch(appConfigProvider).webBaseUrl;
    final shuffled = [
      if (quiz.settings.shuffleQuestions) l10n.staffQuizShuffleQuestions,
      if (quiz.settings.shuffleOptions) l10n.staffQuizShuffleOptions,
    ];

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(staffQuizProvider(quiz.id))
          ..invalidate(quizStatsProvider(quiz.id));
        await ref.read(staffQuizProvider(quiz.id).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
        children: [
          DetailHeader(
            icon: AppIcons.quiz,
            badge: StatusBadge(quizStatusKind(quiz.status)),
            title: quiz.title,
            facts: [
              MetaItem(
                icon: AppIcons.list,
                label: [
                  l10n.staffQuizQuestions(quiz.questions.length),
                  l10n.staffQuizPoints(quiz.totalPoints),
                ].join(' · '),
              ),
            ],
            footer: [
              if (quiz.instructions.trim().isNotEmpty)
                Text(quiz.instructions, style: context.type.bodyM),
            ],
          ),
          const SizedBox(height: Space.s4),
          AppButton(
            label: l10n.staffQuizEditOnWeb,
            icon: AppIcons.external,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () =>
                ref.read(openExternalLinkProvider)(courseEditUrl(webBase, role, quiz.courseId)),
          ),
          const SizedBox(height: Space.sectionGap),
          SectionHeader(
            title: l10n.staffQuizSettingsTitle,
            icon: AppIcons.settings,
            iconColor: c.hue(Hue.blue).solid,
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s1),
            child: KeyValueTable(
              rows: [
                (l10n.staffQuizPassMarkLabel, '${quiz.settings.passMark}%'),
                (
                  l10n.staffQuizAttemptsLabel,
                  quiz.settings.unlimitedAttempts
                      ? l10n.staffQuizAttemptsUnlimited
                      : l10n.quizAttemptsAllowed(quiz.settings.attempts),
                ),
                (
                  l10n.staffQuizTimeLimitLabel,
                  quiz.settings.timeLimitMin == null
                      ? l10n.staffQuizNoTimeLimit
                      : l10n.quizTimeLimit(quiz.settings.timeLimitMin!),
                ),
                (
                  l10n.staffQuizShuffleLabel,
                  shuffled.isEmpty ? l10n.staffQuizShuffleNothing : shuffled.join(' · '),
                ),
                (
                  l10n.staffQuizResultsLabel,
                  resultsVisibilityLabel(l10n, quiz.settings.showResults),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.sectionGap),
          SectionHeader(
            title: l10n.staffQuizStatsTitle,
            icon: AppIcons.reports,
            iconColor: c.hue(Hue.violet).solid,
          ),
          AsyncView<QuizStats>(
            value: stats,
            onRetry: () => ref.invalidate(quizStatsProvider(quiz.id)),
            skeleton: const DelayedLoading(skeleton: SkeletonCard()),
            data: (stats) => _Stats(stats: stats),
          ),
          const SizedBox(height: Space.sectionGap),
          SectionHeader(
            title: l10n.staffQuizQuestionsTitle,
            icon: AppIcons.quiz,
            iconColor: c.hue(AppNavIcons.of(AppIcons.quiz).hue).solid,
          ),
          Text(l10n.staffQuizAnswerKeyNote, style: context.type.caption.copyWith(color: c.muted)),
          const SizedBox(height: Space.s3),
          for (var i = 0; i < quiz.questions.length; i++) ...[
            StaffQuizQuestionCard(
              question: quiz.questions[i],
              number: i + 1,
              total: quiz.questions.length,
              stat: stats.value?.statFor(quiz.questions[i].id),
            ),
            const SizedBox(height: Space.s3),
          ],
        ],
      ),
    );
  }
}

/// How learners did, in the academy's figures: the three that matter most side by side, the rest
/// as a table, and how the scores fell. Counted over attempts, as the server counts them.
class _Stats extends StatelessWidget {
  const _Stats({required this.stats});

  final QuizStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (stats.isEmpty) {
      return EmptyState(
        title: l10n.staffQuizNoAttemptsTitle,
        message: l10n.staffQuizNoAttemptsBody,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatSummaryCard(
          figures: [
            StatFigure(
              value: formatFigure(stats.attempts),
              label: l10n.staffQuizStatAttempts,
              icon: AppIcons.quiz,
              hue: Hue.orange,
            ),
            StatFigure(
              value: formatFigure(stats.learners),
              label: l10n.staffQuizStatLearners,
              icon: AppIcons.people,
              hue: Hue.green,
            ),
            StatFigure(
              value: '${formatFigure(stats.passRate)}%',
              label: l10n.staffQuizStatPassRate,
              icon: AppIcons.success,
              hue: Hue.violet,
            ),
          ],
        ),
        const SizedBox(height: Space.s3),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s1),
          child: KeyValueTable(
            rows: [
              (l10n.staffQuizStatAvgScore, '${formatFigure(stats.avgScore)}%'),
              (
                l10n.staffQuizStatMedianTime,
                l10n.staffQuizMinutes(formatFigure(stats.medianMinutes)),
              ),
            ],
          ),
        ),
        if (stats.distribution.isNotEmpty) ...[
          const SizedBox(height: Space.s4),
          BarList(
            title: l10n.staffQuizDistributionTitle,
            // The bands are the server's own arithmetic, labelled its own way.
            points: [
              for (final band in stats.distribution)
                ChartPoint(band.label, band.value.toDouble(), formatFigure(band.value)),
            ],
          ),
        ],
      ],
    );
  }
}
