import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/auth/capabilities.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/entitlements/entitlements.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/auth.dart';
import '../../../staff_courses/staff_courses.dart';
import '../../../staff_dashboard/staff_dashboard.dart';
import '../../application/staff_live_controller.dart';
import '../widgets/live_parts.dart';

/// `/staff/live` — the academy's live teaching (LMS-012 staff side). The four views, their counts
/// and each class's phase are the academy's; an instructor sees the classes of the courses they
/// teach and any they host (§7). A shell body.
class StaffLiveScreen extends ConsumerWidget {
  const StaffLiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;
    final mayManage = watchCan(ref, Capability.manageLive);
    // While the plan that included live classes has ended, existing classes still run and can be
    // edited, but no new one can be scheduled — the button stays, disabled, and says why.
    final readOnly = watchModuleAccess(ref, WorkspaceModule.live) == ModuleAccess.readOnly;

    return FabLayout(
      fab: mayManage
          ? AppFab(
              label: l10n.staffLiveScheduleAction,
              icon: AppIcons.add,
              disabledReason: readOnly ? readOnlyActionReason(l10n, WorkspaceModule.live) : null,
              onPressed: readOnly ? null : () => GoRouter.of(context).go(AppRoutes.staffLiveNew),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(staffLiveScheduleProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            gutter,
            Space.s3,
            gutter,
            mayManage ? FabLayout.clearance : Space.s6,
          ),
          children: [
            const _Filters(),
            const SizedBox(height: Space.s4),
            AsyncView<StaffLivePage>(
              value: ref.watch(staffLiveScheduleProvider),
              onRetry: () => ref.invalidate(staffLiveScheduleProvider),
              data: (page) => _Rows(page: page),
            ),
          ],
        ),
      ),
    );
  }
}

/// The schedule's head: the search, the four views with the academy's counts, and the course and
/// instructor filters behind the Filters button.
class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(liveFilterProvider);
    final controller = ref.read(liveFilterProvider.notifier);
    final counts = ref.watch(staffLiveScheduleProvider).value;
    final courses = ref.watch(staffCoursesProvider).value?.rows ?? const [];
    final admin = ref.watch(currentUserProvider)?.role == UserRole.admin;
    final instructors = admin
        ? ref.watch(dashboardInstructorsProvider).value ?? const []
        : const <({String id, String name})>[];
    final active = [filter.courseId, filter.instructorId].nonNulls.length;

    int? countOf(String view) => counts?.countOf(view);

    return ListToolbar(
      search: AppSearchField(
        hintText: l10n.staffLiveSearch,
        initialValue: filter.search,
        onChanged: controller.searchFor,
      ),
      chips: FilterChipBar<String>(
        padding: EdgeInsets.zero,
        selected: filter.view,
        onSelected: controller.show,
        options: [
          FilterOption('upcoming', l10n.staffLiveTabUpcoming, count: countOf('upcoming')),
          FilterOption('live', l10n.staffLiveTabLive, count: countOf('live')),
          FilterOption('history', l10n.staffLiveTabHistory, count: countOf('history')),
          FilterOption('cancelled', l10n.staffLiveTabCancelled, count: countOf('cancelled')),
        ],
      ),
      filters: courses.isEmpty && instructors.isEmpty ? null : (_) => const _SheetFilters(),
      activeFilters: active,
      onClearFilters: active == 0
          ? null
          : () {
              controller
                ..inCourse(null)
                ..byInstructor(null);
            },
    );
  }
}

/// The course and instructor filters, in the Filters sheet. They apply as they change.
class _SheetFilters extends ConsumerWidget {
  const _SheetFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(liveFilterProvider);
    final controller = ref.read(liveFilterProvider.notifier);
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
            label: l10n.staffLiveFormCourse,
            value: filter.courseId ?? '',
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
            value: filter.instructorId ?? '',
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

class _Rows extends ConsumerWidget {
  const _Rows({required this.page});

  final StaffLivePage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(liveFilterProvider);
    final controller = ref.read(liveFilterProvider.notifier);
    final now = liveNow(ref);

    if (page.isEmpty) {
      final narrowed =
          filter.search != null || filter.courseId != null || filter.instructorId != null;
      return Padding(
        padding: const EdgeInsets.only(top: Space.s5),
        child: narrowed
            ? EmptyState.noMatches(
                onClearFilters: () {
                  controller
                    ..searchFor(null)
                    ..inCourse(null)
                    ..byInstructor(null);
                },
              )
            : EmptyState(title: l10n.staffLiveEmptyTitle, message: l10n.staffLiveEmptyBody),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in page.rows) ...[
          StaffLiveCard(
            row: row,
            now: now,
            onOpen: () => GoRouter.of(context).go(AppRoutes.staffLiveClass(row.liveClass.id)),
          ),
          const SizedBox(height: Space.s3),
        ],
        PagerRow(
          page: filter.page,
          pages: (page.total / livePageSize).ceil(),
          onPage: controller.showPage,
        ),
      ],
    );
  }
}
