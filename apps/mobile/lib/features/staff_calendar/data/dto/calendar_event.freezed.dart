// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CalendarSource {

 String get kind; String get id;
/// Create a copy of CalendarSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarSourceCopyWith<CalendarSource> get copyWith => _$CalendarSourceCopyWithImpl<CalendarSource>(this as CalendarSource, _$identity);

  /// Serializes this CalendarSource to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarSource&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,id);

@override
String toString() {
  return 'CalendarSource(kind: $kind, id: $id)';
}


}

/// @nodoc
abstract mixin class $CalendarSourceCopyWith<$Res>  {
  factory $CalendarSourceCopyWith(CalendarSource value, $Res Function(CalendarSource) _then) = _$CalendarSourceCopyWithImpl;
@useResult
$Res call({
 String kind, String id
});




}
/// @nodoc
class _$CalendarSourceCopyWithImpl<$Res>
    implements $CalendarSourceCopyWith<$Res> {
  _$CalendarSourceCopyWithImpl(this._self, this._then);

  final CalendarSource _self;
  final $Res Function(CalendarSource) _then;

/// Create a copy of CalendarSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? id = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarSource].
extension CalendarSourcePatterns on CalendarSource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarSource value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarSource() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarSource value)  $default,){
final _that = this;
switch (_that) {
case _CalendarSource():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarSource value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarSource() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarSource() when $default != null:
return $default(_that.kind,_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String id)  $default,) {final _that = this;
switch (_that) {
case _CalendarSource():
return $default(_that.kind,_that.id);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String id)?  $default,) {final _that = this;
switch (_that) {
case _CalendarSource() when $default != null:
return $default(_that.kind,_that.id);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarSource implements CalendarSource {
  const _CalendarSource({this.kind = '', this.id = ''});
  factory _CalendarSource.fromJson(Map<String, dynamic> json) => _$CalendarSourceFromJson(json);

@override@JsonKey() final  String kind;
@override@JsonKey() final  String id;

/// Create a copy of CalendarSource
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarSourceCopyWith<_CalendarSource> get copyWith => __$CalendarSourceCopyWithImpl<_CalendarSource>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarSourceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarSource&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,id);

@override
String toString() {
  return 'CalendarSource(kind: $kind, id: $id)';
}


}

/// @nodoc
abstract mixin class _$CalendarSourceCopyWith<$Res> implements $CalendarSourceCopyWith<$Res> {
  factory _$CalendarSourceCopyWith(_CalendarSource value, $Res Function(_CalendarSource) _then) = __$CalendarSourceCopyWithImpl;
@override @useResult
$Res call({
 String kind, String id
});




}
/// @nodoc
class __$CalendarSourceCopyWithImpl<$Res>
    implements _$CalendarSourceCopyWith<$Res> {
  __$CalendarSourceCopyWithImpl(this._self, this._then);

  final _CalendarSource _self;
  final $Res Function(_CalendarSource) _then;

/// Create a copy of CalendarSource
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? id = null,}) {
  return _then(_CalendarSource(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CalendarEvent {

 String get id;@JsonKey(unknownEnumValue: CalendarEventType.unknown) CalendarEventType get type; String get title; String? get description;@JsonKey(unknownEnumValue: CalendarTiming.unknown) CalendarTiming get timing;@UtcDateTimeConverter() DateTime get startsAt;/// Timed events only.
 int? get durationMin; String? get courseId; String? get chapterId; String? get instructorId; String? get quizId;@JsonKey(unknownEnumValue: MilestoneKind.unknown) MilestoneKind? get milestone;@JsonKey(unknownEnumValue: ReminderAudience.unknown) ReminderAudience? get audience;/// A reminder belongs to whoever set it.
 String? get ownerId;/// Minutes before the start that the academy sends a notice; absent for none.
 int? get notifyMin; bool get done; bool get cancelled; CalendarSource? get source;
/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarEventCopyWith<CalendarEvent> get copyWith => _$CalendarEventCopyWithImpl<CalendarEvent>(this as CalendarEvent, _$identity);

  /// Serializes this CalendarEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.timing, timing) || other.timing == timing)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.instructorId, instructorId) || other.instructorId == instructorId)&&(identical(other.quizId, quizId) || other.quizId == quizId)&&(identical(other.milestone, milestone) || other.milestone == milestone)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.notifyMin, notifyMin) || other.notifyMin == notifyMin)&&(identical(other.done, done) || other.done == done)&&(identical(other.cancelled, cancelled) || other.cancelled == cancelled)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,title,description,timing,startsAt,durationMin,courseId,chapterId,instructorId,quizId,milestone,audience,ownerId,notifyMin,done,cancelled,source);

@override
String toString() {
  return 'CalendarEvent(id: $id, type: $type, title: $title, description: $description, timing: $timing, startsAt: $startsAt, durationMin: $durationMin, courseId: $courseId, chapterId: $chapterId, instructorId: $instructorId, quizId: $quizId, milestone: $milestone, audience: $audience, ownerId: $ownerId, notifyMin: $notifyMin, done: $done, cancelled: $cancelled, source: $source)';
}


}

/// @nodoc
abstract mixin class $CalendarEventCopyWith<$Res>  {
  factory $CalendarEventCopyWith(CalendarEvent value, $Res Function(CalendarEvent) _then) = _$CalendarEventCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: CalendarEventType.unknown) CalendarEventType type, String title, String? description,@JsonKey(unknownEnumValue: CalendarTiming.unknown) CalendarTiming timing,@UtcDateTimeConverter() DateTime startsAt, int? durationMin, String? courseId, String? chapterId, String? instructorId, String? quizId,@JsonKey(unknownEnumValue: MilestoneKind.unknown) MilestoneKind? milestone,@JsonKey(unknownEnumValue: ReminderAudience.unknown) ReminderAudience? audience, String? ownerId, int? notifyMin, bool done, bool cancelled, CalendarSource? source
});


$CalendarSourceCopyWith<$Res>? get source;

}
/// @nodoc
class _$CalendarEventCopyWithImpl<$Res>
    implements $CalendarEventCopyWith<$Res> {
  _$CalendarEventCopyWithImpl(this._self, this._then);

  final CalendarEvent _self;
  final $Res Function(CalendarEvent) _then;

/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? title = null,Object? description = freezed,Object? timing = null,Object? startsAt = null,Object? durationMin = freezed,Object? courseId = freezed,Object? chapterId = freezed,Object? instructorId = freezed,Object? quizId = freezed,Object? milestone = freezed,Object? audience = freezed,Object? ownerId = freezed,Object? notifyMin = freezed,Object? done = null,Object? cancelled = null,Object? source = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CalendarEventType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,timing: null == timing ? _self.timing : timing // ignore: cast_nullable_to_non_nullable
as CalendarTiming,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,durationMin: freezed == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int?,courseId: freezed == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String?,chapterId: freezed == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String?,instructorId: freezed == instructorId ? _self.instructorId : instructorId // ignore: cast_nullable_to_non_nullable
as String?,quizId: freezed == quizId ? _self.quizId : quizId // ignore: cast_nullable_to_non_nullable
as String?,milestone: freezed == milestone ? _self.milestone : milestone // ignore: cast_nullable_to_non_nullable
as MilestoneKind?,audience: freezed == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as ReminderAudience?,ownerId: freezed == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String?,notifyMin: freezed == notifyMin ? _self.notifyMin : notifyMin // ignore: cast_nullable_to_non_nullable
as int?,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,cancelled: null == cancelled ? _self.cancelled : cancelled // ignore: cast_nullable_to_non_nullable
as bool,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as CalendarSource?,
  ));
}
/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalendarSourceCopyWith<$Res>? get source {
    if (_self.source == null) {
    return null;
  }

  return $CalendarSourceCopyWith<$Res>(_self.source!, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}


/// Adds pattern-matching-related methods to [CalendarEvent].
extension CalendarEventPatterns on CalendarEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarEvent value)  $default,){
final _that = this;
switch (_that) {
case _CalendarEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarEvent value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: CalendarEventType.unknown)  CalendarEventType type,  String title,  String? description, @JsonKey(unknownEnumValue: CalendarTiming.unknown)  CalendarTiming timing, @UtcDateTimeConverter()  DateTime startsAt,  int? durationMin,  String? courseId,  String? chapterId,  String? instructorId,  String? quizId, @JsonKey(unknownEnumValue: MilestoneKind.unknown)  MilestoneKind? milestone, @JsonKey(unknownEnumValue: ReminderAudience.unknown)  ReminderAudience? audience,  String? ownerId,  int? notifyMin,  bool done,  bool cancelled,  CalendarSource? source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.description,_that.timing,_that.startsAt,_that.durationMin,_that.courseId,_that.chapterId,_that.instructorId,_that.quizId,_that.milestone,_that.audience,_that.ownerId,_that.notifyMin,_that.done,_that.cancelled,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: CalendarEventType.unknown)  CalendarEventType type,  String title,  String? description, @JsonKey(unknownEnumValue: CalendarTiming.unknown)  CalendarTiming timing, @UtcDateTimeConverter()  DateTime startsAt,  int? durationMin,  String? courseId,  String? chapterId,  String? instructorId,  String? quizId, @JsonKey(unknownEnumValue: MilestoneKind.unknown)  MilestoneKind? milestone, @JsonKey(unknownEnumValue: ReminderAudience.unknown)  ReminderAudience? audience,  String? ownerId,  int? notifyMin,  bool done,  bool cancelled,  CalendarSource? source)  $default,) {final _that = this;
switch (_that) {
case _CalendarEvent():
return $default(_that.id,_that.type,_that.title,_that.description,_that.timing,_that.startsAt,_that.durationMin,_that.courseId,_that.chapterId,_that.instructorId,_that.quizId,_that.milestone,_that.audience,_that.ownerId,_that.notifyMin,_that.done,_that.cancelled,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(unknownEnumValue: CalendarEventType.unknown)  CalendarEventType type,  String title,  String? description, @JsonKey(unknownEnumValue: CalendarTiming.unknown)  CalendarTiming timing, @UtcDateTimeConverter()  DateTime startsAt,  int? durationMin,  String? courseId,  String? chapterId,  String? instructorId,  String? quizId, @JsonKey(unknownEnumValue: MilestoneKind.unknown)  MilestoneKind? milestone, @JsonKey(unknownEnumValue: ReminderAudience.unknown)  ReminderAudience? audience,  String? ownerId,  int? notifyMin,  bool done,  bool cancelled,  CalendarSource? source)?  $default,) {final _that = this;
switch (_that) {
case _CalendarEvent() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.description,_that.timing,_that.startsAt,_that.durationMin,_that.courseId,_that.chapterId,_that.instructorId,_that.quizId,_that.milestone,_that.audience,_that.ownerId,_that.notifyMin,_that.done,_that.cancelled,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarEvent extends CalendarEvent {
  const _CalendarEvent({this.id = '', @JsonKey(unknownEnumValue: CalendarEventType.unknown) this.type = CalendarEventType.unknown, this.title = '', this.description, @JsonKey(unknownEnumValue: CalendarTiming.unknown) this.timing = CalendarTiming.timed, @UtcDateTimeConverter() required this.startsAt, this.durationMin, this.courseId, this.chapterId, this.instructorId, this.quizId, @JsonKey(unknownEnumValue: MilestoneKind.unknown) this.milestone, @JsonKey(unknownEnumValue: ReminderAudience.unknown) this.audience, this.ownerId, this.notifyMin, this.done = false, this.cancelled = false, this.source}): super._();
  factory _CalendarEvent.fromJson(Map<String, dynamic> json) => _$CalendarEventFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey(unknownEnumValue: CalendarEventType.unknown) final  CalendarEventType type;
@override@JsonKey() final  String title;
@override final  String? description;
@override@JsonKey(unknownEnumValue: CalendarTiming.unknown) final  CalendarTiming timing;
@override@UtcDateTimeConverter() final  DateTime startsAt;
/// Timed events only.
@override final  int? durationMin;
@override final  String? courseId;
@override final  String? chapterId;
@override final  String? instructorId;
@override final  String? quizId;
@override@JsonKey(unknownEnumValue: MilestoneKind.unknown) final  MilestoneKind? milestone;
@override@JsonKey(unknownEnumValue: ReminderAudience.unknown) final  ReminderAudience? audience;
/// A reminder belongs to whoever set it.
@override final  String? ownerId;
/// Minutes before the start that the academy sends a notice; absent for none.
@override final  int? notifyMin;
@override@JsonKey() final  bool done;
@override@JsonKey() final  bool cancelled;
@override final  CalendarSource? source;

/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarEventCopyWith<_CalendarEvent> get copyWith => __$CalendarEventCopyWithImpl<_CalendarEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.timing, timing) || other.timing == timing)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.instructorId, instructorId) || other.instructorId == instructorId)&&(identical(other.quizId, quizId) || other.quizId == quizId)&&(identical(other.milestone, milestone) || other.milestone == milestone)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.notifyMin, notifyMin) || other.notifyMin == notifyMin)&&(identical(other.done, done) || other.done == done)&&(identical(other.cancelled, cancelled) || other.cancelled == cancelled)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,title,description,timing,startsAt,durationMin,courseId,chapterId,instructorId,quizId,milestone,audience,ownerId,notifyMin,done,cancelled,source);

