// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RegisteredDevice {

 String get id; String get platform;/// The last eight characters of the token — never the token itself.
 String get tokenEnd;/// Whether this is the device the current session is signed in on.
 bool get current;@UtcDateTimeConverter() DateTime get createdAt;@UtcDateTimeConverter() DateTime get lastSeenAt;
/// Create a copy of RegisteredDevice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisteredDeviceCopyWith<RegisteredDevice> get copyWith => _$RegisteredDeviceCopyWithImpl<RegisteredDevice>(this as RegisteredDevice, _$identity);

  /// Serializes this RegisteredDevice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisteredDevice&&(identical(other.id, id) || other.id == id)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.tokenEnd, tokenEnd) || other.tokenEnd == tokenEnd)&&(identical(other.current, current) || other.current == current)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,platform,tokenEnd,current,createdAt,lastSeenAt);

@override
String toString() {
  return 'RegisteredDevice(id: $id, platform: $platform, tokenEnd: $tokenEnd, current: $current, createdAt: $createdAt, lastSeenAt: $lastSeenAt)';
}


}

/// @nodoc
abstract mixin class $RegisteredDeviceCopyWith<$Res>  {
  factory $RegisteredDeviceCopyWith(RegisteredDevice value, $Res Function(RegisteredDevice) _then) = _$RegisteredDeviceCopyWithImpl;
@useResult
$Res call({
 String id, String platform, String tokenEnd, bool current,@UtcDateTimeConverter() DateTime createdAt,@UtcDateTimeConverter() DateTime lastSeenAt
});




}
/// @nodoc
class _$RegisteredDeviceCopyWithImpl<$Res>
    implements $RegisteredDeviceCopyWith<$Res> {
  _$RegisteredDeviceCopyWithImpl(this._self, this._then);

  final RegisteredDevice _self;
  final $Res Function(RegisteredDevice) _then;

/// Create a copy of RegisteredDevice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? platform = null,Object? tokenEnd = null,Object? current = null,Object? createdAt = null,Object? lastSeenAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,tokenEnd: null == tokenEnd ? _self.tokenEnd : tokenEnd // ignore: cast_nullable_to_non_nullable
as String,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastSeenAt: null == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RegisteredDevice].
extension RegisteredDevicePatterns on RegisteredDevice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegisteredDevice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegisteredDevice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegisteredDevice value)  $default,){
final _that = this;
switch (_that) {
case _RegisteredDevice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegisteredDevice value)?  $default,){
final _that = this;
switch (_that) {
case _RegisteredDevice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String platform,  String tokenEnd,  bool current, @UtcDateTimeConverter()  DateTime createdAt, @UtcDateTimeConverter()  DateTime lastSeenAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegisteredDevice() when $default != null:
return $default(_that.id,_that.platform,_that.tokenEnd,_that.current,_that.createdAt,_that.lastSeenAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String platform,  String tokenEnd,  bool current, @UtcDateTimeConverter()  DateTime createdAt, @UtcDateTimeConverter()  DateTime lastSeenAt)  $default,) {final _that = this;
switch (_that) {
case _RegisteredDevice():
return $default(_that.id,_that.platform,_that.tokenEnd,_that.current,_that.createdAt,_that.lastSeenAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String platform,  String tokenEnd,  bool current, @UtcDateTimeConverter()  DateTime createdAt, @UtcDateTimeConverter()  DateTime lastSeenAt)?  $default,) {final _that = this;
switch (_that) {
case _RegisteredDevice() when $default != null:
return $default(_that.id,_that.platform,_that.tokenEnd,_that.current,_that.createdAt,_that.lastSeenAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RegisteredDevice implements RegisteredDevice {
  const _RegisteredDevice({this.id = '', this.platform = '', this.tokenEnd = '', this.current = false, @UtcDateTimeConverter() required this.createdAt, @UtcDateTimeConverter() required this.lastSeenAt});
  factory _RegisteredDevice.fromJson(Map<String, dynamic> json) => _$RegisteredDeviceFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String platform;
/// The last eight characters of the token — never the token itself.
@override@JsonKey() final  String tokenEnd;
/// Whether this is the device the current session is signed in on.
@override@JsonKey() final  bool current;
@override@UtcDateTimeConverter() final  DateTime createdAt;
@override@UtcDateTimeConverter() final  DateTime lastSeenAt;

/// Create a copy of RegisteredDevice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegisteredDeviceCopyWith<_RegisteredDevice> get copyWith => __$RegisteredDeviceCopyWithImpl<_RegisteredDevice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegisteredDeviceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegisteredDevice&&(identical(other.id, id) || other.id == id)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.tokenEnd, tokenEnd) || other.tokenEnd == tokenEnd)&&(identical(other.current, current) || other.current == current)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,platform,tokenEnd,current,createdAt,lastSeenAt);

@override
String toString() {
  return 'RegisteredDevice(id: $id, platform: $platform, tokenEnd: $tokenEnd, current: $current, createdAt: $createdAt, lastSeenAt: $lastSeenAt)';
}


}

/// @nodoc
abstract mixin class _$RegisteredDeviceCopyWith<$Res> implements $RegisteredDeviceCopyWith<$Res> {
  factory _$RegisteredDeviceCopyWith(_RegisteredDevice value, $Res Function(_RegisteredDevice) _then) = __$RegisteredDeviceCopyWithImpl;
@override @useResult
$Res call({
 String id, String platform, String tokenEnd, bool current,@UtcDateTimeConverter() DateTime createdAt,@UtcDateTimeConverter() DateTime lastSeenAt
});




}
/// @nodoc
class __$RegisteredDeviceCopyWithImpl<$Res>
    implements _$RegisteredDeviceCopyWith<$Res> {
  __$RegisteredDeviceCopyWithImpl(this._self, this._then);

  final _RegisteredDevice _self;
  final $Res Function(_RegisteredDevice) _then;

/// Create a copy of RegisteredDevice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? platform = null,Object? tokenEnd = null,Object? current = null,Object? createdAt = null,Object? lastSeenAt = null,}) {
  return _then(_RegisteredDevice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,tokenEnd: null == tokenEnd ? _self.tokenEnd : tokenEnd // ignore: cast_nullable_to_non_nullable
as String,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastSeenAt: null == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
