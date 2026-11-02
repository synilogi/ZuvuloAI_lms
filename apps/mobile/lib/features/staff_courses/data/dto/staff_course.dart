import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';
import '../../../../shared/domain/course.dart';
import '../../../../shared/domain/dashboard.dart';

part 'staff_course.freezed.dart';
part 'staff_course.g.dart';

/// `GET /courses` — the academy's own courses, with the counts the status tabs read. An instructor
/// is served only what they teach: the token decides, never the query (§7).
@freezed
abstract class StaffCoursePage with _$StaffCoursePage {
  const factory StaffCoursePage({
    @Default(<Course>[]) List<Course> rows,
    @Default(0) int total,
    @Default(<String, int>{}) Map<String, int> counts,
  }) = _StaffCoursePage;

  const StaffCoursePage._();

  factory StaffCoursePage.fromJson(Map<String, dynamic> json) => _$StaffCoursePageFromJson(json);

  int countOf(String status) => counts[status] ?? 0;

  bool get isEmpty => rows.isEmpty;
}

/// One of the eight learners who enrolled most recently, as `GET /courses/:id/stats` lists them.
@freezed
abstract class CourseLearnerRow with _$CourseLearnerRow {
  const factory CourseLearnerRow({
    @Default('') String studentId,
    @Default('') String name,
    @Default(0) num progress,
    @NullableUtcDateTimeConverter() DateTime? enrolledAt,
    String? status,
  }) = _CourseLearnerRow;

  factory CourseLearnerRow.fromJson(Map<String, dynamic> json) => _$CourseLearnerRowFromJson(json);
}

/// One fifth of the progress range and how many learners sit in it (`0-20%` … `80-100%`). The
/// label is the server's own; the app does not name the bands.
@freezed
abstract class ProgressBucket with _$ProgressBucket {
  const factory ProgressBucket({@Default('') String label, @Default(0) num value}) =
      _ProgressBucket;

  factory ProgressBucket.fromJson(Map<String, dynamic> json) => _$ProgressBucketFromJson(json);
}

/// `GET /courses/:id/stats` — how one course is doing, counted by the academy.
@freezed
abstract class CourseStats with _$CourseStats {
  const factory CourseStats({
    @Default('') String courseId,
    @Default(0) int enrolled,

    /// Learners who opened it in the last 14 days.
    @Default(0) int active,
    @Default(0) num completionRate,
    @Default(0) num avgProgress,

    /// Weekly new enrolments, twelve weeks, oldest → newest.
    @Default(<TrendPoint>[]) List<TrendPoint> weekly,

    /// How many learners sit in each fifth of the progress range.
    @Default(<ProgressBucket>[]) List<ProgressBucket> progressBuckets,
    @Default(<CourseLearnerRow>[]) List<CourseLearnerRow> recent,

    /// How many live classes are still to come — a count, not a list.
    @Default(0) int upcomingLive,
    @Default(0) int certificatesIssued,
    @Default(0) int reviewsWaiting,

    /// Every lesson's minutes, summed by the server.
    @Default(0) int totalMinutes,
  }) = _CourseStats;

  factory CourseStats.fromJson(Map<String, dynamic> json) => _$CourseStatsFromJson(json);
}

/// `GET /courses/:courseId/chapters/stats` — how far the enrolled learners have got, per chapter
/// and per lesson. Every figure is the academy's.
@freezed
abstract class CurriculumStats with _$CurriculumStats {
  const factory CurriculumStats({
    @Default(0) int enrolled,
    @Default(<String, ChapterProgressStat>{}) Map<String, ChapterProgressStat> chapters,

    /// Percent of enrolled learners who have completed each lesson, by lesson id.
    @Default(<String, num>{}) Map<String, num> lessons,
  }) = _CurriculumStats;

  const CurriculumStats._();

  factory CurriculumStats.fromJson(Map<String, dynamic> json) => _$CurriculumStatsFromJson(json);

  num lessonPercent(String lessonId) => lessons[lessonId] ?? 0;
}

@freezed
abstract class ChapterProgressStat with _$ChapterProgressStat {
  const factory ChapterProgressStat({@Default(0) num completionRate, @Default(0) num startedRate}) =
      _ChapterProgressStat;

