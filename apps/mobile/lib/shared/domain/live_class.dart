import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/json.dart';

part 'live_class.freezed.dart';
part 'live_class.g.dart';

/// `LiveClassPhase` — where a class is in its own life. The server sends it, and the app derives
/// it again from the clock so "Join" opens on time without another request (§14).
enum LivePhase {
  upcoming,
  @JsonValue('starting-soon')
  startingSoon,
  live,
  ended,
  @JsonValue('recording-expired')
  recordingExpired,
  cancelled,
  unknown,
}

/// `LiveVisibility`.
enum LiveVisibility { enrolled, cohort, public, unknown }

/// How the class is attended: the academy's own room, or a link to an outside meeting.
enum MeetingKind { room, external, unknown }

/// Joining opens this many minutes before the start (`JOIN_WINDOW_MIN`).
const joinWindow = Duration(minutes: 15);

/// A room the host left open counts as ended this long after its slot (`ROOM_OVERRUN_MIN`).
const roomOverrun = Duration(minutes: 60);

@freezed
abstract class AgendaItem with _$AgendaItem {
  const factory AgendaItem({@Default('') String title, @Default(0) int minutes}) = _AgendaItem;

  factory AgendaItem.fromJson(Map<String, dynamic> json) => _$AgendaItemFromJson(json);
}

/// Where the class happens. `link` is the field the write path actually stores — the route's own
/// schema also names a `url`, which nothing reads (finding 15).
///
/// Staff read the outside meeting's `link`. A learner never does: their payloads carry only
/// [linkHost], the site the meeting is on, and the link itself comes from `POST /live/:id/join` —
/// to a learner allowed in, inside the join window (`forLearner` in apps/api/src/lib/mapLive.ts).
@freezed
abstract class LiveMeeting with _$LiveMeeting {
  const factory LiveMeeting({
    @JsonKey(unknownEnumValue: MeetingKind.unknown) @Default(MeetingKind.room) MeetingKind kind,
    String? link,

    /// The outside meeting's site (`zoom.us`), on a learner's payload in place of the link.
    String? linkHost,
  }) = _LiveMeeting;

  const LiveMeeting._();

  factory LiveMeeting.fromJson(Map<String, dynamic> json) => _$LiveMeetingFromJson(json);

  /// The meeting to open, and only over https — the app never opens anything else (§13, B12).
  /// Staff only: a learner's payload has no link.
  Uri? get joinable => kind == MeetingKind.external ? safeMeetingLink(link) : null;

  /// The site an outside meeting is on, to name before the learner leaves the app: what the academy
  /// said, else the host of the link staff can see. Null for the built-in room, or when neither is
  /// known.
  String? get host {
    if (kind != MeetingKind.external) return null;
    final named = linkHost?.trim().toLowerCase();
    if (named != null && named.isNotEmpty) return named;
    return joinable?.host;
  }
}

/// [raw] as a link the app will open: https, with a host, and nothing else (§13). Null otherwise,
/// and never a throw — the link was typed by a person, and is untrusted input (§18).
Uri? safeMeetingLink(String? raw) {
  final parsed = Uri.tryParse(raw?.trim() ?? '');
  if (parsed == null || parsed.scheme != 'https' || parsed.host.isEmpty) return null;
  return parsed;
}

/// Where a kept recording stands: still being fetched from the video service, or ready to play.
/// A recording with no status predates the kept file — listed, with nothing to play.
enum RecordingStatus { processing, ready, unknown }

/// A recording the academy kept: how long it runs, until when, and whether it can be played yet. It
/// plays from `GET /live/:id/recording` with the learner's own token.
@freezed
abstract class LiveRecording with _$LiveRecording {
  const factory LiveRecording({
    @Default(0) int durationMin,
    @NullableUtcDateTimeConverter() DateTime? availableUntil,
    @JsonKey(unknownEnumValue: RecordingStatus.unknown) RecordingStatus? status,
  }) = _LiveRecording;

  const LiveRecording._();

  factory LiveRecording.fromJson(Map<String, dynamic> json) => _$LiveRecordingFromJson(json);

  bool get playable => status == RecordingStatus.ready;
}

