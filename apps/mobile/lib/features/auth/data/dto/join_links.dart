import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/json.dart';

part 'join_links.freezed.dart';
part 'join_links.g.dart';

/// The Admin's LMS a link names, as a visitor is shown it: its display name and its address.
@freezed
abstract class LmsSummary with _$LmsSummary {
  const factory LmsSummary({required String name, required String slug}) = _LmsSummary;

  factory LmsSummary.fromJson(Map<String, dynamic> json) => _$LmsSummaryFromJson(json);
}

/// `GET /public/academies/:slug` — the LMS a join link (`/join/<address>`) names. [open] is false
/// while the platform has suspended it: it takes nobody new. [invitationOnly] is true when the LMS adds
/// learners by invitation only: its join link takes no learners, though instructors may still ask to
/// teach there.
@freezed
abstract class LmsJoinPage with _$LmsJoinPage {
  const factory LmsJoinPage({
    required String name,
    required String slug,
    @Default(false) bool open,
    @Default(false) bool invitationOnly,
  }) = _LmsJoinPage;

  factory LmsJoinPage.fromJson(Map<String, dynamic> json) => _$LmsJoinPageFromJson(json);
}

/// `GET /public/invitations/:token` — what an invitation offers before anything is asked. The LMS
/// and the role are the invitation's, never the app's to choose; [email] is set when the Admin bound
/// it to one address, and only that address can accept it.
@freezed
abstract class InvitationView with _$InvitationView {
  const factory InvitationView({
    required LmsSummary lms,
    @Default('student') String role,
    String? email,
    @UtcDateTimeConverter() required DateTime expiresAt,
    @Default(false) bool open,
  }) = _InvitationView;

  factory InvitationView.fromJson(Map<String, dynamic> json) => _$InvitationViewFromJson(json);
}

/// The course a course link names.
@freezed
abstract class CourseLinkCourse with _$CourseLinkCourse {
  const factory CourseLinkCourse({
    required String id,
    required String title,
    @Default('') String slug,
  }) = _CourseLinkCourse;

  factory CourseLinkCourse.fromJson(Map<String, dynamic> json) => _$CourseLinkCourseFromJson(json);
}

/// `GET /public/courses/:courseId/enroll` — a course link: the course, and the Admin's LMS it
/// belongs to.
@freezed
abstract class CourseLinkView with _$CourseLinkView {
  const factory CourseLinkView({
    required LmsSummary lms,
    required CourseLinkCourse course,
    @Default(false) bool open,
  }) = _CourseLinkView;

  factory CourseLinkView.fromJson(Map<String, dynamic> json) => _$CourseLinkViewFromJson(json);
}
