import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/platform/clock.dart';
import '../../../core/platform/live_room.dart';
import '../../../shared/domain/live_class.dart';
import '../data/dto/staff_live.dart';
import '../data/staff_live_api.dart';

/// What the staff live screens read (§26).
export '../../../shared/domain/live_class.dart';
export '../data/dto/staff_live.dart';

/// How many rows one page of the schedule holds.
const livePageSize = StaffLiveApi.pageSize;

/// What the schedule is showing. `view` is the route's own word: `upcoming`, `live`, `history` or
/// `cancelled`.
@immutable
class LiveFilter {
  const LiveFilter({
    this.view = 'upcoming',
    this.search,
    this.courseId,
    this.instructorId,
    this.page = 1,
  });

  final String view;
  final String? search;
  final String? courseId;
  final String? instructorId;
  final int page;

  LiveFilter copyWith({
    String? view,
    String? search,
    bool clearSearch = false,
    String? courseId,
    bool clearCourse = false,
    String? instructorId,
    bool clearInstructor = false,
    int? page,
  }) => LiveFilter(
    view: view ?? this.view,
    search: clearSearch ? null : (search ?? this.search),
    courseId: clearCourse ? null : (courseId ?? this.courseId),
    instructorId: clearInstructor ? null : (instructorId ?? this.instructorId),
    page: page ?? 1,
  );

  @override
  bool operator ==(Object other) =>
      other is LiveFilter &&
      other.view == view &&
      other.search == search &&
      other.courseId == courseId &&
      other.instructorId == instructorId &&
      other.page == page;

  @override
  int get hashCode => Object.hash(view, search, courseId, instructorId, page);
}

class LiveFilterController extends Notifier<LiveFilter> {
  @override
  LiveFilter build() => const LiveFilter();

  void show(String view) => state = state.copyWith(view: view);

  void searchFor(String? text) => (text == null || text.trim().isEmpty)
      ? state = state.copyWith(clearSearch: true)
      : state = state.copyWith(search: text.trim());

  void inCourse(String? courseId) => courseId == null
      ? state = state.copyWith(clearCourse: true)
      : state = state.copyWith(courseId: courseId);

  void byInstructor(String? instructorId) => instructorId == null
      ? state = state.copyWith(clearInstructor: true)
      : state = state.copyWith(instructorId: instructorId);

  void showPage(int page) => state = state.copyWith(page: page);
}

final liveFilterProvider = NotifierProvider<LiveFilterController, LiveFilter>(
  LiveFilterController.new,
  isAutoDispose: true,
);

final staffLiveScheduleProvider = FutureProvider<StaffLivePage>((ref) {
  final filter = ref.watch(liveFilterProvider);
  return ref
      .watch(staffLiveApiProvider)
      .schedule(
        view: filter.view,
        search: filter.search,
        courseId: filter.courseId,
        instructorId: filter.instructorId,
        page: filter.page,
      );
}, isAutoDispose: true);

final staffLiveClassProvider = FutureProvider.family<StaffLiveDetail, String>(
  (ref, liveId) => ref.watch(staffLiveApiProvider).liveClass(liveId),
  isAutoDispose: true,
);

/// A clock that ticks while a live screen is open, so a phase changes on its own as the start time
/// comes and goes (§14). Half a minute, as the design asks.
final liveTickerProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  return Stream<DateTime>.periodic(const Duration(seconds: 30), (_) => clock()).map((now) => now);
}, isAutoDispose: true);

/// The device's idea of now, ticking, for a screen that shows a phase. Used only to show one, never
/// to decide one: what a learner may join is the academy's call (§14, §18).
DateTime liveNow(WidgetRef ref) =>
    ref.watch(liveTickerProvider).value ?? ref.watch(clockProvider)();

/// What a live action left behind.
@immutable
class LiveActionState {
  const LiveActionState({
    this.busy = false,
    this.savedId,
    this.sent,
    this.issues = const [],
    this.failure,
    this.ended = false,
    this.roomFailed = false,
    this.connectionLost = false,
  });

  final bool busy;

  /// The academy closed the room at the host's word.
  final bool ended;

  /// The academy opened the room, but this phone could not show it.
  final bool roomFailed;

  /// The room closed on an error from the video service rather than the host leaving.
  final bool connectionLost;

  /// The class the academy just created or saved.
  final String? savedId;

  /// How many learners a reminder reached, as the academy counted them.
  final int? sent;

  /// What the academy refused, field by field (`validateLiveClass`).
  final List<FieldIssue> issues;
  final AppFailure? failure;

