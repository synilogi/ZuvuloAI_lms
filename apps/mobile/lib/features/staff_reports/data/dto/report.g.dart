// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReportWindow _$ReportWindowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ReportWindow', json, ($checkedConvert) {
      final val = _ReportWindow(
        from: $checkedConvert('from', (v) => const UtcDateTimeConverter().fromJson(v as String)),
        to: $checkedConvert('to', (v) => const UtcDateTimeConverter().fromJson(v as String)),
        previousFrom: $checkedConvert(
          'previousFrom',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
        previousTo: $checkedConvert(
          'previousTo',
          (v) => const UtcDateTimeConverter().fromJson(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ReportWindowToJson(_ReportWindow instance) => <String, dynamic>{
  'from': const UtcDateTimeConverter().toJson(instance.from),
  'to': const UtcDateTimeConverter().toJson(instance.to),
  'previousFrom': const UtcDateTimeConverter().toJson(instance.previousFrom),
  'previousTo': const UtcDateTimeConverter().toJson(instance.previousTo),
};

_ReportSeriesPoint _$ReportSeriesPointFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ReportSeriesPoint', json, ($checkedConvert) {
      final val = _ReportSeriesPoint(
        from: $checkedConvert('from', (v) => const UtcDateTimeConverter().fromJson(v as String)),
        to: $checkedConvert('to', (v) => const UtcDateTimeConverter().fromJson(v as String)),
        value: $checkedConvert('value', (v) => v as num? ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$ReportSeriesPointToJson(_ReportSeriesPoint instance) => <String, dynamic>{
  'from': const UtcDateTimeConverter().toJson(instance.from),
  'to': const UtcDateTimeConverter().toJson(instance.to),
  'value': instance.value,
};

_LabelledCount _$LabelledCountFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LabelledCount', json, ($checkedConvert) {
      final val = _LabelledCount(
        label: $checkedConvert('label', (v) => v as String? ?? ''),
        value: $checkedConvert('value', (v) => v as num? ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$LabelledCountToJson(_LabelledCount instance) => <String, dynamic>{
  'label': instance.label,
  'value': instance.value,
};

_ReportSeries _$ReportSeriesFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ReportSeries', json, ($checkedConvert) {
      final val = _ReportSeries(
        enrollments: $checkedConvert(
          'enrollments',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => ReportSeriesPoint.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <ReportSeriesPoint>[],
        ),
        completions: $checkedConvert(
          'completions',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => ReportSeriesPoint.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <ReportSeriesPoint>[],
        ),
        activeLearners: $checkedConvert(
          'activeLearners',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => ReportSeriesPoint.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <ReportSeriesPoint>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$ReportSeriesToJson(_ReportSeries instance) => <String, dynamic>{
  'enrollments': instance.enrollments.map((e) => e.toJson()).toList(),
  'completions': instance.completions.map((e) => e.toJson()).toList(),
  'activeLearners': instance.activeLearners.map((e) => e.toJson()).toList(),
};

_CourseReportRow _$CourseReportRowFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_CourseReportRow',
  json,
  ($checkedConvert) {
    final val = _CourseReportRow(
      courseId: $checkedConvert('courseId', (v) => v as String? ?? ''),
      title: $checkedConvert('title', (v) => v as String? ?? ''),
      categoryTitle: $checkedConvert('categoryTitle', (v) => v as String? ?? ''),
      instructorNames: $checkedConvert(
        'instructorNames',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
      ),
      status: $checkedConvert('status', (v) => v as String? ?? ''),
      enrollments: $checkedConvert('enrollments', (v) => (v as num?)?.toInt() ?? 0),
      previousEnrollments: $checkedConvert('previousEnrollments', (v) => (v as num?)?.toInt() ?? 0),
      completions: $checkedConvert('completions', (v) => (v as num?)?.toInt() ?? 0),
      completionRate: $checkedConvert('completionRate', (v) => (v as num?)?.toInt()),
      activeLearners: $checkedConvert('activeLearners', (v) => (v as num?)?.toInt() ?? 0),
      avgProgress: $checkedConvert('avgProgress', (v) => (v as num?)?.toInt()),
      quizPassRate: $checkedConvert('quizPassRate', (v) => (v as num?)?.toInt()),
      assignmentPassRate: $checkedConvert('assignmentPassRate', (v) => (v as num?)?.toInt()),
      rating: $checkedConvert('rating', (v) => (v as num?)?.toDouble()),
      trend: $checkedConvert(
        'trend',
        (v) => (v as List<dynamic>?)?.map((e) => e as num).toList() ?? const <num>[],
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$CourseReportRowToJson(_CourseReportRow instance) => <String, dynamic>{
  'courseId': instance.courseId,
  'title': instance.title,
  'categoryTitle': instance.categoryTitle,
  'instructorNames': instance.instructorNames,
  'status': instance.status,
  'enrollments': instance.enrollments,
  'previousEnrollments': instance.previousEnrollments,
  'completions': instance.completions,
  'completionRate': instance.completionRate,
  'activeLearners': instance.activeLearners,
  'avgProgress': instance.avgProgress,
  'quizPassRate': instance.quizPassRate,
  'assignmentPassRate': instance.assignmentPassRate,
  'rating': instance.rating,
  'trend': instance.trend,
};

_CategoryReportRow _$CategoryReportRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CategoryReportRow', json, ($checkedConvert) {
      final val = _CategoryReportRow(
        categoryId: $checkedConvert('categoryId', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        enrollments: $checkedConvert('enrollments', (v) => (v as num?)?.toInt() ?? 0),
        previousEnrollments: $checkedConvert('previousEnrollments', (v) => (v as num?)?.toInt()),
        completionRate: $checkedConvert('completionRate', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$CategoryReportRowToJson(_CategoryReportRow instance) => <String, dynamic>{
  'categoryId': instance.categoryId,
  'title': instance.title,
  'enrollments': instance.enrollments,
  'previousEnrollments': instance.previousEnrollments,
  'completionRate': instance.completionRate,
};

_OverviewKpis _$OverviewKpisFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_OverviewKpis', json, ($checkedConvert) {
      final val = _OverviewKpis(
        enrollments: $checkedConvert(
          'enrollments',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        completions: $checkedConvert(
          'completions',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        completionRate: $checkedConvert(
          'completionRate',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        activeLearners: $checkedConvert(
          'activeLearners',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        avgProgress: $checkedConvert(
          'avgProgress',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$OverviewKpisToJson(_OverviewKpis instance) => <String, dynamic>{
  'enrollments': instance.enrollments.toJson(),
  'completions': instance.completions.toJson(),
  'completionRate': instance.completionRate.toJson(),
  'activeLearners': instance.activeLearners.toJson(),
  'avgProgress': instance.avgProgress.toJson(),
};

_QuizFigures _$QuizFiguresFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_QuizFigures', json, ($checkedConvert) {
      final val = _QuizFigures(
        attempts: $checkedConvert(
          'attempts',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        passRate: $checkedConvert(
          'passRate',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        avgScore: $checkedConvert(
          'avgScore',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$QuizFiguresToJson(_QuizFigures instance) => <String, dynamic>{
  'attempts': instance.attempts.toJson(),
  'passRate': instance.passRate.toJson(),
  'avgScore': instance.avgScore.toJson(),
};

_AssignmentFigures _$AssignmentFiguresFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AssignmentFigures', json, ($checkedConvert) {
      final val = _AssignmentFigures(
        submitted: $checkedConvert(
          'submitted',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        passRate: $checkedConvert(
          'passRate',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        onTime: $checkedConvert(
          'onTime',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        reviewHours: $checkedConvert(
          'reviewHours',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AssignmentFiguresToJson(_AssignmentFigures instance) => <String, dynamic>{
  'submitted': instance.submitted.toJson(),
  'passRate': instance.passRate.toJson(),
  'onTime': instance.onTime.toJson(),
  'reviewHours': instance.reviewHours.toJson(),
};

_EngagementFigures _$EngagementFiguresFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_EngagementFigures', json, ($checkedConvert) {
      final val = _EngagementFigures(
        lessonsCompleted: $checkedConvert(
          'lessonsCompleted',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        lessonsPerLearner: $checkedConvert(
          'lessonsPerLearner',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        liveAttendance: $checkedConvert(
          'liveAttendance',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$EngagementFiguresToJson(_EngagementFigures instance) => <String, dynamic>{
  'lessonsCompleted': instance.lessonsCompleted.toJson(),
  'lessonsPerLearner': instance.lessonsPerLearner.toJson(),
  'liveAttendance': instance.liveAttendance.toJson(),
};

_OverviewReport _$OverviewReportFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_OverviewReport', json, ($checkedConvert) {
      final val = _OverviewReport(
        window: $checkedConvert('window', (v) => ReportWindow.fromJson(v as Map<String, dynamic>)),
        courseCount: $checkedConvert('courseCount', (v) => (v as num?)?.toInt() ?? 0),
        kpis: $checkedConvert(
          'kpis',
          (v) =>
              v == null ? const OverviewKpis() : OverviewKpis.fromJson(v as Map<String, dynamic>),
        ),
        series: $checkedConvert(
          'series',
          (v) =>
              v == null ? const ReportSeries() : ReportSeries.fromJson(v as Map<String, dynamic>),
        ),
        quizzes: $checkedConvert(
          'quizzes',
          (v) => v == null ? const QuizFigures() : QuizFigures.fromJson(v as Map<String, dynamic>),
        ),
        assignments: $checkedConvert(
          'assignments',
          (v) => v == null
              ? const AssignmentFigures()
              : AssignmentFigures.fromJson(v as Map<String, dynamic>),
        ),
        engagement: $checkedConvert(
          'engagement',
          (v) => v == null
              ? const EngagementFigures()
              : EngagementFigures.fromJson(v as Map<String, dynamic>),
        ),
        progressBands: $checkedConvert(
          'progressBands',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => LabelledCount.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <LabelledCount>[],
        ),
        categories: $checkedConvert(
          'categories',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CategoryReportRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <CategoryReportRow>[],
        ),
        topCourses: $checkedConvert(
          'topCourses',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CourseReportRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <CourseReportRow>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$OverviewReportToJson(_OverviewReport instance) => <String, dynamic>{
  'window': instance.window.toJson(),
  'courseCount': instance.courseCount,
  'kpis': instance.kpis.toJson(),
  'series': instance.series.toJson(),
  'quizzes': instance.quizzes.toJson(),
  'assignments': instance.assignments.toJson(),
  'engagement': instance.engagement.toJson(),
  'progressBands': instance.progressBands.map((e) => e.toJson()).toList(),
  'categories': instance.categories.map((e) => e.toJson()).toList(),
  'topCourses': instance.topCourses.map((e) => e.toJson()).toList(),
};

_CoursesReport _$CoursesReportFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CoursesReport', json, ($checkedConvert) {
      final val = _CoursesReport(
        window: $checkedConvert('window', (v) => ReportWindow.fromJson(v as Map<String, dynamic>)),
        courseCount: $checkedConvert('courseCount', (v) => (v as num?)?.toInt() ?? 0),
        rows: $checkedConvert(
          'rows',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CourseReportRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <CourseReportRow>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$CoursesReportToJson(_CoursesReport instance) => <String, dynamic>{
  'window': instance.window.toJson(),
  'courseCount': instance.courseCount,
  'rows': instance.rows.map((e) => e.toJson()).toList(),
};

_ChapterReach _$ChapterReachFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ChapterReach', json, ($checkedConvert) {
      final val = _ChapterReach(
        chapterId: $checkedConvert('chapterId', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        reached: $checkedConvert('reached', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$ChapterReachToJson(_ChapterReach instance) => <String, dynamic>{
  'chapterId': instance.chapterId,
  'title': instance.title,
  'reached': instance.reached,
};

_QuizReportRow _$QuizReportRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_QuizReportRow', json, ($checkedConvert) {
      final val = _QuizReportRow(
        quizId: $checkedConvert('quizId', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        attempts: $checkedConvert('attempts', (v) => (v as num?)?.toInt() ?? 0),
        passRate: $checkedConvert('passRate', (v) => (v as num?)?.toInt()),
        avgScore: $checkedConvert('avgScore', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$QuizReportRowToJson(_QuizReportRow instance) => <String, dynamic>{
  'quizId': instance.quizId,
  'title': instance.title,
  'attempts': instance.attempts,
  'passRate': instance.passRate,
  'avgScore': instance.avgScore,
};

_AssignmentReportRow _$AssignmentReportRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AssignmentReportRow', json, ($checkedConvert) {
      final val = _AssignmentReportRow(
        assignmentId: $checkedConvert('assignmentId', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        submitted: $checkedConvert('submitted', (v) => (v as num?)?.toInt() ?? 0),
        passRate: $checkedConvert('passRate', (v) => (v as num?)?.toInt()),
        avgScore: $checkedConvert('avgScore', (v) => (v as num?)?.toInt()),
        onTime: $checkedConvert('onTime', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$AssignmentReportRowToJson(_AssignmentReportRow instance) =>
    <String, dynamic>{
      'assignmentId': instance.assignmentId,
      'title': instance.title,
      'submitted': instance.submitted,
      'passRate': instance.passRate,
      'avgScore': instance.avgScore,
      'onTime': instance.onTime,
    };

_CourseReportKpis _$CourseReportKpisFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CourseReportKpis', json, ($checkedConvert) {
      final val = _CourseReportKpis(
        enrollments: $checkedConvert(
          'enrollments',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        completionRate: $checkedConvert(
          'completionRate',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        activeLearners: $checkedConvert(
          'activeLearners',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        avgProgress: $checkedConvert(
          'avgProgress',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CourseReportKpisToJson(_CourseReportKpis instance) => <String, dynamic>{
  'enrollments': instance.enrollments.toJson(),
  'completionRate': instance.completionRate.toJson(),
  'activeLearners': instance.activeLearners.toJson(),
  'avgProgress': instance.avgProgress.toJson(),
};

_CourseReport _$CourseReportFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CourseReport', json, ($checkedConvert) {
      final val = _CourseReport(
        window: $checkedConvert('window', (v) => ReportWindow.fromJson(v as Map<String, dynamic>)),
        courseCount: $checkedConvert('courseCount', (v) => (v as num?)?.toInt() ?? 0),
        row: $checkedConvert(
          'row',
          (v) => v == null
              ? const CourseReportRow()
              : CourseReportRow.fromJson(v as Map<String, dynamic>),
        ),
        kpis: $checkedConvert(
          'kpis',
          (v) => v == null
              ? const CourseReportKpis()
              : CourseReportKpis.fromJson(v as Map<String, dynamic>),
        ),
        series: $checkedConvert(
          'series',
          (v) =>
              v == null ? const ReportSeries() : ReportSeries.fromJson(v as Map<String, dynamic>),
        ),
        funnel: $checkedConvert(
          'funnel',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => LabelledCount.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <LabelledCount>[],
        ),
        chapters: $checkedConvert(
          'chapters',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => ChapterReach.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <ChapterReach>[],
        ),
        quizzes: $checkedConvert(
          'quizzes',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => QuizReportRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <QuizReportRow>[],
        ),
        assignments: $checkedConvert(
          'assignments',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => AssignmentReportRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <AssignmentReportRow>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$CourseReportToJson(_CourseReport instance) => <String, dynamic>{
  'window': instance.window.toJson(),
  'courseCount': instance.courseCount,
  'row': instance.row.toJson(),
  'kpis': instance.kpis.toJson(),
  'series': instance.series.toJson(),
  'funnel': instance.funnel.map((e) => e.toJson()).toList(),
  'chapters': instance.chapters.map((e) => e.toJson()).toList(),
  'quizzes': instance.quizzes.map((e) => e.toJson()).toList(),
  'assignments': instance.assignments.map((e) => e.toJson()).toList(),
};

_LearnerReportKpis _$LearnerReportKpisFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LearnerReportKpis', json, ($checkedConvert) {
      final val = _LearnerReportKpis(
        learners: $checkedConvert(
          'learners',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        active: $checkedConvert(
          'active',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        atRisk: $checkedConvert(
          'atRisk',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        avgProgress: $checkedConvert(
          'avgProgress',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LearnerReportKpisToJson(_LearnerReportKpis instance) => <String, dynamic>{
  'learners': instance.learners.toJson(),
  'active': instance.active.toJson(),
  'atRisk': instance.atRisk.toJson(),
  'avgProgress': instance.avgProgress.toJson(),
};

_LearnerReportRow _$LearnerReportRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LearnerReportRow', json, ($checkedConvert) {
      final val = _LearnerReportRow(
        studentId: $checkedConvert('studentId', (v) => v as String? ?? ''),
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        city: $checkedConvert('city', (v) => v as String? ?? ''),
        status: $checkedConvert('status', (v) => v as String? ?? ''),
        courses: $checkedConvert('courses', (v) => (v as num?)?.toInt() ?? 0),
        completed: $checkedConvert('completed', (v) => (v as num?)?.toInt() ?? 0),
        avgProgress: $checkedConvert('avgProgress', (v) => (v as num?)?.toInt()),
        assignmentAvg: $checkedConvert('assignmentAvg', (v) => (v as num?)?.toInt()),
        lastActiveAt: $checkedConvert(
          'lastActiveAt',
          (v) => const NullableUtcDateTimeConverter().fromJson(v as String?),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LearnerReportRowToJson(_LearnerReportRow instance) => <String, dynamic>{
  'studentId': instance.studentId,
  'name': instance.name,
  'city': instance.city,
  'status': instance.status,
  'courses': instance.courses,
  'completed': instance.completed,
  'avgProgress': instance.avgProgress,
  'assignmentAvg': instance.assignmentAvg,
  'lastActiveAt': const NullableUtcDateTimeConverter().toJson(instance.lastActiveAt),
};

_LearnersReport _$LearnersReportFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LearnersReport', json, ($checkedConvert) {
      final val = _LearnersReport(
        window: $checkedConvert('window', (v) => ReportWindow.fromJson(v as Map<String, dynamic>)),
        courseCount: $checkedConvert('courseCount', (v) => (v as num?)?.toInt() ?? 0),
        kpis: $checkedConvert(
          'kpis',
          (v) => v == null
              ? const LearnerReportKpis()
              : LearnerReportKpis.fromJson(v as Map<String, dynamic>),
        ),
        segments: $checkedConvert(
          'segments',
          (v) =>
              (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, (e as num).toInt())) ??
              const <String, int>{},
        ),
        statuses: $checkedConvert(
          'statuses',
          (v) =>
              (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, (e as num).toInt())) ??
              const <String, int>{},
        ),
        progressBands: $checkedConvert(
          'progressBands',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => LabelledCount.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <LabelledCount>[],
        ),
        rows: $checkedConvert(
          'rows',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => LearnerReportRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <LearnerReportRow>[],
        ),
        total: $checkedConvert('total', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$LearnersReportToJson(_LearnersReport instance) => <String, dynamic>{
  'window': instance.window.toJson(),
  'courseCount': instance.courseCount,
  'kpis': instance.kpis.toJson(),
  'segments': instance.segments,
  'statuses': instance.statuses,
  'progressBands': instance.progressBands.map((e) => e.toJson()).toList(),
  'rows': instance.rows.map((e) => e.toJson()).toList(),
  'total': instance.total,
};

_EnrolmentSourceRow _$EnrolmentSourceRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_EnrolmentSourceRow', json, ($checkedConvert) {
      final val = _EnrolmentSourceRow(
        source: $checkedConvert('source', (v) => v as String? ?? ''),
        enrollments: $checkedConvert('enrollments', (v) => (v as num?)?.toInt() ?? 0),
        share: $checkedConvert('share', (v) => (v as num?)?.toInt()),
        completionRate: $checkedConvert('completionRate', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$EnrolmentSourceRowToJson(_EnrolmentSourceRow instance) => <String, dynamic>{
  'source': instance.source,
  'enrollments': instance.enrollments,
  'share': instance.share,
  'completionRate': instance.completionRate,
};

_CohortRow _$CohortRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CohortRow', json, ($checkedConvert) {
      final val = _CohortRow(
        month: $checkedConvert('month', (v) => v as String? ?? ''),
        enrolled: $checkedConvert('enrolled', (v) => (v as num?)?.toInt() ?? 0),
        within30: $checkedConvert('within30', (v) => (v as num?)?.toInt()),
        within60: $checkedConvert('within60', (v) => (v as num?)?.toInt()),
        within90: $checkedConvert('within90', (v) => (v as num?)?.toInt()),
        toDate: $checkedConvert('toDate', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$CohortRowToJson(_CohortRow instance) => <String, dynamic>{
  'month': instance.month,
  'enrolled': instance.enrolled,
  'within30': instance.within30,
  'within60': instance.within60,
  'within90': instance.within90,
  'toDate': instance.toDate,
};

_EnrolmentKpis _$EnrolmentKpisFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_EnrolmentKpis', json, ($checkedConvert) {
      final val = _EnrolmentKpis(
        enrollments: $checkedConvert(
          'enrollments',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        completions: $checkedConvert(
          'completions',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        completionRate: $checkedConvert(
          'completionRate',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        selfShare: $checkedConvert(
          'selfShare',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$EnrolmentKpisToJson(_EnrolmentKpis instance) => <String, dynamic>{
  'enrollments': instance.enrollments.toJson(),
  'completions': instance.completions.toJson(),
  'completionRate': instance.completionRate.toJson(),
  'selfShare': instance.selfShare.toJson(),
};

_EnrolmentsReport _$EnrolmentsReportFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_EnrolmentsReport', json, ($checkedConvert) {
      final val = _EnrolmentsReport(
        window: $checkedConvert('window', (v) => ReportWindow.fromJson(v as Map<String, dynamic>)),
        courseCount: $checkedConvert('courseCount', (v) => (v as num?)?.toInt() ?? 0),
        kpis: $checkedConvert(
          'kpis',
          (v) =>
              v == null ? const EnrolmentKpis() : EnrolmentKpis.fromJson(v as Map<String, dynamic>),
        ),
        series: $checkedConvert(
          'series',
          (v) =>
              v == null ? const ReportSeries() : ReportSeries.fromJson(v as Map<String, dynamic>),
        ),
        sources: $checkedConvert(
          'sources',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => EnrolmentSourceRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <EnrolmentSourceRow>[],
        ),
        categories: $checkedConvert(
          'categories',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CategoryReportRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <CategoryReportRow>[],
        ),
        cohorts: $checkedConvert(
          'cohorts',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => CohortRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <CohortRow>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$EnrolmentsReportToJson(_EnrolmentsReport instance) => <String, dynamic>{
  'window': instance.window.toJson(),
  'courseCount': instance.courseCount,
  'kpis': instance.kpis.toJson(),
  'series': instance.series.toJson(),
  'sources': instance.sources.map((e) => e.toJson()).toList(),
  'categories': instance.categories.map((e) => e.toJson()).toList(),
  'cohorts': instance.cohorts.map((e) => e.toJson()).toList(),
};

_InstructorReportRow _$InstructorReportRowFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_InstructorReportRow', json, ($checkedConvert) {
      final val = _InstructorReportRow(
        instructorId: $checkedConvert('instructorId', (v) => v as String? ?? ''),
        name: $checkedConvert('name', (v) => v as String? ?? ''),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        courses: $checkedConvert('courses', (v) => (v as num?)?.toInt() ?? 0),
        learners: $checkedConvert('learners', (v) => (v as num?)?.toInt() ?? 0),
        completionRate: $checkedConvert('completionRate', (v) => (v as num?)?.toInt()),
        rating: $checkedConvert('rating', (v) => (v as num?)?.toDouble()),
        reviews: $checkedConvert('reviews', (v) => (v as num?)?.toInt() ?? 0),
        reviewHours: $checkedConvert('reviewHours', (v) => (v as num?)?.toInt()),
        onTime: $checkedConvert('onTime', (v) => (v as num?)?.toInt()),
        liveClasses: $checkedConvert('liveClasses', (v) => (v as num?)?.toInt() ?? 0),
        attendance: $checkedConvert('attendance', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$InstructorReportRowToJson(_InstructorReportRow instance) =>
    <String, dynamic>{
      'instructorId': instance.instructorId,
      'name': instance.name,
      'title': instance.title,
      'courses': instance.courses,
      'learners': instance.learners,
      'completionRate': instance.completionRate,
      'rating': instance.rating,
      'reviews': instance.reviews,
      'reviewHours': instance.reviewHours,
      'onTime': instance.onTime,
      'liveClasses': instance.liveClasses,
      'attendance': instance.attendance,
    };

_InstructorReportFigures _$InstructorReportFiguresFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_InstructorReportFigures', json, ($checkedConvert) {
      final val = _InstructorReportFigures(
        reviews: $checkedConvert(
          'reviews',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        reviewHours: $checkedConvert(
          'reviewHours',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        onTime: $checkedConvert(
          'onTime',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        attendance: $checkedConvert(
          'attendance',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$InstructorReportFiguresToJson(_InstructorReportFigures instance) =>
    <String, dynamic>{
      'reviews': instance.reviews.toJson(),
      'reviewHours': instance.reviewHours.toJson(),
      'onTime': instance.onTime.toJson(),
      'attendance': instance.attendance.toJson(),
    };

_InstructorsReport _$InstructorsReportFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_InstructorsReport', json, ($checkedConvert) {
      final val = _InstructorsReport(
        window: $checkedConvert('window', (v) => ReportWindow.fromJson(v as Map<String, dynamic>)),
        courseCount: $checkedConvert('courseCount', (v) => (v as num?)?.toInt() ?? 0),
        rows: $checkedConvert(
          'rows',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => InstructorReportRow.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const <InstructorReportRow>[],
        ),
        figures: $checkedConvert(
          'figures',
          (v) => v == null
              ? const InstructorReportFigures()
              : InstructorReportFigures.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$InstructorsReportToJson(_InstructorsReport instance) => <String, dynamic>{
  'window': instance.window.toJson(),
  'courseCount': instance.courseCount,
  'rows': instance.rows.map((e) => e.toJson()).toList(),
  'figures': instance.figures.toJson(),
};