@override
String toString() {
  return 'CalendarEvent(id: $id, type: $type, title: $title, description: $description, timing: $timing, startsAt: $startsAt, durationMin: $durationMin, courseId: $courseId, chapterId: $chapterId, instructorId: $instructorId, quizId: $quizId, milestone: $milestone, audience: $audience, ownerId: $ownerId, notifyMin: $notifyMin, done: $done, cancelled: $cancelled, source: $source)';
}


}

/// @nodoc
abstract mixin class _$CalendarEventCopyWith<$Res> implements $CalendarEventCopyWith<$Res> {
  factory _$CalendarEventCopyWith(_CalendarEvent value, $Res Function(_CalendarEvent) _then) = __$CalendarEventCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: CalendarEventType.unknown) CalendarEventType type, String title, String? description,@JsonKey(unknownEnumValue: CalendarTiming.unknown) CalendarTiming timing,@UtcDateTimeConverter() DateTime startsAt, int? durationMin, String? courseId, String? chapterId, String? instructorId, String? quizId,@JsonKey(unknownEnumValue: MilestoneKind.unknown) MilestoneKind? milestone,@JsonKey(unknownEnumValue: ReminderAudience.unknown) ReminderAudience? audience, String? ownerId, int? notifyMin, bool done, bool cancelled, CalendarSource? source
});


@override $CalendarSourceCopyWith<$Res>? get source;

}
/// @nodoc
class __$CalendarEventCopyWithImpl<$Res>
    implements _$CalendarEventCopyWith<$Res> {
  __$CalendarEventCopyWithImpl(this._self, this._then);

  final _CalendarEvent _self;
  final $Res Function(_CalendarEvent) _then;

/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? title = null,Object? description = freezed,Object? timing = null,Object? startsAt = null,Object? durationMin = freezed,Object? courseId = freezed,Object? chapterId = freezed,Object? instructorId = freezed,Object? quizId = freezed,Object? milestone = freezed,Object? audience = freezed,Object? ownerId = freezed,Object? notifyMin = freezed,Object? done = null,Object? cancelled = null,Object? source = freezed,}) {
  return _then(_CalendarEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CalendarEventType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,timing: null == timing ? _self.timing : timing // ignore: cast_nullable_to_non_nullable
as CalendarTiming,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,durationMin: freezed == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int?,courseId: freezed == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String?,chapterId: freezed == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String?,instructorId: freezed == instructorId ? _self.instructorId : instructorId // ignore: cast_nullable_to_non_nullable
as String?,quizId: freezed == quizId ? _self.quizId : quizId // ignore: cast_nullable_to_non_nullable
as String?,milestone: freezed == milestone ? _self.milestone : milestone // ignore: cast_nullable_to_non_nullable
as MilestoneKind?,audience: freezed == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as ReminderAudience?,ownerId: freezed == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String?,notifyMin: freezed == notifyMin ? _self.notifyMin : notifyMin // ignore: cast_nullable_to_non_nullable
as int?,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,cancelled: null == cancelled ? _self.cancelled : cancelled // ignore: cast_nullable_to_non_nullable
as bool,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as CalendarSource?,
  ));
}

/// Create a copy of CalendarEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalendarSourceCopyWith<$Res>? get source {
    if (_self.source == null) {
    return null;
  }

  return $CalendarSourceCopyWith<$Res>(_self.source!, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}


