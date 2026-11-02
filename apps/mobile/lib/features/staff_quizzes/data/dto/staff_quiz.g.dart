// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_quiz.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StaffQuizOption _$StaffQuizOptionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StaffQuizOption', json, ($checkedConvert) {
      final val = _StaffQuizOption(
        id: $checkedConvert('id', (v) => v as String),
        text: $checkedConvert('text', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$StaffQuizOptionToJson(_StaffQuizOption instance) => <String, dynamic>{
  'id': instance.id,
  'text': instance.text,
};

_StaffQuizQuestion _$StaffQuizQuestionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StaffQuizQuestion', json, ($checkedConvert) {
      final val = _StaffQuizQuestion(
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
                  ?.map((e) => StaffQuizOption.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <StaffQuizOption>[],
        ),
        correct: $checkedConvert(
          'correct',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        acceptedAnswers: $checkedConvert(
          'acceptedAnswers',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        points: $checkedConvert('points', (v) => (v as num?)?.toInt() ?? 0),
        explanation: $checkedConvert('explanation', (v) => v as String?),
        needed: $checkedConvert('required', (v) => v as bool? ?? true),
      );
      return val;
    }, fieldKeyMap: const {'needed': 'required'});

Map<String, dynamic> _$StaffQuizQuestionToJson(_StaffQuizQuestion instance) => <String, dynamic>{
  'id': instance.id,
  'type': _$QuestionTypeEnumMap[instance.type]!,
  'prompt': instance.prompt,
  'options': instance.options.map((e) => e.toJson()).toList(),
  'correct': instance.correct,
  'acceptedAnswers': instance.acceptedAnswers,
  'points': instance.points,
  'explanation': instance.explanation,
  'required': instance.needed,
};

const _$QuestionTypeEnumMap = {
  QuestionType.single: 'single',
  QuestionType.multiple: 'multiple',
  QuestionType.trueFalse: 'true-false',
  QuestionType.short: 'short',
  QuestionType.unknown: 'unknown',
};

_StaffQuizSettings _$StaffQuizSettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StaffQuizSettings', json, ($checkedConvert) {
      final val = _StaffQuizSettings(
        passMark: $checkedConvert('passMark', (v) => (v as num?)?.toInt() ?? 70),
        attempts: $checkedConvert('attempts', (v) => (v as num?)?.toInt() ?? 2),
        timeLimitMin: $checkedConvert('timeLimitMin', (v) => (v as num?)?.toInt()),
        shuffleQuestions: $checkedConvert('shuffleQuestions', (v) => v as bool? ?? false),
        shuffleOptions: $checkedConvert('shuffleOptions', (v) => v as bool? ?? true),
        showResults: $checkedConvert(
          'showResults',
          (v) =>
              $enumDecodeNullable(
                _$ResultsVisibilityEnumMap,
                v,
                unknownValue: ResultsVisibility.unknown,
              ) ??
              ResultsVisibility.scoreAndAnswers,
        ),
      );
      return val;
    });

Map<String, dynamic> _$StaffQuizSettingsToJson(_StaffQuizSettings instance) => <String, dynamic>{
  'passMark': instance.passMark,
  'attempts': instance.attempts,
  'timeLimitMin': instance.timeLimitMin,
  'shuffleQuestions': instance.shuffleQuestions,
  'shuffleOptions': instance.shuffleOptions,
  'showResults': _$ResultsVisibilityEnumMap[instance.showResults]!,
};

const _$ResultsVisibilityEnumMap = {
  ResultsVisibility.scoreAndAnswers: 'score-and-answers',
  ResultsVisibility.scoreOnly: 'score-only',
  ResultsVisibility.hidden: 'hidden',
  ResultsVisibility.unknown: 'unknown',
};

