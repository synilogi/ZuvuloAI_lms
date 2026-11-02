// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StudyDayMinutes {

 String get date; int get minutes;
/// Create a copy of StudyDayMinutes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudyDayMinutesCopyWith<StudyDayMinutes> get copyWith => _$StudyDayMinutesCopyWithImpl<StudyDayMinutes>(this as StudyDayMinutes, _$identity);

  /// Serializes this StudyDayMinutes to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudyDayMinutes&&(identical(other.date, date) || other.date == date)&&(identical(other.minutes, minutes) || other.minutes == minutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,minutes);

@override
String toString() {
  return 'StudyDayMinutes(date: $date, minutes: $minutes)';
}


}

/// @nodoc
abstract mixin class $StudyDayMinutesCopyWith<$Res>  {
  factory $StudyDayMinutesCopyWith(StudyDayMinutes value, $Res Function(StudyDayMinutes) _then) = _$StudyDayMinutesCopyWithImpl;
@useResult
$Res call({
 String date, int minutes
});




}
/// @nodoc
class _$StudyDayMinutesCopyWithImpl<$Res>
    implements $StudyDayMinutesCopyWith<$Res> {
  _$StudyDayMinutesCopyWithImpl(this._self, this._then);

  final StudyDayMinutes _self;
  final $Res Function(StudyDayMinutes) _then;

/// Create a copy of StudyDayMinutes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? minutes = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StudyDayMinutes].
extension StudyDayMinutesPatterns on StudyDayMinutes {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudyDayMinutes value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudyDayMinutes() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudyDayMinutes value)  $default,){
final _that = this;
switch (_that) {
case _StudyDayMinutes():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudyDayMinutes value)?  $default,){
final _that = this;
switch (_that) {
case _StudyDayMinutes() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  int minutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudyDayMinutes() when $default != null:
return $default(_that.date,_that.minutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  int minutes)  $default,) {final _that = this;
switch (_that) {
case _StudyDayMinutes():
return $default(_that.date,_that.minutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  int minutes)?  $default,) {final _that = this;
switch (_that) {
case _StudyDayMinutes() when $default != null:
return $default(_that.date,_that.minutes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudyDayMinutes extends StudyDayMinutes {
  const _StudyDayMinutes({required this.date, this.minutes = 0}): super._();
  factory _StudyDayMinutes.fromJson(Map<String, dynamic> json) => _$StudyDayMinutesFromJson(json);

@override final  String date;
@override@JsonKey() final  int minutes;

/// Create a copy of StudyDayMinutes
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudyDayMinutesCopyWith<_StudyDayMinutes> get copyWith => __$StudyDayMinutesCopyWithImpl<_StudyDayMinutes>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudyDayMinutesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudyDayMinutes&&(identical(other.date, date) || other.date == date)&&(identical(other.minutes, minutes) || other.minutes == minutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,minutes);

@override
String toString() {
  return 'StudyDayMinutes(date: $date, minutes: $minutes)';
}


}

/// @nodoc
abstract mixin class _$StudyDayMinutesCopyWith<$Res> implements $StudyDayMinutesCopyWith<$Res> {
  factory _$StudyDayMinutesCopyWith(_StudyDayMinutes value, $Res Function(_StudyDayMinutes) _then) = __$StudyDayMinutesCopyWithImpl;
@override @useResult
$Res call({
 String date, int minutes
});




}
/// @nodoc
class __$StudyDayMinutesCopyWithImpl<$Res>
    implements _$StudyDayMinutesCopyWith<$Res> {
  __$StudyDayMinutesCopyWithImpl(this._self, this._then);

  final _StudyDayMinutes _self;
  final $Res Function(_StudyDayMinutes) _then;

/// Create a copy of StudyDayMinutes
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? minutes = null,}) {
  return _then(_StudyDayMinutes(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StudyWeek {

 String get label; String get detail; int get minutes;
/// Create a copy of StudyWeek
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudyWeekCopyWith<StudyWeek> get copyWith => _$StudyWeekCopyWithImpl<StudyWeek>(this as StudyWeek, _$identity);

  /// Serializes this StudyWeek to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudyWeek&&(identical(other.label, label) || other.label == label)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.minutes, minutes) || other.minutes == minutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,detail,minutes);

@override
String toString() {
  return 'StudyWeek(label: $label, detail: $detail, minutes: $minutes)';
}


}

/// @nodoc
abstract mixin class $StudyWeekCopyWith<$Res>  {
  factory $StudyWeekCopyWith(StudyWeek value, $Res Function(StudyWeek) _then) = _$StudyWeekCopyWithImpl;
@useResult
$Res call({
 String label, String detail, int minutes
});




}
/// @nodoc
class _$StudyWeekCopyWithImpl<$Res>
    implements $StudyWeekCopyWith<$Res> {
  _$StudyWeekCopyWithImpl(this._self, this._then);

  final StudyWeek _self;
  final $Res Function(StudyWeek) _then;

/// Create a copy of StudyWeek
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? detail = null,Object? minutes = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StudyWeek].
extension StudyWeekPatterns on StudyWeek {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudyWeek value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudyWeek() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudyWeek value)  $default,){
final _that = this;
switch (_that) {
case _StudyWeek():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudyWeek value)?  $default,){
final _that = this;
switch (_that) {
case _StudyWeek() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String detail,  int minutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudyWeek() when $default != null:
return $default(_that.label,_that.detail,_that.minutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String detail,  int minutes)  $default,) {final _that = this;
switch (_that) {
case _StudyWeek():
return $default(_that.label,_that.detail,_that.minutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String detail,  int minutes)?  $default,) {final _that = this;
switch (_that) {
case _StudyWeek() when $default != null:
return $default(_that.label,_that.detail,_that.minutes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudyWeek implements StudyWeek {
  const _StudyWeek({this.label = '', this.detail = '', this.minutes = 0});
  factory _StudyWeek.fromJson(Map<String, dynamic> json) => _$StudyWeekFromJson(json);

@override@JsonKey() final  String label;
@override@JsonKey() final  String detail;
@override@JsonKey() final  int minutes;

/// Create a copy of StudyWeek
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudyWeekCopyWith<_StudyWeek> get copyWith => __$StudyWeekCopyWithImpl<_StudyWeek>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudyWeekToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudyWeek&&(identical(other.label, label) || other.label == label)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.minutes, minutes) || other.minutes == minutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,detail,minutes);

@override
String toString() {
  return 'StudyWeek(label: $label, detail: $detail, minutes: $minutes)';
}


}

/// @nodoc
abstract mixin class _$StudyWeekCopyWith<$Res> implements $StudyWeekCopyWith<$Res> {
  factory _$StudyWeekCopyWith(_StudyWeek value, $Res Function(_StudyWeek) _then) = __$StudyWeekCopyWithImpl;
@override @useResult
$Res call({
 String label, String detail, int minutes
});




}
/// @nodoc
class __$StudyWeekCopyWithImpl<$Res>
    implements _$StudyWeekCopyWith<$Res> {
  __$StudyWeekCopyWithImpl(this._self, this._then);

  final _StudyWeek _self;
  final $Res Function(_StudyWeek) _then;

/// Create a copy of StudyWeek
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? detail = null,Object? minutes = null,}) {
  return _then(_StudyWeek(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$LearningEvent {

 String get id;@JsonKey(unknownEnumValue: ActivityKind.unknown) ActivityKind get kind; String get title; String? get context;/// Which course it happened in. Sent by the staff activity route, which can be filtered by it;
/// the learner's own feed does not need it.
 String? get courseId;@UtcDateTimeConverter() DateTime get at;
/// Create a copy of LearningEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearningEventCopyWith<LearningEvent> get copyWith => _$LearningEventCopyWithImpl<LearningEvent>(this as LearningEvent, _$identity);

  /// Serializes this LearningEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearningEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.context, context) || other.context == context)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,title,context,courseId,at);

@override
String toString() {
  return 'LearningEvent(id: $id, kind: $kind, title: $title, context: $context, courseId: $courseId, at: $at)';
}


}

/// @nodoc
abstract mixin class $LearningEventCopyWith<$Res>  {
  factory $LearningEventCopyWith(LearningEvent value, $Res Function(LearningEvent) _then) = _$LearningEventCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: ActivityKind.unknown) ActivityKind kind, String title, String? context, String? courseId,@UtcDateTimeConverter() DateTime at
});




}
/// @nodoc
class _$LearningEventCopyWithImpl<$Res>
    implements $LearningEventCopyWith<$Res> {
  _$LearningEventCopyWithImpl(this._self, this._then);

  final LearningEvent _self;
  final $Res Function(LearningEvent) _then;

/// Create a copy of LearningEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? context = freezed,Object? courseId = freezed,Object? at = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ActivityKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,context: freezed == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as String?,courseId: freezed == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String?,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [LearningEvent].
extension LearningEventPatterns on LearningEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearningEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearningEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearningEvent value)  $default,){
final _that = this;
switch (_that) {
case _LearningEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearningEvent value)?  $default,){
final _that = this;
switch (_that) {
case _LearningEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: ActivityKind.unknown)  ActivityKind kind,  String title,  String? context,  String? courseId, @UtcDateTimeConverter()  DateTime at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearningEvent() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.context,_that.courseId,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: ActivityKind.unknown)  ActivityKind kind,  String title,  String? context,  String? courseId, @UtcDateTimeConverter()  DateTime at)  $default,) {final _that = this;
switch (_that) {
case _LearningEvent():
return $default(_that.id,_that.kind,_that.title,_that.context,_that.courseId,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(unknownEnumValue: ActivityKind.unknown)  ActivityKind kind,  String title,  String? context,  String? courseId, @UtcDateTimeConverter()  DateTime at)?  $default,) {final _that = this;
switch (_that) {
case _LearningEvent() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.context,_that.courseId,_that.at);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LearningEvent implements LearningEvent {
  const _LearningEvent({required this.id, @JsonKey(unknownEnumValue: ActivityKind.unknown) this.kind = ActivityKind.unknown, this.title = '', this.context, this.courseId, @UtcDateTimeConverter() required this.at});
  factory _LearningEvent.fromJson(Map<String, dynamic> json) => _$LearningEventFromJson(json);

@override final  String id;
@override@JsonKey(unknownEnumValue: ActivityKind.unknown) final  ActivityKind kind;
@override@JsonKey() final  String title;
@override final  String? context;
/// Which course it happened in. Sent by the staff activity route, which can be filtered by it;
/// the learner's own feed does not need it.
@override final  String? courseId;
@override@UtcDateTimeConverter() final  DateTime at;

/// Create a copy of LearningEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearningEventCopyWith<_LearningEvent> get copyWith => __$LearningEventCopyWithImpl<_LearningEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearningEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearningEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.context, context) || other.context == context)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,title,context,courseId,at);

@override
String toString() {
  return 'LearningEvent(id: $id, kind: $kind, title: $title, context: $context, courseId: $courseId, at: $at)';
}


}

/// @nodoc
abstract mixin class _$LearningEventCopyWith<$Res> implements $LearningEventCopyWith<$Res> {
  factory _$LearningEventCopyWith(_LearningEvent value, $Res Function(_LearningEvent) _then) = __$LearningEventCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: ActivityKind.unknown) ActivityKind kind, String title, String? context, String? courseId,@UtcDateTimeConverter() DateTime at
});




}
/// @nodoc
class __$LearningEventCopyWithImpl<$Res>
    implements _$LearningEventCopyWith<$Res> {
  __$LearningEventCopyWithImpl(this._self, this._then);

  final _LearningEvent _self;
  final $Res Function(_LearningEvent) _then;

/// Create a copy of LearningEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? context = freezed,Object? courseId = freezed,Object? at = null,}) {
  return _then(_LearningEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ActivityKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,context: freezed == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as String?,courseId: freezed == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String?,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$LearningActivity {

 List<StudyDayMinutes> get week; List<LearningEvent> get events;
/// Create a copy of LearningActivity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearningActivityCopyWith<LearningActivity> get copyWith => _$LearningActivityCopyWithImpl<LearningActivity>(this as LearningActivity, _$identity);

  /// Serializes this LearningActivity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearningActivity&&const DeepCollectionEquality().equals(other.week, week)&&const DeepCollectionEquality().equals(other.events, events));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(week),const DeepCollectionEquality().hash(events));

@override
String toString() {
  return 'LearningActivity(week: $week, events: $events)';
}


}

/// @nodoc
abstract mixin class $LearningActivityCopyWith<$Res>  {
  factory $LearningActivityCopyWith(LearningActivity value, $Res Function(LearningActivity) _then) = _$LearningActivityCopyWithImpl;
@useResult
$Res call({
 List<StudyDayMinutes> week, List<LearningEvent> events
});




}
/// @nodoc
class _$LearningActivityCopyWithImpl<$Res>
    implements $LearningActivityCopyWith<$Res> {
  _$LearningActivityCopyWithImpl(this._self, this._then);

  final LearningActivity _self;
  final $Res Function(LearningActivity) _then;

/// Create a copy of LearningActivity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? week = null,Object? events = null,}) {
  return _then(_self.copyWith(
week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as List<StudyDayMinutes>,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<LearningEvent>,
  ));
}

}


/// Adds pattern-matching-related methods to [LearningActivity].
extension LearningActivityPatterns on LearningActivity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearningActivity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearningActivity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearningActivity value)  $default,){
final _that = this;
switch (_that) {
case _LearningActivity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearningActivity value)?  $default,){
final _that = this;
switch (_that) {
case _LearningActivity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<StudyDayMinutes> week,  List<LearningEvent> events)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearningActivity() when $default != null:
return $default(_that.week,_that.events);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<StudyDayMinutes> week,  List<LearningEvent> events)  $default,) {final _that = this;
switch (_that) {
case _LearningActivity():
return $default(_that.week,_that.events);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<StudyDayMinutes> week,  List<LearningEvent> events)?  $default,) {final _that = this;
switch (_that) {
case _LearningActivity() when $default != null:
return $default(_that.week,_that.events);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LearningActivity extends LearningActivity {
  const _LearningActivity({final  List<StudyDayMinutes> week = const <StudyDayMinutes>[], final  List<LearningEvent> events = const <LearningEvent>[]}): _week = week,_events = events,super._();
  factory _LearningActivity.fromJson(Map<String, dynamic> json) => _$LearningActivityFromJson(json);

 final  List<StudyDayMinutes> _week;
@override@JsonKey() List<StudyDayMinutes> get week {
  if (_week is EqualUnmodifiableListView) return _week;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_week);
}

 final  List<LearningEvent> _events;
@override@JsonKey() List<LearningEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}


/// Create a copy of LearningActivity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearningActivityCopyWith<_LearningActivity> get copyWith => __$LearningActivityCopyWithImpl<_LearningActivity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearningActivityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearningActivity&&const DeepCollectionEquality().equals(other._week, _week)&&const DeepCollectionEquality().equals(other._events, _events));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_week),const DeepCollectionEquality().hash(_events));

@override
String toString() {
  return 'LearningActivity(week: $week, events: $events)';
}


}

/// @nodoc
abstract mixin class _$LearningActivityCopyWith<$Res> implements $LearningActivityCopyWith<$Res> {
  factory _$LearningActivityCopyWith(_LearningActivity value, $Res Function(_LearningActivity) _then) = __$LearningActivityCopyWithImpl;
@override @useResult
$Res call({
 List<StudyDayMinutes> week, List<LearningEvent> events
});




}
/// @nodoc
class __$LearningActivityCopyWithImpl<$Res>
    implements _$LearningActivityCopyWith<$Res> {
  __$LearningActivityCopyWithImpl(this._self, this._then);

  final _LearningActivity _self;
  final $Res Function(_LearningActivity) _then;

/// Create a copy of LearningActivity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? week = null,Object? events = null,}) {
  return _then(_LearningActivity(
week: null == week ? _self._week : week // ignore: cast_nullable_to_non_nullable
as List<StudyDayMinutes>,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<LearningEvent>,
  ));
}


}

// dart format on
