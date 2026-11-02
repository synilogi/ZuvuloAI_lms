import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';
import '../../../../shared/domain/dashboard.dart';

part 'report.freezed.dart';
part 'report.g.dart';

/// `apps/api/src/routes/reports.ts`, `lib/reports.ts` and `packages/domain/src/reports.ts` — the
/// academy's own analytics. **Every figure here is the route's arithmetic.** The app formats, ranks
/// and draws them; it never recomputes one, because a second definition of "completion rate" is a
/// second answer (§18, LMS-015).

/// `ReportRange` — the period a report covers.
enum ReportRange {
  @JsonValue('30d')
  thirtyDays,
  @JsonValue('90d')
  ninetyDays,
  @JsonValue('6m')
  sixMonths,
  @JsonValue('12m')
  twelveMonths,
}

/// The word the route knows each range by.
extension ReportRangeWire on ReportRange {
  String get wireName => switch (this) {
    ReportRange.thirtyDays => '30d',
    ReportRange.ninetyDays => '90d',
    ReportRange.sixMonths => '6m',
    ReportRange.twelveMonths => '12m',
  };
}

/// `LearnerSegment` — which learners a report counts. `new` is a reserved word in Dart, so the
/// constant is named for what it means and carries the route's own word.
enum LearnerSegment {
  all,
  @JsonValue('new')
  newcomers,
  active,
  @JsonValue('at-risk')
  atRisk,
  inactive,
  completers,
  unknown,
}

extension LearnerSegmentWire on LearnerSegment {
  String get wireName => switch (this) {
    LearnerSegment.all => 'all',
    LearnerSegment.newcomers => 'new',
    LearnerSegment.active => 'active',
    LearnerSegment.atRisk => 'at-risk',
    LearnerSegment.inactive => 'inactive',
    LearnerSegment.completers => 'completers',
    LearnerSegment.unknown => 'all',
  };
}

/// How a learner table may be ordered, in the route's own words.
enum LearnerSortKey {
  name,
  courses,
  progress,
  assignments,
  @JsonValue('lastActive')
  lastActive,
}

extension LearnerSortKeyWire on LearnerSortKey {
  String get wireName => this == LearnerSortKey.lastActive ? 'lastActive' : name;
}

/// The period a report covers, and the equal one before it that every `previous` is measured over.
@freezed
abstract class ReportWindow with _$ReportWindow {
  const factory ReportWindow({
    @UtcDateTimeConverter() required DateTime from,
    @UtcDateTimeConverter() required DateTime to,
    @UtcDateTimeConverter() required DateTime previousFrom,
    @UtcDateTimeConverter() required DateTime previousTo,
  }) = _ReportWindow;

  factory ReportWindow.fromJson(Map<String, dynamic> json) => _$ReportWindowFromJson(json);
}

/// One bucket of a series: what the route measured, and over which stretch of time.
@freezed
abstract class ReportSeriesPoint with _$ReportSeriesPoint {
  const factory ReportSeriesPoint({
    @UtcDateTimeConverter() required DateTime from,
    @UtcDateTimeConverter() required DateTime to,
    @Default(0) num value,
  }) = _ReportSeriesPoint;

  factory ReportSeriesPoint.fromJson(Map<String, dynamic> json) =>
      _$ReportSeriesPointFromJson(json);
}

/// A labelled count — a progress band, a funnel step. The label is the academy's own.
@freezed
abstract class LabelledCount with _$LabelledCount {
  const factory LabelledCount({@Default('') String label, @Default(0) num value}) = _LabelledCount;

  factory LabelledCount.fromJson(Map<String, dynamic> json) => _$LabelledCountFromJson(json);
}

/// The three series every trend tab carries.
@freezed
abstract class ReportSeries with _$ReportSeries {
  const factory ReportSeries({
    @Default(<ReportSeriesPoint>[]) List<ReportSeriesPoint> enrollments,
    @Default(<ReportSeriesPoint>[]) List<ReportSeriesPoint> completions,
    @Default(<ReportSeriesPoint>[]) List<ReportSeriesPoint> activeLearners,
  }) = _ReportSeries;

  factory ReportSeries.fromJson(Map<String, dynamic> json) => _$ReportSeriesFromJson(json);
}

