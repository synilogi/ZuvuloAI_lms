// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_view.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LessonLink _$LessonLinkFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LessonLink', json, ($checkedConvert) {
      final val = _LessonLink(
        id: $checkedConvert('id', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        locked: $checkedConvert('locked', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$LessonLinkToJson(_LessonLink instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'locked': instance.locked,
};

_LessonPosition _$LessonPositionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LessonPosition', json, ($checkedConvert) {
      final val = _LessonPosition(
        index: $checkedConvert('index', (v) => (v as num?)?.toInt() ?? 0),
        total: $checkedConvert('total', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$LessonPositionToJson(_LessonPosition instance) => <String, dynamic>{
  'index': instance.index,
  'total': instance.total,
};

_LessonView _$LessonViewFromJson(Map<String, dynamic> json) => $checkedCreate('_LessonView', json, (
  $checkedConvert,
) {
  final val = _LessonView(
    course: $checkedConvert('course', (v) => Course.fromJson(v as Map<String, dynamic>)),
    lesson: $checkedConvert('lesson', (v) => Lesson.fromJson(v as Map<String, dynamic>)),
    snapshot: $checkedConvert(
      'snapshot',
      (v) => CourseProgressSnapshot.fromJson(v as Map<String, dynamic>),
    ),
    progress: $checkedConvert(
      'progress',
      (v) => ProgressSummary.fromJson(v as Map<String, dynamic>),
    ),
    enrolled: $checkedConvert('enrolled', (v) => v as bool? ?? false),
    chapterIndex: $checkedConvert('chapterIndex', (v) => (v as num?)?.toInt() ?? 0),
    lessonIndex: $checkedConvert('lessonIndex', (v) => (v as num?)?.toInt() ?? 0),
    number: $checkedConvert('number', (v) => v as String? ?? ''),
    position: $checkedConvert(
      'position',
      (v) =>
          v == null ? const LessonPosition() : LessonPosition.fromJson(v as Map<String, dynamic>),
    ),
    state: $checkedConvert(
      'state',
      (v) =>
          $enumDecodeNullable(_$ProgressStateEnumMap, v, unknownValue: ProgressState.unknown) ??
          ProgressState.notStarted,
    ),
    lessonProgress: $checkedConvert(
      'lessonProgress',
      (v) => v == null ? null : LessonProgress.fromJson(v as Map<String, dynamic>),
    ),
    access: $checkedConvert(
      'access',
      (v) =>
          $enumDecodeNullable(_$LessonAccessEnumMap, v, unknownValue: LessonAccess.unknown) ??
          LessonAccess.unknown,
    ),
    lockedReason: $checkedConvert('lockedReason', (v) => v as String?),
    previous: $checkedConvert(
      'previous',
      (v) => v == null ? null : LessonLink.fromJson(v as Map<String, dynamic>),
    ),
    next: $checkedConvert(
      'next',
      (v) => v == null ? null : LessonLink.fromJson(v as Map<String, dynamic>),
    ),
    quiz: $checkedConvert(
      'quiz',
      (v) => v == null ? null : LearnerQuiz.fromJson(v as Map<String, dynamic>),
    ),
    quizBest: $checkedConvert('quizBest', (v) => (v as num?)?.toInt()),
    assignment: $checkedConvert('assignment', (v) => _assignmentFrom(v)),
    instructorNames: $checkedConvert(
      'instructorNames',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
    ),
    note: $checkedConvert('note', (v) => v as String? ?? ''),
    bookmarked: $checkedConvert('bookmarked', (v) => v as bool? ?? false),
    threshold: $checkedConvert('threshold', (v) => (v as num?)?.toInt() ?? 0),
  );
  return val;
});

Map<String, dynamic> _$LessonViewToJson(_LessonView instance) => <String, dynamic>{
  'course': instance.course.toJson(),
  'lesson': instance.lesson.toJson(),
  'snapshot': instance.snapshot.toJson(),
  'progress': instance.progress.toJson(),
  'enrolled': instance.enrolled,
  'chapterIndex': instance.chapterIndex,
  'lessonIndex': instance.lessonIndex,
  'number': instance.number,
  'position': instance.position.toJson(),
  'state': _$ProgressStateEnumMap[instance.state]!,
  'lessonProgress': instance.lessonProgress?.toJson(),
  'access': _$LessonAccessEnumMap[instance.access]!,
  'lockedReason': instance.lockedReason,
  'previous': instance.previous?.toJson(),
  'next': instance.next?.toJson(),
  'quiz': instance.quiz?.toJson(),
  'quizBest': instance.quizBest,
  'instructorNames': instance.instructorNames,
  'note': instance.note,
  'bookmarked': instance.bookmarked,
  'threshold': instance.threshold,
};

const _$ProgressStateEnumMap = {
  ProgressState.locked: 'locked',
  ProgressState.notStarted: 'not-started',
  ProgressState.inProgress: 'in-progress',
  ProgressState.completed: 'completed',
  ProgressState.unknown: 'unknown',
};

const _$LessonAccessEnumMap = {
  LessonAccess.open: 'open',
  LessonAccess.locked: 'locked',
  LessonAccess.notEnrolled: 'not-enrolled',
  LessonAccess.unavailable: 'unavailable',
  LessonAccess.unknown: 'unknown',
};