/// `LiveClass` (`packages/domain/src/live-class.ts`).
@freezed
abstract class LiveClass with _$LiveClass {
  const factory LiveClass({
    required String id,
    @Default('') String courseId,
    @Default('') String title,
    @Default('') String instructorId,
    @UtcDateTimeConverter() required DateTime startsAt,
    @Default(0) int durationMin,
    int? capacity,

    /// On a learner's own row this counts **their** registration, not the class's (finding 17).
    int? registered,
    int? attending,
    int? attended,
    @Default(false) bool cancelled,

    /// When the host opened the built-in room; such a class is live only from here.
    @NullableUtcDateTimeConverter() DateTime? startedAt,

    /// When the host (or the academy, for a room left open) closed it.
    @NullableUtcDateTimeConverter() DateTime? endedAt,
    LiveRecording? recording,
    String? description,
    @Default(<AgendaItem>[]) List<AgendaItem> agenda,
    @JsonKey(unknownEnumValue: LiveVisibility.unknown)
    @Default(LiveVisibility.enrolled)
    LiveVisibility visibility,
    @Default(LiveMeeting()) LiveMeeting meeting,

    /// Minutes before the start that registrants are reminded.
    @Default(<int>[]) List<int> reminders,
    String? cancelReason,
    String? chapterId,
  }) = _LiveClass;

  const LiveClass._();

  factory LiveClass.fromJson(Map<String, dynamic> json) => _$LiveClassFromJson(json);

  DateTime get endsAt => startsAt.add(Duration(minutes: durationMin));

  bool get isRoom => meeting.kind == MeetingKind.room;

  /// A built-in room in its window that its host has not opened yet: learners wait for them.
  bool waitingForHostAt(DateTime now) =>
      isRoom && startedAt == null && deriveLivePhase(this, now) == LivePhase.startingSoon;

  /// The agenda's own total, which the academy keeps at or under the class length.
  int get agendaMinutes => agenda.fold(0, (sum, item) => sum + item.minutes);
}

/// `deriveLiveClassPhase` — the same reading the server makes, so the screen moves on time without
/// asking again. An outside meeting runs on the clock; the built-in room runs on its host: live from
/// their start until their end, and "starting soon" while learners wait — never live on the clock alone.
LivePhase deriveLivePhase(LiveClass cls, DateTime now) {
  if (cls.cancelled) return LivePhase.cancelled;
  final start = cls.startsAt;
  final end = cls.endsAt;
  LivePhase afterwards() {
    final until = cls.recording?.availableUntil;
    if (until == null || now.isAfter(until)) return LivePhase.recordingExpired;
    return LivePhase.ended;
  }

  // Ended is the server's word, whatever this device's clock says: a phone running a minute behind
  // must not keep offering Join to a class its host has closed. The server only stamps the past.
  if (cls.endedAt != null) return afterwards();
  if (cls.isRoom || cls.startedAt != null) {
    if (cls.startedAt != null) {
      return now.isBefore(end.add(roomOverrun)) ? LivePhase.live : afterwards();
    }
    if (now.isBefore(start.subtract(joinWindow))) return LivePhase.upcoming;
    if (now.isBefore(end)) return LivePhase.startingSoon;
    return afterwards();
  }
  if (now.isBefore(start.subtract(joinWindow))) return LivePhase.upcoming;
  if (now.isBefore(start)) return LivePhase.startingSoon;
  if (now.isBefore(end)) return LivePhase.live;
  return afterwards();
}

/// `canJoin` — an outside link opens in the quarter hour before the start and until it ends; the
/// built-in room only once its host has started it.
bool canJoinPhase(LivePhase phase, [LiveClass? cls]) {
  if (cls != null && cls.isRoom && cls.startedAt == null) return false;
  return phase == LivePhase.startingSoon || phase == LivePhase.live;
}

/// `canStartRoom` — the host may open the built-in room from the join window until the scheduled end, once.
bool canStartRoom(LiveClass cls, DateTime now) =>
    !cls.cancelled &&
    cls.isRoom &&
    cls.startedAt == null &&
    cls.endedAt == null &&
    deriveLivePhase(cls, now) == LivePhase.startingSoon;

/// What the academy's record says about one person and a class that is over — and no more than it
/// can know. `attended` true means they **joined the built-in room from the app**; the video service
/// does not vouch for how long they stayed, so it is "joined", never a verified "attended". False
/// means they held a place and never joined. An outside meeting happens where the academy cannot
/// see: opening its link is all there is to say. Null — no record — says nothing at all.
enum LiveAttendance {
  joined,
  missed,
  openedLink;

  /// The record for `attended` at a class in the built-in room ([inRoom]) or an outside meeting.
  static LiveAttendance? of({required bool? attended, required bool inRoom}) => switch (attended) {
    null => null,
    false => missed,
    true => inRoom ? joined : openedLink,
  };
}

