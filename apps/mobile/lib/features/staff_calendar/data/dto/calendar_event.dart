/// The academy's teaching calendar (`packages/domain/src/calendar.ts`, `routes/calendar.ts`). Live
/// classes and assignment deadlines are **derived** by the route from their own records and cannot be
/// changed here; a quiz window, a milestone and a reminder are the calendar's own (§26, FLUTTER-024).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/format/ist.dart';
import '../../../../core/network/json.dart';
import '../../../../shared/domain/live_class.dart';

part 'calendar_event.freezed.dart';
part 'calendar_event.g.dart';

/// `CalendarEventType`.
enum CalendarEventType { live, assignment, quiz, milestone, reminder, unknown }

/// `CalendarTiming` — a start and a length, a point in time, or a whole date.
enum CalendarTiming {
  timed,
  moment,
  @JsonValue('all-day')
  allDay,
  unknown,
}

/// `MilestoneKind`.
enum MilestoneKind {
  @JsonValue('cohort-starts')
  cohortStarts,
  @JsonValue('chapter-release')
  chapterRelease,
  @JsonValue('enrolment-closes')
  enrolmentCloses,
  @JsonValue('cohort-ends')
  cohortEnds,
  @JsonValue('course-launch')
  courseLaunch,
  unknown,
}

/// `ReminderAudience` — only the person who set it, or the course's learners too.
enum ReminderAudience { me, learners, unknown }

/// Where a derived event really lives. The calendar shows it; it is changed on the live class or the
/// assignment itself.
@freezed
abstract class CalendarSource with _$CalendarSource {
  const factory CalendarSource({@Default('') String kind, @Default('') String id}) =
      _CalendarSource;

  factory CalendarSource.fromJson(Map<String, dynamic> json) => _$CalendarSourceFromJson(json);
}

@freezed
abstract class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent({
    @Default('') String id,
    @JsonKey(unknownEnumValue: CalendarEventType.unknown)
    @Default(CalendarEventType.unknown)
    CalendarEventType type,
    @Default('') String title,
    String? description,
    @JsonKey(unknownEnumValue: CalendarTiming.unknown)
    @Default(CalendarTiming.timed)
    CalendarTiming timing,
    @UtcDateTimeConverter() required DateTime startsAt,

    /// Timed events only.
    int? durationMin,
    String? courseId,
    String? chapterId,
    String? instructorId,
    String? quizId,
    @JsonKey(unknownEnumValue: MilestoneKind.unknown) MilestoneKind? milestone,
    @JsonKey(unknownEnumValue: ReminderAudience.unknown) ReminderAudience? audience,

    /// A reminder belongs to whoever set it.
    String? ownerId,

    /// Minutes before the start that the academy sends a notice; absent for none.
    int? notifyMin,
    @Default(false) bool done,
    @Default(false) bool cancelled,
    CalendarSource? source,
  }) = _CalendarEvent;

  const CalendarEvent._();

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => _$CalendarEventFromJson(json);

  /// A live class or an assignment deadline, which the calendar shows but does not own.
  bool get isDerived => source != null;

  /// The IST calendar day this event sits on — the day the agenda files it under.
  DateTime get istDay {
    final wall = Ist.wallClock(startsAt);
    return DateTime.utc(wall.year, wall.month, wall.day);
  }

  /// `calendarEventEnd`, ported: the end of a timed event, the moment itself, or the end of the IST
  /// day for an all-day one.
  DateTime get endsAt => switch (timing) {
    CalendarTiming.timed => startsAt.add(Duration(minutes: durationMin ?? 0)),
    CalendarTiming.allDay => Ist.instantFromWallClock(
      Ist.wallClock(startsAt).year,
      Ist.wallClock(startsAt).month,
      Ist.wallClock(startsAt).day,
    ).add(const Duration(days: 1)),
    _ => startsAt,
  };
}

/// How many learners a deadline is for, and how many have handed in.
@freezed
abstract class CalendarDue with _$CalendarDue {
  const factory CalendarDue({@Default(0) int learners, @Default(0) int submitted}) = _CalendarDue;

  const CalendarDue._();

  factory CalendarDue.fromJson(Map<String, dynamic> json) => _$CalendarDueFromJson(json);

