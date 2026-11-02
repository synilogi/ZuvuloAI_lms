/// A quiz as the **learner** is served it (`learnerQuestion` in `packages/domain/src/quiz.ts`), and
/// the server-run attempt it is taken in (`packages/domain/src/quizSession.ts`).
///
/// The answer key is deliberately absent: `correct`, `acceptedAnswers` and `explanation` are not
/// modelled, so even if a server sent them they could not be read, stored or shown. Scoring
/// happens on the server and nowhere else (§18, §28.4). What the server releases about an attempt
/// once it is handed in is the assessments feature's `AttemptReview`, never a question's.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/json.dart';

part 'quiz.freezed.dart';
part 'quiz.g.dart';

/// `QuestionType`.
enum QuestionType {
  single,
  multiple,
  @JsonValue('true-false')
  trueFalse,
  short,
  unknown,
}

/// `ResultsVisibility` — how much of an attempt the academy lets the learner see afterwards.
enum ResultsVisibility {
  @JsonValue('score-and-answers')
  scoreAndAnswers,
  @JsonValue('score-only')
  scoreOnly,
  hidden,
  unknown,
}

@freezed
abstract class LearnerQuizOption with _$LearnerQuizOption {
  const factory LearnerQuizOption({required String id, @Default('') String text}) =
      _LearnerQuizOption;

  factory LearnerQuizOption.fromJson(Map<String, dynamic> json) =>
      _$LearnerQuizOptionFromJson(json);
}

@freezed
abstract class LearnerQuizQuestion with _$LearnerQuizQuestion {
  const factory LearnerQuizQuestion({
    required String id,
    @JsonKey(unknownEnumValue: QuestionType.unknown)
    @Default(QuestionType.unknown)
    QuestionType type,
    @Default('') String prompt,
    @Default(<LearnerQuizOption>[]) List<LearnerQuizOption> options,
    @Default(0) int points,
    @Default(false) bool required,

    /// Marks lost for a wrong answer — never for a blank one. Null or 0: none.
    @JsonKey(includeIfNull: false) double? negativePoints,
  }) = _LearnerQuizQuestion;

  const LearnerQuizQuestion._();

  factory LearnerQuizQuestion.fromJson(Map<String, dynamic> json) =>
      _$LearnerQuizQuestionFromJson(json);

  /// Whether more than one option may be chosen.
  bool get isMultiple => type == QuestionType.multiple;

  /// Whether the answer is typed rather than chosen.
  bool get isWritten => type == QuestionType.short;

  /// Whether a wrong answer costs marks.
  bool get losesMarks => (negativePoints ?? 0) > 0;
}

/// `ResultsRelease` — results at once, or for everyone once the quiz closes.
enum ResultsRelease {
  @JsonValue('on-submit')
  onSubmit,
  @JsonValue('after-close')
  afterClose,
  unknown,
}

/// `QuizWindow` — where now stands against the quiz's opening and closing times, by the server's
/// clock.
enum QuizWindow { upcoming, open, closed, unknown }

@freezed
abstract class LearnerQuizSettings with _$LearnerQuizSettings {
  const factory LearnerQuizSettings({
    /// Percent of points needed to pass.
    @Default(0) int passMark,

    /// 0 means unlimited.
    @Default(0) int attempts,
    int? timeLimitMin,
    @Default(false) bool shuffleQuestions,
    @Default(false) bool shuffleOptions,
    @JsonKey(unknownEnumValue: ResultsVisibility.unknown)
    @Default(ResultsVisibility.hidden)
    ResultsVisibility showResults,
    @JsonKey(unknownEnumValue: ResultsRelease.unknown)
    @Default(ResultsRelease.onSubmit)
    ResultsRelease resultsRelease,

    /// No attempt starts before this moment, nor from [closesAt]; one under way when the quiz
    /// closes is handed in with what was saved.
    @NullableUtcDateTimeConverter() DateTime? opensAt,
    @NullableUtcDateTimeConverter() DateTime? closesAt,
  }) = _LearnerQuizSettings;

  factory LearnerQuizSettings.fromJson(Map<String, dynamic> json) =>
      _$LearnerQuizSettingsFromJson(json);
}

/// A quiz as a lesson sends it: what it is, before an attempt. Timed and windowed quizzes come with
/// **no questions** — those arrive only with a session the server starts ([QuizSessionStart]) — and
/// the app never answers from [questions] even when an untimed quiz still lists them for old apps.
@freezed
abstract class LearnerQuiz with _$LearnerQuiz {
  const factory LearnerQuiz({
    required String id,
    @Default('') String title,
    @Default('') String instructions,
    @Default(<LearnerQuizQuestion>[]) List<LearnerQuizQuestion> questions,
    @Default(LearnerQuizSettings()) LearnerQuizSettings settings,

    /// The server's own count of questions and points; null from a server before sessions.
    @JsonKey(name: 'questionCount') int? servedQuestionCount,
    @JsonKey(name: 'totalPoints') int? servedTotalPoints,

    /// Attempts used so far, counting every session started.
    @Default(0) int attemptsUsed,

    /// The attempt still open, to resume.
    QuizSessionView? openSession,
    @JsonKey(unknownEnumValue: QuizWindow.unknown) @Default(QuizWindow.open) QuizWindow window,

    /// Some question costs marks for a wrong answer — said before an attempt is started.
    @Default(false) bool negativeMarking,
  }) = _LearnerQuiz;

