/// The learning taxonomy as the API serves it (`packages/domain/src/catalog.ts`): a course, its
/// chapters and lessons, the level's categories and the instructors who teach it. Shared, because
/// the public catalogue, the learner's workspace and the lesson player all read the same course
/// (§26). Only the fields the app uses are modelled (§10.4).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/json.dart';

part 'course.freezed.dart';
part 'course.g.dart';

/// How a course runs (`CourseFormat`). [unknown] keeps a value added later from crashing the app.
enum CourseFormat {
  @JsonValue('self-paced')
  selfPaced,
  cohort,
  hybrid,
  unknown,
}

/// `CourseStatus` — the public catalogue only ever serves `published`, but a detail page is
/// reachable by slug, so the value is read rather than assumed.
enum CourseStatus { draft, published, archived, unknown }

/// `CourseVisibility`.
enum CourseVisibility { public, unlisted, private, unknown }

/// `ContentStatus` for chapters and lessons.
enum ContentStatus { draft, published, unknown }

/// `CategoryStatus`; a hidden category is filtered out of the catalogue's chips (the server does
/// not filter it).
enum CategoryStatus { active, hidden, unknown }

/// A stored file the API streams from `url` (`/media/<id>`), behind the bearer header (§13).
@freezed
abstract class MediaFile with _$MediaFile {
  const factory MediaFile({
    required String name,
    @Default(0) double sizeMb,
    String? id,
    String? url,
    String? mime,
  }) = _MediaFile;

  factory MediaFile.fromJson(Map<String, dynamic> json) => _$MediaFileFromJson(json);
}

/// A course price. `amount` is **whole major units** (rupees), not minor units — see
/// `Money.formatMajor` and clarification A2.
@freezed
abstract class Price with _$Price {
  const factory Price({required int amount, required String currency}) = _Price;

  factory Price.fromJson(Map<String, dynamic> json) => _$PriceFromJson(json);
}

/// `CoursePricing` — whether a course costs anything. `unset`: no admin chose yet, so nobody may join
/// it or buy it until one does. [unknown] keeps a value added later from crashing the app, and is
/// read as not open, never as free.
enum CoursePricing { free, paid, unset, unknown }

/// The prices an admin may set for a paid course, in whole rupees (`COURSE_PRICE_MIN`/`MAX` in
/// `packages/domain/src/catalog.ts`).
const coursePriceMin = 1;
const coursePriceMax = 500000;

/// How a learner gets into a course (`courseSale` in `packages/domain/src/catalog.ts`): free to join,
/// paid at the price shown, or not open to them yet. Read only to choose what the page offers — the
/// server decides every enrolment and prices every order itself.
sealed class CourseSale {
  const CourseSale();
}

/// Joined with Enrol, for nothing.
final class FreeCourseSale extends CourseSale {
  const FreeCourseSale();

  @override
  bool operator ==(Object other) => other is FreeCourseSale;

  @override
  int get hashCode => (FreeCourseSale).hashCode;
}

/// Bought, at [price] — whole rupees, all-inclusive, exactly as the academy set it.
final class PaidCourseSale extends CourseSale {
  const PaidCourseSale(this.price);

  final Price price;

  @override
  bool operator ==(Object other) => other is PaidCourseSale && other.price == price;

  @override
  int get hashCode => price.hashCode;
}

/// Neither: the price was never decided, or what was set is not a price the academy can sell at.
final class UnavailableCourseSale extends CourseSale {
  const UnavailableCourseSale();

  @override
  bool operator ==(Object other) => other is UnavailableCourseSale;

  @override
  int get hashCode => (UnavailableCourseSale).hashCode;
}

/// The sale state of a course with [pricing] and [price]. A course from a server that sends no
/// `pricing` reads as the domain's `pricingOf` does: undecided when it carries a price, free when it
/// does not. A paid course without a valid price is never free.
CourseSale courseSaleOf({CoursePricing? pricing, Price? price}) {
  final effective = pricing ?? (price != null ? CoursePricing.unset : CoursePricing.free);
  if (effective == CoursePricing.free) return const FreeCourseSale();
  if (effective == CoursePricing.paid &&
      price != null &&
      price.amount >= coursePriceMin &&
      price.amount <= coursePriceMax &&
      price.currency == 'INR') {
    return PaidCourseSale(price);
  }
  return const UnavailableCourseSale();
}

/// A marker on a lesson's video timeline.
@freezed
abstract class LessonVideoMarker with _$LessonVideoMarker {
  const factory LessonVideoMarker({required int atSec, required String title}) = _LessonVideoMarker;

