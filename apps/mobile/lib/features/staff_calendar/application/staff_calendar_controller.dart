import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/format/ist.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/platform/clock.dart';
import '../data/dto/calendar_event.dart';
import '../data/staff_calendar_api.dart';

/// What the calendar screens read (§26).
export '../data/dto/calendar_event.dart';

/// The IST calendar day an instant falls on, as a UTC-flagged midnight — the key the agenda files
/// events under, and the shape the route's `from`/`to` are built from (§21).
DateTime istDayOf(DateTime instant) {
  final wall = Ist.wallClock(instant);
  return DateTime.utc(wall.year, wall.month, wall.day);
}

/// The Monday of the IST week [day] falls in.
DateTime istWeekStart(DateTime day) => day.subtract(Duration(days: day.weekday - 1));

/// The seven IST days of the week [day] falls in.
List<DateTime> istWeekOf(DateTime day) {
  final start = istWeekStart(day);
  return [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
}

/// The IST days of the month [day] falls in, padded to whole weeks for a month grid.
List<DateTime> istMonthGrid(DateTime day) {
  final first = DateTime.utc(day.year, day.month);
  final last = DateTime.utc(day.year, day.month + 1).subtract(const Duration(days: 1));
  final start = istWeekStart(first);
  final end = istWeekStart(last).add(const Duration(days: 6));
  return [for (var at = start; !at.isAfter(end); at = at.add(const Duration(days: 1))) at];
}

/// What the calendar is showing: the day in view, whether the range is a week or a month, and the
/// filters over it.
@immutable
class CalendarView {
  const CalendarView({
    required this.day,
    this.wholeMonth = false,
    this.types = const {},
    this.courseId,
    this.instructorId,
  });

  /// The IST day the agenda is showing.
  final DateTime day;

  /// Whether the range read is the whole month (a tablet's grid) or the week.
  final bool wholeMonth;
  final Set<CalendarEventType> types;
  final String? courseId;
  final String? instructorId;

  /// The first and last IST day the route is asked for.
  (DateTime, DateTime) get range {
    final days = wholeMonth ? istMonthGrid(day) : istWeekOf(day);
    return (days.first, days.last);
  }

  CalendarView copyWith({
    DateTime? day,
    bool? wholeMonth,
    Set<CalendarEventType>? types,
    String? courseId,
    bool clearCourse = false,
    String? instructorId,
    bool clearInstructor = false,
  }) => CalendarView(
    day: day ?? this.day,
    wholeMonth: wholeMonth ?? this.wholeMonth,
    types: types ?? this.types,
    courseId: clearCourse ? null : (courseId ?? this.courseId),
    instructorId: clearInstructor ? null : (instructorId ?? this.instructorId),
  );

  @override
  bool operator ==(Object other) =>
      other is CalendarView &&
      other.day == day &&
      other.wholeMonth == wholeMonth &&
      setEquals(other.types, types) &&
      other.courseId == courseId &&
      other.instructorId == instructorId;

  @override
  int get hashCode =>
      Object.hash(day, wholeMonth, Object.hashAllUnordered(types), courseId, instructorId);
}

class CalendarViewController extends Notifier<CalendarView> {
  @override
  CalendarView build() => CalendarView(day: istDayOf(ref.read(clockProvider)()));

  void showDay(DateTime istDay) => state = state.copyWith(day: istDay);

  void showToday() => state = state.copyWith(day: istDayOf(ref.read(clockProvider)()));

  void moveWeeks(int weeks) =>
      state = state.copyWith(day: state.day.add(Duration(days: 7 * weeks)));

  void showWholeMonth({required bool whole}) => state = state.copyWith(wholeMonth: whole);

  void toggleType(CalendarEventType type) => state = state.copyWith(
    types: state.types.contains(type)
        ? (state.types.toSet()..remove(type))
        : {...state.types, type},
  );

  void showEveryType() => state = state.copyWith(types: const {});

  void inCourse(String? courseId) => courseId == null
      ? state = state.copyWith(clearCourse: true)
      : state = state.copyWith(courseId: courseId);

  void byInstructor(String? instructorId) => instructorId == null
      ? state = state.copyWith(clearInstructor: true)
      : state = state.copyWith(instructorId: instructorId);
}

final calendarViewProvider = NotifierProvider<CalendarViewController, CalendarView>(
  CalendarViewController.new,
  isAutoDispose: true,
);

/// The events in the range on screen. The counts the route sends cover the **whole range**, so the
/// type chips keep their numbers as one type is picked.
final calendarRangeProvider = FutureProvider<CalendarPage>((ref) {
  final view = ref.watch(calendarViewProvider);
  final (from, to) = view.range;
  return ref
      .watch(staffCalendarApiProvider)
      .range(
        fromIstDay: from,
        toIstDay: to,
        types: view.types.toList(),
        courseId: view.courseId,
        instructorId: view.instructorId,
      );
}, isAutoDispose: true);

final calendarEventProvider = FutureProvider.family<CalendarDetail, String>(
  (ref, eventId) => ref.watch(staffCalendarApiProvider).event(eventId),
  isAutoDispose: true,
);

/// What a calendar action left behind.
@immutable
class CalendarActionState {
  const CalendarActionState({
    this.busy = false,
    this.savedId,
    this.removed = false,
    this.issues = const [],
    this.failure,
  });

  final bool busy;
  final String? savedId;
  final bool removed;

  /// What the academy refused, field by field (`validateCalendarEvent`).
  final List<FieldIssue> issues;
  final AppFailure? failure;

  String? messageFor(String field) =>
      issues.where((i) => i.key == field).map((i) => i.message).firstOrNull;
}

/// Adding, saving, removing and ticking off. Every refusal is the academy's.
class CalendarActionController extends Notifier<CalendarActionState> {
  @override
  CalendarActionState build() => const CalendarActionState();

  void clearAnswer() => state = const CalendarActionState();

  Future<String?> create(CalendarEventForm form) async =>
      (await _write(() => ref.read(staffCalendarApiProvider).create(form)))?.id;

  Future<bool> save(String eventId, CalendarEventForm form) async =>
      await _write(
        () => ref.read(staffCalendarApiProvider).save(eventId, form),
        eventId: eventId,
      ) !=
      null;

  Future<bool> setDone(String eventId, {required bool done}) async =>
      await _write(
        () => ref.read(staffCalendarApiProvider).setDone(eventId, done: done),
        eventId: eventId,
      ) !=
      null;

  Future<bool> remove(String eventId) async {
    if (state.busy) return false;
    state = const CalendarActionState(busy: true);
    try {
      await ref.read(staffCalendarApiProvider).remove(eventId);
      if (!ref.mounted) return true;
      state = const CalendarActionState(removed: true);
      ref.invalidate(calendarRangeProvider);
      return true;
    } on ApiException catch (e) {
      if (!ref.mounted) return false;
      state = CalendarActionState(failure: e.failure);
      return false;
    }
  }

  Future<CalendarEvent?> _write(Future<CalendarEvent> Function() action, {String? eventId}) async {
    if (state.busy) return null;
    state = const CalendarActionState(busy: true);
    try {
      final saved = await action();
      if (!ref.mounted) return saved;
      state = CalendarActionState(savedId: saved.id);
      ref.invalidate(calendarRangeProvider);
      if (eventId != null) ref.invalidate(calendarEventProvider(eventId));
      return saved;
    } on ApiException catch (e) {
      if (!ref.mounted) return null;
      final failure = e.failure;
      final issues = switch (failure) {
        ConflictFailure(:final issues) => issues,
        ValidationFailure(:final issues) => issues,
        _ => const <FieldIssue>[],
      };
      state = CalendarActionState(issues: issues, failure: issues.isEmpty ? failure : null);
      return null;
    }
  }
}

final calendarActionProvider = NotifierProvider<CalendarActionController, CalendarActionState>(
  CalendarActionController.new,
  isAutoDispose: true,
);

/// The event being written, for a new one or an edit.
class CalendarFormController extends Notifier<CalendarEventForm> {
  CalendarFormController(this.eventId);

  /// Null for a new event.
  final String? eventId;

  bool _seeded = false;

  bool get dirty => _dirty;
  bool _dirty = false;

  @override
  CalendarEventForm build() {
    final id = eventId;
    if (id == null) {
      // A new event opens on the day in view, an hour from now.
      final start = ref.read(clockProvider)().add(const Duration(hours: 1));
      final wall = Ist.wallClock(start);
      return CalendarEventForm(
        startsAt: Ist.instantFromWallClock(wall.year, wall.month, wall.day, wall.hour),
      );
    }
    final detail = ref.watch(calendarEventProvider(id)).value;
    if (detail == null) return const CalendarEventForm();
    if (_seeded) return state;
    _seeded = true;
    return CalendarEventForm.of(detail.event);
  }

  void _edit(CalendarEventForm next) {
    _dirty = true;
    state = next;
  }

  void ofType(CalendarEventType type) => _edit(state.copyWith(type: type));

  void titled(String title) => _edit(state.copyWith(title: title));

  void describedAs(String description) => _edit(state.copyWith(description: description));

  void timed(CalendarTiming timing) => _edit(state.copyWith(timing: timing));

  void startingAt(DateTime startsAt) => _edit(state.copyWith(startsAt: startsAt));

  void lasting(int durationMin) => _edit(state.copyWith(durationMin: durationMin));

  void inCourse(String? courseId) => _edit(state.copyWith(courseId: courseId));

  void inChapter(String? chapterId) => _edit(state.copyWith(chapterId: chapterId));

  void forQuiz(String? quizId) => _edit(state.copyWith(quizId: quizId));

  void marking(MilestoneKind? kind) => _edit(state.copyWith(milestone: kind));

  void seenBy(ReminderAudience audience) => _edit(state.copyWith(audience: audience));

  void notifying(int? minutes) => _edit(state.copyWith(notifyMin: minutes));

  void saved() => _dirty = false;
}

final calendarFormProvider =
    NotifierProvider.family<CalendarFormController, CalendarEventForm, String?>(
      CalendarFormController.new,
      isAutoDispose: true,
    );