  /// The academy's own words about one field of the form.
  String? messageFor(String field) =>
      issues.where((i) => i.key == field).map((i) => i.message).firstOrNull;
}

/// Scheduling, saving, cancelling and reminding. Every refusal and every count is the academy's.
class LiveActionController extends Notifier<LiveActionState> {
  @override
  LiveActionState build() => const LiveActionState();

  void clearAnswer() => state = const LiveActionState();

  Future<String?> create(LiveClassForm form) async {
    final saved = await _write(() => ref.read(staffLiveApiProvider).create(form));
    return saved?.id;
  }

  Future<bool> save(String liveId, LiveClassForm form) async =>
      await _write(() => ref.read(staffLiveApiProvider).save(liveId, form), liveId: liveId) != null;

  Future<bool> cancel(String liveId, {required String reason}) async =>
      await _write(
        () => ref.read(staffLiveApiProvider).cancel(liveId, reason: reason),
        liveId: liveId,
      ) !=
      null;

  Future<bool> setReminders(String liveId, List<int> reminders) async =>
      await _write(
        () => ref.read(staffLiveApiProvider).setReminders(liveId, reminders),
        liveId: liveId,
      ) !=
      null;

  Future<bool> remind(String liveId) async {
    if (state.busy) return false;
    state = const LiveActionState(busy: true);
    try {
      final sent = await ref.read(staffLiveApiProvider).remind(liveId);
      if (!ref.mounted) return true;
      state = LiveActionState(sent: sent);
      return true;
    } on ApiException catch (e) {
      if (!ref.mounted) return false;
      state = LiveActionState(failure: e.failure);
      return false;
    }
  }

  /// Opens the built-in room (or goes back into it) as its host: the academy starts the class the first
  /// time and hands over the way in, which opens in the Jitsi SDK.
  Future<bool> teach(String liveId, {required bool alreadyStarted}) async {
    if (state.busy) return false;
    state = const LiveActionState(busy: true);
    try {
      final api = ref.read(staffLiveApiProvider);
      final room = alreadyStarted ? (await api.join(liveId)).room : (await api.start(liveId)).room;
      if (!ref.mounted) return true;
      ref.invalidate(staffLiveClassProvider(liveId));
      ref.invalidate(staffLiveScheduleProvider);
      if (room == null) {
        state = const LiveActionState(roomFailed: true);
        return false;
      }
      state = const LiveActionState();
      await ref.read(openLiveRoomProvider)(
        room,
        onClosed: ({connectionLost = false}) {
          if (!ref.mounted) return;
          ref.invalidate(staffLiveClassProvider(liveId));
          ref.invalidate(staffLiveScheduleProvider);
          if (connectionLost) state = const LiveActionState(connectionLost: true);
        },
      );
      return true;
    } on ApiException catch (e) {
      if (!ref.mounted) return false;
      state = LiveActionState(failure: e.failure);
      ref.invalidate(staffLiveClassProvider(liveId));
      return false;
    } on LiveRoomUnavailable {
      if (!ref.mounted) return false;
      state = const LiveActionState(roomFailed: true);
      return false;
    }
  }

  /// Closes the room. The academy settles attendance: whoever held a place and never came is missed.
  Future<bool> end(String liveId) async {
    final ended = await _write(() => ref.read(staffLiveApiProvider).end(liveId), liveId: liveId);
    if (ended == null || !ref.mounted) return false;
    state = const LiveActionState(ended: true);
    return true;
  }

  Future<LiveClass?> _write(Future<LiveClass> Function() action, {String? liveId}) async {
    if (state.busy) return null;
    state = const LiveActionState(busy: true);
    try {
      final saved = await action();
      if (!ref.mounted) return saved;
      state = LiveActionState(savedId: saved.id);
      ref.invalidate(staffLiveScheduleProvider);
      if (liveId != null) ref.invalidate(staffLiveClassProvider(liveId));
      return saved;
    } on ApiException catch (e) {
      if (!ref.mounted) return null;
      final failure = e.failure;
      // A refused write names the fields it refused, in the academy's own words.
      final issues = switch (failure) {
        ConflictFailure(:final issues) => issues,
        ValidationFailure(:final issues) => issues,
        _ => const <FieldIssue>[],
      };
      state = LiveActionState(issues: issues, failure: issues.isEmpty ? failure : null);
      return null;
    }
  }
}

final liveActionProvider = NotifierProvider<LiveActionController, LiveActionState>(
  LiveActionController.new,
  isAutoDispose: true,
);

