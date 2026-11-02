// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'entitlements.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TenantEntitlements {

@JsonKey(unknownEnumValue: SubscriptionState.unknown) SubscriptionState? get status; String? get planVersionId; PlanSummary? get plan;@_FeatureKeysConverter() List<FeatureKey> get features;@_LimitsConverter() Map<LimitKey, int?> get limits;
/// Create a copy of TenantEntitlements
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TenantEntitlementsCopyWith<TenantEntitlements> get copyWith => _$TenantEntitlementsCopyWithImpl<TenantEntitlements>(this as TenantEntitlements, _$identity);

  /// Serializes this TenantEntitlements to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TenantEntitlements&&(identical(other.status, status) || other.status == status)&&(identical(other.planVersionId, planVersionId) || other.planVersionId == planVersionId)&&(identical(other.plan, plan) || other.plan == plan)&&const DeepCollectionEquality().equals(other.features, features)&&const DeepCollectionEquality().equals(other.limits, limits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,planVersionId,plan,const DeepCollectionEquality().hash(features),const DeepCollectionEquality().hash(limits));

@override
String toString() {
  return 'TenantEntitlements(status: $status, planVersionId: $planVersionId, plan: $plan, features: $features, limits: $limits)';
}


}

/// @nodoc
abstract mixin class $TenantEntitlementsCopyWith<$Res>  {
  factory $TenantEntitlementsCopyWith(TenantEntitlements value, $Res Function(TenantEntitlements) _then) = _$TenantEntitlementsCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: SubscriptionState.unknown) SubscriptionState? status, String? planVersionId, PlanSummary? plan,@_FeatureKeysConverter() List<FeatureKey> features,@_LimitsConverter() Map<LimitKey, int?> limits
});


$PlanSummaryCopyWith<$Res>? get plan;

}
/// @nodoc
class _$TenantEntitlementsCopyWithImpl<$Res>
    implements $TenantEntitlementsCopyWith<$Res> {
  _$TenantEntitlementsCopyWithImpl(this._self, this._then);

  final TenantEntitlements _self;
  final $Res Function(TenantEntitlements) _then;

/// Create a copy of TenantEntitlements
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = freezed,Object? planVersionId = freezed,Object? plan = freezed,Object? features = null,Object? limits = null,}) {
  return _then(_self.copyWith(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubscriptionState?,planVersionId: freezed == planVersionId ? _self.planVersionId : planVersionId // ignore: cast_nullable_to_non_nullable
as String?,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PlanSummary?,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as List<FeatureKey>,limits: null == limits ? _self.limits : limits // ignore: cast_nullable_to_non_nullable
as Map<LimitKey, int?>,
  ));
}
/// Create a copy of TenantEntitlements
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanSummaryCopyWith<$Res>? get plan {
    if (_self.plan == null) {
    return null;
  }

  return $PlanSummaryCopyWith<$Res>(_self.plan!, (value) {
    return _then(_self.copyWith(plan: value));
  });
}
}


