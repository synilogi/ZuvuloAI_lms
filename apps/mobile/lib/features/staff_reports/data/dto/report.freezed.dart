// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReportWindow {

@UtcDateTimeConverter() DateTime get from;@UtcDateTimeConverter() DateTime get to;@UtcDateTimeConverter() DateTime get previousFrom;@UtcDateTimeConverter() DateTime get previousTo;
/// Create a copy of ReportWindow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportWindowCopyWith<ReportWindow> get copyWith => _$ReportWindowCopyWithImpl<ReportWindow>(this as ReportWindow, _$identity);

  /// Serializes this ReportWindow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportWindow&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.previousFrom, previousFrom) || other.previousFrom == previousFrom)&&(identical(other.previousTo, previousTo) || other.previousTo == previousTo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,previousFrom,previousTo);

@override
String toString() {
  return 'ReportWindow(from: $from, to: $to, previousFrom: $previousFrom, previousTo: $previousTo)';
}


}

/// @nodoc
abstract mixin class $ReportWindowCopyWith<$Res>  {
  factory $ReportWindowCopyWith(ReportWindow value, $Res Function(ReportWindow) _then) = _$ReportWindowCopyWithImpl;
@useResult
$Res call({
@UtcDateTimeConverter() DateTime from,@UtcDateTimeConverter() DateTime to,@UtcDateTimeConverter() DateTime previousFrom,@UtcDateTimeConverter() DateTime previousTo
});




}
/// @nodoc
class _$ReportWindowCopyWithImpl<$Res>
    implements $ReportWindowCopyWith<$Res> {
  _$ReportWindowCopyWithImpl(this._self, this._then);

  final ReportWindow _self;
  final $Res Function(ReportWindow) _then;

/// Create a copy of ReportWindow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? to = null,Object? previousFrom = null,Object? previousTo = null,}) {
  return _then(_self.copyWith(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime,previousFrom: null == previousFrom ? _self.previousFrom : previousFrom // ignore: cast_nullable_to_non_nullable
as DateTime,previousTo: null == previousTo ? _self.previousTo : previousTo // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ReportWindow].
extension ReportWindowPatterns on ReportWindow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReportWindow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReportWindow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReportWindow value)  $default,){
final _that = this;
switch (_that) {
case _ReportWindow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReportWindow value)?  $default,){
final _that = this;
switch (_that) {
case _ReportWindow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@UtcDateTimeConverter()  DateTime from, @UtcDateTimeConverter()  DateTime to, @UtcDateTimeConverter()  DateTime previousFrom, @UtcDateTimeConverter()  DateTime previousTo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReportWindow() when $default != null:
return $default(_that.from,_that.to,_that.previousFrom,_that.previousTo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@UtcDateTimeConverter()  DateTime from, @UtcDateTimeConverter()  DateTime to, @UtcDateTimeConverter()  DateTime previousFrom, @UtcDateTimeConverter()  DateTime previousTo)  $default,) {final _that = this;
switch (_that) {
case _ReportWindow():
return $default(_that.from,_that.to,_that.previousFrom,_that.previousTo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@UtcDateTimeConverter()  DateTime from, @UtcDateTimeConverter()  DateTime to, @UtcDateTimeConverter()  DateTime previousFrom, @UtcDateTimeConverter()  DateTime previousTo)?  $default,) {final _that = this;
switch (_that) {
case _ReportWindow() when $default != null:
return $default(_that.from,_that.to,_that.previousFrom,_that.previousTo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReportWindow implements ReportWindow {
  const _ReportWindow({@UtcDateTimeConverter() required this.from, @UtcDateTimeConverter() required this.to, @UtcDateTimeConverter() required this.previousFrom, @UtcDateTimeConverter() required this.previousTo});
  factory _ReportWindow.fromJson(Map<String, dynamic> json) => _$ReportWindowFromJson(json);

@override@UtcDateTimeConverter() final  DateTime from;
@override@UtcDateTimeConverter() final  DateTime to;
@override@UtcDateTimeConverter() final  DateTime previousFrom;
@override@UtcDateTimeConverter() final  DateTime previousTo;

/// Create a copy of ReportWindow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportWindowCopyWith<_ReportWindow> get copyWith => __$ReportWindowCopyWithImpl<_ReportWindow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReportWindowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReportWindow&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.previousFrom, previousFrom) || other.previousFrom == previousFrom)&&(identical(other.previousTo, previousTo) || other.previousTo == previousTo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,previousFrom,previousTo);

@override
String toString() {
  return 'ReportWindow(from: $from, to: $to, previousFrom: $previousFrom, previousTo: $previousTo)';
}


}

/// @nodoc
abstract mixin class _$ReportWindowCopyWith<$Res> implements $ReportWindowCopyWith<$Res> {
  factory _$ReportWindowCopyWith(_ReportWindow value, $Res Function(_ReportWindow) _then) = __$ReportWindowCopyWithImpl;
@override @useResult
$Res call({
@UtcDateTimeConverter() DateTime from,@UtcDateTimeConverter() DateTime to,@UtcDateTimeConverter() DateTime previousFrom,@UtcDateTimeConverter() DateTime previousTo
});




}
/// @nodoc
class __$ReportWindowCopyWithImpl<$Res>
    implements _$ReportWindowCopyWith<$Res> {
  __$ReportWindowCopyWithImpl(this._self, this._then);

  final _ReportWindow _self;
  final $Res Function(_ReportWindow) _then;

/// Create a copy of ReportWindow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,Object? previousFrom = null,Object? previousTo = null,}) {
  return _then(_ReportWindow(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime,previousFrom: null == previousFrom ? _self.previousFrom : previousFrom // ignore: cast_nullable_to_non_nullable
as DateTime,previousTo: null == previousTo ? _self.previousTo : previousTo // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$ReportSeriesPoint {

@UtcDateTimeConverter() DateTime get from;@UtcDateTimeConverter() DateTime get to; num get value;
/// Create a copy of ReportSeriesPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportSeriesPointCopyWith<ReportSeriesPoint> get copyWith => _$ReportSeriesPointCopyWithImpl<ReportSeriesPoint>(this as ReportSeriesPoint, _$identity);

  /// Serializes this ReportSeriesPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportSeriesPoint&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,value);

@override
String toString() {
  return 'ReportSeriesPoint(from: $from, to: $to, value: $value)';
}


}

/// @nodoc
abstract mixin class $ReportSeriesPointCopyWith<$Res>  {
  factory $ReportSeriesPointCopyWith(ReportSeriesPoint value, $Res Function(ReportSeriesPoint) _then) = _$ReportSeriesPointCopyWithImpl;
@useResult
$Res call({
@UtcDateTimeConverter() DateTime from,@UtcDateTimeConverter() DateTime to, num value
});




}
/// @nodoc
class _$ReportSeriesPointCopyWithImpl<$Res>
    implements $ReportSeriesPointCopyWith<$Res> {
  _$ReportSeriesPointCopyWithImpl(this._self, this._then);

  final ReportSeriesPoint _self;
  final $Res Function(ReportSeriesPoint) _then;

/// Create a copy of ReportSeriesPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? to = null,Object? value = null,}) {
  return _then(_self.copyWith(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [ReportSeriesPoint].
extension ReportSeriesPointPatterns on ReportSeriesPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReportSeriesPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReportSeriesPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReportSeriesPoint value)  $default,){
final _that = this;
switch (_that) {
case _ReportSeriesPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReportSeriesPoint value)?  $default,){
final _that = this;
switch (_that) {
case _ReportSeriesPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@UtcDateTimeConverter()  DateTime from, @UtcDateTimeConverter()  DateTime to,  num value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReportSeriesPoint() when $default != null:
return $default(_that.from,_that.to,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@UtcDateTimeConverter()  DateTime from, @UtcDateTimeConverter()  DateTime to,  num value)  $default,) {final _that = this;
switch (_that) {
case _ReportSeriesPoint():
return $default(_that.from,_that.to,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@UtcDateTimeConverter()  DateTime from, @UtcDateTimeConverter()  DateTime to,  num value)?  $default,) {final _that = this;
switch (_that) {
case _ReportSeriesPoint() when $default != null:
return $default(_that.from,_that.to,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReportSeriesPoint implements ReportSeriesPoint {
  const _ReportSeriesPoint({@UtcDateTimeConverter() required this.from, @UtcDateTimeConverter() required this.to, this.value = 0});
  factory _ReportSeriesPoint.fromJson(Map<String, dynamic> json) => _$ReportSeriesPointFromJson(json);

@override@UtcDateTimeConverter() final  DateTime from;
@override@UtcDateTimeConverter() final  DateTime to;
@override@JsonKey() final  num value;

/// Create a copy of ReportSeriesPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportSeriesPointCopyWith<_ReportSeriesPoint> get copyWith => __$ReportSeriesPointCopyWithImpl<_ReportSeriesPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReportSeriesPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReportSeriesPoint&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,value);

@override
String toString() {
  return 'ReportSeriesPoint(from: $from, to: $to, value: $value)';
}


}

/// @nodoc
abstract mixin class _$ReportSeriesPointCopyWith<$Res> implements $ReportSeriesPointCopyWith<$Res> {
  factory _$ReportSeriesPointCopyWith(_ReportSeriesPoint value, $Res Function(_ReportSeriesPoint) _then) = __$ReportSeriesPointCopyWithImpl;
@override @useResult
$Res call({
@UtcDateTimeConverter() DateTime from,@UtcDateTimeConverter() DateTime to, num value
});




}
/// @nodoc
class __$ReportSeriesPointCopyWithImpl<$Res>
    implements _$ReportSeriesPointCopyWith<$Res> {
  __$ReportSeriesPointCopyWithImpl(this._self, this._then);

  final _ReportSeriesPoint _self;
  final $Res Function(_ReportSeriesPoint) _then;

/// Create a copy of ReportSeriesPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,Object? value = null,}) {
  return _then(_ReportSeriesPoint(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}


/// @nodoc
mixin _$LabelledCount {

 String get label; num get value;
/// Create a copy of LabelledCount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LabelledCountCopyWith<LabelledCount> get copyWith => _$LabelledCountCopyWithImpl<LabelledCount>(this as LabelledCount, _$identity);

  /// Serializes this LabelledCount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelledCount&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,value);

@override
String toString() {
  return 'LabelledCount(label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class $LabelledCountCopyWith<$Res>  {
  factory $LabelledCountCopyWith(LabelledCount value, $Res Function(LabelledCount) _then) = _$LabelledCountCopyWithImpl;
@useResult
$Res call({
 String label, num value
});




}
/// @nodoc
class _$LabelledCountCopyWithImpl<$Res>
    implements $LabelledCountCopyWith<$Res> {
  _$LabelledCountCopyWithImpl(this._self, this._then);

  final LabelledCount _self;
  final $Res Function(LabelledCount) _then;

/// Create a copy of LabelledCount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? value = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [LabelledCount].
extension LabelledCountPatterns on LabelledCount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LabelledCount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LabelledCount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LabelledCount value)  $default,){
final _that = this;
switch (_that) {
case _LabelledCount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LabelledCount value)?  $default,){
final _that = this;
switch (_that) {
case _LabelledCount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  num value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LabelledCount() when $default != null:
return $default(_that.label,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  num value)  $default,) {final _that = this;
switch (_that) {
case _LabelledCount():
return $default(_that.label,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  num value)?  $default,) {final _that = this;
switch (_that) {
case _LabelledCount() when $default != null:
return $default(_that.label,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LabelledCount implements LabelledCount {
  const _LabelledCount({this.label = '', this.value = 0});
  factory _LabelledCount.fromJson(Map<String, dynamic> json) => _$LabelledCountFromJson(json);

@override@JsonKey() final  String label;
@override@JsonKey() final  num value;

/// Create a copy of LabelledCount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LabelledCountCopyWith<_LabelledCount> get copyWith => __$LabelledCountCopyWithImpl<_LabelledCount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LabelledCountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LabelledCount&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,value);

@override
String toString() {
  return 'LabelledCount(label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class _$LabelledCountCopyWith<$Res> implements $LabelledCountCopyWith<$Res> {
  factory _$LabelledCountCopyWith(_LabelledCount value, $Res Function(_LabelledCount) _then) = __$LabelledCountCopyWithImpl;
@override @useResult
$Res call({
 String label, num value
});




}
/// @nodoc
class __$LabelledCountCopyWithImpl<$Res>
    implements _$LabelledCountCopyWith<$Res> {
  __$LabelledCountCopyWithImpl(this._self, this._then);

  final _LabelledCount _self;
  final $Res Function(_LabelledCount) _then;

/// Create a copy of LabelledCount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? value = null,}) {
  return _then(_LabelledCount(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}


/// @nodoc
mixin _$ReportSeries {

 List<ReportSeriesPoint> get enrollments; List<ReportSeriesPoint> get completions; List<ReportSeriesPoint> get activeLearners;
/// Create a copy of ReportSeries
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportSeriesCopyWith<ReportSeries> get copyWith => _$ReportSeriesCopyWithImpl<ReportSeries>(this as ReportSeries, _$identity);

  /// Serializes this ReportSeries to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportSeries&&const DeepCollectionEquality().equals(other.enrollments, enrollments)&&const DeepCollectionEquality().equals(other.completions, completions)&&const DeepCollectionEquality().equals(other.activeLearners, activeLearners));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(enrollments),const DeepCollectionEquality().hash(completions),const DeepCollectionEquality().hash(activeLearners));

@override
String toString() {
  return 'ReportSeries(enrollments: $enrollments, completions: $completions, activeLearners: $activeLearners)';
}


}

/// @nodoc
abstract mixin class $ReportSeriesCopyWith<$Res>  {
  factory $ReportSeriesCopyWith(ReportSeries value, $Res Function(ReportSeries) _then) = _$ReportSeriesCopyWithImpl;
@useResult
$Res call({
 List<ReportSeriesPoint> enrollments, List<ReportSeriesPoint> completions, List<ReportSeriesPoint> activeLearners
});




}
/// @nodoc
class _$ReportSeriesCopyWithImpl<$Res>
    implements $ReportSeriesCopyWith<$Res> {
  _$ReportSeriesCopyWithImpl(this._self, this._then);

  final ReportSeries _self;
  final $Res Function(ReportSeries) _then;

/// Create a copy of ReportSeries
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enrollments = null,Object? completions = null,Object? activeLearners = null,}) {
  return _then(_self.copyWith(
enrollments: null == enrollments ? _self.enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as List<ReportSeriesPoint>,completions: null == completions ? _self.completions : completions // ignore: cast_nullable_to_non_nullable
as List<ReportSeriesPoint>,activeLearners: null == activeLearners ? _self.activeLearners : activeLearners // ignore: cast_nullable_to_non_nullable
as List<ReportSeriesPoint>,
  ));
}

}


/// Adds pattern-matching-related methods to [ReportSeries].
extension ReportSeriesPatterns on ReportSeries {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReportSeries value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReportSeries() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReportSeries value)  $default,){
final _that = this;
switch (_that) {
case _ReportSeries():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReportSeries value)?  $default,){
final _that = this;
switch (_that) {
case _ReportSeries() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ReportSeriesPoint> enrollments,  List<ReportSeriesPoint> completions,  List<ReportSeriesPoint> activeLearners)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReportSeries() when $default != null:
return $default(_that.enrollments,_that.completions,_that.activeLearners);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ReportSeriesPoint> enrollments,  List<ReportSeriesPoint> completions,  List<ReportSeriesPoint> activeLearners)  $default,) {final _that = this;
switch (_that) {
case _ReportSeries():
return $default(_that.enrollments,_that.completions,_that.activeLearners);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ReportSeriesPoint> enrollments,  List<ReportSeriesPoint> completions,  List<ReportSeriesPoint> activeLearners)?  $default,) {final _that = this;
switch (_that) {
case _ReportSeries() when $default != null:
return $default(_that.enrollments,_that.completions,_that.activeLearners);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReportSeries implements ReportSeries {
  const _ReportSeries({final  List<ReportSeriesPoint> enrollments = const <ReportSeriesPoint>[], final  List<ReportSeriesPoint> completions = const <ReportSeriesPoint>[], final  List<ReportSeriesPoint> activeLearners = const <ReportSeriesPoint>[]}): _enrollments = enrollments,_completions = completions,_activeLearners = activeLearners;
  factory _ReportSeries.fromJson(Map<String, dynamic> json) => _$ReportSeriesFromJson(json);

 final  List<ReportSeriesPoint> _enrollments;
@override@JsonKey() List<ReportSeriesPoint> get enrollments {
  if (_enrollments is EqualUnmodifiableListView) return _enrollments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_enrollments);
}

 final  List<ReportSeriesPoint> _completions;
@override@JsonKey() List<ReportSeriesPoint> get completions {
  if (_completions is EqualUnmodifiableListView) return _completions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_completions);
}

 final  List<ReportSeriesPoint> _activeLearners;
@override@JsonKey() List<ReportSeriesPoint> get activeLearners {
  if (_activeLearners is EqualUnmodifiableListView) return _activeLearners;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeLearners);
}


/// Create a copy of ReportSeries
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportSeriesCopyWith<_ReportSeries> get copyWith => __$ReportSeriesCopyWithImpl<_ReportSeries>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReportSeriesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReportSeries&&const DeepCollectionEquality().equals(other._enrollments, _enrollments)&&const DeepCollectionEquality().equals(other._completions, _completions)&&const DeepCollectionEquality().equals(other._activeLearners, _activeLearners));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_enrollments),const DeepCollectionEquality().hash(_completions),const DeepCollectionEquality().hash(_activeLearners));

@override
String toString() {
  return 'ReportSeries(enrollments: $enrollments, completions: $completions, activeLearners: $activeLearners)';
}


}

/// @nodoc
abstract mixin class _$ReportSeriesCopyWith<$Res> implements $ReportSeriesCopyWith<$Res> {
  factory _$ReportSeriesCopyWith(_ReportSeries value, $Res Function(_ReportSeries) _then) = __$ReportSeriesCopyWithImpl;
@override @useResult
$Res call({
 List<ReportSeriesPoint> enrollments, List<ReportSeriesPoint> completions, List<ReportSeriesPoint> activeLearners
});




}
/// @nodoc
class __$ReportSeriesCopyWithImpl<$Res>
    implements _$ReportSeriesCopyWith<$Res> {
  __$ReportSeriesCopyWithImpl(this._self, this._then);

  final _ReportSeries _self;
  final $Res Function(_ReportSeries) _then;

/// Create a copy of ReportSeries
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enrollments = null,Object? completions = null,Object? activeLearners = null,}) {
  return _then(_ReportSeries(
enrollments: null == enrollments ? _self._enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as List<ReportSeriesPoint>,completions: null == completions ? _self._completions : completions // ignore: cast_nullable_to_non_nullable
as List<ReportSeriesPoint>,activeLearners: null == activeLearners ? _self._activeLearners : activeLearners // ignore: cast_nullable_to_non_nullable
as List<ReportSeriesPoint>,
  ));
}


}


/// @nodoc
mixin _$CourseReportRow {

 String get courseId; String get title; String get categoryTitle; List<String> get instructorNames; String get status; int get enrollments; int get previousEnrollments; int get completions; int? get completionRate; int get activeLearners; int? get avgProgress; int? get quizPassRate; int? get assignmentPassRate; double? get rating; List<num> get trend;
/// Create a copy of CourseReportRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseReportRowCopyWith<CourseReportRow> get copyWith => _$CourseReportRowCopyWithImpl<CourseReportRow>(this as CourseReportRow, _$identity);

  /// Serializes this CourseReportRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseReportRow&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.title, title) || other.title == title)&&(identical(other.categoryTitle, categoryTitle) || other.categoryTitle == categoryTitle)&&const DeepCollectionEquality().equals(other.instructorNames, instructorNames)&&(identical(other.status, status) || other.status == status)&&(identical(other.enrollments, enrollments) || other.enrollments == enrollments)&&(identical(other.previousEnrollments, previousEnrollments) || other.previousEnrollments == previousEnrollments)&&(identical(other.completions, completions) || other.completions == completions)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.activeLearners, activeLearners) || other.activeLearners == activeLearners)&&(identical(other.avgProgress, avgProgress) || other.avgProgress == avgProgress)&&(identical(other.quizPassRate, quizPassRate) || other.quizPassRate == quizPassRate)&&(identical(other.assignmentPassRate, assignmentPassRate) || other.assignmentPassRate == assignmentPassRate)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.trend, trend));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseId,title,categoryTitle,const DeepCollectionEquality().hash(instructorNames),status,enrollments,previousEnrollments,completions,completionRate,activeLearners,avgProgress,quizPassRate,assignmentPassRate,rating,const DeepCollectionEquality().hash(trend));

@override
String toString() {
  return 'CourseReportRow(courseId: $courseId, title: $title, categoryTitle: $categoryTitle, instructorNames: $instructorNames, status: $status, enrollments: $enrollments, previousEnrollments: $previousEnrollments, completions: $completions, completionRate: $completionRate, activeLearners: $activeLearners, avgProgress: $avgProgress, quizPassRate: $quizPassRate, assignmentPassRate: $assignmentPassRate, rating: $rating, trend: $trend)';
}


}

/// @nodoc
abstract mixin class $CourseReportRowCopyWith<$Res>  {
  factory $CourseReportRowCopyWith(CourseReportRow value, $Res Function(CourseReportRow) _then) = _$CourseReportRowCopyWithImpl;
@useResult
$Res call({
 String courseId, String title, String categoryTitle, List<String> instructorNames, String status, int enrollments, int previousEnrollments, int completions, int? completionRate, int activeLearners, int? avgProgress, int? quizPassRate, int? assignmentPassRate, double? rating, List<num> trend
});




}
/// @nodoc
class _$CourseReportRowCopyWithImpl<$Res>
    implements $CourseReportRowCopyWith<$Res> {
  _$CourseReportRowCopyWithImpl(this._self, this._then);

  final CourseReportRow _self;
  final $Res Function(CourseReportRow) _then;

/// Create a copy of CourseReportRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? courseId = null,Object? title = null,Object? categoryTitle = null,Object? instructorNames = null,Object? status = null,Object? enrollments = null,Object? previousEnrollments = null,Object? completions = null,Object? completionRate = freezed,Object? activeLearners = null,Object? avgProgress = freezed,Object? quizPassRate = freezed,Object? assignmentPassRate = freezed,Object? rating = freezed,Object? trend = null,}) {
  return _then(_self.copyWith(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,categoryTitle: null == categoryTitle ? _self.categoryTitle : categoryTitle // ignore: cast_nullable_to_non_nullable
as String,instructorNames: null == instructorNames ? _self.instructorNames : instructorNames // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,enrollments: null == enrollments ? _self.enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as int,previousEnrollments: null == previousEnrollments ? _self.previousEnrollments : previousEnrollments // ignore: cast_nullable_to_non_nullable
as int,completions: null == completions ? _self.completions : completions // ignore: cast_nullable_to_non_nullable
as int,completionRate: freezed == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as int?,activeLearners: null == activeLearners ? _self.activeLearners : activeLearners // ignore: cast_nullable_to_non_nullable
as int,avgProgress: freezed == avgProgress ? _self.avgProgress : avgProgress // ignore: cast_nullable_to_non_nullable
as int?,quizPassRate: freezed == quizPassRate ? _self.quizPassRate : quizPassRate // ignore: cast_nullable_to_non_nullable
as int?,assignmentPassRate: freezed == assignmentPassRate ? _self.assignmentPassRate : assignmentPassRate // ignore: cast_nullable_to_non_nullable
as int?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,trend: null == trend ? _self.trend : trend // ignore: cast_nullable_to_non_nullable
as List<num>,
  ));
}

}


/// Adds pattern-matching-related methods to [CourseReportRow].
extension CourseReportRowPatterns on CourseReportRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseReportRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseReportRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseReportRow value)  $default,){
final _that = this;
switch (_that) {
case _CourseReportRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseReportRow value)?  $default,){
final _that = this;
switch (_that) {
case _CourseReportRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String courseId,  String title,  String categoryTitle,  List<String> instructorNames,  String status,  int enrollments,  int previousEnrollments,  int completions,  int? completionRate,  int activeLearners,  int? avgProgress,  int? quizPassRate,  int? assignmentPassRate,  double? rating,  List<num> trend)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseReportRow() when $default != null:
return $default(_that.courseId,_that.title,_that.categoryTitle,_that.instructorNames,_that.status,_that.enrollments,_that.previousEnrollments,_that.completions,_that.completionRate,_that.activeLearners,_that.avgProgress,_that.quizPassRate,_that.assignmentPassRate,_that.rating,_that.trend);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String courseId,  String title,  String categoryTitle,  List<String> instructorNames,  String status,  int enrollments,  int previousEnrollments,  int completions,  int? completionRate,  int activeLearners,  int? avgProgress,  int? quizPassRate,  int? assignmentPassRate,  double? rating,  List<num> trend)  $default,) {final _that = this;
switch (_that) {
case _CourseReportRow():
return $default(_that.courseId,_that.title,_that.categoryTitle,_that.instructorNames,_that.status,_that.enrollments,_that.previousEnrollments,_that.completions,_that.completionRate,_that.activeLearners,_that.avgProgress,_that.quizPassRate,_that.assignmentPassRate,_that.rating,_that.trend);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String courseId,  String title,  String categoryTitle,  List<String> instructorNames,  String status,  int enrollments,  int previousEnrollments,  int completions,  int? completionRate,  int activeLearners,  int? avgProgress,  int? quizPassRate,  int? assignmentPassRate,  double? rating,  List<num> trend)?  $default,) {final _that = this;
switch (_that) {
case _CourseReportRow() when $default != null:
return $default(_that.courseId,_that.title,_that.categoryTitle,_that.instructorNames,_that.status,_that.enrollments,_that.previousEnrollments,_that.completions,_that.completionRate,_that.activeLearners,_that.avgProgress,_that.quizPassRate,_that.assignmentPassRate,_that.rating,_that.trend);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseReportRow extends CourseReportRow {
  const _CourseReportRow({this.courseId = '', this.title = '', this.categoryTitle = '', final  List<String> instructorNames = const <String>[], this.status = '', this.enrollments = 0, this.previousEnrollments = 0, this.completions = 0, this.completionRate, this.activeLearners = 0, this.avgProgress, this.quizPassRate, this.assignmentPassRate, this.rating, final  List<num> trend = const <num>[]}): _instructorNames = instructorNames,_trend = trend,super._();
  factory _CourseReportRow.fromJson(Map<String, dynamic> json) => _$CourseReportRowFromJson(json);

@override@JsonKey() final  String courseId;
@override@JsonKey() final  String title;
@override@JsonKey() final  String categoryTitle;
 final  List<String> _instructorNames;
@override@JsonKey() List<String> get instructorNames {
  if (_instructorNames is EqualUnmodifiableListView) return _instructorNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_instructorNames);
}

@override@JsonKey() final  String status;
@override@JsonKey() final  int enrollments;
@override@JsonKey() final  int previousEnrollments;
@override@JsonKey() final  int completions;
@override final  int? completionRate;
@override@JsonKey() final  int activeLearners;
@override final  int? avgProgress;
@override final  int? quizPassRate;
@override final  int? assignmentPassRate;
@override final  double? rating;
 final  List<num> _trend;
@override@JsonKey() List<num> get trend {
  if (_trend is EqualUnmodifiableListView) return _trend;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trend);
}


/// Create a copy of CourseReportRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseReportRowCopyWith<_CourseReportRow> get copyWith => __$CourseReportRowCopyWithImpl<_CourseReportRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseReportRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseReportRow&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.title, title) || other.title == title)&&(identical(other.categoryTitle, categoryTitle) || other.categoryTitle == categoryTitle)&&const DeepCollectionEquality().equals(other._instructorNames, _instructorNames)&&(identical(other.status, status) || other.status == status)&&(identical(other.enrollments, enrollments) || other.enrollments == enrollments)&&(identical(other.previousEnrollments, previousEnrollments) || other.previousEnrollments == previousEnrollments)&&(identical(other.completions, completions) || other.completions == completions)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.activeLearners, activeLearners) || other.activeLearners == activeLearners)&&(identical(other.avgProgress, avgProgress) || other.avgProgress == avgProgress)&&(identical(other.quizPassRate, quizPassRate) || other.quizPassRate == quizPassRate)&&(identical(other.assignmentPassRate, assignmentPassRate) || other.assignmentPassRate == assignmentPassRate)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other._trend, _trend));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseId,title,categoryTitle,const DeepCollectionEquality().hash(_instructorNames),status,enrollments,previousEnrollments,completions,completionRate,activeLearners,avgProgress,quizPassRate,assignmentPassRate,rating,const DeepCollectionEquality().hash(_trend));

@override
String toString() {
  return 'CourseReportRow(courseId: $courseId, title: $title, categoryTitle: $categoryTitle, instructorNames: $instructorNames, status: $status, enrollments: $enrollments, previousEnrollments: $previousEnrollments, completions: $completions, completionRate: $completionRate, activeLearners: $activeLearners, avgProgress: $avgProgress, quizPassRate: $quizPassRate, assignmentPassRate: $assignmentPassRate, rating: $rating, trend: $trend)';
}


}

/// @nodoc
abstract mixin class _$CourseReportRowCopyWith<$Res> implements $CourseReportRowCopyWith<$Res> {
  factory _$CourseReportRowCopyWith(_CourseReportRow value, $Res Function(_CourseReportRow) _then) = __$CourseReportRowCopyWithImpl;
@override @useResult
$Res call({
 String courseId, String title, String categoryTitle, List<String> instructorNames, String status, int enrollments, int previousEnrollments, int completions, int? completionRate, int activeLearners, int? avgProgress, int? quizPassRate, int? assignmentPassRate, double? rating, List<num> trend
});




}
/// @nodoc
class __$CourseReportRowCopyWithImpl<$Res>
    implements _$CourseReportRowCopyWith<$Res> {
  __$CourseReportRowCopyWithImpl(this._self, this._then);

  final _CourseReportRow _self;
  final $Res Function(_CourseReportRow) _then;

/// Create a copy of CourseReportRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? courseId = null,Object? title = null,Object? categoryTitle = null,Object? instructorNames = null,Object? status = null,Object? enrollments = null,Object? previousEnrollments = null,Object? completions = null,Object? completionRate = freezed,Object? activeLearners = null,Object? avgProgress = freezed,Object? quizPassRate = freezed,Object? assignmentPassRate = freezed,Object? rating = freezed,Object? trend = null,}) {
  return _then(_CourseReportRow(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,categoryTitle: null == categoryTitle ? _self.categoryTitle : categoryTitle // ignore: cast_nullable_to_non_nullable
as String,instructorNames: null == instructorNames ? _self._instructorNames : instructorNames // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,enrollments: null == enrollments ? _self.enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as int,previousEnrollments: null == previousEnrollments ? _self.previousEnrollments : previousEnrollments // ignore: cast_nullable_to_non_nullable
as int,completions: null == completions ? _self.completions : completions // ignore: cast_nullable_to_non_nullable
as int,completionRate: freezed == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as int?,activeLearners: null == activeLearners ? _self.activeLearners : activeLearners // ignore: cast_nullable_to_non_nullable
as int,avgProgress: freezed == avgProgress ? _self.avgProgress : avgProgress // ignore: cast_nullable_to_non_nullable
as int?,quizPassRate: freezed == quizPassRate ? _self.quizPassRate : quizPassRate // ignore: cast_nullable_to_non_nullable
as int?,assignmentPassRate: freezed == assignmentPassRate ? _self.assignmentPassRate : assignmentPassRate // ignore: cast_nullable_to_non_nullable
as int?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,trend: null == trend ? _self._trend : trend // ignore: cast_nullable_to_non_nullable
as List<num>,
  ));
}


}


/// @nodoc
mixin _$CategoryReportRow {

 String get categoryId; String get title; int get enrollments; int? get previousEnrollments; int? get completionRate;
/// Create a copy of CategoryReportRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryReportRowCopyWith<CategoryReportRow> get copyWith => _$CategoryReportRowCopyWithImpl<CategoryReportRow>(this as CategoryReportRow, _$identity);

  /// Serializes this CategoryReportRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryReportRow&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.title, title) || other.title == title)&&(identical(other.enrollments, enrollments) || other.enrollments == enrollments)&&(identical(other.previousEnrollments, previousEnrollments) || other.previousEnrollments == previousEnrollments)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categoryId,title,enrollments,previousEnrollments,completionRate);

@override
String toString() {
  return 'CategoryReportRow(categoryId: $categoryId, title: $title, enrollments: $enrollments, previousEnrollments: $previousEnrollments, completionRate: $completionRate)';
}


}

/// @nodoc
abstract mixin class $CategoryReportRowCopyWith<$Res>  {
  factory $CategoryReportRowCopyWith(CategoryReportRow value, $Res Function(CategoryReportRow) _then) = _$CategoryReportRowCopyWithImpl;
@useResult
$Res call({
 String categoryId, String title, int enrollments, int? previousEnrollments, int? completionRate
});




}
/// @nodoc
class _$CategoryReportRowCopyWithImpl<$Res>
    implements $CategoryReportRowCopyWith<$Res> {
  _$CategoryReportRowCopyWithImpl(this._self, this._then);

  final CategoryReportRow _self;
  final $Res Function(CategoryReportRow) _then;

/// Create a copy of CategoryReportRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryId = null,Object? title = null,Object? enrollments = null,Object? previousEnrollments = freezed,Object? completionRate = freezed,}) {
  return _then(_self.copyWith(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,enrollments: null == enrollments ? _self.enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as int,previousEnrollments: freezed == previousEnrollments ? _self.previousEnrollments : previousEnrollments // ignore: cast_nullable_to_non_nullable
as int?,completionRate: freezed == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryReportRow].
extension CategoryReportRowPatterns on CategoryReportRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryReportRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryReportRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryReportRow value)  $default,){
final _that = this;
switch (_that) {
case _CategoryReportRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryReportRow value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryReportRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String categoryId,  String title,  int enrollments,  int? previousEnrollments,  int? completionRate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryReportRow() when $default != null:
return $default(_that.categoryId,_that.title,_that.enrollments,_that.previousEnrollments,_that.completionRate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String categoryId,  String title,  int enrollments,  int? previousEnrollments,  int? completionRate)  $default,) {final _that = this;
switch (_that) {
case _CategoryReportRow():
return $default(_that.categoryId,_that.title,_that.enrollments,_that.previousEnrollments,_that.completionRate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String categoryId,  String title,  int enrollments,  int? previousEnrollments,  int? completionRate)?  $default,) {final _that = this;
switch (_that) {
case _CategoryReportRow() when $default != null:
return $default(_that.categoryId,_that.title,_that.enrollments,_that.previousEnrollments,_that.completionRate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryReportRow implements CategoryReportRow {
  const _CategoryReportRow({this.categoryId = '', this.title = '', this.enrollments = 0, this.previousEnrollments, this.completionRate});
  factory _CategoryReportRow.fromJson(Map<String, dynamic> json) => _$CategoryReportRowFromJson(json);

@override@JsonKey() final  String categoryId;
@override@JsonKey() final  String title;
@override@JsonKey() final  int enrollments;
@override final  int? previousEnrollments;
@override final  int? completionRate;

/// Create a copy of CategoryReportRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryReportRowCopyWith<_CategoryReportRow> get copyWith => __$CategoryReportRowCopyWithImpl<_CategoryReportRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryReportRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryReportRow&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.title, title) || other.title == title)&&(identical(other.enrollments, enrollments) || other.enrollments == enrollments)&&(identical(other.previousEnrollments, previousEnrollments) || other.previousEnrollments == previousEnrollments)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categoryId,title,enrollments,previousEnrollments,completionRate);

@override
String toString() {
  return 'CategoryReportRow(categoryId: $categoryId, title: $title, enrollments: $enrollments, previousEnrollments: $previousEnrollments, completionRate: $completionRate)';
}


}

/// @nodoc
abstract mixin class _$CategoryReportRowCopyWith<$Res> implements $CategoryReportRowCopyWith<$Res> {
  factory _$CategoryReportRowCopyWith(_CategoryReportRow value, $Res Function(_CategoryReportRow) _then) = __$CategoryReportRowCopyWithImpl;
@override @useResult
$Res call({
 String categoryId, String title, int enrollments, int? previousEnrollments, int? completionRate
});




}
/// @nodoc
class __$CategoryReportRowCopyWithImpl<$Res>
    implements _$CategoryReportRowCopyWith<$Res> {
  __$CategoryReportRowCopyWithImpl(this._self, this._then);

  final _CategoryReportRow _self;
  final $Res Function(_CategoryReportRow) _then;

/// Create a copy of CategoryReportRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryId = null,Object? title = null,Object? enrollments = null,Object? previousEnrollments = freezed,Object? completionRate = freezed,}) {
  return _then(_CategoryReportRow(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,enrollments: null == enrollments ? _self.enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as int,previousEnrollments: freezed == previousEnrollments ? _self.previousEnrollments : previousEnrollments // ignore: cast_nullable_to_non_nullable
as int?,completionRate: freezed == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$OverviewKpis {

 Kpi get enrollments; Kpi get completions; Kpi get completionRate; Kpi get activeLearners; Kpi get avgProgress;
/// Create a copy of OverviewKpis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OverviewKpisCopyWith<OverviewKpis> get copyWith => _$OverviewKpisCopyWithImpl<OverviewKpis>(this as OverviewKpis, _$identity);

  /// Serializes this OverviewKpis to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OverviewKpis&&(identical(other.enrollments, enrollments) || other.enrollments == enrollments)&&(identical(other.completions, completions) || other.completions == completions)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.activeLearners, activeLearners) || other.activeLearners == activeLearners)&&(identical(other.avgProgress, avgProgress) || other.avgProgress == avgProgress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrollments,completions,completionRate,activeLearners,avgProgress);

@override
String toString() {
  return 'OverviewKpis(enrollments: $enrollments, completions: $completions, completionRate: $completionRate, activeLearners: $activeLearners, avgProgress: $avgProgress)';
}


}

/// @nodoc
abstract mixin class $OverviewKpisCopyWith<$Res>  {
  factory $OverviewKpisCopyWith(OverviewKpis value, $Res Function(OverviewKpis) _then) = _$OverviewKpisCopyWithImpl;
@useResult
$Res call({
 Kpi enrollments, Kpi completions, Kpi completionRate, Kpi activeLearners, Kpi avgProgress
});


$KpiCopyWith<$Res> get enrollments;$KpiCopyWith<$Res> get completions;$KpiCopyWith<$Res> get completionRate;$KpiCopyWith<$Res> get activeLearners;$KpiCopyWith<$Res> get avgProgress;

}
/// @nodoc
class _$OverviewKpisCopyWithImpl<$Res>
    implements $OverviewKpisCopyWith<$Res> {
  _$OverviewKpisCopyWithImpl(this._self, this._then);

  final OverviewKpis _self;
  final $Res Function(OverviewKpis) _then;

/// Create a copy of OverviewKpis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enrollments = null,Object? completions = null,Object? completionRate = null,Object? activeLearners = null,Object? avgProgress = null,}) {
  return _then(_self.copyWith(
enrollments: null == enrollments ? _self.enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as Kpi,completions: null == completions ? _self.completions : completions // ignore: cast_nullable_to_non_nullable
as Kpi,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as Kpi,activeLearners: null == activeLearners ? _self.activeLearners : activeLearners // ignore: cast_nullable_to_non_nullable
as Kpi,avgProgress: null == avgProgress ? _self.avgProgress : avgProgress // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}
/// Create a copy of OverviewKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get enrollments {
  
  return $KpiCopyWith<$Res>(_self.enrollments, (value) {
    return _then(_self.copyWith(enrollments: value));
  });
}/// Create a copy of OverviewKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get completions {
  
  return $KpiCopyWith<$Res>(_self.completions, (value) {
    return _then(_self.copyWith(completions: value));
  });
}/// Create a copy of OverviewKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get completionRate {
  
  return $KpiCopyWith<$Res>(_self.completionRate, (value) {
    return _then(_self.copyWith(completionRate: value));
  });
}/// Create a copy of OverviewKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get activeLearners {
  
  return $KpiCopyWith<$Res>(_self.activeLearners, (value) {
    return _then(_self.copyWith(activeLearners: value));
  });
}/// Create a copy of OverviewKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get avgProgress {
  
  return $KpiCopyWith<$Res>(_self.avgProgress, (value) {
    return _then(_self.copyWith(avgProgress: value));
  });
}
}


/// Adds pattern-matching-related methods to [OverviewKpis].
extension OverviewKpisPatterns on OverviewKpis {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OverviewKpis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OverviewKpis() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OverviewKpis value)  $default,){
final _that = this;
switch (_that) {
case _OverviewKpis():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OverviewKpis value)?  $default,){
final _that = this;
switch (_that) {
case _OverviewKpis() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Kpi enrollments,  Kpi completions,  Kpi completionRate,  Kpi activeLearners,  Kpi avgProgress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OverviewKpis() when $default != null:
return $default(_that.enrollments,_that.completions,_that.completionRate,_that.activeLearners,_that.avgProgress);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Kpi enrollments,  Kpi completions,  Kpi completionRate,  Kpi activeLearners,  Kpi avgProgress)  $default,) {final _that = this;
switch (_that) {
case _OverviewKpis():
return $default(_that.enrollments,_that.completions,_that.completionRate,_that.activeLearners,_that.avgProgress);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Kpi enrollments,  Kpi completions,  Kpi completionRate,  Kpi activeLearners,  Kpi avgProgress)?  $default,) {final _that = this;
switch (_that) {
case _OverviewKpis() when $default != null:
return $default(_that.enrollments,_that.completions,_that.completionRate,_that.activeLearners,_that.avgProgress);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OverviewKpis implements OverviewKpis {
  const _OverviewKpis({this.enrollments = const Kpi(), this.completions = const Kpi(), this.completionRate = const Kpi(), this.activeLearners = const Kpi(), this.avgProgress = const Kpi()});
  factory _OverviewKpis.fromJson(Map<String, dynamic> json) => _$OverviewKpisFromJson(json);

@override@JsonKey() final  Kpi enrollments;
@override@JsonKey() final  Kpi completions;
@override@JsonKey() final  Kpi completionRate;
@override@JsonKey() final  Kpi activeLearners;
@override@JsonKey() final  Kpi avgProgress;

/// Create a copy of OverviewKpis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OverviewKpisCopyWith<_OverviewKpis> get copyWith => __$OverviewKpisCopyWithImpl<_OverviewKpis>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OverviewKpisToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OverviewKpis&&(identical(other.enrollments, enrollments) || other.enrollments == enrollments)&&(identical(other.completions, completions) || other.completions == completions)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.activeLearners, activeLearners) || other.activeLearners == activeLearners)&&(identical(other.avgProgress, avgProgress) || other.avgProgress == avgProgress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrollments,completions,completionRate,activeLearners,avgProgress);

@override
String toString() {
  return 'OverviewKpis(enrollments: $enrollments, completions: $completions, completionRate: $completionRate, activeLearners: $activeLearners, avgProgress: $avgProgress)';
}


}

/// @nodoc
abstract mixin class _$OverviewKpisCopyWith<$Res> implements $OverviewKpisCopyWith<$Res> {
  factory _$OverviewKpisCopyWith(_OverviewKpis value, $Res Function(_OverviewKpis) _then) = __$OverviewKpisCopyWithImpl;
@override @useResult
$Res call({
 Kpi enrollments, Kpi completions, Kpi completionRate, Kpi activeLearners, Kpi avgProgress
});


@override $KpiCopyWith<$Res> get enrollments;@override $KpiCopyWith<$Res> get completions;@override $KpiCopyWith<$Res> get completionRate;@override $KpiCopyWith<$Res> get activeLearners;@override $KpiCopyWith<$Res> get avgProgress;

}
/// @nodoc
class __$OverviewKpisCopyWithImpl<$Res>
    implements _$OverviewKpisCopyWith<$Res> {
  __$OverviewKpisCopyWithImpl(this._self, this._then);

  final _OverviewKpis _self;
  final $Res Function(_OverviewKpis) _then;

/// Create a copy of OverviewKpis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enrollments = null,Object? completions = null,Object? completionRate = null,Object? activeLearners = null,Object? avgProgress = null,}) {
  return _then(_OverviewKpis(
enrollments: null == enrollments ? _self.enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as Kpi,completions: null == completions ? _self.completions : completions // ignore: cast_nullable_to_non_nullable
as Kpi,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as Kpi,activeLearners: null == activeLearners ? _self.activeLearners : activeLearners // ignore: cast_nullable_to_non_nullable
as Kpi,avgProgress: null == avgProgress ? _self.avgProgress : avgProgress // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}

/// Create a copy of OverviewKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get enrollments {
  
  return $KpiCopyWith<$Res>(_self.enrollments, (value) {
    return _then(_self.copyWith(enrollments: value));
  });
}/// Create a copy of OverviewKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get completions {
  
  return $KpiCopyWith<$Res>(_self.completions, (value) {
    return _then(_self.copyWith(completions: value));
  });
}/// Create a copy of OverviewKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get completionRate {
  
  return $KpiCopyWith<$Res>(_self.completionRate, (value) {
    return _then(_self.copyWith(completionRate: value));
  });
}/// Create a copy of OverviewKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get activeLearners {
  
  return $KpiCopyWith<$Res>(_self.activeLearners, (value) {
    return _then(_self.copyWith(activeLearners: value));
  });
}/// Create a copy of OverviewKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get avgProgress {
  
  return $KpiCopyWith<$Res>(_self.avgProgress, (value) {
    return _then(_self.copyWith(avgProgress: value));
  });
}
}


/// @nodoc
mixin _$QuizFigures {

 Kpi get attempts; Kpi get passRate; Kpi get avgScore;
/// Create a copy of QuizFigures
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizFiguresCopyWith<QuizFigures> get copyWith => _$QuizFiguresCopyWithImpl<QuizFigures>(this as QuizFigures, _$identity);

  /// Serializes this QuizFigures to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizFigures&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.passRate, passRate) || other.passRate == passRate)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attempts,passRate,avgScore);

@override
String toString() {
  return 'QuizFigures(attempts: $attempts, passRate: $passRate, avgScore: $avgScore)';
}


}

/// @nodoc
abstract mixin class $QuizFiguresCopyWith<$Res>  {
  factory $QuizFiguresCopyWith(QuizFigures value, $Res Function(QuizFigures) _then) = _$QuizFiguresCopyWithImpl;
@useResult
$Res call({
 Kpi attempts, Kpi passRate, Kpi avgScore
});


$KpiCopyWith<$Res> get attempts;$KpiCopyWith<$Res> get passRate;$KpiCopyWith<$Res> get avgScore;

}
/// @nodoc
class _$QuizFiguresCopyWithImpl<$Res>
    implements $QuizFiguresCopyWith<$Res> {
  _$QuizFiguresCopyWithImpl(this._self, this._then);

  final QuizFigures _self;
  final $Res Function(QuizFigures) _then;

/// Create a copy of QuizFigures
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attempts = null,Object? passRate = null,Object? avgScore = null,}) {
  return _then(_self.copyWith(
attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as Kpi,passRate: null == passRate ? _self.passRate : passRate // ignore: cast_nullable_to_non_nullable
as Kpi,avgScore: null == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}
/// Create a copy of QuizFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get attempts {
  
  return $KpiCopyWith<$Res>(_self.attempts, (value) {
    return _then(_self.copyWith(attempts: value));
  });
}/// Create a copy of QuizFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get passRate {
  
  return $KpiCopyWith<$Res>(_self.passRate, (value) {
    return _then(_self.copyWith(passRate: value));
  });
}/// Create a copy of QuizFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get avgScore {
  
  return $KpiCopyWith<$Res>(_self.avgScore, (value) {
    return _then(_self.copyWith(avgScore: value));
  });
}
}


/// Adds pattern-matching-related methods to [QuizFigures].
extension QuizFiguresPatterns on QuizFigures {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizFigures value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizFigures() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizFigures value)  $default,){
final _that = this;
switch (_that) {
case _QuizFigures():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizFigures value)?  $default,){
final _that = this;
switch (_that) {
case _QuizFigures() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Kpi attempts,  Kpi passRate,  Kpi avgScore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizFigures() when $default != null:
return $default(_that.attempts,_that.passRate,_that.avgScore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Kpi attempts,  Kpi passRate,  Kpi avgScore)  $default,) {final _that = this;
switch (_that) {
case _QuizFigures():
return $default(_that.attempts,_that.passRate,_that.avgScore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Kpi attempts,  Kpi passRate,  Kpi avgScore)?  $default,) {final _that = this;
switch (_that) {
case _QuizFigures() when $default != null:
return $default(_that.attempts,_that.passRate,_that.avgScore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizFigures implements QuizFigures {
  const _QuizFigures({this.attempts = const Kpi(), this.passRate = const Kpi(), this.avgScore = const Kpi()});
  factory _QuizFigures.fromJson(Map<String, dynamic> json) => _$QuizFiguresFromJson(json);

@override@JsonKey() final  Kpi attempts;
@override@JsonKey() final  Kpi passRate;
@override@JsonKey() final  Kpi avgScore;

/// Create a copy of QuizFigures
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizFiguresCopyWith<_QuizFigures> get copyWith => __$QuizFiguresCopyWithImpl<_QuizFigures>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizFiguresToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizFigures&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.passRate, passRate) || other.passRate == passRate)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attempts,passRate,avgScore);

@override
String toString() {
  return 'QuizFigures(attempts: $attempts, passRate: $passRate, avgScore: $avgScore)';
}


}

/// @nodoc
abstract mixin class _$QuizFiguresCopyWith<$Res> implements $QuizFiguresCopyWith<$Res> {
  factory _$QuizFiguresCopyWith(_QuizFigures value, $Res Function(_QuizFigures) _then) = __$QuizFiguresCopyWithImpl;
@override @useResult
$Res call({
 Kpi attempts, Kpi passRate, Kpi avgScore
});


@override $KpiCopyWith<$Res> get attempts;@override $KpiCopyWith<$Res> get passRate;@override $KpiCopyWith<$Res> get avgScore;

}
/// @nodoc
class __$QuizFiguresCopyWithImpl<$Res>
    implements _$QuizFiguresCopyWith<$Res> {
  __$QuizFiguresCopyWithImpl(this._self, this._then);

  final _QuizFigures _self;
  final $Res Function(_QuizFigures) _then;

/// Create a copy of QuizFigures
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attempts = null,Object? passRate = null,Object? avgScore = null,}) {
  return _then(_QuizFigures(
attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as Kpi,passRate: null == passRate ? _self.passRate : passRate // ignore: cast_nullable_to_non_nullable
as Kpi,avgScore: null == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}

/// Create a copy of QuizFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get attempts {
  
  return $KpiCopyWith<$Res>(_self.attempts, (value) {
    return _then(_self.copyWith(attempts: value));
  });
}/// Create a copy of QuizFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get passRate {
  
  return $KpiCopyWith<$Res>(_self.passRate, (value) {
    return _then(_self.copyWith(passRate: value));
  });
}/// Create a copy of QuizFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get avgScore {
  
  return $KpiCopyWith<$Res>(_self.avgScore, (value) {
    return _then(_self.copyWith(avgScore: value));
  });
}
}


/// @nodoc
mixin _$AssignmentFigures {

 Kpi get submitted; Kpi get passRate; Kpi get onTime; Kpi get reviewHours;
/// Create a copy of AssignmentFigures
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssignmentFiguresCopyWith<AssignmentFigures> get copyWith => _$AssignmentFiguresCopyWithImpl<AssignmentFigures>(this as AssignmentFigures, _$identity);

  /// Serializes this AssignmentFigures to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssignmentFigures&&(identical(other.submitted, submitted) || other.submitted == submitted)&&(identical(other.passRate, passRate) || other.passRate == passRate)&&(identical(other.onTime, onTime) || other.onTime == onTime)&&(identical(other.reviewHours, reviewHours) || other.reviewHours == reviewHours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,submitted,passRate,onTime,reviewHours);

@override
String toString() {
  return 'AssignmentFigures(submitted: $submitted, passRate: $passRate, onTime: $onTime, reviewHours: $reviewHours)';
}


}

/// @nodoc
abstract mixin class $AssignmentFiguresCopyWith<$Res>  {
  factory $AssignmentFiguresCopyWith(AssignmentFigures value, $Res Function(AssignmentFigures) _then) = _$AssignmentFiguresCopyWithImpl;
@useResult
$Res call({
 Kpi submitted, Kpi passRate, Kpi onTime, Kpi reviewHours
});


$KpiCopyWith<$Res> get submitted;$KpiCopyWith<$Res> get passRate;$KpiCopyWith<$Res> get onTime;$KpiCopyWith<$Res> get reviewHours;

}
/// @nodoc
class _$AssignmentFiguresCopyWithImpl<$Res>
    implements $AssignmentFiguresCopyWith<$Res> {
  _$AssignmentFiguresCopyWithImpl(this._self, this._then);

  final AssignmentFigures _self;
  final $Res Function(AssignmentFigures) _then;

/// Create a copy of AssignmentFigures
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? submitted = null,Object? passRate = null,Object? onTime = null,Object? reviewHours = null,}) {
  return _then(_self.copyWith(
submitted: null == submitted ? _self.submitted : submitted // ignore: cast_nullable_to_non_nullable
as Kpi,passRate: null == passRate ? _self.passRate : passRate // ignore: cast_nullable_to_non_nullable
as Kpi,onTime: null == onTime ? _self.onTime : onTime // ignore: cast_nullable_to_non_nullable
as Kpi,reviewHours: null == reviewHours ? _self.reviewHours : reviewHours // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}
/// Create a copy of AssignmentFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get submitted {
  
  return $KpiCopyWith<$Res>(_self.submitted, (value) {
    return _then(_self.copyWith(submitted: value));
  });
}/// Create a copy of AssignmentFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get passRate {
  
  return $KpiCopyWith<$Res>(_self.passRate, (value) {
    return _then(_self.copyWith(passRate: value));
  });
}/// Create a copy of AssignmentFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get onTime {
  
  return $KpiCopyWith<$Res>(_self.onTime, (value) {
    return _then(_self.copyWith(onTime: value));
  });
}/// Create a copy of AssignmentFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get reviewHours {
  
  return $KpiCopyWith<$Res>(_self.reviewHours, (value) {
    return _then(_self.copyWith(reviewHours: value));
  });
}
}


/// Adds pattern-matching-related methods to [AssignmentFigures].
extension AssignmentFiguresPatterns on AssignmentFigures {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssignmentFigures value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssignmentFigures() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssignmentFigures value)  $default,){
final _that = this;
switch (_that) {
case _AssignmentFigures():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssignmentFigures value)?  $default,){
final _that = this;
switch (_that) {
case _AssignmentFigures() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Kpi submitted,  Kpi passRate,  Kpi onTime,  Kpi reviewHours)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssignmentFigures() when $default != null:
return $default(_that.submitted,_that.passRate,_that.onTime,_that.reviewHours);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Kpi submitted,  Kpi passRate,  Kpi onTime,  Kpi reviewHours)  $default,) {final _that = this;
switch (_that) {
case _AssignmentFigures():
return $default(_that.submitted,_that.passRate,_that.onTime,_that.reviewHours);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Kpi submitted,  Kpi passRate,  Kpi onTime,  Kpi reviewHours)?  $default,) {final _that = this;
switch (_that) {
case _AssignmentFigures() when $default != null:
return $default(_that.submitted,_that.passRate,_that.onTime,_that.reviewHours);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssignmentFigures implements AssignmentFigures {
  const _AssignmentFigures({this.submitted = const Kpi(), this.passRate = const Kpi(), this.onTime = const Kpi(), this.reviewHours = const Kpi()});
  factory _AssignmentFigures.fromJson(Map<String, dynamic> json) => _$AssignmentFiguresFromJson(json);

@override@JsonKey() final  Kpi submitted;
@override@JsonKey() final  Kpi passRate;
@override@JsonKey() final  Kpi onTime;
@override@JsonKey() final  Kpi reviewHours;

/// Create a copy of AssignmentFigures
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssignmentFiguresCopyWith<_AssignmentFigures> get copyWith => __$AssignmentFiguresCopyWithImpl<_AssignmentFigures>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssignmentFiguresToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssignmentFigures&&(identical(other.submitted, submitted) || other.submitted == submitted)&&(identical(other.passRate, passRate) || other.passRate == passRate)&&(identical(other.onTime, onTime) || other.onTime == onTime)&&(identical(other.reviewHours, reviewHours) || other.reviewHours == reviewHours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,submitted,passRate,onTime,reviewHours);

@override
String toString() {
  return 'AssignmentFigures(submitted: $submitted, passRate: $passRate, onTime: $onTime, reviewHours: $reviewHours)';
}


}

/// @nodoc
abstract mixin class _$AssignmentFiguresCopyWith<$Res> implements $AssignmentFiguresCopyWith<$Res> {
  factory _$AssignmentFiguresCopyWith(_AssignmentFigures value, $Res Function(_AssignmentFigures) _then) = __$AssignmentFiguresCopyWithImpl;
@override @useResult
$Res call({
 Kpi submitted, Kpi passRate, Kpi onTime, Kpi reviewHours
});


@override $KpiCopyWith<$Res> get submitted;@override $KpiCopyWith<$Res> get passRate;@override $KpiCopyWith<$Res> get onTime;@override $KpiCopyWith<$Res> get reviewHours;

}
/// @nodoc
class __$AssignmentFiguresCopyWithImpl<$Res>
    implements _$AssignmentFiguresCopyWith<$Res> {
  __$AssignmentFiguresCopyWithImpl(this._self, this._then);

  final _AssignmentFigures _self;
  final $Res Function(_AssignmentFigures) _then;

/// Create a copy of AssignmentFigures
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? submitted = null,Object? passRate = null,Object? onTime = null,Object? reviewHours = null,}) {
  return _then(_AssignmentFigures(
submitted: null == submitted ? _self.submitted : submitted // ignore: cast_nullable_to_non_nullable
as Kpi,passRate: null == passRate ? _self.passRate : passRate // ignore: cast_nullable_to_non_nullable
as Kpi,onTime: null == onTime ? _self.onTime : onTime // ignore: cast_nullable_to_non_nullable
as Kpi,reviewHours: null == reviewHours ? _self.reviewHours : reviewHours // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}

/// Create a copy of AssignmentFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get submitted {
  
  return $KpiCopyWith<$Res>(_self.submitted, (value) {
    return _then(_self.copyWith(submitted: value));
  });
}/// Create a copy of AssignmentFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get passRate {
  
  return $KpiCopyWith<$Res>(_self.passRate, (value) {
    return _then(_self.copyWith(passRate: value));
  });
}/// Create a copy of AssignmentFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get onTime {
  
  return $KpiCopyWith<$Res>(_self.onTime, (value) {
    return _then(_self.copyWith(onTime: value));
  });
}/// Create a copy of AssignmentFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get reviewHours {
  
  return $KpiCopyWith<$Res>(_self.reviewHours, (value) {
    return _then(_self.copyWith(reviewHours: value));
  });
}
}


/// @nodoc
mixin _$EngagementFigures {

 Kpi get lessonsCompleted; Kpi get lessonsPerLearner; Kpi get liveAttendance;
/// Create a copy of EngagementFigures
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EngagementFiguresCopyWith<EngagementFigures> get copyWith => _$EngagementFiguresCopyWithImpl<EngagementFigures>(this as EngagementFigures, _$identity);

  /// Serializes this EngagementFigures to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EngagementFigures&&(identical(other.lessonsCompleted, lessonsCompleted) || other.lessonsCompleted == lessonsCompleted)&&(identical(other.lessonsPerLearner, lessonsPerLearner) || other.lessonsPerLearner == lessonsPerLearner)&&(identical(other.liveAttendance, liveAttendance) || other.liveAttendance == liveAttendance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lessonsCompleted,lessonsPerLearner,liveAttendance);

@override
String toString() {
  return 'EngagementFigures(lessonsCompleted: $lessonsCompleted, lessonsPerLearner: $lessonsPerLearner, liveAttendance: $liveAttendance)';
}


}

/// @nodoc
abstract mixin class $EngagementFiguresCopyWith<$Res>  {
  factory $EngagementFiguresCopyWith(EngagementFigures value, $Res Function(EngagementFigures) _then) = _$EngagementFiguresCopyWithImpl;
@useResult
$Res call({
 Kpi lessonsCompleted, Kpi lessonsPerLearner, Kpi liveAttendance
});


$KpiCopyWith<$Res> get lessonsCompleted;$KpiCopyWith<$Res> get lessonsPerLearner;$KpiCopyWith<$Res> get liveAttendance;

}
/// @nodoc
class _$EngagementFiguresCopyWithImpl<$Res>
    implements $EngagementFiguresCopyWith<$Res> {
  _$EngagementFiguresCopyWithImpl(this._self, this._then);

  final EngagementFigures _self;
  final $Res Function(EngagementFigures) _then;

/// Create a copy of EngagementFigures
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lessonsCompleted = null,Object? lessonsPerLearner = null,Object? liveAttendance = null,}) {
  return _then(_self.copyWith(
lessonsCompleted: null == lessonsCompleted ? _self.lessonsCompleted : lessonsCompleted // ignore: cast_nullable_to_non_nullable
as Kpi,lessonsPerLearner: null == lessonsPerLearner ? _self.lessonsPerLearner : lessonsPerLearner // ignore: cast_nullable_to_non_nullable
as Kpi,liveAttendance: null == liveAttendance ? _self.liveAttendance : liveAttendance // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}
/// Create a copy of EngagementFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get lessonsCompleted {
  
  return $KpiCopyWith<$Res>(_self.lessonsCompleted, (value) {
    return _then(_self.copyWith(lessonsCompleted: value));
  });
}/// Create a copy of EngagementFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get lessonsPerLearner {
  
  return $KpiCopyWith<$Res>(_self.lessonsPerLearner, (value) {
    return _then(_self.copyWith(lessonsPerLearner: value));
  });
}/// Create a copy of EngagementFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get liveAttendance {
  
  return $KpiCopyWith<$Res>(_self.liveAttendance, (value) {
    return _then(_self.copyWith(liveAttendance: value));
  });
}
}