/// How one course is doing over the period. `rating` is sent only for a published course the academy
/// publishes ratings for; each rate is `null` when there was nothing to divide by.
@freezed
abstract class CourseReportRow with _$CourseReportRow {
  const factory CourseReportRow({
    @Default('') String courseId,
    @Default('') String title,
    @Default('') String categoryTitle,
    @Default(<String>[]) List<String> instructorNames,
    @Default('') String status,
    @Default(0) int enrollments,
    @Default(0) int previousEnrollments,
    @Default(0) int completions,
    int? completionRate,
    @Default(0) int activeLearners,
    int? avgProgress,
    int? quizPassRate,
    int? assignmentPassRate,
    double? rating,
    @Default(<num>[]) List<num> trend,
  }) = _CourseReportRow;

  const CourseReportRow._();

  factory CourseReportRow.fromJson(Map<String, dynamic> json) => _$CourseReportRowFromJson(json);

  /// How enrolments moved against the period before, as the route's own two counts.
  int get enrollmentChange => enrollments - previousEnrollments;
}

/// How a category is doing. `previousEnrollments` is sent by the enrolments tab only.
@freezed
abstract class CategoryReportRow with _$CategoryReportRow {
  const factory CategoryReportRow({
    @Default('') String categoryId,
    @Default('') String title,
    @Default(0) int enrollments,
    int? previousEnrollments,
    int? completionRate,
  }) = _CategoryReportRow;

  factory CategoryReportRow.fromJson(Map<String, dynamic> json) =>
      _$CategoryReportRowFromJson(json);
}

/// The headline figures of the overview.
@freezed
abstract class OverviewKpis with _$OverviewKpis {
  const factory OverviewKpis({
    @Default(Kpi()) Kpi enrollments,
    @Default(Kpi()) Kpi completions,
    @Default(Kpi()) Kpi completionRate,
    @Default(Kpi()) Kpi activeLearners,
    @Default(Kpi()) Kpi avgProgress,
  }) = _OverviewKpis;

  factory OverviewKpis.fromJson(Map<String, dynamic> json) => _$OverviewKpisFromJson(json);
}

@freezed
abstract class QuizFigures with _$QuizFigures {
  const factory QuizFigures({
    @Default(Kpi()) Kpi attempts,
    @Default(Kpi()) Kpi passRate,
    @Default(Kpi()) Kpi avgScore,
  }) = _QuizFigures;

  factory QuizFigures.fromJson(Map<String, dynamic> json) => _$QuizFiguresFromJson(json);
}

@freezed
abstract class AssignmentFigures with _$AssignmentFigures {
  const factory AssignmentFigures({
    @Default(Kpi()) Kpi submitted,
    @Default(Kpi()) Kpi passRate,
    @Default(Kpi()) Kpi onTime,
    @Default(Kpi()) Kpi reviewHours,
  }) = _AssignmentFigures;

  factory AssignmentFigures.fromJson(Map<String, dynamic> json) =>
      _$AssignmentFiguresFromJson(json);
}

@freezed
abstract class EngagementFigures with _$EngagementFigures {
  const factory EngagementFigures({
    @Default(Kpi()) Kpi lessonsCompleted,
    @Default(Kpi()) Kpi lessonsPerLearner,
    @Default(Kpi()) Kpi liveAttendance,
  }) = _EngagementFigures;

  factory EngagementFigures.fromJson(Map<String, dynamic> json) =>
      _$EngagementFiguresFromJson(json);
}

/// `GET /reports/overview`.
@freezed
abstract class OverviewReport with _$OverviewReport {
  const factory OverviewReport({
    required ReportWindow window,
    @Default(0) int courseCount,
    @Default(OverviewKpis()) OverviewKpis kpis,
    @Default(ReportSeries()) ReportSeries series,
    @Default(QuizFigures()) QuizFigures quizzes,
    @Default(AssignmentFigures()) AssignmentFigures assignments,
    @Default(EngagementFigures()) EngagementFigures engagement,
    @Default(<LabelledCount>[]) List<LabelledCount> progressBands,
    @Default(<CategoryReportRow>[]) List<CategoryReportRow> categories,
    @Default(<CourseReportRow>[]) List<CourseReportRow> topCourses,
  }) = _OverviewReport;

  factory OverviewReport.fromJson(Map<String, dynamic> json) => _$OverviewReportFromJson(json);
}

/// `GET /reports/courses`.
@freezed
abstract class CoursesReport with _$CoursesReport {
  const factory CoursesReport({
    required ReportWindow window,
    @Default(0) int courseCount,
    @Default(<CourseReportRow>[]) List<CourseReportRow> rows,
  }) = _CoursesReport;

  factory CoursesReport.fromJson(Map<String, dynamic> json) => _$CoursesReportFromJson(json);
}

