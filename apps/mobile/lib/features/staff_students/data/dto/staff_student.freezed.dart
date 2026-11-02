// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'staff_student.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RosterCourse {

 String get id; String get title; num get progress;@JsonKey(unknownEnumValue: EnrollmentStatus.unknown) EnrollmentStatus get status;
/// Create a copy of RosterCourse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RosterCourseCopyWith<RosterCourse> get copyWith => _$RosterCourseCopyWithImpl<RosterCourse>(this as RosterCourse, _$identity);

  /// Serializes this RosterCourse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RosterCourse&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,progress,status);

@override
String toString() {
  return 'RosterCourse(id: $id, title: $title, progress: $progress, status: $status)';
}


}

/// @nodoc
abstract mixin class $RosterCourseCopyWith<$Res>  {
  factory $RosterCourseCopyWith(RosterCourse value, $Res Function(RosterCourse) _then) = _$RosterCourseCopyWithImpl;
@useResult
$Res call({
 String id, String title, num progress,@JsonKey(unknownEnumValue: EnrollmentStatus.unknown) EnrollmentStatus status
});




}
/// @nodoc
class _$RosterCourseCopyWithImpl<$Res>
    implements $RosterCourseCopyWith<$Res> {
  _$RosterCourseCopyWithImpl(this._self, this._then);

  final RosterCourse _self;
  final $Res Function(RosterCourse) _then;

/// Create a copy of RosterCourse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? progress = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as num,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EnrollmentStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [RosterCourse].
extension RosterCoursePatterns on RosterCourse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RosterCourse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RosterCourse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RosterCourse value)  $default,){
final _that = this;
switch (_that) {
case _RosterCourse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RosterCourse value)?  $default,){
final _that = this;
switch (_that) {
case _RosterCourse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  num progress, @JsonKey(unknownEnumValue: EnrollmentStatus.unknown)  EnrollmentStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RosterCourse() when $default != null:
return $default(_that.id,_that.title,_that.progress,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  num progress, @JsonKey(unknownEnumValue: EnrollmentStatus.unknown)  EnrollmentStatus status)  $default,) {final _that = this;
switch (_that) {
case _RosterCourse():
return $default(_that.id,_that.title,_that.progress,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  num progress, @JsonKey(unknownEnumValue: EnrollmentStatus.unknown)  EnrollmentStatus status)?  $default,) {final _that = this;
switch (_that) {
case _RosterCourse() when $default != null:
return $default(_that.id,_that.title,_that.progress,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RosterCourse implements RosterCourse {
  const _RosterCourse({this.id = '', this.title = '', this.progress = 0, @JsonKey(unknownEnumValue: EnrollmentStatus.unknown) this.status = EnrollmentStatus.active});
  factory _RosterCourse.fromJson(Map<String, dynamic> json) => _$RosterCourseFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String title;
@override@JsonKey() final  num progress;
@override@JsonKey(unknownEnumValue: EnrollmentStatus.unknown) final  EnrollmentStatus status;

/// Create a copy of RosterCourse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RosterCourseCopyWith<_RosterCourse> get copyWith => __$RosterCourseCopyWithImpl<_RosterCourse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RosterCourseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RosterCourse&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,progress,status);

@override
String toString() {
  return 'RosterCourse(id: $id, title: $title, progress: $progress, status: $status)';
}


}

/// @nodoc
abstract mixin class _$RosterCourseCopyWith<$Res> implements $RosterCourseCopyWith<$Res> {
  factory _$RosterCourseCopyWith(_RosterCourse value, $Res Function(_RosterCourse) _then) = __$RosterCourseCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, num progress,@JsonKey(unknownEnumValue: EnrollmentStatus.unknown) EnrollmentStatus status
});




}
/// @nodoc
class __$RosterCourseCopyWithImpl<$Res>
    implements _$RosterCourseCopyWith<$Res> {
  __$RosterCourseCopyWithImpl(this._self, this._then);

  final _RosterCourse _self;
  final $Res Function(_RosterCourse) _then;

/// Create a copy of RosterCourse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? progress = null,Object? status = null,}) {
  return _then(_RosterCourse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as num,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EnrollmentStatus,
  ));
}


}


/// @nodoc
mixin _$RosterRow {

 Student get student;@JsonKey(unknownEnumValue: StudentStatus.unknown) StudentStatus get status; List<RosterCourse> get courses; num get progress;
/// Create a copy of RosterRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RosterRowCopyWith<RosterRow> get copyWith => _$RosterRowCopyWithImpl<RosterRow>(this as RosterRow, _$identity);

  /// Serializes this RosterRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RosterRow&&(identical(other.student, student) || other.student == student)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.courses, courses)&&(identical(other.progress, progress) || other.progress == progress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,student,status,const DeepCollectionEquality().hash(courses),progress);

@override
String toString() {
  return 'RosterRow(student: $student, status: $status, courses: $courses, progress: $progress)';
}


}

/// @nodoc
abstract mixin class $RosterRowCopyWith<$Res>  {
  factory $RosterRowCopyWith(RosterRow value, $Res Function(RosterRow) _then) = _$RosterRowCopyWithImpl;
@useResult
$Res call({
 Student student,@JsonKey(unknownEnumValue: StudentStatus.unknown) StudentStatus status, List<RosterCourse> courses, num progress
});


$StudentCopyWith<$Res> get student;

}
/// @nodoc
class _$RosterRowCopyWithImpl<$Res>
    implements $RosterRowCopyWith<$Res> {
  _$RosterRowCopyWithImpl(this._self, this._then);

  final RosterRow _self;
  final $Res Function(RosterRow) _then;

/// Create a copy of RosterRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? student = null,Object? status = null,Object? courses = null,Object? progress = null,}) {
  return _then(_self.copyWith(
student: null == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as Student,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StudentStatus,courses: null == courses ? _self.courses : courses // ignore: cast_nullable_to_non_nullable
as List<RosterCourse>,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as num,
  ));
}
/// Create a copy of RosterRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StudentCopyWith<$Res> get student {
  
  return $StudentCopyWith<$Res>(_self.student, (value) {
    return _then(_self.copyWith(student: value));
  });
}
}


