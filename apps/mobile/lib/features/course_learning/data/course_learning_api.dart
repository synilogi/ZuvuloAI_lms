import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import '../../../shared/domain/learning.dart';
import 'dto/learner_course_detail.dart';
import 'dto/lesson_view.dart';

/// `apps/api/src/routes/learning.ts` — one course as the learner sees it, saving, and enrolling.
/// None of these calls carries a body: the price, the source and the status are the server's
/// (§7, §18). Enrolling is idempotent.
class CourseLearningApi {
  CourseLearningApi(this._client);

  final ApiClient _client;

  Future<LearnerCourseDetail> course(String courseId) async {
    const endpoint = 'GET /learning/courses/:courseId';
    final body = await _client.get(ApiPath.of(['learning', 'courses', ApiPath.id(courseId)]));
    return parseResponse(
      endpoint,
      body,
      (b) => LearnerCourseDetail.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Toggles saving and returns what the server now holds.
  Future<bool> toggleSaved(String courseId) async {
    const endpoint = 'POST /learning/courses/:courseId/save';
    final body = await _client.post(
      ApiPath.of(['learning', 'courses', ApiPath.id(courseId), 'save']),
    );
    return parseResponse(endpoint, body, (b) => asJsonObject(endpoint, b)['saved'] == true);
  }

  /// One lesson. Reading it **records the visit** on the server: that is what drives "recently
  /// viewed", resume and at-risk detection, so the app never keeps that tally itself.
  Future<LessonView> lesson({required String courseId, required String lessonId}) async {
    const endpoint = 'GET /learning/courses/:courseId/lessons/:lessonId';
    final body = await _client.get(
      ApiPath.of(['learning', 'courses', ApiPath.id(courseId), 'lessons', ApiPath.id(lessonId)]),
    );
    return parseResponse(endpoint, body, (b) => LessonView.fromJson(asJsonObject(endpoint, b)));
  }

  /// Asks the server to mark the lesson done. It applies the academy's completion rule and
  /// answers 409 with the sentence the learner should read; the app never decides this (§18).
  Future<CompleteResult> complete({required String courseId, required String lessonId}) async {
    const endpoint = 'POST /learning/courses/:courseId/lessons/:lessonId/complete';
    final body = await _client.post(
      ApiPath.of([
        'learning',
        'courses',
        ApiPath.id(courseId),
        'lessons',
        ApiPath.id(lessonId),
        'complete',
      ]),
    );
    return parseResponse(endpoint, body, (b) => CompleteResult.fromJson(asJsonObject(endpoint, b)));
  }

  /// Reports how far through a video the learner is. Idempotent, so a lost report is simply
  /// retried; the server decides whether that position completes the lesson.
  Future<void> reportPosition({
    required String courseId,
    required String lessonId,
    required int positionSec,
    required double fraction,
  }) async {
    await _client.put(
      ApiPath.of([
        'learning',
        'courses',
        ApiPath.id(courseId),
        'lessons',
        ApiPath.id(lessonId),
        'position',
      ]),
      body: {'positionSec': positionSec, 'fraction': fraction.clamp(0.0, 1.0)},
      idempotent: true,
    );
  }

  /// Saves the learner's note and answers when it was stored.
  Future<DateTime> saveNote({
    required String courseId,
    required String lessonId,
    required String text,
  }) async {
    const endpoint = 'PUT /learning/courses/:courseId/lessons/:lessonId/note';
    final body = await _client.put(
      ApiPath.of([
        'learning',
        'courses',
        ApiPath.id(courseId),
        'lessons',
        ApiPath.id(lessonId),
        'note',
      ]),
      body: {'text': text},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => DateTime.parse('${asJsonObject(endpoint, b)['savedAt']}').toUtc(),
    );
  }

  Future<bool> toggleBookmark({required String courseId, required String lessonId}) async {
    const endpoint = 'POST /learning/courses/:courseId/lessons/:lessonId/bookmark';
    final body = await _client.post(
      ApiPath.of([
        'learning',
        'courses',
        ApiPath.id(courseId),
        'lessons',
        ApiPath.id(lessonId),
        'bookmark',
      ]),
    );
    return parseResponse(endpoint, body, (b) => asJsonObject(endpoint, b)['bookmarked'] == true);
  }

  /// Enrols this learner. The academy's policy, their suspension and the course's visibility are
  /// all decided by the server, which answers 409 or 404 with its own words.
  Future<LearnerCourse> enroll(String courseId) async {
    const endpoint = 'POST /learning/courses/:courseId/enroll';
    final body = await _client.post(
      ApiPath.of(['learning', 'courses', ApiPath.id(courseId), 'enroll']),
    );
    return parseResponse(endpoint, body, (b) => LearnerCourse.fromJson(asJsonObject(endpoint, b)));
  }
}

final courseLearningApiProvider = Provider<CourseLearningApi>(
  (ref) => CourseLearningApi(ref.watch(apiClientProvider)),
);
