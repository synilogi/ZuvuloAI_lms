import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import 'dto/staff_quiz.dart';

/// `apps/api/src/routes/quizzes.ts` — the read side of the academy's quizzes. An instructor is
/// served only the quizzes of the courses they teach: the token decides, never the query (§7).
/// Building and editing a quiz stays on the web (§26).
class StaffQuizzesApi {
  StaffQuizzesApi(this._client);

  final ApiClient _client;

  Future<StaffQuizPage> quizzes({String? search, String? courseId, String? status}) async {
    const endpoint = 'GET /quizzes';
    final body = await _client.get(
      '/quizzes',
      query: {'search': ?search, 'courseId': ?courseId, 'status': ?status},
    );
    return parseResponse(endpoint, body, (b) => StaffQuizPage.fromJson(asJsonObject(endpoint, b)));
  }

  Future<StaffQuiz> quiz(String quizId) async {
    const endpoint = 'GET /quizzes/:id';
    final body = await _client.get(ApiPath.of(['quizzes', ApiPath.id(quizId)]));
    return parseResponse(endpoint, body, (b) => StaffQuiz.fromJson(asJsonObject(endpoint, b)));
  }

  Future<QuizStats> stats(String quizId) async {
    const endpoint = 'GET /quizzes/:id/stats';
    final body = await _client.get(ApiPath.of(['quizzes', ApiPath.id(quizId), 'stats']));
    return parseResponse(endpoint, body, (b) => QuizStats.fromJson(asJsonObject(endpoint, b)));
  }
}

final staffQuizzesApiProvider = Provider<StaffQuizzesApi>(
  (ref) => StaffQuizzesApi(ref.watch(apiClientProvider)),
);
