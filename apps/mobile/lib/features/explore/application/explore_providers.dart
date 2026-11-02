import '../../learner_home/learner_home.dart';

/// Explore is the same catalogue the public sees — `GET /catalog/*` — read by someone who is
/// signed in, so the courses they already hold are marked. The filters, the search and the models
/// come from the public-catalogue feature through its barrel (§26).
export '../../public_catalog/public_catalog.dart'
    show
        Course,
        CourseCategory,
        allCoursesProvider,
        CatalogFilter,
        catalogCategoriesProvider,
        catalogCourseProvider,
        catalogFilterProvider,
        catalogInstructorsProvider,
        catalogLevelsProvider,
        catalogSearchProvider,
        courseMatches,
        instructorsOf,
        visibleCoursesProvider;

/// The ids this learner is enrolled in. Empty while the workspace has not been read, or when the
/// server refused it — Explore still works, it simply marks nothing.
///
/// A plain function rather than a derived provider on purpose: the course page invalidates
/// `learnerCoursesProvider` after enrolling, and a provider derived from it is notified while
/// another screen is flushing that same provider mid-build, which Riverpod reports as
/// "setState() called during build". Reading the workspace where it is used has no such step.
Set<String> enrolledCourseIds(LearnerCourses? workspace) => {
  for (final course in workspace?.courses ?? const <LearnerCourse>[]) course.course.id,
};

/// The ids this learner saved, as the server holds them.
Set<String> savedCourseIds(LearnerCourses? workspace) => {
  for (final saved in workspace?.saved ?? const <SavedCourse>[]) saved.course.id,
};
