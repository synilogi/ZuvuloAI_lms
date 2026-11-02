// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'uploaded_media.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UploadedMedia {

 String get id;/// The original file name, as the server stored it.
 String get name;/// Size in megabytes, rounded by the server to one decimal.
 double get sizeMb;/// Always `/media/<id>` — relative to the API, never an absolute URL.
 String get url; String? get mime;@JsonKey(fromJson: MediaKind.parse, toJson: _kindToJson) MediaKind get kind;
/// Create a copy of UploadedMedia
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UploadedMediaCopyWith<UploadedMedia> get copyWith => _$UploadedMediaCopyWithImpl<UploadedMedia>(this as UploadedMedia, _$identity);

  /// Serializes this UploadedMedia to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UploadedMedia&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sizeMb, sizeMb) || other.sizeMb == sizeMb)&&(identical(other.url, url) || other.url == url)&&(identical(other.mime, mime) || other.mime == mime)&&(identical(other.kind, kind) || other.kind == kind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,sizeMb,url,mime,kind);

@override
String toString() {
  return 'UploadedMedia(id: $id, name: $name, sizeMb: $sizeMb, url: $url, mime: $mime, kind: $kind)';
}


}

/// @nodoc
abstract mixin class $UploadedMediaCopyWith<$Res>  {
  factory $UploadedMediaCopyWith(UploadedMedia value, $Res Function(UploadedMedia) _then) = _$UploadedMediaCopyWithImpl;
@useResult
$Res call({
 String id, String name, double sizeMb, String url, String? mime,@JsonKey(fromJson: MediaKind.parse, toJson: _kindToJson) MediaKind kind
});




}
/// @nodoc
class _$UploadedMediaCopyWithImpl<$Res>
    implements $UploadedMediaCopyWith<$Res> {
  _$UploadedMediaCopyWithImpl(this._self, this._then);

  final UploadedMedia _self;
  final $Res Function(UploadedMedia) _then;

/// Create a copy of UploadedMedia
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? sizeMb = null,Object? url = null,Object? mime = freezed,Object? kind = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sizeMb: null == sizeMb ? _self.sizeMb : sizeMb // ignore: cast_nullable_to_non_nullable
as double,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,mime: freezed == mime ? _self.mime : mime // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaKind,
  ));
}

}


/// Adds pattern-matching-related methods to [UploadedMedia].
extension UploadedMediaPatterns on UploadedMedia {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UploadedMedia value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UploadedMedia() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UploadedMedia value)  $default,){
final _that = this;
switch (_that) {
case _UploadedMedia():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UploadedMedia value)?  $default,){
final _that = this;
switch (_that) {
case _UploadedMedia() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  double sizeMb,  String url,  String? mime, @JsonKey(fromJson: MediaKind.parse, toJson: _kindToJson)  MediaKind kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UploadedMedia() when $default != null:
return $default(_that.id,_that.name,_that.sizeMb,_that.url,_that.mime,_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  double sizeMb,  String url,  String? mime, @JsonKey(fromJson: MediaKind.parse, toJson: _kindToJson)  MediaKind kind)  $default,) {final _that = this;
switch (_that) {
case _UploadedMedia():
return $default(_that.id,_that.name,_that.sizeMb,_that.url,_that.mime,_that.kind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  double sizeMb,  String url,  String? mime, @JsonKey(fromJson: MediaKind.parse, toJson: _kindToJson)  MediaKind kind)?  $default,) {final _that = this;
switch (_that) {
case _UploadedMedia() when $default != null:
return $default(_that.id,_that.name,_that.sizeMb,_that.url,_that.mime,_that.kind);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UploadedMedia implements UploadedMedia {
  const _UploadedMedia({required this.id, required this.name, required this.sizeMb, required this.url, this.mime, @JsonKey(fromJson: MediaKind.parse, toJson: _kindToJson) this.kind = MediaKind.unknown});
  factory _UploadedMedia.fromJson(Map<String, dynamic> json) => _$UploadedMediaFromJson(json);

@override final  String id;
/// The original file name, as the server stored it.
@override final  String name;
/// Size in megabytes, rounded by the server to one decimal.
@override final  double sizeMb;
/// Always `/media/<id>` — relative to the API, never an absolute URL.
@override final  String url;
@override final  String? mime;
@override@JsonKey(fromJson: MediaKind.parse, toJson: _kindToJson) final  MediaKind kind;

/// Create a copy of UploadedMedia
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UploadedMediaCopyWith<_UploadedMedia> get copyWith => __$UploadedMediaCopyWithImpl<_UploadedMedia>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UploadedMediaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UploadedMedia&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sizeMb, sizeMb) || other.sizeMb == sizeMb)&&(identical(other.url, url) || other.url == url)&&(identical(other.mime, mime) || other.mime == mime)&&(identical(other.kind, kind) || other.kind == kind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,sizeMb,url,mime,kind);

@override
String toString() {
  return 'UploadedMedia(id: $id, name: $name, sizeMb: $sizeMb, url: $url, mime: $mime, kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$UploadedMediaCopyWith<$Res> implements $UploadedMediaCopyWith<$Res> {
  factory _$UploadedMediaCopyWith(_UploadedMedia value, $Res Function(_UploadedMedia) _then) = __$UploadedMediaCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double sizeMb, String url, String? mime,@JsonKey(fromJson: MediaKind.parse, toJson: _kindToJson) MediaKind kind
});




}
/// @nodoc
class __$UploadedMediaCopyWithImpl<$Res>
    implements _$UploadedMediaCopyWith<$Res> {
  __$UploadedMediaCopyWithImpl(this._self, this._then);

  final _UploadedMedia _self;
  final $Res Function(_UploadedMedia) _then;

/// Create a copy of UploadedMedia
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? sizeMb = null,Object? url = null,Object? mime = freezed,Object? kind = null,}) {
  return _then(_UploadedMedia(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sizeMb: null == sizeMb ? _self.sizeMb : sizeMb // ignore: cast_nullable_to_non_nullable
as double,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,mime: freezed == mime ? _self.mime : mime // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaKind,
  ));
}


}

// dart format on
