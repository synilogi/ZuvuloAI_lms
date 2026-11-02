// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'join_links.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LmsSummary {

 String get name; String get slug;
/// Create a copy of LmsSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LmsSummaryCopyWith<LmsSummary> get copyWith => _$LmsSummaryCopyWithImpl<LmsSummary>(this as LmsSummary, _$identity);

  /// Serializes this LmsSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LmsSummary&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,slug);

@override
String toString() {
  return 'LmsSummary(name: $name, slug: $slug)';
}


}

/// @nodoc
abstract mixin class $LmsSummaryCopyWith<$Res>  {
  factory $LmsSummaryCopyWith(LmsSummary value, $Res Function(LmsSummary) _then) = _$LmsSummaryCopyWithImpl;
@useResult
$Res call({
 String name, String slug
});




}
/// @nodoc
class _$LmsSummaryCopyWithImpl<$Res>
    implements $LmsSummaryCopyWith<$Res> {
  _$LmsSummaryCopyWithImpl(this._self, this._then);

  final LmsSummary _self;
  final $Res Function(LmsSummary) _then;

/// Create a copy of LmsSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? slug = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LmsSummary].
extension LmsSummaryPatterns on LmsSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LmsSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LmsSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LmsSummary value)  $default,){
final _that = this;
switch (_that) {
case _LmsSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LmsSummary value)?  $default,){
final _that = this;
switch (_that) {
case _LmsSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String slug)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LmsSummary() when $default != null:
return $default(_that.name,_that.slug);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String slug)  $default,) {final _that = this;
switch (_that) {
case _LmsSummary():
return $default(_that.name,_that.slug);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String slug)?  $default,) {final _that = this;
switch (_that) {
case _LmsSummary() when $default != null:
return $default(_that.name,_that.slug);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LmsSummary implements LmsSummary {
  const _LmsSummary({required this.name, required this.slug});
  factory _LmsSummary.fromJson(Map<String, dynamic> json) => _$LmsSummaryFromJson(json);

@override final  String name;
@override final  String slug;

/// Create a copy of LmsSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LmsSummaryCopyWith<_LmsSummary> get copyWith => __$LmsSummaryCopyWithImpl<_LmsSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LmsSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LmsSummary&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,slug);

@override
String toString() {
  return 'LmsSummary(name: $name, slug: $slug)';
}


}

/// @nodoc
abstract mixin class _$LmsSummaryCopyWith<$Res> implements $LmsSummaryCopyWith<$Res> {
  factory _$LmsSummaryCopyWith(_LmsSummary value, $Res Function(_LmsSummary) _then) = __$LmsSummaryCopyWithImpl;
@override @useResult
$Res call({
 String name, String slug
});




}
/// @nodoc
class __$LmsSummaryCopyWithImpl<$Res>
    implements _$LmsSummaryCopyWith<$Res> {
  __$LmsSummaryCopyWithImpl(this._self, this._then);

  final _LmsSummary _self;
  final $Res Function(_LmsSummary) _then;

/// Create a copy of LmsSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? slug = null,}) {
  return _then(_LmsSummary(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$LmsJoinPage {

 String get name; String get slug; bool get open; bool get invitationOnly;
/// Create a copy of LmsJoinPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LmsJoinPageCopyWith<LmsJoinPage> get copyWith => _$LmsJoinPageCopyWithImpl<LmsJoinPage>(this as LmsJoinPage, _$identity);

  /// Serializes this LmsJoinPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LmsJoinPage&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.open, open) || other.open == open)&&(identical(other.invitationOnly, invitationOnly) || other.invitationOnly == invitationOnly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,slug,open,invitationOnly);

@override
String toString() {
  return 'LmsJoinPage(name: $name, slug: $slug, open: $open, invitationOnly: $invitationOnly)';
}


}

/// @nodoc
abstract mixin class $LmsJoinPageCopyWith<$Res>  {
  factory $LmsJoinPageCopyWith(LmsJoinPage value, $Res Function(LmsJoinPage) _then) = _$LmsJoinPageCopyWithImpl;
@useResult
$Res call({
 String name, String slug, bool open, bool invitationOnly
});




}
/// @nodoc
class _$LmsJoinPageCopyWithImpl<$Res>
    implements $LmsJoinPageCopyWith<$Res> {
  _$LmsJoinPageCopyWithImpl(this._self, this._then);

  final LmsJoinPage _self;
  final $Res Function(LmsJoinPage) _then;

/// Create a copy of LmsJoinPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? slug = null,Object? open = null,Object? invitationOnly = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as bool,invitationOnly: null == invitationOnly ? _self.invitationOnly : invitationOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LmsJoinPage].
extension LmsJoinPagePatterns on LmsJoinPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LmsJoinPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LmsJoinPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LmsJoinPage value)  $default,){
final _that = this;
switch (_that) {
case _LmsJoinPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LmsJoinPage value)?  $default,){
final _that = this;
switch (_that) {
case _LmsJoinPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String slug,  bool open,  bool invitationOnly)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LmsJoinPage() when $default != null:
return $default(_that.name,_that.slug,_that.open,_that.invitationOnly);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String slug,  bool open,  bool invitationOnly)  $default,) {final _that = this;
switch (_that) {
case _LmsJoinPage():
return $default(_that.name,_that.slug,_that.open,_that.invitationOnly);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String slug,  bool open,  bool invitationOnly)?  $default,) {final _that = this;
switch (_that) {
case _LmsJoinPage() when $default != null:
return $default(_that.name,_that.slug,_that.open,_that.invitationOnly);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LmsJoinPage implements LmsJoinPage {
  const _LmsJoinPage({required this.name, required this.slug, this.open = false, this.invitationOnly = false});
  factory _LmsJoinPage.fromJson(Map<String, dynamic> json) => _$LmsJoinPageFromJson(json);

@override final  String name;
@override final  String slug;
@override@JsonKey() final  bool open;
@override@JsonKey() final  bool invitationOnly;

/// Create a copy of LmsJoinPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LmsJoinPageCopyWith<_LmsJoinPage> get copyWith => __$LmsJoinPageCopyWithImpl<_LmsJoinPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LmsJoinPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LmsJoinPage&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.open, open) || other.open == open)&&(identical(other.invitationOnly, invitationOnly) || other.invitationOnly == invitationOnly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,slug,open,invitationOnly);

@override
String toString() {
  return 'LmsJoinPage(name: $name, slug: $slug, open: $open, invitationOnly: $invitationOnly)';
}


}

/// @nodoc
abstract mixin class _$LmsJoinPageCopyWith<$Res> implements $LmsJoinPageCopyWith<$Res> {
  factory _$LmsJoinPageCopyWith(_LmsJoinPage value, $Res Function(_LmsJoinPage) _then) = __$LmsJoinPageCopyWithImpl;
@override @useResult
$Res call({
 String name, String slug, bool open, bool invitationOnly
});




}
/// @nodoc
class __$LmsJoinPageCopyWithImpl<$Res>
    implements _$LmsJoinPageCopyWith<$Res> {
  __$LmsJoinPageCopyWithImpl(this._self, this._then);

  final _LmsJoinPage _self;
  final $Res Function(_LmsJoinPage) _then;

/// Create a copy of LmsJoinPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? slug = null,Object? open = null,Object? invitationOnly = null,}) {
  return _then(_LmsJoinPage(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as bool,invitationOnly: null == invitationOnly ? _self.invitationOnly : invitationOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$InvitationView {

 LmsSummary get lms; String get role; String? get email;@UtcDateTimeConverter() DateTime get expiresAt; bool get open;
/// Create a copy of InvitationView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvitationViewCopyWith<InvitationView> get copyWith => _$InvitationViewCopyWithImpl<InvitationView>(this as InvitationView, _$identity);

  /// Serializes this InvitationView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvitationView&&(identical(other.lms, lms) || other.lms == lms)&&(identical(other.role, role) || other.role == role)&&(identical(other.email, email) || other.email == email)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.open, open) || other.open == open));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lms,role,email,expiresAt,open);

@override
String toString() {
  return 'InvitationView(lms: $lms, role: $role, email: $email, expiresAt: $expiresAt, open: $open)';
}


}

/// @nodoc
abstract mixin class $InvitationViewCopyWith<$Res>  {
  factory $InvitationViewCopyWith(InvitationView value, $Res Function(InvitationView) _then) = _$InvitationViewCopyWithImpl;
@useResult
$Res call({
 LmsSummary lms, String role, String? email,@UtcDateTimeConverter() DateTime expiresAt, bool open
});


$LmsSummaryCopyWith<$Res> get lms;

}
/// @nodoc
class _$InvitationViewCopyWithImpl<$Res>
    implements $InvitationViewCopyWith<$Res> {
  _$InvitationViewCopyWithImpl(this._self, this._then);

  final InvitationView _self;
  final $Res Function(InvitationView) _then;

/// Create a copy of InvitationView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lms = null,Object? role = null,Object? email = freezed,Object? expiresAt = null,Object? open = null,}) {
  return _then(_self.copyWith(
lms: null == lms ? _self.lms : lms // ignore: cast_nullable_to_non_nullable
as LmsSummary,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of InvitationView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LmsSummaryCopyWith<$Res> get lms {
  
  return $LmsSummaryCopyWith<$Res>(_self.lms, (value) {
    return _then(_self.copyWith(lms: value));
  });
}
}


/// Adds pattern-matching-related methods to [InvitationView].
extension InvitationViewPatterns on InvitationView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvitationView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvitationView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvitationView value)  $default,){
final _that = this;
switch (_that) {
case _InvitationView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvitationView value)?  $default,){
final _that = this;
switch (_that) {
case _InvitationView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LmsSummary lms,  String role,  String? email, @UtcDateTimeConverter()  DateTime expiresAt,  bool open)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvitationView() when $default != null:
return $default(_that.lms,_that.role,_that.email,_that.expiresAt,_that.open);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LmsSummary lms,  String role,  String? email, @UtcDateTimeConverter()  DateTime expiresAt,  bool open)  $default,) {final _that = this;
switch (_that) {
case _InvitationView():
return $default(_that.lms,_that.role,_that.email,_that.expiresAt,_that.open);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LmsSummary lms,  String role,  String? email, @UtcDateTimeConverter()  DateTime expiresAt,  bool open)?  $default,) {final _that = this;
switch (_that) {
case _InvitationView() when $default != null:
return $default(_that.lms,_that.role,_that.email,_that.expiresAt,_that.open);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvitationView implements InvitationView {
  const _InvitationView({required this.lms, this.role = 'student', this.email, @UtcDateTimeConverter() required this.expiresAt, this.open = false});
  factory _InvitationView.fromJson(Map<String, dynamic> json) => _$InvitationViewFromJson(json);

@override final  LmsSummary lms;
@override@JsonKey() final  String role;
@override final  String? email;
@override@UtcDateTimeConverter() final  DateTime expiresAt;
@override@JsonKey() final  bool open;

/// Create a copy of InvitationView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvitationViewCopyWith<_InvitationView> get copyWith => __$InvitationViewCopyWithImpl<_InvitationView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvitationViewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvitationView&&(identical(other.lms, lms) || other.lms == lms)&&(identical(other.role, role) || other.role == role)&&(identical(other.email, email) || other.email == email)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.open, open) || other.open == open));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lms,role,email,expiresAt,open);

@override
String toString() {
  return 'InvitationView(lms: $lms, role: $role, email: $email, expiresAt: $expiresAt, open: $open)';
}


}

/// @nodoc
abstract mixin class _$InvitationViewCopyWith<$Res> implements $InvitationViewCopyWith<$Res> {
  factory _$InvitationViewCopyWith(_InvitationView value, $Res Function(_InvitationView) _then) = __$InvitationViewCopyWithImpl;
@override @useResult
$Res call({
 LmsSummary lms, String role, String? email,@UtcDateTimeConverter() DateTime expiresAt, bool open
});


@override $LmsSummaryCopyWith<$Res> get lms;

}
/// @nodoc
class __$InvitationViewCopyWithImpl<$Res>
    implements _$InvitationViewCopyWith<$Res> {
  __$InvitationViewCopyWithImpl(this._self, this._then);

  final _InvitationView _self;
  final $Res Function(_InvitationView) _then;

/// Create a copy of InvitationView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lms = null,Object? role = null,Object? email = freezed,Object? expiresAt = null,Object? open = null,}) {
  return _then(_InvitationView(
lms: null == lms ? _self.lms : lms // ignore: cast_nullable_to_non_nullable
as LmsSummary,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of InvitationView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LmsSummaryCopyWith<$Res> get lms {
  
  return $LmsSummaryCopyWith<$Res>(_self.lms, (value) {
    return _then(_self.copyWith(lms: value));
  });
}
}


/// @nodoc
mixin _$CourseLinkCourse {

 String get id; String get title; String get slug;
/// Create a copy of CourseLinkCourse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseLinkCourseCopyWith<CourseLinkCourse> get copyWith => _$CourseLinkCourseCopyWithImpl<CourseLinkCourse>(this as CourseLinkCourse, _$identity);

  /// Serializes this CourseLinkCourse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseLinkCourse&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,slug);

@override
String toString() {
  return 'CourseLinkCourse(id: $id, title: $title, slug: $slug)';
}


}

/// @nodoc
abstract mixin class $CourseLinkCourseCopyWith<$Res>  {
  factory $CourseLinkCourseCopyWith(CourseLinkCourse value, $Res Function(CourseLinkCourse) _then) = _$CourseLinkCourseCopyWithImpl;
@useResult
$Res call({
 String id, String title, String slug
});




}
/// @nodoc
class _$CourseLinkCourseCopyWithImpl<$Res>
    implements $CourseLinkCourseCopyWith<$Res> {
  _$CourseLinkCourseCopyWithImpl(this._self, this._then);

  final CourseLinkCourse _self;
  final $Res Function(CourseLinkCourse) _then;

/// Create a copy of CourseLinkCourse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? slug = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CourseLinkCourse].
extension CourseLinkCoursePatterns on CourseLinkCourse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseLinkCourse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseLinkCourse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseLinkCourse value)  $default,){
final _that = this;
switch (_that) {
case _CourseLinkCourse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseLinkCourse value)?  $default,){
final _that = this;
switch (_that) {
case _CourseLinkCourse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String slug)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseLinkCourse() when $default != null:
return $default(_that.id,_that.title,_that.slug);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String slug)  $default,) {final _that = this;
switch (_that) {
case _CourseLinkCourse():
return $default(_that.id,_that.title,_that.slug);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String slug)?  $default,) {final _that = this;
switch (_that) {
case _CourseLinkCourse() when $default != null:
return $default(_that.id,_that.title,_that.slug);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseLinkCourse implements CourseLinkCourse {
  const _CourseLinkCourse({required this.id, required this.title, this.slug = ''});
  factory _CourseLinkCourse.fromJson(Map<String, dynamic> json) => _$CourseLinkCourseFromJson(json);

@override final  String id;
@override final  String title;
@override@JsonKey() final  String slug;

/// Create a copy of CourseLinkCourse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseLinkCourseCopyWith<_CourseLinkCourse> get copyWith => __$CourseLinkCourseCopyWithImpl<_CourseLinkCourse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseLinkCourseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseLinkCourse&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,slug);

@override
String toString() {
  return 'CourseLinkCourse(id: $id, title: $title, slug: $slug)';
}


}

/// @nodoc
abstract mixin class _$CourseLinkCourseCopyWith<$Res> implements $CourseLinkCourseCopyWith<$Res> {
  factory _$CourseLinkCourseCopyWith(_CourseLinkCourse value, $Res Function(_CourseLinkCourse) _then) = __$CourseLinkCourseCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String slug
});




}
/// @nodoc
class __$CourseLinkCourseCopyWithImpl<$Res>
    implements _$CourseLinkCourseCopyWith<$Res> {
  __$CourseLinkCourseCopyWithImpl(this._self, this._then);

  final _CourseLinkCourse _self;
  final $Res Function(_CourseLinkCourse) _then;

/// Create a copy of CourseLinkCourse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? slug = null,}) {
  return _then(_CourseLinkCourse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CourseLinkView {

 LmsSummary get lms; CourseLinkCourse get course; bool get open;
/// Create a copy of CourseLinkView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseLinkViewCopyWith<CourseLinkView> get copyWith => _$CourseLinkViewCopyWithImpl<CourseLinkView>(this as CourseLinkView, _$identity);

  /// Serializes this CourseLinkView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseLinkView&&(identical(other.lms, lms) || other.lms == lms)&&(identical(other.course, course) || other.course == course)&&(identical(other.open, open) || other.open == open));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lms,course,open);

@override
String toString() {
  return 'CourseLinkView(lms: $lms, course: $course, open: $open)';
}


}

/// @nodoc
abstract mixin class $CourseLinkViewCopyWith<$Res>  {
  factory $CourseLinkViewCopyWith(CourseLinkView value, $Res Function(CourseLinkView) _then) = _$CourseLinkViewCopyWithImpl;
@useResult
$Res call({
 LmsSummary lms, CourseLinkCourse course, bool open
});


$LmsSummaryCopyWith<$Res> get lms;$CourseLinkCourseCopyWith<$Res> get course;

}
/// @nodoc
class _$CourseLinkViewCopyWithImpl<$Res>
    implements $CourseLinkViewCopyWith<$Res> {
  _$CourseLinkViewCopyWithImpl(this._self, this._then);

  final CourseLinkView _self;
  final $Res Function(CourseLinkView) _then;

/// Create a copy of CourseLinkView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lms = null,Object? course = null,Object? open = null,}) {
  return _then(_self.copyWith(
lms: null == lms ? _self.lms : lms // ignore: cast_nullable_to_non_nullable
as LmsSummary,course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as CourseLinkCourse,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of CourseLinkView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LmsSummaryCopyWith<$Res> get lms {
  
  return $LmsSummaryCopyWith<$Res>(_self.lms, (value) {
    return _then(_self.copyWith(lms: value));
  });
}/// Create a copy of CourseLinkView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseLinkCourseCopyWith<$Res> get course {
  
  return $CourseLinkCourseCopyWith<$Res>(_self.course, (value) {
    return _then(_self.copyWith(course: value));
  });
}
}


/// Adds pattern-matching-related methods to [CourseLinkView].
extension CourseLinkViewPatterns on CourseLinkView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseLinkView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseLinkView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseLinkView value)  $default,){
final _that = this;
switch (_that) {
case _CourseLinkView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseLinkView value)?  $default,){
final _that = this;
switch (_that) {
case _CourseLinkView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LmsSummary lms,  CourseLinkCourse course,  bool open)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseLinkView() when $default != null:
return $default(_that.lms,_that.course,_that.open);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LmsSummary lms,  CourseLinkCourse course,  bool open)  $default,) {final _that = this;
switch (_that) {
case _CourseLinkView():
return $default(_that.lms,_that.course,_that.open);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LmsSummary lms,  CourseLinkCourse course,  bool open)?  $default,) {final _that = this;
switch (_that) {
case _CourseLinkView() when $default != null:
return $default(_that.lms,_that.course,_that.open);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseLinkView implements CourseLinkView {
  const _CourseLinkView({required this.lms, required this.course, this.open = false});
  factory _CourseLinkView.fromJson(Map<String, dynamic> json) => _$CourseLinkViewFromJson(json);

@override final  LmsSummary lms;
@override final  CourseLinkCourse course;
@override@JsonKey() final  bool open;

/// Create a copy of CourseLinkView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseLinkViewCopyWith<_CourseLinkView> get copyWith => __$CourseLinkViewCopyWithImpl<_CourseLinkView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseLinkViewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseLinkView&&(identical(other.lms, lms) || other.lms == lms)&&(identical(other.course, course) || other.course == course)&&(identical(other.open, open) || other.open == open));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lms,course,open);

@override
String toString() {
  return 'CourseLinkView(lms: $lms, course: $course, open: $open)';
}


}

/// @nodoc
abstract mixin class _$CourseLinkViewCopyWith<$Res> implements $CourseLinkViewCopyWith<$Res> {
  factory _$CourseLinkViewCopyWith(_CourseLinkView value, $Res Function(_CourseLinkView) _then) = __$CourseLinkViewCopyWithImpl;
@override @useResult
$Res call({
 LmsSummary lms, CourseLinkCourse course, bool open
});


@override $LmsSummaryCopyWith<$Res> get lms;@override $CourseLinkCourseCopyWith<$Res> get course;

}
/// @nodoc
class __$CourseLinkViewCopyWithImpl<$Res>
    implements _$CourseLinkViewCopyWith<$Res> {
  __$CourseLinkViewCopyWithImpl(this._self, this._then);

  final _CourseLinkView _self;
  final $Res Function(_CourseLinkView) _then;

/// Create a copy of CourseLinkView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lms = null,Object? course = null,Object? open = null,}) {
  return _then(_CourseLinkView(
lms: null == lms ? _self.lms : lms // ignore: cast_nullable_to_non_nullable
as LmsSummary,course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as CourseLinkCourse,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of CourseLinkView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LmsSummaryCopyWith<$Res> get lms {
  
  return $LmsSummaryCopyWith<$Res>(_self.lms, (value) {
    return _then(_self.copyWith(lms: value));
  });
}/// Create a copy of CourseLinkView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseLinkCourseCopyWith<$Res> get course {
  
  return $CourseLinkCourseCopyWith<$Res>(_self.course, (value) {
    return _then(_self.copyWith(course: value));
  });
}
}

// dart format on
