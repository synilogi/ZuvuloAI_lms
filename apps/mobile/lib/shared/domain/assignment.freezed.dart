// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assignment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Attachment {

 String? get id; String get name; double get sizeMb; String? get url; String? get mime; int? get pages;
/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentCopyWith<Attachment> get copyWith => _$AttachmentCopyWithImpl<Attachment>(this as Attachment, _$identity);

  /// Serializes this Attachment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Attachment&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sizeMb, sizeMb) || other.sizeMb == sizeMb)&&(identical(other.url, url) || other.url == url)&&(identical(other.mime, mime) || other.mime == mime)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,sizeMb,url,mime,pages);

@override
String toString() {
  return 'Attachment(id: $id, name: $name, sizeMb: $sizeMb, url: $url, mime: $mime, pages: $pages)';
}


}

/// @nodoc
abstract mixin class $AttachmentCopyWith<$Res>  {
  factory $AttachmentCopyWith(Attachment value, $Res Function(Attachment) _then) = _$AttachmentCopyWithImpl;
@useResult
$Res call({
 String? id, String name, double sizeMb, String? url, String? mime, int? pages
});




}
/// @nodoc
class _$AttachmentCopyWithImpl<$Res>
    implements $AttachmentCopyWith<$Res> {
  _$AttachmentCopyWithImpl(this._self, this._then);

  final Attachment _self;
  final $Res Function(Attachment) _then;

/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = null,Object? sizeMb = null,Object? url = freezed,Object? mime = freezed,Object? pages = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sizeMb: null == sizeMb ? _self.sizeMb : sizeMb // ignore: cast_nullable_to_non_nullable
as double,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,mime: freezed == mime ? _self.mime : mime // ignore: cast_nullable_to_non_nullable
as String?,pages: freezed == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Attachment].
extension AttachmentPatterns on Attachment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Attachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Attachment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Attachment value)  $default,){
final _that = this;
switch (_that) {
case _Attachment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Attachment value)?  $default,){
final _that = this;
switch (_that) {
case _Attachment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String name,  double sizeMb,  String? url,  String? mime,  int? pages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Attachment() when $default != null:
return $default(_that.id,_that.name,_that.sizeMb,_that.url,_that.mime,_that.pages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String name,  double sizeMb,  String? url,  String? mime,  int? pages)  $default,) {final _that = this;
switch (_that) {
case _Attachment():
return $default(_that.id,_that.name,_that.sizeMb,_that.url,_that.mime,_that.pages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String name,  double sizeMb,  String? url,  String? mime,  int? pages)?  $default,) {final _that = this;
switch (_that) {
case _Attachment() when $default != null:
return $default(_that.id,_that.name,_that.sizeMb,_that.url,_that.mime,_that.pages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Attachment implements Attachment {
  const _Attachment({this.id, this.name = '', this.sizeMb = 0, this.url, this.mime, this.pages});
  factory _Attachment.fromJson(Map<String, dynamic> json) => _$AttachmentFromJson(json);

@override final  String? id;
@override@JsonKey() final  String name;
@override@JsonKey() final  double sizeMb;
@override final  String? url;
@override final  String? mime;
@override final  int? pages;

/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttachmentCopyWith<_Attachment> get copyWith => __$AttachmentCopyWithImpl<_Attachment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttachmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Attachment&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sizeMb, sizeMb) || other.sizeMb == sizeMb)&&(identical(other.url, url) || other.url == url)&&(identical(other.mime, mime) || other.mime == mime)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,sizeMb,url,mime,pages);

@override
String toString() {
  return 'Attachment(id: $id, name: $name, sizeMb: $sizeMb, url: $url, mime: $mime, pages: $pages)';
}


}

/// @nodoc
abstract mixin class _$AttachmentCopyWith<$Res> implements $AttachmentCopyWith<$Res> {
  factory _$AttachmentCopyWith(_Attachment value, $Res Function(_Attachment) _then) = __$AttachmentCopyWithImpl;
@override @useResult
$Res call({
 String? id, String name, double sizeMb, String? url, String? mime, int? pages
});




}
/// @nodoc
class __$AttachmentCopyWithImpl<$Res>
    implements _$AttachmentCopyWith<$Res> {
  __$AttachmentCopyWithImpl(this._self, this._then);

  final _Attachment _self;
  final $Res Function(_Attachment) _then;

/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = null,Object? sizeMb = null,Object? url = freezed,Object? mime = freezed,Object? pages = freezed,}) {
  return _then(_Attachment(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sizeMb: null == sizeMb ? _self.sizeMb : sizeMb // ignore: cast_nullable_to_non_nullable
as double,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,mime: freezed == mime ? _self.mime : mime // ignore: cast_nullable_to_non_nullable
as String?,pages: freezed == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$RubricCriterion {

 String get id; String get title; String get description; int get points;
/// Create a copy of RubricCriterion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RubricCriterionCopyWith<RubricCriterion> get copyWith => _$RubricCriterionCopyWithImpl<RubricCriterion>(this as RubricCriterion, _$identity);

  /// Serializes this RubricCriterion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RubricCriterion&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.points, points) || other.points == points));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,points);

@override
String toString() {
  return 'RubricCriterion(id: $id, title: $title, description: $description, points: $points)';
}


}

/// @nodoc
abstract mixin class $RubricCriterionCopyWith<$Res>  {
  factory $RubricCriterionCopyWith(RubricCriterion value, $Res Function(RubricCriterion) _then) = _$RubricCriterionCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, int points
});




}
/// @nodoc
class _$RubricCriterionCopyWithImpl<$Res>
    implements $RubricCriterionCopyWith<$Res> {
  _$RubricCriterionCopyWithImpl(this._self, this._then);

  final RubricCriterion _self;
  final $Res Function(RubricCriterion) _then;

/// Create a copy of RubricCriterion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? points = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RubricCriterion].
extension RubricCriterionPatterns on RubricCriterion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RubricCriterion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RubricCriterion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RubricCriterion value)  $default,){
final _that = this;
switch (_that) {
case _RubricCriterion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RubricCriterion value)?  $default,){
final _that = this;
switch (_that) {
case _RubricCriterion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  int points)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RubricCriterion() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.points);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  int points)  $default,) {final _that = this;
switch (_that) {
case _RubricCriterion():
return $default(_that.id,_that.title,_that.description,_that.points);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  int points)?  $default,) {final _that = this;
switch (_that) {
case _RubricCriterion() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.points);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RubricCriterion implements RubricCriterion {
  const _RubricCriterion({required this.id, this.title = '', this.description = '', this.points = 0});
  factory _RubricCriterion.fromJson(Map<String, dynamic> json) => _$RubricCriterionFromJson(json);

@override final  String id;
@override@JsonKey() final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  int points;

/// Create a copy of RubricCriterion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RubricCriterionCopyWith<_RubricCriterion> get copyWith => __$RubricCriterionCopyWithImpl<_RubricCriterion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RubricCriterionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RubricCriterion&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.points, points) || other.points == points));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,points);

@override
String toString() {
  return 'RubricCriterion(id: $id, title: $title, description: $description, points: $points)';
}


}

/// @nodoc
abstract mixin class _$RubricCriterionCopyWith<$Res> implements $RubricCriterionCopyWith<$Res> {
  factory _$RubricCriterionCopyWith(_RubricCriterion value, $Res Function(_RubricCriterion) _then) = __$RubricCriterionCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, int points
});




}
/// @nodoc
class __$RubricCriterionCopyWithImpl<$Res>
    implements _$RubricCriterionCopyWith<$Res> {
  __$RubricCriterionCopyWithImpl(this._self, this._then);

  final _RubricCriterion _self;
  final $Res Function(_RubricCriterion) _then;

/// Create a copy of RubricCriterion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? points = null,}) {
  return _then(_RubricCriterion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DuePolicy {

@JsonKey(unknownEnumValue: DueKind.unknown) DueKind get kind;@NullableUtcDateTimeConverter() DateTime? get dueAt; int? get days;
/// Create a copy of DuePolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuePolicyCopyWith<DuePolicy> get copyWith => _$DuePolicyCopyWithImpl<DuePolicy>(this as DuePolicy, _$identity);

  /// Serializes this DuePolicy to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuePolicy&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.days, days) || other.days == days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,dueAt,days);

@override
String toString() {
  return 'DuePolicy(kind: $kind, dueAt: $dueAt, days: $days)';
}


}

/// @nodoc
abstract mixin class $DuePolicyCopyWith<$Res>  {
  factory $DuePolicyCopyWith(DuePolicy value, $Res Function(DuePolicy) _then) = _$DuePolicyCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: DueKind.unknown) DueKind kind,@NullableUtcDateTimeConverter() DateTime? dueAt, int? days
});




}
/// @nodoc
class _$DuePolicyCopyWithImpl<$Res>
    implements $DuePolicyCopyWith<$Res> {
  _$DuePolicyCopyWithImpl(this._self, this._then);

  final DuePolicy _self;
  final $Res Function(DuePolicy) _then;

/// Create a copy of DuePolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? dueAt = freezed,Object? days = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as DueKind,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,days: freezed == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [DuePolicy].
extension DuePolicyPatterns on DuePolicy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuePolicy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuePolicy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuePolicy value)  $default,){
final _that = this;
switch (_that) {
case _DuePolicy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuePolicy value)?  $default,){
final _that = this;
switch (_that) {
case _DuePolicy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: DueKind.unknown)  DueKind kind, @NullableUtcDateTimeConverter()  DateTime? dueAt,  int? days)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuePolicy() when $default != null:
return $default(_that.kind,_that.dueAt,_that.days);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: DueKind.unknown)  DueKind kind, @NullableUtcDateTimeConverter()  DateTime? dueAt,  int? days)  $default,) {final _that = this;
switch (_that) {
case _DuePolicy():
return $default(_that.kind,_that.dueAt,_that.days);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: DueKind.unknown)  DueKind kind, @NullableUtcDateTimeConverter()  DateTime? dueAt,  int? days)?  $default,) {final _that = this;
switch (_that) {
case _DuePolicy() when $default != null:
return $default(_that.kind,_that.dueAt,_that.days);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DuePolicy implements DuePolicy {
  const _DuePolicy({@JsonKey(unknownEnumValue: DueKind.unknown) this.kind = DueKind.none, @NullableUtcDateTimeConverter() this.dueAt, this.days});
  factory _DuePolicy.fromJson(Map<String, dynamic> json) => _$DuePolicyFromJson(json);

@override@JsonKey(unknownEnumValue: DueKind.unknown) final  DueKind kind;
@override@NullableUtcDateTimeConverter() final  DateTime? dueAt;
@override final  int? days;

/// Create a copy of DuePolicy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuePolicyCopyWith<_DuePolicy> get copyWith => __$DuePolicyCopyWithImpl<_DuePolicy>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DuePolicyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuePolicy&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.days, days) || other.days == days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,dueAt,days);

@override
String toString() {
  return 'DuePolicy(kind: $kind, dueAt: $dueAt, days: $days)';
}


}

/// @nodoc
abstract mixin class _$DuePolicyCopyWith<$Res> implements $DuePolicyCopyWith<$Res> {
  factory _$DuePolicyCopyWith(_DuePolicy value, $Res Function(_DuePolicy) _then) = __$DuePolicyCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: DueKind.unknown) DueKind kind,@NullableUtcDateTimeConverter() DateTime? dueAt, int? days
});




}
/// @nodoc
class __$DuePolicyCopyWithImpl<$Res>
    implements _$DuePolicyCopyWith<$Res> {
  __$DuePolicyCopyWithImpl(this._self, this._then);

  final _DuePolicy _self;
  final $Res Function(_DuePolicy) _then;

/// Create a copy of DuePolicy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? dueAt = freezed,Object? days = freezed,}) {
  return _then(_DuePolicy(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as DueKind,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,days: freezed == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$BirthDetails {

 String get label; String get date; String get time; String get place; String get lagna; String get moonSign; String get nakshatra;
/// Create a copy of BirthDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BirthDetailsCopyWith<BirthDetails> get copyWith => _$BirthDetailsCopyWithImpl<BirthDetails>(this as BirthDetails, _$identity);

  /// Serializes this BirthDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BirthDetails&&(identical(other.label, label) || other.label == label)&&(identical(other.date, date) || other.date == date)&&(identical(other.time, time) || other.time == time)&&(identical(other.place, place) || other.place == place)&&(identical(other.lagna, lagna) || other.lagna == lagna)&&(identical(other.moonSign, moonSign) || other.moonSign == moonSign)&&(identical(other.nakshatra, nakshatra) || other.nakshatra == nakshatra));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,date,time,place,lagna,moonSign,nakshatra);

@override
String toString() {
  return 'BirthDetails(label: $label, date: $date, time: $time, place: $place, lagna: $lagna, moonSign: $moonSign, nakshatra: $nakshatra)';
}


}

/// @nodoc
abstract mixin class $BirthDetailsCopyWith<$Res>  {
  factory $BirthDetailsCopyWith(BirthDetails value, $Res Function(BirthDetails) _then) = _$BirthDetailsCopyWithImpl;
@useResult
$Res call({
 String label, String date, String time, String place, String lagna, String moonSign, String nakshatra
});




}
/// @nodoc
class _$BirthDetailsCopyWithImpl<$Res>
    implements $BirthDetailsCopyWith<$Res> {
  _$BirthDetailsCopyWithImpl(this._self, this._then);

  final BirthDetails _self;
  final $Res Function(BirthDetails) _then;

/// Create a copy of BirthDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? date = null,Object? time = null,Object? place = null,Object? lagna = null,Object? moonSign = null,Object? nakshatra = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String,place: null == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String,lagna: null == lagna ? _self.lagna : lagna // ignore: cast_nullable_to_non_nullable
as String,moonSign: null == moonSign ? _self.moonSign : moonSign // ignore: cast_nullable_to_non_nullable
as String,nakshatra: null == nakshatra ? _self.nakshatra : nakshatra // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BirthDetails].
extension BirthDetailsPatterns on BirthDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BirthDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BirthDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BirthDetails value)  $default,){
final _that = this;
switch (_that) {
case _BirthDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BirthDetails value)?  $default,){
final _that = this;
switch (_that) {
case _BirthDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String date,  String time,  String place,  String lagna,  String moonSign,  String nakshatra)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BirthDetails() when $default != null:
return $default(_that.label,_that.date,_that.time,_that.place,_that.lagna,_that.moonSign,_that.nakshatra);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String date,  String time,  String place,  String lagna,  String moonSign,  String nakshatra)  $default,) {final _that = this;
switch (_that) {
case _BirthDetails():
return $default(_that.label,_that.date,_that.time,_that.place,_that.lagna,_that.moonSign,_that.nakshatra);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String date,  String time,  String place,  String lagna,  String moonSign,  String nakshatra)?  $default,) {final _that = this;
switch (_that) {
case _BirthDetails() when $default != null:
return $default(_that.label,_that.date,_that.time,_that.place,_that.lagna,_that.moonSign,_that.nakshatra);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BirthDetails extends BirthDetails {
  const _BirthDetails({this.label = '', this.date = '', this.time = '', this.place = '', this.lagna = '', this.moonSign = '', this.nakshatra = ''}): super._();
  factory _BirthDetails.fromJson(Map<String, dynamic> json) => _$BirthDetailsFromJson(json);

@override@JsonKey() final  String label;
@override@JsonKey() final  String date;
@override@JsonKey() final  String time;
@override@JsonKey() final  String place;
@override@JsonKey() final  String lagna;
@override@JsonKey() final  String moonSign;
@override@JsonKey() final  String nakshatra;

/// Create a copy of BirthDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BirthDetailsCopyWith<_BirthDetails> get copyWith => __$BirthDetailsCopyWithImpl<_BirthDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BirthDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BirthDetails&&(identical(other.label, label) || other.label == label)&&(identical(other.date, date) || other.date == date)&&(identical(other.time, time) || other.time == time)&&(identical(other.place, place) || other.place == place)&&(identical(other.lagna, lagna) || other.lagna == lagna)&&(identical(other.moonSign, moonSign) || other.moonSign == moonSign)&&(identical(other.nakshatra, nakshatra) || other.nakshatra == nakshatra));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,date,time,place,lagna,moonSign,nakshatra);

@override
String toString() {
  return 'BirthDetails(label: $label, date: $date, time: $time, place: $place, lagna: $lagna, moonSign: $moonSign, nakshatra: $nakshatra)';
}


}

/// @nodoc
abstract mixin class _$BirthDetailsCopyWith<$Res> implements $BirthDetailsCopyWith<$Res> {
  factory _$BirthDetailsCopyWith(_BirthDetails value, $Res Function(_BirthDetails) _then) = __$BirthDetailsCopyWithImpl;
@override @useResult
$Res call({
 String label, String date, String time, String place, String lagna, String moonSign, String nakshatra
});




}
/// @nodoc
class __$BirthDetailsCopyWithImpl<$Res>
    implements _$BirthDetailsCopyWith<$Res> {
  __$BirthDetailsCopyWithImpl(this._self, this._then);

  final _BirthDetails _self;
  final $Res Function(_BirthDetails) _then;

/// Create a copy of BirthDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? date = null,Object? time = null,Object? place = null,Object? lagna = null,Object? moonSign = null,Object? nakshatra = null,}) {
  return _then(_BirthDetails(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String,place: null == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String,lagna: null == lagna ? _self.lagna : lagna // ignore: cast_nullable_to_non_nullable
as String,moonSign: null == moonSign ? _self.moonSign : moonSign // ignore: cast_nullable_to_non_nullable
as String,nakshatra: null == nakshatra ? _self.nakshatra : nakshatra // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Review {

@JsonKey(unknownEnumValue: ReviewStatus.unknown) ReviewStatus get status;/// Points per rubric criterion, keyed by criterion id.
 Map<String, num> get scores;/// Points given directly when there is no rubric.
 num? get points;/// The final score, after any late penalty the academy applies.
 num? get score; String get feedback;@NullableUtcDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewCopyWith<Review> get copyWith => _$ReviewCopyWithImpl<Review>(this as Review, _$identity);

  /// Serializes this Review to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Review&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.scores, scores)&&(identical(other.points, points) || other.points == points)&&(identical(other.score, score) || other.score == score)&&(identical(other.feedback, feedback) || other.feedback == feedback)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(scores),points,score,feedback,updatedAt);

@override
String toString() {
  return 'Review(status: $status, scores: $scores, points: $points, score: $score, feedback: $feedback, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ReviewCopyWith<$Res>  {
  factory $ReviewCopyWith(Review value, $Res Function(Review) _then) = _$ReviewCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: ReviewStatus.unknown) ReviewStatus status, Map<String, num> scores, num? points, num? score, String feedback,@NullableUtcDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$ReviewCopyWithImpl<$Res>
    implements $ReviewCopyWith<$Res> {
  _$ReviewCopyWithImpl(this._self, this._then);

  final Review _self;
  final $Res Function(Review) _then;

/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? scores = null,Object? points = freezed,Object? score = freezed,Object? feedback = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReviewStatus,scores: null == scores ? _self.scores : scores // ignore: cast_nullable_to_non_nullable
as Map<String, num>,points: freezed == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as num?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as num?,feedback: null == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Review].
extension ReviewPatterns on Review {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Review value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Review() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Review value)  $default,){
final _that = this;
switch (_that) {
case _Review():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Review value)?  $default,){
final _that = this;
switch (_that) {
case _Review() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: ReviewStatus.unknown)  ReviewStatus status,  Map<String, num> scores,  num? points,  num? score,  String feedback, @NullableUtcDateTimeConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Review() when $default != null:
return $default(_that.status,_that.scores,_that.points,_that.score,_that.feedback,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: ReviewStatus.unknown)  ReviewStatus status,  Map<String, num> scores,  num? points,  num? score,  String feedback, @NullableUtcDateTimeConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Review():
return $default(_that.status,_that.scores,_that.points,_that.score,_that.feedback,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: ReviewStatus.unknown)  ReviewStatus status,  Map<String, num> scores,  num? points,  num? score,  String feedback, @NullableUtcDateTimeConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Review() when $default != null:
return $default(_that.status,_that.scores,_that.points,_that.score,_that.feedback,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Review extends Review {
  const _Review({@JsonKey(unknownEnumValue: ReviewStatus.unknown) this.status = ReviewStatus.waiting, final  Map<String, num> scores = const <String, num>{}, this.points, this.score, this.feedback = '', @NullableUtcDateTimeConverter() this.updatedAt}): _scores = scores,super._();
  factory _Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);

@override@JsonKey(unknownEnumValue: ReviewStatus.unknown) final  ReviewStatus status;
/// Points per rubric criterion, keyed by criterion id.
 final  Map<String, num> _scores;
/// Points per rubric criterion, keyed by criterion id.
@override@JsonKey() Map<String, num> get scores {
  if (_scores is EqualUnmodifiableMapView) return _scores;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_scores);
}

/// Points given directly when there is no rubric.
@override final  num? points;
/// The final score, after any late penalty the academy applies.
@override final  num? score;
@override@JsonKey() final  String feedback;
@override@NullableUtcDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewCopyWith<_Review> get copyWith => __$ReviewCopyWithImpl<_Review>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Review&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._scores, _scores)&&(identical(other.points, points) || other.points == points)&&(identical(other.score, score) || other.score == score)&&(identical(other.feedback, feedback) || other.feedback == feedback)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_scores),points,score,feedback,updatedAt);

@override
String toString() {
  return 'Review(status: $status, scores: $scores, points: $points, score: $score, feedback: $feedback, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ReviewCopyWith<$Res> implements $ReviewCopyWith<$Res> {
  factory _$ReviewCopyWith(_Review value, $Res Function(_Review) _then) = __$ReviewCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: ReviewStatus.unknown) ReviewStatus status, Map<String, num> scores, num? points, num? score, String feedback,@NullableUtcDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$ReviewCopyWithImpl<$Res>
    implements _$ReviewCopyWith<$Res> {
  __$ReviewCopyWithImpl(this._self, this._then);

  final _Review _self;
  final $Res Function(_Review) _then;

/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? scores = null,Object? points = freezed,Object? score = freezed,Object? feedback = null,Object? updatedAt = freezed,}) {
  return _then(_Review(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReviewStatus,scores: null == scores ? _self._scores : scores // ignore: cast_nullable_to_non_nullable
as Map<String, num>,points: freezed == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as num?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as num?,feedback: null == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$Submission {

 String get id; int get attempt;@UtcDateTimeConverter() DateTime get submittedAt; bool get late; String? get text; List<Attachment> get files; BirthDetails? get chart; Review get review;
/// Create a copy of Submission
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubmissionCopyWith<Submission> get copyWith => _$SubmissionCopyWithImpl<Submission>(this as Submission, _$identity);

  /// Serializes this Submission to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Submission&&(identical(other.id, id) || other.id == id)&&(identical(other.attempt, attempt) || other.attempt == attempt)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.late, late) || other.late == late)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.files, files)&&(identical(other.chart, chart) || other.chart == chart)&&(identical(other.review, review) || other.review == review));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,attempt,submittedAt,late,text,const DeepCollectionEquality().hash(files),chart,review);

@override
String toString() {
  return 'Submission(id: $id, attempt: $attempt, submittedAt: $submittedAt, late: $late, text: $text, files: $files, chart: $chart, review: $review)';
}


}

/// @nodoc
abstract mixin class $SubmissionCopyWith<$Res>  {
  factory $SubmissionCopyWith(Submission value, $Res Function(Submission) _then) = _$SubmissionCopyWithImpl;
@useResult
$Res call({
 String id, int attempt,@UtcDateTimeConverter() DateTime submittedAt, bool late, String? text, List<Attachment> files, BirthDetails? chart, Review review
});


$BirthDetailsCopyWith<$Res>? get chart;$ReviewCopyWith<$Res> get review;

}
/// @nodoc
class _$SubmissionCopyWithImpl<$Res>
    implements $SubmissionCopyWith<$Res> {
  _$SubmissionCopyWithImpl(this._self, this._then);

  final Submission _self;
  final $Res Function(Submission) _then;

/// Create a copy of Submission
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? attempt = null,Object? submittedAt = null,Object? late = null,Object? text = freezed,Object? files = null,Object? chart = freezed,Object? review = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,late: null == late ? _self.late : late // ignore: cast_nullable_to_non_nullable
as bool,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<Attachment>,chart: freezed == chart ? _self.chart : chart // ignore: cast_nullable_to_non_nullable
as BirthDetails?,review: null == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as Review,
  ));
}
/// Create a copy of Submission
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BirthDetailsCopyWith<$Res>? get chart {
    if (_self.chart == null) {
    return null;
  }

  return $BirthDetailsCopyWith<$Res>(_self.chart!, (value) {
    return _then(_self.copyWith(chart: value));
  });
}/// Create a copy of Submission
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewCopyWith<$Res> get review {
  
  return $ReviewCopyWith<$Res>(_self.review, (value) {
    return _then(_self.copyWith(review: value));
  });
}
}


/// Adds pattern-matching-related methods to [Submission].
extension SubmissionPatterns on Submission {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Submission value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Submission() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Submission value)  $default,){
final _that = this;
switch (_that) {
case _Submission():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Submission value)?  $default,){
final _that = this;
switch (_that) {
case _Submission() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int attempt, @UtcDateTimeConverter()  DateTime submittedAt,  bool late,  String? text,  List<Attachment> files,  BirthDetails? chart,  Review review)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Submission() when $default != null:
return $default(_that.id,_that.attempt,_that.submittedAt,_that.late,_that.text,_that.files,_that.chart,_that.review);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int attempt, @UtcDateTimeConverter()  DateTime submittedAt,  bool late,  String? text,  List<Attachment> files,  BirthDetails? chart,  Review review)  $default,) {final _that = this;
switch (_that) {
case _Submission():
return $default(_that.id,_that.attempt,_that.submittedAt,_that.late,_that.text,_that.files,_that.chart,_that.review);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int attempt, @UtcDateTimeConverter()  DateTime submittedAt,  bool late,  String? text,  List<Attachment> files,  BirthDetails? chart,  Review review)?  $default,) {final _that = this;
switch (_that) {
case _Submission() when $default != null:
return $default(_that.id,_that.attempt,_that.submittedAt,_that.late,_that.text,_that.files,_that.chart,_that.review);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Submission implements Submission {
  const _Submission({required this.id, this.attempt = 1, @UtcDateTimeConverter() required this.submittedAt, this.late = false, this.text, final  List<Attachment> files = const <Attachment>[], this.chart, this.review = const Review()}): _files = files;
  factory _Submission.fromJson(Map<String, dynamic> json) => _$SubmissionFromJson(json);

@override final  String id;
@override@JsonKey() final  int attempt;
@override@UtcDateTimeConverter() final  DateTime submittedAt;
@override@JsonKey() final  bool late;
@override final  String? text;
 final  List<Attachment> _files;
@override@JsonKey() List<Attachment> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}

@override final  BirthDetails? chart;
@override@JsonKey() final  Review review;

/// Create a copy of Submission
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubmissionCopyWith<_Submission> get copyWith => __$SubmissionCopyWithImpl<_Submission>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubmissionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Submission&&(identical(other.id, id) || other.id == id)&&(identical(other.attempt, attempt) || other.attempt == attempt)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.late, late) || other.late == late)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._files, _files)&&(identical(other.chart, chart) || other.chart == chart)&&(identical(other.review, review) || other.review == review));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,attempt,submittedAt,late,text,const DeepCollectionEquality().hash(_files),chart,review);

