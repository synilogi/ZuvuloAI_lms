import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/json.dart';

part 'activity.freezed.dart';
part 'activity.g.dart';

/// One of the seven days in "This week". `date` is an IST calendar day (`YYYY-MM-DD`) the server
/// worked out; the app parses it as a date, never as an instant (`StudyDay`).
@freezed
abstract class StudyDayMinutes with _$StudyDayMinutes {
  const factory StudyDayMinutes({required String date, @Default(0) int minutes}) = _StudyDayMinutes;

  const StudyDayMinutes._();

  factory StudyDayMinutes.fromJson(Map<String, dynamic> json) => _$StudyDayMinutesFromJson(json);

  /// The calendar day, or null if the server sent something this build cannot read.
  DateTime? get day => DateTime.tryParse(date);
}

/// One week of study, as the server labelled it. The label and the detail are its own words; the
/// app never works a week boundary out for itself (`studyWeeks`).
@freezed
abstract class StudyWeek with _$StudyWeek {
  const factory StudyWeek({
    @Default('') String label,
    @Default('') String detail,
    @Default(0) int minutes,
  }) = _StudyWeek;

  factory StudyWeek.fromJson(Map<String, dynamic> json) => _$StudyWeekFromJson(json);
}

/// `ActivityKind` (`packages/domain/src/activity.ts`).
enum ActivityKind {
  enrolled,
  @JsonValue('lesson-completed')
  lessonCompleted,
  @JsonValue('chapter-completed')
  chapterCompleted,
  @JsonValue('live-attended')
  liveAttended,
  @JsonValue('assignment-submitted')
  assignmentSubmitted,
  @JsonValue('assessment-passed')
  assessmentPassed,
  @JsonValue('certificate-issued')
  certificateIssued,
  @JsonValue('rank-achieved')
  rankAchieved,
  unknown,
}

/// The value the API uses for a kind, for a query that filters by it.
extension ActivityKindWire on ActivityKind {
  String get wireName => switch (this) {
    ActivityKind.enrolled => 'enrolled',
    ActivityKind.lessonCompleted => 'lesson-completed',
    ActivityKind.chapterCompleted => 'chapter-completed',
    ActivityKind.liveAttended => 'live-attended',
    ActivityKind.assignmentSubmitted => 'assignment-submitted',
    ActivityKind.assessmentPassed => 'assessment-passed',
    ActivityKind.certificateIssued => 'certificate-issued',
    ActivityKind.rankAchieved => 'rank-achieved',
    ActivityKind.unknown => 'unknown',
  };
}

/// One thing the learner did, as the academy recorded it.
@freezed
abstract class LearningEvent with _$LearningEvent {
  const factory LearningEvent({
    required String id,
    @JsonKey(unknownEnumValue: ActivityKind.unknown)
    @Default(ActivityKind.unknown)
    ActivityKind kind,
    @Default('') String title,
    String? context,

    /// Which course it happened in. Sent by the staff activity route, which can be filtered by it;
    /// the learner's own feed does not need it.
    String? courseId,
    @UtcDateTimeConverter() required DateTime at,
  }) = _LearningEvent;

  factory LearningEvent.fromJson(Map<String, dynamic> json) => _$LearningEventFromJson(json);
}

/// `GET /learning/activity` — the learner's own week and what they have been doing.
@freezed
abstract class LearningActivity with _$LearningActivity {
  const factory LearningActivity({
    @Default(<StudyDayMinutes>[]) List<StudyDayMinutes> week,
    @Default(<LearningEvent>[]) List<LearningEvent> events,
  }) = _LearningActivity;

  const LearningActivity._();

  factory LearningActivity.fromJson(Map<String, dynamic> json) => _$LearningActivityFromJson(json);

  bool get isEmpty => events.isEmpty;

  /// Minutes studied across the week the server sent.
  int get weekMinutes => week.fold(0, (sum, day) => sum + day.minutes);
}