/// Adds pattern-matching-related methods to [TenantEntitlements].
extension TenantEntitlementsPatterns on TenantEntitlements {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TenantEntitlements value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TenantEntitlements() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TenantEntitlements value)  $default,){
final _that = this;
switch (_that) {
case _TenantEntitlements():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TenantEntitlements value)?  $default,){
final _that = this;
switch (_that) {
case _TenantEntitlements() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: SubscriptionState.unknown)  SubscriptionState? status,  String? planVersionId,  PlanSummary? plan, @_FeatureKeysConverter()  List<FeatureKey> features, @_LimitsConverter()  Map<LimitKey, int?> limits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TenantEntitlements() when $default != null:
return $default(_that.status,_that.planVersionId,_that.plan,_that.features,_that.limits);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: SubscriptionState.unknown)  SubscriptionState? status,  String? planVersionId,  PlanSummary? plan, @_FeatureKeysConverter()  List<FeatureKey> features, @_LimitsConverter()  Map<LimitKey, int?> limits)  $default,) {final _that = this;
switch (_that) {
case _TenantEntitlements():
return $default(_that.status,_that.planVersionId,_that.plan,_that.features,_that.limits);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: SubscriptionState.unknown)  SubscriptionState? status,  String? planVersionId,  PlanSummary? plan, @_FeatureKeysConverter()  List<FeatureKey> features, @_LimitsConverter()  Map<LimitKey, int?> limits)?  $default,) {final _that = this;
switch (_that) {
case _TenantEntitlements() when $default != null:
return $default(_that.status,_that.planVersionId,_that.plan,_that.features,_that.limits);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TenantEntitlements extends TenantEntitlements {
  const _TenantEntitlements({@JsonKey(unknownEnumValue: SubscriptionState.unknown) this.status, this.planVersionId, this.plan, @_FeatureKeysConverter() final  List<FeatureKey> features = const [], @_LimitsConverter() final  Map<LimitKey, int?> limits = const {}}): _features = features,_limits = limits,super._();
  factory _TenantEntitlements.fromJson(Map<String, dynamic> json) => _$TenantEntitlementsFromJson(json);

@override@JsonKey(unknownEnumValue: SubscriptionState.unknown) final  SubscriptionState? status;
@override final  String? planVersionId;
@override final  PlanSummary? plan;
 final  List<FeatureKey> _features;
@override@JsonKey()@_FeatureKeysConverter() List<FeatureKey> get features {
  if (_features is EqualUnmodifiableListView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_features);
}

 final  Map<LimitKey, int?> _limits;
@override@JsonKey()@_LimitsConverter() Map<LimitKey, int?> get limits {
  if (_limits is EqualUnmodifiableMapView) return _limits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_limits);
}


/// Create a copy of TenantEntitlements
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TenantEntitlementsCopyWith<_TenantEntitlements> get copyWith => __$TenantEntitlementsCopyWithImpl<_TenantEntitlements>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TenantEntitlementsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TenantEntitlements&&(identical(other.status, status) || other.status == status)&&(identical(other.planVersionId, planVersionId) || other.planVersionId == planVersionId)&&(identical(other.plan, plan) || other.plan == plan)&&const DeepCollectionEquality().equals(other._features, _features)&&const DeepCollectionEquality().equals(other._limits, _limits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,planVersionId,plan,const DeepCollectionEquality().hash(_features),const DeepCollectionEquality().hash(_limits));

@override
String toString() {
  return 'TenantEntitlements(status: $status, planVersionId: $planVersionId, plan: $plan, features: $features, limits: $limits)';
}


}

/// @nodoc
abstract mixin class _$TenantEntitlementsCopyWith<$Res> implements $TenantEntitlementsCopyWith<$Res> {
  factory _$TenantEntitlementsCopyWith(_TenantEntitlements value, $Res Function(_TenantEntitlements) _then) = __$TenantEntitlementsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: SubscriptionState.unknown) SubscriptionState? status, String? planVersionId, PlanSummary? plan,@_FeatureKeysConverter() List<FeatureKey> features,@_LimitsConverter() Map<LimitKey, int?> limits
});


@override $PlanSummaryCopyWith<$Res>? get plan;

}
/// @nodoc
class __$TenantEntitlementsCopyWithImpl<$Res>
    implements _$TenantEntitlementsCopyWith<$Res> {
  __$TenantEntitlementsCopyWithImpl(this._self, this._then);

  final _TenantEntitlements _self;
  final $Res Function(_TenantEntitlements) _then;

/// Create a copy of TenantEntitlements
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = freezed,Object? planVersionId = freezed,Object? plan = freezed,Object? features = null,Object? limits = null,}) {
  return _then(_TenantEntitlements(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubscriptionState?,planVersionId: freezed == planVersionId ? _self.planVersionId : planVersionId // ignore: cast_nullable_to_non_nullable
as String?,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PlanSummary?,features: null == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as List<FeatureKey>,limits: null == limits ? _self._limits : limits // ignore: cast_nullable_to_non_nullable
as Map<LimitKey, int?>,
  ));
}

/// Create a copy of TenantEntitlements
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanSummaryCopyWith<$Res>? get plan {
    if (_self.plan == null) {
    return null;
  }

  return $PlanSummaryCopyWith<$Res>(_self.plan!, (value) {
    return _then(_self.copyWith(plan: value));
  });
}
}


/// @nodoc
mixin _$PlanSummary {

 String get id; String get code; String get name;
/// Create a copy of PlanSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanSummaryCopyWith<PlanSummary> get copyWith => _$PlanSummaryCopyWithImpl<PlanSummary>(this as PlanSummary, _$identity);

  /// Serializes this PlanSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name);

@override
String toString() {
  return 'PlanSummary(id: $id, code: $code, name: $name)';
}


}

