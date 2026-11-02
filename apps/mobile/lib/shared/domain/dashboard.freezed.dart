// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Kpi {

 num get value;/// The same measure one period earlier.
 num get previous;/// Oldest → newest, for the sparkline.
 List<num> get series;@JsonKey(unknownEnumValue: KpiUnit.unknown) KpiUnit get unit;
/// Create a copy of Kpi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KpiCopyWith<Kpi> get copyWith => _$KpiCopyWithImpl<Kpi>(this as Kpi, _$identity);

  /// Serializes this Kpi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Kpi&&(identical(other.value, value) || other.value == value)&&(identical(other.previous, previous) || other.previous == previous)&&const DeepCollectionEquality().equals(other.series, series)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,previous,const DeepCollectionEquality().hash(series),unit);

@override
String toString() {
  return 'Kpi(value: $value, previous: $previous, series: $series, unit: $unit)';
}


}

/// @nodoc
abstract mixin class $KpiCopyWith<$Res>  {
  factory $KpiCopyWith(Kpi value, $Res Function(Kpi) _then) = _$KpiCopyWithImpl;
@useResult
$Res call({
 num value, num previous, List<num> series,@JsonKey(unknownEnumValue: KpiUnit.unknown) KpiUnit unit
});




}
/// @nodoc
class _$KpiCopyWithImpl<$Res>
    implements $KpiCopyWith<$Res> {
  _$KpiCopyWithImpl(this._self, this._then);

  final Kpi _self;
  final $Res Function(Kpi) _then;

/// Create a copy of Kpi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? previous = null,Object? series = null,Object? unit = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,previous: null == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as num,series: null == series ? _self.series : series // ignore: cast_nullable_to_non_nullable
as List<num>,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as KpiUnit,
  ));
}

}