  int get outstanding => learners - submitted < 0 ? 0 : learners - submitted;
}

/// One row of `GET /calendar`.
@freezed
abstract class CalendarRow with _$CalendarRow {
  const factory CalendarRow({
    required CalendarEvent event,
    String? courseTitle,
    String? instructorName,
    @JsonKey(unknownEnumValue: LivePhase.unknown) LivePhase? phase,
    CalendarDue? due,
  }) = _CalendarRow;

  factory CalendarRow.fromJson(Map<String, dynamic> json) => _$CalendarRowFromJson(json);
}

/// `GET /calendar` — every event in the range, with the counts by type over the whole range.
@freezed
abstract class CalendarPage with _$CalendarPage {
  const factory CalendarPage({
    @Default(<CalendarRow>[]) List<CalendarRow> rows,
    @Default(0) int total,
    @Default(<String, int>{}) Map<String, int> counts,
  }) = _CalendarPage;

  const CalendarPage._();

  factory CalendarPage.fromJson(Map<String, dynamic> json) => _$CalendarPageFromJson(json);

  int countOf(CalendarEventType type) => counts[type.name] ?? 0;

  bool get isEmpty => rows.isEmpty;

  /// The events on one IST day, in the order the route sent them.
  List<CalendarRow> on(DateTime istDay) => rows.where((r) => r.event.istDay == istDay).toList();

  /// Every IST day in the range that has something on it.
  Set<DateTime> get busyDays => {for (final row in rows) row.event.istDay};
}

/// One learner a deadline is waiting on.
@freezed
abstract class LearnerDue with _$LearnerDue {
  const factory LearnerDue({
    @Default('') String id,
    @Default('') String name,
    @Default(false) bool submitted,
  }) = _LearnerDue;

  factory LearnerDue.fromJson(Map<String, dynamic> json) => _$LearnerDueFromJson(json);
}

/// What a live event's own record says, as the calendar reads it.
@freezed
abstract class CalendarLiveFacts with _$CalendarLiveFacts {
  const factory CalendarLiveFacts({@Default(0) int registered, int? capacity, int? attended}) =
      _CalendarLiveFacts;

  factory CalendarLiveFacts.fromJson(Map<String, dynamic> json) =>
      _$CalendarLiveFactsFromJson(json);
}

/// The quiz a quiz event points at, as the calendar reads it.
@freezed
abstract class CalendarQuizFacts with _$CalendarQuizFacts {
  const factory CalendarQuizFacts({
    @Default('') String id,
    @Default('') String title,
    @Default('') String status,
    @Default(0) int questions,
    int? timeLimitMin,
    int? attempts,
    int? passMark,
  }) = _CalendarQuizFacts;

  factory CalendarQuizFacts.fromJson(Map<String, dynamic> json) =>
      _$CalendarQuizFactsFromJson(json);
}

/// `GET /calendar/:id` — one event, with whatever its type carries.
@freezed
abstract class CalendarDetail with _$CalendarDetail {
  const factory CalendarDetail({
    required CalendarEvent event,
    String? courseTitle,
    String? chapterTitle,
    String? instructorName,
    String? instructorTitle,
    @JsonKey(unknownEnumValue: LivePhase.unknown) LivePhase? phase,

    /// Whether the **academy** will take a change to it. A derived event never is.
    @Default(false) bool editable,
    CalendarLiveFacts? live,
    CalendarDue? due,
    @Default(<LearnerDue>[]) List<LearnerDue> learnersDue,
    CalendarQuizFacts? quiz,

    /// How many learners the event reaches, where the academy counts them.
    int? audienceSize,
  }) = _CalendarDetail;

  factory CalendarDetail.fromJson(Map<String, dynamic> json) => _$CalendarDetailFromJson(json);
}

/// What the form holds, and what a write sends. `POST /calendar` wraps it in `{input: …}` and
/// `PATCH /calendar/:id` takes it bare (finding 30).
@freezed
abstract class CalendarEventForm with _$CalendarEventForm {
  const factory CalendarEventForm({
    @Default(CalendarEventType.reminder) CalendarEventType type,
    @Default('') String title,
    @Default('') String description,
    @Default(CalendarTiming.timed) CalendarTiming timing,
    DateTime? startsAt,
    @Default(30) int durationMin,
    String? courseId,
    String? chapterId,
    String? quizId,
    MilestoneKind? milestone,
    @Default(ReminderAudience.me) ReminderAudience audience,
    int? notifyMin,
  }) = _CalendarEventForm;

