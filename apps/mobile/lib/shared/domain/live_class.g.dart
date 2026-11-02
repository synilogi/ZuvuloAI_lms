// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_class.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AgendaItem _$AgendaItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AgendaItem', json, ($checkedConvert) {
      final val = _AgendaItem(
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        minutes: $checkedConvert('minutes', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$AgendaItemToJson(_AgendaItem instance) => <String, dynamic>{
  'title': instance.title,
  'minutes': instance.minutes,
};

_LiveMeeting _$LiveMeetingFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LiveMeeting', json, ($checkedConvert) {
      final val = _LiveMeeting(
        kind: $checkedConvert(
          'kind',
          (v) =>
              $enumDecodeNullable(_$MeetingKindEnumMap, v, unknownValue: MeetingKind.unknown) ??
              MeetingKind.room,
        ),
        link: $checkedConvert('link', (v) => v as String?),
        linkHost: $checkedConvert('linkHost', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$LiveMeetingToJson(_LiveMeeting instance) => <String, dynamic>{
  'kind': _$MeetingKindEnumMap[instance.kind]!,
  'link': instance.link,
  'linkHost': instance.linkHost,
};

const _$MeetingKindEnumMap = {
  MeetingKind.room: 'room',
  MeetingKind.external: 'external',
  MeetingKind.unknown: 'unknown',
};

_LiveRecording _$LiveRecordingFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_LiveRecording',
  json,
  ($checkedConvert) {
    final val = _LiveRecording(
      durationMin: $checkedConvert('durationMin', (v) => (v as num?)?.toInt() ?? 0),
      availableUntil: $checkedConvert(
        'availableUntil',
        (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
      ),
      status: $checkedConvert(
        'status',
        (v) =>
            $enumDecodeNullable(_$RecordingStatusEnumMap, v, unknownValue: RecordingStatus.unknown),
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$LiveRecordingToJson(_LiveRecording instance) => <String, dynamic>{
  'durationMin': instance.durationMin,
  'availableUntil': const NullableUtcDateTimeConverter().toJson(instance.availableUntil),
  'status': _$RecordingStatusEnumMap[instance.status],
};

const _$RecordingStatusEnumMap = {
  RecordingStatus.processing: 'processing',
  RecordingStatus.ready: 'ready',
  RecordingStatus.unknown: 'unknown',
};

_LiveClass _$LiveClassFromJson(Map<String, dynamic> json) => $checkedCreate('_LiveClass', json, (
  $checkedConvert,
) {
  final val = _LiveClass(
    id: $checkedConvert('id', (v) => v as String),
    courseId: $checkedConvert('courseId', (v) => v as String? ?? ''),
    title: $checkedConvert('title', (v) => v as String? ?? ''),
    instructorId: $checkedConvert('instructorId', (v) => v as String? ?? ''),
    startsAt: $checkedConvert(
      'startsAt',
      (v) => const UtcDateTimeConverter().fromJson(v as String),
    ),
    durationMin: $checkedConvert('durationMin', (v) => (v as num?)?.toInt() ?? 0),
    capacity: $checkedConvert('capacity', (v) => (v as num?)?.toInt()),
    registered: $checkedConvert('registered', (v) => (v as num?)?.toInt()),
    attending: $checkedConvert('attending', (v) => (v as num?)?.toInt()),
    attended: $checkedConvert('attended', (v) => (v as num?)?.toInt()),
    cancelled: $checkedConvert('cancelled', (v) => v as bool? ?? false),
    startedAt: $checkedConvert(
      'startedAt',
      (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
    ),
    endedAt: $checkedConvert(
      'endedAt',
      (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
    ),
    recording: $checkedConvert(
      'recording',
      (v) => v == null ? null : LiveRecording.fromJson(v as Map<String, dynamic>),
    ),
    description: $checkedConvert('description', (v) => v as String?),
    agenda: $checkedConvert(
      'agenda',
      (v) =>
          (v as List<dynamic>?)
              ?.map((e) => AgendaItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <AgendaItem>[],
    ),
    visibility: $checkedConvert(
      'visibility',
      (v) =>
          $enumDecodeNullable(_$LiveVisibilityEnumMap, v, unknownValue: LiveVisibility.unknown) ??
          LiveVisibility.enrolled,
    ),
    meeting: $checkedConvert(
      'meeting',
      (v) => v == null ? const LiveMeeting() : LiveMeeting.fromJson(v as Map<String, dynamic>),
    ),
    reminders: $checkedConvert(
      'reminders',
      (v) => (v as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? const <int>[],
    ),
    cancelReason: $checkedConvert('cancelReason', (v) => v as String?),
    chapterId: $checkedConvert('chapterId', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$LiveClassToJson(_LiveClass instance) => <String, dynamic>{
  'id': instance.id,
  'courseId': instance.courseId,
  'title': instance.title,
  'instructorId': instance.instructorId,
  'startsAt': const UtcDateTimeConverter().toJson(instance.startsAt),
  'durationMin': instance.durationMin,
  'capacity': instance.capacity,
  'registered': instance.registered,
  'attending': instance.attending,
  'attended': instance.attended,
  'cancelled': instance.cancelled,
  'startedAt': const NullableUtcDateTimeConverter().toJson(instance.startedAt),
  'endedAt': const NullableUtcDateTimeConverter().toJson(instance.endedAt),
  'recording': instance.recording?.toJson(),
  'description': instance.description,
  'agenda': instance.agenda.map((e) => e.toJson()).toList(),
  'visibility': _$LiveVisibilityEnumMap[instance.visibility]!,
  'meeting': instance.meeting.toJson(),
  'reminders': instance.reminders,
  'cancelReason': instance.cancelReason,
  'chapterId': instance.chapterId,
};

const _$LiveVisibilityEnumMap = {
  LiveVisibility.enrolled: 'enrolled',
  LiveVisibility.cohort: 'cohort',
  LiveVisibility.public: 'public',
  LiveVisibility.unknown: 'unknown',
};

_LearnerLiveRow _$LearnerLiveRowFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_LearnerLiveRow',
  json,
  ($checkedConvert) {
    final val = _LearnerLiveRow(
      liveClass: $checkedConvert('liveClass', (v) => LiveClass.fromJson(v as Map<String, dynamic>)),
      phase: $checkedConvert(
        'phase',
        (v) =>
            $enumDecodeNullable(_$LivePhaseEnumMap, v, unknownValue: LivePhase.unknown) ??
            LivePhase.unknown,
      ),
      courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
      instructorName: $checkedConvert('instructorName', (v) => v as String? ?? ''),
      registered: $checkedConvert('registered', (v) => v as bool? ?? false),
      attended: $checkedConvert('attended', (v) => v as bool?),
    );
    return val;
  },
);

Map<String, dynamic> _$LearnerLiveRowToJson(_LearnerLiveRow instance) => <String, dynamic>{
  'liveClass': instance.liveClass.toJson(),
  'phase': _$LivePhaseEnumMap[instance.phase]!,
  'courseTitle': instance.courseTitle,
  'instructorName': instance.instructorName,
  'registered': instance.registered,
  'attended': instance.attended,
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

_LiveSchedule _$LiveScheduleFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LiveSchedule', json, ($checkedConvert) {
      final val = _LiveSchedule(
        live: $checkedConvert(
          'live',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => LearnerLiveRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <LearnerLiveRow>[],
        ),
        upcoming: $checkedConvert(
          'upcoming',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => LearnerLiveRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <LearnerLiveRow>[],
        ),
        recordings: $checkedConvert(
          'recordings',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => LearnerLiveRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <LearnerLiveRow>[],
        ),
        history: $checkedConvert(
          'history',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => LearnerLiveRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <LearnerLiveRow>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$LiveScheduleToJson(_LiveSchedule instance) => <String, dynamic>{
  'live': instance.live.map((e) => e.toJson()).toList(),
  'upcoming': instance.upcoming.map((e) => e.toJson()).toList(),
  'recordings': instance.recordings.map((e) => e.toJson()).toList(),
  'history': instance.history.map((e) => e.toJson()).toList(),
};

_LiveRegistration _$LiveRegistrationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LiveRegistration', json, ($checkedConvert) {
      final val = _LiveRegistration(
        registered: $checkedConvert('registered', (v) => v as bool? ?? false),
        spotsLeft: $checkedConvert('spotsLeft', (v) => (v as num?)?.toInt() ?? 999),
      );
      return val;
    });

Map<String, dynamic> _$LiveRegistrationToJson(_LiveRegistration instance) => <String, dynamic>{
  'registered': instance.registered,
  'spotsLeft': instance.spotsLeft,
};

_LiveRoomJoin _$LiveRoomJoinFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LiveRoomJoin', json, ($checkedConvert) {
      final val = _LiveRoomJoin(
        provider: $checkedConvert('provider', (v) => v as String? ?? 'jitsi'),
        domain: $checkedConvert('domain', (v) => v as String),
        room: $checkedConvert('room', (v) => v as String),
        jwt: $checkedConvert('jwt', (v) => v as String?),
        subject: $checkedConvert('subject', (v) => v as String? ?? ''),
        displayName: $checkedConvert('displayName', (v) => v as String? ?? ''),
        email: $checkedConvert('email', (v) => v as String?),
        moderator: $checkedConvert('moderator', (v) => v as bool? ?? false),
        recording: $checkedConvert('recording', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$LiveRoomJoinToJson(_LiveRoomJoin instance) => <String, dynamic>{
  'provider': instance.provider,
  'domain': instance.domain,
  'room': instance.room,
  'jwt': instance.jwt,
  'subject': instance.subject,
  'displayName': instance.displayName,
  'email': instance.email,
  'moderator': instance.moderator,
  'recording': instance.recording,
};

_LiveJoin _$LiveJoinFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LiveJoin', json, ($checkedConvert) {
      final val = _LiveJoin(
        kind: $checkedConvert(
          'kind',
          (v) =>
              $enumDecodeNullable(_$MeetingKindEnumMap, v, unknownValue: MeetingKind.unknown) ??
              MeetingKind.unknown,
        ),
        room: $checkedConvert(
          'room',
          (v) => v == null ? null : LiveRoomJoin.fromJson(v as Map<String, dynamic>),
        ),
        link: $checkedConvert('link', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$LiveJoinToJson(_LiveJoin instance) => <String, dynamic>{
  'kind': _$MeetingKindEnumMap[instance.kind]!,
  'room': instance.room?.toJson(),
  'link': instance.link,
};
