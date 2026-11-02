import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../data/dto/staff_instructor.dart';
import '../data/staff_instructors_api.dart';

/// What the instructor screens read (§26).
export '../../../shared/domain/course.dart' show CourseStatus, MediaFile;
export '../../../shared/domain/dashboard.dart' show AdminEvent, AdminEventKind;
export '../data/dto/staff_instructor.dart';

/// The sorts the route understands, in the order the screen offers them.
const instructorSorts = StaffInstructorsApi.sorts;

/// What the directory is showing.
@immutable
class DirectoryFilter {
  const DirectoryFilter({this.status = 'all', this.search, this.expertise, this.sort = 'name'});

  final String status;
  final String? search;
  final String? expertise;
  final String sort;

  DirectoryFilter copyWith({
    String? status,
    String? search,
    bool clearSearch = false,
    String? expertise,
    bool clearExpertise = false,
    String? sort,
  }) => DirectoryFilter(
    status: status ?? this.status,
    search: clearSearch ? null : (search ?? this.search),
    expertise: clearExpertise ? null : (expertise ?? this.expertise),
    sort: sort ?? this.sort,
  );

  @override
  bool operator ==(Object other) =>
      other is DirectoryFilter &&
      other.status == status &&
      other.search == search &&
      other.expertise == expertise &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(status, search, expertise, sort);
}

class DirectoryFilterController extends Notifier<DirectoryFilter> {
  @override
  DirectoryFilter build() => const DirectoryFilter();

  void showStatus(String status) => state = state.copyWith(status: status);

  void searchFor(String? text) => (text == null || text.trim().isEmpty)
      ? state = state.copyWith(clearSearch: true)
      : state = state.copyWith(search: text.trim());

  void withExpertise(String? tag) => tag == null
      ? state = state.copyWith(clearExpertise: true)
      : state = state.copyWith(expertise: tag);

  void sortBy(String sort) => state = state.copyWith(sort: sort);
}

final directoryFilterProvider = NotifierProvider<DirectoryFilterController, DirectoryFilter>(
  DirectoryFilterController.new,
  isAutoDispose: true,
);

final instructorDirectoryProvider = FutureProvider<InstructorDirectory>((ref) {
  final filter = ref.watch(directoryFilterProvider);
  return ref
      .watch(staffInstructorsApiProvider)
      .directory(
        search: filter.search,
        status: filter.status == 'all' ? null : filter.status,
        expertise: filter.expertise,
        // Name order is the route's own default, so the app sends nothing for it.
        sort: filter.sort == 'name' ? null : filter.sort,
      );
}, isAutoDispose: true);

final instructorProvider = FutureProvider.family<InstructorDetail, String>(
  (ref, instructorId) => ref.watch(staffInstructorsApiProvider).instructor(instructorId),
  isAutoDispose: true,
);

/// What an instructor action left behind: what is in flight, and the academy's answer.
@immutable
class InstructorActionState {
  const InstructorActionState({
    this.busy = false,
    this.savedId,
    this.invitedTo,
    this.done = false,
    this.issues = const [],
    this.failure,
  });

  final bool busy;

  /// The instructor the academy added or saved.
  final String? savedId;

  /// The address the academy says it sent the invitation to.
  final String? invitedTo;
  final bool done;

  /// The fields the academy refused, in its own words.
  final List<FieldIssue> issues;
  final AppFailure? failure;

  /// The academy's message for one field, or `null` when it said nothing about it.
  String? messageFor(String field) =>
      issues.where((i) => i.isAbout(field)).map((i) => i.message).firstOrNull;
}

/// Adding, saving, changing a status and sending an invitation again. Every refusal is the academy's:
/// a 409 arrives field by field, and a plan limit arrives as its own failure (§6, §18).
class InstructorActionController extends Notifier<InstructorActionState> {
  @override
  InstructorActionState build() => const InstructorActionState();

  void clearAnswer() => state = const InstructorActionState();

  /// Adds an instructor; answers with their id, or `null` when the academy refused.
  Future<String?> create(InstructorForm form) async {
    final saved = await _run((api) => api.create(form));
    return saved?.id;
  }

  Future<bool> save(String instructorId, InstructorForm form) async =>
      await _run((api) => api.save(instructorId, form), instructorId: instructorId) != null;

  Future<bool> setStatus(String instructorId, InstructorStatus status) async =>
      await _run((api) => api.setStatus(instructorId, status), instructorId: instructorId) != null;

  /// Sends the invitation again, and keeps the address the academy says it went to.
  Future<bool> resendInvite(String instructorId) async {
    if (state.busy) return false;
    state = const InstructorActionState(busy: true);
    try {
      final sentTo = await ref.read(staffInstructorsApiProvider).resendInvite(instructorId);
      if (!ref.mounted) return true;
      state = InstructorActionState(invitedTo: sentTo, done: true);
      return true;
    } on ApiException catch (e) {
      if (!ref.mounted) return false;
      state = InstructorActionState(failure: e.failure, issues: _issuesOf(e.failure));
      return false;
    }
  }

