// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LessonProgress _$LessonProgressFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LessonProgress', json, ($checkedConvert) {
      final val = _LessonProgress(
        lessonId: $checkedConvert('lessonId', (v) => v as String),
        state: $checkedConvert(
          'state',
          (v) =>
              $enumDecodeNullable(_$ProgressStateEnumMap, v, unknownValue: ProgressState.unknown) ??
              ProgressState.notStarted,
        ),
        fraction: $checkedConvert('fraction', (v) => (v as num?)?.toDouble()),
        positionSec: $checkedConvert('positionSec', (v) => (v as num?)?.toInt()),
        completedAt: $checkedConvert(
          'completedAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LessonProgressToJson(_LessonProgress instance) => <String, dynamic>{
  'lessonId': instance.lessonId,
  'state': _$ProgressStateEnumMap[instance.state]!,
  'fraction': instance.fraction,
  'positionSec': instance.positionSec,
  'completedAt': const NullableUtcDateTimeConverter().toJson(instance.completedAt),
};

const _$ProgressStateEnumMap = {
  ProgressState.locked: 'locked',
  ProgressState.notStarted: 'not-started',
  ProgressState.inProgress: 'in-progress',
  ProgressState.completed: 'completed',
  ProgressState.unknown: 'unknown',
};

_CourseProgressSnapshot _$CourseProgressSnapshotFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CourseProgressSnapshot', json, ($checkedConvert) {
      final val = _CourseProgressSnapshot(
        courseId: $checkedConvert('courseId', (v) => v as String),
        lessons: $checkedConvert(
          'lessons',
          (v) =>
              (v as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, LessonProgress.fromJson(e as Map<String, dynamic>)),
              ) ??
              const <String, LessonProgress>{},
        ),
        lastLessonId: $checkedConvert('lastLessonId', (v) => v as String?),
        lastActiveAt: $checkedConvert(
          'lastActiveAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CourseProgressSnapshotToJson(_CourseProgressSnapshot instance) =>
    <String, dynamic>{
      'courseId': instance.courseId,
      'lessons': instance.lessons.map((k, e) => MapEntry(k, e.toJson())),
      'lastLessonId': instance.lastLessonId,
      'lastActiveAt': const NullableUtcDateTimeConverter().toJson(instance.lastActiveAt),
    };

_ProgressSummary _$ProgressSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ProgressSummary', json, ($checkedConvert) {
      final val = _ProgressSummary(
        completed: $checkedConvert('completed', (v) => (v as num?)?.toInt() ?? 0),
        total: $checkedConvert('total', (v) => (v as num?)?.toInt() ?? 0),
        percent: $checkedConvert('percent', (v) => (v as num?)?.toInt() ?? 0),
        remainingMin: $checkedConvert('remainingMin', (v) => (v as num?)?.toInt() ?? 0),
        state: $checkedConvert(
          'state',
          (v) =>
              $enumDecodeNullable(_$ProgressStateEnumMap, v, unknownValue: ProgressState.unknown) ??
              ProgressState.notStarted,
        ),
      );
      return val;
    });

Map<String, dynamic> _$ProgressSummaryToJson(_ProgressSummary instance) => <String, dynamic>{
  'completed': instance.completed,
  'total': instance.total,
  'percent': instance.percent,
  'remainingMin': instance.remainingMin,
  'state': _$ProgressStateEnumMap[instance.state]!,
};

_Enrollment _$EnrollmentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_Enrollment', json, ($checkedConvert) {
      final val = _Enrollment(
        id: $checkedConvert('id', (v) => v as String),
        studentId: $checkedConvert('studentId', (v) => v as String),
        courseId: $checkedConvert('courseId', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(
                _$EnrollmentStatusEnumMap,
                v,
                unknownValue: EnrollmentStatus.unknown,
              ) ??
              EnrollmentStatus.active,
        ),
        progress: $checkedConvert('progress', (v) => (v as num?)?.toInt() ?? 0),
        source: $checkedConvert('source', (v) => v as String? ?? ''),
        enrolledAt: $checkedConvert(
          'enrolledAt',
          (v) => const EmptyAsNullUtcDateTimeConverter().fromJson(v as String?),
        ),
        lastActiveAt: $checkedConvert(
          'lastActiveAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        completedAt: $checkedConvert(
          'completedAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        expiresAt: $checkedConvert(
          'expiresAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        lastLessonId: $checkedConvert('lastLessonId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$EnrollmentToJson(_Enrollment instance) => <String, dynamic>{
  'id': instance.id,
  'studentId': instance.studentId,
  'courseId': instance.courseId,
  'status': _$EnrollmentStatusEnumMap[instance.status]!,
  'progress': instance.progress,
  'source': instance.source,
  'enrolledAt': const EmptyAsNullUtcDateTimeConverter().toJson(instance.enrolledAt),
  'lastActiveAt': const NullableUtcDateTimeConverter().toJson(instance.lastActiveAt),
  'completedAt': const NullableUtcDateTimeConverter().toJson(instance.completedAt),
  'expiresAt': const NullableUtcDateTimeConverter().toJson(instance.expiresAt),
  'lastLessonId': instance.lastLessonId,
};

const _$EnrollmentStatusEnumMap = {
  EnrollmentStatus.active: 'active',
  EnrollmentStatus.completed: 'completed',
  EnrollmentStatus.paused: 'paused',
  EnrollmentStatus.expired: 'expired',
  EnrollmentStatus.unknown: 'unknown',
};

_NextLesson _$NextLessonFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_NextLesson', json, ($checkedConvert) {
      final val = _NextLesson(
        id: $checkedConvert('id', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        type: $checkedConvert('type', (v) => v as String? ?? ''),
        durationMin: $checkedConvert('durationMin', (v) => (v as num?)?.toInt() ?? 0),
        chapterIndex: $checkedConvert('chapterIndex', (v) => (v as num?)?.toInt() ?? 0),
        chapterTitle: $checkedConvert('chapterTitle', (v) => v as String? ?? ''),
        lessonNumber: $checkedConvert('lessonNumber', (v) => v as String? ?? ''),
        state: $checkedConvert(
          'state',
          (v) =>
              $enumDecodeNullable(_$ProgressStateEnumMap, v, unknownValue: ProgressState.unknown) ??
              ProgressState.notStarted,
        ),
        fraction: $checkedConvert('fraction', (v) => (v as num?)?.toDouble()),
        positionSec: $checkedConvert('positionSec', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$NextLessonToJson(_NextLesson instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'type': instance.type,
  'durationMin': instance.durationMin,
  'chapterIndex': instance.chapterIndex,
  'chapterTitle': instance.chapterTitle,
  'lessonNumber': instance.lessonNumber,
  'state': _$ProgressStateEnumMap[instance.state]!,
  'fraction': instance.fraction,
  'positionSec': instance.positionSec,
};
