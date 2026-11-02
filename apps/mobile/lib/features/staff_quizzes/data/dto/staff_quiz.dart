/// A quiz as **staff** are served it (`mapQuiz` in `apps/api/src/routes/quizzes.ts`): the whole
/// thing, including the answer key. It is a separate model from the learner's `LearnerQuiz` on
/// purpose — the learner's screens cannot reach this file, and an architecture test holds that line
/// (§18, §28.4, FLUTTER-021).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/domain/quiz.dart';

part 'staff_quiz.freezed.dart';
part 'staff_quiz.g.dart';

/// `QuizStatus`.
enum StaffQuizStatus { draft, published, archived, unknown }

@freezed
abstract class StaffQuizOption with _$StaffQuizOption {
  const factory StaffQuizOption({required String id, @Default('') String text}) = _StaffQuizOption;

  factory StaffQuizOption.fromJson(Map<String, dynamic> json) => _$StaffQuizOptionFromJson(json);
}

/// One question, with the answer the academy marks against. Only staff ever read this.
@freezed
abstract class StaffQuizQuestion with _$StaffQuizQuestion {
  const factory StaffQuizQuestion({
    required String id,
    @JsonKey(unknownEnumValue: QuestionType.unknown)
    @Default(QuestionType.unknown)
    QuestionType type,
    @Default('') String prompt,
    @Default(<StaffQuizOption>[]) List<StaffQuizOption> options,

    /// The ids of the correct options.
    @Default(<String>[]) List<String> correct,

    /// Short answers the academy accepts, compared without case or surrounding space.
    @Default(<String>[]) List<String> acceptedAnswers,
    @Default(0) int points,
    String? explanation,

    /// `required` on the wire; renamed because `required` is a Dart keyword in this position.
    @JsonKey(name: 'required') @Default(true) bool needed,
  }) = _StaffQuizQuestion;

  const StaffQuizQuestion._();

  factory StaffQuizQuestion.fromJson(Map<String, dynamic> json) =>
      _$StaffQuizQuestionFromJson(json);

  /// The options the academy marks as right, in the order they are shown.
  List<StaffQuizOption> get correctOptions => options.where((o) => correct.contains(o.id)).toList();
}

@freezed
abstract class StaffQuizSettings with _$StaffQuizSettings {
  const factory StaffQuizSettings({
    /// Percent of the points needed to pass.
    @Default(70) int passMark,

    /// 0 means as many as they like.
    @Default(2) int attempts,
    int? timeLimitMin,
    @Default(false) bool shuffleQuestions,
    @Default(true) bool shuffleOptions,
    @JsonKey(unknownEnumValue: ResultsVisibility.unknown)
    @Default(ResultsVisibility.scoreAndAnswers)
    ResultsVisibility showResults,
  }) = _StaffQuizSettings;

  const StaffQuizSettings._();

  factory StaffQuizSettings.fromJson(Map<String, dynamic> json) =>
      _$StaffQuizSettingsFromJson(json);

  bool get unlimitedAttempts => attempts == 0;
}

/// `GET /quizzes/:id`.
@freezed
abstract class StaffQuiz with _$StaffQuiz {
  const factory StaffQuiz({
    required String id,
    @Default('') String courseId,
    String? chapterId,

    /// The assessment lesson that delivers it, when it is part of the curriculum.
    String? lessonId,
    @Default('') String title,
    @Default('') String instructions,
    @JsonKey(unknownEnumValue: StaffQuizStatus.unknown)
    @Default(StaffQuizStatus.draft)
    StaffQuizStatus status,
    @Default(<StaffQuizQuestion>[]) List<StaffQuizQuestion> questions,
    @Default(StaffQuizSettings()) StaffQuizSettings settings,
  }) = _StaffQuiz;

  const StaffQuiz._();

  factory StaffQuiz.fromJson(Map<String, dynamic> json) => _$StaffQuizFromJson(json);

  /// `quizTotalPoints` — summed from the questions, as the list route does.
  int get totalPoints => questions.fold(0, (sum, q) => sum + q.points);
}

/// One row of `GET /quizzes` — the quiz and how it is going. `passRate` and `avgScore` are null
/// until someone has attempted it; a zero would read as everyone failing.
@freezed
abstract class StaffQuizRow with _$StaffQuizRow {
  const factory StaffQuizRow({
    required StaffQuiz quiz,
    @Default('') String courseTitle,
    String? chapterTitle,
    @Default(0) int points,
    @Default(0) int attempts,
    num? passRate,
    num? avgScore,
  }) = _StaffQuizRow;

  factory StaffQuizRow.fromJson(Map<String, dynamic> json) => _$StaffQuizRowFromJson(json);
}

/// `GET /quizzes`.
@freezed
abstract class StaffQuizPage with _$StaffQuizPage {
  const factory StaffQuizPage({
    @Default(<StaffQuizRow>[]) List<StaffQuizRow> rows,
    @Default(<String, int>{}) Map<String, int> counts,
  }) = _StaffQuizPage;

  const StaffQuizPage._();

  factory StaffQuizPage.fromJson(Map<String, dynamic> json) => _$StaffQuizPageFromJson(json);

  int countOf(String status) => counts[status] ?? 0;

  bool get isEmpty => rows.isEmpty;
}

/// One band of the score distribution, named by the server (`0–9%` … `90–100%`).
@freezed
abstract class ScoreBand with _$ScoreBand {
  const factory ScoreBand({@Default('') String label, @Default(0) num value}) = _ScoreBand;

  factory ScoreBand.fromJson(Map<String, dynamic> json) => _$ScoreBandFromJson(json);
}

/// How one question went. `commonWrongOptionId` is absent for a short-answer question, and for one
/// nobody has got wrong.
@freezed
abstract class QuestionStat with _$QuestionStat {
  const factory QuestionStat({
    @Default('') String questionId,
    @Default(0) num correctRate,
    String? commonWrongOptionId,
  }) = _QuestionStat;

  factory QuestionStat.fromJson(Map<String, dynamic> json) => _$QuestionStatFromJson(json);
}

/// `GET /quizzes/:id/stats` — every figure counted by the academy over every attempt, not per
/// learner: someone who attempts it three times is counted three times.
@freezed
abstract class QuizStats with _$QuizStats {
  const factory QuizStats({
    @Default('') String quizId,
    @Default(0) int attempts,
    @Default(0) int learners,
    @Default(0) num passRate,
    @Default(0) num avgScore,
    @Default(0) num medianMinutes,
    @Default(<ScoreBand>[]) List<ScoreBand> distribution,
    @Default(<QuestionStat>[]) List<QuestionStat> questions,
  }) = _QuizStats;

  const QuizStats._();

  factory QuizStats.fromJson(Map<String, dynamic> json) => _$QuizStatsFromJson(json);

  /// Nobody has attempted it yet, so none of the figures mean anything.
  bool get isEmpty => attempts == 0;

  QuestionStat? statFor(String questionId) =>
      questions.where((q) => q.questionId == questionId).firstOrNull;
}