/// Adds pattern-matching-related methods to [EngagementFigures].
extension EngagementFiguresPatterns on EngagementFigures {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EngagementFigures value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EngagementFigures() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EngagementFigures value)  $default,){
final _that = this;
switch (_that) {
case _EngagementFigures():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EngagementFigures value)?  $default,){
final _that = this;
switch (_that) {
case _EngagementFigures() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Kpi lessonsCompleted,  Kpi lessonsPerLearner,  Kpi liveAttendance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EngagementFigures() when $default != null:
return $default(_that.lessonsCompleted,_that.lessonsPerLearner,_that.liveAttendance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Kpi lessonsCompleted,  Kpi lessonsPerLearner,  Kpi liveAttendance)  $default,) {final _that = this;
switch (_that) {
case _EngagementFigures():
return $default(_that.lessonsCompleted,_that.lessonsPerLearner,_that.liveAttendance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Kpi lessonsCompleted,  Kpi lessonsPerLearner,  Kpi liveAttendance)?  $default,) {final _that = this;
switch (_that) {
case _EngagementFigures() when $default != null:
return $default(_that.lessonsCompleted,_that.lessonsPerLearner,_that.liveAttendance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EngagementFigures implements EngagementFigures {
  const _EngagementFigures({this.lessonsCompleted = const Kpi(), this.lessonsPerLearner = const Kpi(), this.liveAttendance = const Kpi()});
  factory _EngagementFigures.fromJson(Map<String, dynamic> json) => _$EngagementFiguresFromJson(json);

@override@JsonKey() final  Kpi lessonsCompleted;
@override@JsonKey() final  Kpi lessonsPerLearner;
@override@JsonKey() final  Kpi liveAttendance;

/// Create a copy of EngagementFigures
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EngagementFiguresCopyWith<_EngagementFigures> get copyWith => __$EngagementFiguresCopyWithImpl<_EngagementFigures>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EngagementFiguresToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EngagementFigures&&(identical(other.lessonsCompleted, lessonsCompleted) || other.lessonsCompleted == lessonsCompleted)&&(identical(other.lessonsPerLearner, lessonsPerLearner) || other.lessonsPerLearner == lessonsPerLearner)&&(identical(other.liveAttendance, liveAttendance) || other.liveAttendance == liveAttendance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lessonsCompleted,lessonsPerLearner,liveAttendance);

@override
String toString() {
  return 'EngagementFigures(lessonsCompleted: $lessonsCompleted, lessonsPerLearner: $lessonsPerLearner, liveAttendance: $liveAttendance)';
}


}

/// @nodoc
abstract mixin class _$EngagementFiguresCopyWith<$Res> implements $EngagementFiguresCopyWith<$Res> {
  factory _$EngagementFiguresCopyWith(_EngagementFigures value, $Res Function(_EngagementFigures) _then) = __$EngagementFiguresCopyWithImpl;
@override @useResult
$Res call({
 Kpi lessonsCompleted, Kpi lessonsPerLearner, Kpi liveAttendance
});


@override $KpiCopyWith<$Res> get lessonsCompleted;@override $KpiCopyWith<$Res> get lessonsPerLearner;@override $KpiCopyWith<$Res> get liveAttendance;

}
/// @nodoc
class __$EngagementFiguresCopyWithImpl<$Res>
    implements _$EngagementFiguresCopyWith<$Res> {
  __$EngagementFiguresCopyWithImpl(this._self, this._then);

  final _EngagementFigures _self;
  final $Res Function(_EngagementFigures) _then;

/// Create a copy of EngagementFigures
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lessonsCompleted = null,Object? lessonsPerLearner = null,Object? liveAttendance = null,}) {
  return _then(_EngagementFigures(
lessonsCompleted: null == lessonsCompleted ? _self.lessonsCompleted : lessonsCompleted // ignore: cast_nullable_to_non_nullable
as Kpi,lessonsPerLearner: null == lessonsPerLearner ? _self.lessonsPerLearner : lessonsPerLearner // ignore: cast_nullable_to_non_nullable
as Kpi,liveAttendance: null == liveAttendance ? _self.liveAttendance : liveAttendance // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}

/// Create a copy of EngagementFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get lessonsCompleted {
  
  return $KpiCopyWith<$Res>(_self.lessonsCompleted, (value) {
    return _then(_self.copyWith(lessonsCompleted: value));
  });
}/// Create a copy of EngagementFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get lessonsPerLearner {
  
  return $KpiCopyWith<$Res>(_self.lessonsPerLearner, (value) {
    return _then(_self.copyWith(lessonsPerLearner: value));
  });
}/// Create a copy of EngagementFigures
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
mixin _$OverviewReport {

 ReportWindow get window; int get courseCount; OverviewKpis get kpis; ReportSeries get series; QuizFigures get quizzes; AssignmentFigures get assignments; EngagementFigures get engagement; List<LabelledCount> get progressBands; List<CategoryReportRow> get categories; List<CourseReportRow> get topCourses;
/// Create a copy of OverviewReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OverviewReportCopyWith<OverviewReport> get copyWith => _$OverviewReportCopyWithImpl<OverviewReport>(this as OverviewReport, _$identity);

  /// Serializes this OverviewReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OverviewReport&&(identical(other.window, window) || other.window == window)&&(identical(other.courseCount, courseCount) || other.courseCount == courseCount)&&(identical(other.kpis, kpis) || other.kpis == kpis)&&(identical(other.series, series) || other.series == series)&&(identical(other.quizzes, quizzes) || other.quizzes == quizzes)&&(identical(other.assignments, assignments) || other.assignments == assignments)&&(identical(other.engagement, engagement) || other.engagement == engagement)&&const DeepCollectionEquality().equals(other.progressBands, progressBands)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.topCourses, topCourses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,window,courseCount,kpis,series,quizzes,assignments,engagement,const DeepCollectionEquality().hash(progressBands),const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(topCourses));

@override
String toString() {
  return 'OverviewReport(window: $window, courseCount: $courseCount, kpis: $kpis, series: $series, quizzes: $quizzes, assignments: $assignments, engagement: $engagement, progressBands: $progressBands, categories: $categories, topCourses: $topCourses)';
}


}

/// @nodoc
abstract mixin class $OverviewReportCopyWith<$Res>  {
  factory $OverviewReportCopyWith(OverviewReport value, $Res Function(OverviewReport) _then) = _$OverviewReportCopyWithImpl;
@useResult
$Res call({
 ReportWindow window, int courseCount, OverviewKpis kpis, ReportSeries series, QuizFigures quizzes, AssignmentFigures assignments, EngagementFigures engagement, List<LabelledCount> progressBands, List<CategoryReportRow> categories, List<CourseReportRow> topCourses
});


$ReportWindowCopyWith<$Res> get window;$OverviewKpisCopyWith<$Res> get kpis;$ReportSeriesCopyWith<$Res> get series;$QuizFiguresCopyWith<$Res> get quizzes;$AssignmentFiguresCopyWith<$Res> get assignments;$EngagementFiguresCopyWith<$Res> get engagement;

}
/// @nodoc
class _$OverviewReportCopyWithImpl<$Res>
    implements $OverviewReportCopyWith<$Res> {
  _$OverviewReportCopyWithImpl(this._self, this._then);

  final OverviewReport _self;
  final $Res Function(OverviewReport) _then;

/// Create a copy of OverviewReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? window = null,Object? courseCount = null,Object? kpis = null,Object? series = null,Object? quizzes = null,Object? assignments = null,Object? engagement = null,Object? progressBands = null,Object? categories = null,Object? topCourses = null,}) {
  return _then(_self.copyWith(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as ReportWindow,courseCount: null == courseCount ? _self.courseCount : courseCount // ignore: cast_nullable_to_non_nullable
as int,kpis: null == kpis ? _self.kpis : kpis // ignore: cast_nullable_to_non_nullable
as OverviewKpis,series: null == series ? _self.series : series // ignore: cast_nullable_to_non_nullable
as ReportSeries,quizzes: null == quizzes ? _self.quizzes : quizzes // ignore: cast_nullable_to_non_nullable
as QuizFigures,assignments: null == assignments ? _self.assignments : assignments // ignore: cast_nullable_to_non_nullable
as AssignmentFigures,engagement: null == engagement ? _self.engagement : engagement // ignore: cast_nullable_to_non_nullable
as EngagementFigures,progressBands: null == progressBands ? _self.progressBands : progressBands // ignore: cast_nullable_to_non_nullable
as List<LabelledCount>,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<CategoryReportRow>,topCourses: null == topCourses ? _self.topCourses : topCourses // ignore: cast_nullable_to_non_nullable
as List<CourseReportRow>,
  ));
}
/// Create a copy of OverviewReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportWindowCopyWith<$Res> get window {
  
  return $ReportWindowCopyWith<$Res>(_self.window, (value) {
    return _then(_self.copyWith(window: value));
  });
}/// Create a copy of OverviewReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OverviewKpisCopyWith<$Res> get kpis {
  
  return $OverviewKpisCopyWith<$Res>(_self.kpis, (value) {
    return _then(_self.copyWith(kpis: value));
  });
}/// Create a copy of OverviewReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportSeriesCopyWith<$Res> get series {
  
  return $ReportSeriesCopyWith<$Res>(_self.series, (value) {
    return _then(_self.copyWith(series: value));
  });
}/// Create a copy of OverviewReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizFiguresCopyWith<$Res> get quizzes {
  
  return $QuizFiguresCopyWith<$Res>(_self.quizzes, (value) {
    return _then(_self.copyWith(quizzes: value));
  });
}/// Create a copy of OverviewReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssignmentFiguresCopyWith<$Res> get assignments {
  
  return $AssignmentFiguresCopyWith<$Res>(_self.assignments, (value) {
    return _then(_self.copyWith(assignments: value));
  });
}/// Create a copy of OverviewReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EngagementFiguresCopyWith<$Res> get engagement {
  
  return $EngagementFiguresCopyWith<$Res>(_self.engagement, (value) {
    return _then(_self.copyWith(engagement: value));
  });
}
}


