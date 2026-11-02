// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'academy_signup.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SignupPending {

 String get signupId; String get email;@UtcDateTimeConverter() DateTime get expiresAt;@UtcDateTimeConverter() DateTime get resendAvailableAt;
/// Create a copy of SignupPending
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignupPendingCopyWith<SignupPending> get copyWith => _$SignupPendingCopyWithImpl<SignupPending>(this as SignupPending, _$identity);

  /// Serializes this SignupPending to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignupPending&&(identical(other.signupId, signupId) || other.signupId == signupId)&&(identical(other.email, email) || other.email == email)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.resendAvailableAt, resendAvailableAt) || other.resendAvailableAt == resendAvailableAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,signupId,email,expiresAt,resendAvailableAt);

@override
String toString() {
  return 'SignupPending(signupId: $signupId, email: $email, expiresAt: $expiresAt, resendAvailableAt: $resendAvailableAt)';
}


}

/// @nodoc
abstract mixin class $SignupPendingCopyWith<$Res>  {
  factory $SignupPendingCopyWith(SignupPending value, $Res Function(SignupPending) _then) = _$SignupPendingCopyWithImpl;
@useResult
$Res call({
 String signupId, String email,@UtcDateTimeConverter() DateTime expiresAt,@UtcDateTimeConverter() DateTime resendAvailableAt
});




}
/// @nodoc
class _$SignupPendingCopyWithImpl<$Res>
    implements $SignupPendingCopyWith<$Res> {
  _$SignupPendingCopyWithImpl(this._self, this._then);

  final SignupPending _self;
  final $Res Function(SignupPending) _then;

/// Create a copy of SignupPending
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? signupId = null,Object? email = null,Object? expiresAt = null,Object? resendAvailableAt = null,}) {
  return _then(_self.copyWith(
signupId: null == signupId ? _self.signupId : signupId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,resendAvailableAt: null == resendAvailableAt ? _self.resendAvailableAt : resendAvailableAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SignupPending].
extension SignupPendingPatterns on SignupPending {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SignupPending value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignupPending() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SignupPending value)  $default,){
final _that = this;
switch (_that) {
case _SignupPending():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SignupPending value)?  $default,){
final _that = this;
switch (_that) {
case _SignupPending() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String signupId,  String email, @UtcDateTimeConverter()  DateTime expiresAt, @UtcDateTimeConverter()  DateTime resendAvailableAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignupPending() when $default != null:
return $default(_that.signupId,_that.email,_that.expiresAt,_that.resendAvailableAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String signupId,  String email, @UtcDateTimeConverter()  DateTime expiresAt, @UtcDateTimeConverter()  DateTime resendAvailableAt)  $default,) {final _that = this;
switch (_that) {
case _SignupPending():
return $default(_that.signupId,_that.email,_that.expiresAt,_that.resendAvailableAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String signupId,  String email, @UtcDateTimeConverter()  DateTime expiresAt, @UtcDateTimeConverter()  DateTime resendAvailableAt)?  $default,) {final _that = this;
switch (_that) {
case _SignupPending() when $default != null:
return $default(_that.signupId,_that.email,_that.expiresAt,_that.resendAvailableAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SignupPending implements SignupPending {
  const _SignupPending({required this.signupId, required this.email, @UtcDateTimeConverter() required this.expiresAt, @UtcDateTimeConverter() required this.resendAvailableAt});
  factory _SignupPending.fromJson(Map<String, dynamic> json) => _$SignupPendingFromJson(json);

@override final  String signupId;
@override final  String email;
@override@UtcDateTimeConverter() final  DateTime expiresAt;
@override@UtcDateTimeConverter() final  DateTime resendAvailableAt;

/// Create a copy of SignupPending
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignupPendingCopyWith<_SignupPending> get copyWith => __$SignupPendingCopyWithImpl<_SignupPending>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignupPendingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignupPending&&(identical(other.signupId, signupId) || other.signupId == signupId)&&(identical(other.email, email) || other.email == email)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.resendAvailableAt, resendAvailableAt) || other.resendAvailableAt == resendAvailableAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,signupId,email,expiresAt,resendAvailableAt);

@override
String toString() {
  return 'SignupPending(signupId: $signupId, email: $email, expiresAt: $expiresAt, resendAvailableAt: $resendAvailableAt)';
}


}

/// @nodoc
abstract mixin class _$SignupPendingCopyWith<$Res> implements $SignupPendingCopyWith<$Res> {
  factory _$SignupPendingCopyWith(_SignupPending value, $Res Function(_SignupPending) _then) = __$SignupPendingCopyWithImpl;
@override @useResult
$Res call({
 String signupId, String email,@UtcDateTimeConverter() DateTime expiresAt,@UtcDateTimeConverter() DateTime resendAvailableAt
});




}
/// @nodoc
class __$SignupPendingCopyWithImpl<$Res>
    implements _$SignupPendingCopyWith<$Res> {
  __$SignupPendingCopyWithImpl(this._self, this._then);

  final _SignupPending _self;
  final $Res Function(_SignupPending) _then;

/// Create a copy of SignupPending
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? signupId = null,Object? email = null,Object? expiresAt = null,Object? resendAvailableAt = null,}) {
  return _then(_SignupPending(
signupId: null == signupId ? _self.signupId : signupId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,resendAvailableAt: null == resendAvailableAt ? _self.resendAvailableAt : resendAvailableAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