  factory ChapterProgressStat.fromJson(Map<String, dynamic> json) =>
      _$ChapterProgressStatFromJson(json);
}

/// One row of `GET /courses/:courseId/lessons` — the lesson and where it sits.
@freezed
abstract class StaffLessonRow with _$StaffLessonRow {
  const factory StaffLessonRow({
    required Lesson lesson,
    @Default('') String chapterId,
    @Default('') String chapterTitle,
    @Default(0) int chapterIndex,
    @Default(0) int lessonIndex,
  }) = _StaffLessonRow;

  factory StaffLessonRow.fromJson(Map<String, dynamic> json) => _$StaffLessonRowFromJson(json);
}

/// `GET /courses/:courseId/lessons`.
@freezed
abstract class StaffLessonPage with _$StaffLessonPage {
  const factory StaffLessonPage({
    @Default(<StaffLessonRow>[]) List<StaffLessonRow> rows,
    @Default(<String, dynamic>{}) Map<String, dynamic> counts,
  }) = _StaffLessonPage;

  factory StaffLessonPage.fromJson(Map<String, dynamic> json) => _$StaffLessonPageFromJson(json);
}

/// One line of the academy's publish checklist (`publishChecklist`), as a refused publish sends
/// it: `{id, label, met}` — not the `{field, message}` most refusals carry (finding 23).
@immutable
class PublishCheck {
  const PublishCheck({required this.id, required this.label, required this.met});

  factory PublishCheck.fromJson(Map<String, Object?> json) => PublishCheck(
    id: '${json['id'] ?? ''}',
    label: '${json['label'] ?? ''}',
    met: json['met'] == true,
  );

  final String id;
  final String label;
  final bool met;

  @override
  bool operator ==(Object other) =>
      other is PublishCheck && other.id == id && other.label == label && other.met == met;

  @override
  int get hashCode => Object.hash(id, label, met);
}

/// The checklist inside a refused publish, or an empty list when the refusal was something else.
List<PublishCheck> publishChecklistOf(List<Object?> rawIssues) => [
  for (final issue in rawIssues)
    if (issue is Map && issue['id'] != null && issue['label'] != null)
      PublishCheck.fromJson(issue.cast<String, Object?>()),
];

/// Where a lesson sits next to this one, as the lesson route sends it.
@freezed
abstract class LessonLink with _$LessonLink {
  const factory LessonLink({required String id, required String title}) = _LessonLink;

  factory LessonLink.fromJson(Map<String, dynamic> json) => _$LessonLinkFromJson(json);
}

/// `GET /courses/:courseId/lessons/:lessonId` — one lesson, its chapter and its neighbours. The
/// route strips a quiz's and an assignment's ids from the mirrored content, so the staff view
/// shows what the lesson delivers, never the answer key (`lessons.ts`).
@freezed
abstract class StaffLessonDetail with _$StaffLessonDetail {
  const factory StaffLessonDetail({
    required Lesson lesson,
    @Default('') String chapterId,
    @Default('') String chapterTitle,
    @Default(0) int chapterIndex,
    @Default(0) int lessonIndex,
    Chapter? chapter,
    LessonLink? previous,
    LessonLink? next,
  }) = _StaffLessonDetail;

  factory StaffLessonDetail.fromJson(Map<String, dynamic> json) =>
      _$StaffLessonDetailFromJson(json);
}

/// One row of `GET /categories` — the category and how much of the catalogue sits in it.
@freezed
abstract class StaffCategoryRow with _$StaffCategoryRow {
  const factory StaffCategoryRow({
    required CourseCategory category,
    @Default(0) int courseCount,
    @Default(0) int publishedCount,
    @Default(0) int learnerCount,
  }) = _StaffCategoryRow;

  factory StaffCategoryRow.fromJson(Map<String, dynamic> json) => _$StaffCategoryRowFromJson(json);
}

/// `GET /categories` — what the list's category filter offers.
@freezed
abstract class StaffCategoryPage with _$StaffCategoryPage {
  const factory StaffCategoryPage({@Default(<StaffCategoryRow>[]) List<StaffCategoryRow> rows}) =
      _StaffCategoryPage;

  factory StaffCategoryPage.fromJson(Map<String, dynamic> json) =>
      _$StaffCategoryPageFromJson(json);
}
