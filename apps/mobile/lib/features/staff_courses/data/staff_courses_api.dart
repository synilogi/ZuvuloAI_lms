import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import '../../../shared/domain/course.dart';
import 'dto/staff_course.dart';

/// `apps/api/src/routes/courses.ts`, `chapters.ts` and `lessons.ts` — the academy's own catalogue
/// as staff read it. An instructor is scoped by their token: the app never sends an `instructorId`
/// for them, and the route would ignore it anyway (§7).
class StaffCoursesApi {
  StaffCoursesApi(this._client);

  static const pageSize = 20;

  final ApiClient _client;

  Future<StaffCoursePage> courses({
    String? search,
    String? categoryId,
    String? instructorId,
    String? status,
    String? sort,
    int page = 1,
  }) async {
    const endpoint = 'GET /courses';
    final body = await _client.get(
      '/courses',
      query: {
        'search': ?search,
        'categoryId': ?categoryId,
        'instructorId': ?instructorId,
        'status': ?status,
        'sort': ?sort,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return parseResponse(
      endpoint,
      body,
      (b) => StaffCoursePage.fromJson(asJsonObject(endpoint, b)),
    );
  }

  Future<Course> course(String courseId) async {
    const endpoint = 'GET /courses/:id';
    final body = await _client.get(ApiPath.of(['courses', ApiPath.id(courseId)]));
    return parseResponse(endpoint, body, (b) => Course.fromJson(asJsonObject(endpoint, b)));
  }

  Future<CourseStats> stats(String courseId) async {
    const endpoint = 'GET /courses/:id/stats';
    final body = await _client.get(ApiPath.of(['courses', ApiPath.id(courseId), 'stats']));
    return parseResponse(endpoint, body, (b) => CourseStats.fromJson(asJsonObject(endpoint, b)));
  }

  Future<CurriculumStats> curriculumStats(String courseId) async {
    const endpoint = 'GET /courses/:courseId/chapters/stats';
    final body = await _client.get(
      ApiPath.of(['courses', ApiPath.id(courseId), 'chapters', 'stats']),
    );
    return parseResponse(
      endpoint,
      body,
      (b) => CurriculumStats.fromJson(asJsonObject(endpoint, b)),
    );
  }

  Future<StaffLessonPage> lessons(String courseId, {String? chapterId, String? search}) async {
    const endpoint = 'GET /courses/:courseId/lessons';
    final body = await _client.get(
      ApiPath.of(['courses', ApiPath.id(courseId), 'lessons']),
      query: {'chapterId': ?chapterId, 'search': ?search},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => StaffLessonPage.fromJson(asJsonObject(endpoint, b)),
    );
  }

  Future<StaffLessonDetail> lesson(String courseId, String lessonId) async {
    const endpoint = 'GET /courses/:courseId/lessons/:lessonId';
    final body = await _client.get(
      ApiPath.of(['courses', ApiPath.id(courseId), 'lessons', ApiPath.id(lessonId)]),
    );
    return parseResponse(
      endpoint,
      body,
      (b) => StaffLessonDetail.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// The categories the list's filter offers. Needs `catalog.view`, like the list itself.
  Future<StaffCategoryPage> categories() async {
    const endpoint = 'GET /categories';
    final body = await _client.get('/categories');
    return parseResponse(
      endpoint,
      body,
      (b) => StaffCategoryPage.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Takes a course live. A 409 carries the academy's own checklist; a 403 is an academy that
  /// asks an admin to review first, and says so in its own words.
  Future<Course> publish(String courseId) => _action(courseId, 'publish');

  Future<Course> unpublish(String courseId) => _action(courseId, 'unpublish');

  Future<Course> archive(String courseId) => _action(courseId, 'archive');

  /// Bringing a course back counts against the plan's `courses.max`, so it can be refused (§9).
  Future<Course> restore(String courseId) => _action(courseId, 'restore');

  Future<Course> _action(String courseId, String action) async {
    final endpoint = 'POST /courses/:id/$action';
    final body = await _client.post(ApiPath.of(['courses', ApiPath.id(courseId), action]));
    return parseResponse(endpoint, body, (b) => Course.fromJson(asJsonObject(endpoint, b)));
  }
}

final staffCoursesApiProvider = Provider<StaffCoursesApi>(
  (ref) => StaffCoursesApi(ref.watch(apiClientProvider)),
);
