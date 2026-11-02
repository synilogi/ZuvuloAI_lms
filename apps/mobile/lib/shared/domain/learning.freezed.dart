// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'learning.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LearnerCourse {

 Course get course; Enrollment get enrollment; ProgressSummary get progress; CourseProgressSnapshot get snapshot;/// Absent once the course is finished, or while every remaining lesson is locked.
 NextLesson? get next; List<String> get instructorNames; String get levelTitle;@NullableUtcDateTimeConverter() DateTime? get lastActiveAt;
/// Create a copy of LearnerCourse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearnerCourseCopyWith<LearnerCourse> get copyWith => _$LearnerCourseCopyWithImpl<LearnerCourse>(this as LearnerCourse, _$identity);

  /// Serializes this LearnerCourse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearnerCourse&&(identical(other.course, course) || other.course == course)&&(identical(other.enrollment, enrollment) || other.enrollment == enrollment)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&(identical(other.next, next) || other.next == next)&&const DeepCollectionEquality().equals(other.instructorNames, instructorNames)&&(identical(other.levelTitle, levelTitle) || other.levelTitle == levelTitle)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,course,enrollment,progress,snapshot,next,const DeepCollectionEquality().hash(instructorNames),levelTitle,lastActiveAt);

@override
String toString() {
  return 'LearnerCourse(course: $course, enrollment: $enrollment, progress: $progress, snapshot: $snapshot, next: $next, instructorNames: $instructorNames, levelTitle: $levelTitle, lastActiveAt: $lastActiveAt)';
}


}

/// @nodoc
abstract mixin class $LearnerCourseCopyWith<$Res>  {
  factory $LearnerCourseCopyWith(LearnerCourse value, $Res Function(LearnerCourse) _then) = _$LearnerCourseCopyWithImpl;
@useResult
$Res call({
 Course course, Enrollment enrollment, ProgressSummary progress, CourseProgressSnapshot snapshot, NextLesson? next, List<String> instructorNames, String levelTitle,@NullableUtcDateTimeConverter() DateTime? lastActiveAt
});


$CourseCopyWith<$Res> get course;$EnrollmentCopyWith<$Res> get enrollment;$ProgressSummaryCopyWith<$Res> get progress;$CourseProgressSnapshotCopyWith<$Res> get snapshot;$NextLessonCopyWith<$Res>? get next;

}
/// @nodoc
class _$LearnerCourseCopyWithImpl<$Res>
    implements $LearnerCourseCopyWith<$Res> {
  _$LearnerCourseCopyWithImpl(this._self, this._then);

  final LearnerCourse _self;
  final $Res Function(LearnerCourse) _then;

/// Create a copy of LearnerCourse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? course = null,Object? enrollment = null,Object? progress = null,Object? snapshot = null,Object? next = freezed,Object? instructorNames = null,Object? levelTitle = null,Object? lastActiveAt = freezed,}) {
  return _then(_self.copyWith(
course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as Course,enrollment: null == enrollment ? _self.enrollment : enrollment // ignore: cast_nullable_to_non_nullable
as Enrollment,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as ProgressSummary,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as CourseProgressSnapshot,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as NextLesson?,instructorNames: null == instructorNames ? _self.instructorNames : instructorNames // ignore: cast_nullable_to_non_nullable
as List<String>,levelTitle: null == levelTitle ? _self.levelTitle : levelTitle // ignore: cast_nullable_to_non_nullable
as String,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of LearnerCourse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseCopyWith<$Res> get course {
  
  return $CourseCopyWith<$Res>(_self.course, (value) {
    return _then(_self.copyWith(course: value));
  });
}/// Create a copy of LearnerCourse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EnrollmentCopyWith<$Res> get enrollment {
  
  return $EnrollmentCopyWith<$Res>(_self.enrollment, (value) {
    return _then(_self.copyWith(enrollment: value));
  });
}/// Create a copy of LearnerCourse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProgressSummaryCopyWith<$Res> get progress {
  
  return $ProgressSummaryCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of LearnerCourse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseProgressSnapshotCopyWith<$Res> get snapshot {
  
  return $CourseProgressSnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}/// Create a copy of LearnerCourse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NextLessonCopyWith<$Res>? get next {
    if (_self.next == null) {
    return null;
  }

  return $NextLessonCopyWith<$Res>(_self.next!, (value) {
    return _then(_self.copyWith(next: value));
  });
}
}