  const CalendarEventForm._();

  /// The event as it stands, ready to be edited.
  factory CalendarEventForm.of(CalendarEvent event) => CalendarEventForm(
    type: event.type,
    title: event.title,
    description: event.description ?? '',
    timing: event.timing,
    startsAt: event.startsAt,
    durationMin: event.durationMin ?? 30,
    courseId: event.courseId,
    chapterId: event.chapterId,
    quizId: event.quizId,
    milestone: event.milestone,
    audience: event.audience ?? ReminderAudience.me,
    notifyMin: event.notifyMin,
  );

  /// The length the academy's own validator accepts for a timed event.
  static const minDuration = 5;
  static const maxDuration = 720;

  /// The body a write sends. A duration only travels for a timed event, as the validator expects.
  Map<String, Object?> toInput() => {
    'type': type.name,
    'title': title.trim(),
    'description': description.trim(),
    'timing': timing == CalendarTiming.allDay ? 'all-day' : timing.name,
    'startsAt': startsAt?.toUtc().toIso8601String(),
    if (timing == CalendarTiming.timed) 'durationMin': durationMin,
    'courseId': ?courseId,
    'chapterId': ?chapterId,
    'quizId': ?quizId,
    if (milestone case final kind? when kind != MilestoneKind.unknown)
      'milestone': _milestoneWire(kind),
    if (type == CalendarEventType.reminder) 'audience': audience.name,
    'notifyMin': ?notifyMin,
  };

  static String _milestoneWire(MilestoneKind kind) => switch (kind) {
    MilestoneKind.cohortStarts => 'cohort-starts',
    MilestoneKind.chapterRelease => 'chapter-release',
    MilestoneKind.enrolmentCloses => 'enrolment-closes',
    MilestoneKind.cohortEnds => 'cohort-ends',
    MilestoneKind.courseLaunch => 'course-launch',
    MilestoneKind.unknown => 'cohort-starts',
  };
}

/// `validateCalendarEvent`, ported far enough to keep a button honest: which fields the academy
/// would refuse. The **server** decides, and its `issues` carry the words (§18).
List<String> calendarFormProblems(CalendarEventForm form, {required DateTime now}) {
  final problems = <String>[];
  // A live class or an assignment deadline is changed where it lives, never here.
  if (form.type == CalendarEventType.live || form.type == CalendarEventType.assignment) {
    problems.add('type');
  }
  if (form.title.trim().length < 3) problems.add('title');
  final needsCourse =
      form.type == CalendarEventType.quiz ||
      form.type == CalendarEventType.milestone ||
      (form.type == CalendarEventType.reminder && form.audience == ReminderAudience.learners);
  if (needsCourse && (form.courseId ?? '').isEmpty) problems.add('course');
  if (form.type == CalendarEventType.quiz && (form.quizId ?? '').isEmpty) problems.add('quiz');
  if (form.type == CalendarEventType.milestone && form.milestone == null) {
    problems.add('milestone');
  }
  if (form.type == CalendarEventType.milestone &&
      form.milestone == MilestoneKind.chapterRelease &&
      (form.chapterId ?? '').isEmpty) {
    problems.add('chapter');
  }
  final start = form.startsAt;
  if (start == null) {
    problems.add('startsAt');
  } else if (form.timing == CalendarTiming.allDay) {
    // An all-day event is judged by its IST date, not by the instant.
    final today = Ist.wallClock(now);
    final day = Ist.wallClock(start);
    if (DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).isBefore(DateTime.utc(today.year, today.month, today.day))) {
      problems.add('startsAt');
    }
  } else if (!start.isAfter(now)) {
    problems.add('startsAt');
  }
  if (form.timing == CalendarTiming.timed &&
      (form.durationMin < CalendarEventForm.minDuration ||
          form.durationMin > CalendarEventForm.maxDuration)) {
    problems.add('duration');
  }
  return problems;
}
