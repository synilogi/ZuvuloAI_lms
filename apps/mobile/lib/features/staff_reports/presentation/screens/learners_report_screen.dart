import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/platform/clock.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_reports_controller.dart';
import '../widgets/report_parts.dart';

/// `/staff/reports/learners` — how the academy's learners are doing. The table is the academy's own
/// ordering: `sortKey` and `sortDirection` go back to it as two flat strings and the rows return in
/// that order, so the app never sorts a page it was handed (§18). A shell body.
class LearnersReportScreen extends ConsumerWidget {
  const LearnersReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(learnersReportProvider.future),
      child: AsyncView<LearnersReport>(
        value: ref.watch(learnersReportProvider),
        onRetry: () => ref.invalidate(learnersReportProvider),
        data: (report) => _Learners(report: report),
      ),
    );
  }
}

class _Learners extends ConsumerWidget {
  const _Learners({required this.report});

  final LearnersReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final gutter = WindowSize.of(context).isCompact ? Space.s4 : Space.gutterMedium;
    final period = periodLabel(l10n, ref.watch(reportFilterProvider).range);
    final table = ref.watch(learnerTableProvider);
    final controller = ref.read(learnerTableProvider.notifier);
    final now = ref.watch(clockProvider)();
    final kpis = report.kpis;
    final pages = (report.total / learnerReportPageSize).ceil();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
      children: [
        ReportHeader(title: l10n.reportsTabLearners, courseCount: report.courseCount),
        const SizedBox(height: Space.s4),
        TileGrid(
          children: [
            ReportKpi(
              icon: AppIcons.people,
              tone: Tone.info,
              label: l10n.reportsLearnersCount,
              kpi: kpis.learners,
              period: period,
            ),
            ReportKpi(
              icon: AppIcons.rocket,
              tone: Tone.accent,
              label: l10n.reportsLearnersActive,
              kpi: kpis.active,
              period: period,
            ),
            ReportKpi(
              icon: AppIcons.warning,
              tone: Tone.danger,
              label: l10n.reportsLearnersAtRisk,
              kpi: kpis.atRisk,
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
        ReportBands(
          title: l10n.reportsProgressBandsTitle,
          icon: AppIcons.people,
          hue: Hue.green,
          bands: report.progressBands,
          valueLabel: (value) => l10n.reportsBandLearners(value.toInt()),
        ),
        const SizedBox(height: Space.sectionGap),
        ReportSection(title: l10n.reportsStatusesTitle, icon: AppIcons.profile, hue: Hue.blue),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: Space.cardPadding, vertical: Space.s1),
          child: KeyValueTable(
            rows: [
              (l10n.reportsSegmentActive, '${report.statusCount('active')}'),
              (l10n.reportsSegmentAtRisk, '${report.statusCount('at-risk')}'),
              (l10n.reportsSegmentInactive, '${report.statusCount('inactive')}'),
            ],
          ),
        ),
        const SizedBox(height: Space.sectionGap),
        AppSearchField(
          hintText: l10n.reportsLearnerSearch,
          initialValue: table.search,
          onChanged: controller.searchFor,
        ),
        const SizedBox(height: Space.s3),
        Wrap(
          spacing: Space.s3,
          runSpacing: Space.s3,
          children: [
            AppSelectField<LearnerSortKey>(
              label: l10n.reportsSortLabel,
              value: table.sortKey,
              onChanged: controller.sortBy,
              options: [
                SelectOption(LearnerSortKey.progress, l10n.reportsSortProgress),
                SelectOption(LearnerSortKey.name, l10n.reportsSortName),
                SelectOption(LearnerSortKey.courses, l10n.reportsSortCourses),
                SelectOption(LearnerSortKey.assignments, l10n.reportsSortAssignments),
                SelectOption(LearnerSortKey.lastActive, l10n.reportsSortLastActive),
              ],
            ),
            // Asking for the column already shown turns the order around.
            AppButton(
              label: table.descending ? l10n.reportsSortDescending : l10n.reportsSortAscending,
              variant: AppButtonVariant.tertiary,
              icon: table.descending ? AppIcons.chevronDown : AppIcons.chevronUp,
              onPressed: () => controller.sortBy(table.sortKey),
            ),
          ],
        ),
        const SizedBox(height: Space.s4),
        if (report.rows.isEmpty)
          EmptyState(title: l10n.reportsTabLearners, message: l10n.reportsLearnersEmpty)
        else
          GroupedList(
            children: [
              for (final row in report.rows)
                AppListTile(
                  title: row.name,
                  subtitle: [
                    l10n.reportsLearnerCourses(row.courses, row.completed),
                    if (row.avgProgress case final progress?) l10n.reportsLearnerProgress(progress),
                    if (row.assignmentAvg case final average?)
                      l10n.reportsLearnerAssignments(average),
                    row.lastActiveAt == null
                        ? l10n.reportsLearnerNeverSeen
                        : l10n.reportsLearnerLastSeen(
                            DatesIst.relative(l10n, row.lastActiveAt!, now),
                          ),
                  ].join(' · '),
                  leading: AvatarInitials(name: row.name, size: AvatarSizes.sm),
                  onTap: () => GoRouter.of(context).go(AppRoutes.staffStudent(row.studentId)),
                ),
            ],
          ),
        PagerRow(page: table.page, pages: pages, onPage: controller.showPage),
      ],
    );
  }
}