@override
String toString() {
  return 'Submission(id: $id, attempt: $attempt, submittedAt: $submittedAt, late: $late, text: $text, files: $files, chart: $chart, review: $review)';
}


}

/// @nodoc
abstract mixin class _$SubmissionCopyWith<$Res> implements $SubmissionCopyWith<$Res> {
  factory _$SubmissionCopyWith(_Submission value, $Res Function(_Submission) _then) = __$SubmissionCopyWithImpl;
@override @useResult
$Res call({
 String id, int attempt,@UtcDateTimeConverter() DateTime submittedAt, bool late, String? text, List<Attachment> files, BirthDetails? chart, Review review
});


@override $BirthDetailsCopyWith<$Res>? get chart;@override $ReviewCopyWith<$Res> get review;

}
/// @nodoc
class __$SubmissionCopyWithImpl<$Res>
    implements _$SubmissionCopyWith<$Res> {
  __$SubmissionCopyWithImpl(this._self, this._then);

  final _Submission _self;
  final $Res Function(_Submission) _then;

/// Create a copy of Submission
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? attempt = null,Object? submittedAt = null,Object? late = null,Object? text = freezed,Object? files = null,Object? chart = freezed,Object? review = null,}) {
  return _then(_Submission(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,late: null == late ? _self.late : late // ignore: cast_nullable_to_non_nullable
as bool,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<Attachment>,chart: freezed == chart ? _self.chart : chart // ignore: cast_nullable_to_non_nullable
as BirthDetails?,review: null == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as Review,
  ));
}