/// The form being filled in, for a new class or an edit. A `PATCH` takes the whole object, so an
/// edit starts from the class as it stands.
class LiveFormController extends Notifier<LiveClassForm> {
  LiveFormController(this.liveId);

  /// Null for a new class.
  final String? liveId;

  bool _seeded = false;

  /// Whether anything has been typed since the form opened — the unsaved-changes guard.
  bool get dirty => _dirty;
  bool _dirty = false;

  @override
  LiveClassForm build() {
    final id = liveId;
    if (id == null) {
      // A new class opens an hour from now, on the academy's own reminder offsets.
      final start = ref.read(clockProvider)().add(const Duration(hours: 1));
      return LiveClassForm(startsAt: DateTime.utc(start.year, start.month, start.day, start.hour));
    }
    final detail = ref.watch(staffLiveClassProvider(id)).value;
    if (detail == null) return const LiveClassForm();
    // Seeded once: a re-read after a save must not throw away what is being typed.
    if (_seeded) return state;
    _seeded = true;
    return LiveClassForm.of(detail.liveClass);
  }

  void _edit(LiveClassForm next) {
    _dirty = true;
    state = next;
  }

  void inCourse(String courseId) => _edit(state.copyWith(courseId: courseId));

  void titled(String title) => _edit(state.copyWith(title: title));

  void hostedBy(String instructorId) => _edit(state.copyWith(instructorId: instructorId));

  void startingAt(DateTime startsAt) => _edit(state.copyWith(startsAt: startsAt));

  void lasting(int durationMin) => _edit(state.copyWith(durationMin: durationMin));

  void seating(int? capacity) => _edit(state.copyWith(capacity: capacity));

  void describedAs(String description) => _edit(state.copyWith(description: description));

  void seenBy(LiveVisibility visibility) => _edit(state.copyWith(visibility: visibility));

  void meetingAt(String link) => _edit(state.copyWith(meetingLink: link));

  void heldIn(MeetingKind kind) => _edit(state.copyWith(meetingKind: kind));

  void addAgendaItem() => _edit(
    state.copyWith(
      agenda: [
        ...state.agenda,
        const AgendaItem(title: '', minutes: 10),
      ],
    ),
  );

  void editAgendaItem(int index, {String? title, int? minutes}) {
    final agenda = [...state.agenda];
    agenda[index] = agenda[index].copyWith(
      title: title ?? agenda[index].title,
      minutes: minutes ?? agenda[index].minutes,
    );
    _edit(state.copyWith(agenda: agenda));
  }

  void removeAgendaItem(int index) =>
      _edit(state.copyWith(agenda: [...state.agenda]..removeAt(index)));

  void toggleReminder(int minutes) {
    final reminders = state.reminders.contains(minutes)
        ? (state.reminders.toList()..remove(minutes))
        : [...state.reminders, minutes];
    if (reminders.length > LiveClassForm.maxReminders) return;
    _edit(state.copyWith(reminders: reminders..sort((a, b) => b.compareTo(a))));
  }

  void saved() => _dirty = false;
}

final liveFormProvider = NotifierProvider.family<LiveFormController, LiveClassForm, String?>(
  LiveFormController.new,
  isAutoDispose: true,
);

/// What the academy's validator would refuse, checked the way `validateLiveClass` does so a button
/// is not offered for something that cannot be saved. The **server** decides; these are field names,
/// and the screen says the rest in its own words (§18).
List<String> liveFormProblems(LiveClassForm form, {required DateTime now, int registered = 0}) {
  final problems = <String>[];
  if (form.title.trim().length < 3) problems.add('title');
  if (form.courseId.isEmpty) problems.add('course');
  if (form.instructorId.isEmpty) problems.add('instructor');
  final start = form.startsAt;
  if (start == null || !start.isAfter(now)) problems.add('startsAt');
  if (form.durationMin < LiveClassForm.minDuration ||
      form.durationMin > LiveClassForm.maxDuration) {
    problems.add('duration');
  }
  if (form.capacity case final capacity? when capacity < (registered > 1 ? registered : 1)) {
    problems.add('capacity');
  }
  if (form.meetingKind == MeetingKind.external &&
      !RegExp(r'^https://\S+\.\S+').hasMatch(form.meetingLink.trim())) {
    problems.add('meeting');
  }
  if (form.durationMin >= LiveClassForm.minDuration && form.agendaMinutes > form.durationMin) {
    problems.add('agenda');
  }
  return problems;
}
