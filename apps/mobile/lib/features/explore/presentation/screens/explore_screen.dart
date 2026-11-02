import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/level.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../learner_home/learner_home.dart';
import '../../../public_catalog/public_catalog.dart';
import '../../application/explore_providers.dart';

/// `/explore` — the academy's catalogue for a signed-in learner. It reads the same public routes
/// the visitor catalogue does; what is different is that a course they already hold is marked and
/// opens their own learning view. A shell body: the shell draws the frame.
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final courses = ref.watch(visibleCoursesProvider);
    final levels = ref.watch(catalogLevelsProvider).value ?? const <Level>[];
    final categories = ref.watch(catalogCategoriesProvider).value ?? const <CourseCategory>[];
    final filter = ref.watch(catalogFilterProvider);
    final topics = [
      for (final c in categories)
        if (filter.levelId == null || c.levelIds.contains(filter.levelId)) c,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s2),
          child: AppSearchField(
            hintText: l10n.exploreSearchHint,
            onChanged: (q) => ref.read(catalogSearchProvider.notifier).set(q),
          ),
        ),
        FilterChipBar<String?>(
          options: [
            FilterOption(null, l10n.catalogFilterAllLevels),
            for (final level in levels) FilterOption(level.id, level.name),
          ],
          selected: filter.levelId,
          onSelected: (id) => ref.read(catalogFilterProvider.notifier).setLevel(id),
        ),
        if (topics.isNotEmpty) ...[
          FilterChipBar<String?>(
            options: [
              FilterOption(null, l10n.catalogFilterAllTopics),
              for (final topic in topics) FilterOption(topic.id, topic.name),
            ],
            selected: filter.categoryId,
            onSelected: (id) => ref.read(catalogFilterProvider.notifier).setCategory(id),
          ),
        ],
        const SizedBox(height: Space.s3),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(catalogCoursesProvider);
              await ref.read(catalogCoursesProvider.future);
            },
            child: AsyncView<List<Course>>(
              value: courses,
              onRetry: () => ref.invalidate(catalogCoursesProvider),
              skeleton: const DelayedLoading(skeleton: SkeletonList(count: 3)),
              data: (list) => _Results(courses: list),
            ),
          ),
        ),
      ],
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.courses});

  final List<Course> courses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final filter = ref.watch(catalogFilterProvider);
    final query = ref.watch(catalogSearchProvider);
    final levelName = {
      for (final level in ref.watch(catalogLevelsProvider).value ?? const <Level>[])
        level.id: level.name,
    };
    final instructors = ref.watch(catalogInstructorsProvider).value ?? const <Instructor>[];
    final enrolled = enrolledCourseIds(ref.watch(learnerCoursesProvider).value);

    if (courses.isEmpty) {
      return !filter.isEmpty || query.isNotEmpty
          ? EmptyState.noMatches(
              onClearFilters: () {
                ref.read(catalogFilterProvider.notifier).clear();
                ref.read(catalogSearchProvider.notifier).set('');
              },
            )
          : EmptyState(title: l10n.catalogEmptyTitle, message: l10n.catalogEmptyBody);
    }

    final columns = WindowSize.of(context).isCompact ? 1 : 2;
    final rows = (courses.length / columns).ceil();
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s6),
      // How many courses the filters leave, then the courses themselves.
      itemCount: rows + 1,
      separatorBuilder: (_, _) => const SizedBox(height: Space.s4),
      itemBuilder: (context, index) {
        // The shelf's heading: the level it shows (or all of them), and how many courses are on it.
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                levelName[filter.levelId] ?? l10n.catalogFilterAllLevels,
                style: context.type.titleL,
              ),
              Text(
                l10n.catalogCourseCount(courses.length),
                style: context.type.bodyS.copyWith(color: context.colors.muted),
              ),
            ],
          );
        }
        final row = index - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < columns; i++) ...[
              if (i > 0) const SizedBox(width: Space.s4),
              Expanded(
                child: row * columns + i < courses.length
                    ? _card(
                        context,
                        courses[row * columns + i],
                        levelName,
                        instructors,
                        enrolled,
                        router,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _card(
    BuildContext context,
    Course course,
    Map<String, String> levelName,
    List<Instructor> instructors,
    Set<String> enrolled,
    GoRouter router,
  ) {
    return CourseBatchCard(
      course: course,
      levelName: levelName[course.levelId] ?? '',
      instructorNames: [for (final i in instructorsOf(course, instructors)) i.name],
      enrolled: enrolled.contains(course.id),
      // Signed in, every course opens the learner's own view of it.
      onTap: () => router.go(AppRoutes.learnCourse(course.id)),
    );
  }
}
