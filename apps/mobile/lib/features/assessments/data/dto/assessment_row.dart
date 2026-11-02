import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';
import '../../../../shared/domain/quiz.dart';

part 'assessment_row.freezed.dart';
part 'assessment_row.g.dart';

/// Where a learner stands with one quiz, as the server works it out from their attempts and the
/// course's locks.
enum AssessmentState {
  available,
  @JsonValue('in-progress')
  inProgress,
  failed,
  locked,
  passed,
  submitted,
  unknown,
}

/// A row of `GET /learning/assessments`.
@freezed
abstract class AssessmentRow with _$AssessmentRow {
  const factory AssessmentRow({
    required String id,
    required String lessonId,
    required String courseId,
    @Default('') String courseTitle,
    @Default('') String title,
    @Default(0) int questions,
    @Default(0) int durationMin,
    @Default(0) int passMark,

    /// 0 means unlimited.
    @Default(0) int attemptsAllowed,
    @Default(0) int attemptsUsed,
    @JsonKey(unknownEnumValue: AssessmentState.unknown)
    @Default(AssessmentState.unknown)
    AssessmentState state,
    String? lockedReason,

    /// The learner's best percentage so far. Absent while results are held until the quiz closes.
    int? score,
    @JsonKey(unknownEnumValue: QuizWindow.unknown) @Default(QuizWindow.open) QuizWindow window,
    @NullableUtcDateTimeConverter() DateTime? opensAt,
    @NullableUtcDateTimeConverter() DateTime? closesAt,

    /// When the attempt under way must be handed in, by the server's clock.
    @NullableUtcDateTimeConverter() DateTime? deadlineAt,

    /// While results are held until the quiz closes: when they are shown.
    @NullableUtcDateTimeConverter() DateTime? resultsAt,

    /// Some question costs marks for a wrong answer.
    @Default(false) bool negativeMarking,

    /// The learner has passed: further attempts are practice, and not limited.
    @Default(false) bool passed,
  }) = _AssessmentRow;

  const AssessmentRow._();

  factory AssessmentRow.fromJson(Map<String, dynamic> json) => _$AssessmentRowFromJson(json);

  /// How many tries are left, or null when the academy sets no limit. Never a reason to stop the
  /// learner: the server refuses the attempt if there are none (§18).
  int? get attemptsLeft => attemptsAllowed <= 0 || passed
      ? null
      : (attemptsAllowed - attemptsUsed).clamp(0, attemptsAllowed);

  /// An attempt is under way, to resume.
  bool get inProgress => state == AssessmentState.inProgress;

  /// Whether the quiz is a way in: an attempt to resume, or one to start while the window is open.
  /// The server's start still decides.
  bool get isOpen =>
      inProgress ||
      ((state == AssessmentState.available || state == AssessmentState.failed) &&
          window != QuizWindow.upcoming &&
          window != QuizWindow.closed);

  /// Results are held until the quiz closes, as the server says.
  bool get resultsHeld => resultsAt != null;
}
