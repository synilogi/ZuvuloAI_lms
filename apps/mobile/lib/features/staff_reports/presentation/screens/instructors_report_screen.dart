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

/// `/staff/reports/instructors` — how the teaching is going. This one is an admin's: the route asks
/// for `reports.instructors.view` **and** the `reports.advanced` feature, and its refusal is shown as
/// what it is — a plan that does not include this report, or a permission this account lacks — never
/// as an error to retry (§6, §9). A shell body.
class InstructorsReportScreen extends ConsumerWidget {
  const InstructorsReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(instructorsReportProvider.future),
      child: AsyncView<InstructorsReport>(
        value: ref.watch(instructorsReportProvider),
        onRetry: () => ref.invalidate(instructorsReportProvider),
        data: (report) => _Instructors(report: report),
      ),
    );
  }
}

class _Instructors extends ConsumerWidget {
  const _Instructors({required this.report});

  final InstructorsReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final gutter = WindowSize.of(context).isCompact ? Space.s4 : Space.gutterMedium;
    final period = periodLabel(l10n, ref.watch(reportFilterProvider).range);
    final figures = report.figures;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, Space.s4, gutter, Space.s6),
      children: [
        ReportHeader(title: l10n.reportsTabInstructors, courseCount: report.courseCount),
        const SizedBox(height: Space.s4),
        TileGrid(
          children: [
            ReportKpi(
              icon: AppIcons.review,
              tone: Tone.warn,
              label: l10n.reportsInstructorReviews,
              kpi: figures.reviews,
              period: period,
            ),
            ReportKpi(
              icon: AppIcons.review,
              tone: Tone.warn,
              label: l10n.reportsInstructorReviewHours,
              kpi: figures.reviewHours,
              period: period,
            ),
            ReportKpi(
              icon: AppIcons.time,
              tone: Tone.warn,
              label: l10n.reportsInstructorOnTime,
              kpi: figures.onTime,
              period: period,
            ),
            ReportKpi(
              icon: AppIcons.chart,
              tone: Tone.accent,
              label: l10n.reportsInstructorAttendance,
              kpi: figures.attendance,
              period: period,
            ),
          ],
        ),
        const SizedBox(height: Space.sectionGap),
        ReportSection(
          title: l10n.reportsInstructorsTitle,
          icon: AppIcons.instructor,
          hue: AppNavIcons.of(AppIcons.instructor).hue,
        ),
        if (report.rows.isEmpty)
          EmptyState(title: l10n.reportsTabInstructors, message: l10n.reportsInstructorsEmpty)
        else
          for (final row in report.rows) ...[
            StripCard(
              onTap: () => GoRouter.of(context).go(AppRoutes.staffInstructor(row.instructorId)),
              strip: c.hue(AppNavIcons.of(AppIcons.instructor).hue),
              stripIcon: AppIcons.instructor,
              stripLabel: l10n.reportsInstructorSummary(row.courses, row.learners),
              title: row.name,
              subtitle: row.title,
              facts: [
                if (row.rating case final rating?)
                  MetaItem(
                    icon: AppIcons.rating,
                    label: l10n.reportsCourseRating(formatFigure(rating)),
                  ),
              ],
              footer: KeyValueTable(
                rows: [
                  (l10n.reportsCompletionRate, figureOr(l10n, row.completionRate, percent: true)),
                  (l10n.reportsInstructorReviews, '${row.reviews}'),
                  (l10n.reportsInstructorReviewHours, figureOr(l10n, row.reviewHours)),
                  (l10n.reportsInstructorOnTime, figureOr(l10n, row.onTime, percent: true)),
                  (l10n.reportsLiveAttendance, figureOr(l10n, row.attendance, percent: true)),
                ],
              ),
            ),
            const SizedBox(height: Space.s3),
          ],
      ],
    );
  }
}
