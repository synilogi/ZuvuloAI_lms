/// Coursework as everyone reads it (`packages/domain/src/assignment.ts`): the assignment the
/// academy wrote, the hand-in, the rubric and the reviewer's verdict. Shared, because the learner's
/// coursework screens and the staff review queue read the same submission (§26). Only the fields
/// the app uses are modelled (§10.4).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/json.dart';

part 'assignment.freezed.dart';
part 'assignment.g.dart';

/// `SubmissionFormat` — what this assignment takes.
enum SubmissionFormat { file, text, chart, unknown }

/// `ReviewStatus`.
enum ReviewStatus {
  waiting,
  @JsonValue('in-review')
  inReview,
  graded,
  returned,
  unknown,
}

/// `DuePolicy.kind`: a fixed date, a number of days from when the chapter opened, or no deadline.
enum DueKind { date, relative, none, unknown }

/// A file on an assignment or a submission. The same shape the media route returns, which is why
/// it can be sent straight back as part of the work.
@freezed
abstract class Attachment with _$Attachment {
  const factory Attachment({
    String? id,
    @Default('') String name,
    @Default(0) double sizeMb,
    String? url,
    String? mime,
    int? pages,
  }) = _Attachment;

  factory Attachment.fromJson(Map<String, dynamic> json) => _$AttachmentFromJson(json);
}

/// One line of the academy's rubric.
@freezed
abstract class RubricCriterion with _$RubricCriterion {
  const factory RubricCriterion({
    required String id,
    @Default('') String title,
    @Default('') String description,
    @Default(0) int points,
  }) = _RubricCriterion;

  factory RubricCriterion.fromJson(Map<String, dynamic> json) => _$RubricCriterionFromJson(json);
}

/// When the assignment is due, as the academy set it. The **date** a learner sees is `dueAt` on
/// the response, which the server works out per learner — never computed here.
@freezed
abstract class DuePolicy with _$DuePolicy {
  const factory DuePolicy({
    @JsonKey(unknownEnumValue: DueKind.unknown) @Default(DueKind.none) DueKind kind,
    @NullableUtcDateTimeConverter() DateTime? dueAt,
    int? days,
  }) = _DuePolicy;

  factory DuePolicy.fromJson(Map<String, dynamic> json) => _$DuePolicyFromJson(json);
}

/// The birth details a chart submission carries, beside its written interpretation.
@freezed
abstract class BirthDetails with _$BirthDetails {
  const factory BirthDetails({
    @Default('') String label,
    @Default('') String date,
    @Default('') String time,
    @Default('') String place,
    @Default('') String lagna,
    @Default('') String moonSign,
    @Default('') String nakshatra,
  }) = _BirthDetails;

  const BirthDetails._();

  factory BirthDetails.fromJson(Map<String, dynamic> json) => _$BirthDetailsFromJson(json);

  /// Whether every field has something in it — the server takes the chart as one thing.
  bool get isComplete =>
      [label, date, time, place, lagna, moonSign, nakshatra].every((v) => v.trim().isNotEmpty);

  bool get isEmpty =>
      [label, date, time, place, lagna, moonSign, nakshatra].every((v) => v.trim().isEmpty);
}

/// The reviewer's verdict.
@freezed
abstract class Review with _$Review {
  const factory Review({
    @JsonKey(unknownEnumValue: ReviewStatus.unknown)
    @Default(ReviewStatus.waiting)
    ReviewStatus status,

    /// Points per rubric criterion, keyed by criterion id.
    @Default(<String, num>{}) Map<String, num> scores,

    /// Points given directly when there is no rubric.
    num? points,

    /// The final score, after any late penalty the academy applies.
    num? score,
    @Default('') String feedback,
    @NullableUtcDateTimeConverter() DateTime? updatedAt,
  }) = _Review;

  const Review._();

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);

  /// Sent back for another attempt.
  bool get isReturned => status == ReviewStatus.returned;

  /// The score, but only once it has actually been graded. A returned submission carries a
  /// `score` of 0 that means nothing yet (`mapLearnerSubmission`), and showing it would read as
  /// a zero the learner was given.
  num? get gradedScore => status == ReviewStatus.graded ? score : null;
}

/// What the learner handed in.
@freezed
abstract class Submission with _$Submission {
  const factory Submission({
    required String id,
    @Default(1) int attempt,
    @UtcDateTimeConverter() required DateTime submittedAt,
    @Default(false) bool late,
    String? text,
    @Default(<Attachment>[]) List<Attachment> files,
    BirthDetails? chart,
    @Default(Review()) Review review,
  }) = _Submission;

  factory Submission.fromJson(Map<String, dynamic> json) => _$SubmissionFromJson(json);
}

