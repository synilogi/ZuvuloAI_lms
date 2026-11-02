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
import '../../../auth/auth.dart';
import '../../../staff_courses/staff_courses.dart';
import '../../../staff_dashboard/staff_dashboard.dart';
import '../../application/staff_calendar_controller.dart';
import '../widgets/calendar_parts.dart';

/// `/staff/calendar` — the academy's teaching schedule, agenda-first (LMS-013). Every event is the
/// academy's: live classes and deadlines are derived from their own records, and the counts on the
/// type chips cover the whole range in view. A shell body.
class StaffCalendarScreen extends ConsumerWidget {
  const StaffCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final window = WindowSize.of(context);
    final gutter = window.isCompact ? Space.s4 : Space.gutterMedium;
    final view = ref.watch(calendarViewProvider);
    final controller = ref.read(calendarViewProvider.notifier);
    final today = istDayOf(ref.watch(clockProvider)());
    // A tablet shows the month beside the day, and reads the month's range for it (§20).
    final showMonth = !window.isCompact;
    if (showMonth != view.wholeMonth) {
      // The range follows the layout, set once the first frame knows how wide it is.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.showWholeMonth(whole: showMonth),
      );
    }

    return FabLayout(
      fab: AppFab(
        label: l10n.calendarAddAction,
        icon: AppIcons.add,
        onPressed: () => GoRouter.of(context).go(AppRoutes.staffCalendarNew),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(calendarRangeProvider.future),
        child: AsyncView<CalendarPage>(
          value: ref.watch(calendarRangeProvider),
          onRetry: () => ref.invalidate(calendarRangeProvider),
          data: (page) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(gutter, Space.s3, gutter, FabLayout.clearance),
            children: [
              // The week (or month) in view and its days, on one card.
              AppCard(
                padding: const EdgeInsets.fromLTRB(Space.s2, Space.s1, Space.s2, Space.s3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(page: page, today: today),
                    const SizedBox(height: Space.s2),
                    if (showMonth)
                      MonthGrid(
                        days: istMonthGrid(view.day),
                        selected: view.day,
                        busy: page.busyDays,
                        today: today,
                        onPick: controller.showDay,
                      )
                    else
                      WeekStrip(
                        days: istWeekOf(view.day),
                        selected: view.day,
                        busy: page.busyDays,
                        today: today,
                        onPick: controller.showDay,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Space.s4),
              _TypeChips(page: page),
              const SizedBox(height: Space.s4),
              SectionHeader(
                title: DatesIst.longDay(view.day),
                icon: AppIcons.calendar,
                iconColor: context.colors.hue(AppNavIcons.of(AppIcons.calendar).hue).solid,
              ),
              _Agenda(page: page, day: view.day),
              if (page.isEmpty) ...[
                const SizedBox(height: Space.s4),
                Text(
                  l10n.calendarRangeEmptyBody,
                  style: context.type.caption.copyWith(color: context.colors.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Which week or month is in view, and the ways out of it.
class _Header extends ConsumerWidget {
  const _Header({required this.page, required this.today});

  final CalendarPage page;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(calendarViewProvider);
    final controller = ref.read(calendarViewProvider.notifier);

    return Row(
      children: [
        AppIconButton(
          icon: AppIcons.back,
          label: l10n.actionPrevious,
          onPressed: () => controller.moveWeeks(-1),
        ),
        Expanded(
          child: Text(
            l10n.calendarWeekOf(DatesIst.date(istWeekStart(view.day))),
            style: context.type.titleS,
            textAlign: TextAlign.center,
          ),
        ),
        TextButton(
          onPressed: view.day == today ? null : controller.showToday,
          child: Text(l10n.calendarToday),
        ),
        AppIconButton(
          icon: AppIcons.forward,
          label: l10n.actionNext,
          onPressed: () => controller.moveWeeks(1),
        ),
      ],
    );
  }
}

/// The types in the range, with the counts the route sent for the whole of it, and the course and
/// instructor filters behind the Filters button beside them.
class _TypeChips extends ConsumerWidget {
  const _TypeChips({required this.page});

  final CalendarPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(calendarViewProvider);
    final controller = ref.read(calendarViewProvider.notifier);
    final courses = ref.watch(staffCoursesProvider).value?.rows ?? const [];
    final admin = ref.watch(currentUserProvider)?.role == UserRole.admin;
    final instructors = admin
        ? ref.watch(dashboardInstructorsProvider).value ?? const []
        : const <({String id, String name})>[];
    final active = [view.courseId, view.instructorId].nonNulls.length;

    // Several types can be on at once, so this is a row of independent chips, not a FilterChipBar.
    // Clipped at its own edge: the Filters button sits beside it, and a chip scrolled past that
    // edge must not paint underneath the button.
    final chips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AppFilterChip(
            label: l10n.calendarTypeAll,
            selected: view.types.isEmpty,
            onTap: controller.showEveryType,
          ),
          for (final type in [
            CalendarEventType.live,
            CalendarEventType.assignment,
            CalendarEventType.quiz,
            CalendarEventType.milestone,
            CalendarEventType.reminder,
          ]) ...[
            const SizedBox(width: Space.s2),
            AppFilterChip(
              label: eventTypeLabel(l10n, type),
              count: page.countOf(type),
              selected: view.types.contains(type),
              onTap: () => controller.toggleType(type),
            ),
          ],
        ],
      ),
    );
    if (courses.isEmpty && instructors.isEmpty) return chips;
    return Row(
      children: [
        Expanded(child: chips),
        const SizedBox(width: Space.s2),
        FiltersButton(
          active: active,
          onPressed: () => showFilterSheet(
            context,
            builder: (_) => const _SheetFilters(),
            onClear: active == 0
                ? null
                : () {
                    controller
                      ..inCourse(null)
                      ..byInstructor(null);
                  },
          ),
        ),
      ],
    );
  }
}

/// The course and instructor filters, in the Filters sheet. They apply as they change.
class _SheetFilters extends ConsumerWidget {
  const _SheetFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(calendarViewProvider);
    final controller = ref.read(calendarViewProvider.notifier);
    final courses = ref.watch(staffCoursesProvider).value?.rows ?? const [];
    final admin = ref.watch(currentUserProvider)?.role == UserRole.admin;
    final instructors = admin
        ? ref.watch(dashboardInstructorsProvider).value ?? const []
        : const <({String id, String name})>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (courses.isNotEmpty)
          AppSelectField<String>(
            label: l10n.calendarFormCourse,
            value: view.courseId ?? '',
            onChanged: (value) => controller.inCourse(value.isEmpty ? null : value),
            options: [
              SelectOption('', l10n.studentsAllCourses),
              for (final course in courses) SelectOption(course.id, course.title),
            ],
          ),
        if (courses.isNotEmpty && instructors.isNotEmpty) const SizedBox(height: Space.s3),
        if (instructors.isNotEmpty)
          AppSelectField<String>(
            label: l10n.staffCoursesInstructorLabel,
            value: view.instructorId ?? '',
            onChanged: (value) => controller.byInstructor(value.isEmpty ? null : value),
            options: [
              SelectOption('', l10n.staffCoursesFilterAnyInstructor),
              for (final instructor in instructors) SelectOption(instructor.id, instructor.name),
            ],
          ),
      ],
    );
  }
}

class _Agenda extends ConsumerWidget {
  const _Agenda({required this.page, required this.day});

  final CalendarPage page;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rows = page.on(day);

    if (rows.isEmpty) {
      return AppCard(
        child: Text(
          page.isEmpty ? l10n.calendarRangeEmpty : l10n.calendarDayEmpty,
          style: context.type.bodyM.copyWith(color: context.colors.muted),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows) ...[
          AgendaRow(
            row: row,
            onOpen: () => GoRouter.of(context).go(AppRoutes.staffEvent(row.event.id)),
          ),
          const SizedBox(height: Space.s3),
        ],
        Text(
          l10n.calendarEventsOnDay(rows.length),
          style: context.type.caption.copyWith(color: context.colors.muted),
        ),
      ],
    );
  }
}
