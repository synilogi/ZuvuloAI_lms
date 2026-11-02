import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/domain/assignment.dart';
import '../data/dto/staff_submission.dart';
import '../data/staff_review_api.dart';

/// What the review screens read (§26).
export '../../../shared/domain/assignment.dart';
export '../data/dto/staff_submission.dart';

/// How many rows one page of the queue holds.
const submissionPageSize = StaffReviewApi.pageSize;

/// How much is waiting, for the queue's headline and the dashboard's own count.
final reviewQueueProvider = FutureProvider<ReviewQueue>(
  (ref) => ref.watch(staffReviewApiProvider).queue(),
  isAutoDispose: true,
);

/// What the queue is showing. `filter` is the route's own word (`to-review`, `graded`, `returned`,
/// `missing`) or `all`.
@immutable
class SubmissionFilter {
  const SubmissionFilter({
    this.filter = 'to-review',
    this.search,
    this.courseId,
    this.assignmentId,
    this.sort = 'oldest',
    this.page = 1,
  });

  final String filter;
  final String? search;
  final String? courseId;
  final String? assignmentId;
  final String sort;
  final int page;

  SubmissionFilter copyWith({
    String? filter,
    String? search,
    bool clearSearch = false,
    String? courseId,
    bool clearCourse = false,
    String? assignmentId,
    bool clearAssignment = false,
    String? sort,
    int? page,
  }) => SubmissionFilter(
    filter: filter ?? this.filter,
    search: clearSearch ? null : (search ?? this.search),
    courseId: clearCourse ? null : (courseId ?? this.courseId),
    assignmentId: clearAssignment ? null : (assignmentId ?? this.assignmentId),
    sort: sort ?? this.sort,
    page: page ?? 1,
  );

  @override
  bool operator ==(Object other) =>
      other is SubmissionFilter &&
      other.filter == filter &&
      other.search == search &&
      other.courseId == courseId &&
      other.assignmentId == assignmentId &&
      other.sort == sort &&
      other.page == page;

  @override
  int get hashCode => Object.hash(filter, search, courseId, assignmentId, sort, page);
}

class SubmissionFilterController extends Notifier<SubmissionFilter> {
  @override
  SubmissionFilter build() => const SubmissionFilter();

  void show(String filter) => state = state.copyWith(filter: filter);

  void searchFor(String? text) => (text == null || text.trim().isEmpty)
      ? state = state.copyWith(clearSearch: true)
      : state = state.copyWith(search: text.trim());

  void inCourse(String? courseId) => courseId == null
      ? state = state.copyWith(clearCourse: true)
      : state = state.copyWith(courseId: courseId);

  void forAssignment(String? assignmentId) => assignmentId == null
      ? state = state.copyWith(clearAssignment: true)
      : state = state.copyWith(assignmentId: assignmentId);

  void sortBy(String sort) => state = state.copyWith(sort: sort);

  void showPage(int page) => state = state.copyWith(page: page);
}

final submissionFilterProvider = NotifierProvider<SubmissionFilterController, SubmissionFilter>(
  SubmissionFilterController.new,
  isAutoDispose: true,
);

/// The hand-ins for the filter on screen.
final submissionsProvider = FutureProvider<SubmissionPage>((ref) {
  final filter = ref.watch(submissionFilterProvider);
  return ref
      .watch(staffReviewApiProvider)
      .submissions(
        assignmentId: filter.assignmentId,
        courseId: filter.courseId,
        filter: filter.filter == 'all' ? null : filter.filter,
        search: filter.search,
        sort: filter.sort,
        page: filter.page,
      );
}, isAutoDispose: true);

/// One assignment's own hand-ins, including the learners who owe it.
final assignmentSubmissionsProvider = FutureProvider.family<SubmissionPage, String>((
  ref,
  assignmentId,
) {
  final filter = ref.watch(submissionFilterProvider);
  return ref
      .watch(staffReviewApiProvider)
      .submissions(
        assignmentId: assignmentId,
        filter: filter.filter == 'all' ? null : filter.filter,
        search: filter.search,
        sort: filter.sort,
        page: filter.page,
      );
}, isAutoDispose: true);

final submissionProvider = FutureProvider.family<SubmissionDetail, String>(
  (ref, submissionId) => ref.watch(staffReviewApiProvider).submission(submissionId),
  isAutoDispose: true,
);

/// The assignments, for the queue's picker. Empty when the academy refuses the read, so the picker
/// simply does not appear.
final staffAssignmentsProvider = FutureProvider<List<StaffAssignmentRow>>((ref) async {
  try {
    return (await ref.watch(staffReviewApiProvider).assignments()).rows;
  } on ApiException {
    return const [];
  }
}, isAutoDispose: true);

/// The review being written: what the reviewer has entered, and what the academy said about it.
@immutable
class ReviewDraft {
  const ReviewDraft({
    this.scores = const {},
    this.points,
    this.feedback = '',
    this.privateNote = '',
    this.busy = false,
    this.issues = const [],
    this.failure,
    this.dirty = false,
  });

  /// Points per rubric criterion, by criterion id.
  final Map<String, num> scores;

  /// Points given directly, when the assignment has no rubric.
  final num? points;
  final String feedback;
  final String privateNote;
  final bool busy;

  /// What the academy refused, field by field, in its own words.
  final List<FieldIssue> issues;

  /// A refusal that is not about a field.
  final AppFailure? failure;

  /// Whether anything has been typed since the screen opened — the unsaved-changes guard.
  final bool dirty;