/// The assignment as the academy wrote it.
@freezed
abstract class CourseAssignment with _$CourseAssignment {
  const factory CourseAssignment({
    required String id,
    required String courseId,
    String? chapterId,
    String? lessonId,
    @Default('') String title,

    /// The brief, in the same small markup the article renderer supports.
    @Default('') String instructions,
    @Default(<Attachment>[]) List<Attachment> attachments,
    @JsonKey(unknownEnumValue: SubmissionFormat.unknown)
    @Default(SubmissionFormat.unknown)
    SubmissionFormat format,

    /// Written and chart submissions only.
    int? wordLimit,
    @Default(DuePolicy()) DuePolicy due,
    @Default(false) bool acceptsLate,

    /// Percent taken off a late submission's score.
    @Default(0) int latePenalty,
    @Default(<RubricCriterion>[]) List<RubricCriterion> rubric,
    @Default(0) int maxScore,

    /// In points.
    @Default(0) int passMark,
    @Default('') String status,
  }) = _CourseAssignment;

  const CourseAssignment._();

  factory CourseAssignment.fromJson(Map<String, dynamic> json) => _$CourseAssignmentFromJson(json);

  /// Graded against the rubric when it has criteria, otherwise out of `maxScore`.
  int get totalPoints =>
      rubric.isEmpty ? maxScore : rubric.fold(0, (sum, criterion) => sum + criterion.points);
}

/// Words as a reader counts them — runs of non-space characters, exactly as `countWords` in
/// `packages/domain/src/assignment.ts` does, because the server's own limits are counted this way.
int countWords(String? text) {
  final trimmed = (text ?? '').trim();
  return trimmed.isEmpty ? 0 : trimmed.split(RegExp(r'\s+')).length;
}

/// What a review would score, ported from `reviewScore`. The **server** computes the score it
/// stores; this is only what the app may show as an estimate before asking (§18).
@immutable
class ReviewScore {
  const ReviewScore({
    required this.raw,
    required this.penalty,
    required this.score,
    required this.max,
  });

  /// Before any late penalty.
  final num raw;

  /// Taken off for a late hand-in, when the academy's policy is to penalise.
  final num penalty;
  final num score;
  final num max;

  @override
  bool operator ==(Object other) =>
      other is ReviewScore &&
      other.raw == raw &&
      other.penalty == penalty &&
      other.score == score &&
      other.max == max;

  @override
  int get hashCode => Object.hash(raw, penalty, score, max);
}

/// [applyLatePenalty] is the academy's `learning.latePolicy`, which only the server knows; pass
/// false and the penalty is zero, exactly as the route does for a policy of `accept`.
ReviewScore reviewScore(
  CourseAssignment assignment, {
  required Map<String, num> scores,
  num? points,
  required bool late,
  bool applyLatePenalty = true,
}) {
  final raw = assignment.rubric.isEmpty
      ? (points ?? 0)
      : assignment.rubric.fold<num>(0, (n, c) => n + (scores[c.id] ?? 0));
  final penaltyPercent = applyLatePenalty ? assignment.latePenalty : 0;
  final penalty = late && penaltyPercent > 0 ? ((raw * penaltyPercent / 100) * 2).round() / 2 : 0;
  return ReviewScore(
    raw: raw,
    penalty: penalty,
    score: raw - penalty < 0 ? 0 : raw - penalty,
    max: assignment.totalPoints,
  );
}

/// What a decision needs before the server will take it. One problem, named the way `ReviewIssue`
/// names it, so a server refusal and the app's own check read the same.
@immutable
class ReviewIssue {
  const ReviewIssue({required this.field, required this.message, this.criterionId});

  /// `scores`, `points` or `feedback`.
  final String field;
  final String? criterionId;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is ReviewIssue &&
      other.field == field &&
      other.criterionId == criterionId &&
      other.message == message;

  @override
  int get hashCode => Object.hash(field, criterionId, message);
}

/// Whether a decision is ready, ported from `validateReview`. The app checks it to keep a button
/// honest; the **server** decides, and its `issues` are what a refusal shows (§18). The messages
/// here are the domain's own English, so they are only used to decide *which field* is wrong — the
/// screen says it in its own words.
List<ReviewIssue> validateReview(
  CourseAssignment assignment, {
  required Map<String, num> scores,
  num? points,
  required String feedback,
  required ReviewStatus decision,
}) {
  final issues = <ReviewIssue>[];
  if (decision == ReviewStatus.graded) {
    if (assignment.rubric.isNotEmpty) {
      for (final criterion in assignment.rubric) {
        final value = scores[criterion.id];
        if (value == null) {
          issues.add(
            ReviewIssue(field: 'scores', criterionId: criterion.id, message: criterion.title),
          );
        } else if (value < 0 || value > criterion.points) {
          issues.add(
            ReviewIssue(field: 'scores', criterionId: criterion.id, message: criterion.title),
          );
        }
      }
    } else if (points == null || points < 0 || points > assignment.maxScore) {
      issues.add(const ReviewIssue(field: 'points', message: 'points'));
    }
  }
  final words = countWords(feedback);
  if (decision == ReviewStatus.returned && words < 8) {
    issues.add(const ReviewIssue(field: 'feedback', message: 'feedback'));
  }
  if (decision == ReviewStatus.graded && words < 3) {
    issues.add(const ReviewIssue(field: 'feedback', message: 'feedback'));
  }
  return issues;
}
