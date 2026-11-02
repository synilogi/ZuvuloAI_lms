import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import '../../../shared/domain/assignment.dart';
import 'dto/staff_submission.dart';

/// `apps/api/src/routes/assignments.ts` — the staff side of coursework. Every route is scoped to
/// the courses the caller teaches by the token, never by a query (§7).
class StaffReviewApi {
  StaffReviewApi(this._client);

  static const pageSize = 20;

  final ApiClient _client;

  Future<ReviewQueue> queue() async {
    const endpoint = 'GET /assignments/review';
    final body = await _client.get('/assignments/review');
    return parseResponse(endpoint, body, (b) => ReviewQueue.fromJson(asJsonObject(endpoint, b)));
  }

  /// The hand-ins, filtered the way the queue's tabs offer. [assignmentId] uses the assignment's
  /// own route, which also checks the caller may see it.
  Future<SubmissionPage> submissions({
    String? assignmentId,
    String? courseId,
    String? filter,
    String? search,
    String? sort,
    int page = 1,
  }) async {
    final endpoint = assignmentId == null
        ? 'GET /assignments/submissions'
        : 'GET /assignments/:id/submissions';
    final path = assignmentId == null
        ? '/assignments/submissions'
        : ApiPath.of(['assignments', ApiPath.id(assignmentId), 'submissions']);
    final body = await _client.get(
      path,
      query: {
        'courseId': ?courseId,
        'filter': ?filter,
        'search': ?search,
        'sort': ?sort,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return parseResponse(endpoint, body, (b) => SubmissionPage.fromJson(asJsonObject(endpoint, b)));
  }

  Future<SubmissionDetail> submission(String submissionId) async {
    const endpoint = 'GET /assignments/submissions/:submissionId';
    final body = await _client.get(
      ApiPath.of(['assignments', 'submissions', ApiPath.id(submissionId)]),
    );
    return parseResponse(
      endpoint,
      body,
      (b) => SubmissionDetail.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Saves, returns or grades. The **score is the server's**: it applies the academy's late policy
  /// and answers with the submission it stored (§18). A `draft` decision is kept as `in-review`.
  Future<Submission> review(
    String submissionId, {
    required ReviewStatus decision,
    Map<String, num> scores = const {},
    num? points,
    String feedback = '',
    String? privateNote,
  }) async {
    const endpoint = 'POST /assignments/submissions/:submissionId/review';
    final body = await _client.post(
      ApiPath.of(['assignments', 'submissions', ApiPath.id(submissionId), 'review']),
      body: {
        'decision': decision == ReviewStatus.inReview ? 'draft' : decision.name,
        'scores': scores,
        'points': ?points,
        'feedback': feedback,
        'privateNote': ?privateNote,
      },
    );
    return parseResponse(endpoint, body, (b) => Submission.fromJson(asJsonObject(endpoint, b)));
  }

  /// Reminds the learners who still owe this assignment. An empty [studentIds] means every one of
  /// them — the route decides who is still missing, so the app never names a learner who has since
  /// handed in.
  Future<int> remind(String assignmentId, {List<String> studentIds = const []}) async {
    const endpoint = 'POST /assignments/:id/remind';
    final body = await _client.post(
      ApiPath.of(['assignments', ApiPath.id(assignmentId), 'remind']),
      body: {'studentIds': studentIds},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => asCount(endpoint, asJsonObject(endpoint, b)['sent']),
    );
  }

  /// The assignments themselves, for the queue's per-assignment picker.
  Future<StaffAssignmentPage> assignments({
    String? courseId,
    String? status,
    String? search,
  }) async {
    const endpoint = 'GET /assignments';
    final body = await _client.get(
      '/assignments',
      query: {'courseId': ?courseId, 'status': ?status, 'search': ?search},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => StaffAssignmentPage.fromJson(asJsonObject(endpoint, b)),
    );
  }
}

final staffReviewApiProvider = Provider<StaffReviewApi>(
  (ref) => StaffReviewApi(ref.watch(apiClientProvider)),
);