/// One row of `GET /live/learner`: the class, where it is in its life, and the names the learner
/// reads it by.
@freezed
abstract class LearnerLiveRow with _$LearnerLiveRow {
  const factory LearnerLiveRow({
    required LiveClass liveClass,
    @JsonKey(unknownEnumValue: LivePhase.unknown) @Default(LivePhase.unknown) LivePhase phase,
    @Default('') String courseTitle,
    @Default('') String instructorName,

    /// Whether **this** learner has a seat. Sent on upcoming rows only.
    @Default(false) bool registered,

    /// On a past class: whether this learner joined it (null when they held no place).
    bool? attended,
  }) = _LearnerLiveRow;

  const LearnerLiveRow._();

  factory LearnerLiveRow.fromJson(Map<String, dynamic> json) => _$LearnerLiveRowFromJson(json);

  /// The phase now, from the clock — the server's own phase was true when it answered.
  LivePhase phaseAt(DateTime now) => deriveLivePhase(liveClass, now);
}

/// `GET /live/learner` — the learner's schedule in the academy's own three groups.
@freezed
abstract class LiveSchedule with _$LiveSchedule {
  const factory LiveSchedule({
    @Default(<LearnerLiveRow>[]) List<LearnerLiveRow> live,
    @Default(<LearnerLiveRow>[]) List<LearnerLiveRow> upcoming,
    @Default(<LearnerLiveRow>[]) List<LearnerLiveRow> recordings,

    /// Past classes this learner held a place for, with whether they came.
    @Default(<LearnerLiveRow>[]) List<LearnerLiveRow> history,
  }) = _LiveSchedule;

  const LiveSchedule._();

  factory LiveSchedule.fromJson(Map<String, dynamic> json) => _$LiveScheduleFromJson(json);

  /// Nothing at all to show — not even the learner's attendance at classes already over.
  bool get isEmpty => live.isEmpty && upcoming.isEmpty && recordings.isEmpty && history.isEmpty;

  List<LearnerLiveRow> get all => [...live, ...upcoming, ...recordings, ...history];

  /// One class by id, wherever it sits. There is no learner endpoint for a single class, so the
  /// detail screen reads it from the schedule.
  LearnerLiveRow? rowFor(String liveClassId) {
    for (final row in all) {
      if (row.liveClass.id == liveClassId) return row;
    }
    return null;
  }
}

/// `POST /live/:id/register` — whether the learner now holds a seat, and how many are left.
@freezed
abstract class LiveRegistration with _$LiveRegistration {
  const factory LiveRegistration({
    @Default(false) bool registered,

    /// The route sends 999 for a class with no capacity at all; that is not a number to show.
    @Default(999) int spotsLeft,
  }) = _LiveRegistration;

  const LiveRegistration._();

  factory LiveRegistration.fromJson(Map<String, dynamic> json) => _$LiveRegistrationFromJson(json);

  static const unlimited = 999;

  bool get isUnlimited => spotsLeft >= unlimited;
}

/// The video service the API names for the built-in room (`RoomJoin` in apps/api/src/lib/liveRoom.ts):
/// the server, the room, and — on JaaS — a token signed for this person.
@freezed
abstract class LiveRoomJoin with _$LiveRoomJoin {
  const factory LiveRoomJoin({
    @Default('jitsi') String provider,
    required String domain,
    required String room,
    String? jwt,
    @Default('') String subject,
    @Default('') String displayName,
    String? email,
    @Default(false) bool moderator,
    @Default(false) bool recording,
  }) = _LiveRoomJoin;

  const LiveRoomJoin._();

  factory LiveRoomJoin.fromJson(Map<String, dynamic> json) => _$LiveRoomJoinFromJson(json);

  /// The server to connect to — https only, as everything the app opens (§13).
  Uri get serverUrl => Uri(scheme: 'https', host: domain);
}

/// `POST /live/:id/join` — the built-in room, or an outside meeting's link.
@freezed
abstract class LiveJoin with _$LiveJoin {
  const factory LiveJoin({
    @JsonKey(unknownEnumValue: MeetingKind.unknown) @Default(MeetingKind.unknown) MeetingKind kind,
    LiveRoomJoin? room,
    String? link,
  }) = _LiveJoin;

  factory LiveJoin.fromJson(Map<String, dynamic> json) => _$LiveJoinFromJson(json);
}
