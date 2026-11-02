import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';
import '../../../../shared/domain/course.dart';
import '../../../../shared/domain/progress.dart';
import '../../../../shared/domain/quiz.dart';

export '../../../../shared/domain/learning.dart' show CompleteResult;

part 'lesson_view.freezed.dart';
part 'lesson_view.g.dart';

/// Whether this lesson is open to this person, as the **server** decided.
enum LessonAccess {
  open,
  locked,

  /// Not enrolled, and the lesson is not a free preview.
  @JsonValue('not-enrolled')
  notEnrolled,

  /// Unpublished, or the enrolment's access has ended.
  unavailable,
  unknown,
}

/// Where Previous and Next go. `locked` says the next lesson cannot be opened yet.
@freezed
abstract class LessonLink with _$LessonLink {
  const factory LessonLink({
    required String id,
    @Default('') String title,
    @Default(false) bool locked,
  }) = _LessonLink;

  factory LessonLink.fromJson(Map<String, dynamic> json) => _$LessonLinkFromJson(json);
}

/// "3 of 18" across the whole course.
@freezed
abstract class LessonPosition with _$LessonPosition {
  const factory LessonPosition({@Default(0) int index, @Default(0) int total}) = _LessonPosition;

  const LessonPosition._();

  factory LessonPosition.fromJson(Map<String, dynamic> json) => _$LessonPositionFromJson(json);

  /// 1-based, for reading.
  int get oneBased => index + 1;
}

/// What the player needs to know about a linked assignment; the full assignment is FLUTTER-013's.
@freezed
abstract class LessonAssignmentSummary with _$LessonAssignmentSummary {
  const factory LessonAssignmentSummary({
    required String id,
    @Default('') String title,

    /// The server's own word: not-started, draft, submitted, under-review, graded, overdue, closed.
    @Default('') String state,
    @NullableUtcDateTimeConverter() DateTime? dueAt,
  }) = _LessonAssignmentSummary;

  factory LessonAssignmentSummary.fromJson(Map<String, dynamic> json) {
    final assignment = json['assignment'];
    return LessonAssignmentSummary(
      id: assignment is Map<String, dynamic> ? '${assignment['id']}' : '',
      title: assignment is Map<String, dynamic> ? '${assignment['title']}' : '',
      state: '${json['state'] ?? ''}',
      dueAt: json['dueAt'] is String && (json['dueAt']! as String).isNotEmpty
          ? DateTime.parse(json['dueAt']! as String).toUtc()
          : null,
    );
  }
}

/// `GET /learning/courses/:courseId/lessons/:lessonId`. Reading it **records the visit** on the
/// server, which is what "recently viewed" and resume are built from.
@freezed
abstract class LessonView with _$LessonView {
  const factory LessonView({
    required Course course,
    required Lesson lesson,
    required CourseProgressSnapshot snapshot,
    required ProgressSummary progress,
    @Default(false) bool enrolled,
    @Default(0) int chapterIndex,
    @Default(0) int lessonIndex,

    /// "2.3"
    @Default('') String number,
    @Default(LessonPosition()) LessonPosition position,
    @JsonKey(unknownEnumValue: ProgressState.unknown)
    @Default(ProgressState.notStarted)
    ProgressState state,
    LessonProgress? lessonProgress,
    @JsonKey(unknownEnumValue: LessonAccess.unknown)
    @Default(LessonAccess.unknown)
    LessonAccess access,

    /// Why it is closed, in the academy's words.
    String? lockedReason,
    LessonLink? previous,
    LessonLink? next,

    /// The quiz this lesson delivers, without its answer key — the route sends it that way and
    /// the model could not hold one anyway (`shared/domain/quiz.dart`).
    LearnerQuiz? quiz,

    /// The learner's best score on the linked quiz, as a percentage.
    int? quizBest,
    @JsonKey(fromJson: _assignmentFrom, includeToJson: false) LessonAssignmentSummary? assignment,
    @Default(<String>[]) List<String> instructorNames,
    @Default('') String note,
    @Default(false) bool bookmarked,

    /// The academy's watch threshold, as a percentage.
    @Default(0) int threshold,
  }) = _LessonView;

  const LessonView._();

  factory LessonView.fromJson(Map<String, dynamic> json) => _$LessonViewFromJson(json);

  bool get isOpen => access == LessonAccess.open;

  /// What this lesson needs before it counts as done, as the academy set it.
  CompletionRule get rule => lesson.settings?.completion ?? defaultCompletionFor(lesson.type);
}

LessonAssignmentSummary? _assignmentFrom(Object? json) =>
    json is Map<String, dynamic> ? LessonAssignmentSummary.fromJson(json) : null;

/// `defaultCompletion` from `packages/domain/src/catalog.ts` — what a lesson of each type needs
/// when the academy has not set a rule of its own. Display only: the server decides.
CompletionRule defaultCompletionFor(String lessonType) => switch (lessonType) {
  'video' => CompletionRule.watched,
  'reading' || 'document' || 'live' => CompletionRule.opened,
  'practice' || 'assignment' => CompletionRule.submitted,
  'assessment' => CompletionRule.passed,
  _ => CompletionRule.unknown,
};
