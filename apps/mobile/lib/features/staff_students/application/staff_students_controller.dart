import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../data/dto/staff_student.dart';
import '../data/staff_students_api.dart';

/// What the staff student screens read (§26).
export '../../../shared/domain/people.dart';
export '../data/dto/staff_student.dart';

/// How many rows one page of the roster holds.
const rosterPageSize = StaffStudentsApi.pageSize;

/// The most learners one message may name, as the route's schema allows.
const maxMessageRecipients = StaffStudentsApi.maxMessageRecipients;

/// What the roster is showing.
@immutable
class RosterFilter {
  const RosterFilter({
    this.status = 'all',
    this.search,
    this.courseId,
    this.sort = 'active',
    this.page = 1,
  });

  final String status;
  final String? search;
  final String? courseId;

  /// `name`, `progress`, `joined`, or the route's default — last active first.
  final String sort;
  final int page;

  RosterFilter copyWith({
    String? status,
    String? search,
    bool clearSearch = false,
    String? courseId,
    bool clearCourse = false,
    String? sort,
    int? page,
  }) => RosterFilter(
    status: status ?? this.status,
    search: clearSearch ? null : (search ?? this.search),
    courseId: clearCourse ? null : (courseId ?? this.courseId),
    sort: sort ?? this.sort,
    page: page ?? 1,
  );

  @override
  bool operator ==(Object other) =>
      other is RosterFilter &&
      other.status == status &&
      other.search == search &&
      other.courseId == courseId &&
      other.sort == sort &&
      other.page == page;

  @override
  int get hashCode => Object.hash(status, search, courseId, sort, page);
}

class RosterFilterController extends Notifier<RosterFilter> {
  @override
  RosterFilter build() => const RosterFilter();

  void showStatus(String status) => state = state.copyWith(status: status);

  void searchFor(String? text) => (text == null || text.trim().isEmpty)
      ? state = state.copyWith(clearSearch: true)
      : state = state.copyWith(search: text.trim());

  void inCourse(String? courseId) => courseId == null
      ? state = state.copyWith(clearCourse: true)
      : state = state.copyWith(courseId: courseId);

  void sortBy(String sort) => state = state.copyWith(sort: sort);

  void showPage(int page) => state = state.copyWith(page: page);
}

final rosterFilterProvider = NotifierProvider<RosterFilterController, RosterFilter>(
  RosterFilterController.new,
  isAutoDispose: true,
);

final rosterProvider = FutureProvider<RosterPage>((ref) {
  final filter = ref.watch(rosterFilterProvider);
  return ref
      .watch(staffStudentsApiProvider)
      .students(
        search: filter.search,
        courseId: filter.courseId,
        status: filter.status == 'all' ? null : filter.status,
        // The route's own default is last-active-first, so the app sends nothing for it.
        sort: filter.sort == 'active' ? null : filter.sort,
        page: filter.page,
      );
}, isAutoDispose: true);

final studentProfileProvider = FutureProvider.family<StudentProfile, String>(
  (ref, studentId) => ref.watch(staffStudentsApiProvider).student(studentId),
  isAutoDispose: true,
);

final studentProgressProvider = FutureProvider.family<StudentProgress, String>(
  (ref, studentId) => ref.watch(staffStudentsApiProvider).progress(studentId),
  isAutoDispose: true,
);

/// What the activity tab is filtered to, for one learner.
@immutable
class ActivityFilter {
  const ActivityFilter({this.kind, this.courseId});

  final String? kind;
  final String? courseId;

  @override
  bool operator ==(Object other) =>
      other is ActivityFilter && other.kind == kind && other.courseId == courseId;

  @override
  int get hashCode => Object.hash(kind, courseId);
}

class ActivityFilterController extends Notifier<ActivityFilter> {
  @override
  ActivityFilter build() => const ActivityFilter();

  void ofKind(String? kind) =>
      state = ActivityFilter(kind: kind == 'all' ? null : kind, courseId: state.courseId);

  void inCourse(String? courseId) => state = ActivityFilter(kind: state.kind, courseId: courseId);
}

final activityFilterProvider = NotifierProvider<ActivityFilterController, ActivityFilter>(
  ActivityFilterController.new,
  isAutoDispose: true,
);

final studentActivityProvider = FutureProvider.family<StudentActivity, String>((ref, studentId) {
  final filter = ref.watch(activityFilterProvider);
  return ref
      .watch(staffStudentsApiProvider)
      .activity(studentId, kind: filter.kind, courseId: filter.courseId);
}, isAutoDispose: true);

/// Which learners the roster has selected, for a message to all of them at once.
class RosterSelection extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String studentId) => state = {
    ...state.contains(studentId) ? (state.toSet()..remove(studentId)) : {...state, studentId},
  };

  void clear() => state = const {};

  bool holds(String studentId) => state.contains(studentId);
}