  factory LessonVideoMarker.fromJson(Map<String, dynamic> json) =>
      _$LessonVideoMarkerFromJson(json);
}

@freezed
abstract class VideoContent with _$VideoContent {
  const factory VideoContent({
    MediaFile? file,
    int? durationSec,
    @Default(false) bool captions,
    @Default(<LessonVideoMarker>[]) List<LessonVideoMarker> markers,
  }) = _VideoContent;

  factory VideoContent.fromJson(Map<String, dynamic> json) => _$VideoContentFromJson(json);
}

@freezed
abstract class ArticleContent with _$ArticleContent {
  const factory ArticleContent({@Default('') String body}) = _ArticleContent;

  factory ArticleContent.fromJson(Map<String, dynamic> json) => _$ArticleContentFromJson(json);
}

@freezed
abstract class DocumentContent with _$DocumentContent {
  const factory DocumentContent({MediaFile? file, int? pages, @Default(false) bool downloadable}) =
      _DocumentContent;

  factory DocumentContent.fromJson(Map<String, dynamic> json) => _$DocumentContentFromJson(json);
}

/// What a quiz lesson delivers, mirrored from the linked quiz. The questions themselves come
/// from the learner-safe quiz the lesson route sends separately — never with their answer key.
@freezed
abstract class QuizContent with _$QuizContent {
  const factory QuizContent({
    String? quizId,
    @Default(0) int questions,
    @Default(0) int passMark,
    @Default(0) int attempts,
    int? timeLimitMin,
  }) = _QuizContent;

  factory QuizContent.fromJson(Map<String, dynamic> json) => _$QuizContentFromJson(json);
}

/// What an assignment lesson delivers, mirrored from the linked assignment.
@freezed
abstract class AssignmentContent with _$AssignmentContent {
  const factory AssignmentContent({
    String? assignmentId,
    @Default('') String brief,
    @Default(0) int dueAfterDays,
    @Default(0) int maxScore,
    @Default('') String submission,
  }) = _AssignmentContent;

  factory AssignmentContent.fromJson(Map<String, dynamic> json) =>
      _$AssignmentContentFromJson(json);
}

/// What a live lesson delivers, mirrored from the linked live class.
@freezed
abstract class LiveContent with _$LiveContent {
  const factory LiveContent({
    @NullableUtcDateTimeConverter() DateTime? startsAt,
    @Default(0) int durationMin,
    @Default(false) bool recorded,
    String? liveClassId,
  }) = _LiveContent;

  factory LiveContent.fromJson(Map<String, dynamic> json) => _$LiveContentFromJson(json);
}

/// What a lesson holds, by type. The server sends only the block its type uses, and strips every
/// block when the viewer may not open the lesson — a stripped lesson arrives as `{}`.
@freezed
abstract class LessonContent with _$LessonContent {
  const factory LessonContent({
    VideoContent? video,
    ArticleContent? article,
    DocumentContent? document,
    QuizContent? quiz,
    AssignmentContent? assignment,
    LiveContent? live,
  }) = _LessonContent;

  const LessonContent._();

  factory LessonContent.fromJson(Map<String, dynamic> json) => _$LessonContentFromJson(json);

  /// Whether the server sent anything to show.
  bool get isEmpty =>
      video == null &&
      article == null &&
      document == null &&
      quiz == null &&
      assignment == null &&
      live == null;
}

/// How a lesson counts as done (`CompletionRule`). The **server** applies it; the app only says
/// what it is waiting for.
enum CompletionRule { opened, watched, submitted, passed, unknown }

/// A lesson's own settings, where the academy set them.
@freezed
abstract class LessonSettings with _$LessonSettings {
  const factory LessonSettings({
    @JsonKey(unknownEnumValue: CompletionRule.unknown) CompletionRule? completion,
    @Default(false) bool sequential,
    @Default(false) bool discussion,
    @Default(false) bool resourcesDownloadable,
  }) = _LessonSettings;

  factory LessonSettings.fromJson(Map<String, dynamic> json) => _$LessonSettingsFromJson(json);
}

@freezed
abstract class Lesson with _$Lesson {
  const factory Lesson({
    required String id,
    required String title,

    /// The backend's `LessonType`, kept as sent; the UI maps it through `LessonType.parse`.
    required String type,
    @Default(0) int durationMin,
    @JsonKey(unknownEnumValue: ContentStatus.unknown)
    @Default(ContentStatus.published)
    ContentStatus status,
    @Default(false) bool isPreview,
    String? description,
    @Default(<String>[]) List<String> objectives,
    LessonContent? content,
    LessonSettings? settings,
  }) = _Lesson;