/// Adds pattern-matching-related methods to [OverviewReport].
extension OverviewReportPatterns on OverviewReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OverviewReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OverviewReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OverviewReport value)  $default,){
final _that = this;
switch (_that) {
case _OverviewReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OverviewReport value)?  $default,){
final _that = this;
switch (_that) {
case _OverviewReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReportWindow window,  int courseCount,  OverviewKpis kpis,  ReportSeries series,  QuizFigures quizzes,  AssignmentFigures assignments,  EngagementFigures engagement,  List<LabelledCount> progressBands,  List<CategoryReportRow> categories,  List<CourseReportRow> topCourses)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OverviewReport() when $default != null:
return $default(_that.window,_that.courseCount,_that.kpis,_that.series,_that.quizzes,_that.assignments,_that.engagement,_that.progressBands,_that.categories,_that.topCourses);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReportWindow window,  int courseCount,  OverviewKpis kpis,  ReportSeries series,  QuizFigures quizzes,  AssignmentFigures assignments,  EngagementFigures engagement,  List<LabelledCount> progressBands,  List<CategoryReportRow> categories,  List<CourseReportRow> topCourses)  $default,) {final _that = this;
switch (_that) {
case _OverviewReport():
return $default(_that.window,_that.courseCount,_that.kpis,_that.series,_that.quizzes,_that.assignments,_that.engagement,_that.progressBands,_that.categories,_that.topCourses);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReportWindow window,  int courseCount,  OverviewKpis kpis,  ReportSeries series,  QuizFigures quizzes,  AssignmentFigures assignments,  EngagementFigures engagement,  List<LabelledCount> progressBands,  List<CategoryReportRow> categories,  List<CourseReportRow> topCourses)?  $default,) {final _that = this;
switch (_that) {
case _OverviewReport() when $default != null:
return $default(_that.window,_that.courseCount,_that.kpis,_that.series,_that.quizzes,_that.assignments,_that.engagement,_that.progressBands,_that.categories,_that.topCourses);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OverviewReport implements OverviewReport {
  const _OverviewReport({required this.window, this.courseCount = 0, this.kpis = const OverviewKpis(), this.series = const ReportSeries(), this.quizzes = const QuizFigures(), this.assignments = const AssignmentFigures(), this.engagement = const EngagementFigures(), final  List<LabelledCount> progressBands = const <LabelledCount>[], final  List<CategoryReportRow> categories = const <CategoryReportRow>[], final  List<CourseReportRow> topCourses = const <CourseReportRow>[]}): _progressBands = progressBands,_categories = categories,_topCourses = topCourses;
  factory _OverviewReport.fromJson(Map<String, dynamic> json) => _$OverviewReportFromJson(json);

@override final  ReportWindow window;
@override@JsonKey() final  int courseCount;
@override@JsonKey() final  OverviewKpis kpis;
@override@JsonKey() final  ReportSeries series;
@override@JsonKey() final  QuizFigures quizzes;
@override@JsonKey() final  AssignmentFigures assignments;
@override@JsonKey() final  EngagementFigures engagement;
 final  List<LabelledCount> _progressBands;
@override@JsonKey() List<LabelledCount> get progressBands {
  if (_progressBands is EqualUnmodifiableListView) return _progressBands;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_progressBands);
}

 final  List<CategoryReportRow> _categories;
@override@JsonKey() List<CategoryReportRow> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<CourseReportRow> _topCourses;
@override@JsonKey() List<CourseReportRow> get topCourses {
  if (_topCourses is EqualUnmodifiableListView) return _topCourses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topCourses);
}


/// Create a copy of OverviewReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OverviewReportCopyWith<_OverviewReport> get copyWith => __$OverviewReportCopyWithImpl<_OverviewReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OverviewReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OverviewReport&&(identical(other.window, window) || other.window == window)&&(identical(other.courseCount, courseCount) || other.courseCount == courseCount)&&(identical(other.kpis, kpis) || other.kpis == kpis)&&(identical(other.series, series) || other.series == series)&&(identical(other.quizzes, quizzes) || other.quizzes == quizzes)&&(identical(other.assignments, assignments) || other.assignments == assignments)&&(identical(other.engagement, engagement) || other.engagement == engagement)&&const DeepCollectionEquality().equals(other._progressBands, _progressBands)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._topCourses, _topCourses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,window,courseCount,kpis,series,quizzes,assignments,engagement,const DeepCollectionEquality().hash(_progressBands),const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_topCourses));

@override
String toString() {
  return 'OverviewReport(window: $window, courseCount: $courseCount, kpis: $kpis, series: $series, quizzes: $quizzes, assignments: $assignments, engagement: $engagement, progressBands: $progressBands, categories: $categories, topCourses: $topCourses)';
}


}