_StaffQuiz _$StaffQuizFromJson(Map<String, dynamic> json) => $checkedCreate('_StaffQuiz', json, (
  $checkedConvert,
) {
  final val = _StaffQuiz(
    id: $checkedConvert('id', (v) => v as String),
    courseId: $checkedConvert('courseId', (v) => v as String? ?? ''),
    chapterId: $checkedConvert('chapterId', (v) => v as String?),
    lessonId: $checkedConvert('lessonId', (v) => v as String?),
    title: $checkedConvert('title', (v) => v as String? ?? ''),
    instructions: $checkedConvert('instructions', (v) => v as String? ?? ''),
    status: $checkedConvert(
      'status',
      (v) =>
          $enumDecodeNullable(_$StaffQuizStatusEnumMap, v, unknownValue: StaffQuizStatus.unknown) ??
          StaffQuizStatus.draft,
    ),
    questions: $checkedConvert(
      'questions',
      (v) =>
          (v as List<dynamic>?)
              ?.map((e) => StaffQuizQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <StaffQuizQuestion>[],
    ),
    settings: $checkedConvert(
      'settings',
      (v) => v == null
          ? const StaffQuizSettings()
          : StaffQuizSettings.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$StaffQuizToJson(_StaffQuiz instance) => <String, dynamic>{
  'id': instance.id,
  'courseId': instance.courseId,
  'chapterId': instance.chapterId,
  'lessonId': instance.lessonId,
  'title': instance.title,
  'instructions': instance.instructions,
  'status': _$StaffQuizStatusEnumMap[instance.status]!,
  'questions': instance.questions.map((e) => e.toJson()).toList(),
  'settings': instance.settings.toJson(),
};

const _$StaffQuizStatusEnumMap = {
  StaffQuizStatus.draft: 'draft',
  StaffQuizStatus.published: 'published',
  StaffQuizStatus.archived: 'archived',
  StaffQuizStatus.unknown: 'unknown',
};

_StaffQuizRow _$StaffQuizRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StaffQuizRow', json, ($checkedConvert) {
      final val = _StaffQuizRow(
        quiz: $checkedConvert('quiz', (v) => StaffQuiz.fromJson(v as Map<String, dynamic>)),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
        chapterTitle: $checkedConvert('chapterTitle', (v) => v as String?),
        points: $checkedConvert('points', (v) => (v as num?)?.toInt() ?? 0),
        attempts: $checkedConvert('attempts', (v) => (v as num?)?.toInt() ?? 0),
        passRate: $checkedConvert('passRate', (v) => v as num?),
        avgScore: $checkedConvert('avgScore', (v) => v as num?),
      );
      return val;
    });

Map<String, dynamic> _$StaffQuizRowToJson(_StaffQuizRow instance) => <String, dynamic>{
  'quiz': instance.quiz.toJson(),
  'courseTitle': instance.courseTitle,
  'chapterTitle': instance.chapterTitle,
  'points': instance.points,
  'attempts': instance.attempts,
  'passRate': instance.passRate,
  'avgScore': instance.avgScore,
};

_StaffQuizPage _$StaffQuizPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StaffQuizPage', json, ($checkedConvert) {
      final val = _StaffQuizPage(
        rows: $checkedConvert(
          'rows',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => StaffQuizRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <StaffQuizRow>[],
        ),
        counts: $checkedConvert(
          'counts',
          (v) =>
              (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, (e as num).toInt())) ??
              const <String, int>{},
        ),
      );
      return val;
    });

Map<String, dynamic> _$StaffQuizPageToJson(_StaffQuizPage instance) => <String, dynamic>{
  'rows': instance.rows.map((e) => e.toJson()).toList(),
  'counts': instance.counts,
};

_ScoreBand _$ScoreBandFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ScoreBand', json, ($checkedConvert) {
      final val = _ScoreBand(
        label: $checkedConvert('label', (v) => v as String? ?? ''),
        value: $checkedConvert('value', (v) => v as num? ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$ScoreBandToJson(_ScoreBand instance) => <String, dynamic>{
  'label': instance.label,
  'value': instance.value,
};

_QuestionStat _$QuestionStatFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_QuestionStat', json, ($checkedConvert) {
      final val = _QuestionStat(
        questionId: $checkedConvert('questionId', (v) => v as String? ?? ''),
        correctRate: $checkedConvert('correctRate', (v) => v as num? ?? 0),
        commonWrongOptionId: $checkedConvert('commonWrongOptionId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$QuestionStatToJson(_QuestionStat instance) => <String, dynamic>{
  'questionId': instance.questionId,
  'correctRate': instance.correctRate,
  'commonWrongOptionId': instance.commonWrongOptionId,
};

_QuizStats _$QuizStatsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_QuizStats', json, ($checkedConvert) {
      final val = _QuizStats(
        quizId: $checkedConvert('quizId', (v) => v as String? ?? ''),
        attempts: $checkedConvert('attempts', (v) => (v as num?)?.toInt() ?? 0),
        learners: $checkedConvert('learners', (v) => (v as num?)?.toInt() ?? 0),
        passRate: $checkedConvert('passRate', (v) => v as num? ?? 0),
        avgScore: $checkedConvert('avgScore', (v) => v as num? ?? 0),
        medianMinutes: $checkedConvert('medianMinutes', (v) => v as num? ?? 0),
        distribution: $checkedConvert(
          'distribution',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => ScoreBand.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <ScoreBand>[],
        ),
        questions: $checkedConvert(
          'questions',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => QuestionStat.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <QuestionStat>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$QuizStatsToJson(_QuizStats instance) => <String, dynamic>{
  'quizId': instance.quizId,
  'attempts': instance.attempts,
  'learners': instance.learners,
  'passRate': instance.passRate,
  'avgScore': instance.avgScore,
  'medianMinutes': instance.medianMinutes,
  'distribution': instance.distribution.map((e) => e.toJson()).toList(),
  'questions': instance.questions.map((e) => e.toJson()).toList(),
};
