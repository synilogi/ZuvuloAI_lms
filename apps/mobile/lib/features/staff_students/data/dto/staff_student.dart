import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';
import '../../../../shared/domain/activity.dart';
import '../../../../shared/domain/assignment.dart';
import '../../../../shared/domain/people.dart';
import '../../../../shared/domain/rank.dart';

part 'staff_student.freezed.dart';
part 'staff_student.g.dart';

/// One course a learner is on, as the roster row lists it.
@freezed
abstract class RosterCourse with _$RosterCourse {
  const factory RosterCourse({
    @Default('') String id,
    @Default('') String title,
    @Default(0) num progress,
    @JsonKey(unknownEnumValue: EnrollmentStatus.unknown)
    @Default(EnrollmentStatus.active)
    EnrollmentStatus status,
  }) = _RosterCourse;

  factory RosterCourse.fromJson(Map<String, dynamic> json) => _$RosterCourseFromJson(json);
}

/// One row of `GET /students` — the learner, the status the academy derived, their courses, and
/// their progress across the ones still open.
@freezed
abstract class RosterRow with _$RosterRow {
  const factory RosterRow({
    @Default(Student()) Student student,
    @JsonKey(unknownEnumValue: StudentStatus.unknown)
    @Default(StudentStatus.unknown)
    StudentStatus status,
    @Default(<RosterCourse>[]) List<RosterCourse> courses,
    @Default(0) num progress,
  }) = _RosterRow;

  factory RosterRow.fromJson(Map<String, dynamic> json) => _$RosterRowFromJson(json);
}

/// `GET /students`.
@freezed
abstract class RosterPage with _$RosterPage {
  const factory RosterPage({
    @Default(<RosterRow>[]) List<RosterRow> rows,
    @Default(0) int total,
    @Default(<String, int>{}) Map<String, int> counts,
  }) = _RosterPage;

  const RosterPage._();

  factory RosterPage.fromJson(Map<String, dynamic> json) => _$RosterPageFromJson(json);

  int countOf(String status) => counts[status] ?? 0;

  bool get isEmpty => rows.isEmpty;
}

/// How far through one course's chapters a learner is.
@freezed
abstract class ChapterProgress with _$ChapterProgress {
  const factory ChapterProgress({
    @Default('') String id,
    @Default('') String title,
    @Default(0) num percent,
    @Default(0) int completed,
    @Default(0) int total,
  }) = _ChapterProgress;

  factory ChapterProgress.fromJson(Map<String, dynamic> json) => _$ChapterProgressFromJson(json);
}

/// One of the learner's enrolments on their profile, with how much of the curriculum they have done
/// and where they left off.
@freezed
abstract class StudentEnrollment with _$StudentEnrollment {
  const factory StudentEnrollment({
    @Default(Enrollment()) Enrollment enrollment,
    @Default('') String courseTitle,
    @Default('') String levelTitle,
    String? categoryId,
    @Default(<String>[]) List<String> instructorNames,
    @Default(DonePair()) DonePair chapters,
    @Default(DonePair()) DonePair lessons,

    /// Where they are up to; absent once the course is finished.
    String? lastLessonTitle,
    String? certificateTitle,
  }) = _StudentEnrollment;

  factory StudentEnrollment.fromJson(Map<String, dynamic> json) =>
      _$StudentEnrollmentFromJson(json);
}

/// How many of something is done, out of how many there are.
@freezed
abstract class DonePair with _$DonePair {
  const factory DonePair({@Default(0) int done, @Default(0) int total}) = _DonePair;

  const DonePair._();

  factory DonePair.fromJson(Map<String, dynamic> json) => _$DonePairFromJson(json);

  bool get isComplete => total > 0 && done >= total;
}

/// The figures on a learner's profile, all counted by the academy. `avgScore` is null when nothing
/// of theirs has been marked.
@freezed
abstract class StudentSummary with _$StudentSummary {
  const factory StudentSummary({
    @Default(0) int enrolled,
    @Default(0) int active,
    @Default(0) int completed,
    @Default(0) num avgProgress,
    @Default(0) int studyMinutes,
    @Default(0) int submissions,
    num? avgScore,
  }) = _StudentSummary;

  factory StudentSummary.fromJson(Map<String, dynamic> json) => _$StudentSummaryFromJson(json);
}

/// A certificate the learner holds, as their profile lists it.
@freezed
abstract class StudentCertificate with _$StudentCertificate {
  const factory StudentCertificate({
    @Default('') String id,
    @Default('') String courseId,
    @Default('') String courseTitle,
    @Default('') String title,
    @NullableUtcDateTimeConverter() DateTime? issuedAt,
    @Default('') String credentialId,
  }) = _StudentCertificate;

