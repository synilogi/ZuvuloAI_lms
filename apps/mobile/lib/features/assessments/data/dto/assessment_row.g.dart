// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assessment_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssessmentRow _$AssessmentRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AssessmentRow', json, ($checkedConvert) {
      final val = _AssessmentRow(
        id: $checkedConvert('id', (v) => v as String),
        lessonId: $checkedConvert('lessonId', (v) => v as String),
        courseId: $checkedConvert('courseId', (v) => v as String),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        questions: $checkedConvert('questions', (v) => (v as num?)?.toInt() ?? 0),
        durationMin: $checkedConvert('durationMin', (v) => (v as num?)?.toInt() ?? 0),
        passMark: $checkedConvert('passMark', (v) => (v as num?)?.toInt() ?? 0),
        attemptsAllowed: $checkedConvert('attemptsAllowed', (v) => (v as num?)?.toInt() ?? 0),
        attemptsUsed: $checkedConvert('attemptsUsed', (v) => (v as num?)?.toInt() ?? 0),
        state: $checkedConvert(
          'state',
          (v) =>
              $enumDecodeNullable(
                _$AssessmentStateEnumMap,
                v,
                unknownValue: AssessmentState.unknown,
              ) ??
              AssessmentState.unknown,
        ),
        lockedReason: $checkedConvert('lockedReason', (v) => v as String?),
        score: $checkedConvert('score', (v) => (v as num?)?.toInt()),
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
        deadlineAt: $checkedConvert(
          'deadlineAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        resultsAt: $checkedConvert(
          'resultsAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        negativeMarking: $checkedConvert('negativeMarking', (v) => v as bool? ?? false),
        passed: $checkedConvert('passed', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$AssessmentRowToJson(_AssessmentRow instance) => <String, dynamic>{
  'id': instance.id,
  'lessonId': instance.lessonId,
  'courseId': instance.courseId,
  'courseTitle': instance.courseTitle,
  'title': instance.title,
  'questions': instance.questions,
  'durationMin': instance.durationMin,
  'passMark': instance.passMark,
  'attemptsAllowed': instance.attemptsAllowed,
  'attemptsUsed': instance.attemptsUsed,
  'state': _$AssessmentStateEnumMap[instance.state]!,
  'lockedReason': instance.lockedReason,
  'score': instance.score,
  'window': _$QuizWindowEnumMap[instance.window]!,
  'opensAt': const NullableUtcDateTimeConverter().toJson(instance.opensAt),
  'closesAt': const NullableUtcDateTimeConverter().toJson(instance.closesAt),
  'deadlineAt': const NullableUtcDateTimeConverter().toJson(instance.deadlineAt),
  'resultsAt': const NullableUtcDateTimeConverter().toJson(instance.resultsAt),
  'negativeMarking': instance.negativeMarking,
  'passed': instance.passed,
};

const _$AssessmentStateEnumMap = {
  AssessmentState.available: 'available',
  AssessmentState.inProgress: 'in-progress',
  AssessmentState.failed: 'failed',
  AssessmentState.locked: 'locked',
  AssessmentState.passed: 'passed',
  AssessmentState.submitted: 'submitted',
  AssessmentState.unknown: 'unknown',
};

const _$QuizWindowEnumMap = {
  QuizWindow.upcoming: 'upcoming',
  QuizWindow.open: 'open',
  QuizWindow.closed: 'closed',
  QuizWindow.unknown: 'unknown',
};
