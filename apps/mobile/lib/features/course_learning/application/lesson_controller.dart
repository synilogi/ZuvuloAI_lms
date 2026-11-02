import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_exception.dart';
import '../../learner_home/learner_home.dart';
import '../data/course_learning_api.dart';
import '../data/dto/lesson_view.dart';
import 'course_overview_controller.dart';

/// The lesson models the screens read (§26).
export '../data/dto/lesson_view.dart';

/// Which lesson, of which course.
@immutable
class LessonRef {
  const LessonRef({required this.courseId, required this.lessonId});

  final String courseId;
  final String lessonId;

  @override
  bool operator ==(Object other) =>
      other is LessonRef && other.courseId == courseId && other.lessonId == lessonId;

  @override
  int get hashCode => Object.hash(courseId, lessonId);
}

/// One lesson as the server serves it. Auto-disposed, and deliberately re-read on every visit:
/// reading it is also what records the visit, and the access decision may have changed.
final lessonViewProvider = FutureProvider.family<LessonView, LessonRef>(
  (ref, lesson) => ref
      .watch(courseLearningApiProvider)
      .lesson(courseId: lesson.courseId, lessonId: lesson.lessonId),
  isAutoDispose: true,
);

/// What the player is doing besides showing the lesson.
@immutable
class LessonActionState {
  const LessonActionState({
    this.completing = false,
    this.hint,
    this.moment,
    this.bookmarkedOverride,
    this.failure,
  });

  final bool completing;

  /// The academy's own sentence for why this lesson is not done yet ("Watch at least 90 % …"),
  /// shown where the completion hint goes (§16).
  final String? hint;

  /// The last completion the server confirmed — the only reason a chapter or course moment is
  /// ever shown.
  final CompleteResult? moment;

  /// The bookmark as the app is drawing it, once the server has answered or while it is asked.
  final bool? bookmarkedOverride;

  final AppFailure? failure;

  bool bookmarkedFor(LessonView view) => bookmarkedOverride ?? view.bookmarked;

  LessonActionState clearedOfMoment() =>
      LessonActionState(hint: hint, bookmarkedOverride: bookmarkedOverride);
}

/// Completing, bookmarking and reporting how far a video has been watched. Every one of these is
/// the server's decision to make; this carries its answer back.
class LessonActionsController extends Notifier<LessonActionState> {
  /// The last position accepted by the server, so a repeat of the same second is not re-sent.
  int? _reportedSec;

  @override
  LessonActionState build() => const LessonActionState();

  /// Asks the server to complete the lesson. A 409 is not an error to apologise for — it is the
  /// academy saying what is still missing, so it becomes the hint under the button.
  Future<CompleteResult?> complete(LessonRef lesson) async {
    if (state.completing) return null;
    state = LessonActionState(bookmarkedOverride: state.bookmarkedOverride, completing: true);
    try {
      final result = await ref
          .read(courseLearningApiProvider)
          .complete(courseId: lesson.courseId, lessonId: lesson.lessonId);
      state = LessonActionState(bookmarkedOverride: state.bookmarkedOverride, moment: result);
      _afterProgress(lesson);
      return result;
    } on ApiException catch (e) {
      final failure = e.failure;
      state = LessonActionState(
        bookmarkedOverride: state.bookmarkedOverride,
        hint: failure is ConflictFailure ? failure.message : null,
        failure: failure is ConflictFailure ? null : failure,
      );
      return null;
    }
  }

  /// Reports a watched position. Nothing here decides completion — the server may complete the
  /// lesson itself once the academy's threshold is reached, which the next read reflects.
  Future<void> reportPosition(
    LessonRef lesson, {
    required int positionSec,
    required double fraction,
  }) async {
    if (_reportedSec == positionSec) return;
    final api = ref.read(courseLearningApiProvider);
    Future<void> send() => api.reportPosition(
      courseId: lesson.courseId,
      lessonId: lesson.lessonId,
      positionSec: positionSec,
      fraction: fraction,
    );
    try {
      await send();
      _reportedSec = positionSec;
    } on ApiException catch (e) {
      // A position is worth one retry and nothing more: losing one costs a few seconds of
      // progress, and the player will report again shortly (§17).
      if (e.failure is! NetworkFailure) return;
      try {
        await send();
        _reportedSec = positionSec;
      } on ApiException {
        return;
      }
    }
  }

