import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';
import '../../../../shared/domain/live_class.dart';

part 'staff_live.freezed.dart';
part 'staff_live.g.dart';

/// One row of `GET /live` — the class, the phase the **server** derived, and who it belongs to.
@freezed
abstract class StaffLiveRow with _$StaffLiveRow {
  const factory StaffLiveRow({
    required LiveClass liveClass,
    @JsonKey(unknownEnumValue: LivePhase.unknown) @Default(LivePhase.unknown) LivePhase phase,
    @Default('') String courseTitle,
    @Default('') String instructorName,
  }) = _StaffLiveRow;

  const StaffLiveRow._();

  factory StaffLiveRow.fromJson(Map<String, dynamic> json) => _$StaffLiveRowFromJson(json);

  /// The phase as it stands now, from the server's timestamps and the device clock. Presentation
  /// only: the server's own `phase` is what a decision is made on (§14).
  LivePhase phaseAt(DateTime now) => deriveLivePhase(liveClass, now);

  /// Which of the list's four views this class falls in, the way `viewFor` sorts them.
  String get view {
    if (liveClass.cancelled) return 'cancelled';
    return switch (phase) {
      LivePhase.upcoming || LivePhase.startingSoon => 'upcoming',
      LivePhase.live => 'live',
      _ => 'history',
    };
  }
}

/// `GET /live`.
@freezed
abstract class StaffLivePage with _$StaffLivePage {
  const factory StaffLivePage({
    @Default(<StaffLiveRow>[]) List<StaffLiveRow> rows,
    @Default(0) int total,
    @Default(<String, int>{}) Map<String, int> counts,
  }) = _StaffLivePage;

  const StaffLivePage._();

  factory StaffLivePage.fromJson(Map<String, dynamic> json) => _$StaffLivePageFromJson(json);

  int countOf(String view) => counts[view] ?? 0;

  bool get isEmpty => rows.isEmpty;
}

/// One learner who took a seat. `attended` is absent until the academy marks it, and the app never
/// guesses: there is no attendance write in this release.
@freezed
abstract class LiveAttendee with _$LiveAttendee {
  const factory LiveAttendee({
    @Default('') String id,
    @Default('') String name,
    @Default('') String city,
    bool? attended,

    /// When they first went into the room.
    @NullableUtcDateTimeConverter() DateTime? joinedAt,
  }) = _LiveAttendee;

  factory LiveAttendee.fromJson(Map<String, dynamic> json) => _$LiveAttendeeFromJson(json);
}

/// A class beside this one in the same course, for moving through a series.
@freezed
abstract class LiveNeighbour with _$LiveNeighbour {
  const factory LiveNeighbour({
    @Default('') String id,
    @Default('') String title,
    @NullableUtcDateTimeConverter() DateTime? startsAt,
  }) = _LiveNeighbour;

  factory LiveNeighbour.fromJson(Map<String, dynamic> json) => _$LiveNeighbourFromJson(json);
}

/// `GET /live/:id` — one class in full, as staff read it.
@freezed
abstract class StaffLiveDetail with _$StaffLiveDetail {
  const factory StaffLiveDetail({
    required LiveClass liveClass,
    @JsonKey(unknownEnumValue: LivePhase.unknown) @Default(LivePhase.unknown) LivePhase phase,
    @Default('') String courseTitle,
    @Default('') String instructorName,
    @Default('') String instructorTitle,
    @Default(<LiveAttendee>[]) List<LiveAttendee> attendees,
    @Default(0) int attendeeTotal,

    /// How often the recording has been watched, where the academy counts it.
    int? recordingViews,
    LiveNeighbour? previous,
    LiveNeighbour? next,

    /// What the built-in room can do at this academy.
    LiveRoomInfo? room,
  }) = _StaffLiveDetail;

  const StaffLiveDetail._();

  factory StaffLiveDetail.fromJson(Map<String, dynamic> json) => _$StaffLiveDetailFromJson(json);

  LivePhase phaseAt(DateTime now) => deriveLivePhase(liveClass, now);

  /// Whether the host may open the built-in room at [now] — read again as the clock ticks, so Start
  /// appears at the quarter hour before the class without a refresh. What the academy knows decides
  /// first: a class cancelled, already started, ended or on an outside meeting is never started
  /// here. Otherwise the academy's own `canStartRoom` is reproduced on the clock; and should this
  /// phone's clock run behind the academy's, the academy's answer when the page was read
  /// ([LiveRoomInfo.canStart]) stands until the class's scheduled end.
  bool canStartAt(DateTime now) {
    final cls = liveClass;
    if (cls.cancelled || !cls.isRoom || cls.startedAt != null || cls.endedAt != null) return false;
    if (canStartRoom(cls, now)) return true;
    return (room?.canStart ?? false) && now.isBefore(cls.endsAt);
  }

