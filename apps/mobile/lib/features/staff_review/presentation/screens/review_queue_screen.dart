import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/format/figures.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/staff_review_controller.dart';
import '../widgets/review_parts.dart';
import 'submission_review_screen.dart';

/// Which hand-in the two-pane layout is showing. Null until one is chosen, and only ever used on a
/// screen wide enough to show the review beside the queue (§20).
final selectedSubmissionProvider = NotifierProvider<SelectedSubmission, String?>(
  SelectedSubmission.new,
  isAutoDispose: true,
);

class SelectedSubmission extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String? submissionId) => state = submissionId;
}

/// `/staff/review` — what is waiting to be marked (LMS-007 staff side). The counts, the overdue
/// window and who may be reviewed are all the academy's. A shell body.
class ReviewQueueScreen extends ConsumerWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final twoPane = WindowSize.of(context).isExpanded;
    final selected = ref.watch(selectedSubmissionProvider);

    if (!twoPane) return const _Queue();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(flex: 2, child: _Queue()),
        VerticalDivider(width: 1, thickness: 1, color: context.colors.border),
        Expanded(
          flex: 3,
          child: selected == null
              ? Center(
                  child: EmptyState(
                    title: context.l10n.reviewTitle,
                    message: context.l10n.reviewEmptyBody,
                  ),
                )
              : SubmissionReviewScreen(
                  submissionId: selected,
                  onOpenOther: ref.read(selectedSubmissionProvider.notifier).show,
                ),
        ),
      ],
    );
  }
}

class _Queue extends ConsumerWidget {
  const _Queue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = !WindowSize.of(context).isCompact;
    final gutter = wide ? Space.gutterMedium : Space.s4;
    final queue = ref.watch(reviewQueueProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(reviewQueueProvider)
          ..invalidate(submissionsProvider);
        await ref.read(submissionsProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(gutter, Space.s3, gutter, Space.s6),
        children: [
          const _Toolbar(),
          const SizedBox(height: Space.s4),
          AsyncView<ReviewQueue>(
            value: queue,
            onRetry: () => ref.invalidate(reviewQueueProvider),
            skeleton: const DelayedLoading(skeleton: SkeletonCard()),
            data: (queue) => _Headline(queue: queue),
          ),
          const SizedBox(height: Space.s4),
          AsyncView<SubmissionPage>(
            value: ref.watch(submissionsProvider),
            onRetry: () => ref.invalidate(submissionsProvider),
            data: (page) => _Rows(page: page),
          ),
        ],
      ),
    );
  }
}

/// The titles of the courses the academy's assignments belong to, by course id.
Map<String, String> _courseTitles(WidgetRef ref) {
  final assignments = ref.watch(staffAssignmentsProvider).value ?? const [];
  return {for (final row in assignments) row.assignment.courseId: row.courseTitle};
}

/// How much is waiting, and where — the academy's own two numbers, then its load per course.
class _Headline extends ConsumerWidget {
  const _Headline({required this.queue});