/// @nodoc
abstract mixin class $PlanSummaryCopyWith<$Res>  {
  factory $PlanSummaryCopyWith(PlanSummary value, $Res Function(PlanSummary) _then) = _$PlanSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String code, String name
});




}
/// @nodoc
class _$PlanSummaryCopyWithImpl<$Res>
    implements $PlanSummaryCopyWith<$Res> {
  _$PlanSummaryCopyWithImpl(this._self, this._then);

  final PlanSummary _self;
  final $Res Function(PlanSummary) _then;

/// Create a copy of PlanSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanSummary].
extension PlanSummaryPatterns on PlanSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanSummary value)  $default,){
final _that = this;
switch (_that) {
case _PlanSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PlanSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String code,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanSummary() when $default != null:
return $default(_that.id,_that.code,_that.name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String code,  String name)  $default,) {final _that = this;
switch (_that) {
case _PlanSummary():
return $default(_that.id,_that.code,_that.name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String code,  String name)?  $default,) {final _that = this;
switch (_that) {
case _PlanSummary() when $default != null:
return $default(_that.id,_that.code,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanSummary implements PlanSummary {
  const _PlanSummary({required this.id, required this.code, required this.name});
  factory _PlanSummary.fromJson(Map<String, dynamic> json) => _$PlanSummaryFromJson(json);

@override final  String id;
@override final  String code;
@override final  String name;

/// Create a copy of PlanSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanSummaryCopyWith<_PlanSummary> get copyWith => __$PlanSummaryCopyWithImpl<_PlanSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name);

@override
String toString() {
  return 'PlanSummary(id: $id, code: $code, name: $name)';
}


}

/// @nodoc
abstract mixin class _$PlanSummaryCopyWith<$Res> implements $PlanSummaryCopyWith<$Res> {
  factory _$PlanSummaryCopyWith(_PlanSummary value, $Res Function(_PlanSummary) _then) = __$PlanSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String code, String name
});




}
/// @nodoc
class __$PlanSummaryCopyWithImpl<$Res>
    implements _$PlanSummaryCopyWith<$Res> {
  __$PlanSummaryCopyWithImpl(this._self, this._then);

  final _PlanSummary _self;
  final $Res Function(_PlanSummary) _then;

/// Create a copy of PlanSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,}) {
  return _then(_PlanSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$UsageLine {

@JsonKey(fromJson: LimitKey.parse, toJson: _limitToJson) LimitKey get limit; String get label; int get used;/// The plan's limit: a number, null for unlimited, 0 when no plan is served.
 int? get allowed;/// Room left, or null for unlimited.
 int? get remaining;/// How the figure is measured, in the server's words.
 String get counts;
/// Create a copy of UsageLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UsageLineCopyWith<UsageLine> get copyWith => _$UsageLineCopyWithImpl<UsageLine>(this as UsageLine, _$identity);

  /// Serializes this UsageLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsageLine&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.label, label) || other.label == label)&&(identical(other.used, used) || other.used == used)&&(identical(other.allowed, allowed) || other.allowed == allowed)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.counts, counts) || other.counts == counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,limit,label,used,allowed,remaining,counts);

@override
String toString() {
  return 'UsageLine(limit: $limit, label: $label, used: $used, allowed: $allowed, remaining: $remaining, counts: $counts)';
}


}

/// @nodoc
abstract mixin class $UsageLineCopyWith<$Res>  {
  factory $UsageLineCopyWith(UsageLine value, $Res Function(UsageLine) _then) = _$UsageLineCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: LimitKey.parse, toJson: _limitToJson) LimitKey limit, String label, int used, int? allowed, int? remaining, String counts
});




}
/// @nodoc
class _$UsageLineCopyWithImpl<$Res>
    implements $UsageLineCopyWith<$Res> {
  _$UsageLineCopyWithImpl(this._self, this._then);

  final UsageLine _self;
  final $Res Function(UsageLine) _then;

/// Create a copy of UsageLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? limit = null,Object? label = null,Object? used = null,Object? allowed = freezed,Object? remaining = freezed,Object? counts = null,}) {
  return _then(_self.copyWith(
limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as LimitKey,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,used: null == used ? _self.used : used // ignore: cast_nullable_to_non_nullable
as int,allowed: freezed == allowed ? _self.allowed : allowed // ignore: cast_nullable_to_non_nullable
as int?,remaining: freezed == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int?,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UsageLine].
extension UsageLinePatterns on UsageLine {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UsageLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UsageLine() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UsageLine value)  $default,){
final _that = this;
switch (_that) {
case _UsageLine():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UsageLine value)?  $default,){
final _that = this;
switch (_that) {
case _UsageLine() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: LimitKey.parse, toJson: _limitToJson)  LimitKey limit,  String label,  int used,  int? allowed,  int? remaining,  String counts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UsageLine() when $default != null:
return $default(_that.limit,_that.label,_that.used,_that.allowed,_that.remaining,_that.counts);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: LimitKey.parse, toJson: _limitToJson)  LimitKey limit,  String label,  int used,  int? allowed,  int? remaining,  String counts)  $default,) {final _that = this;
switch (_that) {
case _UsageLine():
return $default(_that.limit,_that.label,_that.used,_that.allowed,_that.remaining,_that.counts);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: LimitKey.parse, toJson: _limitToJson)  LimitKey limit,  String label,  int used,  int? allowed,  int? remaining,  String counts)?  $default,) {final _that = this;
switch (_that) {
case _UsageLine() when $default != null:
return $default(_that.limit,_that.label,_that.used,_that.allowed,_that.remaining,_that.counts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UsageLine extends UsageLine {
  const _UsageLine({@JsonKey(fromJson: LimitKey.parse, toJson: _limitToJson) required this.limit, required this.label, required this.used, this.allowed, this.remaining, this.counts = ''}): super._();
  factory _UsageLine.fromJson(Map<String, dynamic> json) => _$UsageLineFromJson(json);

@override@JsonKey(fromJson: LimitKey.parse, toJson: _limitToJson) final  LimitKey limit;
@override final  String label;
@override final  int used;
/// The plan's limit: a number, null for unlimited, 0 when no plan is served.
@override final  int? allowed;
/// Room left, or null for unlimited.
@override final  int? remaining;
/// How the figure is measured, in the server's words.
@override@JsonKey() final  String counts;

/// Create a copy of UsageLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UsageLineCopyWith<_UsageLine> get copyWith => __$UsageLineCopyWithImpl<_UsageLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UsageLineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UsageLine&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.label, label) || other.label == label)&&(identical(other.used, used) || other.used == used)&&(identical(other.allowed, allowed) || other.allowed == allowed)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.counts, counts) || other.counts == counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,limit,label,used,allowed,remaining,counts);

@override
String toString() {
  return 'UsageLine(limit: $limit, label: $label, used: $used, allowed: $allowed, remaining: $remaining, counts: $counts)';
}


}

/// @nodoc
abstract mixin class _$UsageLineCopyWith<$Res> implements $UsageLineCopyWith<$Res> {
  factory _$UsageLineCopyWith(_UsageLine value, $Res Function(_UsageLine) _then) = __$UsageLineCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: LimitKey.parse, toJson: _limitToJson) LimitKey limit, String label, int used, int? allowed, int? remaining, String counts
});




}
/// @nodoc
class __$UsageLineCopyWithImpl<$Res>
    implements _$UsageLineCopyWith<$Res> {
  __$UsageLineCopyWithImpl(this._self, this._then);

  final _UsageLine _self;
  final $Res Function(_UsageLine) _then;

/// Create a copy of UsageLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? limit = null,Object? label = null,Object? used = null,Object? allowed = freezed,Object? remaining = freezed,Object? counts = null,}) {
  return _then(_UsageLine(
limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as LimitKey,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,used: null == used ? _self.used : used // ignore: cast_nullable_to_non_nullable
as int,allowed: freezed == allowed ? _self.allowed : allowed // ignore: cast_nullable_to_non_nullable
as int?,remaining: freezed == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int?,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$UsageSummary {

@JsonKey(unknownEnumValue: SubscriptionState.unknown) SubscriptionState? get status;/// The server's own word for "this academy is served no plan" — never computed here.
 bool get restricted; PlanSummary? get plan; List<UsageLine> get lines;
/// Create a copy of UsageSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UsageSummaryCopyWith<UsageSummary> get copyWith => _$UsageSummaryCopyWithImpl<UsageSummary>(this as UsageSummary, _$identity);

  /// Serializes this UsageSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsageSummary&&(identical(other.status, status) || other.status == status)&&(identical(other.restricted, restricted) || other.restricted == restricted)&&(identical(other.plan, plan) || other.plan == plan)&&const DeepCollectionEquality().equals(other.lines, lines));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,restricted,plan,const DeepCollectionEquality().hash(lines));

@override
String toString() {
  return 'UsageSummary(status: $status, restricted: $restricted, plan: $plan, lines: $lines)';
}


}

/// @nodoc
abstract mixin class $UsageSummaryCopyWith<$Res>  {
  factory $UsageSummaryCopyWith(UsageSummary value, $Res Function(UsageSummary) _then) = _$UsageSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: SubscriptionState.unknown) SubscriptionState? status, bool restricted, PlanSummary? plan, List<UsageLine> lines
});


$PlanSummaryCopyWith<$Res>? get plan;

}
/// @nodoc
class _$UsageSummaryCopyWithImpl<$Res>
    implements $UsageSummaryCopyWith<$Res> {
  _$UsageSummaryCopyWithImpl(this._self, this._then);

  final UsageSummary _self;
  final $Res Function(UsageSummary) _then;

/// Create a copy of UsageSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = freezed,Object? restricted = null,Object? plan = freezed,Object? lines = null,}) {
  return _then(_self.copyWith(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubscriptionState?,restricted: null == restricted ? _self.restricted : restricted // ignore: cast_nullable_to_non_nullable
as bool,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PlanSummary?,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<UsageLine>,
  ));
}
/// Create a copy of UsageSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanSummaryCopyWith<$Res>? get plan {
    if (_self.plan == null) {
    return null;
  }

  return $PlanSummaryCopyWith<$Res>(_self.plan!, (value) {
    return _then(_self.copyWith(plan: value));
  });
}
}


