import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_reports_controller.dart';
import '../widgets/report_parts.dart';

/// `/staff/reports/enrolments` — where enrolments come from and how each month's intake gets on. A
/// cohort's `within30/60/90` is absent until the period has run long enough for it to mean anything;
/// the app shows a dash rather than a nought, which would read as nobody finishing (§18). A shell
/// body.
class EnrolmentsReportScreen extends ConsumerWidget {
  const EnrolmentsReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(enrolmentsReportProvider.future),
      child: AsyncView<EnrolmentsReport>(
        value: ref.watch(enrolmentsReportProvider),
        onRetry: () => ref.invalidate(enrolmentsReportProvider),
        data: (report) => _Enrolments(report: report),
      ),
    );
  }
}

class _Enrolments extends ConsumerWidget {
  const _Enrolments({required this.report});

  final EnrolmentsReport report;

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
        ReportHeader(title: l10n.reportsTabEnrolments, courseCount: report.courseCount),
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
              icon: AppIcons.explore,
              tone: Tone.info,
              label: l10n.reportsSelfShare,
              kpi: kpis.selfShare,
              period: period,
            ),
          ],
        ),
        const SizedBox(height: Space.sectionGap),
        ReportSeriesView(title: l10n.reportsSeriesEnrolments, points: report.series.enrollments),
        const SizedBox(height: Space.s4),
        ReportSeriesView(title: l10n.reportsSeriesCompletions, points: report.series.completions),
        if (report.sources.isNotEmpty) ...[
          const SizedBox(height: Space.sectionGap),
          ReportSection(title: l10n.reportsSourcesTitle, icon: AppIcons.explore, hue: Hue.blue),
          GroupedList(
            children: [
              for (final source in report.sources)
                AppListTile(
                  title: sourceLabel(l10n, source.source),
                  subtitle: l10n.reportsSourceSummary(source.enrollments, source.share ?? 0),
                  trailing: Text(
                    figureOr(l10n, source.completionRate, percent: true),
                    style: context.type.label,
                  ),
                ),
            ],
          ),
        ],
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
        if (report.cohorts.isNotEmpty) ...[
          const SizedBox(height: Space.sectionGap),
          ReportSection(title: l10n.reportsCohortsTitle, icon: AppIcons.calendar, hue: Hue.green),
          for (final cohort in report.cohorts) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(cohort.month, style: context.type.titleS)),
                      Text(
                        l10n.reportsCohortEnrolled(cohort.enrolled),
                        style: context.type.caption.copyWith(color: context.colors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.s2),
                  KeyValueTable(
                    rows: [
                      (
                        l10n.reportsCohortWithin(30),
                        figureOr(l10n, cohort.within30, percent: true),
                      ),
                      (
                        l10n.reportsCohortWithin(60),
                        figureOr(l10n, cohort.within60, percent: true),
                      ),
                      (
                        l10n.reportsCohortWithin(90),
                        figureOr(l10n, cohort.within90, percent: true),
                      ),
                      (l10n.reportsCohortToDate, figureOr(l10n, cohort.toDate, percent: true)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.s3),
          ],
        ],
      ],
    );
  }
}
