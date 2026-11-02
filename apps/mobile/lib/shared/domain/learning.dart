/// A course as the learner's own workspace serves it (`GET /learning/home`,
/// `/learning/courses`, `/learning/courses/:courseId`). Shared, because the workspace, Explore
/// and the lesson player all read the same shape (§26).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/json.dart';
import 'course.dart';
import 'progress.dart';

part 'learning.freezed.dart';
part 'learning.g.dart';

@freezed
abstract class LearnerCourse with _$LearnerCourse {
  const factory LearnerCourse({
    required Course course,
    required Enrollment enrollment,
    required ProgressSummary progress,
    required CourseProgressSnapshot snapshot,

    /// Absent once the course is finished, or while every remaining lesson is locked.
    NextLesson? next,
    @Default(<String>[]) List<String> instructorNames,
    @Default('') String levelTitle,
    @NullableUtcDateTimeConverter() DateTime? lastActiveAt,
  }) = _LearnerCourse;

  factory LearnerCourse.fromJson(Map<String, dynamic> json) => _$LearnerCourseFromJson(json);
}

/// A course the learner bookmarked but has not enrolled in: the outline only.
@freezed
abstract class SavedCourse with _$SavedCourse {
  const factory SavedCourse({
    required Course course,
    @Default(<String>[]) List<String> instructorNames,
    @Default('') String levelTitle,
  }) = _SavedCourse;

  factory SavedCourse.fromJson(Map<String, dynamic> json) => _$SavedCourseFromJson(json);
}

/// `POST …/complete` — what changed. The app shows a chapter or course moment **only** when the
/// server says so.
@freezed
abstract class CompleteResult with _$CompleteResult {
  const factory CompleteResult({
    required CourseProgressSnapshot snapshot,
    required ProgressSummary progress,

    /// The chapter's title, when this lesson finished it.
    String? chapterCompleted,
    @Default(false) bool courseCompleted,
    String? nextLessonId,
  }) = _CompleteResult;

  factory CompleteResult.fromJson(Map<String, dynamic> json) => _$CompleteResultFromJson(json);
}
