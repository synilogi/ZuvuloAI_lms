import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';
import 'dto/learner_home.dart';

/// `apps/api/src/routes/learning.ts` — the learner's own workspace. Every route checks the
/// caller is a learner and not suspended; the app sends no student id, and never could
/// (§7, §18).
class LearningApi {
  LearningApi(this._client);

  final ApiClient _client;

  Future<LearnerHome> home() async {
    const endpoint = 'GET /learning/home';
    final body = await _client.get('/learning/home');
    return parseResponse(endpoint, body, (b) => LearnerHome.fromJson(asJsonObject(endpoint, b)));
  }

  Future<LearnerCourses> courses() async {
    const endpoint = 'GET /learning/courses';
    final body = await _client.get('/learning/courses');
    return parseResponse(endpoint, body, (b) => LearnerCourses.fromJson(asJsonObject(endpoint, b)));
  }
}

final learningApiProvider = Provider<LearningApi>(
  (ref) => LearningApi(ref.watch(apiClientProvider)),
);