/// Adds pattern-matching-related methods to [UsageSummary].
extension UsageSummaryPatterns on UsageSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UsageSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UsageSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UsageSummary value)  $default,){
final _that = this;
switch (_that) {
case _UsageSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UsageSummary value)?  $default,){
final _that = this;
switch (_that) {
case _UsageSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: SubscriptionState.unknown)  SubscriptionState? status,  bool restricted,  PlanSummary? plan,  List<UsageLine> lines)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UsageSummary() when $default != null:
return $default(_that.status,_that.restricted,_that.plan,_that.lines);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: SubscriptionState.unknown)  SubscriptionState? status,  bool restricted,  PlanSummary? plan,  List<UsageLine> lines)  $default,) {final _that = this;
switch (_that) {
case _UsageSummary():
return $default(_that.status,_that.restricted,_that.plan,_that.lines);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: SubscriptionState.unknown)  SubscriptionState? status,  bool restricted,  PlanSummary? plan,  List<UsageLine> lines)?  $default,) {final _that = this;
switch (_that) {
case _UsageSummary() when $default != null:
return $default(_that.status,_that.restricted,_that.plan,_that.lines);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UsageSummary extends UsageSummary {
  const _UsageSummary({@JsonKey(unknownEnumValue: SubscriptionState.unknown) this.status, this.restricted = false, this.plan, final  List<UsageLine> lines = const []}): _lines = lines,super._();
  factory _UsageSummary.fromJson(Map<String, dynamic> json) => _$UsageSummaryFromJson(json);

@override@JsonKey(unknownEnumValue: SubscriptionState.unknown) final  SubscriptionState? status;
/// The server's own word for "this academy is served no plan" — never computed here.
@override@JsonKey() final  bool restricted;
@override final  PlanSummary? plan;
 final  List<UsageLine> _lines;
@override@JsonKey() List<UsageLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}


/// Create a copy of UsageSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UsageSummaryCopyWith<_UsageSummary> get copyWith => __$UsageSummaryCopyWithImpl<_UsageSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UsageSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UsageSummary&&(identical(other.status, status) || other.status == status)&&(identical(other.restricted, restricted) || other.restricted == restricted)&&(identical(other.plan, plan) || other.plan == plan)&&const DeepCollectionEquality().equals(other._lines, _lines));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,restricted,plan,const DeepCollectionEquality().hash(_lines));

@override
String toString() {
  return 'UsageSummary(status: $status, restricted: $restricted, plan: $plan, lines: $lines)';
}


}

/// @nodoc
abstract mixin class _$UsageSummaryCopyWith<$Res> implements $UsageSummaryCopyWith<$Res> {
  factory _$UsageSummaryCopyWith(_UsageSummary value, $Res Function(_UsageSummary) _then) = __$UsageSummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: SubscriptionState.unknown) SubscriptionState? status, bool restricted, PlanSummary? plan, List<UsageLine> lines
});


