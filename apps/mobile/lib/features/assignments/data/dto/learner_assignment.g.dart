// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learner_assignment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AssignmentWork _$AssignmentWorkFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AssignmentWork', json, ($checkedConvert) {
      final val = _AssignmentWork(
        text: $checkedConvert('text', (v) => v as String? ?? ''),
        files: $checkedConvert(
          'files',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <Attachment>[],
        ),
        chart: $checkedConvert(
          'chart',
          (v) => v == null ? null : BirthDetails.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AssignmentWorkToJson(_AssignmentWork instance) => <String, dynamic>{
  'text': instance.text,
  'files': instance.files.map((e) => e.toJson()).toList(),
  'chart': instance.chart?.toJson(),
};

_LearnerAssignment _$LearnerAssignmentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LearnerAssignment', json, ($checkedConvert) {
      final val = _LearnerAssignment(
        assignment: $checkedConvert(
          'assignment',
          (v) => CourseAssignment.fromJson(v as Map<String, dynamic>),
        ),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
        chapterTitle: $checkedConvert('chapterTitle', (v) => v as String?),
        lessonId: $checkedConvert('lessonId', (v) => v as String?),
        state: $checkedConvert(
          'state',
          (v) =>
              $enumDecodeNullable(
                _$AssignmentStateEnumMap,
                v,
                unknownValue: AssignmentState.unknown,
              ) ??
              AssignmentState.unknown,
        ),
        dueAt: $checkedConvert(
          'dueAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        submission: $checkedConvert(
          'submission',
          (v) => v == null ? null : Submission.fromJson(v as Map<String, dynamic>),
        ),
        draft: $checkedConvert(
          'draft',
          (v) => v == null ? null : AssignmentWork.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LearnerAssignmentToJson(_LearnerAssignment instance) => <String, dynamic>{
  'assignment': instance.assignment.toJson(),
  'courseTitle': instance.courseTitle,
  'chapterTitle': instance.chapterTitle,
  'lessonId': instance.lessonId,
  'state': _$AssignmentStateEnumMap[instance.state]!,
  'dueAt': const NullableUtcDateTimeConverter().toJson(instance.dueAt),
  'submission': instance.submission?.toJson(),
  'draft': instance.draft?.toJson(),
};

const _$AssignmentStateEnumMap = {
  AssignmentState.notStarted: 'not-started',
  AssignmentState.draft: 'draft',
  AssignmentState.submitted: 'submitted',
  AssignmentState.underReview: 'under-review',
  AssignmentState.graded: 'graded',
  AssignmentState.overdue: 'overdue',
  AssignmentState.closed: 'closed',
  AssignmentState.unknown: 'unknown',
};