/// Adds pattern-matching-related methods to [Kpi].
extension KpiPatterns on Kpi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Kpi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Kpi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Kpi value)  $default,){
final _that = this;
switch (_that) {
case _Kpi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Kpi value)?  $default,){
final _that = this;
switch (_that) {
case _Kpi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( num value,  num previous,  List<num> series, @JsonKey(unknownEnumValue: KpiUnit.unknown)  KpiUnit unit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Kpi() when $default != null:
return $default(_that.value,_that.previous,_that.series,_that.unit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( num value,  num previous,  List<num> series, @JsonKey(unknownEnumValue: KpiUnit.unknown)  KpiUnit unit)  $default,) {final _that = this;
switch (_that) {
case _Kpi():
return $default(_that.value,_that.previous,_that.series,_that.unit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( num value,  num previous,  List<num> series, @JsonKey(unknownEnumValue: KpiUnit.unknown)  KpiUnit unit)?  $default,) {final _that = this;
switch (_that) {
case _Kpi() when $default != null:
return $default(_that.value,_that.previous,_that.series,_that.unit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Kpi extends Kpi {
  const _Kpi({this.value = 0, this.previous = 0, final  List<num> series = const <num>[], @JsonKey(unknownEnumValue: KpiUnit.unknown) this.unit = KpiUnit.count}): _series = series,super._();
  factory _Kpi.fromJson(Map<String, dynamic> json) => _$KpiFromJson(json);

@override@JsonKey() final  num value;
/// The same measure one period earlier.
@override@JsonKey() final  num previous;
/// Oldest → newest, for the sparkline.
 final  List<num> _series;
/// Oldest → newest, for the sparkline.
@override@JsonKey() List<num> get series {
  if (_series is EqualUnmodifiableListView) return _series;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_series);
}

@override@JsonKey(unknownEnumValue: KpiUnit.unknown) final  KpiUnit unit;

/// Create a copy of Kpi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KpiCopyWith<_Kpi> get copyWith => __$KpiCopyWithImpl<_Kpi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KpiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Kpi&&(identical(other.value, value) || other.value == value)&&(identical(other.previous, previous) || other.previous == previous)&&const DeepCollectionEquality().equals(other._series, _series)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,previous,const DeepCollectionEquality().hash(_series),unit);

@override
String toString() {
  return 'Kpi(value: $value, previous: $previous, series: $series, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$KpiCopyWith<$Res> implements $KpiCopyWith<$Res> {
  factory _$KpiCopyWith(_Kpi value, $Res Function(_Kpi) _then) = __$KpiCopyWithImpl;
@override @useResult
$Res call({
 num value, num previous, List<num> series,@JsonKey(unknownEnumValue: KpiUnit.unknown) KpiUnit unit
});




}
/// @nodoc
class __$KpiCopyWithImpl<$Res>
    implements _$KpiCopyWith<$Res> {
  __$KpiCopyWithImpl(this._self, this._then);

  final _Kpi _self;
  final $Res Function(_Kpi) _then;

/// Create a copy of Kpi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? previous = null,Object? series = null,Object? unit = null,}) {
  return _then(_Kpi(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,previous: null == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as num,series: null == series ? _self._series : series // ignore: cast_nullable_to_non_nullable
as List<num>,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as KpiUnit,
  ));
}


}


/// @nodoc
mixin _$TrendPoint {

 String get date; num get value;
/// Create a copy of TrendPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrendPointCopyWith<TrendPoint> get copyWith => _$TrendPointCopyWithImpl<TrendPoint>(this as TrendPoint, _$identity);

  /// Serializes this TrendPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrendPoint&&(identical(other.date, date) || other.date == date)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,value);

@override
String toString() {
  return 'TrendPoint(date: $date, value: $value)';
}


}

/// @nodoc
abstract mixin class $TrendPointCopyWith<$Res>  {
  factory $TrendPointCopyWith(TrendPoint value, $Res Function(TrendPoint) _then) = _$TrendPointCopyWithImpl;
@useResult
$Res call({
 String date, num value
});




}
/// @nodoc
class _$TrendPointCopyWithImpl<$Res>
    implements $TrendPointCopyWith<$Res> {
  _$TrendPointCopyWithImpl(this._self, this._then);

  final TrendPoint _self;
  final $Res Function(TrendPoint) _then;

/// Create a copy of TrendPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? value = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [TrendPoint].
extension TrendPointPatterns on TrendPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrendPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrendPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrendPoint value)  $default,){
final _that = this;
switch (_that) {
case _TrendPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrendPoint value)?  $default,){
final _that = this;
switch (_that) {
case _TrendPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  num value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrendPoint() when $default != null:
return $default(_that.date,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  num value)  $default,) {final _that = this;
switch (_that) {
case _TrendPoint():
return $default(_that.date,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  num value)?  $default,) {final _that = this;
switch (_that) {
case _TrendPoint() when $default != null:
return $default(_that.date,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrendPoint extends TrendPoint {
  const _TrendPoint({this.date = '', this.value = 0}): super._();
  factory _TrendPoint.fromJson(Map<String, dynamic> json) => _$TrendPointFromJson(json);

@override@JsonKey() final  String date;
@override@JsonKey() final  num value;

/// Create a copy of TrendPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrendPointCopyWith<_TrendPoint> get copyWith => __$TrendPointCopyWithImpl<_TrendPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrendPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrendPoint&&(identical(other.date, date) || other.date == date)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,value);

@override
String toString() {
  return 'TrendPoint(date: $date, value: $value)';
}


}

/// @nodoc
abstract mixin class _$TrendPointCopyWith<$Res> implements $TrendPointCopyWith<$Res> {
  factory _$TrendPointCopyWith(_TrendPoint value, $Res Function(_TrendPoint) _then) = __$TrendPointCopyWithImpl;
@override @useResult
$Res call({
 String date, num value
});




}
/// @nodoc
class __$TrendPointCopyWithImpl<$Res>
    implements _$TrendPointCopyWith<$Res> {
  __$TrendPointCopyWithImpl(this._self, this._then);

  final _TrendPoint _self;
  final $Res Function(_TrendPoint) _then;

/// Create a copy of TrendPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? value = null,}) {
  return _then(_TrendPoint(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}


/// @nodoc
mixin _$CoursePerformance {

 String get courseId; int get enrolled;/// Learners who opened the course in the last 14 days.
 int get active; num get completionRate; num get avgProgress; num? get rating;/// Weekly new enrolments, oldest → newest.
 List<num> get weeklyEnrollments;
/// Create a copy of CoursePerformance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoursePerformanceCopyWith<CoursePerformance> get copyWith => _$CoursePerformanceCopyWithImpl<CoursePerformance>(this as CoursePerformance, _$identity);

  /// Serializes this CoursePerformance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoursePerformance&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.active, active) || other.active == active)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.avgProgress, avgProgress) || other.avgProgress == avgProgress)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.weeklyEnrollments, weeklyEnrollments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseId,enrolled,active,completionRate,avgProgress,rating,const DeepCollectionEquality().hash(weeklyEnrollments));

@override
String toString() {
  return 'CoursePerformance(courseId: $courseId, enrolled: $enrolled, active: $active, completionRate: $completionRate, avgProgress: $avgProgress, rating: $rating, weeklyEnrollments: $weeklyEnrollments)';
}


}

/// @nodoc
abstract mixin class $CoursePerformanceCopyWith<$Res>  {
  factory $CoursePerformanceCopyWith(CoursePerformance value, $Res Function(CoursePerformance) _then) = _$CoursePerformanceCopyWithImpl;
@useResult
$Res call({
 String courseId, int enrolled, int active, num completionRate, num avgProgress, num? rating, List<num> weeklyEnrollments
});




}
/// @nodoc
class _$CoursePerformanceCopyWithImpl<$Res>
    implements $CoursePerformanceCopyWith<$Res> {
  _$CoursePerformanceCopyWithImpl(this._self, this._then);

  final CoursePerformance _self;
  final $Res Function(CoursePerformance) _then;

/// Create a copy of CoursePerformance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? courseId = null,Object? enrolled = null,Object? active = null,Object? completionRate = null,Object? avgProgress = null,Object? rating = freezed,Object? weeklyEnrollments = null,}) {
  return _then(_self.copyWith(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as int,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as num,avgProgress: null == avgProgress ? _self.avgProgress : avgProgress // ignore: cast_nullable_to_non_nullable
as num,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as num?,weeklyEnrollments: null == weeklyEnrollments ? _self.weeklyEnrollments : weeklyEnrollments // ignore: cast_nullable_to_non_nullable
as List<num>,
  ));
}

}


/// Adds pattern-matching-related methods to [CoursePerformance].
extension CoursePerformancePatterns on CoursePerformance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoursePerformance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoursePerformance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoursePerformance value)  $default,){
final _that = this;
switch (_that) {
case _CoursePerformance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoursePerformance value)?  $default,){
final _that = this;
switch (_that) {
case _CoursePerformance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String courseId,  int enrolled,  int active,  num completionRate,  num avgProgress,  num? rating,  List<num> weeklyEnrollments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoursePerformance() when $default != null:
return $default(_that.courseId,_that.enrolled,_that.active,_that.completionRate,_that.avgProgress,_that.rating,_that.weeklyEnrollments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String courseId,  int enrolled,  int active,  num completionRate,  num avgProgress,  num? rating,  List<num> weeklyEnrollments)  $default,) {final _that = this;
switch (_that) {
case _CoursePerformance():
return $default(_that.courseId,_that.enrolled,_that.active,_that.completionRate,_that.avgProgress,_that.rating,_that.weeklyEnrollments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String courseId,  int enrolled,  int active,  num completionRate,  num avgProgress,  num? rating,  List<num> weeklyEnrollments)?  $default,) {final _that = this;
switch (_that) {
case _CoursePerformance() when $default != null:
return $default(_that.courseId,_that.enrolled,_that.active,_that.completionRate,_that.avgProgress,_that.rating,_that.weeklyEnrollments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CoursePerformance implements CoursePerformance {
  const _CoursePerformance({this.courseId = '', this.enrolled = 0, this.active = 0, this.completionRate = 0, this.avgProgress = 0, this.rating, final  List<num> weeklyEnrollments = const <num>[]}): _weeklyEnrollments = weeklyEnrollments;
  factory _CoursePerformance.fromJson(Map<String, dynamic> json) => _$CoursePerformanceFromJson(json);

@override@JsonKey() final  String courseId;
@override@JsonKey() final  int enrolled;
/// Learners who opened the course in the last 14 days.
@override@JsonKey() final  int active;
@override@JsonKey() final  num completionRate;
@override@JsonKey() final  num avgProgress;
@override final  num? rating;
/// Weekly new enrolments, oldest → newest.
 final  List<num> _weeklyEnrollments;
/// Weekly new enrolments, oldest → newest.
@override@JsonKey() List<num> get weeklyEnrollments {
  if (_weeklyEnrollments is EqualUnmodifiableListView) return _weeklyEnrollments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weeklyEnrollments);
}


/// Create a copy of CoursePerformance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoursePerformanceCopyWith<_CoursePerformance> get copyWith => __$CoursePerformanceCopyWithImpl<_CoursePerformance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoursePerformanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoursePerformance&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.active, active) || other.active == active)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.avgProgress, avgProgress) || other.avgProgress == avgProgress)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other._weeklyEnrollments, _weeklyEnrollments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseId,enrolled,active,completionRate,avgProgress,rating,const DeepCollectionEquality().hash(_weeklyEnrollments));

@override
String toString() {
  return 'CoursePerformance(courseId: $courseId, enrolled: $enrolled, active: $active, completionRate: $completionRate, avgProgress: $avgProgress, rating: $rating, weeklyEnrollments: $weeklyEnrollments)';
}


}

/// @nodoc
abstract mixin class _$CoursePerformanceCopyWith<$Res> implements $CoursePerformanceCopyWith<$Res> {
  factory _$CoursePerformanceCopyWith(_CoursePerformance value, $Res Function(_CoursePerformance) _then) = __$CoursePerformanceCopyWithImpl;
@override @useResult
$Res call({
 String courseId, int enrolled, int active, num completionRate, num avgProgress, num? rating, List<num> weeklyEnrollments
});




}
/// @nodoc
class __$CoursePerformanceCopyWithImpl<$Res>
    implements _$CoursePerformanceCopyWith<$Res> {
  __$CoursePerformanceCopyWithImpl(this._self, this._then);

  final _CoursePerformance _self;
  final $Res Function(_CoursePerformance) _then;

/// Create a copy of CoursePerformance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? courseId = null,Object? enrolled = null,Object? active = null,Object? completionRate = null,Object? avgProgress = null,Object? rating = freezed,Object? weeklyEnrollments = null,}) {
  return _then(_CoursePerformance(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as int,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as num,avgProgress: null == avgProgress ? _self.avgProgress : avgProgress // ignore: cast_nullable_to_non_nullable
as num,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as num?,weeklyEnrollments: null == weeklyEnrollments ? _self._weeklyEnrollments : weeklyEnrollments // ignore: cast_nullable_to_non_nullable
as List<num>,
  ));
}


}


/// @nodoc
mixin _$ActivityDay {

 String get date; int get activeLearners; int get lessonsCompleted;
/// Create a copy of ActivityDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityDayCopyWith<ActivityDay> get copyWith => _$ActivityDayCopyWithImpl<ActivityDay>(this as ActivityDay, _$identity);

  /// Serializes this ActivityDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityDay&&(identical(other.date, date) || other.date == date)&&(identical(other.activeLearners, activeLearners) || other.activeLearners == activeLearners)&&(identical(other.lessonsCompleted, lessonsCompleted) || other.lessonsCompleted == lessonsCompleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,activeLearners,lessonsCompleted);

@override
String toString() {
  return 'ActivityDay(date: $date, activeLearners: $activeLearners, lessonsCompleted: $lessonsCompleted)';
}


}

/// @nodoc
abstract mixin class $ActivityDayCopyWith<$Res>  {
  factory $ActivityDayCopyWith(ActivityDay value, $Res Function(ActivityDay) _then) = _$ActivityDayCopyWithImpl;
@useResult
$Res call({
 String date, int activeLearners, int lessonsCompleted
});




}
/// @nodoc
class _$ActivityDayCopyWithImpl<$Res>
    implements $ActivityDayCopyWith<$Res> {
  _$ActivityDayCopyWithImpl(this._self, this._then);

  final ActivityDay _self;
  final $Res Function(ActivityDay) _then;

/// Create a copy of ActivityDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? activeLearners = null,Object? lessonsCompleted = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,activeLearners: null == activeLearners ? _self.activeLearners : activeLearners // ignore: cast_nullable_to_non_nullable
as int,lessonsCompleted: null == lessonsCompleted ? _self.lessonsCompleted : lessonsCompleted // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivityDay].
extension ActivityDayPatterns on ActivityDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityDay value)  $default,){
final _that = this;
switch (_that) {
case _ActivityDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityDay value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  int activeLearners,  int lessonsCompleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityDay() when $default != null:
return $default(_that.date,_that.activeLearners,_that.lessonsCompleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  int activeLearners,  int lessonsCompleted)  $default,) {final _that = this;
switch (_that) {
case _ActivityDay():
return $default(_that.date,_that.activeLearners,_that.lessonsCompleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  int activeLearners,  int lessonsCompleted)?  $default,) {final _that = this;
switch (_that) {
case _ActivityDay() when $default != null:
return $default(_that.date,_that.activeLearners,_that.lessonsCompleted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivityDay extends ActivityDay {
  const _ActivityDay({this.date = '', this.activeLearners = 0, this.lessonsCompleted = 0}): super._();
  factory _ActivityDay.fromJson(Map<String, dynamic> json) => _$ActivityDayFromJson(json);

@override@JsonKey() final  String date;
@override@JsonKey() final  int activeLearners;
@override@JsonKey() final  int lessonsCompleted;

/// Create a copy of ActivityDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityDayCopyWith<_ActivityDay> get copyWith => __$ActivityDayCopyWithImpl<_ActivityDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivityDayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityDay&&(identical(other.date, date) || other.date == date)&&(identical(other.activeLearners, activeLearners) || other.activeLearners == activeLearners)&&(identical(other.lessonsCompleted, lessonsCompleted) || other.lessonsCompleted == lessonsCompleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,activeLearners,lessonsCompleted);

@override
String toString() {
  return 'ActivityDay(date: $date, activeLearners: $activeLearners, lessonsCompleted: $lessonsCompleted)';
}


}

/// @nodoc
abstract mixin class _$ActivityDayCopyWith<$Res> implements $ActivityDayCopyWith<$Res> {
  factory _$ActivityDayCopyWith(_ActivityDay value, $Res Function(_ActivityDay) _then) = __$ActivityDayCopyWithImpl;
@override @useResult
$Res call({
 String date, int activeLearners, int lessonsCompleted
});




}
/// @nodoc
class __$ActivityDayCopyWithImpl<$Res>
    implements _$ActivityDayCopyWith<$Res> {
  __$ActivityDayCopyWithImpl(this._self, this._then);

  final _ActivityDay _self;
  final $Res Function(_ActivityDay) _then;

/// Create a copy of ActivityDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? activeLearners = null,Object? lessonsCompleted = null,}) {
  return _then(_ActivityDay(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,activeLearners: null == activeLearners ? _self.activeLearners : activeLearners // ignore: cast_nullable_to_non_nullable
as int,lessonsCompleted: null == lessonsCompleted ? _self.lessonsCompleted : lessonsCompleted // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AttentionItem {

 String get id;@JsonKey(unknownEnumValue: AttentionKind.unknown) AttentionKind get kind; String get title; String get detail; int? get count;@JsonKey(unknownEnumValue: AttentionSeverity.unknown) AttentionSeverity get severity;/// A **web** path, mapped to one of the app's own routes (§5.4).
 String get to;
/// Create a copy of AttentionItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttentionItemCopyWith<AttentionItem> get copyWith => _$AttentionItemCopyWithImpl<AttentionItem>(this as AttentionItem, _$identity);

  /// Serializes this AttentionItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttentionItem&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.count, count) || other.count == count)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,title,detail,count,severity,to);

@override
String toString() {
  return 'AttentionItem(id: $id, kind: $kind, title: $title, detail: $detail, count: $count, severity: $severity, to: $to)';
}


}

/// @nodoc
abstract mixin class $AttentionItemCopyWith<$Res>  {
  factory $AttentionItemCopyWith(AttentionItem value, $Res Function(AttentionItem) _then) = _$AttentionItemCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: AttentionKind.unknown) AttentionKind kind, String title, String detail, int? count,@JsonKey(unknownEnumValue: AttentionSeverity.unknown) AttentionSeverity severity, String to
});




}
/// @nodoc
class _$AttentionItemCopyWithImpl<$Res>
    implements $AttentionItemCopyWith<$Res> {
  _$AttentionItemCopyWithImpl(this._self, this._then);

  final AttentionItem _self;
  final $Res Function(AttentionItem) _then;

/// Create a copy of AttentionItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? detail = null,Object? count = freezed,Object? severity = null,Object? to = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AttentionKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,count: freezed == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int?,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as AttentionSeverity,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AttentionItem].
extension AttentionItemPatterns on AttentionItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttentionItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttentionItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttentionItem value)  $default,){
final _that = this;
switch (_that) {
case _AttentionItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttentionItem value)?  $default,){
final _that = this;
switch (_that) {
case _AttentionItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: AttentionKind.unknown)  AttentionKind kind,  String title,  String detail,  int? count, @JsonKey(unknownEnumValue: AttentionSeverity.unknown)  AttentionSeverity severity,  String to)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttentionItem() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.detail,_that.count,_that.severity,_that.to);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: AttentionKind.unknown)  AttentionKind kind,  String title,  String detail,  int? count, @JsonKey(unknownEnumValue: AttentionSeverity.unknown)  AttentionSeverity severity,  String to)  $default,) {final _that = this;
switch (_that) {
case _AttentionItem():
return $default(_that.id,_that.kind,_that.title,_that.detail,_that.count,_that.severity,_that.to);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(unknownEnumValue: AttentionKind.unknown)  AttentionKind kind,  String title,  String detail,  int? count, @JsonKey(unknownEnumValue: AttentionSeverity.unknown)  AttentionSeverity severity,  String to)?  $default,) {final _that = this;
switch (_that) {
case _AttentionItem() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.detail,_that.count,_that.severity,_that.to);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttentionItem implements AttentionItem {
  const _AttentionItem({this.id = '', @JsonKey(unknownEnumValue: AttentionKind.unknown) this.kind = AttentionKind.unknown, this.title = '', this.detail = '', this.count, @JsonKey(unknownEnumValue: AttentionSeverity.unknown) this.severity = AttentionSeverity.unknown, this.to = ''});
  factory _AttentionItem.fromJson(Map<String, dynamic> json) => _$AttentionItemFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey(unknownEnumValue: AttentionKind.unknown) final  AttentionKind kind;
@override@JsonKey() final  String title;
@override@JsonKey() final  String detail;
@override final  int? count;
@override@JsonKey(unknownEnumValue: AttentionSeverity.unknown) final  AttentionSeverity severity;
/// A **web** path, mapped to one of the app's own routes (§5.4).
@override@JsonKey() final  String to;

/// Create a copy of AttentionItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttentionItemCopyWith<_AttentionItem> get copyWith => __$AttentionItemCopyWithImpl<_AttentionItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttentionItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttentionItem&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.count, count) || other.count == count)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,title,detail,count,severity,to);

@override
String toString() {
  return 'AttentionItem(id: $id, kind: $kind, title: $title, detail: $detail, count: $count, severity: $severity, to: $to)';
}


}

/// @nodoc
abstract mixin class _$AttentionItemCopyWith<$Res> implements $AttentionItemCopyWith<$Res> {
  factory _$AttentionItemCopyWith(_AttentionItem value, $Res Function(_AttentionItem) _then) = __$AttentionItemCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: AttentionKind.unknown) AttentionKind kind, String title, String detail, int? count,@JsonKey(unknownEnumValue: AttentionSeverity.unknown) AttentionSeverity severity, String to
});




}
/// @nodoc
class __$AttentionItemCopyWithImpl<$Res>
    implements _$AttentionItemCopyWith<$Res> {
  __$AttentionItemCopyWithImpl(this._self, this._then);

  final _AttentionItem _self;
  final $Res Function(_AttentionItem) _then;

/// Create a copy of AttentionItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? detail = null,Object? count = freezed,Object? severity = null,Object? to = null,}) {
  return _then(_AttentionItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AttentionKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,count: freezed == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int?,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as AttentionSeverity,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AdminEvent {

 String get id;@JsonKey(unknownEnumValue: AdminEventKind.unknown) AdminEventKind get kind; String get actor;/// Completes the sentence after the actor: "published Reading the Dasha System".
 String get summary; String? get context; String? get courseId;@UtcDateTimeConverter() DateTime get at; String? get to;
/// Create a copy of AdminEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminEventCopyWith<AdminEvent> get copyWith => _$AdminEventCopyWithImpl<AdminEvent>(this as AdminEvent, _$identity);

  /// Serializes this AdminEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.context, context) || other.context == context)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.at, at) || other.at == at)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,actor,summary,context,courseId,at,to);

@override
String toString() {
  return 'AdminEvent(id: $id, kind: $kind, actor: $actor, summary: $summary, context: $context, courseId: $courseId, at: $at, to: $to)';
}


}

/// @nodoc
abstract mixin class $AdminEventCopyWith<$Res>  {
  factory $AdminEventCopyWith(AdminEvent value, $Res Function(AdminEvent) _then) = _$AdminEventCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: AdminEventKind.unknown) AdminEventKind kind, String actor, String summary, String? context, String? courseId,@UtcDateTimeConverter() DateTime at, String? to
});




}
/// @nodoc
class _$AdminEventCopyWithImpl<$Res>
    implements $AdminEventCopyWith<$Res> {
  _$AdminEventCopyWithImpl(this._self, this._then);

  final AdminEvent _self;
  final $Res Function(AdminEvent) _then;

/// Create a copy of AdminEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? actor = null,Object? summary = null,Object? context = freezed,Object? courseId = freezed,Object? at = null,Object? to = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AdminEventKind,actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,context: freezed == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as String?,courseId: freezed == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String?,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminEvent].
extension AdminEventPatterns on AdminEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminEvent value)  $default,){
final _that = this;
switch (_that) {
case _AdminEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminEvent value)?  $default,){
final _that = this;
switch (_that) {
case _AdminEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: AdminEventKind.unknown)  AdminEventKind kind,  String actor,  String summary,  String? context,  String? courseId, @UtcDateTimeConverter()  DateTime at,  String? to)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminEvent() when $default != null:
return $default(_that.id,_that.kind,_that.actor,_that.summary,_that.context,_that.courseId,_that.at,_that.to);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: AdminEventKind.unknown)  AdminEventKind kind,  String actor,  String summary,  String? context,  String? courseId, @UtcDateTimeConverter()  DateTime at,  String? to)  $default,) {final _that = this;
switch (_that) {
case _AdminEvent():
return $default(_that.id,_that.kind,_that.actor,_that.summary,_that.context,_that.courseId,_that.at,_that.to);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(unknownEnumValue: AdminEventKind.unknown)  AdminEventKind kind,  String actor,  String summary,  String? context,  String? courseId, @UtcDateTimeConverter()  DateTime at,  String? to)?  $default,) {final _that = this;
switch (_that) {
case _AdminEvent() when $default != null:
return $default(_that.id,_that.kind,_that.actor,_that.summary,_that.context,_that.courseId,_that.at,_that.to);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminEvent implements AdminEvent {
  const _AdminEvent({this.id = '', @JsonKey(unknownEnumValue: AdminEventKind.unknown) this.kind = AdminEventKind.unknown, this.actor = '', this.summary = '', this.context, this.courseId, @UtcDateTimeConverter() required this.at, this.to});
  factory _AdminEvent.fromJson(Map<String, dynamic> json) => _$AdminEventFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey(unknownEnumValue: AdminEventKind.unknown) final  AdminEventKind kind;
@override@JsonKey() final  String actor;
/// Completes the sentence after the actor: "published Reading the Dasha System".
@override@JsonKey() final  String summary;
@override final  String? context;
@override final  String? courseId;
@override@UtcDateTimeConverter() final  DateTime at;
@override final  String? to;

/// Create a copy of AdminEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminEventCopyWith<_AdminEvent> get copyWith => __$AdminEventCopyWithImpl<_AdminEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.context, context) || other.context == context)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.at, at) || other.at == at)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,actor,summary,context,courseId,at,to);

@override
String toString() {
  return 'AdminEvent(id: $id, kind: $kind, actor: $actor, summary: $summary, context: $context, courseId: $courseId, at: $at, to: $to)';
}


}

/// @nodoc
abstract mixin class _$AdminEventCopyWith<$Res> implements $AdminEventCopyWith<$Res> {
  factory _$AdminEventCopyWith(_AdminEvent value, $Res Function(_AdminEvent) _then) = __$AdminEventCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: AdminEventKind.unknown) AdminEventKind kind, String actor, String summary, String? context, String? courseId,@UtcDateTimeConverter() DateTime at, String? to
});




}
/// @nodoc
class __$AdminEventCopyWithImpl<$Res>
    implements _$AdminEventCopyWith<$Res> {
  __$AdminEventCopyWithImpl(this._self, this._then);

  final _AdminEvent _self;
  final $Res Function(_AdminEvent) _then;

/// Create a copy of AdminEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? actor = null,Object? summary = null,Object? context = freezed,Object? courseId = freezed,Object? at = null,Object? to = freezed,}) {
  return _then(_AdminEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AdminEventKind,actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,context: freezed == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as String?,courseId: freezed == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String?,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DashboardScope {

 String get kind; String? get instructorId;
/// Create a copy of DashboardScope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardScopeCopyWith<DashboardScope> get copyWith => _$DashboardScopeCopyWithImpl<DashboardScope>(this as DashboardScope, _$identity);

  /// Serializes this DashboardScope to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardScope&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.instructorId, instructorId) || other.instructorId == instructorId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,instructorId);

@override
String toString() {
  return 'DashboardScope(kind: $kind, instructorId: $instructorId)';
}


}

/// @nodoc
abstract mixin class $DashboardScopeCopyWith<$Res>  {
  factory $DashboardScopeCopyWith(DashboardScope value, $Res Function(DashboardScope) _then) = _$DashboardScopeCopyWithImpl;
@useResult
$Res call({
 String kind, String? instructorId
});




}
/// @nodoc
class _$DashboardScopeCopyWithImpl<$Res>
    implements $DashboardScopeCopyWith<$Res> {
  _$DashboardScopeCopyWithImpl(this._self, this._then);

  final DashboardScope _self;
  final $Res Function(DashboardScope) _then;

/// Create a copy of DashboardScope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? instructorId = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,instructorId: freezed == instructorId ? _self.instructorId : instructorId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardScope].
extension DashboardScopePatterns on DashboardScope {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardScope value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardScope() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardScope value)  $default,){
final _that = this;
switch (_that) {
case _DashboardScope():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardScope value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardScope() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String? instructorId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardScope() when $default != null:
return $default(_that.kind,_that.instructorId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String? instructorId)  $default,) {final _that = this;
switch (_that) {
case _DashboardScope():
return $default(_that.kind,_that.instructorId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String? instructorId)?  $default,) {final _that = this;
switch (_that) {
case _DashboardScope() when $default != null:
return $default(_that.kind,_that.instructorId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardScope extends DashboardScope {
  const _DashboardScope({this.kind = 'academy', this.instructorId}): super._();
  factory _DashboardScope.fromJson(Map<String, dynamic> json) => _$DashboardScopeFromJson(json);

@override@JsonKey() final  String kind;
@override final  String? instructorId;

/// Create a copy of DashboardScope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardScopeCopyWith<_DashboardScope> get copyWith => __$DashboardScopeCopyWithImpl<_DashboardScope>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardScopeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardScope&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.instructorId, instructorId) || other.instructorId == instructorId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,instructorId);

@override
String toString() {
  return 'DashboardScope(kind: $kind, instructorId: $instructorId)';
}


}

/// @nodoc
abstract mixin class _$DashboardScopeCopyWith<$Res> implements $DashboardScopeCopyWith<$Res> {
  factory _$DashboardScopeCopyWith(_DashboardScope value, $Res Function(_DashboardScope) _then) = __$DashboardScopeCopyWithImpl;
@override @useResult
$Res call({
 String kind, String? instructorId
});




}
/// @nodoc
class __$DashboardScopeCopyWithImpl<$Res>
    implements _$DashboardScopeCopyWith<$Res> {
  __$DashboardScopeCopyWithImpl(this._self, this._then);

  final _DashboardScope _self;
  final $Res Function(_DashboardScope) _then;

/// Create a copy of DashboardScope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? instructorId = freezed,}) {
  return _then(_DashboardScope(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,instructorId: freezed == instructorId ? _self.instructorId : instructorId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DashboardKpis {

 Kpi get courses; Kpi get students;/// The academy's active instructors, or the instructor's submissions waiting for review.
 Kpi get third; Kpi get completionRate;
/// Create a copy of DashboardKpis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardKpisCopyWith<DashboardKpis> get copyWith => _$DashboardKpisCopyWithImpl<DashboardKpis>(this as DashboardKpis, _$identity);

  /// Serializes this DashboardKpis to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardKpis&&(identical(other.courses, courses) || other.courses == courses)&&(identical(other.students, students) || other.students == students)&&(identical(other.third, third) || other.third == third)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courses,students,third,completionRate);

@override
String toString() {
  return 'DashboardKpis(courses: $courses, students: $students, third: $third, completionRate: $completionRate)';
}


}

/// @nodoc
abstract mixin class $DashboardKpisCopyWith<$Res>  {
  factory $DashboardKpisCopyWith(DashboardKpis value, $Res Function(DashboardKpis) _then) = _$DashboardKpisCopyWithImpl;
@useResult
$Res call({
 Kpi courses, Kpi students, Kpi third, Kpi completionRate
});


$KpiCopyWith<$Res> get courses;$KpiCopyWith<$Res> get students;$KpiCopyWith<$Res> get third;$KpiCopyWith<$Res> get completionRate;

}
/// @nodoc
class _$DashboardKpisCopyWithImpl<$Res>
    implements $DashboardKpisCopyWith<$Res> {
  _$DashboardKpisCopyWithImpl(this._self, this._then);

  final DashboardKpis _self;
  final $Res Function(DashboardKpis) _then;

/// Create a copy of DashboardKpis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? courses = null,Object? students = null,Object? third = null,Object? completionRate = null,}) {
  return _then(_self.copyWith(
courses: null == courses ? _self.courses : courses // ignore: cast_nullable_to_non_nullable
as Kpi,students: null == students ? _self.students : students // ignore: cast_nullable_to_non_nullable
as Kpi,third: null == third ? _self.third : third // ignore: cast_nullable_to_non_nullable
as Kpi,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}
/// Create a copy of DashboardKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get courses {
  
  return $KpiCopyWith<$Res>(_self.courses, (value) {
    return _then(_self.copyWith(courses: value));
  });
}/// Create a copy of DashboardKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get students {
  
  return $KpiCopyWith<$Res>(_self.students, (value) {
    return _then(_self.copyWith(students: value));
  });
}/// Create a copy of DashboardKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get third {
  
  return $KpiCopyWith<$Res>(_self.third, (value) {
    return _then(_self.copyWith(third: value));
  });
}/// Create a copy of DashboardKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get completionRate {
  
  return $KpiCopyWith<$Res>(_self.completionRate, (value) {
    return _then(_self.copyWith(completionRate: value));
  });
}
}


/// Adds pattern-matching-related methods to [DashboardKpis].
extension DashboardKpisPatterns on DashboardKpis {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardKpis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardKpis() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardKpis value)  $default,){
final _that = this;
switch (_that) {
case _DashboardKpis():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardKpis value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardKpis() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Kpi courses,  Kpi students,  Kpi third,  Kpi completionRate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardKpis() when $default != null:
return $default(_that.courses,_that.students,_that.third,_that.completionRate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Kpi courses,  Kpi students,  Kpi third,  Kpi completionRate)  $default,) {final _that = this;
switch (_that) {
case _DashboardKpis():
return $default(_that.courses,_that.students,_that.third,_that.completionRate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Kpi courses,  Kpi students,  Kpi third,  Kpi completionRate)?  $default,) {final _that = this;
switch (_that) {
case _DashboardKpis() when $default != null:
return $default(_that.courses,_that.students,_that.third,_that.completionRate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardKpis implements DashboardKpis {
  const _DashboardKpis({this.courses = const Kpi(), this.students = const Kpi(), this.third = const Kpi(), this.completionRate = const Kpi()});
  factory _DashboardKpis.fromJson(Map<String, dynamic> json) => _$DashboardKpisFromJson(json);

@override@JsonKey() final  Kpi courses;
@override@JsonKey() final  Kpi students;
/// The academy's active instructors, or the instructor's submissions waiting for review.
@override@JsonKey() final  Kpi third;
@override@JsonKey() final  Kpi completionRate;

/// Create a copy of DashboardKpis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardKpisCopyWith<_DashboardKpis> get copyWith => __$DashboardKpisCopyWithImpl<_DashboardKpis>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardKpisToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardKpis&&(identical(other.courses, courses) || other.courses == courses)&&(identical(other.students, students) || other.students == students)&&(identical(other.third, third) || other.third == third)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courses,students,third,completionRate);

@override
String toString() {
  return 'DashboardKpis(courses: $courses, students: $students, third: $third, completionRate: $completionRate)';
}


}

/// @nodoc
abstract mixin class _$DashboardKpisCopyWith<$Res> implements $DashboardKpisCopyWith<$Res> {
  factory _$DashboardKpisCopyWith(_DashboardKpis value, $Res Function(_DashboardKpis) _then) = __$DashboardKpisCopyWithImpl;
@override @useResult
$Res call({
 Kpi courses, Kpi students, Kpi third, Kpi completionRate
});


@override $KpiCopyWith<$Res> get courses;@override $KpiCopyWith<$Res> get students;@override $KpiCopyWith<$Res> get third;@override $KpiCopyWith<$Res> get completionRate;

}
/// @nodoc
class __$DashboardKpisCopyWithImpl<$Res>
    implements _$DashboardKpisCopyWith<$Res> {
  __$DashboardKpisCopyWithImpl(this._self, this._then);

  final _DashboardKpis _self;
  final $Res Function(_DashboardKpis) _then;

/// Create a copy of DashboardKpis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? courses = null,Object? students = null,Object? third = null,Object? completionRate = null,}) {
  return _then(_DashboardKpis(
courses: null == courses ? _self.courses : courses // ignore: cast_nullable_to_non_nullable
as Kpi,students: null == students ? _self.students : students // ignore: cast_nullable_to_non_nullable
as Kpi,third: null == third ? _self.third : third // ignore: cast_nullable_to_non_nullable
as Kpi,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}

/// Create a copy of DashboardKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get courses {
  
  return $KpiCopyWith<$Res>(_self.courses, (value) {
    return _then(_self.copyWith(courses: value));
  });
}/// Create a copy of DashboardKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get students {
  
  return $KpiCopyWith<$Res>(_self.students, (value) {
    return _then(_self.copyWith(students: value));
  });
}/// Create a copy of DashboardKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get third {
  
  return $KpiCopyWith<$Res>(_self.third, (value) {
    return _then(_self.copyWith(third: value));
  });
}/// Create a copy of DashboardKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get completionRate {
  
  return $KpiCopyWith<$Res>(_self.completionRate, (value) {
    return _then(_self.copyWith(completionRate: value));
  });
}
}


/// @nodoc
mixin _$EngagementKpis {

 Kpi get lessonsCompleted; Kpi get quizAttempts; Kpi get submissions; Kpi get liveAttendance;
/// Create a copy of EngagementKpis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EngagementKpisCopyWith<EngagementKpis> get copyWith => _$EngagementKpisCopyWithImpl<EngagementKpis>(this as EngagementKpis, _$identity);

  /// Serializes this EngagementKpis to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EngagementKpis&&(identical(other.lessonsCompleted, lessonsCompleted) || other.lessonsCompleted == lessonsCompleted)&&(identical(other.quizAttempts, quizAttempts) || other.quizAttempts == quizAttempts)&&(identical(other.submissions, submissions) || other.submissions == submissions)&&(identical(other.liveAttendance, liveAttendance) || other.liveAttendance == liveAttendance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lessonsCompleted,quizAttempts,submissions,liveAttendance);

@override
String toString() {
  return 'EngagementKpis(lessonsCompleted: $lessonsCompleted, quizAttempts: $quizAttempts, submissions: $submissions, liveAttendance: $liveAttendance)';
}


}

/// @nodoc
abstract mixin class $EngagementKpisCopyWith<$Res>  {
  factory $EngagementKpisCopyWith(EngagementKpis value, $Res Function(EngagementKpis) _then) = _$EngagementKpisCopyWithImpl;
@useResult
$Res call({
 Kpi lessonsCompleted, Kpi quizAttempts, Kpi submissions, Kpi liveAttendance
});


$KpiCopyWith<$Res> get lessonsCompleted;$KpiCopyWith<$Res> get quizAttempts;$KpiCopyWith<$Res> get submissions;$KpiCopyWith<$Res> get liveAttendance;

}
/// @nodoc
class _$EngagementKpisCopyWithImpl<$Res>
    implements $EngagementKpisCopyWith<$Res> {
  _$EngagementKpisCopyWithImpl(this._self, this._then);

  final EngagementKpis _self;
  final $Res Function(EngagementKpis) _then;

/// Create a copy of EngagementKpis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lessonsCompleted = null,Object? quizAttempts = null,Object? submissions = null,Object? liveAttendance = null,}) {
  return _then(_self.copyWith(
lessonsCompleted: null == lessonsCompleted ? _self.lessonsCompleted : lessonsCompleted // ignore: cast_nullable_to_non_nullable
as Kpi,quizAttempts: null == quizAttempts ? _self.quizAttempts : quizAttempts // ignore: cast_nullable_to_non_nullable
as Kpi,submissions: null == submissions ? _self.submissions : submissions // ignore: cast_nullable_to_non_nullable
as Kpi,liveAttendance: null == liveAttendance ? _self.liveAttendance : liveAttendance // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}
/// Create a copy of EngagementKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get lessonsCompleted {
  
  return $KpiCopyWith<$Res>(_self.lessonsCompleted, (value) {
    return _then(_self.copyWith(lessonsCompleted: value));
  });
}/// Create a copy of EngagementKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get quizAttempts {
  
  return $KpiCopyWith<$Res>(_self.quizAttempts, (value) {
    return _then(_self.copyWith(quizAttempts: value));
  });
}/// Create a copy of EngagementKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get submissions {
  
  return $KpiCopyWith<$Res>(_self.submissions, (value) {
    return _then(_self.copyWith(submissions: value));
  });
}/// Create a copy of EngagementKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get liveAttendance {
  
  return $KpiCopyWith<$Res>(_self.liveAttendance, (value) {
    return _then(_self.copyWith(liveAttendance: value));
  });
}
}


/// Adds pattern-matching-related methods to [EngagementKpis].
extension EngagementKpisPatterns on EngagementKpis {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EngagementKpis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EngagementKpis() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EngagementKpis value)  $default,){
final _that = this;
switch (_that) {
case _EngagementKpis():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EngagementKpis value)?  $default,){
final _that = this;
switch (_that) {
case _EngagementKpis() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Kpi lessonsCompleted,  Kpi quizAttempts,  Kpi submissions,  Kpi liveAttendance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EngagementKpis() when $default != null:
return $default(_that.lessonsCompleted,_that.quizAttempts,_that.submissions,_that.liveAttendance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Kpi lessonsCompleted,  Kpi quizAttempts,  Kpi submissions,  Kpi liveAttendance)  $default,) {final _that = this;
switch (_that) {
case _EngagementKpis():
return $default(_that.lessonsCompleted,_that.quizAttempts,_that.submissions,_that.liveAttendance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Kpi lessonsCompleted,  Kpi quizAttempts,  Kpi submissions,  Kpi liveAttendance)?  $default,) {final _that = this;
switch (_that) {
case _EngagementKpis() when $default != null:
return $default(_that.lessonsCompleted,_that.quizAttempts,_that.submissions,_that.liveAttendance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EngagementKpis implements EngagementKpis {
  const _EngagementKpis({this.lessonsCompleted = const Kpi(), this.quizAttempts = const Kpi(), this.submissions = const Kpi(), this.liveAttendance = const Kpi()});
  factory _EngagementKpis.fromJson(Map<String, dynamic> json) => _$EngagementKpisFromJson(json);

@override@JsonKey() final  Kpi lessonsCompleted;
@override@JsonKey() final  Kpi quizAttempts;
@override@JsonKey() final  Kpi submissions;
@override@JsonKey() final  Kpi liveAttendance;

/// Create a copy of EngagementKpis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EngagementKpisCopyWith<_EngagementKpis> get copyWith => __$EngagementKpisCopyWithImpl<_EngagementKpis>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EngagementKpisToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EngagementKpis&&(identical(other.lessonsCompleted, lessonsCompleted) || other.lessonsCompleted == lessonsCompleted)&&(identical(other.quizAttempts, quizAttempts) || other.quizAttempts == quizAttempts)&&(identical(other.submissions, submissions) || other.submissions == submissions)&&(identical(other.liveAttendance, liveAttendance) || other.liveAttendance == liveAttendance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lessonsCompleted,quizAttempts,submissions,liveAttendance);

@override
String toString() {
  return 'EngagementKpis(lessonsCompleted: $lessonsCompleted, quizAttempts: $quizAttempts, submissions: $submissions, liveAttendance: $liveAttendance)';
}


}

/// @nodoc
abstract mixin class _$EngagementKpisCopyWith<$Res> implements $EngagementKpisCopyWith<$Res> {
  factory _$EngagementKpisCopyWith(_EngagementKpis value, $Res Function(_EngagementKpis) _then) = __$EngagementKpisCopyWithImpl;
@override @useResult
$Res call({
 Kpi lessonsCompleted, Kpi quizAttempts, Kpi submissions, Kpi liveAttendance
});


@override $KpiCopyWith<$Res> get lessonsCompleted;@override $KpiCopyWith<$Res> get quizAttempts;@override $KpiCopyWith<$Res> get submissions;@override $KpiCopyWith<$Res> get liveAttendance;

}
/// @nodoc
class __$EngagementKpisCopyWithImpl<$Res>
    implements _$EngagementKpisCopyWith<$Res> {
  __$EngagementKpisCopyWithImpl(this._self, this._then);

  final _EngagementKpis _self;
  final $Res Function(_EngagementKpis) _then;

/// Create a copy of EngagementKpis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lessonsCompleted = null,Object? quizAttempts = null,Object? submissions = null,Object? liveAttendance = null,}) {
  return _then(_EngagementKpis(
lessonsCompleted: null == lessonsCompleted ? _self.lessonsCompleted : lessonsCompleted // ignore: cast_nullable_to_non_nullable
as Kpi,quizAttempts: null == quizAttempts ? _self.quizAttempts : quizAttempts // ignore: cast_nullable_to_non_nullable
as Kpi,submissions: null == submissions ? _self.submissions : submissions // ignore: cast_nullable_to_non_nullable
as Kpi,liveAttendance: null == liveAttendance ? _self.liveAttendance : liveAttendance // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}

/// Create a copy of EngagementKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get lessonsCompleted {
  
  return $KpiCopyWith<$Res>(_self.lessonsCompleted, (value) {
    return _then(_self.copyWith(lessonsCompleted: value));
  });
}/// Create a copy of EngagementKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get quizAttempts {
  
  return $KpiCopyWith<$Res>(_self.quizAttempts, (value) {
    return _then(_self.copyWith(quizAttempts: value));
  });
}/// Create a copy of EngagementKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get submissions {
  
  return $KpiCopyWith<$Res>(_self.submissions, (value) {
    return _then(_self.copyWith(submissions: value));
  });
}/// Create a copy of EngagementKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get liveAttendance {
  
  return $KpiCopyWith<$Res>(_self.liveAttendance, (value) {
    return _then(_self.copyWith(liveAttendance: value));
  });
}
}


/// @nodoc
mixin _$DashboardSnapshot {

 DashboardScope get scope;@UtcDateTimeConverter() DateTime get generatedAt; DashboardKpis get kpis;/// Weekly new enrolments and completions, twelve weeks, oldest → newest.
 List<TrendPoint> get enrollments; List<TrendPoint> get completions; List<CoursePerformance> get courses;/// Daily learning activity, twenty-eight days, oldest → newest.
 List<ActivityDay> get activity; EngagementKpis get engagement; List<LiveClass> get upcomingLive; List<AttentionItem> get attention; List<AdminEvent> get events;
/// Create a copy of DashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardSnapshotCopyWith<DashboardSnapshot> get copyWith => _$DashboardSnapshotCopyWithImpl<DashboardSnapshot>(this as DashboardSnapshot, _$identity);

  /// Serializes this DashboardSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardSnapshot&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.kpis, kpis) || other.kpis == kpis)&&const DeepCollectionEquality().equals(other.enrollments, enrollments)&&const DeepCollectionEquality().equals(other.completions, completions)&&const DeepCollectionEquality().equals(other.courses, courses)&&const DeepCollectionEquality().equals(other.activity, activity)&&(identical(other.engagement, engagement) || other.engagement == engagement)&&const DeepCollectionEquality().equals(other.upcomingLive, upcomingLive)&&const DeepCollectionEquality().equals(other.attention, attention)&&const DeepCollectionEquality().equals(other.events, events));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,scope,generatedAt,kpis,const DeepCollectionEquality().hash(enrollments),const DeepCollectionEquality().hash(completions),const DeepCollectionEquality().hash(courses),const DeepCollectionEquality().hash(activity),engagement,const DeepCollectionEquality().hash(upcomingLive),const DeepCollectionEquality().hash(attention),const DeepCollectionEquality().hash(events));

@override
String toString() {
  return 'DashboardSnapshot(scope: $scope, generatedAt: $generatedAt, kpis: $kpis, enrollments: $enrollments, completions: $completions, courses: $courses, activity: $activity, engagement: $engagement, upcomingLive: $upcomingLive, attention: $attention, events: $events)';
}


}

/// @nodoc
abstract mixin class $DashboardSnapshotCopyWith<$Res>  {
  factory $DashboardSnapshotCopyWith(DashboardSnapshot value, $Res Function(DashboardSnapshot) _then) = _$DashboardSnapshotCopyWithImpl;
@useResult
$Res call({
 DashboardScope scope,@UtcDateTimeConverter() DateTime generatedAt, DashboardKpis kpis, List<TrendPoint> enrollments, List<TrendPoint> completions, List<CoursePerformance> courses, List<ActivityDay> activity, EngagementKpis engagement, List<LiveClass> upcomingLive, List<AttentionItem> attention, List<AdminEvent> events
});


$DashboardScopeCopyWith<$Res> get scope;$DashboardKpisCopyWith<$Res> get kpis;$EngagementKpisCopyWith<$Res> get engagement;

}
/// @nodoc
class _$DashboardSnapshotCopyWithImpl<$Res>
    implements $DashboardSnapshotCopyWith<$Res> {
  _$DashboardSnapshotCopyWithImpl(this._self, this._then);

  final DashboardSnapshot _self;
  final $Res Function(DashboardSnapshot) _then;

/// Create a copy of DashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scope = null,Object? generatedAt = null,Object? kpis = null,Object? enrollments = null,Object? completions = null,Object? courses = null,Object? activity = null,Object? engagement = null,Object? upcomingLive = null,Object? attention = null,Object? events = null,}) {
  return _then(_self.copyWith(
scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as DashboardScope,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,kpis: null == kpis ? _self.kpis : kpis // ignore: cast_nullable_to_non_nullable
as DashboardKpis,enrollments: null == enrollments ? _self.enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as List<TrendPoint>,completions: null == completions ? _self.completions : completions // ignore: cast_nullable_to_non_nullable
as List<TrendPoint>,courses: null == courses ? _self.courses : courses // ignore: cast_nullable_to_non_nullable
as List<CoursePerformance>,activity: null == activity ? _self.activity : activity // ignore: cast_nullable_to_non_nullable
as List<ActivityDay>,engagement: null == engagement ? _self.engagement : engagement // ignore: cast_nullable_to_non_nullable
as EngagementKpis,upcomingLive: null == upcomingLive ? _self.upcomingLive : upcomingLive // ignore: cast_nullable_to_non_nullable
as List<LiveClass>,attention: null == attention ? _self.attention : attention // ignore: cast_nullable_to_non_nullable
as List<AttentionItem>,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<AdminEvent>,
  ));
}
/// Create a copy of DashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardScopeCopyWith<$Res> get scope {
  
  return $DashboardScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}/// Create a copy of DashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardKpisCopyWith<$Res> get kpis {
  
  return $DashboardKpisCopyWith<$Res>(_self.kpis, (value) {
    return _then(_self.copyWith(kpis: value));
  });
}/// Create a copy of DashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EngagementKpisCopyWith<$Res> get engagement {
  
  return $EngagementKpisCopyWith<$Res>(_self.engagement, (value) {
    return _then(_self.copyWith(engagement: value));
  });
}
}


/// Adds pattern-matching-related methods to [DashboardSnapshot].
extension DashboardSnapshotPatterns on DashboardSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _DashboardSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DashboardScope scope, @UtcDateTimeConverter()  DateTime generatedAt,  DashboardKpis kpis,  List<TrendPoint> enrollments,  List<TrendPoint> completions,  List<CoursePerformance> courses,  List<ActivityDay> activity,  EngagementKpis engagement,  List<LiveClass> upcomingLive,  List<AttentionItem> attention,  List<AdminEvent> events)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardSnapshot() when $default != null:
return $default(_that.scope,_that.generatedAt,_that.kpis,_that.enrollments,_that.completions,_that.courses,_that.activity,_that.engagement,_that.upcomingLive,_that.attention,_that.events);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DashboardScope scope, @UtcDateTimeConverter()  DateTime generatedAt,  DashboardKpis kpis,  List<TrendPoint> enrollments,  List<TrendPoint> completions,  List<CoursePerformance> courses,  List<ActivityDay> activity,  EngagementKpis engagement,  List<LiveClass> upcomingLive,  List<AttentionItem> attention,  List<AdminEvent> events)  $default,) {final _that = this;
switch (_that) {
case _DashboardSnapshot():
return $default(_that.scope,_that.generatedAt,_that.kpis,_that.enrollments,_that.completions,_that.courses,_that.activity,_that.engagement,_that.upcomingLive,_that.attention,_that.events);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DashboardScope scope, @UtcDateTimeConverter()  DateTime generatedAt,  DashboardKpis kpis,  List<TrendPoint> enrollments,  List<TrendPoint> completions,  List<CoursePerformance> courses,  List<ActivityDay> activity,  EngagementKpis engagement,  List<LiveClass> upcomingLive,  List<AttentionItem> attention,  List<AdminEvent> events)?  $default,) {final _that = this;
switch (_that) {
case _DashboardSnapshot() when $default != null:
return $default(_that.scope,_that.generatedAt,_that.kpis,_that.enrollments,_that.completions,_that.courses,_that.activity,_that.engagement,_that.upcomingLive,_that.attention,_that.events);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardSnapshot extends DashboardSnapshot {
  const _DashboardSnapshot({this.scope = const DashboardScope(), @UtcDateTimeConverter() required this.generatedAt, this.kpis = const DashboardKpis(), final  List<TrendPoint> enrollments = const <TrendPoint>[], final  List<TrendPoint> completions = const <TrendPoint>[], final  List<CoursePerformance> courses = const <CoursePerformance>[], final  List<ActivityDay> activity = const <ActivityDay>[], this.engagement = const EngagementKpis(), final  List<LiveClass> upcomingLive = const <LiveClass>[], final  List<AttentionItem> attention = const <AttentionItem>[], final  List<AdminEvent> events = const <AdminEvent>[]}): _enrollments = enrollments,_completions = completions,_courses = courses,_activity = activity,_upcomingLive = upcomingLive,_attention = attention,_events = events,super._();
  factory _DashboardSnapshot.fromJson(Map<String, dynamic> json) => _$DashboardSnapshotFromJson(json);

@override@JsonKey() final  DashboardScope scope;
@override@UtcDateTimeConverter() final  DateTime generatedAt;
@override@JsonKey() final  DashboardKpis kpis;
/// Weekly new enrolments and completions, twelve weeks, oldest → newest.
 final  List<TrendPoint> _enrollments;
/// Weekly new enrolments and completions, twelve weeks, oldest → newest.
@override@JsonKey() List<TrendPoint> get enrollments {
  if (_enrollments is EqualUnmodifiableListView) return _enrollments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_enrollments);
}

 final  List<TrendPoint> _completions;
@override@JsonKey() List<TrendPoint> get completions {
  if (_completions is EqualUnmodifiableListView) return _completions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_completions);
}

 final  List<CoursePerformance> _courses;
@override@JsonKey() List<CoursePerformance> get courses {
  if (_courses is EqualUnmodifiableListView) return _courses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_courses);
}

/// Daily learning activity, twenty-eight days, oldest → newest.
 final  List<ActivityDay> _activity;
/// Daily learning activity, twenty-eight days, oldest → newest.
@override@JsonKey() List<ActivityDay> get activity {
  if (_activity is EqualUnmodifiableListView) return _activity;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activity);
}

@override@JsonKey() final  EngagementKpis engagement;
 final  List<LiveClass> _upcomingLive;
@override@JsonKey() List<LiveClass> get upcomingLive {
  if (_upcomingLive is EqualUnmodifiableListView) return _upcomingLive;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_upcomingLive);
}

 final  List<AttentionItem> _attention;
@override@JsonKey() List<AttentionItem> get attention {
  if (_attention is EqualUnmodifiableListView) return _attention;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attention);
}

 final  List<AdminEvent> _events;
@override@JsonKey() List<AdminEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}


