import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/domain/course.dart';
import '../../../shared/domain/user_profile.dart';
import '../../../shared/session/current_user.dart';
import '../data/dto/staff_course.dart';
import '../data/staff_courses_api.dart';

/// What the staff course screens read (§26).
export '../data/dto/staff_course.dart';

/// How many rows one page of the list holds — the service's own page size, so the list can say
/// which page of how many it is showing.
const coursePageSize = StaffCoursesApi.pageSize;

/// What the list is showing. `instructorId` is the **admin's** filter; an instructor is scoped by
/// their own token and never sends one (§7).
@immutable
class CourseFilter {
  const CourseFilter({
    this.status = 'all',
    this.search,
    this.categoryId,
    this.instructorId,
    this.sort = 'updated',
    this.page = 1,
  });

  final String status;
  final String? search;
  final String? categoryId;
  final String? instructorId;
  final String sort;
  final int page;

  CourseFilter copyWith({
    String? status,
    String? search,
    bool clearSearch = false,
    String? categoryId,
    bool clearCategory = false,
    String? instructorId,
    bool clearInstructor = false,
    String? sort,
    int? page,
  }) => CourseFilter(
    status: status ?? this.status,
    search: clearSearch ? null : (search ?? this.search),
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    instructorId: clearInstructor ? null : (instructorId ?? this.instructorId),
    sort: sort ?? this.sort,
    page: page ?? 1,
  );

  @override
  bool operator ==(Object other) =>
      other is CourseFilter &&
      other.status == status &&
      other.search == search &&
      other.categoryId == categoryId &&
      other.instructorId == instructorId &&
      other.sort == sort &&
      other.page == page;

  @override
  int get hashCode => Object.hash(status, search, categoryId, instructorId, sort, page);
}

class CourseFilterController extends Notifier<CourseFilter> {
  @override
  CourseFilter build() => const CourseFilter();

  void showStatus(String status) => state = state.copyWith(status: status);

  void searchFor(String? text) => (text == null || text.trim().isEmpty)
      ? state = state.copyWith(clearSearch: true)
      : state = state.copyWith(search: text.trim());

  void inCategory(String? categoryId) => categoryId == null
      ? state = state.copyWith(clearCategory: true)
      : state = state.copyWith(categoryId: categoryId);

  void byInstructor(String? instructorId) => instructorId == null
      ? state = state.copyWith(clearInstructor: true)
      : state = state.copyWith(instructorId: instructorId);

  void sortBy(String sort) => state = state.copyWith(sort: sort);

  void showPage(int page) => state = state.copyWith(page: page);
}

final courseFilterProvider = NotifierProvider<CourseFilterController, CourseFilter>(
  CourseFilterController.new,
  isAutoDispose: true,
);

/// The academy's courses for the filter on screen. Only an admin may narrow by instructor.
final staffCoursesProvider = FutureProvider<StaffCoursePage>((ref) {
  final filter = ref.watch(courseFilterProvider);
  final admin = ref.watch(currentUserProvider)?.role == UserRole.admin;
  return ref
      .watch(staffCoursesApiProvider)
      .courses(
        search: filter.search,
        categoryId: filter.categoryId,
        instructorId: admin ? filter.instructorId : null,
        status: filter.status == 'all' ? null : filter.status,
        sort: filter.sort,
        page: filter.page,
      );
}, isAutoDispose: true);

final staffCourseProvider = FutureProvider.family<Course, String>(
  (ref, courseId) => ref.watch(staffCoursesApiProvider).course(courseId),
  isAutoDispose: true,
);

final staffCourseStatsProvider = FutureProvider.family<CourseStats, String>(
  (ref, courseId) => ref.watch(staffCoursesApiProvider).stats(courseId),
  isAutoDispose: true,
);

final curriculumStatsProvider = FutureProvider.family<CurriculumStats, String>(
  (ref, courseId) => ref.watch(staffCoursesApiProvider).curriculumStats(courseId),
  isAutoDispose: true,
);

final staffLessonProvider =
    FutureProvider.family<StaffLessonDetail, ({String courseId, String lessonId})>(
      (ref, key) => ref.watch(staffCoursesApiProvider).lesson(key.courseId, key.lessonId),
      isAutoDispose: true,
    );

/// The categories the list filters by. Empty when the academy refuses the read — the filter simply
/// does not appear rather than the list failing.
final courseCategoriesProvider = FutureProvider<List<StaffCategoryRow>>((ref) async {
  try {
    return (await ref.watch(staffCoursesApiProvider).categories()).rows;
  } on ApiException {
    return const [];
  }
}, isAutoDispose: true);

/// What a lifecycle action left behind: what is in flight, the academy's checklist when it refused
/// a publish, and any other refusal in its own words.
@immutable
class CourseActionState {
  const CourseActionState({this.busy = false, this.checklist = const [], this.failure});

  final bool busy;

  /// The academy's own publish checklist, when it said the course is not ready.
  final List<PublishCheck> checklist;

  final AppFailure? failure;
}

/// Publishing, unpublishing, archiving and restoring. Every refusal is the academy's: the app
/// makes no decision about whether a course may go live (§18).
class CourseActionController extends Notifier<CourseActionState> {
  @override
  CourseActionState build() => const CourseActionState();

  Future<bool> publish(String courseId) => _run(courseId, (api) => api.publish(courseId));

  Future<bool> unpublish(String courseId) => _run(courseId, (api) => api.unpublish(courseId));

  Future<bool> archive(String courseId) => _run(courseId, (api) => api.archive(courseId));

  Future<bool> restore(String courseId) => _run(courseId, (api) => api.restore(courseId));

  /// Forgets the academy's last answer — the checklist and any refusal.
  void clearAnswer() => state = const CourseActionState();

  Future<bool> _run(String courseId, Future<Course> Function(StaffCoursesApi api) action) async {
    if (state.busy) return false;
    state = const CourseActionState(busy: true);
    try {
      await action(ref.read(staffCoursesApiProvider));
      // The academy acted; if the screen has gone there is nothing left to tell or re-read.
      if (!ref.mounted) return true;
      state = const CourseActionState();
      ref
        ..invalidate(staffCoursesProvider)
        ..invalidate(staffCourseProvider(courseId));
      return true;
    } on ApiException catch (e) {
      if (!ref.mounted) return false;
      final failure = e.failure;
      // A refused publish carries the academy's checklist in its own shape (finding 23).
      final checklist = failure is ConflictFailure
          ? publishChecklistOf(failure.rawIssues)
          : const <PublishCheck>[];
      state = CourseActionState(checklist: checklist, failure: checklist.isEmpty ? failure : null);
      return false;
    }
  }
}

final courseActionProvider = NotifierProvider<CourseActionController, CourseActionState>(
  CourseActionController.new,
  isAutoDispose: true,
);
