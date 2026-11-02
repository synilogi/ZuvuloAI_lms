import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/network/json.dart';

part 'entitlements.freezed.dart';
part 'entitlements.g.dart';

/// What a plan can include (`packages/domain/src/entitlement.ts`). The app displays these; it never
/// decides what a plan grants (§9.3).
enum FeatureKey {
  coursesManage('courses.manage'),
  assessmentsManage('assessments.manage'),
  certificatesManage('certificates.manage'),
  liveClasses('live_classes'),
  reportsBasic('reports.basic'),
  reportsAdvanced('reports.advanced'),
  analyticsAdvanced('analytics.advanced'),
  customBranding('custom_branding'),
  prioritySupport('priority_support'),

  /// A feature added to the catalogue after this build shipped.
  unknown('');

  const FeatureKey(this.wire);

  final String wire;

  static FeatureKey parse(Object? value) =>
      FeatureKey.values.firstWhere((f) => f.wire == value, orElse: () => FeatureKey.unknown);
}

/// The countable limits a plan sets. `null` means unlimited; 0 means none.
enum LimitKey {
  learnersMax('learners.max'),
  instructorsMax('instructors.max'),
  coursesMax('courses.max'),
  storageBytes('storage.bytes'),
  liveClassesMax('live_classes.max'),
  adminAccountsMax('admin_accounts.max'),
  unknown('');

  const LimitKey(this.wire);

  final String wire;

  static LimitKey parse(Object? value) =>
      LimitKey.values.firstWhere((l) => l.wire == value, orElse: () => LimitKey.unknown);
}

/// `SubscriptionState` as `/tenant/subscription*` sends it (snake_case, `packages/domain/src/lifecycle.ts`).
/// `/tenant/billing` uses hyphenated UI values — a different enum in FLUTTER-027 (§9.5).
@JsonEnum(fieldRename: FieldRename.snake)
enum SubscriptionState {
  trialing,
  active,
  @JsonValue('past_due')
  pastDue,
  paused,
  canceling,
  canceled,
  expired,
  unknown,
}

class _FeatureKeysConverter implements JsonConverter<List<FeatureKey>, List<dynamic>?> {
  const _FeatureKeysConverter();

  /// A feature this build does not know grants nothing and cannot be asked about, so it is
  /// dropped rather than kept as `unknown`.
  @override
  List<FeatureKey> fromJson(List<dynamic>? json) => [
    for (final value in json ?? const [])
      if (FeatureKey.parse(value) != FeatureKey.unknown) FeatureKey.parse(value),
  ];

  @override
  List<dynamic> toJson(List<FeatureKey> object) => [for (final key in object) key.wire];
}

class _LimitsConverter implements JsonConverter<Map<LimitKey, int?>, Map<String, dynamic>?> {
  const _LimitsConverter();

  @override
  Map<LimitKey, int?> fromJson(Map<String, dynamic>? json) => {
    for (final entry in (json ?? const {}).entries)
      if (LimitKey.parse(entry.key) != LimitKey.unknown)
        LimitKey.parse(entry.key): (entry.value as num?)?.toInt(),
  };

  @override
  Map<String, dynamic> toJson(Map<LimitKey, int?> object) => {
    for (final entry in object.entries) entry.key.wire: entry.value,
  };
}

/// The plan an academy is served: `GET /tenant/subscription/entitlements` (`lib/entitlements.ts`).
/// `tenantId` is deliberately not modelled — the app never holds one (§8).
@freezed
abstract class TenantEntitlements with _$TenantEntitlements {
  const factory TenantEntitlements({
    @JsonKey(unknownEnumValue: SubscriptionState.unknown) SubscriptionState? status,
    String? planVersionId,
    PlanSummary? plan,
    @_FeatureKeysConverter() @Default([]) List<FeatureKey> features,
    @_LimitsConverter() @Default({}) Map<LimitKey, int?> limits,
  }) = _TenantEntitlements;

  const TenantEntitlements._();

  factory TenantEntitlements.fromJson(Map<String, dynamic> json) =>
      _$TenantEntitlementsFromJson(json);

  /// Whether the academy is served a plan at all. Never inferred from the plan's name (§9.3).
  bool get servesAPlan => planVersionId != null;

  bool includes(FeatureKey feature) => feature != FeatureKey.unknown && features.contains(feature);

  /// The limit the server reported: null for unlimited (or unknown to this build).
  int? limitOf(LimitKey limit) => limits[limit];
}

@freezed
abstract class PlanSummary with _$PlanSummary {
  const factory PlanSummary({required String id, required String code, required String name}) =
      _PlanSummary;

  factory PlanSummary.fromJson(Map<String, dynamic> json) => _$PlanSummaryFromJson(json);
}

