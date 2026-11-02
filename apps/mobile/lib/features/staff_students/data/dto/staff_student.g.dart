// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_student.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RosterCourse _$RosterCourseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_RosterCourse', json, ($checkedConvert) {
      final val = _RosterCourse(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        progress: $checkedConvert('progress', (v) => v as num? ?? 0),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(
                _$EnrollmentStatusEnumMap,
                v,
                unknownValue: EnrollmentStatus.unknown,
              ) ??
              EnrollmentStatus.active,
        ),
      );
      return val;
    });

Map<String, dynamic> _$RosterCourseToJson(_RosterCourse instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'progress': instance.progress,
  'status': _$EnrollmentStatusEnumMap[instance.status]!,
};

const _$EnrollmentStatusEnumMap = {
  EnrollmentStatus.active: 'active',
  EnrollmentStatus.completed: 'completed',
  EnrollmentStatus.paused: 'paused',
  EnrollmentStatus.expired: 'expired',
  EnrollmentStatus.unknown: 'unknown',
};

_RosterRow _$RosterRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_RosterRow', json, ($checkedConvert) {
      final val = _RosterRow(
        student: $checkedConvert(
          'student',
          (v) => v == null ? const Student() : Student.fromJson(v as Map<String, dynamic>),
        ),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(_$StudentStatusEnumMap, v, unknownValue: StudentStatus.unknown) ??
              StudentStatus.unknown,
        ),
        courses: $checkedConvert(
          'courses',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => RosterCourse.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <RosterCourse>[],
        ),
        progress: $checkedConvert('progress', (v) => v as num? ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$RosterRowToJson(_RosterRow instance) => <String, dynamic>{
  'student': instance.student.toJson(),
  'status': _$StudentStatusEnumMap[instance.status]!,
  'courses': instance.courses.map((e) => e.toJson()).toList(),
  'progress': instance.progress,
};

const _$StudentStatusEnumMap = {
  StudentStatus.active: 'active',
  StudentStatus.atRisk: 'at-risk',
  StudentStatus.inactive: 'inactive',
  StudentStatus.suspended: 'suspended',
  StudentStatus.unknown: 'unknown',
};

_RosterPage _$RosterPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_RosterPage', json, ($checkedConvert) {
      final val = _RosterPage(
        rows: $checkedConvert(
          'rows',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => RosterRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <RosterRow>[],
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

Map<String, dynamic> _$RosterPageToJson(_RosterPage instance) => <String, dynamic>{
  'rows': instance.rows.map((e) => e.toJson()).toList(),
  'total': instance.total,
  'counts': instance.counts,
};

_ChapterProgress _$ChapterProgressFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ChapterProgress', json, ($checkedConvert) {
      final val = _ChapterProgress(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        percent: $checkedConvert('percent', (v) => v as num? ?? 0),
        completed: $checkedConvert('completed', (v) => (v as num?)?.toInt() ?? 0),
        total: $checkedConvert('total', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$ChapterProgressToJson(_ChapterProgress instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'percent': instance.percent,
  'completed': instance.completed,
  'total': instance.total,
};

_StudentEnrollment _$StudentEnrollmentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StudentEnrollment', json, ($checkedConvert) {
      final val = _StudentEnrollment(
        enrollment: $checkedConvert(
          'enrollment',
          (v) => v == null ? const Enrollment() : Enrollment.fromJson(v as Map<String, dynamic>),
        ),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
        levelTitle: $checkedConvert('levelTitle', (v) => v as String? ?? ''),
        categoryId: $checkedConvert('categoryId', (v) => v as String?),
        instructorNames: $checkedConvert(
          'instructorNames',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
        ),
        chapters: $checkedConvert(
          'chapters',
          (v) => v == null ? const DonePair() : DonePair.fromJson(v as Map<String, dynamic>),
        ),
        lessons: $checkedConvert(
          'lessons',
          (v) => v == null ? const DonePair() : DonePair.fromJson(v as Map<String, dynamic>),
        ),
        lastLessonTitle: $checkedConvert('lastLessonTitle', (v) => v as String?),
        certificateTitle: $checkedConvert('certificateTitle', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$StudentEnrollmentToJson(_StudentEnrollment instance) => <String, dynamic>{
  'enrollment': instance.enrollment.toJson(),
  'courseTitle': instance.courseTitle,
  'levelTitle': instance.levelTitle,
  'categoryId': instance.categoryId,
  'instructorNames': instance.instructorNames,
  'chapters': instance.chapters.toJson(),
  'lessons': instance.lessons.toJson(),
  'lastLessonTitle': instance.lastLessonTitle,
  'certificateTitle': instance.certificateTitle,
};

_DonePair _$DonePairFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_DonePair', json, ($checkedConvert) {
      final val = _DonePair(
        done: $checkedConvert('done', (v) => (v as num?)?.toInt() ?? 0),
        total: $checkedConvert('total', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$DonePairToJson(_DonePair instance) => <String, dynamic>{
  'done': instance.done,
  'total': instance.total,
};

_StudentSummary _$StudentSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StudentSummary', json, ($checkedConvert) {
      final val = _StudentSummary(
        enrolled: $checkedConvert('enrolled', (v) => (v as num?)?.toInt() ?? 0),
        active: $checkedConvert('active', (v) => (v as num?)?.toInt() ?? 0),
        completed: $checkedConvert('completed', (v) => (v as num?)?.toInt() ?? 0),
        avgProgress: $checkedConvert('avgProgress', (v) => v as num? ?? 0),
        studyMinutes: $checkedConvert('studyMinutes', (v) => (v as num?)?.toInt() ?? 0),
        submissions: $checkedConvert('submissions', (v) => (v as num?)?.toInt() ?? 0),
        avgScore: $checkedConvert('avgScore', (v) => v as num?),
      );
      return val;
    });

Map<String, dynamic> _$StudentSummaryToJson(_StudentSummary instance) => <String, dynamic>{
  'enrolled': instance.enrolled,
  'active': instance.active,
  'completed': instance.completed,
  'avgProgress': instance.avgProgress,
  'studyMinutes': instance.studyMinutes,
  'submissions': instance.submissions,
  'avgScore': instance.avgScore,
};

_StudentCertificate _$StudentCertificateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StudentCertificate', json, ($checkedConvert) {
      final val = _StudentCertificate(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        courseId: $checkedConvert('courseId', (v) => v as String? ?? ''),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        issuedAt: $checkedConvert(
          'issuedAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        credentialId: $checkedConvert('credentialId', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$StudentCertificateToJson(_StudentCertificate instance) => <String, dynamic>{
  'id': instance.id,
  'courseId': instance.courseId,
  'courseTitle': instance.courseTitle,
  'title': instance.title,
  'issuedAt': const NullableUtcDateTimeConverter().toJson(instance.issuedAt),
  'credentialId': instance.credentialId,
};

_StudentProfile _$StudentProfileFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_StudentProfile',
  json,
  ($checkedConvert) {
    final val = _StudentProfile(
      student: $checkedConvert(
        'student',
        (v) => v == null ? const Student() : Student.fromJson(v as Map<String, dynamic>),
      ),
      status: $checkedConvert(
        'status',
        (v) =>
            $enumDecodeNullable(_$StudentStatusEnumMap, v, unknownValue: StudentStatus.unknown) ??
            StudentStatus.unknown,
      ),
      quietDays: $checkedConvert('quietDays', (v) => (v as num?)?.toInt() ?? 0),
      rank: $checkedConvert(
        'rank',
        (v) => v == null ? const Rank() : Rank.fromJson(v as Map<String, dynamic>),
      ),
      enrollments: $checkedConvert(
        'enrollments',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => StudentEnrollment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <StudentEnrollment>[],
      ),
      certificates: $checkedConvert(
        'certificates',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => StudentCertificate.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <StudentCertificate>[],
      ),
      summary: $checkedConvert(
        'summary',
        (v) =>
            v == null ? const StudentSummary() : StudentSummary.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$StudentProfileToJson(_StudentProfile instance) => <String, dynamic>{
  'student': instance.student.toJson(),
  'status': _$StudentStatusEnumMap[instance.status]!,
  'quietDays': instance.quietDays,
  'rank': instance.rank.toJson(),
  'enrollments': instance.enrollments.map((e) => e.toJson()).toList(),
  'certificates': instance.certificates.map((e) => e.toJson()).toList(),
  'summary': instance.summary.toJson(),
};

_CourseProgressDetail _$CourseProgressDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CourseProgressDetail', json, ($checkedConvert) {
      final val = _CourseProgressDetail(
        courseId: $checkedConvert('courseId', (v) => v as String? ?? ''),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
        progress: $checkedConvert('progress', (v) => v as num? ?? 0),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(
                _$EnrollmentStatusEnumMap,
                v,
                unknownValue: EnrollmentStatus.unknown,
              ) ??
              EnrollmentStatus.active,
        ),
        chapters: $checkedConvert(
          'chapters',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => ChapterProgress.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <ChapterProgress>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$CourseProgressDetailToJson(_CourseProgressDetail instance) =>
    <String, dynamic>{
      'courseId': instance.courseId,
      'courseTitle': instance.courseTitle,
      'progress': instance.progress,
      'status': _$EnrollmentStatusEnumMap[instance.status]!,
      'chapters': instance.chapters.map((e) => e.toJson()).toList(),
    };

_StudentQuizResult _$StudentQuizResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StudentQuizResult', json, ($checkedConvert) {
      final val = _StudentQuizResult(
        quizId: $checkedConvert('quizId', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
        attempts: $checkedConvert('attempts', (v) => (v as num?)?.toInt() ?? 0),
        best: $checkedConvert('best', (v) => v as num? ?? 0),
        passMark: $checkedConvert('passMark', (v) => v as num? ?? 0),
        lastAt: $checkedConvert(
          'lastAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
      );
      return val;
    });

Map<String, dynamic> _$StudentQuizResultToJson(_StudentQuizResult instance) => <String, dynamic>{
  'quizId': instance.quizId,
  'title': instance.title,
  'courseTitle': instance.courseTitle,
  'attempts': instance.attempts,
  'best': instance.best,
  'passMark': instance.passMark,
  'lastAt': const NullableUtcDateTimeConverter().toJson(instance.lastAt),
};

_StudentAssignmentResult _$StudentAssignmentResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StudentAssignmentResult', json, ($checkedConvert) {
      final val = _StudentAssignmentResult(
        submissionId: $checkedConvert('submissionId', (v) => v as String? ?? ''),
        assignmentId: $checkedConvert('assignmentId', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        courseTitle: $checkedConvert('courseTitle', (v) => v as String? ?? ''),
        submittedAt: $checkedConvert(
          'submittedAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
        status: $checkedConvert(
          'status',
          (v) =>
              $enumDecodeNullable(_$ReviewStatusEnumMap, v, unknownValue: ReviewStatus.unknown) ??
              ReviewStatus.waiting,
        ),
        score: $checkedConvert('score', (v) => v as num?),
        max: $checkedConvert('max', (v) => v as num? ?? 0),
        passMark: $checkedConvert('passMark', (v) => v as num? ?? 0),
        late: $checkedConvert('late', (v) => v as bool? ?? false),
      );
      return val;
    });

Map<String, dynamic> _$StudentAssignmentResultToJson(_StudentAssignmentResult instance) =>
    <String, dynamic>{
      'submissionId': instance.submissionId,
      'assignmentId': instance.assignmentId,
      'title': instance.title,
      'courseTitle': instance.courseTitle,
      'submittedAt': const NullableUtcDateTimeConverter().toJson(instance.submittedAt),
      'status': _$ReviewStatusEnumMap[instance.status]!,
      'score': instance.score,
      'max': instance.max,
      'passMark': instance.passMark,
      'late': instance.late,
    };

const _$ReviewStatusEnumMap = {
  ReviewStatus.waiting: 'waiting',
  ReviewStatus.inReview: 'in-review',
  ReviewStatus.graded: 'graded',
  ReviewStatus.returned: 'returned',
  ReviewStatus.unknown: 'unknown',
};

_StudentProgress _$StudentProgressFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StudentProgress', json, ($checkedConvert) {
      final val = _StudentProgress(
        courses: $checkedConvert(
          'courses',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CourseProgressDetail.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <CourseProgressDetail>[],
        ),
        quizzes: $checkedConvert(
          'quizzes',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => StudentQuizResult.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <StudentQuizResult>[],
        ),
        assignments: $checkedConvert(
          'assignments',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => StudentAssignmentResult.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <StudentAssignmentResult>[],
        ),
        studyWeeks: $checkedConvert(
          'studyWeeks',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => StudyWeek.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <StudyWeek>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$StudentProgressToJson(_StudentProgress instance) => <String, dynamic>{
  'courses': instance.courses.map((e) => e.toJson()).toList(),
  'quizzes': instance.quizzes.map((e) => e.toJson()).toList(),
  'assignments': instance.assignments.map((e) => e.toJson()).toList(),
  'studyWeeks': instance.studyWeeks.map((e) => e.toJson()).toList(),
};

_StudentActivity _$StudentActivityFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_StudentActivity', json, ($checkedConvert) {
      final val = _StudentActivity(
        events: $checkedConvert(
          'events',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => LearningEvent.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <LearningEvent>[],
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

Map<String, dynamic> _$StudentActivityToJson(_StudentActivity instance) => <String, dynamic>{
  'events': instance.events.map((e) => e.toJson()).toList(),
  'total': instance.total,
  'counts': instance.counts,
};
