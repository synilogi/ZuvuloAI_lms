import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';
import '../../../../shared/domain/assignment.dart';

/// The coursework models everyone shares (§26).
export '../../../../shared/domain/assignment.dart';

part 'learner_assignment.freezed.dart';
part 'learner_assignment.g.dart';

/// `AssignmentState` — where the learner stands with one assignment, as the **server** works it
/// out from their submission, their draft and the deadline it computed for them.
enum AssignmentState {
  @JsonValue('not-started')
  notStarted,
  draft,
  submitted,
  @JsonValue('under-review')
  underReview,
  graded,
  overdue,
  closed,
  unknown,
}

/// The work in progress: what will be sent as a draft, and as the submission.
@freezed
abstract class AssignmentWork with _$AssignmentWork {
  const factory AssignmentWork({
    @Default('') String text,
    @Default(<Attachment>[]) List<Attachment> files,
    BirthDetails? chart,
  }) = _AssignmentWork;

  const AssignmentWork._();

  factory AssignmentWork.fromJson(Map<String, dynamic> json) => _$AssignmentWorkFromJson(json);

  /// At most this many files in one request, as the route's schema allows.
  static const maxFiles = 20;

  /// What a hand-in may carry, from `MAX_SUBMISSION_FILES` in `packages/domain/src/assignment.ts`.
  /// A draft may hold more; the submission is refused above this.
  static const maxSubmissionFiles = 3;

  /// The route's own limit on the written part.
  static const maxTextLength = 50000;

  /// Nothing to send yet. The server refuses an empty hand-in and the app does not offer one.
  bool get isEmpty => text.trim().isEmpty && files.isEmpty && (chart?.isEmpty ?? true);

  /// Words, counted the way the server counts them for `wordLimit`.
  int get wordCount => text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
}

/// `GET /learning/assignments` and `/learning/assignments/:id`.
@freezed
abstract class LearnerAssignment with _$LearnerAssignment {
  const factory LearnerAssignment({
    required CourseAssignment assignment,
    @Default('') String courseTitle,
    String? chapterTitle,
    String? lessonId,
    @JsonKey(unknownEnumValue: AssignmentState.unknown)
    @Default(AssignmentState.unknown)
    AssignmentState state,

    /// When it is due **for this learner** — the server works a relative deadline out from when
    /// their chapter opened.
    @NullableUtcDateTimeConverter() DateTime? dueAt,
    Submission? submission,
    AssignmentWork? draft,
  }) = _LearnerAssignment;

  const LearnerAssignment._();

  factory LearnerAssignment.fromJson(Map<String, dynamic> json) =>
      _$LearnerAssignmentFromJson(json);

  /// A submission the reviewer sent back reads as `draft` with a `returned` review — the state
  /// alone would not say so (`routes/learning.ts`).
  bool get isReturned => submission?.review.isReturned ?? false;

  /// Whether there is anything more to hand in. A returned submission may be sent again.
  bool get canSubmit =>
      state != AssignmentState.closed &&
      (submission == null || isReturned) &&
      assignment.status != 'closed';

  /// Where the work area starts: the saved draft, else the returned submission's own work.
  AssignmentWork get startingWork {
    if (draft != null) return draft!;
    final returned = isReturned ? submission : null;
    if (returned == null) return const AssignmentWork();
    return AssignmentWork(text: returned.text ?? '', files: returned.files, chart: returned.chart);
  }
}
