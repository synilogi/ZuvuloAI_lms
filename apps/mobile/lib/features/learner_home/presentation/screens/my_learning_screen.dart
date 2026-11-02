import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/learner_home_providers.dart';
import '../widgets/learner_widgets.dart';

/// `/my-learning/:tab` — in progress, completed and saved. The **server's** `enrollment.status`
/// and its own saved list decide which course is where; nothing is counted here (§18).
class MyLearningScreen extends ConsumerWidget {
  const MyLearningScreen({required this.tab, super.key});

  final MyLearningTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(learnerCoursesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The shell's app bar already carries "My Courses"; the tabs are this screen's header.
        const SizedBox(height: Space.s3),
        FilterChipBar<MyLearningTab>(
          options: [
            FilterOption(
              MyLearningTab.inProgress,
              l10n.myLearningInProgress,
              count: data.value == null
                  ? null
                  : coursesForTab(data.value!, MyLearningTab.inProgress).length,
            ),
            FilterOption(
              MyLearningTab.completed,
              l10n.myLearningCompleted,
              count: data.value == null
                  ? null
                  : coursesForTab(data.value!, MyLearningTab.completed).length,
            ),
            FilterOption(
              MyLearningTab.saved,
              l10n.myLearningSaved,
              count: data.value?.saved.length,
            ),
          ],
          selected: tab,
          onSelected: (next) => goWithin(context, AppRoutes.myLearning(next), replace: true),
        ),
        const SizedBox(height: Space.s3),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(learnerCoursesProvider.future),
            child: AsyncView<LearnerCourses>(
              value: data,
              onRetry: () => ref.invalidate(learnerCoursesProvider),
              data: (value) => _TabBody(tab: tab, data: value),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({required this.tab, required this.data});

  final MyLearningTab tab;
  final LearnerCourses data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final columns = WindowSize.of(context).isCompact ? 1 : 2;

    if (tab == MyLearningTab.saved) {
      return _Grid(
        columns: columns,
        empty: EmptyState(title: l10n.myLearningEmptySaved, message: l10n.myLearningEmptySavedBody),
        children: [
          for (final saved in data.saved)
            SavedCourseRow(
              saved: saved,
              onTap: () => router.go(AppRoutes.catalogCourse(saved.course.slug)),
            ),
        ],
      );
    }

    final courses = coursesForTab(data, tab);
    final (String title, String body) = tab == MyLearningTab.completed
        ? (l10n.myLearningEmptyCompleted, l10n.myLearningEmptyCompletedBody)
        : (l10n.myLearningEmptyInProgress, l10n.myLearningEmptyInProgressBody);

    return _Grid(
      columns: columns,
      empty: EmptyState(
        title: title,
        message: body,
        actionLabel: tab == MyLearningTab.completed ? null : l10n.actionExplore,
        onAction: tab == MyLearningTab.completed ? null : () => router.go(AppRoutes.explore),
      ),
      children: [
        for (final course in courses)
          LearnerCourseCard(
            course: course,
            expand: true,
            onTap: () => router.go(AppRoutes.learnCourse(course.course.id)),
          ),
      ],
    );
  }
}

/// A scrollable list that stays scrollable when empty, so pull-to-refresh still works.
class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.children, required this.empty});

  final int columns;
  final List<Widget> children;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [SizedBox(height: 360, child: empty)],
      );
    }
    final rows = (children.length / columns).ceil();
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s6),
      itemCount: rows,
      separatorBuilder: (_, _) => const SizedBox(height: Space.s3),
      itemBuilder: (context, row) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < columns; i++) ...[
            if (i > 0) const SizedBox(width: Space.s3),
            Expanded(
              child: row * columns + i < children.length
                  ? children[row * columns + i]
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }
}