  Future<AcademyInstructor?> _run(
    Future<AcademyInstructor> Function(StaffInstructorsApi api) write, {
    String? instructorId,
  }) async {
    if (state.busy) return null;
    state = const InstructorActionState(busy: true);
    try {
      final saved = await write(ref.read(staffInstructorsApiProvider));
      if (!ref.mounted) return saved;
      state = InstructorActionState(savedId: saved.id, done: true);
      ref.invalidate(instructorDirectoryProvider);
      ref.invalidate(instructorProvider(instructorId ?? saved.id));
      return saved;
    } on ApiException catch (e) {
      if (!ref.mounted) return null;
      state = InstructorActionState(failure: e.failure, issues: _issuesOf(e.failure));
      return null;
    }
  }

  List<FieldIssue> _issuesOf(AppFailure failure) =>
      failure is ConflictFailure ? failure.issues : const [];
}

final instructorActionProvider =
    NotifierProvider<InstructorActionController, InstructorActionState>(
      InstructorActionController.new,
      isAutoDispose: true,
    );

/// The invite and edit form. A new instructor opens as `invited`, because that is what sends them
/// their invitation; an edit opens on the record exactly as the academy holds it.
class InstructorFormController extends Notifier<InstructorForm> {
  InstructorFormController(this.instructorId);

  final String? instructorId;

  bool _dirty = false;

  /// Whether anything has been typed since the form opened or was last saved.
  bool get dirty => _dirty;

  @override
  InstructorForm build() {
    final id = instructorId;
    if (id == null) return const InstructorForm();
    final detail = ref.watch(instructorProvider(id)).value;
    if (detail == null) return const InstructorForm(status: InstructorStatus.active);
    return InstructorForm.of(
      detail.instructor,
      courseIds: [for (final course in detail.courses) course.id],
    );
  }

  void _edit(InstructorForm next) {
    _dirty = true;
    state = next;
  }

  void named(String name) => _edit(state.copyWith(name: name));

  void titled(String title) => _edit(state.copyWith(title: title));

  void emailed(String email) => _edit(state.copyWith(email: email));

  void wrote(String bio) => _edit(state.copyWith(bio: bio));

  void inCity(String city) => _edit(state.copyWith(city: city));

  void phoned(String? phone) => _edit(state.copyWith(phone: phone));

  void teaching(int? years) => _edit(state.copyWith(yearsTeaching: years));

  void asStatus(InstructorStatus status) => _edit(state.copyWith(status: status));

  void toggleExpertise(String tag) => _edit(
    state.copyWith(
      expertise: state.expertise.contains(tag)
          ? [...state.expertise.where((e) => e != tag)]
          : [...state.expertise, tag],
    ),
  );

  void toggleLanguage(String language) => _edit(
    state.copyWith(
      languages: state.languages.contains(language)
          ? [...state.languages.where((l) => l != language)]
          : [...state.languages, language],
    ),
  );

  void toggleCourse(String courseId) => _edit(
    state.copyWith(
      courseIds: state.courseIds.contains(courseId)
          ? [...state.courseIds.where((c) => c != courseId)]
          : [...state.courseIds, courseId],
    ),
  );

  /// Called once the academy has taken the form, so the unsaved-changes guard stands down.
  void saved() => _dirty = false;
}

final instructorFormProvider =
    NotifierProvider.family<InstructorFormController, InstructorForm, String?>(
      InstructorFormController.new,
      isAutoDispose: true,
    );

/// The academy's instructor requests (D34), read only for an admin who may manage instructors.
final instructorRequestsProvider = FutureProvider<List<InstructorRequest>>(
  (ref) => ref.watch(staffInstructorsApiProvider).requests(),
  isAutoDispose: true,
);

/// Decides an instructor request (D34) and re-reads what it moves: the requests and the directory
/// the approved instructor joins. Answers with the academy's refusal, or `null` once decided.
class InstructorRequestDecisions {
  InstructorRequestDecisions(this._ref);

  final Ref _ref;

  Future<AppFailure?> approve(String requestId) =>
      _decide(() => _ref.read(staffInstructorsApiProvider).approveRequest(requestId));

  Future<AppFailure?> reject(String requestId) =>
      _decide(() => _ref.read(staffInstructorsApiProvider).rejectRequest(requestId));

  Future<AppFailure?> _decide(Future<void> Function() call) async {
    try {
      await call();
    } on ApiException catch (e) {
      return e.failure;
    }
    _ref
      ..invalidate(instructorRequestsProvider)
      ..invalidate(instructorDirectoryProvider);
    return null;
  }
}

final instructorRequestDecisionsProvider = Provider<InstructorRequestDecisions>(
  InstructorRequestDecisions.new,
);