/// @nodoc
abstract mixin class _$OverviewReportCopyWith<$Res> implements $OverviewReportCopyWith<$Res> {
  factory _$OverviewReportCopyWith(_OverviewReport value, $Res Function(_OverviewReport) _then) = __$OverviewReportCopyWithImpl;
@override @useResult
$Res call({
 ReportWindow window, int courseCount, OverviewKpis kpis, ReportSeries series, QuizFigures quizzes, AssignmentFigures assignments, EngagementFigures engagement, List<LabelledCount> progressBands, List<CategoryReportRow> categories, List<CourseReportRow> topCourses
});


@override $ReportWindowCopyWith<$Res> get window;@override $OverviewKpisCopyWith<$Res> get kpis;@override $ReportSeriesCopyWith<$Res> get series;@override $QuizFiguresCopyWith<$Res> get quizzes;@override $AssignmentFiguresCopyWith<$Res> get assignments;@override $EngagementFiguresCopyWith<$Res> get engagement;

}
/// @nodoc
class __$OverviewReportCopyWithImpl<$Res>
    implements _$OverviewReportCopyWith<$Res> {
  __$OverviewReportCopyWithImpl(this._self, this._then);

  final _OverviewReport _self;
  final $Res Function(_OverviewReport) _then;

/// Create a copy of OverviewReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? window = null,Object? courseCount = null,Object? kpis = null,Object? series = null,Object? quizzes = null,Object? assignments = null,Object? engagement = null,Object? progressBands = null,Object? categories = null,Object? topCourses = null,}) {
  return _then(_OverviewReport(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as ReportWindow,courseCount: null == courseCount ? _self.courseCount : courseCount // ignore: cast_nullable_to_non_nullable
as int,kpis: null == kpis ? _self.kpis : kpis // ignore: cast_nullable_to_non_nullable
as OverviewKpis,series: null == series ? _self.series : series // ignore: cast_nullable_to_non_nullable
as ReportSeries,quizzes: null == quizzes ? _self.quizzes : quizzes // ignore: cast_nullable_to_non_nullable
as QuizFigures,assignments: null == assignments ? _self.assignments : assignments // ignore: cast_nullable_to_non_nullable
as AssignmentFigures,engagement: null == engagement ? _self.engagement : engagement // ignore: cast_nullable_to_non_nullable
as EngagementFigures,progressBands: null == progressBands ? _self._progressBands : progressBands // ignore: cast_nullable_to_non_nullable
as List<LabelledCount>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<CategoryReportRow>,topCourses: null == topCourses ? _self._topCourses : topCourses // ignore: cast_nullable_to_non_nullable
as List<CourseReportRow>,
  ));
}

/// Create a copy of OverviewReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportWindowCopyWith<$Res> get window {
  
  return $ReportWindowCopyWith<$Res>(_self.window, (value) {
    return _then(_self.copyWith(window: value));
  });
}/// Create a copy of OverviewReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OverviewKpisCopyWith<$Res> get kpis {
  
  return $OverviewKpisCopyWith<$Res>(_self.kpis, (value) {
    return _then(_self.copyWith(kpis: value));
  });
}/// Create a copy of OverviewReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportSeriesCopyWith<$Res> get series {
  
  return $ReportSeriesCopyWith<$Res>(_self.series, (value) {
    return _then(_self.copyWith(series: value));
  });
}/// Create a copy of OverviewReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizFiguresCopyWith<$Res> get quizzes {
  
  return $QuizFiguresCopyWith<$Res>(_self.quizzes, (value) {
    return _then(_self.copyWith(quizzes: value));
  });
}/// Create a copy of OverviewReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssignmentFiguresCopyWith<$Res> get assignments {
  
  return $AssignmentFiguresCopyWith<$Res>(_self.assignments, (value) {
    return _then(_self.copyWith(assignments: value));
  });
}/// Create a copy of OverviewReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EngagementFiguresCopyWith<$Res> get engagement {
  
  return $EngagementFiguresCopyWith<$Res>(_self.engagement, (value) {
    return _then(_self.copyWith(engagement: value));
  });
}
}


/// @nodoc
mixin _$CoursesReport {

 ReportWindow get window; int get courseCount; List<CourseReportRow> get rows;
/// Create a copy of CoursesReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoursesReportCopyWith<CoursesReport> get copyWith => _$CoursesReportCopyWithImpl<CoursesReport>(this as CoursesReport, _$identity);

  /// Serializes this CoursesReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoursesReport&&(identical(other.window, window) || other.window == window)&&(identical(other.courseCount, courseCount) || other.courseCount == courseCount)&&const DeepCollectionEquality().equals(other.rows, rows));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,window,courseCount,const DeepCollectionEquality().hash(rows));

@override
String toString() {
  return 'CoursesReport(window: $window, courseCount: $courseCount, rows: $rows)';
}


}

/// @nodoc
abstract mixin class $CoursesReportCopyWith<$Res>  {
  factory $CoursesReportCopyWith(CoursesReport value, $Res Function(CoursesReport) _then) = _$CoursesReportCopyWithImpl;
@useResult
$Res call({
 ReportWindow window, int courseCount, List<CourseReportRow> rows
});


$ReportWindowCopyWith<$Res> get window;

}
/// @nodoc
class _$CoursesReportCopyWithImpl<$Res>
    implements $CoursesReportCopyWith<$Res> {
  _$CoursesReportCopyWithImpl(this._self, this._then);

  final CoursesReport _self;
  final $Res Function(CoursesReport) _then;

/// Create a copy of CoursesReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? window = null,Object? courseCount = null,Object? rows = null,}) {
  return _then(_self.copyWith(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as ReportWindow,courseCount: null == courseCount ? _self.courseCount : courseCount // ignore: cast_nullable_to_non_nullable
as int,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<CourseReportRow>,
  ));
}
/// Create a copy of CoursesReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportWindowCopyWith<$Res> get window {
  
  return $ReportWindowCopyWith<$Res>(_self.window, (value) {
    return _then(_self.copyWith(window: value));
  });
}
}


/// Adds pattern-matching-related methods to [CoursesReport].
extension CoursesReportPatterns on CoursesReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoursesReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoursesReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoursesReport value)  $default,){
final _that = this;
switch (_that) {
case _CoursesReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoursesReport value)?  $default,){
final _that = this;
switch (_that) {
case _CoursesReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReportWindow window,  int courseCount,  List<CourseReportRow> rows)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoursesReport() when $default != null:
return $default(_that.window,_that.courseCount,_that.rows);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReportWindow window,  int courseCount,  List<CourseReportRow> rows)  $default,) {final _that = this;
switch (_that) {
case _CoursesReport():
return $default(_that.window,_that.courseCount,_that.rows);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReportWindow window,  int courseCount,  List<CourseReportRow> rows)?  $default,) {final _that = this;
switch (_that) {
case _CoursesReport() when $default != null:
return $default(_that.window,_that.courseCount,_that.rows);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CoursesReport implements CoursesReport {
  const _CoursesReport({required this.window, this.courseCount = 0, final  List<CourseReportRow> rows = const <CourseReportRow>[]}): _rows = rows;
  factory _CoursesReport.fromJson(Map<String, dynamic> json) => _$CoursesReportFromJson(json);

@override final  ReportWindow window;
@override@JsonKey() final  int courseCount;
 final  List<CourseReportRow> _rows;
@override@JsonKey() List<CourseReportRow> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}


/// Create a copy of CoursesReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoursesReportCopyWith<_CoursesReport> get copyWith => __$CoursesReportCopyWithImpl<_CoursesReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoursesReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoursesReport&&(identical(other.window, window) || other.window == window)&&(identical(other.courseCount, courseCount) || other.courseCount == courseCount)&&const DeepCollectionEquality().equals(other._rows, _rows));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,window,courseCount,const DeepCollectionEquality().hash(_rows));

@override
String toString() {
  return 'CoursesReport(window: $window, courseCount: $courseCount, rows: $rows)';
}


}

/// @nodoc
abstract mixin class _$CoursesReportCopyWith<$Res> implements $CoursesReportCopyWith<$Res> {
  factory _$CoursesReportCopyWith(_CoursesReport value, $Res Function(_CoursesReport) _then) = __$CoursesReportCopyWithImpl;
@override @useResult
$Res call({
 ReportWindow window, int courseCount, List<CourseReportRow> rows
});


@override $ReportWindowCopyWith<$Res> get window;

}
/// @nodoc
class __$CoursesReportCopyWithImpl<$Res>
    implements _$CoursesReportCopyWith<$Res> {
  __$CoursesReportCopyWithImpl(this._self, this._then);

  final _CoursesReport _self;
  final $Res Function(_CoursesReport) _then;

/// Create a copy of CoursesReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? window = null,Object? courseCount = null,Object? rows = null,}) {
  return _then(_CoursesReport(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as ReportWindow,courseCount: null == courseCount ? _self.courseCount : courseCount // ignore: cast_nullable_to_non_nullable
as int,rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<CourseReportRow>,
  ));
}

/// Create a copy of CoursesReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportWindowCopyWith<$Res> get window {
  
  return $ReportWindowCopyWith<$Res>(_self.window, (value) {
    return _then(_self.copyWith(window: value));
  });
}
}


/// @nodoc
mixin _$ChapterReach {

 String get chapterId; String get title; int? get reached;
/// Create a copy of ChapterReach
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChapterReachCopyWith<ChapterReach> get copyWith => _$ChapterReachCopyWithImpl<ChapterReach>(this as ChapterReach, _$identity);

  /// Serializes this ChapterReach to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChapterReach&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.title, title) || other.title == title)&&(identical(other.reached, reached) || other.reached == reached));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,chapterId,title,reached);

@override
String toString() {
  return 'ChapterReach(chapterId: $chapterId, title: $title, reached: $reached)';
}


}

/// @nodoc
abstract mixin class $ChapterReachCopyWith<$Res>  {
  factory $ChapterReachCopyWith(ChapterReach value, $Res Function(ChapterReach) _then) = _$ChapterReachCopyWithImpl;
@useResult
$Res call({
 String chapterId, String title, int? reached
});




}
/// @nodoc
class _$ChapterReachCopyWithImpl<$Res>
    implements $ChapterReachCopyWith<$Res> {
  _$ChapterReachCopyWithImpl(this._self, this._then);

  final ChapterReach _self;
  final $Res Function(ChapterReach) _then;

/// Create a copy of ChapterReach
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? chapterId = null,Object? title = null,Object? reached = freezed,}) {
  return _then(_self.copyWith(
chapterId: null == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,reached: freezed == reached ? _self.reached : reached // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChapterReach].
extension ChapterReachPatterns on ChapterReach {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChapterReach value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChapterReach() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChapterReach value)  $default,){
final _that = this;
switch (_that) {
case _ChapterReach():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChapterReach value)?  $default,){
final _that = this;
switch (_that) {
case _ChapterReach() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String chapterId,  String title,  int? reached)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChapterReach() when $default != null:
return $default(_that.chapterId,_that.title,_that.reached);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String chapterId,  String title,  int? reached)  $default,) {final _that = this;
switch (_that) {
case _ChapterReach():
return $default(_that.chapterId,_that.title,_that.reached);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String chapterId,  String title,  int? reached)?  $default,) {final _that = this;
switch (_that) {
case _ChapterReach() when $default != null:
return $default(_that.chapterId,_that.title,_that.reached);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChapterReach implements ChapterReach {
  const _ChapterReach({this.chapterId = '', this.title = '', this.reached});
  factory _ChapterReach.fromJson(Map<String, dynamic> json) => _$ChapterReachFromJson(json);

@override@JsonKey() final  String chapterId;
@override@JsonKey() final  String title;
@override final  int? reached;

/// Create a copy of ChapterReach
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChapterReachCopyWith<_ChapterReach> get copyWith => __$ChapterReachCopyWithImpl<_ChapterReach>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChapterReachToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChapterReach&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.title, title) || other.title == title)&&(identical(other.reached, reached) || other.reached == reached));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,chapterId,title,reached);

@override
String toString() {
  return 'ChapterReach(chapterId: $chapterId, title: $title, reached: $reached)';
}


}

