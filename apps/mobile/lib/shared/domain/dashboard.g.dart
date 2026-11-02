// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Kpi _$KpiFromJson(Map<String, dynamic> json) => $checkedCreate('_Kpi', json, ($checkedConvert) {
  final val = _Kpi(
    value: $checkedConvert('value', (v) => v as num? ?? 0),
    previous: $checkedConvert('previous', (v) => v as num? ?? 0),
    series: $checkedConvert(
      'series',
      (v) => (v as List<dynamic>?)?.map((e) => e as num).toList() ?? const <num>[],
    ),
    unit: $checkedConvert(
      'unit',
      (v) =>
          $enumDecodeNullable(_$KpiUnitEnumMap, v, unknownValue: KpiUnit.unknown) ?? KpiUnit.count,
    ),
  );
  return val;
});

Map<String, dynamic> _$KpiToJson(_Kpi instance) => <String, dynamic>{
  'value': instance.value,
  'previous': instance.previous,
  'series': instance.series,
  'unit': _$KpiUnitEnumMap[instance.unit]!,
};

const _$KpiUnitEnumMap = {KpiUnit.percent: '%', KpiUnit.count: 'count', KpiUnit.unknown: 'unknown'};

_TrendPoint _$TrendPointFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_TrendPoint', json, ($checkedConvert) {
      final val = _TrendPoint(
        date: $checkedConvert('date', (v) => v as String? ?? ''),
        value: $checkedConvert('value', (v) => v as num? ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$TrendPointToJson(_TrendPoint instance) => <String, dynamic>{
  'date': instance.date,
  'value': instance.value,
};

_CoursePerformance _$CoursePerformanceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_CoursePerformance', json, ($checkedConvert) {
      final val = _CoursePerformance(
        courseId: $checkedConvert('courseId', (v) => v as String? ?? ''),
        enrolled: $checkedConvert('enrolled', (v) => (v as num?)?.toInt() ?? 0),
        active: $checkedConvert('active', (v) => (v as num?)?.toInt() ?? 0),
        completionRate: $checkedConvert('completionRate', (v) => v as num? ?? 0),
        avgProgress: $checkedConvert('avgProgress', (v) => v as num? ?? 0),
        rating: $checkedConvert('rating', (v) => v as num?),
        weeklyEnrollments: $checkedConvert(
          'weeklyEnrollments',
          (v) => (v as List<dynamic>?)?.map((e) => e as num).toList() ?? const <num>[],
        ),
      );
      return val;
    });

Map<String, dynamic> _$CoursePerformanceToJson(_CoursePerformance instance) => <String, dynamic>{
  'courseId': instance.courseId,
  'enrolled': instance.enrolled,
  'active': instance.active,
  'completionRate': instance.completionRate,
  'avgProgress': instance.avgProgress,
  'rating': instance.rating,
  'weeklyEnrollments': instance.weeklyEnrollments,
};

_ActivityDay _$ActivityDayFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ActivityDay', json, ($checkedConvert) {
      final val = _ActivityDay(
        date: $checkedConvert('date', (v) => v as String? ?? ''),
        activeLearners: $checkedConvert('activeLearners', (v) => (v as num?)?.toInt() ?? 0),
        lessonsCompleted: $checkedConvert('lessonsCompleted', (v) => (v as num?)?.toInt() ?? 0),
      );
      return val;
    });

Map<String, dynamic> _$ActivityDayToJson(_ActivityDay instance) => <String, dynamic>{
  'date': instance.date,
  'activeLearners': instance.activeLearners,
  'lessonsCompleted': instance.lessonsCompleted,
};