/// Create a copy of Submission
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BirthDetailsCopyWith<$Res>? get chart {
    if (_self.chart == null) {
    return null;
  }

  return $BirthDetailsCopyWith<$Res>(_self.chart!, (value) {
    return _then(_self.copyWith(chart: value));
  });
}/// Create a copy of Submission
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewCopyWith<$Res> get review {
  
  return $ReviewCopyWith<$Res>(_self.review, (value) {
    return _then(_self.copyWith(review: value));
  });
}
}


/// @nodoc
mixin _$CourseAssignment {

 String get id; String get courseId; String? get chapterId; String? get lessonId; String get title;/// The brief, in the same small markup the article renderer supports.
 String get instructions; List<Attachment> get attachments;@JsonKey(unknownEnumValue: SubmissionFormat.unknown) SubmissionFormat get format;/// Written and chart submissions only.
 int? get wordLimit; DuePolicy get due; bool get acceptsLate;/// Percent taken off a late submission's score.
 int get latePenalty; List<RubricCriterion> get rubric; int get maxScore;/// In points.
 int get passMark; String get status;
/// Create a copy of CourseAssignment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseAssignmentCopyWith<CourseAssignment> get copyWith => _$CourseAssignmentCopyWithImpl<CourseAssignment>(this as CourseAssignment, _$identity);

  /// Serializes this CourseAssignment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseAssignment&&(identical(other.id, id) || other.id == id)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.lessonId, lessonId) || other.lessonId == lessonId)&&(identical(other.title, title) || other.title == title)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&const DeepCollectionEquality().equals(other.attachments, attachments)&&(identical(other.format, format) || other.format == format)&&(identical(other.wordLimit, wordLimit) || other.wordLimit == wordLimit)&&(identical(other.due, due) || other.due == due)&&(identical(other.acceptsLate, acceptsLate) || other.acceptsLate == acceptsLate)&&(identical(other.latePenalty, latePenalty) || other.latePenalty == latePenalty)&&const DeepCollectionEquality().equals(other.rubric, rubric)&&(identical(other.maxScore, maxScore) || other.maxScore == maxScore)&&(identical(other.passMark, passMark) || other.passMark == passMark)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,courseId,chapterId,lessonId,title,instructions,const DeepCollectionEquality().hash(attachments),format,wordLimit,due,acceptsLate,latePenalty,const DeepCollectionEquality().hash(rubric),maxScore,passMark,status);

@override
String toString() {
  return 'CourseAssignment(id: $id, courseId: $courseId, chapterId: $chapterId, lessonId: $lessonId, title: $title, instructions: $instructions, attachments: $attachments, format: $format, wordLimit: $wordLimit, due: $due, acceptsLate: $acceptsLate, latePenalty: $latePenalty, rubric: $rubric, maxScore: $maxScore, passMark: $passMark, status: $status)';
}


}

