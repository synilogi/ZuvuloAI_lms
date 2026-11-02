// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'learner_home.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpcomingItem {

 String get id;@JsonKey(unknownEnumValue: UpcomingKind.unknown) UpcomingKind get kind; String get title;/// "Foundations of Vedic Astrology · 60 min"
 String get context;@UtcDateTimeConverter() DateTime get at; String get to;@JsonKey(unknownEnumValue: UpcomingFlag.unknown) UpcomingFlag? get flag;
/// Create a copy of UpcomingItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpcomingItemCopyWith<UpcomingItem> get copyWith => _$UpcomingItemCopyWithImpl<UpcomingItem>(this as UpcomingItem, _$identity);

  /// Serializes this UpcomingItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpcomingItem&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.context, context) || other.context == context)&&(identical(other.at, at) || other.at == at)&&(identical(other.to, to) || other.to == to)&&(identical(other.flag, flag) || other.flag == flag));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,title,context,at,to,flag);

@override
String toString() {
  return 'UpcomingItem(id: $id, kind: $kind, title: $title, context: $context, at: $at, to: $to, flag: $flag)';
}


}

/// @nodoc
abstract mixin class $UpcomingItemCopyWith<$Res>  {
  factory $UpcomingItemCopyWith(UpcomingItem value, $Res Function(UpcomingItem) _then) = _$UpcomingItemCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: UpcomingKind.unknown) UpcomingKind kind, String title, String context,@UtcDateTimeConverter() DateTime at, String to,@JsonKey(unknownEnumValue: UpcomingFlag.unknown) UpcomingFlag? flag
});




}
/// @nodoc
class _$UpcomingItemCopyWithImpl<$Res>
    implements $UpcomingItemCopyWith<$Res> {
  _$UpcomingItemCopyWithImpl(this._self, this._then);

  final UpcomingItem _self;
  final $Res Function(UpcomingItem) _then;

/// Create a copy of UpcomingItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? context = null,Object? at = null,Object? to = null,Object? flag = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as UpcomingKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,flag: freezed == flag ? _self.flag : flag // ignore: cast_nullable_to_non_nullable
as UpcomingFlag?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpcomingItem].
extension UpcomingItemPatterns on UpcomingItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpcomingItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpcomingItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpcomingItem value)  $default,){
final _that = this;
switch (_that) {
case _UpcomingItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpcomingItem value)?  $default,){
final _that = this;
switch (_that) {
case _UpcomingItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: UpcomingKind.unknown)  UpcomingKind kind,  String title,  String context, @UtcDateTimeConverter()  DateTime at,  String to, @JsonKey(unknownEnumValue: UpcomingFlag.unknown)  UpcomingFlag? flag)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpcomingItem() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.context,_that.at,_that.to,_that.flag);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: UpcomingKind.unknown)  UpcomingKind kind,  String title,  String context, @UtcDateTimeConverter()  DateTime at,  String to, @JsonKey(unknownEnumValue: UpcomingFlag.unknown)  UpcomingFlag? flag)  $default,) {final _that = this;
switch (_that) {
case _UpcomingItem():
return $default(_that.id,_that.kind,_that.title,_that.context,_that.at,_that.to,_that.flag);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(unknownEnumValue: UpcomingKind.unknown)  UpcomingKind kind,  String title,  String context, @UtcDateTimeConverter()  DateTime at,  String to, @JsonKey(unknownEnumValue: UpcomingFlag.unknown)  UpcomingFlag? flag)?  $default,) {final _that = this;
switch (_that) {
case _UpcomingItem() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.context,_that.at,_that.to,_that.flag);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpcomingItem implements UpcomingItem {
  const _UpcomingItem({required this.id, @JsonKey(unknownEnumValue: UpcomingKind.unknown) this.kind = UpcomingKind.unknown, this.title = '', this.context = '', @UtcDateTimeConverter() required this.at, this.to = '', @JsonKey(unknownEnumValue: UpcomingFlag.unknown) this.flag});
  factory _UpcomingItem.fromJson(Map<String, dynamic> json) => _$UpcomingItemFromJson(json);

@override final  String id;
@override@JsonKey(unknownEnumValue: UpcomingKind.unknown) final  UpcomingKind kind;
@override@JsonKey() final  String title;
/// "Foundations of Vedic Astrology · 60 min"
@override@JsonKey() final  String context;
@override@UtcDateTimeConverter() final  DateTime at;
@override@JsonKey() final  String to;
@override@JsonKey(unknownEnumValue: UpcomingFlag.unknown) final  UpcomingFlag? flag;

/// Create a copy of UpcomingItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpcomingItemCopyWith<_UpcomingItem> get copyWith => __$UpcomingItemCopyWithImpl<_UpcomingItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpcomingItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpcomingItem&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.context, context) || other.context == context)&&(identical(other.at, at) || other.at == at)&&(identical(other.to, to) || other.to == to)&&(identical(other.flag, flag) || other.flag == flag));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,title,context,at,to,flag);

@override
String toString() {
  return 'UpcomingItem(id: $id, kind: $kind, title: $title, context: $context, at: $at, to: $to, flag: $flag)';
}


}

/// @nodoc
abstract mixin class _$UpcomingItemCopyWith<$Res> implements $UpcomingItemCopyWith<$Res> {
  factory _$UpcomingItemCopyWith(_UpcomingItem value, $Res Function(_UpcomingItem) _then) = __$UpcomingItemCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: UpcomingKind.unknown) UpcomingKind kind, String title, String context,@UtcDateTimeConverter() DateTime at, String to,@JsonKey(unknownEnumValue: UpcomingFlag.unknown) UpcomingFlag? flag
});




}
/// @nodoc
class __$UpcomingItemCopyWithImpl<$Res>
    implements _$UpcomingItemCopyWith<$Res> {
  __$UpcomingItemCopyWithImpl(this._self, this._then);

  final _UpcomingItem _self;
  final $Res Function(_UpcomingItem) _then;

/// Create a copy of UpcomingItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? context = null,Object? at = null,Object? to = null,Object? flag = freezed,}) {
  return _then(_UpcomingItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as UpcomingKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,flag: freezed == flag ? _self.flag : flag // ignore: cast_nullable_to_non_nullable
as UpcomingFlag?,
  ));
}


}


