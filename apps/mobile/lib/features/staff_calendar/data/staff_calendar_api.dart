import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/dates_ist.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import 'dto/calendar_event.dart';

/// `apps/api/src/routes/calendar.ts` — the academy's teaching schedule. The range is asked for in
/// **IST calendar dates**, which is how the route reads `from` and `to` (§21). An instructor is
/// served their own events and their courses'; the token decides (§7).
class StaffCalendarApi {
  StaffCalendarApi(this._client);

  final ApiClient _client;

  /// Every event between two IST days, inclusive.
  Future<CalendarPage> range({
    required DateTime fromIstDay,
    required DateTime toIstDay,
    List<CalendarEventType> types = const [],
    String? courseId,
    String? instructorId,
  }) async {
    const endpoint = 'GET /calendar';
    final body = await _client.get(
      '/calendar',
      query: {
        'from': DatesIst.queryDate(fromIstDay),
        'to': DatesIst.queryDate(toIstDay),
        if (types.isNotEmpty) 'types': [for (final type in types) type.name],
        'courseId': ?courseId,
        'instructorId': ?instructorId,
      },
    );
    return parseResponse(endpoint, body, (b) => CalendarPage.fromJson(asJsonObject(endpoint, b)));
  }

  Future<CalendarDetail> event(String eventId) async {
    const endpoint = 'GET /calendar/:id';
    final body = await _client.get(ApiPath.of(['calendar', ApiPath.id(eventId)]));
    return parseResponse(endpoint, body, (b) => CalendarDetail.fromJson(asJsonObject(endpoint, b)));
  }

  /// Adds an event. The route wraps the input in `{input: …}` on create and takes it bare on save
  /// (finding 30), so the two calls differ by exactly that.
  Future<CalendarEvent> create(CalendarEventForm form) async {
    const endpoint = 'POST /calendar';
    final body = await _client.post('/calendar', body: {'input': form.toInput()});
    return parseResponse(endpoint, body, (b) => CalendarEvent.fromJson(asJsonObject(endpoint, b)));
  }

  Future<CalendarEvent> save(String eventId, CalendarEventForm form) async {
    const endpoint = 'PATCH /calendar/:id';
    final body = await _client.patch(
      ApiPath.of(['calendar', ApiPath.id(eventId)]),
      body: form.toInput(),
    );
    return parseResponse(endpoint, body, (b) => CalendarEvent.fromJson(asJsonObject(endpoint, b)));
  }

  Future<void> remove(String eventId) =>
      _client.delete(ApiPath.of(['calendar', ApiPath.id(eventId)]));

  /// Marks a reminder done, or not done again.
  Future<CalendarEvent> setDone(String eventId, {required bool done}) async {
    const endpoint = 'POST /calendar/:id/done';
    final body = await _client.post(
      ApiPath.of(['calendar', ApiPath.id(eventId), 'done']),
      body: {'done': done},
    );
    return parseResponse(endpoint, body, (b) => CalendarEvent.fromJson(asJsonObject(endpoint, b)));
  }
}

final staffCalendarApiProvider = Provider<StaffCalendarApi>(
  (ref) => StaffCalendarApi(ref.watch(apiClientProvider)),
);
