import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';
import '../../../shared/domain/activity.dart';

/// `apps/api/src/routes/learning.ts` — what this learner has been doing. Learner-only: the route
/// answers 400 for anyone else, so the profile asks only when a learner is signed in (§26).
class ActivityApi {
  ActivityApi(this._client);

  final ApiClient _client;

  Future<LearningActivity> activity() async {
    const endpoint = 'GET /learning/activity';
    final body = await _client.get('/learning/activity');
    return parseResponse(
      endpoint,
      body,
      (b) => LearningActivity.fromJson(asJsonObject(endpoint, b)),
    );
  }
}

final activityApiProvider = Provider<ActivityApi>(
  (ref) => ActivityApi(ref.watch(apiClientProvider)),
);
