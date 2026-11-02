import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/web_path_mapper.dart';
import '../../../../core/auth/capabilities.dart';
import '../../../../core/format/dates_ist.dart';
import '../../../../core/format/durations.dart';
import '../../../../core/format/figures.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/live_class.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/auth.dart';
import '../../application/dashboard_controller.dart';
import '../widgets/dashboard_sections.dart';

/// `/staff` — what needs attention now, then how things are going (LMS-001, §18). Every figure is
/// the server's; the app arranges them and says which way they moved using the academy's own rule.
/// A shell body.
class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(dashboardProvider.future),
      child: AsyncView<DashboardSnapshot>(
        value: ref.watch(dashboardProvider),
        onRetry: () => ref.invalidate(dashboardProvider),
        skeleton: const DelayedLoading(skeleton: SkeletonDashboard()),
        data: (snapshot) => _Dashboard(snapshot: snapshot),
      ),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final profile = ref.watch(currentUserProvider);
    final role = profile?.role ?? UserRole.unknown;
    final titles = ref.watch(dashboardCourseTitlesProvider).value ?? const <String, String>{};
    final wide = !WindowSize.of(context).isCompact;
    // An admin looking at the whole academy reads its trends too; an instructor (or an admin
    // looking at one instructor) gets the teaching view, without the enrolment charts.
    final academyView = snapshot.scope.isAcademy;

    void open(String? webPath) {
      final target = WebPathMapper.map(webPath, role);
      if (target != null) GoRouter.of(context).go(target);
    }

    Widget header(String title, IconData icon, Hue hue, {String? action, VoidCallback? onAction}) =>
        SectionHeader(
          title: title,
          icon: icon,
          iconColor: c.hue(hue).solid,
          actionLabel: action,
          onAction: onAction,
        );

    final sections = <Widget>[
      if (canChooseScope(profile)) ...[const _ScopePicker(), const SizedBox(height: Space.s4)],
      _Hero(snapshot: snapshot),
      // Phone order: what is next, what needs doing, what to do, then how things are going.
      if (snapshot.upcomingLive.isNotEmpty) ...[
        const SizedBox(height: Space.sectionGap),
        header(
          l10n.dashboardUpcomingLiveTitle,
          AppIcons.live,
          Hue.pink,
          action: l10n.actionSeeAll,
          onAction: () => GoRouter.of(context).go(AppRoutes.staffLive),
        ),
        _UpcomingLive(classes: snapshot.upcomingLive, onOpen: (id) => open('/live/$id')),
      ],
      const SizedBox(height: Space.sectionGap),
      header(l10n.dashboardAttentionTitle, AppIcons.notifications, Hue.orange),
      if (snapshot.attention.isEmpty)
        AppCard(
          child: Row(
            children: [
              const IconTile(icon: AppIcons.success),
              const SizedBox(width: Space.s3),
              Expanded(
                child: Text(
                  l10n.dashboardAttentionEmpty,
                  style: context.type.bodyM.copyWith(color: c.muted),
                ),
              ),
            ],
          ),
        )
      else
        GroupedList(
          children: [
            for (final item in snapshot.attention)
              AttentionCard(
                item: item,
                onOpen: WebPathMapper.map(item.to, role) == null ? null : () => open(item.to),
              ),
          ],
        ),
      const SizedBox(height: Space.sectionGap),
      header(l10n.dashboardQuickActionsTitle, AppIcons.add, Hue.violet),
      _QuickActions(role: role),
      if (snapshot.courses.isNotEmpty) ...[
        const SizedBox(height: Space.sectionGap),
        header(
          l10n.dashboardCoursesTitle,
          AppIcons.courses,
          Hue.blue,
          action: snapshot.courses.length > _courseLimit ? l10n.actionSeeAll : null,
          onAction: () => GoRouter.of(context).go(AppRoutes.staffCourses),
        ),
        for (final performance in snapshot.courses.take(_courseLimit)) ...[
          CoursePerformanceCard(
            performance: performance,
            title: titles[performance.courseId] ?? l10n.dashboardCoursesTitle,
            onOpen: () => open('/teach/courses/${performance.courseId}'),
          ),
          const SizedBox(height: Space.s3),
        ],
      ],
      const SizedBox(height: Space.sectionGap),
      header(l10n.dashboardKpisTitle, AppIcons.reports, Hue.green),
      _Kpis(snapshot: snapshot, role: role),
      if (academyView) ...[
        const SizedBox(height: Space.sectionGap),
        header(l10n.dashboardTrendsTitle, AppIcons.reports, Hue.violet),
        TrendChart(
          title: l10n.dashboardTrendEnrollments,
          points: [
            for (final point in snapshot.enrollments)
              ChartPoint(_weekLabel(point), point.value.toDouble(), formatFigure(point.value)),
          ],
        ),
        const SizedBox(height: Space.s3),
        TrendChart(
          title: l10n.dashboardTrendCompletions,
          points: [
            for (final point in snapshot.completions)
              ChartPoint(_weekLabel(point), point.value.toDouble(), formatFigure(point.value)),
          ],
        ),
      ],
      const SizedBox(height: Space.sectionGap),
      header(l10n.dashboardEngagementTitle, AppIcons.people, Hue.blue),
      _Engagement(engagement: snapshot.engagement),
      const SizedBox(height: Space.sectionGap),
      header(l10n.dashboardActivityTitle, AppIcons.date, Hue.gold),
      if (snapshot.events.isEmpty)
        AppCard(
          child: Text(
            l10n.dashboardActivityEmpty,
            style: context.type.bodyM.copyWith(color: c.muted),
          ),
        )
      else
        GroupedList(
          children: [
            for (final event in snapshot.events.take(_eventLimit))
              DashboardEventRow(
                event: event,
                onOpen: WebPathMapper.map(event.to, role) == null ? null : () => open(event.to),
              ),
          ],
        ),
      const SizedBox(height: Space.s4),
      Text(
        l10n.dashboardGeneratedAt(DatesIst.dateTime(l10n, snapshot.generatedAt)),
        style: context.type.caption.copyWith(color: c.muted),
      ),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        wide ? Space.gutterMedium : Space.s4,
        Space.s3,
        wide ? Space.gutterMedium : Space.s4,
        Space.s6,
      ),
      children: sections,
    );
  }

  String _weekLabel(TrendPoint point) {
    final day = point.day;
    return day == null ? point.date : DatesIst.shortDate(day);
  }
}

