import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/error_decoder.dart';
import '../../learner_home/learner_home.dart';
import '../data/course_learning_api.dart';
import '../data/dto/learner_course_detail.dart';

/// The course models the screens read (§26).
export '../data/dto/learner_course_detail.dart';

/// One course as this learner sees it. Auto-disposed: leaving the page and coming back re-reads
/// it, because enrolling, saving and progress all change it.
final learnerCourseProvider = FutureProvider.family<LearnerCourseDetail, String>(
  (ref, courseId) => ref.watch(courseLearningApiProvider).course(courseId),
  isAutoDispose: true,
);

/// What the course page is doing besides showing the course.
@immutable
class CourseActionState {
  const CourseActionState({
    this.enrolling = false,
    this.savePending = false,
    this.savedOverride,
    this.failure,
  });

  final bool enrolling;

  /// A save is in flight; the bookmark has already moved.
  final bool savePending;

  /// What to draw for the bookmark instead of what the course last said: the optimistic value
  /// while the request is in flight, then the server's own answer. Null means "ask the course".
  final bool? savedOverride;

  /// Why the last action was refused; the server's own words are inside it (§16).
  final AppFailure? failure;

  bool get busy => enrolling || savePending;

  /// Whether the bookmark is on, with the server's answer always winning over the course's older
  /// copy of it.
  bool savedFor(LearnerCourseDetail detail) => savedOverride ?? detail.saved;
}

/// Saving and enrolling. Both are the server's decision; this carries its answer back and
/// re-reads the learner's other screens so they agree.
class CourseActionsController extends Notifier<CourseActionState> {
  @override
  CourseActionState build() => const CourseActionState();

  /// Moves the bookmark at once and puts it back if the server refuses.
  Future<void> toggleSaved(String courseId) async {
    final current = ref.read(learnerCourseProvider(courseId)).value;
    if (current == null || state.busy) return;
    final optimistic = !state.savedFor(current);
    state = CourseActionState(savePending: true, savedOverride: optimistic);
    try {
      final saved = await ref.read(courseLearningApiProvider).toggleSaved(courseId);
      state = CourseActionState(savedOverride: saved);
      _refreshWorkspace();
    } on ApiException catch (e) {
      // Back to what the server last told us, with the reason it gave.
      state = CourseActionState(savedOverride: current.saved, failure: e.failure);
    }
  }

  /// Enrols, then re-reads the course and the learner's workspace, so Home and My Learning show
  /// it without a restart.
  Future<bool> enroll(String courseId) async {
    if (state.busy) return false;
    state = CourseActionState(enrolling: true, savedOverride: state.savedOverride);
    try {
      await ref.read(courseLearningApiProvider).enroll(courseId);
      state = CourseActionState(savedOverride: state.savedOverride);
      ref.invalidate(learnerCourseProvider(courseId));
      _refreshWorkspace();
      return true;
    } on ApiException catch (e) {
      state = CourseActionState(savedOverride: state.savedOverride, failure: e.failure);
      // The page thought the course was free to join, but it is paid or not open: read it again,
      // so the way in it offers is the right one.
      if (e.failure is CourseSaleFailure) ref.invalidate(learnerCourseProvider(courseId));
      return false;
    }
  }

  void clearFailure() => state = CourseActionState(savedOverride: state.savedOverride);

  /// Home and My Learning are read from the server too, so they are simply read again.
  void _refreshWorkspace() {
    ref.invalidate(learnerHomeProvider);
    ref.invalidate(learnerCoursesProvider);
  }
}

final courseActionsProvider = NotifierProvider<CourseActionsController, CourseActionState>(
  CourseActionsController.new,
  isAutoDispose: true,
);
