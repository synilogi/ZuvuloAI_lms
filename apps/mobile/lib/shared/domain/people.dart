/// Learners as the academy keeps them (`packages/domain/src/people.ts`): the person, their
/// enrolments, and the engagement status the academy derives. Shared, because the roster, a
/// learner's own profile and the reports all read the same student (§26).
///
/// The **server** derives the status it sends. [deriveStudentStatus] is ported so the app can read
/// a status it was not given — a roster row the academy filtered, say — and never to overrule one it
/// was (§18).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/json.dart';

part 'people.freezed.dart';
part 'people.g.dart';

/// `StudentStatus` — how engaged the academy reckons a learner is.
enum StudentStatus {
  active,
  @JsonValue('at-risk')
  atRisk,
  inactive,
  suspended,
  unknown,
}

/// `EnrollmentStatus`.
enum EnrollmentStatus { active, completed, paused, expired, unknown }

/// `EnrollmentSource` — how the learner came to be enrolled. `purchase`: a paid course opened by a
/// purchase the server verified with the gateway.
enum EnrollmentSource { self, admin, cohort, scholarship, purchase, unknown }

/// A learner. The e-mail and phone are here because only staff read this model; nothing public may
/// show them, and they are never written to disk (§18).
@freezed
abstract class Student with _$Student {
  const factory Student({
    @Default('') String id,
    @Default('') String name,
    @Default('') String email,
    String? phone,
    @Default('') String city,
    @NullableUtcDateTimeConverter() DateTime? joinedAt,
    @NullableUtcDateTimeConverter() DateTime? lastActiveAt,

    /// Set by an admin; the academy's derived status gives way to it.
    bool? suspended,
    @Default('') String rankId,
  }) = _Student;

  const Student._();

  factory Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);

  bool get isSuspended => suspended ?? false;
}

/// One enrolment, as the academy counts it.
@freezed
abstract class Enrollment with _$Enrollment {
  const factory Enrollment({
    @Default('') String id,
    @Default('') String studentId,
    @Default('') String courseId,
    @NullableUtcDateTimeConverter() DateTime? enrolledAt,
    @JsonKey(unknownEnumValue: EnrollmentStatus.unknown)
    @Default(EnrollmentStatus.active)
    EnrollmentStatus status,

    /// 0–100, weighted by lesson length the way course progress is.
    @Default(0) num progress,
    @JsonKey(unknownEnumValue: EnrollmentSource.unknown)
    @Default(EnrollmentSource.self)
    EnrollmentSource source,
    @NullableUtcDateTimeConverter() DateTime? lastActiveAt,
    @NullableUtcDateTimeConverter() DateTime? completedAt,
    String? lastLessonId,

    /// When access ends, from the academy's access length; absent for lifetime access.
    @NullableUtcDateTimeConverter() DateTime? expiresAt,
  }) = _Enrollment;

  const Enrollment._();

  factory Enrollment.fromJson(Map<String, dynamic> json) => _$EnrollmentFromJson(json);

  /// Whether the academy would let this enrolment be paused — a finished or expired one is done.
  bool get isOpen => status == EnrollmentStatus.active || status == EnrollmentStatus.paused;
}

/// A learner with open coursework reads as at risk after this many quiet days, unless the academy's
/// `settings.learning.atRiskDays` says otherwise.
const atRiskAfterDays = 10;

/// Nothing opened for this long and the learner reads as inactive, whatever else is true.
const inactiveAfterDays = 45;

/// `deriveStudentStatus`, ported. At risk means there is unfinished work **and** the learner has
/// gone quiet; someone with nothing in progress is simply inactive. [atRiskDays] is the academy's
/// own setting, which only the server knows — pass it when it is to hand.
StudentStatus deriveStudentStatus(
  Student student,
  List<Enrollment> enrollments, {
  required DateTime now,
  int atRiskDays = atRiskAfterDays,
}) {
  if (student.isSuspended) return StudentStatus.suspended;
  final lastActive = student.lastActiveAt;
  if (lastActive == null) return StudentStatus.unknown;
  final quietDays = now.difference(lastActive).inMicroseconds / Duration.microsecondsPerDay;
  final hasOpenWork = enrollments.any((e) => e.status == EnrollmentStatus.active);
  if (quietDays >= inactiveAfterDays) return StudentStatus.inactive;
  if (quietDays >= atRiskDays) {
    return hasOpenWork ? StudentStatus.atRisk : StudentStatus.inactive;
  }
  return StudentStatus.active;
}

/// `completionRate`, ported — the share of settled enrolments that finished, 0–100. A paused
/// enrolment is not counted either way, because it was never given its chance.
int completionRate(List<Enrollment> enrollments) {
  final settled = enrollments.where((e) => e.status != EnrollmentStatus.paused).toList();
  if (settled.isEmpty) return 0;
  final done = settled.where((e) => e.status == EnrollmentStatus.completed).length;
  return (done / settled.length * 100).round();
}
