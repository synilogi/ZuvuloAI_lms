// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'certificate_register.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CertificateRegisterRow {

 IssuedCertificate get certificate; String get studentName; String get studentEmail; String get courseTitle;
/// Create a copy of CertificateRegisterRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CertificateRegisterRowCopyWith<CertificateRegisterRow> get copyWith => _$CertificateRegisterRowCopyWithImpl<CertificateRegisterRow>(this as CertificateRegisterRow, _$identity);

  /// Serializes this CertificateRegisterRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CertificateRegisterRow&&(identical(other.certificate, certificate) || other.certificate == certificate)&&(identical(other.studentName, studentName) || other.studentName == studentName)&&(identical(other.studentEmail, studentEmail) || other.studentEmail == studentEmail)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,certificate,studentName,studentEmail,courseTitle);

@override
String toString() {
  return 'CertificateRegisterRow(certificate: $certificate, studentName: $studentName, studentEmail: $studentEmail, courseTitle: $courseTitle)';
}


}

/// @nodoc
abstract mixin class $CertificateRegisterRowCopyWith<$Res>  {
  factory $CertificateRegisterRowCopyWith(CertificateRegisterRow value, $Res Function(CertificateRegisterRow) _then) = _$CertificateRegisterRowCopyWithImpl;
@useResult
$Res call({
 IssuedCertificate certificate, String studentName, String studentEmail, String courseTitle
});


$IssuedCertificateCopyWith<$Res> get certificate;

}
/// @nodoc
class _$CertificateRegisterRowCopyWithImpl<$Res>
    implements $CertificateRegisterRowCopyWith<$Res> {
  _$CertificateRegisterRowCopyWithImpl(this._self, this._then);

  final CertificateRegisterRow _self;
  final $Res Function(CertificateRegisterRow) _then;

/// Create a copy of CertificateRegisterRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? certificate = null,Object? studentName = null,Object? studentEmail = null,Object? courseTitle = null,}) {
  return _then(_self.copyWith(
certificate: null == certificate ? _self.certificate : certificate // ignore: cast_nullable_to_non_nullable
as IssuedCertificate,studentName: null == studentName ? _self.studentName : studentName // ignore: cast_nullable_to_non_nullable
as String,studentEmail: null == studentEmail ? _self.studentEmail : studentEmail // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of CertificateRegisterRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuedCertificateCopyWith<$Res> get certificate {
  
  return $IssuedCertificateCopyWith<$Res>(_self.certificate, (value) {
    return _then(_self.copyWith(certificate: value));
  });
}
}


/// Adds pattern-matching-related methods to [CertificateRegisterRow].
extension CertificateRegisterRowPatterns on CertificateRegisterRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CertificateRegisterRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CertificateRegisterRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CertificateRegisterRow value)  $default,){
final _that = this;
switch (_that) {
case _CertificateRegisterRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CertificateRegisterRow value)?  $default,){
final _that = this;
switch (_that) {
case _CertificateRegisterRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( IssuedCertificate certificate,  String studentName,  String studentEmail,  String courseTitle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CertificateRegisterRow() when $default != null:
return $default(_that.certificate,_that.studentName,_that.studentEmail,_that.courseTitle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( IssuedCertificate certificate,  String studentName,  String studentEmail,  String courseTitle)  $default,) {final _that = this;
switch (_that) {
case _CertificateRegisterRow():
return $default(_that.certificate,_that.studentName,_that.studentEmail,_that.courseTitle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( IssuedCertificate certificate,  String studentName,  String studentEmail,  String courseTitle)?  $default,) {final _that = this;
switch (_that) {
case _CertificateRegisterRow() when $default != null:
return $default(_that.certificate,_that.studentName,_that.studentEmail,_that.courseTitle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CertificateRegisterRow implements CertificateRegisterRow {
  const _CertificateRegisterRow({required this.certificate, this.studentName = '', this.studentEmail = '', this.courseTitle = ''});
  factory _CertificateRegisterRow.fromJson(Map<String, dynamic> json) => _$CertificateRegisterRowFromJson(json);

@override final  IssuedCertificate certificate;
@override@JsonKey() final  String studentName;
@override@JsonKey() final  String studentEmail;
@override@JsonKey() final  String courseTitle;

/// Create a copy of CertificateRegisterRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CertificateRegisterRowCopyWith<_CertificateRegisterRow> get copyWith => __$CertificateRegisterRowCopyWithImpl<_CertificateRegisterRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CertificateRegisterRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CertificateRegisterRow&&(identical(other.certificate, certificate) || other.certificate == certificate)&&(identical(other.studentName, studentName) || other.studentName == studentName)&&(identical(other.studentEmail, studentEmail) || other.studentEmail == studentEmail)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,certificate,studentName,studentEmail,courseTitle);

@override
String toString() {
  return 'CertificateRegisterRow(certificate: $certificate, studentName: $studentName, studentEmail: $studentEmail, courseTitle: $courseTitle)';
}


}

/// @nodoc
abstract mixin class _$CertificateRegisterRowCopyWith<$Res> implements $CertificateRegisterRowCopyWith<$Res> {
  factory _$CertificateRegisterRowCopyWith(_CertificateRegisterRow value, $Res Function(_CertificateRegisterRow) _then) = __$CertificateRegisterRowCopyWithImpl;
@override @useResult
$Res call({
 IssuedCertificate certificate, String studentName, String studentEmail, String courseTitle
});


@override $IssuedCertificateCopyWith<$Res> get certificate;

}
/// @nodoc
class __$CertificateRegisterRowCopyWithImpl<$Res>
    implements _$CertificateRegisterRowCopyWith<$Res> {
  __$CertificateRegisterRowCopyWithImpl(this._self, this._then);

  final _CertificateRegisterRow _self;
  final $Res Function(_CertificateRegisterRow) _then;

/// Create a copy of CertificateRegisterRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? certificate = null,Object? studentName = null,Object? studentEmail = null,Object? courseTitle = null,}) {
  return _then(_CertificateRegisterRow(
certificate: null == certificate ? _self.certificate : certificate // ignore: cast_nullable_to_non_nullable
as IssuedCertificate,studentName: null == studentName ? _self.studentName : studentName // ignore: cast_nullable_to_non_nullable
as String,studentEmail: null == studentEmail ? _self.studentEmail : studentEmail // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of CertificateRegisterRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuedCertificateCopyWith<$Res> get certificate {
  
  return $IssuedCertificateCopyWith<$Res>(_self.certificate, (value) {
    return _then(_self.copyWith(certificate: value));
  });
}
}


/// @nodoc
mixin _$CertificateRegister {

 List<CertificateRegisterRow> get rows; int get total; Map<String, int> get counts;
/// Create a copy of CertificateRegister
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CertificateRegisterCopyWith<CertificateRegister> get copyWith => _$CertificateRegisterCopyWithImpl<CertificateRegister>(this as CertificateRegister, _$identity);

  /// Serializes this CertificateRegister to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CertificateRegister&&const DeepCollectionEquality().equals(other.rows, rows)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.counts, counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rows),total,const DeepCollectionEquality().hash(counts));

@override
String toString() {
  return 'CertificateRegister(rows: $rows, total: $total, counts: $counts)';
}


}

/// @nodoc
abstract mixin class $CertificateRegisterCopyWith<$Res>  {
  factory $CertificateRegisterCopyWith(CertificateRegister value, $Res Function(CertificateRegister) _then) = _$CertificateRegisterCopyWithImpl;
@useResult
$Res call({
 List<CertificateRegisterRow> rows, int total, Map<String, int> counts
});




}
/// @nodoc
class _$CertificateRegisterCopyWithImpl<$Res>
    implements $CertificateRegisterCopyWith<$Res> {
  _$CertificateRegisterCopyWithImpl(this._self, this._then);

  final CertificateRegister _self;
  final $Res Function(CertificateRegister) _then;

/// Create a copy of CertificateRegister
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? total = null,Object? counts = null,}) {
  return _then(_self.copyWith(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<CertificateRegisterRow>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [CertificateRegister].
extension CertificateRegisterPatterns on CertificateRegister {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CertificateRegister value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CertificateRegister() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CertificateRegister value)  $default,){
final _that = this;
switch (_that) {
case _CertificateRegister():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CertificateRegister value)?  $default,){
final _that = this;
switch (_that) {
case _CertificateRegister() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CertificateRegisterRow> rows,  int total,  Map<String, int> counts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CertificateRegister() when $default != null:
return $default(_that.rows,_that.total,_that.counts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CertificateRegisterRow> rows,  int total,  Map<String, int> counts)  $default,) {final _that = this;
switch (_that) {
case _CertificateRegister():
return $default(_that.rows,_that.total,_that.counts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CertificateRegisterRow> rows,  int total,  Map<String, int> counts)?  $default,) {final _that = this;
switch (_that) {
case _CertificateRegister() when $default != null:
return $default(_that.rows,_that.total,_that.counts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CertificateRegister extends CertificateRegister {
  const _CertificateRegister({final  List<CertificateRegisterRow> rows = const <CertificateRegisterRow>[], this.total = 0, final  Map<String, int> counts = const <String, int>{}}): _rows = rows,_counts = counts,super._();
  factory _CertificateRegister.fromJson(Map<String, dynamic> json) => _$CertificateRegisterFromJson(json);

 final  List<CertificateRegisterRow> _rows;
@override@JsonKey() List<CertificateRegisterRow> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

@override@JsonKey() final  int total;
 final  Map<String, int> _counts;
@override@JsonKey() Map<String, int> get counts {
  if (_counts is EqualUnmodifiableMapView) return _counts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_counts);
}


/// Create a copy of CertificateRegister
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CertificateRegisterCopyWith<_CertificateRegister> get copyWith => __$CertificateRegisterCopyWithImpl<_CertificateRegister>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CertificateRegisterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CertificateRegister&&const DeepCollectionEquality().equals(other._rows, _rows)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._counts, _counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows),total,const DeepCollectionEquality().hash(_counts));

@override
String toString() {
  return 'CertificateRegister(rows: $rows, total: $total, counts: $counts)';
}


}

/// @nodoc
abstract mixin class _$CertificateRegisterCopyWith<$Res> implements $CertificateRegisterCopyWith<$Res> {
  factory _$CertificateRegisterCopyWith(_CertificateRegister value, $Res Function(_CertificateRegister) _then) = __$CertificateRegisterCopyWithImpl;
@override @useResult
$Res call({
 List<CertificateRegisterRow> rows, int total, Map<String, int> counts
});




}
/// @nodoc
class __$CertificateRegisterCopyWithImpl<$Res>
    implements _$CertificateRegisterCopyWith<$Res> {
  __$CertificateRegisterCopyWithImpl(this._self, this._then);

  final _CertificateRegister _self;
  final $Res Function(_CertificateRegister) _then;

/// Create a copy of CertificateRegister
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,Object? total = null,Object? counts = null,}) {
  return _then(_CertificateRegister(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<CertificateRegisterRow>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self._counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}


/// @nodoc
mixin _$RegisterLearner {

 String get id; String get name; String get email; String get city;
/// Create a copy of RegisterLearner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterLearnerCopyWith<RegisterLearner> get copyWith => _$RegisterLearnerCopyWithImpl<RegisterLearner>(this as RegisterLearner, _$identity);

  /// Serializes this RegisterLearner to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterLearner&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.city, city) || other.city == city));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,city);

@override
String toString() {
  return 'RegisterLearner(id: $id, name: $name, email: $email, city: $city)';
}


}

/// @nodoc
abstract mixin class $RegisterLearnerCopyWith<$Res>  {
  factory $RegisterLearnerCopyWith(RegisterLearner value, $Res Function(RegisterLearner) _then) = _$RegisterLearnerCopyWithImpl;
@useResult
$Res call({
 String id, String name, String email, String city
});




}
/// @nodoc
class _$RegisterLearnerCopyWithImpl<$Res>
    implements $RegisterLearnerCopyWith<$Res> {
  _$RegisterLearnerCopyWithImpl(this._self, this._then);

  final RegisterLearner _self;
  final $Res Function(RegisterLearner) _then;

/// Create a copy of RegisterLearner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,Object? city = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RegisterLearner].
extension RegisterLearnerPatterns on RegisterLearner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegisterLearner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegisterLearner() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegisterLearner value)  $default,){
final _that = this;
switch (_that) {
case _RegisterLearner():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegisterLearner value)?  $default,){
final _that = this;
switch (_that) {
case _RegisterLearner() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String email,  String city)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegisterLearner() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.city);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String email,  String city)  $default,) {final _that = this;
switch (_that) {
case _RegisterLearner():
return $default(_that.id,_that.name,_that.email,_that.city);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String email,  String city)?  $default,) {final _that = this;
switch (_that) {
case _RegisterLearner() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.city);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RegisterLearner implements RegisterLearner {
  const _RegisterLearner({this.id = '', this.name = '', this.email = '', this.city = ''});
  factory _RegisterLearner.fromJson(Map<String, dynamic> json) => _$RegisterLearnerFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String email;
@override@JsonKey() final  String city;

/// Create a copy of RegisterLearner
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegisterLearnerCopyWith<_RegisterLearner> get copyWith => __$RegisterLearnerCopyWithImpl<_RegisterLearner>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegisterLearnerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegisterLearner&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.city, city) || other.city == city));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,city);

@override
String toString() {
  return 'RegisterLearner(id: $id, name: $name, email: $email, city: $city)';
}


}

/// @nodoc
abstract mixin class _$RegisterLearnerCopyWith<$Res> implements $RegisterLearnerCopyWith<$Res> {
  factory _$RegisterLearnerCopyWith(_RegisterLearner value, $Res Function(_RegisterLearner) _then) = __$RegisterLearnerCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String email, String city
});




}
/// @nodoc
class __$RegisterLearnerCopyWithImpl<$Res>
    implements _$RegisterLearnerCopyWith<$Res> {
  __$RegisterLearnerCopyWithImpl(this._self, this._then);

  final _RegisterLearner _self;
  final $Res Function(_RegisterLearner) _then;

/// Create a copy of RegisterLearner
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,Object? city = null,}) {
  return _then(_RegisterLearner(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$StaffCertificateDetail {

 IssuedCertificate get certificate; RegisterLearner get student; String get courseTitle; String get levelTitle; CertificateTemplateInfo? get template;/// Always `/verify/<credentialId>`, relative to the **web** app (§13).
 String get verifyUrl;
/// Create a copy of StaffCertificateDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffCertificateDetailCopyWith<StaffCertificateDetail> get copyWith => _$StaffCertificateDetailCopyWithImpl<StaffCertificateDetail>(this as StaffCertificateDetail, _$identity);

  /// Serializes this StaffCertificateDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffCertificateDetail&&(identical(other.certificate, certificate) || other.certificate == certificate)&&(identical(other.student, student) || other.student == student)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.levelTitle, levelTitle) || other.levelTitle == levelTitle)&&(identical(other.template, template) || other.template == template)&&(identical(other.verifyUrl, verifyUrl) || other.verifyUrl == verifyUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,certificate,student,courseTitle,levelTitle,template,verifyUrl);

@override
String toString() {
  return 'StaffCertificateDetail(certificate: $certificate, student: $student, courseTitle: $courseTitle, levelTitle: $levelTitle, template: $template, verifyUrl: $verifyUrl)';
}


}

/// @nodoc
abstract mixin class $StaffCertificateDetailCopyWith<$Res>  {
  factory $StaffCertificateDetailCopyWith(StaffCertificateDetail value, $Res Function(StaffCertificateDetail) _then) = _$StaffCertificateDetailCopyWithImpl;
@useResult
$Res call({
 IssuedCertificate certificate, RegisterLearner student, String courseTitle, String levelTitle, CertificateTemplateInfo? template, String verifyUrl
});


$IssuedCertificateCopyWith<$Res> get certificate;$RegisterLearnerCopyWith<$Res> get student;$CertificateTemplateInfoCopyWith<$Res>? get template;

}
/// @nodoc
class _$StaffCertificateDetailCopyWithImpl<$Res>
    implements $StaffCertificateDetailCopyWith<$Res> {
  _$StaffCertificateDetailCopyWithImpl(this._self, this._then);

  final StaffCertificateDetail _self;
  final $Res Function(StaffCertificateDetail) _then;

/// Create a copy of StaffCertificateDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? certificate = null,Object? student = null,Object? courseTitle = null,Object? levelTitle = null,Object? template = freezed,Object? verifyUrl = null,}) {
  return _then(_self.copyWith(
certificate: null == certificate ? _self.certificate : certificate // ignore: cast_nullable_to_non_nullable
as IssuedCertificate,student: null == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as RegisterLearner,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,levelTitle: null == levelTitle ? _self.levelTitle : levelTitle // ignore: cast_nullable_to_non_nullable
as String,template: freezed == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as CertificateTemplateInfo?,verifyUrl: null == verifyUrl ? _self.verifyUrl : verifyUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of StaffCertificateDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuedCertificateCopyWith<$Res> get certificate {
  
  return $IssuedCertificateCopyWith<$Res>(_self.certificate, (value) {
    return _then(_self.copyWith(certificate: value));
  });
}/// Create a copy of StaffCertificateDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RegisterLearnerCopyWith<$Res> get student {
  
  return $RegisterLearnerCopyWith<$Res>(_self.student, (value) {
    return _then(_self.copyWith(student: value));
  });
}/// Create a copy of StaffCertificateDetail
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


/// Adds pattern-matching-related methods to [StaffCertificateDetail].
extension StaffCertificateDetailPatterns on StaffCertificateDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffCertificateDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffCertificateDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffCertificateDetail value)  $default,){
final _that = this;
switch (_that) {
case _StaffCertificateDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffCertificateDetail value)?  $default,){
final _that = this;
switch (_that) {
case _StaffCertificateDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( IssuedCertificate certificate,  RegisterLearner student,  String courseTitle,  String levelTitle,  CertificateTemplateInfo? template,  String verifyUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffCertificateDetail() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( IssuedCertificate certificate,  RegisterLearner student,  String courseTitle,  String levelTitle,  CertificateTemplateInfo? template,  String verifyUrl)  $default,) {final _that = this;
switch (_that) {
case _StaffCertificateDetail():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( IssuedCertificate certificate,  RegisterLearner student,  String courseTitle,  String levelTitle,  CertificateTemplateInfo? template,  String verifyUrl)?  $default,) {final _that = this;
switch (_that) {
case _StaffCertificateDetail() when $default != null:
return $default(_that.certificate,_that.student,_that.courseTitle,_that.levelTitle,_that.template,_that.verifyUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffCertificateDetail extends StaffCertificateDetail {
  const _StaffCertificateDetail({required this.certificate, this.student = const RegisterLearner(), this.courseTitle = '', this.levelTitle = '', this.template, this.verifyUrl = ''}): super._();
  factory _StaffCertificateDetail.fromJson(Map<String, dynamic> json) => _$StaffCertificateDetailFromJson(json);

@override final  IssuedCertificate certificate;
@override@JsonKey() final  RegisterLearner student;
@override@JsonKey() final  String courseTitle;
@override@JsonKey() final  String levelTitle;
@override final  CertificateTemplateInfo? template;
/// Always `/verify/<credentialId>`, relative to the **web** app (§13).
@override@JsonKey() final  String verifyUrl;

/// Create a copy of StaffCertificateDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffCertificateDetailCopyWith<_StaffCertificateDetail> get copyWith => __$StaffCertificateDetailCopyWithImpl<_StaffCertificateDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffCertificateDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffCertificateDetail&&(identical(other.certificate, certificate) || other.certificate == certificate)&&(identical(other.student, student) || other.student == student)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.levelTitle, levelTitle) || other.levelTitle == levelTitle)&&(identical(other.template, template) || other.template == template)&&(identical(other.verifyUrl, verifyUrl) || other.verifyUrl == verifyUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,certificate,student,courseTitle,levelTitle,template,verifyUrl);

@override
String toString() {
  return 'StaffCertificateDetail(certificate: $certificate, student: $student, courseTitle: $courseTitle, levelTitle: $levelTitle, template: $template, verifyUrl: $verifyUrl)';
}


}

/// @nodoc
abstract mixin class _$StaffCertificateDetailCopyWith<$Res> implements $StaffCertificateDetailCopyWith<$Res> {
  factory _$StaffCertificateDetailCopyWith(_StaffCertificateDetail value, $Res Function(_StaffCertificateDetail) _then) = __$StaffCertificateDetailCopyWithImpl;
@override @useResult
$Res call({
 IssuedCertificate certificate, RegisterLearner student, String courseTitle, String levelTitle, CertificateTemplateInfo? template, String verifyUrl
});


@override $IssuedCertificateCopyWith<$Res> get certificate;@override $RegisterLearnerCopyWith<$Res> get student;@override $CertificateTemplateInfoCopyWith<$Res>? get template;

}
/// @nodoc
class __$StaffCertificateDetailCopyWithImpl<$Res>
    implements _$StaffCertificateDetailCopyWith<$Res> {
  __$StaffCertificateDetailCopyWithImpl(this._self, this._then);

  final _StaffCertificateDetail _self;
  final $Res Function(_StaffCertificateDetail) _then;

/// Create a copy of StaffCertificateDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? certificate = null,Object? student = null,Object? courseTitle = null,Object? levelTitle = null,Object? template = freezed,Object? verifyUrl = null,}) {
  return _then(_StaffCertificateDetail(
certificate: null == certificate ? _self.certificate : certificate // ignore: cast_nullable_to_non_nullable
as IssuedCertificate,student: null == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as RegisterLearner,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,levelTitle: null == levelTitle ? _self.levelTitle : levelTitle // ignore: cast_nullable_to_non_nullable
as String,template: freezed == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as CertificateTemplateInfo?,verifyUrl: null == verifyUrl ? _self.verifyUrl : verifyUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of StaffCertificateDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuedCertificateCopyWith<$Res> get certificate {
  
  return $IssuedCertificateCopyWith<$Res>(_self.certificate, (value) {
    return _then(_self.copyWith(certificate: value));
  });
}/// Create a copy of StaffCertificateDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RegisterLearnerCopyWith<$Res> get student {
  
  return $RegisterLearnerCopyWith<$Res>(_self.student, (value) {
    return _then(_self.copyWith(student: value));
  });
}/// Create a copy of StaffCertificateDetail
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

// dart format on
