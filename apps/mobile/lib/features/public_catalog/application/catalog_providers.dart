import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/course.dart';
import '../../../shared/domain/level.dart';
import '../data/catalog_api.dart';

/// The catalogue models the screens read; presentation reaches them through this layer (§26).
export '../../../shared/domain/course.dart';

/// Which level and category the catalogue is narrowed to. Both are ids the server sent; null is
/// "all". The server does the narrowing — the app only passes the ids back (§18).
@immutable
class CatalogFilter {
  const CatalogFilter({this.levelId, this.categoryId});

  final String? levelId;
  final String? categoryId;

  bool get isEmpty => levelId == null && categoryId == null;

  CatalogFilter withLevel(String? id) => CatalogFilter(levelId: id, categoryId: categoryId);

  CatalogFilter withCategory(String? id) => CatalogFilter(levelId: levelId, categoryId: id);

  @override
  bool operator ==(Object other) =>
      other is CatalogFilter && other.levelId == levelId && other.categoryId == categoryId;

  @override
  int get hashCode => Object.hash(levelId, categoryId);
}

class CatalogFilterNotifier extends Notifier<CatalogFilter> {
  @override
  CatalogFilter build() => const CatalogFilter();

  void setLevel(String? levelId) {
    // A category is offered per level, so narrowing the level drops a category it does not cover.
    final categories = ref.read(catalogCategoriesProvider).value ?? const <CourseCategory>[];
    final current = state.categoryId;
    final keepCategory =
        current == null ||
        levelId == null ||
        categories.any((c) => c.id == current && c.levelIds.contains(levelId));
    state = CatalogFilter(levelId: levelId, categoryId: keepCategory ? current : null);
  }

  void setCategory(String? categoryId) => state = state.withCategory(categoryId);

  void clear() => state = const CatalogFilter();
}

final catalogFilterProvider = NotifierProvider<CatalogFilterNotifier, CatalogFilter>(
  CatalogFilterNotifier.new,
);

/// The catalogue's text box. The catalogue endpoint is unpaged and has no search, so this filters
/// what the server already returned (FLUTTER-008 spec, "client-side text search").
class CatalogSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final catalogSearchProvider = NotifierProvider<CatalogSearchNotifier, String>(
  CatalogSearchNotifier.new,
);

final catalogLevelsProvider = FutureProvider<List<Level>>(
  (ref) => ref.watch(catalogApiProvider).levels(),
);

/// Categories a visitor may see: the route returns hidden ones too, and hiding is the client's job
/// (FLUTTER-008 spec, confirmed in `apps/api/src/routes/catalog.ts`).
final catalogCategoriesProvider = FutureProvider<List<CourseCategory>>((ref) async {
  final all = await ref.watch(catalogApiProvider).categories();
  return [
    for (final c in all)
      if (c.status != CategoryStatus.hidden) c,
  ];
});

final catalogInstructorsProvider = FutureProvider<List<Instructor>>(
  (ref) => ref.watch(catalogApiProvider).instructors(),
);

/// The courses the server returns for the current filter.
final catalogCoursesProvider = FutureProvider<List<Course>>((ref) {
  final filter = ref.watch(catalogFilterProvider);
  return ref
      .watch(catalogApiProvider)
      .courses(levelId: filter.levelId, categoryId: filter.categoryId);
});

/// Every course the academy lists, whatever Explore is filtered to — Home's and the Courses tab's
/// "All courses". The same public route, asked with no level or category.
final allCoursesProvider = FutureProvider<List<Course>>(
  (ref) => ref.watch(catalogApiProvider).courses(),
);

/// Matches [query] against a course's title, subtitle and tags — the fields a person can see.
bool courseMatches(Course course, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return course.title.toLowerCase().contains(q) ||
      course.subtitle.toLowerCase().contains(q) ||
      course.tags.any((t) => t.toLowerCase().contains(q));
}

/// What the catalogue list shows: the server's result, narrowed by the text box.
final visibleCoursesProvider = Provider<AsyncValue<List<Course>>>((ref) {
  final query = ref.watch(catalogSearchProvider);
  return ref
      .watch(catalogCoursesProvider)
      .whenData(
        (courses) => [
          for (final c in courses)
            if (courseMatches(c, query)) c,
        ],
      );
});

/// One course by slug. Auto-disposed: a detail page is read once and re-read on return.
final catalogCourseProvider = FutureProvider.family<Course, String>(
  (ref, slug) => ref.watch(catalogApiProvider).course(slug),
  isAutoDispose: true,
);

/// The instructors of [course], in the order the course lists them; unknown ids are skipped.
List<Instructor> instructorsOf(Course course, List<Instructor> all) {
  final byId = {for (final i in all) i.id: i};
  return [
    for (final id in course.instructorIds)
      if (byId[id] != null) byId[id]!,
  ];
}