  const LearnerQuiz._();

  factory LearnerQuiz.fromJson(Map<String, dynamic> json) => _$LearnerQuizFromJson(json);

  int get questionCount => servedQuestionCount ?? questions.length;

  int get totalPoints => servedTotalPoints ?? questions.fold(0, (sum, q) => sum + q.points);
}

/// `QuizSessionStatus`.
enum QuizSessionStatus { active, submitted, expired, unknown }

/// One attempt as the server runs it: started by the server, with the server's deadline and the
/// answers it accepted before it. A countdown is drawn from [remainingSec] measured from the
/// moment the response arrived — never from the phone's wall clock, which may be wrong.
@freezed
abstract class QuizSessionView with _$QuizSessionView {
  const factory QuizSessionView({
    required String id,
    @Default('') String quizId,
    @Default(1) int attemptNo,
    @JsonKey(unknownEnumValue: QuizSessionStatus.unknown)
    @Default(QuizSessionStatus.unknown)
    QuizSessionStatus status,
    @UtcDateTimeConverter() required DateTime startedAt,

    /// Absent for an untimed quiz.
    @NullableUtcDateTimeConverter() DateTime? deadlineAt,

    /// The server's clock when it answered.
    @NullableUtcDateTimeConverter() DateTime? serverNow,

    /// Whole seconds to the deadline by the server's clock, never below 0; null when untimed.
    int? remainingSec,

    /// The answers the server holds: option-id lists for choice questions, text for written ones.
    @Default(<String, dynamic>{}) Map<String, dynamic> answers,

    /// The highest save number the server has accepted. A save numbered no higher is ignored.
    @Default(0) int answersSeq,
    @NullableUtcDateTimeConverter() DateTime? savedAt,
    @NullableUtcDateTimeConverter() DateTime? finishedAt,

    /// The scored attempt, once the session is finished.
    String? attemptId,
  }) = _QuizSessionView;

  const QuizSessionView._();

  factory QuizSessionView.fromJson(Map<String, dynamic> json) => _$QuizSessionViewFromJson(json);

  bool get isActive => status == QuizSessionStatus.active;

  bool get isTimed => remainingSec != null;

  /// The stored answers in the shape the taker keeps them: lists of option ids, or text.
  Map<String, Object> get answerSheet => answerSheetOf(answers);
}

/// [raw] answers as the taker keeps them — anything not a list of ids or a text is dropped.
Map<String, Object> answerSheetOf(Map<String, dynamic> raw) => {
  for (final entry in raw.entries)
    if (entry.value is List)
      entry.key: (entry.value as List).whereType<String>().toList()
    else if (entry.value is String)
      entry.key: entry.value as String,
};

/// What starting — or resuming — a session answers: the session and, only now, its questions, in
/// the order the server fixed for this attempt.
@freezed
abstract class QuizSessionStart with _$QuizSessionStart {
  const factory QuizSessionStart({
    required QuizSessionView session,
    @Default(<LearnerQuizQuestion>[]) List<LearnerQuizQuestion> questions,

    /// True when an open session was picked up again instead of a new attempt being started.
    @Default(false) bool resumed,
  }) = _QuizSessionStart;

  factory QuizSessionStart.fromJson(Map<String, dynamic> json) => _$QuizSessionStartFromJson(json);
}

/// `QuizStanding` — where the learner stands with one quiz: what they may do next. The server's
/// start still decides.
@freezed
abstract class QuizStanding with _$QuizStanding {
  const factory QuizStanding({
    @Default('') String quizId,
    @NullableUtcDateTimeConverter() DateTime? serverNow,
    @JsonKey(unknownEnumValue: QuizWindow.unknown) @Default(QuizWindow.open) QuizWindow window,
    @NullableUtcDateTimeConverter() DateTime? opensAt,
    @NullableUtcDateTimeConverter() DateTime? closesAt,

    /// 0 means unlimited. Once passed, more attempts are practice and not limited.
    @Default(0) int attemptsAllowed,
    @Default(0) int attemptsUsed,
    @Default(false) bool passed,

    /// The attempt still open, to resume.
    QuizSessionView? openSession,

    /// True when an attempt is open to resume or a new one may start.
    @Default(false) bool canStart,

    /// Why not, in the academy's words.
    String? blockedReason,

    /// While results are held until the quiz closes: when they are shown.
    @NullableUtcDateTimeConverter() DateTime? resultsAt,
  }) = _QuizStanding;

  const QuizStanding._();

  factory QuizStanding.fromJson(Map<String, dynamic> json) => _$QuizStandingFromJson(json);

  /// Attempts still to use, or null when unlimited (or passed, when retakes are practice).
  int? get attemptsLeft => attemptsAllowed <= 0 || passed
      ? null
      : (attemptsAllowed - attemptsUsed).clamp(0, attemptsAllowed);
}
