// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LearnerCourse _$LearnerCourseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LearnerCourse', json, ($checkedConvert) {
      final val = _LearnerCourse(
        course: $checkedConvert('course', (v) => Course.fromJson(v as Map<String, dynamic>)),
        enrollment: $checkedConvert(
          'enrollment',
          (v) => Enrollment.fromJson(v as Map<String, dynamic>),
        ),
        progress: $checkedConvert(
          'progress',
          (v) => ProgressSummary.fromJson(v as Map<String, dynamic>),
        ),
        snapshot: $checkedConvert(
          'snapshot',
          (v) => CourseProgressSnapshot.fromJson(v as Map<String, dynamic>),
        ),
        next: $checkedConvert(
          'next',
          (v) => v == null ? null : NextLesson.fromJson(v as Map<String, dynamic>),
        ),
        instructorNames: $checkedConvert(
          'instructorNames',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        levelTitle: $checkedConvert('levelTitle', (v) => v as String? ?? ''),
        lastActiveAt: $checkedConvert(
          'lastActiveAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LearnerCourseToJson(_LearnerCourse instance) => <String, dynamic>{
  'course': instance.course.toJson(),
  'enrollment': instance.enrollment.toJson(),
  'progress': instance.progress.toJson(),
  'snapshot': instance.snapshot.toJson(),
  'next': instance.next?.toJson(),
  'instructorNames': instance.instructorNames,
  'levelTitle': instance.levelTitle,
  'lastActiveAt': const NullableUtcDateTimeConverter().toJson(instance.lastActiveAt),
};

_SavedCourse _$SavedCourseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_SavedCourse', json, ($checkedConvert) {
      final val = _SavedCourse(
        course: $checkedConvert('course', (v) => Course.fromJson(v as Map<String, dynamic>)),
        instructorNames: $checkedConvert(
          'instructorNames',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        levelTitle: $checkedConvert('levelTitle', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$SavedCourseToJson(_SavedCourse instance) => <String, dynamic>{
  'course': instance.course.toJson(),
  'instructorNames': instance.instructorNames,
  'levelTitle': instance.levelTitle,
};

_CompleteResult _$CompleteResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CompleteResult', json, ($checkedConvert) {
      final val = _CompleteResult(
        snapshot: $checkedConvert(
          'snapshot',
          (v) => CourseProgressSnapshot.fromJson(v as Map<String, dynamic>),
        ),
        progress: $checkedConvert(
          'progress',
          (v) => ProgressSummary.fromJson(v as Map<String, dynamic>),
        ),
        chapterCompleted: $checkedConvert('chapterCompleted', (v) => v as String?),
        courseCompleted: $checkedConvert('courseCompleted', (v) => v as bool? ?? false),
        nextLessonId: $checkedConvert('nextLessonId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CompleteResultToJson(_CompleteResult instance) => <String, dynamic>{
  'snapshot': instance.snapshot.toJson(),
  'progress': instance.progress.toJson(),
  'chapterCompleted': instance.chapterCompleted,
  'courseCompleted': instance.courseCompleted,
  'nextLessonId': instance.nextLessonId,
};