/// One row of `GET /tenant/subscription/usage` (`lib/usage.ts` `UsageLine`).
@freezed
abstract class UsageLine with _$UsageLine {
  const factory UsageLine({
    @JsonKey(fromJson: LimitKey.parse, toJson: _limitToJson) required LimitKey limit,
    required String label,
    required int used,

    /// The plan's limit: a number, null for unlimited, 0 when no plan is served.
    int? allowed,

    /// Room left, or null for unlimited.
    int? remaining,

    /// How the figure is measured, in the server's words.
    @Default('') String counts,
  }) = _UsageLine;

  const UsageLine._();

  factory UsageLine.fromJson(Map<String, dynamic> json) => _$UsageLineFromJson(json);

  bool get isUnlimited => allowed == null;

  /// How full the allowance is, for a meter; null when unlimited or unknown.
  double? get fraction {
    final allowance = allowed;
    if (allowance == null || allowance <= 0) return null;
    return (used / allowance).clamp(0.0, 1.0);
  }
}

String _limitToJson(LimitKey key) => key.wire;

/// `GET /tenant/subscription/usage`.
@freezed
abstract class UsageSummary with _$UsageSummary {
  const factory UsageSummary({
    @JsonKey(unknownEnumValue: SubscriptionState.unknown) SubscriptionState? status,

    /// The server's own word for "this academy is served no plan" — never computed here.
    @Default(false) bool restricted,
    PlanSummary? plan,
    @Default([]) List<UsageLine> lines,
  }) = _UsageSummary;

  const UsageSummary._();

  factory UsageSummary.fromJson(Map<String, dynamic> json) => _$UsageSummaryFromJson(json);

  UsageLine? lineFor(LimitKey limit) => lines.where((line) => line.limit == limit).firstOrNull;
}

/// `GET /academy/plan` (`AcademyPlan`, `packages/domain/src/entitlement.ts`;
/// `apps/api/src/routes/academyPlan.ts`) — what the academy's plan lets its staff use, readable by
/// every admin and instructor. It names the plan and its features and never a price, an invoice or a
/// payment: those stay on the admin's billing page. UX only — every refusal is still the server's.
@freezed
abstract class AcademyPlan with _$AcademyPlan {
  const factory AcademyPlan({
    /// Whether plans are enforced yet (`ENTITLEMENT_ENFORCEMENT`). While not, every module is open.
    // The route always sends these five keys; a body without them is not this route's answer, and
    // is refused as a contract failure rather than read as "not enforced, never subscribed".
    @JsonKey(required: true) @Default(false) bool enforced,

    /// The subscription's server status, or `null` when the academy has never subscribed.
    @JsonKey(required: true, unknownEnumValue: SubscriptionState.unknown) SubscriptionState? status,

    /// No plan is served (never subscribed, paused, ended): nothing new can be added.
    @JsonKey(required: true) @Default(false) bool restricted,
    PlanSummary? plan,

    /// The features the academy is served now.
    @JsonKey(required: true) @_FeatureKeysConverter() @Default([]) List<FeatureKey> features,

    /// While restricted after a plan ended: the features that plan had, which stay readable.
    @JsonKey(required: true) @_FeatureKeysConverter() @Default([]) List<FeatureKey> lastFeatures,

    /// Sent only while trialing.
    @NullableUtcDateTimeConverter() DateTime? trialEndsAt,

    /// Sent only for a live subscription that is not trialing.
    @NullableUtcDateTimeConverter() DateTime? renewsAt,
  }) = _AcademyPlan;

  const AcademyPlan._();

  factory AcademyPlan.fromJson(Map<String, dynamic> json) => _$AcademyPlanFromJson(json);

  /// The academy has never had a subscription — the server's `status: null`, never inferred.
  bool get neverSubscribed => status == null;

  /// A brand-new academy on a platform that enforces plans: its admin chooses a plan first.
  bool get needsOnboarding => enforced && neverSubscribed;

  /// Restricted **and** enforced: the academy is actually being refused what a plan would allow.
  bool get restrictionBites => enforced && restricted;

  /// A payment failed and the academy owes it — the server's status, never inferred here.
  bool get pastDue => status == SubscriptionState.pastDue;

  bool get trialing => status == SubscriptionState.trialing;

  /// Whether [feature] is usable now: everything is while plans are not enforced.
  bool includes(FeatureKey feature) =>
      !enforced || (feature != FeatureKey.unknown && features.contains(feature));

  /// Whole days of the trial left at [now], counting a part day as a day — a trial that ends later
  /// today has one day left, and one that has ended has none. `null` when this is not a trial.
  int? trialDaysLeft(DateTime now) {
    final ends = trialEndsAt;
    if (!trialing || ends == null) return null;
    final minutes = ends.difference(now).inMinutes;
    if (minutes <= 0) return 0;
    return (minutes / Duration.minutesPerDay).ceil();
  }
}
