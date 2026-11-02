import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';
import '../../../../shared/domain/learning.dart';
import '../../../../shared/domain/quiz.dart';

part 'quiz_attempt.freezed.dart';
part 'quiz_attempt.g.dart';

/// `AnswerState` — how the server marked one question of a handed-in attempt.
enum AnswerState { correct, incorrect, partial, unanswered, unknown }

/// How an attempt ended: handed in by the learner, or by the server at the deadline with the
/// answers it had saved by then.
enum AttemptFinish { submitted, expired, unknown }

/// One question of a reviewed attempt (`ReviewedQuestion`): always its outcome; the learner's own
/// answer and the right one only when the academy shows answers **and** the server has released
/// them — never while the quiz can still be taken for credit. The app shows what arrived and never
/// works any of it out.
@freezed
abstract class ReviewedQuestion with _$ReviewedQuestion {
  const factory ReviewedQuestion({
    @JsonKey(unknownEnumValue: AnswerState.unknown) @Default(AnswerState.unknown) AnswerState state,

    /// May be negative: a wrong answer can cost marks.
    @Default(0) double points,

    /// The learner's answer as submitted: option ids, or text.
    Object? answer,
    List<String>? correct,
    List<String>? acceptedAnswers,
    String? explanation,
  }) = _ReviewedQuestion;

  factory ReviewedQuestion.fromJson(Map<String, dynamic> json) => _$ReviewedQuestionFromJson(json);
}

/// `AttemptReview` — an attempt as the learner may see it after handing it in, cut to the quiz's
/// `showResults` by the server.
@freezed
abstract class AttemptReview with _$AttemptReview {
  const factory AttemptReview({
    required String attemptId,
    @UtcDateTimeConverter() required DateTime submittedAt,
    @JsonKey(unknownEnumValue: ResultsVisibility.unknown)
    @Default(ResultsVisibility.hidden)
    ResultsVisibility showResults,
    @Default(false) bool passed,

    /// Never below 0, even when [points] is.
    int? percent,
    double? points,
    double? max,
    int? passMark,

    /// Per question, only when the academy shows answers.
    Map<String, ReviewedQuestion>? questions,

    /// The review is cut to the score while the learner can still take the quiz for credit.
    @Default(false) bool keyWithheld,

    /// While the result is held until the quiz closes: when it is shown.
    @NullableUtcDateTimeConverter() DateTime? resultsAt,

    /// 1 for the first attempt; absent on attempts made before attempts were numbered.
    int? attemptNo,
    @JsonKey(unknownEnumValue: AttemptFinish.unknown)
    @Default(AttemptFinish.submitted)
    AttemptFinish finish,
  }) = _AttemptReview;

  const AttemptReview._();

  factory AttemptReview.fromJson(Map<String, dynamic> json) => _$AttemptReviewFromJson(json);

  /// The result is held back until the quiz closes: nothing about the outcome is shown yet.
  bool get held => resultsAt != null;

  /// Handed in by the server at the deadline, on what it had saved.
  bool get expired => finish == AttemptFinish.expired;

  bool get hasScore => !held && percent != null;
}

/// `GET …/quiz-attempts` — the learner's attempts, newest first, and where they stand now.
@freezed
abstract class QuizAttempts with _$QuizAttempts {
  const factory QuizAttempts({
    @Default(<AttemptReview>[]) List<AttemptReview> attempts,
    required QuizStanding standing,
  }) = _QuizAttempts;

  factory QuizAttempts.fromJson(Map<String, dynamic> json) => _$QuizAttemptsFromJson(json);
}

/// `POST …/quiz-session/:id/submit` — what handing an attempt in answers. Repeating it answers the
/// same result: the server hands an attempt in once.
@freezed
abstract class QuizHandIn with _$QuizHandIn {
  const factory QuizHandIn({
    required QuizSessionView session,

    /// The lesson's completion, on a pass; null otherwise.
    CompleteResult? completion,

    /// Whether the final sheet sent with this call was kept — false after the deadline, and on a
    /// repeat.
    @Default(false) bool answersAccepted,
    AttemptReview? review,
    required QuizStanding standing,
  }) = _QuizHandIn;

  factory QuizHandIn.fromJson(Map<String, dynamic> json) => _$QuizHandInFromJson(json);
}
