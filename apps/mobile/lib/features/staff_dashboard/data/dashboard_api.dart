import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';
import '../../../shared/domain/dashboard.dart';

/// `apps/api/src/routes/dashboard.ts` — the staff dashboard, worked out by the server. Every
/// figure here is the academy's: the app only asks which scope to read (§18).
class DashboardApi {
  DashboardApi(this._client);

  final ApiClient _client;

  /// [instructorId] is the **admin's** scope picker. An instructor never sends one: the route
  /// scopes their dashboard to themselves, and asking for someone else's would be refused (§7).
  Future<DashboardSnapshot> snapshot({String? scope, String? instructorId}) async {
    const endpoint = 'GET /dashboard';
    final body = await _client.get(
      '/dashboard',
      query: {'scope': ?scope, 'instructorId': ?instructorId},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => DashboardSnapshot.fromJson(asJsonObject(endpoint, b)),
    );
  }

  /// The titles of the academy's courses, by id. The dashboard's course performance carries only
  /// an id (finding 22), and a **staff** list is the right source because it includes drafts.
  /// FLUTTER-019 builds the courses feature itself.
  Future<Map<String, String>> courseTitles() async {
    const endpoint = 'GET /courses';
    final body = await _client.get('/courses');
    return parseResponse(endpoint, body, (b) {
      final rows = asJsonObject(endpoint, b)['rows'];
      return {
        for (final row in asJsonList(endpoint, rows))
          '${(row as Map<String, dynamic>)['id']}': '${row['title']}',
      };
    });
  }

  /// The academy's instructors, for the admin's scope picker. Only the name and id are read here;
  /// FLUTTER-025 builds the instructors feature itself.
  Future<List<({String id, String name})>> instructors() async {
    const endpoint = 'GET /instructors';
    final body = await _client.get('/instructors');
    return parseResponse(endpoint, body, (b) {
      final rows = asJsonObject(endpoint, b)['rows'];
      return [
        for (final row in asJsonList(endpoint, rows))
          if ((row as Map<String, dynamic>)['instructor'] case final Map<String, dynamic> row?)
            (id: '${row['id']}', name: '${row['name']}'),
      ];
    });
  }
}

final dashboardApiProvider = Provider<DashboardApi>(
  (ref) => DashboardApi(ref.watch(apiClientProvider)),
);