/// Adds pattern-matching-related methods to [RosterRow].
extension RosterRowPatterns on RosterRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RosterRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RosterRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RosterRow value)  $default,){
final _that = this;
switch (_that) {
case _RosterRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RosterRow value)?  $default,){
final _that = this;
switch (_that) {
case _RosterRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Student student, @JsonKey(unknownEnumValue: StudentStatus.unknown)  StudentStatus status,  List<RosterCourse> courses,  num progress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RosterRow() when $default != null:
return $default(_that.student,_that.status,_that.courses,_that.progress);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Student student, @JsonKey(unknownEnumValue: StudentStatus.unknown)  StudentStatus status,  List<RosterCourse> courses,  num progress)  $default,) {final _that = this;
switch (_that) {
case _RosterRow():
return $default(_that.student,_that.status,_that.courses,_that.progress);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Student student, @JsonKey(unknownEnumValue: StudentStatus.unknown)  StudentStatus status,  List<RosterCourse> courses,  num progress)?  $default,) {final _that = this;
switch (_that) {
case _RosterRow() when $default != null:
return $default(_that.student,_that.status,_that.courses,_that.progress);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RosterRow implements RosterRow {
  const _RosterRow({this.student = const Student(), @JsonKey(unknownEnumValue: StudentStatus.unknown) this.status = StudentStatus.unknown, final  List<RosterCourse> courses = const <RosterCourse>[], this.progress = 0}): _courses = courses;
  factory _RosterRow.fromJson(Map<String, dynamic> json) => _$RosterRowFromJson(json);

@override@JsonKey() final  Student student;
@override@JsonKey(unknownEnumValue: StudentStatus.unknown) final  StudentStatus status;
 final  List<RosterCourse> _courses;
@override@JsonKey() List<RosterCourse> get courses {
  if (_courses is EqualUnmodifiableListView) return _courses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_courses);
}

@override@JsonKey() final  num progress;

/// Create a copy of RosterRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RosterRowCopyWith<_RosterRow> get copyWith => __$RosterRowCopyWithImpl<_RosterRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RosterRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RosterRow&&(identical(other.student, student) || other.student == student)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._courses, _courses)&&(identical(other.progress, progress) || other.progress == progress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,student,status,const DeepCollectionEquality().hash(_courses),progress);

@override
String toString() {
  return 'RosterRow(student: $student, status: $status, courses: $courses, progress: $progress)';
}


}

/// @nodoc
abstract mixin class _$RosterRowCopyWith<$Res> implements $RosterRowCopyWith<$Res> {
  factory _$RosterRowCopyWith(_RosterRow value, $Res Function(_RosterRow) _then) = __$RosterRowCopyWithImpl;
@override @useResult
$Res call({
 Student student,@JsonKey(unknownEnumValue: StudentStatus.unknown) StudentStatus status, List<RosterCourse> courses, num progress
});


@override $StudentCopyWith<$Res> get student;

}
/// @nodoc
class __$RosterRowCopyWithImpl<$Res>
    implements _$RosterRowCopyWith<$Res> {
  __$RosterRowCopyWithImpl(this._self, this._then);

  final _RosterRow _self;
  final $Res Function(_RosterRow) _then;

/// Create a copy of RosterRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? student = null,Object? status = null,Object? courses = null,Object? progress = null,}) {
  return _then(_RosterRow(
student: null == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as Student,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StudentStatus,courses: null == courses ? _self._courses : courses // ignore: cast_nullable_to_non_nullable
as List<RosterCourse>,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

/// Create a copy of RosterRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StudentCopyWith<$Res> get student {
  
  return $StudentCopyWith<$Res>(_self.student, (value) {
    return _then(_self.copyWith(student: value));
  });
}
}


/// @nodoc
mixin _$RosterPage {

 List<RosterRow> get rows; int get total; Map<String, int> get counts;
/// Create a copy of RosterPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RosterPageCopyWith<RosterPage> get copyWith => _$RosterPageCopyWithImpl<RosterPage>(this as RosterPage, _$identity);

  /// Serializes this RosterPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RosterPage&&const DeepCollectionEquality().equals(other.rows, rows)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.counts, counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rows),total,const DeepCollectionEquality().hash(counts));

@override
String toString() {
  return 'RosterPage(rows: $rows, total: $total, counts: $counts)';
}


}

/// @nodoc
abstract mixin class $RosterPageCopyWith<$Res>  {
  factory $RosterPageCopyWith(RosterPage value, $Res Function(RosterPage) _then) = _$RosterPageCopyWithImpl;
@useResult
$Res call({
 List<RosterRow> rows, int total, Map<String, int> counts
});




}
/// @nodoc
class _$RosterPageCopyWithImpl<$Res>
    implements $RosterPageCopyWith<$Res> {
  _$RosterPageCopyWithImpl(this._self, this._then);

  final RosterPage _self;
  final $Res Function(RosterPage) _then;

/// Create a copy of RosterPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? total = null,Object? counts = null,}) {
  return _then(_self.copyWith(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<RosterRow>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [RosterPage].
extension RosterPagePatterns on RosterPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RosterPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RosterPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RosterPage value)  $default,){
final _that = this;
switch (_that) {
case _RosterPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RosterPage value)?  $default,){
final _that = this;
switch (_that) {
case _RosterPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<RosterRow> rows,  int total,  Map<String, int> counts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RosterPage() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<RosterRow> rows,  int total,  Map<String, int> counts)  $default,) {final _that = this;
switch (_that) {
case _RosterPage():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<RosterRow> rows,  int total,  Map<String, int> counts)?  $default,) {final _that = this;
switch (_that) {
case _RosterPage() when $default != null:
return $default(_that.rows,_that.total,_that.counts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RosterPage extends RosterPage {
  const _RosterPage({final  List<RosterRow> rows = const <RosterRow>[], this.total = 0, final  Map<String, int> counts = const <String, int>{}}): _rows = rows,_counts = counts,super._();
  factory _RosterPage.fromJson(Map<String, dynamic> json) => _$RosterPageFromJson(json);

 final  List<RosterRow> _rows;
@override@JsonKey() List<RosterRow> get rows {
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


/// Create a copy of RosterPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RosterPageCopyWith<_RosterPage> get copyWith => __$RosterPageCopyWithImpl<_RosterPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RosterPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RosterPage&&const DeepCollectionEquality().equals(other._rows, _rows)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._counts, _counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows),total,const DeepCollectionEquality().hash(_counts));

@override
String toString() {
  return 'RosterPage(rows: $rows, total: $total, counts: $counts)';
}


}

/// @nodoc
abstract mixin class _$RosterPageCopyWith<$Res> implements $RosterPageCopyWith<$Res> {
  factory _$RosterPageCopyWith(_RosterPage value, $Res Function(_RosterPage) _then) = __$RosterPageCopyWithImpl;
@override @useResult
$Res call({
 List<RosterRow> rows, int total, Map<String, int> counts
});




}
/// @nodoc
class __$RosterPageCopyWithImpl<$Res>
    implements _$RosterPageCopyWith<$Res> {
  __$RosterPageCopyWithImpl(this._self, this._then);

  final _RosterPage _self;
  final $Res Function(_RosterPage) _then;

/// Create a copy of RosterPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,Object? total = null,Object? counts = null,}) {
  return _then(_RosterPage(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<RosterRow>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self._counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}


/// @nodoc
mixin _$ChapterProgress {

 String get id; String get title; num get percent; int get completed; int get total;
/// Create a copy of ChapterProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChapterProgressCopyWith<ChapterProgress> get copyWith => _$ChapterProgressCopyWithImpl<ChapterProgress>(this as ChapterProgress, _$identity);

  /// Serializes this ChapterProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChapterProgress&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,percent,completed,total);

@override
String toString() {
  return 'ChapterProgress(id: $id, title: $title, percent: $percent, completed: $completed, total: $total)';
}


}

/// @nodoc
abstract mixin class $ChapterProgressCopyWith<$Res>  {
  factory $ChapterProgressCopyWith(ChapterProgress value, $Res Function(ChapterProgress) _then) = _$ChapterProgressCopyWithImpl;
@useResult
$Res call({
 String id, String title, num percent, int completed, int total
});




}
/// @nodoc
class _$ChapterProgressCopyWithImpl<$Res>
    implements $ChapterProgressCopyWith<$Res> {
  _$ChapterProgressCopyWithImpl(this._self, this._then);

  final ChapterProgress _self;
  final $Res Function(ChapterProgress) _then;

/// Create a copy of ChapterProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? percent = null,Object? completed = null,Object? total = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as num,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChapterProgress].
extension ChapterProgressPatterns on ChapterProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChapterProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChapterProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChapterProgress value)  $default,){
final _that = this;
switch (_that) {
case _ChapterProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChapterProgress value)?  $default,){
final _that = this;
switch (_that) {
case _ChapterProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  num percent,  int completed,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChapterProgress() when $default != null:
return $default(_that.id,_that.title,_that.percent,_that.completed,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  num percent,  int completed,  int total)  $default,) {final _that = this;
switch (_that) {
case _ChapterProgress():
return $default(_that.id,_that.title,_that.percent,_that.completed,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  num percent,  int completed,  int total)?  $default,) {final _that = this;
switch (_that) {
case _ChapterProgress() when $default != null:
return $default(_that.id,_that.title,_that.percent,_that.completed,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChapterProgress implements ChapterProgress {
  const _ChapterProgress({this.id = '', this.title = '', this.percent = 0, this.completed = 0, this.total = 0});
  factory _ChapterProgress.fromJson(Map<String, dynamic> json) => _$ChapterProgressFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String title;
@override@JsonKey() final  num percent;
@override@JsonKey() final  int completed;
@override@JsonKey() final  int total;

/// Create a copy of ChapterProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChapterProgressCopyWith<_ChapterProgress> get copyWith => __$ChapterProgressCopyWithImpl<_ChapterProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChapterProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChapterProgress&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,percent,completed,total);

@override
String toString() {
  return 'ChapterProgress(id: $id, title: $title, percent: $percent, completed: $completed, total: $total)';
}


}

/// @nodoc
abstract mixin class _$ChapterProgressCopyWith<$Res> implements $ChapterProgressCopyWith<$Res> {
  factory _$ChapterProgressCopyWith(_ChapterProgress value, $Res Function(_ChapterProgress) _then) = __$ChapterProgressCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, num percent, int completed, int total
});




}
/// @nodoc
class __$ChapterProgressCopyWithImpl<$Res>
    implements _$ChapterProgressCopyWith<$Res> {
  __$ChapterProgressCopyWithImpl(this._self, this._then);

  final _ChapterProgress _self;
  final $Res Function(_ChapterProgress) _then;

/// Create a copy of ChapterProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? percent = null,Object? completed = null,Object? total = null,}) {
  return _then(_ChapterProgress(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as num,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StudentEnrollment {

 Enrollment get enrollment; String get courseTitle; String get levelTitle; String? get categoryId; List<String> get instructorNames; DonePair get chapters; DonePair get lessons;/// Where they are up to; absent once the course is finished.
 String? get lastLessonTitle; String? get certificateTitle;
/// Create a copy of StudentEnrollment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentEnrollmentCopyWith<StudentEnrollment> get copyWith => _$StudentEnrollmentCopyWithImpl<StudentEnrollment>(this as StudentEnrollment, _$identity);

  /// Serializes this StudentEnrollment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudentEnrollment&&(identical(other.enrollment, enrollment) || other.enrollment == enrollment)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.levelTitle, levelTitle) || other.levelTitle == levelTitle)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&const DeepCollectionEquality().equals(other.instructorNames, instructorNames)&&(identical(other.chapters, chapters) || other.chapters == chapters)&&(identical(other.lessons, lessons) || other.lessons == lessons)&&(identical(other.lastLessonTitle, lastLessonTitle) || other.lastLessonTitle == lastLessonTitle)&&(identical(other.certificateTitle, certificateTitle) || other.certificateTitle == certificateTitle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrollment,courseTitle,levelTitle,categoryId,const DeepCollectionEquality().hash(instructorNames),chapters,lessons,lastLessonTitle,certificateTitle);

@override
String toString() {
  return 'StudentEnrollment(enrollment: $enrollment, courseTitle: $courseTitle, levelTitle: $levelTitle, categoryId: $categoryId, instructorNames: $instructorNames, chapters: $chapters, lessons: $lessons, lastLessonTitle: $lastLessonTitle, certificateTitle: $certificateTitle)';
}


}

/// @nodoc
abstract mixin class $StudentEnrollmentCopyWith<$Res>  {
  factory $StudentEnrollmentCopyWith(StudentEnrollment value, $Res Function(StudentEnrollment) _then) = _$StudentEnrollmentCopyWithImpl;
@useResult
$Res call({
 Enrollment enrollment, String courseTitle, String levelTitle, String? categoryId, List<String> instructorNames, DonePair chapters, DonePair lessons, String? lastLessonTitle, String? certificateTitle
});


$EnrollmentCopyWith<$Res> get enrollment;$DonePairCopyWith<$Res> get chapters;$DonePairCopyWith<$Res> get lessons;

}
/// @nodoc
class _$StudentEnrollmentCopyWithImpl<$Res>
    implements $StudentEnrollmentCopyWith<$Res> {
  _$StudentEnrollmentCopyWithImpl(this._self, this._then);

  final StudentEnrollment _self;
  final $Res Function(StudentEnrollment) _then;

/// Create a copy of StudentEnrollment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enrollment = null,Object? courseTitle = null,Object? levelTitle = null,Object? categoryId = freezed,Object? instructorNames = null,Object? chapters = null,Object? lessons = null,Object? lastLessonTitle = freezed,Object? certificateTitle = freezed,}) {
  return _then(_self.copyWith(
enrollment: null == enrollment ? _self.enrollment : enrollment // ignore: cast_nullable_to_non_nullable
as Enrollment,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,levelTitle: null == levelTitle ? _self.levelTitle : levelTitle // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,instructorNames: null == instructorNames ? _self.instructorNames : instructorNames // ignore: cast_nullable_to_non_nullable
as List<String>,chapters: null == chapters ? _self.chapters : chapters // ignore: cast_nullable_to_non_nullable
as DonePair,lessons: null == lessons ? _self.lessons : lessons // ignore: cast_nullable_to_non_nullable
as DonePair,lastLessonTitle: freezed == lastLessonTitle ? _self.lastLessonTitle : lastLessonTitle // ignore: cast_nullable_to_non_nullable
as String?,certificateTitle: freezed == certificateTitle ? _self.certificateTitle : certificateTitle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of StudentEnrollment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EnrollmentCopyWith<$Res> get enrollment {
  
  return $EnrollmentCopyWith<$Res>(_self.enrollment, (value) {
    return _then(_self.copyWith(enrollment: value));
  });
}/// Create a copy of StudentEnrollment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DonePairCopyWith<$Res> get chapters {
  
  return $DonePairCopyWith<$Res>(_self.chapters, (value) {
    return _then(_self.copyWith(chapters: value));
  });
}/// Create a copy of StudentEnrollment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DonePairCopyWith<$Res> get lessons {
  
  return $DonePairCopyWith<$Res>(_self.lessons, (value) {
    return _then(_self.copyWith(lessons: value));
  });
}
}


/// Adds pattern-matching-related methods to [StudentEnrollment].
extension StudentEnrollmentPatterns on StudentEnrollment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudentEnrollment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudentEnrollment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudentEnrollment value)  $default,){
final _that = this;
switch (_that) {
case _StudentEnrollment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudentEnrollment value)?  $default,){
final _that = this;
switch (_that) {
case _StudentEnrollment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Enrollment enrollment,  String courseTitle,  String levelTitle,  String? categoryId,  List<String> instructorNames,  DonePair chapters,  DonePair lessons,  String? lastLessonTitle,  String? certificateTitle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudentEnrollment() when $default != null:
return $default(_that.enrollment,_that.courseTitle,_that.levelTitle,_that.categoryId,_that.instructorNames,_that.chapters,_that.lessons,_that.lastLessonTitle,_that.certificateTitle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Enrollment enrollment,  String courseTitle,  String levelTitle,  String? categoryId,  List<String> instructorNames,  DonePair chapters,  DonePair lessons,  String? lastLessonTitle,  String? certificateTitle)  $default,) {final _that = this;
switch (_that) {
case _StudentEnrollment():
return $default(_that.enrollment,_that.courseTitle,_that.levelTitle,_that.categoryId,_that.instructorNames,_that.chapters,_that.lessons,_that.lastLessonTitle,_that.certificateTitle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Enrollment enrollment,  String courseTitle,  String levelTitle,  String? categoryId,  List<String> instructorNames,  DonePair chapters,  DonePair lessons,  String? lastLessonTitle,  String? certificateTitle)?  $default,) {final _that = this;
switch (_that) {
case _StudentEnrollment() when $default != null:
return $default(_that.enrollment,_that.courseTitle,_that.levelTitle,_that.categoryId,_that.instructorNames,_that.chapters,_that.lessons,_that.lastLessonTitle,_that.certificateTitle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudentEnrollment implements StudentEnrollment {
  const _StudentEnrollment({this.enrollment = const Enrollment(), this.courseTitle = '', this.levelTitle = '', this.categoryId, final  List<String> instructorNames = const <String>[], this.chapters = const DonePair(), this.lessons = const DonePair(), this.lastLessonTitle, this.certificateTitle}): _instructorNames = instructorNames;
  factory _StudentEnrollment.fromJson(Map<String, dynamic> json) => _$StudentEnrollmentFromJson(json);

@override@JsonKey() final  Enrollment enrollment;
@override@JsonKey() final  String courseTitle;
@override@JsonKey() final  String levelTitle;
@override final  String? categoryId;
 final  List<String> _instructorNames;
@override@JsonKey() List<String> get instructorNames {
  if (_instructorNames is EqualUnmodifiableListView) return _instructorNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_instructorNames);
}

@override@JsonKey() final  DonePair chapters;
@override@JsonKey() final  DonePair lessons;
/// Where they are up to; absent once the course is finished.
@override final  String? lastLessonTitle;
@override final  String? certificateTitle;

/// Create a copy of StudentEnrollment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentEnrollmentCopyWith<_StudentEnrollment> get copyWith => __$StudentEnrollmentCopyWithImpl<_StudentEnrollment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudentEnrollmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudentEnrollment&&(identical(other.enrollment, enrollment) || other.enrollment == enrollment)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.levelTitle, levelTitle) || other.levelTitle == levelTitle)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&const DeepCollectionEquality().equals(other._instructorNames, _instructorNames)&&(identical(other.chapters, chapters) || other.chapters == chapters)&&(identical(other.lessons, lessons) || other.lessons == lessons)&&(identical(other.lastLessonTitle, lastLessonTitle) || other.lastLessonTitle == lastLessonTitle)&&(identical(other.certificateTitle, certificateTitle) || other.certificateTitle == certificateTitle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrollment,courseTitle,levelTitle,categoryId,const DeepCollectionEquality().hash(_instructorNames),chapters,lessons,lastLessonTitle,certificateTitle);

@override
String toString() {
  return 'StudentEnrollment(enrollment: $enrollment, courseTitle: $courseTitle, levelTitle: $levelTitle, categoryId: $categoryId, instructorNames: $instructorNames, chapters: $chapters, lessons: $lessons, lastLessonTitle: $lastLessonTitle, certificateTitle: $certificateTitle)';
}


}

/// @nodoc
abstract mixin class _$StudentEnrollmentCopyWith<$Res> implements $StudentEnrollmentCopyWith<$Res> {
  factory _$StudentEnrollmentCopyWith(_StudentEnrollment value, $Res Function(_StudentEnrollment) _then) = __$StudentEnrollmentCopyWithImpl;
@override @useResult
$Res call({
 Enrollment enrollment, String courseTitle, String levelTitle, String? categoryId, List<String> instructorNames, DonePair chapters, DonePair lessons, String? lastLessonTitle, String? certificateTitle
});


@override $EnrollmentCopyWith<$Res> get enrollment;@override $DonePairCopyWith<$Res> get chapters;@override $DonePairCopyWith<$Res> get lessons;

}
/// @nodoc
class __$StudentEnrollmentCopyWithImpl<$Res>
    implements _$StudentEnrollmentCopyWith<$Res> {
  __$StudentEnrollmentCopyWithImpl(this._self, this._then);

  final _StudentEnrollment _self;
  final $Res Function(_StudentEnrollment) _then;

/// Create a copy of StudentEnrollment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enrollment = null,Object? courseTitle = null,Object? levelTitle = null,Object? categoryId = freezed,Object? instructorNames = null,Object? chapters = null,Object? lessons = null,Object? lastLessonTitle = freezed,Object? certificateTitle = freezed,}) {
  return _then(_StudentEnrollment(
enrollment: null == enrollment ? _self.enrollment : enrollment // ignore: cast_nullable_to_non_nullable
as Enrollment,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,levelTitle: null == levelTitle ? _self.levelTitle : levelTitle // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,instructorNames: null == instructorNames ? _self._instructorNames : instructorNames // ignore: cast_nullable_to_non_nullable
as List<String>,chapters: null == chapters ? _self.chapters : chapters // ignore: cast_nullable_to_non_nullable
as DonePair,lessons: null == lessons ? _self.lessons : lessons // ignore: cast_nullable_to_non_nullable
as DonePair,lastLessonTitle: freezed == lastLessonTitle ? _self.lastLessonTitle : lastLessonTitle // ignore: cast_nullable_to_non_nullable
as String?,certificateTitle: freezed == certificateTitle ? _self.certificateTitle : certificateTitle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of StudentEnrollment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EnrollmentCopyWith<$Res> get enrollment {
  
  return $EnrollmentCopyWith<$Res>(_self.enrollment, (value) {
    return _then(_self.copyWith(enrollment: value));
  });
}/// Create a copy of StudentEnrollment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DonePairCopyWith<$Res> get chapters {
  
  return $DonePairCopyWith<$Res>(_self.chapters, (value) {
    return _then(_self.copyWith(chapters: value));
  });
}/// Create a copy of StudentEnrollment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DonePairCopyWith<$Res> get lessons {
  
  return $DonePairCopyWith<$Res>(_self.lessons, (value) {
    return _then(_self.copyWith(lessons: value));
  });
}
}


/// @nodoc
mixin _$DonePair {

 int get done; int get total;
/// Create a copy of DonePair
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DonePairCopyWith<DonePair> get copyWith => _$DonePairCopyWithImpl<DonePair>(this as DonePair, _$identity);

  /// Serializes this DonePair to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DonePair&&(identical(other.done, done) || other.done == done)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,done,total);

@override
String toString() {
  return 'DonePair(done: $done, total: $total)';
}


}

/// @nodoc
abstract mixin class $DonePairCopyWith<$Res>  {
  factory $DonePairCopyWith(DonePair value, $Res Function(DonePair) _then) = _$DonePairCopyWithImpl;
@useResult
$Res call({
 int done, int total
});




}
/// @nodoc
class _$DonePairCopyWithImpl<$Res>
    implements $DonePairCopyWith<$Res> {
  _$DonePairCopyWithImpl(this._self, this._then);

  final DonePair _self;
  final $Res Function(DonePair) _then;

/// Create a copy of DonePair
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? done = null,Object? total = null,}) {
  return _then(_self.copyWith(
done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DonePair].
extension DonePairPatterns on DonePair {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DonePair value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DonePair() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DonePair value)  $default,){
final _that = this;
switch (_that) {
case _DonePair():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DonePair value)?  $default,){
final _that = this;
switch (_that) {
case _DonePair() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int done,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DonePair() when $default != null:
return $default(_that.done,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int done,  int total)  $default,) {final _that = this;
switch (_that) {
case _DonePair():
return $default(_that.done,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int done,  int total)?  $default,) {final _that = this;
switch (_that) {
case _DonePair() when $default != null:
return $default(_that.done,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DonePair extends DonePair {
  const _DonePair({this.done = 0, this.total = 0}): super._();
  factory _DonePair.fromJson(Map<String, dynamic> json) => _$DonePairFromJson(json);

@override@JsonKey() final  int done;
@override@JsonKey() final  int total;

/// Create a copy of DonePair
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DonePairCopyWith<_DonePair> get copyWith => __$DonePairCopyWithImpl<_DonePair>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DonePairToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DonePair&&(identical(other.done, done) || other.done == done)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,done,total);

@override
String toString() {
  return 'DonePair(done: $done, total: $total)';
}


}

/// @nodoc
abstract mixin class _$DonePairCopyWith<$Res> implements $DonePairCopyWith<$Res> {
  factory _$DonePairCopyWith(_DonePair value, $Res Function(_DonePair) _then) = __$DonePairCopyWithImpl;
@override @useResult
$Res call({
 int done, int total
});




}
/// @nodoc
class __$DonePairCopyWithImpl<$Res>
    implements _$DonePairCopyWith<$Res> {
  __$DonePairCopyWithImpl(this._self, this._then);

  final _DonePair _self;
  final $Res Function(_DonePair) _then;

/// Create a copy of DonePair
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? done = null,Object? total = null,}) {
  return _then(_DonePair(
done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StudentSummary {

 int get enrolled; int get active; int get completed; num get avgProgress; int get studyMinutes; int get submissions; num? get avgScore;
/// Create a copy of StudentSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentSummaryCopyWith<StudentSummary> get copyWith => _$StudentSummaryCopyWithImpl<StudentSummary>(this as StudentSummary, _$identity);

  /// Serializes this StudentSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudentSummary&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.active, active) || other.active == active)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.avgProgress, avgProgress) || other.avgProgress == avgProgress)&&(identical(other.studyMinutes, studyMinutes) || other.studyMinutes == studyMinutes)&&(identical(other.submissions, submissions) || other.submissions == submissions)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrolled,active,completed,avgProgress,studyMinutes,submissions,avgScore);

@override
String toString() {
  return 'StudentSummary(enrolled: $enrolled, active: $active, completed: $completed, avgProgress: $avgProgress, studyMinutes: $studyMinutes, submissions: $submissions, avgScore: $avgScore)';
}


}

/// @nodoc
abstract mixin class $StudentSummaryCopyWith<$Res>  {
  factory $StudentSummaryCopyWith(StudentSummary value, $Res Function(StudentSummary) _then) = _$StudentSummaryCopyWithImpl;
@useResult
$Res call({
 int enrolled, int active, int completed, num avgProgress, int studyMinutes, int submissions, num? avgScore
});




}
/// @nodoc
class _$StudentSummaryCopyWithImpl<$Res>
    implements $StudentSummaryCopyWith<$Res> {
  _$StudentSummaryCopyWithImpl(this._self, this._then);

  final StudentSummary _self;
  final $Res Function(StudentSummary) _then;

/// Create a copy of StudentSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enrolled = null,Object? active = null,Object? completed = null,Object? avgProgress = null,Object? studyMinutes = null,Object? submissions = null,Object? avgScore = freezed,}) {
  return _then(_self.copyWith(
enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as int,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int,avgProgress: null == avgProgress ? _self.avgProgress : avgProgress // ignore: cast_nullable_to_non_nullable
as num,studyMinutes: null == studyMinutes ? _self.studyMinutes : studyMinutes // ignore: cast_nullable_to_non_nullable
as int,submissions: null == submissions ? _self.submissions : submissions // ignore: cast_nullable_to_non_nullable
as int,avgScore: freezed == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}

}


/// Adds pattern-matching-related methods to [StudentSummary].
extension StudentSummaryPatterns on StudentSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudentSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudentSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudentSummary value)  $default,){
final _that = this;
switch (_that) {
case _StudentSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudentSummary value)?  $default,){
final _that = this;
switch (_that) {
case _StudentSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int enrolled,  int active,  int completed,  num avgProgress,  int studyMinutes,  int submissions,  num? avgScore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudentSummary() when $default != null:
return $default(_that.enrolled,_that.active,_that.completed,_that.avgProgress,_that.studyMinutes,_that.submissions,_that.avgScore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int enrolled,  int active,  int completed,  num avgProgress,  int studyMinutes,  int submissions,  num? avgScore)  $default,) {final _that = this;
switch (_that) {
case _StudentSummary():
return $default(_that.enrolled,_that.active,_that.completed,_that.avgProgress,_that.studyMinutes,_that.submissions,_that.avgScore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int enrolled,  int active,  int completed,  num avgProgress,  int studyMinutes,  int submissions,  num? avgScore)?  $default,) {final _that = this;
switch (_that) {
case _StudentSummary() when $default != null:
return $default(_that.enrolled,_that.active,_that.completed,_that.avgProgress,_that.studyMinutes,_that.submissions,_that.avgScore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudentSummary implements StudentSummary {
  const _StudentSummary({this.enrolled = 0, this.active = 0, this.completed = 0, this.avgProgress = 0, this.studyMinutes = 0, this.submissions = 0, this.avgScore});
  factory _StudentSummary.fromJson(Map<String, dynamic> json) => _$StudentSummaryFromJson(json);

@override@JsonKey() final  int enrolled;
@override@JsonKey() final  int active;
@override@JsonKey() final  int completed;
@override@JsonKey() final  num avgProgress;
@override@JsonKey() final  int studyMinutes;
@override@JsonKey() final  int submissions;
@override final  num? avgScore;

/// Create a copy of StudentSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentSummaryCopyWith<_StudentSummary> get copyWith => __$StudentSummaryCopyWithImpl<_StudentSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudentSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudentSummary&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.active, active) || other.active == active)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.avgProgress, avgProgress) || other.avgProgress == avgProgress)&&(identical(other.studyMinutes, studyMinutes) || other.studyMinutes == studyMinutes)&&(identical(other.submissions, submissions) || other.submissions == submissions)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrolled,active,completed,avgProgress,studyMinutes,submissions,avgScore);

@override
String toString() {
  return 'StudentSummary(enrolled: $enrolled, active: $active, completed: $completed, avgProgress: $avgProgress, studyMinutes: $studyMinutes, submissions: $submissions, avgScore: $avgScore)';
}


}

/// @nodoc
abstract mixin class _$StudentSummaryCopyWith<$Res> implements $StudentSummaryCopyWith<$Res> {
  factory _$StudentSummaryCopyWith(_StudentSummary value, $Res Function(_StudentSummary) _then) = __$StudentSummaryCopyWithImpl;
@override @useResult
$Res call({
 int enrolled, int active, int completed, num avgProgress, int studyMinutes, int submissions, num? avgScore
});




}
/// @nodoc
class __$StudentSummaryCopyWithImpl<$Res>
    implements _$StudentSummaryCopyWith<$Res> {
  __$StudentSummaryCopyWithImpl(this._self, this._then);

  final _StudentSummary _self;
  final $Res Function(_StudentSummary) _then;

/// Create a copy of StudentSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enrolled = null,Object? active = null,Object? completed = null,Object? avgProgress = null,Object? studyMinutes = null,Object? submissions = null,Object? avgScore = freezed,}) {
  return _then(_StudentSummary(
enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as int,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int,avgProgress: null == avgProgress ? _self.avgProgress : avgProgress // ignore: cast_nullable_to_non_nullable
as num,studyMinutes: null == studyMinutes ? _self.studyMinutes : studyMinutes // ignore: cast_nullable_to_non_nullable
as int,submissions: null == submissions ? _self.submissions : submissions // ignore: cast_nullable_to_non_nullable
as int,avgScore: freezed == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}


}


/// @nodoc
mixin _$StudentCertificate {

 String get id; String get courseId; String get courseTitle; String get title;@NullableUtcDateTimeConverter() DateTime? get issuedAt; String get credentialId;
/// Create a copy of StudentCertificate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentCertificateCopyWith<StudentCertificate> get copyWith => _$StudentCertificateCopyWithImpl<StudentCertificate>(this as StudentCertificate, _$identity);

  /// Serializes this StudentCertificate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudentCertificate&&(identical(other.id, id) || other.id == id)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.title, title) || other.title == title)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.credentialId, credentialId) || other.credentialId == credentialId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,courseId,courseTitle,title,issuedAt,credentialId);

@override
String toString() {
  return 'StudentCertificate(id: $id, courseId: $courseId, courseTitle: $courseTitle, title: $title, issuedAt: $issuedAt, credentialId: $credentialId)';
}


}

/// @nodoc
abstract mixin class $StudentCertificateCopyWith<$Res>  {
  factory $StudentCertificateCopyWith(StudentCertificate value, $Res Function(StudentCertificate) _then) = _$StudentCertificateCopyWithImpl;
@useResult
$Res call({
 String id, String courseId, String courseTitle, String title,@NullableUtcDateTimeConverter() DateTime? issuedAt, String credentialId
});




}
/// @nodoc
class _$StudentCertificateCopyWithImpl<$Res>
    implements $StudentCertificateCopyWith<$Res> {
  _$StudentCertificateCopyWithImpl(this._self, this._then);

  final StudentCertificate _self;
  final $Res Function(StudentCertificate) _then;

/// Create a copy of StudentCertificate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? courseId = null,Object? courseTitle = null,Object? title = null,Object? issuedAt = freezed,Object? credentialId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,credentialId: null == credentialId ? _self.credentialId : credentialId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StudentCertificate].
extension StudentCertificatePatterns on StudentCertificate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudentCertificate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudentCertificate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudentCertificate value)  $default,){
final _that = this;
switch (_that) {
case _StudentCertificate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudentCertificate value)?  $default,){
final _that = this;
switch (_that) {
case _StudentCertificate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String courseId,  String courseTitle,  String title, @NullableUtcDateTimeConverter()  DateTime? issuedAt,  String credentialId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudentCertificate() when $default != null:
return $default(_that.id,_that.courseId,_that.courseTitle,_that.title,_that.issuedAt,_that.credentialId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String courseId,  String courseTitle,  String title, @NullableUtcDateTimeConverter()  DateTime? issuedAt,  String credentialId)  $default,) {final _that = this;
switch (_that) {
case _StudentCertificate():
return $default(_that.id,_that.courseId,_that.courseTitle,_that.title,_that.issuedAt,_that.credentialId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String courseId,  String courseTitle,  String title, @NullableUtcDateTimeConverter()  DateTime? issuedAt,  String credentialId)?  $default,) {final _that = this;
switch (_that) {
case _StudentCertificate() when $default != null:
return $default(_that.id,_that.courseId,_that.courseTitle,_that.title,_that.issuedAt,_that.credentialId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudentCertificate implements StudentCertificate {
  const _StudentCertificate({this.id = '', this.courseId = '', this.courseTitle = '', this.title = '', @NullableUtcDateTimeConverter() this.issuedAt, this.credentialId = ''});
  factory _StudentCertificate.fromJson(Map<String, dynamic> json) => _$StudentCertificateFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String courseId;
@override@JsonKey() final  String courseTitle;
@override@JsonKey() final  String title;
@override@NullableUtcDateTimeConverter() final  DateTime? issuedAt;
@override@JsonKey() final  String credentialId;

/// Create a copy of StudentCertificate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentCertificateCopyWith<_StudentCertificate> get copyWith => __$StudentCertificateCopyWithImpl<_StudentCertificate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudentCertificateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudentCertificate&&(identical(other.id, id) || other.id == id)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.title, title) || other.title == title)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.credentialId, credentialId) || other.credentialId == credentialId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,courseId,courseTitle,title,issuedAt,credentialId);

@override
String toString() {
  return 'StudentCertificate(id: $id, courseId: $courseId, courseTitle: $courseTitle, title: $title, issuedAt: $issuedAt, credentialId: $credentialId)';
}


}

/// @nodoc
abstract mixin class _$StudentCertificateCopyWith<$Res> implements $StudentCertificateCopyWith<$Res> {
  factory _$StudentCertificateCopyWith(_StudentCertificate value, $Res Function(_StudentCertificate) _then) = __$StudentCertificateCopyWithImpl;
@override @useResult
$Res call({
 String id, String courseId, String courseTitle, String title,@NullableUtcDateTimeConverter() DateTime? issuedAt, String credentialId
});




}
/// @nodoc
class __$StudentCertificateCopyWithImpl<$Res>
    implements _$StudentCertificateCopyWith<$Res> {
  __$StudentCertificateCopyWithImpl(this._self, this._then);

  final _StudentCertificate _self;
  final $Res Function(_StudentCertificate) _then;

/// Create a copy of StudentCertificate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? courseId = null,Object? courseTitle = null,Object? title = null,Object? issuedAt = freezed,Object? credentialId = null,}) {
  return _then(_StudentCertificate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,credentialId: null == credentialId ? _self.credentialId : credentialId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$StudentProfile {

 Student get student;@JsonKey(unknownEnumValue: StudentStatus.unknown) StudentStatus get status;/// Days since the learner last opened anything, as the academy counted them.
 int get quietDays; Rank get rank; List<StudentEnrollment> get enrollments; List<StudentCertificate> get certificates; StudentSummary get summary;
/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentProfileCopyWith<StudentProfile> get copyWith => _$StudentProfileCopyWithImpl<StudentProfile>(this as StudentProfile, _$identity);

  /// Serializes this StudentProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudentProfile&&(identical(other.student, student) || other.student == student)&&(identical(other.status, status) || other.status == status)&&(identical(other.quietDays, quietDays) || other.quietDays == quietDays)&&(identical(other.rank, rank) || other.rank == rank)&&const DeepCollectionEquality().equals(other.enrollments, enrollments)&&const DeepCollectionEquality().equals(other.certificates, certificates)&&(identical(other.summary, summary) || other.summary == summary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,student,status,quietDays,rank,const DeepCollectionEquality().hash(enrollments),const DeepCollectionEquality().hash(certificates),summary);

@override
String toString() {
  return 'StudentProfile(student: $student, status: $status, quietDays: $quietDays, rank: $rank, enrollments: $enrollments, certificates: $certificates, summary: $summary)';
}


}

/// @nodoc
abstract mixin class $StudentProfileCopyWith<$Res>  {
  factory $StudentProfileCopyWith(StudentProfile value, $Res Function(StudentProfile) _then) = _$StudentProfileCopyWithImpl;
@useResult
$Res call({
 Student student,@JsonKey(unknownEnumValue: StudentStatus.unknown) StudentStatus status, int quietDays, Rank rank, List<StudentEnrollment> enrollments, List<StudentCertificate> certificates, StudentSummary summary
});


$StudentCopyWith<$Res> get student;$RankCopyWith<$Res> get rank;$StudentSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$StudentProfileCopyWithImpl<$Res>
    implements $StudentProfileCopyWith<$Res> {
  _$StudentProfileCopyWithImpl(this._self, this._then);

  final StudentProfile _self;
  final $Res Function(StudentProfile) _then;

/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? student = null,Object? status = null,Object? quietDays = null,Object? rank = null,Object? enrollments = null,Object? certificates = null,Object? summary = null,}) {
  return _then(_self.copyWith(
student: null == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as Student,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StudentStatus,quietDays: null == quietDays ? _self.quietDays : quietDays // ignore: cast_nullable_to_non_nullable
as int,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as Rank,enrollments: null == enrollments ? _self.enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as List<StudentEnrollment>,certificates: null == certificates ? _self.certificates : certificates // ignore: cast_nullable_to_non_nullable
as List<StudentCertificate>,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as StudentSummary,
  ));
}
/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StudentCopyWith<$Res> get student {
  
  return $StudentCopyWith<$Res>(_self.student, (value) {
    return _then(_self.copyWith(student: value));
  });
}/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RankCopyWith<$Res> get rank {
  
  return $RankCopyWith<$Res>(_self.rank, (value) {
    return _then(_self.copyWith(rank: value));
  });
}/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StudentSummaryCopyWith<$Res> get summary {
  
  return $StudentSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// Adds pattern-matching-related methods to [StudentProfile].
extension StudentProfilePatterns on StudentProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudentProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudentProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudentProfile value)  $default,){
final _that = this;
switch (_that) {
case _StudentProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudentProfile value)?  $default,){
final _that = this;
switch (_that) {
case _StudentProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Student student, @JsonKey(unknownEnumValue: StudentStatus.unknown)  StudentStatus status,  int quietDays,  Rank rank,  List<StudentEnrollment> enrollments,  List<StudentCertificate> certificates,  StudentSummary summary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudentProfile() when $default != null:
return $default(_that.student,_that.status,_that.quietDays,_that.rank,_that.enrollments,_that.certificates,_that.summary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Student student, @JsonKey(unknownEnumValue: StudentStatus.unknown)  StudentStatus status,  int quietDays,  Rank rank,  List<StudentEnrollment> enrollments,  List<StudentCertificate> certificates,  StudentSummary summary)  $default,) {final _that = this;
switch (_that) {
case _StudentProfile():
return $default(_that.student,_that.status,_that.quietDays,_that.rank,_that.enrollments,_that.certificates,_that.summary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Student student, @JsonKey(unknownEnumValue: StudentStatus.unknown)  StudentStatus status,  int quietDays,  Rank rank,  List<StudentEnrollment> enrollments,  List<StudentCertificate> certificates,  StudentSummary summary)?  $default,) {final _that = this;
switch (_that) {
case _StudentProfile() when $default != null:
return $default(_that.student,_that.status,_that.quietDays,_that.rank,_that.enrollments,_that.certificates,_that.summary);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudentProfile implements StudentProfile {
  const _StudentProfile({this.student = const Student(), @JsonKey(unknownEnumValue: StudentStatus.unknown) this.status = StudentStatus.unknown, this.quietDays = 0, this.rank = const Rank(), final  List<StudentEnrollment> enrollments = const <StudentEnrollment>[], final  List<StudentCertificate> certificates = const <StudentCertificate>[], this.summary = const StudentSummary()}): _enrollments = enrollments,_certificates = certificates;
  factory _StudentProfile.fromJson(Map<String, dynamic> json) => _$StudentProfileFromJson(json);

@override@JsonKey() final  Student student;
@override@JsonKey(unknownEnumValue: StudentStatus.unknown) final  StudentStatus status;
/// Days since the learner last opened anything, as the academy counted them.
@override@JsonKey() final  int quietDays;
@override@JsonKey() final  Rank rank;
 final  List<StudentEnrollment> _enrollments;
@override@JsonKey() List<StudentEnrollment> get enrollments {
  if (_enrollments is EqualUnmodifiableListView) return _enrollments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_enrollments);
}

 final  List<StudentCertificate> _certificates;
@override@JsonKey() List<StudentCertificate> get certificates {
  if (_certificates is EqualUnmodifiableListView) return _certificates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_certificates);
}

@override@JsonKey() final  StudentSummary summary;

/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentProfileCopyWith<_StudentProfile> get copyWith => __$StudentProfileCopyWithImpl<_StudentProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudentProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudentProfile&&(identical(other.student, student) || other.student == student)&&(identical(other.status, status) || other.status == status)&&(identical(other.quietDays, quietDays) || other.quietDays == quietDays)&&(identical(other.rank, rank) || other.rank == rank)&&const DeepCollectionEquality().equals(other._enrollments, _enrollments)&&const DeepCollectionEquality().equals(other._certificates, _certificates)&&(identical(other.summary, summary) || other.summary == summary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,student,status,quietDays,rank,const DeepCollectionEquality().hash(_enrollments),const DeepCollectionEquality().hash(_certificates),summary);

@override
String toString() {
  return 'StudentProfile(student: $student, status: $status, quietDays: $quietDays, rank: $rank, enrollments: $enrollments, certificates: $certificates, summary: $summary)';
}


}

/// @nodoc
abstract mixin class _$StudentProfileCopyWith<$Res> implements $StudentProfileCopyWith<$Res> {
  factory _$StudentProfileCopyWith(_StudentProfile value, $Res Function(_StudentProfile) _then) = __$StudentProfileCopyWithImpl;
@override @useResult
$Res call({
 Student student,@JsonKey(unknownEnumValue: StudentStatus.unknown) StudentStatus status, int quietDays, Rank rank, List<StudentEnrollment> enrollments, List<StudentCertificate> certificates, StudentSummary summary
});


@override $StudentCopyWith<$Res> get student;@override $RankCopyWith<$Res> get rank;@override $StudentSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class __$StudentProfileCopyWithImpl<$Res>
    implements _$StudentProfileCopyWith<$Res> {
  __$StudentProfileCopyWithImpl(this._self, this._then);

  final _StudentProfile _self;
  final $Res Function(_StudentProfile) _then;

/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? student = null,Object? status = null,Object? quietDays = null,Object? rank = null,Object? enrollments = null,Object? certificates = null,Object? summary = null,}) {
  return _then(_StudentProfile(
student: null == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as Student,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StudentStatus,quietDays: null == quietDays ? _self.quietDays : quietDays // ignore: cast_nullable_to_non_nullable
as int,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as Rank,enrollments: null == enrollments ? _self._enrollments : enrollments // ignore: cast_nullable_to_non_nullable
as List<StudentEnrollment>,certificates: null == certificates ? _self._certificates : certificates // ignore: cast_nullable_to_non_nullable
as List<StudentCertificate>,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as StudentSummary,
  ));
}

/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StudentCopyWith<$Res> get student {
  
  return $StudentCopyWith<$Res>(_self.student, (value) {
    return _then(_self.copyWith(student: value));
  });
}/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RankCopyWith<$Res> get rank {
  
  return $RankCopyWith<$Res>(_self.rank, (value) {
    return _then(_self.copyWith(rank: value));
  });
}/// Create a copy of StudentProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StudentSummaryCopyWith<$Res> get summary {
  
  return $StudentSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// @nodoc
mixin _$CourseProgressDetail {

 String get courseId; String get courseTitle; num get progress;@JsonKey(unknownEnumValue: EnrollmentStatus.unknown) EnrollmentStatus get status; List<ChapterProgress> get chapters;
/// Create a copy of CourseProgressDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseProgressDetailCopyWith<CourseProgressDetail> get copyWith => _$CourseProgressDetailCopyWithImpl<CourseProgressDetail>(this as CourseProgressDetail, _$identity);

  /// Serializes this CourseProgressDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseProgressDetail&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.chapters, chapters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseId,courseTitle,progress,status,const DeepCollectionEquality().hash(chapters));

@override
String toString() {
  return 'CourseProgressDetail(courseId: $courseId, courseTitle: $courseTitle, progress: $progress, status: $status, chapters: $chapters)';
}


}

/// @nodoc
abstract mixin class $CourseProgressDetailCopyWith<$Res>  {
  factory $CourseProgressDetailCopyWith(CourseProgressDetail value, $Res Function(CourseProgressDetail) _then) = _$CourseProgressDetailCopyWithImpl;
@useResult
$Res call({
 String courseId, String courseTitle, num progress,@JsonKey(unknownEnumValue: EnrollmentStatus.unknown) EnrollmentStatus status, List<ChapterProgress> chapters
});




}
/// @nodoc
class _$CourseProgressDetailCopyWithImpl<$Res>
    implements $CourseProgressDetailCopyWith<$Res> {
  _$CourseProgressDetailCopyWithImpl(this._self, this._then);

  final CourseProgressDetail _self;
  final $Res Function(CourseProgressDetail) _then;

/// Create a copy of CourseProgressDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? courseId = null,Object? courseTitle = null,Object? progress = null,Object? status = null,Object? chapters = null,}) {
  return _then(_self.copyWith(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as num,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EnrollmentStatus,chapters: null == chapters ? _self.chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<ChapterProgress>,
  ));
}

}


/// Adds pattern-matching-related methods to [CourseProgressDetail].
extension CourseProgressDetailPatterns on CourseProgressDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseProgressDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseProgressDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseProgressDetail value)  $default,){
final _that = this;
switch (_that) {
case _CourseProgressDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseProgressDetail value)?  $default,){
final _that = this;
switch (_that) {
case _CourseProgressDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String courseId,  String courseTitle,  num progress, @JsonKey(unknownEnumValue: EnrollmentStatus.unknown)  EnrollmentStatus status,  List<ChapterProgress> chapters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseProgressDetail() when $default != null:
return $default(_that.courseId,_that.courseTitle,_that.progress,_that.status,_that.chapters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String courseId,  String courseTitle,  num progress, @JsonKey(unknownEnumValue: EnrollmentStatus.unknown)  EnrollmentStatus status,  List<ChapterProgress> chapters)  $default,) {final _that = this;
switch (_that) {
case _CourseProgressDetail():
return $default(_that.courseId,_that.courseTitle,_that.progress,_that.status,_that.chapters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String courseId,  String courseTitle,  num progress, @JsonKey(unknownEnumValue: EnrollmentStatus.unknown)  EnrollmentStatus status,  List<ChapterProgress> chapters)?  $default,) {final _that = this;
switch (_that) {
case _CourseProgressDetail() when $default != null:
return $default(_that.courseId,_that.courseTitle,_that.progress,_that.status,_that.chapters);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseProgressDetail implements CourseProgressDetail {
  const _CourseProgressDetail({this.courseId = '', this.courseTitle = '', this.progress = 0, @JsonKey(unknownEnumValue: EnrollmentStatus.unknown) this.status = EnrollmentStatus.active, final  List<ChapterProgress> chapters = const <ChapterProgress>[]}): _chapters = chapters;
  factory _CourseProgressDetail.fromJson(Map<String, dynamic> json) => _$CourseProgressDetailFromJson(json);

@override@JsonKey() final  String courseId;
@override@JsonKey() final  String courseTitle;
@override@JsonKey() final  num progress;
@override@JsonKey(unknownEnumValue: EnrollmentStatus.unknown) final  EnrollmentStatus status;
 final  List<ChapterProgress> _chapters;
@override@JsonKey() List<ChapterProgress> get chapters {
  if (_chapters is EqualUnmodifiableListView) return _chapters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_chapters);
}


/// Create a copy of CourseProgressDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseProgressDetailCopyWith<_CourseProgressDetail> get copyWith => __$CourseProgressDetailCopyWithImpl<_CourseProgressDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseProgressDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseProgressDetail&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._chapters, _chapters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseId,courseTitle,progress,status,const DeepCollectionEquality().hash(_chapters));

@override
String toString() {
  return 'CourseProgressDetail(courseId: $courseId, courseTitle: $courseTitle, progress: $progress, status: $status, chapters: $chapters)';
}


}

/// @nodoc
abstract mixin class _$CourseProgressDetailCopyWith<$Res> implements $CourseProgressDetailCopyWith<$Res> {
  factory _$CourseProgressDetailCopyWith(_CourseProgressDetail value, $Res Function(_CourseProgressDetail) _then) = __$CourseProgressDetailCopyWithImpl;
@override @useResult
$Res call({
 String courseId, String courseTitle, num progress,@JsonKey(unknownEnumValue: EnrollmentStatus.unknown) EnrollmentStatus status, List<ChapterProgress> chapters
});




}
/// @nodoc
class __$CourseProgressDetailCopyWithImpl<$Res>
    implements _$CourseProgressDetailCopyWith<$Res> {
  __$CourseProgressDetailCopyWithImpl(this._self, this._then);

  final _CourseProgressDetail _self;
  final $Res Function(_CourseProgressDetail) _then;

/// Create a copy of CourseProgressDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? courseId = null,Object? courseTitle = null,Object? progress = null,Object? status = null,Object? chapters = null,}) {
  return _then(_CourseProgressDetail(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as num,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EnrollmentStatus,chapters: null == chapters ? _self._chapters : chapters // ignore: cast_nullable_to_non_nullable
as List<ChapterProgress>,
  ));
}


}


/// @nodoc
mixin _$StudentQuizResult {

 String get quizId; String get title; String get courseTitle; int get attempts;/// Their best percentage across those attempts.
 num get best; num get passMark;@NullableUtcDateTimeConverter() DateTime? get lastAt;
/// Create a copy of StudentQuizResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentQuizResultCopyWith<StudentQuizResult> get copyWith => _$StudentQuizResultCopyWithImpl<StudentQuizResult>(this as StudentQuizResult, _$identity);

  /// Serializes this StudentQuizResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudentQuizResult&&(identical(other.quizId, quizId) || other.quizId == quizId)&&(identical(other.title, title) || other.title == title)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.best, best) || other.best == best)&&(identical(other.passMark, passMark) || other.passMark == passMark)&&(identical(other.lastAt, lastAt) || other.lastAt == lastAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quizId,title,courseTitle,attempts,best,passMark,lastAt);

@override
String toString() {
  return 'StudentQuizResult(quizId: $quizId, title: $title, courseTitle: $courseTitle, attempts: $attempts, best: $best, passMark: $passMark, lastAt: $lastAt)';
}


}

/// @nodoc
abstract mixin class $StudentQuizResultCopyWith<$Res>  {
  factory $StudentQuizResultCopyWith(StudentQuizResult value, $Res Function(StudentQuizResult) _then) = _$StudentQuizResultCopyWithImpl;
@useResult
$Res call({
 String quizId, String title, String courseTitle, int attempts, num best, num passMark,@NullableUtcDateTimeConverter() DateTime? lastAt
});




}
/// @nodoc
class _$StudentQuizResultCopyWithImpl<$Res>
    implements $StudentQuizResultCopyWith<$Res> {
  _$StudentQuizResultCopyWithImpl(this._self, this._then);

  final StudentQuizResult _self;
  final $Res Function(StudentQuizResult) _then;

/// Create a copy of StudentQuizResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quizId = null,Object? title = null,Object? courseTitle = null,Object? attempts = null,Object? best = null,Object? passMark = null,Object? lastAt = freezed,}) {
  return _then(_self.copyWith(
quizId: null == quizId ? _self.quizId : quizId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,best: null == best ? _self.best : best // ignore: cast_nullable_to_non_nullable
as num,passMark: null == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as num,lastAt: freezed == lastAt ? _self.lastAt : lastAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [StudentQuizResult].
extension StudentQuizResultPatterns on StudentQuizResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudentQuizResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudentQuizResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudentQuizResult value)  $default,){
final _that = this;
switch (_that) {
case _StudentQuizResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudentQuizResult value)?  $default,){
final _that = this;
switch (_that) {
case _StudentQuizResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String quizId,  String title,  String courseTitle,  int attempts,  num best,  num passMark, @NullableUtcDateTimeConverter()  DateTime? lastAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudentQuizResult() when $default != null:
return $default(_that.quizId,_that.title,_that.courseTitle,_that.attempts,_that.best,_that.passMark,_that.lastAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String quizId,  String title,  String courseTitle,  int attempts,  num best,  num passMark, @NullableUtcDateTimeConverter()  DateTime? lastAt)  $default,) {final _that = this;
switch (_that) {
case _StudentQuizResult():
return $default(_that.quizId,_that.title,_that.courseTitle,_that.attempts,_that.best,_that.passMark,_that.lastAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String quizId,  String title,  String courseTitle,  int attempts,  num best,  num passMark, @NullableUtcDateTimeConverter()  DateTime? lastAt)?  $default,) {final _that = this;
switch (_that) {
case _StudentQuizResult() when $default != null:
return $default(_that.quizId,_that.title,_that.courseTitle,_that.attempts,_that.best,_that.passMark,_that.lastAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudentQuizResult extends StudentQuizResult {
  const _StudentQuizResult({this.quizId = '', this.title = '', this.courseTitle = '', this.attempts = 0, this.best = 0, this.passMark = 0, @NullableUtcDateTimeConverter() this.lastAt}): super._();
  factory _StudentQuizResult.fromJson(Map<String, dynamic> json) => _$StudentQuizResultFromJson(json);

@override@JsonKey() final  String quizId;
@override@JsonKey() final  String title;
@override@JsonKey() final  String courseTitle;
@override@JsonKey() final  int attempts;
/// Their best percentage across those attempts.
@override@JsonKey() final  num best;
@override@JsonKey() final  num passMark;
@override@NullableUtcDateTimeConverter() final  DateTime? lastAt;

/// Create a copy of StudentQuizResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentQuizResultCopyWith<_StudentQuizResult> get copyWith => __$StudentQuizResultCopyWithImpl<_StudentQuizResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudentQuizResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudentQuizResult&&(identical(other.quizId, quizId) || other.quizId == quizId)&&(identical(other.title, title) || other.title == title)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.best, best) || other.best == best)&&(identical(other.passMark, passMark) || other.passMark == passMark)&&(identical(other.lastAt, lastAt) || other.lastAt == lastAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quizId,title,courseTitle,attempts,best,passMark,lastAt);

@override
String toString() {
  return 'StudentQuizResult(quizId: $quizId, title: $title, courseTitle: $courseTitle, attempts: $attempts, best: $best, passMark: $passMark, lastAt: $lastAt)';
}


}

/// @nodoc
abstract mixin class _$StudentQuizResultCopyWith<$Res> implements $StudentQuizResultCopyWith<$Res> {
  factory _$StudentQuizResultCopyWith(_StudentQuizResult value, $Res Function(_StudentQuizResult) _then) = __$StudentQuizResultCopyWithImpl;
@override @useResult
$Res call({
 String quizId, String title, String courseTitle, int attempts, num best, num passMark,@NullableUtcDateTimeConverter() DateTime? lastAt
});




}
/// @nodoc
class __$StudentQuizResultCopyWithImpl<$Res>
    implements _$StudentQuizResultCopyWith<$Res> {
  __$StudentQuizResultCopyWithImpl(this._self, this._then);

  final _StudentQuizResult _self;
  final $Res Function(_StudentQuizResult) _then;

/// Create a copy of StudentQuizResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quizId = null,Object? title = null,Object? courseTitle = null,Object? attempts = null,Object? best = null,Object? passMark = null,Object? lastAt = freezed,}) {
  return _then(_StudentQuizResult(
quizId: null == quizId ? _self.quizId : quizId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,best: null == best ? _self.best : best // ignore: cast_nullable_to_non_nullable
as num,passMark: null == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as num,lastAt: freezed == lastAt ? _self.lastAt : lastAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$StudentAssignmentResult {

 String get submissionId; String get assignmentId; String get title; String get courseTitle;@NullableUtcDateTimeConverter() DateTime? get submittedAt;@JsonKey(unknownEnumValue: ReviewStatus.unknown) ReviewStatus get status; num? get score; num get max; num get passMark; bool get late;
/// Create a copy of StudentAssignmentResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentAssignmentResultCopyWith<StudentAssignmentResult> get copyWith => _$StudentAssignmentResultCopyWithImpl<StudentAssignmentResult>(this as StudentAssignmentResult, _$identity);

  /// Serializes this StudentAssignmentResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudentAssignmentResult&&(identical(other.submissionId, submissionId) || other.submissionId == submissionId)&&(identical(other.assignmentId, assignmentId) || other.assignmentId == assignmentId)&&(identical(other.title, title) || other.title == title)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.score, score) || other.score == score)&&(identical(other.max, max) || other.max == max)&&(identical(other.passMark, passMark) || other.passMark == passMark)&&(identical(other.late, late) || other.late == late));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,submissionId,assignmentId,title,courseTitle,submittedAt,status,score,max,passMark,late);

@override
String toString() {
  return 'StudentAssignmentResult(submissionId: $submissionId, assignmentId: $assignmentId, title: $title, courseTitle: $courseTitle, submittedAt: $submittedAt, status: $status, score: $score, max: $max, passMark: $passMark, late: $late)';
}


}

/// @nodoc
abstract mixin class $StudentAssignmentResultCopyWith<$Res>  {
  factory $StudentAssignmentResultCopyWith(StudentAssignmentResult value, $Res Function(StudentAssignmentResult) _then) = _$StudentAssignmentResultCopyWithImpl;
@useResult
$Res call({
 String submissionId, String assignmentId, String title, String courseTitle,@NullableUtcDateTimeConverter() DateTime? submittedAt,@JsonKey(unknownEnumValue: ReviewStatus.unknown) ReviewStatus status, num? score, num max, num passMark, bool late
});




}
/// @nodoc
class _$StudentAssignmentResultCopyWithImpl<$Res>
    implements $StudentAssignmentResultCopyWith<$Res> {
  _$StudentAssignmentResultCopyWithImpl(this._self, this._then);

  final StudentAssignmentResult _self;
  final $Res Function(StudentAssignmentResult) _then;

/// Create a copy of StudentAssignmentResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? submissionId = null,Object? assignmentId = null,Object? title = null,Object? courseTitle = null,Object? submittedAt = freezed,Object? status = null,Object? score = freezed,Object? max = null,Object? passMark = null,Object? late = null,}) {
  return _then(_self.copyWith(
submissionId: null == submissionId ? _self.submissionId : submissionId // ignore: cast_nullable_to_non_nullable
as String,assignmentId: null == assignmentId ? _self.assignmentId : assignmentId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReviewStatus,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as num?,max: null == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as num,passMark: null == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as num,late: null == late ? _self.late : late // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StudentAssignmentResult].
extension StudentAssignmentResultPatterns on StudentAssignmentResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudentAssignmentResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudentAssignmentResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudentAssignmentResult value)  $default,){
final _that = this;
switch (_that) {
case _StudentAssignmentResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudentAssignmentResult value)?  $default,){
final _that = this;
switch (_that) {
case _StudentAssignmentResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String submissionId,  String assignmentId,  String title,  String courseTitle, @NullableUtcDateTimeConverter()  DateTime? submittedAt, @JsonKey(unknownEnumValue: ReviewStatus.unknown)  ReviewStatus status,  num? score,  num max,  num passMark,  bool late)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudentAssignmentResult() when $default != null:
return $default(_that.submissionId,_that.assignmentId,_that.title,_that.courseTitle,_that.submittedAt,_that.status,_that.score,_that.max,_that.passMark,_that.late);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String submissionId,  String assignmentId,  String title,  String courseTitle, @NullableUtcDateTimeConverter()  DateTime? submittedAt, @JsonKey(unknownEnumValue: ReviewStatus.unknown)  ReviewStatus status,  num? score,  num max,  num passMark,  bool late)  $default,) {final _that = this;
switch (_that) {
case _StudentAssignmentResult():
return $default(_that.submissionId,_that.assignmentId,_that.title,_that.courseTitle,_that.submittedAt,_that.status,_that.score,_that.max,_that.passMark,_that.late);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String submissionId,  String assignmentId,  String title,  String courseTitle, @NullableUtcDateTimeConverter()  DateTime? submittedAt, @JsonKey(unknownEnumValue: ReviewStatus.unknown)  ReviewStatus status,  num? score,  num max,  num passMark,  bool late)?  $default,) {final _that = this;
switch (_that) {
case _StudentAssignmentResult() when $default != null:
return $default(_that.submissionId,_that.assignmentId,_that.title,_that.courseTitle,_that.submittedAt,_that.status,_that.score,_that.max,_that.passMark,_that.late);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudentAssignmentResult implements StudentAssignmentResult {
  const _StudentAssignmentResult({this.submissionId = '', this.assignmentId = '', this.title = '', this.courseTitle = '', @NullableUtcDateTimeConverter() this.submittedAt, @JsonKey(unknownEnumValue: ReviewStatus.unknown) this.status = ReviewStatus.waiting, this.score, this.max = 0, this.passMark = 0, this.late = false});
  factory _StudentAssignmentResult.fromJson(Map<String, dynamic> json) => _$StudentAssignmentResultFromJson(json);

@override@JsonKey() final  String submissionId;
@override@JsonKey() final  String assignmentId;
@override@JsonKey() final  String title;
@override@JsonKey() final  String courseTitle;
@override@NullableUtcDateTimeConverter() final  DateTime? submittedAt;
@override@JsonKey(unknownEnumValue: ReviewStatus.unknown) final  ReviewStatus status;
@override final  num? score;
@override@JsonKey() final  num max;
@override@JsonKey() final  num passMark;
@override@JsonKey() final  bool late;

/// Create a copy of StudentAssignmentResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentAssignmentResultCopyWith<_StudentAssignmentResult> get copyWith => __$StudentAssignmentResultCopyWithImpl<_StudentAssignmentResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudentAssignmentResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudentAssignmentResult&&(identical(other.submissionId, submissionId) || other.submissionId == submissionId)&&(identical(other.assignmentId, assignmentId) || other.assignmentId == assignmentId)&&(identical(other.title, title) || other.title == title)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.score, score) || other.score == score)&&(identical(other.max, max) || other.max == max)&&(identical(other.passMark, passMark) || other.passMark == passMark)&&(identical(other.late, late) || other.late == late));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,submissionId,assignmentId,title,courseTitle,submittedAt,status,score,max,passMark,late);

@override
String toString() {
  return 'StudentAssignmentResult(submissionId: $submissionId, assignmentId: $assignmentId, title: $title, courseTitle: $courseTitle, submittedAt: $submittedAt, status: $status, score: $score, max: $max, passMark: $passMark, late: $late)';
}


}

/// @nodoc
abstract mixin class _$StudentAssignmentResultCopyWith<$Res> implements $StudentAssignmentResultCopyWith<$Res> {
  factory _$StudentAssignmentResultCopyWith(_StudentAssignmentResult value, $Res Function(_StudentAssignmentResult) _then) = __$StudentAssignmentResultCopyWithImpl;
@override @useResult
$Res call({
 String submissionId, String assignmentId, String title, String courseTitle,@NullableUtcDateTimeConverter() DateTime? submittedAt,@JsonKey(unknownEnumValue: ReviewStatus.unknown) ReviewStatus status, num? score, num max, num passMark, bool late
});




}
/// @nodoc
class __$StudentAssignmentResultCopyWithImpl<$Res>
    implements _$StudentAssignmentResultCopyWith<$Res> {
  __$StudentAssignmentResultCopyWithImpl(this._self, this._then);

  final _StudentAssignmentResult _self;
  final $Res Function(_StudentAssignmentResult) _then;

/// Create a copy of StudentAssignmentResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? submissionId = null,Object? assignmentId = null,Object? title = null,Object? courseTitle = null,Object? submittedAt = freezed,Object? status = null,Object? score = freezed,Object? max = null,Object? passMark = null,Object? late = null,}) {
  return _then(_StudentAssignmentResult(
submissionId: null == submissionId ? _self.submissionId : submissionId // ignore: cast_nullable_to_non_nullable
as String,assignmentId: null == assignmentId ? _self.assignmentId : assignmentId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReviewStatus,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as num?,max: null == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as num,passMark: null == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as num,late: null == late ? _self.late : late // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$StudentProgress {

 List<CourseProgressDetail> get courses; List<StudentQuizResult> get quizzes; List<StudentAssignmentResult> get assignments; List<StudyWeek> get studyWeeks;
/// Create a copy of StudentProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentProgressCopyWith<StudentProgress> get copyWith => _$StudentProgressCopyWithImpl<StudentProgress>(this as StudentProgress, _$identity);

  /// Serializes this StudentProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudentProgress&&const DeepCollectionEquality().equals(other.courses, courses)&&const DeepCollectionEquality().equals(other.quizzes, quizzes)&&const DeepCollectionEquality().equals(other.assignments, assignments)&&const DeepCollectionEquality().equals(other.studyWeeks, studyWeeks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(courses),const DeepCollectionEquality().hash(quizzes),const DeepCollectionEquality().hash(assignments),const DeepCollectionEquality().hash(studyWeeks));

@override
String toString() {
  return 'StudentProgress(courses: $courses, quizzes: $quizzes, assignments: $assignments, studyWeeks: $studyWeeks)';
}


}

/// @nodoc
abstract mixin class $StudentProgressCopyWith<$Res>  {
  factory $StudentProgressCopyWith(StudentProgress value, $Res Function(StudentProgress) _then) = _$StudentProgressCopyWithImpl;
@useResult
$Res call({
 List<CourseProgressDetail> courses, List<StudentQuizResult> quizzes, List<StudentAssignmentResult> assignments, List<StudyWeek> studyWeeks
});




}
/// @nodoc
class _$StudentProgressCopyWithImpl<$Res>
    implements $StudentProgressCopyWith<$Res> {
  _$StudentProgressCopyWithImpl(this._self, this._then);

  final StudentProgress _self;
  final $Res Function(StudentProgress) _then;

/// Create a copy of StudentProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? courses = null,Object? quizzes = null,Object? assignments = null,Object? studyWeeks = null,}) {
  return _then(_self.copyWith(
courses: null == courses ? _self.courses : courses // ignore: cast_nullable_to_non_nullable
as List<CourseProgressDetail>,quizzes: null == quizzes ? _self.quizzes : quizzes // ignore: cast_nullable_to_non_nullable
as List<StudentQuizResult>,assignments: null == assignments ? _self.assignments : assignments // ignore: cast_nullable_to_non_nullable
as List<StudentAssignmentResult>,studyWeeks: null == studyWeeks ? _self.studyWeeks : studyWeeks // ignore: cast_nullable_to_non_nullable
as List<StudyWeek>,
  ));
}

}


/// Adds pattern-matching-related methods to [StudentProgress].
extension StudentProgressPatterns on StudentProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudentProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudentProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudentProgress value)  $default,){
final _that = this;
switch (_that) {
case _StudentProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudentProgress value)?  $default,){
final _that = this;
switch (_that) {
case _StudentProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CourseProgressDetail> courses,  List<StudentQuizResult> quizzes,  List<StudentAssignmentResult> assignments,  List<StudyWeek> studyWeeks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudentProgress() when $default != null:
return $default(_that.courses,_that.quizzes,_that.assignments,_that.studyWeeks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CourseProgressDetail> courses,  List<StudentQuizResult> quizzes,  List<StudentAssignmentResult> assignments,  List<StudyWeek> studyWeeks)  $default,) {final _that = this;
switch (_that) {
case _StudentProgress():
return $default(_that.courses,_that.quizzes,_that.assignments,_that.studyWeeks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CourseProgressDetail> courses,  List<StudentQuizResult> quizzes,  List<StudentAssignmentResult> assignments,  List<StudyWeek> studyWeeks)?  $default,) {final _that = this;
switch (_that) {
case _StudentProgress() when $default != null:
return $default(_that.courses,_that.quizzes,_that.assignments,_that.studyWeeks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudentProgress implements StudentProgress {
  const _StudentProgress({final  List<CourseProgressDetail> courses = const <CourseProgressDetail>[], final  List<StudentQuizResult> quizzes = const <StudentQuizResult>[], final  List<StudentAssignmentResult> assignments = const <StudentAssignmentResult>[], final  List<StudyWeek> studyWeeks = const <StudyWeek>[]}): _courses = courses,_quizzes = quizzes,_assignments = assignments,_studyWeeks = studyWeeks;
  factory _StudentProgress.fromJson(Map<String, dynamic> json) => _$StudentProgressFromJson(json);

 final  List<CourseProgressDetail> _courses;
@override@JsonKey() List<CourseProgressDetail> get courses {
  if (_courses is EqualUnmodifiableListView) return _courses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_courses);
}

 final  List<StudentQuizResult> _quizzes;
@override@JsonKey() List<StudentQuizResult> get quizzes {
  if (_quizzes is EqualUnmodifiableListView) return _quizzes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_quizzes);
}

 final  List<StudentAssignmentResult> _assignments;
@override@JsonKey() List<StudentAssignmentResult> get assignments {
  if (_assignments is EqualUnmodifiableListView) return _assignments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assignments);
}

 final  List<StudyWeek> _studyWeeks;
@override@JsonKey() List<StudyWeek> get studyWeeks {
  if (_studyWeeks is EqualUnmodifiableListView) return _studyWeeks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_studyWeeks);
}


/// Create a copy of StudentProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentProgressCopyWith<_StudentProgress> get copyWith => __$StudentProgressCopyWithImpl<_StudentProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudentProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudentProgress&&const DeepCollectionEquality().equals(other._courses, _courses)&&const DeepCollectionEquality().equals(other._quizzes, _quizzes)&&const DeepCollectionEquality().equals(other._assignments, _assignments)&&const DeepCollectionEquality().equals(other._studyWeeks, _studyWeeks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_courses),const DeepCollectionEquality().hash(_quizzes),const DeepCollectionEquality().hash(_assignments),const DeepCollectionEquality().hash(_studyWeeks));

@override
String toString() {
  return 'StudentProgress(courses: $courses, quizzes: $quizzes, assignments: $assignments, studyWeeks: $studyWeeks)';
}


}

/// @nodoc
abstract mixin class _$StudentProgressCopyWith<$Res> implements $StudentProgressCopyWith<$Res> {
  factory _$StudentProgressCopyWith(_StudentProgress value, $Res Function(_StudentProgress) _then) = __$StudentProgressCopyWithImpl;
@override @useResult
$Res call({
 List<CourseProgressDetail> courses, List<StudentQuizResult> quizzes, List<StudentAssignmentResult> assignments, List<StudyWeek> studyWeeks
});




}
/// @nodoc
class __$StudentProgressCopyWithImpl<$Res>
    implements _$StudentProgressCopyWith<$Res> {
  __$StudentProgressCopyWithImpl(this._self, this._then);

  final _StudentProgress _self;
  final $Res Function(_StudentProgress) _then;

/// Create a copy of StudentProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? courses = null,Object? quizzes = null,Object? assignments = null,Object? studyWeeks = null,}) {
  return _then(_StudentProgress(
courses: null == courses ? _self._courses : courses // ignore: cast_nullable_to_non_nullable
as List<CourseProgressDetail>,quizzes: null == quizzes ? _self._quizzes : quizzes // ignore: cast_nullable_to_non_nullable
as List<StudentQuizResult>,assignments: null == assignments ? _self._assignments : assignments // ignore: cast_nullable_to_non_nullable
as List<StudentAssignmentResult>,studyWeeks: null == studyWeeks ? _self._studyWeeks : studyWeeks // ignore: cast_nullable_to_non_nullable
as List<StudyWeek>,
  ));
}


}


/// @nodoc
mixin _$StudentActivity {

 List<LearningEvent> get events; int get total; Map<String, int> get counts;
/// Create a copy of StudentActivity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudentActivityCopyWith<StudentActivity> get copyWith => _$StudentActivityCopyWithImpl<StudentActivity>(this as StudentActivity, _$identity);

  /// Serializes this StudentActivity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudentActivity&&const DeepCollectionEquality().equals(other.events, events)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.counts, counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(events),total,const DeepCollectionEquality().hash(counts));

@override
String toString() {
  return 'StudentActivity(events: $events, total: $total, counts: $counts)';
}


}

/// @nodoc
abstract mixin class $StudentActivityCopyWith<$Res>  {
  factory $StudentActivityCopyWith(StudentActivity value, $Res Function(StudentActivity) _then) = _$StudentActivityCopyWithImpl;
@useResult
$Res call({
 List<LearningEvent> events, int total, Map<String, int> counts
});




}
/// @nodoc
class _$StudentActivityCopyWithImpl<$Res>
    implements $StudentActivityCopyWith<$Res> {
  _$StudentActivityCopyWithImpl(this._self, this._then);

  final StudentActivity _self;
  final $Res Function(StudentActivity) _then;

/// Create a copy of StudentActivity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? events = null,Object? total = null,Object? counts = null,}) {
  return _then(_self.copyWith(
events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<LearningEvent>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [StudentActivity].
extension StudentActivityPatterns on StudentActivity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudentActivity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudentActivity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudentActivity value)  $default,){
final _that = this;
switch (_that) {
case _StudentActivity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudentActivity value)?  $default,){
final _that = this;
switch (_that) {
case _StudentActivity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<LearningEvent> events,  int total,  Map<String, int> counts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudentActivity() when $default != null:
return $default(_that.events,_that.total,_that.counts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<LearningEvent> events,  int total,  Map<String, int> counts)  $default,) {final _that = this;
switch (_that) {
case _StudentActivity():
return $default(_that.events,_that.total,_that.counts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<LearningEvent> events,  int total,  Map<String, int> counts)?  $default,) {final _that = this;
switch (_that) {
case _StudentActivity() when $default != null:
return $default(_that.events,_that.total,_that.counts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudentActivity extends StudentActivity {
  const _StudentActivity({final  List<LearningEvent> events = const <LearningEvent>[], this.total = 0, final  Map<String, int> counts = const <String, int>{}}): _events = events,_counts = counts,super._();
  factory _StudentActivity.fromJson(Map<String, dynamic> json) => _$StudentActivityFromJson(json);

 final  List<LearningEvent> _events;
@override@JsonKey() List<LearningEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

@override@JsonKey() final  int total;
 final  Map<String, int> _counts;
@override@JsonKey() Map<String, int> get counts {
  if (_counts is EqualUnmodifiableMapView) return _counts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_counts);
}


/// Create a copy of StudentActivity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudentActivityCopyWith<_StudentActivity> get copyWith => __$StudentActivityCopyWithImpl<_StudentActivity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudentActivityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudentActivity&&const DeepCollectionEquality().equals(other._events, _events)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._counts, _counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_events),total,const DeepCollectionEquality().hash(_counts));

@override
String toString() {
  return 'StudentActivity(events: $events, total: $total, counts: $counts)';
}


}

/// @nodoc
abstract mixin class _$StudentActivityCopyWith<$Res> implements $StudentActivityCopyWith<$Res> {
  factory _$StudentActivityCopyWith(_StudentActivity value, $Res Function(_StudentActivity) _then) = __$StudentActivityCopyWithImpl;
@override @useResult
$Res call({
 List<LearningEvent> events, int total, Map<String, int> counts
});




}
/// @nodoc
class __$StudentActivityCopyWithImpl<$Res>
    implements _$StudentActivityCopyWith<$Res> {
  __$StudentActivityCopyWithImpl(this._self, this._then);

  final _StudentActivity _self;
  final $Res Function(_StudentActivity) _then;

/// Create a copy of StudentActivity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? events = null,Object? total = null,Object? counts = null,}) {
  return _then(_StudentActivity(
events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<LearningEvent>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self._counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}

// dart format on
