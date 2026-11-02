import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dto/report.dart';
import '../data/staff_reports_api.dart';

/// What the report screens read (§26).
export '../../../shared/domain/dashboard.dart'
    show Kpi, KpiChange, KpiUnit, TrendDirection, kpiChange;
export '../data/dto/report.dart';
export '../data/staff_reports_api.dart' show ReportQuery;

/// How many learners one page of the learner table holds.
const learnerReportPageSize = StaffReportsApi.pageSize;

/// The periods the routes understand, in the order the picker offers them.
const reportRanges = ReportRange.values;

/// What every tab is currently narrowed to. One filter for the whole section, so moving between
/// tabs keeps the period and the course the reader chose.
class ReportFilterController extends Notifier<ReportQuery> {
  @override
  ReportQuery build() => const ReportQuery();

  void overPeriod(ReportRange range) => state = ReportQuery(
    range: range,
    segment: state.segment,
    categoryId: state.categoryId,
    courseId: state.courseId,
    instructorId: state.instructorId,
  );

  void forSegment(LearnerSegment? segment) => state = ReportQuery(
    range: state.range,
    segment: segment == LearnerSegment.all ? null : segment,
    categoryId: state.categoryId,
    courseId: state.courseId,
    instructorId: state.instructorId,
  );

  void inCategory(String? categoryId) => state = ReportQuery(
    range: state.range,
    segment: state.segment,
    categoryId: categoryId,
    courseId: state.courseId,
    instructorId: state.instructorId,
  );

  void inCourse(String? courseId) => state = ReportQuery(
    range: state.range,
    segment: state.segment,
    categoryId: state.categoryId,
    courseId: courseId,
    instructorId: state.instructorId,
  );

  void byInstructor(String? instructorId) => state = ReportQuery(
    range: state.range,
    segment: state.segment,
    categoryId: state.categoryId,
    courseId: state.courseId,
    instructorId: instructorId,
  );

  /// Back to the whole academy over the default period.
  void clear() => state = const ReportQuery();
}

final reportFilterProvider = NotifierProvider<ReportFilterController, ReportQuery>(
  ReportFilterController.new,
  isAutoDispose: true,
);

/// How many filters are narrowing the reports, so a screen can say so under its title.
int narrowedBy(ReportQuery query) => [
  query.segment,
  query.categoryId,
  query.courseId,
  query.instructorId,
].where((f) => f != null).length;

final overviewReportProvider = FutureProvider<OverviewReport>(
  (ref) => ref.watch(staffReportsApiProvider).overview(ref.watch(reportFilterProvider)),
  isAutoDispose: true,
);

final coursesReportProvider = FutureProvider<CoursesReport>(
  (ref) => ref.watch(staffReportsApiProvider).courses(ref.watch(reportFilterProvider)),
  isAutoDispose: true,
);

final courseReportProvider = FutureProvider.family<CourseReport, String>(
  (ref, courseId) =>
      ref.watch(staffReportsApiProvider).course(courseId, ref.watch(reportFilterProvider)),
  isAutoDispose: true,
);

final enrolmentsReportProvider = FutureProvider<EnrolmentsReport>(
  (ref) => ref.watch(staffReportsApiProvider).enrolments(ref.watch(reportFilterProvider)),
  isAutoDispose: true,
);

final instructorsReportProvider = FutureProvider<InstructorsReport>(
  (ref) => ref.watch(staffReportsApiProvider).instructors(ref.watch(reportFilterProvider)),
  isAutoDispose: true,
);

/// How the learner table is ordered and paged. Kept apart from the section's filters so sorting a
/// column does not re-read the other tabs.
@immutable
class LearnerTableView {
  const LearnerTableView({
    this.search,
    this.sortKey = LearnerSortKey.progress,
    this.descending = true,
    this.page = 1,
  });

  final String? search;
  final LearnerSortKey sortKey;
  final bool descending;
  final int page;

  @override
  bool operator ==(Object other) =>
      other is LearnerTableView &&
      other.search == search &&
      other.sortKey == sortKey &&
      other.descending == descending &&
      other.page == page;

  @override
  int get hashCode => Object.hash(search, sortKey, descending, page);
}

class LearnerTableController extends Notifier<LearnerTableView> {
  @override
  LearnerTableView build() => const LearnerTableView();

  void searchFor(String? text) => state = LearnerTableView(
    search: (text == null || text.trim().isEmpty) ? null : text.trim(),
    sortKey: state.sortKey,
    descending: state.descending,
  );

  /// Ordering by a column. Asking for the column already shown turns it around, which is what a
  /// reader expects of a table.
  void sortBy(LearnerSortKey key) => state = LearnerTableView(
    search: state.search,
    sortKey: key,
    // A name reads best A–Z first; every figure reads best highest-first.
    descending: key == state.sortKey ? !state.descending : key != LearnerSortKey.name,
  );

  void showPage(int page) => state = LearnerTableView(
    search: state.search,
    sortKey: state.sortKey,
    descending: state.descending,
    page: page,
  );
}

final learnerTableProvider = NotifierProvider<LearnerTableController, LearnerTableView>(
  LearnerTableController.new,
  isAutoDispose: true,
);

final learnersReportProvider = FutureProvider<LearnersReport>((ref) {
  final table = ref.watch(learnerTableProvider);
  return ref
      .watch(staffReportsApiProvider)
      .learners(
        ref.watch(reportFilterProvider),
        search: table.search,
        sortKey: table.sortKey,
        descending: table.descending,
        page: table.page,
      );
}, isAutoDispose: true);
