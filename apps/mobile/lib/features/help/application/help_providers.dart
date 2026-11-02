import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/user_profile.dart';
import '../../../shared/session/current_user.dart';
import '../data/dto/help_models.dart';
import '../data/help_api.dart';

/// The help models the screens read (§26).
export '../data/dto/help_models.dart';

/// Which audience the help centre is read as: the signed-in person's role, or `all` for a
/// visitor and for a role this build does not serve.
final helpAudienceProvider = Provider<HelpAudience>((ref) {
  return switch (ref.watch(currentUserProvider)?.role) {
    UserRole.student => HelpAudience.student,
    UserRole.instructor => HelpAudience.instructor,
    UserRole.admin => HelpAudience.admin,
    _ => HelpAudience.all,
  };
});

/// The hub's search box. The route searches title, summary and tags, so the query goes to the
/// server — after a pause, so a request is not spent on every keystroke.
class HelpSearchNotifier extends Notifier<String> {
  static const debounce = Duration(milliseconds: 300);

  Timer? _timer;

  @override
  String build() {
    ref.onDispose(() => _timer?.cancel());
    return '';
  }

  void set(String query) {
    _timer?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = '';
      return;
    }
    _timer = Timer(debounce, () => state = trimmed);
  }
}

final helpSearchProvider = NotifierProvider<HelpSearchNotifier, String>(HelpSearchNotifier.new);

final helpCategoriesProvider = FutureProvider<List<HelpCategorySummary>>(
  (ref) => ref.watch(helpApiProvider).categories(ref.watch(helpAudienceProvider)),
);

/// What a list of articles is narrowed by.
@immutable
class HelpArticleQuery {
  const HelpArticleQuery({this.search, this.categoryId});

  final String? search;
  final String? categoryId;

  @override
  bool operator ==(Object other) =>
      other is HelpArticleQuery && other.search == search && other.categoryId == categoryId;

  @override
  int get hashCode => Object.hash(search, categoryId);
}

final helpArticlesProvider = FutureProvider.family<List<HelpArticleListItem>, HelpArticleQuery>((
  ref,
  query,
) {
  return ref
      .watch(helpApiProvider)
      .articles(
        audience: ref.watch(helpAudienceProvider),
        search: query.search,
        categoryId: query.categoryId,
      );
}, isAutoDispose: true);

final helpArticleProvider = FutureProvider.family<HelpArticleDetail, String>(
  (ref, slug) =>
      ref.watch(helpApiProvider).article(slug: slug, audience: ref.watch(helpAudienceProvider)),
  isAutoDispose: true,
);
