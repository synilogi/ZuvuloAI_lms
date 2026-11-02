// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'staff_submission.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReviewQueue {

 int get toReview; int get overdue; List<CourseReviewLoad> get byCourse;
/// Create a copy of ReviewQueue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewQueueCopyWith<ReviewQueue> get copyWith => _$ReviewQueueCopyWithImpl<ReviewQueue>(this as ReviewQueue, _$identity);

  /// Serializes this ReviewQueue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewQueue&&(identical(other.toReview, toReview) || other.toReview == toReview)&&(identical(other.overdue, overdue) || other.overdue == overdue)&&const DeepCollectionEquality().equals(other.byCourse, byCourse));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,toReview,overdue,const DeepCollectionEquality().hash(byCourse));

@override
String toString() {
  return 'ReviewQueue(toReview: $toReview, overdue: $overdue, byCourse: $byCourse)';
}


}

/// @nodoc
abstract mixin class $ReviewQueueCopyWith<$Res>  {
  factory $ReviewQueueCopyWith(ReviewQueue value, $Res Function(ReviewQueue) _then) = _$ReviewQueueCopyWithImpl;
@useResult
$Res call({
 int toReview, int overdue, List<CourseReviewLoad> byCourse
});




}
/// @nodoc
class _$ReviewQueueCopyWithImpl<$Res>
    implements $ReviewQueueCopyWith<$Res> {
  _$ReviewQueueCopyWithImpl(this._self, this._then);

  final ReviewQueue _self;
  final $Res Function(ReviewQueue) _then;

/// Create a copy of ReviewQueue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? toReview = null,Object? overdue = null,Object? byCourse = null,}) {
  return _then(_self.copyWith(
toReview: null == toReview ? _self.toReview : toReview // ignore: cast_nullable_to_non_nullable
as int,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as int,byCourse: null == byCourse ? _self.byCourse : byCourse // ignore: cast_nullable_to_non_nullable
as List<CourseReviewLoad>,
  ));
}

}


/// Adds pattern-matching-related methods to [ReviewQueue].
extension ReviewQueuePatterns on ReviewQueue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewQueue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewQueue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewQueue value)  $default,){
final _that = this;
switch (_that) {
case _ReviewQueue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewQueue value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewQueue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int toReview,  int overdue,  List<CourseReviewLoad> byCourse)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewQueue() when $default != null:
return $default(_that.toReview,_that.overdue,_that.byCourse);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int toReview,  int overdue,  List<CourseReviewLoad> byCourse)  $default,) {final _that = this;
switch (_that) {
case _ReviewQueue():
return $default(_that.toReview,_that.overdue,_that.byCourse);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int toReview,  int overdue,  List<CourseReviewLoad> byCourse)?  $default,) {final _that = this;
switch (_that) {
case _ReviewQueue() when $default != null:
return $default(_that.toReview,_that.overdue,_that.byCourse);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReviewQueue extends ReviewQueue {
  const _ReviewQueue({this.toReview = 0, this.overdue = 0, final  List<CourseReviewLoad> byCourse = const <CourseReviewLoad>[]}): _byCourse = byCourse,super._();
  factory _ReviewQueue.fromJson(Map<String, dynamic> json) => _$ReviewQueueFromJson(json);

@override@JsonKey() final  int toReview;
@override@JsonKey() final  int overdue;
 final  List<CourseReviewLoad> _byCourse;
@override@JsonKey() List<CourseReviewLoad> get byCourse {
  if (_byCourse is EqualUnmodifiableListView) return _byCourse;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byCourse);
}


/// Create a copy of ReviewQueue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewQueueCopyWith<_ReviewQueue> get copyWith => __$ReviewQueueCopyWithImpl<_ReviewQueue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewQueueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewQueue&&(identical(other.toReview, toReview) || other.toReview == toReview)&&(identical(other.overdue, overdue) || other.overdue == overdue)&&const DeepCollectionEquality().equals(other._byCourse, _byCourse));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,toReview,overdue,const DeepCollectionEquality().hash(_byCourse));

@override
String toString() {
  return 'ReviewQueue(toReview: $toReview, overdue: $overdue, byCourse: $byCourse)';
}


}

/// @nodoc
abstract mixin class _$ReviewQueueCopyWith<$Res> implements $ReviewQueueCopyWith<$Res> {
  factory _$ReviewQueueCopyWith(_ReviewQueue value, $Res Function(_ReviewQueue) _then) = __$ReviewQueueCopyWithImpl;
@override @useResult
$Res call({
 int toReview, int overdue, List<CourseReviewLoad> byCourse
});




}
/// @nodoc
class __$ReviewQueueCopyWithImpl<$Res>
    implements _$ReviewQueueCopyWith<$Res> {
  __$ReviewQueueCopyWithImpl(this._self, this._then);

  final _ReviewQueue _self;
  final $Res Function(_ReviewQueue) _then;

/// Create a copy of ReviewQueue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? toReview = null,Object? overdue = null,Object? byCourse = null,}) {
  return _then(_ReviewQueue(
toReview: null == toReview ? _self.toReview : toReview // ignore: cast_nullable_to_non_nullable
as int,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as int,byCourse: null == byCourse ? _self._byCourse : byCourse // ignore: cast_nullable_to_non_nullable
as List<CourseReviewLoad>,
  ));
}


}


/// @nodoc
mixin _$CourseReviewLoad {

 String get courseId; int get toReview; int get overdue;
/// Create a copy of CourseReviewLoad
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseReviewLoadCopyWith<CourseReviewLoad> get copyWith => _$CourseReviewLoadCopyWithImpl<CourseReviewLoad>(this as CourseReviewLoad, _$identity);

  /// Serializes this CourseReviewLoad to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseReviewLoad&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.toReview, toReview) || other.toReview == toReview)&&(identical(other.overdue, overdue) || other.overdue == overdue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseId,toReview,overdue);

@override
String toString() {
  return 'CourseReviewLoad(courseId: $courseId, toReview: $toReview, overdue: $overdue)';
}


}