/// @nodoc
mixin _$CalendarDue {

 int get learners; int get submitted;
/// Create a copy of CalendarDue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarDueCopyWith<CalendarDue> get copyWith => _$CalendarDueCopyWithImpl<CalendarDue>(this as CalendarDue, _$identity);

  /// Serializes this CalendarDue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarDue&&(identical(other.learners, learners) || other.learners == learners)&&(identical(other.submitted, submitted) || other.submitted == submitted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,learners,submitted);

@override
String toString() {
  return 'CalendarDue(learners: $learners, submitted: $submitted)';
}


}

/// @nodoc
abstract mixin class $CalendarDueCopyWith<$Res>  {
  factory $CalendarDueCopyWith(CalendarDue value, $Res Function(CalendarDue) _then) = _$CalendarDueCopyWithImpl;
@useResult
$Res call({
 int learners, int submitted
});




}
/// @nodoc
class _$CalendarDueCopyWithImpl<$Res>
    implements $CalendarDueCopyWith<$Res> {
  _$CalendarDueCopyWithImpl(this._self, this._then);

  final CalendarDue _self;
  final $Res Function(CalendarDue) _then;

/// Create a copy of CalendarDue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? learners = null,Object? submitted = null,}) {
  return _then(_self.copyWith(
learners: null == learners ? _self.learners : learners // ignore: cast_nullable_to_non_nullable
as int,submitted: null == submitted ? _self.submitted : submitted // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarDue].
extension CalendarDuePatterns on CalendarDue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarDue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarDue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarDue value)  $default,){
final _that = this;
switch (_that) {
case _CalendarDue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarDue value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarDue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int learners,  int submitted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarDue() when $default != null:
return $default(_that.learners,_that.submitted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int learners,  int submitted)  $default,) {final _that = this;
switch (_that) {
case _CalendarDue():
return $default(_that.learners,_that.submitted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int learners,  int submitted)?  $default,) {final _that = this;
switch (_that) {
case _CalendarDue() when $default != null:
return $default(_that.learners,_that.submitted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarDue extends CalendarDue {
  const _CalendarDue({this.learners = 0, this.submitted = 0}): super._();
  factory _CalendarDue.fromJson(Map<String, dynamic> json) => _$CalendarDueFromJson(json);

@override@JsonKey() final  int learners;
@override@JsonKey() final  int submitted;

/// Create a copy of CalendarDue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarDueCopyWith<_CalendarDue> get copyWith => __$CalendarDueCopyWithImpl<_CalendarDue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarDueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarDue&&(identical(other.learners, learners) || other.learners == learners)&&(identical(other.submitted, submitted) || other.submitted == submitted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,learners,submitted);

@override
String toString() {
  return 'CalendarDue(learners: $learners, submitted: $submitted)';
}


}

/// @nodoc
abstract mixin class _$CalendarDueCopyWith<$Res> implements $CalendarDueCopyWith<$Res> {
  factory _$CalendarDueCopyWith(_CalendarDue value, $Res Function(_CalendarDue) _then) = __$CalendarDueCopyWithImpl;
@override @useResult
$Res call({
 int learners, int submitted
});




}
/// @nodoc
class __$CalendarDueCopyWithImpl<$Res>
    implements _$CalendarDueCopyWith<$Res> {
  __$CalendarDueCopyWithImpl(this._self, this._then);

  final _CalendarDue _self;
  final $Res Function(_CalendarDue) _then;

/// Create a copy of CalendarDue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? learners = null,Object? submitted = null,}) {
  return _then(_CalendarDue(
learners: null == learners ? _self.learners : learners // ignore: cast_nullable_to_non_nullable
as int,submitted: null == submitted ? _self.submitted : submitted // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CalendarRow {

 CalendarEvent get event; String? get courseTitle; String? get instructorName;@JsonKey(unknownEnumValue: LivePhase.unknown) LivePhase? get phase; CalendarDue? get due;
/// Create a copy of CalendarRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarRowCopyWith<CalendarRow> get copyWith => _$CalendarRowCopyWithImpl<CalendarRow>(this as CalendarRow, _$identity);

  /// Serializes this CalendarRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarRow&&(identical(other.event, event) || other.event == event)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.instructorName, instructorName) || other.instructorName == instructorName)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.due, due) || other.due == due));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,event,courseTitle,instructorName,phase,due);

@override
String toString() {
  return 'CalendarRow(event: $event, courseTitle: $courseTitle, instructorName: $instructorName, phase: $phase, due: $due)';
}


}

/// @nodoc
abstract mixin class $CalendarRowCopyWith<$Res>  {
  factory $CalendarRowCopyWith(CalendarRow value, $Res Function(CalendarRow) _then) = _$CalendarRowCopyWithImpl;
@useResult
$Res call({
 CalendarEvent event, String? courseTitle, String? instructorName,@JsonKey(unknownEnumValue: LivePhase.unknown) LivePhase? phase, CalendarDue? due
});


$CalendarEventCopyWith<$Res> get event;$CalendarDueCopyWith<$Res>? get due;

}
/// @nodoc
class _$CalendarRowCopyWithImpl<$Res>
    implements $CalendarRowCopyWith<$Res> {
  _$CalendarRowCopyWithImpl(this._self, this._then);

  final CalendarRow _self;
  final $Res Function(CalendarRow) _then;

/// Create a copy of CalendarRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? event = null,Object? courseTitle = freezed,Object? instructorName = freezed,Object? phase = freezed,Object? due = freezed,}) {
  return _then(_self.copyWith(
event: null == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as CalendarEvent,courseTitle: freezed == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String?,instructorName: freezed == instructorName ? _self.instructorName : instructorName // ignore: cast_nullable_to_non_nullable
as String?,phase: freezed == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as LivePhase?,due: freezed == due ? _self.due : due // ignore: cast_nullable_to_non_nullable
as CalendarDue?,
  ));
}
/// Create a copy of CalendarRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalendarEventCopyWith<$Res> get event {
  
  return $CalendarEventCopyWith<$Res>(_self.event, (value) {
    return _then(_self.copyWith(event: value));
  });
}/// Create a copy of CalendarRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalendarDueCopyWith<$Res>? get due {
    if (_self.due == null) {
    return null;
  }

  return $CalendarDueCopyWith<$Res>(_self.due!, (value) {
    return _then(_self.copyWith(due: value));
  });
}
}


/// Adds pattern-matching-related methods to [CalendarRow].
extension CalendarRowPatterns on CalendarRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarRow value)  $default,){
final _that = this;
switch (_that) {
case _CalendarRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarRow value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CalendarEvent event,  String? courseTitle,  String? instructorName, @JsonKey(unknownEnumValue: LivePhase.unknown)  LivePhase? phase,  CalendarDue? due)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarRow() when $default != null:
return $default(_that.event,_that.courseTitle,_that.instructorName,_that.phase,_that.due);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CalendarEvent event,  String? courseTitle,  String? instructorName, @JsonKey(unknownEnumValue: LivePhase.unknown)  LivePhase? phase,  CalendarDue? due)  $default,) {final _that = this;
switch (_that) {
case _CalendarRow():
return $default(_that.event,_that.courseTitle,_that.instructorName,_that.phase,_that.due);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CalendarEvent event,  String? courseTitle,  String? instructorName, @JsonKey(unknownEnumValue: LivePhase.unknown)  LivePhase? phase,  CalendarDue? due)?  $default,) {final _that = this;
switch (_that) {
case _CalendarRow() when $default != null:
return $default(_that.event,_that.courseTitle,_that.instructorName,_that.phase,_that.due);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarRow implements CalendarRow {
  const _CalendarRow({required this.event, this.courseTitle, this.instructorName, @JsonKey(unknownEnumValue: LivePhase.unknown) this.phase, this.due});
  factory _CalendarRow.fromJson(Map<String, dynamic> json) => _$CalendarRowFromJson(json);

@override final  CalendarEvent event;
@override final  String? courseTitle;
@override final  String? instructorName;
@override@JsonKey(unknownEnumValue: LivePhase.unknown) final  LivePhase? phase;
@override final  CalendarDue? due;

/// Create a copy of CalendarRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarRowCopyWith<_CalendarRow> get copyWith => __$CalendarRowCopyWithImpl<_CalendarRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarRow&&(identical(other.event, event) || other.event == event)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.instructorName, instructorName) || other.instructorName == instructorName)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.due, due) || other.due == due));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,event,courseTitle,instructorName,phase,due);

@override
String toString() {
  return 'CalendarRow(event: $event, courseTitle: $courseTitle, instructorName: $instructorName, phase: $phase, due: $due)';
}


}

/// @nodoc
abstract mixin class _$CalendarRowCopyWith<$Res> implements $CalendarRowCopyWith<$Res> {
  factory _$CalendarRowCopyWith(_CalendarRow value, $Res Function(_CalendarRow) _then) = __$CalendarRowCopyWithImpl;
@override @useResult
$Res call({
 CalendarEvent event, String? courseTitle, String? instructorName,@JsonKey(unknownEnumValue: LivePhase.unknown) LivePhase? phase, CalendarDue? due
});


@override $CalendarEventCopyWith<$Res> get event;@override $CalendarDueCopyWith<$Res>? get due;

}
/// @nodoc
class __$CalendarRowCopyWithImpl<$Res>
    implements _$CalendarRowCopyWith<$Res> {
  __$CalendarRowCopyWithImpl(this._self, this._then);

  final _CalendarRow _self;
  final $Res Function(_CalendarRow) _then;

/// Create a copy of CalendarRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? event = null,Object? courseTitle = freezed,Object? instructorName = freezed,Object? phase = freezed,Object? due = freezed,}) {
  return _then(_CalendarRow(
event: null == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as CalendarEvent,courseTitle: freezed == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String?,instructorName: freezed == instructorName ? _self.instructorName : instructorName // ignore: cast_nullable_to_non_nullable
as String?,phase: freezed == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as LivePhase?,due: freezed == due ? _self.due : due // ignore: cast_nullable_to_non_nullable
as CalendarDue?,
  ));
}

/// Create a copy of CalendarRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalendarEventCopyWith<$Res> get event {
  
  return $CalendarEventCopyWith<$Res>(_self.event, (value) {
    return _then(_self.copyWith(event: value));
  });
}/// Create a copy of CalendarRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalendarDueCopyWith<$Res>? get due {
    if (_self.due == null) {
    return null;
  }

  return $CalendarDueCopyWith<$Res>(_self.due!, (value) {
    return _then(_self.copyWith(due: value));
  });
}
}


/// @nodoc
mixin _$CalendarPage {

 List<CalendarRow> get rows; int get total; Map<String, int> get counts;
/// Create a copy of CalendarPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarPageCopyWith<CalendarPage> get copyWith => _$CalendarPageCopyWithImpl<CalendarPage>(this as CalendarPage, _$identity);

  /// Serializes this CalendarPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarPage&&const DeepCollectionEquality().equals(other.rows, rows)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.counts, counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rows),total,const DeepCollectionEquality().hash(counts));

@override
String toString() {
  return 'CalendarPage(rows: $rows, total: $total, counts: $counts)';
}


}

/// @nodoc
abstract mixin class $CalendarPageCopyWith<$Res>  {
  factory $CalendarPageCopyWith(CalendarPage value, $Res Function(CalendarPage) _then) = _$CalendarPageCopyWithImpl;
@useResult
$Res call({
 List<CalendarRow> rows, int total, Map<String, int> counts
});




}
/// @nodoc
class _$CalendarPageCopyWithImpl<$Res>
    implements $CalendarPageCopyWith<$Res> {
  _$CalendarPageCopyWithImpl(this._self, this._then);

  final CalendarPage _self;
  final $Res Function(CalendarPage) _then;

/// Create a copy of CalendarPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? total = null,Object? counts = null,}) {
  return _then(_self.copyWith(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<CalendarRow>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarPage].
extension CalendarPagePatterns on CalendarPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarPage value)  $default,){
final _that = this;
switch (_that) {
case _CalendarPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarPage value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CalendarRow> rows,  int total,  Map<String, int> counts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarPage() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CalendarRow> rows,  int total,  Map<String, int> counts)  $default,) {final _that = this;
switch (_that) {
case _CalendarPage():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CalendarRow> rows,  int total,  Map<String, int> counts)?  $default,) {final _that = this;
switch (_that) {
case _CalendarPage() when $default != null:
return $default(_that.rows,_that.total,_that.counts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarPage extends CalendarPage {
  const _CalendarPage({final  List<CalendarRow> rows = const <CalendarRow>[], this.total = 0, final  Map<String, int> counts = const <String, int>{}}): _rows = rows,_counts = counts,super._();
  factory _CalendarPage.fromJson(Map<String, dynamic> json) => _$CalendarPageFromJson(json);

 final  List<CalendarRow> _rows;
@override@JsonKey() List<CalendarRow> get rows {
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


/// Create a copy of CalendarPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarPageCopyWith<_CalendarPage> get copyWith => __$CalendarPageCopyWithImpl<_CalendarPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarPage&&const DeepCollectionEquality().equals(other._rows, _rows)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._counts, _counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows),total,const DeepCollectionEquality().hash(_counts));

@override
String toString() {
  return 'CalendarPage(rows: $rows, total: $total, counts: $counts)';
}


}

/// @nodoc
abstract mixin class _$CalendarPageCopyWith<$Res> implements $CalendarPageCopyWith<$Res> {
  factory _$CalendarPageCopyWith(_CalendarPage value, $Res Function(_CalendarPage) _then) = __$CalendarPageCopyWithImpl;
@override @useResult
$Res call({
 List<CalendarRow> rows, int total, Map<String, int> counts
});




}
/// @nodoc
class __$CalendarPageCopyWithImpl<$Res>
    implements _$CalendarPageCopyWith<$Res> {
  __$CalendarPageCopyWithImpl(this._self, this._then);

  final _CalendarPage _self;
  final $Res Function(_CalendarPage) _then;

/// Create a copy of CalendarPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,Object? total = null,Object? counts = null,}) {
  return _then(_CalendarPage(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<CalendarRow>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self._counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}


/// @nodoc
mixin _$LearnerDue {

 String get id; String get name; bool get submitted;
/// Create a copy of LearnerDue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearnerDueCopyWith<LearnerDue> get copyWith => _$LearnerDueCopyWithImpl<LearnerDue>(this as LearnerDue, _$identity);

  /// Serializes this LearnerDue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearnerDue&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.submitted, submitted) || other.submitted == submitted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,submitted);

@override
String toString() {
  return 'LearnerDue(id: $id, name: $name, submitted: $submitted)';
}


}

/// @nodoc
abstract mixin class $LearnerDueCopyWith<$Res>  {
  factory $LearnerDueCopyWith(LearnerDue value, $Res Function(LearnerDue) _then) = _$LearnerDueCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool submitted
});




}
/// @nodoc
class _$LearnerDueCopyWithImpl<$Res>
    implements $LearnerDueCopyWith<$Res> {
  _$LearnerDueCopyWithImpl(this._self, this._then);

  final LearnerDue _self;
  final $Res Function(LearnerDue) _then;

/// Create a copy of LearnerDue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? submitted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,submitted: null == submitted ? _self.submitted : submitted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LearnerDue].
extension LearnerDuePatterns on LearnerDue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearnerDue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearnerDue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearnerDue value)  $default,){
final _that = this;
switch (_that) {
case _LearnerDue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearnerDue value)?  $default,){
final _that = this;
switch (_that) {
case _LearnerDue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  bool submitted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearnerDue() when $default != null:
return $default(_that.id,_that.name,_that.submitted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  bool submitted)  $default,) {final _that = this;
switch (_that) {
case _LearnerDue():
return $default(_that.id,_that.name,_that.submitted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  bool submitted)?  $default,) {final _that = this;
switch (_that) {
case _LearnerDue() when $default != null:
return $default(_that.id,_that.name,_that.submitted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LearnerDue implements LearnerDue {
  const _LearnerDue({this.id = '', this.name = '', this.submitted = false});
  factory _LearnerDue.fromJson(Map<String, dynamic> json) => _$LearnerDueFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  bool submitted;

/// Create a copy of LearnerDue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearnerDueCopyWith<_LearnerDue> get copyWith => __$LearnerDueCopyWithImpl<_LearnerDue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearnerDueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearnerDue&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.submitted, submitted) || other.submitted == submitted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,submitted);

@override
String toString() {
  return 'LearnerDue(id: $id, name: $name, submitted: $submitted)';
}


}

/// @nodoc
abstract mixin class _$LearnerDueCopyWith<$Res> implements $LearnerDueCopyWith<$Res> {
  factory _$LearnerDueCopyWith(_LearnerDue value, $Res Function(_LearnerDue) _then) = __$LearnerDueCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool submitted
});




}
/// @nodoc
class __$LearnerDueCopyWithImpl<$Res>
    implements _$LearnerDueCopyWith<$Res> {
  __$LearnerDueCopyWithImpl(this._self, this._then);

  final _LearnerDue _self;
  final $Res Function(_LearnerDue) _then;

/// Create a copy of LearnerDue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? submitted = null,}) {
  return _then(_LearnerDue(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,submitted: null == submitted ? _self.submitted : submitted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$CalendarLiveFacts {

 int get registered; int? get capacity; int? get attended;
/// Create a copy of CalendarLiveFacts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarLiveFactsCopyWith<CalendarLiveFacts> get copyWith => _$CalendarLiveFactsCopyWithImpl<CalendarLiveFacts>(this as CalendarLiveFacts, _$identity);

  /// Serializes this CalendarLiveFacts to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarLiveFacts&&(identical(other.registered, registered) || other.registered == registered)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.attended, attended) || other.attended == attended));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,registered,capacity,attended);

@override
String toString() {
  return 'CalendarLiveFacts(registered: $registered, capacity: $capacity, attended: $attended)';
}


}

/// @nodoc
abstract mixin class $CalendarLiveFactsCopyWith<$Res>  {
  factory $CalendarLiveFactsCopyWith(CalendarLiveFacts value, $Res Function(CalendarLiveFacts) _then) = _$CalendarLiveFactsCopyWithImpl;
@useResult
$Res call({
 int registered, int? capacity, int? attended
});




}
/// @nodoc
class _$CalendarLiveFactsCopyWithImpl<$Res>
    implements $CalendarLiveFactsCopyWith<$Res> {
  _$CalendarLiveFactsCopyWithImpl(this._self, this._then);

  final CalendarLiveFacts _self;
  final $Res Function(CalendarLiveFacts) _then;

/// Create a copy of CalendarLiveFacts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? registered = null,Object? capacity = freezed,Object? attended = freezed,}) {
  return _then(_self.copyWith(
registered: null == registered ? _self.registered : registered // ignore: cast_nullable_to_non_nullable
as int,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,attended: freezed == attended ? _self.attended : attended // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarLiveFacts].
extension CalendarLiveFactsPatterns on CalendarLiveFacts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarLiveFacts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarLiveFacts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarLiveFacts value)  $default,){
final _that = this;
switch (_that) {
case _CalendarLiveFacts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarLiveFacts value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarLiveFacts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int registered,  int? capacity,  int? attended)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarLiveFacts() when $default != null:
return $default(_that.registered,_that.capacity,_that.attended);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int registered,  int? capacity,  int? attended)  $default,) {final _that = this;
switch (_that) {
case _CalendarLiveFacts():
return $default(_that.registered,_that.capacity,_that.attended);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int registered,  int? capacity,  int? attended)?  $default,) {final _that = this;
switch (_that) {
case _CalendarLiveFacts() when $default != null:
return $default(_that.registered,_that.capacity,_that.attended);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarLiveFacts implements CalendarLiveFacts {
  const _CalendarLiveFacts({this.registered = 0, this.capacity, this.attended});
  factory _CalendarLiveFacts.fromJson(Map<String, dynamic> json) => _$CalendarLiveFactsFromJson(json);

@override@JsonKey() final  int registered;
@override final  int? capacity;
@override final  int? attended;

/// Create a copy of CalendarLiveFacts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarLiveFactsCopyWith<_CalendarLiveFacts> get copyWith => __$CalendarLiveFactsCopyWithImpl<_CalendarLiveFacts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarLiveFactsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarLiveFacts&&(identical(other.registered, registered) || other.registered == registered)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.attended, attended) || other.attended == attended));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,registered,capacity,attended);

@override
String toString() {
  return 'CalendarLiveFacts(registered: $registered, capacity: $capacity, attended: $attended)';
}


}

/// @nodoc
abstract mixin class _$CalendarLiveFactsCopyWith<$Res> implements $CalendarLiveFactsCopyWith<$Res> {
  factory _$CalendarLiveFactsCopyWith(_CalendarLiveFacts value, $Res Function(_CalendarLiveFacts) _then) = __$CalendarLiveFactsCopyWithImpl;
@override @useResult
$Res call({
 int registered, int? capacity, int? attended
});




}
/// @nodoc
class __$CalendarLiveFactsCopyWithImpl<$Res>
    implements _$CalendarLiveFactsCopyWith<$Res> {
  __$CalendarLiveFactsCopyWithImpl(this._self, this._then);

  final _CalendarLiveFacts _self;
  final $Res Function(_CalendarLiveFacts) _then;

/// Create a copy of CalendarLiveFacts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? registered = null,Object? capacity = freezed,Object? attended = freezed,}) {
  return _then(_CalendarLiveFacts(
registered: null == registered ? _self.registered : registered // ignore: cast_nullable_to_non_nullable
as int,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,attended: freezed == attended ? _self.attended : attended // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$CalendarQuizFacts {

 String get id; String get title; String get status; int get questions; int? get timeLimitMin; int? get attempts; int? get passMark;
/// Create a copy of CalendarQuizFacts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarQuizFactsCopyWith<CalendarQuizFacts> get copyWith => _$CalendarQuizFactsCopyWithImpl<CalendarQuizFacts>(this as CalendarQuizFacts, _$identity);

  /// Serializes this CalendarQuizFacts to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarQuizFacts&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.questions, questions) || other.questions == questions)&&(identical(other.timeLimitMin, timeLimitMin) || other.timeLimitMin == timeLimitMin)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.passMark, passMark) || other.passMark == passMark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,status,questions,timeLimitMin,attempts,passMark);

@override
String toString() {
  return 'CalendarQuizFacts(id: $id, title: $title, status: $status, questions: $questions, timeLimitMin: $timeLimitMin, attempts: $attempts, passMark: $passMark)';
}


}

/// @nodoc
abstract mixin class $CalendarQuizFactsCopyWith<$Res>  {
  factory $CalendarQuizFactsCopyWith(CalendarQuizFacts value, $Res Function(CalendarQuizFacts) _then) = _$CalendarQuizFactsCopyWithImpl;
@useResult
$Res call({
 String id, String title, String status, int questions, int? timeLimitMin, int? attempts, int? passMark
});




}
/// @nodoc
class _$CalendarQuizFactsCopyWithImpl<$Res>
    implements $CalendarQuizFactsCopyWith<$Res> {
  _$CalendarQuizFactsCopyWithImpl(this._self, this._then);

  final CalendarQuizFacts _self;
  final $Res Function(CalendarQuizFacts) _then;

/// Create a copy of CalendarQuizFacts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? status = null,Object? questions = null,Object? timeLimitMin = freezed,Object? attempts = freezed,Object? passMark = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as int,timeLimitMin: freezed == timeLimitMin ? _self.timeLimitMin : timeLimitMin // ignore: cast_nullable_to_non_nullable
as int?,attempts: freezed == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int?,passMark: freezed == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarQuizFacts].
extension CalendarQuizFactsPatterns on CalendarQuizFacts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarQuizFacts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarQuizFacts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarQuizFacts value)  $default,){
final _that = this;
switch (_that) {
case _CalendarQuizFacts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarQuizFacts value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarQuizFacts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String status,  int questions,  int? timeLimitMin,  int? attempts,  int? passMark)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarQuizFacts() when $default != null:
return $default(_that.id,_that.title,_that.status,_that.questions,_that.timeLimitMin,_that.attempts,_that.passMark);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String status,  int questions,  int? timeLimitMin,  int? attempts,  int? passMark)  $default,) {final _that = this;
switch (_that) {
case _CalendarQuizFacts():
return $default(_that.id,_that.title,_that.status,_that.questions,_that.timeLimitMin,_that.attempts,_that.passMark);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String status,  int questions,  int? timeLimitMin,  int? attempts,  int? passMark)?  $default,) {final _that = this;
switch (_that) {
case _CalendarQuizFacts() when $default != null:
return $default(_that.id,_that.title,_that.status,_that.questions,_that.timeLimitMin,_that.attempts,_that.passMark);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarQuizFacts implements CalendarQuizFacts {
  const _CalendarQuizFacts({this.id = '', this.title = '', this.status = '', this.questions = 0, this.timeLimitMin, this.attempts, this.passMark});
  factory _CalendarQuizFacts.fromJson(Map<String, dynamic> json) => _$CalendarQuizFactsFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String title;
@override@JsonKey() final  String status;
@override@JsonKey() final  int questions;
@override final  int? timeLimitMin;
@override final  int? attempts;
@override final  int? passMark;

/// Create a copy of CalendarQuizFacts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarQuizFactsCopyWith<_CalendarQuizFacts> get copyWith => __$CalendarQuizFactsCopyWithImpl<_CalendarQuizFacts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarQuizFactsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarQuizFacts&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.questions, questions) || other.questions == questions)&&(identical(other.timeLimitMin, timeLimitMin) || other.timeLimitMin == timeLimitMin)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.passMark, passMark) || other.passMark == passMark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,status,questions,timeLimitMin,attempts,passMark);

@override
String toString() {
  return 'CalendarQuizFacts(id: $id, title: $title, status: $status, questions: $questions, timeLimitMin: $timeLimitMin, attempts: $attempts, passMark: $passMark)';
}


}

/// @nodoc
abstract mixin class _$CalendarQuizFactsCopyWith<$Res> implements $CalendarQuizFactsCopyWith<$Res> {
  factory _$CalendarQuizFactsCopyWith(_CalendarQuizFacts value, $Res Function(_CalendarQuizFacts) _then) = __$CalendarQuizFactsCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String status, int questions, int? timeLimitMin, int? attempts, int? passMark
});




}
/// @nodoc
class __$CalendarQuizFactsCopyWithImpl<$Res>
    implements _$CalendarQuizFactsCopyWith<$Res> {
  __$CalendarQuizFactsCopyWithImpl(this._self, this._then);

  final _CalendarQuizFacts _self;
  final $Res Function(_CalendarQuizFacts) _then;

/// Create a copy of CalendarQuizFacts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? status = null,Object? questions = null,Object? timeLimitMin = freezed,Object? attempts = freezed,Object? passMark = freezed,}) {
  return _then(_CalendarQuizFacts(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as int,timeLimitMin: freezed == timeLimitMin ? _self.timeLimitMin : timeLimitMin // ignore: cast_nullable_to_non_nullable
as int?,attempts: freezed == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int?,passMark: freezed == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$CalendarDetail {

 CalendarEvent get event; String? get courseTitle; String? get chapterTitle; String? get instructorName; String? get instructorTitle;@JsonKey(unknownEnumValue: LivePhase.unknown) LivePhase? get phase;/// Whether the **academy** will take a change to it. A derived event never is.
 bool get editable; CalendarLiveFacts? get live; CalendarDue? get due; List<LearnerDue> get learnersDue; CalendarQuizFacts? get quiz;/// How many learners the event reaches, where the academy counts them.
 int? get audienceSize;
/// Create a copy of CalendarDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarDetailCopyWith<CalendarDetail> get copyWith => _$CalendarDetailCopyWithImpl<CalendarDetail>(this as CalendarDetail, _$identity);

  /// Serializes this CalendarDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarDetail&&(identical(other.event, event) || other.event == event)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.instructorName, instructorName) || other.instructorName == instructorName)&&(identical(other.instructorTitle, instructorTitle) || other.instructorTitle == instructorTitle)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.editable, editable) || other.editable == editable)&&(identical(other.live, live) || other.live == live)&&(identical(other.due, due) || other.due == due)&&const DeepCollectionEquality().equals(other.learnersDue, learnersDue)&&(identical(other.quiz, quiz) || other.quiz == quiz)&&(identical(other.audienceSize, audienceSize) || other.audienceSize == audienceSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,event,courseTitle,chapterTitle,instructorName,instructorTitle,phase,editable,live,due,const DeepCollectionEquality().hash(learnersDue),quiz,audienceSize);

@override
String toString() {
  return 'CalendarDetail(event: $event, courseTitle: $courseTitle, chapterTitle: $chapterTitle, instructorName: $instructorName, instructorTitle: $instructorTitle, phase: $phase, editable: $editable, live: $live, due: $due, learnersDue: $learnersDue, quiz: $quiz, audienceSize: $audienceSize)';
}


}

/// @nodoc
abstract mixin class $CalendarDetailCopyWith<$Res>  {
  factory $CalendarDetailCopyWith(CalendarDetail value, $Res Function(CalendarDetail) _then) = _$CalendarDetailCopyWithImpl;
@useResult
$Res call({
 CalendarEvent event, String? courseTitle, String? chapterTitle, String? instructorName, String? instructorTitle,@JsonKey(unknownEnumValue: LivePhase.unknown) LivePhase? phase, bool editable, CalendarLiveFacts? live, CalendarDue? due, List<LearnerDue> learnersDue, CalendarQuizFacts? quiz, int? audienceSize
});


$CalendarEventCopyWith<$Res> get event;$CalendarLiveFactsCopyWith<$Res>? get live;$CalendarDueCopyWith<$Res>? get due;$CalendarQuizFactsCopyWith<$Res>? get quiz;

}
/// @nodoc
class _$CalendarDetailCopyWithImpl<$Res>
    implements $CalendarDetailCopyWith<$Res> {
  _$CalendarDetailCopyWithImpl(this._self, this._then);

  final CalendarDetail _self;
  final $Res Function(CalendarDetail) _then;

/// Create a copy of CalendarDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? event = null,Object? courseTitle = freezed,Object? chapterTitle = freezed,Object? instructorName = freezed,Object? instructorTitle = freezed,Object? phase = freezed,Object? editable = null,Object? live = freezed,Object? due = freezed,Object? learnersDue = null,Object? quiz = freezed,Object? audienceSize = freezed,}) {
  return _then(_self.copyWith(
event: null == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as CalendarEvent,courseTitle: freezed == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String?,chapterTitle: freezed == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String?,instructorName: freezed == instructorName ? _self.instructorName : instructorName // ignore: cast_nullable_to_non_nullable
as String?,instructorTitle: freezed == instructorTitle ? _self.instructorTitle : instructorTitle // ignore: cast_nullable_to_non_nullable
as String?,phase: freezed == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as LivePhase?,editable: null == editable ? _self.editable : editable // ignore: cast_nullable_to_non_nullable
as bool,live: freezed == live ? _self.live : live // ignore: cast_nullable_to_non_nullable
as CalendarLiveFacts?,due: freezed == due ? _self.due : due // ignore: cast_nullable_to_non_nullable
as CalendarDue?,learnersDue: null == learnersDue ? _self.learnersDue : learnersDue // ignore: cast_nullable_to_non_nullable
as List<LearnerDue>,quiz: freezed == quiz ? _self.quiz : quiz // ignore: cast_nullable_to_non_nullable
as CalendarQuizFacts?,audienceSize: freezed == audienceSize ? _self.audienceSize : audienceSize // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of CalendarDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalendarEventCopyWith<$Res> get event {
  
  return $CalendarEventCopyWith<$Res>(_self.event, (value) {
    return _then(_self.copyWith(event: value));
  });
}/// Create a copy of CalendarDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalendarLiveFactsCopyWith<$Res>? get live {
    if (_self.live == null) {
    return null;
  }

  return $CalendarLiveFactsCopyWith<$Res>(_self.live!, (value) {
    return _then(_self.copyWith(live: value));
  });
}/// Create a copy of CalendarDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalendarDueCopyWith<$Res>? get due {
    if (_self.due == null) {
    return null;
  }

  return $CalendarDueCopyWith<$Res>(_self.due!, (value) {
    return _then(_self.copyWith(due: value));
  });
}/// Create a copy of CalendarDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalendarQuizFactsCopyWith<$Res>? get quiz {
    if (_self.quiz == null) {
    return null;
  }

  return $CalendarQuizFactsCopyWith<$Res>(_self.quiz!, (value) {
    return _then(_self.copyWith(quiz: value));
  });
}
}


/// Adds pattern-matching-related methods to [CalendarDetail].
extension CalendarDetailPatterns on CalendarDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarDetail value)  $default,){
final _that = this;
switch (_that) {
case _CalendarDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarDetail value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CalendarEvent event,  String? courseTitle,  String? chapterTitle,  String? instructorName,  String? instructorTitle, @JsonKey(unknownEnumValue: LivePhase.unknown)  LivePhase? phase,  bool editable,  CalendarLiveFacts? live,  CalendarDue? due,  List<LearnerDue> learnersDue,  CalendarQuizFacts? quiz,  int? audienceSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarDetail() when $default != null:
return $default(_that.event,_that.courseTitle,_that.chapterTitle,_that.instructorName,_that.instructorTitle,_that.phase,_that.editable,_that.live,_that.due,_that.learnersDue,_that.quiz,_that.audienceSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CalendarEvent event,  String? courseTitle,  String? chapterTitle,  String? instructorName,  String? instructorTitle, @JsonKey(unknownEnumValue: LivePhase.unknown)  LivePhase? phase,  bool editable,  CalendarLiveFacts? live,  CalendarDue? due,  List<LearnerDue> learnersDue,  CalendarQuizFacts? quiz,  int? audienceSize)  $default,) {final _that = this;
switch (_that) {
case _CalendarDetail():
return $default(_that.event,_that.courseTitle,_that.chapterTitle,_that.instructorName,_that.instructorTitle,_that.phase,_that.editable,_that.live,_that.due,_that.learnersDue,_that.quiz,_that.audienceSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CalendarEvent event,  String? courseTitle,  String? chapterTitle,  String? instructorName,  String? instructorTitle, @JsonKey(unknownEnumValue: LivePhase.unknown)  LivePhase? phase,  bool editable,  CalendarLiveFacts? live,  CalendarDue? due,  List<LearnerDue> learnersDue,  CalendarQuizFacts? quiz,  int? audienceSize)?  $default,) {final _that = this;
switch (_that) {
case _CalendarDetail() when $default != null:
return $default(_that.event,_that.courseTitle,_that.chapterTitle,_that.instructorName,_that.instructorTitle,_that.phase,_that.editable,_that.live,_that.due,_that.learnersDue,_that.quiz,_that.audienceSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarDetail implements CalendarDetail {
  const _CalendarDetail({required this.event, this.courseTitle, this.chapterTitle, this.instructorName, this.instructorTitle, @JsonKey(unknownEnumValue: LivePhase.unknown) this.phase, this.editable = false, this.live, this.due, final  List<LearnerDue> learnersDue = const <LearnerDue>[], this.quiz, this.audienceSize}): _learnersDue = learnersDue;
  factory _CalendarDetail.fromJson(Map<String, dynamic> json) => _$CalendarDetailFromJson(json);

@override final  CalendarEvent event;
@override final  String? courseTitle;
@override final  String? chapterTitle;
@override final  String? instructorName;
@override final  String? instructorTitle;
@override@JsonKey(unknownEnumValue: LivePhase.unknown) final  LivePhase? phase;
/// Whether the **academy** will take a change to it. A derived event never is.
@override@JsonKey() final  bool editable;
@override final  CalendarLiveFacts? live;
@override final  CalendarDue? due;
 final  List<LearnerDue> _learnersDue;
@override@JsonKey() List<LearnerDue> get learnersDue {
  if (_learnersDue is EqualUnmodifiableListView) return _learnersDue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_learnersDue);
}

@override final  CalendarQuizFacts? quiz;
/// How many learners the event reaches, where the academy counts them.
@override final  int? audienceSize;

/// Create a copy of CalendarDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarDetailCopyWith<_CalendarDetail> get copyWith => __$CalendarDetailCopyWithImpl<_CalendarDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarDetail&&(identical(other.event, event) || other.event == event)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.instructorName, instructorName) || other.instructorName == instructorName)&&(identical(other.instructorTitle, instructorTitle) || other.instructorTitle == instructorTitle)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.editable, editable) || other.editable == editable)&&(identical(other.live, live) || other.live == live)&&(identical(other.due, due) || other.due == due)&&const DeepCollectionEquality().equals(other._learnersDue, _learnersDue)&&(identical(other.quiz, quiz) || other.quiz == quiz)&&(identical(other.audienceSize, audienceSize) || other.audienceSize == audienceSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,event,courseTitle,chapterTitle,instructorName,instructorTitle,phase,editable,live,due,const DeepCollectionEquality().hash(_learnersDue),quiz,audienceSize);

@override
String toString() {
  return 'CalendarDetail(event: $event, courseTitle: $courseTitle, chapterTitle: $chapterTitle, instructorName: $instructorName, instructorTitle: $instructorTitle, phase: $phase, editable: $editable, live: $live, due: $due, learnersDue: $learnersDue, quiz: $quiz, audienceSize: $audienceSize)';
}


}

/// @nodoc
abstract mixin class _$CalendarDetailCopyWith<$Res> implements $CalendarDetailCopyWith<$Res> {
  factory _$CalendarDetailCopyWith(_CalendarDetail value, $Res Function(_CalendarDetail) _then) = __$CalendarDetailCopyWithImpl;
@override @useResult
$Res call({
 CalendarEvent event, String? courseTitle, String? chapterTitle, String? instructorName, String? instructorTitle,@JsonKey(unknownEnumValue: LivePhase.unknown) LivePhase? phase, bool editable, CalendarLiveFacts? live, CalendarDue? due, List<LearnerDue> learnersDue, CalendarQuizFacts? quiz, int? audienceSize
});


@override $CalendarEventCopyWith<$Res> get event;@override $CalendarLiveFactsCopyWith<$Res>? get live;@override $CalendarDueCopyWith<$Res>? get due;@override $CalendarQuizFactsCopyWith<$Res>? get quiz;

}
/// @nodoc
class __$CalendarDetailCopyWithImpl<$Res>
    implements _$CalendarDetailCopyWith<$Res> {
  __$CalendarDetailCopyWithImpl(this._self, this._then);

  final _CalendarDetail _self;
  final $Res Function(_CalendarDetail) _then;

/// Create a copy of CalendarDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? event = null,Object? courseTitle = freezed,Object? chapterTitle = freezed,Object? instructorName = freezed,Object? instructorTitle = freezed,Object? phase = freezed,Object? editable = null,Object? live = freezed,Object? due = freezed,Object? learnersDue = null,Object? quiz = freezed,Object? audienceSize = freezed,}) {
  return _then(_CalendarDetail(
event: null == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as CalendarEvent,courseTitle: freezed == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String?,chapterTitle: freezed == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String?,instructorName: freezed == instructorName ? _self.instructorName : instructorName // ignore: cast_nullable_to_non_nullable
as String?,instructorTitle: freezed == instructorTitle ? _self.instructorTitle : instructorTitle // ignore: cast_nullable_to_non_nullable
as String?,phase: freezed == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as LivePhase?,editable: null == editable ? _self.editable : editable // ignore: cast_nullable_to_non_nullable
as bool,live: freezed == live ? _self.live : live // ignore: cast_nullable_to_non_nullable
as CalendarLiveFacts?,due: freezed == due ? _self.due : due // ignore: cast_nullable_to_non_nullable
as CalendarDue?,learnersDue: null == learnersDue ? _self._learnersDue : learnersDue // ignore: cast_nullable_to_non_nullable
as List<LearnerDue>,quiz: freezed == quiz ? _self.quiz : quiz // ignore: cast_nullable_to_non_nullable
as CalendarQuizFacts?,audienceSize: freezed == audienceSize ? _self.audienceSize : audienceSize // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of CalendarDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalendarEventCopyWith<$Res> get event {
  
  return $CalendarEventCopyWith<$Res>(_self.event, (value) {
    return _then(_self.copyWith(event: value));
  });
}/// Create a copy of CalendarDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalendarLiveFactsCopyWith<$Res>? get live {
    if (_self.live == null) {
    return null;
  }

  return $CalendarLiveFactsCopyWith<$Res>(_self.live!, (value) {
    return _then(_self.copyWith(live: value));
  });
}/// Create a copy of CalendarDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalendarDueCopyWith<$Res>? get due {
    if (_self.due == null) {
    return null;
  }

  return $CalendarDueCopyWith<$Res>(_self.due!, (value) {
    return _then(_self.copyWith(due: value));
  });
}/// Create a copy of CalendarDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CalendarQuizFactsCopyWith<$Res>? get quiz {
    if (_self.quiz == null) {
    return null;
  }

  return $CalendarQuizFactsCopyWith<$Res>(_self.quiz!, (value) {
    return _then(_self.copyWith(quiz: value));
  });
}
}

/// @nodoc
mixin _$CalendarEventForm {

 CalendarEventType get type; String get title; String get description; CalendarTiming get timing; DateTime? get startsAt; int get durationMin; String? get courseId; String? get chapterId; String? get quizId; MilestoneKind? get milestone; ReminderAudience get audience; int? get notifyMin;
/// Create a copy of CalendarEventForm
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarEventFormCopyWith<CalendarEventForm> get copyWith => _$CalendarEventFormCopyWithImpl<CalendarEventForm>(this as CalendarEventForm, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarEventForm&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.timing, timing) || other.timing == timing)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.quizId, quizId) || other.quizId == quizId)&&(identical(other.milestone, milestone) || other.milestone == milestone)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.notifyMin, notifyMin) || other.notifyMin == notifyMin));
}


@override
int get hashCode => Object.hash(runtimeType,type,title,description,timing,startsAt,durationMin,courseId,chapterId,quizId,milestone,audience,notifyMin);

@override
String toString() {
  return 'CalendarEventForm(type: $type, title: $title, description: $description, timing: $timing, startsAt: $startsAt, durationMin: $durationMin, courseId: $courseId, chapterId: $chapterId, quizId: $quizId, milestone: $milestone, audience: $audience, notifyMin: $notifyMin)';
}


}

/// @nodoc
abstract mixin class $CalendarEventFormCopyWith<$Res>  {
  factory $CalendarEventFormCopyWith(CalendarEventForm value, $Res Function(CalendarEventForm) _then) = _$CalendarEventFormCopyWithImpl;
@useResult
$Res call({
 CalendarEventType type, String title, String description, CalendarTiming timing, DateTime? startsAt, int durationMin, String? courseId, String? chapterId, String? quizId, MilestoneKind? milestone, ReminderAudience audience, int? notifyMin
});




}
/// @nodoc
class _$CalendarEventFormCopyWithImpl<$Res>
    implements $CalendarEventFormCopyWith<$Res> {
  _$CalendarEventFormCopyWithImpl(this._self, this._then);

  final CalendarEventForm _self;
  final $Res Function(CalendarEventForm) _then;

/// Create a copy of CalendarEventForm
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? title = null,Object? description = null,Object? timing = null,Object? startsAt = freezed,Object? durationMin = null,Object? courseId = freezed,Object? chapterId = freezed,Object? quizId = freezed,Object? milestone = freezed,Object? audience = null,Object? notifyMin = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CalendarEventType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,timing: null == timing ? _self.timing : timing // ignore: cast_nullable_to_non_nullable
as CalendarTiming,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,durationMin: null == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int,courseId: freezed == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String?,chapterId: freezed == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String?,quizId: freezed == quizId ? _self.quizId : quizId // ignore: cast_nullable_to_non_nullable
as String?,milestone: freezed == milestone ? _self.milestone : milestone // ignore: cast_nullable_to_non_nullable
as MilestoneKind?,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as ReminderAudience,notifyMin: freezed == notifyMin ? _self.notifyMin : notifyMin // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarEventForm].
extension CalendarEventFormPatterns on CalendarEventForm {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarEventForm value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarEventForm() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarEventForm value)  $default,){
final _that = this;
switch (_that) {
case _CalendarEventForm():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarEventForm value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarEventForm() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CalendarEventType type,  String title,  String description,  CalendarTiming timing,  DateTime? startsAt,  int durationMin,  String? courseId,  String? chapterId,  String? quizId,  MilestoneKind? milestone,  ReminderAudience audience,  int? notifyMin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarEventForm() when $default != null:
return $default(_that.type,_that.title,_that.description,_that.timing,_that.startsAt,_that.durationMin,_that.courseId,_that.chapterId,_that.quizId,_that.milestone,_that.audience,_that.notifyMin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CalendarEventType type,  String title,  String description,  CalendarTiming timing,  DateTime? startsAt,  int durationMin,  String? courseId,  String? chapterId,  String? quizId,  MilestoneKind? milestone,  ReminderAudience audience,  int? notifyMin)  $default,) {final _that = this;
switch (_that) {
case _CalendarEventForm():
return $default(_that.type,_that.title,_that.description,_that.timing,_that.startsAt,_that.durationMin,_that.courseId,_that.chapterId,_that.quizId,_that.milestone,_that.audience,_that.notifyMin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CalendarEventType type,  String title,  String description,  CalendarTiming timing,  DateTime? startsAt,  int durationMin,  String? courseId,  String? chapterId,  String? quizId,  MilestoneKind? milestone,  ReminderAudience audience,  int? notifyMin)?  $default,) {final _that = this;
switch (_that) {
case _CalendarEventForm() when $default != null:
return $default(_that.type,_that.title,_that.description,_that.timing,_that.startsAt,_that.durationMin,_that.courseId,_that.chapterId,_that.quizId,_that.milestone,_that.audience,_that.notifyMin);case _:
  return null;

}
}

}

/// @nodoc


class _CalendarEventForm extends CalendarEventForm {
  const _CalendarEventForm({this.type = CalendarEventType.reminder, this.title = '', this.description = '', this.timing = CalendarTiming.timed, this.startsAt, this.durationMin = 30, this.courseId, this.chapterId, this.quizId, this.milestone, this.audience = ReminderAudience.me, this.notifyMin}): super._();
  

@override@JsonKey() final  CalendarEventType type;
@override@JsonKey() final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  CalendarTiming timing;
@override final  DateTime? startsAt;
@override@JsonKey() final  int durationMin;
@override final  String? courseId;
@override final  String? chapterId;
@override final  String? quizId;
@override final  MilestoneKind? milestone;
@override@JsonKey() final  ReminderAudience audience;
@override final  int? notifyMin;

/// Create a copy of CalendarEventForm
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarEventFormCopyWith<_CalendarEventForm> get copyWith => __$CalendarEventFormCopyWithImpl<_CalendarEventForm>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarEventForm&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.timing, timing) || other.timing == timing)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.quizId, quizId) || other.quizId == quizId)&&(identical(other.milestone, milestone) || other.milestone == milestone)&&(identical(other.audience, audience) || other.audience == audience)&&(identical(other.notifyMin, notifyMin) || other.notifyMin == notifyMin));
}


@override
int get hashCode => Object.hash(runtimeType,type,title,description,timing,startsAt,durationMin,courseId,chapterId,quizId,milestone,audience,notifyMin);

@override
String toString() {
  return 'CalendarEventForm(type: $type, title: $title, description: $description, timing: $timing, startsAt: $startsAt, durationMin: $durationMin, courseId: $courseId, chapterId: $chapterId, quizId: $quizId, milestone: $milestone, audience: $audience, notifyMin: $notifyMin)';
}


}