/// Create a copy of DashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardSnapshotCopyWith<_DashboardSnapshot> get copyWith => __$DashboardSnapshotCopyWithImpl<_DashboardSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardSnapshot&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.kpis, kpis) || other.kpis == kpis)&&const DeepCollectionEquality().equals(other._enrollments, _enrollments)&&const DeepCollectionEquality().equals(other._completions, _completions)&&const DeepCollectionEquality().equals(other._courses, _courses)&&const DeepCollectionEquality().equals(other._activity, _activity)&&(identical(other.engagement, engagement) || other.engagement == engagement)&&const DeepCollectionEquality().equals(other._upcomingLive, _upcomingLive)&&const DeepCollectionEquality().equals(other._attention, _attention)&&const DeepCollectionEquality().equals(other._events, _events));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,scope,generatedAt,kpis,const DeepCollectionEquality().hash(_enrollments),const DeepCollectionEquality().hash(_completions),const DeepCollectionEquality().hash(_courses),const DeepCollectionEquality().hash(_activity),engagement,const DeepCollectionEquality().hash(_upcomingLive),const DeepCollectionEquality().hash(_attention),const DeepCollectionEquality().hash(_events));

@override
String toString() {
  return 'DashboardSnapshot(scope: $scope, generatedAt: $generatedAt, kpis: $kpis, enrollments: $enrollments, completions: $completions, courses: $courses, activity: $activity, engagement: $engagement, upcomingLive: $upcomingLive, attention: $attention, events: $events)';
}


}

