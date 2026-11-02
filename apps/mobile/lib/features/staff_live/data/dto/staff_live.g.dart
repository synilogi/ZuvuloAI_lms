// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_live.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StaffLiveRow _$StaffLiveRowFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_StaffLiveRow',
  json,
  ($checkedConvert) {
    final val = _StaffLiveRow(
      liveClass: $checkedConvert('liveClass', (v) => LiveClass.fromJson(v as Map<String, dynamic>)),
      phase: $checkedConvert(
        'phase',
        (v) =>
            $enumDecodeNullable(_$LivePhaseEnumMap, v, unknownValue: LivePhase.unknown) ??
            LivePhase.unknown,
      ),
      courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
      instructorName: $checkedConvert('instructorName', (v) => v as String? ?? ''),
    );
    return val;
  },
);

Map<String, dynamic> _$StaffLiveRowToJson(_StaffLiveRow instance) => <String, dynamic>{
  'liveClass': instance.liveClass.toJson(),
  'phase': _$LivePhaseEnumMap[instance.phase]!,
  'courseTitle': instance.courseTitle,
  'instructorName': instance.instructorName,
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

_StaffLivePage _$StaffLivePageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StaffLivePage', json, ($checkedConvert) {
      final val = _StaffLivePage(
        rows: $checkedConvert(
          'rows',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => StaffLiveRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <StaffLiveRow>[],
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

Map<String, dynamic> _$StaffLivePageToJson(_StaffLivePage instance) => <String, dynamic>{
  'rows': instance.rows.map((e) => e.toJson()).toList(),
  'total': instance.total,
  'counts': instance.counts,
};

_LiveAttendee _$LiveAttendeeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LiveAttendee', json, ($checkedConvert) {
      final val = _LiveAttendee(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        city: $checkedConvert('city', (v) => v as String? ?? ''),
        attended: $checkedConvert('attended', (v) => v as bool?),
        joinedAt: $checkedConvert(
          'joinedAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LiveAttendeeToJson(_LiveAttendee instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'city': instance.city,
  'attended': instance.attended,
  'joinedAt': const NullableUtcDateTimeConverter().toJson(instance.joinedAt),
};

_LiveNeighbour _$LiveNeighbourFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LiveNeighbour', json, ($checkedConvert) {
      final val = _LiveNeighbour(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        startsAt: $checkedConvert(
          'startsAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LiveNeighbourToJson(_LiveNeighbour instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'startsAt': const NullableUtcDateTimeConverter().toJson(instance.startsAt),
};

_StaffLiveDetail _$StaffLiveDetailFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_StaffLiveDetail',
  json,
  ($checkedConvert) {
    final val = _StaffLiveDetail(
      liveClass: $checkedConvert('liveClass', (v) => LiveClass.fromJson(v as Map<String, dynamic>)),
      phase: $checkedConvert(
        'phase',
        (v) =>
            $enumDecodeNullable(_$LivePhaseEnumMap, v, unknownValue: LivePhase.unknown) ??
            LivePhase.unknown,
      ),
      courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
      instructorName: $checkedConvert('instructorName', (v) => v as String? ?? ''),
      instructorTitle: $checkedConvert('instructorTitle', (v) => v as String? ?? ''),
      attendees: $checkedConvert(
        'attendees',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => LiveAttendee.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <LiveAttendee>[],
      ),
      attendeeTotal: $checkedConvert('attendeeTotal', (v) => (v as num?)?.toInt() ?? 0),
      recordingViews: $checkedConvert('recordingViews', (v) => (v as num?)?.toInt()),
      previous: $checkedConvert(
        'previous',
        (v) => v == null ? null : LiveNeighbour.fromJson(v as Map<String, dynamic>),
      ),
      next: $checkedConvert(
        'next',
        (v) => v == null ? null : LiveNeighbour.fromJson(v as Map<String, dynamic>),
      ),
      room: $checkedConvert(
        'room',
        (v) => v == null ? null : LiveRoomInfo.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$StaffLiveDetailToJson(_StaffLiveDetail instance) => <String, dynamic>{
  'liveClass': instance.liveClass.toJson(),
  'phase': _$LivePhaseEnumMap[instance.phase]!,
  'courseTitle': instance.courseTitle,
  'instructorName': instance.instructorName,
  'instructorTitle': instance.instructorTitle,
  'attendees': instance.attendees.map((e) => e.toJson()).toList(),
  'attendeeTotal': instance.attendeeTotal,
  'recordingViews': instance.recordingViews,
  'previous': instance.previous?.toJson(),
  'next': instance.next?.toJson(),
  'room': instance.room?.toJson(),
};

_LiveRoomInfo _$LiveRoomInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LiveRoomInfo', json, ($checkedConvert) {
      final val = _LiveRoomInfo(
        provider: $checkedConvert('provider', (v) => v as String? ?? 'jitsi'),
        recording: $checkedConvert('recording', (v) => v as bool? ?? false),
        canStart: $checkedConvert('canStart', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$LiveRoomInfoToJson(_LiveRoomInfo instance) => <String, dynamic>{
  'provider': instance.provider,
  'recording': instance.recording,
  'canStart': instance.canStart,
};

_LiveStarted _$LiveStartedFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_LiveStarted',
  json,
  ($checkedConvert) {
    final val = _LiveStarted(
      liveClass: $checkedConvert('liveClass', (v) => LiveClass.fromJson(v as Map<String, dynamic>)),
      room: $checkedConvert('room', (v) => LiveRoomJoin.fromJson(v as Map<String, dynamic>)),
    );
    return val;
  },
);

Map<String, dynamic> _$LiveStartedToJson(_LiveStarted instance) => <String, dynamic>{
  'liveClass': instance.liveClass.toJson(),
  'room': instance.room.toJson(),
};
