import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/capabilities.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/figures.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../staff_courses/staff_courses.dart';
import '../../../staff_instructors/staff_instructors.dart';
import '../../application/staff_reports_controller.dart';

/// How a period reads on screen.
String rangeLabel(AppLocalizations l10n, ReportRange range) => switch (range) {
  ReportRange.thirtyDays => l10n.reportsRange30d,
  ReportRange.ninetyDays => l10n.reportsRange90d,
  ReportRange.sixMonths => l10n.reportsRange6m,
  ReportRange.twelveMonths => l10n.reportsRange12m,
};

/// The same period said plainly, for the comparison line: "vs the previous 90 days" reads properly
/// where "vs the previous Last 90 days" does not.
String periodLabel(AppLocalizations l10n, ReportRange range) => switch (range) {
  ReportRange.thirtyDays => l10n.reportsPeriod30d,
  ReportRange.ninetyDays => l10n.reportsPeriod90d,
  ReportRange.sixMonths => l10n.reportsPeriod6m,
  ReportRange.twelveMonths => l10n.reportsPeriod12m,
};

/// How a learner segment reads on screen.
String segmentLabel(AppLocalizations l10n, LearnerSegment segment) => switch (segment) {
  LearnerSegment.all || LearnerSegment.unknown => l10n.reportsSegmentAll,
  LearnerSegment.newcomers => l10n.reportsSegmentNew,
  LearnerSegment.active => l10n.reportsSegmentActive,
  LearnerSegment.atRisk => l10n.reportsSegmentAtRisk,
  LearnerSegment.inactive => l10n.reportsSegmentInactive,
  LearnerSegment.completers => l10n.reportsSegmentCompleters,
};

/// How an enrolment source reads on screen — the route's own words, in the app's language.
String sourceLabel(AppLocalizations l10n, String source) => switch (source) {
  'self' => l10n.reportsSourceSelf,
  'admin' => l10n.reportsSourceAdmin,
  'import' => l10n.reportsSourceImport,
  'gift' => l10n.reportsSourceGift,
  'purchase' => l10n.reportsSourcePurchase,
  _ => source,
};

/// A figure, or a dash where the academy sent nothing to show.
String figureOr(AppLocalizations l10n, num? value, {bool percent = false}) =>
    value == null ? l10n.reportsNoFigure : (percent ? '$value%' : formatFigure(value));

/// The line under every report title: the period, how many courses it covers, and how many filters
/// are narrowing it.
class ReportHeader extends ConsumerWidget {
  const ReportHeader({required this.title, required this.courseCount, super.key});

  final String title;
  final int courseCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(reportFilterProvider);
    final narrowed = narrowedBy(query);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(header: true, child: Text(title, style: context.type.titleL)),
            ),
            const SizedBox(width: Space.s2),
            // The list pages' Filters button, counting what narrows the reports now.
            FiltersButton(active: narrowed, onPressed: () => showReportFilters(context)),
          ],
        ),
        const SizedBox(height: Space.s1),
        Text(
          [
            l10n.reportsCovering(rangeLabel(l10n, query.range), courseCount),
            if (narrowed > 0) l10n.reportsNarrowedBy(narrowed),
          ].join(' · '),
          style: context.type.caption.copyWith(color: context.colors.muted),
        ),
      ],
    );
  }
}

