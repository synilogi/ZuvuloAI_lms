import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_path.dart';
import '../../../core/network/json.dart';
import 'dto/report.dart';

/// What every report tab is narrowed by. The instructor filter is an admin's: the route replaces it
/// with the caller's own scope for an instructor, so what the app sends for one is ignored (§7).
@immutable
class ReportQuery {
  const ReportQuery({
    this.range = ReportRange.ninetyDays,
    this.segment,
    this.categoryId,
    this.courseId,
    this.instructorId,
  });

  final ReportRange range;
  final LearnerSegment? segment;
  final String? categoryId;
  final String? courseId;
  final String? instructorId;

  @override
  bool operator ==(Object other) =>
      other is ReportQuery &&
      other.range == range &&
      other.segment == segment &&
      other.categoryId == categoryId &&
      other.courseId == courseId &&
      other.instructorId == instructorId;

  @override
  int get hashCode => Object.hash(range, segment, categoryId, courseId, instructorId);

  /// The query the routes share. `90d` is sent explicitly: it is the route's default, but a report
  /// that says "last 90 days" on screen should ask for exactly that.
  Map<String, Object?> toQuery() => {
    'range': range.wireName,
    if (segment case final segment? when segment != LearnerSegment.unknown)
      'segment': segment.wireName,
    'categoryId': ?categoryId,
    'courseId': ?courseId,
    'instructorId': ?instructorId,
  };
}

/// `apps/api/src/routes/reports.ts` — the academy's analytics. Reading needs `reports.view` and the
/// `reports.basic` feature; the instructor report needs `reports.instructors.view` **and**
/// `reports.advanced`, and the route refuses anyone else (§6).
class StaffReportsApi {
  StaffReportsApi(this._client);

  static const pageSize = 20;

  final ApiClient _client;

  Future<OverviewReport> overview(ReportQuery query) async {
    const endpoint = 'GET /reports/overview';
    final body = await _client.get('/reports/overview', query: query.toQuery());
    return parseResponse(endpoint, body, (b) => OverviewReport.fromJson(asJsonObject(endpoint, b)));
  }

  Future<CoursesReport> courses(ReportQuery query) async {
    const endpoint = 'GET /reports/courses';
    final body = await _client.get('/reports/courses', query: query.toQuery());
    return parseResponse(endpoint, body, (b) => CoursesReport.fromJson(asJsonObject(endpoint, b)));
  }

  /// One course. A draft — or a course outside the caller's scope — is a 404, which the screen shows
  /// as not found rather than as an error to retry (§7).
  Future<CourseReport> course(String courseId, ReportQuery query) async {
    const endpoint = 'GET /reports/courses/:courseId';
    final body = await _client.get(
      ApiPath.of(['reports', 'courses', ApiPath.id(courseId)]),
      query: query.toQuery(),
    );
    return parseResponse(endpoint, body, (b) => CourseReport.fromJson(asJsonObject(endpoint, b)));
  }

  /// The learner table. `sortKey` and `sortDirection` travel as two flat strings, which is what the
  /// route's schema parses — sending an object would be silently dropped.
  Future<LearnersReport> learners(
    ReportQuery query, {
    String? search,
    LearnerSortKey sortKey = LearnerSortKey.progress,
    bool descending = true,
    int page = 1,
  }) async {
    const endpoint = 'GET /reports/learners';
    final body = await _client.get(
      '/reports/learners',
      query: {
        ...query.toQuery(),
        'search': ?search,
        'sortKey': sortKey.wireName,
        'sortDirection': descending ? 'desc' : 'asc',
        'page': page,
        'pageSize': pageSize,
      },
    );
    return parseResponse(endpoint, body, (b) => LearnersReport.fromJson(asJsonObject(endpoint, b)));
  }

  Future<EnrolmentsReport> enrolments(ReportQuery query) async {
    const endpoint = 'GET /reports/enrolments';
    final body = await _client.get('/reports/enrolments', query: query.toQuery());
    return parseResponse(
      endpoint,
      body,
      (b) => EnrolmentsReport.fromJson(asJsonObject(endpoint, b)),
    );
  }

  Future<InstructorsReport> instructors(ReportQuery query) async {
    const endpoint = 'GET /reports/instructors';
    final body = await _client.get('/reports/instructors', query: query.toQuery());
    return parseResponse(
      endpoint,
      body,
      (b) => InstructorsReport.fromJson(asJsonObject(endpoint, b)),
    );
  }
}

final staffReportsApiProvider = Provider<StaffReportsApi>(
  (ref) => StaffReportsApi(ref.watch(apiClientProvider)),
);