/// @nodoc
mixin _$RecentLesson {

 String get courseId; String get lessonId; String get courseTitle; String get lessonTitle;/// The backend's `LessonType`, kept as sent.
 String get type;@UtcDateTimeConverter() DateTime get at; String get state;
/// Create a copy of RecentLesson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentLessonCopyWith<RecentLesson> get copyWith => _$RecentLessonCopyWithImpl<RecentLesson>(this as RecentLesson, _$identity);

  /// Serializes this RecentLesson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentLesson&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.lessonId, lessonId) || other.lessonId == lessonId)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.lessonTitle, lessonTitle) || other.lessonTitle == lessonTitle)&&(identical(other.type, type) || other.type == type)&&(identical(other.at, at) || other.at == at)&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseId,lessonId,courseTitle,lessonTitle,type,at,state);

@override
String toString() {
  return 'RecentLesson(courseId: $courseId, lessonId: $lessonId, courseTitle: $courseTitle, lessonTitle: $lessonTitle, type: $type, at: $at, state: $state)';
}


}

/// @nodoc
abstract mixin class $RecentLessonCopyWith<$Res>  {
  factory $RecentLessonCopyWith(RecentLesson value, $Res Function(RecentLesson) _then) = _$RecentLessonCopyWithImpl;
@useResult
$Res call({
 String courseId, String lessonId, String courseTitle, String lessonTitle, String type,@UtcDateTimeConverter() DateTime at, String state
});




}
/// @nodoc
class _$RecentLessonCopyWithImpl<$Res>
    implements $RecentLessonCopyWith<$Res> {
  _$RecentLessonCopyWithImpl(this._self, this._then);

  final RecentLesson _self;
  final $Res Function(RecentLesson) _then;

/// Create a copy of RecentLesson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? courseId = null,Object? lessonId = null,Object? courseTitle = null,Object? lessonTitle = null,Object? type = null,Object? at = null,Object? state = null,}) {
  return _then(_self.copyWith(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,lessonId: null == lessonId ? _self.lessonId : lessonId // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,lessonTitle: null == lessonTitle ? _self.lessonTitle : lessonTitle // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RecentLesson].
extension RecentLessonPatterns on RecentLesson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecentLesson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecentLesson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecentLesson value)  $default,){
final _that = this;
switch (_that) {
case _RecentLesson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecentLesson value)?  $default,){
final _that = this;
switch (_that) {
case _RecentLesson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String courseId,  String lessonId,  String courseTitle,  String lessonTitle,  String type, @UtcDateTimeConverter()  DateTime at,  String state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecentLesson() when $default != null:
return $default(_that.courseId,_that.lessonId,_that.courseTitle,_that.lessonTitle,_that.type,_that.at,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String courseId,  String lessonId,  String courseTitle,  String lessonTitle,  String type, @UtcDateTimeConverter()  DateTime at,  String state)  $default,) {final _that = this;
switch (_that) {
case _RecentLesson():
return $default(_that.courseId,_that.lessonId,_that.courseTitle,_that.lessonTitle,_that.type,_that.at,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String courseId,  String lessonId,  String courseTitle,  String lessonTitle,  String type, @UtcDateTimeConverter()  DateTime at,  String state)?  $default,) {final _that = this;
switch (_that) {
case _RecentLesson() when $default != null:
return $default(_that.courseId,_that.lessonId,_that.courseTitle,_that.lessonTitle,_that.type,_that.at,_that.state);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecentLesson implements RecentLesson {
  const _RecentLesson({required this.courseId, required this.lessonId, this.courseTitle = '', this.lessonTitle = '', this.type = '', @UtcDateTimeConverter() required this.at, this.state = ''});
  factory _RecentLesson.fromJson(Map<String, dynamic> json) => _$RecentLessonFromJson(json);

@override final  String courseId;
@override final  String lessonId;
@override@JsonKey() final  String courseTitle;
@override@JsonKey() final  String lessonTitle;
/// The backend's `LessonType`, kept as sent.
@override@JsonKey() final  String type;
@override@UtcDateTimeConverter() final  DateTime at;
@override@JsonKey() final  String state;

/// Create a copy of RecentLesson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecentLessonCopyWith<_RecentLesson> get copyWith => __$RecentLessonCopyWithImpl<_RecentLesson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecentLessonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecentLesson&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.lessonId, lessonId) || other.lessonId == lessonId)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.lessonTitle, lessonTitle) || other.lessonTitle == lessonTitle)&&(identical(other.type, type) || other.type == type)&&(identical(other.at, at) || other.at == at)&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,courseId,lessonId,courseTitle,lessonTitle,type,at,state);

@override
String toString() {
  return 'RecentLesson(courseId: $courseId, lessonId: $lessonId, courseTitle: $courseTitle, lessonTitle: $lessonTitle, type: $type, at: $at, state: $state)';
}


}

/// @nodoc
abstract mixin class _$RecentLessonCopyWith<$Res> implements $RecentLessonCopyWith<$Res> {
  factory _$RecentLessonCopyWith(_RecentLesson value, $Res Function(_RecentLesson) _then) = __$RecentLessonCopyWithImpl;
@override @useResult
$Res call({
 String courseId, String lessonId, String courseTitle, String lessonTitle, String type,@UtcDateTimeConverter() DateTime at, String state
});




}
/// @nodoc
class __$RecentLessonCopyWithImpl<$Res>
    implements _$RecentLessonCopyWith<$Res> {
  __$RecentLessonCopyWithImpl(this._self, this._then);

  final _RecentLesson _self;
  final $Res Function(_RecentLesson) _then;

/// Create a copy of RecentLesson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? courseId = null,Object? lessonId = null,Object? courseTitle = null,Object? lessonTitle = null,Object? type = null,Object? at = null,Object? state = null,}) {
  return _then(_RecentLesson(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,lessonId: null == lessonId ? _self.lessonId : lessonId // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,lessonTitle: null == lessonTitle ? _self.lessonTitle : lessonTitle // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$LearnerHome {

 String get firstName; List<LearnerCourse> get courses; List<SavedCourse> get saved; List<RecentLesson> get recent; List<UpcomingItem> get upcoming; List<StudyDayMinutes> get week;
/// Create a copy of LearnerHome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearnerHomeCopyWith<LearnerHome> get copyWith => _$LearnerHomeCopyWithImpl<LearnerHome>(this as LearnerHome, _$identity);

  /// Serializes this LearnerHome to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearnerHome&&(identical(other.firstName, firstName) || other.firstName == firstName)&&const DeepCollectionEquality().equals(other.courses, courses)&&const DeepCollectionEquality().equals(other.saved, saved)&&const DeepCollectionEquality().equals(other.recent, recent)&&const DeepCollectionEquality().equals(other.upcoming, upcoming)&&const DeepCollectionEquality().equals(other.week, week));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,firstName,const DeepCollectionEquality().hash(courses),const DeepCollectionEquality().hash(saved),const DeepCollectionEquality().hash(recent),const DeepCollectionEquality().hash(upcoming),const DeepCollectionEquality().hash(week));

@override
String toString() {
  return 'LearnerHome(firstName: $firstName, courses: $courses, saved: $saved, recent: $recent, upcoming: $upcoming, week: $week)';
}


}

/// @nodoc
abstract mixin class $LearnerHomeCopyWith<$Res>  {
  factory $LearnerHomeCopyWith(LearnerHome value, $Res Function(LearnerHome) _then) = _$LearnerHomeCopyWithImpl;
@useResult
$Res call({
 String firstName, List<LearnerCourse> courses, List<SavedCourse> saved, List<RecentLesson> recent, List<UpcomingItem> upcoming, List<StudyDayMinutes> week
});




}
/// @nodoc
class _$LearnerHomeCopyWithImpl<$Res>
    implements $LearnerHomeCopyWith<$Res> {
  _$LearnerHomeCopyWithImpl(this._self, this._then);

  final LearnerHome _self;
  final $Res Function(LearnerHome) _then;

/// Create a copy of LearnerHome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? firstName = null,Object? courses = null,Object? saved = null,Object? recent = null,Object? upcoming = null,Object? week = null,}) {
  return _then(_self.copyWith(
firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,courses: null == courses ? _self.courses : courses // ignore: cast_nullable_to_non_nullable
as List<LearnerCourse>,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as List<SavedCourse>,recent: null == recent ? _self.recent : recent // ignore: cast_nullable_to_non_nullable
as List<RecentLesson>,upcoming: null == upcoming ? _self.upcoming : upcoming // ignore: cast_nullable_to_non_nullable
as List<UpcomingItem>,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as List<StudyDayMinutes>,
  ));
}

}


/// Adds pattern-matching-related methods to [LearnerHome].
extension LearnerHomePatterns on LearnerHome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearnerHome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearnerHome() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearnerHome value)  $default,){
final _that = this;
switch (_that) {
case _LearnerHome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearnerHome value)?  $default,){
final _that = this;
switch (_that) {
case _LearnerHome() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String firstName,  List<LearnerCourse> courses,  List<SavedCourse> saved,  List<RecentLesson> recent,  List<UpcomingItem> upcoming,  List<StudyDayMinutes> week)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearnerHome() when $default != null:
return $default(_that.firstName,_that.courses,_that.saved,_that.recent,_that.upcoming,_that.week);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String firstName,  List<LearnerCourse> courses,  List<SavedCourse> saved,  List<RecentLesson> recent,  List<UpcomingItem> upcoming,  List<StudyDayMinutes> week)  $default,) {final _that = this;
switch (_that) {
case _LearnerHome():
return $default(_that.firstName,_that.courses,_that.saved,_that.recent,_that.upcoming,_that.week);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String firstName,  List<LearnerCourse> courses,  List<SavedCourse> saved,  List<RecentLesson> recent,  List<UpcomingItem> upcoming,  List<StudyDayMinutes> week)?  $default,) {final _that = this;
switch (_that) {
case _LearnerHome() when $default != null:
return $default(_that.firstName,_that.courses,_that.saved,_that.recent,_that.upcoming,_that.week);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LearnerHome extends LearnerHome {
  const _LearnerHome({this.firstName = '', final  List<LearnerCourse> courses = const <LearnerCourse>[], final  List<SavedCourse> saved = const <SavedCourse>[], final  List<RecentLesson> recent = const <RecentLesson>[], final  List<UpcomingItem> upcoming = const <UpcomingItem>[], final  List<StudyDayMinutes> week = const <StudyDayMinutes>[]}): _courses = courses,_saved = saved,_recent = recent,_upcoming = upcoming,_week = week,super._();
  factory _LearnerHome.fromJson(Map<String, dynamic> json) => _$LearnerHomeFromJson(json);

@override@JsonKey() final  String firstName;
 final  List<LearnerCourse> _courses;
@override@JsonKey() List<LearnerCourse> get courses {
  if (_courses is EqualUnmodifiableListView) return _courses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_courses);
}

 final  List<SavedCourse> _saved;
@override@JsonKey() List<SavedCourse> get saved {
  if (_saved is EqualUnmodifiableListView) return _saved;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_saved);
}

 final  List<RecentLesson> _recent;
@override@JsonKey() List<RecentLesson> get recent {
  if (_recent is EqualUnmodifiableListView) return _recent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recent);
}

 final  List<UpcomingItem> _upcoming;
@override@JsonKey() List<UpcomingItem> get upcoming {
  if (_upcoming is EqualUnmodifiableListView) return _upcoming;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_upcoming);
}

 final  List<StudyDayMinutes> _week;
@override@JsonKey() List<StudyDayMinutes> get week {
  if (_week is EqualUnmodifiableListView) return _week;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_week);
}


/// Create a copy of LearnerHome
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearnerHomeCopyWith<_LearnerHome> get copyWith => __$LearnerHomeCopyWithImpl<_LearnerHome>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearnerHomeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearnerHome&&(identical(other.firstName, firstName) || other.firstName == firstName)&&const DeepCollectionEquality().equals(other._courses, _courses)&&const DeepCollectionEquality().equals(other._saved, _saved)&&const DeepCollectionEquality().equals(other._recent, _recent)&&const DeepCollectionEquality().equals(other._upcoming, _upcoming)&&const DeepCollectionEquality().equals(other._week, _week));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,firstName,const DeepCollectionEquality().hash(_courses),const DeepCollectionEquality().hash(_saved),const DeepCollectionEquality().hash(_recent),const DeepCollectionEquality().hash(_upcoming),const DeepCollectionEquality().hash(_week));

