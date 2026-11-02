import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/format/figures.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_reports_controller.dart';
import '../widgets/report_parts.dart';

/// `/staff/reports/courses` — every course that had activity in the period, ranked by the academy's
/// own order (busiest first). A table on the web; ranked cards here (§20). A shell body.
class CoursesReportScreen extends ConsumerWidget {
  const CoursesReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final gutter = WindowSize.of(context).isCompact ? Space.s4 : Space.gutterMedium;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(coursesReportProvider.future),
      child: AsyncView<CoursesReport>(
        value: ref.watch(coursesReportProvider),
        onRetry: () => ref.invalidate(coursesReportProvider),
        data: (report) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
          children: [
            ReportHeader(title: l10n.reportsTabCourses, courseCount: report.courseCount),
            const SizedBox(height: Space.s4),
            if (report.rows.isEmpty)
              EmptyState(title: l10n.reportsEmptyTitle, message: l10n.reportsCoursesEmpty)
            else
              for (final row in report.rows) ...[
                CourseReportCard(
                  row: row,
                  onOpen: () => GoRouter.of(context).go(AppRoutes.staffReportsCourse(row.courseId)),
                ),
                const SizedBox(height: Space.s3),
              ],
          ],
        ),
      ),
    );
  }
}

/// `/staff/reports/courses/:courseId` — one course in full. A draft, or a course outside the caller's
/// scope, is a 404 and reads as not found rather than as an error to retry (§7). A shell body.
class CourseReportScreen extends ConsumerWidget {
  const CourseReportScreen({required this.courseId, super.key});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(courseReportProvider(courseId).future),
      child: AsyncView<CourseReport>(
        value: ref.watch(courseReportProvider(courseId)),
        onRetry: () => ref.invalidate(courseReportProvider(courseId)),
        // The academy's own words for it: a draft has no report, and nor has a course this
        // account may not see (§7).
        notFound: EmptyState(title: l10n.reportsTabCourses, message: l10n.reportsCourseNotFound),
        data: (report) => _Course(report: report),
      ),
    );
  }
}

class _Course extends ConsumerWidget {
  const _Course({required this.report});

  final CourseReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final gutter = WindowSize.of(context).isCompact ? Space.s4 : Space.gutterMedium;
    final period = periodLabel(l10n, ref.watch(reportFilterProvider).range);
    final row = report.row;
    final kpis = report.kpis;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
      children: [
        ReportHeader(title: row.title, courseCount: report.courseCount),
        const SizedBox(height: Space.s2),
        Text(
          [
            row.categoryTitle,
            if (row.instructorNames.isNotEmpty) row.instructorNames.join(', '),
            if (row.rating case final rating?) l10n.reportsCourseRating(formatFigure(rating)),
          ].where((part) => part.isNotEmpty).join(' · '),
          style: context.type.bodyS.copyWith(color: context.colors.muted),
        ),
        const SizedBox(height: Space.s4),
        TileGrid(
          children: [
            ReportKpi(
              icon: AppIcons.people,
              tone: Tone.info,
              label: l10n.reportsEnrolments,
              kpi: kpis.enrollments,
              period: period,
            ),
            ReportKpi(
              icon: AppIcons.success,
              tone: Tone.accent,
              label: l10n.reportsCompletionRate,
              kpi: kpis.completionRate,
              period: period,
            ),
            ReportKpi(
              icon: AppIcons.rocket,
              tone: Tone.accent,
              label: l10n.reportsActiveLearners,
              kpi: kpis.activeLearners,
              period: period,
            ),
            ReportKpi(
              icon: AppIcons.chart,
              tone: Tone.info,
              label: l10n.reportsAvgProgress,
              kpi: kpis.avgProgress,
              period: period,
            ),
          ],
        ),
        const SizedBox(height: Space.sectionGap),
        ReportSeriesView(title: l10n.reportsSeriesEnrolments, points: report.series.enrollments),
        const SizedBox(height: Space.s4),
        ReportSeriesView(title: l10n.reportsSeriesCompletions, points: report.series.completions),
        const SizedBox(height: Space.sectionGap),
        ReportBands(
          title: l10n.reportsCourseFunnelTitle,
          icon: AppIcons.people,
          hue: Hue.green,
          bands: report.funnel,
          valueLabel: (value) => l10n.reportsBandLearners(value.toInt()),
        ),
        if (report.chapters.isNotEmpty) ...[
          const SizedBox(height: Space.sectionGap),
          ReportSection(
            title: l10n.reportsCourseChaptersTitle,
            icon: AppIcons.learning,
            hue: Hue.blue,
          ),
          GroupedList(
            children: [
              for (final chapter in report.chapters)
                AppListTile(
                  title: chapter.title,
                  subtitle: chapter.reached == null
                      ? l10n.reportsNoFigure
                      : l10n.reportsCourseChapterReached(chapter.reached!),
                ),
            ],
          ),
        ],
        if (report.quizzes.isNotEmpty) ...[
          const SizedBox(height: Space.sectionGap),
          ReportSection(
            title: l10n.reportsCourseQuizzesTitle,
            icon: AppIcons.quiz,
            hue: Hue.orange,
          ),
          GroupedList(
            children: [
              for (final quiz in report.quizzes)
                AppListTile(
                  title: quiz.title,
                  subtitle: l10n.reportsQuizSummary(quiz.attempts, quiz.passRate ?? 0),
                  trailing: Text(
                    figureOr(l10n, quiz.avgScore, percent: true),
                    style: context.type.label,
                  ),
                ),
            ],
          ),
        ],
        if (report.assignments.isNotEmpty) ...[
          const SizedBox(height: Space.sectionGap),
          ReportSection(
            title: l10n.reportsCourseAssignmentsTitle,
            icon: AppIcons.assignment,
            hue: Hue.pink,
          ),
          GroupedList(
            children: [
              for (final assignment in report.assignments)
                AppListTile(
                  title: assignment.title,
                  subtitle: l10n.reportsAssignmentSummary(
                    assignment.submitted,
                    assignment.passRate ?? 0,
                  ),
                  trailing: Text(
                    figureOr(l10n, assignment.onTime, percent: true),
                    style: context.type.label,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