final rosterSelectionProvider = NotifierProvider<RosterSelection, Set<String>>(
  RosterSelection.new,
  isAutoDispose: true,
);

/// What a learner action left behind: what is in flight, and the academy's answer.
@immutable
class StudentActionState {
  const StudentActionState({this.busy = false, this.sent, this.done = false, this.failure});

  final bool busy;

  /// How many learners the academy actually reached, after a message.
  final int? sent;

  /// The academy carried the action out.
  final bool done;
  final AppFailure? failure;
}

/// Enrolling, pausing, removing, messaging, suspending. Every refusal is the academy's, and every
/// count reported is the one it sent back (§18).
class StudentActionController extends Notifier<StudentActionState> {
  @override
  StudentActionState build() => const StudentActionState();

  void clearAnswer() => state = const StudentActionState();

  Future<bool> enroll(String studentId, {required String courseId}) =>
      _run(studentId, (api) => api.enroll(studentId, courseId: courseId));

  Future<bool> pause(String studentId, String enrollmentId, {required bool paused}) =>
      _run(studentId, (api) => api.setEnrollmentStatus(enrollmentId, paused: paused));

  Future<bool> removeEnrollment(String studentId, String enrollmentId) =>
      _run(studentId, (api) => api.removeEnrollment(enrollmentId));

  Future<bool> setSuspended(String studentId, {required bool suspended, String? reason}) =>
      _run(studentId, (api) => api.setSuspended(studentId, suspended: suspended, reason: reason));

  /// Messages the learners selected. The academy decides who of them it can reach; [sent] is its
  /// count, never the number asked for.
  Future<bool> message({
    required List<String> studentIds,
    required String subject,
    required String body,
    required Set<String> channels,
  }) async {
    if (state.busy) return false;
    state = const StudentActionState(busy: true);
    try {
      final sent = await ref
          .read(staffStudentsApiProvider)
          .message(studentIds: studentIds, subject: subject, body: body, channels: channels);
      if (!ref.mounted) return true;
      state = StudentActionState(sent: sent, done: true);
      return true;
    } on ApiException catch (e) {
      if (!ref.mounted) return false;
      state = StudentActionState(failure: e.failure);
      return false;
    }
  }

  Future<bool> _run(String studentId, Future<void> Function(StaffStudentsApi api) action) async {
    if (state.busy) return false;
    state = const StudentActionState(busy: true);
    try {
      await action(ref.read(staffStudentsApiProvider));
      if (!ref.mounted) return true;
      state = const StudentActionState(done: true);
      // The roster, the profile and everything hanging off it have all moved.
      ref
        ..invalidate(rosterProvider)
        ..invalidate(studentProfileProvider(studentId))
        ..invalidate(studentProgressProvider(studentId))
        ..invalidate(studentActivityProvider(studentId));
      return true;
    } on ApiException catch (e) {
      if (!ref.mounted) return false;
      state = StudentActionState(failure: e.failure);
      return false;
    }
  }
}

final studentActionProvider = NotifierProvider<StudentActionController, StudentActionState>(
  StudentActionController.new,
  isAutoDispose: true,
);

/// What the message form needs before the route will take it, mirroring `messageSchema`. The
/// **server** decides; this only keeps the button honest.
@immutable
class MessageDraft {
  const MessageDraft({this.subject = '', this.body = '', this.channels = const {'app'}});

  final String subject;
  final String body;
  final Set<String> channels;

  static const maxSubject = 200;
  static const minBody = 10;
  static const maxBody = 5000;

  MessageDraft copyWith({String? subject, String? body, Set<String>? channels}) => MessageDraft(
    subject: subject ?? this.subject,
    body: body ?? this.body,
    channels: channels ?? this.channels,
  );

  bool get hasSubject => subject.trim().isNotEmpty && subject.trim().length <= maxSubject;

  bool get hasBody => body.trim().length >= minBody && body.trim().length <= maxBody;

  bool get isReady => hasSubject && hasBody && channels.isNotEmpty;
}

class MessageDraftController extends Notifier<MessageDraft> {
  @override
  MessageDraft build() => const MessageDraft();

  void writeSubject(String text) => state = state.copyWith(subject: text);

  void writeBody(String text) => state = state.copyWith(body: text);

  void toggleChannel(String channel) {
    final next = state.channels.contains(channel)
        ? (state.channels.toSet()..remove(channel))
        : {...state.channels, channel};
    state = state.copyWith(channels: next);
  }

  void reset() => state = const MessageDraft();
}

final messageDraftProvider = NotifierProvider<MessageDraftController, MessageDraft>(
  MessageDraftController.new,
  isAutoDispose: true,
);
