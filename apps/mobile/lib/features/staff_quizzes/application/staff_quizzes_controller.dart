import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dto/staff_quiz.dart';
import '../data/staff_quizzes_api.dart';

/// What the staff quiz screens read (§26).
export '../data/dto/staff_quiz.dart';

/// What the list is showing.
@immutable
class QuizFilter {
  const QuizFilter({this.status = 'all', this.search, this.courseId});

  final String status;
  final String? search;
  final String? courseId;

  QuizFilter copyWith({
    String? status,
    String? search,
    bool clearSearch = false,
    String? courseId,
    bool clearCourse = false,
  }) => QuizFilter(
    status: status ?? this.status,
    search: clearSearch ? null : (search ?? this.search),
    courseId: clearCourse ? null : (courseId ?? this.courseId),
  );

  @override
  bool operator ==(Object other) =>
      other is QuizFilter &&
      other.status == status &&
      other.search == search &&
      other.courseId == courseId;

  @override
  int get hashCode => Object.hash(status, search, courseId);
}

class QuizFilterController extends Notifier<QuizFilter> {
  @override
  QuizFilter build() => const QuizFilter();

  void showStatus(String status) => state = state.copyWith(status: status);

  void searchFor(String? text) => (text == null || text.trim().isEmpty)
      ? state = state.copyWith(clearSearch: true)
      : state = state.copyWith(search: text.trim());

  void inCourse(String? courseId) => courseId == null
      ? state = state.copyWith(clearCourse: true)
      : state = state.copyWith(courseId: courseId);
}

final quizFilterProvider = NotifierProvider<QuizFilterController, QuizFilter>(
  QuizFilterController.new,
  isAutoDispose: true,
);

final staffQuizzesProvider = FutureProvider<StaffQuizPage>((ref) {
  final filter = ref.watch(quizFilterProvider);
  return ref
      .watch(staffQuizzesApiProvider)
      .quizzes(
        search: filter.search,
        courseId: filter.courseId,
        status: filter.status == 'all' ? null : filter.status,
      );
}, isAutoDispose: true);

final staffQuizProvider = FutureProvider.family<StaffQuiz, String>(
  (ref, quizId) => ref.watch(staffQuizzesApiProvider).quiz(quizId),
  isAutoDispose: true,
);

final quizStatsProvider = FutureProvider.family<QuizStats, String>(
  (ref, quizId) => ref.watch(staffQuizzesApiProvider).stats(quizId),
  isAutoDispose: true,
);