/// @nodoc
abstract mixin class $CourseAssignmentCopyWith<$Res>  {
  factory $CourseAssignmentCopyWith(CourseAssignment value, $Res Function(CourseAssignment) _then) = _$CourseAssignmentCopyWithImpl;
@useResult
$Res call({
 String id, String courseId, String? chapterId, String? lessonId, String title, String instructions, List<Attachment> attachments,@JsonKey(unknownEnumValue: SubmissionFormat.unknown) SubmissionFormat format, int? wordLimit, DuePolicy due, bool acceptsLate, int latePenalty, List<RubricCriterion> rubric, int maxScore, int passMark, String status
});


$DuePolicyCopyWith<$Res> get due;

}
/// @nodoc
class _$CourseAssignmentCopyWithImpl<$Res>
    implements $CourseAssignmentCopyWith<$Res> {
  _$CourseAssignmentCopyWithImpl(this._self, this._then);

  final CourseAssignment _self;
  final $Res Function(CourseAssignment) _then;

/// Create a copy of CourseAssignment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? courseId = null,Object? chapterId = freezed,Object? lessonId = freezed,Object? title = null,Object? instructions = null,Object? attachments = null,Object? format = null,Object? wordLimit = freezed,Object? due = null,Object? acceptsLate = null,Object? latePenalty = null,Object? rubric = null,Object? maxScore = null,Object? passMark = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,chapterId: freezed == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String?,lessonId: freezed == lessonId ? _self.lessonId : lessonId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<Attachment>,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as SubmissionFormat,wordLimit: freezed == wordLimit ? _self.wordLimit : wordLimit // ignore: cast_nullable_to_non_nullable
as int?,due: null == due ? _self.due : due // ignore: cast_nullable_to_non_nullable
as DuePolicy,acceptsLate: null == acceptsLate ? _self.acceptsLate : acceptsLate // ignore: cast_nullable_to_non_nullable
as bool,latePenalty: null == latePenalty ? _self.latePenalty : latePenalty // ignore: cast_nullable_to_non_nullable
as int,rubric: null == rubric ? _self.rubric : rubric // ignore: cast_nullable_to_non_nullable
as List<RubricCriterion>,maxScore: null == maxScore ? _self.maxScore : maxScore // ignore: cast_nullable_to_non_nullable
as int,passMark: null == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of CourseAssignment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuePolicyCopyWith<$Res> get due {
  
  return $DuePolicyCopyWith<$Res>(_self.due, (value) {
    return _then(_self.copyWith(due: value));
  });
}
}