  const Lesson._();

  factory Lesson.fromJson(Map<String, dynamic> json) => _$LessonFromJson(json);

  /// A lesson a visitor may open: the server sends its body only when both are true, and the app
  /// asks for nothing more (`withoutLessonContent` in `apps/api/src/lib/mapCourse.ts`).
  bool get isPlayablePreview => isPreview && status == ContentStatus.published;
}

@freezed
abstract class Chapter with _$Chapter {
  const factory Chapter({
    required String id,
    required String title,
    String? summary,
    String? objective,
    @JsonKey(unknownEnumValue: ContentStatus.unknown)
    @Default(ContentStatus.published)
    ContentStatus status,
    @Default(<Lesson>[]) List<Lesson> lessons,
  }) = _CatalogChapter;

  factory Chapter.fromJson(Map<String, dynamic> json) => _$CatalogChapterFromJson(json);
}

/// A course as the public catalogue serves it (`GET /catalog/courses`), outline only.
@freezed
abstract class Course with _$Course {
  const factory Course({
    required String id,
    required String slug,
    required String title,
    @Default('') String subtitle,
    @Default('') String description,
    required String levelId,
    required String categoryId,
    @Default(<String>[]) List<String> instructorIds,
    @JsonKey(unknownEnumValue: CourseFormat.unknown)
    @Default(CourseFormat.selfPaced)
    CourseFormat format,
    @Default('') String language,

    /// The backend's `CoverMotif`, kept as sent; the UI maps it through `CoverMotif.parse`.
    String? coverMotif,

    /// The uploaded cover image (`/catalog/covers/<id>`), or null when the motif is the cover.
    String? coverImageId,
    String? coverImageUrl,
    @Default(<Chapter>[]) List<Chapter> chapters,
    @Default(0) int liveSessions,
    int? estimatedWeeks,
    String? certificateTitle,
    Price? price,

    /// Free, paid or undecided; read with [price] through [sale].
    @JsonKey(unknownEnumValue: CoursePricing.unknown) CoursePricing? pricing,
    @Default(0) int enrolledCount,
    @JsonKey(unknownEnumValue: CourseStatus.unknown)
    @Default(CourseStatus.published)
    CourseStatus status,
    @JsonKey(unknownEnumValue: CourseVisibility.unknown)
    @Default(CourseVisibility.public)
    CourseVisibility visibility,
    @Default(<String>[]) List<String> outcomes,
    @Default(<String>[]) List<String> tags,

    /// Sent only when the academy publishes ratings and the minimum count is met (`catalog.ts`).
    double? rating,
    int? ratingCount,
  }) = _CatalogCourse;

  const Course._();

  factory Course.fromJson(Map<String, dynamic> json) => _$CatalogCourseFromJson(json);

  List<Lesson> get lessons => [for (final c in chapters) ...c.lessons];

  /// Summed from the lessons the server sent, as the web's `courseDurationMin` does.
  int get durationMin => lessons.fold(0, (sum, l) => sum + l.durationMin);

  int get previewCount => lessons.where((l) => l.isPlayablePreview).length;

  /// Free to join, for sale at its price, or not open yet.
  CourseSale get sale => courseSaleOf(pricing: pricing, price: price);
}

/// A catalogue category (`GET /catalog/categories`).
@freezed
abstract class CourseCategory with _$CourseCategory {
  const factory CourseCategory({
    required String id,
    required String name,
    @Default('') String description,
    @Default(<String>[]) List<String> levelIds,
    @Default(0) int order,
    @JsonKey(unknownEnumValue: CategoryStatus.unknown)
    @Default(CategoryStatus.active)
    CategoryStatus status,
  }) = _CatalogCategory;

  factory CourseCategory.fromJson(Map<String, dynamic> json) => _$CatalogCategoryFromJson(json);
}

/// An instructor as the public catalogue serves them. Their email and phone are deliberately not
/// modelled: the route sends them, and nothing public may show them (§18).
@freezed
abstract class Instructor with _$Instructor {
  const factory Instructor({
    required String id,
    required String name,
    @Default('') String title,
    @Default('') String bio,
    @Default(<String>[]) List<String> expertise,
    int? yearsTeaching,
    MediaFile? photo,
  }) = _CatalogInstructor;

  factory Instructor.fromJson(Map<String, dynamic> json) => _$CatalogInstructorFromJson(json);
}
