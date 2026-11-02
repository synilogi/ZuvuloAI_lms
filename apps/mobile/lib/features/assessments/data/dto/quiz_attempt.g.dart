// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_attempt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReviewedQuestion _$ReviewedQuestionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ReviewedQuestion', json, ($checkedConvert) {
      final val = _ReviewedQuestion(
        state: $checkedConvert(
          'state',
          (v) =>
              $enumDecodeNullable(_$AnswerStateEnumMap, v, unknownValue: AnswerState.unknown) ??
              AnswerState.unknown,
        ),
        points: $checkedConvert('points', (v) => (v as num?)?.toDouble() ?? 0),
        answer: $checkedConvert('answer', (v) => v),
        correct: $checkedConvert(
          'correct',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        acceptedAnswers: $checkedConvert(
          'acceptedAnswers',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        explanation: $checkedConvert('explanation', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ReviewedQuestionToJson(_ReviewedQuestion instance) => <String, dynamic>{
  'state': _$AnswerStateEnumMap[instance.state]!,
  'points': instance.points,
  'answer': instance.answer,
  'correct': instance.correct,
  'acceptedAnswers': instance.acceptedAnswers,
  'explanation': instance.explanation,
};

const _$AnswerStateEnumMap = {
  AnswerState.correct: 'correct',
  AnswerState.incorrect: 'incorrect',
  AnswerState.partial: 'partial',
  AnswerState.unanswered: 'unanswered',
  AnswerState.unknown: 'unknown',
};

_AttemptReview _$AttemptReviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AttemptReview', json, ($checkedConvert) {
      final val = _AttemptReview(
        attemptId: $checkedConvert('attemptId', (v) => v as String),
        submittedAt: $checkedConvert(
          'submittedAt',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
        showResults: $checkedConvert(
          'showResults',
          (v) =>
              $enumDecodeNullable(
                _$ResultsVisibilityEnumMap,
                v,
                unknownValue: ResultsVisibility.unknown,
              ) ??
              ResultsVisibility.hidden,
        ),
        passed: $checkedConvert('passed', (v) => v as bool? ?? false),
        percent: $checkedConvert('percent', (v) => (v as num?)?.toInt()),
        points: $checkedConvert('points', (v) => (v as num?)?.toDouble()),
        max: $checkedConvert('max', (v) => (v as num?)?.toDouble()),
        passMark: $checkedConvert('passMark', (v) => (v as num?)?.toInt()),
        questions: $checkedConvert(
          'questions',
          (v) => (v as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, ReviewedQuestion.fromJson(e as Map<String, dynamic>)),
          ),
        ),
        keyWithheld: $checkedConvert('keyWithheld', (v) => v as bool? ?? false),
        resultsAt: $checkedConvert(
          'resultsAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        attemptNo: $checkedConvert('attemptNo', (v) => (v as num?)?.toInt()),
        finish: $checkedConvert(
          'finish',
          (v) =>
              $enumDecodeNullable(_$AttemptFinishEnumMap, v, unknownValue: AttemptFinish.unknown) ??
              AttemptFinish.submitted,
        ),
      );
      return val;
    });

Map<String, dynamic> _$AttemptReviewToJson(_AttemptReview instance) => <String, dynamic>{
  'attemptId': instance.attemptId,
  'submittedAt': const UtcDateTimeConverter().toJson(instance.submittedAt),
  'showResults': _$ResultsVisibilityEnumMap[instance.showResults]!,
  'passed': instance.passed,
  'percent': instance.percent,
  'points': instance.points,
  'max': instance.max,
  'passMark': instance.passMark,
  'questions': instance.questions?.map((k, e) => MapEntry(k, e.toJson())),
  'keyWithheld': instance.keyWithheld,
  'resultsAt': const NullableUtcDateTimeConverter().toJson(instance.resultsAt),
  'attemptNo': instance.attemptNo,
  'finish': _$AttemptFinishEnumMap[instance.finish]!,
};

const _$ResultsVisibilityEnumMap = {
  ResultsVisibility.scoreAndAnswers: 'score-and-answers',
  ResultsVisibility.scoreOnly: 'score-only',
  ResultsVisibility.hidden: 'hidden',
  ResultsVisibility.unknown: 'unknown',
};

const _$AttemptFinishEnumMap = {
  AttemptFinish.submitted: 'submitted',
  AttemptFinish.expired: 'expired',
  AttemptFinish.unknown: 'unknown',
};

_QuizAttempts _$QuizAttemptsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_QuizAttempts', json, ($checkedConvert) {
      final val = _QuizAttempts(
        attempts: $checkedConvert(
          'attempts',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => AttemptReview.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <AttemptReview>[],
        ),
        standing: $checkedConvert(
          'standing',
          (v) => QuizStanding.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$QuizAttemptsToJson(_QuizAttempts instance) => <String, dynamic>{
  'attempts': instance.attempts.map((e) => e.toJson()).toList(),
  'standing': instance.standing.toJson(),
};

_QuizHandIn _$QuizHandInFromJson(Map<String, dynamic> json) => $checkedCreate('_QuizHandIn', json, (
  $checkedConvert,
) {
  final val = _QuizHandIn(
    session: $checkedConvert('session', (v) => QuizSessionView.fromJson(v as Map<String, dynamic>)),
    completion: $checkedConvert(
      'completion',
      (v) => v == null ? null : CompleteResult.fromJson(v as Map<String, dynamic>),
    ),
    answersAccepted: $checkedConvert('answersAccepted', (v) => v as bool? ?? false),
    review: $checkedConvert(
      'review',
      (v) => v == null ? null : AttemptReview.fromJson(v as Map<String, dynamic>),
    ),
    standing: $checkedConvert('standing', (v) => QuizStanding.fromJson(v as Map<String, dynamic>)),
  );
  return val;
});

Map<String, dynamic> _$QuizHandInToJson(_QuizHandIn instance) => <String, dynamic>{
  'session': instance.session.toJson(),
  'completion': instance.completion?.toJson(),
  'answersAccepted': instance.answersAccepted,
  'review': instance.review?.toJson(),
  'standing': instance.standing.toJson(),
};