/// @nodoc
abstract mixin class _$ChapterReachCopyWith<$Res> implements $ChapterReachCopyWith<$Res> {
  factory _$ChapterReachCopyWith(_ChapterReach value, $Res Function(_ChapterReach) _then) = __$ChapterReachCopyWithImpl;
@override @useResult
$Res call({
 String chapterId, String title, int? reached
});




}
/// @nodoc
class __$ChapterReachCopyWithImpl<$Res>
    implements _$ChapterReachCopyWith<$Res> {
  __$ChapterReachCopyWithImpl(this._self, this._then);

  final _ChapterReach _self;
  final $Res Function(_ChapterReach) _then;

/// Create a copy of ChapterReach
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? chapterId = null,Object? title = null,Object? reached = freezed,}) {
  return _then(_ChapterReach(
chapterId: null == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,reached: freezed == reached ? _self.reached : reached // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$QuizReportRow {

 String get quizId; String get title; int get attempts; int? get passRate; int? get avgScore;
/// Create a copy of QuizReportRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizReportRowCopyWith<QuizReportRow> get copyWith => _$QuizReportRowCopyWithImpl<QuizReportRow>(this as QuizReportRow, _$identity);

  /// Serializes this QuizReportRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizReportRow&&(identical(other.quizId, quizId) || other.quizId == quizId)&&(identical(other.title, title) || other.title == title)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.passRate, passRate) || other.passRate == passRate)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quizId,title,attempts,passRate,avgScore);

@override
String toString() {
  return 'QuizReportRow(quizId: $quizId, title: $title, attempts: $attempts, passRate: $passRate, avgScore: $avgScore)';
}


}

/// @nodoc
abstract mixin class $QuizReportRowCopyWith<$Res>  {
  factory $QuizReportRowCopyWith(QuizReportRow value, $Res Function(QuizReportRow) _then) = _$QuizReportRowCopyWithImpl;
@useResult
$Res call({
 String quizId, String title, int attempts, int? passRate, int? avgScore
});




}
/// @nodoc
class _$QuizReportRowCopyWithImpl<$Res>
    implements $QuizReportRowCopyWith<$Res> {
  _$QuizReportRowCopyWithImpl(this._self, this._then);

  final QuizReportRow _self;
  final $Res Function(QuizReportRow) _then;

/// Create a copy of QuizReportRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quizId = null,Object? title = null,Object? attempts = null,Object? passRate = freezed,Object? avgScore = freezed,}) {
  return _then(_self.copyWith(
quizId: null == quizId ? _self.quizId : quizId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,passRate: freezed == passRate ? _self.passRate : passRate // ignore: cast_nullable_to_non_nullable
as int?,avgScore: freezed == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuizReportRow].
extension QuizReportRowPatterns on QuizReportRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizReportRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizReportRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizReportRow value)  $default,){
final _that = this;
switch (_that) {
case _QuizReportRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizReportRow value)?  $default,){
final _that = this;
switch (_that) {
case _QuizReportRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String quizId,  String title,  int attempts,  int? passRate,  int? avgScore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizReportRow() when $default != null:
return $default(_that.quizId,_that.title,_that.attempts,_that.passRate,_that.avgScore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String quizId,  String title,  int attempts,  int? passRate,  int? avgScore)  $default,) {final _that = this;
switch (_that) {
case _QuizReportRow():
return $default(_that.quizId,_that.title,_that.attempts,_that.passRate,_that.avgScore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String quizId,  String title,  int attempts,  int? passRate,  int? avgScore)?  $default,) {final _that = this;
switch (_that) {
case _QuizReportRow() when $default != null:
return $default(_that.quizId,_that.title,_that.attempts,_that.passRate,_that.avgScore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizReportRow implements QuizReportRow {
  const _QuizReportRow({this.quizId = '', this.title = '', this.attempts = 0, this.passRate, this.avgScore});
  factory _QuizReportRow.fromJson(Map<String, dynamic> json) => _$QuizReportRowFromJson(json);

@override@JsonKey() final  String quizId;
@override@JsonKey() final  String title;
@override@JsonKey() final  int attempts;
@override final  int? passRate;
@override final  int? avgScore;

/// Create a copy of QuizReportRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizReportRowCopyWith<_QuizReportRow> get copyWith => __$QuizReportRowCopyWithImpl<_QuizReportRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizReportRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizReportRow&&(identical(other.quizId, quizId) || other.quizId == quizId)&&(identical(other.title, title) || other.title == title)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.passRate, passRate) || other.passRate == passRate)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quizId,title,attempts,passRate,avgScore);

@override
String toString() {
  return 'QuizReportRow(quizId: $quizId, title: $title, attempts: $attempts, passRate: $passRate, avgScore: $avgScore)';
}


}

/// @nodoc
abstract mixin class _$QuizReportRowCopyWith<$Res> implements $QuizReportRowCopyWith<$Res> {
  factory _$QuizReportRowCopyWith(_QuizReportRow value, $Res Function(_QuizReportRow) _then) = __$QuizReportRowCopyWithImpl;
@override @useResult
$Res call({
 String quizId, String title, int attempts, int? passRate, int? avgScore
});




}
/// @nodoc
class __$QuizReportRowCopyWithImpl<$Res>
    implements _$QuizReportRowCopyWith<$Res> {
  __$QuizReportRowCopyWithImpl(this._self, this._then);

  final _QuizReportRow _self;
  final $Res Function(_QuizReportRow) _then;

/// Create a copy of QuizReportRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quizId = null,Object? title = null,Object? attempts = null,Object? passRate = freezed,Object? avgScore = freezed,}) {
  return _then(_QuizReportRow(
quizId: null == quizId ? _self.quizId : quizId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,passRate: freezed == passRate ? _self.passRate : passRate // ignore: cast_nullable_to_non_nullable
as int?,avgScore: freezed == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$AssignmentReportRow {

 String get assignmentId; String get title; int get submitted; int? get passRate; int? get avgScore; int? get onTime;
/// Create a copy of AssignmentReportRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssignmentReportRowCopyWith<AssignmentReportRow> get copyWith => _$AssignmentReportRowCopyWithImpl<AssignmentReportRow>(this as AssignmentReportRow, _$identity);

  /// Serializes this AssignmentReportRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssignmentReportRow&&(identical(other.assignmentId, assignmentId) || other.assignmentId == assignmentId)&&(identical(other.title, title) || other.title == title)&&(identical(other.submitted, submitted) || other.submitted == submitted)&&(identical(other.passRate, passRate) || other.passRate == passRate)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore)&&(identical(other.onTime, onTime) || other.onTime == onTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assignmentId,title,submitted,passRate,avgScore,onTime);

@override
String toString() {
  return 'AssignmentReportRow(assignmentId: $assignmentId, title: $title, submitted: $submitted, passRate: $passRate, avgScore: $avgScore, onTime: $onTime)';
}


}

/// @nodoc
abstract mixin class $AssignmentReportRowCopyWith<$Res>  {
  factory $AssignmentReportRowCopyWith(AssignmentReportRow value, $Res Function(AssignmentReportRow) _then) = _$AssignmentReportRowCopyWithImpl;
@useResult
$Res call({
 String assignmentId, String title, int submitted, int? passRate, int? avgScore, int? onTime
});




}
/// @nodoc
class _$AssignmentReportRowCopyWithImpl<$Res>
    implements $AssignmentReportRowCopyWith<$Res> {
  _$AssignmentReportRowCopyWithImpl(this._self, this._then);

  final AssignmentReportRow _self;
  final $Res Function(AssignmentReportRow) _then;

/// Create a copy of AssignmentReportRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? assignmentId = null,Object? title = null,Object? submitted = null,Object? passRate = freezed,Object? avgScore = freezed,Object? onTime = freezed,}) {
  return _then(_self.copyWith(
assignmentId: null == assignmentId ? _self.assignmentId : assignmentId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,submitted: null == submitted ? _self.submitted : submitted // ignore: cast_nullable_to_non_nullable
as int,passRate: freezed == passRate ? _self.passRate : passRate // ignore: cast_nullable_to_non_nullable
as int?,avgScore: freezed == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as int?,onTime: freezed == onTime ? _self.onTime : onTime // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AssignmentReportRow].
extension AssignmentReportRowPatterns on AssignmentReportRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssignmentReportRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssignmentReportRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssignmentReportRow value)  $default,){
final _that = this;
switch (_that) {
case _AssignmentReportRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssignmentReportRow value)?  $default,){
final _that = this;
switch (_that) {
case _AssignmentReportRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String assignmentId,  String title,  int submitted,  int? passRate,  int? avgScore,  int? onTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssignmentReportRow() when $default != null:
return $default(_that.assignmentId,_that.title,_that.submitted,_that.passRate,_that.avgScore,_that.onTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String assignmentId,  String title,  int submitted,  int? passRate,  int? avgScore,  int? onTime)  $default,) {final _that = this;
switch (_that) {
case _AssignmentReportRow():
return $default(_that.assignmentId,_that.title,_that.submitted,_that.passRate,_that.avgScore,_that.onTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String assignmentId,  String title,  int submitted,  int? passRate,  int? avgScore,  int? onTime)?  $default,) {final _that = this;
switch (_that) {
case _AssignmentReportRow() when $default != null:
return $default(_that.assignmentId,_that.title,_that.submitted,_that.passRate,_that.avgScore,_that.onTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssignmentReportRow implements AssignmentReportRow {
  const _AssignmentReportRow({this.assignmentId = '', this.title = '', this.submitted = 0, this.passRate, this.avgScore, this.onTime});
  factory _AssignmentReportRow.fromJson(Map<String, dynamic> json) => _$AssignmentReportRowFromJson(json);

@override@JsonKey() final  String assignmentId;
@override@JsonKey() final  String title;
@override@JsonKey() final  int submitted;
@override final  int? passRate;
@override final  int? avgScore;
@override final  int? onTime;

/// Create a copy of AssignmentReportRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssignmentReportRowCopyWith<_AssignmentReportRow> get copyWith => __$AssignmentReportRowCopyWithImpl<_AssignmentReportRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssignmentReportRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssignmentReportRow&&(identical(other.assignmentId, assignmentId) || other.assignmentId == assignmentId)&&(identical(other.title, title) || other.title == title)&&(identical(other.submitted, submitted) || other.submitted == submitted)&&(identical(other.passRate, passRate) || other.passRate == passRate)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore)&&(identical(other.onTime, onTime) || other.onTime == onTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assignmentId,title,submitted,passRate,avgScore,onTime);

@override
String toString() {
  return 'AssignmentReportRow(assignmentId: $assignmentId, title: $title, submitted: $submitted, passRate: $passRate, avgScore: $avgScore, onTime: $onTime)';
}


}

/// @nodoc
abstract mixin class _$AssignmentReportRowCopyWith<$Res> implements $AssignmentReportRowCopyWith<$Res> {
  factory _$AssignmentReportRowCopyWith(_AssignmentReportRow value, $Res Function(_AssignmentReportRow) _then) = __$AssignmentReportRowCopyWithImpl;
@override @useResult
$Res call({
 String assignmentId, String title, int submitted, int? passRate, int? avgScore, int? onTime
});




}
/// @nodoc
class __$AssignmentReportRowCopyWithImpl<$Res>
    implements _$AssignmentReportRowCopyWith<$Res> {
  __$AssignmentReportRowCopyWithImpl(this._self, this._then);

  final _AssignmentReportRow _self;
  final $Res Function(_AssignmentReportRow) _then;

/// Create a copy of AssignmentReportRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? assignmentId = null,Object? title = null,Object? submitted = null,Object? passRate = freezed,Object? avgScore = freezed,Object? onTime = freezed,}) {
  return _then(_AssignmentReportRow(
assignmentId: null == assignmentId ? _self.assignmentId : assignmentId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,submitted: null == submitted ? _self.submitted : submitted // ignore: cast_nullable_to_non_nullable
as int,passRate: freezed == passRate ? _self.passRate : passRate // ignore: cast_nullable_to_non_nullable
as int?,avgScore: freezed == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as int?,onTime: freezed == onTime ? _self.onTime : onTime // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$CourseReportKpis {

 Kpi get enrollments; Kpi get completionRate; Kpi get activeLearners; Kpi get avgProgress;
/// Create a copy of CourseReportKpis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseReportKpisCopyWith<CourseReportKpis> get copyWith => _$CourseReportKpisCopyWithImpl<CourseReportKpis>(this as CourseReportKpis, _$identity);

  /// Serializes this CourseReportKpis to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseReportKpis&&(identical(other.enrollments, enrollments) || other.enrollments == enrollments)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.activeLearners, activeLearners) || other.activeLearners == activeLearners)&&(identical(other.avgProgress, avgProgress) || other.avgProgress == avgProgress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrollments,completionRate,activeLearners,avgProgress);

@override
String toString() {
  return 'CourseReportKpis(enrollments: $enrollments, completionRate: $completionRate, activeLearners: $activeLearners, avgProgress: $avgProgress)';
}


}

/// @nodoc
abstract mixin class $CourseReportKpisCopyWith<$Res>  {
  factory $CourseReportKpisCopyWith(CourseReportKpis value, $Res Function(CourseReportKpis) _then) = _$CourseReportKpisCopyWithImpl;
@useResult
$Res call({
 Kpi enrollments, Kpi completionRate, Kpi activeLearners, Kpi avgProgress
});


$KpiCopyWith<$Res> get enrollments;$KpiCopyWith<$Res> get completionRate;$KpiCopyWith<$Res> get activeLearners;$KpiCopyWith<$Res> get avgProgress;

}
/// @nodoc
class _$CourseReportKpisCopyWithImpl<$Res>
    implements $CourseReportKpisCopyWith<$Res> {
  _$CourseReportKpisCopyWithImpl(this._self, this._then);

  final CourseReportKpis _self;
  final $Res Function(CourseReportKpis) _then;

/// Create a copy of CourseReportKpis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enrollments = null,Object? completionRate = null,Object? activeLearners = null,Object? avgProgress = null,}) {
  return _then(_self.copyWith(
enrollments: null == enrollments ? _self.enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as Kpi,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as Kpi,activeLearners: null == activeLearners ? _self.activeLearners : activeLearners // ignore: cast_nullable_to_non_nullable
as Kpi,avgProgress: null == avgProgress ? _self.avgProgress : avgProgress // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}
/// Create a copy of CourseReportKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get enrollments {
  
  return $KpiCopyWith<$Res>(_self.enrollments, (value) {
    return _then(_self.copyWith(enrollments: value));
  });
}/// Create a copy of CourseReportKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get completionRate {
  
  return $KpiCopyWith<$Res>(_self.completionRate, (value) {
    return _then(_self.copyWith(completionRate: value));
  });
}/// Create a copy of CourseReportKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get activeLearners {
  
  return $KpiCopyWith<$Res>(_self.activeLearners, (value) {
    return _then(_self.copyWith(activeLearners: value));
  });
}/// Create a copy of CourseReportKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get avgProgress {
  
  return $KpiCopyWith<$Res>(_self.avgProgress, (value) {
    return _then(_self.copyWith(avgProgress: value));
  });
}
}


/// Adds pattern-matching-related methods to [CourseReportKpis].
extension CourseReportKpisPatterns on CourseReportKpis {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseReportKpis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseReportKpis() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseReportKpis value)  $default,){
final _that = this;
switch (_that) {
case _CourseReportKpis():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseReportKpis value)?  $default,){
final _that = this;
switch (_that) {
case _CourseReportKpis() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Kpi enrollments,  Kpi completionRate,  Kpi activeLearners,  Kpi avgProgress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseReportKpis() when $default != null:
return $default(_that.enrollments,_that.completionRate,_that.activeLearners,_that.avgProgress);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Kpi enrollments,  Kpi completionRate,  Kpi activeLearners,  Kpi avgProgress)  $default,) {final _that = this;
switch (_that) {
case _CourseReportKpis():
return $default(_that.enrollments,_that.completionRate,_that.activeLearners,_that.avgProgress);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Kpi enrollments,  Kpi completionRate,  Kpi activeLearners,  Kpi avgProgress)?  $default,) {final _that = this;
switch (_that) {
case _CourseReportKpis() when $default != null:
return $default(_that.enrollments,_that.completionRate,_that.activeLearners,_that.avgProgress);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseReportKpis implements CourseReportKpis {
  const _CourseReportKpis({this.enrollments = const Kpi(), this.completionRate = const Kpi(), this.activeLearners = const Kpi(), this.avgProgress = const Kpi()});
  factory _CourseReportKpis.fromJson(Map<String, dynamic> json) => _$CourseReportKpisFromJson(json);

@override@JsonKey() final  Kpi enrollments;
@override@JsonKey() final  Kpi completionRate;
@override@JsonKey() final  Kpi activeLearners;
@override@JsonKey() final  Kpi avgProgress;

/// Create a copy of CourseReportKpis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseReportKpisCopyWith<_CourseReportKpis> get copyWith => __$CourseReportKpisCopyWithImpl<_CourseReportKpis>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseReportKpisToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseReportKpis&&(identical(other.enrollments, enrollments) || other.enrollments == enrollments)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.activeLearners, activeLearners) || other.activeLearners == activeLearners)&&(identical(other.avgProgress, avgProgress) || other.avgProgress == avgProgress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrollments,completionRate,activeLearners,avgProgress);

@override
String toString() {
  return 'CourseReportKpis(enrollments: $enrollments, completionRate: $completionRate, activeLearners: $activeLearners, avgProgress: $avgProgress)';
}


}

/// @nodoc
abstract mixin class _$CourseReportKpisCopyWith<$Res> implements $CourseReportKpisCopyWith<$Res> {
  factory _$CourseReportKpisCopyWith(_CourseReportKpis value, $Res Function(_CourseReportKpis) _then) = __$CourseReportKpisCopyWithImpl;
@override @useResult
$Res call({
 Kpi enrollments, Kpi completionRate, Kpi activeLearners, Kpi avgProgress
});


@override $KpiCopyWith<$Res> get enrollments;@override $KpiCopyWith<$Res> get completionRate;@override $KpiCopyWith<$Res> get activeLearners;@override $KpiCopyWith<$Res> get avgProgress;

}
/// @nodoc
class __$CourseReportKpisCopyWithImpl<$Res>
    implements _$CourseReportKpisCopyWith<$Res> {
  __$CourseReportKpisCopyWithImpl(this._self, this._then);

  final _CourseReportKpis _self;
  final $Res Function(_CourseReportKpis) _then;

/// Create a copy of CourseReportKpis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enrollments = null,Object? completionRate = null,Object? activeLearners = null,Object? avgProgress = null,}) {
  return _then(_CourseReportKpis(
enrollments: null == enrollments ? _self.enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as Kpi,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as Kpi,activeLearners: null == activeLearners ? _self.activeLearners : activeLearners // ignore: cast_nullable_to_non_nullable
as Kpi,avgProgress: null == avgProgress ? _self.avgProgress : avgProgress // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}

/// Create a copy of CourseReportKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get enrollments {
  
  return $KpiCopyWith<$Res>(_self.enrollments, (value) {
    return _then(_self.copyWith(enrollments: value));
  });
}/// Create a copy of CourseReportKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get completionRate {
  
  return $KpiCopyWith<$Res>(_self.completionRate, (value) {
    return _then(_self.copyWith(completionRate: value));
  });
}/// Create a copy of CourseReportKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get activeLearners {
  
  return $KpiCopyWith<$Res>(_self.activeLearners, (value) {
    return _then(_self.copyWith(activeLearners: value));
  });
}/// Create a copy of CourseReportKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get avgProgress {
  
  return $KpiCopyWith<$Res>(_self.avgProgress, (value) {
    return _then(_self.copyWith(avgProgress: value));
  });
}
}


/// @nodoc
mixin _$CourseReport {

 ReportWindow get window; int get courseCount; CourseReportRow get row; CourseReportKpis get kpis; ReportSeries get series; List<LabelledCount> get funnel; List<ChapterReach> get chapters; List<QuizReportRow> get quizzes; List<AssignmentReportRow> get assignments;
/// Create a copy of CourseReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseReportCopyWith<CourseReport> get copyWith => _$CourseReportCopyWithImpl<CourseReport>(this as CourseReport, _$identity);

  /// Serializes this CourseReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseReport&&(identical(other.window, window) || other.window == window)&&(identical(other.courseCount, courseCount) || other.courseCount == courseCount)&&(identical(other.row, row) || other.row == row)&&(identical(other.kpis, kpis) || other.kpis == kpis)&&(identical(other.series, series) || other.series == series)&&const DeepCollectionEquality().equals(other.funnel, funnel)&&const DeepCollectionEquality().equals(other.chapters, chapters)&&const DeepCollectionEquality().equals(other.quizzes, quizzes)&&const DeepCollectionEquality().equals(other.assignments, assignments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,window,courseCount,row,kpis,series,const DeepCollectionEquality().hash(funnel),const DeepCollectionEquality().hash(chapters),const DeepCollectionEquality().hash(quizzes),const DeepCollectionEquality().hash(assignments));

@override
String toString() {
  return 'CourseReport(window: $window, courseCount: $courseCount, row: $row, kpis: $kpis, series: $series, funnel: $funnel, chapters: $chapters, quizzes: $quizzes, assignments: $assignments)';
}


}

/// @nodoc
abstract mixin class $CourseReportCopyWith<$Res>  {
  factory $CourseReportCopyWith(CourseReport value, $Res Function(CourseReport) _then) = _$CourseReportCopyWithImpl;
@useResult
$Res call({
 ReportWindow window, int courseCount, CourseReportRow row, CourseReportKpis kpis, ReportSeries series, List<LabelledCount> funnel, List<ChapterReach> chapters, List<QuizReportRow> quizzes, List<AssignmentReportRow> assignments
});


$ReportWindowCopyWith<$Res> get window;$CourseReportRowCopyWith<$Res> get row;$CourseReportKpisCopyWith<$Res> get kpis;$ReportSeriesCopyWith<$Res> get series;

}
/// @nodoc
class _$CourseReportCopyWithImpl<$Res>
    implements $CourseReportCopyWith<$Res> {
  _$CourseReportCopyWithImpl(this._self, this._then);

  final CourseReport _self;
  final $Res Function(CourseReport) _then;

/// Create a copy of CourseReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? window = null,Object? courseCount = null,Object? row = null,Object? kpis = null,Object? series = null,Object? funnel = null,Object? chapters = null,Object? quizzes = null,Object? assignments = null,}) {
  return _then(_self.copyWith(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as ReportWindow,courseCount: null == courseCount ? _self.courseCount : courseCount // ignore: cast_nullable_to_non_nullable
as int,row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as CourseReportRow,kpis: null == kpis ? _self.kpis : kpis // ignore: cast_nullable_to_non_nullable
as CourseReportKpis,series: null == series ? _self.series : series // ignore: cast_nullable_to_non_nullable
as ReportSeries,funnel: null == funnel ? _self.funnel : funnel // ignore: cast_nullable_to_non_nullable
as List<LabelledCount>,chapters: null == chapters ? _self.chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<ChapterReach>,quizzes: null == quizzes ? _self.quizzes : quizzes // ignore: cast_nullable_to_non_nullable
as List<QuizReportRow>,assignments: null == assignments ? _self.assignments : assignments // ignore: cast_nullable_to_non_nullable
as List<AssignmentReportRow>,
  ));
}
/// Create a copy of CourseReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportWindowCopyWith<$Res> get window {
  
  return $ReportWindowCopyWith<$Res>(_self.window, (value) {
    return _then(_self.copyWith(window: value));
  });
}/// Create a copy of CourseReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseReportRowCopyWith<$Res> get row {
  
  return $CourseReportRowCopyWith<$Res>(_self.row, (value) {
    return _then(_self.copyWith(row: value));
  });
}/// Create a copy of CourseReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseReportKpisCopyWith<$Res> get kpis {
  
  return $CourseReportKpisCopyWith<$Res>(_self.kpis, (value) {
    return _then(_self.copyWith(kpis: value));
  });
}/// Create a copy of CourseReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportSeriesCopyWith<$Res> get series {
  
  return $ReportSeriesCopyWith<$Res>(_self.series, (value) {
    return _then(_self.copyWith(series: value));
  });
}
}


/// Adds pattern-matching-related methods to [CourseReport].
extension CourseReportPatterns on CourseReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseReport value)  $default,){
final _that = this;
switch (_that) {
case _CourseReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseReport value)?  $default,){
final _that = this;
switch (_that) {
case _CourseReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReportWindow window,  int courseCount,  CourseReportRow row,  CourseReportKpis kpis,  ReportSeries series,  List<LabelledCount> funnel,  List<ChapterReach> chapters,  List<QuizReportRow> quizzes,  List<AssignmentReportRow> assignments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseReport() when $default != null:
return $default(_that.window,_that.courseCount,_that.row,_that.kpis,_that.series,_that.funnel,_that.chapters,_that.quizzes,_that.assignments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReportWindow window,  int courseCount,  CourseReportRow row,  CourseReportKpis kpis,  ReportSeries series,  List<LabelledCount> funnel,  List<ChapterReach> chapters,  List<QuizReportRow> quizzes,  List<AssignmentReportRow> assignments)  $default,) {final _that = this;
switch (_that) {
case _CourseReport():
return $default(_that.window,_that.courseCount,_that.row,_that.kpis,_that.series,_that.funnel,_that.chapters,_that.quizzes,_that.assignments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReportWindow window,  int courseCount,  CourseReportRow row,  CourseReportKpis kpis,  ReportSeries series,  List<LabelledCount> funnel,  List<ChapterReach> chapters,  List<QuizReportRow> quizzes,  List<AssignmentReportRow> assignments)?  $default,) {final _that = this;
switch (_that) {
case _CourseReport() when $default != null:
return $default(_that.window,_that.courseCount,_that.row,_that.kpis,_that.series,_that.funnel,_that.chapters,_that.quizzes,_that.assignments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseReport implements CourseReport {
  const _CourseReport({required this.window, this.courseCount = 0, this.row = const CourseReportRow(), this.kpis = const CourseReportKpis(), this.series = const ReportSeries(), final  List<LabelledCount> funnel = const <LabelledCount>[], final  List<ChapterReach> chapters = const <ChapterReach>[], final  List<QuizReportRow> quizzes = const <QuizReportRow>[], final  List<AssignmentReportRow> assignments = const <AssignmentReportRow>[]}): _funnel = funnel,_chapters = chapters,_quizzes = quizzes,_assignments = assignments;
  factory _CourseReport.fromJson(Map<String, dynamic> json) => _$CourseReportFromJson(json);

@override final  ReportWindow window;
@override@JsonKey() final  int courseCount;
@override@JsonKey() final  CourseReportRow row;
@override@JsonKey() final  CourseReportKpis kpis;
@override@JsonKey() final  ReportSeries series;
 final  List<LabelledCount> _funnel;
@override@JsonKey() List<LabelledCount> get funnel {
  if (_funnel is EqualUnmodifiableListView) return _funnel;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_funnel);
}

 final  List<ChapterReach> _chapters;
@override@JsonKey() List<ChapterReach> get chapters {
  if (_chapters is EqualUnmodifiableListView) return _chapters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_chapters);
}

 final  List<QuizReportRow> _quizzes;
@override@JsonKey() List<QuizReportRow> get quizzes {
  if (_quizzes is EqualUnmodifiableListView) return _quizzes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_quizzes);
}

 final  List<AssignmentReportRow> _assignments;
@override@JsonKey() List<AssignmentReportRow> get assignments {
  if (_assignments is EqualUnmodifiableListView) return _assignments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assignments);
}


/// Create a copy of CourseReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseReportCopyWith<_CourseReport> get copyWith => __$CourseReportCopyWithImpl<_CourseReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseReport&&(identical(other.window, window) || other.window == window)&&(identical(other.courseCount, courseCount) || other.courseCount == courseCount)&&(identical(other.row, row) || other.row == row)&&(identical(other.kpis, kpis) || other.kpis == kpis)&&(identical(other.series, series) || other.series == series)&&const DeepCollectionEquality().equals(other._funnel, _funnel)&&const DeepCollectionEquality().equals(other._chapters, _chapters)&&const DeepCollectionEquality().equals(other._quizzes, _quizzes)&&const DeepCollectionEquality().equals(other._assignments, _assignments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,window,courseCount,row,kpis,series,const DeepCollectionEquality().hash(_funnel),const DeepCollectionEquality().hash(_chapters),const DeepCollectionEquality().hash(_quizzes),const DeepCollectionEquality().hash(_assignments));

@override
String toString() {
  return 'CourseReport(window: $window, courseCount: $courseCount, row: $row, kpis: $kpis, series: $series, funnel: $funnel, chapters: $chapters, quizzes: $quizzes, assignments: $assignments)';
}


}

/// @nodoc
abstract mixin class _$CourseReportCopyWith<$Res> implements $CourseReportCopyWith<$Res> {
  factory _$CourseReportCopyWith(_CourseReport value, $Res Function(_CourseReport) _then) = __$CourseReportCopyWithImpl;
@override @useResult
$Res call({
 ReportWindow window, int courseCount, CourseReportRow row, CourseReportKpis kpis, ReportSeries series, List<LabelledCount> funnel, List<ChapterReach> chapters, List<QuizReportRow> quizzes, List<AssignmentReportRow> assignments
});


@override $ReportWindowCopyWith<$Res> get window;@override $CourseReportRowCopyWith<$Res> get row;@override $CourseReportKpisCopyWith<$Res> get kpis;@override $ReportSeriesCopyWith<$Res> get series;

}
/// @nodoc
class __$CourseReportCopyWithImpl<$Res>
    implements _$CourseReportCopyWith<$Res> {
  __$CourseReportCopyWithImpl(this._self, this._then);

  final _CourseReport _self;
  final $Res Function(_CourseReport) _then;

/// Create a copy of CourseReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? window = null,Object? courseCount = null,Object? row = null,Object? kpis = null,Object? series = null,Object? funnel = null,Object? chapters = null,Object? quizzes = null,Object? assignments = null,}) {
  return _then(_CourseReport(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as ReportWindow,courseCount: null == courseCount ? _self.courseCount : courseCount // ignore: cast_nullable_to_non_nullable
as int,row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as CourseReportRow,kpis: null == kpis ? _self.kpis : kpis // ignore: cast_nullable_to_non_nullable
as CourseReportKpis,series: null == series ? _self.series : series // ignore: cast_nullable_to_non_nullable
as ReportSeries,funnel: null == funnel ? _self._funnel : funnel // ignore: cast_nullable_to_non_nullable
as List<LabelledCount>,chapters: null == chapters ? _self._chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<ChapterReach>,quizzes: null == quizzes ? _self._quizzes : quizzes // ignore: cast_nullable_to_non_nullable
as List<QuizReportRow>,assignments: null == assignments ? _self._assignments : assignments // ignore: cast_nullable_to_non_nullable
as List<AssignmentReportRow>,
  ));
}

/// Create a copy of CourseReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportWindowCopyWith<$Res> get window {
  
  return $ReportWindowCopyWith<$Res>(_self.window, (value) {
    return _then(_self.copyWith(window: value));
  });
}/// Create a copy of CourseReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseReportRowCopyWith<$Res> get row {
  
  return $CourseReportRowCopyWith<$Res>(_self.row, (value) {
    return _then(_self.copyWith(row: value));
  });
}/// Create a copy of CourseReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseReportKpisCopyWith<$Res> get kpis {
  
  return $CourseReportKpisCopyWith<$Res>(_self.kpis, (value) {
    return _then(_self.copyWith(kpis: value));
  });
}/// Create a copy of CourseReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportSeriesCopyWith<$Res> get series {
  
  return $ReportSeriesCopyWith<$Res>(_self.series, (value) {
    return _then(_self.copyWith(series: value));
  });
}
}


/// @nodoc
mixin _$LearnerReportKpis {

 Kpi get learners; Kpi get active;@JsonKey(name: 'atRisk') Kpi get atRisk; Kpi get avgProgress;
/// Create a copy of LearnerReportKpis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearnerReportKpisCopyWith<LearnerReportKpis> get copyWith => _$LearnerReportKpisCopyWithImpl<LearnerReportKpis>(this as LearnerReportKpis, _$identity);

  /// Serializes this LearnerReportKpis to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearnerReportKpis&&(identical(other.learners, learners) || other.learners == learners)&&(identical(other.active, active) || other.active == active)&&(identical(other.atRisk, atRisk) || other.atRisk == atRisk)&&(identical(other.avgProgress, avgProgress) || other.avgProgress == avgProgress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,learners,active,atRisk,avgProgress);

@override
String toString() {
  return 'LearnerReportKpis(learners: $learners, active: $active, atRisk: $atRisk, avgProgress: $avgProgress)';
}


}

/// @nodoc
abstract mixin class $LearnerReportKpisCopyWith<$Res>  {
  factory $LearnerReportKpisCopyWith(LearnerReportKpis value, $Res Function(LearnerReportKpis) _then) = _$LearnerReportKpisCopyWithImpl;
@useResult
$Res call({
 Kpi learners, Kpi active,@JsonKey(name: 'atRisk') Kpi atRisk, Kpi avgProgress
});


$KpiCopyWith<$Res> get learners;$KpiCopyWith<$Res> get active;$KpiCopyWith<$Res> get atRisk;$KpiCopyWith<$Res> get avgProgress;

}
/// @nodoc
class _$LearnerReportKpisCopyWithImpl<$Res>
    implements $LearnerReportKpisCopyWith<$Res> {
  _$LearnerReportKpisCopyWithImpl(this._self, this._then);

  final LearnerReportKpis _self;
  final $Res Function(LearnerReportKpis) _then;

/// Create a copy of LearnerReportKpis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? learners = null,Object? active = null,Object? atRisk = null,Object? avgProgress = null,}) {
  return _then(_self.copyWith(
learners: null == learners ? _self.learners : learners // ignore: cast_nullable_to_non_nullable
as Kpi,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as Kpi,atRisk: null == atRisk ? _self.atRisk : atRisk // ignore: cast_nullable_to_non_nullable
as Kpi,avgProgress: null == avgProgress ? _self.avgProgress : avgProgress // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}
/// Create a copy of LearnerReportKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get learners {
  
  return $KpiCopyWith<$Res>(_self.learners, (value) {
    return _then(_self.copyWith(learners: value));
  });
}/// Create a copy of LearnerReportKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get active {
  
  return $KpiCopyWith<$Res>(_self.active, (value) {
    return _then(_self.copyWith(active: value));
  });
}/// Create a copy of LearnerReportKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get atRisk {
  
  return $KpiCopyWith<$Res>(_self.atRisk, (value) {
    return _then(_self.copyWith(atRisk: value));
  });
}/// Create a copy of LearnerReportKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get avgProgress {
  
  return $KpiCopyWith<$Res>(_self.avgProgress, (value) {
    return _then(_self.copyWith(avgProgress: value));
  });
}
}


/// Adds pattern-matching-related methods to [LearnerReportKpis].
extension LearnerReportKpisPatterns on LearnerReportKpis {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearnerReportKpis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearnerReportKpis() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearnerReportKpis value)  $default,){
final _that = this;
switch (_that) {
case _LearnerReportKpis():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearnerReportKpis value)?  $default,){
final _that = this;
switch (_that) {
case _LearnerReportKpis() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Kpi learners,  Kpi active, @JsonKey(name: 'atRisk')  Kpi atRisk,  Kpi avgProgress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearnerReportKpis() when $default != null:
return $default(_that.learners,_that.active,_that.atRisk,_that.avgProgress);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Kpi learners,  Kpi active, @JsonKey(name: 'atRisk')  Kpi atRisk,  Kpi avgProgress)  $default,) {final _that = this;
switch (_that) {
case _LearnerReportKpis():
return $default(_that.learners,_that.active,_that.atRisk,_that.avgProgress);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Kpi learners,  Kpi active, @JsonKey(name: 'atRisk')  Kpi atRisk,  Kpi avgProgress)?  $default,) {final _that = this;
switch (_that) {
case _LearnerReportKpis() when $default != null:
return $default(_that.learners,_that.active,_that.atRisk,_that.avgProgress);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LearnerReportKpis implements LearnerReportKpis {
  const _LearnerReportKpis({this.learners = const Kpi(), this.active = const Kpi(), @JsonKey(name: 'atRisk') this.atRisk = const Kpi(), this.avgProgress = const Kpi()});
  factory _LearnerReportKpis.fromJson(Map<String, dynamic> json) => _$LearnerReportKpisFromJson(json);

@override@JsonKey() final  Kpi learners;
@override@JsonKey() final  Kpi active;
@override@JsonKey(name: 'atRisk') final  Kpi atRisk;
@override@JsonKey() final  Kpi avgProgress;

/// Create a copy of LearnerReportKpis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearnerReportKpisCopyWith<_LearnerReportKpis> get copyWith => __$LearnerReportKpisCopyWithImpl<_LearnerReportKpis>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearnerReportKpisToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearnerReportKpis&&(identical(other.learners, learners) || other.learners == learners)&&(identical(other.active, active) || other.active == active)&&(identical(other.atRisk, atRisk) || other.atRisk == atRisk)&&(identical(other.avgProgress, avgProgress) || other.avgProgress == avgProgress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,learners,active,atRisk,avgProgress);

@override
String toString() {
  return 'LearnerReportKpis(learners: $learners, active: $active, atRisk: $atRisk, avgProgress: $avgProgress)';
}


}

/// @nodoc
abstract mixin class _$LearnerReportKpisCopyWith<$Res> implements $LearnerReportKpisCopyWith<$Res> {
  factory _$LearnerReportKpisCopyWith(_LearnerReportKpis value, $Res Function(_LearnerReportKpis) _then) = __$LearnerReportKpisCopyWithImpl;
@override @useResult
$Res call({
 Kpi learners, Kpi active,@JsonKey(name: 'atRisk') Kpi atRisk, Kpi avgProgress
});


@override $KpiCopyWith<$Res> get learners;@override $KpiCopyWith<$Res> get active;@override $KpiCopyWith<$Res> get atRisk;@override $KpiCopyWith<$Res> get avgProgress;

}
/// @nodoc
class __$LearnerReportKpisCopyWithImpl<$Res>
    implements _$LearnerReportKpisCopyWith<$Res> {
  __$LearnerReportKpisCopyWithImpl(this._self, this._then);

  final _LearnerReportKpis _self;
  final $Res Function(_LearnerReportKpis) _then;

/// Create a copy of LearnerReportKpis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? learners = null,Object? active = null,Object? atRisk = null,Object? avgProgress = null,}) {
  return _then(_LearnerReportKpis(
learners: null == learners ? _self.learners : learners // ignore: cast_nullable_to_non_nullable
as Kpi,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as Kpi,atRisk: null == atRisk ? _self.atRisk : atRisk // ignore: cast_nullable_to_non_nullable
as Kpi,avgProgress: null == avgProgress ? _self.avgProgress : avgProgress // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}

/// Create a copy of LearnerReportKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get learners {
  
  return $KpiCopyWith<$Res>(_self.learners, (value) {
    return _then(_self.copyWith(learners: value));
  });
}/// Create a copy of LearnerReportKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get active {
  
  return $KpiCopyWith<$Res>(_self.active, (value) {
    return _then(_self.copyWith(active: value));
  });
}/// Create a copy of LearnerReportKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get atRisk {
  
  return $KpiCopyWith<$Res>(_self.atRisk, (value) {
    return _then(_self.copyWith(atRisk: value));
  });
}/// Create a copy of LearnerReportKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get avgProgress {
  
  return $KpiCopyWith<$Res>(_self.avgProgress, (value) {
    return _then(_self.copyWith(avgProgress: value));
  });
}
}


/// @nodoc
mixin _$LearnerReportRow {

 String get studentId; String get name; String get city; String get status; int get courses; int get completed; int? get avgProgress; int? get assignmentAvg;@NullableUtcDateTimeConverter() DateTime? get lastActiveAt;
/// Create a copy of LearnerReportRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearnerReportRowCopyWith<LearnerReportRow> get copyWith => _$LearnerReportRowCopyWithImpl<LearnerReportRow>(this as LearnerReportRow, _$identity);

  /// Serializes this LearnerReportRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearnerReportRow&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.status, status) || other.status == status)&&(identical(other.courses, courses) || other.courses == courses)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.avgProgress, avgProgress) || other.avgProgress == avgProgress)&&(identical(other.assignmentAvg, assignmentAvg) || other.assignmentAvg == assignmentAvg)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,studentId,name,city,status,courses,completed,avgProgress,assignmentAvg,lastActiveAt);

@override
String toString() {
  return 'LearnerReportRow(studentId: $studentId, name: $name, city: $city, status: $status, courses: $courses, completed: $completed, avgProgress: $avgProgress, assignmentAvg: $assignmentAvg, lastActiveAt: $lastActiveAt)';
}


}

/// @nodoc
abstract mixin class $LearnerReportRowCopyWith<$Res>  {
  factory $LearnerReportRowCopyWith(LearnerReportRow value, $Res Function(LearnerReportRow) _then) = _$LearnerReportRowCopyWithImpl;
@useResult
$Res call({
 String studentId, String name, String city, String status, int courses, int completed, int? avgProgress, int? assignmentAvg,@NullableUtcDateTimeConverter() DateTime? lastActiveAt
});




}
/// @nodoc
class _$LearnerReportRowCopyWithImpl<$Res>
    implements $LearnerReportRowCopyWith<$Res> {
  _$LearnerReportRowCopyWithImpl(this._self, this._then);

  final LearnerReportRow _self;
  final $Res Function(LearnerReportRow) _then;

/// Create a copy of LearnerReportRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? studentId = null,Object? name = null,Object? city = null,Object? status = null,Object? courses = null,Object? completed = null,Object? avgProgress = freezed,Object? assignmentAvg = freezed,Object? lastActiveAt = freezed,}) {
  return _then(_self.copyWith(
studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,courses: null == courses ? _self.courses : courses // ignore: cast_nullable_to_non_nullable
as int,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int,avgProgress: freezed == avgProgress ? _self.avgProgress : avgProgress // ignore: cast_nullable_to_non_nullable
as int?,assignmentAvg: freezed == assignmentAvg ? _self.assignmentAvg : assignmentAvg // ignore: cast_nullable_to_non_nullable
as int?,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LearnerReportRow].
extension LearnerReportRowPatterns on LearnerReportRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearnerReportRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearnerReportRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearnerReportRow value)  $default,){
final _that = this;
switch (_that) {
case _LearnerReportRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearnerReportRow value)?  $default,){
final _that = this;
switch (_that) {
case _LearnerReportRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String studentId,  String name,  String city,  String status,  int courses,  int completed,  int? avgProgress,  int? assignmentAvg, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearnerReportRow() when $default != null:
return $default(_that.studentId,_that.name,_that.city,_that.status,_that.courses,_that.completed,_that.avgProgress,_that.assignmentAvg,_that.lastActiveAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String studentId,  String name,  String city,  String status,  int courses,  int completed,  int? avgProgress,  int? assignmentAvg, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt)  $default,) {final _that = this;
switch (_that) {
case _LearnerReportRow():
return $default(_that.studentId,_that.name,_that.city,_that.status,_that.courses,_that.completed,_that.avgProgress,_that.assignmentAvg,_that.lastActiveAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String studentId,  String name,  String city,  String status,  int courses,  int completed,  int? avgProgress,  int? assignmentAvg, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt)?  $default,) {final _that = this;
switch (_that) {
case _LearnerReportRow() when $default != null:
return $default(_that.studentId,_that.name,_that.city,_that.status,_that.courses,_that.completed,_that.avgProgress,_that.assignmentAvg,_that.lastActiveAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LearnerReportRow implements LearnerReportRow {
  const _LearnerReportRow({this.studentId = '', this.name = '', this.city = '', this.status = '', this.courses = 0, this.completed = 0, this.avgProgress, this.assignmentAvg, @NullableUtcDateTimeConverter() this.lastActiveAt});
  factory _LearnerReportRow.fromJson(Map<String, dynamic> json) => _$LearnerReportRowFromJson(json);

@override@JsonKey() final  String studentId;
@override@JsonKey() final  String name;
@override@JsonKey() final  String city;
@override@JsonKey() final  String status;
@override@JsonKey() final  int courses;
@override@JsonKey() final  int completed;
@override final  int? avgProgress;
@override final  int? assignmentAvg;
@override@NullableUtcDateTimeConverter() final  DateTime? lastActiveAt;

/// Create a copy of LearnerReportRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearnerReportRowCopyWith<_LearnerReportRow> get copyWith => __$LearnerReportRowCopyWithImpl<_LearnerReportRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearnerReportRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearnerReportRow&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.status, status) || other.status == status)&&(identical(other.courses, courses) || other.courses == courses)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.avgProgress, avgProgress) || other.avgProgress == avgProgress)&&(identical(other.assignmentAvg, assignmentAvg) || other.assignmentAvg == assignmentAvg)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,studentId,name,city,status,courses,completed,avgProgress,assignmentAvg,lastActiveAt);

@override
String toString() {
  return 'LearnerReportRow(studentId: $studentId, name: $name, city: $city, status: $status, courses: $courses, completed: $completed, avgProgress: $avgProgress, assignmentAvg: $assignmentAvg, lastActiveAt: $lastActiveAt)';
}


}

/// @nodoc
abstract mixin class _$LearnerReportRowCopyWith<$Res> implements $LearnerReportRowCopyWith<$Res> {
  factory _$LearnerReportRowCopyWith(_LearnerReportRow value, $Res Function(_LearnerReportRow) _then) = __$LearnerReportRowCopyWithImpl;
@override @useResult
$Res call({
 String studentId, String name, String city, String status, int courses, int completed, int? avgProgress, int? assignmentAvg,@NullableUtcDateTimeConverter() DateTime? lastActiveAt
});




}
/// @nodoc
class __$LearnerReportRowCopyWithImpl<$Res>
    implements _$LearnerReportRowCopyWith<$Res> {
  __$LearnerReportRowCopyWithImpl(this._self, this._then);

  final _LearnerReportRow _self;
  final $Res Function(_LearnerReportRow) _then;

/// Create a copy of LearnerReportRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? studentId = null,Object? name = null,Object? city = null,Object? status = null,Object? courses = null,Object? completed = null,Object? avgProgress = freezed,Object? assignmentAvg = freezed,Object? lastActiveAt = freezed,}) {
  return _then(_LearnerReportRow(
studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,courses: null == courses ? _self.courses : courses // ignore: cast_nullable_to_non_nullable
as int,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int,avgProgress: freezed == avgProgress ? _self.avgProgress : avgProgress // ignore: cast_nullable_to_non_nullable
as int?,assignmentAvg: freezed == assignmentAvg ? _self.assignmentAvg : assignmentAvg // ignore: cast_nullable_to_non_nullable
as int?,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$LearnersReport {

 ReportWindow get window; int get courseCount; LearnerReportKpis get kpis; Map<String, int> get segments; Map<String, int> get statuses; List<LabelledCount> get progressBands; List<LearnerReportRow> get rows; int get total;
/// Create a copy of LearnersReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearnersReportCopyWith<LearnersReport> get copyWith => _$LearnersReportCopyWithImpl<LearnersReport>(this as LearnersReport, _$identity);

  /// Serializes this LearnersReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearnersReport&&(identical(other.window, window) || other.window == window)&&(identical(other.courseCount, courseCount) || other.courseCount == courseCount)&&(identical(other.kpis, kpis) || other.kpis == kpis)&&const DeepCollectionEquality().equals(other.segments, segments)&&const DeepCollectionEquality().equals(other.statuses, statuses)&&const DeepCollectionEquality().equals(other.progressBands, progressBands)&&const DeepCollectionEquality().equals(other.rows, rows)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,window,courseCount,kpis,const DeepCollectionEquality().hash(segments),const DeepCollectionEquality().hash(statuses),const DeepCollectionEquality().hash(progressBands),const DeepCollectionEquality().hash(rows),total);

@override
String toString() {
  return 'LearnersReport(window: $window, courseCount: $courseCount, kpis: $kpis, segments: $segments, statuses: $statuses, progressBands: $progressBands, rows: $rows, total: $total)';
}


}

/// @nodoc
abstract mixin class $LearnersReportCopyWith<$Res>  {
  factory $LearnersReportCopyWith(LearnersReport value, $Res Function(LearnersReport) _then) = _$LearnersReportCopyWithImpl;
@useResult
$Res call({
 ReportWindow window, int courseCount, LearnerReportKpis kpis, Map<String, int> segments, Map<String, int> statuses, List<LabelledCount> progressBands, List<LearnerReportRow> rows, int total
});


$ReportWindowCopyWith<$Res> get window;$LearnerReportKpisCopyWith<$Res> get kpis;

}
/// @nodoc
class _$LearnersReportCopyWithImpl<$Res>
    implements $LearnersReportCopyWith<$Res> {
  _$LearnersReportCopyWithImpl(this._self, this._then);

  final LearnersReport _self;
  final $Res Function(LearnersReport) _then;

/// Create a copy of LearnersReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? window = null,Object? courseCount = null,Object? kpis = null,Object? segments = null,Object? statuses = null,Object? progressBands = null,Object? rows = null,Object? total = null,}) {
  return _then(_self.copyWith(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as ReportWindow,courseCount: null == courseCount ? _self.courseCount : courseCount // ignore: cast_nullable_to_non_nullable
as int,kpis: null == kpis ? _self.kpis : kpis // ignore: cast_nullable_to_non_nullable
as LearnerReportKpis,segments: null == segments ? _self.segments : segments // ignore: cast_nullable_to_non_nullable
as Map<String, int>,statuses: null == statuses ? _self.statuses : statuses // ignore: cast_nullable_to_non_nullable
as Map<String, int>,progressBands: null == progressBands ? _self.progressBands : progressBands // ignore: cast_nullable_to_non_nullable
as List<LabelledCount>,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<LearnerReportRow>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of LearnersReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportWindowCopyWith<$Res> get window {
  
  return $ReportWindowCopyWith<$Res>(_self.window, (value) {
    return _then(_self.copyWith(window: value));
  });
}/// Create a copy of LearnersReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LearnerReportKpisCopyWith<$Res> get kpis {
  
  return $LearnerReportKpisCopyWith<$Res>(_self.kpis, (value) {
    return _then(_self.copyWith(kpis: value));
  });
}
}


/// Adds pattern-matching-related methods to [LearnersReport].
extension LearnersReportPatterns on LearnersReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearnersReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearnersReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearnersReport value)  $default,){
final _that = this;
switch (_that) {
case _LearnersReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearnersReport value)?  $default,){
final _that = this;
switch (_that) {
case _LearnersReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReportWindow window,  int courseCount,  LearnerReportKpis kpis,  Map<String, int> segments,  Map<String, int> statuses,  List<LabelledCount> progressBands,  List<LearnerReportRow> rows,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearnersReport() when $default != null:
return $default(_that.window,_that.courseCount,_that.kpis,_that.segments,_that.statuses,_that.progressBands,_that.rows,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReportWindow window,  int courseCount,  LearnerReportKpis kpis,  Map<String, int> segments,  Map<String, int> statuses,  List<LabelledCount> progressBands,  List<LearnerReportRow> rows,  int total)  $default,) {final _that = this;
switch (_that) {
case _LearnersReport():
return $default(_that.window,_that.courseCount,_that.kpis,_that.segments,_that.statuses,_that.progressBands,_that.rows,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReportWindow window,  int courseCount,  LearnerReportKpis kpis,  Map<String, int> segments,  Map<String, int> statuses,  List<LabelledCount> progressBands,  List<LearnerReportRow> rows,  int total)?  $default,) {final _that = this;
switch (_that) {
case _LearnersReport() when $default != null:
return $default(_that.window,_that.courseCount,_that.kpis,_that.segments,_that.statuses,_that.progressBands,_that.rows,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LearnersReport extends LearnersReport {
  const _LearnersReport({required this.window, this.courseCount = 0, this.kpis = const LearnerReportKpis(), final  Map<String, int> segments = const <String, int>{}, final  Map<String, int> statuses = const <String, int>{}, final  List<LabelledCount> progressBands = const <LabelledCount>[], final  List<LearnerReportRow> rows = const <LearnerReportRow>[], this.total = 0}): _segments = segments,_statuses = statuses,_progressBands = progressBands,_rows = rows,super._();
  factory _LearnersReport.fromJson(Map<String, dynamic> json) => _$LearnersReportFromJson(json);

@override final  ReportWindow window;
@override@JsonKey() final  int courseCount;
@override@JsonKey() final  LearnerReportKpis kpis;
 final  Map<String, int> _segments;
@override@JsonKey() Map<String, int> get segments {
  if (_segments is EqualUnmodifiableMapView) return _segments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_segments);
}

 final  Map<String, int> _statuses;
@override@JsonKey() Map<String, int> get statuses {
  if (_statuses is EqualUnmodifiableMapView) return _statuses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_statuses);
}

 final  List<LabelledCount> _progressBands;
@override@JsonKey() List<LabelledCount> get progressBands {
  if (_progressBands is EqualUnmodifiableListView) return _progressBands;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_progressBands);
}

 final  List<LearnerReportRow> _rows;
@override@JsonKey() List<LearnerReportRow> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

@override@JsonKey() final  int total;

/// Create a copy of LearnersReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearnersReportCopyWith<_LearnersReport> get copyWith => __$LearnersReportCopyWithImpl<_LearnersReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearnersReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearnersReport&&(identical(other.window, window) || other.window == window)&&(identical(other.courseCount, courseCount) || other.courseCount == courseCount)&&(identical(other.kpis, kpis) || other.kpis == kpis)&&const DeepCollectionEquality().equals(other._segments, _segments)&&const DeepCollectionEquality().equals(other._statuses, _statuses)&&const DeepCollectionEquality().equals(other._progressBands, _progressBands)&&const DeepCollectionEquality().equals(other._rows, _rows)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,window,courseCount,kpis,const DeepCollectionEquality().hash(_segments),const DeepCollectionEquality().hash(_statuses),const DeepCollectionEquality().hash(_progressBands),const DeepCollectionEquality().hash(_rows),total);

@override
String toString() {
  return 'LearnersReport(window: $window, courseCount: $courseCount, kpis: $kpis, segments: $segments, statuses: $statuses, progressBands: $progressBands, rows: $rows, total: $total)';
}


}

/// @nodoc
abstract mixin class _$LearnersReportCopyWith<$Res> implements $LearnersReportCopyWith<$Res> {
  factory _$LearnersReportCopyWith(_LearnersReport value, $Res Function(_LearnersReport) _then) = __$LearnersReportCopyWithImpl;
@override @useResult
$Res call({
 ReportWindow window, int courseCount, LearnerReportKpis kpis, Map<String, int> segments, Map<String, int> statuses, List<LabelledCount> progressBands, List<LearnerReportRow> rows, int total
});


@override $ReportWindowCopyWith<$Res> get window;@override $LearnerReportKpisCopyWith<$Res> get kpis;

}
/// @nodoc
class __$LearnersReportCopyWithImpl<$Res>
    implements _$LearnersReportCopyWith<$Res> {
  __$LearnersReportCopyWithImpl(this._self, this._then);

  final _LearnersReport _self;
  final $Res Function(_LearnersReport) _then;

/// Create a copy of LearnersReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? window = null,Object? courseCount = null,Object? kpis = null,Object? segments = null,Object? statuses = null,Object? progressBands = null,Object? rows = null,Object? total = null,}) {
  return _then(_LearnersReport(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as ReportWindow,courseCount: null == courseCount ? _self.courseCount : courseCount // ignore: cast_nullable_to_non_nullable
as int,kpis: null == kpis ? _self.kpis : kpis // ignore: cast_nullable_to_non_nullable
as LearnerReportKpis,segments: null == segments ? _self._segments : segments // ignore: cast_nullable_to_non_nullable
as Map<String, int>,statuses: null == statuses ? _self._statuses : statuses // ignore: cast_nullable_to_non_nullable
as Map<String, int>,progressBands: null == progressBands ? _self._progressBands : progressBands // ignore: cast_nullable_to_non_nullable
as List<LabelledCount>,rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<LearnerReportRow>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of LearnersReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportWindowCopyWith<$Res> get window {
  
  return $ReportWindowCopyWith<$Res>(_self.window, (value) {
    return _then(_self.copyWith(window: value));
  });
}/// Create a copy of LearnersReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LearnerReportKpisCopyWith<$Res> get kpis {
  
  return $LearnerReportKpisCopyWith<$Res>(_self.kpis, (value) {
    return _then(_self.copyWith(kpis: value));
  });
}
}


/// @nodoc
mixin _$EnrolmentSourceRow {

 String get source; int get enrollments; int? get share; int? get completionRate;
/// Create a copy of EnrolmentSourceRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnrolmentSourceRowCopyWith<EnrolmentSourceRow> get copyWith => _$EnrolmentSourceRowCopyWithImpl<EnrolmentSourceRow>(this as EnrolmentSourceRow, _$identity);

  /// Serializes this EnrolmentSourceRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnrolmentSourceRow&&(identical(other.source, source) || other.source == source)&&(identical(other.enrollments, enrollments) || other.enrollments == enrollments)&&(identical(other.share, share) || other.share == share)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,enrollments,share,completionRate);

@override
String toString() {
  return 'EnrolmentSourceRow(source: $source, enrollments: $enrollments, share: $share, completionRate: $completionRate)';
}


}

/// @nodoc
abstract mixin class $EnrolmentSourceRowCopyWith<$Res>  {
  factory $EnrolmentSourceRowCopyWith(EnrolmentSourceRow value, $Res Function(EnrolmentSourceRow) _then) = _$EnrolmentSourceRowCopyWithImpl;
@useResult
$Res call({
 String source, int enrollments, int? share, int? completionRate
});




}
/// @nodoc
class _$EnrolmentSourceRowCopyWithImpl<$Res>
    implements $EnrolmentSourceRowCopyWith<$Res> {
  _$EnrolmentSourceRowCopyWithImpl(this._self, this._then);

  final EnrolmentSourceRow _self;
  final $Res Function(EnrolmentSourceRow) _then;

/// Create a copy of EnrolmentSourceRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? enrollments = null,Object? share = freezed,Object? completionRate = freezed,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,enrollments: null == enrollments ? _self.enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as int,share: freezed == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as int?,completionRate: freezed == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [EnrolmentSourceRow].
extension EnrolmentSourceRowPatterns on EnrolmentSourceRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnrolmentSourceRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnrolmentSourceRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnrolmentSourceRow value)  $default,){
final _that = this;
switch (_that) {
case _EnrolmentSourceRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnrolmentSourceRow value)?  $default,){
final _that = this;
switch (_that) {
case _EnrolmentSourceRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String source,  int enrollments,  int? share,  int? completionRate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnrolmentSourceRow() when $default != null:
return $default(_that.source,_that.enrollments,_that.share,_that.completionRate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String source,  int enrollments,  int? share,  int? completionRate)  $default,) {final _that = this;
switch (_that) {
case _EnrolmentSourceRow():
return $default(_that.source,_that.enrollments,_that.share,_that.completionRate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String source,  int enrollments,  int? share,  int? completionRate)?  $default,) {final _that = this;
switch (_that) {
case _EnrolmentSourceRow() when $default != null:
return $default(_that.source,_that.enrollments,_that.share,_that.completionRate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnrolmentSourceRow implements EnrolmentSourceRow {
  const _EnrolmentSourceRow({this.source = '', this.enrollments = 0, this.share, this.completionRate});
  factory _EnrolmentSourceRow.fromJson(Map<String, dynamic> json) => _$EnrolmentSourceRowFromJson(json);

@override@JsonKey() final  String source;
@override@JsonKey() final  int enrollments;
@override final  int? share;
@override final  int? completionRate;

/// Create a copy of EnrolmentSourceRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnrolmentSourceRowCopyWith<_EnrolmentSourceRow> get copyWith => __$EnrolmentSourceRowCopyWithImpl<_EnrolmentSourceRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnrolmentSourceRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnrolmentSourceRow&&(identical(other.source, source) || other.source == source)&&(identical(other.enrollments, enrollments) || other.enrollments == enrollments)&&(identical(other.share, share) || other.share == share)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,enrollments,share,completionRate);

@override
String toString() {
  return 'EnrolmentSourceRow(source: $source, enrollments: $enrollments, share: $share, completionRate: $completionRate)';
}


}

/// @nodoc
abstract mixin class _$EnrolmentSourceRowCopyWith<$Res> implements $EnrolmentSourceRowCopyWith<$Res> {
  factory _$EnrolmentSourceRowCopyWith(_EnrolmentSourceRow value, $Res Function(_EnrolmentSourceRow) _then) = __$EnrolmentSourceRowCopyWithImpl;
@override @useResult
$Res call({
 String source, int enrollments, int? share, int? completionRate
});




}
/// @nodoc
class __$EnrolmentSourceRowCopyWithImpl<$Res>
    implements _$EnrolmentSourceRowCopyWith<$Res> {
  __$EnrolmentSourceRowCopyWithImpl(this._self, this._then);

  final _EnrolmentSourceRow _self;
  final $Res Function(_EnrolmentSourceRow) _then;

/// Create a copy of EnrolmentSourceRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? enrollments = null,Object? share = freezed,Object? completionRate = freezed,}) {
  return _then(_EnrolmentSourceRow(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,enrollments: null == enrollments ? _self.enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as int,share: freezed == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as int?,completionRate: freezed == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$CohortRow {

 String get month; int get enrolled; int? get within30; int? get within60; int? get within90; int? get toDate;
/// Create a copy of CohortRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CohortRowCopyWith<CohortRow> get copyWith => _$CohortRowCopyWithImpl<CohortRow>(this as CohortRow, _$identity);

  /// Serializes this CohortRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CohortRow&&(identical(other.month, month) || other.month == month)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.within30, within30) || other.within30 == within30)&&(identical(other.within60, within60) || other.within60 == within60)&&(identical(other.within90, within90) || other.within90 == within90)&&(identical(other.toDate, toDate) || other.toDate == toDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,enrolled,within30,within60,within90,toDate);

@override
String toString() {
  return 'CohortRow(month: $month, enrolled: $enrolled, within30: $within30, within60: $within60, within90: $within90, toDate: $toDate)';
}


}

/// @nodoc
abstract mixin class $CohortRowCopyWith<$Res>  {
  factory $CohortRowCopyWith(CohortRow value, $Res Function(CohortRow) _then) = _$CohortRowCopyWithImpl;
@useResult
$Res call({
 String month, int enrolled, int? within30, int? within60, int? within90, int? toDate
});




}
/// @nodoc
class _$CohortRowCopyWithImpl<$Res>
    implements $CohortRowCopyWith<$Res> {
  _$CohortRowCopyWithImpl(this._self, this._then);

  final CohortRow _self;
  final $Res Function(CohortRow) _then;

/// Create a copy of CohortRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? enrolled = null,Object? within30 = freezed,Object? within60 = freezed,Object? within90 = freezed,Object? toDate = freezed,}) {
  return _then(_self.copyWith(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as int,within30: freezed == within30 ? _self.within30 : within30 // ignore: cast_nullable_to_non_nullable
as int?,within60: freezed == within60 ? _self.within60 : within60 // ignore: cast_nullable_to_non_nullable
as int?,within90: freezed == within90 ? _self.within90 : within90 // ignore: cast_nullable_to_non_nullable
as int?,toDate: freezed == toDate ? _self.toDate : toDate // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CohortRow].
extension CohortRowPatterns on CohortRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CohortRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CohortRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CohortRow value)  $default,){
final _that = this;
switch (_that) {
case _CohortRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CohortRow value)?  $default,){
final _that = this;
switch (_that) {
case _CohortRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String month,  int enrolled,  int? within30,  int? within60,  int? within90,  int? toDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CohortRow() when $default != null:
return $default(_that.month,_that.enrolled,_that.within30,_that.within60,_that.within90,_that.toDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String month,  int enrolled,  int? within30,  int? within60,  int? within90,  int? toDate)  $default,) {final _that = this;
switch (_that) {
case _CohortRow():
return $default(_that.month,_that.enrolled,_that.within30,_that.within60,_that.within90,_that.toDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String month,  int enrolled,  int? within30,  int? within60,  int? within90,  int? toDate)?  $default,) {final _that = this;
switch (_that) {
case _CohortRow() when $default != null:
return $default(_that.month,_that.enrolled,_that.within30,_that.within60,_that.within90,_that.toDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CohortRow implements CohortRow {
  const _CohortRow({this.month = '', this.enrolled = 0, this.within30, this.within60, this.within90, this.toDate});
  factory _CohortRow.fromJson(Map<String, dynamic> json) => _$CohortRowFromJson(json);

@override@JsonKey() final  String month;
@override@JsonKey() final  int enrolled;
@override final  int? within30;
@override final  int? within60;
@override final  int? within90;
@override final  int? toDate;

/// Create a copy of CohortRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CohortRowCopyWith<_CohortRow> get copyWith => __$CohortRowCopyWithImpl<_CohortRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CohortRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CohortRow&&(identical(other.month, month) || other.month == month)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.within30, within30) || other.within30 == within30)&&(identical(other.within60, within60) || other.within60 == within60)&&(identical(other.within90, within90) || other.within90 == within90)&&(identical(other.toDate, toDate) || other.toDate == toDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,enrolled,within30,within60,within90,toDate);

@override
String toString() {
  return 'CohortRow(month: $month, enrolled: $enrolled, within30: $within30, within60: $within60, within90: $within90, toDate: $toDate)';
}


}

/// @nodoc
abstract mixin class _$CohortRowCopyWith<$Res> implements $CohortRowCopyWith<$Res> {
  factory _$CohortRowCopyWith(_CohortRow value, $Res Function(_CohortRow) _then) = __$CohortRowCopyWithImpl;
@override @useResult
$Res call({
 String month, int enrolled, int? within30, int? within60, int? within90, int? toDate
});




}
/// @nodoc
class __$CohortRowCopyWithImpl<$Res>
    implements _$CohortRowCopyWith<$Res> {
  __$CohortRowCopyWithImpl(this._self, this._then);

  final _CohortRow _self;
  final $Res Function(_CohortRow) _then;

/// Create a copy of CohortRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? enrolled = null,Object? within30 = freezed,Object? within60 = freezed,Object? within90 = freezed,Object? toDate = freezed,}) {
  return _then(_CohortRow(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as int,within30: freezed == within30 ? _self.within30 : within30 // ignore: cast_nullable_to_non_nullable
as int?,within60: freezed == within60 ? _self.within60 : within60 // ignore: cast_nullable_to_non_nullable
as int?,within90: freezed == within90 ? _self.within90 : within90 // ignore: cast_nullable_to_non_nullable
as int?,toDate: freezed == toDate ? _self.toDate : toDate // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$EnrolmentKpis {

 Kpi get enrollments; Kpi get completions; Kpi get completionRate; Kpi get selfShare;
/// Create a copy of EnrolmentKpis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnrolmentKpisCopyWith<EnrolmentKpis> get copyWith => _$EnrolmentKpisCopyWithImpl<EnrolmentKpis>(this as EnrolmentKpis, _$identity);

  /// Serializes this EnrolmentKpis to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnrolmentKpis&&(identical(other.enrollments, enrollments) || other.enrollments == enrollments)&&(identical(other.completions, completions) || other.completions == completions)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.selfShare, selfShare) || other.selfShare == selfShare));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrollments,completions,completionRate,selfShare);

@override
String toString() {
  return 'EnrolmentKpis(enrollments: $enrollments, completions: $completions, completionRate: $completionRate, selfShare: $selfShare)';
}


}

/// @nodoc
abstract mixin class $EnrolmentKpisCopyWith<$Res>  {
  factory $EnrolmentKpisCopyWith(EnrolmentKpis value, $Res Function(EnrolmentKpis) _then) = _$EnrolmentKpisCopyWithImpl;
@useResult
$Res call({
 Kpi enrollments, Kpi completions, Kpi completionRate, Kpi selfShare
});


$KpiCopyWith<$Res> get enrollments;$KpiCopyWith<$Res> get completions;$KpiCopyWith<$Res> get completionRate;$KpiCopyWith<$Res> get selfShare;

}
/// @nodoc
class _$EnrolmentKpisCopyWithImpl<$Res>
    implements $EnrolmentKpisCopyWith<$Res> {
  _$EnrolmentKpisCopyWithImpl(this._self, this._then);

  final EnrolmentKpis _self;
  final $Res Function(EnrolmentKpis) _then;

/// Create a copy of EnrolmentKpis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enrollments = null,Object? completions = null,Object? completionRate = null,Object? selfShare = null,}) {
  return _then(_self.copyWith(
enrollments: null == enrollments ? _self.enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as Kpi,completions: null == completions ? _self.completions : completions // ignore: cast_nullable_to_non_nullable
as Kpi,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as Kpi,selfShare: null == selfShare ? _self.selfShare : selfShare // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}
/// Create a copy of EnrolmentKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get enrollments {
  
  return $KpiCopyWith<$Res>(_self.enrollments, (value) {
    return _then(_self.copyWith(enrollments: value));
  });
}/// Create a copy of EnrolmentKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get completions {
  
  return $KpiCopyWith<$Res>(_self.completions, (value) {
    return _then(_self.copyWith(completions: value));
  });
}/// Create a copy of EnrolmentKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get completionRate {
  
  return $KpiCopyWith<$Res>(_self.completionRate, (value) {
    return _then(_self.copyWith(completionRate: value));
  });
}/// Create a copy of EnrolmentKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get selfShare {
  
  return $KpiCopyWith<$Res>(_self.selfShare, (value) {
    return _then(_self.copyWith(selfShare: value));
  });
}
}


/// Adds pattern-matching-related methods to [EnrolmentKpis].
extension EnrolmentKpisPatterns on EnrolmentKpis {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnrolmentKpis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnrolmentKpis() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnrolmentKpis value)  $default,){
final _that = this;
switch (_that) {
case _EnrolmentKpis():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnrolmentKpis value)?  $default,){
final _that = this;
switch (_that) {
case _EnrolmentKpis() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Kpi enrollments,  Kpi completions,  Kpi completionRate,  Kpi selfShare)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnrolmentKpis() when $default != null:
return $default(_that.enrollments,_that.completions,_that.completionRate,_that.selfShare);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Kpi enrollments,  Kpi completions,  Kpi completionRate,  Kpi selfShare)  $default,) {final _that = this;
switch (_that) {
case _EnrolmentKpis():
return $default(_that.enrollments,_that.completions,_that.completionRate,_that.selfShare);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Kpi enrollments,  Kpi completions,  Kpi completionRate,  Kpi selfShare)?  $default,) {final _that = this;
switch (_that) {
case _EnrolmentKpis() when $default != null:
return $default(_that.enrollments,_that.completions,_that.completionRate,_that.selfShare);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnrolmentKpis implements EnrolmentKpis {
  const _EnrolmentKpis({this.enrollments = const Kpi(), this.completions = const Kpi(), this.completionRate = const Kpi(), this.selfShare = const Kpi()});
  factory _EnrolmentKpis.fromJson(Map<String, dynamic> json) => _$EnrolmentKpisFromJson(json);

@override@JsonKey() final  Kpi enrollments;
@override@JsonKey() final  Kpi completions;
@override@JsonKey() final  Kpi completionRate;
@override@JsonKey() final  Kpi selfShare;

/// Create a copy of EnrolmentKpis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnrolmentKpisCopyWith<_EnrolmentKpis> get copyWith => __$EnrolmentKpisCopyWithImpl<_EnrolmentKpis>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnrolmentKpisToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnrolmentKpis&&(identical(other.enrollments, enrollments) || other.enrollments == enrollments)&&(identical(other.completions, completions) || other.completions == completions)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.selfShare, selfShare) || other.selfShare == selfShare));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrollments,completions,completionRate,selfShare);

@override
String toString() {
  return 'EnrolmentKpis(enrollments: $enrollments, completions: $completions, completionRate: $completionRate, selfShare: $selfShare)';
}


}

/// @nodoc
abstract mixin class _$EnrolmentKpisCopyWith<$Res> implements $EnrolmentKpisCopyWith<$Res> {
  factory _$EnrolmentKpisCopyWith(_EnrolmentKpis value, $Res Function(_EnrolmentKpis) _then) = __$EnrolmentKpisCopyWithImpl;
@override @useResult
$Res call({
 Kpi enrollments, Kpi completions, Kpi completionRate, Kpi selfShare
});


@override $KpiCopyWith<$Res> get enrollments;@override $KpiCopyWith<$Res> get completions;@override $KpiCopyWith<$Res> get completionRate;@override $KpiCopyWith<$Res> get selfShare;

}
/// @nodoc
class __$EnrolmentKpisCopyWithImpl<$Res>
    implements _$EnrolmentKpisCopyWith<$Res> {
  __$EnrolmentKpisCopyWithImpl(this._self, this._then);

  final _EnrolmentKpis _self;
  final $Res Function(_EnrolmentKpis) _then;

/// Create a copy of EnrolmentKpis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enrollments = null,Object? completions = null,Object? completionRate = null,Object? selfShare = null,}) {
  return _then(_EnrolmentKpis(
enrollments: null == enrollments ? _self.enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as Kpi,completions: null == completions ? _self.completions : completions // ignore: cast_nullable_to_non_nullable
as Kpi,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as Kpi,selfShare: null == selfShare ? _self.selfShare : selfShare // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}

/// Create a copy of EnrolmentKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get enrollments {
  
  return $KpiCopyWith<$Res>(_self.enrollments, (value) {
    return _then(_self.copyWith(enrollments: value));
  });
}/// Create a copy of EnrolmentKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get completions {
  
  return $KpiCopyWith<$Res>(_self.completions, (value) {
    return _then(_self.copyWith(completions: value));
  });
}/// Create a copy of EnrolmentKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get completionRate {
  
  return $KpiCopyWith<$Res>(_self.completionRate, (value) {
    return _then(_self.copyWith(completionRate: value));
  });
}/// Create a copy of EnrolmentKpis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get selfShare {
  
  return $KpiCopyWith<$Res>(_self.selfShare, (value) {
    return _then(_self.copyWith(selfShare: value));
  });
}
}


/// @nodoc
mixin _$EnrolmentsReport {

 ReportWindow get window; int get courseCount; EnrolmentKpis get kpis; ReportSeries get series; List<EnrolmentSourceRow> get sources; List<CategoryReportRow> get categories; List<CohortRow> get cohorts;
/// Create a copy of EnrolmentsReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnrolmentsReportCopyWith<EnrolmentsReport> get copyWith => _$EnrolmentsReportCopyWithImpl<EnrolmentsReport>(this as EnrolmentsReport, _$identity);

  /// Serializes this EnrolmentsReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnrolmentsReport&&(identical(other.window, window) || other.window == window)&&(identical(other.courseCount, courseCount) || other.courseCount == courseCount)&&(identical(other.kpis, kpis) || other.kpis == kpis)&&(identical(other.series, series) || other.series == series)&&const DeepCollectionEquality().equals(other.sources, sources)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.cohorts, cohorts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,window,courseCount,kpis,series,const DeepCollectionEquality().hash(sources),const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(cohorts));

@override
String toString() {
  return 'EnrolmentsReport(window: $window, courseCount: $courseCount, kpis: $kpis, series: $series, sources: $sources, categories: $categories, cohorts: $cohorts)';
}


}

/// @nodoc
abstract mixin class $EnrolmentsReportCopyWith<$Res>  {
  factory $EnrolmentsReportCopyWith(EnrolmentsReport value, $Res Function(EnrolmentsReport) _then) = _$EnrolmentsReportCopyWithImpl;
@useResult
$Res call({
 ReportWindow window, int courseCount, EnrolmentKpis kpis, ReportSeries series, List<EnrolmentSourceRow> sources, List<CategoryReportRow> categories, List<CohortRow> cohorts
});


$ReportWindowCopyWith<$Res> get window;$EnrolmentKpisCopyWith<$Res> get kpis;$ReportSeriesCopyWith<$Res> get series;

}
/// @nodoc
class _$EnrolmentsReportCopyWithImpl<$Res>
    implements $EnrolmentsReportCopyWith<$Res> {
  _$EnrolmentsReportCopyWithImpl(this._self, this._then);

  final EnrolmentsReport _self;
  final $Res Function(EnrolmentsReport) _then;

/// Create a copy of EnrolmentsReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? window = null,Object? courseCount = null,Object? kpis = null,Object? series = null,Object? sources = null,Object? categories = null,Object? cohorts = null,}) {
  return _then(_self.copyWith(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as ReportWindow,courseCount: null == courseCount ? _self.courseCount : courseCount // ignore: cast_nullable_to_non_nullable
as int,kpis: null == kpis ? _self.kpis : kpis // ignore: cast_nullable_to_non_nullable
as EnrolmentKpis,series: null == series ? _self.series : series // ignore: cast_nullable_to_non_nullable
as ReportSeries,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<EnrolmentSourceRow>,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<CategoryReportRow>,cohorts: null == cohorts ? _self.cohorts : cohorts // ignore: cast_nullable_to_non_nullable
as List<CohortRow>,
  ));
}
/// Create a copy of EnrolmentsReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportWindowCopyWith<$Res> get window {
  
  return $ReportWindowCopyWith<$Res>(_self.window, (value) {
    return _then(_self.copyWith(window: value));
  });
}/// Create a copy of EnrolmentsReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EnrolmentKpisCopyWith<$Res> get kpis {
  
  return $EnrolmentKpisCopyWith<$Res>(_self.kpis, (value) {
    return _then(_self.copyWith(kpis: value));
  });
}/// Create a copy of EnrolmentsReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportSeriesCopyWith<$Res> get series {
  
  return $ReportSeriesCopyWith<$Res>(_self.series, (value) {
    return _then(_self.copyWith(series: value));
  });
}
}


/// Adds pattern-matching-related methods to [EnrolmentsReport].
extension EnrolmentsReportPatterns on EnrolmentsReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnrolmentsReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnrolmentsReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnrolmentsReport value)  $default,){
final _that = this;
switch (_that) {
case _EnrolmentsReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnrolmentsReport value)?  $default,){
final _that = this;
switch (_that) {
case _EnrolmentsReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReportWindow window,  int courseCount,  EnrolmentKpis kpis,  ReportSeries series,  List<EnrolmentSourceRow> sources,  List<CategoryReportRow> categories,  List<CohortRow> cohorts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnrolmentsReport() when $default != null:
return $default(_that.window,_that.courseCount,_that.kpis,_that.series,_that.sources,_that.categories,_that.cohorts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReportWindow window,  int courseCount,  EnrolmentKpis kpis,  ReportSeries series,  List<EnrolmentSourceRow> sources,  List<CategoryReportRow> categories,  List<CohortRow> cohorts)  $default,) {final _that = this;
switch (_that) {
case _EnrolmentsReport():
return $default(_that.window,_that.courseCount,_that.kpis,_that.series,_that.sources,_that.categories,_that.cohorts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReportWindow window,  int courseCount,  EnrolmentKpis kpis,  ReportSeries series,  List<EnrolmentSourceRow> sources,  List<CategoryReportRow> categories,  List<CohortRow> cohorts)?  $default,) {final _that = this;
switch (_that) {
case _EnrolmentsReport() when $default != null:
return $default(_that.window,_that.courseCount,_that.kpis,_that.series,_that.sources,_that.categories,_that.cohorts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnrolmentsReport implements EnrolmentsReport {
  const _EnrolmentsReport({required this.window, this.courseCount = 0, this.kpis = const EnrolmentKpis(), this.series = const ReportSeries(), final  List<EnrolmentSourceRow> sources = const <EnrolmentSourceRow>[], final  List<CategoryReportRow> categories = const <CategoryReportRow>[], final  List<CohortRow> cohorts = const <CohortRow>[]}): _sources = sources,_categories = categories,_cohorts = cohorts;
  factory _EnrolmentsReport.fromJson(Map<String, dynamic> json) => _$EnrolmentsReportFromJson(json);

@override final  ReportWindow window;
@override@JsonKey() final  int courseCount;
@override@JsonKey() final  EnrolmentKpis kpis;
@override@JsonKey() final  ReportSeries series;
 final  List<EnrolmentSourceRow> _sources;
@override@JsonKey() List<EnrolmentSourceRow> get sources {
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sources);
}

 final  List<CategoryReportRow> _categories;
@override@JsonKey() List<CategoryReportRow> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<CohortRow> _cohorts;
@override@JsonKey() List<CohortRow> get cohorts {
  if (_cohorts is EqualUnmodifiableListView) return _cohorts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cohorts);
}


/// Create a copy of EnrolmentsReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnrolmentsReportCopyWith<_EnrolmentsReport> get copyWith => __$EnrolmentsReportCopyWithImpl<_EnrolmentsReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnrolmentsReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnrolmentsReport&&(identical(other.window, window) || other.window == window)&&(identical(other.courseCount, courseCount) || other.courseCount == courseCount)&&(identical(other.kpis, kpis) || other.kpis == kpis)&&(identical(other.series, series) || other.series == series)&&const DeepCollectionEquality().equals(other._sources, _sources)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._cohorts, _cohorts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,window,courseCount,kpis,series,const DeepCollectionEquality().hash(_sources),const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_cohorts));

@override
String toString() {
  return 'EnrolmentsReport(window: $window, courseCount: $courseCount, kpis: $kpis, series: $series, sources: $sources, categories: $categories, cohorts: $cohorts)';
}


}

/// @nodoc
abstract mixin class _$EnrolmentsReportCopyWith<$Res> implements $EnrolmentsReportCopyWith<$Res> {
  factory _$EnrolmentsReportCopyWith(_EnrolmentsReport value, $Res Function(_EnrolmentsReport) _then) = __$EnrolmentsReportCopyWithImpl;
@override @useResult
$Res call({
 ReportWindow window, int courseCount, EnrolmentKpis kpis, ReportSeries series, List<EnrolmentSourceRow> sources, List<CategoryReportRow> categories, List<CohortRow> cohorts
});


@override $ReportWindowCopyWith<$Res> get window;@override $EnrolmentKpisCopyWith<$Res> get kpis;@override $ReportSeriesCopyWith<$Res> get series;

}
/// @nodoc
class __$EnrolmentsReportCopyWithImpl<$Res>
    implements _$EnrolmentsReportCopyWith<$Res> {
  __$EnrolmentsReportCopyWithImpl(this._self, this._then);

  final _EnrolmentsReport _self;
  final $Res Function(_EnrolmentsReport) _then;

/// Create a copy of EnrolmentsReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? window = null,Object? courseCount = null,Object? kpis = null,Object? series = null,Object? sources = null,Object? categories = null,Object? cohorts = null,}) {
  return _then(_EnrolmentsReport(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as ReportWindow,courseCount: null == courseCount ? _self.courseCount : courseCount // ignore: cast_nullable_to_non_nullable
as int,kpis: null == kpis ? _self.kpis : kpis // ignore: cast_nullable_to_non_nullable
as EnrolmentKpis,series: null == series ? _self.series : series // ignore: cast_nullable_to_non_nullable
as ReportSeries,sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<EnrolmentSourceRow>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<CategoryReportRow>,cohorts: null == cohorts ? _self._cohorts : cohorts // ignore: cast_nullable_to_non_nullable
as List<CohortRow>,
  ));
}

/// Create a copy of EnrolmentsReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportWindowCopyWith<$Res> get window {
  
  return $ReportWindowCopyWith<$Res>(_self.window, (value) {
    return _then(_self.copyWith(window: value));
  });
}/// Create a copy of EnrolmentsReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EnrolmentKpisCopyWith<$Res> get kpis {
  
  return $EnrolmentKpisCopyWith<$Res>(_self.kpis, (value) {
    return _then(_self.copyWith(kpis: value));
  });
}/// Create a copy of EnrolmentsReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportSeriesCopyWith<$Res> get series {
  
  return $ReportSeriesCopyWith<$Res>(_self.series, (value) {
    return _then(_self.copyWith(series: value));
  });
}
}


/// @nodoc
mixin _$InstructorReportRow {

 String get instructorId; String get name; String get title; int get courses; int get learners; int? get completionRate; double? get rating; int get reviews; int? get reviewHours; int? get onTime; int get liveClasses; int? get attendance;
/// Create a copy of InstructorReportRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstructorReportRowCopyWith<InstructorReportRow> get copyWith => _$InstructorReportRowCopyWithImpl<InstructorReportRow>(this as InstructorReportRow, _$identity);

  /// Serializes this InstructorReportRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstructorReportRow&&(identical(other.instructorId, instructorId) || other.instructorId == instructorId)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.courses, courses) || other.courses == courses)&&(identical(other.learners, learners) || other.learners == learners)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.reviews, reviews) || other.reviews == reviews)&&(identical(other.reviewHours, reviewHours) || other.reviewHours == reviewHours)&&(identical(other.onTime, onTime) || other.onTime == onTime)&&(identical(other.liveClasses, liveClasses) || other.liveClasses == liveClasses)&&(identical(other.attendance, attendance) || other.attendance == attendance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,instructorId,name,title,courses,learners,completionRate,rating,reviews,reviewHours,onTime,liveClasses,attendance);

@override
String toString() {
  return 'InstructorReportRow(instructorId: $instructorId, name: $name, title: $title, courses: $courses, learners: $learners, completionRate: $completionRate, rating: $rating, reviews: $reviews, reviewHours: $reviewHours, onTime: $onTime, liveClasses: $liveClasses, attendance: $attendance)';
}


}

/// @nodoc
abstract mixin class $InstructorReportRowCopyWith<$Res>  {
  factory $InstructorReportRowCopyWith(InstructorReportRow value, $Res Function(InstructorReportRow) _then) = _$InstructorReportRowCopyWithImpl;
@useResult
$Res call({
 String instructorId, String name, String title, int courses, int learners, int? completionRate, double? rating, int reviews, int? reviewHours, int? onTime, int liveClasses, int? attendance
});




}
/// @nodoc
class _$InstructorReportRowCopyWithImpl<$Res>
    implements $InstructorReportRowCopyWith<$Res> {
  _$InstructorReportRowCopyWithImpl(this._self, this._then);

  final InstructorReportRow _self;
  final $Res Function(InstructorReportRow) _then;

/// Create a copy of InstructorReportRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? instructorId = null,Object? name = null,Object? title = null,Object? courses = null,Object? learners = null,Object? completionRate = freezed,Object? rating = freezed,Object? reviews = null,Object? reviewHours = freezed,Object? onTime = freezed,Object? liveClasses = null,Object? attendance = freezed,}) {
  return _then(_self.copyWith(
instructorId: null == instructorId ? _self.instructorId : instructorId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,courses: null == courses ? _self.courses : courses // ignore: cast_nullable_to_non_nullable
as int,learners: null == learners ? _self.learners : learners // ignore: cast_nullable_to_non_nullable
as int,completionRate: freezed == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as int?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,reviews: null == reviews ? _self.reviews : reviews // ignore: cast_nullable_to_non_nullable
as int,reviewHours: freezed == reviewHours ? _self.reviewHours : reviewHours // ignore: cast_nullable_to_non_nullable
as int?,onTime: freezed == onTime ? _self.onTime : onTime // ignore: cast_nullable_to_non_nullable
as int?,liveClasses: null == liveClasses ? _self.liveClasses : liveClasses // ignore: cast_nullable_to_non_nullable
as int,attendance: freezed == attendance ? _self.attendance : attendance // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [InstructorReportRow].
extension InstructorReportRowPatterns on InstructorReportRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstructorReportRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstructorReportRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstructorReportRow value)  $default,){
final _that = this;
switch (_that) {
case _InstructorReportRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstructorReportRow value)?  $default,){
final _that = this;
switch (_that) {
case _InstructorReportRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String instructorId,  String name,  String title,  int courses,  int learners,  int? completionRate,  double? rating,  int reviews,  int? reviewHours,  int? onTime,  int liveClasses,  int? attendance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstructorReportRow() when $default != null:
return $default(_that.instructorId,_that.name,_that.title,_that.courses,_that.learners,_that.completionRate,_that.rating,_that.reviews,_that.reviewHours,_that.onTime,_that.liveClasses,_that.attendance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String instructorId,  String name,  String title,  int courses,  int learners,  int? completionRate,  double? rating,  int reviews,  int? reviewHours,  int? onTime,  int liveClasses,  int? attendance)  $default,) {final _that = this;
switch (_that) {
case _InstructorReportRow():
return $default(_that.instructorId,_that.name,_that.title,_that.courses,_that.learners,_that.completionRate,_that.rating,_that.reviews,_that.reviewHours,_that.onTime,_that.liveClasses,_that.attendance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String instructorId,  String name,  String title,  int courses,  int learners,  int? completionRate,  double? rating,  int reviews,  int? reviewHours,  int? onTime,  int liveClasses,  int? attendance)?  $default,) {final _that = this;
switch (_that) {
case _InstructorReportRow() when $default != null:
return $default(_that.instructorId,_that.name,_that.title,_that.courses,_that.learners,_that.completionRate,_that.rating,_that.reviews,_that.reviewHours,_that.onTime,_that.liveClasses,_that.attendance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstructorReportRow implements InstructorReportRow {
  const _InstructorReportRow({this.instructorId = '', this.name = '', this.title = '', this.courses = 0, this.learners = 0, this.completionRate, this.rating, this.reviews = 0, this.reviewHours, this.onTime, this.liveClasses = 0, this.attendance});
  factory _InstructorReportRow.fromJson(Map<String, dynamic> json) => _$InstructorReportRowFromJson(json);

@override@JsonKey() final  String instructorId;
@override@JsonKey() final  String name;
@override@JsonKey() final  String title;
@override@JsonKey() final  int courses;
@override@JsonKey() final  int learners;
@override final  int? completionRate;
@override final  double? rating;
@override@JsonKey() final  int reviews;
@override final  int? reviewHours;
@override final  int? onTime;
@override@JsonKey() final  int liveClasses;
@override final  int? attendance;

/// Create a copy of InstructorReportRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstructorReportRowCopyWith<_InstructorReportRow> get copyWith => __$InstructorReportRowCopyWithImpl<_InstructorReportRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstructorReportRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstructorReportRow&&(identical(other.instructorId, instructorId) || other.instructorId == instructorId)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.courses, courses) || other.courses == courses)&&(identical(other.learners, learners) || other.learners == learners)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.reviews, reviews) || other.reviews == reviews)&&(identical(other.reviewHours, reviewHours) || other.reviewHours == reviewHours)&&(identical(other.onTime, onTime) || other.onTime == onTime)&&(identical(other.liveClasses, liveClasses) || other.liveClasses == liveClasses)&&(identical(other.attendance, attendance) || other.attendance == attendance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,instructorId,name,title,courses,learners,completionRate,rating,reviews,reviewHours,onTime,liveClasses,attendance);

@override
String toString() {
  return 'InstructorReportRow(instructorId: $instructorId, name: $name, title: $title, courses: $courses, learners: $learners, completionRate: $completionRate, rating: $rating, reviews: $reviews, reviewHours: $reviewHours, onTime: $onTime, liveClasses: $liveClasses, attendance: $attendance)';
}


}

/// @nodoc
abstract mixin class _$InstructorReportRowCopyWith<$Res> implements $InstructorReportRowCopyWith<$Res> {
  factory _$InstructorReportRowCopyWith(_InstructorReportRow value, $Res Function(_InstructorReportRow) _then) = __$InstructorReportRowCopyWithImpl;
@override @useResult
$Res call({
 String instructorId, String name, String title, int courses, int learners, int? completionRate, double? rating, int reviews, int? reviewHours, int? onTime, int liveClasses, int? attendance
});




}
/// @nodoc
class __$InstructorReportRowCopyWithImpl<$Res>
    implements _$InstructorReportRowCopyWith<$Res> {
  __$InstructorReportRowCopyWithImpl(this._self, this._then);

  final _InstructorReportRow _self;
  final $Res Function(_InstructorReportRow) _then;

/// Create a copy of InstructorReportRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? instructorId = null,Object? name = null,Object? title = null,Object? courses = null,Object? learners = null,Object? completionRate = freezed,Object? rating = freezed,Object? reviews = null,Object? reviewHours = freezed,Object? onTime = freezed,Object? liveClasses = null,Object? attendance = freezed,}) {
  return _then(_InstructorReportRow(
instructorId: null == instructorId ? _self.instructorId : instructorId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,courses: null == courses ? _self.courses : courses // ignore: cast_nullable_to_non_nullable
as int,learners: null == learners ? _self.learners : learners // ignore: cast_nullable_to_non_nullable
as int,completionRate: freezed == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as int?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,reviews: null == reviews ? _self.reviews : reviews // ignore: cast_nullable_to_non_nullable
as int,reviewHours: freezed == reviewHours ? _self.reviewHours : reviewHours // ignore: cast_nullable_to_non_nullable
as int?,onTime: freezed == onTime ? _self.onTime : onTime // ignore: cast_nullable_to_non_nullable
as int?,liveClasses: null == liveClasses ? _self.liveClasses : liveClasses // ignore: cast_nullable_to_non_nullable
as int,attendance: freezed == attendance ? _self.attendance : attendance // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$InstructorReportFigures {

 Kpi get reviews; Kpi get reviewHours; Kpi get onTime; Kpi get attendance;
/// Create a copy of InstructorReportFigures
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstructorReportFiguresCopyWith<InstructorReportFigures> get copyWith => _$InstructorReportFiguresCopyWithImpl<InstructorReportFigures>(this as InstructorReportFigures, _$identity);

  /// Serializes this InstructorReportFigures to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstructorReportFigures&&(identical(other.reviews, reviews) || other.reviews == reviews)&&(identical(other.reviewHours, reviewHours) || other.reviewHours == reviewHours)&&(identical(other.onTime, onTime) || other.onTime == onTime)&&(identical(other.attendance, attendance) || other.attendance == attendance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reviews,reviewHours,onTime,attendance);

@override
String toString() {
  return 'InstructorReportFigures(reviews: $reviews, reviewHours: $reviewHours, onTime: $onTime, attendance: $attendance)';
}


}

/// @nodoc
abstract mixin class $InstructorReportFiguresCopyWith<$Res>  {
  factory $InstructorReportFiguresCopyWith(InstructorReportFigures value, $Res Function(InstructorReportFigures) _then) = _$InstructorReportFiguresCopyWithImpl;
@useResult
$Res call({
 Kpi reviews, Kpi reviewHours, Kpi onTime, Kpi attendance
});


$KpiCopyWith<$Res> get reviews;$KpiCopyWith<$Res> get reviewHours;$KpiCopyWith<$Res> get onTime;$KpiCopyWith<$Res> get attendance;

}
/// @nodoc
class _$InstructorReportFiguresCopyWithImpl<$Res>
    implements $InstructorReportFiguresCopyWith<$Res> {
  _$InstructorReportFiguresCopyWithImpl(this._self, this._then);

  final InstructorReportFigures _self;
  final $Res Function(InstructorReportFigures) _then;

/// Create a copy of InstructorReportFigures
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reviews = null,Object? reviewHours = null,Object? onTime = null,Object? attendance = null,}) {
  return _then(_self.copyWith(
reviews: null == reviews ? _self.reviews : reviews // ignore: cast_nullable_to_non_nullable
as Kpi,reviewHours: null == reviewHours ? _self.reviewHours : reviewHours // ignore: cast_nullable_to_non_nullable
as Kpi,onTime: null == onTime ? _self.onTime : onTime // ignore: cast_nullable_to_non_nullable
as Kpi,attendance: null == attendance ? _self.attendance : attendance // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}
/// Create a copy of InstructorReportFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get reviews {
  
  return $KpiCopyWith<$Res>(_self.reviews, (value) {
    return _then(_self.copyWith(reviews: value));
  });
}/// Create a copy of InstructorReportFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get reviewHours {
  
  return $KpiCopyWith<$Res>(_self.reviewHours, (value) {
    return _then(_self.copyWith(reviewHours: value));
  });
}/// Create a copy of InstructorReportFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get onTime {
  
  return $KpiCopyWith<$Res>(_self.onTime, (value) {
    return _then(_self.copyWith(onTime: value));
  });
}/// Create a copy of InstructorReportFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get attendance {
  
  return $KpiCopyWith<$Res>(_self.attendance, (value) {
    return _then(_self.copyWith(attendance: value));
  });
}
}


/// Adds pattern-matching-related methods to [InstructorReportFigures].
extension InstructorReportFiguresPatterns on InstructorReportFigures {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstructorReportFigures value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstructorReportFigures() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstructorReportFigures value)  $default,){
final _that = this;
switch (_that) {
case _InstructorReportFigures():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstructorReportFigures value)?  $default,){
final _that = this;
switch (_that) {
case _InstructorReportFigures() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Kpi reviews,  Kpi reviewHours,  Kpi onTime,  Kpi attendance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstructorReportFigures() when $default != null:
return $default(_that.reviews,_that.reviewHours,_that.onTime,_that.attendance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Kpi reviews,  Kpi reviewHours,  Kpi onTime,  Kpi attendance)  $default,) {final _that = this;
switch (_that) {
case _InstructorReportFigures():
return $default(_that.reviews,_that.reviewHours,_that.onTime,_that.attendance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Kpi reviews,  Kpi reviewHours,  Kpi onTime,  Kpi attendance)?  $default,) {final _that = this;
switch (_that) {
case _InstructorReportFigures() when $default != null:
return $default(_that.reviews,_that.reviewHours,_that.onTime,_that.attendance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstructorReportFigures implements InstructorReportFigures {
  const _InstructorReportFigures({this.reviews = const Kpi(), this.reviewHours = const Kpi(), this.onTime = const Kpi(), this.attendance = const Kpi()});
  factory _InstructorReportFigures.fromJson(Map<String, dynamic> json) => _$InstructorReportFiguresFromJson(json);

@override@JsonKey() final  Kpi reviews;
@override@JsonKey() final  Kpi reviewHours;
@override@JsonKey() final  Kpi onTime;
@override@JsonKey() final  Kpi attendance;

/// Create a copy of InstructorReportFigures
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstructorReportFiguresCopyWith<_InstructorReportFigures> get copyWith => __$InstructorReportFiguresCopyWithImpl<_InstructorReportFigures>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstructorReportFiguresToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstructorReportFigures&&(identical(other.reviews, reviews) || other.reviews == reviews)&&(identical(other.reviewHours, reviewHours) || other.reviewHours == reviewHours)&&(identical(other.onTime, onTime) || other.onTime == onTime)&&(identical(other.attendance, attendance) || other.attendance == attendance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reviews,reviewHours,onTime,attendance);

@override
String toString() {
  return 'InstructorReportFigures(reviews: $reviews, reviewHours: $reviewHours, onTime: $onTime, attendance: $attendance)';
}


}

/// @nodoc
abstract mixin class _$InstructorReportFiguresCopyWith<$Res> implements $InstructorReportFiguresCopyWith<$Res> {
  factory _$InstructorReportFiguresCopyWith(_InstructorReportFigures value, $Res Function(_InstructorReportFigures) _then) = __$InstructorReportFiguresCopyWithImpl;
@override @useResult
$Res call({
 Kpi reviews, Kpi reviewHours, Kpi onTime, Kpi attendance
});


@override $KpiCopyWith<$Res> get reviews;@override $KpiCopyWith<$Res> get reviewHours;@override $KpiCopyWith<$Res> get onTime;@override $KpiCopyWith<$Res> get attendance;

}
/// @nodoc
class __$InstructorReportFiguresCopyWithImpl<$Res>
    implements _$InstructorReportFiguresCopyWith<$Res> {
  __$InstructorReportFiguresCopyWithImpl(this._self, this._then);

  final _InstructorReportFigures _self;
  final $Res Function(_InstructorReportFigures) _then;

/// Create a copy of InstructorReportFigures
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reviews = null,Object? reviewHours = null,Object? onTime = null,Object? attendance = null,}) {
  return _then(_InstructorReportFigures(
reviews: null == reviews ? _self.reviews : reviews // ignore: cast_nullable_to_non_nullable
as Kpi,reviewHours: null == reviewHours ? _self.reviewHours : reviewHours // ignore: cast_nullable_to_non_nullable
as Kpi,onTime: null == onTime ? _self.onTime : onTime // ignore: cast_nullable_to_non_nullable
as Kpi,attendance: null == attendance ? _self.attendance : attendance // ignore: cast_nullable_to_non_nullable
as Kpi,
  ));
}

/// Create a copy of InstructorReportFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get reviews {
  
  return $KpiCopyWith<$Res>(_self.reviews, (value) {
    return _then(_self.copyWith(reviews: value));
  });
}/// Create a copy of InstructorReportFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get reviewHours {
  
  return $KpiCopyWith<$Res>(_self.reviewHours, (value) {
    return _then(_self.copyWith(reviewHours: value));
  });
}/// Create a copy of InstructorReportFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get onTime {
  
  return $KpiCopyWith<$Res>(_self.onTime, (value) {
    return _then(_self.copyWith(onTime: value));
  });
}/// Create a copy of InstructorReportFigures
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KpiCopyWith<$Res> get attendance {
  
  return $KpiCopyWith<$Res>(_self.attendance, (value) {
    return _then(_self.copyWith(attendance: value));
  });
}
}


/// @nodoc
mixin _$InstructorsReport {

 ReportWindow get window; int get courseCount; List<InstructorReportRow> get rows; InstructorReportFigures get figures;
/// Create a copy of InstructorsReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstructorsReportCopyWith<InstructorsReport> get copyWith => _$InstructorsReportCopyWithImpl<InstructorsReport>(this as InstructorsReport, _$identity);

  /// Serializes this InstructorsReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstructorsReport&&(identical(other.window, window) || other.window == window)&&(identical(other.courseCount, courseCount) || other.courseCount == courseCount)&&const DeepCollectionEquality().equals(other.rows, rows)&&(identical(other.figures, figures) || other.figures == figures));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,window,courseCount,const DeepCollectionEquality().hash(rows),figures);

@override
String toString() {
  return 'InstructorsReport(window: $window, courseCount: $courseCount, rows: $rows, figures: $figures)';
}


}

/// @nodoc
abstract mixin class $InstructorsReportCopyWith<$Res>  {
  factory $InstructorsReportCopyWith(InstructorsReport value, $Res Function(InstructorsReport) _then) = _$InstructorsReportCopyWithImpl;
@useResult
$Res call({
 ReportWindow window, int courseCount, List<InstructorReportRow> rows, InstructorReportFigures figures
});


$ReportWindowCopyWith<$Res> get window;$InstructorReportFiguresCopyWith<$Res> get figures;

}
/// @nodoc
class _$InstructorsReportCopyWithImpl<$Res>
    implements $InstructorsReportCopyWith<$Res> {
  _$InstructorsReportCopyWithImpl(this._self, this._then);

  final InstructorsReport _self;
  final $Res Function(InstructorsReport) _then;

/// Create a copy of InstructorsReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? window = null,Object? courseCount = null,Object? rows = null,Object? figures = null,}) {
  return _then(_self.copyWith(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as ReportWindow,courseCount: null == courseCount ? _self.courseCount : courseCount // ignore: cast_nullable_to_non_nullable
as int,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<InstructorReportRow>,figures: null == figures ? _self.figures : figures // ignore: cast_nullable_to_non_nullable
as InstructorReportFigures,
  ));
}
/// Create a copy of InstructorsReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportWindowCopyWith<$Res> get window {
  
  return $ReportWindowCopyWith<$Res>(_self.window, (value) {
    return _then(_self.copyWith(window: value));
  });
}/// Create a copy of InstructorsReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstructorReportFiguresCopyWith<$Res> get figures {
  
  return $InstructorReportFiguresCopyWith<$Res>(_self.figures, (value) {
    return _then(_self.copyWith(figures: value));
  });
}
}


/// Adds pattern-matching-related methods to [InstructorsReport].
extension InstructorsReportPatterns on InstructorsReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstructorsReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstructorsReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstructorsReport value)  $default,){
final _that = this;
switch (_that) {
case _InstructorsReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstructorsReport value)?  $default,){
final _that = this;
switch (_that) {
case _InstructorsReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReportWindow window,  int courseCount,  List<InstructorReportRow> rows,  InstructorReportFigures figures)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstructorsReport() when $default != null:
return $default(_that.window,_that.courseCount,_that.rows,_that.figures);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReportWindow window,  int courseCount,  List<InstructorReportRow> rows,  InstructorReportFigures figures)  $default,) {final _that = this;
switch (_that) {
case _InstructorsReport():
return $default(_that.window,_that.courseCount,_that.rows,_that.figures);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReportWindow window,  int courseCount,  List<InstructorReportRow> rows,  InstructorReportFigures figures)?  $default,) {final _that = this;
switch (_that) {
case _InstructorsReport() when $default != null:
return $default(_that.window,_that.courseCount,_that.rows,_that.figures);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstructorsReport implements InstructorsReport {
  const _InstructorsReport({required this.window, this.courseCount = 0, final  List<InstructorReportRow> rows = const <InstructorReportRow>[], this.figures = const InstructorReportFigures()}): _rows = rows;
  factory _InstructorsReport.fromJson(Map<String, dynamic> json) => _$InstructorsReportFromJson(json);

@override final  ReportWindow window;
@override@JsonKey() final  int courseCount;
 final  List<InstructorReportRow> _rows;
@override@JsonKey() List<InstructorReportRow> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

@override@JsonKey() final  InstructorReportFigures figures;

/// Create a copy of InstructorsReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstructorsReportCopyWith<_InstructorsReport> get copyWith => __$InstructorsReportCopyWithImpl<_InstructorsReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstructorsReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstructorsReport&&(identical(other.window, window) || other.window == window)&&(identical(other.courseCount, courseCount) || other.courseCount == courseCount)&&const DeepCollectionEquality().equals(other._rows, _rows)&&(identical(other.figures, figures) || other.figures == figures));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,window,courseCount,const DeepCollectionEquality().hash(_rows),figures);

@override
String toString() {
  return 'InstructorsReport(window: $window, courseCount: $courseCount, rows: $rows, figures: $figures)';
}


}

/// @nodoc
abstract mixin class _$InstructorsReportCopyWith<$Res> implements $InstructorsReportCopyWith<$Res> {
  factory _$InstructorsReportCopyWith(_InstructorsReport value, $Res Function(_InstructorsReport) _then) = __$InstructorsReportCopyWithImpl;
@override @useResult
$Res call({
 ReportWindow window, int courseCount, List<InstructorReportRow> rows, InstructorReportFigures figures
});


@override $ReportWindowCopyWith<$Res> get window;@override $InstructorReportFiguresCopyWith<$Res> get figures;

}
/// @nodoc
class __$InstructorsReportCopyWithImpl<$Res>
    implements _$InstructorsReportCopyWith<$Res> {
  __$InstructorsReportCopyWithImpl(this._self, this._then);

  final _InstructorsReport _self;
  final $Res Function(_InstructorsReport) _then;

/// Create a copy of InstructorsReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? window = null,Object? courseCount = null,Object? rows = null,Object? figures = null,}) {
  return _then(_InstructorsReport(
window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as ReportWindow,courseCount: null == courseCount ? _self.courseCount : courseCount // ignore: cast_nullable_to_non_nullable
as int,rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<InstructorReportRow>,figures: null == figures ? _self.figures : figures // ignore: cast_nullable_to_non_nullable
as InstructorReportFigures,
  ));
}

/// Create a copy of InstructorsReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReportWindowCopyWith<$Res> get window {
  
  return $ReportWindowCopyWith<$Res>(_self.window, (value) {
    return _then(_self.copyWith(window: value));
  });
}/// Create a copy of InstructorsReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstructorReportFiguresCopyWith<$Res> get figures {
  
  return $InstructorReportFiguresCopyWith<$Res>(_self.figures, (value) {
    return _then(_self.copyWith(figures: value));
  });
}
}

// dart format on
