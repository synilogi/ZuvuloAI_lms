import 'package:flutter/foundation.dart';

import '../../../../shared/domain/certificate.dart';
import '../../../../shared/domain/learning.dart';
import 'lesson_view.dart';

/// The certificate models are the shared ones: the wallet reads the same records (§10.4).
export '../../../../shared/domain/certificate.dart' show CertificateCriterion, CertificateRecord;

/// `GET /learning/courses/:courseId` — a [LearnerCourse] with what the course page adds: whether
/// this learner is enrolled, whether they saved it, its assignments and how close the certificate
/// is. The live classes the route also returns are FLUTTER-014's model (§10.4).
///
/// Written by hand rather than generated: the response is flat, so the shared part is parsed by
/// [LearnerCourse] and the extras are read beside it.
@immutable
class LearnerCourseDetail {
  const LearnerCourseDetail({
    required this.learner,
    required this.enrolled,
    required this.saved,
    this.assignments = const [],
    this.certificate,
  });

  factory LearnerCourseDetail.fromJson(Map<String, dynamic> json) => LearnerCourseDetail(
    learner: LearnerCourse.fromJson(json),
    enrolled: json['enrolled'] == true,
    saved: json['saved'] == true,
    assignments: [
      for (final row in (json['assignments'] as List<dynamic>?) ?? const [])
        LessonAssignmentSummary.fromJson(row as Map<String, dynamic>),
    ],
    certificate: json['certificate'] is Map<String, dynamic>
        ? CertificateRecord.fromJson(json['certificate']! as Map<String, dynamic>)
        : null,
  );

  final LearnerCourse learner;

  /// The server's own answer. The `enrollment` it sends alongside is a placeholder when this is
  /// false, so nothing else may be read as "enrolled".
  final bool enrolled;
  final bool saved;

  /// The course's published assignments for this learner, with the state the server gave each.
  final List<LessonAssignmentSummary> assignments;

  /// How close the certificate is; absent when the learner is not enrolled.
  final CertificateRecord? certificate;

  LearnerCourseDetail copyWith({LearnerCourse? learner, bool? enrolled, bool? saved}) =>
      LearnerCourseDetail(
        learner: learner ?? this.learner,
        enrolled: enrolled ?? this.enrolled,
        saved: saved ?? this.saved,
        assignments: assignments,
        certificate: certificate,
      );

  @override
  bool operator ==(Object other) =>
      other is LearnerCourseDetail &&
      other.learner == learner &&
      other.enrolled == enrolled &&
      other.saved == saved &&
      other.certificate == certificate &&
      listEquals(other.assignments, assignments);

  @override
  int get hashCode =>
      Object.hash(learner, enrolled, saved, certificate, Object.hashAll(assignments));
}