@override
String toString() {
  return 'LearnerHome(firstName: $firstName, courses: $courses, saved: $saved, recent: $recent, upcoming: $upcoming, week: $week)';
}


}

/// @nodoc
abstract mixin class _$LearnerHomeCopyWith<$Res> implements $LearnerHomeCopyWith<$Res> {
  factory _$LearnerHomeCopyWith(_LearnerHome value, $Res Function(_LearnerHome) _then) = __$LearnerHomeCopyWithImpl;
@override @useResult
$Res call({
 String firstName, List<LearnerCourse> courses, List<SavedCourse> saved, List<RecentLesson> recent, List<UpcomingItem> upcoming, List<StudyDayMinutes> week
});




}
/// @nodoc
class __$LearnerHomeCopyWithImpl<$Res>
    implements _$LearnerHomeCopyWith<$Res> {
  __$LearnerHomeCopyWithImpl(this._self, this._then);

  final _LearnerHome _self;
  final $Res Function(_LearnerHome) _then;

/// Create a copy of LearnerHome
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? firstName = null,Object? courses = null,Object? saved = null,Object? recent = null,Object? upcoming = null,Object? week = null,}) {
  return _then(_LearnerHome(
firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,courses: null == courses ? _self._courses : courses // ignore: cast_nullable_to_non_nullable
as List<LearnerCourse>,saved: null == saved ? _self._saved : saved // ignore: cast_nullable_to_non_nullable
as List<SavedCourse>,recent: null == recent ? _self._recent : recent // ignore: cast_nullable_to_non_nullable
as List<RecentLesson>,upcoming: null == upcoming ? _self._upcoming : upcoming // ignore: cast_nullable_to_non_nullable
as List<UpcomingItem>,week: null == week ? _self._week : week // ignore: cast_nullable_to_non_nullable
as List<StudyDayMinutes>,
  ));
}


}