_AttentionItem _$AttentionItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AttentionItem', json, ($checkedConvert) {
      final val = _AttentionItem(
        id: $checkedConvert('id', (v) => v as String? ?? ''),
        kind: $checkedConvert(
          'kind',
          (v) =>
              $enumDecodeNullable(_$AttentionKindEnumMap, v, unknownValue: AttentionKind.unknown) ??
              AttentionKind.unknown,
        ),
        title: $checkedConvert('title', (v) => v as String? ?? ''),
        detail: $checkedConvert('detail', (v) => v as String? ?? ''),
        count: $checkedConvert('count', (v) => (v as num?)?.toInt()),
        severity: $checkedConvert(
          'severity',
          (v) =>
              $enumDecodeNullable(
                _$AttentionSeverityEnumMap,
                v,
                unknownValue: AttentionSeverity.unknown,
              ) ??
              AttentionSeverity.unknown,
        ),
        to: $checkedConvert('to', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$AttentionItemToJson(_AttentionItem instance) => <String, dynamic>{
  'id': instance.id,
  'kind': _$AttentionKindEnumMap[instance.kind]!,
  'title': instance.title,
  'detail': instance.detail,
  'count': instance.count,
  'severity': _$AttentionSeverityEnumMap[instance.severity]!,
  'to': instance.to,
};

const _$AttentionKindEnumMap = {
  AttentionKind.reviews: 'reviews',
  AttentionKind.atRisk: 'at-risk',
  AttentionKind.staleDraft: 'stale-draft',
  AttentionKind.capacity: 'capacity',
  AttentionKind.accessibility: 'accessibility',
  AttentionKind.unknown: 'unknown',
};

const _$AttentionSeverityEnumMap = {
  AttentionSeverity.high: 'high',
  AttentionSeverity.medium: 'medium',
  AttentionSeverity.low: 'low',
  AttentionSeverity.unknown: 'unknown',
};

_AdminEvent _$AdminEventFromJson(Map<String, dynamic> json) => $checkedCreate('_AdminEvent', json, (
  $checkedConvert,
) {
  final val = _AdminEvent(
    id: $checkedConvert('id', (v) => v as String? ?? ''),
    kind: $checkedConvert(
      'kind',
      (v) =>
          $enumDecodeNullable(_$AdminEventKindEnumMap, v, unknownValue: AdminEventKind.unknown) ??
          AdminEventKind.unknown,
    ),
    actor: $checkedConvert('actor', (v) => v as String? ?? ''),
    summary: $checkedConvert('summary', (v) => v as String? ?? ''),
    context: $checkedConvert('context', (v) => v as String?),
    courseId: $checkedConvert('courseId', (v) => v as String?),
    at: $checkedConvert('at', (v) => const UtcDateTimeConverter().fromJson(v as String)),
    to: $checkedConvert('to', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$AdminEventToJson(_AdminEvent instance) => <String, dynamic>{
  'id': instance.id,
  'kind': _$AdminEventKindEnumMap[instance.kind]!,
  'actor': instance.actor,
  'summary': instance.summary,
  'context': instance.context,
  'courseId': instance.courseId,
  'at': const UtcDateTimeConverter().toJson(instance.at),
  'to': instance.to,
};

const _$AdminEventKindEnumMap = {
  AdminEventKind.enrollment: 'enrollment',
  AdminEventKind.coursePublished: 'course-published',
  AdminEventKind.courseUpdated: 'course-updated',
  AdminEventKind.submission: 'submission',
  AdminEventKind.certificate: 'certificate',
  AdminEventKind.instructor: 'instructor',
  AdminEventKind.review: 'review',
  AdminEventKind.liveScheduled: 'live-scheduled',
  AdminEventKind.unknown: 'unknown',
};

_DashboardScope _$DashboardScopeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_DashboardScope', json, ($checkedConvert) {
      final val = _DashboardScope(
        kind: $checkedConvert('kind', (v) => v as String? ?? 'academy'),
        instructorId: $checkedConvert('instructorId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$DashboardScopeToJson(_DashboardScope instance) => <String, dynamic>{
  'kind': instance.kind,
  'instructorId': instance.instructorId,
};

_DashboardKpis _$DashboardKpisFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_DashboardKpis', json, ($checkedConvert) {
      final val = _DashboardKpis(
        courses: $checkedConvert(
          'courses',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        students: $checkedConvert(
          'students',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        third: $checkedConvert(
          'third',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        completionRate: $checkedConvert(
          'completionRate',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DashboardKpisToJson(_DashboardKpis instance) => <String, dynamic>{
  'courses': instance.courses.toJson(),
  'students': instance.students.toJson(),
  'third': instance.third.toJson(),
  'completionRate': instance.completionRate.toJson(),
};

_EngagementKpis _$EngagementKpisFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_EngagementKpis', json, ($checkedConvert) {
      final val = _EngagementKpis(
        lessonsCompleted: $checkedConvert(
          'lessonsCompleted',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        quizAttempts: $checkedConvert(
          'quizAttempts',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        submissions: $checkedConvert(
          'submissions',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
        liveAttendance: $checkedConvert(
          'liveAttendance',
          (v) => v == null ? const Kpi() : Kpi.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$EngagementKpisToJson(_EngagementKpis instance) => <String, dynamic>{
  'lessonsCompleted': instance.lessonsCompleted.toJson(),
  'quizAttempts': instance.quizAttempts.toJson(),
  'submissions': instance.submissions.toJson(),
  'liveAttendance': instance.liveAttendance.toJson(),
};

_DashboardSnapshot _$DashboardSnapshotFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_DashboardSnapshot',
  json,
  ($checkedConvert) {
    final val = _DashboardSnapshot(
      scope: $checkedConvert(
        'scope',
        (v) =>
            v == null ? const DashboardScope() : DashboardScope.fromJson(v as Map<String, dynamic>),
      ),
      generatedAt: $checkedConvert(
        'generatedAt',
        (v) => const UtcDateTimeConverter().fromJson(v as String),
      ),
      kpis: $checkedConvert(
        'kpis',
        (v) =>
            v == null ? const DashboardKpis() : DashboardKpis.fromJson(v as Map<String, dynamic>),
      ),
      enrollments: $checkedConvert(
        'enrollments',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <TrendPoint>[],
      ),
      completions: $checkedConvert(
        'completions',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <TrendPoint>[],
      ),
      courses: $checkedConvert(
        'courses',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => CoursePerformance.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <CoursePerformance>[],
      ),
      activity: $checkedConvert(
        'activity',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => ActivityDay.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <ActivityDay>[],
      ),
      engagement: $checkedConvert(
        'engagement',
        (v) =>
            v == null ? const EngagementKpis() : EngagementKpis.fromJson(v as Map<String, dynamic>),
      ),
      upcomingLive: $checkedConvert(
        'upcomingLive',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => LiveClass.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <LiveClass>[],
      ),
      attention: $checkedConvert(
        'attention',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => AttentionItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <AttentionItem>[],
      ),
      events: $checkedConvert(
        'events',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => AdminEvent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <AdminEvent>[],
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$DashboardSnapshotToJson(_DashboardSnapshot instance) => <String, dynamic>{
  'scope': instance.scope.toJson(),
  'generatedAt': const UtcDateTimeConverter().toJson(instance.generatedAt),
  'kpis': instance.kpis.toJson(),
  'enrollments': instance.enrollments.map((e) => e.toJson()).toList(),
  'completions': instance.completions.map((e) => e.toJson()).toList(),
  'courses': instance.courses.map((e) => e.toJson()).toList(),
  'activity': instance.activity.map((e) => e.toJson()).toList(),
  'engagement': instance.engagement.toJson(),
  'upcomingLive': instance.upcomingLive.map((e) => e.toJson()).toList(),
  'attention': instance.attention.map((e) => e.toJson()).toList(),
  'events': instance.events.map((e) => e.toJson()).toList(),
};
