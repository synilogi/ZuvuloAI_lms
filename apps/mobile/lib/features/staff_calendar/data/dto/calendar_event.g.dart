// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CalendarSource _$CalendarSourceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CalendarSource', json, ($checkedConvert) {
      final val = _CalendarSource(
        kind: $checkedConvert('kind', (v) => v as String? ?? ''),
        id: $checkedConvert('id', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$CalendarSourceToJson(_CalendarSource instance) => <String, dynamic>{
  'kind': instance.kind,
  'id': instance.id,
};

_CalendarEvent _$CalendarEventFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_CalendarEvent', json, ($checkedConvert) {
  final val = _CalendarEvent(
    id: $checkedConvert('id', (v) => v as String? ?? ''),
    type: $checkedConvert(
      'type',
      (v) =>
          $enumDecodeNullable(
            _$CalendarEventTypeEnumMap,
            v,
            unknownValue: CalendarEventType.unknown,
          ) ??
          CalendarEventType.unknown,
    ),
    title: $checkedConvert('title', (v) => v as String? ?? ''),
    description: $checkedConvert('description', (v) => v as String?),
    timing: $checkedConvert(
      'timing',
      (v) =>
          $enumDecodeNullable(_$CalendarTimingEnumMap, v, unknownValue: CalendarTiming.unknown) ??
          CalendarTiming.timed,
    ),
    startsAt: $checkedConvert(
      'startsAt',
      (v) => const UtcDateTimeConverter().fromJson(v as String),
    ),
    durationMin: $checkedConvert('durationMin', (v) => (v as num?)?.toInt()),
    courseId: $checkedConvert('courseId', (v) => v as String?),
    chapterId: $checkedConvert('chapterId', (v) => v as String?),
    instructorId: $checkedConvert('instructorId', (v) => v as String?),
    quizId: $checkedConvert('quizId', (v) => v as String?),
    milestone: $checkedConvert(
      'milestone',
      (v) => $enumDecodeNullable(_$MilestoneKindEnumMap, v, unknownValue: MilestoneKind.unknown),
    ),
    audience: $checkedConvert(
      'audience',
      (v) =>
          $enumDecodeNullable(_$ReminderAudienceEnumMap, v, unknownValue: ReminderAudience.unknown),
    ),
    ownerId: $checkedConvert('ownerId', (v) => v as String?),
    notifyMin: $checkedConvert('notifyMin', (v) => (v as num?)?.toInt()),
    done: $checkedConvert('done', (v) => v as bool? ?? false),
    cancelled: $checkedConvert('cancelled', (v) => v as bool? ?? false),
    source: $checkedConvert(
      'source',
      (v) => v == null ? null : CalendarSource.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$CalendarEventToJson(_CalendarEvent instance) => <String, dynamic>{
  'id': instance.id,
  'type': _$CalendarEventTypeEnumMap[instance.type]!,
  'title': instance.title,
  'description': instance.description,
  'timing': _$CalendarTimingEnumMap[instance.timing]!,
  'startsAt': const UtcDateTimeConverter().toJson(instance.startsAt),
  'durationMin': instance.durationMin,
  'courseId': instance.courseId,
  'chapterId': instance.chapterId,
  'instructorId': instance.instructorId,
  'quizId': instance.quizId,
  'milestone': _$MilestoneKindEnumMap[instance.milestone],
  'audience': _$ReminderAudienceEnumMap[instance.audience],
  'ownerId': instance.ownerId,
  'notifyMin': instance.notifyMin,
  'done': instance.done,
  'cancelled': instance.cancelled,
  'source': instance.source?.toJson(),
};

const _$CalendarEventTypeEnumMap = {
  CalendarEventType.live: 'live',
  CalendarEventType.assignment: 'assignment',
  CalendarEventType.quiz: 'quiz',
  CalendarEventType.milestone: 'milestone',
  CalendarEventType.reminder: 'reminder',
  CalendarEventType.unknown: 'unknown',
};

const _$CalendarTimingEnumMap = {
  CalendarTiming.timed: 'timed',
  CalendarTiming.moment: 'moment',
  CalendarTiming.allDay: 'all-day',
  CalendarTiming.unknown: 'unknown',
};

const _$MilestoneKindEnumMap = {
  MilestoneKind.cohortStarts: 'cohort-starts',
  MilestoneKind.chapterRelease: 'chapter-release',
  MilestoneKind.enrolmentCloses: 'enrolment-closes',
  MilestoneKind.cohortEnds: 'cohort-ends',
  MilestoneKind.courseLaunch: 'course-launch',
  MilestoneKind.unknown: 'unknown',
};

const _$ReminderAudienceEnumMap = {
  ReminderAudience.me: 'me',
  ReminderAudience.learners: 'learners',
  ReminderAudience.unknown: 'unknown',
};

_CalendarDue _$CalendarDueFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CalendarDue', json, ($checkedConvert) {
      final val = _CalendarDue(
        learners: $checkedConvert('learners', (v) => (v as num?)?.toInt() ?? 0),
        submitted: $checkedConvert('submitted', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$CalendarDueToJson(_CalendarDue instance) => <String, dynamic>{
  'learners': instance.learners,
  'submitted': instance.submitted,
};

_CalendarRow _$CalendarRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CalendarRow', json, ($checkedConvert) {
      final val = _CalendarRow(
        event: $checkedConvert('event', (v) => CalendarEvent.fromJson(v as Map<String, dynamic>)),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String?),
        instructorName: $checkedConvert('instructorName', (v) => v as String?),
        phase: $checkedConvert(
          'phase',
          (v) => $enumDecodeNullable(_$LivePhaseEnumMap, v, unknownValue: LivePhase.unknown),
        ),
        due: $checkedConvert(
          'due',
          (v) => v == null ? null : CalendarDue.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CalendarRowToJson(_CalendarRow instance) => <String, dynamic>{
  'event': instance.event.toJson(),
  'courseTitle': instance.courseTitle,
  'instructorName': instance.instructorName,
  'phase': _$LivePhaseEnumMap[instance.phase],
  'due': instance.due?.toJson(),
};

const _$LivePhaseEnumMap = {
  LivePhase.upcoming: 'upcoming',
  LivePhase.startingSoon: 'starting-soon',
  LivePhase.live: 'live',
  LivePhase.ended: 'ended',
  LivePhase.recordingExpired: 'recording-expired',
  LivePhase.cancelled: 'cancelled',
  LivePhase.unknown: 'unknown',
};

_CalendarPage _$CalendarPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CalendarPage', json, ($checkedConvert) {
      final val = _CalendarPage(
        rows: $checkedConvert(
          'rows',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CalendarRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <CalendarRow>[],
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

Map<String, dynamic> _$CalendarPageToJson(_CalendarPage instance) => <String, dynamic>{
  'rows': instance.rows.map((e) => e.toJson()).toList(),
  'total': instance.total,
  'counts': instance.counts,
};

_LearnerDue _$LearnerDueFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LearnerDue', json, ($checkedConvert) {
      final val = _LearnerDue(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        submitted: $checkedConvert('submitted', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$LearnerDueToJson(_LearnerDue instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'submitted': instance.submitted,
};

_CalendarLiveFacts _$CalendarLiveFactsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CalendarLiveFacts', json, ($checkedConvert) {
      final val = _CalendarLiveFacts(
        registered: $checkedConvert('registered', (v) => (v as num?)?.toInt() ?? 0),
        capacity: $checkedConvert('capacity', (v) => (v as num?)?.toInt()),
        attended: $checkedConvert('attended', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$CalendarLiveFactsToJson(_CalendarLiveFacts instance) => <String, dynamic>{
  'registered': instance.registered,
  'capacity': instance.capacity,
  'attended': instance.attended,
};

_CalendarQuizFacts _$CalendarQuizFactsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CalendarQuizFacts', json, ($checkedConvert) {
      final val = _CalendarQuizFacts(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        status: $checkedConvert('status', (v) => v as String? ?? ''),
        questions: $checkedConvert('questions', (v) => (v as num?)?.toInt() ?? 0),
        timeLimitMin: $checkedConvert('timeLimitMin', (v) => (v as num?)?.toInt()),
        attempts: $checkedConvert('attempts', (v) => (v as num?)?.toInt()),
        passMark: $checkedConvert('passMark', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$CalendarQuizFactsToJson(_CalendarQuizFacts instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'status': instance.status,
  'questions': instance.questions,
  'timeLimitMin': instance.timeLimitMin,
  'attempts': instance.attempts,
  'passMark': instance.passMark,
};

_CalendarDetail _$CalendarDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CalendarDetail', json, ($checkedConvert) {
      final val = _CalendarDetail(
        event: $checkedConvert('event', (v) => CalendarEvent.fromJson(v as Map<String, dynamic>)),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String?),
        chapterTitle: $checkedConvert('chapterTitle', (v) => v as String?),
        instructorName: $checkedConvert('instructorName', (v) => v as String?),
        instructorTitle: $checkedConvert('instructorTitle', (v) => v as String?),
        phase: $checkedConvert(
          'phase',
          (v) => $enumDecodeNullable(_$LivePhaseEnumMap, v, unknownValue: LivePhase.unknown),
        ),
        editable: $checkedConvert('editable', (v) => v as bool? ?? false),
        live: $checkedConvert(
          'live',
          (v) => v == null ? null : CalendarLiveFacts.fromJson(v as Map<String, dynamic>),
        ),
        due: $checkedConvert(
          'due',
          (v) => v == null ? null : CalendarDue.fromJson(v as Map<String, dynamic>),
        ),
        learnersDue: $checkedConvert(
          'learnersDue',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => LearnerDue.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <LearnerDue>[],
        ),
        quiz: $checkedConvert(
          'quiz',
          (v) => v == null ? null : CalendarQuizFacts.fromJson(v as Map<String, dynamic>),
        ),
        audienceSize: $checkedConvert('audienceSize', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$CalendarDetailToJson(_CalendarDetail instance) => <String, dynamic>{
  'event': instance.event.toJson(),
  'courseTitle': instance.courseTitle,
  'chapterTitle': instance.chapterTitle,
  'instructorName': instance.instructorName,
  'instructorTitle': instance.instructorTitle,
  'phase': _$LivePhaseEnumMap[instance.phase],
  'editable': instance.editable,
  'live': instance.live?.toJson(),
  'due': instance.due?.toJson(),
  'learnersDue': instance.learnersDue.map((e) => e.toJson()).toList(),
  'quiz': instance.quiz?.toJson(),
  'audienceSize': instance.audienceSize,
};
