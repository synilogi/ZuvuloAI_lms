// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StudyDayMinutes _$StudyDayMinutesFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StudyDayMinutes', json, ($checkedConvert) {
      final val = _StudyDayMinutes(
        date: $checkedConvert('date', (v) => v as String),
        minutes: $checkedConvert('minutes', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$StudyDayMinutesToJson(_StudyDayMinutes instance) => <String, dynamic>{
  'date': instance.date,
  'minutes': instance.minutes,
};

_StudyWeek _$StudyWeekFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StudyWeek', json, ($checkedConvert) {
      final val = _StudyWeek(
        label: $checkedConvert('label', (v) => v as String? ?? ''),
        detail: $checkedConvert('detail', (v) => v as String? ?? ''),
        minutes: $checkedConvert('minutes', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$StudyWeekToJson(_StudyWeek instance) => <String, dynamic>{
  'label': instance.label,
  'detail': instance.detail,
  'minutes': instance.minutes,
};

_LearningEvent _$LearningEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LearningEvent', json, ($checkedConvert) {
      final val = _LearningEvent(
        id: $checkedConvert('id', (v) => v as String),
        kind: $checkedConvert(
          'kind',
          (v) =>
              $enumDecodeNullable(_$ActivityKindEnumMap, v, unknownValue: ActivityKind.unknown) ??
              ActivityKind.unknown,
        ),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        context: $checkedConvert('context', (v) => v as String?),
        courseId: $checkedConvert('courseId', (v) => v as String?),
        at: $checkedConvert('at', (v) => const UtcDateTimeConverter().fromJson(v as String)),
      );
      return val;
    });

Map<String, dynamic> _$LearningEventToJson(_LearningEvent instance) => <String, dynamic>{
  'id': instance.id,
  'kind': _$ActivityKindEnumMap[instance.kind]!,
  'title': instance.title,
  'context': instance.context,
  'courseId': instance.courseId,
  'at': const UtcDateTimeConverter().toJson(instance.at),
};

const _$ActivityKindEnumMap = {
  ActivityKind.enrolled: 'enrolled',
  ActivityKind.lessonCompleted: 'lesson-completed',
  ActivityKind.chapterCompleted: 'chapter-completed',
  ActivityKind.liveAttended: 'live-attended',
  ActivityKind.assignmentSubmitted: 'assignment-submitted',
  ActivityKind.assessmentPassed: 'assessment-passed',
  ActivityKind.certificateIssued: 'certificate-issued',
  ActivityKind.rankAchieved: 'rank-achieved',
  ActivityKind.unknown: 'unknown',
};

_LearningActivity _$LearningActivityFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LearningActivity', json, ($checkedConvert) {
      final val = _LearningActivity(
        week: $checkedConvert(
          'week',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => StudyDayMinutes.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <StudyDayMinutes>[],
        ),
        events: $checkedConvert(
          'events',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => LearningEvent.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <LearningEvent>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$LearningActivityToJson(_LearningActivity instance) => <String, dynamic>{
  'week': instance.week.map((e) => e.toJson()).toList(),
  'events': instance.events.map((e) => e.toJson()).toList(),
};