@override $PlanSummaryCopyWith<$Res>? get plan;

}
/// @nodoc
class __$UsageSummaryCopyWithImpl<$Res>
    implements _$UsageSummaryCopyWith<$Res> {
  __$UsageSummaryCopyWithImpl(this._self, this._then);

  final _UsageSummary _self;
  final $Res Function(_UsageSummary) _then;

/// Create a copy of UsageSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = freezed,Object? restricted = null,Object? plan = freezed,Object? lines = null,}) {
  return _then(_UsageSummary(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubscriptionState?,restricted: null == restricted ? _self.restricted : restricted // ignore: cast_nullable_to_non_nullable
as bool,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PlanSummary?,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<UsageLine>,
  ));
}

/// Create a copy of UsageSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanSummaryCopyWith<$Res>? get plan {
    if (_self.plan == null) {
    return null;
  }

  return $PlanSummaryCopyWith<$Res>(_self.plan!, (value) {
    return _then(_self.copyWith(plan: value));
  });
}
}


/// @nodoc
mixin _$AcademyPlan {

/// Whether plans are enforced yet (`ENTITLEMENT_ENFORCEMENT`). While not, every module is open.
// The route always sends these five keys; a body without them is not this route's answer, and
// is refused as a contract failure rather than read as "not enforced, never subscribed".
@JsonKey(required: true) bool get enforced;/// The subscription's server status, or `null` when the academy has never subscribed.
@JsonKey(required: true, unknownEnumValue: SubscriptionState.unknown) SubscriptionState? get status;/// No plan is served (never subscribed, paused, ended): nothing new can be added.
@JsonKey(required: true) bool get restricted; PlanSummary? get plan;/// The features the academy is served now.
@JsonKey(required: true)@_FeatureKeysConverter() List<FeatureKey> get features;/// While restricted after a plan ended: the features that plan had, which stay readable.
@JsonKey(required: true)@_FeatureKeysConverter() List<FeatureKey> get lastFeatures;/// Sent only while trialing.
@NullableUtcDateTimeConverter() DateTime? get trialEndsAt;/// Sent only for a live subscription that is not trialing.
@NullableUtcDateTimeConverter() DateTime? get renewsAt;
/// Create a copy of AcademyPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AcademyPlanCopyWith<AcademyPlan> get copyWith => _$AcademyPlanCopyWithImpl<AcademyPlan>(this as AcademyPlan, _$identity);

  /// Serializes this AcademyPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AcademyPlan&&(identical(other.enforced, enforced) || other.enforced == enforced)&&(identical(other.status, status) || other.status == status)&&(identical(other.restricted, restricted) || other.restricted == restricted)&&(identical(other.plan, plan) || other.plan == plan)&&const DeepCollectionEquality().equals(other.features, features)&&const DeepCollectionEquality().equals(other.lastFeatures, lastFeatures)&&(identical(other.trialEndsAt, trialEndsAt) || other.trialEndsAt == trialEndsAt)&&(identical(other.renewsAt, renewsAt) || other.renewsAt == renewsAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enforced,status,restricted,plan,const DeepCollectionEquality().hash(features),const DeepCollectionEquality().hash(lastFeatures),trialEndsAt,renewsAt);

@override
String toString() {
  return 'AcademyPlan(enforced: $enforced, status: $status, restricted: $restricted, plan: $plan, features: $features, lastFeatures: $lastFeatures, trialEndsAt: $trialEndsAt, renewsAt: $renewsAt)';
}


}