/// @nodoc
abstract mixin class _$DashboardSnapshotCopyWith<$Res> implements $DashboardSnapshotCopyWith<$Res> {
  factory _$DashboardSnapshotCopyWith(_DashboardSnapshot value, $Res Function(_DashboardSnapshot) _then) = __$DashboardSnapshotCopyWithImpl;
@override @useResult
$Res call({
 DashboardScope scope,@UtcDateTimeConverter() DateTime generatedAt, DashboardKpis kpis, List<TrendPoint> enrollments, List<TrendPoint> completions, List<CoursePerformance> courses, List<ActivityDay> activity, EngagementKpis engagement, List<LiveClass> upcomingLive, List<AttentionItem> attention, List<AdminEvent> events
});


@override $DashboardScopeCopyWith<$Res> get scope;@override $DashboardKpisCopyWith<$Res> get kpis;@override $EngagementKpisCopyWith<$Res> get engagement;

}
/// @nodoc
class __$DashboardSnapshotCopyWithImpl<$Res>
    implements _$DashboardSnapshotCopyWith<$Res> {
  __$DashboardSnapshotCopyWithImpl(this._self, this._then);

  final _DashboardSnapshot _self;
  final $Res Function(_DashboardSnapshot) _then;

/// Create a copy of DashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? scope = null,Object? generatedAt = null,Object? kpis = null,Object? enrollments = null,Object? completions = null,Object? courses = null,Object? activity = null,Object? engagement = null,Object? upcomingLive = null,Object? attention = null,Object? events = null,}) {
  return _then(_DashboardSnapshot(
scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as DashboardScope,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,kpis: null == kpis ? _self.kpis : kpis // ignore: cast_nullable_to_non_nullable
as DashboardKpis,enrollments: null == enrollments ? _self._enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as List<TrendPoint>,completions: null == completions ? _self._completions : completions // ignore: cast_nullable_to_non_nullable
as List<TrendPoint>,courses: null == courses ? _self._courses : courses // ignore: cast_nullable_to_non_nullable
as List<CoursePerformance>,activity: null == activity ? _self._activity : activity // ignore: cast_nullable_to_non_nullable
as List<ActivityDay>,engagement: null == engagement ? _self.engagement : engagement // ignore: cast_nullable_to_non_nullable
as EngagementKpis,upcomingLive: null == upcomingLive ? _self._upcomingLive : upcomingLive // ignore: cast_nullable_to_non_nullable
as List<LiveClass>,attention: null == attention ? _self._attention : attention // ignore: cast_nullable_to_non_nullable
as List<AttentionItem>,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<AdminEvent>,
  ));
}

/// Create a copy of DashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardScopeCopyWith<$Res> get scope {
  
  return $DashboardScopeCopyWith<$Res>(_self.scope, (value) {
    return _then(_self.copyWith(scope: value));
  });
}/// Create a copy of DashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardKpisCopyWith<$Res> get kpis {
  
  return $DashboardKpisCopyWith<$Res>(_self.kpis, (value) {
    return _then(_self.copyWith(kpis: value));
  });
}/// Create a copy of DashboardSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EngagementKpisCopyWith<$Res> get engagement {
  
  return $EngagementKpisCopyWith<$Res>(_self.engagement, (value) {
    return _then(_self.copyWith(engagement: value));
  });
}
}

// dart format on
