// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verified_certificate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CertificateSignatoryDto {

 String get name; String get title;
/// Create a copy of CertificateSignatoryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CertificateSignatoryDtoCopyWith<CertificateSignatoryDto> get copyWith => _$CertificateSignatoryDtoCopyWithImpl<CertificateSignatoryDto>(this as CertificateSignatoryDto, _$identity);

  /// Serializes this CertificateSignatoryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CertificateSignatoryDto&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,title);

@override
String toString() {
  return 'CertificateSignatoryDto(name: $name, title: $title)';
}


}

/// @nodoc
abstract mixin class $CertificateSignatoryDtoCopyWith<$Res>  {
  factory $CertificateSignatoryDtoCopyWith(CertificateSignatoryDto value, $Res Function(CertificateSignatoryDto) _then) = _$CertificateSignatoryDtoCopyWithImpl;
@useResult
$Res call({
 String name, String title
});




}
/// @nodoc
class _$CertificateSignatoryDtoCopyWithImpl<$Res>
    implements $CertificateSignatoryDtoCopyWith<$Res> {
  _$CertificateSignatoryDtoCopyWithImpl(this._self, this._then);

  final CertificateSignatoryDto _self;
  final $Res Function(CertificateSignatoryDto) _then;

/// Create a copy of CertificateSignatoryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? title = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CertificateSignatoryDto].
extension CertificateSignatoryDtoPatterns on CertificateSignatoryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CertificateSignatoryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CertificateSignatoryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CertificateSignatoryDto value)  $default,){
final _that = this;
switch (_that) {
case _CertificateSignatoryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CertificateSignatoryDto value)?  $default,){
final _that = this;
switch (_that) {
case _CertificateSignatoryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CertificateSignatoryDto() when $default != null:
return $default(_that.name,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String title)  $default,) {final _that = this;
switch (_that) {
case _CertificateSignatoryDto():
return $default(_that.name,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String title)?  $default,) {final _that = this;
switch (_that) {
case _CertificateSignatoryDto() when $default != null:
return $default(_that.name,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CertificateSignatoryDto implements CertificateSignatoryDto {
  const _CertificateSignatoryDto({required this.name, this.title = ''});
  factory _CertificateSignatoryDto.fromJson(Map<String, dynamic> json) => _$CertificateSignatoryDtoFromJson(json);

@override final  String name;
@override@JsonKey() final  String title;

/// Create a copy of CertificateSignatoryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CertificateSignatoryDtoCopyWith<_CertificateSignatoryDto> get copyWith => __$CertificateSignatoryDtoCopyWithImpl<_CertificateSignatoryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CertificateSignatoryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CertificateSignatoryDto&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,title);

@override
String toString() {
  return 'CertificateSignatoryDto(name: $name, title: $title)';
}


}

/// @nodoc
abstract mixin class _$CertificateSignatoryDtoCopyWith<$Res> implements $CertificateSignatoryDtoCopyWith<$Res> {
  factory _$CertificateSignatoryDtoCopyWith(_CertificateSignatoryDto value, $Res Function(_CertificateSignatoryDto) _then) = __$CertificateSignatoryDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, String title
});




}
/// @nodoc
class __$CertificateSignatoryDtoCopyWithImpl<$Res>
    implements _$CertificateSignatoryDtoCopyWith<$Res> {
  __$CertificateSignatoryDtoCopyWithImpl(this._self, this._then);

  final _CertificateSignatoryDto _self;
  final $Res Function(_CertificateSignatoryDto) _then;

/// Create a copy of CertificateSignatoryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? title = null,}) {
  return _then(_CertificateSignatoryDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CertificateTemplateDto {

 String get id; String get name; String get heading; String get statement;@JsonKey(unknownEnumValue: CertificateAccentValue.unknown) CertificateAccentValue get accent; List<CertificateSignatoryDto> get signatories; bool get showScore; bool get showHours;
/// Create a copy of CertificateTemplateDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CertificateTemplateDtoCopyWith<CertificateTemplateDto> get copyWith => _$CertificateTemplateDtoCopyWithImpl<CertificateTemplateDto>(this as CertificateTemplateDto, _$identity);

  /// Serializes this CertificateTemplateDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CertificateTemplateDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.heading, heading) || other.heading == heading)&&(identical(other.statement, statement) || other.statement == statement)&&(identical(other.accent, accent) || other.accent == accent)&&const DeepCollectionEquality().equals(other.signatories, signatories)&&(identical(other.showScore, showScore) || other.showScore == showScore)&&(identical(other.showHours, showHours) || other.showHours == showHours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,heading,statement,accent,const DeepCollectionEquality().hash(signatories),showScore,showHours);

@override
String toString() {
  return 'CertificateTemplateDto(id: $id, name: $name, heading: $heading, statement: $statement, accent: $accent, signatories: $signatories, showScore: $showScore, showHours: $showHours)';
}


}

/// @nodoc
abstract mixin class $CertificateTemplateDtoCopyWith<$Res>  {
  factory $CertificateTemplateDtoCopyWith(CertificateTemplateDto value, $Res Function(CertificateTemplateDto) _then) = _$CertificateTemplateDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String heading, String statement,@JsonKey(unknownEnumValue: CertificateAccentValue.unknown) CertificateAccentValue accent, List<CertificateSignatoryDto> signatories, bool showScore, bool showHours
});




}
/// @nodoc
class _$CertificateTemplateDtoCopyWithImpl<$Res>
    implements $CertificateTemplateDtoCopyWith<$Res> {
  _$CertificateTemplateDtoCopyWithImpl(this._self, this._then);

  final CertificateTemplateDto _self;
  final $Res Function(CertificateTemplateDto) _then;

/// Create a copy of CertificateTemplateDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? heading = null,Object? statement = null,Object? accent = null,Object? signatories = null,Object? showScore = null,Object? showHours = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,heading: null == heading ? _self.heading : heading // ignore: cast_nullable_to_non_nullable
as String,statement: null == statement ? _self.statement : statement // ignore: cast_nullable_to_non_nullable
as String,accent: null == accent ? _self.accent : accent // ignore: cast_nullable_to_non_nullable
as CertificateAccentValue,signatories: null == signatories ? _self.signatories : signatories // ignore: cast_nullable_to_non_nullable
as List<CertificateSignatoryDto>,showScore: null == showScore ? _self.showScore : showScore // ignore: cast_nullable_to_non_nullable
as bool,showHours: null == showHours ? _self.showHours : showHours // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CertificateTemplateDto].
extension CertificateTemplateDtoPatterns on CertificateTemplateDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CertificateTemplateDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CertificateTemplateDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CertificateTemplateDto value)  $default,){
final _that = this;
switch (_that) {
case _CertificateTemplateDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CertificateTemplateDto value)?  $default,){
final _that = this;
switch (_that) {
case _CertificateTemplateDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String heading,  String statement, @JsonKey(unknownEnumValue: CertificateAccentValue.unknown)  CertificateAccentValue accent,  List<CertificateSignatoryDto> signatories,  bool showScore,  bool showHours)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CertificateTemplateDto() when $default != null:
return $default(_that.id,_that.name,_that.heading,_that.statement,_that.accent,_that.signatories,_that.showScore,_that.showHours);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String heading,  String statement, @JsonKey(unknownEnumValue: CertificateAccentValue.unknown)  CertificateAccentValue accent,  List<CertificateSignatoryDto> signatories,  bool showScore,  bool showHours)  $default,) {final _that = this;
switch (_that) {
case _CertificateTemplateDto():
return $default(_that.id,_that.name,_that.heading,_that.statement,_that.accent,_that.signatories,_that.showScore,_that.showHours);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String heading,  String statement, @JsonKey(unknownEnumValue: CertificateAccentValue.unknown)  CertificateAccentValue accent,  List<CertificateSignatoryDto> signatories,  bool showScore,  bool showHours)?  $default,) {final _that = this;
switch (_that) {
case _CertificateTemplateDto() when $default != null:
return $default(_that.id,_that.name,_that.heading,_that.statement,_that.accent,_that.signatories,_that.showScore,_that.showHours);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CertificateTemplateDto implements CertificateTemplateDto {
  const _CertificateTemplateDto({required this.id, this.name = '', this.heading = '', this.statement = '', @JsonKey(unknownEnumValue: CertificateAccentValue.unknown) this.accent = CertificateAccentValue.emerald, final  List<CertificateSignatoryDto> signatories = const <CertificateSignatoryDto>[], this.showScore = false, this.showHours = false}): _signatories = signatories;
  factory _CertificateTemplateDto.fromJson(Map<String, dynamic> json) => _$CertificateTemplateDtoFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String heading;
@override@JsonKey() final  String statement;
@override@JsonKey(unknownEnumValue: CertificateAccentValue.unknown) final  CertificateAccentValue accent;
 final  List<CertificateSignatoryDto> _signatories;
@override@JsonKey() List<CertificateSignatoryDto> get signatories {
  if (_signatories is EqualUnmodifiableListView) return _signatories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_signatories);
}

@override@JsonKey() final  bool showScore;
@override@JsonKey() final  bool showHours;

/// Create a copy of CertificateTemplateDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CertificateTemplateDtoCopyWith<_CertificateTemplateDto> get copyWith => __$CertificateTemplateDtoCopyWithImpl<_CertificateTemplateDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CertificateTemplateDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CertificateTemplateDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.heading, heading) || other.heading == heading)&&(identical(other.statement, statement) || other.statement == statement)&&(identical(other.accent, accent) || other.accent == accent)&&const DeepCollectionEquality().equals(other._signatories, _signatories)&&(identical(other.showScore, showScore) || other.showScore == showScore)&&(identical(other.showHours, showHours) || other.showHours == showHours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,heading,statement,accent,const DeepCollectionEquality().hash(_signatories),showScore,showHours);

@override
String toString() {
  return 'CertificateTemplateDto(id: $id, name: $name, heading: $heading, statement: $statement, accent: $accent, signatories: $signatories, showScore: $showScore, showHours: $showHours)';
}


}

/// @nodoc
abstract mixin class _$CertificateTemplateDtoCopyWith<$Res> implements $CertificateTemplateDtoCopyWith<$Res> {
  factory _$CertificateTemplateDtoCopyWith(_CertificateTemplateDto value, $Res Function(_CertificateTemplateDto) _then) = __$CertificateTemplateDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String heading, String statement,@JsonKey(unknownEnumValue: CertificateAccentValue.unknown) CertificateAccentValue accent, List<CertificateSignatoryDto> signatories, bool showScore, bool showHours
});




}
/// @nodoc
class __$CertificateTemplateDtoCopyWithImpl<$Res>
    implements _$CertificateTemplateDtoCopyWith<$Res> {
  __$CertificateTemplateDtoCopyWithImpl(this._self, this._then);

  final _CertificateTemplateDto _self;
  final $Res Function(_CertificateTemplateDto) _then;

/// Create a copy of CertificateTemplateDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? heading = null,Object? statement = null,Object? accent = null,Object? signatories = null,Object? showScore = null,Object? showHours = null,}) {
  return _then(_CertificateTemplateDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,heading: null == heading ? _self.heading : heading // ignore: cast_nullable_to_non_nullable
as String,statement: null == statement ? _self.statement : statement // ignore: cast_nullable_to_non_nullable
as String,accent: null == accent ? _self.accent : accent // ignore: cast_nullable_to_non_nullable
as CertificateAccentValue,signatories: null == signatories ? _self._signatories : signatories // ignore: cast_nullable_to_non_nullable
as List<CertificateSignatoryDto>,showScore: null == showScore ? _self.showScore : showScore // ignore: cast_nullable_to_non_nullable
as bool,showHours: null == showHours ? _self.showHours : showHours // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$IssuedCertificateDto {

 String get id; String get credentialId; String get title;@JsonKey(unknownEnumValue: IssuedCertificateStatus.unknown) IssuedCertificateStatus get status;@UtcDateTimeConverter() DateTime get completedAt;@NullableUtcDateTimeConverter() DateTime? get issuedAt;@NullableUtcDateTimeConverter() DateTime? get revokedAt; String? get revokedReason; int? get finalScore;/// The academy rounds study hours to the nearest half hour, so this is not always whole.
 num get hours;
/// Create a copy of IssuedCertificateDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssuedCertificateDtoCopyWith<IssuedCertificateDto> get copyWith => _$IssuedCertificateDtoCopyWithImpl<IssuedCertificateDto>(this as IssuedCertificateDto, _$identity);

  /// Serializes this IssuedCertificateDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssuedCertificateDto&&(identical(other.id, id) || other.id == id)&&(identical(other.credentialId, credentialId) || other.credentialId == credentialId)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.revokedAt, revokedAt) || other.revokedAt == revokedAt)&&(identical(other.revokedReason, revokedReason) || other.revokedReason == revokedReason)&&(identical(other.finalScore, finalScore) || other.finalScore == finalScore)&&(identical(other.hours, hours) || other.hours == hours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,credentialId,title,status,completedAt,issuedAt,revokedAt,revokedReason,finalScore,hours);

@override
String toString() {
  return 'IssuedCertificateDto(id: $id, credentialId: $credentialId, title: $title, status: $status, completedAt: $completedAt, issuedAt: $issuedAt, revokedAt: $revokedAt, revokedReason: $revokedReason, finalScore: $finalScore, hours: $hours)';
}


}

/// @nodoc
abstract mixin class $IssuedCertificateDtoCopyWith<$Res>  {
  factory $IssuedCertificateDtoCopyWith(IssuedCertificateDto value, $Res Function(IssuedCertificateDto) _then) = _$IssuedCertificateDtoCopyWithImpl;
@useResult
$Res call({
 String id, String credentialId, String title,@JsonKey(unknownEnumValue: IssuedCertificateStatus.unknown) IssuedCertificateStatus status,@UtcDateTimeConverter() DateTime completedAt,@NullableUtcDateTimeConverter() DateTime? issuedAt,@NullableUtcDateTimeConverter() DateTime? revokedAt, String? revokedReason, int? finalScore, num hours
});




}
/// @nodoc
class _$IssuedCertificateDtoCopyWithImpl<$Res>
    implements $IssuedCertificateDtoCopyWith<$Res> {
  _$IssuedCertificateDtoCopyWithImpl(this._self, this._then);

  final IssuedCertificateDto _self;
  final $Res Function(IssuedCertificateDto) _then;

/// Create a copy of IssuedCertificateDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? credentialId = null,Object? title = null,Object? status = null,Object? completedAt = null,Object? issuedAt = freezed,Object? revokedAt = freezed,Object? revokedReason = freezed,Object? finalScore = freezed,Object? hours = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,credentialId: null == credentialId ? _self.credentialId : credentialId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IssuedCertificateStatus,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,revokedAt: freezed == revokedAt ? _self.revokedAt : revokedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,revokedReason: freezed == revokedReason ? _self.revokedReason : revokedReason // ignore: cast_nullable_to_non_nullable
as String?,finalScore: freezed == finalScore ? _self.finalScore : finalScore // ignore: cast_nullable_to_non_nullable
as int?,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [IssuedCertificateDto].
extension IssuedCertificateDtoPatterns on IssuedCertificateDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssuedCertificateDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssuedCertificateDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssuedCertificateDto value)  $default,){
final _that = this;
switch (_that) {
case _IssuedCertificateDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssuedCertificateDto value)?  $default,){
final _that = this;
switch (_that) {
case _IssuedCertificateDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String credentialId,  String title, @JsonKey(unknownEnumValue: IssuedCertificateStatus.unknown)  IssuedCertificateStatus status, @UtcDateTimeConverter()  DateTime completedAt, @NullableUtcDateTimeConverter()  DateTime? issuedAt, @NullableUtcDateTimeConverter()  DateTime? revokedAt,  String? revokedReason,  int? finalScore,  num hours)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssuedCertificateDto() when $default != null:
return $default(_that.id,_that.credentialId,_that.title,_that.status,_that.completedAt,_that.issuedAt,_that.revokedAt,_that.revokedReason,_that.finalScore,_that.hours);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String credentialId,  String title, @JsonKey(unknownEnumValue: IssuedCertificateStatus.unknown)  IssuedCertificateStatus status, @UtcDateTimeConverter()  DateTime completedAt, @NullableUtcDateTimeConverter()  DateTime? issuedAt, @NullableUtcDateTimeConverter()  DateTime? revokedAt,  String? revokedReason,  int? finalScore,  num hours)  $default,) {final _that = this;
switch (_that) {
case _IssuedCertificateDto():
return $default(_that.id,_that.credentialId,_that.title,_that.status,_that.completedAt,_that.issuedAt,_that.revokedAt,_that.revokedReason,_that.finalScore,_that.hours);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String credentialId,  String title, @JsonKey(unknownEnumValue: IssuedCertificateStatus.unknown)  IssuedCertificateStatus status, @UtcDateTimeConverter()  DateTime completedAt, @NullableUtcDateTimeConverter()  DateTime? issuedAt, @NullableUtcDateTimeConverter()  DateTime? revokedAt,  String? revokedReason,  int? finalScore,  num hours)?  $default,) {final _that = this;
switch (_that) {
case _IssuedCertificateDto() when $default != null:
return $default(_that.id,_that.credentialId,_that.title,_that.status,_that.completedAt,_that.issuedAt,_that.revokedAt,_that.revokedReason,_that.finalScore,_that.hours);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssuedCertificateDto implements IssuedCertificateDto {
  const _IssuedCertificateDto({required this.id, required this.credentialId, this.title = '', @JsonKey(unknownEnumValue: IssuedCertificateStatus.unknown) this.status = IssuedCertificateStatus.issued, @UtcDateTimeConverter() required this.completedAt, @NullableUtcDateTimeConverter() this.issuedAt, @NullableUtcDateTimeConverter() this.revokedAt, this.revokedReason, this.finalScore, this.hours = 0});
  factory _IssuedCertificateDto.fromJson(Map<String, dynamic> json) => _$IssuedCertificateDtoFromJson(json);

@override final  String id;
@override final  String credentialId;
@override@JsonKey() final  String title;
@override@JsonKey(unknownEnumValue: IssuedCertificateStatus.unknown) final  IssuedCertificateStatus status;
@override@UtcDateTimeConverter() final  DateTime completedAt;
@override@NullableUtcDateTimeConverter() final  DateTime? issuedAt;
@override@NullableUtcDateTimeConverter() final  DateTime? revokedAt;
@override final  String? revokedReason;
@override final  int? finalScore;
/// The academy rounds study hours to the nearest half hour, so this is not always whole.
@override@JsonKey() final  num hours;

/// Create a copy of IssuedCertificateDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssuedCertificateDtoCopyWith<_IssuedCertificateDto> get copyWith => __$IssuedCertificateDtoCopyWithImpl<_IssuedCertificateDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssuedCertificateDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssuedCertificateDto&&(identical(other.id, id) || other.id == id)&&(identical(other.credentialId, credentialId) || other.credentialId == credentialId)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.revokedAt, revokedAt) || other.revokedAt == revokedAt)&&(identical(other.revokedReason, revokedReason) || other.revokedReason == revokedReason)&&(identical(other.finalScore, finalScore) || other.finalScore == finalScore)&&(identical(other.hours, hours) || other.hours == hours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,credentialId,title,status,completedAt,issuedAt,revokedAt,revokedReason,finalScore,hours);

@override
String toString() {
  return 'IssuedCertificateDto(id: $id, credentialId: $credentialId, title: $title, status: $status, completedAt: $completedAt, issuedAt: $issuedAt, revokedAt: $revokedAt, revokedReason: $revokedReason, finalScore: $finalScore, hours: $hours)';
}


}

/// @nodoc
abstract mixin class _$IssuedCertificateDtoCopyWith<$Res> implements $IssuedCertificateDtoCopyWith<$Res> {
  factory _$IssuedCertificateDtoCopyWith(_IssuedCertificateDto value, $Res Function(_IssuedCertificateDto) _then) = __$IssuedCertificateDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String credentialId, String title,@JsonKey(unknownEnumValue: IssuedCertificateStatus.unknown) IssuedCertificateStatus status,@UtcDateTimeConverter() DateTime completedAt,@NullableUtcDateTimeConverter() DateTime? issuedAt,@NullableUtcDateTimeConverter() DateTime? revokedAt, String? revokedReason, int? finalScore, num hours
});




}
/// @nodoc
class __$IssuedCertificateDtoCopyWithImpl<$Res>
    implements _$IssuedCertificateDtoCopyWith<$Res> {
  __$IssuedCertificateDtoCopyWithImpl(this._self, this._then);

  final _IssuedCertificateDto _self;
  final $Res Function(_IssuedCertificateDto) _then;

/// Create a copy of IssuedCertificateDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? credentialId = null,Object? title = null,Object? status = null,Object? completedAt = null,Object? issuedAt = freezed,Object? revokedAt = freezed,Object? revokedReason = freezed,Object? finalScore = freezed,Object? hours = null,}) {
  return _then(_IssuedCertificateDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,credentialId: null == credentialId ? _self.credentialId : credentialId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IssuedCertificateStatus,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,revokedAt: freezed == revokedAt ? _self.revokedAt : revokedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,revokedReason: freezed == revokedReason ? _self.revokedReason : revokedReason // ignore: cast_nullable_to_non_nullable
as String?,finalScore: freezed == finalScore ? _self.finalScore : finalScore // ignore: cast_nullable_to_non_nullable
as int?,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}


/// @nodoc
mixin _$CertificateHolder {

 String get name; String get city;
/// Create a copy of CertificateHolder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CertificateHolderCopyWith<CertificateHolder> get copyWith => _$CertificateHolderCopyWithImpl<CertificateHolder>(this as CertificateHolder, _$identity);

  /// Serializes this CertificateHolder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CertificateHolder&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,city);

@override
String toString() {
  return 'CertificateHolder(name: $name, city: $city)';
}


}

/// @nodoc
abstract mixin class $CertificateHolderCopyWith<$Res>  {
  factory $CertificateHolderCopyWith(CertificateHolder value, $Res Function(CertificateHolder) _then) = _$CertificateHolderCopyWithImpl;
@useResult
$Res call({
 String name, String city
});




}
/// @nodoc
class _$CertificateHolderCopyWithImpl<$Res>
    implements $CertificateHolderCopyWith<$Res> {
  _$CertificateHolderCopyWithImpl(this._self, this._then);

  final CertificateHolder _self;
  final $Res Function(CertificateHolder) _then;

/// Create a copy of CertificateHolder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? city = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CertificateHolder].
extension CertificateHolderPatterns on CertificateHolder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CertificateHolder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CertificateHolder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CertificateHolder value)  $default,){
final _that = this;
switch (_that) {
case _CertificateHolder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CertificateHolder value)?  $default,){
final _that = this;
switch (_that) {
case _CertificateHolder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String city)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CertificateHolder() when $default != null:
return $default(_that.name,_that.city);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String city)  $default,) {final _that = this;
switch (_that) {
case _CertificateHolder():
return $default(_that.name,_that.city);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String city)?  $default,) {final _that = this;
switch (_that) {
case _CertificateHolder() when $default != null:
return $default(_that.name,_that.city);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CertificateHolder implements CertificateHolder {
  const _CertificateHolder({required this.name, this.city = ''});
  factory _CertificateHolder.fromJson(Map<String, dynamic> json) => _$CertificateHolderFromJson(json);

@override final  String name;
@override@JsonKey() final  String city;

/// Create a copy of CertificateHolder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CertificateHolderCopyWith<_CertificateHolder> get copyWith => __$CertificateHolderCopyWithImpl<_CertificateHolder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CertificateHolderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CertificateHolder&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,city);

@override
String toString() {
  return 'CertificateHolder(name: $name, city: $city)';
}


}

/// @nodoc
abstract mixin class _$CertificateHolderCopyWith<$Res> implements $CertificateHolderCopyWith<$Res> {
  factory _$CertificateHolderCopyWith(_CertificateHolder value, $Res Function(_CertificateHolder) _then) = __$CertificateHolderCopyWithImpl;
@override @useResult
$Res call({
 String name, String city
});




}
/// @nodoc
class __$CertificateHolderCopyWithImpl<$Res>
    implements _$CertificateHolderCopyWith<$Res> {
  __$CertificateHolderCopyWithImpl(this._self, this._then);

  final _CertificateHolder _self;
  final $Res Function(_CertificateHolder) _then;

/// Create a copy of CertificateHolder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? city = null,}) {
  return _then(_CertificateHolder(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$VerifiedCertificate {

 IssuedCertificateDto get certificate; CertificateHolder get student; String get courseTitle; String get levelTitle; CertificateTemplateDto? get template;@NullableUtcDateTimeConverter() DateTime? get validUntil; bool get expired;
/// Create a copy of VerifiedCertificate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifiedCertificateCopyWith<VerifiedCertificate> get copyWith => _$VerifiedCertificateCopyWithImpl<VerifiedCertificate>(this as VerifiedCertificate, _$identity);

  /// Serializes this VerifiedCertificate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifiedCertificate&&(identical(other.certificate, certificate) || other.certificate == certificate)&&(identical(other.student, student) || other.student == student)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.levelTitle, levelTitle) || other.levelTitle == levelTitle)&&(identical(other.template, template) || other.template == template)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.expired, expired) || other.expired == expired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,certificate,student,courseTitle,levelTitle,template,validUntil,expired);

@override
String toString() {
  return 'VerifiedCertificate(certificate: $certificate, student: $student, courseTitle: $courseTitle, levelTitle: $levelTitle, template: $template, validUntil: $validUntil, expired: $expired)';
}


}

/// @nodoc
abstract mixin class $VerifiedCertificateCopyWith<$Res>  {
  factory $VerifiedCertificateCopyWith(VerifiedCertificate value, $Res Function(VerifiedCertificate) _then) = _$VerifiedCertificateCopyWithImpl;
@useResult
$Res call({
 IssuedCertificateDto certificate, CertificateHolder student, String courseTitle, String levelTitle, CertificateTemplateDto? template,@NullableUtcDateTimeConverter() DateTime? validUntil, bool expired
});


$IssuedCertificateDtoCopyWith<$Res> get certificate;$CertificateHolderCopyWith<$Res> get student;$CertificateTemplateDtoCopyWith<$Res>? get template;

}
/// @nodoc
class _$VerifiedCertificateCopyWithImpl<$Res>
    implements $VerifiedCertificateCopyWith<$Res> {
  _$VerifiedCertificateCopyWithImpl(this._self, this._then);

  final VerifiedCertificate _self;
  final $Res Function(VerifiedCertificate) _then;

/// Create a copy of VerifiedCertificate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? certificate = null,Object? student = null,Object? courseTitle = null,Object? levelTitle = null,Object? template = freezed,Object? validUntil = freezed,Object? expired = null,}) {
  return _then(_self.copyWith(
certificate: null == certificate ? _self.certificate : certificate // ignore: cast_nullable_to_non_nullable
as IssuedCertificateDto,student: null == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as CertificateHolder,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,levelTitle: null == levelTitle ? _self.levelTitle : levelTitle // ignore: cast_nullable_to_non_nullable
as String,template: freezed == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as CertificateTemplateDto?,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,expired: null == expired ? _self.expired : expired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of VerifiedCertificate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuedCertificateDtoCopyWith<$Res> get certificate {
  
  return $IssuedCertificateDtoCopyWith<$Res>(_self.certificate, (value) {
    return _then(_self.copyWith(certificate: value));
  });
}/// Create a copy of VerifiedCertificate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CertificateHolderCopyWith<$Res> get student {
  
  return $CertificateHolderCopyWith<$Res>(_self.student, (value) {
    return _then(_self.copyWith(student: value));
  });
}/// Create a copy of VerifiedCertificate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CertificateTemplateDtoCopyWith<$Res>? get template {
    if (_self.template == null) {
    return null;
  }

  return $CertificateTemplateDtoCopyWith<$Res>(_self.template!, (value) {
    return _then(_self.copyWith(template: value));
  });
}
}


/// Adds pattern-matching-related methods to [VerifiedCertificate].
extension VerifiedCertificatePatterns on VerifiedCertificate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerifiedCertificate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerifiedCertificate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerifiedCertificate value)  $default,){
final _that = this;
switch (_that) {
case _VerifiedCertificate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerifiedCertificate value)?  $default,){
final _that = this;
switch (_that) {
case _VerifiedCertificate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( IssuedCertificateDto certificate,  CertificateHolder student,  String courseTitle,  String levelTitle,  CertificateTemplateDto? template, @NullableUtcDateTimeConverter()  DateTime? validUntil,  bool expired)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerifiedCertificate() when $default != null:
return $default(_that.certificate,_that.student,_that.courseTitle,_that.levelTitle,_that.template,_that.validUntil,_that.expired);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( IssuedCertificateDto certificate,  CertificateHolder student,  String courseTitle,  String levelTitle,  CertificateTemplateDto? template, @NullableUtcDateTimeConverter()  DateTime? validUntil,  bool expired)  $default,) {final _that = this;
switch (_that) {
case _VerifiedCertificate():
return $default(_that.certificate,_that.student,_that.courseTitle,_that.levelTitle,_that.template,_that.validUntil,_that.expired);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( IssuedCertificateDto certificate,  CertificateHolder student,  String courseTitle,  String levelTitle,  CertificateTemplateDto? template, @NullableUtcDateTimeConverter()  DateTime? validUntil,  bool expired)?  $default,) {final _that = this;
switch (_that) {
case _VerifiedCertificate() when $default != null:
return $default(_that.certificate,_that.student,_that.courseTitle,_that.levelTitle,_that.template,_that.validUntil,_that.expired);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerifiedCertificate extends VerifiedCertificate {
  const _VerifiedCertificate({required this.certificate, required this.student, this.courseTitle = '', this.levelTitle = '', this.template, @NullableUtcDateTimeConverter() this.validUntil, this.expired = false}): super._();
  factory _VerifiedCertificate.fromJson(Map<String, dynamic> json) => _$VerifiedCertificateFromJson(json);

@override final  IssuedCertificateDto certificate;
@override final  CertificateHolder student;
@override@JsonKey() final  String courseTitle;
@override@JsonKey() final  String levelTitle;
@override final  CertificateTemplateDto? template;
@override@NullableUtcDateTimeConverter() final  DateTime? validUntil;
@override@JsonKey() final  bool expired;

/// Create a copy of VerifiedCertificate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerifiedCertificateCopyWith<_VerifiedCertificate> get copyWith => __$VerifiedCertificateCopyWithImpl<_VerifiedCertificate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerifiedCertificateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerifiedCertificate&&(identical(other.certificate, certificate) || other.certificate == certificate)&&(identical(other.student, student) || other.student == student)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.levelTitle, levelTitle) || other.levelTitle == levelTitle)&&(identical(other.template, template) || other.template == template)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.expired, expired) || other.expired == expired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,certificate,student,courseTitle,levelTitle,template,validUntil,expired);

@override
String toString() {
  return 'VerifiedCertificate(certificate: $certificate, student: $student, courseTitle: $courseTitle, levelTitle: $levelTitle, template: $template, validUntil: $validUntil, expired: $expired)';
}


}

/// @nodoc
abstract mixin class _$VerifiedCertificateCopyWith<$Res> implements $VerifiedCertificateCopyWith<$Res> {
  factory _$VerifiedCertificateCopyWith(_VerifiedCertificate value, $Res Function(_VerifiedCertificate) _then) = __$VerifiedCertificateCopyWithImpl;
@override @useResult
$Res call({
 IssuedCertificateDto certificate, CertificateHolder student, String courseTitle, String levelTitle, CertificateTemplateDto? template,@NullableUtcDateTimeConverter() DateTime? validUntil, bool expired
});


@override $IssuedCertificateDtoCopyWith<$Res> get certificate;@override $CertificateHolderCopyWith<$Res> get student;@override $CertificateTemplateDtoCopyWith<$Res>? get template;

}
/// @nodoc
class __$VerifiedCertificateCopyWithImpl<$Res>
    implements _$VerifiedCertificateCopyWith<$Res> {
  __$VerifiedCertificateCopyWithImpl(this._self, this._then);

  final _VerifiedCertificate _self;
  final $Res Function(_VerifiedCertificate) _then;

/// Create a copy of VerifiedCertificate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? certificate = null,Object? student = null,Object? courseTitle = null,Object? levelTitle = null,Object? template = freezed,Object? validUntil = freezed,Object? expired = null,}) {
  return _then(_VerifiedCertificate(
certificate: null == certificate ? _self.certificate : certificate // ignore: cast_nullable_to_non_nullable
as IssuedCertificateDto,student: null == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as CertificateHolder,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,levelTitle: null == levelTitle ? _self.levelTitle : levelTitle // ignore: cast_nullable_to_non_nullable
as String,template: freezed == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as CertificateTemplateDto?,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,expired: null == expired ? _self.expired : expired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of VerifiedCertificate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuedCertificateDtoCopyWith<$Res> get certificate {
  
  return $IssuedCertificateDtoCopyWith<$Res>(_self.certificate, (value) {
    return _then(_self.copyWith(certificate: value));
  });
}/// Create a copy of VerifiedCertificate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CertificateHolderCopyWith<$Res> get student {
  
  return $CertificateHolderCopyWith<$Res>(_self.student, (value) {
    return _then(_self.copyWith(student: value));
  });
}/// Create a copy of VerifiedCertificate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CertificateTemplateDtoCopyWith<$Res>? get template {
    if (_self.template == null) {
    return null;
  }

  return $CertificateTemplateDtoCopyWith<$Res>(_self.template!, (value) {
    return _then(_self.copyWith(template: value));
  });
}
}

// dart format on
