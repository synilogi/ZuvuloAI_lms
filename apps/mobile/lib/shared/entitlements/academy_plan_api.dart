import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/json.dart';
import 'dto/entitlements.dart';

/// Reads what the academy's plan lets its staff use: `GET /academy/plan`
/// (`apps/api/src/routes/academyPlan.ts`). Any admin or instructor may; a learner is refused (403)
/// and never asks. It carries no price, invoice or payment — the billing page is the admin's.
class AcademyPlanApi {
  AcademyPlanApi(this._client);

  final ApiClient _client;

  Future<AcademyPlan> read() async {
    const endpoint = 'GET /academy/plan';
    final body = await _client.get('/academy/plan');
    return parseResponse(endpoint, body, (b) => AcademyPlan.fromJson(asJsonObject(endpoint, b)));
  }
}

final academyPlanApiProvider = Provider<AcademyPlanApi>(
  (ref) => AcademyPlanApi(ref.watch(apiClientProvider)),
);
