// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'staff_course.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StaffCoursePage {

 List<Course> get rows; int get total; Map<String, int> get counts;
/// Create a copy of StaffCoursePage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffCoursePageCopyWith<StaffCoursePage> get copyWith => _$StaffCoursePageCopyWithImpl<StaffCoursePage>(this as StaffCoursePage, _$identity);

  /// Serializes this StaffCoursePage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffCoursePage&&const DeepCollectionEquality().equals(other.rows, rows)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.counts, counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rows),total,const DeepCollectionEquality().hash(counts));

@override
String toString() {
  return 'StaffCoursePage(rows: $rows, total: $total, counts: $counts)';
}


}

/// @nodoc
abstract mixin class $StaffCoursePageCopyWith<$Res>  {
  factory $StaffCoursePageCopyWith(StaffCoursePage value, $Res Function(StaffCoursePage) _then) = _$StaffCoursePageCopyWithImpl;
@useResult
$Res call({
 List<Course> rows, int total, Map<String, int> counts
});




}
/// @nodoc
class _$StaffCoursePageCopyWithImpl<$Res>
    implements $StaffCoursePageCopyWith<$Res> {
  _$StaffCoursePageCopyWithImpl(this._self, this._then);

  final StaffCoursePage _self;
  final $Res Function(StaffCoursePage) _then;

/// Create a copy of StaffCoursePage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? total = null,Object? counts = null,}) {
  return _then(_self.copyWith(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<Course>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffCoursePage].
extension StaffCoursePagePatterns on StaffCoursePage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffCoursePage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffCoursePage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffCoursePage value)  $default,){
final _that = this;
switch (_that) {
case _StaffCoursePage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffCoursePage value)?  $default,){
final _that = this;
switch (_that) {
case _StaffCoursePage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Course> rows,  int total,  Map<String, int> counts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffCoursePage() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Course> rows,  int total,  Map<String, int> counts)  $default,) {final _that = this;
switch (_that) {
case _StaffCoursePage():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Course> rows,  int total,  Map<String, int> counts)?  $default,) {final _that = this;
switch (_that) {
case _StaffCoursePage() when $default != null:
return $default(_that.rows,_that.total,_that.counts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffCoursePage extends StaffCoursePage {
  const _StaffCoursePage({final  List<Course> rows = const <Course>[], this.total = 0, final  Map<String, int> counts = const <String, int>{}}): _rows = rows,_counts = counts,super._();
  factory _StaffCoursePage.fromJson(Map<String, dynamic> json) => _$StaffCoursePageFromJson(json);

 final  List<Course> _rows;
@override@JsonKey() List<Course> get rows {
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


/// Create a copy of StaffCoursePage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffCoursePageCopyWith<_StaffCoursePage> get copyWith => __$StaffCoursePageCopyWithImpl<_StaffCoursePage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffCoursePageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffCoursePage&&const DeepCollectionEquality().equals(other._rows, _rows)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._counts, _counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows),total,const DeepCollectionEquality().hash(_counts));

@override
String toString() {
  return 'StaffCoursePage(rows: $rows, total: $total, counts: $counts)';
}


}

/// @nodoc
abstract mixin class _$StaffCoursePageCopyWith<$Res> implements $StaffCoursePageCopyWith<$Res> {
  factory _$StaffCoursePageCopyWith(_StaffCoursePage value, $Res Function(_StaffCoursePage) _then) = __$StaffCoursePageCopyWithImpl;
@override @useResult
$Res call({
 List<Course> rows, int total, Map<String, int> counts
});




}
/// @nodoc
class __$StaffCoursePageCopyWithImpl<$Res>
    implements _$StaffCoursePageCopyWith<$Res> {
  __$StaffCoursePageCopyWithImpl(this._self, this._then);

  final _StaffCoursePage _self;
  final $Res Function(_StaffCoursePage) _then;

/// Create a copy of StaffCoursePage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,Object? total = null,Object? counts = null,}) {
  return _then(_StaffCoursePage(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<Course>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self._counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}


/// @nodoc
mixin _$CourseLearnerRow {

 String get studentId; String get name; num get progress;@NullableUtcDateTimeConverter() DateTime? get enrolledAt; String? get status;
/// Create a copy of CourseLearnerRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseLearnerRowCopyWith<CourseLearnerRow> get copyWith => _$CourseLearnerRowCopyWithImpl<CourseLearnerRow>(this as CourseLearnerRow, _$identity);

  /// Serializes this CourseLearnerRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseLearnerRow&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.enrolledAt, enrolledAt) || other.enrolledAt == enrolledAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,studentId,name,progress,enrolledAt,status);

@override
String toString() {
  return 'CourseLearnerRow(studentId: $studentId, name: $name, progress: $progress, enrolledAt: $enrolledAt, status: $status)';
}


}

/// @nodoc
abstract mixin class $CourseLearnerRowCopyWith<$Res>  {
  factory $CourseLearnerRowCopyWith(CourseLearnerRow value, $Res Function(CourseLearnerRow) _then) = _$CourseLearnerRowCopyWithImpl;
@useResult
$Res call({
 String studentId, String name, num progress,@NullableUtcDateTimeConverter() DateTime? enrolledAt, String? status
});




}
/// @nodoc
class _$CourseLearnerRowCopyWithImpl<$Res>
    implements $CourseLearnerRowCopyWith<$Res> {
  _$CourseLearnerRowCopyWithImpl(this._self, this._then);

  final CourseLearnerRow _self;
  final $Res Function(CourseLearnerRow) _then;

/// Create a copy of CourseLearnerRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? studentId = null,Object? name = null,Object? progress = null,Object? enrolledAt = freezed,Object? status = freezed,}) {
  return _then(_self.copyWith(
studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as num,enrolledAt: freezed == enrolledAt ? _self.enrolledAt : enrolledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CourseLearnerRow].
extension CourseLearnerRowPatterns on CourseLearnerRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseLearnerRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseLearnerRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseLearnerRow value)  $default,){
final _that = this;
switch (_that) {
case _CourseLearnerRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseLearnerRow value)?  $default,){
final _that = this;
switch (_that) {
case _CourseLearnerRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String studentId,  String name,  num progress, @NullableUtcDateTimeConverter()  DateTime? enrolledAt,  String? status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseLearnerRow() when $default != null:
return $default(_that.studentId,_that.name,_that.progress,_that.enrolledAt,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String studentId,  String name,  num progress, @NullableUtcDateTimeConverter()  DateTime? enrolledAt,  String? status)  $default,) {final _that = this;
switch (_that) {
case _CourseLearnerRow():
return $default(_that.studentId,_that.name,_that.progress,_that.enrolledAt,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String studentId,  String name,  num progress, @NullableUtcDateTimeConverter()  DateTime? enrolledAt,  String? status)?  $default,) {final _that = this;
switch (_that) {
case _CourseLearnerRow() when $default != null:
return $default(_that.studentId,_that.name,_that.progress,_that.enrolledAt,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseLearnerRow implements CourseLearnerRow {
  const _CourseLearnerRow({this.studentId = '', this.name = '', this.progress = 0, @NullableUtcDateTimeConverter() this.enrolledAt, this.status});
  factory _CourseLearnerRow.fromJson(Map<String, dynamic> json) => _$CourseLearnerRowFromJson(json);

@override@JsonKey() final  String studentId;
@override@JsonKey() final  String name;
@override@JsonKey() final  num progress;
@override@NullableUtcDateTimeConverter() final  DateTime? enrolledAt;
@override final  String? status;

/// Create a copy of CourseLearnerRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseLearnerRowCopyWith<_CourseLearnerRow> get copyWith => __$CourseLearnerRowCopyWithImpl<_CourseLearnerRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseLearnerRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseLearnerRow&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.enrolledAt, enrolledAt) || other.enrolledAt == enrolledAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,studentId,name,progress,enrolledAt,status);

@override
String toString() {
  return 'CourseLearnerRow(studentId: $studentId, name: $name, progress: $progress, enrolledAt: $enrolledAt, status: $status)';
}


}

/// @nodoc
abstract mixin class _$CourseLearnerRowCopyWith<$Res> implements $CourseLearnerRowCopyWith<$Res> {
  factory _$CourseLearnerRowCopyWith(_CourseLearnerRow value, $Res Function(_CourseLearnerRow) _then) = __$CourseLearnerRowCopyWithImpl;
@override @useResult
$Res call({
 String studentId, String name, num progress,@NullableUtcDateTimeConverter() DateTime? enrolledAt, String? status
});




}
/// @nodoc
class __$CourseLearnerRowCopyWithImpl<$Res>
    implements _$CourseLearnerRowCopyWith<$Res> {
  __$CourseLearnerRowCopyWithImpl(this._self, this._then);

  final _CourseLearnerRow _self;
  final $Res Function(_CourseLearnerRow) _then;

/// Create a copy of CourseLearnerRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? studentId = null,Object? name = null,Object? progress = null,Object? enrolledAt = freezed,Object? status = freezed,}) {
  return _then(_CourseLearnerRow(
studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as num,enrolledAt: freezed == enrolledAt ? _self.enrolledAt : enrolledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ProgressBucket {

 String get label; num get value;
/// Create a copy of ProgressBucket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgressBucketCopyWith<ProgressBucket> get copyWith => _$ProgressBucketCopyWithImpl<ProgressBucket>(this as ProgressBucket, _$identity);

  /// Serializes this ProgressBucket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgressBucket&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,value);

@override
String toString() {
  return 'ProgressBucket(label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class $ProgressBucketCopyWith<$Res>  {
  factory $ProgressBucketCopyWith(ProgressBucket value, $Res Function(ProgressBucket) _then) = _$ProgressBucketCopyWithImpl;
@useResult
$Res call({
 String label, num value
});




}
/// @nodoc
class _$ProgressBucketCopyWithImpl<$Res>
    implements $ProgressBucketCopyWith<$Res> {
  _$ProgressBucketCopyWithImpl(this._self, this._then);

  final ProgressBucket _self;
  final $Res Function(ProgressBucket) _then;

/// Create a copy of ProgressBucket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? value = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [ProgressBucket].
extension ProgressBucketPatterns on ProgressBucket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgressBucket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgressBucket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgressBucket value)  $default,){
final _that = this;
switch (_that) {
case _ProgressBucket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgressBucket value)?  $default,){
final _that = this;
switch (_that) {
case _ProgressBucket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  num value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgressBucket() when $default != null:
return $default(_that.label,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  num value)  $default,) {final _that = this;
switch (_that) {
case _ProgressBucket():
return $default(_that.label,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  num value)?  $default,) {final _that = this;
switch (_that) {
case _ProgressBucket() when $default != null:
return $default(_that.label,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProgressBucket implements ProgressBucket {
  const _ProgressBucket({this.label = '', this.value = 0});
  factory _ProgressBucket.fromJson(Map<String, dynamic> json) => _$ProgressBucketFromJson(json);

@override@JsonKey() final  String label;
@override@JsonKey() final  num value;

/// Create a copy of ProgressBucket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgressBucketCopyWith<_ProgressBucket> get copyWith => __$ProgressBucketCopyWithImpl<_ProgressBucket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProgressBucketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgressBucket&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,value);

@override
String toString() {
  return 'ProgressBucket(label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class _$ProgressBucketCopyWith<$Res> implements $ProgressBucketCopyWith<$Res> {
  factory _$ProgressBucketCopyWith(_ProgressBucket value, $Res Function(_ProgressBucket) _then) = __$ProgressBucketCopyWithImpl;
@override @useResult
$Res call({
 String label, num value
});




}
/// @nodoc
class __$ProgressBucketCopyWithImpl<$Res>
    implements _$ProgressBucketCopyWith<$Res> {
  __$ProgressBucketCopyWithImpl(this._self, this._then);

  final _ProgressBucket _self;
  final $Res Function(_ProgressBucket) _then;

/// Create a copy of ProgressBucket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? value = null,}) {
  return _then(_ProgressBucket(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}


/// @nodoc
mixin _$CourseStats {

 String get courseId; int get enrolled;/// Learners who opened it in the last 14 days.
 int get active; num get completionRate; num get avgProgress;/// Weekly new enrolments, twelve weeks, oldest → newest.
 List<TrendPoint> get weekly;/// How many learners sit in each fifth of the progress range.
 List<ProgressBucket> get progressBuckets; List<CourseLearnerRow> get recent;/// How many live classes are still to come — a count, not a list.
 int get upcomingLive; int get certificatesIssued; int get reviewsWaiting;/// Every lesson's minutes, summed by the server.
 int get totalMinutes;
/// Create a copy of CourseStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseStatsCopyWith<CourseStats> get copyWith => _$CourseStatsCopyWithImpl<CourseStats>(this as CourseStats, _$identity);

  /// Serializes this CourseStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseStats&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.active, active) || other.active == active)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.avgProgress, avgProgress) || other.avgProgress == avgProgress)&&const DeepCollectionEquality().equals(other.weekly, weekly)&&const DeepCollectionEquality().equals(other.progressBuckets, progressBuckets)&&const DeepCollectionEquality().equals(other.recent, recent)&&(identical(other.upcomingLive, upcomingLive) || other.upcomingLive == upcomingLive)&&(identical(other.certificatesIssued, certificatesIssued) || other.certificatesIssued == certificatesIssued)&&(identical(other.reviewsWaiting, reviewsWaiting) || other.reviewsWaiting == reviewsWaiting)&&(identical(other.totalMinutes, totalMinutes) || other.totalMinutes == totalMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseId,enrolled,active,completionRate,avgProgress,const DeepCollectionEquality().hash(weekly),const DeepCollectionEquality().hash(progressBuckets),const DeepCollectionEquality().hash(recent),upcomingLive,certificatesIssued,reviewsWaiting,totalMinutes);

@override
String toString() {
  return 'CourseStats(courseId: $courseId, enrolled: $enrolled, active: $active, completionRate: $completionRate, avgProgress: $avgProgress, weekly: $weekly, progressBuckets: $progressBuckets, recent: $recent, upcomingLive: $upcomingLive, certificatesIssued: $certificatesIssued, reviewsWaiting: $reviewsWaiting, totalMinutes: $totalMinutes)';
}


}

/// @nodoc
abstract mixin class $CourseStatsCopyWith<$Res>  {
  factory $CourseStatsCopyWith(CourseStats value, $Res Function(CourseStats) _then) = _$CourseStatsCopyWithImpl;
@useResult
$Res call({
 String courseId, int enrolled, int active, num completionRate, num avgProgress, List<TrendPoint> weekly, List<ProgressBucket> progressBuckets, List<CourseLearnerRow> recent, int upcomingLive, int certificatesIssued, int reviewsWaiting, int totalMinutes
});




}
/// @nodoc
class _$CourseStatsCopyWithImpl<$Res>
    implements $CourseStatsCopyWith<$Res> {
  _$CourseStatsCopyWithImpl(this._self, this._then);

  final CourseStats _self;
  final $Res Function(CourseStats) _then;

/// Create a copy of CourseStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? courseId = null,Object? enrolled = null,Object? active = null,Object? completionRate = null,Object? avgProgress = null,Object? weekly = null,Object? progressBuckets = null,Object? recent = null,Object? upcomingLive = null,Object? certificatesIssued = null,Object? reviewsWaiting = null,Object? totalMinutes = null,}) {
  return _then(_self.copyWith(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as int,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as num,avgProgress: null == avgProgress ? _self.avgProgress : avgProgress // ignore: cast_nullable_to_non_nullable
as num,weekly: null == weekly ? _self.weekly : weekly // ignore: cast_nullable_to_non_nullable
as List<TrendPoint>,progressBuckets: null == progressBuckets ? _self.progressBuckets : progressBuckets // ignore: cast_nullable_to_non_nullable
as List<ProgressBucket>,recent: null == recent ? _self.recent : recent // ignore: cast_nullable_to_non_nullable
as List<CourseLearnerRow>,upcomingLive: null == upcomingLive ? _self.upcomingLive : upcomingLive // ignore: cast_nullable_to_non_nullable
as int,certificatesIssued: null == certificatesIssued ? _self.certificatesIssued : certificatesIssued // ignore: cast_nullable_to_non_nullable
as int,reviewsWaiting: null == reviewsWaiting ? _self.reviewsWaiting : reviewsWaiting // ignore: cast_nullable_to_non_nullable
as int,totalMinutes: null == totalMinutes ? _self.totalMinutes : totalMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CourseStats].
extension CourseStatsPatterns on CourseStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseStats value)  $default,){
final _that = this;
switch (_that) {
case _CourseStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseStats value)?  $default,){
final _that = this;
switch (_that) {
case _CourseStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String courseId,  int enrolled,  int active,  num completionRate,  num avgProgress,  List<TrendPoint> weekly,  List<ProgressBucket> progressBuckets,  List<CourseLearnerRow> recent,  int upcomingLive,  int certificatesIssued,  int reviewsWaiting,  int totalMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseStats() when $default != null:
return $default(_that.courseId,_that.enrolled,_that.active,_that.completionRate,_that.avgProgress,_that.weekly,_that.progressBuckets,_that.recent,_that.upcomingLive,_that.certificatesIssued,_that.reviewsWaiting,_that.totalMinutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String courseId,  int enrolled,  int active,  num completionRate,  num avgProgress,  List<TrendPoint> weekly,  List<ProgressBucket> progressBuckets,  List<CourseLearnerRow> recent,  int upcomingLive,  int certificatesIssued,  int reviewsWaiting,  int totalMinutes)  $default,) {final _that = this;
switch (_that) {
case _CourseStats():
return $default(_that.courseId,_that.enrolled,_that.active,_that.completionRate,_that.avgProgress,_that.weekly,_that.progressBuckets,_that.recent,_that.upcomingLive,_that.certificatesIssued,_that.reviewsWaiting,_that.totalMinutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String courseId,  int enrolled,  int active,  num completionRate,  num avgProgress,  List<TrendPoint> weekly,  List<ProgressBucket> progressBuckets,  List<CourseLearnerRow> recent,  int upcomingLive,  int certificatesIssued,  int reviewsWaiting,  int totalMinutes)?  $default,) {final _that = this;
switch (_that) {
case _CourseStats() when $default != null:
return $default(_that.courseId,_that.enrolled,_that.active,_that.completionRate,_that.avgProgress,_that.weekly,_that.progressBuckets,_that.recent,_that.upcomingLive,_that.certificatesIssued,_that.reviewsWaiting,_that.totalMinutes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseStats implements CourseStats {
  const _CourseStats({this.courseId = '', this.enrolled = 0, this.active = 0, this.completionRate = 0, this.avgProgress = 0, final  List<TrendPoint> weekly = const <TrendPoint>[], final  List<ProgressBucket> progressBuckets = const <ProgressBucket>[], final  List<CourseLearnerRow> recent = const <CourseLearnerRow>[], this.upcomingLive = 0, this.certificatesIssued = 0, this.reviewsWaiting = 0, this.totalMinutes = 0}): _weekly = weekly,_progressBuckets = progressBuckets,_recent = recent;
  factory _CourseStats.fromJson(Map<String, dynamic> json) => _$CourseStatsFromJson(json);

@override@JsonKey() final  String courseId;
@override@JsonKey() final  int enrolled;
/// Learners who opened it in the last 14 days.
@override@JsonKey() final  int active;
@override@JsonKey() final  num completionRate;
@override@JsonKey() final  num avgProgress;
/// Weekly new enrolments, twelve weeks, oldest → newest.
 final  List<TrendPoint> _weekly;
/// Weekly new enrolments, twelve weeks, oldest → newest.
@override@JsonKey() List<TrendPoint> get weekly {
  if (_weekly is EqualUnmodifiableListView) return _weekly;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weekly);
}

/// How many learners sit in each fifth of the progress range.
 final  List<ProgressBucket> _progressBuckets;
/// How many learners sit in each fifth of the progress range.
@override@JsonKey() List<ProgressBucket> get progressBuckets {
  if (_progressBuckets is EqualUnmodifiableListView) return _progressBuckets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_progressBuckets);
}

 final  List<CourseLearnerRow> _recent;
@override@JsonKey() List<CourseLearnerRow> get recent {
  if (_recent is EqualUnmodifiableListView) return _recent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recent);
}

/// How many live classes are still to come — a count, not a list.
@override@JsonKey() final  int upcomingLive;
@override@JsonKey() final  int certificatesIssued;
@override@JsonKey() final  int reviewsWaiting;
/// Every lesson's minutes, summed by the server.
@override@JsonKey() final  int totalMinutes;

/// Create a copy of CourseStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseStatsCopyWith<_CourseStats> get copyWith => __$CourseStatsCopyWithImpl<_CourseStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseStats&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.active, active) || other.active == active)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.avgProgress, avgProgress) || other.avgProgress == avgProgress)&&const DeepCollectionEquality().equals(other._weekly, _weekly)&&const DeepCollectionEquality().equals(other._progressBuckets, _progressBuckets)&&const DeepCollectionEquality().equals(other._recent, _recent)&&(identical(other.upcomingLive, upcomingLive) || other.upcomingLive == upcomingLive)&&(identical(other.certificatesIssued, certificatesIssued) || other.certificatesIssued == certificatesIssued)&&(identical(other.reviewsWaiting, reviewsWaiting) || other.reviewsWaiting == reviewsWaiting)&&(identical(other.totalMinutes, totalMinutes) || other.totalMinutes == totalMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseId,enrolled,active,completionRate,avgProgress,const DeepCollectionEquality().hash(_weekly),const DeepCollectionEquality().hash(_progressBuckets),const DeepCollectionEquality().hash(_recent),upcomingLive,certificatesIssued,reviewsWaiting,totalMinutes);

@override
String toString() {
  return 'CourseStats(courseId: $courseId, enrolled: $enrolled, active: $active, completionRate: $completionRate, avgProgress: $avgProgress, weekly: $weekly, progressBuckets: $progressBuckets, recent: $recent, upcomingLive: $upcomingLive, certificatesIssued: $certificatesIssued, reviewsWaiting: $reviewsWaiting, totalMinutes: $totalMinutes)';
}


}

/// @nodoc
abstract mixin class _$CourseStatsCopyWith<$Res> implements $CourseStatsCopyWith<$Res> {
  factory _$CourseStatsCopyWith(_CourseStats value, $Res Function(_CourseStats) _then) = __$CourseStatsCopyWithImpl;
@override @useResult
$Res call({
 String courseId, int enrolled, int active, num completionRate, num avgProgress, List<TrendPoint> weekly, List<ProgressBucket> progressBuckets, List<CourseLearnerRow> recent, int upcomingLive, int certificatesIssued, int reviewsWaiting, int totalMinutes
});




}
/// @nodoc
class __$CourseStatsCopyWithImpl<$Res>
    implements _$CourseStatsCopyWith<$Res> {
  __$CourseStatsCopyWithImpl(this._self, this._then);

  final _CourseStats _self;
  final $Res Function(_CourseStats) _then;

/// Create a copy of CourseStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? courseId = null,Object? enrolled = null,Object? active = null,Object? completionRate = null,Object? avgProgress = null,Object? weekly = null,Object? progressBuckets = null,Object? recent = null,Object? upcomingLive = null,Object? certificatesIssued = null,Object? reviewsWaiting = null,Object? totalMinutes = null,}) {
  return _then(_CourseStats(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as int,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as num,avgProgress: null == avgProgress ? _self.avgProgress : avgProgress // ignore: cast_nullable_to_non_nullable
as num,weekly: null == weekly ? _self._weekly : weekly // ignore: cast_nullable_to_non_nullable
as List<TrendPoint>,progressBuckets: null == progressBuckets ? _self._progressBuckets : progressBuckets // ignore: cast_nullable_to_non_nullable
as List<ProgressBucket>,recent: null == recent ? _self._recent : recent // ignore: cast_nullable_to_non_nullable
as List<CourseLearnerRow>,upcomingLive: null == upcomingLive ? _self.upcomingLive : upcomingLive // ignore: cast_nullable_to_non_nullable
as int,certificatesIssued: null == certificatesIssued ? _self.certificatesIssued : certificatesIssued // ignore: cast_nullable_to_non_nullable
as int,reviewsWaiting: null == reviewsWaiting ? _self.reviewsWaiting : reviewsWaiting // ignore: cast_nullable_to_non_nullable
as int,totalMinutes: null == totalMinutes ? _self.totalMinutes : totalMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CurriculumStats {

 int get enrolled; Map<String, ChapterProgressStat> get chapters;/// Percent of enrolled learners who have completed each lesson, by lesson id.
 Map<String, num> get lessons;
/// Create a copy of CurriculumStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CurriculumStatsCopyWith<CurriculumStats> get copyWith => _$CurriculumStatsCopyWithImpl<CurriculumStats>(this as CurriculumStats, _$identity);

  /// Serializes this CurriculumStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CurriculumStats&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&const DeepCollectionEquality().equals(other.chapters, chapters)&&const DeepCollectionEquality().equals(other.lessons, lessons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrolled,const DeepCollectionEquality().hash(chapters),const DeepCollectionEquality().hash(lessons));

@override
String toString() {
  return 'CurriculumStats(enrolled: $enrolled, chapters: $chapters, lessons: $lessons)';
}


}

/// @nodoc
abstract mixin class $CurriculumStatsCopyWith<$Res>  {
  factory $CurriculumStatsCopyWith(CurriculumStats value, $Res Function(CurriculumStats) _then) = _$CurriculumStatsCopyWithImpl;
@useResult
$Res call({
 int enrolled, Map<String, ChapterProgressStat> chapters, Map<String, num> lessons
});




}
/// @nodoc
class _$CurriculumStatsCopyWithImpl<$Res>
    implements $CurriculumStatsCopyWith<$Res> {
  _$CurriculumStatsCopyWithImpl(this._self, this._then);

  final CurriculumStats _self;
  final $Res Function(CurriculumStats) _then;

/// Create a copy of CurriculumStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enrolled = null,Object? chapters = null,Object? lessons = null,}) {
  return _then(_self.copyWith(
enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as int,chapters: null == chapters ? _self.chapters : chapters // ignore: cast_nullable_to_non_nullable
as Map<String, ChapterProgressStat>,lessons: null == lessons ? _self.lessons : lessons // ignore: cast_nullable_to_non_nullable
as Map<String, num>,
  ));
}

}


/// Adds pattern-matching-related methods to [CurriculumStats].
extension CurriculumStatsPatterns on CurriculumStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CurriculumStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CurriculumStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CurriculumStats value)  $default,){
final _that = this;
switch (_that) {
case _CurriculumStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CurriculumStats value)?  $default,){
final _that = this;
switch (_that) {
case _CurriculumStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int enrolled,  Map<String, ChapterProgressStat> chapters,  Map<String, num> lessons)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CurriculumStats() when $default != null:
return $default(_that.enrolled,_that.chapters,_that.lessons);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int enrolled,  Map<String, ChapterProgressStat> chapters,  Map<String, num> lessons)  $default,) {final _that = this;
switch (_that) {
case _CurriculumStats():
return $default(_that.enrolled,_that.chapters,_that.lessons);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int enrolled,  Map<String, ChapterProgressStat> chapters,  Map<String, num> lessons)?  $default,) {final _that = this;
switch (_that) {
case _CurriculumStats() when $default != null:
return $default(_that.enrolled,_that.chapters,_that.lessons);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CurriculumStats extends CurriculumStats {
  const _CurriculumStats({this.enrolled = 0, final  Map<String, ChapterProgressStat> chapters = const <String, ChapterProgressStat>{}, final  Map<String, num> lessons = const <String, num>{}}): _chapters = chapters,_lessons = lessons,super._();
  factory _CurriculumStats.fromJson(Map<String, dynamic> json) => _$CurriculumStatsFromJson(json);

@override@JsonKey() final  int enrolled;
 final  Map<String, ChapterProgressStat> _chapters;
@override@JsonKey() Map<String, ChapterProgressStat> get chapters {
  if (_chapters is EqualUnmodifiableMapView) return _chapters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_chapters);
}

/// Percent of enrolled learners who have completed each lesson, by lesson id.
 final  Map<String, num> _lessons;
/// Percent of enrolled learners who have completed each lesson, by lesson id.
@override@JsonKey() Map<String, num> get lessons {
  if (_lessons is EqualUnmodifiableMapView) return _lessons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_lessons);
}


/// Create a copy of CurriculumStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CurriculumStatsCopyWith<_CurriculumStats> get copyWith => __$CurriculumStatsCopyWithImpl<_CurriculumStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CurriculumStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CurriculumStats&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&const DeepCollectionEquality().equals(other._chapters, _chapters)&&const DeepCollectionEquality().equals(other._lessons, _lessons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enrolled,const DeepCollectionEquality().hash(_chapters),const DeepCollectionEquality().hash(_lessons));

@override
String toString() {
  return 'CurriculumStats(enrolled: $enrolled, chapters: $chapters, lessons: $lessons)';
}


}

/// @nodoc
abstract mixin class _$CurriculumStatsCopyWith<$Res> implements $CurriculumStatsCopyWith<$Res> {
  factory _$CurriculumStatsCopyWith(_CurriculumStats value, $Res Function(_CurriculumStats) _then) = __$CurriculumStatsCopyWithImpl;
@override @useResult
$Res call({
 int enrolled, Map<String, ChapterProgressStat> chapters, Map<String, num> lessons
});




}
/// @nodoc
class __$CurriculumStatsCopyWithImpl<$Res>
    implements _$CurriculumStatsCopyWith<$Res> {
  __$CurriculumStatsCopyWithImpl(this._self, this._then);

  final _CurriculumStats _self;
  final $Res Function(_CurriculumStats) _then;

/// Create a copy of CurriculumStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enrolled = null,Object? chapters = null,Object? lessons = null,}) {
  return _then(_CurriculumStats(
enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as int,chapters: null == chapters ? _self._chapters : chapters // ignore: cast_nullable_to_non_nullable
as Map<String, ChapterProgressStat>,lessons: null == lessons ? _self._lessons : lessons // ignore: cast_nullable_to_non_nullable
as Map<String, num>,
  ));
}


}


/// @nodoc
mixin _$ChapterProgressStat {

 num get completionRate; num get startedRate;
/// Create a copy of ChapterProgressStat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChapterProgressStatCopyWith<ChapterProgressStat> get copyWith => _$ChapterProgressStatCopyWithImpl<ChapterProgressStat>(this as ChapterProgressStat, _$identity);

  /// Serializes this ChapterProgressStat to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChapterProgressStat&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.startedRate, startedRate) || other.startedRate == startedRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,completionRate,startedRate);

@override
String toString() {
  return 'ChapterProgressStat(completionRate: $completionRate, startedRate: $startedRate)';
}


}

/// @nodoc
abstract mixin class $ChapterProgressStatCopyWith<$Res>  {
  factory $ChapterProgressStatCopyWith(ChapterProgressStat value, $Res Function(ChapterProgressStat) _then) = _$ChapterProgressStatCopyWithImpl;
@useResult
$Res call({
 num completionRate, num startedRate
});




}
/// @nodoc
class _$ChapterProgressStatCopyWithImpl<$Res>
    implements $ChapterProgressStatCopyWith<$Res> {
  _$ChapterProgressStatCopyWithImpl(this._self, this._then);

  final ChapterProgressStat _self;
  final $Res Function(ChapterProgressStat) _then;

/// Create a copy of ChapterProgressStat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? completionRate = null,Object? startedRate = null,}) {
  return _then(_self.copyWith(
completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as num,startedRate: null == startedRate ? _self.startedRate : startedRate // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [ChapterProgressStat].
extension ChapterProgressStatPatterns on ChapterProgressStat {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChapterProgressStat value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChapterProgressStat() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChapterProgressStat value)  $default,){
final _that = this;
switch (_that) {
case _ChapterProgressStat():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChapterProgressStat value)?  $default,){
final _that = this;
switch (_that) {
case _ChapterProgressStat() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( num completionRate,  num startedRate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChapterProgressStat() when $default != null:
return $default(_that.completionRate,_that.startedRate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( num completionRate,  num startedRate)  $default,) {final _that = this;
switch (_that) {
case _ChapterProgressStat():
return $default(_that.completionRate,_that.startedRate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( num completionRate,  num startedRate)?  $default,) {final _that = this;
switch (_that) {
case _ChapterProgressStat() when $default != null:
return $default(_that.completionRate,_that.startedRate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChapterProgressStat implements ChapterProgressStat {
  const _ChapterProgressStat({this.completionRate = 0, this.startedRate = 0});
  factory _ChapterProgressStat.fromJson(Map<String, dynamic> json) => _$ChapterProgressStatFromJson(json);

@override@JsonKey() final  num completionRate;
@override@JsonKey() final  num startedRate;

/// Create a copy of ChapterProgressStat
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChapterProgressStatCopyWith<_ChapterProgressStat> get copyWith => __$ChapterProgressStatCopyWithImpl<_ChapterProgressStat>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChapterProgressStatToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChapterProgressStat&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.startedRate, startedRate) || other.startedRate == startedRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,completionRate,startedRate);

@override
String toString() {
  return 'ChapterProgressStat(completionRate: $completionRate, startedRate: $startedRate)';
}


}

/// @nodoc
abstract mixin class _$ChapterProgressStatCopyWith<$Res> implements $ChapterProgressStatCopyWith<$Res> {
  factory _$ChapterProgressStatCopyWith(_ChapterProgressStat value, $Res Function(_ChapterProgressStat) _then) = __$ChapterProgressStatCopyWithImpl;
@override @useResult
$Res call({
 num completionRate, num startedRate
});




}
/// @nodoc
class __$ChapterProgressStatCopyWithImpl<$Res>
    implements _$ChapterProgressStatCopyWith<$Res> {
  __$ChapterProgressStatCopyWithImpl(this._self, this._then);

  final _ChapterProgressStat _self;
  final $Res Function(_ChapterProgressStat) _then;

/// Create a copy of ChapterProgressStat
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? completionRate = null,Object? startedRate = null,}) {
  return _then(_ChapterProgressStat(
completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as num,startedRate: null == startedRate ? _self.startedRate : startedRate // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}


/// @nodoc
mixin _$StaffLessonRow {

 Lesson get lesson; String get chapterId; String get chapterTitle; int get chapterIndex; int get lessonIndex;
/// Create a copy of StaffLessonRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffLessonRowCopyWith<StaffLessonRow> get copyWith => _$StaffLessonRowCopyWithImpl<StaffLessonRow>(this as StaffLessonRow, _$identity);

  /// Serializes this StaffLessonRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffLessonRow&&(identical(other.lesson, lesson) || other.lesson == lesson)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.lessonIndex, lessonIndex) || other.lessonIndex == lessonIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lesson,chapterId,chapterTitle,chapterIndex,lessonIndex);

@override
String toString() {
  return 'StaffLessonRow(lesson: $lesson, chapterId: $chapterId, chapterTitle: $chapterTitle, chapterIndex: $chapterIndex, lessonIndex: $lessonIndex)';
}


}

/// @nodoc
abstract mixin class $StaffLessonRowCopyWith<$Res>  {
  factory $StaffLessonRowCopyWith(StaffLessonRow value, $Res Function(StaffLessonRow) _then) = _$StaffLessonRowCopyWithImpl;
@useResult
$Res call({
 Lesson lesson, String chapterId, String chapterTitle, int chapterIndex, int lessonIndex
});


$LessonCopyWith<$Res> get lesson;

}
/// @nodoc
class _$StaffLessonRowCopyWithImpl<$Res>
    implements $StaffLessonRowCopyWith<$Res> {
  _$StaffLessonRowCopyWithImpl(this._self, this._then);

  final StaffLessonRow _self;
  final $Res Function(StaffLessonRow) _then;

/// Create a copy of StaffLessonRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lesson = null,Object? chapterId = null,Object? chapterTitle = null,Object? chapterIndex = null,Object? lessonIndex = null,}) {
  return _then(_self.copyWith(
lesson: null == lesson ? _self.lesson : lesson // ignore: cast_nullable_to_non_nullable
as Lesson,chapterId: null == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String,chapterTitle: null == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String,chapterIndex: null == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int,lessonIndex: null == lessonIndex ? _self.lessonIndex : lessonIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of StaffLessonRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonCopyWith<$Res> get lesson {
  
  return $LessonCopyWith<$Res>(_self.lesson, (value) {
    return _then(_self.copyWith(lesson: value));
  });
}
}


/// Adds pattern-matching-related methods to [StaffLessonRow].
extension StaffLessonRowPatterns on StaffLessonRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffLessonRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffLessonRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffLessonRow value)  $default,){
final _that = this;
switch (_that) {
case _StaffLessonRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffLessonRow value)?  $default,){
final _that = this;
switch (_that) {
case _StaffLessonRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Lesson lesson,  String chapterId,  String chapterTitle,  int chapterIndex,  int lessonIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffLessonRow() when $default != null:
return $default(_that.lesson,_that.chapterId,_that.chapterTitle,_that.chapterIndex,_that.lessonIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Lesson lesson,  String chapterId,  String chapterTitle,  int chapterIndex,  int lessonIndex)  $default,) {final _that = this;
switch (_that) {
case _StaffLessonRow():
return $default(_that.lesson,_that.chapterId,_that.chapterTitle,_that.chapterIndex,_that.lessonIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Lesson lesson,  String chapterId,  String chapterTitle,  int chapterIndex,  int lessonIndex)?  $default,) {final _that = this;
switch (_that) {
case _StaffLessonRow() when $default != null:
return $default(_that.lesson,_that.chapterId,_that.chapterTitle,_that.chapterIndex,_that.lessonIndex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffLessonRow implements StaffLessonRow {
  const _StaffLessonRow({required this.lesson, this.chapterId = '', this.chapterTitle = '', this.chapterIndex = 0, this.lessonIndex = 0});
  factory _StaffLessonRow.fromJson(Map<String, dynamic> json) => _$StaffLessonRowFromJson(json);

@override final  Lesson lesson;
@override@JsonKey() final  String chapterId;
@override@JsonKey() final  String chapterTitle;
@override@JsonKey() final  int chapterIndex;
@override@JsonKey() final  int lessonIndex;

/// Create a copy of StaffLessonRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffLessonRowCopyWith<_StaffLessonRow> get copyWith => __$StaffLessonRowCopyWithImpl<_StaffLessonRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffLessonRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffLessonRow&&(identical(other.lesson, lesson) || other.lesson == lesson)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.lessonIndex, lessonIndex) || other.lessonIndex == lessonIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lesson,chapterId,chapterTitle,chapterIndex,lessonIndex);

@override
String toString() {
  return 'StaffLessonRow(lesson: $lesson, chapterId: $chapterId, chapterTitle: $chapterTitle, chapterIndex: $chapterIndex, lessonIndex: $lessonIndex)';
}


}

/// @nodoc
abstract mixin class _$StaffLessonRowCopyWith<$Res> implements $StaffLessonRowCopyWith<$Res> {
  factory _$StaffLessonRowCopyWith(_StaffLessonRow value, $Res Function(_StaffLessonRow) _then) = __$StaffLessonRowCopyWithImpl;
@override @useResult
$Res call({
 Lesson lesson, String chapterId, String chapterTitle, int chapterIndex, int lessonIndex
});


@override $LessonCopyWith<$Res> get lesson;

}
/// @nodoc
class __$StaffLessonRowCopyWithImpl<$Res>
    implements _$StaffLessonRowCopyWith<$Res> {
  __$StaffLessonRowCopyWithImpl(this._self, this._then);

  final _StaffLessonRow _self;
  final $Res Function(_StaffLessonRow) _then;

/// Create a copy of StaffLessonRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lesson = null,Object? chapterId = null,Object? chapterTitle = null,Object? chapterIndex = null,Object? lessonIndex = null,}) {
  return _then(_StaffLessonRow(
lesson: null == lesson ? _self.lesson : lesson // ignore: cast_nullable_to_non_nullable
as Lesson,chapterId: null == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String,chapterTitle: null == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String,chapterIndex: null == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int,lessonIndex: null == lessonIndex ? _self.lessonIndex : lessonIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of StaffLessonRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonCopyWith<$Res> get lesson {
  
  return $LessonCopyWith<$Res>(_self.lesson, (value) {
    return _then(_self.copyWith(lesson: value));
  });
}
}


/// @nodoc
mixin _$StaffLessonPage {

 List<StaffLessonRow> get rows; Map<String, dynamic> get counts;
/// Create a copy of StaffLessonPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffLessonPageCopyWith<StaffLessonPage> get copyWith => _$StaffLessonPageCopyWithImpl<StaffLessonPage>(this as StaffLessonPage, _$identity);

  /// Serializes this StaffLessonPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffLessonPage&&const DeepCollectionEquality().equals(other.rows, rows)&&const DeepCollectionEquality().equals(other.counts, counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rows),const DeepCollectionEquality().hash(counts));

@override
String toString() {
  return 'StaffLessonPage(rows: $rows, counts: $counts)';
}


}

/// @nodoc
abstract mixin class $StaffLessonPageCopyWith<$Res>  {
  factory $StaffLessonPageCopyWith(StaffLessonPage value, $Res Function(StaffLessonPage) _then) = _$StaffLessonPageCopyWithImpl;
@useResult
$Res call({
 List<StaffLessonRow> rows, Map<String, dynamic> counts
});




}
/// @nodoc
class _$StaffLessonPageCopyWithImpl<$Res>
    implements $StaffLessonPageCopyWith<$Res> {
  _$StaffLessonPageCopyWithImpl(this._self, this._then);

  final StaffLessonPage _self;
  final $Res Function(StaffLessonPage) _then;

/// Create a copy of StaffLessonPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? counts = null,}) {
  return _then(_self.copyWith(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<StaffLessonRow>,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffLessonPage].
extension StaffLessonPagePatterns on StaffLessonPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffLessonPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffLessonPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffLessonPage value)  $default,){
final _that = this;
switch (_that) {
case _StaffLessonPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffLessonPage value)?  $default,){
final _that = this;
switch (_that) {
case _StaffLessonPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<StaffLessonRow> rows,  Map<String, dynamic> counts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffLessonPage() when $default != null:
return $default(_that.rows,_that.counts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<StaffLessonRow> rows,  Map<String, dynamic> counts)  $default,) {final _that = this;
switch (_that) {
case _StaffLessonPage():
return $default(_that.rows,_that.counts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<StaffLessonRow> rows,  Map<String, dynamic> counts)?  $default,) {final _that = this;
switch (_that) {
case _StaffLessonPage() when $default != null:
return $default(_that.rows,_that.counts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffLessonPage implements StaffLessonPage {
  const _StaffLessonPage({final  List<StaffLessonRow> rows = const <StaffLessonRow>[], final  Map<String, dynamic> counts = const <String, dynamic>{}}): _rows = rows,_counts = counts;
  factory _StaffLessonPage.fromJson(Map<String, dynamic> json) => _$StaffLessonPageFromJson(json);

 final  List<StaffLessonRow> _rows;
@override@JsonKey() List<StaffLessonRow> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

 final  Map<String, dynamic> _counts;
@override@JsonKey() Map<String, dynamic> get counts {
  if (_counts is EqualUnmodifiableMapView) return _counts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_counts);
}


/// Create a copy of StaffLessonPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffLessonPageCopyWith<_StaffLessonPage> get copyWith => __$StaffLessonPageCopyWithImpl<_StaffLessonPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffLessonPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffLessonPage&&const DeepCollectionEquality().equals(other._rows, _rows)&&const DeepCollectionEquality().equals(other._counts, _counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows),const DeepCollectionEquality().hash(_counts));

@override
String toString() {
  return 'StaffLessonPage(rows: $rows, counts: $counts)';
}


}

/// @nodoc
abstract mixin class _$StaffLessonPageCopyWith<$Res> implements $StaffLessonPageCopyWith<$Res> {
  factory _$StaffLessonPageCopyWith(_StaffLessonPage value, $Res Function(_StaffLessonPage) _then) = __$StaffLessonPageCopyWithImpl;
@override @useResult
$Res call({
 List<StaffLessonRow> rows, Map<String, dynamic> counts
});




}
/// @nodoc
class __$StaffLessonPageCopyWithImpl<$Res>
    implements _$StaffLessonPageCopyWith<$Res> {
  __$StaffLessonPageCopyWithImpl(this._self, this._then);

  final _StaffLessonPage _self;
  final $Res Function(_StaffLessonPage) _then;

/// Create a copy of StaffLessonPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,Object? counts = null,}) {
  return _then(_StaffLessonPage(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<StaffLessonRow>,counts: null == counts ? _self._counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$LessonLink {

 String get id; String get title;
/// Create a copy of LessonLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonLinkCopyWith<LessonLink> get copyWith => _$LessonLinkCopyWithImpl<LessonLink>(this as LessonLink, _$identity);

  /// Serializes this LessonLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonLink&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title);

@override
String toString() {
  return 'LessonLink(id: $id, title: $title)';
}


}

/// @nodoc
abstract mixin class $LessonLinkCopyWith<$Res>  {
  factory $LessonLinkCopyWith(LessonLink value, $Res Function(LessonLink) _then) = _$LessonLinkCopyWithImpl;
@useResult
$Res call({
 String id, String title
});




}
/// @nodoc
class _$LessonLinkCopyWithImpl<$Res>
    implements $LessonLinkCopyWith<$Res> {
  _$LessonLinkCopyWithImpl(this._self, this._then);

  final LessonLink _self;
  final $Res Function(LessonLink) _then;

/// Create a copy of LessonLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonLink].
extension LessonLinkPatterns on LessonLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonLink value)  $default,){
final _that = this;
switch (_that) {
case _LessonLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonLink value)?  $default,){
final _that = this;
switch (_that) {
case _LessonLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonLink() when $default != null:
return $default(_that.id,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title)  $default,) {final _that = this;
switch (_that) {
case _LessonLink():
return $default(_that.id,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title)?  $default,) {final _that = this;
switch (_that) {
case _LessonLink() when $default != null:
return $default(_that.id,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonLink implements LessonLink {
  const _LessonLink({required this.id, required this.title});
  factory _LessonLink.fromJson(Map<String, dynamic> json) => _$LessonLinkFromJson(json);

@override final  String id;
@override final  String title;

/// Create a copy of LessonLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonLinkCopyWith<_LessonLink> get copyWith => __$LessonLinkCopyWithImpl<_LessonLink>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonLinkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonLink&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title);

@override
String toString() {
  return 'LessonLink(id: $id, title: $title)';
}


}

/// @nodoc
abstract mixin class _$LessonLinkCopyWith<$Res> implements $LessonLinkCopyWith<$Res> {
  factory _$LessonLinkCopyWith(_LessonLink value, $Res Function(_LessonLink) _then) = __$LessonLinkCopyWithImpl;
@override @useResult
$Res call({
 String id, String title
});




}
/// @nodoc
class __$LessonLinkCopyWithImpl<$Res>
    implements _$LessonLinkCopyWith<$Res> {
  __$LessonLinkCopyWithImpl(this._self, this._then);

  final _LessonLink _self;
  final $Res Function(_LessonLink) _then;

/// Create a copy of LessonLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,}) {
  return _then(_LessonLink(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$StaffLessonDetail {

 Lesson get lesson; String get chapterId; String get chapterTitle; int get chapterIndex; int get lessonIndex; Chapter? get chapter; LessonLink? get previous; LessonLink? get next;
/// Create a copy of StaffLessonDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffLessonDetailCopyWith<StaffLessonDetail> get copyWith => _$StaffLessonDetailCopyWithImpl<StaffLessonDetail>(this as StaffLessonDetail, _$identity);

  /// Serializes this StaffLessonDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffLessonDetail&&(identical(other.lesson, lesson) || other.lesson == lesson)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.lessonIndex, lessonIndex) || other.lessonIndex == lessonIndex)&&(identical(other.chapter, chapter) || other.chapter == chapter)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.next, next) || other.next == next));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lesson,chapterId,chapterTitle,chapterIndex,lessonIndex,chapter,previous,next);

@override
String toString() {
  return 'StaffLessonDetail(lesson: $lesson, chapterId: $chapterId, chapterTitle: $chapterTitle, chapterIndex: $chapterIndex, lessonIndex: $lessonIndex, chapter: $chapter, previous: $previous, next: $next)';
}


}

/// @nodoc
abstract mixin class $StaffLessonDetailCopyWith<$Res>  {
  factory $StaffLessonDetailCopyWith(StaffLessonDetail value, $Res Function(StaffLessonDetail) _then) = _$StaffLessonDetailCopyWithImpl;
@useResult
$Res call({
 Lesson lesson, String chapterId, String chapterTitle, int chapterIndex, int lessonIndex, Chapter? chapter, LessonLink? previous, LessonLink? next
});


$LessonCopyWith<$Res> get lesson;$ChapterCopyWith<$Res>? get chapter;$LessonLinkCopyWith<$Res>? get previous;$LessonLinkCopyWith<$Res>? get next;

}
/// @nodoc
class _$StaffLessonDetailCopyWithImpl<$Res>
    implements $StaffLessonDetailCopyWith<$Res> {
  _$StaffLessonDetailCopyWithImpl(this._self, this._then);

  final StaffLessonDetail _self;
  final $Res Function(StaffLessonDetail) _then;

/// Create a copy of StaffLessonDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lesson = null,Object? chapterId = null,Object? chapterTitle = null,Object? chapterIndex = null,Object? lessonIndex = null,Object? chapter = freezed,Object? previous = freezed,Object? next = freezed,}) {
  return _then(_self.copyWith(
lesson: null == lesson ? _self.lesson : lesson // ignore: cast_nullable_to_non_nullable
as Lesson,chapterId: null == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String,chapterTitle: null == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String,chapterIndex: null == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int,lessonIndex: null == lessonIndex ? _self.lessonIndex : lessonIndex // ignore: cast_nullable_to_non_nullable
as int,chapter: freezed == chapter ? _self.chapter : chapter // ignore: cast_nullable_to_non_nullable
as Chapter?,previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as LessonLink?,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as LessonLink?,
  ));
}
/// Create a copy of StaffLessonDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonCopyWith<$Res> get lesson {
  
  return $LessonCopyWith<$Res>(_self.lesson, (value) {
    return _then(_self.copyWith(lesson: value));
  });
}/// Create a copy of StaffLessonDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChapterCopyWith<$Res>? get chapter {
    if (_self.chapter == null) {
    return null;
  }

  return $ChapterCopyWith<$Res>(_self.chapter!, (value) {
    return _then(_self.copyWith(chapter: value));
  });
}/// Create a copy of StaffLessonDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonLinkCopyWith<$Res>? get previous {
    if (_self.previous == null) {
    return null;
  }

  return $LessonLinkCopyWith<$Res>(_self.previous!, (value) {
    return _then(_self.copyWith(previous: value));
  });
}/// Create a copy of StaffLessonDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonLinkCopyWith<$Res>? get next {
    if (_self.next == null) {
    return null;
  }

  return $LessonLinkCopyWith<$Res>(_self.next!, (value) {
    return _then(_self.copyWith(next: value));
  });
}
}


/// Adds pattern-matching-related methods to [StaffLessonDetail].
extension StaffLessonDetailPatterns on StaffLessonDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffLessonDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffLessonDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffLessonDetail value)  $default,){
final _that = this;
switch (_that) {
case _StaffLessonDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffLessonDetail value)?  $default,){
final _that = this;
switch (_that) {
case _StaffLessonDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Lesson lesson,  String chapterId,  String chapterTitle,  int chapterIndex,  int lessonIndex,  Chapter? chapter,  LessonLink? previous,  LessonLink? next)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffLessonDetail() when $default != null:
return $default(_that.lesson,_that.chapterId,_that.chapterTitle,_that.chapterIndex,_that.lessonIndex,_that.chapter,_that.previous,_that.next);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Lesson lesson,  String chapterId,  String chapterTitle,  int chapterIndex,  int lessonIndex,  Chapter? chapter,  LessonLink? previous,  LessonLink? next)  $default,) {final _that = this;
switch (_that) {
case _StaffLessonDetail():
return $default(_that.lesson,_that.chapterId,_that.chapterTitle,_that.chapterIndex,_that.lessonIndex,_that.chapter,_that.previous,_that.next);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Lesson lesson,  String chapterId,  String chapterTitle,  int chapterIndex,  int lessonIndex,  Chapter? chapter,  LessonLink? previous,  LessonLink? next)?  $default,) {final _that = this;
switch (_that) {
case _StaffLessonDetail() when $default != null:
return $default(_that.lesson,_that.chapterId,_that.chapterTitle,_that.chapterIndex,_that.lessonIndex,_that.chapter,_that.previous,_that.next);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffLessonDetail implements StaffLessonDetail {
  const _StaffLessonDetail({required this.lesson, this.chapterId = '', this.chapterTitle = '', this.chapterIndex = 0, this.lessonIndex = 0, this.chapter, this.previous, this.next});
  factory _StaffLessonDetail.fromJson(Map<String, dynamic> json) => _$StaffLessonDetailFromJson(json);

@override final  Lesson lesson;
@override@JsonKey() final  String chapterId;
@override@JsonKey() final  String chapterTitle;
@override@JsonKey() final  int chapterIndex;
@override@JsonKey() final  int lessonIndex;
@override final  Chapter? chapter;
@override final  LessonLink? previous;
@override final  LessonLink? next;

/// Create a copy of StaffLessonDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffLessonDetailCopyWith<_StaffLessonDetail> get copyWith => __$StaffLessonDetailCopyWithImpl<_StaffLessonDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffLessonDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffLessonDetail&&(identical(other.lesson, lesson) || other.lesson == lesson)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.lessonIndex, lessonIndex) || other.lessonIndex == lessonIndex)&&(identical(other.chapter, chapter) || other.chapter == chapter)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.next, next) || other.next == next));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lesson,chapterId,chapterTitle,chapterIndex,lessonIndex,chapter,previous,next);

@override
String toString() {
  return 'StaffLessonDetail(lesson: $lesson, chapterId: $chapterId, chapterTitle: $chapterTitle, chapterIndex: $chapterIndex, lessonIndex: $lessonIndex, chapter: $chapter, previous: $previous, next: $next)';
}


}

/// @nodoc
abstract mixin class _$StaffLessonDetailCopyWith<$Res> implements $StaffLessonDetailCopyWith<$Res> {
  factory _$StaffLessonDetailCopyWith(_StaffLessonDetail value, $Res Function(_StaffLessonDetail) _then) = __$StaffLessonDetailCopyWithImpl;
@override @useResult
$Res call({
 Lesson lesson, String chapterId, String chapterTitle, int chapterIndex, int lessonIndex, Chapter? chapter, LessonLink? previous, LessonLink? next
});


@override $LessonCopyWith<$Res> get lesson;@override $ChapterCopyWith<$Res>? get chapter;@override $LessonLinkCopyWith<$Res>? get previous;@override $LessonLinkCopyWith<$Res>? get next;

}
/// @nodoc
class __$StaffLessonDetailCopyWithImpl<$Res>
    implements _$StaffLessonDetailCopyWith<$Res> {
  __$StaffLessonDetailCopyWithImpl(this._self, this._then);

  final _StaffLessonDetail _self;
  final $Res Function(_StaffLessonDetail) _then;

/// Create a copy of StaffLessonDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lesson = null,Object? chapterId = null,Object? chapterTitle = null,Object? chapterIndex = null,Object? lessonIndex = null,Object? chapter = freezed,Object? previous = freezed,Object? next = freezed,}) {
  return _then(_StaffLessonDetail(
lesson: null == lesson ? _self.lesson : lesson // ignore: cast_nullable_to_non_nullable
as Lesson,chapterId: null == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String,chapterTitle: null == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String,chapterIndex: null == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int,lessonIndex: null == lessonIndex ? _self.lessonIndex : lessonIndex // ignore: cast_nullable_to_non_nullable
as int,chapter: freezed == chapter ? _self.chapter : chapter // ignore: cast_nullable_to_non_nullable
as Chapter?,previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as LessonLink?,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as LessonLink?,
  ));
}

/// Create a copy of StaffLessonDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonCopyWith<$Res> get lesson {
  
  return $LessonCopyWith<$Res>(_self.lesson, (value) {
    return _then(_self.copyWith(lesson: value));
  });
}/// Create a copy of StaffLessonDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChapterCopyWith<$Res>? get chapter {
    if (_self.chapter == null) {
    return null;
  }

  return $ChapterCopyWith<$Res>(_self.chapter!, (value) {
    return _then(_self.copyWith(chapter: value));
  });
}/// Create a copy of StaffLessonDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonLinkCopyWith<$Res>? get previous {
    if (_self.previous == null) {
    return null;
  }

  return $LessonLinkCopyWith<$Res>(_self.previous!, (value) {
    return _then(_self.copyWith(previous: value));
  });
}/// Create a copy of StaffLessonDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonLinkCopyWith<$Res>? get next {
    if (_self.next == null) {
    return null;
  }

  return $LessonLinkCopyWith<$Res>(_self.next!, (value) {
    return _then(_self.copyWith(next: value));
  });
}
}


/// @nodoc
mixin _$StaffCategoryRow {

 CourseCategory get category; int get courseCount; int get publishedCount; int get learnerCount;
/// Create a copy of StaffCategoryRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffCategoryRowCopyWith<StaffCategoryRow> get copyWith => _$StaffCategoryRowCopyWithImpl<StaffCategoryRow>(this as StaffCategoryRow, _$identity);

  /// Serializes this StaffCategoryRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffCategoryRow&&(identical(other.category, category) || other.category == category)&&(identical(other.courseCount, courseCount) || other.courseCount == courseCount)&&(identical(other.publishedCount, publishedCount) || other.publishedCount == publishedCount)&&(identical(other.learnerCount, learnerCount) || other.learnerCount == learnerCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,courseCount,publishedCount,learnerCount);

@override
String toString() {
  return 'StaffCategoryRow(category: $category, courseCount: $courseCount, publishedCount: $publishedCount, learnerCount: $learnerCount)';
}


}

/// @nodoc
abstract mixin class $StaffCategoryRowCopyWith<$Res>  {
  factory $StaffCategoryRowCopyWith(StaffCategoryRow value, $Res Function(StaffCategoryRow) _then) = _$StaffCategoryRowCopyWithImpl;
@useResult
$Res call({
 CourseCategory category, int courseCount, int publishedCount, int learnerCount
});


$CourseCategoryCopyWith<$Res> get category;

}
/// @nodoc
class _$StaffCategoryRowCopyWithImpl<$Res>
    implements $StaffCategoryRowCopyWith<$Res> {
  _$StaffCategoryRowCopyWithImpl(this._self, this._then);

  final StaffCategoryRow _self;
  final $Res Function(StaffCategoryRow) _then;

/// Create a copy of StaffCategoryRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? courseCount = null,Object? publishedCount = null,Object? learnerCount = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CourseCategory,courseCount: null == courseCount ? _self.courseCount : courseCount // ignore: cast_nullable_to_non_nullable
as int,publishedCount: null == publishedCount ? _self.publishedCount : publishedCount // ignore: cast_nullable_to_non_nullable
as int,learnerCount: null == learnerCount ? _self.learnerCount : learnerCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of StaffCategoryRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseCategoryCopyWith<$Res> get category {
  
  return $CourseCategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [StaffCategoryRow].
extension StaffCategoryRowPatterns on StaffCategoryRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffCategoryRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffCategoryRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffCategoryRow value)  $default,){
final _that = this;
switch (_that) {
case _StaffCategoryRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffCategoryRow value)?  $default,){
final _that = this;
switch (_that) {
case _StaffCategoryRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CourseCategory category,  int courseCount,  int publishedCount,  int learnerCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffCategoryRow() when $default != null:
return $default(_that.category,_that.courseCount,_that.publishedCount,_that.learnerCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CourseCategory category,  int courseCount,  int publishedCount,  int learnerCount)  $default,) {final _that = this;
switch (_that) {
case _StaffCategoryRow():
return $default(_that.category,_that.courseCount,_that.publishedCount,_that.learnerCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CourseCategory category,  int courseCount,  int publishedCount,  int learnerCount)?  $default,) {final _that = this;
switch (_that) {
case _StaffCategoryRow() when $default != null:
return $default(_that.category,_that.courseCount,_that.publishedCount,_that.learnerCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffCategoryRow implements StaffCategoryRow {
  const _StaffCategoryRow({required this.category, this.courseCount = 0, this.publishedCount = 0, this.learnerCount = 0});
  factory _StaffCategoryRow.fromJson(Map<String, dynamic> json) => _$StaffCategoryRowFromJson(json);

@override final  CourseCategory category;
@override@JsonKey() final  int courseCount;
@override@JsonKey() final  int publishedCount;
@override@JsonKey() final  int learnerCount;

/// Create a copy of StaffCategoryRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffCategoryRowCopyWith<_StaffCategoryRow> get copyWith => __$StaffCategoryRowCopyWithImpl<_StaffCategoryRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffCategoryRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffCategoryRow&&(identical(other.category, category) || other.category == category)&&(identical(other.courseCount, courseCount) || other.courseCount == courseCount)&&(identical(other.publishedCount, publishedCount) || other.publishedCount == publishedCount)&&(identical(other.learnerCount, learnerCount) || other.learnerCount == learnerCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,courseCount,publishedCount,learnerCount);

@override
String toString() {
  return 'StaffCategoryRow(category: $category, courseCount: $courseCount, publishedCount: $publishedCount, learnerCount: $learnerCount)';
}


}

/// @nodoc
abstract mixin class _$StaffCategoryRowCopyWith<$Res> implements $StaffCategoryRowCopyWith<$Res> {
  factory _$StaffCategoryRowCopyWith(_StaffCategoryRow value, $Res Function(_StaffCategoryRow) _then) = __$StaffCategoryRowCopyWithImpl;
@override @useResult
$Res call({
 CourseCategory category, int courseCount, int publishedCount, int learnerCount
});


@override $CourseCategoryCopyWith<$Res> get category;

}
/// @nodoc
class __$StaffCategoryRowCopyWithImpl<$Res>
    implements _$StaffCategoryRowCopyWith<$Res> {
  __$StaffCategoryRowCopyWithImpl(this._self, this._then);

  final _StaffCategoryRow _self;
  final $Res Function(_StaffCategoryRow) _then;

/// Create a copy of StaffCategoryRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? courseCount = null,Object? publishedCount = null,Object? learnerCount = null,}) {
  return _then(_StaffCategoryRow(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CourseCategory,courseCount: null == courseCount ? _self.courseCount : courseCount // ignore: cast_nullable_to_non_nullable
as int,publishedCount: null == publishedCount ? _self.publishedCount : publishedCount // ignore: cast_nullable_to_non_nullable
as int,learnerCount: null == learnerCount ? _self.learnerCount : learnerCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of StaffCategoryRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseCategoryCopyWith<$Res> get category {
  
  return $CourseCategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// @nodoc
mixin _$StaffCategoryPage {

 List<StaffCategoryRow> get rows;
/// Create a copy of StaffCategoryPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffCategoryPageCopyWith<StaffCategoryPage> get copyWith => _$StaffCategoryPageCopyWithImpl<StaffCategoryPage>(this as StaffCategoryPage, _$identity);

  /// Serializes this StaffCategoryPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffCategoryPage&&const DeepCollectionEquality().equals(other.rows, rows));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rows));

@override
String toString() {
  return 'StaffCategoryPage(rows: $rows)';
}


}

/// @nodoc
abstract mixin class $StaffCategoryPageCopyWith<$Res>  {
  factory $StaffCategoryPageCopyWith(StaffCategoryPage value, $Res Function(StaffCategoryPage) _then) = _$StaffCategoryPageCopyWithImpl;
@useResult
$Res call({
 List<StaffCategoryRow> rows
});




}
/// @nodoc
class _$StaffCategoryPageCopyWithImpl<$Res>
    implements $StaffCategoryPageCopyWith<$Res> {
  _$StaffCategoryPageCopyWithImpl(this._self, this._then);

  final StaffCategoryPage _self;
  final $Res Function(StaffCategoryPage) _then;

/// Create a copy of StaffCategoryPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,}) {
  return _then(_self.copyWith(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<StaffCategoryRow>,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffCategoryPage].
extension StaffCategoryPagePatterns on StaffCategoryPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffCategoryPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffCategoryPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffCategoryPage value)  $default,){
final _that = this;
switch (_that) {
case _StaffCategoryPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffCategoryPage value)?  $default,){
final _that = this;
switch (_that) {
case _StaffCategoryPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<StaffCategoryRow> rows)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffCategoryPage() when $default != null:
return $default(_that.rows);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<StaffCategoryRow> rows)  $default,) {final _that = this;
switch (_that) {
case _StaffCategoryPage():
return $default(_that.rows);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<StaffCategoryRow> rows)?  $default,) {final _that = this;
switch (_that) {
case _StaffCategoryPage() when $default != null:
return $default(_that.rows);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffCategoryPage implements StaffCategoryPage {
  const _StaffCategoryPage({final  List<StaffCategoryRow> rows = const <StaffCategoryRow>[]}): _rows = rows;
  factory _StaffCategoryPage.fromJson(Map<String, dynamic> json) => _$StaffCategoryPageFromJson(json);

 final  List<StaffCategoryRow> _rows;
@override@JsonKey() List<StaffCategoryRow> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}


/// Create a copy of StaffCategoryPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffCategoryPageCopyWith<_StaffCategoryPage> get copyWith => __$StaffCategoryPageCopyWithImpl<_StaffCategoryPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffCategoryPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffCategoryPage&&const DeepCollectionEquality().equals(other._rows, _rows));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows));

@override
String toString() {
  return 'StaffCategoryPage(rows: $rows)';
}


}

/// @nodoc
abstract mixin class _$StaffCategoryPageCopyWith<$Res> implements $StaffCategoryPageCopyWith<$Res> {
  factory _$StaffCategoryPageCopyWith(_StaffCategoryPage value, $Res Function(_StaffCategoryPage) _then) = __$StaffCategoryPageCopyWithImpl;
@override @useResult
$Res call({
 List<StaffCategoryRow> rows
});




}
/// @nodoc
class __$StaffCategoryPageCopyWithImpl<$Res>
    implements _$StaffCategoryPageCopyWith<$Res> {
  __$StaffCategoryPageCopyWithImpl(this._self, this._then);

  final _StaffCategoryPage _self;
  final $Res Function(_StaffCategoryPage) _then;

/// Create a copy of StaffCategoryPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,}) {
  return _then(_StaffCategoryPage(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<StaffCategoryRow>,
  ));
}


}

// dart format on
