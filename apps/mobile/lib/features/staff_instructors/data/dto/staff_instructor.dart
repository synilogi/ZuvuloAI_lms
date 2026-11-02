import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';
import '../../../../shared/domain/course.dart';
import '../../../../shared/domain/dashboard.dart';

part 'staff_instructor.freezed.dart';
part 'staff_instructor.g.dart';

/// `apps/api/src/routes/instructors.ts` and `packages/domain/src/catalog.ts` — the academy's
/// teaching staff as an admin reads and manages them. The public `Instructor` in
/// `shared/domain/course.dart` carries only what a learner may see; this one carries the record.

/// `InstructorStatus`. An invited instructor has an account and has not chosen a password yet.
enum InstructorStatus { active, invited, inactive, unknown }

/// The instructor record, as `mapInstructor` sends it.
@freezed
abstract class AcademyInstructor with _$AcademyInstructor {
  const factory AcademyInstructor({
    required String id,
    @Default('') String name,
    @Default('') String title,
    int? yearsTeaching,
    @Default('') String email,
    @Default('') String bio,
    @Default(<String>[]) List<String> expertise,
    @JsonKey(unknownEnumValue: InstructorStatus.unknown)
    @Default(InstructorStatus.unknown)
    InstructorStatus status,
    @UtcDateTimeConverter() required DateTime joinedAt,
    @Default('') String city,
    @Default(<String>[]) List<String> languages,
    String? phone,
    MediaFile? photo,
  }) = _AcademyInstructor;

  const AcademyInstructor._();

  factory AcademyInstructor.fromJson(Map<String, dynamic> json) =>
      _$AcademyInstructorFromJson(json);

  /// An invited instructor may be sent their invitation again; nobody else needs one.
  bool get awaitsInvite => status == InstructorStatus.invited;
}

/// A course on an instructor's row, named only.
@freezed
abstract class InstructorCourseBrief with _$InstructorCourseBrief {
  const factory InstructorCourseBrief({
    @Default('') String id,
    @Default('') String title,
    @JsonKey(unknownEnumValue: CourseStatus.unknown)
    @Default(CourseStatus.unknown)
    CourseStatus status,
  }) = _InstructorCourseBrief;

  factory InstructorCourseBrief.fromJson(Map<String, dynamic> json) =>
      _$InstructorCourseBriefFromJson(json);
}

/// One row of the directory: the record plus the academy's own arithmetic about their teaching.
@freezed
abstract class InstructorRow with _$InstructorRow {
  const factory InstructorRow({
    required AcademyInstructor instructor,
    @Default(<InstructorCourseBrief>[]) List<InstructorCourseBrief> courses,
    @Default(0) int students,

    /// Weighted across their published courses; `null` until a course has been rated.
    double? rating,
    @Default(0) int ratingCount,

    /// Percentage; `null` when they have no settled enrolments to compute one from.
    int? completion,
    @Default(0) int toReview,
    @Default(0) int overdue,
  }) = _InstructorRow;

  const InstructorRow._();

  factory InstructorRow.fromJson(Map<String, dynamic> json) => _$InstructorRowFromJson(json);

  int get publishedCourses => courses.where((c) => c.status == CourseStatus.published).length;
}

/// `GET /instructors` — the directory, the academy's own counts, and every expertise tag in use.
@freezed
abstract class InstructorDirectory with _$InstructorDirectory {
  const factory InstructorDirectory({
    @Default(<InstructorRow>[]) List<InstructorRow> rows,
    @Default(<String, int>{}) Map<String, int> counts,
    @Default(<String>[]) List<String> expertise,
  }) = _InstructorDirectory;

  const InstructorDirectory._();

  factory InstructorDirectory.fromJson(Map<String, dynamic> json) =>
      _$InstructorDirectoryFromJson(json);

  /// The route's count for a status tab, or for `all`.
  int countOf(String status) => counts[status] ?? 0;
}

