// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'help_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HelpCategory _$HelpCategoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_HelpCategory', json, ($checkedConvert) {
      final val = _HelpCategory(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String? ?? ''),
        icon: $checkedConvert(
          'icon',
          (v) =>
              $enumDecodeNullable(
                _$HelpCategoryIconEnumMap,
                v,
                unknownValue: HelpCategoryIcon.unknown,
              ) ??
              HelpCategoryIcon.unknown,
        ),
        order: $checkedConvert('order', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$HelpCategoryToJson(_HelpCategory instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'icon': _$HelpCategoryIconEnumMap[instance.icon]!,
  'order': instance.order,
};

const _$HelpCategoryIconEnumMap = {
  HelpCategoryIcon.rocket: 'rocket',
  HelpCategoryIcon.book: 'book',
  HelpCategoryIcon.clipboard: 'clipboard',
  HelpCategoryIcon.video: 'video',
  HelpCategoryIcon.certificate: 'certificate',
  HelpCategoryIcon.chart: 'chart',
  HelpCategoryIcon.gear: 'gear',
  HelpCategoryIcon.users: 'users',
  HelpCategoryIcon.unknown: 'unknown',
};

_HelpCategorySummary _$HelpCategorySummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_HelpCategorySummary', json, ($checkedConvert) {
      final val = _HelpCategorySummary(
        category: $checkedConvert(
          'category',
          (v) => HelpCategory.fromJson(v as Map<String, dynamic>),
        ),
        articleCount: $checkedConvert('articleCount', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$HelpCategorySummaryToJson(_HelpCategorySummary instance) =>
    <String, dynamic>{
      'category': instance.category.toJson(),
      'articleCount': instance.articleCount,
    };

_HelpArticle _$HelpArticleFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_HelpArticle', json, ($checkedConvert) {
      final val = _HelpArticle(
        id: $checkedConvert('id', (v) => v as String),
        slug: $checkedConvert('slug', (v) => v as String),
        categoryId: $checkedConvert('categoryId', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        summary: $checkedConvert('summary', (v) => v as String? ?? ''),
        body: $checkedConvert('body', (v) => v as String? ?? ''),
        audience: $checkedConvert(
          'audience',
          (v) =>
              $enumDecodeNullable(_$HelpAudienceEnumMap, v, unknownValue: HelpAudience.all) ??
              HelpAudience.all,
        ),
        tags: $checkedConvert(
          'tags',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        readMinutes: $checkedConvert('readMinutes', (v) => (v as num?)?.toInt() ?? 0),
        updatedAt: $checkedConvert(
          'updatedAt',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
        popular: $checkedConvert('popular', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$HelpArticleToJson(_HelpArticle instance) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'categoryId': instance.categoryId,
  'title': instance.title,
  'summary': instance.summary,
  'body': instance.body,
  'audience': _$HelpAudienceEnumMap[instance.audience]!,
  'tags': instance.tags,
  'readMinutes': instance.readMinutes,
  'updatedAt': const UtcDateTimeConverter().toJson(instance.updatedAt),
  'popular': instance.popular,
};

const _$HelpAudienceEnumMap = {
  HelpAudience.all: 'all',
  HelpAudience.student: 'student',
  HelpAudience.instructor: 'instructor',
  HelpAudience.admin: 'admin',
};

_HelpArticleListItem _$HelpArticleListItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_HelpArticleListItem', json, ($checkedConvert) {
      final val = _HelpArticleListItem(
        article: $checkedConvert('article', (v) => HelpArticle.fromJson(v as Map<String, dynamic>)),
        categoryName: $checkedConvert('categoryName', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$HelpArticleListItemToJson(_HelpArticleListItem instance) =>
    <String, dynamic>{'article': instance.article.toJson(), 'categoryName': instance.categoryName};

_HelpArticleDetail _$HelpArticleDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_HelpArticleDetail', json, ($checkedConvert) {
      final val = _HelpArticleDetail(
        article: $checkedConvert('article', (v) => HelpArticle.fromJson(v as Map<String, dynamic>)),
        categoryName: $checkedConvert('categoryName', (v) => v as String? ?? ''),
        related: $checkedConvert(
          'related',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => HelpArticleListItem.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <HelpArticleListItem>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$HelpArticleDetailToJson(_HelpArticleDetail instance) => <String, dynamic>{
  'article': instance.article.toJson(),
  'categoryName': instance.categoryName,
  'related': instance.related.map((e) => e.toJson()).toList(),
};