/// @nodoc
abstract mixin class _$CalendarEventFormCopyWith<$Res> implements $CalendarEventFormCopyWith<$Res> {
  factory _$CalendarEventFormCopyWith(_CalendarEventForm value, $Res Function(_CalendarEventForm) _then) = __$CalendarEventFormCopyWithImpl;
@override @useResult
$Res call({
 CalendarEventType type, String title, String description, CalendarTiming timing, DateTime? startsAt, int durationMin, String? courseId, String? chapterId, String? quizId, MilestoneKind? milestone, ReminderAudience audience, int? notifyMin
});




}
/// @nodoc
class __$CalendarEventFormCopyWithImpl<$Res>
    implements _$CalendarEventFormCopyWith<$Res> {
  __$CalendarEventFormCopyWithImpl(this._self, this._then);

  final _CalendarEventForm _self;
  final $Res Function(_CalendarEventForm) _then;

/// Create a copy of CalendarEventForm
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? title = null,Object? description = null,Object? timing = null,Object? startsAt = freezed,Object? durationMin = null,Object? courseId = freezed,Object? chapterId = freezed,Object? quizId = freezed,Object? milestone = freezed,Object? audience = null,Object? notifyMin = freezed,}) {
  return _then(_CalendarEventForm(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CalendarEventType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,timing: null == timing ? _self.timing : timing // ignore: cast_nullable_to_non_nullable
as CalendarTiming,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,durationMin: null == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int,courseId: freezed == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String?,chapterId: freezed == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String?,quizId: freezed == quizId ? _self.quizId : quizId // ignore: cast_nullable_to_non_nullable
as String?,milestone: freezed == milestone ? _self.milestone : milestone // ignore: cast_nullable_to_non_nullable
as MilestoneKind?,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as ReminderAudience,notifyMin: freezed == notifyMin ? _self.notifyMin : notifyMin // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