/// @nodoc
abstract mixin class $CourseReviewLoadCopyWith<$Res>  {
  factory $CourseReviewLoadCopyWith(CourseReviewLoad value, $Res Function(CourseReviewLoad) _then) = _$CourseReviewLoadCopyWithImpl;
@useResult
$Res call({
 String courseId, int toReview, int overdue
});




}
/// @nodoc
class _$CourseReviewLoadCopyWithImpl<$Res>
    implements $CourseReviewLoadCopyWith<$Res> {
  _$CourseReviewLoadCopyWithImpl(this._self, this._then);

  final CourseReviewLoad _self;
  final $Res Function(CourseReviewLoad) _then;

/// Create a copy of CourseReviewLoad
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? courseId = null,Object? toReview = null,Object? overdue = null,}) {
  return _then(_self.copyWith(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,toReview: null == toReview ? _self.toReview : toReview // ignore: cast_nullable_to_non_nullable
as int,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CourseReviewLoad].
extension CourseReviewLoadPatterns on CourseReviewLoad {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseReviewLoad value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseReviewLoad() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseReviewLoad value)  $default,){
final _that = this;
switch (_that) {
case _CourseReviewLoad():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseReviewLoad value)?  $default,){
final _that = this;
switch (_that) {
case _CourseReviewLoad() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String courseId,  int toReview,  int overdue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseReviewLoad() when $default != null:
return $default(_that.courseId,_that.toReview,_that.overdue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String courseId,  int toReview,  int overdue)  $default,) {final _that = this;
switch (_that) {
case _CourseReviewLoad():
return $default(_that.courseId,_that.toReview,_that.overdue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String courseId,  int toReview,  int overdue)?  $default,) {final _that = this;
switch (_that) {
case _CourseReviewLoad() when $default != null:
return $default(_that.courseId,_that.toReview,_that.overdue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseReviewLoad implements CourseReviewLoad {
  const _CourseReviewLoad({this.courseId = '', this.toReview = 0, this.overdue = 0});
  factory _CourseReviewLoad.fromJson(Map<String, dynamic> json) => _$CourseReviewLoadFromJson(json);

@override@JsonKey() final  String courseId;
@override@JsonKey() final  int toReview;
@override@JsonKey() final  int overdue;

/// Create a copy of CourseReviewLoad
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseReviewLoadCopyWith<_CourseReviewLoad> get copyWith => __$CourseReviewLoadCopyWithImpl<_CourseReviewLoad>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseReviewLoadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseReviewLoad&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.toReview, toReview) || other.toReview == toReview)&&(identical(other.overdue, overdue) || other.overdue == overdue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseId,toReview,overdue);

@override
String toString() {
  return 'CourseReviewLoad(courseId: $courseId, toReview: $toReview, overdue: $overdue)';
}


}

/// @nodoc
abstract mixin class _$CourseReviewLoadCopyWith<$Res> implements $CourseReviewLoadCopyWith<$Res> {
  factory _$CourseReviewLoadCopyWith(_CourseReviewLoad value, $Res Function(_CourseReviewLoad) _then) = __$CourseReviewLoadCopyWithImpl;
@override @useResult
$Res call({
 String courseId, int toReview, int overdue
});




}
/// @nodoc
class __$CourseReviewLoadCopyWithImpl<$Res>
    implements _$CourseReviewLoadCopyWith<$Res> {
  __$CourseReviewLoadCopyWithImpl(this._self, this._then);

  final _CourseReviewLoad _self;
  final $Res Function(_CourseReviewLoad) _then;

/// Create a copy of CourseReviewLoad
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? courseId = null,Object? toReview = null,Object? overdue = null,}) {
  return _then(_CourseReviewLoad(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,toReview: null == toReview ? _self.toReview : toReview // ignore: cast_nullable_to_non_nullable
as int,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ReviewLearner {

 String get id; String get name; String get email; String get city;/// Their progress through the course, sent with a submission's detail only.
 num get progress;@NullableUtcDateTimeConverter() DateTime? get enrolledAt;
/// Create a copy of ReviewLearner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewLearnerCopyWith<ReviewLearner> get copyWith => _$ReviewLearnerCopyWithImpl<ReviewLearner>(this as ReviewLearner, _$identity);

  /// Serializes this ReviewLearner to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewLearner&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.city, city) || other.city == city)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.enrolledAt, enrolledAt) || other.enrolledAt == enrolledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,city,progress,enrolledAt);

@override
String toString() {
  return 'ReviewLearner(id: $id, name: $name, email: $email, city: $city, progress: $progress, enrolledAt: $enrolledAt)';
}


}

/// @nodoc
abstract mixin class $ReviewLearnerCopyWith<$Res>  {
  factory $ReviewLearnerCopyWith(ReviewLearner value, $Res Function(ReviewLearner) _then) = _$ReviewLearnerCopyWithImpl;
@useResult
$Res call({
 String id, String name, String email, String city, num progress,@NullableUtcDateTimeConverter() DateTime? enrolledAt
});




}
/// @nodoc
class _$ReviewLearnerCopyWithImpl<$Res>
    implements $ReviewLearnerCopyWith<$Res> {
  _$ReviewLearnerCopyWithImpl(this._self, this._then);

  final ReviewLearner _self;
  final $Res Function(ReviewLearner) _then;

/// Create a copy of ReviewLearner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,Object? city = null,Object? progress = null,Object? enrolledAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as num,enrolledAt: freezed == enrolledAt ? _self.enrolledAt : enrolledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReviewLearner].
extension ReviewLearnerPatterns on ReviewLearner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewLearner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewLearner() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewLearner value)  $default,){
final _that = this;
switch (_that) {
case _ReviewLearner():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewLearner value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewLearner() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String email,  String city,  num progress, @NullableUtcDateTimeConverter()  DateTime? enrolledAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewLearner() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.city,_that.progress,_that.enrolledAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String email,  String city,  num progress, @NullableUtcDateTimeConverter()  DateTime? enrolledAt)  $default,) {final _that = this;
switch (_that) {
case _ReviewLearner():
return $default(_that.id,_that.name,_that.email,_that.city,_that.progress,_that.enrolledAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String email,  String city,  num progress, @NullableUtcDateTimeConverter()  DateTime? enrolledAt)?  $default,) {final _that = this;
switch (_that) {
case _ReviewLearner() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.city,_that.progress,_that.enrolledAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReviewLearner implements ReviewLearner {
  const _ReviewLearner({this.id = '', this.name = '', this.email = '', this.city = '', this.progress = 0, @NullableUtcDateTimeConverter() this.enrolledAt});
  factory _ReviewLearner.fromJson(Map<String, dynamic> json) => _$ReviewLearnerFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String email;
@override@JsonKey() final  String city;
/// Their progress through the course, sent with a submission's detail only.
@override@JsonKey() final  num progress;
@override@NullableUtcDateTimeConverter() final  DateTime? enrolledAt;

/// Create a copy of ReviewLearner
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewLearnerCopyWith<_ReviewLearner> get copyWith => __$ReviewLearnerCopyWithImpl<_ReviewLearner>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewLearnerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewLearner&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.city, city) || other.city == city)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.enrolledAt, enrolledAt) || other.enrolledAt == enrolledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,city,progress,enrolledAt);

@override
String toString() {
  return 'ReviewLearner(id: $id, name: $name, email: $email, city: $city, progress: $progress, enrolledAt: $enrolledAt)';
}


}

/// @nodoc
abstract mixin class _$ReviewLearnerCopyWith<$Res> implements $ReviewLearnerCopyWith<$Res> {
  factory _$ReviewLearnerCopyWith(_ReviewLearner value, $Res Function(_ReviewLearner) _then) = __$ReviewLearnerCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String email, String city, num progress,@NullableUtcDateTimeConverter() DateTime? enrolledAt
});




}
/// @nodoc
class __$ReviewLearnerCopyWithImpl<$Res>
    implements _$ReviewLearnerCopyWith<$Res> {
  __$ReviewLearnerCopyWithImpl(this._self, this._then);

  final _ReviewLearner _self;
  final $Res Function(_ReviewLearner) _then;

/// Create a copy of ReviewLearner
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,Object? city = null,Object? progress = null,Object? enrolledAt = freezed,}) {
  return _then(_ReviewLearner(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as num,enrolledAt: freezed == enrolledAt ? _self.enrolledAt : enrolledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$SubmissionRow {

 String get id; Submission? get submission; ReviewLearner get student; String get assignmentId; String get assignmentTitle; String get courseTitle; num get maxScore;/// Past the academy's review window, as the route worked it out.
 bool get overdue;
/// Create a copy of SubmissionRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubmissionRowCopyWith<SubmissionRow> get copyWith => _$SubmissionRowCopyWithImpl<SubmissionRow>(this as SubmissionRow, _$identity);

  /// Serializes this SubmissionRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubmissionRow&&(identical(other.id, id) || other.id == id)&&(identical(other.submission, submission) || other.submission == submission)&&(identical(other.student, student) || other.student == student)&&(identical(other.assignmentId, assignmentId) || other.assignmentId == assignmentId)&&(identical(other.assignmentTitle, assignmentTitle) || other.assignmentTitle == assignmentTitle)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.maxScore, maxScore) || other.maxScore == maxScore)&&(identical(other.overdue, overdue) || other.overdue == overdue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,submission,student,assignmentId,assignmentTitle,courseTitle,maxScore,overdue);

@override
String toString() {
  return 'SubmissionRow(id: $id, submission: $submission, student: $student, assignmentId: $assignmentId, assignmentTitle: $assignmentTitle, courseTitle: $courseTitle, maxScore: $maxScore, overdue: $overdue)';
}


}

/// @nodoc
abstract mixin class $SubmissionRowCopyWith<$Res>  {
  factory $SubmissionRowCopyWith(SubmissionRow value, $Res Function(SubmissionRow) _then) = _$SubmissionRowCopyWithImpl;
@useResult
$Res call({
 String id, Submission? submission, ReviewLearner student, String assignmentId, String assignmentTitle, String courseTitle, num maxScore, bool overdue
});


$SubmissionCopyWith<$Res>? get submission;$ReviewLearnerCopyWith<$Res> get student;

}
/// @nodoc
class _$SubmissionRowCopyWithImpl<$Res>
    implements $SubmissionRowCopyWith<$Res> {
  _$SubmissionRowCopyWithImpl(this._self, this._then);

  final SubmissionRow _self;
  final $Res Function(SubmissionRow) _then;

/// Create a copy of SubmissionRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? submission = freezed,Object? student = null,Object? assignmentId = null,Object? assignmentTitle = null,Object? courseTitle = null,Object? maxScore = null,Object? overdue = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,submission: freezed == submission ? _self.submission : submission // ignore: cast_nullable_to_non_nullable
as Submission?,student: null == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as ReviewLearner,assignmentId: null == assignmentId ? _self.assignmentId : assignmentId // ignore: cast_nullable_to_non_nullable
as String,assignmentTitle: null == assignmentTitle ? _self.assignmentTitle : assignmentTitle // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,maxScore: null == maxScore ? _self.maxScore : maxScore // ignore: cast_nullable_to_non_nullable
as num,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of SubmissionRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubmissionCopyWith<$Res>? get submission {
    if (_self.submission == null) {
    return null;
  }

  return $SubmissionCopyWith<$Res>(_self.submission!, (value) {
    return _then(_self.copyWith(submission: value));
  });
}/// Create a copy of SubmissionRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewLearnerCopyWith<$Res> get student {
  
  return $ReviewLearnerCopyWith<$Res>(_self.student, (value) {
    return _then(_self.copyWith(student: value));
  });
}
}


/// Adds pattern-matching-related methods to [SubmissionRow].
extension SubmissionRowPatterns on SubmissionRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubmissionRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubmissionRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubmissionRow value)  $default,){
final _that = this;
switch (_that) {
case _SubmissionRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubmissionRow value)?  $default,){
final _that = this;
switch (_that) {
case _SubmissionRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Submission? submission,  ReviewLearner student,  String assignmentId,  String assignmentTitle,  String courseTitle,  num maxScore,  bool overdue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubmissionRow() when $default != null:
return $default(_that.id,_that.submission,_that.student,_that.assignmentId,_that.assignmentTitle,_that.courseTitle,_that.maxScore,_that.overdue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Submission? submission,  ReviewLearner student,  String assignmentId,  String assignmentTitle,  String courseTitle,  num maxScore,  bool overdue)  $default,) {final _that = this;
switch (_that) {
case _SubmissionRow():
return $default(_that.id,_that.submission,_that.student,_that.assignmentId,_that.assignmentTitle,_that.courseTitle,_that.maxScore,_that.overdue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Submission? submission,  ReviewLearner student,  String assignmentId,  String assignmentTitle,  String courseTitle,  num maxScore,  bool overdue)?  $default,) {final _that = this;
switch (_that) {
case _SubmissionRow() when $default != null:
return $default(_that.id,_that.submission,_that.student,_that.assignmentId,_that.assignmentTitle,_that.courseTitle,_that.maxScore,_that.overdue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubmissionRow extends SubmissionRow {
  const _SubmissionRow({this.id = '', this.submission, this.student = const ReviewLearner(), this.assignmentId = '', this.assignmentTitle = '', this.courseTitle = '', this.maxScore = 0, this.overdue = false}): super._();
  factory _SubmissionRow.fromJson(Map<String, dynamic> json) => _$SubmissionRowFromJson(json);

@override@JsonKey() final  String id;
@override final  Submission? submission;
@override@JsonKey() final  ReviewLearner student;
@override@JsonKey() final  String assignmentId;
@override@JsonKey() final  String assignmentTitle;
@override@JsonKey() final  String courseTitle;
@override@JsonKey() final  num maxScore;
/// Past the academy's review window, as the route worked it out.
@override@JsonKey() final  bool overdue;

/// Create a copy of SubmissionRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubmissionRowCopyWith<_SubmissionRow> get copyWith => __$SubmissionRowCopyWithImpl<_SubmissionRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubmissionRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubmissionRow&&(identical(other.id, id) || other.id == id)&&(identical(other.submission, submission) || other.submission == submission)&&(identical(other.student, student) || other.student == student)&&(identical(other.assignmentId, assignmentId) || other.assignmentId == assignmentId)&&(identical(other.assignmentTitle, assignmentTitle) || other.assignmentTitle == assignmentTitle)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.maxScore, maxScore) || other.maxScore == maxScore)&&(identical(other.overdue, overdue) || other.overdue == overdue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,submission,student,assignmentId,assignmentTitle,courseTitle,maxScore,overdue);

@override
String toString() {
  return 'SubmissionRow(id: $id, submission: $submission, student: $student, assignmentId: $assignmentId, assignmentTitle: $assignmentTitle, courseTitle: $courseTitle, maxScore: $maxScore, overdue: $overdue)';
}


}

/// @nodoc
abstract mixin class _$SubmissionRowCopyWith<$Res> implements $SubmissionRowCopyWith<$Res> {
  factory _$SubmissionRowCopyWith(_SubmissionRow value, $Res Function(_SubmissionRow) _then) = __$SubmissionRowCopyWithImpl;
@override @useResult
$Res call({
 String id, Submission? submission, ReviewLearner student, String assignmentId, String assignmentTitle, String courseTitle, num maxScore, bool overdue
});


@override $SubmissionCopyWith<$Res>? get submission;@override $ReviewLearnerCopyWith<$Res> get student;

}
/// @nodoc
class __$SubmissionRowCopyWithImpl<$Res>
    implements _$SubmissionRowCopyWith<$Res> {
  __$SubmissionRowCopyWithImpl(this._self, this._then);

  final _SubmissionRow _self;
  final $Res Function(_SubmissionRow) _then;

/// Create a copy of SubmissionRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? submission = freezed,Object? student = null,Object? assignmentId = null,Object? assignmentTitle = null,Object? courseTitle = null,Object? maxScore = null,Object? overdue = null,}) {
  return _then(_SubmissionRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,submission: freezed == submission ? _self.submission : submission // ignore: cast_nullable_to_non_nullable
as Submission?,student: null == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as ReviewLearner,assignmentId: null == assignmentId ? _self.assignmentId : assignmentId // ignore: cast_nullable_to_non_nullable
as String,assignmentTitle: null == assignmentTitle ? _self.assignmentTitle : assignmentTitle // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,maxScore: null == maxScore ? _self.maxScore : maxScore // ignore: cast_nullable_to_non_nullable
as num,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of SubmissionRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubmissionCopyWith<$Res>? get submission {
    if (_self.submission == null) {
    return null;
  }

  return $SubmissionCopyWith<$Res>(_self.submission!, (value) {
    return _then(_self.copyWith(submission: value));
  });
}/// Create a copy of SubmissionRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewLearnerCopyWith<$Res> get student {
  
  return $ReviewLearnerCopyWith<$Res>(_self.student, (value) {
    return _then(_self.copyWith(student: value));
  });
}
}


/// @nodoc
mixin _$SubmissionPage {

 List<SubmissionRow> get rows; int get total; Map<String, int> get counts;
/// Create a copy of SubmissionPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubmissionPageCopyWith<SubmissionPage> get copyWith => _$SubmissionPageCopyWithImpl<SubmissionPage>(this as SubmissionPage, _$identity);

  /// Serializes this SubmissionPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubmissionPage&&const DeepCollectionEquality().equals(other.rows, rows)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.counts, counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rows),total,const DeepCollectionEquality().hash(counts));

@override
String toString() {
  return 'SubmissionPage(rows: $rows, total: $total, counts: $counts)';
}


}

/// @nodoc
abstract mixin class $SubmissionPageCopyWith<$Res>  {
  factory $SubmissionPageCopyWith(SubmissionPage value, $Res Function(SubmissionPage) _then) = _$SubmissionPageCopyWithImpl;
@useResult
$Res call({
 List<SubmissionRow> rows, int total, Map<String, int> counts
});




}
/// @nodoc
class _$SubmissionPageCopyWithImpl<$Res>
    implements $SubmissionPageCopyWith<$Res> {
  _$SubmissionPageCopyWithImpl(this._self, this._then);

  final SubmissionPage _self;
  final $Res Function(SubmissionPage) _then;

/// Create a copy of SubmissionPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? total = null,Object? counts = null,}) {
  return _then(_self.copyWith(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<SubmissionRow>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubmissionPage].
extension SubmissionPagePatterns on SubmissionPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubmissionPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubmissionPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubmissionPage value)  $default,){
final _that = this;
switch (_that) {
case _SubmissionPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubmissionPage value)?  $default,){
final _that = this;
switch (_that) {
case _SubmissionPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SubmissionRow> rows,  int total,  Map<String, int> counts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubmissionPage() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SubmissionRow> rows,  int total,  Map<String, int> counts)  $default,) {final _that = this;
switch (_that) {
case _SubmissionPage():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SubmissionRow> rows,  int total,  Map<String, int> counts)?  $default,) {final _that = this;
switch (_that) {
case _SubmissionPage() when $default != null:
return $default(_that.rows,_that.total,_that.counts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubmissionPage extends SubmissionPage {
  const _SubmissionPage({final  List<SubmissionRow> rows = const <SubmissionRow>[], this.total = 0, final  Map<String, int> counts = const <String, int>{}}): _rows = rows,_counts = counts,super._();
  factory _SubmissionPage.fromJson(Map<String, dynamic> json) => _$SubmissionPageFromJson(json);

 final  List<SubmissionRow> _rows;
@override@JsonKey() List<SubmissionRow> get rows {
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


/// Create a copy of SubmissionPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubmissionPageCopyWith<_SubmissionPage> get copyWith => __$SubmissionPageCopyWithImpl<_SubmissionPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubmissionPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubmissionPage&&const DeepCollectionEquality().equals(other._rows, _rows)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._counts, _counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows),total,const DeepCollectionEquality().hash(_counts));

@override
String toString() {
  return 'SubmissionPage(rows: $rows, total: $total, counts: $counts)';
}


}

/// @nodoc
abstract mixin class _$SubmissionPageCopyWith<$Res> implements $SubmissionPageCopyWith<$Res> {
  factory _$SubmissionPageCopyWith(_SubmissionPage value, $Res Function(_SubmissionPage) _then) = __$SubmissionPageCopyWithImpl;
@override @useResult
$Res call({
 List<SubmissionRow> rows, int total, Map<String, int> counts
});




}
/// @nodoc
class __$SubmissionPageCopyWithImpl<$Res>
    implements _$SubmissionPageCopyWith<$Res> {
  __$SubmissionPageCopyWithImpl(this._self, this._then);

  final _SubmissionPage _self;
  final $Res Function(_SubmissionPage) _then;

/// Create a copy of SubmissionPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,Object? total = null,Object? counts = null,}) {
  return _then(_SubmissionPage(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<SubmissionRow>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self._counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}


/// @nodoc
mixin _$ReviewQueuePosition {

 int get position; int get total; String? get previousId; String? get nextId;
/// Create a copy of ReviewQueuePosition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewQueuePositionCopyWith<ReviewQueuePosition> get copyWith => _$ReviewQueuePositionCopyWithImpl<ReviewQueuePosition>(this as ReviewQueuePosition, _$identity);

  /// Serializes this ReviewQueuePosition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewQueuePosition&&(identical(other.position, position) || other.position == position)&&(identical(other.total, total) || other.total == total)&&(identical(other.previousId, previousId) || other.previousId == previousId)&&(identical(other.nextId, nextId) || other.nextId == nextId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,position,total,previousId,nextId);

@override
String toString() {
  return 'ReviewQueuePosition(position: $position, total: $total, previousId: $previousId, nextId: $nextId)';
}


}

/// @nodoc
abstract mixin class $ReviewQueuePositionCopyWith<$Res>  {
  factory $ReviewQueuePositionCopyWith(ReviewQueuePosition value, $Res Function(ReviewQueuePosition) _then) = _$ReviewQueuePositionCopyWithImpl;
@useResult
$Res call({
 int position, int total, String? previousId, String? nextId
});




}
/// @nodoc
class _$ReviewQueuePositionCopyWithImpl<$Res>
    implements $ReviewQueuePositionCopyWith<$Res> {
  _$ReviewQueuePositionCopyWithImpl(this._self, this._then);

  final ReviewQueuePosition _self;
  final $Res Function(ReviewQueuePosition) _then;

/// Create a copy of ReviewQueuePosition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? position = null,Object? total = null,Object? previousId = freezed,Object? nextId = freezed,}) {
  return _then(_self.copyWith(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,previousId: freezed == previousId ? _self.previousId : previousId // ignore: cast_nullable_to_non_nullable
as String?,nextId: freezed == nextId ? _self.nextId : nextId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReviewQueuePosition].
extension ReviewQueuePositionPatterns on ReviewQueuePosition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewQueuePosition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewQueuePosition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewQueuePosition value)  $default,){
final _that = this;
switch (_that) {
case _ReviewQueuePosition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewQueuePosition value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewQueuePosition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int position,  int total,  String? previousId,  String? nextId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewQueuePosition() when $default != null:
return $default(_that.position,_that.total,_that.previousId,_that.nextId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int position,  int total,  String? previousId,  String? nextId)  $default,) {final _that = this;
switch (_that) {
case _ReviewQueuePosition():
return $default(_that.position,_that.total,_that.previousId,_that.nextId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int position,  int total,  String? previousId,  String? nextId)?  $default,) {final _that = this;
switch (_that) {
case _ReviewQueuePosition() when $default != null:
return $default(_that.position,_that.total,_that.previousId,_that.nextId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReviewQueuePosition extends ReviewQueuePosition {
  const _ReviewQueuePosition({this.position = 0, this.total = 0, this.previousId, this.nextId}): super._();
  factory _ReviewQueuePosition.fromJson(Map<String, dynamic> json) => _$ReviewQueuePositionFromJson(json);

@override@JsonKey() final  int position;
@override@JsonKey() final  int total;
@override final  String? previousId;
@override final  String? nextId;

/// Create a copy of ReviewQueuePosition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewQueuePositionCopyWith<_ReviewQueuePosition> get copyWith => __$ReviewQueuePositionCopyWithImpl<_ReviewQueuePosition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewQueuePositionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewQueuePosition&&(identical(other.position, position) || other.position == position)&&(identical(other.total, total) || other.total == total)&&(identical(other.previousId, previousId) || other.previousId == previousId)&&(identical(other.nextId, nextId) || other.nextId == nextId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,position,total,previousId,nextId);

@override
String toString() {
  return 'ReviewQueuePosition(position: $position, total: $total, previousId: $previousId, nextId: $nextId)';
}


}

/// @nodoc
abstract mixin class _$ReviewQueuePositionCopyWith<$Res> implements $ReviewQueuePositionCopyWith<$Res> {
  factory _$ReviewQueuePositionCopyWith(_ReviewQueuePosition value, $Res Function(_ReviewQueuePosition) _then) = __$ReviewQueuePositionCopyWithImpl;
@override @useResult
$Res call({
 int position, int total, String? previousId, String? nextId
});




}
/// @nodoc
class __$ReviewQueuePositionCopyWithImpl<$Res>
    implements _$ReviewQueuePositionCopyWith<$Res> {
  __$ReviewQueuePositionCopyWithImpl(this._self, this._then);

  final _ReviewQueuePosition _self;
  final $Res Function(_ReviewQueuePosition) _then;

/// Create a copy of ReviewQueuePosition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? position = null,Object? total = null,Object? previousId = freezed,Object? nextId = freezed,}) {
  return _then(_ReviewQueuePosition(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,previousId: freezed == previousId ? _self.previousId : previousId // ignore: cast_nullable_to_non_nullable
as String?,nextId: freezed == nextId ? _self.nextId : nextId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SubmissionDetail {

 Submission get submission; CourseAssignment get assignment; String get courseTitle; String? get chapterTitle; ReviewLearner get student; ReviewQueuePosition get queue;
/// Create a copy of SubmissionDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubmissionDetailCopyWith<SubmissionDetail> get copyWith => _$SubmissionDetailCopyWithImpl<SubmissionDetail>(this as SubmissionDetail, _$identity);

  /// Serializes this SubmissionDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubmissionDetail&&(identical(other.submission, submission) || other.submission == submission)&&(identical(other.assignment, assignment) || other.assignment == assignment)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.student, student) || other.student == student)&&(identical(other.queue, queue) || other.queue == queue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,submission,assignment,courseTitle,chapterTitle,student,queue);

@override
String toString() {
  return 'SubmissionDetail(submission: $submission, assignment: $assignment, courseTitle: $courseTitle, chapterTitle: $chapterTitle, student: $student, queue: $queue)';
}


}

/// @nodoc
abstract mixin class $SubmissionDetailCopyWith<$Res>  {
  factory $SubmissionDetailCopyWith(SubmissionDetail value, $Res Function(SubmissionDetail) _then) = _$SubmissionDetailCopyWithImpl;
@useResult
$Res call({
 Submission submission, CourseAssignment assignment, String courseTitle, String? chapterTitle, ReviewLearner student, ReviewQueuePosition queue
});


$SubmissionCopyWith<$Res> get submission;$CourseAssignmentCopyWith<$Res> get assignment;$ReviewLearnerCopyWith<$Res> get student;$ReviewQueuePositionCopyWith<$Res> get queue;

}
/// @nodoc
class _$SubmissionDetailCopyWithImpl<$Res>
    implements $SubmissionDetailCopyWith<$Res> {
  _$SubmissionDetailCopyWithImpl(this._self, this._then);

  final SubmissionDetail _self;
  final $Res Function(SubmissionDetail) _then;

/// Create a copy of SubmissionDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? submission = null,Object? assignment = null,Object? courseTitle = null,Object? chapterTitle = freezed,Object? student = null,Object? queue = null,}) {
  return _then(_self.copyWith(
submission: null == submission ? _self.submission : submission // ignore: cast_nullable_to_non_nullable
as Submission,assignment: null == assignment ? _self.assignment : assignment // ignore: cast_nullable_to_non_nullable
as CourseAssignment,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,chapterTitle: freezed == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String?,student: null == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as ReviewLearner,queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as ReviewQueuePosition,
  ));
}
/// Create a copy of SubmissionDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubmissionCopyWith<$Res> get submission {
  
  return $SubmissionCopyWith<$Res>(_self.submission, (value) {
    return _then(_self.copyWith(submission: value));
  });
}/// Create a copy of SubmissionDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseAssignmentCopyWith<$Res> get assignment {
  
  return $CourseAssignmentCopyWith<$Res>(_self.assignment, (value) {
    return _then(_self.copyWith(assignment: value));
  });
}/// Create a copy of SubmissionDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewLearnerCopyWith<$Res> get student {
  
  return $ReviewLearnerCopyWith<$Res>(_self.student, (value) {
    return _then(_self.copyWith(student: value));
  });
}/// Create a copy of SubmissionDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewQueuePositionCopyWith<$Res> get queue {
  
  return $ReviewQueuePositionCopyWith<$Res>(_self.queue, (value) {
    return _then(_self.copyWith(queue: value));
  });
}
}


/// Adds pattern-matching-related methods to [SubmissionDetail].
extension SubmissionDetailPatterns on SubmissionDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubmissionDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubmissionDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubmissionDetail value)  $default,){
final _that = this;
switch (_that) {
case _SubmissionDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubmissionDetail value)?  $default,){
final _that = this;
switch (_that) {
case _SubmissionDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Submission submission,  CourseAssignment assignment,  String courseTitle,  String? chapterTitle,  ReviewLearner student,  ReviewQueuePosition queue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubmissionDetail() when $default != null:
return $default(_that.submission,_that.assignment,_that.courseTitle,_that.chapterTitle,_that.student,_that.queue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Submission submission,  CourseAssignment assignment,  String courseTitle,  String? chapterTitle,  ReviewLearner student,  ReviewQueuePosition queue)  $default,) {final _that = this;
switch (_that) {
case _SubmissionDetail():
return $default(_that.submission,_that.assignment,_that.courseTitle,_that.chapterTitle,_that.student,_that.queue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Submission submission,  CourseAssignment assignment,  String courseTitle,  String? chapterTitle,  ReviewLearner student,  ReviewQueuePosition queue)?  $default,) {final _that = this;
switch (_that) {
case _SubmissionDetail() when $default != null:
return $default(_that.submission,_that.assignment,_that.courseTitle,_that.chapterTitle,_that.student,_that.queue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubmissionDetail implements SubmissionDetail {
  const _SubmissionDetail({required this.submission, required this.assignment, this.courseTitle = '', this.chapterTitle, this.student = const ReviewLearner(), this.queue = const ReviewQueuePosition()});
  factory _SubmissionDetail.fromJson(Map<String, dynamic> json) => _$SubmissionDetailFromJson(json);

@override final  Submission submission;
@override final  CourseAssignment assignment;
@override@JsonKey() final  String courseTitle;
@override final  String? chapterTitle;
@override@JsonKey() final  ReviewLearner student;
@override@JsonKey() final  ReviewQueuePosition queue;

/// Create a copy of SubmissionDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubmissionDetailCopyWith<_SubmissionDetail> get copyWith => __$SubmissionDetailCopyWithImpl<_SubmissionDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubmissionDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubmissionDetail&&(identical(other.submission, submission) || other.submission == submission)&&(identical(other.assignment, assignment) || other.assignment == assignment)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.student, student) || other.student == student)&&(identical(other.queue, queue) || other.queue == queue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,submission,assignment,courseTitle,chapterTitle,student,queue);

@override
String toString() {
  return 'SubmissionDetail(submission: $submission, assignment: $assignment, courseTitle: $courseTitle, chapterTitle: $chapterTitle, student: $student, queue: $queue)';
}


}

/// @nodoc
abstract mixin class _$SubmissionDetailCopyWith<$Res> implements $SubmissionDetailCopyWith<$Res> {
  factory _$SubmissionDetailCopyWith(_SubmissionDetail value, $Res Function(_SubmissionDetail) _then) = __$SubmissionDetailCopyWithImpl;
@override @useResult
$Res call({
 Submission submission, CourseAssignment assignment, String courseTitle, String? chapterTitle, ReviewLearner student, ReviewQueuePosition queue
});


@override $SubmissionCopyWith<$Res> get submission;@override $CourseAssignmentCopyWith<$Res> get assignment;@override $ReviewLearnerCopyWith<$Res> get student;@override $ReviewQueuePositionCopyWith<$Res> get queue;

}
/// @nodoc
class __$SubmissionDetailCopyWithImpl<$Res>
    implements _$SubmissionDetailCopyWith<$Res> {
  __$SubmissionDetailCopyWithImpl(this._self, this._then);

  final _SubmissionDetail _self;
  final $Res Function(_SubmissionDetail) _then;

/// Create a copy of SubmissionDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? submission = null,Object? assignment = null,Object? courseTitle = null,Object? chapterTitle = freezed,Object? student = null,Object? queue = null,}) {
  return _then(_SubmissionDetail(
submission: null == submission ? _self.submission : submission // ignore: cast_nullable_to_non_nullable
as Submission,assignment: null == assignment ? _self.assignment : assignment // ignore: cast_nullable_to_non_nullable
as CourseAssignment,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,chapterTitle: freezed == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String?,student: null == student ? _self.student : student // ignore: cast_nullable_to_non_nullable
as ReviewLearner,queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as ReviewQueuePosition,
  ));
}

/// Create a copy of SubmissionDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubmissionCopyWith<$Res> get submission {
  
  return $SubmissionCopyWith<$Res>(_self.submission, (value) {
    return _then(_self.copyWith(submission: value));
  });
}/// Create a copy of SubmissionDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseAssignmentCopyWith<$Res> get assignment {
  
  return $CourseAssignmentCopyWith<$Res>(_self.assignment, (value) {
    return _then(_self.copyWith(assignment: value));
  });
}/// Create a copy of SubmissionDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewLearnerCopyWith<$Res> get student {
  
  return $ReviewLearnerCopyWith<$Res>(_self.student, (value) {
    return _then(_self.copyWith(student: value));
  });
}/// Create a copy of SubmissionDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewQueuePositionCopyWith<$Res> get queue {
  
  return $ReviewQueuePositionCopyWith<$Res>(_self.queue, (value) {
    return _then(_self.copyWith(queue: value));
  });
}
}


/// @nodoc
mixin _$StaffAssignmentRow {

 CourseAssignment get assignment; String get courseTitle; String? get chapterTitle; int get submitted; int get toReview; int get overdue; int get graded;/// Enrolled learners with nothing handed in; only meaningful once it is published.
 int get missing;/// The mean score as a percentage of the maximum, or null when nothing is scored yet.
 num? get avgScore;
/// Create a copy of StaffAssignmentRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffAssignmentRowCopyWith<StaffAssignmentRow> get copyWith => _$StaffAssignmentRowCopyWithImpl<StaffAssignmentRow>(this as StaffAssignmentRow, _$identity);

  /// Serializes this StaffAssignmentRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffAssignmentRow&&(identical(other.assignment, assignment) || other.assignment == assignment)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.submitted, submitted) || other.submitted == submitted)&&(identical(other.toReview, toReview) || other.toReview == toReview)&&(identical(other.overdue, overdue) || other.overdue == overdue)&&(identical(other.graded, graded) || other.graded == graded)&&(identical(other.missing, missing) || other.missing == missing)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assignment,courseTitle,chapterTitle,submitted,toReview,overdue,graded,missing,avgScore);

@override
String toString() {
  return 'StaffAssignmentRow(assignment: $assignment, courseTitle: $courseTitle, chapterTitle: $chapterTitle, submitted: $submitted, toReview: $toReview, overdue: $overdue, graded: $graded, missing: $missing, avgScore: $avgScore)';
}


}

/// @nodoc
abstract mixin class $StaffAssignmentRowCopyWith<$Res>  {
  factory $StaffAssignmentRowCopyWith(StaffAssignmentRow value, $Res Function(StaffAssignmentRow) _then) = _$StaffAssignmentRowCopyWithImpl;
@useResult
$Res call({
 CourseAssignment assignment, String courseTitle, String? chapterTitle, int submitted, int toReview, int overdue, int graded, int missing, num? avgScore
});


$CourseAssignmentCopyWith<$Res> get assignment;

}
/// @nodoc
class _$StaffAssignmentRowCopyWithImpl<$Res>
    implements $StaffAssignmentRowCopyWith<$Res> {
  _$StaffAssignmentRowCopyWithImpl(this._self, this._then);

  final StaffAssignmentRow _self;
  final $Res Function(StaffAssignmentRow) _then;

/// Create a copy of StaffAssignmentRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? assignment = null,Object? courseTitle = null,Object? chapterTitle = freezed,Object? submitted = null,Object? toReview = null,Object? overdue = null,Object? graded = null,Object? missing = null,Object? avgScore = freezed,}) {
  return _then(_self.copyWith(
assignment: null == assignment ? _self.assignment : assignment // ignore: cast_nullable_to_non_nullable
as CourseAssignment,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,chapterTitle: freezed == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String?,submitted: null == submitted ? _self.submitted : submitted // ignore: cast_nullable_to_non_nullable
as int,toReview: null == toReview ? _self.toReview : toReview // ignore: cast_nullable_to_non_nullable
as int,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as int,graded: null == graded ? _self.graded : graded // ignore: cast_nullable_to_non_nullable
as int,missing: null == missing ? _self.missing : missing // ignore: cast_nullable_to_non_nullable
as int,avgScore: freezed == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}
/// Create a copy of StaffAssignmentRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseAssignmentCopyWith<$Res> get assignment {
  
  return $CourseAssignmentCopyWith<$Res>(_self.assignment, (value) {
    return _then(_self.copyWith(assignment: value));
  });
}
}


/// Adds pattern-matching-related methods to [StaffAssignmentRow].
extension StaffAssignmentRowPatterns on StaffAssignmentRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffAssignmentRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffAssignmentRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffAssignmentRow value)  $default,){
final _that = this;
switch (_that) {
case _StaffAssignmentRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffAssignmentRow value)?  $default,){
final _that = this;
switch (_that) {
case _StaffAssignmentRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CourseAssignment assignment,  String courseTitle,  String? chapterTitle,  int submitted,  int toReview,  int overdue,  int graded,  int missing,  num? avgScore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffAssignmentRow() when $default != null:
return $default(_that.assignment,_that.courseTitle,_that.chapterTitle,_that.submitted,_that.toReview,_that.overdue,_that.graded,_that.missing,_that.avgScore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CourseAssignment assignment,  String courseTitle,  String? chapterTitle,  int submitted,  int toReview,  int overdue,  int graded,  int missing,  num? avgScore)  $default,) {final _that = this;
switch (_that) {
case _StaffAssignmentRow():
return $default(_that.assignment,_that.courseTitle,_that.chapterTitle,_that.submitted,_that.toReview,_that.overdue,_that.graded,_that.missing,_that.avgScore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CourseAssignment assignment,  String courseTitle,  String? chapterTitle,  int submitted,  int toReview,  int overdue,  int graded,  int missing,  num? avgScore)?  $default,) {final _that = this;
switch (_that) {
case _StaffAssignmentRow() when $default != null:
return $default(_that.assignment,_that.courseTitle,_that.chapterTitle,_that.submitted,_that.toReview,_that.overdue,_that.graded,_that.missing,_that.avgScore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffAssignmentRow implements StaffAssignmentRow {
  const _StaffAssignmentRow({required this.assignment, this.courseTitle = '', this.chapterTitle, this.submitted = 0, this.toReview = 0, this.overdue = 0, this.graded = 0, this.missing = 0, this.avgScore});
  factory _StaffAssignmentRow.fromJson(Map<String, dynamic> json) => _$StaffAssignmentRowFromJson(json);

@override final  CourseAssignment assignment;
@override@JsonKey() final  String courseTitle;
@override final  String? chapterTitle;
@override@JsonKey() final  int submitted;
@override@JsonKey() final  int toReview;
@override@JsonKey() final  int overdue;
@override@JsonKey() final  int graded;
/// Enrolled learners with nothing handed in; only meaningful once it is published.
@override@JsonKey() final  int missing;
/// The mean score as a percentage of the maximum, or null when nothing is scored yet.
@override final  num? avgScore;

/// Create a copy of StaffAssignmentRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffAssignmentRowCopyWith<_StaffAssignmentRow> get copyWith => __$StaffAssignmentRowCopyWithImpl<_StaffAssignmentRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffAssignmentRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffAssignmentRow&&(identical(other.assignment, assignment) || other.assignment == assignment)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.submitted, submitted) || other.submitted == submitted)&&(identical(other.toReview, toReview) || other.toReview == toReview)&&(identical(other.overdue, overdue) || other.overdue == overdue)&&(identical(other.graded, graded) || other.graded == graded)&&(identical(other.missing, missing) || other.missing == missing)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assignment,courseTitle,chapterTitle,submitted,toReview,overdue,graded,missing,avgScore);

@override
String toString() {
  return 'StaffAssignmentRow(assignment: $assignment, courseTitle: $courseTitle, chapterTitle: $chapterTitle, submitted: $submitted, toReview: $toReview, overdue: $overdue, graded: $graded, missing: $missing, avgScore: $avgScore)';
}


}

/// @nodoc
abstract mixin class _$StaffAssignmentRowCopyWith<$Res> implements $StaffAssignmentRowCopyWith<$Res> {
  factory _$StaffAssignmentRowCopyWith(_StaffAssignmentRow value, $Res Function(_StaffAssignmentRow) _then) = __$StaffAssignmentRowCopyWithImpl;
@override @useResult
$Res call({
 CourseAssignment assignment, String courseTitle, String? chapterTitle, int submitted, int toReview, int overdue, int graded, int missing, num? avgScore
});


@override $CourseAssignmentCopyWith<$Res> get assignment;

}
/// @nodoc
class __$StaffAssignmentRowCopyWithImpl<$Res>
    implements _$StaffAssignmentRowCopyWith<$Res> {
  __$StaffAssignmentRowCopyWithImpl(this._self, this._then);

  final _StaffAssignmentRow _self;
  final $Res Function(_StaffAssignmentRow) _then;

/// Create a copy of StaffAssignmentRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? assignment = null,Object? courseTitle = null,Object? chapterTitle = freezed,Object? submitted = null,Object? toReview = null,Object? overdue = null,Object? graded = null,Object? missing = null,Object? avgScore = freezed,}) {
  return _then(_StaffAssignmentRow(
assignment: null == assignment ? _self.assignment : assignment // ignore: cast_nullable_to_non_nullable
as CourseAssignment,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,chapterTitle: freezed == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String?,submitted: null == submitted ? _self.submitted : submitted // ignore: cast_nullable_to_non_nullable
as int,toReview: null == toReview ? _self.toReview : toReview // ignore: cast_nullable_to_non_nullable
as int,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as int,graded: null == graded ? _self.graded : graded // ignore: cast_nullable_to_non_nullable
as int,missing: null == missing ? _self.missing : missing // ignore: cast_nullable_to_non_nullable
as int,avgScore: freezed == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}

/// Create a copy of StaffAssignmentRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseAssignmentCopyWith<$Res> get assignment {
  
  return $CourseAssignmentCopyWith<$Res>(_self.assignment, (value) {
    return _then(_self.copyWith(assignment: value));
  });
}
}


/// @nodoc
mixin _$StaffAssignmentPage {

 List<StaffAssignmentRow> get rows; Map<String, int> get counts;
/// Create a copy of StaffAssignmentPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffAssignmentPageCopyWith<StaffAssignmentPage> get copyWith => _$StaffAssignmentPageCopyWithImpl<StaffAssignmentPage>(this as StaffAssignmentPage, _$identity);

  /// Serializes this StaffAssignmentPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffAssignmentPage&&const DeepCollectionEquality().equals(other.rows, rows)&&const DeepCollectionEquality().equals(other.counts, counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rows),const DeepCollectionEquality().hash(counts));

@override
String toString() {
  return 'StaffAssignmentPage(rows: $rows, counts: $counts)';
}


}

/// @nodoc
abstract mixin class $StaffAssignmentPageCopyWith<$Res>  {
  factory $StaffAssignmentPageCopyWith(StaffAssignmentPage value, $Res Function(StaffAssignmentPage) _then) = _$StaffAssignmentPageCopyWithImpl;
@useResult
$Res call({
 List<StaffAssignmentRow> rows, Map<String, int> counts
});




}
/// @nodoc
class _$StaffAssignmentPageCopyWithImpl<$Res>
    implements $StaffAssignmentPageCopyWith<$Res> {
  _$StaffAssignmentPageCopyWithImpl(this._self, this._then);

  final StaffAssignmentPage _self;
  final $Res Function(StaffAssignmentPage) _then;

/// Create a copy of StaffAssignmentPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? counts = null,}) {
  return _then(_self.copyWith(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<StaffAssignmentRow>,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffAssignmentPage].
extension StaffAssignmentPagePatterns on StaffAssignmentPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffAssignmentPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffAssignmentPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffAssignmentPage value)  $default,){
final _that = this;
switch (_that) {
case _StaffAssignmentPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffAssignmentPage value)?  $default,){
final _that = this;
switch (_that) {
case _StaffAssignmentPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<StaffAssignmentRow> rows,  Map<String, int> counts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffAssignmentPage() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<StaffAssignmentRow> rows,  Map<String, int> counts)  $default,) {final _that = this;
switch (_that) {
case _StaffAssignmentPage():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<StaffAssignmentRow> rows,  Map<String, int> counts)?  $default,) {final _that = this;
switch (_that) {
case _StaffAssignmentPage() when $default != null:
return $default(_that.rows,_that.counts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffAssignmentPage implements StaffAssignmentPage {
  const _StaffAssignmentPage({final  List<StaffAssignmentRow> rows = const <StaffAssignmentRow>[], final  Map<String, int> counts = const <String, int>{}}): _rows = rows,_counts = counts;
  factory _StaffAssignmentPage.fromJson(Map<String, dynamic> json) => _$StaffAssignmentPageFromJson(json);

 final  List<StaffAssignmentRow> _rows;
@override@JsonKey() List<StaffAssignmentRow> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

 final  Map<String, int> _counts;
@override@JsonKey() Map<String, int> get counts {
  if (_counts is EqualUnmodifiableMapView) return _counts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_counts);
}


/// Create a copy of StaffAssignmentPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffAssignmentPageCopyWith<_StaffAssignmentPage> get copyWith => __$StaffAssignmentPageCopyWithImpl<_StaffAssignmentPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffAssignmentPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffAssignmentPage&&const DeepCollectionEquality().equals(other._rows, _rows)&&const DeepCollectionEquality().equals(other._counts, _counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows),const DeepCollectionEquality().hash(_counts));

@override
String toString() {
  return 'StaffAssignmentPage(rows: $rows, counts: $counts)';
}


}

/// @nodoc
abstract mixin class _$StaffAssignmentPageCopyWith<$Res> implements $StaffAssignmentPageCopyWith<$Res> {
  factory _$StaffAssignmentPageCopyWith(_StaffAssignmentPage value, $Res Function(_StaffAssignmentPage) _then) = __$StaffAssignmentPageCopyWithImpl;
@override @useResult
$Res call({
 List<StaffAssignmentRow> rows, Map<String, int> counts
});




}
/// @nodoc
class __$StaffAssignmentPageCopyWithImpl<$Res>
    implements _$StaffAssignmentPageCopyWith<$Res> {
  __$StaffAssignmentPageCopyWithImpl(this._self, this._then);

  final _StaffAssignmentPage _self;
  final $Res Function(_StaffAssignmentPage) _then;

/// Create a copy of StaffAssignmentPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,Object? counts = null,}) {
  return _then(_StaffAssignmentPage(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<StaffAssignmentRow>,counts: null == counts ? _self._counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}

// dart format on
