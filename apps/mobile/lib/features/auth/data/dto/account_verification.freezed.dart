// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_verification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VerificationPending {

 String get verificationId; String get email; String get role; String get lms;@UtcDateTimeConverter() DateTime get expiresAt;@UtcDateTimeConverter() DateTime get resendAvailableAt;
/// Create a copy of VerificationPending
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationPendingCopyWith<VerificationPending> get copyWith => _$VerificationPendingCopyWithImpl<VerificationPending>(this as VerificationPending, _$identity);

  /// Serializes this VerificationPending to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationPending&&(identical(other.verificationId, verificationId) || other.verificationId == verificationId)&&(identical(other.email, email) || other.email == email)&&(identical(other.role, role) || other.role == role)&&(identical(other.lms, lms) || other.lms == lms)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.resendAvailableAt, resendAvailableAt) || other.resendAvailableAt == resendAvailableAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,verificationId,email,role,lms,expiresAt,resendAvailableAt);

@override
String toString() {
  return 'VerificationPending(verificationId: $verificationId, email: $email, role: $role, lms: $lms, expiresAt: $expiresAt, resendAvailableAt: $resendAvailableAt)';
}


}

/// @nodoc
abstract mixin class $VerificationPendingCopyWith<$Res>  {
  factory $VerificationPendingCopyWith(VerificationPending value, $Res Function(VerificationPending) _then) = _$VerificationPendingCopyWithImpl;
@useResult
$Res call({
 String verificationId, String email, String role, String lms,@UtcDateTimeConverter() DateTime expiresAt,@UtcDateTimeConverter() DateTime resendAvailableAt
});




}
/// @nodoc
class _$VerificationPendingCopyWithImpl<$Res>
    implements $VerificationPendingCopyWith<$Res> {
  _$VerificationPendingCopyWithImpl(this._self, this._then);

  final VerificationPending _self;
  final $Res Function(VerificationPending) _then;

/// Create a copy of VerificationPending
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? verificationId = null,Object? email = null,Object? role = null,Object? lms = null,Object? expiresAt = null,Object? resendAvailableAt = null,}) {
  return _then(_self.copyWith(
verificationId: null == verificationId ? _self.verificationId : verificationId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,lms: null == lms ? _self.lms : lms // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,resendAvailableAt: null == resendAvailableAt ? _self.resendAvailableAt : resendAvailableAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [VerificationPending].
extension VerificationPendingPatterns on VerificationPending {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerificationPending value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerificationPending() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerificationPending value)  $default,){
final _that = this;
switch (_that) {
case _VerificationPending():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerificationPending value)?  $default,){
final _that = this;
switch (_that) {
case _VerificationPending() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String verificationId,  String email,  String role,  String lms, @UtcDateTimeConverter()  DateTime expiresAt, @UtcDateTimeConverter()  DateTime resendAvailableAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerificationPending() when $default != null:
return $default(_that.verificationId,_that.email,_that.role,_that.lms,_that.expiresAt,_that.resendAvailableAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String verificationId,  String email,  String role,  String lms, @UtcDateTimeConverter()  DateTime expiresAt, @UtcDateTimeConverter()  DateTime resendAvailableAt)  $default,) {final _that = this;
switch (_that) {
case _VerificationPending():
return $default(_that.verificationId,_that.email,_that.role,_that.lms,_that.expiresAt,_that.resendAvailableAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String verificationId,  String email,  String role,  String lms, @UtcDateTimeConverter()  DateTime expiresAt, @UtcDateTimeConverter()  DateTime resendAvailableAt)?  $default,) {final _that = this;
switch (_that) {
case _VerificationPending() when $default != null:
return $default(_that.verificationId,_that.email,_that.role,_that.lms,_that.expiresAt,_that.resendAvailableAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerificationPending implements VerificationPending {
  const _VerificationPending({required this.verificationId, required this.email, this.role = 'student', this.lms = '', @UtcDateTimeConverter() required this.expiresAt, @UtcDateTimeConverter() required this.resendAvailableAt});
  factory _VerificationPending.fromJson(Map<String, dynamic> json) => _$VerificationPendingFromJson(json);

@override final  String verificationId;
@override final  String email;
@override@JsonKey() final  String role;
@override@JsonKey() final  String lms;
@override@UtcDateTimeConverter() final  DateTime expiresAt;
@override@UtcDateTimeConverter() final  DateTime resendAvailableAt;

/// Create a copy of VerificationPending
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationPendingCopyWith<_VerificationPending> get copyWith => __$VerificationPendingCopyWithImpl<_VerificationPending>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerificationPendingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerificationPending&&(identical(other.verificationId, verificationId) || other.verificationId == verificationId)&&(identical(other.email, email) || other.email == email)&&(identical(other.role, role) || other.role == role)&&(identical(other.lms, lms) || other.lms == lms)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.resendAvailableAt, resendAvailableAt) || other.resendAvailableAt == resendAvailableAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,verificationId,email,role,lms,expiresAt,resendAvailableAt);

@override
String toString() {
  return 'VerificationPending(verificationId: $verificationId, email: $email, role: $role, lms: $lms, expiresAt: $expiresAt, resendAvailableAt: $resendAvailableAt)';
}


}

/// @nodoc
abstract mixin class _$VerificationPendingCopyWith<$Res> implements $VerificationPendingCopyWith<$Res> {
  factory _$VerificationPendingCopyWith(_VerificationPending value, $Res Function(_VerificationPending) _then) = __$VerificationPendingCopyWithImpl;
@override @useResult
$Res call({
 String verificationId, String email, String role, String lms,@UtcDateTimeConverter() DateTime expiresAt,@UtcDateTimeConverter() DateTime resendAvailableAt
});




}
/// @nodoc
class __$VerificationPendingCopyWithImpl<$Res>
    implements _$VerificationPendingCopyWith<$Res> {
  __$VerificationPendingCopyWithImpl(this._self, this._then);

  final _VerificationPending _self;
  final $Res Function(_VerificationPending) _then;

/// Create a copy of VerificationPending
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? verificationId = null,Object? email = null,Object? role = null,Object? lms = null,Object? expiresAt = null,Object? resendAvailableAt = null,}) {
  return _then(_VerificationPending(
verificationId: null == verificationId ? _self.verificationId : verificationId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,lms: null == lms ? _self.lms : lms // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,resendAvailableAt: null == resendAvailableAt ? _self.resendAvailableAt : resendAvailableAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
