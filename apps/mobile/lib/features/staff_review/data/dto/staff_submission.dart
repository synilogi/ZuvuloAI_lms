import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';
import '../../../../shared/domain/assignment.dart';

part 'staff_submission.freezed.dart';
part 'staff_submission.g.dart';

/// `GET /assignments/review` — how much is waiting, and where. `overdue` is the academy's own
/// window (48 hours since the hand-in), counted by the route.
@freezed
abstract class ReviewQueue with _$ReviewQueue {
  const factory ReviewQueue({
    @Default(0) int toReview,
    @Default(0) int overdue,
    @Default(<CourseReviewLoad>[]) List<CourseReviewLoad> byCourse,
  }) = _ReviewQueue;

  const ReviewQueue._();

  factory ReviewQueue.fromJson(Map<String, dynamic> json) => _$ReviewQueueFromJson(json);

  bool get isClear => toReview == 0;
}

/// What one course is waiting on.
@freezed
abstract class CourseReviewLoad with _$CourseReviewLoad {
  const factory CourseReviewLoad({
    @Default('') String courseId,
    @Default(0) int toReview,
    @Default(0) int overdue,
  }) = _CourseReviewLoad;

  factory CourseReviewLoad.fromJson(Map<String, dynamic> json) => _$CourseReviewLoadFromJson(json);
}

/// The learner behind a hand-in, as staff read them. The e-mail is here because only staff ever
/// see this list (§18); nothing public may show it.
@freezed
abstract class ReviewLearner with _$ReviewLearner {
  const factory ReviewLearner({
    @Default('') String id,
    @Default('') String name,
    @Default('') String email,
    @Default('') String city,

    /// Their progress through the course, sent with a submission's detail only.
    @Default(0) num progress,
    @NullableUtcDateTimeConverter() DateTime? enrolledAt,
  }) = _ReviewLearner;

  factory ReviewLearner.fromJson(Map<String, dynamic> json) => _$ReviewLearnerFromJson(json);
}

/// One row of `GET /assignments/submissions`. A row with no [submission] is a learner who has not
/// handed in: the route lists them so they can be reminded, and its `id` is a made-up
/// `missing-<assignmentId>-<studentId>` that no detail route will answer.
@freezed
abstract class SubmissionRow with _$SubmissionRow {
  const factory SubmissionRow({
    @Default('') String id,
    Submission? submission,
    @Default(ReviewLearner()) ReviewLearner student,
    @Default('') String assignmentId,
    @Default('') String assignmentTitle,
    @Default('') String courseTitle,
    @Default(0) num maxScore,

    /// Past the academy's review window, as the route worked it out.
    @Default(false) bool overdue,
  }) = _SubmissionRow;

  const SubmissionRow._();

  factory SubmissionRow.fromJson(Map<String, dynamic> json) => _$SubmissionRowFromJson(json);

  /// Nothing handed in — the row exists so the learner can be reminded, not reviewed.
  bool get isMissing => submission == null;
}

/// `GET /assignments/submissions` and `GET /assignments/:id/submissions`.
@freezed
abstract class SubmissionPage with _$SubmissionPage {
  const factory SubmissionPage({
    @Default(<SubmissionRow>[]) List<SubmissionRow> rows,
    @Default(0) int total,
    @Default(<String, int>{}) Map<String, int> counts,
  }) = _SubmissionPage;

  const SubmissionPage._();

  factory SubmissionPage.fromJson(Map<String, dynamic> json) => _$SubmissionPageFromJson(json);

  int countOf(String filter) => counts[filter] ?? 0;
}

/// Where this hand-in sits in what is still waiting on the same assignment, so a reviewer can go
/// straight to the next one. `position` is 0 for a submission that is no longer in the queue.
@freezed
abstract class ReviewQueuePosition with _$ReviewQueuePosition {
  const factory ReviewQueuePosition({
    @Default(0) int position,
    @Default(0) int total,
    String? previousId,
    String? nextId,
  }) = _ReviewQueuePosition;

  const ReviewQueuePosition._();

  factory ReviewQueuePosition.fromJson(Map<String, dynamic> json) =>
      _$ReviewQueuePositionFromJson(json);

  bool get isInQueue => position > 0;
}

/// `GET /assignments/submissions/:submissionId` — one hand-in, the assignment it answers, the
/// learner who sent it and what else is waiting.
@freezed
abstract class SubmissionDetail with _$SubmissionDetail {
  const factory SubmissionDetail({
    required Submission submission,
    required CourseAssignment assignment,
    @Default('') String courseTitle,
    String? chapterTitle,
    @Default(ReviewLearner()) ReviewLearner student,
    @Default(ReviewQueuePosition()) ReviewQueuePosition queue,
  }) = _SubmissionDetail;

  factory SubmissionDetail.fromJson(Map<String, dynamic> json) => _$SubmissionDetailFromJson(json);
}

/// One row of `GET /assignments` — the assignment and how its hand-ins are going.
@freezed
abstract class StaffAssignmentRow with _$StaffAssignmentRow {
  const factory StaffAssignmentRow({
    required CourseAssignment assignment,
    @Default('') String courseTitle,
    String? chapterTitle,
    @Default(0) int submitted,
    @Default(0) int toReview,
    @Default(0) int overdue,
    @Default(0) int graded,

    /// Enrolled learners with nothing handed in; only meaningful once it is published.
    @Default(0) int missing,

    /// The mean score as a percentage of the maximum, or null when nothing is scored yet.
    num? avgScore,
  }) = _StaffAssignmentRow;

  factory StaffAssignmentRow.fromJson(Map<String, dynamic> json) =>
      _$StaffAssignmentRowFromJson(json);
}

/// `GET /assignments`.
@freezed
abstract class StaffAssignmentPage with _$StaffAssignmentPage {
  const factory StaffAssignmentPage({
    @Default(<StaffAssignmentRow>[]) List<StaffAssignmentRow> rows,
    @Default(<String, int>{}) Map<String, int> counts,
  }) = _StaffAssignmentPage;

  factory StaffAssignmentPage.fromJson(Map<String, dynamic> json) =>
      _$StaffAssignmentPageFromJson(json);
}
