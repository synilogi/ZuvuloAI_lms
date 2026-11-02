import 'package:flutter/material.dart';

import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/figures.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/dashboard_controller.dart';

/// The tone an attention item carries, from the academy's own severity.
Tone attentionTone(AttentionSeverity severity) => switch (severity) {
  AttentionSeverity.high => Tone.danger,
  AttentionSeverity.medium => Tone.warn,
  AttentionSeverity.low || AttentionSeverity.unknown => Tone.info,
};

IconData attentionIcon(AttentionKind kind) => switch (kind) {
  AttentionKind.reviews => AppIcons.review,
  AttentionKind.atRisk => AppIcons.people,
  AttentionKind.staleDraft => AppIcons.edit,
  AttentionKind.capacity => AppIcons.live,
  AttentionKind.accessibility => AppIcons.eye,
  AttentionKind.unknown => AppIcons.notifications,
};

IconData eventIcon(AdminEventKind kind) => switch (kind) {
  AdminEventKind.enrollment => AppIcons.people,
  AdminEventKind.coursePublished || AdminEventKind.courseUpdated => AppIcons.courses,
  AdminEventKind.submission => AppIcons.assignment,
  AdminEventKind.certificate => AppIcons.certificate,
  AdminEventKind.instructor => AppIcons.instructor,
  AdminEventKind.review => AppIcons.review,
  AdminEventKind.liveScheduled => AppIcons.live,
  AdminEventKind.unknown => AppIcons.notifications,
};

/// One thing that needs doing, as a row of the dashboard's "Needs you" list. The academy wrote the
/// words and set the severity; the row only gives it a tone (on its mark and its count, not the
/// whole row) and a way in.
class AttentionCard extends StatelessWidget {
  const AttentionCard({required this.item, required this.onOpen, super.key});

  final AttentionItem item;

  /// Null when the academy pointed somewhere this app has no screen for (§5.4).
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = attentionTone(item.severity);
    final t = c.tone(tone);
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: attentionIcon(item.kind), tone: tone),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: context.type.titleS),
                const SizedBox(height: 2),
                Text(item.detail, style: context.type.bodyS.copyWith(color: c.muted)),
              ],
            ),
          ),
          if (item.count case final count?) ...[
            const SizedBox(width: Space.s2),
            Container(
              constraints: const BoxConstraints(minWidth: Space.s6),
              padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: 2),
              decoration: BoxDecoration(
                color: t.soft,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: context.type.label.copyWith(color: t.ink, fontWeight: FontWeight.w700),
              ),
            ),
          ],
          if (onOpen != null) ...[
            const SizedBox(width: Space.s2),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AppIcon(AppIcons.chevronRight, size: IconSizes.sm, color: c.faint),
            ),
          ],
        ],
      ),
    );
    return Semantics(
      button: onOpen != null,
      container: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onOpen, child: row),
      ),
    );
  }
}

/// A headline figure with the change the academy's own rule says it made.
class DashboardKpi extends StatelessWidget {
  const DashboardKpi({
    required this.label,
    required this.kpi,
    super.key,
    this.higherIsBetter = true,
    this.icon,
    this.tone = Tone.accent,
  });

  final String label;
  final Kpi kpi;
  final bool higherIsBetter;
  final IconData? icon;
  final Tone tone;

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
      // A count moves in percent, a rate in points — the academy's own rule (§18).
      deltaUnit: change.isPoints ? ' pts' : '%',
      comparisonLabel: l10n.dashboardComparison,
      higherIsBetter: higherIsBetter,
      footer: kpi.series.length > 1
          ? Sparkline(
              values: [for (final point in kpi.series) point.toDouble()],
              semanticLabel: l10n.dashboardSparkline(label, kpi.series.length),
              height: 28,
            )
          : null,
    );
  }
}

/// What has happened lately, in the academy's own sentences.
class DashboardEventRow extends StatelessWidget {
  const DashboardEventRow({required this.event, required this.onOpen, super.key, this.now});

  final AdminEvent event;
  final VoidCallback? onOpen;

  /// Overridable so a test does not depend on the clock.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppListTile(
      title: '${event.actor} ${event.summary}'.trim(),
      subtitle: event.context,
      meta: DatesIst.relative(l10n, event.at, now ?? DateTime.now()),
      leading: AppIcon(eventIcon(event.kind), color: context.colors.muted),
      showChevron: onOpen != null,
      onTap: onOpen,
    );
  }
}

/// How one course is doing, as the academy counted it.
class CoursePerformanceCard extends StatelessWidget {
  const CoursePerformanceCard({
    required this.performance,
    required this.title,
    super.key,
    this.onOpen,
  });

  final CoursePerformance performance;

  /// The course's own title, which the dashboard payload does not carry.
  final String title;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.type.titleS),
          const SizedBox(height: Space.s2),
          Text(
            l10n.dashboardCourseFacts(performance.enrolled, performance.active),
            style: context.type.bodyS.copyWith(color: c.muted),
          ),
          const SizedBox(height: Space.s1),
          Text(
            l10n.dashboardCourseProgress(
              formatFigure(performance.completionRate),
              formatFigure(performance.avgProgress),
            ),
            style: context.type.caption.copyWith(color: c.muted),
          ),
          if (performance.weeklyEnrollments.length > 1) ...[
            const SizedBox(height: Space.s2),
            Sparkline(
              values: [for (final week in performance.weeklyEnrollments) week.toDouble()],
              semanticLabel: l10n.dashboardSparkline(
                l10n.dashboardTrendEnrollments,
                performance.weeklyEnrollments.length,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