/// How many courses and events the dashboard shows before "See all" takes over.
const _courseLimit = 3;
const _eventLimit = 6;

/// The next class on its own card, then — quieter — the two after it.
class _UpcomingLive extends StatelessWidget {
  const _UpcomingLive({required this.classes, required this.onOpen});

  final List<LiveClass> classes;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final next = classes.first;
    final later = classes.skip(1).take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StripCard(
          strip: c.hue(Hue.pink),
          stripIcon: AppIcons.live,
          stripLabel: l10n.homeNextLiveTitle,
          title: next.title,
          facts: [
            MetaItem(
              icon: AppIcons.date,
              label: [
                DatesIst.dateTime(l10n, next.startsAt),
                AppDurations.minutes(l10n, next.durationMin),
              ].join(' · '),
            ),
          ],
          onTap: () => onOpen(next.id),
        ),
        if (later.isNotEmpty) ...[
          const SizedBox(height: Space.s3),
          GroupedList(
            children: [
              for (final live in later)
                AppListTile(
                  title: live.title,
                  subtitle: DatesIst.dateTime(l10n, live.startsAt),
                  meta: AppDurations.minutes(l10n, live.durationMin),
                  leading: const HueTile(icon: AppIcons.live, hue: Hue.pink),
                  showChevron: true,
                  onTap: () => onOpen(live.id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The academy admin's choice: the whole academy, or one instructor. An instructor never sees this
/// — the route scopes their dashboard to themselves whatever it is asked for (§7).
class _ScopePicker extends ConsumerWidget {
  const _ScopePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(dashboardViewProvider);
    final controller = ref.read(dashboardViewProvider.notifier);
    final instructors = ref.watch(dashboardInstructorsProvider).value ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(l10n.dashboardScopeAcademy)),
            ButtonSegment(value: false, label: Text(l10n.dashboardScopeInstructor)),
          ],
          selected: {view.isAcademy},
          showSelectedIcon: false,
          onSelectionChanged: (values) {
            if (values.first) {
              controller.showAcademy();
            } else if (instructors.isNotEmpty) {
              controller.showInstructor(instructors.first.id);
            }
          },
        ),
        if (!view.isAcademy && instructors.isNotEmpty) ...[
          const SizedBox(height: Space.s2),
          FilterChipBar<String>(
            padding: EdgeInsets.zero,
            options: [
              for (final instructor in instructors) FilterOption(instructor.id, instructor.name),
            ],
            selected: view.instructorId ?? instructors.first.id,
            onSelected: controller.showInstructor,
          ),
        ],
      ],
    );
  }
}

