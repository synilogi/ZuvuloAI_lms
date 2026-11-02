import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../staff_courses/staff_courses.dart';
import '../../application/staff_quizzes_controller.dart';
import '../widgets/quiz_parts.dart';

/// `/staff/quizzes` — the academy's quizzes and how they are going (LMS-006 read side). Every
/// figure is the server's; building a quiz stays on the web. A shell body.
class StaffQuizzesScreen extends ConsumerWidget {
  const StaffQuizzesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(staffQuizzesProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(gutter, Space.s3, gutter, Space.s6),
        children: [
          const _Filters(),
          const SizedBox(height: Space.s4),
          AsyncView<StaffQuizPage>(
            value: ref.watch(staffQuizzesProvider),
            onRetry: () => ref.invalidate(staffQuizzesProvider),
            data: (page) => _Rows(page: page),
          ),
        ],
      ),
    );
  }
}

/// The search box and the status tabs with the academy's counts; the course sits behind the
/// Filters button.
class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(quizFilterProvider);
    final controller = ref.read(quizFilterProvider.notifier);
    final counts = ref.watch(staffQuizzesProvider).value;
    // The courses the academy lets this account see, for the course filter.
    final courses = ref.watch(staffCoursesProvider).value?.rows ?? const [];

    int? countOf(String status) => counts?.countOf(status);

    return ListToolbar(
      search: AppSearchField(
        hintText: l10n.staffQuizzesSearch,
        initialValue: filter.search,
        onChanged: controller.searchFor,
      ),
      chips: FilterChipBar<String>(
        padding: EdgeInsets.zero,
        selected: filter.status,
        onSelected: controller.showStatus,
        options: [
          FilterOption('all', l10n.staffQuizStatusAll, count: countOf('all')),
          FilterOption('draft', l10n.staffQuizStatusDraft, count: countOf('draft')),
          FilterOption('published', l10n.staffQuizStatusPublished, count: countOf('published')),
          FilterOption('archived', l10n.staffQuizStatusArchived, count: countOf('archived')),
        ],
      ),
      filters: courses.isEmpty ? null : (_) => const _SheetFilters(),
      activeFilters: filter.courseId == null ? 0 : 1,
      onClearFilters: filter.courseId == null ? null : () => controller.inCourse(null),
    );
  }
}

/// The Filters sheet: which course's quizzes to show. It applies as it changes.
class _SheetFilters extends ConsumerWidget {
  const _SheetFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(quizFilterProvider);
    final controller = ref.read(quizFilterProvider.notifier);
    final courses = ref.watch(staffCoursesProvider).value?.rows ?? const [];

    return AppSelectField<String>(
      label: l10n.staffQuizCourseLabel,
      value: filter.courseId ?? '',
      onChanged: (value) => controller.inCourse(value.isEmpty ? null : value),
      options: [
        SelectOption('', l10n.staffQuizAllCourses),
        for (final course in courses) SelectOption(course.id, course.title),
      ],
    );
  }
}

class _Rows extends ConsumerWidget {
  const _Rows({required this.page});

  final StaffQuizPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(quizFilterProvider);
    final controller = ref.read(quizFilterProvider.notifier);

    if (page.isEmpty) {
      final narrowed = filter.search != null || filter.courseId != null || filter.status != 'all';
      return Padding(
        padding: const EdgeInsets.only(top: Space.s5),
        child: narrowed
            ? EmptyState.noMatches(
                onClearFilters: () {
                  controller
                    ..searchFor(null)
                    ..inCourse(null)
                    ..showStatus('all');
                },
              )
            : EmptyState(title: l10n.staffQuizzesEmptyTitle, message: l10n.staffQuizzesEmptyBody),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in page.rows) ...[
          StaffQuizCard(
            row: row,
            onOpen: () => GoRouter.of(context).go(AppRoutes.staffQuiz(row.quiz.id)),
          ),
          const SizedBox(height: Space.s3),
        ],
      ],
    );
  }
}