/// How far learners get through a course's chapters, as a percentage who reached each.
@freezed
abstract class ChapterReach with _$ChapterReach {
  const factory ChapterReach({
    @Default('') String chapterId,
    @Default('') String title,
    int? reached,
  }) = _ChapterReach;

  factory ChapterReach.fromJson(Map<String, dynamic> json) => _$ChapterReachFromJson(json);
}

@freezed
abstract class QuizReportRow with _$QuizReportRow {
  const factory QuizReportRow({
    @Default('') String quizId,
    @Default('') String title,
    @Default(0) int attempts,
    int? passRate,
    int? avgScore,
  }) = _QuizReportRow;

  factory QuizReportRow.fromJson(Map<String, dynamic> json) => _$QuizReportRowFromJson(json);
}

@freezed
abstract class AssignmentReportRow with _$AssignmentReportRow {
  const factory AssignmentReportRow({
    @Default('') String assignmentId,
    @Default('') String title,
    @Default(0) int submitted,
    int? passRate,
    int? avgScore,
    int? onTime,
  }) = _AssignmentReportRow;

  factory AssignmentReportRow.fromJson(Map<String, dynamic> json) =>
      _$AssignmentReportRowFromJson(json);
}

@freezed
abstract class CourseReportKpis with _$CourseReportKpis {
  const factory CourseReportKpis({
    @Default(Kpi()) Kpi enrollments,
    @Default(Kpi()) Kpi completionRate,
    @Default(Kpi()) Kpi activeLearners,
    @Default(Kpi()) Kpi avgProgress,
  }) = _CourseReportKpis;

  factory CourseReportKpis.fromJson(Map<String, dynamic> json) => _$CourseReportKpisFromJson(json);
}

/// `GET /reports/courses/:courseId` — 404 for a course the caller may not see, and for a draft.
@freezed
abstract class CourseReport with _$CourseReport {
  const factory CourseReport({
    required ReportWindow window,
    @Default(0) int courseCount,
    @Default(CourseReportRow()) CourseReportRow row,
    @Default(CourseReportKpis()) CourseReportKpis kpis,
    @Default(ReportSeries()) ReportSeries series,
    @Default(<LabelledCount>[]) List<LabelledCount> funnel,
    @Default(<ChapterReach>[]) List<ChapterReach> chapters,
    @Default(<QuizReportRow>[]) List<QuizReportRow> quizzes,
    @Default(<AssignmentReportRow>[]) List<AssignmentReportRow> assignments,
  }) = _CourseReport;

  factory CourseReport.fromJson(Map<String, dynamic> json) => _$CourseReportFromJson(json);
}

@freezed
abstract class LearnerReportKpis with _$LearnerReportKpis {
  const factory LearnerReportKpis({
    @Default(Kpi()) Kpi learners,
    @Default(Kpi()) Kpi active,
    @JsonKey(name: 'atRisk') @Default(Kpi()) Kpi atRisk,
    @Default(Kpi()) Kpi avgProgress,
  }) = _LearnerReportKpis;

  factory LearnerReportKpis.fromJson(Map<String, dynamic> json) =>
      _$LearnerReportKpisFromJson(json);
}

/// One learner in the table. Each figure is the route's; `assignmentAvg` and `lastActiveAt` are
/// absent for someone who has handed nothing in or never been seen.
@freezed
abstract class LearnerReportRow with _$LearnerReportRow {
  const factory LearnerReportRow({
    @Default('') String studentId,
    @Default('') String name,
    @Default('') String city,
    @Default('') String status,
    @Default(0) int courses,
    @Default(0) int completed,
    int? avgProgress,
    int? assignmentAvg,
    @NullableUtcDateTimeConverter() DateTime? lastActiveAt,
  }) = _LearnerReportRow;

  factory LearnerReportRow.fromJson(Map<String, dynamic> json) => _$LearnerReportRowFromJson(json);
}

/// `GET /reports/learners`. `segments` and `statuses` arrive keyed by the academy's own words —
/// `at-risk` among them — so they are read as maps rather than renamed into Dart identifiers.
@freezed
abstract class LearnersReport with _$LearnersReport {
  const factory LearnersReport({
    required ReportWindow window,
    @Default(0) int courseCount,
    @Default(LearnerReportKpis()) LearnerReportKpis kpis,
    @Default(<String, int>{}) Map<String, int> segments,
    @Default(<String, int>{}) Map<String, int> statuses,
    @Default(<LabelledCount>[]) List<LabelledCount> progressBands,
    @Default(<LearnerReportRow>[]) List<LearnerReportRow> rows,
    @Default(0) int total,
  }) = _LearnersReport;

