/// How far a learner has got, exactly as the API reports it (`packages/domain/src/progress.ts`,
/// `apps/api/src/lib/learning.ts`). The app never works out completion, locking or a percentage
/// of its own — it renders what the server sent (§18, §28.4).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/json.dart';

part 'progress.freezed.dart';
part 'progress.g.dart';

/// `ProgressState`. [unknown] keeps a value added later from crashing the app.
enum ProgressState {
  locked,
  @JsonValue('not-started')
  notStarted,
  @JsonValue('in-progress')
  inProgress,
  completed,
  unknown,
}

/// `Enrollment.status`.
enum EnrollmentStatus { active, completed, paused, expired, unknown }

@freezed
abstract class LessonProgress with _$LessonProgress {
  const factory LessonProgress({
    required String lessonId,
    @JsonKey(unknownEnumValue: ProgressState.unknown)
    @Default(ProgressState.notStarted)
    ProgressState state,

    /// 0–1 for a lesson partly consumed (video watched, reading scrolled).
    double? fraction,

    /// Where a video was left, in seconds.
    int? positionSec,
    @NullableUtcDateTimeConverter() DateTime? completedAt,
  }) = _LessonProgress;

  factory LessonProgress.fromJson(Map<String, dynamic> json) => _$LessonProgressFromJson(json);
}

/// Every lesson's state in one course, keyed by lesson id.
@freezed
abstract class CourseProgressSnapshot with _$CourseProgressSnapshot {
  const factory CourseProgressSnapshot({
    required String courseId,
    @Default(<String, LessonProgress>{}) Map<String, LessonProgress> lessons,
    String? lastLessonId,
    @NullableUtcDateTimeConverter() DateTime? lastActiveAt,
  }) = _CourseProgressSnapshot;

  const CourseProgressSnapshot._();

  factory CourseProgressSnapshot.fromJson(Map<String, dynamic> json) =>
      _$CourseProgressSnapshotFromJson(json);

  ProgressState stateOf(String lessonId) => lessons[lessonId]?.state ?? ProgressState.notStarted;
}

/// The course's totals, weighted by lesson minutes on the server — never recomputed here.
@freezed
abstract class ProgressSummary with _$ProgressSummary {
  const factory ProgressSummary({
    @Default(0) int completed,
    @Default(0) int total,

    /// 0–100.
    @Default(0) int percent,
    @Default(0) int remainingMin,
    @JsonKey(unknownEnumValue: ProgressState.unknown)
    @Default(ProgressState.notStarted)
    ProgressState state,
  }) = _ProgressSummary;

  const ProgressSummary._();

  factory ProgressSummary.fromJson(Map<String, dynamic> json) => _$ProgressSummaryFromJson(json);

  /// 0–1, for a ring or a bar.
  double get fraction => percent / 100;
}

/// A learner's place in a course. `progress` here is the server's stored percentage; the live
/// figure a screen shows comes from [ProgressSummary].
@freezed
abstract class Enrollment with _$Enrollment {
  const factory Enrollment({
    required String id,
    required String studentId,
    required String courseId,
    @JsonKey(unknownEnumValue: EnrollmentStatus.unknown)
    @Default(EnrollmentStatus.active)
    EnrollmentStatus status,
    @Default(0) int progress,
    @Default('') String source,

    /// Empty for the placeholder enrolment of a learner who is not enrolled.
    @EmptyAsNullUtcDateTimeConverter() DateTime? enrolledAt,
    @NullableUtcDateTimeConverter() DateTime? lastActiveAt,
    @NullableUtcDateTimeConverter() DateTime? completedAt,
    @NullableUtcDateTimeConverter() DateTime? expiresAt,
    String? lastLessonId,
  }) = _Enrollment;

  const Enrollment._();

  factory Enrollment.fromJson(Map<String, dynamic> json) => _$EnrollmentFromJson(json);

  /// A course the learner may still work on. The server decides; this only groups the tabs.
  bool get isOpen => status == EnrollmentStatus.active || status == EnrollmentStatus.paused;

  /// The stand-in `GET /learning/courses/:id` sends for someone who is not enrolled: it has no
  /// id and no date, and says nothing about access. `enrolled` on the response is what decides.
  bool get isPlaceholder => id.isEmpty;
}

/// Where the learner carries on: the server picks it, and Resume opens exactly this.
@freezed
abstract class NextLesson with _$NextLesson {
  const factory NextLesson({
    required String id,
    required String title,

    /// The backend's `LessonType`, kept as sent.
    @Default('') String type,
    @Default(0) int durationMin,
    @Default(0) int chapterIndex,
    @Default('') String chapterTitle,

    /// "2.3"
    @Default('') String lessonNumber,
    @JsonKey(unknownEnumValue: ProgressState.unknown)
    @Default(ProgressState.notStarted)
    ProgressState state,
    double? fraction,
    int? positionSec,
  }) = _NextLesson;

  factory NextLesson.fromJson(Map<String, dynamic> json) => _$NextLessonFromJson(json);
}
