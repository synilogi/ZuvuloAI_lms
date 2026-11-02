// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learner_home.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpcomingItem _$UpcomingItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_UpcomingItem', json, ($checkedConvert) {
      final val = _UpcomingItem(
        id: $checkedConvert('id', (v) => v as String),
        kind: $checkedConvert(
          'kind',
          (v) =>
              $enumDecodeNullable(_$UpcomingKindEnumMap, v, unknownValue: UpcomingKind.unknown) ??
              UpcomingKind.unknown,
        ),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        context: $checkedConvert('context', (v) => v as String? ?? ''),
        at: $checkedConvert('at', (v) => const UtcDateTimeConverter().fromJson(v as String)),
        to: $checkedConvert('to', (v) => v as String? ?? ''),
        flag: $checkedConvert(
          'flag',
          (v) => $enumDecodeNullable(_$UpcomingFlagEnumMap, v, unknownValue: UpcomingFlag.unknown),
        ),
      );
      return val;
    });

Map<String, dynamic> _$UpcomingItemToJson(_UpcomingItem instance) => <String, dynamic>{
  'id': instance.id,
  'kind': _$UpcomingKindEnumMap[instance.kind]!,
  'title': instance.title,
  'context': instance.context,
  'at': const UtcDateTimeConverter().toJson(instance.at),
  'to': instance.to,
  'flag': _$UpcomingFlagEnumMap[instance.flag],
};

const _$UpcomingKindEnumMap = {
  UpcomingKind.live: 'live',
  UpcomingKind.assignment: 'assignment',
  UpcomingKind.quiz: 'quiz',
  UpcomingKind.unknown: 'unknown',
};

const _$UpcomingFlagEnumMap = {
  UpcomingFlag.liveNow: 'live-now',
  UpcomingFlag.startingSoon: 'starting-soon',
  UpcomingFlag.overdue: 'overdue',
  UpcomingFlag.dueSoon: 'due-soon',
  UpcomingFlag.unknown: 'unknown',
};

_RecentLesson _$RecentLessonFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_RecentLesson', json, ($checkedConvert) {
      final val = _RecentLesson(
        courseId: $checkedConvert('courseId', (v) => v as String),
        lessonId: $checkedConvert('lessonId', (v) => v as String),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
        lessonTitle: $checkedConvert('lessonTitle', (v) => v as String? ?? ''),
        type: $checkedConvert('type', (v) => v as String? ?? ''),
        at: $checkedConvert('at', (v) => const UtcDateTimeConverter().fromJson(v as String)),
        state: $checkedConvert('state', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$RecentLessonToJson(_RecentLesson instance) => <String, dynamic>{
  'courseId': instance.courseId,
  'lessonId': instance.lessonId,
  'courseTitle': instance.courseTitle,
  'lessonTitle': instance.lessonTitle,
  'type': instance.type,
  'at': const UtcDateTimeConverter().toJson(instance.at),
  'state': instance.state,
};

_LearnerHome _$LearnerHomeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LearnerHome', json, ($checkedConvert) {
      final val = _LearnerHome(
        firstName: $checkedConvert('firstName', (v) => v as String? ?? ''),
        courses: $checkedConvert(
          'courses',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => LearnerCourse.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <LearnerCourse>[],
        ),
        saved: $checkedConvert(
          'saved',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => SavedCourse.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <SavedCourse>[],
        ),
        recent: $checkedConvert(
          'recent',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => RecentLesson.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <RecentLesson>[],
        ),
        upcoming: $checkedConvert(
          'upcoming',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => UpcomingItem.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <UpcomingItem>[],
        ),
        week: $checkedConvert(
          'week',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => StudyDayMinutes.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <StudyDayMinutes>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$LearnerHomeToJson(_LearnerHome instance) => <String, dynamic>{
  'firstName': instance.firstName,
  'courses': instance.courses.map((e) => e.toJson()).toList(),
  'saved': instance.saved.map((e) => e.toJson()).toList(),
  'recent': instance.recent.map((e) => e.toJson()).toList(),
  'upcoming': instance.upcoming.map((e) => e.toJson()).toList(),
  'week': instance.week.map((e) => e.toJson()).toList(),
};

_LearnerCourses _$LearnerCoursesFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LearnerCourses', json, ($checkedConvert) {
      final val = _LearnerCourses(
        courses: $checkedConvert(
          'courses',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => LearnerCourse.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <LearnerCourse>[],
        ),
        saved: $checkedConvert(
          'saved',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => SavedCourse.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <SavedCourse>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$LearnerCoursesToJson(_LearnerCourses instance) => <String, dynamic>{
  'courses': instance.courses.map((e) => e.toJson()).toList(),
  'saved': instance.saved.map((e) => e.toJson()).toList(),
};
