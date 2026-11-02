// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaFile _$MediaFileFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_MediaFile', json, ($checkedConvert) {
      final val = _MediaFile(
        name: $checkedConvert('name', (v) => v as String),
        sizeMb: $checkedConvert('sizeMb', (v) => (v as num?)?.toDouble() ?? 0),
        id: $checkedConvert('id', (v) => v as String?),
        url: $checkedConvert('url', (v) => v as String?),
        mime: $checkedConvert('mime', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$MediaFileToJson(_MediaFile instance) => <String, dynamic>{
  'name': instance.name,
  'sizeMb': instance.sizeMb,
  'id': instance.id,
  'url': instance.url,
  'mime': instance.mime,
};

_Price _$PriceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_Price', json, ($checkedConvert) {
      final val = _Price(
        amount: $checkedConvert('amount', (v) => (v as num).toInt()),
        currency: $checkedConvert('currency', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PriceToJson(_Price instance) => <String, dynamic>{
  'amount': instance.amount,
  'currency': instance.currency,
};

_LessonVideoMarker _$LessonVideoMarkerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LessonVideoMarker', json, ($checkedConvert) {
      final val = _LessonVideoMarker(
        atSec: $checkedConvert('atSec', (v) => (v as num).toInt()),
        title: $checkedConvert('title', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$LessonVideoMarkerToJson(_LessonVideoMarker instance) => <String, dynamic>{
  'atSec': instance.atSec,
  'title': instance.title,
};

_VideoContent _$VideoContentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_VideoContent', json, ($checkedConvert) {
      final val = _VideoContent(
        file: $checkedConvert(
          'file',
          (v) => v == null ? null : MediaFile.fromJson(v as Map<String, dynamic>),
        ),
        durationSec: $checkedConvert('durationSec', (v) => (v as num?)?.toInt()),
        captions: $checkedConvert('captions', (v) => v as bool? ?? false),
        markers: $checkedConvert(
          'markers',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => LessonVideoMarker.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <LessonVideoMarker>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$VideoContentToJson(_VideoContent instance) => <String, dynamic>{
  'file': instance.file?.toJson(),
  'durationSec': instance.durationSec,
  'captions': instance.captions,
  'markers': instance.markers.map((e) => e.toJson()).toList(),
};

_ArticleContent _$ArticleContentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ArticleContent', json, ($checkedConvert) {
      final val = _ArticleContent(body: $checkedConvert('body', (v) => v as String? ?? ''));
      return val;
    });

Map<String, dynamic> _$ArticleContentToJson(_ArticleContent instance) => <String, dynamic>{
  'body': instance.body,
};

_DocumentContent _$DocumentContentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_DocumentContent', json, ($checkedConvert) {
      final val = _DocumentContent(
        file: $checkedConvert(
          'file',
          (v) => v == null ? null : MediaFile.fromJson(v as Map<String, dynamic>),
        ),
        pages: $checkedConvert('pages', (v) => (v as num?)?.toInt()),
        downloadable: $checkedConvert('downloadable', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$DocumentContentToJson(_DocumentContent instance) => <String, dynamic>{
  'file': instance.file?.toJson(),
  'pages': instance.pages,
  'downloadable': instance.downloadable,
};

_QuizContent _$QuizContentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_QuizContent', json, ($checkedConvert) {
      final val = _QuizContent(
        quizId: $checkedConvert('quizId', (v) => v as String?),
        questions: $checkedConvert('questions', (v) => (v as num?)?.toInt() ?? 0),
        passMark: $checkedConvert('passMark', (v) => (v as num?)?.toInt() ?? 0),
        attempts: $checkedConvert('attempts', (v) => (v as num?)?.toInt() ?? 0),
        timeLimitMin: $checkedConvert('timeLimitMin', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$QuizContentToJson(_QuizContent instance) => <String, dynamic>{
  'quizId': instance.quizId,
  'questions': instance.questions,
  'passMark': instance.passMark,
  'attempts': instance.attempts,
  'timeLimitMin': instance.timeLimitMin,
};

_AssignmentContent _$AssignmentContentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AssignmentContent', json, ($checkedConvert) {
      final val = _AssignmentContent(
        assignmentId: $checkedConvert('assignmentId', (v) => v as String?),
        brief: $checkedConvert('brief', (v) => v as String? ?? ''),
        dueAfterDays: $checkedConvert('dueAfterDays', (v) => (v as num?)?.toInt() ?? 0),
        maxScore: $checkedConvert('maxScore', (v) => (v as num?)?.toInt() ?? 0),
        submission: $checkedConvert('submission', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$AssignmentContentToJson(_AssignmentContent instance) => <String, dynamic>{
  'assignmentId': instance.assignmentId,
  'brief': instance.brief,
  'dueAfterDays': instance.dueAfterDays,
  'maxScore': instance.maxScore,
  'submission': instance.submission,
};

_LiveContent _$LiveContentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LiveContent', json, ($checkedConvert) {
      final val = _LiveContent(
        startsAt: $checkedConvert(
          'startsAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        durationMin: $checkedConvert('durationMin', (v) => (v as num?)?.toInt() ?? 0),
        recorded: $checkedConvert('recorded', (v) => v as bool? ?? false),
        liveClassId: $checkedConvert('liveClassId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$LiveContentToJson(_LiveContent instance) => <String, dynamic>{
  'startsAt': const NullableUtcDateTimeConverter().toJson(instance.startsAt),
  'durationMin': instance.durationMin,
  'recorded': instance.recorded,
  'liveClassId': instance.liveClassId,
};

_LessonContent _$LessonContentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LessonContent', json, ($checkedConvert) {
      final val = _LessonContent(
        video: $checkedConvert(
          'video',
          (v) => v == null ? null : VideoContent.fromJson(v as Map<String, dynamic>),
        ),
        article: $checkedConvert(
          'article',
          (v) => v == null ? null : ArticleContent.fromJson(v as Map<String, dynamic>),
        ),
        document: $checkedConvert(
          'document',
          (v) => v == null ? null : DocumentContent.fromJson(v as Map<String, dynamic>),
        ),
        quiz: $checkedConvert(
          'quiz',
          (v) => v == null ? null : QuizContent.fromJson(v as Map<String, dynamic>),
        ),
        assignment: $checkedConvert(
          'assignment',
          (v) => v == null ? null : AssignmentContent.fromJson(v as Map<String, dynamic>),
        ),
        live: $checkedConvert(
          'live',
          (v) => v == null ? null : LiveContent.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LessonContentToJson(_LessonContent instance) => <String, dynamic>{
  'video': instance.video?.toJson(),
  'article': instance.article?.toJson(),
  'document': instance.document?.toJson(),
  'quiz': instance.quiz?.toJson(),
  'assignment': instance.assignment?.toJson(),
  'live': instance.live?.toJson(),
};

_LessonSettings _$LessonSettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LessonSettings', json, ($checkedConvert) {
      final val = _LessonSettings(
        completion: $checkedConvert(
          'completion',
          (v) =>
              $enumDecodeNullable(_$CompletionRuleEnumMap, v, unknownValue: CompletionRule.unknown),
        ),
        sequential: $checkedConvert('sequential', (v) => v as bool? ?? false),
        discussion: $checkedConvert('discussion', (v) => v as bool? ?? false),
        resourcesDownloadable: $checkedConvert('resourcesDownloadable', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$LessonSettingsToJson(_LessonSettings instance) => <String, dynamic>{
  'completion': _$CompletionRuleEnumMap[instance.completion],
  'sequential': instance.sequential,
  'discussion': instance.discussion,
  'resourcesDownloadable': instance.resourcesDownloadable,
};

const _$CompletionRuleEnumMap = {
  CompletionRule.opened: 'opened',
  CompletionRule.watched: 'watched',
  CompletionRule.submitted: 'submitted',
  CompletionRule.passed: 'passed',
  CompletionRule.unknown: 'unknown',
};

_Lesson _$LessonFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_Lesson', json, ($checkedConvert) {
      final val = _Lesson(
        id: $checkedConvert('id', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        type: $checkedConvert('type', (v) => v as String),
        durationMin: $checkedConvert('durationMin', (v) => (v as num?)?.toInt() ?? 0),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(_$ContentStatusEnumMap, v, unknownValue: ContentStatus.unknown) ??
              ContentStatus.published,
        ),
        isPreview: $checkedConvert('isPreview', (v) => v as bool? ?? false),
        description: $checkedConvert('description', (v) => v as String?),
        objectives: $checkedConvert(
          'objectives',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        content: $checkedConvert(
          'content',
          (v) => v == null ? null : LessonContent.fromJson(v as Map<String, dynamic>),
        ),
        settings: $checkedConvert(
          'settings',
          (v) => v == null ? null : LessonSettings.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LessonToJson(_Lesson instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'type': instance.type,
  'durationMin': instance.durationMin,
  'status': _$ContentStatusEnumMap[instance.status]!,
  'isPreview': instance.isPreview,
  'description': instance.description,
  'objectives': instance.objectives,
  'content': instance.content?.toJson(),
  'settings': instance.settings?.toJson(),
};

const _$ContentStatusEnumMap = {
  ContentStatus.draft: 'draft',
  ContentStatus.published: 'published',
  ContentStatus.unknown: 'unknown',
};

_CatalogChapter _$CatalogChapterFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CatalogChapter', json, ($checkedConvert) {
      final val = _CatalogChapter(
        id: $checkedConvert('id', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        summary: $checkedConvert('summary', (v) => v as String?),
        objective: $checkedConvert('objective', (v) => v as String?),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(_$ContentStatusEnumMap, v, unknownValue: ContentStatus.unknown) ??
              ContentStatus.published,
        ),
        lessons: $checkedConvert(
          'lessons',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => Lesson.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <Lesson>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$CatalogChapterToJson(_CatalogChapter instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'summary': instance.summary,
  'objective': instance.objective,
  'status': _$ContentStatusEnumMap[instance.status]!,
  'lessons': instance.lessons.map((e) => e.toJson()).toList(),
};

_CatalogCourse _$CatalogCourseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CatalogCourse', json, ($checkedConvert) {
      final val = _CatalogCourse(
        id: $checkedConvert('id', (v) => v as String),
        slug: $checkedConvert('slug', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        subtitle: $checkedConvert('subtitle', (v) => v as String? ?? ''),
        description: $checkedConvert('description', (v) => v as String? ?? ''),
        levelId: $checkedConvert('levelId', (v) => v as String),
        categoryId: $checkedConvert('categoryId', (v) => v as String),
        instructorIds: $checkedConvert(
          'instructorIds',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        format: $checkedConvert(
          'format',
          (v) =>
              $enumDecodeNullable(_$CourseFormatEnumMap, v, unknownValue: CourseFormat.unknown) ??
              CourseFormat.selfPaced,
        ),
        language: $checkedConvert('language', (v) => v as String? ?? ''),
        coverMotif: $checkedConvert('coverMotif', (v) => v as String?),
        coverImageId: $checkedConvert('coverImageId', (v) => v as String?),
        coverImageUrl: $checkedConvert('coverImageUrl', (v) => v as String?),
        chapters: $checkedConvert(
          'chapters',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => Chapter.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <Chapter>[],
        ),
        liveSessions: $checkedConvert('liveSessions', (v) => (v as num?)?.toInt() ?? 0),
        estimatedWeeks: $checkedConvert('estimatedWeeks', (v) => (v as num?)?.toInt()),
        certificateTitle: $checkedConvert('certificateTitle', (v) => v as String?),
        price: $checkedConvert(
          'price',
          (v) => v == null ? null : Price.fromJson(v as Map<String, dynamic>),
        ),
        pricing: $checkedConvert(
          'pricing',
          (v) =>
              $enumDecodeNullable(_$CoursePricingEnumMap, v, unknownValue: CoursePricing.unknown),
        ),
        enrolledCount: $checkedConvert('enrolledCount', (v) => (v as num?)?.toInt() ?? 0),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(_$CourseStatusEnumMap, v, unknownValue: CourseStatus.unknown) ??
              CourseStatus.published,
        ),
        visibility: $checkedConvert(
          'visibility',
          (v) =>
              $enumDecodeNullable(
                _$CourseVisibilityEnumMap,
                v,
                unknownValue: CourseVisibility.unknown,
              ) ??
              CourseVisibility.public,
        ),
        outcomes: $checkedConvert(
          'outcomes',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        tags: $checkedConvert(
          'tags',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        rating: $checkedConvert('rating', (v) => (v as num?)?.toDouble()),
        ratingCount: $checkedConvert('ratingCount', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$CatalogCourseToJson(_CatalogCourse instance) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'title': instance.title,
  'subtitle': instance.subtitle,
  'description': instance.description,
  'levelId': instance.levelId,
  'categoryId': instance.categoryId,
  'instructorIds': instance.instructorIds,
  'format': _$CourseFormatEnumMap[instance.format]!,
  'language': instance.language,
  'coverMotif': instance.coverMotif,
  'coverImageId': instance.coverImageId,
  'coverImageUrl': instance.coverImageUrl,
  'chapters': instance.chapters.map((e) => e.toJson()).toList(),
  'liveSessions': instance.liveSessions,
  'estimatedWeeks': instance.estimatedWeeks,
  'certificateTitle': instance.certificateTitle,
  'price': instance.price?.toJson(),
  'pricing': _$CoursePricingEnumMap[instance.pricing],
  'enrolledCount': instance.enrolledCount,
  'status': _$CourseStatusEnumMap[instance.status]!,
  'visibility': _$CourseVisibilityEnumMap[instance.visibility]!,
  'outcomes': instance.outcomes,
  'tags': instance.tags,
  'rating': instance.rating,
  'ratingCount': instance.ratingCount,
};

const _$CourseFormatEnumMap = {
  CourseFormat.selfPaced: 'self-paced',
  CourseFormat.cohort: 'cohort',
  CourseFormat.hybrid: 'hybrid',
  CourseFormat.unknown: 'unknown',
};

const _$CoursePricingEnumMap = {
  CoursePricing.free: 'free',
  CoursePricing.paid: 'paid',
  CoursePricing.unset: 'unset',
  CoursePricing.unknown: 'unknown',
};

const _$CourseStatusEnumMap = {
  CourseStatus.draft: 'draft',
  CourseStatus.published: 'published',
  CourseStatus.archived: 'archived',
  CourseStatus.unknown: 'unknown',
};

const _$CourseVisibilityEnumMap = {
  CourseVisibility.public: 'public',
  CourseVisibility.unlisted: 'unlisted',
  CourseVisibility.private: 'private',
  CourseVisibility.unknown: 'unknown',
};

_CatalogCategory _$CatalogCategoryFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_CatalogCategory',
  json,
  ($checkedConvert) {
    final val = _CatalogCategory(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      description: $checkedConvert('description', (v) => v as String? ?? ''),
      levelIds: $checkedConvert(
        'levelIds',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
      ),
      order: $checkedConvert('order', (v) => (v as num?)?.toInt() ?? 0),
      status: $checkedConvert(
        'status',
        (v) =>
            $enumDecodeNullable(_$CategoryStatusEnumMap, v, unknownValue: CategoryStatus.unknown) ??
            CategoryStatus.active,
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$CatalogCategoryToJson(_CatalogCategory instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'levelIds': instance.levelIds,
  'order': instance.order,
  'status': _$CategoryStatusEnumMap[instance.status]!,
};

const _$CategoryStatusEnumMap = {
  CategoryStatus.active: 'active',
  CategoryStatus.hidden: 'hidden',
  CategoryStatus.unknown: 'unknown',
};

_CatalogInstructor _$CatalogInstructorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CatalogInstructor', json, ($checkedConvert) {
      final val = _CatalogInstructor(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        bio: $checkedConvert('bio', (v) => v as String? ?? ''),
        expertise: $checkedConvert(
          'expertise',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        yearsTeaching: $checkedConvert('yearsTeaching', (v) => (v as num?)?.toInt()),
        photo: $checkedConvert(
          'photo',
          (v) => v == null ? null : MediaFile.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CatalogInstructorToJson(_CatalogInstructor instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'title': instance.title,
  'bio': instance.bio,
  'expertise': instance.expertise,
  'yearsTeaching': instance.yearsTeaching,
  'photo': instance.photo?.toJson(),
};