  ReviewDraft copyWith({
    Map<String, num>? scores,
    num? points,
    bool clearPoints = false,
    String? feedback,
    String? privateNote,
    bool? busy,
    List<FieldIssue>? issues,
    AppFailure? failure,
    bool clearFailure = false,
    bool? dirty,
  }) => ReviewDraft(
    scores: scores ?? this.scores,
    points: clearPoints ? null : (points ?? this.points),
    feedback: feedback ?? this.feedback,
    privateNote: privateNote ?? this.privateNote,
    busy: busy ?? this.busy,
    issues: issues ?? this.issues,
    failure: clearFailure ? null : (failure ?? this.failure),
    dirty: dirty ?? this.dirty,
  );

  /// The academy's own words about one field, if it said anything. A rubric refusal names the
  /// criterion it is about, so each stepper can carry its own message.
  String? messageFor(String field, {String? criterionId}) => issues
      .where((i) => i.isAbout(field, criterionId: criterionId))
      .map((i) => i.message)
      .firstOrNull;
}

/// Writing one review. The score the learner ends up with is the **server's**: it applies the
/// academy's late policy and answers with what it stored, which is what the screen then shows (§18).
class ReviewController extends Notifier<ReviewDraft> {
  ReviewController(this.submissionId);

  final String submissionId;

  @override
  ReviewDraft build() {
    // The screen opens on whatever was already saved — a draft review is kept as `in-review`.
    final detail = ref.watch(submissionProvider(submissionId)).value;
    final review = detail?.submission.review;
    if (review == null) return const ReviewDraft();
    return ReviewDraft(
      scores: review.scores,
      points: review.points,
      feedback: review.feedback,
      privateNote: '',
    );
  }

  void score(String criterionId, num points) => state = state.copyWith(
    scores: {...state.scores, criterionId: points},
    dirty: true,
    issues: const [],
  );

  void scorePoints(num? points) => points == null
      ? state = state.copyWith(clearPoints: true, dirty: true, issues: const [])
      : state = state.copyWith(points: points, dirty: true, issues: const []);

  void writeFeedback(String text) =>
      state = state.copyWith(feedback: text, dirty: true, issues: const []);

  void writePrivateNote(String text) => state = state.copyWith(privateNote: text, dirty: true);

  void clearAnswer() => state = state.copyWith(issues: const [], clearFailure: true);

  /// What this review would score, before the server has its say. Shown as an estimate only: the
  /// academy's late policy is not in the app, so a late hand-in may score less than this (§18).
  ReviewScore estimate(SubmissionDetail detail) => reviewScore(
    detail.assignment,
    scores: state.scores,
    points: state.points,
    late: detail.submission.late,
  );

  /// What the server would refuse, checked the way `validateReview` does, so a button is not
  /// offered for a decision that cannot be taken.
  List<ReviewIssue> problemsWith(SubmissionDetail detail, ReviewStatus decision) => validateReview(
    detail.assignment,
    scores: state.scores,
    points: state.points,
    feedback: state.feedback,
    decision: decision,
  );

  Future<bool> saveDraft() => _send(ReviewStatus.inReview);

  Future<bool> returnForChanges() => _send(ReviewStatus.returned);

  Future<bool> grade() => _send(ReviewStatus.graded);

  Future<bool> _send(ReviewStatus decision) async {
    if (state.busy) return false;
    state = state.copyWith(busy: true, issues: const [], clearFailure: true);
    try {
      await ref
          .read(staffReviewApiProvider)
          .review(
            submissionId,
            decision: decision,
            scores: state.scores,
            points: state.points,
            feedback: state.feedback,
            privateNote: state.privateNote.trim().isEmpty ? null : state.privateNote,
          );
      if (!ref.mounted) return true;
      // Nothing is unsaved any more; the re-read below seeds the editor from what was stored.
      state = state.copyWith(busy: false, dirty: false);
      // The queue, the lists and this hand-in have all moved.
      ref
        ..invalidate(reviewQueueProvider)
        ..invalidate(submissionsProvider)
        ..invalidate(submissionProvider(submissionId));
      return true;
    } on ApiException catch (e) {
      if (!ref.mounted) return false;
      final failure = e.failure;
      // A refused decision names the fields it refused (`validateReview`), in the academy's words.
      final issues = failure is ConflictFailure ? failure.issues : const <FieldIssue>[];
      state = state.copyWith(busy: false, issues: issues, failure: issues.isEmpty ? failure : null);
      return false;
    }
  }
}

final reviewProvider = NotifierProvider.family<ReviewController, ReviewDraft, String>(
  ReviewController.new,
  isAutoDispose: true,
);

/// Reminding the learners who have not handed in.
@immutable
class RemindState {
  const RemindState({this.busy = false, this.sent, this.failure});

  final bool busy;

  /// How many the academy actually reminded, as the route counted them.
  final int? sent;
  final AppFailure? failure;
}

class RemindController extends Notifier<RemindState> {
  @override
  RemindState build() => const RemindState();

  void clearAnswer() => state = const RemindState();

  Future<bool> remind(String assignmentId, {List<String> studentIds = const []}) async {
    if (state.busy) return false;
    state = const RemindState(busy: true);
    try {
      final sent = await ref
          .read(staffReviewApiProvider)
          .remind(assignmentId, studentIds: studentIds);
      if (!ref.mounted) return true;
      state = RemindState(sent: sent);
      ref.invalidate(submissionsProvider);
      return true;
    } on ApiException catch (e) {
      if (!ref.mounted) return false;
      state = RemindState(failure: e.failure);
      return false;
    }
  }
}

final remindProvider = NotifierProvider<RemindController, RemindState>(
  RemindController.new,
  isAutoDispose: true,
);