  factory StudentCertificate.fromJson(Map<String, dynamic> json) =>
      _$StudentCertificateFromJson(json);
}

/// `GET /students/:id` — one learner in full. An instructor is served only the enrolments and
/// certificates of the courses they teach (§7).
@freezed
abstract class StudentProfile with _$StudentProfile {
  const factory StudentProfile({
    @Default(Student()) Student student,
    @JsonKey(unknownEnumValue: StudentStatus.unknown)
    @Default(StudentStatus.unknown)
    StudentStatus status,

    /// Days since the learner last opened anything, as the academy counted them.
    @Default(0) int quietDays,
    @Default(Rank()) Rank rank,
    @Default(<StudentEnrollment>[]) List<StudentEnrollment> enrollments,
    @Default(<StudentCertificate>[]) List<StudentCertificate> certificates,
    @Default(StudentSummary()) StudentSummary summary,
  }) = _StudentProfile;

  factory StudentProfile.fromJson(Map<String, dynamic> json) => _$StudentProfileFromJson(json);
}

/// One course on the learner's progress tab, chapter by chapter.
@freezed
abstract class CourseProgressDetail with _$CourseProgressDetail {
  const factory CourseProgressDetail({
    @Default('') String courseId,
    @Default('') String courseTitle,
    @Default(0) num progress,
    @JsonKey(unknownEnumValue: EnrollmentStatus.unknown)
    @Default(EnrollmentStatus.active)
    EnrollmentStatus status,
    @Default(<ChapterProgress>[]) List<ChapterProgress> chapters,
  }) = _CourseProgressDetail;

  factory CourseProgressDetail.fromJson(Map<String, dynamic> json) =>
      _$CourseProgressDetailFromJson(json);
}

/// One quiz the learner has attempted.
@freezed
abstract class StudentQuizResult with _$StudentQuizResult {
  const factory StudentQuizResult({
    @Default('') String quizId,
    @Default('') String title,
    @Default('') String courseTitle,
    @Default(0) int attempts,

    /// Their best percentage across those attempts.
    @Default(0) num best,
    @Default(0) num passMark,
    @NullableUtcDateTimeConverter() DateTime? lastAt,
  }) = _StudentQuizResult;

  const StudentQuizResult._();

  factory StudentQuizResult.fromJson(Map<String, dynamic> json) =>
      _$StudentQuizResultFromJson(json);

  /// Whether their best attempt met the academy's pass mark.
  bool get passed => best >= passMark;
}

/// One hand-in of the learner's, as their progress tab lists it.
@freezed
abstract class StudentAssignmentResult with _$StudentAssignmentResult {
  const factory StudentAssignmentResult({
    @Default('') String submissionId,
    @Default('') String assignmentId,
    @Default('') String title,
    @Default('') String courseTitle,
    @NullableUtcDateTimeConverter() DateTime? submittedAt,
    @JsonKey(unknownEnumValue: ReviewStatus.unknown)
    @Default(ReviewStatus.waiting)
    ReviewStatus status,
    num? score,
    @Default(0) num max,
    @Default(0) num passMark,
    @Default(false) bool late,
  }) = _StudentAssignmentResult;

  factory StudentAssignmentResult.fromJson(Map<String, dynamic> json) =>
      _$StudentAssignmentResultFromJson(json);
}

/// `GET /students/:id/progress`.
@freezed
abstract class StudentProgress with _$StudentProgress {
  const factory StudentProgress({
    @Default(<CourseProgressDetail>[]) List<CourseProgressDetail> courses,
    @Default(<StudentQuizResult>[]) List<StudentQuizResult> quizzes,
    @Default(<StudentAssignmentResult>[]) List<StudentAssignmentResult> assignments,
    @Default(<StudyWeek>[]) List<StudyWeek> studyWeeks,
  }) = _StudentProgress;

  factory StudentProgress.fromJson(Map<String, dynamic> json) => _$StudentProgressFromJson(json);
}

/// `GET /students/:id/activity`.
@freezed
abstract class StudentActivity with _$StudentActivity {
  const factory StudentActivity({
    @Default(<LearningEvent>[]) List<LearningEvent> events,
    @Default(0) int total,
    @Default(<String, int>{}) Map<String, int> counts,
  }) = _StudentActivity;

  const StudentActivity._();

  factory StudentActivity.fromJson(Map<String, dynamic> json) => _$StudentActivityFromJson(json);

  int countOf(String kind) => counts[kind] ?? 0;
}