/// Adds pattern-matching-related methods to [CourseAssignment].
extension CourseAssignmentPatterns on CourseAssignment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseAssignment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseAssignment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseAssignment value)  $default,){
final _that = this;
switch (_that) {
case _CourseAssignment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseAssignment value)?  $default,){
final _that = this;
switch (_that) {
case _CourseAssignment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String courseId,  String? chapterId,  String? lessonId,  String title,  String instructions,  List<Attachment> attachments, @JsonKey(unknownEnumValue: SubmissionFormat.unknown)  SubmissionFormat format,  int? wordLimit,  DuePolicy due,  bool acceptsLate,  int latePenalty,  List<RubricCriterion> rubric,  int maxScore,  int passMark,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseAssignment() when $default != null:
return $default(_that.id,_that.courseId,_that.chapterId,_that.lessonId,_that.title,_that.instructions,_that.attachments,_that.format,_that.wordLimit,_that.due,_that.acceptsLate,_that.latePenalty,_that.rubric,_that.maxScore,_that.passMark,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String courseId,  String? chapterId,  String? lessonId,  String title,  String instructions,  List<Attachment> attachments, @JsonKey(unknownEnumValue: SubmissionFormat.unknown)  SubmissionFormat format,  int? wordLimit,  DuePolicy due,  bool acceptsLate,  int latePenalty,  List<RubricCriterion> rubric,  int maxScore,  int passMark,  String status)  $default,) {final _that = this;
switch (_that) {
case _CourseAssignment():
return $default(_that.id,_that.courseId,_that.chapterId,_that.lessonId,_that.title,_that.instructions,_that.attachments,_that.format,_that.wordLimit,_that.due,_that.acceptsLate,_that.latePenalty,_that.rubric,_that.maxScore,_that.passMark,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String courseId,  String? chapterId,  String? lessonId,  String title,  String instructions,  List<Attachment> attachments, @JsonKey(unknownEnumValue: SubmissionFormat.unknown)  SubmissionFormat format,  int? wordLimit,  DuePolicy due,  bool acceptsLate,  int latePenalty,  List<RubricCriterion> rubric,  int maxScore,  int passMark,  String status)?  $default,) {final _that = this;
switch (_that) {
case _CourseAssignment() when $default != null:
return $default(_that.id,_that.courseId,_that.chapterId,_that.lessonId,_that.title,_that.instructions,_that.attachments,_that.format,_that.wordLimit,_that.due,_that.acceptsLate,_that.latePenalty,_that.rubric,_that.maxScore,_that.passMark,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseAssignment extends CourseAssignment {
  const _CourseAssignment({required this.id, required this.courseId, this.chapterId, this.lessonId, this.title = '', this.instructions = '', final  List<Attachment> attachments = const <Attachment>[], @JsonKey(unknownEnumValue: SubmissionFormat.unknown) this.format = SubmissionFormat.unknown, this.wordLimit, this.due = const DuePolicy(), this.acceptsLate = false, this.latePenalty = 0, final  List<RubricCriterion> rubric = const <RubricCriterion>[], this.maxScore = 0, this.passMark = 0, this.status = ''}): _attachments = attachments,_rubric = rubric,super._();
  factory _CourseAssignment.fromJson(Map<String, dynamic> json) => _$CourseAssignmentFromJson(json);

@override final  String id;
@override final  String courseId;
@override final  String? chapterId;
@override final  String? lessonId;
@override@JsonKey() final  String title;
/// The brief, in the same small markup the article renderer supports.
@override@JsonKey() final  String instructions;
 final  List<Attachment> _attachments;
@override@JsonKey() List<Attachment> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}

@override@JsonKey(unknownEnumValue: SubmissionFormat.unknown) final  SubmissionFormat format;
/// Written and chart submissions only.
@override final  int? wordLimit;
@override@JsonKey() final  DuePolicy due;
@override@JsonKey() final  bool acceptsLate;
/// Percent taken off a late submission's score.
@override@JsonKey() final  int latePenalty;
 final  List<RubricCriterion> _rubric;
@override@JsonKey() List<RubricCriterion> get rubric {
  if (_rubric is EqualUnmodifiableListView) return _rubric;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rubric);
}

@override@JsonKey() final  int maxScore;
/// In points.
@override@JsonKey() final  int passMark;
@override@JsonKey() final  String status;

/// Create a copy of CourseAssignment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseAssignmentCopyWith<_CourseAssignment> get copyWith => __$CourseAssignmentCopyWithImpl<_CourseAssignment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseAssignmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseAssignment&&(identical(other.id, id) || other.id == id)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.lessonId, lessonId) || other.lessonId == lessonId)&&(identical(other.title, title) || other.title == title)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&const DeepCollectionEquality().equals(other._attachments, _attachments)&&(identical(other.format, format) || other.format == format)&&(identical(other.wordLimit, wordLimit) || other.wordLimit == wordLimit)&&(identical(other.due, due) || other.due == due)&&(identical(other.acceptsLate, acceptsLate) || other.acceptsLate == acceptsLate)&&(identical(other.latePenalty, latePenalty) || other.latePenalty == latePenalty)&&const DeepCollectionEquality().equals(other._rubric, _rubric)&&(identical(other.maxScore, maxScore) || other.maxScore == maxScore)&&(identical(other.passMark, passMark) || other.passMark == passMark)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,courseId,chapterId,lessonId,title,instructions,const DeepCollectionEquality().hash(_attachments),format,wordLimit,due,acceptsLate,latePenalty,const DeepCollectionEquality().hash(_rubric),maxScore,passMark,status);

@override
String toString() {
  return 'CourseAssignment(id: $id, courseId: $courseId, chapterId: $chapterId, lessonId: $lessonId, title: $title, instructions: $instructions, attachments: $attachments, format: $format, wordLimit: $wordLimit, due: $due, acceptsLate: $acceptsLate, latePenalty: $latePenalty, rubric: $rubric, maxScore: $maxScore, passMark: $passMark, status: $status)';
}


}

/// @nodoc
abstract mixin class _$CourseAssignmentCopyWith<$Res> implements $CourseAssignmentCopyWith<$Res> {
  factory _$CourseAssignmentCopyWith(_CourseAssignment value, $Res Function(_CourseAssignment) _then) = __$CourseAssignmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String courseId, String? chapterId, String? lessonId, String title, String instructions, List<Attachment> attachments,@JsonKey(unknownEnumValue: SubmissionFormat.unknown) SubmissionFormat format, int? wordLimit, DuePolicy due, bool acceptsLate, int latePenalty, List<RubricCriterion> rubric, int maxScore, int passMark, String status
});


@override $DuePolicyCopyWith<$Res> get due;

}
/// @nodoc
class __$CourseAssignmentCopyWithImpl<$Res>
    implements _$CourseAssignmentCopyWith<$Res> {
  __$CourseAssignmentCopyWithImpl(this._self, this._then);

  final _CourseAssignment _self;
  final $Res Function(_CourseAssignment) _then;

/// Create a copy of CourseAssignment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? courseId = null,Object? chapterId = freezed,Object? lessonId = freezed,Object? title = null,Object? instructions = null,Object? attachments = null,Object? format = null,Object? wordLimit = freezed,Object? due = null,Object? acceptsLate = null,Object? latePenalty = null,Object? rubric = null,Object? maxScore = null,Object? passMark = null,Object? status = null,}) {
  return _then(_CourseAssignment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,chapterId: freezed == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String?,lessonId: freezed == lessonId ? _self.lessonId : lessonId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<Attachment>,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as SubmissionFormat,wordLimit: freezed == wordLimit ? _self.wordLimit : wordLimit // ignore: cast_nullable_to_non_nullable
as int?,due: null == due ? _self.due : due // ignore: cast_nullable_to_non_nullable
as DuePolicy,acceptsLate: null == acceptsLate ? _self.acceptsLate : acceptsLate // ignore: cast_nullable_to_non_nullable
as bool,latePenalty: null == latePenalty ? _self.latePenalty : latePenalty // ignore: cast_nullable_to_non_nullable
as int,rubric: null == rubric ? _self._rubric : rubric // ignore: cast_nullable_to_non_nullable
as List<RubricCriterion>,maxScore: null == maxScore ? _self.maxScore : maxScore // ignore: cast_nullable_to_non_nullable
as int,passMark: null == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of CourseAssignment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DuePolicyCopyWith<$Res> get due {
  
  return $DuePolicyCopyWith<$Res>(_self.due, (value) {
    return _then(_self.copyWith(due: value));
  });
}
}

// dart format on