/// What a staff member does next, each offered only to someone the academy lets do it (§7).
class _QuickActions extends ConsumerWidget {
  const _QuickActions({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(currentUserProvider);
    void go(String route) => GoRouter.of(context).go(route);

    final actions = <(String, IconData, VoidCallback, Hue)>[
      if (can(profile, Capability.manageLive))
        (l10n.dashboardActionScheduleLive, AppIcons.live, () => go(AppRoutes.staffLive), Hue.pink),
      if (can(profile, Capability.gradeSubmissions))
        (l10n.dashboardActionReview, AppIcons.review, () => go(AppRoutes.staffReview), Hue.orange),
      if (can(profile, Capability.viewLearners))
        (
          l10n.dashboardActionStudents,
          AppIcons.people,
          () => go(AppRoutes.staffStudents),
          Hue.green,
        ),
    ];
    if (actions.isEmpty) return const SizedBox.shrink();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: Space.s3),
            Expanded(
              child: QuickActionTile(
                label: actions[i].$1,
                icon: actions[i].$2,
                onTap: actions[i].$3,
                hue: actions[i].$4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.snapshot, required this.role});

  final DashboardSnapshot snapshot;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kpis = snapshot.kpis;
    // The third figure is the academy's instructors, or this instructor's review queue.
    final thirdLabel = snapshot.scope.isAcademy
        ? l10n.dashboardKpiInstructors
        : l10n.dashboardKpiWaitingReview;
    return TileGrid(
      children: [
        DashboardKpi(label: l10n.dashboardKpiCourses, kpi: kpis.courses, icon: AppIcons.courses),
        DashboardKpi(
          label: l10n.dashboardKpiStudents,
          kpi: kpis.students,
          icon: AppIcons.people,
          tone: Tone.info,
        ),
        DashboardKpi(
          icon: snapshot.scope.isAcademy ? AppIcons.instructor : AppIcons.review,
          tone: Tone.warn,
          label: thirdLabel,
          kpi: kpis.third,
          // A growing review queue is not good news.
          higherIsBetter: snapshot.scope.isAcademy,
        ),
        DashboardKpi(
          label: l10n.dashboardKpiCompletion,
          kpi: kpis.completionRate,
          icon: AppIcons.success,
        ),
      ],
    );
  }
}

class _Engagement extends StatelessWidget {
  const _Engagement({required this.engagement});

  final EngagementKpis engagement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TileGrid(
      children: [
        DashboardKpi(
          label: l10n.dashboardEngagementLessons,
          kpi: engagement.lessonsCompleted,
          icon: AppIcons.lessonReading,
        ),
        DashboardKpi(
          label: l10n.dashboardEngagementQuizzes,
          kpi: engagement.quizAttempts,
          icon: AppIcons.quiz,
          tone: Tone.info,
        ),
        DashboardKpi(
          label: l10n.dashboardEngagementSubmissions,
          kpi: engagement.submissions,
          icon: AppIcons.assignment,
          tone: Tone.warn,
        ),
        DashboardKpi(
          label: l10n.dashboardEngagementLive,
          kpi: engagement.liveAttendance,
          icon: AppIcons.live,
          tone: Tone.danger,
        ),
      ],
    );
  }
}

/// The dashboard's lead: three figures on a plain card, each the server's own number and each a
/// way into what it counts. An instructor (or an admin looking at one instructor) leads with the
/// marking waiting for them; the academy view leads with its learners and courses.
class _Hero extends ConsumerWidget {
  const _Hero({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(currentUserProvider);
    void Function()? goIf(Capability? capability, String route) =>
        capability == null || can(profile, capability)
        ? () => GoRouter.of(context).go(route)
        : null;

    final live = StatFigure(
      value: formatFigure(snapshot.upcomingLive.length),
      label: l10n.dashboardHeroLive,
      icon: AppIcons.live,
      hue: Hue.pink,
      onTap: goIf(null, AppRoutes.staffLive),
    );
    final learners = StatFigure(
      value: formatFigure(snapshot.kpis.students.value),
      label: l10n.dashboardKpiStudents,
      icon: AppIcons.people,
      hue: Hue.green,
      onTap: goIf(Capability.viewLearners, AppRoutes.staffStudents),
    );
    final figures = snapshot.scope.isAcademy
        ? [
            learners,
            StatFigure(
              value: formatFigure(snapshot.kpis.courses.value),
              label: l10n.dashboardKpiCourses,
              icon: AppIcons.courses,
              hue: Hue.blue,
              onTap: goIf(Capability.viewCourses, AppRoutes.staffCourses),
            ),
            live,
          ]
        : [
            StatFigure(
              value: formatFigure(snapshot.kpis.third.value),
              label: l10n.dashboardKpiWaitingReview,
              icon: AppIcons.review,
              hue: Hue.orange,
              onTap: goIf(Capability.viewAssessments, AppRoutes.staffReview),
            ),
            live,
            learners,
          ];
    return StatSummaryCard(figures: figures);
  }
}
