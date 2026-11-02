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
import '../../../staff_courses/staff_courses.dart';
import '../../application/staff_students_controller.dart';
import '../widgets/student_parts.dart';
import 'message_sheet.dart';

/// `/staff/students` — the academy's learners (LMS-008 roster). Each learner's status, the counts on
/// the tabs and who is in the list at all are the academy's; an instructor sees only the learners on
/// a course they teach (§7). A shell body.
class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;
    final selected = ref.watch(rosterSelectionProvider);
    final action = ref.watch(studentActionProvider);

    // The academy's answer to a message is its own count, said once.
    ref.listen(studentActionProvider, (previous, next) {
      if (next.sent case final sent? when sent != previous?.sent) {
        showAppSnackbar(context, l10n.studentsMessageSent(sent), tone: SnackTone.success);
        ref.read(studentActionProvider.notifier).clearAnswer();
        ref.read(rosterSelectionProvider.notifier).clear();
        return;
      }
      final failure = next.failure;
      if (failure == null || failure == previous?.failure) return;
      final kind = refusalKindOf(failure);
      showAppSnackbar(
        context,
        kind == null
            ? failure.message ?? l10n.stateErrorBody
            : refusalMessage(l10n, kind, serverMessage: failure.message),
        tone: SnackTone.error,
      );
      ref.read(studentActionProvider.notifier).clearAnswer();
    });

    return RefreshIndicator(
      onRefresh: () => ref.refresh(rosterProvider.future),
      child: Column(
        children: [
          if (selected.isNotEmpty)
            _SelectionBar(
              count: selected.length,
              busy: action.busy,
              onMessage: () => showMessageSheet(context, studentIds: selected.toList()),
              onClear: ref.read(rosterSelectionProvider.notifier).clear,
            ),
          Expanded(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(gutter, Space.s3, gutter, Space.s6),
              children: [
                const _Toolbar(),
                const SizedBox(height: Space.s4),
                AsyncView<RosterPage>(
                  value: ref.watch(rosterProvider),
                  onRetry: () => ref.invalidate(rosterProvider),
                  data: (page) => _Rows(page: page),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What is selected and what can be done with it. Messaging is offered only to someone the academy
/// lets message learners.
class _SelectionBar extends ConsumerWidget {
  const _SelectionBar({
    required this.count,
    required this.busy,
    required this.onMessage,
    required this.onClear,
  });

  final int count;
  final bool busy;
  final VoidCallback onMessage;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mayMessage = watchCan(ref, Capability.messageLearners);

    // Full width above the list, so it reads as the list's own toolbar; the actions wrap beneath
    // the count only when the text is very large.
    return Container(
      width: double.infinity,
      color: context.colors.accentSoft,
      padding: const EdgeInsets.fromLTRB(Space.s4, Space.s2, Space.s2, Space.s2),
      child: Wrap(
        spacing: Space.s2,
        runSpacing: Space.s1,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(
            l10n.studentsSelected(count),
            style: context.type.label.copyWith(color: context.colors.accentInk),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label: l10n.studentsClearSelection,
                variant: AppButtonVariant.tertiary,
                size: AppButtonSize.sm,
                onPressed: onClear,
              ),
              if (mayMessage) ...[
                const SizedBox(width: Space.s1),
                AppButton(
                  label: l10n.studentsMessageAction,
                  icon: AppIcons.email,
                  size: AppButtonSize.sm,
                  busy: busy,
                  onPressed: onMessage,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The search and the status chips stay above the roster; the sort and the course picker live in
/// the Filters sheet.
class _Toolbar extends ConsumerWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(rosterFilterProvider);
    final controller = ref.read(rosterFilterProvider.notifier);
    final counts = ref.watch(rosterProvider).value;

    int? countOf(String status) => counts?.countOf(status);

    final active = [
      filter.sort != const RosterFilter().sort,
      filter.courseId != null,
    ].where((on) => on).length;

    return ListToolbar(
      search: AppSearchField(
        hintText: l10n.studentsSearch,
        initialValue: filter.search,
        onChanged: controller.searchFor,
      ),
      chips: FilterChipBar<String>(
        padding: EdgeInsets.zero,
        selected: filter.status,
        onSelected: controller.showStatus,
        options: [
          FilterOption('all', l10n.studentsTabAll, count: countOf('all')),
          FilterOption('active', l10n.studentsTabActive, count: countOf('active')),
          FilterOption('at-risk', l10n.studentsTabAtRisk, count: countOf('at-risk')),
          FilterOption('inactive', l10n.studentsTabInactive, count: countOf('inactive')),
          FilterOption('suspended', l10n.studentsTabSuspended, count: countOf('suspended')),
        ],
      ),
      filters: (_) => const _FilterFields(),
      activeFilters: active,
      onClearFilters: active == 0
          ? null
          : () {
              controller
                ..sortBy(const RosterFilter().sort)
                ..inCourse(null);
            },
    );
  }
}

/// The Filters sheet's fields. They watch the filter themselves, so a choice shows at once while
/// the sheet is open.
class _FilterFields extends ConsumerWidget {
  const _FilterFields();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(rosterFilterProvider);
    final controller = ref.read(rosterFilterProvider.notifier);
    final courses = ref.watch(staffCoursesProvider).value?.rows ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSelectField<String>(
          label: l10n.studentsSortLabel,
          value: filter.sort,
          onChanged: controller.sortBy,
          options: [
            SelectOption('active', l10n.studentsSortActive),
            SelectOption('name', l10n.studentsSortName),
            SelectOption('progress', l10n.studentsSortProgress),
            SelectOption('joined', l10n.studentsSortJoined),
          ],
        ),
        if (courses.isNotEmpty) ...[
          const SizedBox(height: Space.s3),
          AppSelectField<String>(
            label: l10n.studentsCourseLabel,
            value: filter.courseId ?? '',
            onChanged: (value) => controller.inCourse(value.isEmpty ? null : value),
            options: [
              SelectOption('', l10n.studentsAllCourses),
              for (final course in courses) SelectOption(course.id, course.title),
            ],
          ),
        ],
      ],
    );
  }
}

class _Rows extends ConsumerWidget {
  const _Rows({required this.page});

  final RosterPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(rosterFilterProvider);
    final controller = ref.read(rosterFilterProvider.notifier);
    final selection = ref.watch(rosterSelectionProvider);
    final selectionController = ref.read(rosterSelectionProvider.notifier);
    final mayMessage = watchCan(ref, Capability.messageLearners);

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
            : EmptyState(title: l10n.studentsEmptyTitle, message: l10n.studentsEmptyBody),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in page.rows) ...[
          RosterCard(
            row: row,
            selecting: selection.isNotEmpty,
            selected: selection.contains(row.student.id),
            onToggle: mayMessage ? () => selectionController.toggle(row.student.id) : null,
            onOpen: () => GoRouter.of(context).go(AppRoutes.staffStudent(row.student.id)),
          ),
          const SizedBox(height: Space.s3),
        ],
        // Selecting begins with the first learner; from then on the whole list is checkboxes.
        if (mayMessage && selection.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: l10n.studentsSelectAction,
              icon: AppIcons.check,
              variant: AppButtonVariant.tertiary,
              onPressed: () => selectionController.toggle(page.rows.first.student.id),
            ),
          ),
        PagerRow(
          page: filter.page,
          pages: (page.total / rosterPageSize).ceil(),
          onPage: controller.showPage,
        ),
      ],
    );
  }
}
