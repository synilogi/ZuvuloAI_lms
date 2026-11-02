// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LearnerQuizOption _$LearnerQuizOptionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LearnerQuizOption', json, ($checkedConvert) {
      final val = _LearnerQuizOption(
        id: $checkedConvert('id', (v) => v as String),
        text: $checkedConvert('text', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$LearnerQuizOptionToJson(_LearnerQuizOption instance) => <String, dynamic>{
  'id': instance.id,
  'text': instance.text,
};

_LearnerQuizQuestion _$LearnerQuizQuestionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LearnerQuizQuestion', json, ($checkedConvert) {
      final val = _LearnerQuizQuestion(
        id: $checkedConvert('id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) =>
              $enumDecodeNullable(_$QuestionTypeEnumMap, v, unknownValue: QuestionType.unknown) ??
              QuestionType.unknown,
        ),
        prompt: $checkedConvert('prompt', (v) => v as String? ?? ''),
        options: $checkedConvert(
          'options',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => LearnerQuizOption.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <LearnerQuizOption>[],
        ),
        points: $checkedConvert('points', (v) => (v as num?)?.toInt() ?? 0),
        required: $checkedConvert('required', (v) => v as bool? ?? false),
        negativePoints: $checkedConvert('negativePoints', (v) => (v as num?)?.toDouble()),
      );
      return val;
    });

Map<String, dynamic> _$LearnerQuizQuestionToJson(_LearnerQuizQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$QuestionTypeEnumMap[instance.type]!,
      'prompt': instance.prompt,
      'options': instance.options.map((e) => e.toJson()).toList(),
      'points': instance.points,
      'required': instance.required,
      'negativePoints': ?instance.negativePoints,
    };

const _$QuestionTypeEnumMap = {
  QuestionType.single: 'single',
  QuestionType.multiple: 'multiple',
  QuestionType.trueFalse: 'true-false',
  QuestionType.short: 'short',
  QuestionType.unknown: 'unknown',
};

