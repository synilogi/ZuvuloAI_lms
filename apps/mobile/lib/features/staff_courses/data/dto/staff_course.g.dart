// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StaffCoursePage _$StaffCoursePageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StaffCoursePage', json, ($checkedConvert) {
      final val = _StaffCoursePage(
        rows: $checkedConvert(
          'rows',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => Course.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <Course>[],
        ),
        total: $checkedConvert('total', (v) => (v as num?)?.toInt() ?? 0),
        counts: $checkedConvert(
          'counts',
          (v) =>
              (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, (e as num).toInt())) ??
              const <String, int>{},
        ),
      );
      return val;
    });

Map<String, dynamic> _$StaffCoursePageToJson(_StaffCoursePage instance) => <String, dynamic>{
  'rows': instance.rows.map((e) => e.toJson()).toList(),
  'total': instance.total,
  'counts': instance.counts,
};

_CourseLearnerRow _$CourseLearnerRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CourseLearnerRow', json, ($checkedConvert) {
      final val = _CourseLearnerRow(
        studentId: $checkedConvert('studentId', (v) => v as String? ?? ''),
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        progress: $checkedConvert('progress', (v) => v as num? ?? 0),
        enrolledAt: $checkedConvert(
          'enrolledAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        status: $checkedConvert('status', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CourseLearnerRowToJson(_CourseLearnerRow instance) => <String, dynamic>{
  'studentId': instance.studentId,
  'name': instance.name,
  'progress': instance.progress,
  'enrolledAt': const NullableUtcDateTimeConverter().toJson(instance.enrolledAt),
  'status': instance.status,
};

_ProgressBucket _$ProgressBucketFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ProgressBucket', json, ($checkedConvert) {
      final val = _ProgressBucket(
        label: $checkedConvert('label', (v) => v as String? ?? ''),
        value: $checkedConvert('value', (v) => v as num? ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$ProgressBucketToJson(_ProgressBucket instance) => <String, dynamic>{
  'label': instance.label,
  'value': instance.value,
};

_CourseStats _$CourseStatsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CourseStats', json, ($checkedConvert) {
      final val = _CourseStats(
        courseId: $checkedConvert('courseId', (v) => v as String? ?? ''),
        enrolled: $checkedConvert('enrolled', (v) => (v as num?)?.toInt() ?? 0),
        active: $checkedConvert('active', (v) => (v as num?)?.toInt() ?? 0),
        completionRate: $checkedConvert('completionRate', (v) => v as num? ?? 0),
        avgProgress: $checkedConvert('avgProgress', (v) => v as num? ?? 0),
        weekly: $checkedConvert(
          'weekly',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <TrendPoint>[],
        ),
        progressBuckets: $checkedConvert(
          'progressBuckets',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => ProgressBucket.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <ProgressBucket>[],
        ),
        recent: $checkedConvert(
          'recent',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CourseLearnerRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <CourseLearnerRow>[],
        ),
        upcomingLive: $checkedConvert('upcomingLive', (v) => (v as num?)?.toInt() ?? 0),
        certificatesIssued: $checkedConvert('certificatesIssued', (v) => (v as num?)?.toInt() ?? 0),
        reviewsWaiting: $checkedConvert('reviewsWaiting', (v) => (v as num?)?.toInt() ?? 0),
        totalMinutes: $checkedConvert('totalMinutes', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$CourseStatsToJson(_CourseStats instance) => <String, dynamic>{
  'courseId': instance.courseId,
  'enrolled': instance.enrolled,
  'active': instance.active,
  'completionRate': instance.completionRate,
  'avgProgress': instance.avgProgress,
  'weekly': instance.weekly.map((e) => e.toJson()).toList(),
  'progressBuckets': instance.progressBuckets.map((e) => e.toJson()).toList(),
  'recent': instance.recent.map((e) => e.toJson()).toList(),
  'upcomingLive': instance.upcomingLive,
  'certificatesIssued': instance.certificatesIssued,
  'reviewsWaiting': instance.reviewsWaiting,
  'totalMinutes': instance.totalMinutes,
};

_CurriculumStats _$CurriculumStatsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CurriculumStats', json, ($checkedConvert) {
      final val = _CurriculumStats(
        enrolled: $checkedConvert('enrolled', (v) => (v as num?)?.toInt() ?? 0),
        chapters: $checkedConvert(
          'chapters',
          (v) =>
              (v as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, ChapterProgressStat.fromJson(e as Map<String, dynamic>)),
              ) ??
              const <String, ChapterProgressStat>{},
        ),
        lessons: $checkedConvert(
          'lessons',
          (v) =>
              (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as num)) ??
              const <String, num>{},
        ),
      );
      return val;
    });

Map<String, dynamic> _$CurriculumStatsToJson(_CurriculumStats instance) => <String, dynamic>{
  'enrolled': instance.enrolled,
  'chapters': instance.chapters.map((k, e) => MapEntry(k, e.toJson())),
  'lessons': instance.lessons,
};

_ChapterProgressStat _$ChapterProgressStatFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ChapterProgressStat', json, ($checkedConvert) {
      final val = _ChapterProgressStat(
        completionRate: $checkedConvert('completionRate', (v) => v as num? ?? 0),
        startedRate: $checkedConvert('startedRate', (v) => v as num? ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$ChapterProgressStatToJson(_ChapterProgressStat instance) =>
    <String, dynamic>{
      'completionRate': instance.completionRate,
      'startedRate': instance.startedRate,
    };

_StaffLessonRow _$StaffLessonRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StaffLessonRow', json, ($checkedConvert) {
      final val = _StaffLessonRow(
        lesson: $checkedConvert('lesson', (v) => Lesson.fromJson(v as Map<String, dynamic>)),
        chapterId: $checkedConvert('chapterId', (v) => v as String? ?? ''),
        chapterTitle: $checkedConvert('chapterTitle', (v) => v as String? ?? ''),
        chapterIndex: $checkedConvert('chapterIndex', (v) => (v as num?)?.toInt() ?? 0),
        lessonIndex: $checkedConvert('lessonIndex', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$StaffLessonRowToJson(_StaffLessonRow instance) => <String, dynamic>{
  'lesson': instance.lesson.toJson(),
  'chapterId': instance.chapterId,
  'chapterTitle': instance.chapterTitle,
  'chapterIndex': instance.chapterIndex,
  'lessonIndex': instance.lessonIndex,
};

_StaffLessonPage _$StaffLessonPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StaffLessonPage', json, ($checkedConvert) {
      final val = _StaffLessonPage(
        rows: $checkedConvert(
          'rows',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => StaffLessonRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <StaffLessonRow>[],
        ),
        counts: $checkedConvert(
          'counts',
          (v) => v as Map<String, dynamic>? ?? const <String, dynamic>{},
        ),
      );
      return val;
    });

Map<String, dynamic> _$StaffLessonPageToJson(_StaffLessonPage instance) => <String, dynamic>{
  'rows': instance.rows.map((e) => e.toJson()).toList(),
  'counts': instance.counts,
};

_LessonLink _$LessonLinkFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LessonLink', json, ($checkedConvert) {
      final val = _LessonLink(
        id: $checkedConvert('id', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$LessonLinkToJson(_LessonLink instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
};

_StaffLessonDetail _$StaffLessonDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StaffLessonDetail', json, ($checkedConvert) {
      final val = _StaffLessonDetail(
        lesson: $checkedConvert('lesson', (v) => Lesson.fromJson(v as Map<String, dynamic>)),
        chapterId: $checkedConvert('chapterId', (v) => v as String? ?? ''),
        chapterTitle: $checkedConvert('chapterTitle', (v) => v as String? ?? ''),
        chapterIndex: $checkedConvert('chapterIndex', (v) => (v as num?)?.toInt() ?? 0),
        lessonIndex: $checkedConvert('lessonIndex', (v) => (v as num?)?.toInt() ?? 0),
        chapter: $checkedConvert(
          'chapter',
          (v) => v == null ? null : Chapter.fromJson(v as Map<String, dynamic>),
        ),
        previous: $checkedConvert(
          'previous',
          (v) => v == null ? null : LessonLink.fromJson(v as Map<String, dynamic>),
        ),
        next: $checkedConvert(
          'next',
          (v) => v == null ? null : LessonLink.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$StaffLessonDetailToJson(_StaffLessonDetail instance) => <String, dynamic>{
  'lesson': instance.lesson.toJson(),
  'chapterId': instance.chapterId,
  'chapterTitle': instance.chapterTitle,
  'chapterIndex': instance.chapterIndex,
  'lessonIndex': instance.lessonIndex,
  'chapter': instance.chapter?.toJson(),
  'previous': instance.previous?.toJson(),
  'next': instance.next?.toJson(),
};

_StaffCategoryRow _$StaffCategoryRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StaffCategoryRow', json, ($checkedConvert) {
      final val = _StaffCategoryRow(
        category: $checkedConvert(
          'category',
          (v) => CourseCategory.fromJson(v as Map<String, dynamic>),
        ),
        courseCount: $checkedConvert('courseCount', (v) => (v as num?)?.toInt() ?? 0),
        publishedCount: $checkedConvert('publishedCount', (v) => (v as num?)?.toInt() ?? 0),
        learnerCount: $checkedConvert('learnerCount', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$StaffCategoryRowToJson(_StaffCategoryRow instance) => <String, dynamic>{
  'category': instance.category.toJson(),
  'courseCount': instance.courseCount,
  'publishedCount': instance.publishedCount,
  'learnerCount': instance.learnerCount,
};

_StaffCategoryPage _$StaffCategoryPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StaffCategoryPage', json, ($checkedConvert) {
      final val = _StaffCategoryPage(
        rows: $checkedConvert(
          'rows',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => StaffCategoryRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <StaffCategoryRow>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$StaffCategoryPageToJson(_StaffCategoryPage instance) => <String, dynamic>{
  'rows': instance.rows.map((e) => e.toJson()).toList(),
};
