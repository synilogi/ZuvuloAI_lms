import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/auth.dart';
import '../../../staff_dashboard/staff_dashboard.dart';
import '../../application/staff_courses_controller.dart';
import '../widgets/course_parts.dart';

/// `/staff/courses` — the academy's catalogue as staff read it (§26). The tabs' counts, the rows
/// and what an instructor is allowed to see are all the server's; the app only asks.
/// A shell body.
class StaffCoursesScreen extends ConsumerWidget {
  const StaffCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(courseFilterProvider);
    final page = ref.watch(staffCoursesProvider);
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(staffCoursesProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(gutter, Space.s3, gutter, Space.s6),
        children: [
          const _Filters(),
          const SizedBox(height: Space.s4),
          AsyncView<StaffCoursePage>(
            value: page,
            onRetry: () => ref.invalidate(staffCoursesProvider),
            data: (page) => _Results(page: page, filter: filter),
          ),
        ],
      ),
    );
  }
}

/// The search box and the status tabs with the academy's counts; the order and — for an admin —
/// who teaches it sit behind the Filters button.
class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(courseFilterProvider);
    final controller = ref.read(courseFilterProvider.notifier);
    final counts = ref.watch(staffCoursesProvider).value;
    // Read here as well as in the sheet, so the sheet opens with its choices already loaded.
    ref.watch(courseCategoriesProvider);
    if (ref.watch(currentUserProvider)?.role == UserRole.admin) {
      ref.watch(dashboardInstructorsProvider);
    }
    final active = [
      filter.sort != const CourseFilter().sort,
      filter.categoryId != null,
      filter.instructorId != null,
    ].where((on) => on).length;

    int? countOf(String status) => counts?.countOf(status);

    return ListToolbar(
      search: AppSearchField(
        hintText: l10n.staffCoursesSearch,
        initialValue: filter.search,
        onChanged: controller.searchFor,
      ),
      chips: FilterChipBar<String>(
        padding: EdgeInsets.zero,
        selected: filter.status,
        onSelected: controller.showStatus,
        options: [
          FilterOption('all', l10n.staffCourseStatusAll, count: countOf('all')),
          FilterOption('draft', l10n.staffCourseStatusDraft, count: countOf('draft')),
          FilterOption('published', l10n.staffCourseStatusPublished, count: countOf('published')),
          FilterOption('archived', l10n.staffCourseStatusArchived, count: countOf('archived')),
        ],
      ),
      filters: (_) => const _SheetFilters(),
      activeFilters: active,
      onClearFilters: active == 0
          ? null
          : () => controller
              ..sortBy(const CourseFilter().sort)
              ..inCategory(null)
              ..byInstructor(null),
    );
  }
}

/// The Filters sheet: the order, the category and — for an admin — who teaches it. Each applies
/// as it changes.
class _SheetFilters extends ConsumerWidget {
  const _SheetFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(courseFilterProvider);
    final controller = ref.read(courseFilterProvider.notifier);
    final admin = ref.watch(currentUserProvider)?.role == UserRole.admin;
    final categories = ref.watch(courseCategoriesProvider).value ?? const [];
    final instructors = admin
        ? ref.watch(dashboardInstructorsProvider).value ?? const []
        : const <({String id, String name})>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSelectField<String>(
          label: l10n.staffCoursesSortLabel,
          value: filter.sort,
          onChanged: controller.sortBy,
          options: [
            SelectOption('updated', l10n.staffCourseSortUpdated),
            SelectOption('created', l10n.staffCourseSortCreated),
            SelectOption('title', l10n.staffCourseSortTitle),
            SelectOption('learners', l10n.staffCourseSortLearners),
          ],
        ),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: Space.s3),
          AppSelectField<String>(
            label: l10n.staffCoursesCategoryLabel,
            value: filter.categoryId ?? '',
            onChanged: (value) => controller.inCategory(value.isEmpty ? null : value),
            options: [
              SelectOption('', l10n.staffCoursesFilterAnyCategory),
              for (final row in categories) SelectOption(row.category.id, row.category.name),
            ],
          ),
        ],
        if (instructors.isNotEmpty) ...[
          const SizedBox(height: Space.s3),
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
      ],
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.page, required this.filter});

  final StaffCoursePage page;
  final CourseFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(courseFilterProvider.notifier);
    final narrowed =
        filter.search != null ||
        filter.categoryId != null ||
        filter.instructorId != null ||
        filter.status != 'all';

    if (page.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: Space.s5),
        child: narrowed
            ? EmptyState.noMatches(
                onClearFilters: () {
                  controller
                    ..searchFor(null)
                    ..inCategory(null)
                    ..byInstructor(null)
                    ..showStatus('all');
                },
              )
            : EmptyState(title: l10n.staffCoursesEmptyTitle, message: l10n.staffCoursesEmptyBody),
      );
    }

    final pages = (page.total / coursePageSize).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final course in page.rows) ...[
          StaffCourseCard(
            course: course,
            onOpen: () => GoRouter.of(context).go(AppRoutes.staffCourse(course.id)),
          ),
          const SizedBox(height: Space.s3),
        ],
        PagerRow(page: filter.page, pages: pages, onPage: controller.showPage),
      ],
    );
  }
}
