import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_reports_controller.dart';
import '../widgets/report_parts.dart';

/// `/staff/reports` — the academy's headline figures (LMS-015). Every number, band and ranking is the
/// route's own arithmetic over the period the filters name; the app formats and draws them, and each
/// chart is written out as a list beside it (§18, §19). A shell body.
class ReportsOverviewScreen extends ConsumerWidget {
  const ReportsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(overviewReportProvider.future),
      child: AsyncView<OverviewReport>(
        value: ref.watch(overviewReportProvider),
        onRetry: () => ref.invalidate(overviewReportProvider),
        data: (report) => _Overview(report: report),
      ),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview({required this.report});

  final OverviewReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final gutter = WindowSize.of(context).isCompact ? Space.s4 : Space.gutterMedium;
    final period = periodLabel(l10n, ref.watch(reportFilterProvider).range);
    final kpis = report.kpis;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
      children: [
        ReportHeader(title: l10n.reportsTabOverview, courseCount: report.courseCount),
        const SizedBox(height: Space.s4),
        if (kpis.enrollments.value == 0 && kpis.activeLearners.value == 0)
          EmptyState(title: l10n.reportsEmptyTitle, message: l10n.reportsEmptyBody)
        else ...[
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
                label: l10n.reportsCompletions,
                kpi: kpis.completions,
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
          ReportSeriesView(title: l10n.reportsSeriesActive, points: report.series.activeLearners),
          const SizedBox(height: Space.sectionGap),
          ReportFigureGroup(
            title: l10n.reportsQuizzesTitle,
            icon: AppIcons.quiz,
            hue: Hue.orange,
            period: period,
            figures: [
              (l10n.reportsQuizAttempts, report.quizzes.attempts),
              (l10n.reportsPassRate, report.quizzes.passRate),
              (l10n.reportsAvgScore, report.quizzes.avgScore),
            ],
          ),
          const SizedBox(height: Space.sectionGap),
          ReportFigureGroup(
            title: l10n.reportsAssignmentsTitle,
            icon: AppIcons.assignment,
            hue: Hue.pink,
            period: period,
            figures: [
              (l10n.reportsSubmitted, report.assignments.submitted),
              (l10n.reportsPassRate, report.assignments.passRate),
              (l10n.reportsOnTime, report.assignments.onTime),
              (l10n.reportsReviewHours, report.assignments.reviewHours),
            ],
          ),
          const SizedBox(height: Space.sectionGap),
          ReportFigureGroup(
            title: l10n.reportsEngagementTitle,
            icon: AppIcons.learning,
            hue: Hue.blue,
            period: period,
            figures: [
              (l10n.reportsLessonsCompleted, report.engagement.lessonsCompleted),
              (l10n.reportsLessonsPerLearner, report.engagement.lessonsPerLearner),
              (l10n.reportsLiveAttendance, report.engagement.liveAttendance),
            ],
          ),
          const SizedBox(height: Space.sectionGap),
          ReportBands(
            title: l10n.reportsProgressBandsTitle,
            icon: AppIcons.people,
            hue: Hue.green,
            bands: report.progressBands,
            valueLabel: (value) => l10n.reportsBandLearners(value.toInt()),
          ),
          if (report.categories.isNotEmpty) ...[
            const SizedBox(height: Space.sectionGap),
            ReportSection(title: l10n.reportsCategoriesTitle, icon: AppIcons.list, hue: Hue.violet),
            GroupedList(
              children: [
                for (final category in report.categories)
                  AppListTile(
                    title: category.title,
                    subtitle: category.completionRate == null
                        ? l10n.reportsCategoryEnrolmentsOnly(category.enrollments)
                        : l10n.reportsCategoryEnrolments(
                            category.enrollments,
                            category.completionRate!,
                          ),
                  ),
              ],
            ),
          ],
          if (report.topCourses.isNotEmpty) ...[
            const SizedBox(height: Space.sectionGap),
            ReportSection(
              title: l10n.reportsTopCoursesTitle,
              icon: AppIcons.courses,
              hue: Hue.blue,
              actionLabel: l10n.reportsTabCourses,
              onAction: () => GoRouter.of(context).go(AppRoutes.staffReportsCourses),
            ),
            for (final row in report.topCourses) ...[
              CourseReportCard(
                row: row,
                onOpen: () => GoRouter.of(context).go(AppRoutes.staffReportsCourse(row.courseId)),
              ),
              const SizedBox(height: Space.s3),
            ],
          ],
        ],
      ],
    );
  }
}