/// Adds pattern-matching-related methods to [LearnerCourse].
extension LearnerCoursePatterns on LearnerCourse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearnerCourse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearnerCourse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearnerCourse value)  $default,){
final _that = this;
switch (_that) {
case _LearnerCourse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearnerCourse value)?  $default,){
final _that = this;
switch (_that) {
case _LearnerCourse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Course course,  Enrollment enrollment,  ProgressSummary progress,  CourseProgressSnapshot snapshot,  NextLesson? next,  List<String> instructorNames,  String levelTitle, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearnerCourse() when $default != null:
return $default(_that.course,_that.enrollment,_that.progress,_that.snapshot,_that.next,_that.instructorNames,_that.levelTitle,_that.lastActiveAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Course course,  Enrollment enrollment,  ProgressSummary progress,  CourseProgressSnapshot snapshot,  NextLesson? next,  List<String> instructorNames,  String levelTitle, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt)  $default,) {final _that = this;
switch (_that) {
case _LearnerCourse():
return $default(_that.course,_that.enrollment,_that.progress,_that.snapshot,_that.next,_that.instructorNames,_that.levelTitle,_that.lastActiveAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Course course,  Enrollment enrollment,  ProgressSummary progress,  CourseProgressSnapshot snapshot,  NextLesson? next,  List<String> instructorNames,  String levelTitle, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt)?  $default,) {final _that = this;
switch (_that) {
case _LearnerCourse() when $default != null:
return $default(_that.course,_that.enrollment,_that.progress,_that.snapshot,_that.next,_that.instructorNames,_that.levelTitle,_that.lastActiveAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LearnerCourse implements LearnerCourse {
  const _LearnerCourse({required this.course, required this.enrollment, required this.progress, required this.snapshot, this.next, final  List<String> instructorNames = const <String>[], this.levelTitle = '', @NullableUtcDateTimeConverter() this.lastActiveAt}): _instructorNames = instructorNames;
  factory _LearnerCourse.fromJson(Map<String, dynamic> json) => _$LearnerCourseFromJson(json);

@override final  Course course;
@override final  Enrollment enrollment;
@override final  ProgressSummary progress;
@override final  CourseProgressSnapshot snapshot;
/// Absent once the course is finished, or while every remaining lesson is locked.
@override final  NextLesson? next;
 final  List<String> _instructorNames;
@override@JsonKey() List<String> get instructorNames {
  if (_instructorNames is EqualUnmodifiableListView) return _instructorNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_instructorNames);
}

@override@JsonKey() final  String levelTitle;
@override@NullableUtcDateTimeConverter() final  DateTime? lastActiveAt;

/// Create a copy of LearnerCourse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearnerCourseCopyWith<_LearnerCourse> get copyWith => __$LearnerCourseCopyWithImpl<_LearnerCourse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearnerCourseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearnerCourse&&(identical(other.course, course) || other.course == course)&&(identical(other.enrollment, enrollment) || other.enrollment == enrollment)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&(identical(other.next, next) || other.next == next)&&const DeepCollectionEquality().equals(other._instructorNames, _instructorNames)&&(identical(other.levelTitle, levelTitle) || other.levelTitle == levelTitle)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,course,enrollment,progress,snapshot,next,const DeepCollectionEquality().hash(_instructorNames),levelTitle,lastActiveAt);

@override
String toString() {
  return 'LearnerCourse(course: $course, enrollment: $enrollment, progress: $progress, snapshot: $snapshot, next: $next, instructorNames: $instructorNames, levelTitle: $levelTitle, lastActiveAt: $lastActiveAt)';
}


}

/// @nodoc
abstract mixin class _$LearnerCourseCopyWith<$Res> implements $LearnerCourseCopyWith<$Res> {
  factory _$LearnerCourseCopyWith(_LearnerCourse value, $Res Function(_LearnerCourse) _then) = __$LearnerCourseCopyWithImpl;
@override @useResult
$Res call({
 Course course, Enrollment enrollment, ProgressSummary progress, CourseProgressSnapshot snapshot, NextLesson? next, List<String> instructorNames, String levelTitle,@NullableUtcDateTimeConverter() DateTime? lastActiveAt
});


@override $CourseCopyWith<$Res> get course;@override $EnrollmentCopyWith<$Res> get enrollment;@override $ProgressSummaryCopyWith<$Res> get progress;@override $CourseProgressSnapshotCopyWith<$Res> get snapshot;@override $NextLessonCopyWith<$Res>? get next;

}
/// @nodoc
class __$LearnerCourseCopyWithImpl<$Res>
    implements _$LearnerCourseCopyWith<$Res> {
  __$LearnerCourseCopyWithImpl(this._self, this._then);

  final _LearnerCourse _self;
  final $Res Function(_LearnerCourse) _then;

/// Create a copy of LearnerCourse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? course = null,Object? enrollment = null,Object? progress = null,Object? snapshot = null,Object? next = freezed,Object? instructorNames = null,Object? levelTitle = null,Object? lastActiveAt = freezed,}) {
  return _then(_LearnerCourse(
course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as Course,enrollment: null == enrollment ? _self.enrollment : enrollment // ignore: cast_nullable_to_non_nullable
as Enrollment,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as ProgressSummary,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as CourseProgressSnapshot,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as NextLesson?,instructorNames: null == instructorNames ? _self._instructorNames : instructorNames // ignore: cast_nullable_to_non_nullable
as List<String>,levelTitle: null == levelTitle ? _self.levelTitle : levelTitle // ignore: cast_nullable_to_non_nullable
as String,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of LearnerCourse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseCopyWith<$Res> get course {
  
  return $CourseCopyWith<$Res>(_self.course, (value) {
    return _then(_self.copyWith(course: value));
  });
}/// Create a copy of LearnerCourse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EnrollmentCopyWith<$Res> get enrollment {
  
  return $EnrollmentCopyWith<$Res>(_self.enrollment, (value) {
    return _then(_self.copyWith(enrollment: value));
  });
}/// Create a copy of LearnerCourse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProgressSummaryCopyWith<$Res> get progress {
  
  return $ProgressSummaryCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of LearnerCourse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseProgressSnapshotCopyWith<$Res> get snapshot {
  
  return $CourseProgressSnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}/// Create a copy of LearnerCourse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NextLessonCopyWith<$Res>? get next {
    if (_self.next == null) {
    return null;
  }

  return $NextLessonCopyWith<$Res>(_self.next!, (value) {
    return _then(_self.copyWith(next: value));
  });
}
}


/// @nodoc
mixin _$SavedCourse {

 Course get course; List<String> get instructorNames; String get levelTitle;
/// Create a copy of SavedCourse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedCourseCopyWith<SavedCourse> get copyWith => _$SavedCourseCopyWithImpl<SavedCourse>(this as SavedCourse, _$identity);

  /// Serializes this SavedCourse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedCourse&&(identical(other.course, course) || other.course == course)&&const DeepCollectionEquality().equals(other.instructorNames, instructorNames)&&(identical(other.levelTitle, levelTitle) || other.levelTitle == levelTitle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,course,const DeepCollectionEquality().hash(instructorNames),levelTitle);

@override
String toString() {
  return 'SavedCourse(course: $course, instructorNames: $instructorNames, levelTitle: $levelTitle)';
}


}

/// @nodoc
abstract mixin class $SavedCourseCopyWith<$Res>  {
  factory $SavedCourseCopyWith(SavedCourse value, $Res Function(SavedCourse) _then) = _$SavedCourseCopyWithImpl;
@useResult
$Res call({
 Course course, List<String> instructorNames, String levelTitle
});


$CourseCopyWith<$Res> get course;

}
/// @nodoc
class _$SavedCourseCopyWithImpl<$Res>
    implements $SavedCourseCopyWith<$Res> {
  _$SavedCourseCopyWithImpl(this._self, this._then);

  final SavedCourse _self;
  final $Res Function(SavedCourse) _then;

/// Create a copy of SavedCourse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? course = null,Object? instructorNames = null,Object? levelTitle = null,}) {
  return _then(_self.copyWith(
course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as Course,instructorNames: null == instructorNames ? _self.instructorNames : instructorNames // ignore: cast_nullable_to_non_nullable
as List<String>,levelTitle: null == levelTitle ? _self.levelTitle : levelTitle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of SavedCourse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseCopyWith<$Res> get course {
  
  return $CourseCopyWith<$Res>(_self.course, (value) {
    return _then(_self.copyWith(course: value));
  });
}
}


/// Adds pattern-matching-related methods to [SavedCourse].
extension SavedCoursePatterns on SavedCourse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedCourse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedCourse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedCourse value)  $default,){
final _that = this;
switch (_that) {
case _SavedCourse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedCourse value)?  $default,){
final _that = this;
switch (_that) {
case _SavedCourse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Course course,  List<String> instructorNames,  String levelTitle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedCourse() when $default != null:
return $default(_that.course,_that.instructorNames,_that.levelTitle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Course course,  List<String> instructorNames,  String levelTitle)  $default,) {final _that = this;
switch (_that) {
case _SavedCourse():
return $default(_that.course,_that.instructorNames,_that.levelTitle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Course course,  List<String> instructorNames,  String levelTitle)?  $default,) {final _that = this;
switch (_that) {
case _SavedCourse() when $default != null:
return $default(_that.course,_that.instructorNames,_that.levelTitle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavedCourse implements SavedCourse {
  const _SavedCourse({required this.course, final  List<String> instructorNames = const <String>[], this.levelTitle = ''}): _instructorNames = instructorNames;
  factory _SavedCourse.fromJson(Map<String, dynamic> json) => _$SavedCourseFromJson(json);

@override final  Course course;
 final  List<String> _instructorNames;
@override@JsonKey() List<String> get instructorNames {
  if (_instructorNames is EqualUnmodifiableListView) return _instructorNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_instructorNames);
}

@override@JsonKey() final  String levelTitle;

/// Create a copy of SavedCourse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedCourseCopyWith<_SavedCourse> get copyWith => __$SavedCourseCopyWithImpl<_SavedCourse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavedCourseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedCourse&&(identical(other.course, course) || other.course == course)&&const DeepCollectionEquality().equals(other._instructorNames, _instructorNames)&&(identical(other.levelTitle, levelTitle) || other.levelTitle == levelTitle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,course,const DeepCollectionEquality().hash(_instructorNames),levelTitle);

@override
String toString() {
  return 'SavedCourse(course: $course, instructorNames: $instructorNames, levelTitle: $levelTitle)';
}


}

/// @nodoc
abstract mixin class _$SavedCourseCopyWith<$Res> implements $SavedCourseCopyWith<$Res> {
  factory _$SavedCourseCopyWith(_SavedCourse value, $Res Function(_SavedCourse) _then) = __$SavedCourseCopyWithImpl;
@override @useResult
$Res call({
 Course course, List<String> instructorNames, String levelTitle
});


@override $CourseCopyWith<$Res> get course;

}
/// @nodoc
class __$SavedCourseCopyWithImpl<$Res>
    implements _$SavedCourseCopyWith<$Res> {
  __$SavedCourseCopyWithImpl(this._self, this._then);

  final _SavedCourse _self;
  final $Res Function(_SavedCourse) _then;

/// Create a copy of SavedCourse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? course = null,Object? instructorNames = null,Object? levelTitle = null,}) {
  return _then(_SavedCourse(
course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as Course,instructorNames: null == instructorNames ? _self._instructorNames : instructorNames // ignore: cast_nullable_to_non_nullable
as List<String>,levelTitle: null == levelTitle ? _self.levelTitle : levelTitle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of SavedCourse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseCopyWith<$Res> get course {
  
  return $CourseCopyWith<$Res>(_self.course, (value) {
    return _then(_self.copyWith(course: value));
  });
}
}


/// @nodoc
mixin _$CompleteResult {

 CourseProgressSnapshot get snapshot; ProgressSummary get progress;/// The chapter's title, when this lesson finished it.
 String? get chapterCompleted; bool get courseCompleted; String? get nextLessonId;
/// Create a copy of CompleteResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompleteResultCopyWith<CompleteResult> get copyWith => _$CompleteResultCopyWithImpl<CompleteResult>(this as CompleteResult, _$identity);

  /// Serializes this CompleteResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompleteResult&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.chapterCompleted, chapterCompleted) || other.chapterCompleted == chapterCompleted)&&(identical(other.courseCompleted, courseCompleted) || other.courseCompleted == courseCompleted)&&(identical(other.nextLessonId, nextLessonId) || other.nextLessonId == nextLessonId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,snapshot,progress,chapterCompleted,courseCompleted,nextLessonId);

@override
String toString() {
  return 'CompleteResult(snapshot: $snapshot, progress: $progress, chapterCompleted: $chapterCompleted, courseCompleted: $courseCompleted, nextLessonId: $nextLessonId)';
}


}

/// @nodoc
abstract mixin class $CompleteResultCopyWith<$Res>  {
  factory $CompleteResultCopyWith(CompleteResult value, $Res Function(CompleteResult) _then) = _$CompleteResultCopyWithImpl;
@useResult
$Res call({
 CourseProgressSnapshot snapshot, ProgressSummary progress, String? chapterCompleted, bool courseCompleted, String? nextLessonId
});


$CourseProgressSnapshotCopyWith<$Res> get snapshot;$ProgressSummaryCopyWith<$Res> get progress;

}
/// @nodoc
class _$CompleteResultCopyWithImpl<$Res>
    implements $CompleteResultCopyWith<$Res> {
  _$CompleteResultCopyWithImpl(this._self, this._then);

  final CompleteResult _self;
  final $Res Function(CompleteResult) _then;

/// Create a copy of CompleteResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? snapshot = null,Object? progress = null,Object? chapterCompleted = freezed,Object? courseCompleted = null,Object? nextLessonId = freezed,}) {
  return _then(_self.copyWith(
snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as CourseProgressSnapshot,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as ProgressSummary,chapterCompleted: freezed == chapterCompleted ? _self.chapterCompleted : chapterCompleted // ignore: cast_nullable_to_non_nullable
as String?,courseCompleted: null == courseCompleted ? _self.courseCompleted : courseCompleted // ignore: cast_nullable_to_non_nullable
as bool,nextLessonId: freezed == nextLessonId ? _self.nextLessonId : nextLessonId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of CompleteResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseProgressSnapshotCopyWith<$Res> get snapshot {
  
  return $CourseProgressSnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}/// Create a copy of CompleteResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProgressSummaryCopyWith<$Res> get progress {
  
  return $ProgressSummaryCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}
}


/// Adds pattern-matching-related methods to [CompleteResult].
extension CompleteResultPatterns on CompleteResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompleteResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompleteResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompleteResult value)  $default,){
final _that = this;
switch (_that) {
case _CompleteResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompleteResult value)?  $default,){
final _that = this;
switch (_that) {
case _CompleteResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CourseProgressSnapshot snapshot,  ProgressSummary progress,  String? chapterCompleted,  bool courseCompleted,  String? nextLessonId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompleteResult() when $default != null:
return $default(_that.snapshot,_that.progress,_that.chapterCompleted,_that.courseCompleted,_that.nextLessonId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CourseProgressSnapshot snapshot,  ProgressSummary progress,  String? chapterCompleted,  bool courseCompleted,  String? nextLessonId)  $default,) {final _that = this;
switch (_that) {
case _CompleteResult():
return $default(_that.snapshot,_that.progress,_that.chapterCompleted,_that.courseCompleted,_that.nextLessonId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CourseProgressSnapshot snapshot,  ProgressSummary progress,  String? chapterCompleted,  bool courseCompleted,  String? nextLessonId)?  $default,) {final _that = this;
switch (_that) {
case _CompleteResult() when $default != null:
return $default(_that.snapshot,_that.progress,_that.chapterCompleted,_that.courseCompleted,_that.nextLessonId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompleteResult implements CompleteResult {
  const _CompleteResult({required this.snapshot, required this.progress, this.chapterCompleted, this.courseCompleted = false, this.nextLessonId});
  factory _CompleteResult.fromJson(Map<String, dynamic> json) => _$CompleteResultFromJson(json);

@override final  CourseProgressSnapshot snapshot;
@override final  ProgressSummary progress;
/// The chapter's title, when this lesson finished it.
@override final  String? chapterCompleted;
@override@JsonKey() final  bool courseCompleted;
@override final  String? nextLessonId;

/// Create a copy of CompleteResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompleteResultCopyWith<_CompleteResult> get copyWith => __$CompleteResultCopyWithImpl<_CompleteResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompleteResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompleteResult&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.chapterCompleted, chapterCompleted) || other.chapterCompleted == chapterCompleted)&&(identical(other.courseCompleted, courseCompleted) || other.courseCompleted == courseCompleted)&&(identical(other.nextLessonId, nextLessonId) || other.nextLessonId == nextLessonId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,snapshot,progress,chapterCompleted,courseCompleted,nextLessonId);

@override
String toString() {
  return 'CompleteResult(snapshot: $snapshot, progress: $progress, chapterCompleted: $chapterCompleted, courseCompleted: $courseCompleted, nextLessonId: $nextLessonId)';
}


}

/// @nodoc
abstract mixin class _$CompleteResultCopyWith<$Res> implements $CompleteResultCopyWith<$Res> {
  factory _$CompleteResultCopyWith(_CompleteResult value, $Res Function(_CompleteResult) _then) = __$CompleteResultCopyWithImpl;
@override @useResult
$Res call({
 CourseProgressSnapshot snapshot, ProgressSummary progress, String? chapterCompleted, bool courseCompleted, String? nextLessonId
});


@override $CourseProgressSnapshotCopyWith<$Res> get snapshot;@override $ProgressSummaryCopyWith<$Res> get progress;

}
/// @nodoc
class __$CompleteResultCopyWithImpl<$Res>
    implements _$CompleteResultCopyWith<$Res> {
  __$CompleteResultCopyWithImpl(this._self, this._then);

  final _CompleteResult _self;
  final $Res Function(_CompleteResult) _then;

/// Create a copy of CompleteResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? snapshot = null,Object? progress = null,Object? chapterCompleted = freezed,Object? courseCompleted = null,Object? nextLessonId = freezed,}) {
  return _then(_CompleteResult(
snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as CourseProgressSnapshot,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as ProgressSummary,chapterCompleted: freezed == chapterCompleted ? _self.chapterCompleted : chapterCompleted // ignore: cast_nullable_to_non_nullable
as String?,courseCompleted: null == courseCompleted ? _self.courseCompleted : courseCompleted // ignore: cast_nullable_to_non_nullable
as bool,nextLessonId: freezed == nextLessonId ? _self.nextLessonId : nextLessonId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of CompleteResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseProgressSnapshotCopyWith<$Res> get snapshot {
  
  return $CourseProgressSnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}/// Create a copy of CompleteResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProgressSummaryCopyWith<$Res> get progress {
  
  return $ProgressSummaryCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}
}

// dart format on
