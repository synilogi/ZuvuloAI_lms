// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_submission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReviewQueue _$ReviewQueueFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ReviewQueue', json, ($checkedConvert) {
      final val = _ReviewQueue(
        toReview: $checkedConvert('toReview', (v) => (v as num?)?.toInt() ?? 0),
        overdue: $checkedConvert('overdue', (v) => (v as num?)?.toInt() ?? 0),
        byCourse: $checkedConvert(
          'byCourse',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CourseReviewLoad.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <CourseReviewLoad>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$ReviewQueueToJson(_ReviewQueue instance) => <String, dynamic>{
  'toReview': instance.toReview,
  'overdue': instance.overdue,
  'byCourse': instance.byCourse.map((e) => e.toJson()).toList(),
};

_CourseReviewLoad _$CourseReviewLoadFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CourseReviewLoad', json, ($checkedConvert) {
      final val = _CourseReviewLoad(
        courseId: $checkedConvert('courseId', (v) => v as String? ?? ''),
        toReview: $checkedConvert('toReview', (v) => (v as num?)?.toInt() ?? 0),
        overdue: $checkedConvert('overdue', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$CourseReviewLoadToJson(_CourseReviewLoad instance) => <String, dynamic>{
  'courseId': instance.courseId,
  'toReview': instance.toReview,
  'overdue': instance.overdue,
};

_ReviewLearner _$ReviewLearnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ReviewLearner', json, ($checkedConvert) {
      final val = _ReviewLearner(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        email: $checkedConvert('email', (v) => v as String? ?? ''),
        city: $checkedConvert('city', (v) => v as String? ?? ''),
        progress: $checkedConvert('progress', (v) => v as num? ?? 0),
        enrolledAt: $checkedConvert(
          'enrolledAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ReviewLearnerToJson(_ReviewLearner instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'city': instance.city,
  'progress': instance.progress,
  'enrolledAt': const NullableUtcDateTimeConverter().toJson(instance.enrolledAt),
};

_SubmissionRow _$SubmissionRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_SubmissionRow', json, ($checkedConvert) {
      final val = _SubmissionRow(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        submission: $checkedConvert(
          'submission',
          (v) => v == null ? null : Submission.fromJson(v as Map<String, dynamic>),
        ),
        student: $checkedConvert(
          'student',
          (v) =>
              v == null ? const ReviewLearner() : ReviewLearner.fromJson(v as Map<String, dynamic>),
        ),
        assignmentId: $checkedConvert('assignmentId', (v) => v as String? ?? ''),
        assignmentTitle: $checkedConvert('assignmentTitle', (v) => v as String? ?? ''),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
        maxScore: $checkedConvert('maxScore', (v) => v as num? ?? 0),
        overdue: $checkedConvert('overdue', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$SubmissionRowToJson(_SubmissionRow instance) => <String, dynamic>{
  'id': instance.id,
  'submission': instance.submission?.toJson(),
  'student': instance.student.toJson(),
  'assignmentId': instance.assignmentId,
  'assignmentTitle': instance.assignmentTitle,
  'courseTitle': instance.courseTitle,
  'maxScore': instance.maxScore,
  'overdue': instance.overdue,
};

_SubmissionPage _$SubmissionPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_SubmissionPage', json, ($checkedConvert) {
      final val = _SubmissionPage(
        rows: $checkedConvert(
          'rows',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => SubmissionRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <SubmissionRow>[],
        ),
        total: $checkedConvert('total', (v) => (v as num?)?.toInt() ?? 0),
        counts: $checkedConvert(
          'counts',
          (v) =>
              (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, (e as num).toInt())) ??
              const <String, int>{},
        ),
      );
      return val;
    });

Map<String, dynamic> _$SubmissionPageToJson(_SubmissionPage instance) => <String, dynamic>{
  'rows': instance.rows.map((e) => e.toJson()).toList(),
  'total': instance.total,
  'counts': instance.counts,
};

_ReviewQueuePosition _$ReviewQueuePositionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ReviewQueuePosition', json, ($checkedConvert) {
      final val = _ReviewQueuePosition(
        position: $checkedConvert('position', (v) => (v as num?)?.toInt() ?? 0),
        total: $checkedConvert('total', (v) => (v as num?)?.toInt() ?? 0),
        previousId: $checkedConvert('previousId', (v) => v as String?),
        nextId: $checkedConvert('nextId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ReviewQueuePositionToJson(_ReviewQueuePosition instance) =>
    <String, dynamic>{
      'position': instance.position,
      'total': instance.total,
      'previousId': instance.previousId,
      'nextId': instance.nextId,
    };

_SubmissionDetail _$SubmissionDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_SubmissionDetail', json, ($checkedConvert) {
      final val = _SubmissionDetail(
        submission: $checkedConvert(
          'submission',
          (v) => Submission.fromJson(v as Map<String, dynamic>),
        ),
        assignment: $checkedConvert(
          'assignment',
          (v) => CourseAssignment.fromJson(v as Map<String, dynamic>),
        ),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
        chapterTitle: $checkedConvert('chapterTitle', (v) => v as String?),
        student: $checkedConvert(
          'student',
          (v) =>
              v == null ? const ReviewLearner() : ReviewLearner.fromJson(v as Map<String, dynamic>),
        ),
        queue: $checkedConvert(
          'queue',
          (v) => v == null
              ? const ReviewQueuePosition()
              : ReviewQueuePosition.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SubmissionDetailToJson(_SubmissionDetail instance) => <String, dynamic>{
  'submission': instance.submission.toJson(),
  'assignment': instance.assignment.toJson(),
  'courseTitle': instance.courseTitle,
  'chapterTitle': instance.chapterTitle,
  'student': instance.student.toJson(),
  'queue': instance.queue.toJson(),
};

_StaffAssignmentRow _$StaffAssignmentRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StaffAssignmentRow', json, ($checkedConvert) {
      final val = _StaffAssignmentRow(
        assignment: $checkedConvert(
          'assignment',
          (v) => CourseAssignment.fromJson(v as Map<String, dynamic>),
        ),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
        chapterTitle: $checkedConvert('chapterTitle', (v) => v as String?),
        submitted: $checkedConvert('submitted', (v) => (v as num?)?.toInt() ?? 0),
        toReview: $checkedConvert('toReview', (v) => (v as num?)?.toInt() ?? 0),
        overdue: $checkedConvert('overdue', (v) => (v as num?)?.toInt() ?? 0),
        graded: $checkedConvert('graded', (v) => (v as num?)?.toInt() ?? 0),
        missing: $checkedConvert('missing', (v) => (v as num?)?.toInt() ?? 0),
        avgScore: $checkedConvert('avgScore', (v) => v as num?),
      );
      return val;
    });

Map<String, dynamic> _$StaffAssignmentRowToJson(_StaffAssignmentRow instance) => <String, dynamic>{
  'assignment': instance.assignment.toJson(),
  'courseTitle': instance.courseTitle,
  'chapterTitle': instance.chapterTitle,
  'submitted': instance.submitted,
  'toReview': instance.toReview,
  'overdue': instance.overdue,
  'graded': instance.graded,
  'missing': instance.missing,
  'avgScore': instance.avgScore,
};

_StaffAssignmentPage _$StaffAssignmentPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StaffAssignmentPage', json, ($checkedConvert) {
      final val = _StaffAssignmentPage(
        rows: $checkedConvert(
          'rows',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => StaffAssignmentRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <StaffAssignmentRow>[],
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

Map<String, dynamic> _$StaffAssignmentPageToJson(_StaffAssignmentPage instance) =>
    <String, dynamic>{
      'rows': instance.rows.map((e) => e.toJson()).toList(),
      'counts': instance.counts,
    };
