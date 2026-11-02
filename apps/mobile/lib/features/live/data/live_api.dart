import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import '../../../shared/domain/live_class.dart';

/// `apps/api/src/routes/live.ts` — the learner's own live classes. There is no learner endpoint
/// for a single class: the schedule carries everything the detail screen shows (§14).
class LiveApi {
  LiveApi(this._client);

  final ApiClient _client;

  Future<LiveSchedule> schedule() async {
    const endpoint = 'GET /live/learner';
    final body = await _client.get('/live/learner');
    return parseResponse(endpoint, body, (b) => LiveSchedule.fromJson(asJsonObject(endpoint, b)));
  }

  /// Takes a seat ([registered] true), or gives it up (false). The learner's wish is sent as it is,
  /// so a double tap or a retry lands in the same place rather than flipping it back; the academy
  /// answers with what it now holds. A refusal (cancelled, ended, full, not enrolled, access ended)
  /// comes back as its own error.
  Future<LiveRegistration> register(String liveClassId, {required bool registered}) async {
    const endpoint = 'POST /live/:id/register';
    final body = await _client.post(
      ApiPath.of(['live', ApiPath.id(liveClassId), 'register']),
      body: {'registered': registered},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => LiveRegistration.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// The way into a class that is on. The academy takes a place for the learner if they had none
  /// (and there is one) and answers with the built-in room — which it records as joined — or the
  /// outside meeting's link, which is handed out only here and only inside the join window.
  Future<LiveJoin> join(String liveClassId) async {
    const endpoint = 'POST /live/:id/join';
    final body = await _client.post(ApiPath.of(['live', ApiPath.id(liveClassId), 'join']));
    return parseResponse(endpoint, body, (b) => LiveJoin.fromJson(asJsonObject(endpoint, b)));
  }

  /// Where the kept recording plays from, for the player to open with the learner's own token.
  static String recordingPath(String liveClassId) =>
      ApiPath.of(['live', ApiPath.id(liveClassId), 'recording']);
}

final liveApiProvider = Provider<LiveApi>((ref) => LiveApi(ref.watch(apiClientProvider)));
