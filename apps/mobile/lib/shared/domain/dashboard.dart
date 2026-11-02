import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/json.dart';
import 'live_class.dart';

part 'dashboard.freezed.dart';
part 'dashboard.g.dart';

/// `Kpi.unit` — a count moves in percent, a rate moves in points.
enum KpiUnit {
  @JsonValue('%')
  percent,
  @JsonValue('count')
  count,
  unknown,
}

/// Which way a figure moved.
enum TrendDirection { up, down, flat }

/// A headline number with enough history to say which way it is moving (`Kpi`).
@freezed
abstract class Kpi with _$Kpi {
  const factory Kpi({
    @Default(0) num value,

    /// The same measure one period earlier.
    @Default(0) num previous,

    /// Oldest → newest, for the sparkline.
    @Default(<num>[]) List<num> series,
    @JsonKey(unknownEnumValue: KpiUnit.unknown) @Default(KpiUnit.count) KpiUnit unit,
  }) = _Kpi;

  const Kpi._();

  factory Kpi.fromJson(Map<String, dynamic> json) => _$KpiFromJson(json);

  bool get isRate => unit == KpiUnit.percent;
}

/// How a KPI moved, in the unit the measure is read in.
@immutable
class KpiChange {
  const KpiChange({required this.direction, required this.amount, required this.isPoints});

  final TrendDirection direction;

  /// Percent for a count, percentage points for a rate.
  final double amount;

  /// Whether [amount] is points rather than percent.
  final bool isPoints;

  @override
  bool operator ==(Object other) =>
      other is KpiChange &&
      other.direction == direction &&
      other.amount == amount &&
      other.isPoints == isPoints;

  @override
  int get hashCode => Object.hash(direction, amount, isPoints);
}

/// `kpiChange` — ported, not invented. A rate compares in **points**, so 60% → 63% reads +3 pts,
/// not +5%. Nothing here recomputes a KPI: only the difference between two the server sent.
KpiChange kpiChange(Kpi kpi) {
  if (kpi.isRate) {
    final amount = ((kpi.value - kpi.previous) * 10).round() / 10;
    return KpiChange(
      direction: amount > 0
          ? TrendDirection.up
          : amount < 0
          ? TrendDirection.down
          : TrendDirection.flat,
      amount: amount.abs().toDouble(),
      isPoints: true,
    );
  }
  if (kpi.previous == 0) {
    return KpiChange(
      direction: kpi.value > 0 ? TrendDirection.up : TrendDirection.flat,
      amount: kpi.value > 0 ? 100 : 0,
      isPoints: false,
    );
  }
  final percent = (((kpi.value - kpi.previous) / kpi.previous) * 1000).round() / 10;
  return KpiChange(
    direction: percent > 0
        ? TrendDirection.up
        : percent < 0
        ? TrendDirection.down
        : TrendDirection.flat,
    amount: percent.abs().toDouble(),
    isPoints: false,
  );
}

/// One point of a weekly trend. `date` is the period's start, an IST calendar day.
@freezed
abstract class TrendPoint with _$TrendPoint {
  const factory TrendPoint({@Default('') String date, @Default(0) num value}) = _TrendPoint;

  const TrendPoint._();

  factory TrendPoint.fromJson(Map<String, dynamic> json) => _$TrendPointFromJson(json);

  DateTime? get day => DateTime.tryParse(date);
}

/// How one course is doing (`CoursePerformance`).
@freezed
abstract class CoursePerformance with _$CoursePerformance {
  const factory CoursePerformance({
    @Default('') String courseId,
    @Default(0) int enrolled,

    /// Learners who opened the course in the last 14 days.
    @Default(0) int active,
    @Default(0) num completionRate,
    @Default(0) num avgProgress,
    num? rating,

    /// Weekly new enrolments, oldest → newest.
    @Default(<num>[]) List<num> weeklyEnrollments,
  }) = _CoursePerformance;

  factory CoursePerformance.fromJson(Map<String, dynamic> json) =>
      _$CoursePerformanceFromJson(json);
}

/// One day of the academy's learning activity.
@freezed
abstract class ActivityDay with _$ActivityDay {
  const factory ActivityDay({
    @Default('') String date,
    @Default(0) int activeLearners,
    @Default(0) int lessonsCompleted,
  }) = _ActivityDay;

  const ActivityDay._();

  factory ActivityDay.fromJson(Map<String, dynamic> json) => _$ActivityDayFromJson(json);

  DateTime? get day => DateTime.tryParse(date);
}

/// `AttentionKind` — what kind of thing is waiting.
enum AttentionKind {
  reviews,
  @JsonValue('at-risk')
  atRisk,
  @JsonValue('stale-draft')
  staleDraft,
  capacity,
  accessibility,
  unknown,
}

/// How loudly it is asking.
enum AttentionSeverity { high, medium, low, unknown }

