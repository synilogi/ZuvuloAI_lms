import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import '../../../shared/domain/people.dart';
import 'dto/staff_student.dart';

/// `apps/api/src/routes/students.ts` — the academy's learners as staff read and support them. An
/// instructor is served only the learners enrolled in a course they teach, and only those courses'
/// enrolments and certificates: the token decides, never the query (§7).
class StaffStudentsApi {
  StaffStudentsApi(this._client);

  static const pageSize = 20;

  /// The most learners one message may name, from the route's own schema.
  static const maxMessageRecipients = 500;

  final ApiClient _client;

  Future<RosterPage> students({
    String? search,
    String? courseId,
    String? status,
    String? sort,
    int page = 1,
  }) async {
    const endpoint = 'GET /students';
    final body = await _client.get(
      '/students',
      query: {
        'search': ?search,
        'courseId': ?courseId,
        'status': ?status,
        'sort': ?sort,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return parseResponse(endpoint, body, (b) => RosterPage.fromJson(asJsonObject(endpoint, b)));
  }

  Future<StudentProfile> student(String studentId) async {
    const endpoint = 'GET /students/:id';
    final body = await _client.get(ApiPath.of(['students', ApiPath.id(studentId)]));
    return parseResponse(endpoint, body, (b) => StudentProfile.fromJson(asJsonObject(endpoint, b)));
  }

  Future<StudentProgress> progress(String studentId) async {
    const endpoint = 'GET /students/:id/progress';
    final body = await _client.get(ApiPath.of(['students', ApiPath.id(studentId), 'progress']));
    return parseResponse(
      endpoint,
      body,
      (b) => StudentProgress.fromJson(asJsonObject(endpoint, b)),
    );
  }

  Future<StudentActivity> activity(String studentId, {String? kind, String? courseId}) async {
    const endpoint = 'GET /students/:id/activity';
    final body = await _client.get(
      ApiPath.of(['students', ApiPath.id(studentId), 'activity']),
      query: {'kind': ?kind, 'courseId': ?courseId},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => StudentActivity.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Messages the learners named. The route drops any id outside the caller's scope without saying
  /// so, and answers with how many it actually reached — which is what the app reports (§18).
  Future<int> message({
    required List<String> studentIds,
    required String subject,
    required String body,
    required Set<String> channels,
  }) async {
    const endpoint = 'POST /students/message';
    final response = await _client.post(
      '/students/message',
      body: {'ids': studentIds, 'subject': subject, 'body': body, 'channels': channels.toList()},
    );
    return parseResponse(
      endpoint,
      response,
      (b) => asCount(endpoint, asJsonObject(endpoint, b)['sent']),
    );
  }

  /// Enrols a learner. The academy decides the access length and whether the course is one this
  /// account may enrol into; the app sends no expiry and no price (§18).
  Future<Enrollment> enroll(String studentId, {required String courseId}) async {
    const endpoint = 'POST /students/:id/enroll';
    final body = await _client.post(
      ApiPath.of(['students', ApiPath.id(studentId), 'enroll']),
      body: {'courseId': courseId, 'source': 'admin'},
    );
    return parseResponse(endpoint, body, (b) => Enrollment.fromJson(asJsonObject(endpoint, b)));
  }

  Future<Enrollment> setEnrollmentStatus(String enrollmentId, {required bool paused}) async {
    const endpoint = 'PATCH /students/enrollments/:enrollmentId';
    final body = await _client.patch(
      ApiPath.of(['students', 'enrollments', ApiPath.id(enrollmentId)]),
      body: {'status': paused ? 'paused' : 'active'},
    );
    return parseResponse(endpoint, body, (b) => Enrollment.fromJson(asJsonObject(endpoint, b)));
  }

  Future<void> removeEnrollment(String enrollmentId) =>
      _client.delete(ApiPath.of(['students', 'enrollments', ApiPath.id(enrollmentId)]));

  /// Suspends or restores a learner. Admins with `learners.suspend` only; the route refuses anyone
  /// else, and the app does not offer it to them either.
  Future<Student> setSuspended(String studentId, {required bool suspended, String? reason}) async {
    const endpoint = 'POST /students/:id/suspend';
    final body = await _client.post(
      ApiPath.of(['students', ApiPath.id(studentId), 'suspend']),
      body: {'suspended': suspended, 'reason': ?reason},
    );
    return parseResponse(endpoint, body, (b) => Student.fromJson(asJsonObject(endpoint, b)));
  }
}

final staffStudentsApiProvider = Provider<StaffStudentsApi>(
  (ref) => StaffStudentsApi(ref.watch(apiClientProvider)),
);