  const LearnersReport._();

  factory LearnersReport.fromJson(Map<String, dynamic> json) => _$LearnersReportFromJson(json);

  /// How many learners fall in one segment, as the academy counted them.
  int countOf(LearnerSegment segment) => segments[segment.wireName] ?? 0;

  /// How many learners hold one status.
  int statusCount(String status) => statuses[status] ?? 0;
}

/// Where enrolments came from, and how they did.
@freezed
abstract class EnrolmentSourceRow with _$EnrolmentSourceRow {
  const factory EnrolmentSourceRow({
    @Default('') String source,
    @Default(0) int enrollments,
    int? share,
    int? completionRate,
  }) = _EnrolmentSourceRow;

  factory EnrolmentSourceRow.fromJson(Map<String, dynamic> json) =>
      _$EnrolmentSourceRowFromJson(json);
}

/// One month's intake and how much of it has finished — `null` where the window has not run long
/// enough for that milestone to mean anything yet.
@freezed
abstract class CohortRow with _$CohortRow {
  const factory CohortRow({
    @Default('') String month,
    @Default(0) int enrolled,
    int? within30,
    int? within60,
    int? within90,
    int? toDate,
  }) = _CohortRow;

  factory CohortRow.fromJson(Map<String, dynamic> json) => _$CohortRowFromJson(json);
}

@freezed
abstract class EnrolmentKpis with _$EnrolmentKpis {
  const factory EnrolmentKpis({
    @Default(Kpi()) Kpi enrollments,
    @Default(Kpi()) Kpi completions,
    @Default(Kpi()) Kpi completionRate,
    @Default(Kpi()) Kpi selfShare,
  }) = _EnrolmentKpis;

  factory EnrolmentKpis.fromJson(Map<String, dynamic> json) => _$EnrolmentKpisFromJson(json);
}

/// `GET /reports/enrolments`.
@freezed
abstract class EnrolmentsReport with _$EnrolmentsReport {
  const factory EnrolmentsReport({
    required ReportWindow window,
    @Default(0) int courseCount,
    @Default(EnrolmentKpis()) EnrolmentKpis kpis,
    @Default(ReportSeries()) ReportSeries series,
    @Default(<EnrolmentSourceRow>[]) List<EnrolmentSourceRow> sources,
    @Default(<CategoryReportRow>[]) List<CategoryReportRow> categories,
    @Default(<CohortRow>[]) List<CohortRow> cohorts,
  }) = _EnrolmentsReport;

  factory EnrolmentsReport.fromJson(Map<String, dynamic> json) => _$EnrolmentsReportFromJson(json);
}

/// How one instructor is doing over the period.
@freezed
abstract class InstructorReportRow with _$InstructorReportRow {
  const factory InstructorReportRow({
    @Default('') String instructorId,
    @Default('') String name,
    @Default('') String title,
    @Default(0) int courses,
    @Default(0) int learners,
    int? completionRate,
    double? rating,
    @Default(0) int reviews,
    int? reviewHours,
    int? onTime,
    @Default(0) int liveClasses,
    int? attendance,
  }) = _InstructorReportRow;

  factory InstructorReportRow.fromJson(Map<String, dynamic> json) =>
      _$InstructorReportRowFromJson(json);
}

@freezed
abstract class InstructorReportFigures with _$InstructorReportFigures {
  const factory InstructorReportFigures({
    @Default(Kpi()) Kpi reviews,
    @Default(Kpi()) Kpi reviewHours,
    @Default(Kpi()) Kpi onTime,
    @Default(Kpi()) Kpi attendance,
  }) = _InstructorReportFigures;

  factory InstructorReportFigures.fromJson(Map<String, dynamic> json) =>
      _$InstructorReportFiguresFromJson(json);
}

/// `GET /reports/instructors` — an admin's, with `reports.instructors.view` and the
/// `reports.advanced` feature. Everyone else is refused, and the app says what the refusal was.
@freezed
abstract class InstructorsReport with _$InstructorsReport {
  const factory InstructorsReport({
    required ReportWindow window,
    @Default(0) int courseCount,
    @Default(<InstructorReportRow>[]) List<InstructorReportRow> rows,
    @Default(InstructorReportFigures()) InstructorReportFigures figures,
  }) = _InstructorsReport;

  factory InstructorsReport.fromJson(Map<String, dynamic> json) =>
      _$InstructorsReportFromJson(json);
}