  final ReviewQueue queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final titles = _courseTitles(ref);
    final controller = ref.read(submissionFilterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatSummaryCard(
          figures: [
            StatFigure(
              value: formatFigure(queue.toReview),
              label: l10n.reviewQueueToReview,
              icon: AppIcons.review,
              hue: Hue.orange,
              onTap: () => controller.show('to-review'),
            ),
            StatFigure(
              value: formatFigure(queue.overdue),
              label: l10n.reviewQueueOverdue,
              icon: AppIcons.warning,
              hue: Hue.pink,
            ),
          ],
        ),
        if (queue.byCourse.isNotEmpty) ...[
          const SizedBox(height: Space.s4),
          SectionHeader(
            title: l10n.reviewQueueByCourse,
            icon: AppIcons.courses,
            iconColor: c.hue(AppNavIcons.of(AppIcons.courses).hue).solid,
          ),
          GroupedList(
            children: [
              for (final load in queue.byCourse)
                AppListTile(
                  title: titles[load.courseId] ?? l10n.reviewQueueByCourse,
                  subtitle: '${l10n.reviewQueueToReview}: ${load.toReview}',
                  meta: load.overdue == 0 ? null : '${l10n.reviewQueueOverdue}: ${load.overdue}',
                  showChevron: true,
                  onTap: () {
                    controller
                      ..forAssignment(null)
                      ..inCourse(load.courseId)
                      ..show('to-review');
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The learner search and the review-status chips stay above the list; the sort and the
/// assignment and course pickers live in the Filters sheet.
class _Toolbar extends ConsumerWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(submissionFilterProvider);
    final controller = ref.read(submissionFilterProvider.notifier);
    final counts = ref.watch(submissionsProvider).value;

    int? countOf(String key) => counts?.countOf(key);

    final active = [
      filter.sort != const SubmissionFilter().sort,
      filter.assignmentId != null,
      filter.courseId != null,
    ].where((on) => on).length;

    return ListToolbar(
      search: AppSearchField(
        hintText: l10n.reviewSearchHint,
        initialValue: filter.search,
        onChanged: controller.searchFor,
      ),
      chips: FilterChipBar<String>(
        padding: EdgeInsets.zero,
        selected: filter.filter,
        onSelected: controller.show,
        options: [
          FilterOption('to-review', l10n.reviewTabToReview, count: countOf('to-review')),
          FilterOption('graded', l10n.reviewTabGraded, count: countOf('graded')),
          FilterOption('returned', l10n.reviewTabReturned, count: countOf('returned')),
          FilterOption('missing', l10n.reviewTabMissing, count: countOf('missing')),
          FilterOption('all', l10n.reviewTabAll, count: countOf('all')),
        ],
      ),
      filters: (_) => const _FilterFields(),
      activeFilters: active,
      onClearFilters: active == 0
          ? null
          : () {
              controller
                ..sortBy(const SubmissionFilter().sort)
                ..forAssignment(null)
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
    final filter = ref.watch(submissionFilterProvider);
    final controller = ref.read(submissionFilterProvider.notifier);
    final assignments = ref.watch(staffAssignmentsProvider).value ?? const [];
    final titles = _courseTitles(ref);
    // A course picked from the per-course list stays listed, under the list's own stand-in.
    if (filter.courseId case final id?) titles.putIfAbsent(id, () => l10n.reviewQueueByCourse);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSelectField<String>(
          label: l10n.reviewSortLabel,
          value: filter.sort,
          onChanged: controller.sortBy,
          options: [
            SelectOption('oldest', l10n.reviewSortOldest),
            SelectOption('newest', l10n.reviewSortNewest),
            SelectOption('score', l10n.reviewSortScore),
          ],
        ),
        if (assignments.isNotEmpty) ...[
          const SizedBox(height: Space.s3),
          AppSelectField<String>(
            label: l10n.reviewAssignmentLabel,
            value: filter.assignmentId ?? '',
            onChanged: (value) => controller.forAssignment(value.isEmpty ? null : value),
            options: [
              SelectOption('', l10n.reviewAllAssignments),
              for (final row in assignments) SelectOption(row.assignment.id, row.assignment.title),
            ],
          ),
        ],
        if (titles.isNotEmpty) ...[
          const SizedBox(height: Space.s3),
          AppSelectField<String>(
            label: l10n.staffReviewCourseLabel,
            value: filter.courseId ?? '',
            onChanged: (value) => controller.inCourse(value.isEmpty ? null : value),
            options: [
              SelectOption('', l10n.staffReviewAllCourses),
              for (final MapEntry(:key, :value) in titles.entries) SelectOption(key, value),
            ],
          ),
        ],
      ],
    );
  }
}

class _Rows extends ConsumerWidget {
  const _Rows({required this.page});

  final SubmissionPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(submissionFilterProvider);
    final controller = ref.read(submissionFilterProvider.notifier);
    final selected = ref.watch(selectedSubmissionProvider);
    final twoPane = WindowSize.of(context).isExpanded;

    if (page.rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: Space.s5),
        child: filter.filter == 'to-review' && filter.search == null && filter.assignmentId == null
            ? EmptyState(title: l10n.reviewQueueClearTitle, message: l10n.reviewQueueClearBody)
            : EmptyState.noMatches(
                onClearFilters: () {
                  controller
                    ..searchFor(null)
                    ..inCourse(null)
                    ..forAssignment(null)
                    ..show('all');
                },
              ),
      );
    }

    void open(SubmissionRow row) {
      if (row.isMissing) return;
      if (twoPane) {
        ref.read(selectedSubmissionProvider.notifier).show(row.id);
      } else {
        GoRouter.of(context).go(AppRoutes.staffSubmission(row.id));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in page.rows) ...[
          SubmissionCard(
            row: row,
            selected: selected == row.id,
            onOpen: row.isMissing ? null : () => open(row),
          ),
          const SizedBox(height: Space.s3),
        ],
        PagerRow(
          page: filter.page,
          pages: (page.total / submissionPageSize).ceil(),
          onPage: controller.showPage,
        ),
      ],
    );
  }
}
