// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'people.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Student {

 String get id; String get name; String get email; String? get phone; String get city;@NullableUtcDateTimeConverter() DateTime? get joinedAt;@NullableUtcDateTimeConverter() DateTime? get lastActiveAt;/// Set by an admin; the academy's derived status gives way to it.
 bool? get suspended; String get rankId;
/// Create a copy of Student
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentCopyWith<Student> get copyWith => _$StudentCopyWithImpl<Student>(this as Student, _$identity);

  /// Serializes this Student to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Student&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.city, city) || other.city == city)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt)&&(identical(other.suspended, suspended) || other.suspended == suspended)&&(identical(other.rankId, rankId) || other.rankId == rankId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,phone,city,joinedAt,lastActiveAt,suspended,rankId);

@override
String toString() {
  return 'Student(id: $id, name: $name, email: $email, phone: $phone, city: $city, joinedAt: $joinedAt, lastActiveAt: $lastActiveAt, suspended: $suspended, rankId: $rankId)';
}


}

/// @nodoc
abstract mixin class $StudentCopyWith<$Res>  {
  factory $StudentCopyWith(Student value, $Res Function(Student) _then) = _$StudentCopyWithImpl;
@useResult
$Res call({
 String id, String name, String email, String? phone, String city,@NullableUtcDateTimeConverter() DateTime? joinedAt,@NullableUtcDateTimeConverter() DateTime? lastActiveAt, bool? suspended, String rankId
});




}
/// @nodoc
class _$StudentCopyWithImpl<$Res>
    implements $StudentCopyWith<$Res> {
  _$StudentCopyWithImpl(this._self, this._then);

  final Student _self;
  final $Res Function(Student) _then;

/// Create a copy of Student
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,Object? phone = freezed,Object? city = null,Object? joinedAt = freezed,Object? lastActiveAt = freezed,Object? suspended = freezed,Object? rankId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,suspended: freezed == suspended ? _self.suspended : suspended // ignore: cast_nullable_to_non_nullable
as bool?,rankId: null == rankId ? _self.rankId : rankId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Student].
extension StudentPatterns on Student {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Student value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Student() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Student value)  $default,){
final _that = this;
switch (_that) {
case _Student():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Student value)?  $default,){
final _that = this;
switch (_that) {
case _Student() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String email,  String? phone,  String city, @NullableUtcDateTimeConverter()  DateTime? joinedAt, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt,  bool? suspended,  String rankId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Student() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.phone,_that.city,_that.joinedAt,_that.lastActiveAt,_that.suspended,_that.rankId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String email,  String? phone,  String city, @NullableUtcDateTimeConverter()  DateTime? joinedAt, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt,  bool? suspended,  String rankId)  $default,) {final _that = this;
switch (_that) {
case _Student():
return $default(_that.id,_that.name,_that.email,_that.phone,_that.city,_that.joinedAt,_that.lastActiveAt,_that.suspended,_that.rankId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String email,  String? phone,  String city, @NullableUtcDateTimeConverter()  DateTime? joinedAt, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt,  bool? suspended,  String rankId)?  $default,) {final _that = this;
switch (_that) {
case _Student() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.phone,_that.city,_that.joinedAt,_that.lastActiveAt,_that.suspended,_that.rankId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Student extends Student {
  const _Student({this.id = '', this.name = '', this.email = '', this.phone, this.city = '', @NullableUtcDateTimeConverter() this.joinedAt, @NullableUtcDateTimeConverter() this.lastActiveAt, this.suspended, this.rankId = ''}): super._();
  factory _Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String email;
@override final  String? phone;
@override@JsonKey() final  String city;
@override@NullableUtcDateTimeConverter() final  DateTime? joinedAt;
@override@NullableUtcDateTimeConverter() final  DateTime? lastActiveAt;
/// Set by an admin; the academy's derived status gives way to it.
@override final  bool? suspended;
@override@JsonKey() final  String rankId;

/// Create a copy of Student
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentCopyWith<_Student> get copyWith => __$StudentCopyWithImpl<_Student>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Student&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.city, city) || other.city == city)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt)&&(identical(other.suspended, suspended) || other.suspended == suspended)&&(identical(other.rankId, rankId) || other.rankId == rankId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,phone,city,joinedAt,lastActiveAt,suspended,rankId);

@override
String toString() {
  return 'Student(id: $id, name: $name, email: $email, phone: $phone, city: $city, joinedAt: $joinedAt, lastActiveAt: $lastActiveAt, suspended: $suspended, rankId: $rankId)';
}


}