/// The period, segment, category, course and instructor every tab shares.
Future<void> showReportFilters(BuildContext context) =>
    showAppBottomSheet<void>(context, builder: (_) => const _FilterSheet());

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(reportFilterProvider);
    final controller = ref.read(reportFilterProvider.notifier);
    final courses = ref.watch(staffCoursesProvider).value?.rows ?? const [];
    // Only an admin may report on someone else's teaching; the route ignores it for anyone else.
    final mayPickInstructor = watchCan(ref, Capability.viewInstructorReport);
    final instructors = mayPickInstructor
        ? (ref.watch(instructorDirectoryProvider).value?.rows ?? const <InstructorRow>[])
        : const <InstructorRow>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s4),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.reportsFiltersTitle, style: context.type.titleM),
            const SizedBox(height: Space.s4),
            AppSelectField<ReportRange>(
              label: l10n.reportsRangeLabel,
              value: query.range,
              onChanged: controller.overPeriod,
              options: [
                for (final range in reportRanges) SelectOption(range, rangeLabel(l10n, range)),
              ],
            ),
            const SizedBox(height: Space.s3),
            AppSelectField<LearnerSegment>(
              label: l10n.reportsSegmentLabel,
              value: query.segment ?? LearnerSegment.all,
              onChanged: controller.forSegment,
              options: [
                for (final segment in LearnerSegment.values)
                  if (segment != LearnerSegment.unknown)
                    SelectOption(segment, segmentLabel(l10n, segment)),
              ],
            ),
            if (courses.isNotEmpty) ...[
              const SizedBox(height: Space.s3),
              AppSelectField<String>(
                label: l10n.reportsCourseLabel,
                value: query.courseId ?? '',
                onChanged: (value) => controller.inCourse(value.isEmpty ? null : value),
                options: [
                  SelectOption('', l10n.reportsAllCourses),
                  for (final course in courses) SelectOption(course.id, course.title),
                ],
              ),
            ],
            if (instructors.isNotEmpty) ...[
              const SizedBox(height: Space.s3),
              AppSelectField<String>(
                label: l10n.reportsInstructorLabel,
                value: query.instructorId ?? '',
                onChanged: (value) => controller.byInstructor(value.isEmpty ? null : value),
                options: [
                  SelectOption('', l10n.reportsAllInstructors),
                  for (final row in instructors)
                    SelectOption(row.instructor.id, row.instructor.name),
                ],
              ),
            ],
            const SizedBox(height: Space.s4),
            AppButton(
              label: l10n.reportsApplyFilters,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: Space.s2),
            AppButton(
              label: l10n.reportsClearFilters,
              variant: AppButtonVariant.tertiary,
              onPressed: () {
                controller.clear();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A headline figure with the academy's own previous-period comparison.
class ReportKpi extends StatelessWidget {
  const ReportKpi({
    required this.label,
    required this.kpi,
    required this.period,
    super.key,
    this.icon,
    this.tone = Tone.accent,
  });

  final String label;
  final IconData? icon;
  final Tone tone;
  final Kpi kpi;

  /// The period this is compared with, in words.
  final String period;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final change = kpiChange(kpi);
    final signed = switch (change.direction) {
      TrendDirection.up => change.amount,
      TrendDirection.down => -change.amount,
      TrendDirection.flat => 0.0,
    };
    return KpiTile(
      icon: icon,
      tone: tone,
      label: label,
      value: kpi.isRate ? '${formatFigure(kpi.value)}%' : formatFigure(kpi.value),
      delta: signed,
      // A rate moves in percentage points, a count in percent — the academy's own rule (§18).
      deltaUnit: change.isPoints ? ' pts' : '%',
      comparisonLabel: l10n.reportsComparedWith(period),
    );
  }
}

/// A series the academy measured, drawn and then written out — every chart is readable as a list, so
/// it still works at 200% text and to a screen reader (§16, §19).
class ReportSeriesView extends StatelessWidget {
  const ReportSeriesView({required this.title, required this.points, super.key});

  final String title;
  final List<ReportSeriesPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrendChart(
          title: title,
          points: [
            for (final point in points)
              ChartPoint(
                DatesIst.shortDate(point.from),
                point.value.toDouble(),
                '${DatesIst.shortDate(point.from)}: ${formatFigure(point.value)}',
              ),
          ],
        ),
        const SizedBox(height: Space.s2),
        _ReadOut(
          title: l10n.reportsReadOut,
          rows: [
            for (final point in points) (DatesIst.shortDate(point.from), formatFigure(point.value)),
          ],
        ),
      ],
    );
  }
}

