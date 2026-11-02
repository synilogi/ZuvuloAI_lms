import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import 'dto/learner_assignment.dart';

/// `apps/api/src/routes/learning.ts` — the learner's coursework. Nothing here carries a student
/// id: the routes act for whoever is signed in, and the server checks that every file sent back
/// belongs to them (`ownFiles`) (§7, §18).
class AssignmentsApi {
  AssignmentsApi(this._client);

  final ApiClient _client;

  Future<List<LearnerAssignment>> assignments() async {
    const endpoint = 'GET /learning/assignments';
    final body = await _client.get('/learning/assignments');
    return parseResponse(
      endpoint,
      body,
      (b) => [
        for (final row in asJsonList(endpoint, b))
          LearnerAssignment.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  Future<LearnerAssignment> assignment(String assignmentId) async {
    const endpoint = 'GET /learning/assignments/:assignmentId';
    final body = await _client.get(
      ApiPath.of(['learning', 'assignments', ApiPath.id(assignmentId)]),
    );
    return parseResponse(
      endpoint,
      body,
      (b) => LearnerAssignment.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Keeps the work on the server and answers when it was stored. Idempotent, so a lost save is
  /// simply made again.
  Future<DateTime> saveDraft({required String assignmentId, required AssignmentWork work}) async {
    const endpoint = 'PUT /learning/assignments/:assignmentId/draft';
    final body = await _client.put(
      ApiPath.of(['learning', 'assignments', ApiPath.id(assignmentId), 'draft']),
      body: _workBody(work),
      idempotent: true,
    );
    return parseResponse(
      endpoint,
      body,
      (b) => DateTime.parse('${asJsonObject(endpoint, b)['savedAt']}').toUtc(),
    );
  }

  /// Hands the work in. The academy decides whether it is late, whether late work is taken at all
  /// and whether this is a resubmission; each refusal comes back as a 409 in its own words.
  Future<LearnerAssignment> submit({
    required String assignmentId,
    required AssignmentWork work,
  }) async {
    const endpoint = 'POST /learning/assignments/:assignmentId/submit';
    final body = await _client.post(
      ApiPath.of(['learning', 'assignments', ApiPath.id(assignmentId), 'submit']),
      body: _workBody(work),
    );
    return parseResponse(
      endpoint,
      body,
      (b) => LearnerAssignment.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// The draft and the submission take the same body. A file is sent back as the media route
  /// returned it, so the server can check it is the learner's own.
  Map<String, Object?> _workBody(AssignmentWork work) => {
    'text': work.text,
    'files': [
      for (final file in work.files)
        {
          'id': ?file.id,
          'name': file.name,
          'sizeMb': file.sizeMb,
          'url': ?file.url,
          'mime': ?file.mime,
        },
    ],
    'chart': ?work.chart?.toJson(),
  };
}

final assignmentsApiProvider = Provider<AssignmentsApi>(
  (ref) => AssignmentsApi(ref.watch(apiClientProvider)),
);