/// @nodoc
abstract mixin class _$StudentCopyWith<$Res> implements $StudentCopyWith<$Res> {
  factory _$StudentCopyWith(_Student value, $Res Function(_Student) _then) = __$StudentCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String email, String? phone, String city,@NullableUtcDateTimeConverter() DateTime? joinedAt,@NullableUtcDateTimeConverter() DateTime? lastActiveAt, bool? suspended, String rankId
});




}
/// @nodoc
class __$StudentCopyWithImpl<$Res>
    implements _$StudentCopyWith<$Res> {
  __$StudentCopyWithImpl(this._self, this._then);

  final _Student _self;
  final $Res Function(_Student) _then;

/// Create a copy of Student
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,Object? phone = freezed,Object? city = null,Object? joinedAt = freezed,Object? lastActiveAt = freezed,Object? suspended = freezed,Object? rankId = null,}) {
  return _then(_Student(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,suspended: freezed == suspended ? _self.suspended : suspended // ignore: cast_nullable_to_non_nullable
as bool?,rankId: null == rankId ? _self.rankId : rankId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Enrollment {

 String get id; String get studentId; String get courseId;@NullableUtcDateTimeConverter() DateTime? get enrolledAt;@JsonKey(unknownEnumValue: EnrollmentStatus.unknown) EnrollmentStatus get status;/// 0–100, weighted by lesson length the way course progress is.
 num get progress;@JsonKey(unknownEnumValue: EnrollmentSource.unknown) EnrollmentSource get source;@NullableUtcDateTimeConverter() DateTime? get lastActiveAt;@NullableUtcDateTimeConverter() DateTime? get completedAt; String? get lastLessonId;/// When access ends, from the academy's access length; absent for lifetime access.
@NullableUtcDateTimeConverter() DateTime? get expiresAt;
/// Create a copy of Enrollment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnrollmentCopyWith<Enrollment> get copyWith => _$EnrollmentCopyWithImpl<Enrollment>(this as Enrollment, _$identity);

  /// Serializes this Enrollment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Enrollment&&(identical(other.id, id) || other.id == id)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.enrolledAt, enrolledAt) || other.enrolledAt == enrolledAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.source, source) || other.source == source)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.lastLessonId, lastLessonId) || other.lastLessonId == lastLessonId)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,studentId,courseId,enrolledAt,status,progress,source,lastActiveAt,completedAt,lastLessonId,expiresAt);

@override
String toString() {
  return 'Enrollment(id: $id, studentId: $studentId, courseId: $courseId, enrolledAt: $enrolledAt, status: $status, progress: $progress, source: $source, lastActiveAt: $lastActiveAt, completedAt: $completedAt, lastLessonId: $lastLessonId, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $EnrollmentCopyWith<$Res>  {
  factory $EnrollmentCopyWith(Enrollment value, $Res Function(Enrollment) _then) = _$EnrollmentCopyWithImpl;
@useResult
$Res call({
 String id, String studentId, String courseId,@NullableUtcDateTimeConverter() DateTime? enrolledAt,@JsonKey(unknownEnumValue: EnrollmentStatus.unknown) EnrollmentStatus status, num progress,@JsonKey(unknownEnumValue: EnrollmentSource.unknown) EnrollmentSource source,@NullableUtcDateTimeConverter() DateTime? lastActiveAt,@NullableUtcDateTimeConverter() DateTime? completedAt, String? lastLessonId,@NullableUtcDateTimeConverter() DateTime? expiresAt
});




}
/// @nodoc
class _$EnrollmentCopyWithImpl<$Res>
    implements $EnrollmentCopyWith<$Res> {
  _$EnrollmentCopyWithImpl(this._self, this._then);

  final Enrollment _self;
  final $Res Function(Enrollment) _then;

/// Create a copy of Enrollment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? studentId = null,Object? courseId = null,Object? enrolledAt = freezed,Object? status = null,Object? progress = null,Object? source = null,Object? lastActiveAt = freezed,Object? completedAt = freezed,Object? lastLessonId = freezed,Object? expiresAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,enrolledAt: freezed == enrolledAt ? _self.enrolledAt : enrolledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EnrollmentStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as num,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as EnrollmentSource,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastLessonId: freezed == lastLessonId ? _self.lastLessonId : lastLessonId // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Enrollment].
extension EnrollmentPatterns on Enrollment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Enrollment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Enrollment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Enrollment value)  $default,){
final _that = this;
switch (_that) {
case _Enrollment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Enrollment value)?  $default,){
final _that = this;
switch (_that) {
case _Enrollment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String studentId,  String courseId, @NullableUtcDateTimeConverter()  DateTime? enrolledAt, @JsonKey(unknownEnumValue: EnrollmentStatus.unknown)  EnrollmentStatus status,  num progress, @JsonKey(unknownEnumValue: EnrollmentSource.unknown)  EnrollmentSource source, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt, @NullableUtcDateTimeConverter()  DateTime? completedAt,  String? lastLessonId, @NullableUtcDateTimeConverter()  DateTime? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Enrollment() when $default != null:
return $default(_that.id,_that.studentId,_that.courseId,_that.enrolledAt,_that.status,_that.progress,_that.source,_that.lastActiveAt,_that.completedAt,_that.lastLessonId,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String studentId,  String courseId, @NullableUtcDateTimeConverter()  DateTime? enrolledAt, @JsonKey(unknownEnumValue: EnrollmentStatus.unknown)  EnrollmentStatus status,  num progress, @JsonKey(unknownEnumValue: EnrollmentSource.unknown)  EnrollmentSource source, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt, @NullableUtcDateTimeConverter()  DateTime? completedAt,  String? lastLessonId, @NullableUtcDateTimeConverter()  DateTime? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _Enrollment():
return $default(_that.id,_that.studentId,_that.courseId,_that.enrolledAt,_that.status,_that.progress,_that.source,_that.lastActiveAt,_that.completedAt,_that.lastLessonId,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String studentId,  String courseId, @NullableUtcDateTimeConverter()  DateTime? enrolledAt, @JsonKey(unknownEnumValue: EnrollmentStatus.unknown)  EnrollmentStatus status,  num progress, @JsonKey(unknownEnumValue: EnrollmentSource.unknown)  EnrollmentSource source, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt, @NullableUtcDateTimeConverter()  DateTime? completedAt,  String? lastLessonId, @NullableUtcDateTimeConverter()  DateTime? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _Enrollment() when $default != null:
return $default(_that.id,_that.studentId,_that.courseId,_that.enrolledAt,_that.status,_that.progress,_that.source,_that.lastActiveAt,_that.completedAt,_that.lastLessonId,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Enrollment extends Enrollment {
  const _Enrollment({this.id = '', this.studentId = '', this.courseId = '', @NullableUtcDateTimeConverter() this.enrolledAt, @JsonKey(unknownEnumValue: EnrollmentStatus.unknown) this.status = EnrollmentStatus.active, this.progress = 0, @JsonKey(unknownEnumValue: EnrollmentSource.unknown) this.source = EnrollmentSource.self, @NullableUtcDateTimeConverter() this.lastActiveAt, @NullableUtcDateTimeConverter() this.completedAt, this.lastLessonId, @NullableUtcDateTimeConverter() this.expiresAt}): super._();
  factory _Enrollment.fromJson(Map<String, dynamic> json) => _$EnrollmentFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String studentId;
@override@JsonKey() final  String courseId;
@override@NullableUtcDateTimeConverter() final  DateTime? enrolledAt;
@override@JsonKey(unknownEnumValue: EnrollmentStatus.unknown) final  EnrollmentStatus status;
/// 0–100, weighted by lesson length the way course progress is.
@override@JsonKey() final  num progress;
@override@JsonKey(unknownEnumValue: EnrollmentSource.unknown) final  EnrollmentSource source;
@override@NullableUtcDateTimeConverter() final  DateTime? lastActiveAt;
@override@NullableUtcDateTimeConverter() final  DateTime? completedAt;
@override final  String? lastLessonId;
/// When access ends, from the academy's access length; absent for lifetime access.
@override@NullableUtcDateTimeConverter() final  DateTime? expiresAt;

/// Create a copy of Enrollment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnrollmentCopyWith<_Enrollment> get copyWith => __$EnrollmentCopyWithImpl<_Enrollment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnrollmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Enrollment&&(identical(other.id, id) || other.id == id)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.enrolledAt, enrolledAt) || other.enrolledAt == enrolledAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.source, source) || other.source == source)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.lastLessonId, lastLessonId) || other.lastLessonId == lastLessonId)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,studentId,courseId,enrolledAt,status,progress,source,lastActiveAt,completedAt,lastLessonId,expiresAt);

@override
String toString() {
  return 'Enrollment(id: $id, studentId: $studentId, courseId: $courseId, enrolledAt: $enrolledAt, status: $status, progress: $progress, source: $source, lastActiveAt: $lastActiveAt, completedAt: $completedAt, lastLessonId: $lastLessonId, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$EnrollmentCopyWith<$Res> implements $EnrollmentCopyWith<$Res> {
  factory _$EnrollmentCopyWith(_Enrollment value, $Res Function(_Enrollment) _then) = __$EnrollmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String studentId, String courseId,@NullableUtcDateTimeConverter() DateTime? enrolledAt,@JsonKey(unknownEnumValue: EnrollmentStatus.unknown) EnrollmentStatus status, num progress,@JsonKey(unknownEnumValue: EnrollmentSource.unknown) EnrollmentSource source,@NullableUtcDateTimeConverter() DateTime? lastActiveAt,@NullableUtcDateTimeConverter() DateTime? completedAt, String? lastLessonId,@NullableUtcDateTimeConverter() DateTime? expiresAt
});




}
/// @nodoc
class __$EnrollmentCopyWithImpl<$Res>
    implements _$EnrollmentCopyWith<$Res> {
  __$EnrollmentCopyWithImpl(this._self, this._then);

  final _Enrollment _self;
  final $Res Function(_Enrollment) _then;

/// Create a copy of Enrollment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? studentId = null,Object? courseId = null,Object? enrolledAt = freezed,Object? status = null,Object? progress = null,Object? source = null,Object? lastActiveAt = freezed,Object? completedAt = freezed,Object? lastLessonId = freezed,Object? expiresAt = freezed,}) {
  return _then(_Enrollment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,enrolledAt: freezed == enrolledAt ? _self.enrolledAt : enrolledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EnrollmentStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as num,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as EnrollmentSource,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastLessonId: freezed == lastLessonId ? _self.lastLessonId : lastLessonId // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
