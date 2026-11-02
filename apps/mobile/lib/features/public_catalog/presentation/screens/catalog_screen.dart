import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/routes.dart';
import '../../../../app/routing/up_navigation.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/level.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/catalog_providers.dart';
import '../widgets/course_card.dart';

/// `/catalog` — the academy's published public courses, narrowed by level and topic on the
/// server and by the text box here (the route is unpaged and has no search).
class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final courses = ref.watch(visibleCoursesProvider);
    final levels = ref.watch(catalogLevelsProvider).value ?? const <Level>[];
    final categories = ref.watch(catalogCategoriesProvider).value ?? const <CourseCategory>[];
    final instructors = ref.watch(catalogInstructorsProvider).value ?? const <Instructor>[];
    final filter = ref.watch(catalogFilterProvider);
    final levelName = {for (final l in levels) l.id: l.name};

    // A topic is offered when it covers the chosen level, as the academy mapped them.
    final topics = [
      for (final c in categories)
        if (filter.levelId == null || c.levelIds.contains(filter.levelId)) c,
    ];

    return UpPopScope(
      fallback: AppRoutes.welcome,
      child: Scaffold(
        appBar: CommonAppBar(
          leading: upButton(context, fallback: AppRoutes.welcome),
          title: l10n.catalogTitle,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.s4, Space.s3, Space.s4, Space.s2),
                child: AppSearchField(
                  hintText: l10n.catalogSearchHint,
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
                child: AsyncView<List<Course>>(
                  value: courses,
                  onRetry: () => ref.invalidate(catalogCoursesProvider),
                  skeleton: const DelayedLoading(skeleton: SkeletonList(count: 3)),
                  data: (list) => _CourseList(
                    courses: list,
                    levelName: levelName,
                    instructors: instructors,
                    filtered: !filter.isEmpty || ref.watch(catalogSearchProvider).isNotEmpty,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseList extends ConsumerWidget {
  const _CourseList({
    required this.courses,
    required this.levelName,
    required this.instructors,
    required this.filtered,
  });

  final List<Course> courses;
  final Map<String, String> levelName;
  final List<Instructor> instructors;
  final bool filtered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (courses.isEmpty) {
      return filtered
          ? EmptyState.noMatches(
              onClearFilters: () {
                ref.read(catalogFilterProvider.notifier).clear();
                ref.read(catalogSearchProvider.notifier).set('');
              },
            )
          : EmptyState(title: l10n.catalogEmptyTitle, message: l10n.catalogEmptyBody);
    }
    final columns = WindowSize.of(context).isCompact ? 1 : 2;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s6),
      itemCount: (courses.length / columns).ceil() + 1,
      separatorBuilder: (_, _) => const SizedBox(height: Space.s4),
      itemBuilder: (context, row) {
        if (row == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Space.s1),
            child: Text(
              l10n.catalogCourseCount(courses.length),
              style: context.type.caption.copyWith(color: context.colors.muted),
            ),
          );
        }
        final start = (row - 1) * columns;
        final slice = courses.skip(start).take(columns).toList();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < columns; i++) ...[
              if (i > 0) const SizedBox(width: Space.s4),
              Expanded(
                child: i < slice.length ? _card(context, ref, slice[i]) : const SizedBox.shrink(),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, Course course) => CourseCard(
    course: course,
    levelName: levelName[course.levelId] ?? '',
    instructorNames: [for (final i in instructorsOf(course, instructors)) i.name],
    onTap: () => GoRouter.of(context).go(AppRoutes.catalogCourse(course.slug)),
  );
}
