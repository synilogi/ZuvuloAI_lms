// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'course.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MediaFile {

 String get name; double get sizeMb; String? get id; String? get url; String? get mime;
/// Create a copy of MediaFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaFileCopyWith<MediaFile> get copyWith => _$MediaFileCopyWithImpl<MediaFile>(this as MediaFile, _$identity);

  /// Serializes this MediaFile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaFile&&(identical(other.name, name) || other.name == name)&&(identical(other.sizeMb, sizeMb) || other.sizeMb == sizeMb)&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.mime, mime) || other.mime == mime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,sizeMb,id,url,mime);

@override
String toString() {
  return 'MediaFile(name: $name, sizeMb: $sizeMb, id: $id, url: $url, mime: $mime)';
}


}

/// @nodoc
abstract mixin class $MediaFileCopyWith<$Res>  {
  factory $MediaFileCopyWith(MediaFile value, $Res Function(MediaFile) _then) = _$MediaFileCopyWithImpl;
@useResult
$Res call({
 String name, double sizeMb, String? id, String? url, String? mime
});




}
/// @nodoc
class _$MediaFileCopyWithImpl<$Res>
    implements $MediaFileCopyWith<$Res> {
  _$MediaFileCopyWithImpl(this._self, this._then);

  final MediaFile _self;
  final $Res Function(MediaFile) _then;

/// Create a copy of MediaFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? sizeMb = null,Object? id = freezed,Object? url = freezed,Object? mime = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sizeMb: null == sizeMb ? _self.sizeMb : sizeMb // ignore: cast_nullable_to_non_nullable
as double,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,mime: freezed == mime ? _self.mime : mime // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaFile].
extension MediaFilePatterns on MediaFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaFile value)  $default,){
final _that = this;
switch (_that) {
case _MediaFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaFile value)?  $default,){
final _that = this;
switch (_that) {
case _MediaFile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  double sizeMb,  String? id,  String? url,  String? mime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaFile() when $default != null:
return $default(_that.name,_that.sizeMb,_that.id,_that.url,_that.mime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  double sizeMb,  String? id,  String? url,  String? mime)  $default,) {final _that = this;
switch (_that) {
case _MediaFile():
return $default(_that.name,_that.sizeMb,_that.id,_that.url,_that.mime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  double sizeMb,  String? id,  String? url,  String? mime)?  $default,) {final _that = this;
switch (_that) {
case _MediaFile() when $default != null:
return $default(_that.name,_that.sizeMb,_that.id,_that.url,_that.mime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaFile implements MediaFile {
  const _MediaFile({required this.name, this.sizeMb = 0, this.id, this.url, this.mime});
  factory _MediaFile.fromJson(Map<String, dynamic> json) => _$MediaFileFromJson(json);

@override final  String name;
@override@JsonKey() final  double sizeMb;
@override final  String? id;
@override final  String? url;
@override final  String? mime;

/// Create a copy of MediaFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaFileCopyWith<_MediaFile> get copyWith => __$MediaFileCopyWithImpl<_MediaFile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaFileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaFile&&(identical(other.name, name) || other.name == name)&&(identical(other.sizeMb, sizeMb) || other.sizeMb == sizeMb)&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.mime, mime) || other.mime == mime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,sizeMb,id,url,mime);

@override
String toString() {
  return 'MediaFile(name: $name, sizeMb: $sizeMb, id: $id, url: $url, mime: $mime)';
}


}

/// @nodoc
abstract mixin class _$MediaFileCopyWith<$Res> implements $MediaFileCopyWith<$Res> {
  factory _$MediaFileCopyWith(_MediaFile value, $Res Function(_MediaFile) _then) = __$MediaFileCopyWithImpl;
@override @useResult
$Res call({
 String name, double sizeMb, String? id, String? url, String? mime
});




}
/// @nodoc
class __$MediaFileCopyWithImpl<$Res>
    implements _$MediaFileCopyWith<$Res> {
  __$MediaFileCopyWithImpl(this._self, this._then);

  final _MediaFile _self;
  final $Res Function(_MediaFile) _then;

/// Create a copy of MediaFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? sizeMb = null,Object? id = freezed,Object? url = freezed,Object? mime = freezed,}) {
  return _then(_MediaFile(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sizeMb: null == sizeMb ? _self.sizeMb : sizeMb // ignore: cast_nullable_to_non_nullable
as double,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,mime: freezed == mime ? _self.mime : mime // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Price {

 int get amount; String get currency;
/// Create a copy of Price
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceCopyWith<Price> get copyWith => _$PriceCopyWithImpl<Price>(this as Price, _$identity);

  /// Serializes this Price to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Price&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,currency);

@override
String toString() {
  return 'Price(amount: $amount, currency: $currency)';
}


}

/// @nodoc
abstract mixin class $PriceCopyWith<$Res>  {
  factory $PriceCopyWith(Price value, $Res Function(Price) _then) = _$PriceCopyWithImpl;
@useResult
$Res call({
 int amount, String currency
});




}
/// @nodoc
class _$PriceCopyWithImpl<$Res>
    implements $PriceCopyWith<$Res> {
  _$PriceCopyWithImpl(this._self, this._then);

  final Price _self;
  final $Res Function(Price) _then;

/// Create a copy of Price
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? currency = null,}) {
  return _then(_self.copyWith(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Price].
extension PricePatterns on Price {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Price value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Price() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Price value)  $default,){
final _that = this;
switch (_that) {
case _Price():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Price value)?  $default,){
final _that = this;
switch (_that) {
case _Price() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int amount,  String currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Price() when $default != null:
return $default(_that.amount,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int amount,  String currency)  $default,) {final _that = this;
switch (_that) {
case _Price():
return $default(_that.amount,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int amount,  String currency)?  $default,) {final _that = this;
switch (_that) {
case _Price() when $default != null:
return $default(_that.amount,_that.currency);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Price implements Price {
  const _Price({required this.amount, required this.currency});
  factory _Price.fromJson(Map<String, dynamic> json) => _$PriceFromJson(json);

@override final  int amount;
@override final  String currency;

/// Create a copy of Price
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceCopyWith<_Price> get copyWith => __$PriceCopyWithImpl<_Price>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PriceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Price&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,currency);

@override
String toString() {
  return 'Price(amount: $amount, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$PriceCopyWith<$Res> implements $PriceCopyWith<$Res> {
  factory _$PriceCopyWith(_Price value, $Res Function(_Price) _then) = __$PriceCopyWithImpl;
@override @useResult
$Res call({
 int amount, String currency
});




}
/// @nodoc
class __$PriceCopyWithImpl<$Res>
    implements _$PriceCopyWith<$Res> {
  __$PriceCopyWithImpl(this._self, this._then);

  final _Price _self;
  final $Res Function(_Price) _then;

/// Create a copy of Price
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? currency = null,}) {
  return _then(_Price(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$LessonVideoMarker {

 int get atSec; String get title;
/// Create a copy of LessonVideoMarker
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonVideoMarkerCopyWith<LessonVideoMarker> get copyWith => _$LessonVideoMarkerCopyWithImpl<LessonVideoMarker>(this as LessonVideoMarker, _$identity);

  /// Serializes this LessonVideoMarker to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonVideoMarker&&(identical(other.atSec, atSec) || other.atSec == atSec)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,atSec,title);

@override
String toString() {
  return 'LessonVideoMarker(atSec: $atSec, title: $title)';
}


}

/// @nodoc
abstract mixin class $LessonVideoMarkerCopyWith<$Res>  {
  factory $LessonVideoMarkerCopyWith(LessonVideoMarker value, $Res Function(LessonVideoMarker) _then) = _$LessonVideoMarkerCopyWithImpl;
@useResult
$Res call({
 int atSec, String title
});




}
/// @nodoc
class _$LessonVideoMarkerCopyWithImpl<$Res>
    implements $LessonVideoMarkerCopyWith<$Res> {
  _$LessonVideoMarkerCopyWithImpl(this._self, this._then);

  final LessonVideoMarker _self;
  final $Res Function(LessonVideoMarker) _then;

/// Create a copy of LessonVideoMarker
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? atSec = null,Object? title = null,}) {
  return _then(_self.copyWith(
atSec: null == atSec ? _self.atSec : atSec // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonVideoMarker].
extension LessonVideoMarkerPatterns on LessonVideoMarker {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonVideoMarker value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonVideoMarker() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonVideoMarker value)  $default,){
final _that = this;
switch (_that) {
case _LessonVideoMarker():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonVideoMarker value)?  $default,){
final _that = this;
switch (_that) {
case _LessonVideoMarker() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int atSec,  String title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonVideoMarker() when $default != null:
return $default(_that.atSec,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int atSec,  String title)  $default,) {final _that = this;
switch (_that) {
case _LessonVideoMarker():
return $default(_that.atSec,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int atSec,  String title)?  $default,) {final _that = this;
switch (_that) {
case _LessonVideoMarker() when $default != null:
return $default(_that.atSec,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonVideoMarker implements LessonVideoMarker {
  const _LessonVideoMarker({required this.atSec, required this.title});
  factory _LessonVideoMarker.fromJson(Map<String, dynamic> json) => _$LessonVideoMarkerFromJson(json);

@override final  int atSec;
@override final  String title;

/// Create a copy of LessonVideoMarker
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonVideoMarkerCopyWith<_LessonVideoMarker> get copyWith => __$LessonVideoMarkerCopyWithImpl<_LessonVideoMarker>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonVideoMarkerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonVideoMarker&&(identical(other.atSec, atSec) || other.atSec == atSec)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,atSec,title);

@override
String toString() {
  return 'LessonVideoMarker(atSec: $atSec, title: $title)';
}


}

/// @nodoc
abstract mixin class _$LessonVideoMarkerCopyWith<$Res> implements $LessonVideoMarkerCopyWith<$Res> {
  factory _$LessonVideoMarkerCopyWith(_LessonVideoMarker value, $Res Function(_LessonVideoMarker) _then) = __$LessonVideoMarkerCopyWithImpl;
@override @useResult
$Res call({
 int atSec, String title
});




}
/// @nodoc
class __$LessonVideoMarkerCopyWithImpl<$Res>
    implements _$LessonVideoMarkerCopyWith<$Res> {
  __$LessonVideoMarkerCopyWithImpl(this._self, this._then);

  final _LessonVideoMarker _self;
  final $Res Function(_LessonVideoMarker) _then;

/// Create a copy of LessonVideoMarker
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? atSec = null,Object? title = null,}) {
  return _then(_LessonVideoMarker(
atSec: null == atSec ? _self.atSec : atSec // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$VideoContent {

 MediaFile? get file; int? get durationSec; bool get captions; List<LessonVideoMarker> get markers;
/// Create a copy of VideoContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoContentCopyWith<VideoContent> get copyWith => _$VideoContentCopyWithImpl<VideoContent>(this as VideoContent, _$identity);

  /// Serializes this VideoContent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoContent&&(identical(other.file, file) || other.file == file)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.captions, captions) || other.captions == captions)&&const DeepCollectionEquality().equals(other.markers, markers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,file,durationSec,captions,const DeepCollectionEquality().hash(markers));

@override
String toString() {
  return 'VideoContent(file: $file, durationSec: $durationSec, captions: $captions, markers: $markers)';
}


}

/// @nodoc
abstract mixin class $VideoContentCopyWith<$Res>  {
  factory $VideoContentCopyWith(VideoContent value, $Res Function(VideoContent) _then) = _$VideoContentCopyWithImpl;
@useResult
$Res call({
 MediaFile? file, int? durationSec, bool captions, List<LessonVideoMarker> markers
});


$MediaFileCopyWith<$Res>? get file;

}
/// @nodoc
class _$VideoContentCopyWithImpl<$Res>
    implements $VideoContentCopyWith<$Res> {
  _$VideoContentCopyWithImpl(this._self, this._then);

  final VideoContent _self;
  final $Res Function(VideoContent) _then;

/// Create a copy of VideoContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? file = freezed,Object? durationSec = freezed,Object? captions = null,Object? markers = null,}) {
  return _then(_self.copyWith(
file: freezed == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as MediaFile?,durationSec: freezed == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int?,captions: null == captions ? _self.captions : captions // ignore: cast_nullable_to_non_nullable
as bool,markers: null == markers ? _self.markers : markers // ignore: cast_nullable_to_non_nullable
as List<LessonVideoMarker>,
  ));
}
/// Create a copy of VideoContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaFileCopyWith<$Res>? get file {
    if (_self.file == null) {
    return null;
  }

  return $MediaFileCopyWith<$Res>(_self.file!, (value) {
    return _then(_self.copyWith(file: value));
  });
}
}


/// Adds pattern-matching-related methods to [VideoContent].
extension VideoContentPatterns on VideoContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoContent value)  $default,){
final _that = this;
switch (_that) {
case _VideoContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoContent value)?  $default,){
final _that = this;
switch (_that) {
case _VideoContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MediaFile? file,  int? durationSec,  bool captions,  List<LessonVideoMarker> markers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoContent() when $default != null:
return $default(_that.file,_that.durationSec,_that.captions,_that.markers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MediaFile? file,  int? durationSec,  bool captions,  List<LessonVideoMarker> markers)  $default,) {final _that = this;
switch (_that) {
case _VideoContent():
return $default(_that.file,_that.durationSec,_that.captions,_that.markers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MediaFile? file,  int? durationSec,  bool captions,  List<LessonVideoMarker> markers)?  $default,) {final _that = this;
switch (_that) {
case _VideoContent() when $default != null:
return $default(_that.file,_that.durationSec,_that.captions,_that.markers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VideoContent implements VideoContent {
  const _VideoContent({this.file, this.durationSec, this.captions = false, final  List<LessonVideoMarker> markers = const <LessonVideoMarker>[]}): _markers = markers;
  factory _VideoContent.fromJson(Map<String, dynamic> json) => _$VideoContentFromJson(json);

@override final  MediaFile? file;
@override final  int? durationSec;
@override@JsonKey() final  bool captions;
 final  List<LessonVideoMarker> _markers;
@override@JsonKey() List<LessonVideoMarker> get markers {
  if (_markers is EqualUnmodifiableListView) return _markers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_markers);
}


/// Create a copy of VideoContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoContentCopyWith<_VideoContent> get copyWith => __$VideoContentCopyWithImpl<_VideoContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoContent&&(identical(other.file, file) || other.file == file)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec)&&(identical(other.captions, captions) || other.captions == captions)&&const DeepCollectionEquality().equals(other._markers, _markers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,file,durationSec,captions,const DeepCollectionEquality().hash(_markers));

@override
String toString() {
  return 'VideoContent(file: $file, durationSec: $durationSec, captions: $captions, markers: $markers)';
}


}

/// @nodoc
abstract mixin class _$VideoContentCopyWith<$Res> implements $VideoContentCopyWith<$Res> {
  factory _$VideoContentCopyWith(_VideoContent value, $Res Function(_VideoContent) _then) = __$VideoContentCopyWithImpl;
@override @useResult
$Res call({
 MediaFile? file, int? durationSec, bool captions, List<LessonVideoMarker> markers
});


@override $MediaFileCopyWith<$Res>? get file;

}
/// @nodoc
class __$VideoContentCopyWithImpl<$Res>
    implements _$VideoContentCopyWith<$Res> {
  __$VideoContentCopyWithImpl(this._self, this._then);

  final _VideoContent _self;
  final $Res Function(_VideoContent) _then;

/// Create a copy of VideoContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? file = freezed,Object? durationSec = freezed,Object? captions = null,Object? markers = null,}) {
  return _then(_VideoContent(
file: freezed == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as MediaFile?,durationSec: freezed == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as int?,captions: null == captions ? _self.captions : captions // ignore: cast_nullable_to_non_nullable
as bool,markers: null == markers ? _self._markers : markers // ignore: cast_nullable_to_non_nullable
as List<LessonVideoMarker>,
  ));
}

/// Create a copy of VideoContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaFileCopyWith<$Res>? get file {
    if (_self.file == null) {
    return null;
  }

  return $MediaFileCopyWith<$Res>(_self.file!, (value) {
    return _then(_self.copyWith(file: value));
  });
}
}


/// @nodoc
mixin _$ArticleContent {

 String get body;
/// Create a copy of ArticleContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleContentCopyWith<ArticleContent> get copyWith => _$ArticleContentCopyWithImpl<ArticleContent>(this as ArticleContent, _$identity);

  /// Serializes this ArticleContent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleContent&&(identical(other.body, body) || other.body == body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,body);

@override
String toString() {
  return 'ArticleContent(body: $body)';
}


}

/// @nodoc
abstract mixin class $ArticleContentCopyWith<$Res>  {
  factory $ArticleContentCopyWith(ArticleContent value, $Res Function(ArticleContent) _then) = _$ArticleContentCopyWithImpl;
@useResult
$Res call({
 String body
});




}
/// @nodoc
class _$ArticleContentCopyWithImpl<$Res>
    implements $ArticleContentCopyWith<$Res> {
  _$ArticleContentCopyWithImpl(this._self, this._then);

  final ArticleContent _self;
  final $Res Function(ArticleContent) _then;

/// Create a copy of ArticleContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? body = null,}) {
  return _then(_self.copyWith(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ArticleContent].
extension ArticleContentPatterns on ArticleContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleContent value)  $default,){
final _that = this;
switch (_that) {
case _ArticleContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleContent value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String body)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleContent() when $default != null:
return $default(_that.body);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String body)  $default,) {final _that = this;
switch (_that) {
case _ArticleContent():
return $default(_that.body);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String body)?  $default,) {final _that = this;
switch (_that) {
case _ArticleContent() when $default != null:
return $default(_that.body);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleContent implements ArticleContent {
  const _ArticleContent({this.body = ''});
  factory _ArticleContent.fromJson(Map<String, dynamic> json) => _$ArticleContentFromJson(json);

@override@JsonKey() final  String body;

/// Create a copy of ArticleContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleContentCopyWith<_ArticleContent> get copyWith => __$ArticleContentCopyWithImpl<_ArticleContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleContent&&(identical(other.body, body) || other.body == body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,body);

@override
String toString() {
  return 'ArticleContent(body: $body)';
}


}

/// @nodoc
abstract mixin class _$ArticleContentCopyWith<$Res> implements $ArticleContentCopyWith<$Res> {
  factory _$ArticleContentCopyWith(_ArticleContent value, $Res Function(_ArticleContent) _then) = __$ArticleContentCopyWithImpl;
@override @useResult
$Res call({
 String body
});




}
/// @nodoc
class __$ArticleContentCopyWithImpl<$Res>
    implements _$ArticleContentCopyWith<$Res> {
  __$ArticleContentCopyWithImpl(this._self, this._then);

  final _ArticleContent _self;
  final $Res Function(_ArticleContent) _then;

/// Create a copy of ArticleContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? body = null,}) {
  return _then(_ArticleContent(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DocumentContent {

 MediaFile? get file; int? get pages; bool get downloadable;
/// Create a copy of DocumentContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentContentCopyWith<DocumentContent> get copyWith => _$DocumentContentCopyWithImpl<DocumentContent>(this as DocumentContent, _$identity);

  /// Serializes this DocumentContent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentContent&&(identical(other.file, file) || other.file == file)&&(identical(other.pages, pages) || other.pages == pages)&&(identical(other.downloadable, downloadable) || other.downloadable == downloadable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,file,pages,downloadable);

@override
String toString() {
  return 'DocumentContent(file: $file, pages: $pages, downloadable: $downloadable)';
}


}

/// @nodoc
abstract mixin class $DocumentContentCopyWith<$Res>  {
  factory $DocumentContentCopyWith(DocumentContent value, $Res Function(DocumentContent) _then) = _$DocumentContentCopyWithImpl;
@useResult
$Res call({
 MediaFile? file, int? pages, bool downloadable
});


$MediaFileCopyWith<$Res>? get file;

}
/// @nodoc
class _$DocumentContentCopyWithImpl<$Res>
    implements $DocumentContentCopyWith<$Res> {
  _$DocumentContentCopyWithImpl(this._self, this._then);

  final DocumentContent _self;
  final $Res Function(DocumentContent) _then;

/// Create a copy of DocumentContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? file = freezed,Object? pages = freezed,Object? downloadable = null,}) {
  return _then(_self.copyWith(
file: freezed == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as MediaFile?,pages: freezed == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int?,downloadable: null == downloadable ? _self.downloadable : downloadable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of DocumentContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaFileCopyWith<$Res>? get file {
    if (_self.file == null) {
    return null;
  }

  return $MediaFileCopyWith<$Res>(_self.file!, (value) {
    return _then(_self.copyWith(file: value));
  });
}
}


/// Adds pattern-matching-related methods to [DocumentContent].
extension DocumentContentPatterns on DocumentContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentContent value)  $default,){
final _that = this;
switch (_that) {
case _DocumentContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentContent value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MediaFile? file,  int? pages,  bool downloadable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentContent() when $default != null:
return $default(_that.file,_that.pages,_that.downloadable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MediaFile? file,  int? pages,  bool downloadable)  $default,) {final _that = this;
switch (_that) {
case _DocumentContent():
return $default(_that.file,_that.pages,_that.downloadable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MediaFile? file,  int? pages,  bool downloadable)?  $default,) {final _that = this;
switch (_that) {
case _DocumentContent() when $default != null:
return $default(_that.file,_that.pages,_that.downloadable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentContent implements DocumentContent {
  const _DocumentContent({this.file, this.pages, this.downloadable = false});
  factory _DocumentContent.fromJson(Map<String, dynamic> json) => _$DocumentContentFromJson(json);

@override final  MediaFile? file;
@override final  int? pages;
@override@JsonKey() final  bool downloadable;

/// Create a copy of DocumentContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentContentCopyWith<_DocumentContent> get copyWith => __$DocumentContentCopyWithImpl<_DocumentContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentContent&&(identical(other.file, file) || other.file == file)&&(identical(other.pages, pages) || other.pages == pages)&&(identical(other.downloadable, downloadable) || other.downloadable == downloadable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,file,pages,downloadable);

@override
String toString() {
  return 'DocumentContent(file: $file, pages: $pages, downloadable: $downloadable)';
}


}

/// @nodoc
abstract mixin class _$DocumentContentCopyWith<$Res> implements $DocumentContentCopyWith<$Res> {
  factory _$DocumentContentCopyWith(_DocumentContent value, $Res Function(_DocumentContent) _then) = __$DocumentContentCopyWithImpl;
@override @useResult
$Res call({
 MediaFile? file, int? pages, bool downloadable
});


@override $MediaFileCopyWith<$Res>? get file;

}
/// @nodoc
class __$DocumentContentCopyWithImpl<$Res>
    implements _$DocumentContentCopyWith<$Res> {
  __$DocumentContentCopyWithImpl(this._self, this._then);

  final _DocumentContent _self;
  final $Res Function(_DocumentContent) _then;

/// Create a copy of DocumentContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? file = freezed,Object? pages = freezed,Object? downloadable = null,}) {
  return _then(_DocumentContent(
file: freezed == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as MediaFile?,pages: freezed == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int?,downloadable: null == downloadable ? _self.downloadable : downloadable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of DocumentContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaFileCopyWith<$Res>? get file {
    if (_self.file == null) {
    return null;
  }

  return $MediaFileCopyWith<$Res>(_self.file!, (value) {
    return _then(_self.copyWith(file: value));
  });
}
}


/// @nodoc
mixin _$QuizContent {

 String? get quizId; int get questions; int get passMark; int get attempts; int? get timeLimitMin;
/// Create a copy of QuizContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizContentCopyWith<QuizContent> get copyWith => _$QuizContentCopyWithImpl<QuizContent>(this as QuizContent, _$identity);

  /// Serializes this QuizContent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizContent&&(identical(other.quizId, quizId) || other.quizId == quizId)&&(identical(other.questions, questions) || other.questions == questions)&&(identical(other.passMark, passMark) || other.passMark == passMark)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.timeLimitMin, timeLimitMin) || other.timeLimitMin == timeLimitMin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quizId,questions,passMark,attempts,timeLimitMin);

@override
String toString() {
  return 'QuizContent(quizId: $quizId, questions: $questions, passMark: $passMark, attempts: $attempts, timeLimitMin: $timeLimitMin)';
}


}

/// @nodoc
abstract mixin class $QuizContentCopyWith<$Res>  {
  factory $QuizContentCopyWith(QuizContent value, $Res Function(QuizContent) _then) = _$QuizContentCopyWithImpl;
@useResult
$Res call({
 String? quizId, int questions, int passMark, int attempts, int? timeLimitMin
});




}
/// @nodoc
class _$QuizContentCopyWithImpl<$Res>
    implements $QuizContentCopyWith<$Res> {
  _$QuizContentCopyWithImpl(this._self, this._then);

  final QuizContent _self;
  final $Res Function(QuizContent) _then;

/// Create a copy of QuizContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quizId = freezed,Object? questions = null,Object? passMark = null,Object? attempts = null,Object? timeLimitMin = freezed,}) {
  return _then(_self.copyWith(
quizId: freezed == quizId ? _self.quizId : quizId // ignore: cast_nullable_to_non_nullable
as String?,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as int,passMark: null == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as int,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,timeLimitMin: freezed == timeLimitMin ? _self.timeLimitMin : timeLimitMin // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuizContent].
extension QuizContentPatterns on QuizContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizContent value)  $default,){
final _that = this;
switch (_that) {
case _QuizContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizContent value)?  $default,){
final _that = this;
switch (_that) {
case _QuizContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? quizId,  int questions,  int passMark,  int attempts,  int? timeLimitMin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizContent() when $default != null:
return $default(_that.quizId,_that.questions,_that.passMark,_that.attempts,_that.timeLimitMin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? quizId,  int questions,  int passMark,  int attempts,  int? timeLimitMin)  $default,) {final _that = this;
switch (_that) {
case _QuizContent():
return $default(_that.quizId,_that.questions,_that.passMark,_that.attempts,_that.timeLimitMin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? quizId,  int questions,  int passMark,  int attempts,  int? timeLimitMin)?  $default,) {final _that = this;
switch (_that) {
case _QuizContent() when $default != null:
return $default(_that.quizId,_that.questions,_that.passMark,_that.attempts,_that.timeLimitMin);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizContent implements QuizContent {
  const _QuizContent({this.quizId, this.questions = 0, this.passMark = 0, this.attempts = 0, this.timeLimitMin});
  factory _QuizContent.fromJson(Map<String, dynamic> json) => _$QuizContentFromJson(json);

@override final  String? quizId;
@override@JsonKey() final  int questions;
@override@JsonKey() final  int passMark;
@override@JsonKey() final  int attempts;
@override final  int? timeLimitMin;

/// Create a copy of QuizContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizContentCopyWith<_QuizContent> get copyWith => __$QuizContentCopyWithImpl<_QuizContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizContent&&(identical(other.quizId, quizId) || other.quizId == quizId)&&(identical(other.questions, questions) || other.questions == questions)&&(identical(other.passMark, passMark) || other.passMark == passMark)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.timeLimitMin, timeLimitMin) || other.timeLimitMin == timeLimitMin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quizId,questions,passMark,attempts,timeLimitMin);

@override
String toString() {
  return 'QuizContent(quizId: $quizId, questions: $questions, passMark: $passMark, attempts: $attempts, timeLimitMin: $timeLimitMin)';
}


}

/// @nodoc
abstract mixin class _$QuizContentCopyWith<$Res> implements $QuizContentCopyWith<$Res> {
  factory _$QuizContentCopyWith(_QuizContent value, $Res Function(_QuizContent) _then) = __$QuizContentCopyWithImpl;
@override @useResult
$Res call({
 String? quizId, int questions, int passMark, int attempts, int? timeLimitMin
});




}
/// @nodoc
class __$QuizContentCopyWithImpl<$Res>
    implements _$QuizContentCopyWith<$Res> {
  __$QuizContentCopyWithImpl(this._self, this._then);

  final _QuizContent _self;
  final $Res Function(_QuizContent) _then;

/// Create a copy of QuizContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quizId = freezed,Object? questions = null,Object? passMark = null,Object? attempts = null,Object? timeLimitMin = freezed,}) {
  return _then(_QuizContent(
quizId: freezed == quizId ? _self.quizId : quizId // ignore: cast_nullable_to_non_nullable
as String?,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as int,passMark: null == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as int,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,timeLimitMin: freezed == timeLimitMin ? _self.timeLimitMin : timeLimitMin // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$AssignmentContent {

 String? get assignmentId; String get brief; int get dueAfterDays; int get maxScore; String get submission;
/// Create a copy of AssignmentContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssignmentContentCopyWith<AssignmentContent> get copyWith => _$AssignmentContentCopyWithImpl<AssignmentContent>(this as AssignmentContent, _$identity);

  /// Serializes this AssignmentContent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssignmentContent&&(identical(other.assignmentId, assignmentId) || other.assignmentId == assignmentId)&&(identical(other.brief, brief) || other.brief == brief)&&(identical(other.dueAfterDays, dueAfterDays) || other.dueAfterDays == dueAfterDays)&&(identical(other.maxScore, maxScore) || other.maxScore == maxScore)&&(identical(other.submission, submission) || other.submission == submission));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assignmentId,brief,dueAfterDays,maxScore,submission);

@override
String toString() {
  return 'AssignmentContent(assignmentId: $assignmentId, brief: $brief, dueAfterDays: $dueAfterDays, maxScore: $maxScore, submission: $submission)';
}


}

/// @nodoc
abstract mixin class $AssignmentContentCopyWith<$Res>  {
  factory $AssignmentContentCopyWith(AssignmentContent value, $Res Function(AssignmentContent) _then) = _$AssignmentContentCopyWithImpl;
@useResult
$Res call({
 String? assignmentId, String brief, int dueAfterDays, int maxScore, String submission
});




}
/// @nodoc
class _$AssignmentContentCopyWithImpl<$Res>
    implements $AssignmentContentCopyWith<$Res> {
  _$AssignmentContentCopyWithImpl(this._self, this._then);

  final AssignmentContent _self;
  final $Res Function(AssignmentContent) _then;

/// Create a copy of AssignmentContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? assignmentId = freezed,Object? brief = null,Object? dueAfterDays = null,Object? maxScore = null,Object? submission = null,}) {
  return _then(_self.copyWith(
assignmentId: freezed == assignmentId ? _self.assignmentId : assignmentId // ignore: cast_nullable_to_non_nullable
as String?,brief: null == brief ? _self.brief : brief // ignore: cast_nullable_to_non_nullable
as String,dueAfterDays: null == dueAfterDays ? _self.dueAfterDays : dueAfterDays // ignore: cast_nullable_to_non_nullable
as int,maxScore: null == maxScore ? _self.maxScore : maxScore // ignore: cast_nullable_to_non_nullable
as int,submission: null == submission ? _self.submission : submission // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AssignmentContent].
extension AssignmentContentPatterns on AssignmentContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssignmentContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssignmentContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssignmentContent value)  $default,){
final _that = this;
switch (_that) {
case _AssignmentContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssignmentContent value)?  $default,){
final _that = this;
switch (_that) {
case _AssignmentContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? assignmentId,  String brief,  int dueAfterDays,  int maxScore,  String submission)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssignmentContent() when $default != null:
return $default(_that.assignmentId,_that.brief,_that.dueAfterDays,_that.maxScore,_that.submission);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? assignmentId,  String brief,  int dueAfterDays,  int maxScore,  String submission)  $default,) {final _that = this;
switch (_that) {
case _AssignmentContent():
return $default(_that.assignmentId,_that.brief,_that.dueAfterDays,_that.maxScore,_that.submission);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? assignmentId,  String brief,  int dueAfterDays,  int maxScore,  String submission)?  $default,) {final _that = this;
switch (_that) {
case _AssignmentContent() when $default != null:
return $default(_that.assignmentId,_that.brief,_that.dueAfterDays,_that.maxScore,_that.submission);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssignmentContent implements AssignmentContent {
  const _AssignmentContent({this.assignmentId, this.brief = '', this.dueAfterDays = 0, this.maxScore = 0, this.submission = ''});
  factory _AssignmentContent.fromJson(Map<String, dynamic> json) => _$AssignmentContentFromJson(json);

@override final  String? assignmentId;
@override@JsonKey() final  String brief;
@override@JsonKey() final  int dueAfterDays;
@override@JsonKey() final  int maxScore;
@override@JsonKey() final  String submission;

/// Create a copy of AssignmentContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssignmentContentCopyWith<_AssignmentContent> get copyWith => __$AssignmentContentCopyWithImpl<_AssignmentContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssignmentContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssignmentContent&&(identical(other.assignmentId, assignmentId) || other.assignmentId == assignmentId)&&(identical(other.brief, brief) || other.brief == brief)&&(identical(other.dueAfterDays, dueAfterDays) || other.dueAfterDays == dueAfterDays)&&(identical(other.maxScore, maxScore) || other.maxScore == maxScore)&&(identical(other.submission, submission) || other.submission == submission));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assignmentId,brief,dueAfterDays,maxScore,submission);

@override
String toString() {
  return 'AssignmentContent(assignmentId: $assignmentId, brief: $brief, dueAfterDays: $dueAfterDays, maxScore: $maxScore, submission: $submission)';
}


}

/// @nodoc
abstract mixin class _$AssignmentContentCopyWith<$Res> implements $AssignmentContentCopyWith<$Res> {
  factory _$AssignmentContentCopyWith(_AssignmentContent value, $Res Function(_AssignmentContent) _then) = __$AssignmentContentCopyWithImpl;
@override @useResult
$Res call({
 String? assignmentId, String brief, int dueAfterDays, int maxScore, String submission
});




}
/// @nodoc
class __$AssignmentContentCopyWithImpl<$Res>
    implements _$AssignmentContentCopyWith<$Res> {
  __$AssignmentContentCopyWithImpl(this._self, this._then);

  final _AssignmentContent _self;
  final $Res Function(_AssignmentContent) _then;

/// Create a copy of AssignmentContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? assignmentId = freezed,Object? brief = null,Object? dueAfterDays = null,Object? maxScore = null,Object? submission = null,}) {
  return _then(_AssignmentContent(
assignmentId: freezed == assignmentId ? _self.assignmentId : assignmentId // ignore: cast_nullable_to_non_nullable
as String?,brief: null == brief ? _self.brief : brief // ignore: cast_nullable_to_non_nullable
as String,dueAfterDays: null == dueAfterDays ? _self.dueAfterDays : dueAfterDays // ignore: cast_nullable_to_non_nullable
as int,maxScore: null == maxScore ? _self.maxScore : maxScore // ignore: cast_nullable_to_non_nullable
as int,submission: null == submission ? _self.submission : submission // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$LiveContent {

@NullableUtcDateTimeConverter() DateTime? get startsAt; int get durationMin; bool get recorded; String? get liveClassId;
/// Create a copy of LiveContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveContentCopyWith<LiveContent> get copyWith => _$LiveContentCopyWithImpl<LiveContent>(this as LiveContent, _$identity);

  /// Serializes this LiveContent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveContent&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.recorded, recorded) || other.recorded == recorded)&&(identical(other.liveClassId, liveClassId) || other.liveClassId == liveClassId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startsAt,durationMin,recorded,liveClassId);

@override
String toString() {
  return 'LiveContent(startsAt: $startsAt, durationMin: $durationMin, recorded: $recorded, liveClassId: $liveClassId)';
}


}

/// @nodoc
abstract mixin class $LiveContentCopyWith<$Res>  {
  factory $LiveContentCopyWith(LiveContent value, $Res Function(LiveContent) _then) = _$LiveContentCopyWithImpl;
@useResult
$Res call({
@NullableUtcDateTimeConverter() DateTime? startsAt, int durationMin, bool recorded, String? liveClassId
});




}
/// @nodoc
class _$LiveContentCopyWithImpl<$Res>
    implements $LiveContentCopyWith<$Res> {
  _$LiveContentCopyWithImpl(this._self, this._then);

  final LiveContent _self;
  final $Res Function(LiveContent) _then;

/// Create a copy of LiveContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startsAt = freezed,Object? durationMin = null,Object? recorded = null,Object? liveClassId = freezed,}) {
  return _then(_self.copyWith(
startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,durationMin: null == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int,recorded: null == recorded ? _self.recorded : recorded // ignore: cast_nullable_to_non_nullable
as bool,liveClassId: freezed == liveClassId ? _self.liveClassId : liveClassId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveContent].
extension LiveContentPatterns on LiveContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveContent value)  $default,){
final _that = this;
switch (_that) {
case _LiveContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveContent value)?  $default,){
final _that = this;
switch (_that) {
case _LiveContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@NullableUtcDateTimeConverter()  DateTime? startsAt,  int durationMin,  bool recorded,  String? liveClassId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveContent() when $default != null:
return $default(_that.startsAt,_that.durationMin,_that.recorded,_that.liveClassId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@NullableUtcDateTimeConverter()  DateTime? startsAt,  int durationMin,  bool recorded,  String? liveClassId)  $default,) {final _that = this;
switch (_that) {
case _LiveContent():
return $default(_that.startsAt,_that.durationMin,_that.recorded,_that.liveClassId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@NullableUtcDateTimeConverter()  DateTime? startsAt,  int durationMin,  bool recorded,  String? liveClassId)?  $default,) {final _that = this;
switch (_that) {
case _LiveContent() when $default != null:
return $default(_that.startsAt,_that.durationMin,_that.recorded,_that.liveClassId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveContent implements LiveContent {
  const _LiveContent({@NullableUtcDateTimeConverter() this.startsAt, this.durationMin = 0, this.recorded = false, this.liveClassId});
  factory _LiveContent.fromJson(Map<String, dynamic> json) => _$LiveContentFromJson(json);

@override@NullableUtcDateTimeConverter() final  DateTime? startsAt;
@override@JsonKey() final  int durationMin;
@override@JsonKey() final  bool recorded;
@override final  String? liveClassId;

/// Create a copy of LiveContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveContentCopyWith<_LiveContent> get copyWith => __$LiveContentCopyWithImpl<_LiveContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveContent&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.recorded, recorded) || other.recorded == recorded)&&(identical(other.liveClassId, liveClassId) || other.liveClassId == liveClassId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startsAt,durationMin,recorded,liveClassId);

@override
String toString() {
  return 'LiveContent(startsAt: $startsAt, durationMin: $durationMin, recorded: $recorded, liveClassId: $liveClassId)';
}


}

/// @nodoc
abstract mixin class _$LiveContentCopyWith<$Res> implements $LiveContentCopyWith<$Res> {
  factory _$LiveContentCopyWith(_LiveContent value, $Res Function(_LiveContent) _then) = __$LiveContentCopyWithImpl;
@override @useResult
$Res call({
@NullableUtcDateTimeConverter() DateTime? startsAt, int durationMin, bool recorded, String? liveClassId
});




}
/// @nodoc
class __$LiveContentCopyWithImpl<$Res>
    implements _$LiveContentCopyWith<$Res> {
  __$LiveContentCopyWithImpl(this._self, this._then);

  final _LiveContent _self;
  final $Res Function(_LiveContent) _then;

/// Create a copy of LiveContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startsAt = freezed,Object? durationMin = null,Object? recorded = null,Object? liveClassId = freezed,}) {
  return _then(_LiveContent(
startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,durationMin: null == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int,recorded: null == recorded ? _self.recorded : recorded // ignore: cast_nullable_to_non_nullable
as bool,liveClassId: freezed == liveClassId ? _self.liveClassId : liveClassId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$LessonContent {

 VideoContent? get video; ArticleContent? get article; DocumentContent? get document; QuizContent? get quiz; AssignmentContent? get assignment; LiveContent? get live;
/// Create a copy of LessonContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonContentCopyWith<LessonContent> get copyWith => _$LessonContentCopyWithImpl<LessonContent>(this as LessonContent, _$identity);

  /// Serializes this LessonContent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonContent&&(identical(other.video, video) || other.video == video)&&(identical(other.article, article) || other.article == article)&&(identical(other.document, document) || other.document == document)&&(identical(other.quiz, quiz) || other.quiz == quiz)&&(identical(other.assignment, assignment) || other.assignment == assignment)&&(identical(other.live, live) || other.live == live));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,video,article,document,quiz,assignment,live);

@override
String toString() {
  return 'LessonContent(video: $video, article: $article, document: $document, quiz: $quiz, assignment: $assignment, live: $live)';
}


}

/// @nodoc
abstract mixin class $LessonContentCopyWith<$Res>  {
  factory $LessonContentCopyWith(LessonContent value, $Res Function(LessonContent) _then) = _$LessonContentCopyWithImpl;
@useResult
$Res call({
 VideoContent? video, ArticleContent? article, DocumentContent? document, QuizContent? quiz, AssignmentContent? assignment, LiveContent? live
});


$VideoContentCopyWith<$Res>? get video;$ArticleContentCopyWith<$Res>? get article;$DocumentContentCopyWith<$Res>? get document;$QuizContentCopyWith<$Res>? get quiz;$AssignmentContentCopyWith<$Res>? get assignment;$LiveContentCopyWith<$Res>? get live;

}
/// @nodoc
class _$LessonContentCopyWithImpl<$Res>
    implements $LessonContentCopyWith<$Res> {
  _$LessonContentCopyWithImpl(this._self, this._then);

  final LessonContent _self;
  final $Res Function(LessonContent) _then;

/// Create a copy of LessonContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? video = freezed,Object? article = freezed,Object? document = freezed,Object? quiz = freezed,Object? assignment = freezed,Object? live = freezed,}) {
  return _then(_self.copyWith(
video: freezed == video ? _self.video : video // ignore: cast_nullable_to_non_nullable
as VideoContent?,article: freezed == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as ArticleContent?,document: freezed == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as DocumentContent?,quiz: freezed == quiz ? _self.quiz : quiz // ignore: cast_nullable_to_non_nullable
as QuizContent?,assignment: freezed == assignment ? _self.assignment : assignment // ignore: cast_nullable_to_non_nullable
as AssignmentContent?,live: freezed == live ? _self.live : live // ignore: cast_nullable_to_non_nullable
as LiveContent?,
  ));
}
/// Create a copy of LessonContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VideoContentCopyWith<$Res>? get video {
    if (_self.video == null) {
    return null;
  }

  return $VideoContentCopyWith<$Res>(_self.video!, (value) {
    return _then(_self.copyWith(video: value));
  });
}/// Create a copy of LessonContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleContentCopyWith<$Res>? get article {
    if (_self.article == null) {
    return null;
  }

  return $ArticleContentCopyWith<$Res>(_self.article!, (value) {
    return _then(_self.copyWith(article: value));
  });
}/// Create a copy of LessonContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DocumentContentCopyWith<$Res>? get document {
    if (_self.document == null) {
    return null;
  }

  return $DocumentContentCopyWith<$Res>(_self.document!, (value) {
    return _then(_self.copyWith(document: value));
  });
}/// Create a copy of LessonContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizContentCopyWith<$Res>? get quiz {
    if (_self.quiz == null) {
    return null;
  }

  return $QuizContentCopyWith<$Res>(_self.quiz!, (value) {
    return _then(_self.copyWith(quiz: value));
  });
}/// Create a copy of LessonContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssignmentContentCopyWith<$Res>? get assignment {
    if (_self.assignment == null) {
    return null;
  }

  return $AssignmentContentCopyWith<$Res>(_self.assignment!, (value) {
    return _then(_self.copyWith(assignment: value));
  });
}/// Create a copy of LessonContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveContentCopyWith<$Res>? get live {
    if (_self.live == null) {
    return null;
  }

  return $LiveContentCopyWith<$Res>(_self.live!, (value) {
    return _then(_self.copyWith(live: value));
  });
}
}


/// Adds pattern-matching-related methods to [LessonContent].
extension LessonContentPatterns on LessonContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonContent value)  $default,){
final _that = this;
switch (_that) {
case _LessonContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonContent value)?  $default,){
final _that = this;
switch (_that) {
case _LessonContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( VideoContent? video,  ArticleContent? article,  DocumentContent? document,  QuizContent? quiz,  AssignmentContent? assignment,  LiveContent? live)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonContent() when $default != null:
return $default(_that.video,_that.article,_that.document,_that.quiz,_that.assignment,_that.live);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( VideoContent? video,  ArticleContent? article,  DocumentContent? document,  QuizContent? quiz,  AssignmentContent? assignment,  LiveContent? live)  $default,) {final _that = this;
switch (_that) {
case _LessonContent():
return $default(_that.video,_that.article,_that.document,_that.quiz,_that.assignment,_that.live);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( VideoContent? video,  ArticleContent? article,  DocumentContent? document,  QuizContent? quiz,  AssignmentContent? assignment,  LiveContent? live)?  $default,) {final _that = this;
switch (_that) {
case _LessonContent() when $default != null:
return $default(_that.video,_that.article,_that.document,_that.quiz,_that.assignment,_that.live);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonContent extends LessonContent {
  const _LessonContent({this.video, this.article, this.document, this.quiz, this.assignment, this.live}): super._();
  factory _LessonContent.fromJson(Map<String, dynamic> json) => _$LessonContentFromJson(json);

@override final  VideoContent? video;
@override final  ArticleContent? article;
@override final  DocumentContent? document;
@override final  QuizContent? quiz;
@override final  AssignmentContent? assignment;
@override final  LiveContent? live;

/// Create a copy of LessonContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonContentCopyWith<_LessonContent> get copyWith => __$LessonContentCopyWithImpl<_LessonContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonContent&&(identical(other.video, video) || other.video == video)&&(identical(other.article, article) || other.article == article)&&(identical(other.document, document) || other.document == document)&&(identical(other.quiz, quiz) || other.quiz == quiz)&&(identical(other.assignment, assignment) || other.assignment == assignment)&&(identical(other.live, live) || other.live == live));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,video,article,document,quiz,assignment,live);

@override
String toString() {
  return 'LessonContent(video: $video, article: $article, document: $document, quiz: $quiz, assignment: $assignment, live: $live)';
}


}

/// @nodoc
abstract mixin class _$LessonContentCopyWith<$Res> implements $LessonContentCopyWith<$Res> {
  factory _$LessonContentCopyWith(_LessonContent value, $Res Function(_LessonContent) _then) = __$LessonContentCopyWithImpl;
@override @useResult
$Res call({
 VideoContent? video, ArticleContent? article, DocumentContent? document, QuizContent? quiz, AssignmentContent? assignment, LiveContent? live
});


@override $VideoContentCopyWith<$Res>? get video;@override $ArticleContentCopyWith<$Res>? get article;@override $DocumentContentCopyWith<$Res>? get document;@override $QuizContentCopyWith<$Res>? get quiz;@override $AssignmentContentCopyWith<$Res>? get assignment;@override $LiveContentCopyWith<$Res>? get live;

}
/// @nodoc
class __$LessonContentCopyWithImpl<$Res>
    implements _$LessonContentCopyWith<$Res> {
  __$LessonContentCopyWithImpl(this._self, this._then);

  final _LessonContent _self;
  final $Res Function(_LessonContent) _then;

/// Create a copy of LessonContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? video = freezed,Object? article = freezed,Object? document = freezed,Object? quiz = freezed,Object? assignment = freezed,Object? live = freezed,}) {
  return _then(_LessonContent(
video: freezed == video ? _self.video : video // ignore: cast_nullable_to_non_nullable
as VideoContent?,article: freezed == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as ArticleContent?,document: freezed == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as DocumentContent?,quiz: freezed == quiz ? _self.quiz : quiz // ignore: cast_nullable_to_non_nullable
as QuizContent?,assignment: freezed == assignment ? _self.assignment : assignment // ignore: cast_nullable_to_non_nullable
as AssignmentContent?,live: freezed == live ? _self.live : live // ignore: cast_nullable_to_non_nullable
as LiveContent?,
  ));
}

/// Create a copy of LessonContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VideoContentCopyWith<$Res>? get video {
    if (_self.video == null) {
    return null;
  }

  return $VideoContentCopyWith<$Res>(_self.video!, (value) {
    return _then(_self.copyWith(video: value));
  });
}/// Create a copy of LessonContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArticleContentCopyWith<$Res>? get article {
    if (_self.article == null) {
    return null;
  }

  return $ArticleContentCopyWith<$Res>(_self.article!, (value) {
    return _then(_self.copyWith(article: value));
  });
}/// Create a copy of LessonContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DocumentContentCopyWith<$Res>? get document {
    if (_self.document == null) {
    return null;
  }

  return $DocumentContentCopyWith<$Res>(_self.document!, (value) {
    return _then(_self.copyWith(document: value));
  });
}/// Create a copy of LessonContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizContentCopyWith<$Res>? get quiz {
    if (_self.quiz == null) {
    return null;
  }

  return $QuizContentCopyWith<$Res>(_self.quiz!, (value) {
    return _then(_self.copyWith(quiz: value));
  });
}/// Create a copy of LessonContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssignmentContentCopyWith<$Res>? get assignment {
    if (_self.assignment == null) {
    return null;
  }

  return $AssignmentContentCopyWith<$Res>(_self.assignment!, (value) {
    return _then(_self.copyWith(assignment: value));
  });
}/// Create a copy of LessonContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveContentCopyWith<$Res>? get live {
    if (_self.live == null) {
    return null;
  }

  return $LiveContentCopyWith<$Res>(_self.live!, (value) {
    return _then(_self.copyWith(live: value));
  });
}
}


/// @nodoc
mixin _$LessonSettings {

@JsonKey(unknownEnumValue: CompletionRule.unknown) CompletionRule? get completion; bool get sequential; bool get discussion; bool get resourcesDownloadable;
/// Create a copy of LessonSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonSettingsCopyWith<LessonSettings> get copyWith => _$LessonSettingsCopyWithImpl<LessonSettings>(this as LessonSettings, _$identity);

  /// Serializes this LessonSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonSettings&&(identical(other.completion, completion) || other.completion == completion)&&(identical(other.sequential, sequential) || other.sequential == sequential)&&(identical(other.discussion, discussion) || other.discussion == discussion)&&(identical(other.resourcesDownloadable, resourcesDownloadable) || other.resourcesDownloadable == resourcesDownloadable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,completion,sequential,discussion,resourcesDownloadable);

@override
String toString() {
  return 'LessonSettings(completion: $completion, sequential: $sequential, discussion: $discussion, resourcesDownloadable: $resourcesDownloadable)';
}


}

/// @nodoc
abstract mixin class $LessonSettingsCopyWith<$Res>  {
  factory $LessonSettingsCopyWith(LessonSettings value, $Res Function(LessonSettings) _then) = _$LessonSettingsCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: CompletionRule.unknown) CompletionRule? completion, bool sequential, bool discussion, bool resourcesDownloadable
});




}
/// @nodoc
class _$LessonSettingsCopyWithImpl<$Res>
    implements $LessonSettingsCopyWith<$Res> {
  _$LessonSettingsCopyWithImpl(this._self, this._then);

  final LessonSettings _self;
  final $Res Function(LessonSettings) _then;

/// Create a copy of LessonSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? completion = freezed,Object? sequential = null,Object? discussion = null,Object? resourcesDownloadable = null,}) {
  return _then(_self.copyWith(
completion: freezed == completion ? _self.completion : completion // ignore: cast_nullable_to_non_nullable
as CompletionRule?,sequential: null == sequential ? _self.sequential : sequential // ignore: cast_nullable_to_non_nullable
as bool,discussion: null == discussion ? _self.discussion : discussion // ignore: cast_nullable_to_non_nullable
as bool,resourcesDownloadable: null == resourcesDownloadable ? _self.resourcesDownloadable : resourcesDownloadable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonSettings].
extension LessonSettingsPatterns on LessonSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonSettings value)  $default,){
final _that = this;
switch (_that) {
case _LessonSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonSettings value)?  $default,){
final _that = this;
switch (_that) {
case _LessonSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: CompletionRule.unknown)  CompletionRule? completion,  bool sequential,  bool discussion,  bool resourcesDownloadable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonSettings() when $default != null:
return $default(_that.completion,_that.sequential,_that.discussion,_that.resourcesDownloadable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: CompletionRule.unknown)  CompletionRule? completion,  bool sequential,  bool discussion,  bool resourcesDownloadable)  $default,) {final _that = this;
switch (_that) {
case _LessonSettings():
return $default(_that.completion,_that.sequential,_that.discussion,_that.resourcesDownloadable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: CompletionRule.unknown)  CompletionRule? completion,  bool sequential,  bool discussion,  bool resourcesDownloadable)?  $default,) {final _that = this;
switch (_that) {
case _LessonSettings() when $default != null:
return $default(_that.completion,_that.sequential,_that.discussion,_that.resourcesDownloadable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonSettings implements LessonSettings {
  const _LessonSettings({@JsonKey(unknownEnumValue: CompletionRule.unknown) this.completion, this.sequential = false, this.discussion = false, this.resourcesDownloadable = false});
  factory _LessonSettings.fromJson(Map<String, dynamic> json) => _$LessonSettingsFromJson(json);

@override@JsonKey(unknownEnumValue: CompletionRule.unknown) final  CompletionRule? completion;
@override@JsonKey() final  bool sequential;
@override@JsonKey() final  bool discussion;
@override@JsonKey() final  bool resourcesDownloadable;

/// Create a copy of LessonSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonSettingsCopyWith<_LessonSettings> get copyWith => __$LessonSettingsCopyWithImpl<_LessonSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonSettings&&(identical(other.completion, completion) || other.completion == completion)&&(identical(other.sequential, sequential) || other.sequential == sequential)&&(identical(other.discussion, discussion) || other.discussion == discussion)&&(identical(other.resourcesDownloadable, resourcesDownloadable) || other.resourcesDownloadable == resourcesDownloadable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,completion,sequential,discussion,resourcesDownloadable);

@override
String toString() {
  return 'LessonSettings(completion: $completion, sequential: $sequential, discussion: $discussion, resourcesDownloadable: $resourcesDownloadable)';
}


}

/// @nodoc
abstract mixin class _$LessonSettingsCopyWith<$Res> implements $LessonSettingsCopyWith<$Res> {
  factory _$LessonSettingsCopyWith(_LessonSettings value, $Res Function(_LessonSettings) _then) = __$LessonSettingsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: CompletionRule.unknown) CompletionRule? completion, bool sequential, bool discussion, bool resourcesDownloadable
});




}
/// @nodoc
class __$LessonSettingsCopyWithImpl<$Res>
    implements _$LessonSettingsCopyWith<$Res> {
  __$LessonSettingsCopyWithImpl(this._self, this._then);

  final _LessonSettings _self;
  final $Res Function(_LessonSettings) _then;

/// Create a copy of LessonSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? completion = freezed,Object? sequential = null,Object? discussion = null,Object? resourcesDownloadable = null,}) {
  return _then(_LessonSettings(
completion: freezed == completion ? _self.completion : completion // ignore: cast_nullable_to_non_nullable
as CompletionRule?,sequential: null == sequential ? _self.sequential : sequential // ignore: cast_nullable_to_non_nullable
as bool,discussion: null == discussion ? _self.discussion : discussion // ignore: cast_nullable_to_non_nullable
as bool,resourcesDownloadable: null == resourcesDownloadable ? _self.resourcesDownloadable : resourcesDownloadable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Lesson {

 String get id; String get title;/// The backend's `LessonType`, kept as sent; the UI maps it through `LessonType.parse`.
 String get type; int get durationMin;@JsonKey(unknownEnumValue: ContentStatus.unknown) ContentStatus get status; bool get isPreview; String? get description; List<String> get objectives; LessonContent? get content; LessonSettings? get settings;
/// Create a copy of Lesson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonCopyWith<Lesson> get copyWith => _$LessonCopyWithImpl<Lesson>(this as Lesson, _$identity);

  /// Serializes this Lesson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Lesson&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.status, status) || other.status == status)&&(identical(other.isPreview, isPreview) || other.isPreview == isPreview)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.objectives, objectives)&&(identical(other.content, content) || other.content == content)&&(identical(other.settings, settings) || other.settings == settings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,type,durationMin,status,isPreview,description,const DeepCollectionEquality().hash(objectives),content,settings);

@override
String toString() {
  return 'Lesson(id: $id, title: $title, type: $type, durationMin: $durationMin, status: $status, isPreview: $isPreview, description: $description, objectives: $objectives, content: $content, settings: $settings)';
}


}

/// @nodoc
abstract mixin class $LessonCopyWith<$Res>  {
  factory $LessonCopyWith(Lesson value, $Res Function(Lesson) _then) = _$LessonCopyWithImpl;
@useResult
$Res call({
 String id, String title, String type, int durationMin,@JsonKey(unknownEnumValue: ContentStatus.unknown) ContentStatus status, bool isPreview, String? description, List<String> objectives, LessonContent? content, LessonSettings? settings
});


$LessonContentCopyWith<$Res>? get content;$LessonSettingsCopyWith<$Res>? get settings;

}
/// @nodoc
class _$LessonCopyWithImpl<$Res>
    implements $LessonCopyWith<$Res> {
  _$LessonCopyWithImpl(this._self, this._then);

  final Lesson _self;
  final $Res Function(Lesson) _then;

/// Create a copy of Lesson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? type = null,Object? durationMin = null,Object? status = null,Object? isPreview = null,Object? description = freezed,Object? objectives = null,Object? content = freezed,Object? settings = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,durationMin: null == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ContentStatus,isPreview: null == isPreview ? _self.isPreview : isPreview // ignore: cast_nullable_to_non_nullable
as bool,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,objectives: null == objectives ? _self.objectives : objectives // ignore: cast_nullable_to_non_nullable
as List<String>,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as LessonContent?,settings: freezed == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as LessonSettings?,
  ));
}
/// Create a copy of Lesson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonContentCopyWith<$Res>? get content {
    if (_self.content == null) {
    return null;
  }

  return $LessonContentCopyWith<$Res>(_self.content!, (value) {
    return _then(_self.copyWith(content: value));
  });
}/// Create a copy of Lesson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonSettingsCopyWith<$Res>? get settings {
    if (_self.settings == null) {
    return null;
  }

  return $LessonSettingsCopyWith<$Res>(_self.settings!, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}


/// Adds pattern-matching-related methods to [Lesson].
extension LessonPatterns on Lesson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Lesson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Lesson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Lesson value)  $default,){
final _that = this;
switch (_that) {
case _Lesson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Lesson value)?  $default,){
final _that = this;
switch (_that) {
case _Lesson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String type,  int durationMin, @JsonKey(unknownEnumValue: ContentStatus.unknown)  ContentStatus status,  bool isPreview,  String? description,  List<String> objectives,  LessonContent? content,  LessonSettings? settings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Lesson() when $default != null:
return $default(_that.id,_that.title,_that.type,_that.durationMin,_that.status,_that.isPreview,_that.description,_that.objectives,_that.content,_that.settings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String type,  int durationMin, @JsonKey(unknownEnumValue: ContentStatus.unknown)  ContentStatus status,  bool isPreview,  String? description,  List<String> objectives,  LessonContent? content,  LessonSettings? settings)  $default,) {final _that = this;
switch (_that) {
case _Lesson():
return $default(_that.id,_that.title,_that.type,_that.durationMin,_that.status,_that.isPreview,_that.description,_that.objectives,_that.content,_that.settings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String type,  int durationMin, @JsonKey(unknownEnumValue: ContentStatus.unknown)  ContentStatus status,  bool isPreview,  String? description,  List<String> objectives,  LessonContent? content,  LessonSettings? settings)?  $default,) {final _that = this;
switch (_that) {
case _Lesson() when $default != null:
return $default(_that.id,_that.title,_that.type,_that.durationMin,_that.status,_that.isPreview,_that.description,_that.objectives,_that.content,_that.settings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Lesson extends Lesson {
  const _Lesson({required this.id, required this.title, required this.type, this.durationMin = 0, @JsonKey(unknownEnumValue: ContentStatus.unknown) this.status = ContentStatus.published, this.isPreview = false, this.description, final  List<String> objectives = const <String>[], this.content, this.settings}): _objectives = objectives,super._();
  factory _Lesson.fromJson(Map<String, dynamic> json) => _$LessonFromJson(json);

@override final  String id;
@override final  String title;
/// The backend's `LessonType`, kept as sent; the UI maps it through `LessonType.parse`.
@override final  String type;
@override@JsonKey() final  int durationMin;
@override@JsonKey(unknownEnumValue: ContentStatus.unknown) final  ContentStatus status;
@override@JsonKey() final  bool isPreview;
@override final  String? description;
 final  List<String> _objectives;
@override@JsonKey() List<String> get objectives {
  if (_objectives is EqualUnmodifiableListView) return _objectives;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_objectives);
}

@override final  LessonContent? content;
@override final  LessonSettings? settings;

/// Create a copy of Lesson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonCopyWith<_Lesson> get copyWith => __$LessonCopyWithImpl<_Lesson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Lesson&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.status, status) || other.status == status)&&(identical(other.isPreview, isPreview) || other.isPreview == isPreview)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._objectives, _objectives)&&(identical(other.content, content) || other.content == content)&&(identical(other.settings, settings) || other.settings == settings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,type,durationMin,status,isPreview,description,const DeepCollectionEquality().hash(_objectives),content,settings);

@override
String toString() {
  return 'Lesson(id: $id, title: $title, type: $type, durationMin: $durationMin, status: $status, isPreview: $isPreview, description: $description, objectives: $objectives, content: $content, settings: $settings)';
}


}

/// @nodoc
abstract mixin class _$LessonCopyWith<$Res> implements $LessonCopyWith<$Res> {
  factory _$LessonCopyWith(_Lesson value, $Res Function(_Lesson) _then) = __$LessonCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String type, int durationMin,@JsonKey(unknownEnumValue: ContentStatus.unknown) ContentStatus status, bool isPreview, String? description, List<String> objectives, LessonContent? content, LessonSettings? settings
});


@override $LessonContentCopyWith<$Res>? get content;@override $LessonSettingsCopyWith<$Res>? get settings;

}
/// @nodoc
class __$LessonCopyWithImpl<$Res>
    implements _$LessonCopyWith<$Res> {
  __$LessonCopyWithImpl(this._self, this._then);

  final _Lesson _self;
  final $Res Function(_Lesson) _then;

/// Create a copy of Lesson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? type = null,Object? durationMin = null,Object? status = null,Object? isPreview = null,Object? description = freezed,Object? objectives = null,Object? content = freezed,Object? settings = freezed,}) {
  return _then(_Lesson(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,durationMin: null == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ContentStatus,isPreview: null == isPreview ? _self.isPreview : isPreview // ignore: cast_nullable_to_non_nullable
as bool,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,objectives: null == objectives ? _self._objectives : objectives // ignore: cast_nullable_to_non_nullable
as List<String>,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as LessonContent?,settings: freezed == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as LessonSettings?,
  ));
}

/// Create a copy of Lesson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonContentCopyWith<$Res>? get content {
    if (_self.content == null) {
    return null;
  }

  return $LessonContentCopyWith<$Res>(_self.content!, (value) {
    return _then(_self.copyWith(content: value));
  });
}/// Create a copy of Lesson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonSettingsCopyWith<$Res>? get settings {
    if (_self.settings == null) {
    return null;
  }

  return $LessonSettingsCopyWith<$Res>(_self.settings!, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}

Chapter _$ChapterFromJson(
  Map<String, dynamic> json
) {
    return _CatalogChapter.fromJson(
      json
    );
}

/// @nodoc
mixin _$Chapter {

 String get id; String get title; String? get summary; String? get objective;@JsonKey(unknownEnumValue: ContentStatus.unknown) ContentStatus get status; List<Lesson> get lessons;
/// Create a copy of Chapter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChapterCopyWith<Chapter> get copyWith => _$ChapterCopyWithImpl<Chapter>(this as Chapter, _$identity);

  /// Serializes this Chapter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Chapter&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.objective, objective) || other.objective == objective)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.lessons, lessons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,summary,objective,status,const DeepCollectionEquality().hash(lessons));

@override
String toString() {
  return 'Chapter(id: $id, title: $title, summary: $summary, objective: $objective, status: $status, lessons: $lessons)';
}


}

/// @nodoc
abstract mixin class $ChapterCopyWith<$Res>  {
  factory $ChapterCopyWith(Chapter value, $Res Function(Chapter) _then) = _$ChapterCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? summary, String? objective,@JsonKey(unknownEnumValue: ContentStatus.unknown) ContentStatus status, List<Lesson> lessons
});




}
/// @nodoc
class _$ChapterCopyWithImpl<$Res>
    implements $ChapterCopyWith<$Res> {
  _$ChapterCopyWithImpl(this._self, this._then);

  final Chapter _self;
  final $Res Function(Chapter) _then;

/// Create a copy of Chapter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? summary = freezed,Object? objective = freezed,Object? status = null,Object? lessons = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,objective: freezed == objective ? _self.objective : objective // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ContentStatus,lessons: null == lessons ? _self.lessons : lessons // ignore: cast_nullable_to_non_nullable
as List<Lesson>,
  ));
}

}


/// Adds pattern-matching-related methods to [Chapter].
extension ChapterPatterns on Chapter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogChapter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogChapter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogChapter value)  $default,){
final _that = this;
switch (_that) {
case _CatalogChapter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogChapter value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogChapter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? summary,  String? objective, @JsonKey(unknownEnumValue: ContentStatus.unknown)  ContentStatus status,  List<Lesson> lessons)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogChapter() when $default != null:
return $default(_that.id,_that.title,_that.summary,_that.objective,_that.status,_that.lessons);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? summary,  String? objective, @JsonKey(unknownEnumValue: ContentStatus.unknown)  ContentStatus status,  List<Lesson> lessons)  $default,) {final _that = this;
switch (_that) {
case _CatalogChapter():
return $default(_that.id,_that.title,_that.summary,_that.objective,_that.status,_that.lessons);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? summary,  String? objective, @JsonKey(unknownEnumValue: ContentStatus.unknown)  ContentStatus status,  List<Lesson> lessons)?  $default,) {final _that = this;
switch (_that) {
case _CatalogChapter() when $default != null:
return $default(_that.id,_that.title,_that.summary,_that.objective,_that.status,_that.lessons);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogChapter implements Chapter {
  const _CatalogChapter({required this.id, required this.title, this.summary, this.objective, @JsonKey(unknownEnumValue: ContentStatus.unknown) this.status = ContentStatus.published, final  List<Lesson> lessons = const <Lesson>[]}): _lessons = lessons;
  factory _CatalogChapter.fromJson(Map<String, dynamic> json) => _$CatalogChapterFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? summary;
@override final  String? objective;
@override@JsonKey(unknownEnumValue: ContentStatus.unknown) final  ContentStatus status;
 final  List<Lesson> _lessons;
@override@JsonKey() List<Lesson> get lessons {
  if (_lessons is EqualUnmodifiableListView) return _lessons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lessons);
}


/// Create a copy of Chapter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogChapterCopyWith<_CatalogChapter> get copyWith => __$CatalogChapterCopyWithImpl<_CatalogChapter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogChapterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogChapter&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.objective, objective) || other.objective == objective)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._lessons, _lessons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,summary,objective,status,const DeepCollectionEquality().hash(_lessons));

@override
String toString() {
  return 'Chapter(id: $id, title: $title, summary: $summary, objective: $objective, status: $status, lessons: $lessons)';
}


}

/// @nodoc
abstract mixin class _$CatalogChapterCopyWith<$Res> implements $ChapterCopyWith<$Res> {
  factory _$CatalogChapterCopyWith(_CatalogChapter value, $Res Function(_CatalogChapter) _then) = __$CatalogChapterCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? summary, String? objective,@JsonKey(unknownEnumValue: ContentStatus.unknown) ContentStatus status, List<Lesson> lessons
});




}
/// @nodoc
class __$CatalogChapterCopyWithImpl<$Res>
    implements _$CatalogChapterCopyWith<$Res> {
  __$CatalogChapterCopyWithImpl(this._self, this._then);

  final _CatalogChapter _self;
  final $Res Function(_CatalogChapter) _then;

/// Create a copy of Chapter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? summary = freezed,Object? objective = freezed,Object? status = null,Object? lessons = null,}) {
  return _then(_CatalogChapter(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,objective: freezed == objective ? _self.objective : objective // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ContentStatus,lessons: null == lessons ? _self._lessons : lessons // ignore: cast_nullable_to_non_nullable
as List<Lesson>,
  ));
}


}

Course _$CourseFromJson(
  Map<String, dynamic> json
) {
    return _CatalogCourse.fromJson(
      json
    );
}

/// @nodoc
mixin _$Course {

 String get id; String get slug; String get title; String get subtitle; String get description; String get levelId; String get categoryId; List<String> get instructorIds;@JsonKey(unknownEnumValue: CourseFormat.unknown) CourseFormat get format; String get language;/// The backend's `CoverMotif`, kept as sent; the UI maps it through `CoverMotif.parse`.
 String? get coverMotif;/// The uploaded cover image (`/catalog/covers/<id>`), or null when the motif is the cover.
 String? get coverImageId; String? get coverImageUrl; List<Chapter> get chapters; int get liveSessions; int? get estimatedWeeks; String? get certificateTitle; Price? get price;/// Free, paid or undecided; read with [price] through [sale].
@JsonKey(unknownEnumValue: CoursePricing.unknown) CoursePricing? get pricing; int get enrolledCount;@JsonKey(unknownEnumValue: CourseStatus.unknown) CourseStatus get status;@JsonKey(unknownEnumValue: CourseVisibility.unknown) CourseVisibility get visibility; List<String> get outcomes; List<String> get tags;/// Sent only when the academy publishes ratings and the minimum count is met (`catalog.ts`).
 double? get rating; int? get ratingCount;
/// Create a copy of Course
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseCopyWith<Course> get copyWith => _$CourseCopyWithImpl<Course>(this as Course, _$identity);

  /// Serializes this Course to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Course&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.description, description) || other.description == description)&&(identical(other.levelId, levelId) || other.levelId == levelId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&const DeepCollectionEquality().equals(other.instructorIds, instructorIds)&&(identical(other.format, format) || other.format == format)&&(identical(other.language, language) || other.language == language)&&(identical(other.coverMotif, coverMotif) || other.coverMotif == coverMotif)&&(identical(other.coverImageId, coverImageId) || other.coverImageId == coverImageId)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&const DeepCollectionEquality().equals(other.chapters, chapters)&&(identical(other.liveSessions, liveSessions) || other.liveSessions == liveSessions)&&(identical(other.estimatedWeeks, estimatedWeeks) || other.estimatedWeeks == estimatedWeeks)&&(identical(other.certificateTitle, certificateTitle) || other.certificateTitle == certificateTitle)&&(identical(other.price, price) || other.price == price)&&(identical(other.pricing, pricing) || other.pricing == pricing)&&(identical(other.enrolledCount, enrolledCount) || other.enrolledCount == enrolledCount)&&(identical(other.status, status) || other.status == status)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&const DeepCollectionEquality().equals(other.outcomes, outcomes)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,slug,title,subtitle,description,levelId,categoryId,const DeepCollectionEquality().hash(instructorIds),format,language,coverMotif,coverImageId,coverImageUrl,const DeepCollectionEquality().hash(chapters),liveSessions,estimatedWeeks,certificateTitle,price,pricing,enrolledCount,status,visibility,const DeepCollectionEquality().hash(outcomes),const DeepCollectionEquality().hash(tags),rating,ratingCount]);

@override
String toString() {
  return 'Course(id: $id, slug: $slug, title: $title, subtitle: $subtitle, description: $description, levelId: $levelId, categoryId: $categoryId, instructorIds: $instructorIds, format: $format, language: $language, coverMotif: $coverMotif, coverImageId: $coverImageId, coverImageUrl: $coverImageUrl, chapters: $chapters, liveSessions: $liveSessions, estimatedWeeks: $estimatedWeeks, certificateTitle: $certificateTitle, price: $price, pricing: $pricing, enrolledCount: $enrolledCount, status: $status, visibility: $visibility, outcomes: $outcomes, tags: $tags, rating: $rating, ratingCount: $ratingCount)';
}


}

/// @nodoc
abstract mixin class $CourseCopyWith<$Res>  {
  factory $CourseCopyWith(Course value, $Res Function(Course) _then) = _$CourseCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String title, String subtitle, String description, String levelId, String categoryId, List<String> instructorIds,@JsonKey(unknownEnumValue: CourseFormat.unknown) CourseFormat format, String language, String? coverMotif, String? coverImageId, String? coverImageUrl, List<Chapter> chapters, int liveSessions, int? estimatedWeeks, String? certificateTitle, Price? price,@JsonKey(unknownEnumValue: CoursePricing.unknown) CoursePricing? pricing, int enrolledCount,@JsonKey(unknownEnumValue: CourseStatus.unknown) CourseStatus status,@JsonKey(unknownEnumValue: CourseVisibility.unknown) CourseVisibility visibility, List<String> outcomes, List<String> tags, double? rating, int? ratingCount
});


$PriceCopyWith<$Res>? get price;

}
/// @nodoc
class _$CourseCopyWithImpl<$Res>
    implements $CourseCopyWith<$Res> {
  _$CourseCopyWithImpl(this._self, this._then);

  final Course _self;
  final $Res Function(Course) _then;

/// Create a copy of Course
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? subtitle = null,Object? description = null,Object? levelId = null,Object? categoryId = null,Object? instructorIds = null,Object? format = null,Object? language = null,Object? coverMotif = freezed,Object? coverImageId = freezed,Object? coverImageUrl = freezed,Object? chapters = null,Object? liveSessions = null,Object? estimatedWeeks = freezed,Object? certificateTitle = freezed,Object? price = freezed,Object? pricing = freezed,Object? enrolledCount = null,Object? status = null,Object? visibility = null,Object? outcomes = null,Object? tags = null,Object? rating = freezed,Object? ratingCount = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,levelId: null == levelId ? _self.levelId : levelId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,instructorIds: null == instructorIds ? _self.instructorIds : instructorIds // ignore: cast_nullable_to_non_nullable
as List<String>,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as CourseFormat,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,coverMotif: freezed == coverMotif ? _self.coverMotif : coverMotif // ignore: cast_nullable_to_non_nullable
as String?,coverImageId: freezed == coverImageId ? _self.coverImageId : coverImageId // ignore: cast_nullable_to_non_nullable
as String?,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,chapters: null == chapters ? _self.chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<Chapter>,liveSessions: null == liveSessions ? _self.liveSessions : liveSessions // ignore: cast_nullable_to_non_nullable
as int,estimatedWeeks: freezed == estimatedWeeks ? _self.estimatedWeeks : estimatedWeeks // ignore: cast_nullable_to_non_nullable
as int?,certificateTitle: freezed == certificateTitle ? _self.certificateTitle : certificateTitle // ignore: cast_nullable_to_non_nullable
as String?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Price?,pricing: freezed == pricing ? _self.pricing : pricing // ignore: cast_nullable_to_non_nullable
as CoursePricing?,enrolledCount: null == enrolledCount ? _self.enrolledCount : enrolledCount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CourseStatus,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as CourseVisibility,outcomes: null == outcomes ? _self.outcomes : outcomes // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: freezed == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of Course
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceCopyWith<$Res>? get price {
    if (_self.price == null) {
    return null;
  }

  return $PriceCopyWith<$Res>(_self.price!, (value) {
    return _then(_self.copyWith(price: value));
  });
}
}


/// Adds pattern-matching-related methods to [Course].
extension CoursePatterns on Course {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogCourse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogCourse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogCourse value)  $default,){
final _that = this;
switch (_that) {
case _CatalogCourse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogCourse value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogCourse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String subtitle,  String description,  String levelId,  String categoryId,  List<String> instructorIds, @JsonKey(unknownEnumValue: CourseFormat.unknown)  CourseFormat format,  String language,  String? coverMotif,  String? coverImageId,  String? coverImageUrl,  List<Chapter> chapters,  int liveSessions,  int? estimatedWeeks,  String? certificateTitle,  Price? price, @JsonKey(unknownEnumValue: CoursePricing.unknown)  CoursePricing? pricing,  int enrolledCount, @JsonKey(unknownEnumValue: CourseStatus.unknown)  CourseStatus status, @JsonKey(unknownEnumValue: CourseVisibility.unknown)  CourseVisibility visibility,  List<String> outcomes,  List<String> tags,  double? rating,  int? ratingCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogCourse() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.subtitle,_that.description,_that.levelId,_that.categoryId,_that.instructorIds,_that.format,_that.language,_that.coverMotif,_that.coverImageId,_that.coverImageUrl,_that.chapters,_that.liveSessions,_that.estimatedWeeks,_that.certificateTitle,_that.price,_that.pricing,_that.enrolledCount,_that.status,_that.visibility,_that.outcomes,_that.tags,_that.rating,_that.ratingCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String subtitle,  String description,  String levelId,  String categoryId,  List<String> instructorIds, @JsonKey(unknownEnumValue: CourseFormat.unknown)  CourseFormat format,  String language,  String? coverMotif,  String? coverImageId,  String? coverImageUrl,  List<Chapter> chapters,  int liveSessions,  int? estimatedWeeks,  String? certificateTitle,  Price? price, @JsonKey(unknownEnumValue: CoursePricing.unknown)  CoursePricing? pricing,  int enrolledCount, @JsonKey(unknownEnumValue: CourseStatus.unknown)  CourseStatus status, @JsonKey(unknownEnumValue: CourseVisibility.unknown)  CourseVisibility visibility,  List<String> outcomes,  List<String> tags,  double? rating,  int? ratingCount)  $default,) {final _that = this;
switch (_that) {
case _CatalogCourse():
return $default(_that.id,_that.slug,_that.title,_that.subtitle,_that.description,_that.levelId,_that.categoryId,_that.instructorIds,_that.format,_that.language,_that.coverMotif,_that.coverImageId,_that.coverImageUrl,_that.chapters,_that.liveSessions,_that.estimatedWeeks,_that.certificateTitle,_that.price,_that.pricing,_that.enrolledCount,_that.status,_that.visibility,_that.outcomes,_that.tags,_that.rating,_that.ratingCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String title,  String subtitle,  String description,  String levelId,  String categoryId,  List<String> instructorIds, @JsonKey(unknownEnumValue: CourseFormat.unknown)  CourseFormat format,  String language,  String? coverMotif,  String? coverImageId,  String? coverImageUrl,  List<Chapter> chapters,  int liveSessions,  int? estimatedWeeks,  String? certificateTitle,  Price? price, @JsonKey(unknownEnumValue: CoursePricing.unknown)  CoursePricing? pricing,  int enrolledCount, @JsonKey(unknownEnumValue: CourseStatus.unknown)  CourseStatus status, @JsonKey(unknownEnumValue: CourseVisibility.unknown)  CourseVisibility visibility,  List<String> outcomes,  List<String> tags,  double? rating,  int? ratingCount)?  $default,) {final _that = this;
switch (_that) {
case _CatalogCourse() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.subtitle,_that.description,_that.levelId,_that.categoryId,_that.instructorIds,_that.format,_that.language,_that.coverMotif,_that.coverImageId,_that.coverImageUrl,_that.chapters,_that.liveSessions,_that.estimatedWeeks,_that.certificateTitle,_that.price,_that.pricing,_that.enrolledCount,_that.status,_that.visibility,_that.outcomes,_that.tags,_that.rating,_that.ratingCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogCourse extends Course {
  const _CatalogCourse({required this.id, required this.slug, required this.title, this.subtitle = '', this.description = '', required this.levelId, required this.categoryId, final  List<String> instructorIds = const <String>[], @JsonKey(unknownEnumValue: CourseFormat.unknown) this.format = CourseFormat.selfPaced, this.language = '', this.coverMotif, this.coverImageId, this.coverImageUrl, final  List<Chapter> chapters = const <Chapter>[], this.liveSessions = 0, this.estimatedWeeks, this.certificateTitle, this.price, @JsonKey(unknownEnumValue: CoursePricing.unknown) this.pricing, this.enrolledCount = 0, @JsonKey(unknownEnumValue: CourseStatus.unknown) this.status = CourseStatus.published, @JsonKey(unknownEnumValue: CourseVisibility.unknown) this.visibility = CourseVisibility.public, final  List<String> outcomes = const <String>[], final  List<String> tags = const <String>[], this.rating, this.ratingCount}): _instructorIds = instructorIds,_chapters = chapters,_outcomes = outcomes,_tags = tags,super._();
  factory _CatalogCourse.fromJson(Map<String, dynamic> json) => _$CatalogCourseFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String title;
@override@JsonKey() final  String subtitle;
@override@JsonKey() final  String description;
@override final  String levelId;
@override final  String categoryId;
 final  List<String> _instructorIds;
@override@JsonKey() List<String> get instructorIds {
  if (_instructorIds is EqualUnmodifiableListView) return _instructorIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_instructorIds);
}

@override@JsonKey(unknownEnumValue: CourseFormat.unknown) final  CourseFormat format;
@override@JsonKey() final  String language;
/// The backend's `CoverMotif`, kept as sent; the UI maps it through `CoverMotif.parse`.
@override final  String? coverMotif;
/// The uploaded cover image (`/catalog/covers/<id>`), or null when the motif is the cover.
@override final  String? coverImageId;
@override final  String? coverImageUrl;
 final  List<Chapter> _chapters;
@override@JsonKey() List<Chapter> get chapters {
  if (_chapters is EqualUnmodifiableListView) return _chapters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_chapters);
}

@override@JsonKey() final  int liveSessions;
@override final  int? estimatedWeeks;
@override final  String? certificateTitle;
@override final  Price? price;
/// Free, paid or undecided; read with [price] through [sale].
@override@JsonKey(unknownEnumValue: CoursePricing.unknown) final  CoursePricing? pricing;
@override@JsonKey() final  int enrolledCount;
@override@JsonKey(unknownEnumValue: CourseStatus.unknown) final  CourseStatus status;
@override@JsonKey(unknownEnumValue: CourseVisibility.unknown) final  CourseVisibility visibility;
 final  List<String> _outcomes;
@override@JsonKey() List<String> get outcomes {
  if (_outcomes is EqualUnmodifiableListView) return _outcomes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_outcomes);
}

 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

/// Sent only when the academy publishes ratings and the minimum count is met (`catalog.ts`).
@override final  double? rating;
@override final  int? ratingCount;

/// Create a copy of Course
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogCourseCopyWith<_CatalogCourse> get copyWith => __$CatalogCourseCopyWithImpl<_CatalogCourse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogCourseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogCourse&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.description, description) || other.description == description)&&(identical(other.levelId, levelId) || other.levelId == levelId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&const DeepCollectionEquality().equals(other._instructorIds, _instructorIds)&&(identical(other.format, format) || other.format == format)&&(identical(other.language, language) || other.language == language)&&(identical(other.coverMotif, coverMotif) || other.coverMotif == coverMotif)&&(identical(other.coverImageId, coverImageId) || other.coverImageId == coverImageId)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&const DeepCollectionEquality().equals(other._chapters, _chapters)&&(identical(other.liveSessions, liveSessions) || other.liveSessions == liveSessions)&&(identical(other.estimatedWeeks, estimatedWeeks) || other.estimatedWeeks == estimatedWeeks)&&(identical(other.certificateTitle, certificateTitle) || other.certificateTitle == certificateTitle)&&(identical(other.price, price) || other.price == price)&&(identical(other.pricing, pricing) || other.pricing == pricing)&&(identical(other.enrolledCount, enrolledCount) || other.enrolledCount == enrolledCount)&&(identical(other.status, status) || other.status == status)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&const DeepCollectionEquality().equals(other._outcomes, _outcomes)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,slug,title,subtitle,description,levelId,categoryId,const DeepCollectionEquality().hash(_instructorIds),format,language,coverMotif,coverImageId,coverImageUrl,const DeepCollectionEquality().hash(_chapters),liveSessions,estimatedWeeks,certificateTitle,price,pricing,enrolledCount,status,visibility,const DeepCollectionEquality().hash(_outcomes),const DeepCollectionEquality().hash(_tags),rating,ratingCount]);

@override
String toString() {
  return 'Course(id: $id, slug: $slug, title: $title, subtitle: $subtitle, description: $description, levelId: $levelId, categoryId: $categoryId, instructorIds: $instructorIds, format: $format, language: $language, coverMotif: $coverMotif, coverImageId: $coverImageId, coverImageUrl: $coverImageUrl, chapters: $chapters, liveSessions: $liveSessions, estimatedWeeks: $estimatedWeeks, certificateTitle: $certificateTitle, price: $price, pricing: $pricing, enrolledCount: $enrolledCount, status: $status, visibility: $visibility, outcomes: $outcomes, tags: $tags, rating: $rating, ratingCount: $ratingCount)';
}


}

/// @nodoc
abstract mixin class _$CatalogCourseCopyWith<$Res> implements $CourseCopyWith<$Res> {
  factory _$CatalogCourseCopyWith(_CatalogCourse value, $Res Function(_CatalogCourse) _then) = __$CatalogCourseCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String title, String subtitle, String description, String levelId, String categoryId, List<String> instructorIds,@JsonKey(unknownEnumValue: CourseFormat.unknown) CourseFormat format, String language, String? coverMotif, String? coverImageId, String? coverImageUrl, List<Chapter> chapters, int liveSessions, int? estimatedWeeks, String? certificateTitle, Price? price,@JsonKey(unknownEnumValue: CoursePricing.unknown) CoursePricing? pricing, int enrolledCount,@JsonKey(unknownEnumValue: CourseStatus.unknown) CourseStatus status,@JsonKey(unknownEnumValue: CourseVisibility.unknown) CourseVisibility visibility, List<String> outcomes, List<String> tags, double? rating, int? ratingCount
});


@override $PriceCopyWith<$Res>? get price;

}
/// @nodoc
class __$CatalogCourseCopyWithImpl<$Res>
    implements _$CatalogCourseCopyWith<$Res> {
  __$CatalogCourseCopyWithImpl(this._self, this._then);

  final _CatalogCourse _self;
  final $Res Function(_CatalogCourse) _then;

/// Create a copy of Course
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? subtitle = null,Object? description = null,Object? levelId = null,Object? categoryId = null,Object? instructorIds = null,Object? format = null,Object? language = null,Object? coverMotif = freezed,Object? coverImageId = freezed,Object? coverImageUrl = freezed,Object? chapters = null,Object? liveSessions = null,Object? estimatedWeeks = freezed,Object? certificateTitle = freezed,Object? price = freezed,Object? pricing = freezed,Object? enrolledCount = null,Object? status = null,Object? visibility = null,Object? outcomes = null,Object? tags = null,Object? rating = freezed,Object? ratingCount = freezed,}) {
  return _then(_CatalogCourse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,levelId: null == levelId ? _self.levelId : levelId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,instructorIds: null == instructorIds ? _self._instructorIds : instructorIds // ignore: cast_nullable_to_non_nullable
as List<String>,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as CourseFormat,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,coverMotif: freezed == coverMotif ? _self.coverMotif : coverMotif // ignore: cast_nullable_to_non_nullable
as String?,coverImageId: freezed == coverImageId ? _self.coverImageId : coverImageId // ignore: cast_nullable_to_non_nullable
as String?,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,chapters: null == chapters ? _self._chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<Chapter>,liveSessions: null == liveSessions ? _self.liveSessions : liveSessions // ignore: cast_nullable_to_non_nullable
as int,estimatedWeeks: freezed == estimatedWeeks ? _self.estimatedWeeks : estimatedWeeks // ignore: cast_nullable_to_non_nullable
as int?,certificateTitle: freezed == certificateTitle ? _self.certificateTitle : certificateTitle // ignore: cast_nullable_to_non_nullable
as String?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Price?,pricing: freezed == pricing ? _self.pricing : pricing // ignore: cast_nullable_to_non_nullable
as CoursePricing?,enrolledCount: null == enrolledCount ? _self.enrolledCount : enrolledCount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CourseStatus,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as CourseVisibility,outcomes: null == outcomes ? _self._outcomes : outcomes // ignore: cast_nullable_to_non_nullable
as List<String>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: freezed == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of Course
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceCopyWith<$Res>? get price {
    if (_self.price == null) {
    return null;
  }

  return $PriceCopyWith<$Res>(_self.price!, (value) {
    return _then(_self.copyWith(price: value));
  });
}
}

CourseCategory _$CourseCategoryFromJson(
  Map<String, dynamic> json
) {
    return _CatalogCategory.fromJson(
      json
    );
}

/// @nodoc
mixin _$CourseCategory {

 String get id; String get name; String get description; List<String> get levelIds; int get order;@JsonKey(unknownEnumValue: CategoryStatus.unknown) CategoryStatus get status;
/// Create a copy of CourseCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseCategoryCopyWith<CourseCategory> get copyWith => _$CourseCategoryCopyWithImpl<CourseCategory>(this as CourseCategory, _$identity);

  /// Serializes this CourseCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.levelIds, levelIds)&&(identical(other.order, order) || other.order == order)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,const DeepCollectionEquality().hash(levelIds),order,status);

@override
String toString() {
  return 'CourseCategory(id: $id, name: $name, description: $description, levelIds: $levelIds, order: $order, status: $status)';
}


}

/// @nodoc
abstract mixin class $CourseCategoryCopyWith<$Res>  {
  factory $CourseCategoryCopyWith(CourseCategory value, $Res Function(CourseCategory) _then) = _$CourseCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, List<String> levelIds, int order,@JsonKey(unknownEnumValue: CategoryStatus.unknown) CategoryStatus status
});




}
/// @nodoc
class _$CourseCategoryCopyWithImpl<$Res>
    implements $CourseCategoryCopyWith<$Res> {
  _$CourseCategoryCopyWithImpl(this._self, this._then);

  final CourseCategory _self;
  final $Res Function(CourseCategory) _then;

/// Create a copy of CourseCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? levelIds = null,Object? order = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,levelIds: null == levelIds ? _self.levelIds : levelIds // ignore: cast_nullable_to_non_nullable
as List<String>,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CategoryStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [CourseCategory].
extension CourseCategoryPatterns on CourseCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogCategory value)  $default,){
final _that = this;
switch (_that) {
case _CatalogCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogCategory value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  List<String> levelIds,  int order, @JsonKey(unknownEnumValue: CategoryStatus.unknown)  CategoryStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogCategory() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.levelIds,_that.order,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  List<String> levelIds,  int order, @JsonKey(unknownEnumValue: CategoryStatus.unknown)  CategoryStatus status)  $default,) {final _that = this;
switch (_that) {
case _CatalogCategory():
return $default(_that.id,_that.name,_that.description,_that.levelIds,_that.order,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  List<String> levelIds,  int order, @JsonKey(unknownEnumValue: CategoryStatus.unknown)  CategoryStatus status)?  $default,) {final _that = this;
switch (_that) {
case _CatalogCategory() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.levelIds,_that.order,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogCategory implements CourseCategory {
  const _CatalogCategory({required this.id, required this.name, this.description = '', final  List<String> levelIds = const <String>[], this.order = 0, @JsonKey(unknownEnumValue: CategoryStatus.unknown) this.status = CategoryStatus.active}): _levelIds = levelIds;
  factory _CatalogCategory.fromJson(Map<String, dynamic> json) => _$CatalogCategoryFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String description;
 final  List<String> _levelIds;
@override@JsonKey() List<String> get levelIds {
  if (_levelIds is EqualUnmodifiableListView) return _levelIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_levelIds);
}

@override@JsonKey() final  int order;
@override@JsonKey(unknownEnumValue: CategoryStatus.unknown) final  CategoryStatus status;

/// Create a copy of CourseCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogCategoryCopyWith<_CatalogCategory> get copyWith => __$CatalogCategoryCopyWithImpl<_CatalogCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._levelIds, _levelIds)&&(identical(other.order, order) || other.order == order)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,const DeepCollectionEquality().hash(_levelIds),order,status);

@override
String toString() {
  return 'CourseCategory(id: $id, name: $name, description: $description, levelIds: $levelIds, order: $order, status: $status)';
}


}

/// @nodoc
abstract mixin class _$CatalogCategoryCopyWith<$Res> implements $CourseCategoryCopyWith<$Res> {
  factory _$CatalogCategoryCopyWith(_CatalogCategory value, $Res Function(_CatalogCategory) _then) = __$CatalogCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, List<String> levelIds, int order,@JsonKey(unknownEnumValue: CategoryStatus.unknown) CategoryStatus status
});




}
/// @nodoc
class __$CatalogCategoryCopyWithImpl<$Res>
    implements _$CatalogCategoryCopyWith<$Res> {
  __$CatalogCategoryCopyWithImpl(this._self, this._then);

  final _CatalogCategory _self;
  final $Res Function(_CatalogCategory) _then;

/// Create a copy of CourseCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? levelIds = null,Object? order = null,Object? status = null,}) {
  return _then(_CatalogCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,levelIds: null == levelIds ? _self._levelIds : levelIds // ignore: cast_nullable_to_non_nullable
as List<String>,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CategoryStatus,
  ));
}


}

Instructor _$InstructorFromJson(
  Map<String, dynamic> json
) {
    return _CatalogInstructor.fromJson(
      json
    );
}

/// @nodoc
mixin _$Instructor {

 String get id; String get name; String get title; String get bio; List<String> get expertise; int? get yearsTeaching; MediaFile? get photo;
/// Create a copy of Instructor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstructorCopyWith<Instructor> get copyWith => _$InstructorCopyWithImpl<Instructor>(this as Instructor, _$identity);

  /// Serializes this Instructor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Instructor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other.expertise, expertise)&&(identical(other.yearsTeaching, yearsTeaching) || other.yearsTeaching == yearsTeaching)&&(identical(other.photo, photo) || other.photo == photo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,title,bio,const DeepCollectionEquality().hash(expertise),yearsTeaching,photo);

@override
String toString() {
  return 'Instructor(id: $id, name: $name, title: $title, bio: $bio, expertise: $expertise, yearsTeaching: $yearsTeaching, photo: $photo)';
}


}

/// @nodoc
abstract mixin class $InstructorCopyWith<$Res>  {
  factory $InstructorCopyWith(Instructor value, $Res Function(Instructor) _then) = _$InstructorCopyWithImpl;
@useResult
$Res call({
 String id, String name, String title, String bio, List<String> expertise, int? yearsTeaching, MediaFile? photo
});


$MediaFileCopyWith<$Res>? get photo;

}
/// @nodoc
class _$InstructorCopyWithImpl<$Res>
    implements $InstructorCopyWith<$Res> {
  _$InstructorCopyWithImpl(this._self, this._then);

  final Instructor _self;
  final $Res Function(Instructor) _then;

/// Create a copy of Instructor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? title = null,Object? bio = null,Object? expertise = null,Object? yearsTeaching = freezed,Object? photo = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,expertise: null == expertise ? _self.expertise : expertise // ignore: cast_nullable_to_non_nullable
as List<String>,yearsTeaching: freezed == yearsTeaching ? _self.yearsTeaching : yearsTeaching // ignore: cast_nullable_to_non_nullable
as int?,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as MediaFile?,
  ));
}
/// Create a copy of Instructor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaFileCopyWith<$Res>? get photo {
    if (_self.photo == null) {
    return null;
  }

  return $MediaFileCopyWith<$Res>(_self.photo!, (value) {
    return _then(_self.copyWith(photo: value));
  });
}
}


/// Adds pattern-matching-related methods to [Instructor].
extension InstructorPatterns on Instructor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogInstructor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogInstructor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogInstructor value)  $default,){
final _that = this;
switch (_that) {
case _CatalogInstructor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogInstructor value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogInstructor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String title,  String bio,  List<String> expertise,  int? yearsTeaching,  MediaFile? photo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogInstructor() when $default != null:
return $default(_that.id,_that.name,_that.title,_that.bio,_that.expertise,_that.yearsTeaching,_that.photo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String title,  String bio,  List<String> expertise,  int? yearsTeaching,  MediaFile? photo)  $default,) {final _that = this;
switch (_that) {
case _CatalogInstructor():
return $default(_that.id,_that.name,_that.title,_that.bio,_that.expertise,_that.yearsTeaching,_that.photo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String title,  String bio,  List<String> expertise,  int? yearsTeaching,  MediaFile? photo)?  $default,) {final _that = this;
switch (_that) {
case _CatalogInstructor() when $default != null:
return $default(_that.id,_that.name,_that.title,_that.bio,_that.expertise,_that.yearsTeaching,_that.photo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogInstructor implements Instructor {
  const _CatalogInstructor({required this.id, required this.name, this.title = '', this.bio = '', final  List<String> expertise = const <String>[], this.yearsTeaching, this.photo}): _expertise = expertise;
  factory _CatalogInstructor.fromJson(Map<String, dynamic> json) => _$CatalogInstructorFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String title;
@override@JsonKey() final  String bio;
 final  List<String> _expertise;
@override@JsonKey() List<String> get expertise {
  if (_expertise is EqualUnmodifiableListView) return _expertise;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expertise);
}

@override final  int? yearsTeaching;
@override final  MediaFile? photo;

/// Create a copy of Instructor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogInstructorCopyWith<_CatalogInstructor> get copyWith => __$CatalogInstructorCopyWithImpl<_CatalogInstructor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogInstructorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogInstructor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other._expertise, _expertise)&&(identical(other.yearsTeaching, yearsTeaching) || other.yearsTeaching == yearsTeaching)&&(identical(other.photo, photo) || other.photo == photo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,title,bio,const DeepCollectionEquality().hash(_expertise),yearsTeaching,photo);

@override
String toString() {
  return 'Instructor(id: $id, name: $name, title: $title, bio: $bio, expertise: $expertise, yearsTeaching: $yearsTeaching, photo: $photo)';
}


}

/// @nodoc
abstract mixin class _$CatalogInstructorCopyWith<$Res> implements $InstructorCopyWith<$Res> {
  factory _$CatalogInstructorCopyWith(_CatalogInstructor value, $Res Function(_CatalogInstructor) _then) = __$CatalogInstructorCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String title, String bio, List<String> expertise, int? yearsTeaching, MediaFile? photo
});


@override $MediaFileCopyWith<$Res>? get photo;

}
/// @nodoc
class __$CatalogInstructorCopyWithImpl<$Res>
    implements _$CatalogInstructorCopyWith<$Res> {
  __$CatalogInstructorCopyWithImpl(this._self, this._then);

  final _CatalogInstructor _self;
  final $Res Function(_CatalogInstructor) _then;

/// Create a copy of Instructor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? title = null,Object? bio = null,Object? expertise = null,Object? yearsTeaching = freezed,Object? photo = freezed,}) {
  return _then(_CatalogInstructor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,expertise: null == expertise ? _self._expertise : expertise // ignore: cast_nullable_to_non_nullable
as List<String>,yearsTeaching: freezed == yearsTeaching ? _self.yearsTeaching : yearsTeaching // ignore: cast_nullable_to_non_nullable
as int?,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as MediaFile?,
  ));
}

/// Create a copy of Instructor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaFileCopyWith<$Res>? get photo {
    if (_self.photo == null) {
    return null;
  }

  return $MediaFileCopyWith<$Res>(_self.photo!, (value) {
    return _then(_self.copyWith(photo: value));
  });
}
}

// dart format on