/// @nodoc
mixin _$LearnerCourses {

 List<LearnerCourse> get courses; List<SavedCourse> get saved;
/// Create a copy of LearnerCourses
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearnerCoursesCopyWith<LearnerCourses> get copyWith => _$LearnerCoursesCopyWithImpl<LearnerCourses>(this as LearnerCourses, _$identity);

  /// Serializes this LearnerCourses to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearnerCourses&&const DeepCollectionEquality().equals(other.courses, courses)&&const DeepCollectionEquality().equals(other.saved, saved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(courses),const DeepCollectionEquality().hash(saved));

@override
String toString() {
  return 'LearnerCourses(courses: $courses, saved: $saved)';
}


}

/// @nodoc
abstract mixin class $LearnerCoursesCopyWith<$Res>  {
  factory $LearnerCoursesCopyWith(LearnerCourses value, $Res Function(LearnerCourses) _then) = _$LearnerCoursesCopyWithImpl;
@useResult
$Res call({
 List<LearnerCourse> courses, List<SavedCourse> saved
});




}
/// @nodoc
class _$LearnerCoursesCopyWithImpl<$Res>
    implements $LearnerCoursesCopyWith<$Res> {
  _$LearnerCoursesCopyWithImpl(this._self, this._then);

  final LearnerCourses _self;
  final $Res Function(LearnerCourses) _then;

/// Create a copy of LearnerCourses
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? courses = null,Object? saved = null,}) {
  return _then(_self.copyWith(
courses: null == courses ? _self.courses : courses // ignore: cast_nullable_to_non_nullable
as List<LearnerCourse>,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as List<SavedCourse>,
  ));
}

}