/// A course in an instructor's portfolio, with how it is doing.
@freezed
abstract class InstructorCourse with _$InstructorCourse {
  const factory InstructorCourse({
    @Default('') String id,
    @Default('') String title,
    @JsonKey(unknownEnumValue: CourseStatus.unknown)
    @Default(CourseStatus.unknown)
    CourseStatus status,
    @Default('') String levelTitle,
    String? coverMotif,

    /// The uploaded cover image (`/catalog/covers/<id>`), or null when the motif is the cover.
    String? coverImageUrl,

    /// `lead` or `co` — the academy decides which from the course's own instructor list.
    @Default('') String role,
    @Default(<String>[]) List<String> coInstructors,
    @Default(0) int enrolled,
    @Default(0) int activeLearners,
    double? rating,
    int? ratingCount,
    int? completion,
    @Default(0) int lessons,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _InstructorCourse;

  const InstructorCourse._();

  factory InstructorCourse.fromJson(Map<String, dynamic> json) => _$InstructorCourseFromJson(json);

  bool get isLead => role == 'lead';
}

/// How many learners in one city.
@freezed
abstract class CityCount with _$CityCount {
  const factory CityCount({@Default('') String city, @Default(0) int count}) = _CityCount;

  factory CityCount.fromJson(Map<String, dynamic> json) => _$CityCountFromJson(json);
}

/// Who this instructor reaches.
@freezed
abstract class InstructorReach with _$InstructorReach {
  const factory InstructorReach({
    @Default(0) int students,
    @Default(0) int active,
    @Default(0) int completed,
    @Default(0) int newThisMonth,
    @Default(<CityCount>[]) List<CityCount> cities,
  }) = _InstructorReach;

  factory InstructorReach.fromJson(Map<String, dynamic> json) => _$InstructorReachFromJson(json);
}

/// One month of enrolments, labelled as the academy labels it.
@freezed
abstract class MonthCount with _$MonthCount {
  const factory MonthCount({
    @Default('') String label,

    /// "Sep 2026", or "Sep so far" for the month in progress.
    @Default('') String detail,
    @Default(0) num value,
  }) = _MonthCount;

  factory MonthCount.fromJson(Map<String, dynamic> json) => _$MonthCountFromJson(json);
}

/// How this instructor is doing, against the academy as a whole.
@freezed
abstract class InstructorPerformance with _$InstructorPerformance {
  const factory InstructorPerformance({
    double? rating,
    @Default(0) int ratingCount,
    @Default(0) double academyRating,
    int? completion,
    @Default(0) int academyCompletion,

    /// Median hours from hand-in to a decision; `null` until they have reviewed one.
    int? reviewHoursMedian,

    /// Percentage reviewed inside the academy's 48-hour window.
    int? reviewsOnTime,
    @Default(0) int reviewed,
    @Default(0) int toReview,
    @Default(0) int liveDelivered,
    @Default(0) int liveUpcoming,

    /// Percentage of registrations that attended; `null` until attendance was taken.
    int? attendance,
    @Default(<MonthCount>[]) List<MonthCount> enrollmentsByMonth,
  }) = _InstructorPerformance;

  const InstructorPerformance._();

  factory InstructorPerformance.fromJson(Map<String, dynamic> json) =>
      _$InstructorPerformanceFromJson(json);

  /// How their rating compares with the academy's, in rating points; `null` without a rating.
  double? get ratingGap => rating == null ? null : rating! - academyRating;

  /// How their completion compares with the academy's, in percentage points.
  int? get completionGap => completion == null ? null : completion! - academyCompletion;
}

/// `GET /instructors/:id`.
@freezed
abstract class InstructorDetail with _$InstructorDetail {
  const factory InstructorDetail({
    required AcademyInstructor instructor,
    @Default(<InstructorCourse>[]) List<InstructorCourse> courses,
    @Default(InstructorReach()) InstructorReach reach,
    @Default(InstructorPerformance()) InstructorPerformance performance,
    @Default(<AdminEvent>[]) List<AdminEvent> activity,
  }) = _InstructorDetail;

  factory InstructorDetail.fromJson(Map<String, dynamic> json) => _$InstructorDetailFromJson(json);
}

/// What the invite and edit screens hold. `POST /instructors` and `PATCH /instructors/:id` both take
/// the **whole** `InstructorInput`, so an edit opens on the record as the academy has it and sends
/// every field back — a missing one would read as a change.
@freezed
abstract class InstructorForm with _$InstructorForm {
  const factory InstructorForm({
    @Default('') String name,
    @Default('') String title,
    @Default('') String email,
    @Default('') String bio,
    @Default(<String>[]) List<String> expertise,
    @Default(InstructorStatus.invited) InstructorStatus status,
    @Default('') String city,
    @Default(<String>[]) List<String> languages,
    @Default(<String>[]) List<String> courseIds,
    String? phone,
    int? yearsTeaching,
  }) = _InstructorForm;

  const InstructorForm._();

  /// An edit starts from the record exactly as the academy holds it.
  factory InstructorForm.of(AcademyInstructor instructor, {List<String> courseIds = const []}) =>
      InstructorForm(
        name: instructor.name,
        title: instructor.title,
        email: instructor.email,
        bio: instructor.bio,
        expertise: instructor.expertise,
        status: instructor.status == InstructorStatus.unknown
            ? InstructorStatus.active
            : instructor.status,
        city: instructor.city,
        languages: instructor.languages,
        courseIds: courseIds,
        phone: instructor.phone,
        yearsTeaching: instructor.yearsTeaching,
      );

  /// The body both write routes take. The photo is never sent: the app offers no upload for it, and
  /// sending nothing leaves whatever the academy holds untouched.
  Map<String, Object?> toInput() => {
    'name': name.trim(),
    'title': title.trim(),
    'email': email.trim().toLowerCase(),
    'bio': bio.trim(),
    'expertise': expertise,
    'status': (status == InstructorStatus.unknown ? InstructorStatus.active : status).name,
    'city': city.trim(),
    'languages': languages,
    'courseIds': courseIds,
    if (phone case final phone? when phone.trim().isNotEmpty) 'phone': phone.trim(),
    'yearsTeaching': ?yearsTeaching,
  };
}

final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
final _phone = RegExp(r'^\+?[\d\s-]{8,16}$');

/// The fields `validateInstructor` would refuse, so the screen can say so before asking. The academy
/// writes the words; this only decides which field each belongs to (D-023-5, D-025-x).
List<String> instructorFormProblems(InstructorForm form) {
  final problems = <String>[];
  if (form.name.trim().length < 3) problems.add('name');
  if (form.title.trim().length < 3) problems.add('title');
  if (!_email.hasMatch(form.email.trim().toLowerCase())) problems.add('email');
  if (form.phone case final phone? when phone.trim().isNotEmpty && !_phone.hasMatch(phone.trim())) {
    problems.add('phone');
  }
  // A full bio is only needed once they are active and visible to learners.
  if (form.status == InstructorStatus.active && form.bio.trim().length < 60) problems.add('bio');
  if (form.expertise.isEmpty) problems.add('expertise');
  if (form.languages.isEmpty) problems.add('languages');
  if (form.yearsTeaching case final years? when years < 0 || years > 70) {
    problems.add('yearsTeaching');
  }
  return problems;
}

/// `GET /instructors/requests` — someone who registered themselves to teach here and waits for this
/// academy's admin (D34). Not staff: approving makes them an active instructor who can sign in.
class InstructorRequest {
  const InstructorRequest({
    required this.id,
    required this.name,
    required this.email,
    required this.title,
    required this.status,
    required this.requestedAt,
  });

  factory InstructorRequest.fromJson(Map<String, dynamic> json) => InstructorRequest(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    title: json['title'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    requestedAt: DateTime.tryParse(json['requestedAt'] as String? ?? '')?.toUtc(),
  );

  final String id;
  final String name;
  final String email;
  final String title;

  /// `pending` or `rejected`.
  final String status;
  final DateTime? requestedAt;
}
