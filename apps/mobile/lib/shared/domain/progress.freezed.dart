// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LessonProgress {

 String get lessonId;@JsonKey(unknownEnumValue: ProgressState.unknown) ProgressState get state;/// 0–1 for a lesson partly consumed (video watched, reading scrolled).
 double? get fraction;/// Where a video was left, in seconds.
 int? get positionSec;@NullableUtcDateTimeConverter() DateTime? get completedAt;
/// Create a copy of LessonProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonProgressCopyWith<LessonProgress> get copyWith => _$LessonProgressCopyWithImpl<LessonProgress>(this as LessonProgress, _$identity);

  /// Serializes this LessonProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonProgress&&(identical(other.lessonId, lessonId) || other.lessonId == lessonId)&&(identical(other.state, state) || other.state == state)&&(identical(other.fraction, fraction) || other.fraction == fraction)&&(identical(other.positionSec, positionSec) || other.positionSec == positionSec)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lessonId,state,fraction,positionSec,completedAt);

@override
String toString() {
  return 'LessonProgress(lessonId: $lessonId, state: $state, fraction: $fraction, positionSec: $positionSec, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $LessonProgressCopyWith<$Res>  {
  factory $LessonProgressCopyWith(LessonProgress value, $Res Function(LessonProgress) _then) = _$LessonProgressCopyWithImpl;
@useResult
$Res call({
 String lessonId,@JsonKey(unknownEnumValue: ProgressState.unknown) ProgressState state, double? fraction, int? positionSec,@NullableUtcDateTimeConverter() DateTime? completedAt
});




}
/// @nodoc
class _$LessonProgressCopyWithImpl<$Res>
    implements $LessonProgressCopyWith<$Res> {
  _$LessonProgressCopyWithImpl(this._self, this._then);

  final LessonProgress _self;
  final $Res Function(LessonProgress) _then;

/// Create a copy of LessonProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lessonId = null,Object? state = null,Object? fraction = freezed,Object? positionSec = freezed,Object? completedAt = freezed,}) {
  return _then(_self.copyWith(
lessonId: null == lessonId ? _self.lessonId : lessonId // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ProgressState,fraction: freezed == fraction ? _self.fraction : fraction // ignore: cast_nullable_to_non_nullable
as double?,positionSec: freezed == positionSec ? _self.positionSec : positionSec // ignore: cast_nullable_to_non_nullable
as int?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonProgress].
extension LessonProgressPatterns on LessonProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonProgress value)  $default,){
final _that = this;
switch (_that) {
case _LessonProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonProgress value)?  $default,){
final _that = this;
switch (_that) {
case _LessonProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String lessonId, @JsonKey(unknownEnumValue: ProgressState.unknown)  ProgressState state,  double? fraction,  int? positionSec, @NullableUtcDateTimeConverter()  DateTime? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonProgress() when $default != null:
return $default(_that.lessonId,_that.state,_that.fraction,_that.positionSec,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String lessonId, @JsonKey(unknownEnumValue: ProgressState.unknown)  ProgressState state,  double? fraction,  int? positionSec, @NullableUtcDateTimeConverter()  DateTime? completedAt)  $default,) {final _that = this;
switch (_that) {
case _LessonProgress():
return $default(_that.lessonId,_that.state,_that.fraction,_that.positionSec,_that.completedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String lessonId, @JsonKey(unknownEnumValue: ProgressState.unknown)  ProgressState state,  double? fraction,  int? positionSec, @NullableUtcDateTimeConverter()  DateTime? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _LessonProgress() when $default != null:
return $default(_that.lessonId,_that.state,_that.fraction,_that.positionSec,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonProgress implements LessonProgress {
  const _LessonProgress({required this.lessonId, @JsonKey(unknownEnumValue: ProgressState.unknown) this.state = ProgressState.notStarted, this.fraction, this.positionSec, @NullableUtcDateTimeConverter() this.completedAt});
  factory _LessonProgress.fromJson(Map<String, dynamic> json) => _$LessonProgressFromJson(json);

@override final  String lessonId;
@override@JsonKey(unknownEnumValue: ProgressState.unknown) final  ProgressState state;
/// 0–1 for a lesson partly consumed (video watched, reading scrolled).
@override final  double? fraction;
/// Where a video was left, in seconds.
@override final  int? positionSec;
@override@NullableUtcDateTimeConverter() final  DateTime? completedAt;

/// Create a copy of LessonProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonProgressCopyWith<_LessonProgress> get copyWith => __$LessonProgressCopyWithImpl<_LessonProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonProgress&&(identical(other.lessonId, lessonId) || other.lessonId == lessonId)&&(identical(other.state, state) || other.state == state)&&(identical(other.fraction, fraction) || other.fraction == fraction)&&(identical(other.positionSec, positionSec) || other.positionSec == positionSec)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lessonId,state,fraction,positionSec,completedAt);

@override
String toString() {
  return 'LessonProgress(lessonId: $lessonId, state: $state, fraction: $fraction, positionSec: $positionSec, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$LessonProgressCopyWith<$Res> implements $LessonProgressCopyWith<$Res> {
  factory _$LessonProgressCopyWith(_LessonProgress value, $Res Function(_LessonProgress) _then) = __$LessonProgressCopyWithImpl;
@override @useResult
$Res call({
 String lessonId,@JsonKey(unknownEnumValue: ProgressState.unknown) ProgressState state, double? fraction, int? positionSec,@NullableUtcDateTimeConverter() DateTime? completedAt
});




}
/// @nodoc
class __$LessonProgressCopyWithImpl<$Res>
    implements _$LessonProgressCopyWith<$Res> {
  __$LessonProgressCopyWithImpl(this._self, this._then);

  final _LessonProgress _self;
  final $Res Function(_LessonProgress) _then;

/// Create a copy of LessonProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lessonId = null,Object? state = null,Object? fraction = freezed,Object? positionSec = freezed,Object? completedAt = freezed,}) {
  return _then(_LessonProgress(
lessonId: null == lessonId ? _self.lessonId : lessonId // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ProgressState,fraction: freezed == fraction ? _self.fraction : fraction // ignore: cast_nullable_to_non_nullable
as double?,positionSec: freezed == positionSec ? _self.positionSec : positionSec // ignore: cast_nullable_to_non_nullable
as int?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CourseProgressSnapshot {

 String get courseId; Map<String, LessonProgress> get lessons; String? get lastLessonId;@NullableUtcDateTimeConverter() DateTime? get lastActiveAt;
/// Create a copy of CourseProgressSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseProgressSnapshotCopyWith<CourseProgressSnapshot> get copyWith => _$CourseProgressSnapshotCopyWithImpl<CourseProgressSnapshot>(this as CourseProgressSnapshot, _$identity);

  /// Serializes this CourseProgressSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseProgressSnapshot&&(identical(other.courseId, courseId) || other.courseId == courseId)&&const DeepCollectionEquality().equals(other.lessons, lessons)&&(identical(other.lastLessonId, lastLessonId) || other.lastLessonId == lastLessonId)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseId,const DeepCollectionEquality().hash(lessons),lastLessonId,lastActiveAt);

@override
String toString() {
  return 'CourseProgressSnapshot(courseId: $courseId, lessons: $lessons, lastLessonId: $lastLessonId, lastActiveAt: $lastActiveAt)';
}


}

/// @nodoc
abstract mixin class $CourseProgressSnapshotCopyWith<$Res>  {
  factory $CourseProgressSnapshotCopyWith(CourseProgressSnapshot value, $Res Function(CourseProgressSnapshot) _then) = _$CourseProgressSnapshotCopyWithImpl;
@useResult
$Res call({
 String courseId, Map<String, LessonProgress> lessons, String? lastLessonId,@NullableUtcDateTimeConverter() DateTime? lastActiveAt
});




}
/// @nodoc
class _$CourseProgressSnapshotCopyWithImpl<$Res>
    implements $CourseProgressSnapshotCopyWith<$Res> {
  _$CourseProgressSnapshotCopyWithImpl(this._self, this._then);

  final CourseProgressSnapshot _self;
  final $Res Function(CourseProgressSnapshot) _then;

/// Create a copy of CourseProgressSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? courseId = null,Object? lessons = null,Object? lastLessonId = freezed,Object? lastActiveAt = freezed,}) {
  return _then(_self.copyWith(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,lessons: null == lessons ? _self.lessons : lessons // ignore: cast_nullable_to_non_nullable
as Map<String, LessonProgress>,lastLessonId: freezed == lastLessonId ? _self.lastLessonId : lastLessonId // ignore: cast_nullable_to_non_nullable
as String?,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CourseProgressSnapshot].
extension CourseProgressSnapshotPatterns on CourseProgressSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseProgressSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseProgressSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseProgressSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _CourseProgressSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseProgressSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _CourseProgressSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String courseId,  Map<String, LessonProgress> lessons,  String? lastLessonId, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseProgressSnapshot() when $default != null:
return $default(_that.courseId,_that.lessons,_that.lastLessonId,_that.lastActiveAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String courseId,  Map<String, LessonProgress> lessons,  String? lastLessonId, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt)  $default,) {final _that = this;
switch (_that) {
case _CourseProgressSnapshot():
return $default(_that.courseId,_that.lessons,_that.lastLessonId,_that.lastActiveAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String courseId,  Map<String, LessonProgress> lessons,  String? lastLessonId, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt)?  $default,) {final _that = this;
switch (_that) {
case _CourseProgressSnapshot() when $default != null:
return $default(_that.courseId,_that.lessons,_that.lastLessonId,_that.lastActiveAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseProgressSnapshot extends CourseProgressSnapshot {
  const _CourseProgressSnapshot({required this.courseId, final  Map<String, LessonProgress> lessons = const <String, LessonProgress>{}, this.lastLessonId, @NullableUtcDateTimeConverter() this.lastActiveAt}): _lessons = lessons,super._();
  factory _CourseProgressSnapshot.fromJson(Map<String, dynamic> json) => _$CourseProgressSnapshotFromJson(json);

@override final  String courseId;
 final  Map<String, LessonProgress> _lessons;
@override@JsonKey() Map<String, LessonProgress> get lessons {
  if (_lessons is EqualUnmodifiableMapView) return _lessons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_lessons);
}

@override final  String? lastLessonId;
@override@NullableUtcDateTimeConverter() final  DateTime? lastActiveAt;

/// Create a copy of CourseProgressSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseProgressSnapshotCopyWith<_CourseProgressSnapshot> get copyWith => __$CourseProgressSnapshotCopyWithImpl<_CourseProgressSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseProgressSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseProgressSnapshot&&(identical(other.courseId, courseId) || other.courseId == courseId)&&const DeepCollectionEquality().equals(other._lessons, _lessons)&&(identical(other.lastLessonId, lastLessonId) || other.lastLessonId == lastLessonId)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseId,const DeepCollectionEquality().hash(_lessons),lastLessonId,lastActiveAt);

@override
String toString() {
  return 'CourseProgressSnapshot(courseId: $courseId, lessons: $lessons, lastLessonId: $lastLessonId, lastActiveAt: $lastActiveAt)';
}


}

/// @nodoc
abstract mixin class _$CourseProgressSnapshotCopyWith<$Res> implements $CourseProgressSnapshotCopyWith<$Res> {
  factory _$CourseProgressSnapshotCopyWith(_CourseProgressSnapshot value, $Res Function(_CourseProgressSnapshot) _then) = __$CourseProgressSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String courseId, Map<String, LessonProgress> lessons, String? lastLessonId,@NullableUtcDateTimeConverter() DateTime? lastActiveAt
});




}
/// @nodoc
class __$CourseProgressSnapshotCopyWithImpl<$Res>
    implements _$CourseProgressSnapshotCopyWith<$Res> {
  __$CourseProgressSnapshotCopyWithImpl(this._self, this._then);

  final _CourseProgressSnapshot _self;
  final $Res Function(_CourseProgressSnapshot) _then;

/// Create a copy of CourseProgressSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? courseId = null,Object? lessons = null,Object? lastLessonId = freezed,Object? lastActiveAt = freezed,}) {
  return _then(_CourseProgressSnapshot(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,lessons: null == lessons ? _self._lessons : lessons // ignore: cast_nullable_to_non_nullable
as Map<String, LessonProgress>,lastLessonId: freezed == lastLessonId ? _self.lastLessonId : lastLessonId // ignore: cast_nullable_to_non_nullable
as String?,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ProgressSummary {

 int get completed; int get total;/// 0–100.
 int get percent; int get remainingMin;@JsonKey(unknownEnumValue: ProgressState.unknown) ProgressState get state;
/// Create a copy of ProgressSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgressSummaryCopyWith<ProgressSummary> get copyWith => _$ProgressSummaryCopyWithImpl<ProgressSummary>(this as ProgressSummary, _$identity);

  /// Serializes this ProgressSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgressSummary&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.total, total) || other.total == total)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.remainingMin, remainingMin) || other.remainingMin == remainingMin)&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,completed,total,percent,remainingMin,state);

@override
String toString() {
  return 'ProgressSummary(completed: $completed, total: $total, percent: $percent, remainingMin: $remainingMin, state: $state)';
}


}

/// @nodoc
abstract mixin class $ProgressSummaryCopyWith<$Res>  {
  factory $ProgressSummaryCopyWith(ProgressSummary value, $Res Function(ProgressSummary) _then) = _$ProgressSummaryCopyWithImpl;
@useResult
$Res call({
 int completed, int total, int percent, int remainingMin,@JsonKey(unknownEnumValue: ProgressState.unknown) ProgressState state
});




}
/// @nodoc
class _$ProgressSummaryCopyWithImpl<$Res>
    implements $ProgressSummaryCopyWith<$Res> {
  _$ProgressSummaryCopyWithImpl(this._self, this._then);

  final ProgressSummary _self;
  final $Res Function(ProgressSummary) _then;

/// Create a copy of ProgressSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? completed = null,Object? total = null,Object? percent = null,Object? remainingMin = null,Object? state = null,}) {
  return _then(_self.copyWith(
completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,remainingMin: null == remainingMin ? _self.remainingMin : remainingMin // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ProgressState,
  ));
}

}


/// Adds pattern-matching-related methods to [ProgressSummary].
extension ProgressSummaryPatterns on ProgressSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgressSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgressSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgressSummary value)  $default,){
final _that = this;
switch (_that) {
case _ProgressSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgressSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ProgressSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int completed,  int total,  int percent,  int remainingMin, @JsonKey(unknownEnumValue: ProgressState.unknown)  ProgressState state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgressSummary() when $default != null:
return $default(_that.completed,_that.total,_that.percent,_that.remainingMin,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int completed,  int total,  int percent,  int remainingMin, @JsonKey(unknownEnumValue: ProgressState.unknown)  ProgressState state)  $default,) {final _that = this;
switch (_that) {
case _ProgressSummary():
return $default(_that.completed,_that.total,_that.percent,_that.remainingMin,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int completed,  int total,  int percent,  int remainingMin, @JsonKey(unknownEnumValue: ProgressState.unknown)  ProgressState state)?  $default,) {final _that = this;
switch (_that) {
case _ProgressSummary() when $default != null:
return $default(_that.completed,_that.total,_that.percent,_that.remainingMin,_that.state);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProgressSummary extends ProgressSummary {
  const _ProgressSummary({this.completed = 0, this.total = 0, this.percent = 0, this.remainingMin = 0, @JsonKey(unknownEnumValue: ProgressState.unknown) this.state = ProgressState.notStarted}): super._();
  factory _ProgressSummary.fromJson(Map<String, dynamic> json) => _$ProgressSummaryFromJson(json);

@override@JsonKey() final  int completed;
@override@JsonKey() final  int total;
/// 0–100.
@override@JsonKey() final  int percent;
@override@JsonKey() final  int remainingMin;
@override@JsonKey(unknownEnumValue: ProgressState.unknown) final  ProgressState state;

/// Create a copy of ProgressSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgressSummaryCopyWith<_ProgressSummary> get copyWith => __$ProgressSummaryCopyWithImpl<_ProgressSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProgressSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgressSummary&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.total, total) || other.total == total)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.remainingMin, remainingMin) || other.remainingMin == remainingMin)&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,completed,total,percent,remainingMin,state);

@override
String toString() {
  return 'ProgressSummary(completed: $completed, total: $total, percent: $percent, remainingMin: $remainingMin, state: $state)';
}


}

/// @nodoc
abstract mixin class _$ProgressSummaryCopyWith<$Res> implements $ProgressSummaryCopyWith<$Res> {
  factory _$ProgressSummaryCopyWith(_ProgressSummary value, $Res Function(_ProgressSummary) _then) = __$ProgressSummaryCopyWithImpl;
@override @useResult
$Res call({
 int completed, int total, int percent, int remainingMin,@JsonKey(unknownEnumValue: ProgressState.unknown) ProgressState state
});




}
/// @nodoc
class __$ProgressSummaryCopyWithImpl<$Res>
    implements _$ProgressSummaryCopyWith<$Res> {
  __$ProgressSummaryCopyWithImpl(this._self, this._then);

  final _ProgressSummary _self;
  final $Res Function(_ProgressSummary) _then;

/// Create a copy of ProgressSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? completed = null,Object? total = null,Object? percent = null,Object? remainingMin = null,Object? state = null,}) {
  return _then(_ProgressSummary(
completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,remainingMin: null == remainingMin ? _self.remainingMin : remainingMin // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ProgressState,
  ));
}


}


/// @nodoc
mixin _$Enrollment {

 String get id; String get studentId; String get courseId;@JsonKey(unknownEnumValue: EnrollmentStatus.unknown) EnrollmentStatus get status; int get progress; String get source;/// Empty for the placeholder enrolment of a learner who is not enrolled.
@EmptyAsNullUtcDateTimeConverter() DateTime? get enrolledAt;@NullableUtcDateTimeConverter() DateTime? get lastActiveAt;@NullableUtcDateTimeConverter() DateTime? get completedAt;@NullableUtcDateTimeConverter() DateTime? get expiresAt; String? get lastLessonId;
/// Create a copy of Enrollment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnrollmentCopyWith<Enrollment> get copyWith => _$EnrollmentCopyWithImpl<Enrollment>(this as Enrollment, _$identity);

  /// Serializes this Enrollment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Enrollment&&(identical(other.id, id) || other.id == id)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.source, source) || other.source == source)&&(identical(other.enrolledAt, enrolledAt) || other.enrolledAt == enrolledAt)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.lastLessonId, lastLessonId) || other.lastLessonId == lastLessonId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,studentId,courseId,status,progress,source,enrolledAt,lastActiveAt,completedAt,expiresAt,lastLessonId);

@override
String toString() {
  return 'Enrollment(id: $id, studentId: $studentId, courseId: $courseId, status: $status, progress: $progress, source: $source, enrolledAt: $enrolledAt, lastActiveAt: $lastActiveAt, completedAt: $completedAt, expiresAt: $expiresAt, lastLessonId: $lastLessonId)';
}


}

/// @nodoc
abstract mixin class $EnrollmentCopyWith<$Res>  {
  factory $EnrollmentCopyWith(Enrollment value, $Res Function(Enrollment) _then) = _$EnrollmentCopyWithImpl;
@useResult
$Res call({
 String id, String studentId, String courseId,@JsonKey(unknownEnumValue: EnrollmentStatus.unknown) EnrollmentStatus status, int progress, String source,@EmptyAsNullUtcDateTimeConverter() DateTime? enrolledAt,@NullableUtcDateTimeConverter() DateTime? lastActiveAt,@NullableUtcDateTimeConverter() DateTime? completedAt,@NullableUtcDateTimeConverter() DateTime? expiresAt, String? lastLessonId
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? studentId = null,Object? courseId = null,Object? status = null,Object? progress = null,Object? source = null,Object? enrolledAt = freezed,Object? lastActiveAt = freezed,Object? completedAt = freezed,Object? expiresAt = freezed,Object? lastLessonId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EnrollmentStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,enrolledAt: freezed == enrolledAt ? _self.enrolledAt : enrolledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastLessonId: freezed == lastLessonId ? _self.lastLessonId : lastLessonId // ignore: cast_nullable_to_non_nullable
as String?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String studentId,  String courseId, @JsonKey(unknownEnumValue: EnrollmentStatus.unknown)  EnrollmentStatus status,  int progress,  String source, @EmptyAsNullUtcDateTimeConverter()  DateTime? enrolledAt, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt, @NullableUtcDateTimeConverter()  DateTime? completedAt, @NullableUtcDateTimeConverter()  DateTime? expiresAt,  String? lastLessonId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Enrollment() when $default != null:
return $default(_that.id,_that.studentId,_that.courseId,_that.status,_that.progress,_that.source,_that.enrolledAt,_that.lastActiveAt,_that.completedAt,_that.expiresAt,_that.lastLessonId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String studentId,  String courseId, @JsonKey(unknownEnumValue: EnrollmentStatus.unknown)  EnrollmentStatus status,  int progress,  String source, @EmptyAsNullUtcDateTimeConverter()  DateTime? enrolledAt, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt, @NullableUtcDateTimeConverter()  DateTime? completedAt, @NullableUtcDateTimeConverter()  DateTime? expiresAt,  String? lastLessonId)  $default,) {final _that = this;
switch (_that) {
case _Enrollment():
return $default(_that.id,_that.studentId,_that.courseId,_that.status,_that.progress,_that.source,_that.enrolledAt,_that.lastActiveAt,_that.completedAt,_that.expiresAt,_that.lastLessonId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String studentId,  String courseId, @JsonKey(unknownEnumValue: EnrollmentStatus.unknown)  EnrollmentStatus status,  int progress,  String source, @EmptyAsNullUtcDateTimeConverter()  DateTime? enrolledAt, @NullableUtcDateTimeConverter()  DateTime? lastActiveAt, @NullableUtcDateTimeConverter()  DateTime? completedAt, @NullableUtcDateTimeConverter()  DateTime? expiresAt,  String? lastLessonId)?  $default,) {final _that = this;
switch (_that) {
case _Enrollment() when $default != null:
return $default(_that.id,_that.studentId,_that.courseId,_that.status,_that.progress,_that.source,_that.enrolledAt,_that.lastActiveAt,_that.completedAt,_that.expiresAt,_that.lastLessonId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Enrollment extends Enrollment {
  const _Enrollment({required this.id, required this.studentId, required this.courseId, @JsonKey(unknownEnumValue: EnrollmentStatus.unknown) this.status = EnrollmentStatus.active, this.progress = 0, this.source = '', @EmptyAsNullUtcDateTimeConverter() this.enrolledAt, @NullableUtcDateTimeConverter() this.lastActiveAt, @NullableUtcDateTimeConverter() this.completedAt, @NullableUtcDateTimeConverter() this.expiresAt, this.lastLessonId}): super._();
  factory _Enrollment.fromJson(Map<String, dynamic> json) => _$EnrollmentFromJson(json);

@override final  String id;
@override final  String studentId;
@override final  String courseId;
@override@JsonKey(unknownEnumValue: EnrollmentStatus.unknown) final  EnrollmentStatus status;
@override@JsonKey() final  int progress;
@override@JsonKey() final  String source;
/// Empty for the placeholder enrolment of a learner who is not enrolled.
@override@EmptyAsNullUtcDateTimeConverter() final  DateTime? enrolledAt;
@override@NullableUtcDateTimeConverter() final  DateTime? lastActiveAt;
@override@NullableUtcDateTimeConverter() final  DateTime? completedAt;
@override@NullableUtcDateTimeConverter() final  DateTime? expiresAt;
@override final  String? lastLessonId;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Enrollment&&(identical(other.id, id) || other.id == id)&&(identical(other.studentId, studentId) || other.studentId == studentId)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.source, source) || other.source == source)&&(identical(other.enrolledAt, enrolledAt) || other.enrolledAt == enrolledAt)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.lastLessonId, lastLessonId) || other.lastLessonId == lastLessonId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,studentId,courseId,status,progress,source,enrolledAt,lastActiveAt,completedAt,expiresAt,lastLessonId);

@override
String toString() {
  return 'Enrollment(id: $id, studentId: $studentId, courseId: $courseId, status: $status, progress: $progress, source: $source, enrolledAt: $enrolledAt, lastActiveAt: $lastActiveAt, completedAt: $completedAt, expiresAt: $expiresAt, lastLessonId: $lastLessonId)';
}


}

/// @nodoc
abstract mixin class _$EnrollmentCopyWith<$Res> implements $EnrollmentCopyWith<$Res> {
  factory _$EnrollmentCopyWith(_Enrollment value, $Res Function(_Enrollment) _then) = __$EnrollmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String studentId, String courseId,@JsonKey(unknownEnumValue: EnrollmentStatus.unknown) EnrollmentStatus status, int progress, String source,@EmptyAsNullUtcDateTimeConverter() DateTime? enrolledAt,@NullableUtcDateTimeConverter() DateTime? lastActiveAt,@NullableUtcDateTimeConverter() DateTime? completedAt,@NullableUtcDateTimeConverter() DateTime? expiresAt, String? lastLessonId
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? studentId = null,Object? courseId = null,Object? status = null,Object? progress = null,Object? source = null,Object? enrolledAt = freezed,Object? lastActiveAt = freezed,Object? completedAt = freezed,Object? expiresAt = freezed,Object? lastLessonId = freezed,}) {
  return _then(_Enrollment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,studentId: null == studentId ? _self.studentId : studentId // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EnrollmentStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,enrolledAt: freezed == enrolledAt ? _self.enrolledAt : enrolledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastLessonId: freezed == lastLessonId ? _self.lastLessonId : lastLessonId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$NextLesson {

 String get id; String get title;/// The backend's `LessonType`, kept as sent.
 String get type; int get durationMin; int get chapterIndex; String get chapterTitle;/// "2.3"
 String get lessonNumber;@JsonKey(unknownEnumValue: ProgressState.unknown) ProgressState get state; double? get fraction; int? get positionSec;
/// Create a copy of NextLesson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NextLessonCopyWith<NextLesson> get copyWith => _$NextLessonCopyWithImpl<NextLesson>(this as NextLesson, _$identity);

  /// Serializes this NextLesson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NextLesson&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.lessonNumber, lessonNumber) || other.lessonNumber == lessonNumber)&&(identical(other.state, state) || other.state == state)&&(identical(other.fraction, fraction) || other.fraction == fraction)&&(identical(other.positionSec, positionSec) || other.positionSec == positionSec));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,type,durationMin,chapterIndex,chapterTitle,lessonNumber,state,fraction,positionSec);

@override
String toString() {
  return 'NextLesson(id: $id, title: $title, type: $type, durationMin: $durationMin, chapterIndex: $chapterIndex, chapterTitle: $chapterTitle, lessonNumber: $lessonNumber, state: $state, fraction: $fraction, positionSec: $positionSec)';
}


}

/// @nodoc
abstract mixin class $NextLessonCopyWith<$Res>  {
  factory $NextLessonCopyWith(NextLesson value, $Res Function(NextLesson) _then) = _$NextLessonCopyWithImpl;
@useResult
$Res call({
 String id, String title, String type, int durationMin, int chapterIndex, String chapterTitle, String lessonNumber,@JsonKey(unknownEnumValue: ProgressState.unknown) ProgressState state, double? fraction, int? positionSec
});




}
/// @nodoc
class _$NextLessonCopyWithImpl<$Res>
    implements $NextLessonCopyWith<$Res> {
  _$NextLessonCopyWithImpl(this._self, this._then);

  final NextLesson _self;
  final $Res Function(NextLesson) _then;

/// Create a copy of NextLesson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? type = null,Object? durationMin = null,Object? chapterIndex = null,Object? chapterTitle = null,Object? lessonNumber = null,Object? state = null,Object? fraction = freezed,Object? positionSec = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,durationMin: null == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int,chapterIndex: null == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int,chapterTitle: null == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String,lessonNumber: null == lessonNumber ? _self.lessonNumber : lessonNumber // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ProgressState,fraction: freezed == fraction ? _self.fraction : fraction // ignore: cast_nullable_to_non_nullable
as double?,positionSec: freezed == positionSec ? _self.positionSec : positionSec // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [NextLesson].
extension NextLessonPatterns on NextLesson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NextLesson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NextLesson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NextLesson value)  $default,){
final _that = this;
switch (_that) {
case _NextLesson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NextLesson value)?  $default,){
final _that = this;
switch (_that) {
case _NextLesson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String type,  int durationMin,  int chapterIndex,  String chapterTitle,  String lessonNumber, @JsonKey(unknownEnumValue: ProgressState.unknown)  ProgressState state,  double? fraction,  int? positionSec)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NextLesson() when $default != null:
return $default(_that.id,_that.title,_that.type,_that.durationMin,_that.chapterIndex,_that.chapterTitle,_that.lessonNumber,_that.state,_that.fraction,_that.positionSec);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String type,  int durationMin,  int chapterIndex,  String chapterTitle,  String lessonNumber, @JsonKey(unknownEnumValue: ProgressState.unknown)  ProgressState state,  double? fraction,  int? positionSec)  $default,) {final _that = this;
switch (_that) {
case _NextLesson():
return $default(_that.id,_that.title,_that.type,_that.durationMin,_that.chapterIndex,_that.chapterTitle,_that.lessonNumber,_that.state,_that.fraction,_that.positionSec);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String type,  int durationMin,  int chapterIndex,  String chapterTitle,  String lessonNumber, @JsonKey(unknownEnumValue: ProgressState.unknown)  ProgressState state,  double? fraction,  int? positionSec)?  $default,) {final _that = this;
switch (_that) {
case _NextLesson() when $default != null:
return $default(_that.id,_that.title,_that.type,_that.durationMin,_that.chapterIndex,_that.chapterTitle,_that.lessonNumber,_that.state,_that.fraction,_that.positionSec);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NextLesson implements NextLesson {
  const _NextLesson({required this.id, required this.title, this.type = '', this.durationMin = 0, this.chapterIndex = 0, this.chapterTitle = '', this.lessonNumber = '', @JsonKey(unknownEnumValue: ProgressState.unknown) this.state = ProgressState.notStarted, this.fraction, this.positionSec});
  factory _NextLesson.fromJson(Map<String, dynamic> json) => _$NextLessonFromJson(json);

@override final  String id;
@override final  String title;
/// The backend's `LessonType`, kept as sent.
@override@JsonKey() final  String type;
@override@JsonKey() final  int durationMin;
@override@JsonKey() final  int chapterIndex;
@override@JsonKey() final  String chapterTitle;
/// "2.3"
@override@JsonKey() final  String lessonNumber;
@override@JsonKey(unknownEnumValue: ProgressState.unknown) final  ProgressState state;
@override final  double? fraction;
@override final  int? positionSec;

/// Create a copy of NextLesson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NextLessonCopyWith<_NextLesson> get copyWith => __$NextLessonCopyWithImpl<_NextLesson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NextLessonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NextLesson&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.lessonNumber, lessonNumber) || other.lessonNumber == lessonNumber)&&(identical(other.state, state) || other.state == state)&&(identical(other.fraction, fraction) || other.fraction == fraction)&&(identical(other.positionSec, positionSec) || other.positionSec == positionSec));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,type,durationMin,chapterIndex,chapterTitle,lessonNumber,state,fraction,positionSec);

@override
String toString() {
  return 'NextLesson(id: $id, title: $title, type: $type, durationMin: $durationMin, chapterIndex: $chapterIndex, chapterTitle: $chapterTitle, lessonNumber: $lessonNumber, state: $state, fraction: $fraction, positionSec: $positionSec)';
}


}

/// @nodoc
abstract mixin class _$NextLessonCopyWith<$Res> implements $NextLessonCopyWith<$Res> {
  factory _$NextLessonCopyWith(_NextLesson value, $Res Function(_NextLesson) _then) = __$NextLessonCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String type, int durationMin, int chapterIndex, String chapterTitle, String lessonNumber,@JsonKey(unknownEnumValue: ProgressState.unknown) ProgressState state, double? fraction, int? positionSec
});




}
/// @nodoc
class __$NextLessonCopyWithImpl<$Res>
    implements _$NextLessonCopyWith<$Res> {
  __$NextLessonCopyWithImpl(this._self, this._then);

  final _NextLesson _self;
  final $Res Function(_NextLesson) _then;

/// Create a copy of NextLesson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? type = null,Object? durationMin = null,Object? chapterIndex = null,Object? chapterTitle = null,Object? lessonNumber = null,Object? state = null,Object? fraction = freezed,Object? positionSec = freezed,}) {
  return _then(_NextLesson(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,durationMin: null == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int,chapterIndex: null == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int,chapterTitle: null == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String,lessonNumber: null == lessonNumber ? _self.lessonNumber : lessonNumber // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ProgressState,fraction: freezed == fraction ? _self.fraction : fraction // ignore: cast_nullable_to_non_nullable
as double?,positionSec: freezed == positionSec ? _self.positionSec : positionSec // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
