import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import '../../../shared/domain/course.dart';
import '../../../shared/domain/level.dart';

/// `apps/api/src/routes/catalog.ts` — the public catalogue. Every route here is unauthenticated:
/// signed out, no bearer header is sent at all, and the academy comes from the host (§8).
class CatalogApi {
  CatalogApi(this._client);

  final ApiClient _client;

  Future<List<Level>> levels() async {
    const endpoint = 'GET /catalog/levels';
    final body = await _client.get('/catalog/levels');
    return parseResponse(
      endpoint,
      body,
      (b) => [
        for (final row in asJsonList(endpoint, b)) Level.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  Future<List<CourseCategory>> categories() async {
    const endpoint = 'GET /catalog/categories';
    final body = await _client.get('/catalog/categories');
    return parseResponse(
      endpoint,
      body,
      (b) => [
        for (final row in asJsonList(endpoint, b))
          CourseCategory.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  Future<List<Instructor>> instructors() async {
    const endpoint = 'GET /catalog/instructors';
    final body = await _client.get('/catalog/instructors');
    return parseResponse(
      endpoint,
      body,
      (b) => [
        for (final row in asJsonList(endpoint, b)) Instructor.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  /// The published, public courses, narrowed by the server. The list is unpaged; any text search
  /// happens on what came back.
  Future<List<Course>> courses({String? levelId, String? categoryId}) async {
    const endpoint = 'GET /catalog/courses';
    final body = await _client.get(
      '/catalog/courses',
      query: {'levelId': ?levelId, 'categoryId': ?categoryId},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => [
        for (final row in asJsonList(endpoint, b)) Course.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  /// One course by slug. Lesson bodies come back only for published free previews; every other
  /// lesson arrives with an empty `content`.
  Future<Course> course(String slug) async {
    const endpoint = 'GET /catalog/courses/:slug';
    final body = await _client.get(ApiPath.of(['catalog', 'courses', ApiPath.id(slug)]));
    return parseResponse(endpoint, body, (b) => Course.fromJson(asJsonObject(endpoint, b)));
  }
}

final catalogApiProvider = Provider<CatalogApi>((ref) => CatalogApi(ref.watch(apiClientProvider)));