/// Something that needs doing, in the academy's own words (`AttentionItem`).
@freezed
abstract class AttentionItem with _$AttentionItem {
  const factory AttentionItem({
    @Default('') String id,
    @JsonKey(unknownEnumValue: AttentionKind.unknown)
    @Default(AttentionKind.unknown)
    AttentionKind kind,
    @Default('') String title,
    @Default('') String detail,
    int? count,
    @JsonKey(unknownEnumValue: AttentionSeverity.unknown)
    @Default(AttentionSeverity.unknown)
    AttentionSeverity severity,

    /// A **web** path, mapped to one of the app's own routes (§5.4).
    @Default('') String to,
  }) = _AttentionItem;

  factory AttentionItem.fromJson(Map<String, dynamic> json) => _$AttentionItemFromJson(json);
}

/// `AdminEventKind`.
enum AdminEventKind {
  enrollment,
  @JsonValue('course-published')
  coursePublished,
  @JsonValue('course-updated')
  courseUpdated,
  submission,
  certificate,
  instructor,
  review,
  @JsonValue('live-scheduled')
  liveScheduled,
  unknown,
}

/// Something that happened in the academy (`AdminEvent`).
@freezed
abstract class AdminEvent with _$AdminEvent {
  const factory AdminEvent({
    @Default('') String id,
    @JsonKey(unknownEnumValue: AdminEventKind.unknown)
    @Default(AdminEventKind.unknown)
    AdminEventKind kind,
    @Default('') String actor,

    /// Completes the sentence after the actor: "published Class 10 Mathematics".
    @Default('') String summary,
    String? context,
    String? courseId,
    @UtcDateTimeConverter() required DateTime at,
    String? to,
  }) = _AdminEvent;

  factory AdminEvent.fromJson(Map<String, dynamic> json) => _$AdminEventFromJson(json);
}

/// Whose figures these are: the whole academy, or one instructor's.
@freezed
abstract class DashboardScope with _$DashboardScope {
  const factory DashboardScope({@Default('academy') String kind, String? instructorId}) =
      _DashboardScope;

  const DashboardScope._();

  factory DashboardScope.fromJson(Map<String, dynamic> json) => _$DashboardScopeFromJson(json);

  bool get isAcademy => kind == 'academy';
}

/// The four figures beside each other, and the four engagement ones.
@freezed
abstract class DashboardKpis with _$DashboardKpis {
  const factory DashboardKpis({
    @Default(Kpi()) Kpi courses,
    @Default(Kpi()) Kpi students,

    /// The academy's active instructors, or the instructor's submissions waiting for review.
    @Default(Kpi()) Kpi third,
    @Default(Kpi()) Kpi completionRate,
  }) = _DashboardKpis;

  factory DashboardKpis.fromJson(Map<String, dynamic> json) => _$DashboardKpisFromJson(json);
}

@freezed
abstract class EngagementKpis with _$EngagementKpis {
  const factory EngagementKpis({
    @Default(Kpi()) Kpi lessonsCompleted,
    @Default(Kpi()) Kpi quizAttempts,
    @Default(Kpi()) Kpi submissions,
    @Default(Kpi()) Kpi liveAttendance,
  }) = _EngagementKpis;

  factory EngagementKpis.fromJson(Map<String, dynamic> json) => _$EngagementKpisFromJson(json);
}

/// `GET /dashboard` — everything the staff dashboard shows, worked out by the server.
@freezed
abstract class DashboardSnapshot with _$DashboardSnapshot {
  const factory DashboardSnapshot({
    @Default(DashboardScope()) DashboardScope scope,
    @UtcDateTimeConverter() required DateTime generatedAt,
    @Default(DashboardKpis()) DashboardKpis kpis,

    /// Weekly new enrolments and completions, twelve weeks, oldest → newest.
    @Default(<TrendPoint>[]) List<TrendPoint> enrollments,
    @Default(<TrendPoint>[]) List<TrendPoint> completions,
    @Default(<CoursePerformance>[]) List<CoursePerformance> courses,

    /// Daily learning activity, twenty-eight days, oldest → newest.
    @Default(<ActivityDay>[]) List<ActivityDay> activity,
    @Default(EngagementKpis()) EngagementKpis engagement,
    @Default(<LiveClass>[]) List<LiveClass> upcomingLive,
    @Default(<AttentionItem>[]) List<AttentionItem> attention,
    @Default(<AdminEvent>[]) List<AdminEvent> events,
  }) = _DashboardSnapshot;

  const DashboardSnapshot._();

  factory DashboardSnapshot.fromJson(Map<String, dynamic> json) =>
      _$DashboardSnapshotFromJson(json);

  /// A new academy with nothing in it yet.
  bool get isEmpty =>
      courses.isEmpty && attention.isEmpty && events.isEmpty && kpis.students.value == 0;
}
