// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'certificate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CertificateCriterion {

 String get id; String get label; double get current;/// The route calls this `required`, which is a reserved name here.
@JsonKey(name: 'required') double get needed;/// "%", "sessions" — how to read the numbers.
 String? get unit;
/// Create a copy of CertificateCriterion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CertificateCriterionCopyWith<CertificateCriterion> get copyWith => _$CertificateCriterionCopyWithImpl<CertificateCriterion>(this as CertificateCriterion, _$identity);

  /// Serializes this CertificateCriterion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CertificateCriterion&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.current, current) || other.current == current)&&(identical(other.needed, needed) || other.needed == needed)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,current,needed,unit);

@override
String toString() {
  return 'CertificateCriterion(id: $id, label: $label, current: $current, needed: $needed, unit: $unit)';
}


}

/// @nodoc
abstract mixin class $CertificateCriterionCopyWith<$Res>  {
  factory $CertificateCriterionCopyWith(CertificateCriterion value, $Res Function(CertificateCriterion) _then) = _$CertificateCriterionCopyWithImpl;
@useResult
$Res call({
 String id, String label, double current,@JsonKey(name: 'required') double needed, String? unit
});




}
/// @nodoc
class _$CertificateCriterionCopyWithImpl<$Res>
    implements $CertificateCriterionCopyWith<$Res> {
  _$CertificateCriterionCopyWithImpl(this._self, this._then);

  final CertificateCriterion _self;
  final $Res Function(CertificateCriterion) _then;

/// Create a copy of CertificateCriterion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? current = null,Object? needed = null,Object? unit = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as double,needed: null == needed ? _self.needed : needed // ignore: cast_nullable_to_non_nullable
as double,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CertificateCriterion].
extension CertificateCriterionPatterns on CertificateCriterion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CertificateCriterion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CertificateCriterion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CertificateCriterion value)  $default,){
final _that = this;
switch (_that) {
case _CertificateCriterion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CertificateCriterion value)?  $default,){
final _that = this;
switch (_that) {
case _CertificateCriterion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  double current, @JsonKey(name: 'required')  double needed,  String? unit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CertificateCriterion() when $default != null:
return $default(_that.id,_that.label,_that.current,_that.needed,_that.unit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  double current, @JsonKey(name: 'required')  double needed,  String? unit)  $default,) {final _that = this;
switch (_that) {
case _CertificateCriterion():
return $default(_that.id,_that.label,_that.current,_that.needed,_that.unit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  double current, @JsonKey(name: 'required')  double needed,  String? unit)?  $default,) {final _that = this;
switch (_that) {
case _CertificateCriterion() when $default != null:
return $default(_that.id,_that.label,_that.current,_that.needed,_that.unit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CertificateCriterion extends CertificateCriterion {
  const _CertificateCriterion({this.id = '', this.label = '', this.current = 0, @JsonKey(name: 'required') this.needed = 0, this.unit}): super._();
  factory _CertificateCriterion.fromJson(Map<String, dynamic> json) => _$CertificateCriterionFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String label;
@override@JsonKey() final  double current;
/// The route calls this `required`, which is a reserved name here.
@override@JsonKey(name: 'required') final  double needed;
/// "%", "sessions" — how to read the numbers.
@override final  String? unit;

/// Create a copy of CertificateCriterion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CertificateCriterionCopyWith<_CertificateCriterion> get copyWith => __$CertificateCriterionCopyWithImpl<_CertificateCriterion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CertificateCriterionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CertificateCriterion&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.current, current) || other.current == current)&&(identical(other.needed, needed) || other.needed == needed)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,current,needed,unit);

@override
String toString() {
  return 'CertificateCriterion(id: $id, label: $label, current: $current, needed: $needed, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$CertificateCriterionCopyWith<$Res> implements $CertificateCriterionCopyWith<$Res> {
  factory _$CertificateCriterionCopyWith(_CertificateCriterion value, $Res Function(_CertificateCriterion) _then) = __$CertificateCriterionCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, double current,@JsonKey(name: 'required') double needed, String? unit
});




}
/// @nodoc
class __$CertificateCriterionCopyWithImpl<$Res>
    implements _$CertificateCriterionCopyWith<$Res> {
  __$CertificateCriterionCopyWithImpl(this._self, this._then);

  final _CertificateCriterion _self;
  final $Res Function(_CertificateCriterion) _then;

/// Create a copy of CertificateCriterion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? current = null,Object? needed = null,Object? unit = freezed,}) {
  return _then(_CertificateCriterion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as double,needed: null == needed ? _self.needed : needed // ignore: cast_nullable_to_non_nullable
as double,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CertificateRecord {

 String get id; String get courseId; String get title; List<CertificateCriterion> get criteria;@NullableUtcDateTimeConverter() DateTime? get issuedAt;/// Set once the academy has issued it.
 String? get credentialId;
/// Create a copy of CertificateRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CertificateRecordCopyWith<CertificateRecord> get copyWith => _$CertificateRecordCopyWithImpl<CertificateRecord>(this as CertificateRecord, _$identity);

  /// Serializes this CertificateRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CertificateRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.criteria, criteria)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.credentialId, credentialId) || other.credentialId == credentialId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,courseId,title,const DeepCollectionEquality().hash(criteria),issuedAt,credentialId);

@override
String toString() {
  return 'CertificateRecord(id: $id, courseId: $courseId, title: $title, criteria: $criteria, issuedAt: $issuedAt, credentialId: $credentialId)';
}


}

/// @nodoc
abstract mixin class $CertificateRecordCopyWith<$Res>  {
  factory $CertificateRecordCopyWith(CertificateRecord value, $Res Function(CertificateRecord) _then) = _$CertificateRecordCopyWithImpl;
@useResult
$Res call({
 String id, String courseId, String title, List<CertificateCriterion> criteria,@NullableUtcDateTimeConverter() DateTime? issuedAt, String? credentialId
});




}
/// @nodoc
class _$CertificateRecordCopyWithImpl<$Res>
    implements $CertificateRecordCopyWith<$Res> {
  _$CertificateRecordCopyWithImpl(this._self, this._then);

  final CertificateRecord _self;
  final $Res Function(CertificateRecord) _then;

/// Create a copy of CertificateRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? courseId = null,Object? title = null,Object? criteria = null,Object? issuedAt = freezed,Object? credentialId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,criteria: null == criteria ? _self.criteria : criteria // ignore: cast_nullable_to_non_nullable
as List<CertificateCriterion>,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,credentialId: freezed == credentialId ? _self.credentialId : credentialId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CertificateRecord].
extension CertificateRecordPatterns on CertificateRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CertificateRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CertificateRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CertificateRecord value)  $default,){
final _that = this;
switch (_that) {
case _CertificateRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CertificateRecord value)?  $default,){
final _that = this;
switch (_that) {
case _CertificateRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String courseId,  String title,  List<CertificateCriterion> criteria, @NullableUtcDateTimeConverter()  DateTime? issuedAt,  String? credentialId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CertificateRecord() when $default != null:
return $default(_that.id,_that.courseId,_that.title,_that.criteria,_that.issuedAt,_that.credentialId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String courseId,  String title,  List<CertificateCriterion> criteria, @NullableUtcDateTimeConverter()  DateTime? issuedAt,  String? credentialId)  $default,) {final _that = this;
switch (_that) {
case _CertificateRecord():
return $default(_that.id,_that.courseId,_that.title,_that.criteria,_that.issuedAt,_that.credentialId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String courseId,  String title,  List<CertificateCriterion> criteria, @NullableUtcDateTimeConverter()  DateTime? issuedAt,  String? credentialId)?  $default,) {final _that = this;
switch (_that) {
case _CertificateRecord() when $default != null:
return $default(_that.id,_that.courseId,_that.title,_that.criteria,_that.issuedAt,_that.credentialId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CertificateRecord extends CertificateRecord {
  const _CertificateRecord({this.id = '', this.courseId = '', this.title = '', final  List<CertificateCriterion> criteria = const <CertificateCriterion>[], @NullableUtcDateTimeConverter() this.issuedAt, this.credentialId}): _criteria = criteria,super._();
  factory _CertificateRecord.fromJson(Map<String, dynamic> json) => _$CertificateRecordFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String courseId;
@override@JsonKey() final  String title;
 final  List<CertificateCriterion> _criteria;
@override@JsonKey() List<CertificateCriterion> get criteria {
  if (_criteria is EqualUnmodifiableListView) return _criteria;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_criteria);
}

@override@NullableUtcDateTimeConverter() final  DateTime? issuedAt;
/// Set once the academy has issued it.
@override final  String? credentialId;

/// Create a copy of CertificateRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CertificateRecordCopyWith<_CertificateRecord> get copyWith => __$CertificateRecordCopyWithImpl<_CertificateRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CertificateRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CertificateRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._criteria, _criteria)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.credentialId, credentialId) || other.credentialId == credentialId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,courseId,title,const DeepCollectionEquality().hash(_criteria),issuedAt,credentialId);

@override
String toString() {
  return 'CertificateRecord(id: $id, courseId: $courseId, title: $title, criteria: $criteria, issuedAt: $issuedAt, credentialId: $credentialId)';
}


}

/// @nodoc
abstract mixin class _$CertificateRecordCopyWith<$Res> implements $CertificateRecordCopyWith<$Res> {
  factory _$CertificateRecordCopyWith(_CertificateRecord value, $Res Function(_CertificateRecord) _then) = __$CertificateRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, String courseId, String title, List<CertificateCriterion> criteria,@NullableUtcDateTimeConverter() DateTime? issuedAt, String? credentialId
});




}
/// @nodoc
class __$CertificateRecordCopyWithImpl<$Res>
    implements _$CertificateRecordCopyWith<$Res> {
  __$CertificateRecordCopyWithImpl(this._self, this._then);

  final _CertificateRecord _self;
  final $Res Function(_CertificateRecord) _then;

/// Create a copy of CertificateRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? courseId = null,Object? title = null,Object? criteria = null,Object? issuedAt = freezed,Object? credentialId = freezed,}) {
  return _then(_CertificateRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,criteria: null == criteria ? _self._criteria : criteria // ignore: cast_nullable_to_non_nullable
as List<CertificateCriterion>,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,credentialId: freezed == credentialId ? _self.credentialId : credentialId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TemplateSignatory {

 String get name; String get title;
/// Create a copy of TemplateSignatory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TemplateSignatoryCopyWith<TemplateSignatory> get copyWith => _$TemplateSignatoryCopyWithImpl<TemplateSignatory>(this as TemplateSignatory, _$identity);

  /// Serializes this TemplateSignatory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TemplateSignatory&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,title);

@override
String toString() {
  return 'TemplateSignatory(name: $name, title: $title)';
}


}

/// @nodoc
abstract mixin class $TemplateSignatoryCopyWith<$Res>  {
  factory $TemplateSignatoryCopyWith(TemplateSignatory value, $Res Function(TemplateSignatory) _then) = _$TemplateSignatoryCopyWithImpl;
@useResult
$Res call({
 String name, String title
});




}
/// @nodoc
class _$TemplateSignatoryCopyWithImpl<$Res>
    implements $TemplateSignatoryCopyWith<$Res> {
  _$TemplateSignatoryCopyWithImpl(this._self, this._then);

  final TemplateSignatory _self;
  final $Res Function(TemplateSignatory) _then;

/// Create a copy of TemplateSignatory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? title = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TemplateSignatory].
extension TemplateSignatoryPatterns on TemplateSignatory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TemplateSignatory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TemplateSignatory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TemplateSignatory value)  $default,){
final _that = this;
switch (_that) {
case _TemplateSignatory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TemplateSignatory value)?  $default,){
final _that = this;
switch (_that) {
case _TemplateSignatory() when $default != null:
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
case _TemplateSignatory() when $default != null:
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
case _TemplateSignatory():
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
case _TemplateSignatory() when $default != null:
return $default(_that.name,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TemplateSignatory implements TemplateSignatory {
  const _TemplateSignatory({this.name = '', this.title = ''});
  factory _TemplateSignatory.fromJson(Map<String, dynamic> json) => _$TemplateSignatoryFromJson(json);

@override@JsonKey() final  String name;
@override@JsonKey() final  String title;

/// Create a copy of TemplateSignatory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TemplateSignatoryCopyWith<_TemplateSignatory> get copyWith => __$TemplateSignatoryCopyWithImpl<_TemplateSignatory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TemplateSignatoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TemplateSignatory&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,title);

@override
String toString() {
  return 'TemplateSignatory(name: $name, title: $title)';
}


}

/// @nodoc
abstract mixin class _$TemplateSignatoryCopyWith<$Res> implements $TemplateSignatoryCopyWith<$Res> {
  factory _$TemplateSignatoryCopyWith(_TemplateSignatory value, $Res Function(_TemplateSignatory) _then) = __$TemplateSignatoryCopyWithImpl;
@override @useResult
$Res call({
 String name, String title
});




}
/// @nodoc
class __$TemplateSignatoryCopyWithImpl<$Res>
    implements _$TemplateSignatoryCopyWith<$Res> {
  __$TemplateSignatoryCopyWithImpl(this._self, this._then);

  final _TemplateSignatory _self;
  final $Res Function(_TemplateSignatory) _then;

/// Create a copy of TemplateSignatory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? title = null,}) {
  return _then(_TemplateSignatory(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CertificateTemplateInfo {

 String get id; String get name; String get style; String get accent; String get heading;/// The line under the learner's name, before the course title.
 String get statement; List<TemplateSignatory> get signatories; bool get showScore; bool get showHours;
/// Create a copy of CertificateTemplateInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CertificateTemplateInfoCopyWith<CertificateTemplateInfo> get copyWith => _$CertificateTemplateInfoCopyWithImpl<CertificateTemplateInfo>(this as CertificateTemplateInfo, _$identity);

  /// Serializes this CertificateTemplateInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CertificateTemplateInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.style, style) || other.style == style)&&(identical(other.accent, accent) || other.accent == accent)&&(identical(other.heading, heading) || other.heading == heading)&&(identical(other.statement, statement) || other.statement == statement)&&const DeepCollectionEquality().equals(other.signatories, signatories)&&(identical(other.showScore, showScore) || other.showScore == showScore)&&(identical(other.showHours, showHours) || other.showHours == showHours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,style,accent,heading,statement,const DeepCollectionEquality().hash(signatories),showScore,showHours);

@override
String toString() {
  return 'CertificateTemplateInfo(id: $id, name: $name, style: $style, accent: $accent, heading: $heading, statement: $statement, signatories: $signatories, showScore: $showScore, showHours: $showHours)';
}


}

/// @nodoc
abstract mixin class $CertificateTemplateInfoCopyWith<$Res>  {
  factory $CertificateTemplateInfoCopyWith(CertificateTemplateInfo value, $Res Function(CertificateTemplateInfo) _then) = _$CertificateTemplateInfoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String style, String accent, String heading, String statement, List<TemplateSignatory> signatories, bool showScore, bool showHours
});




}
/// @nodoc
class _$CertificateTemplateInfoCopyWithImpl<$Res>
    implements $CertificateTemplateInfoCopyWith<$Res> {
  _$CertificateTemplateInfoCopyWithImpl(this._self, this._then);

  final CertificateTemplateInfo _self;
  final $Res Function(CertificateTemplateInfo) _then;

/// Create a copy of CertificateTemplateInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? style = null,Object? accent = null,Object? heading = null,Object? statement = null,Object? signatories = null,Object? showScore = null,Object? showHours = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as String,accent: null == accent ? _self.accent : accent // ignore: cast_nullable_to_non_nullable
as String,heading: null == heading ? _self.heading : heading // ignore: cast_nullable_to_non_nullable
as String,statement: null == statement ? _self.statement : statement // ignore: cast_nullable_to_non_nullable
as String,signatories: null == signatories ? _self.signatories : signatories // ignore: cast_nullable_to_non_nullable
as List<TemplateSignatory>,showScore: null == showScore ? _self.showScore : showScore // ignore: cast_nullable_to_non_nullable
as bool,showHours: null == showHours ? _self.showHours : showHours // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CertificateTemplateInfo].
extension CertificateTemplateInfoPatterns on CertificateTemplateInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CertificateTemplateInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CertificateTemplateInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CertificateTemplateInfo value)  $default,){
final _that = this;
switch (_that) {
case _CertificateTemplateInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CertificateTemplateInfo value)?  $default,){
final _that = this;
switch (_that) {
case _CertificateTemplateInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String style,  String accent,  String heading,  String statement,  List<TemplateSignatory> signatories,  bool showScore,  bool showHours)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CertificateTemplateInfo() when $default != null:
return $default(_that.id,_that.name,_that.style,_that.accent,_that.heading,_that.statement,_that.signatories,_that.showScore,_that.showHours);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String style,  String accent,  String heading,  String statement,  List<TemplateSignatory> signatories,  bool showScore,  bool showHours)  $default,) {final _that = this;
switch (_that) {
case _CertificateTemplateInfo():
return $default(_that.id,_that.name,_that.style,_that.accent,_that.heading,_that.statement,_that.signatories,_that.showScore,_that.showHours);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String style,  String accent,  String heading,  String statement,  List<TemplateSignatory> signatories,  bool showScore,  bool showHours)?  $default,) {final _that = this;
switch (_that) {
case _CertificateTemplateInfo() when $default != null:
return $default(_that.id,_that.name,_that.style,_that.accent,_that.heading,_that.statement,_that.signatories,_that.showScore,_that.showHours);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CertificateTemplateInfo implements CertificateTemplateInfo {
  const _CertificateTemplateInfo({this.id = '', this.name = '', this.style = 'classic', this.accent = 'indigo', this.heading = '', this.statement = '', final  List<TemplateSignatory> signatories = const <TemplateSignatory>[], this.showScore = false, this.showHours = false}): _signatories = signatories;
  factory _CertificateTemplateInfo.fromJson(Map<String, dynamic> json) => _$CertificateTemplateInfoFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String style;
@override@JsonKey() final  String accent;
@override@JsonKey() final  String heading;
/// The line under the learner's name, before the course title.
@override@JsonKey() final  String statement;
 final  List<TemplateSignatory> _signatories;
@override@JsonKey() List<TemplateSignatory> get signatories {
  if (_signatories is EqualUnmodifiableListView) return _signatories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_signatories);
}

@override@JsonKey() final  bool showScore;
@override@JsonKey() final  bool showHours;

/// Create a copy of CertificateTemplateInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CertificateTemplateInfoCopyWith<_CertificateTemplateInfo> get copyWith => __$CertificateTemplateInfoCopyWithImpl<_CertificateTemplateInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CertificateTemplateInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CertificateTemplateInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.style, style) || other.style == style)&&(identical(other.accent, accent) || other.accent == accent)&&(identical(other.heading, heading) || other.heading == heading)&&(identical(other.statement, statement) || other.statement == statement)&&const DeepCollectionEquality().equals(other._signatories, _signatories)&&(identical(other.showScore, showScore) || other.showScore == showScore)&&(identical(other.showHours, showHours) || other.showHours == showHours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,style,accent,heading,statement,const DeepCollectionEquality().hash(_signatories),showScore,showHours);

@override
String toString() {
  return 'CertificateTemplateInfo(id: $id, name: $name, style: $style, accent: $accent, heading: $heading, statement: $statement, signatories: $signatories, showScore: $showScore, showHours: $showHours)';
}


}

/// @nodoc
abstract mixin class _$CertificateTemplateInfoCopyWith<$Res> implements $CertificateTemplateInfoCopyWith<$Res> {
  factory _$CertificateTemplateInfoCopyWith(_CertificateTemplateInfo value, $Res Function(_CertificateTemplateInfo) _then) = __$CertificateTemplateInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String style, String accent, String heading, String statement, List<TemplateSignatory> signatories, bool showScore, bool showHours
});




}
/// @nodoc
class __$CertificateTemplateInfoCopyWithImpl<$Res>
    implements _$CertificateTemplateInfoCopyWith<$Res> {
  __$CertificateTemplateInfoCopyWithImpl(this._self, this._then);

  final _CertificateTemplateInfo _self;
  final $Res Function(_CertificateTemplateInfo) _then;

/// Create a copy of CertificateTemplateInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? style = null,Object? accent = null,Object? heading = null,Object? statement = null,Object? signatories = null,Object? showScore = null,Object? showHours = null,}) {
  return _then(_CertificateTemplateInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as String,accent: null == accent ? _self.accent : accent // ignore: cast_nullable_to_non_nullable
as String,heading: null == heading ? _self.heading : heading // ignore: cast_nullable_to_non_nullable
as String,statement: null == statement ? _self.statement : statement // ignore: cast_nullable_to_non_nullable
as String,signatories: null == signatories ? _self._signatories : signatories // ignore: cast_nullable_to_non_nullable
as List<TemplateSignatory>,showScore: null == showScore ? _self.showScore : showScore // ignore: cast_nullable_to_non_nullable
as bool,showHours: null == showHours ? _self.showHours : showHours // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$IssuedCertificate {

 String get id; String get credentialId; String get courseId; String get title;@JsonKey(unknownEnumValue: CertificateStatus.unknown) CertificateStatus get status;@UtcDateTimeConverter() DateTime get completedAt;@NullableUtcDateTimeConverter() DateTime? get issuedAt;@NullableUtcDateTimeConverter() DateTime? get revokedAt; String? get revokedReason;/// 0–100, when the academy prints it.
 int? get finalScore; num get hours;/// Times the public verification link has been opened.
 int get verifications;
/// Create a copy of IssuedCertificate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssuedCertificateCopyWith<IssuedCertificate> get copyWith => _$IssuedCertificateCopyWithImpl<IssuedCertificate>(this as IssuedCertificate, _$identity);

  /// Serializes this IssuedCertificate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssuedCertificate&&(identical(other.id, id) || other.id == id)&&(identical(other.credentialId, credentialId) || other.credentialId == credentialId)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.revokedAt, revokedAt) || other.revokedAt == revokedAt)&&(identical(other.revokedReason, revokedReason) || other.revokedReason == revokedReason)&&(identical(other.finalScore, finalScore) || other.finalScore == finalScore)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.verifications, verifications) || other.verifications == verifications));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,credentialId,courseId,title,status,completedAt,issuedAt,revokedAt,revokedReason,finalScore,hours,verifications);

@override
String toString() {
  return 'IssuedCertificate(id: $id, credentialId: $credentialId, courseId: $courseId, title: $title, status: $status, completedAt: $completedAt, issuedAt: $issuedAt, revokedAt: $revokedAt, revokedReason: $revokedReason, finalScore: $finalScore, hours: $hours, verifications: $verifications)';
}


}

/// @nodoc
abstract mixin class $IssuedCertificateCopyWith<$Res>  {
  factory $IssuedCertificateCopyWith(IssuedCertificate value, $Res Function(IssuedCertificate) _then) = _$IssuedCertificateCopyWithImpl;
@useResult
$Res call({
 String id, String credentialId, String courseId, String title,@JsonKey(unknownEnumValue: CertificateStatus.unknown) CertificateStatus status,@UtcDateTimeConverter() DateTime completedAt,@NullableUtcDateTimeConverter() DateTime? issuedAt,@NullableUtcDateTimeConverter() DateTime? revokedAt, String? revokedReason, int? finalScore, num hours, int verifications
});




}
/// @nodoc
class _$IssuedCertificateCopyWithImpl<$Res>
    implements $IssuedCertificateCopyWith<$Res> {
  _$IssuedCertificateCopyWithImpl(this._self, this._then);

  final IssuedCertificate _self;
  final $Res Function(IssuedCertificate) _then;

/// Create a copy of IssuedCertificate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? credentialId = null,Object? courseId = null,Object? title = null,Object? status = null,Object? completedAt = null,Object? issuedAt = freezed,Object? revokedAt = freezed,Object? revokedReason = freezed,Object? finalScore = freezed,Object? hours = null,Object? verifications = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,credentialId: null == credentialId ? _self.credentialId : credentialId // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CertificateStatus,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,revokedAt: freezed == revokedAt ? _self.revokedAt : revokedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,revokedReason: freezed == revokedReason ? _self.revokedReason : revokedReason // ignore: cast_nullable_to_non_nullable
as String?,finalScore: freezed == finalScore ? _self.finalScore : finalScore // ignore: cast_nullable_to_non_nullable
as int?,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as num,verifications: null == verifications ? _self.verifications : verifications // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [IssuedCertificate].
extension IssuedCertificatePatterns on IssuedCertificate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssuedCertificate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssuedCertificate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssuedCertificate value)  $default,){
final _that = this;
switch (_that) {
case _IssuedCertificate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssuedCertificate value)?  $default,){
final _that = this;
switch (_that) {
case _IssuedCertificate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String credentialId,  String courseId,  String title, @JsonKey(unknownEnumValue: CertificateStatus.unknown)  CertificateStatus status, @UtcDateTimeConverter()  DateTime completedAt, @NullableUtcDateTimeConverter()  DateTime? issuedAt, @NullableUtcDateTimeConverter()  DateTime? revokedAt,  String? revokedReason,  int? finalScore,  num hours,  int verifications)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssuedCertificate() when $default != null:
return $default(_that.id,_that.credentialId,_that.courseId,_that.title,_that.status,_that.completedAt,_that.issuedAt,_that.revokedAt,_that.revokedReason,_that.finalScore,_that.hours,_that.verifications);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String credentialId,  String courseId,  String title, @JsonKey(unknownEnumValue: CertificateStatus.unknown)  CertificateStatus status, @UtcDateTimeConverter()  DateTime completedAt, @NullableUtcDateTimeConverter()  DateTime? issuedAt, @NullableUtcDateTimeConverter()  DateTime? revokedAt,  String? revokedReason,  int? finalScore,  num hours,  int verifications)  $default,) {final _that = this;
switch (_that) {
case _IssuedCertificate():
return $default(_that.id,_that.credentialId,_that.courseId,_that.title,_that.status,_that.completedAt,_that.issuedAt,_that.revokedAt,_that.revokedReason,_that.finalScore,_that.hours,_that.verifications);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String credentialId,  String courseId,  String title, @JsonKey(unknownEnumValue: CertificateStatus.unknown)  CertificateStatus status, @UtcDateTimeConverter()  DateTime completedAt, @NullableUtcDateTimeConverter()  DateTime? issuedAt, @NullableUtcDateTimeConverter()  DateTime? revokedAt,  String? revokedReason,  int? finalScore,  num hours,  int verifications)?  $default,) {final _that = this;
switch (_that) {
case _IssuedCertificate() when $default != null:
return $default(_that.id,_that.credentialId,_that.courseId,_that.title,_that.status,_that.completedAt,_that.issuedAt,_that.revokedAt,_that.revokedReason,_that.finalScore,_that.hours,_that.verifications);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssuedCertificate extends IssuedCertificate {
  const _IssuedCertificate({required this.id, this.credentialId = '', this.courseId = '', this.title = '', @JsonKey(unknownEnumValue: CertificateStatus.unknown) this.status = CertificateStatus.unknown, @UtcDateTimeConverter() required this.completedAt, @NullableUtcDateTimeConverter() this.issuedAt, @NullableUtcDateTimeConverter() this.revokedAt, this.revokedReason, this.finalScore, this.hours = 0, this.verifications = 0}): super._();
  factory _IssuedCertificate.fromJson(Map<String, dynamic> json) => _$IssuedCertificateFromJson(json);

@override final  String id;
@override@JsonKey() final  String credentialId;
@override@JsonKey() final  String courseId;
@override@JsonKey() final  String title;
@override@JsonKey(unknownEnumValue: CertificateStatus.unknown) final  CertificateStatus status;
@override@UtcDateTimeConverter() final  DateTime completedAt;
@override@NullableUtcDateTimeConverter() final  DateTime? issuedAt;
@override@NullableUtcDateTimeConverter() final  DateTime? revokedAt;
@override final  String? revokedReason;
/// 0–100, when the academy prints it.
@override final  int? finalScore;
@override@JsonKey() final  num hours;
/// Times the public verification link has been opened.
@override@JsonKey() final  int verifications;

/// Create a copy of IssuedCertificate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssuedCertificateCopyWith<_IssuedCertificate> get copyWith => __$IssuedCertificateCopyWithImpl<_IssuedCertificate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssuedCertificateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssuedCertificate&&(identical(other.id, id) || other.id == id)&&(identical(other.credentialId, credentialId) || other.credentialId == credentialId)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.revokedAt, revokedAt) || other.revokedAt == revokedAt)&&(identical(other.revokedReason, revokedReason) || other.revokedReason == revokedReason)&&(identical(other.finalScore, finalScore) || other.finalScore == finalScore)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.verifications, verifications) || other.verifications == verifications));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,credentialId,courseId,title,status,completedAt,issuedAt,revokedAt,revokedReason,finalScore,hours,verifications);

@override
String toString() {
  return 'IssuedCertificate(id: $id, credentialId: $credentialId, courseId: $courseId, title: $title, status: $status, completedAt: $completedAt, issuedAt: $issuedAt, revokedAt: $revokedAt, revokedReason: $revokedReason, finalScore: $finalScore, hours: $hours, verifications: $verifications)';
}


}

/// @nodoc
abstract mixin class _$IssuedCertificateCopyWith<$Res> implements $IssuedCertificateCopyWith<$Res> {
  factory _$IssuedCertificateCopyWith(_IssuedCertificate value, $Res Function(_IssuedCertificate) _then) = __$IssuedCertificateCopyWithImpl;
@override @useResult
$Res call({
 String id, String credentialId, String courseId, String title,@JsonKey(unknownEnumValue: CertificateStatus.unknown) CertificateStatus status,@UtcDateTimeConverter() DateTime completedAt,@NullableUtcDateTimeConverter() DateTime? issuedAt,@NullableUtcDateTimeConverter() DateTime? revokedAt, String? revokedReason, int? finalScore, num hours, int verifications
});




}
/// @nodoc
class __$IssuedCertificateCopyWithImpl<$Res>
    implements _$IssuedCertificateCopyWith<$Res> {
  __$IssuedCertificateCopyWithImpl(this._self, this._then);

  final _IssuedCertificate _self;
  final $Res Function(_IssuedCertificate) _then;

/// Create a copy of IssuedCertificate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? credentialId = null,Object? courseId = null,Object? title = null,Object? status = null,Object? completedAt = null,Object? issuedAt = freezed,Object? revokedAt = freezed,Object? revokedReason = freezed,Object? finalScore = freezed,Object? hours = null,Object? verifications = null,}) {
  return _then(_IssuedCertificate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,credentialId: null == credentialId ? _self.credentialId : credentialId // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CertificateStatus,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,revokedAt: freezed == revokedAt ? _self.revokedAt : revokedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,revokedReason: freezed == revokedReason ? _self.revokedReason : revokedReason // ignore: cast_nullable_to_non_nullable
as String?,finalScore: freezed == finalScore ? _self.finalScore : finalScore // ignore: cast_nullable_to_non_nullable
as int?,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as num,verifications: null == verifications ? _self.verifications : verifications // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CertificateLearner {

 String get name; String get city;
/// Create a copy of CertificateLearner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CertificateLearnerCopyWith<CertificateLearner> get copyWith => _$CertificateLearnerCopyWithImpl<CertificateLearner>(this as CertificateLearner, _$identity);

  /// Serializes this CertificateLearner to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CertificateLearner&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,city);

@override
String toString() {
  return 'CertificateLearner(name: $name, city: $city)';
}


}

/// @nodoc
abstract mixin class $CertificateLearnerCopyWith<$Res>  {
  factory $CertificateLearnerCopyWith(CertificateLearner value, $Res Function(CertificateLearner) _then) = _$CertificateLearnerCopyWithImpl;
@useResult
$Res call({
 String name, String city
});




}
/// @nodoc
class _$CertificateLearnerCopyWithImpl<$Res>
    implements $CertificateLearnerCopyWith<$Res> {
  _$CertificateLearnerCopyWithImpl(this._self, this._then);

  final CertificateLearner _self;
  final $Res Function(CertificateLearner) _then;

/// Create a copy of CertificateLearner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? city = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CertificateLearner].
extension CertificateLearnerPatterns on CertificateLearner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CertificateLearner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CertificateLearner() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CertificateLearner value)  $default,){
final _that = this;
switch (_that) {
case _CertificateLearner():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CertificateLearner value)?  $default,){
final _that = this;
switch (_that) {
case _CertificateLearner() when $default != null:
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
case _CertificateLearner() when $default != null:
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
case _CertificateLearner():
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
case _CertificateLearner() when $default != null:
return $default(_that.name,_that.city);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CertificateLearner implements CertificateLearner {
  const _CertificateLearner({this.name = '', this.city = ''});
  factory _CertificateLearner.fromJson(Map<String, dynamic> json) => _$CertificateLearnerFromJson(json);

@override@JsonKey() final  String name;
@override@JsonKey() final  String city;

/// Create a copy of CertificateLearner
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CertificateLearnerCopyWith<_CertificateLearner> get copyWith => __$CertificateLearnerCopyWithImpl<_CertificateLearner>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CertificateLearnerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CertificateLearner&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,city);

@override
String toString() {
  return 'CertificateLearner(name: $name, city: $city)';
}


}

/// @nodoc
abstract mixin class _$CertificateLearnerCopyWith<$Res> implements $CertificateLearnerCopyWith<$Res> {
  factory _$CertificateLearnerCopyWith(_CertificateLearner value, $Res Function(_CertificateLearner) _then) = __$CertificateLearnerCopyWithImpl;
@override @useResult
$Res call({
 String name, String city
});




}
/// @nodoc
class __$CertificateLearnerCopyWithImpl<$Res>
    implements _$CertificateLearnerCopyWith<$Res> {
  __$CertificateLearnerCopyWithImpl(this._self, this._then);

  final _CertificateLearner _self;
  final $Res Function(_CertificateLearner) _then;

/// Create a copy of CertificateLearner
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? city = null,}) {
  return _then(_CertificateLearner(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CertificateDetail {

 IssuedCertificate get certificate; CertificateLearner get student; String get courseTitle; String get levelTitle; CertificateTemplateInfo? get template;/// Always `/verify/<credentialId>`, relative to the **web** app (§13).
 String get verifyUrl;
/// Create a copy of CertificateDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CertificateDetailCopyWith<CertificateDetail> get copyWith => _$CertificateDetailCopyWithImpl<CertificateDetail>(this as CertificateDetail, _$identity);

  /// Serializes this CertificateDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CertificateDetail&&(identical(other.certificate, certificate) || other.certificate == certificate)&&(identical(other.student, student) || other.student == student)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.levelTitle, levelTitle) || other.levelTitle == levelTitle)&&(identical(other.template, template) || other.template == template)&&(identical(other.verifyUrl, verifyUrl) || other.verifyUrl == verifyUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,certificate,student,courseTitle,levelTitle,template,verifyUrl);

@override
String toString() {
  return 'CertificateDetail(certificate: $certificate, student: $student, courseTitle: $courseTitle, levelTitle: $levelTitle, template: $template, verifyUrl: $verifyUrl)';
}


}

/// @nodoc
abstract mixin class $CertificateDetailCopyWith<$Res>  {
  factory $CertificateDetailCopyWith(CertificateDetail value, $Res Function(CertificateDetail) _then) = _$CertificateDetailCopyWithImpl;
@useResult
$Res call({
 IssuedCertificate certificate, CertificateLearner student, String courseTitle, String levelTitle, CertificateTemplateInfo? template, String verifyUrl
});


$IssuedCertificateCopyWith<$Res> get certificate;$CertificateLearnerCopyWith<$Res> get student;$CertificateTemplateInfoCopyWith<$Res>? get template;

}
/// @nodoc
class _$CertificateDetailCopyWithImpl<$Res>
    implements $CertificateDetailCopyWith<$Res> {
  _$CertificateDetailCopyWithImpl(this._self, this._then);

  final CertificateDetail _self;
  final $Res Function(CertificateDetail) _then;

/// Create a copy of CertificateDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? certificate = null,Object? student = null,Object? courseTitle = null,Object? levelTitle = null,Object? template = freezed,Object? verifyUrl = null,}) {
  return _then(_self.copyWith(
certificate: null == certificate ? _self.certificate : certificate // ignore: cast_nullable_to_non_nullable
as IssuedCertificate,student: null == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as CertificateLearner,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,levelTitle: null == levelTitle ? _self.levelTitle : levelTitle // ignore: cast_nullable_to_non_nullable
as String,template: freezed == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as CertificateTemplateInfo?,verifyUrl: null == verifyUrl ? _self.verifyUrl : verifyUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of CertificateDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuedCertificateCopyWith<$Res> get certificate {
  
  return $IssuedCertificateCopyWith<$Res>(_self.certificate, (value) {
    return _then(_self.copyWith(certificate: value));
  });
}/// Create a copy of CertificateDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CertificateLearnerCopyWith<$Res> get student {
  
  return $CertificateLearnerCopyWith<$Res>(_self.student, (value) {
    return _then(_self.copyWith(student: value));
  });
}/// Create a copy of CertificateDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CertificateTemplateInfoCopyWith<$Res>? get template {
    if (_self.template == null) {
    return null;
  }

  return $CertificateTemplateInfoCopyWith<$Res>(_self.template!, (value) {
    return _then(_self.copyWith(template: value));
  });
}
}


/// Adds pattern-matching-related methods to [CertificateDetail].
extension CertificateDetailPatterns on CertificateDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CertificateDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CertificateDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CertificateDetail value)  $default,){
final _that = this;
switch (_that) {
case _CertificateDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CertificateDetail value)?  $default,){
final _that = this;
switch (_that) {
case _CertificateDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( IssuedCertificate certificate,  CertificateLearner student,  String courseTitle,  String levelTitle,  CertificateTemplateInfo? template,  String verifyUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CertificateDetail() when $default != null:
return $default(_that.certificate,_that.student,_that.courseTitle,_that.levelTitle,_that.template,_that.verifyUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( IssuedCertificate certificate,  CertificateLearner student,  String courseTitle,  String levelTitle,  CertificateTemplateInfo? template,  String verifyUrl)  $default,) {final _that = this;
switch (_that) {
case _CertificateDetail():
return $default(_that.certificate,_that.student,_that.courseTitle,_that.levelTitle,_that.template,_that.verifyUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( IssuedCertificate certificate,  CertificateLearner student,  String courseTitle,  String levelTitle,  CertificateTemplateInfo? template,  String verifyUrl)?  $default,) {final _that = this;
switch (_that) {
case _CertificateDetail() when $default != null:
return $default(_that.certificate,_that.student,_that.courseTitle,_that.levelTitle,_that.template,_that.verifyUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CertificateDetail implements CertificateDetail {
  const _CertificateDetail({required this.certificate, this.student = const CertificateLearner(), this.courseTitle = '', this.levelTitle = '', this.template, this.verifyUrl = ''});
  factory _CertificateDetail.fromJson(Map<String, dynamic> json) => _$CertificateDetailFromJson(json);

@override final  IssuedCertificate certificate;
@override@JsonKey() final  CertificateLearner student;
@override@JsonKey() final  String courseTitle;
@override@JsonKey() final  String levelTitle;
@override final  CertificateTemplateInfo? template;
/// Always `/verify/<credentialId>`, relative to the **web** app (§13).
@override@JsonKey() final  String verifyUrl;

/// Create a copy of CertificateDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CertificateDetailCopyWith<_CertificateDetail> get copyWith => __$CertificateDetailCopyWithImpl<_CertificateDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CertificateDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CertificateDetail&&(identical(other.certificate, certificate) || other.certificate == certificate)&&(identical(other.student, student) || other.student == student)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.levelTitle, levelTitle) || other.levelTitle == levelTitle)&&(identical(other.template, template) || other.template == template)&&(identical(other.verifyUrl, verifyUrl) || other.verifyUrl == verifyUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,certificate,student,courseTitle,levelTitle,template,verifyUrl);

@override
String toString() {
  return 'CertificateDetail(certificate: $certificate, student: $student, courseTitle: $courseTitle, levelTitle: $levelTitle, template: $template, verifyUrl: $verifyUrl)';
}


}

/// @nodoc
abstract mixin class _$CertificateDetailCopyWith<$Res> implements $CertificateDetailCopyWith<$Res> {
  factory _$CertificateDetailCopyWith(_CertificateDetail value, $Res Function(_CertificateDetail) _then) = __$CertificateDetailCopyWithImpl;
@override @useResult
$Res call({
 IssuedCertificate certificate, CertificateLearner student, String courseTitle, String levelTitle, CertificateTemplateInfo? template, String verifyUrl
});


@override $IssuedCertificateCopyWith<$Res> get certificate;@override $CertificateLearnerCopyWith<$Res> get student;@override $CertificateTemplateInfoCopyWith<$Res>? get template;

}
/// @nodoc
class __$CertificateDetailCopyWithImpl<$Res>
    implements _$CertificateDetailCopyWith<$Res> {
  __$CertificateDetailCopyWithImpl(this._self, this._then);

  final _CertificateDetail _self;
  final $Res Function(_CertificateDetail) _then;

/// Create a copy of CertificateDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? certificate = null,Object? student = null,Object? courseTitle = null,Object? levelTitle = null,Object? template = freezed,Object? verifyUrl = null,}) {
  return _then(_CertificateDetail(
certificate: null == certificate ? _self.certificate : certificate // ignore: cast_nullable_to_non_nullable
as IssuedCertificate,student: null == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as CertificateLearner,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,levelTitle: null == levelTitle ? _self.levelTitle : levelTitle // ignore: cast_nullable_to_non_nullable
as String,template: freezed == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as CertificateTemplateInfo?,verifyUrl: null == verifyUrl ? _self.verifyUrl : verifyUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of CertificateDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuedCertificateCopyWith<$Res> get certificate {
  
  return $IssuedCertificateCopyWith<$Res>(_self.certificate, (value) {
    return _then(_self.copyWith(certificate: value));
  });
}/// Create a copy of CertificateDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CertificateLearnerCopyWith<$Res> get student {
  
  return $CertificateLearnerCopyWith<$Res>(_self.student, (value) {
    return _then(_self.copyWith(student: value));
  });
}/// Create a copy of CertificateDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CertificateTemplateInfoCopyWith<$Res>? get template {
    if (_self.template == null) {
    return null;
  }

  return $CertificateTemplateInfoCopyWith<$Res>(_self.template!, (value) {
    return _then(_self.copyWith(template: value));
  });
}
}


/// @nodoc
mixin _$CertificateWallet {

 List<CertificateDetail> get issued; List<CertificateDetail> get pending; List<CertificateRecord> get working;
/// Create a copy of CertificateWallet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CertificateWalletCopyWith<CertificateWallet> get copyWith => _$CertificateWalletCopyWithImpl<CertificateWallet>(this as CertificateWallet, _$identity);

  /// Serializes this CertificateWallet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CertificateWallet&&const DeepCollectionEquality().equals(other.issued, issued)&&const DeepCollectionEquality().equals(other.pending, pending)&&const DeepCollectionEquality().equals(other.working, working));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(issued),const DeepCollectionEquality().hash(pending),const DeepCollectionEquality().hash(working));

@override
String toString() {
  return 'CertificateWallet(issued: $issued, pending: $pending, working: $working)';
}


}

/// @nodoc
abstract mixin class $CertificateWalletCopyWith<$Res>  {
  factory $CertificateWalletCopyWith(CertificateWallet value, $Res Function(CertificateWallet) _then) = _$CertificateWalletCopyWithImpl;
@useResult
$Res call({
 List<CertificateDetail> issued, List<CertificateDetail> pending, List<CertificateRecord> working
});




}
/// @nodoc
class _$CertificateWalletCopyWithImpl<$Res>
    implements $CertificateWalletCopyWith<$Res> {
  _$CertificateWalletCopyWithImpl(this._self, this._then);

  final CertificateWallet _self;
  final $Res Function(CertificateWallet) _then;

/// Create a copy of CertificateWallet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? issued = null,Object? pending = null,Object? working = null,}) {
  return _then(_self.copyWith(
issued: null == issued ? _self.issued : issued // ignore: cast_nullable_to_non_nullable
as List<CertificateDetail>,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as List<CertificateDetail>,working: null == working ? _self.working : working // ignore: cast_nullable_to_non_nullable
as List<CertificateRecord>,
  ));
}

}


/// Adds pattern-matching-related methods to [CertificateWallet].
extension CertificateWalletPatterns on CertificateWallet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CertificateWallet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CertificateWallet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CertificateWallet value)  $default,){
final _that = this;
switch (_that) {
case _CertificateWallet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CertificateWallet value)?  $default,){
final _that = this;
switch (_that) {
case _CertificateWallet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CertificateDetail> issued,  List<CertificateDetail> pending,  List<CertificateRecord> working)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CertificateWallet() when $default != null:
return $default(_that.issued,_that.pending,_that.working);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CertificateDetail> issued,  List<CertificateDetail> pending,  List<CertificateRecord> working)  $default,) {final _that = this;
switch (_that) {
case _CertificateWallet():
return $default(_that.issued,_that.pending,_that.working);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CertificateDetail> issued,  List<CertificateDetail> pending,  List<CertificateRecord> working)?  $default,) {final _that = this;
switch (_that) {
case _CertificateWallet() when $default != null:
return $default(_that.issued,_that.pending,_that.working);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CertificateWallet extends CertificateWallet {
  const _CertificateWallet({final  List<CertificateDetail> issued = const <CertificateDetail>[], final  List<CertificateDetail> pending = const <CertificateDetail>[], final  List<CertificateRecord> working = const <CertificateRecord>[]}): _issued = issued,_pending = pending,_working = working,super._();
  factory _CertificateWallet.fromJson(Map<String, dynamic> json) => _$CertificateWalletFromJson(json);

 final  List<CertificateDetail> _issued;
@override@JsonKey() List<CertificateDetail> get issued {
  if (_issued is EqualUnmodifiableListView) return _issued;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_issued);
}

 final  List<CertificateDetail> _pending;
@override@JsonKey() List<CertificateDetail> get pending {
  if (_pending is EqualUnmodifiableListView) return _pending;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pending);
}

 final  List<CertificateRecord> _working;
@override@JsonKey() List<CertificateRecord> get working {
  if (_working is EqualUnmodifiableListView) return _working;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_working);
}


/// Create a copy of CertificateWallet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CertificateWalletCopyWith<_CertificateWallet> get copyWith => __$CertificateWalletCopyWithImpl<_CertificateWallet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CertificateWalletToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CertificateWallet&&const DeepCollectionEquality().equals(other._issued, _issued)&&const DeepCollectionEquality().equals(other._pending, _pending)&&const DeepCollectionEquality().equals(other._working, _working));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_issued),const DeepCollectionEquality().hash(_pending),const DeepCollectionEquality().hash(_working));

@override
String toString() {
  return 'CertificateWallet(issued: $issued, pending: $pending, working: $working)';
}


}

/// @nodoc
abstract mixin class _$CertificateWalletCopyWith<$Res> implements $CertificateWalletCopyWith<$Res> {
  factory _$CertificateWalletCopyWith(_CertificateWallet value, $Res Function(_CertificateWallet) _then) = __$CertificateWalletCopyWithImpl;
@override @useResult
$Res call({
 List<CertificateDetail> issued, List<CertificateDetail> pending, List<CertificateRecord> working
});




}
/// @nodoc
class __$CertificateWalletCopyWithImpl<$Res>
    implements _$CertificateWalletCopyWith<$Res> {
  __$CertificateWalletCopyWithImpl(this._self, this._then);

  final _CertificateWallet _self;
  final $Res Function(_CertificateWallet) _then;

/// Create a copy of CertificateWallet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? issued = null,Object? pending = null,Object? working = null,}) {
  return _then(_CertificateWallet(
issued: null == issued ? _self._issued : issued // ignore: cast_nullable_to_non_nullable
as List<CertificateDetail>,pending: null == pending ? _self._pending : pending // ignore: cast_nullable_to_non_nullable
as List<CertificateDetail>,working: null == working ? _self._working : working // ignore: cast_nullable_to_non_nullable
as List<CertificateRecord>,
  ));
}


}

// dart format on
