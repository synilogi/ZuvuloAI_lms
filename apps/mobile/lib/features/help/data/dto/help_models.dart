import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';

part 'help_models.freezed.dart';
part 'help_models.g.dart';

/// Who an article is written for (`packages/domain/src/help.ts`). The app always sends one: the
/// route treats a missing `audience` as "show everything", which would leak staff articles to a
/// visitor (`apps/api/src/routes/help.ts`, `visibleTo`).
enum HelpAudience {
  all,
  student,
  instructor,
  admin;

  /// The value sent as `?audience=`.
  String get wire => name;
}

/// `HelpCategoryIcon` — a closed set, so every category has a glyph.
enum HelpCategoryIcon { rocket, book, clipboard, video, certificate, chart, gear, users, unknown }

@freezed
abstract class HelpCategory with _$HelpCategory {
  const factory HelpCategory({
    required String id,
    required String name,
    @Default('') String description,
    @JsonKey(unknownEnumValue: HelpCategoryIcon.unknown)
    @Default(HelpCategoryIcon.unknown)
    HelpCategoryIcon icon,
    @Default(0) int order,
  }) = _HelpCategory;

  factory HelpCategory.fromJson(Map<String, dynamic> json) => _$HelpCategoryFromJson(json);
}

/// One tile on the hub: the category and how many articles this audience may read.
@freezed
abstract class HelpCategorySummary with _$HelpCategorySummary {
  const factory HelpCategorySummary({
    required HelpCategory category,
    @Default(0) int articleCount,
  }) = _HelpCategorySummary;

  factory HelpCategorySummary.fromJson(Map<String, dynamic> json) =>
      _$HelpCategorySummaryFromJson(json);
}

@freezed
abstract class HelpArticle with _$HelpArticle {
  const factory HelpArticle({
    required String id,
    required String slug,
    required String categoryId,
    required String title,
    @Default('') String summary,
    @Default('') String body,
    @JsonKey(unknownEnumValue: HelpAudience.all) @Default(HelpAudience.all) HelpAudience audience,
    @Default(<String>[]) List<String> tags,
    @Default(0) int readMinutes,
    @UtcDateTimeConverter() required DateTime updatedAt,
    @Default(false) bool popular,
  }) = _HelpArticle;

  factory HelpArticle.fromJson(Map<String, dynamic> json) => _$HelpArticleFromJson(json);
}

/// An article in a list, with the name of the category it belongs to.
@freezed
abstract class HelpArticleListItem with _$HelpArticleListItem {
  const factory HelpArticleListItem({
    required HelpArticle article,
    @Default('') String categoryName,
  }) = _HelpArticleListItem;

  factory HelpArticleListItem.fromJson(Map<String, dynamic> json) =>
      _$HelpArticleListItemFromJson(json);
}

/// `GET /help/articles/:slug` — the article, its category and up to three others from it.
@freezed
abstract class HelpArticleDetail with _$HelpArticleDetail {
  const factory HelpArticleDetail({
    required HelpArticle article,
    @Default('') String categoryName,
    @Default(<HelpArticleListItem>[]) List<HelpArticleListItem> related,
  }) = _HelpArticleDetail;

  factory HelpArticleDetail.fromJson(Map<String, dynamic> json) =>
      _$HelpArticleDetailFromJson(json);
}