/// Adds pattern-matching-related methods to [LearnerCourses].
extension LearnerCoursesPatterns on LearnerCourses {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearnerCourses value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearnerCourses() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearnerCourses value)  $default,){
final _that = this;
switch (_that) {
case _LearnerCourses():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearnerCourses value)?  $default,){
final _that = this;
switch (_that) {
case _LearnerCourses() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<LearnerCourse> courses,  List<SavedCourse> saved)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearnerCourses() when $default != null:
return $default(_that.courses,_that.saved);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<LearnerCourse> courses,  List<SavedCourse> saved)  $default,) {final _that = this;
switch (_that) {
case _LearnerCourses():
return $default(_that.courses,_that.saved);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<LearnerCourse> courses,  List<SavedCourse> saved)?  $default,) {final _that = this;
switch (_that) {
case _LearnerCourses() when $default != null:
return $default(_that.courses,_that.saved);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LearnerCourses implements LearnerCourses {
  const _LearnerCourses({final  List<LearnerCourse> courses = const <LearnerCourse>[], final  List<SavedCourse> saved = const <SavedCourse>[]}): _courses = courses,_saved = saved;
  factory _LearnerCourses.fromJson(Map<String, dynamic> json) => _$LearnerCoursesFromJson(json);

 final  List<LearnerCourse> _courses;
@override@JsonKey() List<LearnerCourse> get courses {
  if (_courses is EqualUnmodifiableListView) return _courses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_courses);
}

 final  List<SavedCourse> _saved;
@override@JsonKey() List<SavedCourse> get saved {
  if (_saved is EqualUnmodifiableListView) return _saved;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_saved);
}


/// Create a copy of LearnerCourses
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearnerCoursesCopyWith<_LearnerCourses> get copyWith => __$LearnerCoursesCopyWithImpl<_LearnerCourses>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearnerCoursesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearnerCourses&&const DeepCollectionEquality().equals(other._courses, _courses)&&const DeepCollectionEquality().equals(other._saved, _saved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_courses),const DeepCollectionEquality().hash(_saved));

@override
String toString() {
  return 'LearnerCourses(courses: $courses, saved: $saved)';
}


}

/// @nodoc
abstract mixin class _$LearnerCoursesCopyWith<$Res> implements $LearnerCoursesCopyWith<$Res> {
  factory _$LearnerCoursesCopyWith(_LearnerCourses value, $Res Function(_LearnerCourses) _then) = __$LearnerCoursesCopyWithImpl;
@override @useResult
$Res call({
 List<LearnerCourse> courses, List<SavedCourse> saved
});




}
/// @nodoc
class __$LearnerCoursesCopyWithImpl<$Res>
    implements _$LearnerCoursesCopyWith<$Res> {
  __$LearnerCoursesCopyWithImpl(this._self, this._then);

  final _LearnerCourses _self;
  final $Res Function(_LearnerCourses) _then;

/// Create a copy of LearnerCourses
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? courses = null,Object? saved = null,}) {
  return _then(_LearnerCourses(
courses: null == courses ? _self._courses : courses // ignore: cast_nullable_to_non_nullable
as List<LearnerCourse>,saved: null == saved ? _self._saved : saved // ignore: cast_nullable_to_non_nullable
as List<SavedCourse>,
  ));
}


}

// dart format on
