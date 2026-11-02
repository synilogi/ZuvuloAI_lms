import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import 'dto/help_models.dart';

/// `apps/api/src/routes/help.ts` — the knowledge base. Public: a visitor reads it signed out, and
/// the audience is always sent, because the route shows every article when it is omitted.
class HelpApi {
  HelpApi(this._client);

  final ApiClient _client;

  Future<List<HelpCategorySummary>> categories(HelpAudience audience) async {
    const endpoint = 'GET /help/categories';
    final body = await _client.get('/help/categories', query: {'audience': audience.wire});
    return parseResponse(
      endpoint,
      body,
      (b) => [
        for (final row in asJsonList(endpoint, b))
          HelpCategorySummary.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  Future<List<HelpArticleListItem>> articles({
    required HelpAudience audience,
    String? search,
    String? categoryId,
  }) async {
    const endpoint = 'GET /help/articles';
    final body = await _client.get(
      '/help/articles',
      query: {
        'audience': audience.wire,
        if (search != null && search.isNotEmpty) 'search': search,
        'categoryId': ?categoryId,
      },
    );
    return parseResponse(
      endpoint,
      body,
      (b) => [
        for (final row in asJsonList(endpoint, b))
          HelpArticleListItem.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  /// One article. An article this audience may not read answers 404, the same as a missing slug.
  Future<HelpArticleDetail> article({required String slug, required HelpAudience audience}) async {
    const endpoint = 'GET /help/articles/:slug';
    final body = await _client.get(
      ApiPath.of(['help', 'articles', ApiPath.id(slug)]),
      query: {'audience': audience.wire},
    );
    return parseResponse(
      endpoint,
      body,
      (b) => HelpArticleDetail.fromJson(asJsonObject(endpoint, b)),
    );
  }
}

final helpApiProvider = Provider<HelpApi>((ref) => HelpApi(ref.watch(apiClientProvider)));