  Future<void> toggleBookmark(LessonRef lesson, {required bool current}) async {
    state = LessonActionState(hint: state.hint, moment: state.moment, bookmarkedOverride: !current);
    try {
      final bookmarked = await ref
          .read(courseLearningApiProvider)
          .toggleBookmark(courseId: lesson.courseId, lessonId: lesson.lessonId);
      state = LessonActionState(hint: state.hint, bookmarkedOverride: bookmarked);
    } on ApiException catch (e) {
      state = LessonActionState(hint: state.hint, bookmarkedOverride: current, failure: e.failure);
    }
  }

  /// The moment has been shown; do not show it again on the next rebuild.
  void momentSeen() => state = state.clearedOfMoment();

  void clearFailure() =>
      state = LessonActionState(hint: state.hint, bookmarkedOverride: state.bookmarkedOverride);

  /// Progress changed, so everything that reads it is read again.
  void _afterProgress(LessonRef lesson) {
    ref.invalidate(lessonViewProvider(lesson));
    ref.invalidate(learnerCourseProvider(lesson.courseId));
    ref.invalidate(learnerHomeProvider);
    ref.invalidate(learnerCoursesProvider);
  }
}

final lessonActionsProvider = NotifierProvider<LessonActionsController, LessonActionState>(
  LessonActionsController.new,
  isAutoDispose: true,
);

enum NoteStatus { idle, saving, saved, failed }

@immutable
class NoteState {
  const NoteState({this.text = '', this.status = NoteStatus.idle, this.savedAt, this.failure});

  final String text;
  final NoteStatus status;

  /// When the server stored it, in its own words.
  final DateTime? savedAt;
  final AppFailure? failure;

  /// The route's own limit.
  static const maxLength = 20000;
}

/// The lesson's notes: typed here, stored on the server. Saved a moment after the typing stops,
/// and on demand — a practice lesson completes on written working, so the note is the work.
class LessonNoteController extends Notifier<NoteState> {
  static const debounce = Duration(milliseconds: 1500);

  Timer? _timer;

  @override
  NoteState build() {
    ref.onDispose(() => _timer?.cancel());
    return const NoteState();
  }

  /// Starts from what the server sent with the lesson.
  void load(String text) {
    _timer?.cancel();
    state = NoteState(text: text);
  }

  void edit(LessonRef lesson, String text) {
    _timer?.cancel();
    state = NoteState(text: text, savedAt: state.savedAt);
    _timer = Timer(debounce, () => unawaited(save(lesson)));
  }

  Future<void> save(LessonRef lesson) async {
    _timer?.cancel();
    final text = state.text;
    if (text.length > NoteState.maxLength) return;
    state = NoteState(text: text, status: NoteStatus.saving, savedAt: state.savedAt);
    try {
      final savedAt = await ref
          .read(courseLearningApiProvider)
          .saveNote(courseId: lesson.courseId, lessonId: lesson.lessonId, text: text);
      // Someone may have typed on while the request was in flight; keep what is on screen.
      state = NoteState(text: state.text, status: NoteStatus.saved, savedAt: savedAt);
    } on ApiException catch (e) {
      state = NoteState(
        text: state.text,
        status: NoteStatus.failed,
        savedAt: state.savedAt,
        failure: e.failure,
      );
    }
  }
}

final lessonNoteProvider = NotifierProvider<LessonNoteController, NoteState>(
  LessonNoteController.new,
  isAutoDispose: true,
);
