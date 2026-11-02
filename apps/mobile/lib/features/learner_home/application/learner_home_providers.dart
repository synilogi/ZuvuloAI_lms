import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routing/routes.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/domain/learning.dart';
import '../../../shared/domain/progress.dart';
import '../data/dto/learner_home.dart';
import '../data/learning_api.dart';

/// The learner models the screens read (§26).
export '../../../shared/domain/learning.dart';
export '../../../shared/domain/progress.dart';
export '../data/dto/learner_home.dart';

/// `GET /learning/home`. A staff account reaching this would get the route's 400 "Only learners
/// have a learning workspace."; the app turns that into a not-found so no screen ever shows a
/// developer message (§16).
final learnerHomeProvider = FutureProvider<LearnerHome>((ref) async {
  try {
    return await ref.watch(learningApiProvider).home();
  } on ApiException catch (e) {
    throw _notALearner(e);
  }
});

final learnerCoursesProvider = FutureProvider<LearnerCourses>((ref) async {
  try {
    return await ref.watch(learningApiProvider).courses();
  } on ApiException catch (e) {
    throw _notALearner(e);
  }
});

/// The learning workspace is learner-only, and the router keeps everyone else out. If one of its
/// routes is reached anyway, the server's 400 is a wrong-shell mistake, not a bad request.
ApiException _notALearner(ApiException e) {
  final failure = e.failure;
  return failure is ValidationFailure &&
          failure.message == 'Only learners have a learning workspace.'
      ? const ApiException(NotFoundFailure())
      : e;
}

/// An enrolment that has expired is neither open nor completed, so it would fall out of both
/// tabs. It stays under "In progress" carrying the server's status, so the learner can see that
/// access ended and when.
bool showsInProgress(LearnerCourse course) =>
    course.enrollment.isOpen || course.enrollment.status == EnrollmentStatus.expired;

/// How the courses split across the My Learning tabs. The **server's** `enrollment.status` and
/// its own `saved` list decide; nothing here counts lessons (§18). Saved is a separate list, so
/// that tab has no enrolled courses of its own.
List<LearnerCourse> coursesForTab(LearnerCourses data, MyLearningTab tab) => switch (tab) {
  MyLearningTab.inProgress => [
    for (final c in data.courses)
      if (showsInProgress(c)) c,
  ],
  MyLearningTab.completed => [
    for (final c in data.courses)
      if (c.enrollment.status == EnrollmentStatus.completed) c,
  ],
  MyLearningTab.saved => const [],
};