  /// Whether the academy would still take an edit: it refuses one for a class that has started or
  /// been cancelled, and the app does not offer it either.
  bool editableAt(DateTime now) =>
      !liveClass.cancelled && liveClass.startedAt == null && now.isBefore(liveClass.startsAt);
}

/// `room` on the staff detail: the video service, whether it records, and whether the host may open the
/// room now (the academy's own `canStartRoom`).
@freezed
abstract class LiveRoomInfo with _$LiveRoomInfo {
  const factory LiveRoomInfo({
    @Default('jitsi') String provider,
    @Default(false) bool recording,
    @Default(false) bool canStart,
  }) = _LiveRoomInfo;

  factory LiveRoomInfo.fromJson(Map<String, dynamic> json) => _$LiveRoomInfoFromJson(json);
}

/// `POST /live/:id/start` — the class as it now stands, and the host's way into the room.
@freezed
abstract class LiveStarted with _$LiveStarted {
  const factory LiveStarted({required LiveClass liveClass, required LiveRoomJoin room}) =
      _LiveStarted;

  factory LiveStarted.fromJson(Map<String, dynamic> json) => _$LiveStartedFromJson(json);
}

/// What the form holds, and what a write sends. The route takes the **whole** object on a PATCH, so
/// an edit starts from the class as it stands and sends every field back.
@freezed
abstract class LiveClassForm with _$LiveClassForm {
  const factory LiveClassForm({
    @Default('') String courseId,
    @Default('') String title,
    @Default('') String instructorId,
    DateTime? startsAt,
    @Default(60) int durationMin,
    int? capacity,
    @Default('') String description,
    @Default(<AgendaItem>[]) List<AgendaItem> agenda,
    @Default(LiveVisibility.enrolled) LiveVisibility visibility,
    @Default(MeetingKind.room) MeetingKind meetingKind,
    @Default('') String meetingLink,
    @Default(<int>[]) List<int> reminders,
    String? chapterId,
  }) = _LiveClassForm;

  const LiveClassForm._();

  /// The class as it stands, ready to be edited and sent back whole.
  factory LiveClassForm.of(LiveClass cls) => LiveClassForm(
    courseId: cls.courseId,
    title: cls.title,
    instructorId: cls.instructorId,
    startsAt: cls.startsAt,
    durationMin: cls.durationMin,
    capacity: cls.capacity,
    description: cls.description ?? '',
    agenda: cls.agenda,
    visibility: cls.visibility,
    meetingKind: cls.meeting.kind,
    meetingLink: cls.meeting.link ?? '',
    reminders: cls.reminders,
    chapterId: cls.chapterId,
  );

  /// The class length the academy's own validator accepts.
  static const minDuration = 15;
  static const maxDuration = 240;

  /// The most reminder offsets the route's schema allows.
  static const maxReminders = 10;

  int get agendaMinutes => agenda.fold(0, (sum, item) => sum + item.minutes);

  /// The body a write sends. `meeting.link` is the field the write path validates and stores, even
  /// though the route's own schema names `url` (finding 15, clarification A1). The start is a UTC
  /// instant with its `Z`, which is the offset the route insists on. A capacity, description or
  /// chapter left empty is sent as `null`: on an edit that is what clears it — left out, the
  /// academy would keep the old one.
  Map<String, Object?> toBody() => {
    'courseId': courseId,
    'title': title.trim(),
    'instructorId': instructorId,
    'startsAt': startsAt?.toUtc().toIso8601String(),
    'durationMin': durationMin,
    'capacity': capacity,
    'description': description.trim().isEmpty ? null : description.trim(),
    'agenda': [
      for (final item in agenda) {'title': item.title, 'minutes': item.minutes},
    ],
    'visibility': visibility == LiveVisibility.unknown ? 'enrolled' : visibility.name,
    'meeting': {
      'kind': meetingKind == MeetingKind.unknown ? 'external' : meetingKind.name,
      if (meetingKind == MeetingKind.external) 'link': meetingLink.trim(),
    },
    'reminders': reminders,
    'chapterId': chapterId,
  };
}