/// The list behind a chart, collapsed until it is asked for.
class _ReadOut extends StatelessWidget {
  const _ReadOut({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: Text(title, style: context.type.label),
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: Space.s2),
    children: [KeyValueTable(rows: rows)],
  );
}

/// The mark a report section's header carries: its icon in the hue of what it is about.
class ReportSection extends StatelessWidget {
  const ReportSection({
    required this.title,
    required this.icon,
    required this.hue,
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final IconData icon;
  final Hue hue;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => SectionHeader(
    title: title,
    icon: icon,
    iconColor: context.colors.hue(hue).solid,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

/// A ranked list of labelled counts — a progress band, a funnel, a category.
class ReportBands extends StatelessWidget {
  const ReportBands({
    required this.title,
    required this.bands,
    super.key,
    this.valueLabel,
    this.icon = AppIcons.chart,
    this.hue = Hue.violet,
  });

  final String title;
  final List<LabelledCount> bands;
  final IconData icon;
  final Hue hue;

  /// How each value reads; the count itself by default.
  final String Function(num value)? valueLabel;

  @override
  Widget build(BuildContext context) {
    if (bands.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportSection(title: title, icon: icon, hue: hue),
        BarList(
          points: [
            for (final band in bands)
              ChartPoint(
                band.label,
                band.value.toDouble(),
                valueLabel?.call(band.value) ?? formatFigure(band.value),
              ),
          ],
        ),
      ],
    );
  }
}

/// A row of figures that share a heading — the quiz, assignment and engagement blocks.
class ReportFigureGroup extends StatelessWidget {
  const ReportFigureGroup({
    required this.title,
    required this.figures,
    required this.period,
    required this.icon,
    required this.hue,
    super.key,
  });

  final String title;
  final IconData icon;
  final Hue hue;
  final List<(String label, Kpi kpi)> figures;
  final String period;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ReportSection(title: title, icon: icon, hue: hue),
      Wrap(
        spacing: Space.s3,
        runSpacing: Space.s3,
        children: [
          for (final (label, kpi) in figures) ReportKpi(label: label, kpi: kpi, period: period),
        ],
      ),
    ],
  );
}

/// One course's figures, as a card rather than a table row (§20): a strip in the courses hue with
/// its category, then its title, who teaches it and the academy's figures for it.
class CourseReportCard extends StatelessWidget {
  const CourseReportCard({required this.row, required this.onOpen, super.key});

  final CourseReportRow row;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return StripCard(
      onTap: onOpen,
      strip: context.colors.hue(AppNavIcons.of(AppIcons.courses).hue),
      stripIcon: AppIcons.courses,
      stripLabel: row.categoryTitle.isEmpty ? l10n.reportsTabCourses : row.categoryTitle,
      title: row.title,
      subtitle: row.instructorNames.isEmpty ? null : row.instructorNames.join(', '),
      facts: [
        MetaItem(
          icon: AppIcons.people,
          label: [
            l10n.reportsCourseEnrolments(row.enrollments),
            l10n.reportsCoursePrevious(row.previousEnrollments),
          ].join(' · '),
        ),
        MetaItem(icon: AppIcons.rocket, label: l10n.reportsCourseActive(row.activeLearners)),
        MetaItem(
          icon: AppIcons.success,
          label: [
            l10n.reportsCourseCompletions(row.completions),
            if (row.completionRate case final rate?) '${l10n.reportsCompletionRate} $rate%',
          ].join(' · '),
        ),
        if (row.avgProgress case final progress?)
          MetaItem(icon: AppIcons.chart, label: '${l10n.reportsAvgProgress} $progress%'),
        if (row.rating case final rating?)
          MetaItem(icon: AppIcons.rating, label: l10n.reportsCourseRating(formatFigure(rating))),
      ],
      footer: row.trend.isEmpty
          ? null
          : Sparkline(
              values: [for (final value in row.trend) value.toDouble()],
              semanticLabel: l10n.reportsCourseEnrolments(row.enrollments),
            ),
    );
  }
}
