import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';
import '../../../../shared/domain/activity.dart';
import '../../../../shared/domain/learning.dart';

/// The study week is a shared model: the profile's activity feed reads the same shape.
export '../../../../shared/domain/activity.dart' show StudyDayMinutes;

part 'learner_home.freezed.dart';
part 'learner_home.g.dart';

/// What kind of thing is coming up.
enum UpcomingKind { live, assignment, quiz, unknown }

/// How urgent it is — the **server** decides, from the live class's phase and the deadline it
/// worked out for this learner (`routes/learning.ts`); the app never compares a date to decide.
enum UpcomingFlag {
  @JsonValue('live-now')
  liveNow,
  @JsonValue('starting-soon')
  startingSoon,
  overdue,
  @JsonValue('due-soon')
  dueSoon,
  unknown,
}

/// One entry in "Coming up". `to` is a **web** path; the app maps it through `WebPathMapper` and
/// never follows one it does not recognise (§5.4, §18).
@freezed
abstract class UpcomingItem with _$UpcomingItem {
  const factory UpcomingItem({
    required String id,
    @JsonKey(unknownEnumValue: UpcomingKind.unknown)
    @Default(UpcomingKind.unknown)
    UpcomingKind kind,
    @Default('') String title,

    /// "Class 10 Mathematics · 60 min"
    @Default('') String context,
    @UtcDateTimeConverter() required DateTime at,
    @Default('') String to,
    @JsonKey(unknownEnumValue: UpcomingFlag.unknown) UpcomingFlag? flag,
  }) = _UpcomingItem;

  factory UpcomingItem.fromJson(Map<String, dynamic> json) => _$UpcomingItemFromJson(json);
}

/// A lesson the learner opened recently, newest first (at most five).
@freezed
abstract class RecentLesson with _$RecentLesson {
  const factory RecentLesson({
    required String courseId,
    required String lessonId,
    @Default('') String courseTitle,
    @Default('') String lessonTitle,

    /// The backend's `LessonType`, kept as sent.
    @Default('') String type,
    @UtcDateTimeConverter() required DateTime at,
    @Default('') String state,
  }) = _RecentLesson;

  factory RecentLesson.fromJson(Map<String, dynamic> json) => _$RecentLessonFromJson(json);
}

/// `GET /learning/home`.
@freezed
abstract class LearnerHome with _$LearnerHome {
  const factory LearnerHome({
    @Default('') String firstName,
    @Default(<LearnerCourse>[]) List<LearnerCourse> courses,
    @Default(<SavedCourse>[]) List<SavedCourse> saved,
    @Default(<RecentLesson>[]) List<RecentLesson> recent,
    @Default(<UpcomingItem>[]) List<UpcomingItem> upcoming,
    @Default(<StudyDayMinutes>[]) List<StudyDayMinutes> week,
  }) = _LearnerHome;

  const LearnerHome._();

  factory LearnerHome.fromJson(Map<String, dynamic> json) => _$LearnerHomeFromJson(json);

  bool get isEmpty => courses.isEmpty && saved.isEmpty;
}

/// `GET /learning/courses`.
@freezed
abstract class LearnerCourses with _$LearnerCourses {
  const factory LearnerCourses({
    @Default(<LearnerCourse>[]) List<LearnerCourse> courses,
    @Default(<SavedCourse>[]) List<SavedCourse> saved,
  }) = _LearnerCourses;

  factory LearnerCourses.fromJson(Map<String, dynamic> json) => _$LearnerCoursesFromJson(json);
}