/// @nodoc
abstract mixin class $AcademyPlanCopyWith<$Res>  {
  factory $AcademyPlanCopyWith(AcademyPlan value, $Res Function(AcademyPlan) _then) = _$AcademyPlanCopyWithImpl;
@useResult
$Res call({
@JsonKey(required: true) bool enforced,@JsonKey(required: true, unknownEnumValue: SubscriptionState.unknown) SubscriptionState? status,@JsonKey(required: true) bool restricted, PlanSummary? plan,@JsonKey(required: true)@_FeatureKeysConverter() List<FeatureKey> features,@JsonKey(required: true)@_FeatureKeysConverter() List<FeatureKey> lastFeatures,@NullableUtcDateTimeConverter() DateTime? trialEndsAt,@NullableUtcDateTimeConverter() DateTime? renewsAt
});


$PlanSummaryCopyWith<$Res>? get plan;

}
/// @nodoc
class _$AcademyPlanCopyWithImpl<$Res>
    implements $AcademyPlanCopyWith<$Res> {
  _$AcademyPlanCopyWithImpl(this._self, this._then);

  final AcademyPlan _self;
  final $Res Function(AcademyPlan) _then;

/// Create a copy of AcademyPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enforced = null,Object? status = freezed,Object? restricted = null,Object? plan = freezed,Object? features = null,Object? lastFeatures = null,Object? trialEndsAt = freezed,Object? renewsAt = freezed,}) {
  return _then(_self.copyWith(
enforced: null == enforced ? _self.enforced : enforced // ignore: cast_nullable_to_non_nullable
as bool,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubscriptionState?,restricted: null == restricted ? _self.restricted : restricted // ignore: cast_nullable_to_non_nullable
as bool,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PlanSummary?,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as List<FeatureKey>,lastFeatures: null == lastFeatures ? _self.lastFeatures : lastFeatures // ignore: cast_nullable_to_non_nullable
as List<FeatureKey>,trialEndsAt: freezed == trialEndsAt ? _self.trialEndsAt : trialEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,renewsAt: freezed == renewsAt ? _self.renewsAt : renewsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of AcademyPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanSummaryCopyWith<$Res>? get plan {
    if (_self.plan == null) {
    return null;
  }

  return $PlanSummaryCopyWith<$Res>(_self.plan!, (value) {
    return _then(_self.copyWith(plan: value));
  });
}
}


/// Adds pattern-matching-related methods to [AcademyPlan].
extension AcademyPlanPatterns on AcademyPlan {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AcademyPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AcademyPlan() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AcademyPlan value)  $default,){
final _that = this;
switch (_that) {
case _AcademyPlan():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AcademyPlan value)?  $default,){
final _that = this;
switch (_that) {
case _AcademyPlan() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(required: true)  bool enforced, @JsonKey(required: true, unknownEnumValue: SubscriptionState.unknown)  SubscriptionState? status, @JsonKey(required: true)  bool restricted,  PlanSummary? plan, @JsonKey(required: true)@_FeatureKeysConverter()  List<FeatureKey> features, @JsonKey(required: true)@_FeatureKeysConverter()  List<FeatureKey> lastFeatures, @NullableUtcDateTimeConverter()  DateTime? trialEndsAt, @NullableUtcDateTimeConverter()  DateTime? renewsAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AcademyPlan() when $default != null:
return $default(_that.enforced,_that.status,_that.restricted,_that.plan,_that.features,_that.lastFeatures,_that.trialEndsAt,_that.renewsAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(required: true)  bool enforced, @JsonKey(required: true, unknownEnumValue: SubscriptionState.unknown)  SubscriptionState? status, @JsonKey(required: true)  bool restricted,  PlanSummary? plan, @JsonKey(required: true)@_FeatureKeysConverter()  List<FeatureKey> features, @JsonKey(required: true)@_FeatureKeysConverter()  List<FeatureKey> lastFeatures, @NullableUtcDateTimeConverter()  DateTime? trialEndsAt, @NullableUtcDateTimeConverter()  DateTime? renewsAt)  $default,) {final _that = this;
switch (_that) {
case _AcademyPlan():
return $default(_that.enforced,_that.status,_that.restricted,_that.plan,_that.features,_that.lastFeatures,_that.trialEndsAt,_that.renewsAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(required: true)  bool enforced, @JsonKey(required: true, unknownEnumValue: SubscriptionState.unknown)  SubscriptionState? status, @JsonKey(required: true)  bool restricted,  PlanSummary? plan, @JsonKey(required: true)@_FeatureKeysConverter()  List<FeatureKey> features, @JsonKey(required: true)@_FeatureKeysConverter()  List<FeatureKey> lastFeatures, @NullableUtcDateTimeConverter()  DateTime? trialEndsAt, @NullableUtcDateTimeConverter()  DateTime? renewsAt)?  $default,) {final _that = this;
switch (_that) {
case _AcademyPlan() when $default != null:
return $default(_that.enforced,_that.status,_that.restricted,_that.plan,_that.features,_that.lastFeatures,_that.trialEndsAt,_that.renewsAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AcademyPlan extends AcademyPlan {
  const _AcademyPlan({@JsonKey(required: true) this.enforced = false, @JsonKey(required: true, unknownEnumValue: SubscriptionState.unknown) this.status, @JsonKey(required: true) this.restricted = false, this.plan, @JsonKey(required: true)@_FeatureKeysConverter() final  List<FeatureKey> features = const [], @JsonKey(required: true)@_FeatureKeysConverter() final  List<FeatureKey> lastFeatures = const [], @NullableUtcDateTimeConverter() this.trialEndsAt, @NullableUtcDateTimeConverter() this.renewsAt}): _features = features,_lastFeatures = lastFeatures,super._();
  factory _AcademyPlan.fromJson(Map<String, dynamic> json) => _$AcademyPlanFromJson(json);

/// Whether plans are enforced yet (`ENTITLEMENT_ENFORCEMENT`). While not, every module is open.
// The route always sends these five keys; a body without them is not this route's answer, and
// is refused as a contract failure rather than read as "not enforced, never subscribed".
@override@JsonKey(required: true) final  bool enforced;
/// The subscription's server status, or `null` when the academy has never subscribed.
@override@JsonKey(required: true, unknownEnumValue: SubscriptionState.unknown) final  SubscriptionState? status;
/// No plan is served (never subscribed, paused, ended): nothing new can be added.
@override@JsonKey(required: true) final  bool restricted;
@override final  PlanSummary? plan;
/// The features the academy is served now.
 final  List<FeatureKey> _features;
/// The features the academy is served now.
@override@JsonKey(required: true)@_FeatureKeysConverter() List<FeatureKey> get features {
  if (_features is EqualUnmodifiableListView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_features);
}

/// While restricted after a plan ended: the features that plan had, which stay readable.
 final  List<FeatureKey> _lastFeatures;
/// While restricted after a plan ended: the features that plan had, which stay readable.
@override@JsonKey(required: true)@_FeatureKeysConverter() List<FeatureKey> get lastFeatures {
  if (_lastFeatures is EqualUnmodifiableListView) return _lastFeatures;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lastFeatures);
}

/// Sent only while trialing.
@override@NullableUtcDateTimeConverter() final  DateTime? trialEndsAt;
/// Sent only for a live subscription that is not trialing.
@override@NullableUtcDateTimeConverter() final  DateTime? renewsAt;

/// Create a copy of AcademyPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AcademyPlanCopyWith<_AcademyPlan> get copyWith => __$AcademyPlanCopyWithImpl<_AcademyPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AcademyPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AcademyPlan&&(identical(other.enforced, enforced) || other.enforced == enforced)&&(identical(other.status, status) || other.status == status)&&(identical(other.restricted, restricted) || other.restricted == restricted)&&(identical(other.plan, plan) || other.plan == plan)&&const DeepCollectionEquality().equals(other._features, _features)&&const DeepCollectionEquality().equals(other._lastFeatures, _lastFeatures)&&(identical(other.trialEndsAt, trialEndsAt) || other.trialEndsAt == trialEndsAt)&&(identical(other.renewsAt, renewsAt) || other.renewsAt == renewsAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enforced,status,restricted,plan,const DeepCollectionEquality().hash(_features),const DeepCollectionEquality().hash(_lastFeatures),trialEndsAt,renewsAt);

@override
String toString() {
  return 'AcademyPlan(enforced: $enforced, status: $status, restricted: $restricted, plan: $plan, features: $features, lastFeatures: $lastFeatures, trialEndsAt: $trialEndsAt, renewsAt: $renewsAt)';
}


}

/// @nodoc
abstract mixin class _$AcademyPlanCopyWith<$Res> implements $AcademyPlanCopyWith<$Res> {
  factory _$AcademyPlanCopyWith(_AcademyPlan value, $Res Function(_AcademyPlan) _then) = __$AcademyPlanCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(required: true) bool enforced,@JsonKey(required: true, unknownEnumValue: SubscriptionState.unknown) SubscriptionState? status,@JsonKey(required: true) bool restricted, PlanSummary? plan,@JsonKey(required: true)@_FeatureKeysConverter() List<FeatureKey> features,@JsonKey(required: true)@_FeatureKeysConverter() List<FeatureKey> lastFeatures,@NullableUtcDateTimeConverter() DateTime? trialEndsAt,@NullableUtcDateTimeConverter() DateTime? renewsAt
});


@override $PlanSummaryCopyWith<$Res>? get plan;

}
/// @nodoc
class __$AcademyPlanCopyWithImpl<$Res>
    implements _$AcademyPlanCopyWith<$Res> {
  __$AcademyPlanCopyWithImpl(this._self, this._then);

  final _AcademyPlan _self;
  final $Res Function(_AcademyPlan) _then;

/// Create a copy of AcademyPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enforced = null,Object? status = freezed,Object? restricted = null,Object? plan = freezed,Object? features = null,Object? lastFeatures = null,Object? trialEndsAt = freezed,Object? renewsAt = freezed,}) {
  return _then(_AcademyPlan(
enforced: null == enforced ? _self.enforced : enforced // ignore: cast_nullable_to_non_nullable
as bool,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubscriptionState?,restricted: null == restricted ? _self.restricted : restricted // ignore: cast_nullable_to_non_nullable
as bool,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PlanSummary?,features: null == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as List<FeatureKey>,lastFeatures: null == lastFeatures ? _self._lastFeatures : lastFeatures // ignore: cast_nullable_to_non_nullable
as List<FeatureKey>,trialEndsAt: freezed == trialEndsAt ? _self.trialEndsAt : trialEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,renewsAt: freezed == renewsAt ? _self.renewsAt : renewsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of AcademyPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanSummaryCopyWith<$Res>? get plan {
    if (_self.plan == null) {
    return null;
  }

  return $PlanSummaryCopyWith<$Res>(_self.plan!, (value) {
    return _then(_self.copyWith(plan: value));
  });
}
}

// dart format on
