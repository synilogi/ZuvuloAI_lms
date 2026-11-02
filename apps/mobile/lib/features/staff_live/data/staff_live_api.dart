import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import '../../../shared/domain/live_class.dart';
import 'dto/staff_live.dart';

/// `apps/api/src/routes/live.ts` — running live teaching. An instructor is served the classes of the
/// courses they teach and any they host; the token decides, never the query (§7).
class StaffLiveApi {
  StaffLiveApi(this._client);

  static const pageSize = 20;

  final ApiClient _client;

  Future<StaffLivePage> schedule({
    String? view,
    String? search,
    String? courseId,
    String? instructorId,
    int page = 1,
  }) async {
    const endpoint = 'GET /live';
    final body = await _client.get(
      '/live',
      query: {
        'view': ?view,
        'search': ?search,
        'courseId': ?courseId,
        'instructorId': ?instructorId,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return parseResponse(endpoint, body, (b) => StaffLivePage.fromJson(asJsonObject(endpoint, b)));
  }

  Future<StaffLiveDetail> liveClass(String liveId) async {
    const endpoint = 'GET /live/:id';
    final body = await _client.get(ApiPath.of(['live', ApiPath.id(liveId)]));
    return parseResponse(
      endpoint,
      body,
      (b) => StaffLiveDetail.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// Schedules a class. The academy validates it (`validateLiveClass`), counts it against the
  /// month's allowance and tells the enrolled learners — none of which the app does or repeats.
  Future<LiveClass> create(LiveClassForm form) async {
    const endpoint = 'POST /live';
    final body = await _client.post('/live', body: form.toBody());
    return parseResponse(endpoint, body, (b) => LiveClass.fromJson(asJsonObject(endpoint, b)));
  }

  /// Saves a class. The route takes the **whole** object, so the form sends every field back — a
  /// missing one would be read as a change.
  Future<LiveClass> save(String liveId, LiveClassForm form) async {
    const endpoint = 'PATCH /live/:id';
    final body = await _client.patch(ApiPath.of(['live', ApiPath.id(liveId)]), body: form.toBody());
    return parseResponse(endpoint, body, (b) => LiveClass.fromJson(asJsonObject(endpoint, b)));
  }

  /// Calls a class off. The reason is the academy's message to the learners it tells, so the route
  /// insists on one.
  Future<LiveClass> cancel(String liveId, {required String reason}) async {
    const endpoint = 'POST /live/:id/cancel';
    final body = await _client.post(
      ApiPath.of(['live', ApiPath.id(liveId), 'cancel']),
      body: {'reason': reason},
    );
    return parseResponse(endpoint, body, (b) => LiveClass.fromJson(asJsonObject(endpoint, b)));
  }

  /// Reminds the registered learners now. The count is the academy's own.
  Future<int> remind(String liveId) async {
    const endpoint = 'POST /live/:id/remind';
    final body = await _client.post(ApiPath.of(['live', ApiPath.id(liveId), 'remind']));
    return parseResponse(
      endpoint,
      body,
      (b) => asCount(endpoint, asJsonObject(endpoint, b)['sent']),
    );
  }

  /// Sets when the academy reminds learners, in minutes before the start.
  Future<LiveClass> setReminders(String liveId, List<int> reminders) async {
    const endpoint = 'PATCH /live/:id/reminders';
    final body = await _client.patch(
      ApiPath.of(['live', ApiPath.id(liveId), 'reminders']),
      body: {'reminders': reminders},
    );
    return parseResponse(endpoint, body, (b) => LiveClass.fromJson(asJsonObject(endpoint, b)));
  }

  /// Opens the built-in room — from 15 minutes before the start until the scheduled end. The academy
  /// tells the learners; starting an open room again is rejoining it.
  Future<LiveStarted> start(String liveId) async {
    const endpoint = 'POST /live/:id/start';
    final body = await _client.post(ApiPath.of(['live', ApiPath.id(liveId), 'start']));
    return parseResponse(endpoint, body, (b) => LiveStarted.fromJson(asJsonObject(endpoint, b)));
  }

  /// Back into an open room as its host.
  Future<LiveJoin> join(String liveId) async {
    const endpoint = 'POST /live/:id/join';
    final body = await _client.post(ApiPath.of(['live', ApiPath.id(liveId), 'join']));
    return parseResponse(endpoint, body, (b) => LiveJoin.fromJson(asJsonObject(endpoint, b)));
  }

  /// Closes the room. The academy marks whoever held a place and never came as missed.
  Future<LiveClass> end(String liveId) async {
    const endpoint = 'POST /live/:id/end';
    final body = await _client.post(ApiPath.of(['live', ApiPath.id(liveId), 'end']));
    return parseResponse(
      endpoint,
      body,
      (b) => LiveClass.fromJson(asJsonObject(endpoint, asJsonObject(endpoint, b)['liveClass'])),
    );
  }
}

final staffLiveApiProvider = Provider<StaffLiveApi>(
  (ref) => StaffLiveApi(ref.watch(apiClientProvider)),
);