_LearnerQuizSettings _$LearnerQuizSettingsFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_LearnerQuizSettings',
  json,
  ($checkedConvert) {
    final val = _LearnerQuizSettings(
      passMark: $checkedConvert('passMark', (v) => (v as num?)?.toInt() ?? 0),
      attempts: $checkedConvert('attempts', (v) => (v as num?)?.toInt() ?? 0),
      timeLimitMin: $checkedConvert('timeLimitMin', (v) => (v as num?)?.toInt()),
      shuffleQuestions: $checkedConvert('shuffleQuestions', (v) => v as bool? ?? false),
      shuffleOptions: $checkedConvert('shuffleOptions', (v) => v as bool? ?? false),
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
      resultsRelease: $checkedConvert(
        'resultsRelease',
        (v) =>
            $enumDecodeNullable(_$ResultsReleaseEnumMap, v, unknownValue: ResultsRelease.unknown) ??
            ResultsRelease.onSubmit,
      ),
      opensAt: $checkedConvert(
        'opensAt',
        (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
      ),
      closesAt: $checkedConvert(
        'closesAt',
        (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$LearnerQuizSettingsToJson(_LearnerQuizSettings instance) =>
    <String, dynamic>{
      'passMark': instance.passMark,
      'attempts': instance.attempts,
      'timeLimitMin': instance.timeLimitMin,
      'shuffleQuestions': instance.shuffleQuestions,
      'shuffleOptions': instance.shuffleOptions,
      'showResults': _$ResultsVisibilityEnumMap[instance.showResults]!,
      'resultsRelease': _$ResultsReleaseEnumMap[instance.resultsRelease]!,
      'opensAt': const NullableUtcDateTimeConverter().toJson(instance.opensAt),
      'closesAt': const NullableUtcDateTimeConverter().toJson(instance.closesAt),
    };

const _$ResultsVisibilityEnumMap = {
  ResultsVisibility.scoreAndAnswers: 'score-and-answers',
  ResultsVisibility.scoreOnly: 'score-only',
  ResultsVisibility.hidden: 'hidden',
  ResultsVisibility.unknown: 'unknown',
};

const _$ResultsReleaseEnumMap = {
  ResultsRelease.onSubmit: 'on-submit',
  ResultsRelease.afterClose: 'after-close',
  ResultsRelease.unknown: 'unknown',
};

_LearnerQuiz _$LearnerQuizFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_LearnerQuiz',
  json,
  ($checkedConvert) {
    final val = _LearnerQuiz(
      id: $checkedConvert('id', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String? ?? ''),
      instructions: $checkedConvert('instructions', (v) => v as String? ?? ''),
      questions: $checkedConvert(
        'questions',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => LearnerQuizQuestion.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <LearnerQuizQuestion>[],
      ),
      settings: $checkedConvert(
        'settings',
        (v) => v == null
            ? const LearnerQuizSettings()
            : LearnerQuizSettings.fromJson(v as Map<String, dynamic>),
      ),
      servedQuestionCount: $checkedConvert('questionCount', (v) => (v as num?)?.toInt()),
      servedTotalPoints: $checkedConvert('totalPoints', (v) => (v as num?)?.toInt()),
      attemptsUsed: $checkedConvert('attemptsUsed', (v) => (v as num?)?.toInt() ?? 0),
      openSession: $checkedConvert(
        'openSession',
        (v) => v == null ? null : QuizSessionView.fromJson(v as Map<String, dynamic>),
      ),
      window: $checkedConvert(
        'window',
        (v) =>
            $enumDecodeNullable(_$QuizWindowEnumMap, v, unknownValue: QuizWindow.unknown) ??
            QuizWindow.open,
      ),
      negativeMarking: $checkedConvert('negativeMarking', (v) => v as bool? ?? false),
    );
    return val;
  },
  fieldKeyMap: const {'servedQuestionCount': 'questionCount', 'servedTotalPoints': 'totalPoints'},
);

Map<String, dynamic> _$LearnerQuizToJson(_LearnerQuiz instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'instructions': instance.instructions,
  'questions': instance.questions.map((e) => e.toJson()).toList(),
  'settings': instance.settings.toJson(),
  'questionCount': instance.servedQuestionCount,
  'totalPoints': instance.servedTotalPoints,
  'attemptsUsed': instance.attemptsUsed,
  'openSession': instance.openSession?.toJson(),
  'window': _$QuizWindowEnumMap[instance.window]!,
  'negativeMarking': instance.negativeMarking,
};

const _$QuizWindowEnumMap = {
  QuizWindow.upcoming: 'upcoming',
  QuizWindow.open: 'open',
  QuizWindow.closed: 'closed',
  QuizWindow.unknown: 'unknown',
};

_QuizSessionView _$QuizSessionViewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_QuizSessionView', json, ($checkedConvert) {
      final val = _QuizSessionView(
        id: $checkedConvert('id', (v) => v as String),
        quizId: $checkedConvert('quizId', (v) => v as String? ?? ''),
        attemptNo: $checkedConvert('attemptNo', (v) => (v as num?)?.toInt() ?? 1),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(
                _$QuizSessionStatusEnumMap,
                v,
                unknownValue: QuizSessionStatus.unknown,
              ) ??
              QuizSessionStatus.unknown,
        ),
        startedAt: $checkedConvert(
          'startedAt',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
        deadlineAt: $checkedConvert(
          'deadlineAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        serverNow: $checkedConvert(
          'serverNow',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        remainingSec: $checkedConvert('remainingSec', (v) => (v as num?)?.toInt()),
        answers: $checkedConvert(
          'answers',
          (v) => v as Map<String, dynamic>? ?? const <String, dynamic>{},
        ),
        answersSeq: $checkedConvert('answersSeq', (v) => (v as num?)?.toInt() ?? 0),
        savedAt: $checkedConvert(
          'savedAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        finishedAt: $checkedConvert(
          'finishedAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        attemptId: $checkedConvert('attemptId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$QuizSessionViewToJson(_QuizSessionView instance) => <String, dynamic>{
  'id': instance.id,
  'quizId': instance.quizId,
  'attemptNo': instance.attemptNo,
  'status': _$QuizSessionStatusEnumMap[instance.status]!,
  'startedAt': const UtcDateTimeConverter().toJson(instance.startedAt),
  'deadlineAt': const NullableUtcDateTimeConverter().toJson(instance.deadlineAt),
  'serverNow': const NullableUtcDateTimeConverter().toJson(instance.serverNow),
  'remainingSec': instance.remainingSec,
  'answers': instance.answers,
  'answersSeq': instance.answersSeq,
  'savedAt': const NullableUtcDateTimeConverter().toJson(instance.savedAt),
  'finishedAt': const NullableUtcDateTimeConverter().toJson(instance.finishedAt),
  'attemptId': instance.attemptId,
};

const _$QuizSessionStatusEnumMap = {
  QuizSessionStatus.active: 'active',
  QuizSessionStatus.submitted: 'submitted',
  QuizSessionStatus.expired: 'expired',
  QuizSessionStatus.unknown: 'unknown',
};

_QuizSessionStart _$QuizSessionStartFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_QuizSessionStart', json, ($checkedConvert) {
      final val = _QuizSessionStart(
        session: $checkedConvert(
          'session',
          (v) => QuizSessionView.fromJson(v as Map<String, dynamic>),
        ),
        questions: $checkedConvert(
          'questions',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => LearnerQuizQuestion.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <LearnerQuizQuestion>[],
        ),
        resumed: $checkedConvert('resumed', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$QuizSessionStartToJson(_QuizSessionStart instance) => <String, dynamic>{
  'session': instance.session.toJson(),
  'questions': instance.questions.map((e) => e.toJson()).toList(),
  'resumed': instance.resumed,
};

_QuizStanding _$QuizStandingFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_QuizStanding', json, ($checkedConvert) {
      final val = _QuizStanding(
        quizId: $checkedConvert('quizId', (v) => v as String? ?? ''),
        serverNow: $checkedConvert(
          'serverNow',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        window: $checkedConvert(
          'window',
          (v) =>
              $enumDecodeNullable(_$QuizWindowEnumMap, v, unknownValue: QuizWindow.unknown) ??
              QuizWindow.open,
        ),
        opensAt: $checkedConvert(
          'opensAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        closesAt: $checkedConvert(
          'closesAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        attemptsAllowed: $checkedConvert('attemptsAllowed', (v) => (v as num?)?.toInt() ?? 0),
        attemptsUsed: $checkedConvert('attemptsUsed', (v) => (v as num?)?.toInt() ?? 0),
        passed: $checkedConvert('passed', (v) => v as bool? ?? false),
        openSession: $checkedConvert(
          'openSession',
          (v) => v == null ? null : QuizSessionView.fromJson(v as Map<String, dynamic>),
        ),
        canStart: $checkedConvert('canStart', (v) => v as bool? ?? false),
        blockedReason: $checkedConvert('blockedReason', (v) => v as String?),
        resultsAt: $checkedConvert(
          'resultsAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
      );
      return val;
    });

Map<String, dynamic> _$QuizStandingToJson(_QuizStanding instance) => <String, dynamic>{
  'quizId': instance.quizId,
  'serverNow': const NullableUtcDateTimeConverter().toJson(instance.serverNow),
  'window': _$QuizWindowEnumMap[instance.window]!,
  'opensAt': const NullableUtcDateTimeConverter().toJson(instance.opensAt),
  'closesAt': const NullableUtcDateTimeConverter().toJson(instance.closesAt),
  'attemptsAllowed': instance.attemptsAllowed,
  'attemptsUsed': instance.attemptsUsed,
  'passed': instance.passed,
  'openSession': instance.openSession?.toJson(),
  'canStart': instance.canStart,
  'blockedReason': instance.blockedReason,
  'resultsAt': const NullableUtcDateTimeConverter().toJson(instance.resultsAt),
};
