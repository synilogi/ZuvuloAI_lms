// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_class.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AgendaItem {

 String get title; int get minutes;
/// Create a copy of AgendaItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgendaItemCopyWith<AgendaItem> get copyWith => _$AgendaItemCopyWithImpl<AgendaItem>(this as AgendaItem, _$identity);

  /// Serializes this AgendaItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgendaItem&&(identical(other.title, title) || other.title == title)&&(identical(other.minutes, minutes) || other.minutes == minutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,minutes);

@override
String toString() {
  return 'AgendaItem(title: $title, minutes: $minutes)';
}


}

/// @nodoc
abstract mixin class $AgendaItemCopyWith<$Res>  {
  factory $AgendaItemCopyWith(AgendaItem value, $Res Function(AgendaItem) _then) = _$AgendaItemCopyWithImpl;
@useResult
$Res call({
 String title, int minutes
});




}
/// @nodoc
class _$AgendaItemCopyWithImpl<$Res>
    implements $AgendaItemCopyWith<$Res> {
  _$AgendaItemCopyWithImpl(this._self, this._then);

  final AgendaItem _self;
  final $Res Function(AgendaItem) _then;

/// Create a copy of AgendaItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? minutes = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AgendaItem].
extension AgendaItemPatterns on AgendaItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgendaItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgendaItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgendaItem value)  $default,){
final _that = this;
switch (_that) {
case _AgendaItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgendaItem value)?  $default,){
final _that = this;
switch (_that) {
case _AgendaItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  int minutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgendaItem() when $default != null:
return $default(_that.title,_that.minutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  int minutes)  $default,) {final _that = this;
switch (_that) {
case _AgendaItem():
return $default(_that.title,_that.minutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  int minutes)?  $default,) {final _that = this;
switch (_that) {
case _AgendaItem() when $default != null:
return $default(_that.title,_that.minutes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgendaItem implements AgendaItem {
  const _AgendaItem({this.title = '', this.minutes = 0});
  factory _AgendaItem.fromJson(Map<String, dynamic> json) => _$AgendaItemFromJson(json);

@override@JsonKey() final  String title;
@override@JsonKey() final  int minutes;

/// Create a copy of AgendaItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgendaItemCopyWith<_AgendaItem> get copyWith => __$AgendaItemCopyWithImpl<_AgendaItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgendaItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgendaItem&&(identical(other.title, title) || other.title == title)&&(identical(other.minutes, minutes) || other.minutes == minutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,minutes);

@override
String toString() {
  return 'AgendaItem(title: $title, minutes: $minutes)';
}


}

/// @nodoc
abstract mixin class _$AgendaItemCopyWith<$Res> implements $AgendaItemCopyWith<$Res> {
  factory _$AgendaItemCopyWith(_AgendaItem value, $Res Function(_AgendaItem) _then) = __$AgendaItemCopyWithImpl;
@override @useResult
$Res call({
 String title, int minutes
});




}
/// @nodoc
class __$AgendaItemCopyWithImpl<$Res>
    implements _$AgendaItemCopyWith<$Res> {
  __$AgendaItemCopyWithImpl(this._self, this._then);

  final _AgendaItem _self;
  final $Res Function(_AgendaItem) _then;

/// Create a copy of AgendaItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? minutes = null,}) {
  return _then(_AgendaItem(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$LiveMeeting {

@JsonKey(unknownEnumValue: MeetingKind.unknown) MeetingKind get kind; String? get link;/// The outside meeting's site (`zoom.us`), on a learner's payload in place of the link.
 String? get linkHost;
/// Create a copy of LiveMeeting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveMeetingCopyWith<LiveMeeting> get copyWith => _$LiveMeetingCopyWithImpl<LiveMeeting>(this as LiveMeeting, _$identity);

  /// Serializes this LiveMeeting to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveMeeting&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.link, link) || other.link == link)&&(identical(other.linkHost, linkHost) || other.linkHost == linkHost));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,link,linkHost);

@override
String toString() {
  return 'LiveMeeting(kind: $kind, link: $link, linkHost: $linkHost)';
}


}

/// @nodoc
abstract mixin class $LiveMeetingCopyWith<$Res>  {
  factory $LiveMeetingCopyWith(LiveMeeting value, $Res Function(LiveMeeting) _then) = _$LiveMeetingCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: MeetingKind.unknown) MeetingKind kind, String? link, String? linkHost
});




}
/// @nodoc
class _$LiveMeetingCopyWithImpl<$Res>
    implements $LiveMeetingCopyWith<$Res> {
  _$LiveMeetingCopyWithImpl(this._self, this._then);

  final LiveMeeting _self;
  final $Res Function(LiveMeeting) _then;

/// Create a copy of LiveMeeting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? link = freezed,Object? linkHost = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MeetingKind,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,linkHost: freezed == linkHost ? _self.linkHost : linkHost // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveMeeting].
extension LiveMeetingPatterns on LiveMeeting {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveMeeting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveMeeting() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveMeeting value)  $default,){
final _that = this;
switch (_that) {
case _LiveMeeting():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveMeeting value)?  $default,){
final _that = this;
switch (_that) {
case _LiveMeeting() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: MeetingKind.unknown)  MeetingKind kind,  String? link,  String? linkHost)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveMeeting() when $default != null:
return $default(_that.kind,_that.link,_that.linkHost);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: MeetingKind.unknown)  MeetingKind kind,  String? link,  String? linkHost)  $default,) {final _that = this;
switch (_that) {
case _LiveMeeting():
return $default(_that.kind,_that.link,_that.linkHost);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: MeetingKind.unknown)  MeetingKind kind,  String? link,  String? linkHost)?  $default,) {final _that = this;
switch (_that) {
case _LiveMeeting() when $default != null:
return $default(_that.kind,_that.link,_that.linkHost);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveMeeting extends LiveMeeting {
  const _LiveMeeting({@JsonKey(unknownEnumValue: MeetingKind.unknown) this.kind = MeetingKind.room, this.link, this.linkHost}): super._();
  factory _LiveMeeting.fromJson(Map<String, dynamic> json) => _$LiveMeetingFromJson(json);

@override@JsonKey(unknownEnumValue: MeetingKind.unknown) final  MeetingKind kind;
@override final  String? link;
/// The outside meeting's site (`zoom.us`), on a learner's payload in place of the link.
@override final  String? linkHost;

/// Create a copy of LiveMeeting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveMeetingCopyWith<_LiveMeeting> get copyWith => __$LiveMeetingCopyWithImpl<_LiveMeeting>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveMeetingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveMeeting&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.link, link) || other.link == link)&&(identical(other.linkHost, linkHost) || other.linkHost == linkHost));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,link,linkHost);

@override
String toString() {
  return 'LiveMeeting(kind: $kind, link: $link, linkHost: $linkHost)';
}


}

/// @nodoc
abstract mixin class _$LiveMeetingCopyWith<$Res> implements $LiveMeetingCopyWith<$Res> {
  factory _$LiveMeetingCopyWith(_LiveMeeting value, $Res Function(_LiveMeeting) _then) = __$LiveMeetingCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: MeetingKind.unknown) MeetingKind kind, String? link, String? linkHost
});




}
/// @nodoc
class __$LiveMeetingCopyWithImpl<$Res>
    implements _$LiveMeetingCopyWith<$Res> {
  __$LiveMeetingCopyWithImpl(this._self, this._then);

  final _LiveMeeting _self;
  final $Res Function(_LiveMeeting) _then;

/// Create a copy of LiveMeeting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? link = freezed,Object? linkHost = freezed,}) {
  return _then(_LiveMeeting(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MeetingKind,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,linkHost: freezed == linkHost ? _self.linkHost : linkHost // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$LiveRecording {

 int get durationMin;@NullableUtcDateTimeConverter() DateTime? get availableUntil;@JsonKey(unknownEnumValue: RecordingStatus.unknown) RecordingStatus? get status;
/// Create a copy of LiveRecording
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveRecordingCopyWith<LiveRecording> get copyWith => _$LiveRecordingCopyWithImpl<LiveRecording>(this as LiveRecording, _$identity);

  /// Serializes this LiveRecording to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveRecording&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.availableUntil, availableUntil) || other.availableUntil == availableUntil)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,durationMin,availableUntil,status);

@override
String toString() {
  return 'LiveRecording(durationMin: $durationMin, availableUntil: $availableUntil, status: $status)';
}


}

/// @nodoc
abstract mixin class $LiveRecordingCopyWith<$Res>  {
  factory $LiveRecordingCopyWith(LiveRecording value, $Res Function(LiveRecording) _then) = _$LiveRecordingCopyWithImpl;
@useResult
$Res call({
 int durationMin,@NullableUtcDateTimeConverter() DateTime? availableUntil,@JsonKey(unknownEnumValue: RecordingStatus.unknown) RecordingStatus? status
});




}
/// @nodoc
class _$LiveRecordingCopyWithImpl<$Res>
    implements $LiveRecordingCopyWith<$Res> {
  _$LiveRecordingCopyWithImpl(this._self, this._then);

  final LiveRecording _self;
  final $Res Function(LiveRecording) _then;

/// Create a copy of LiveRecording
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? durationMin = null,Object? availableUntil = freezed,Object? status = freezed,}) {
  return _then(_self.copyWith(
durationMin: null == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int,availableUntil: freezed == availableUntil ? _self.availableUntil : availableUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RecordingStatus?,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveRecording].
extension LiveRecordingPatterns on LiveRecording {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveRecording value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveRecording() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveRecording value)  $default,){
final _that = this;
switch (_that) {
case _LiveRecording():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveRecording value)?  $default,){
final _that = this;
switch (_that) {
case _LiveRecording() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int durationMin, @NullableUtcDateTimeConverter()  DateTime? availableUntil, @JsonKey(unknownEnumValue: RecordingStatus.unknown)  RecordingStatus? status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveRecording() when $default != null:
return $default(_that.durationMin,_that.availableUntil,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int durationMin, @NullableUtcDateTimeConverter()  DateTime? availableUntil, @JsonKey(unknownEnumValue: RecordingStatus.unknown)  RecordingStatus? status)  $default,) {final _that = this;
switch (_that) {
case _LiveRecording():
return $default(_that.durationMin,_that.availableUntil,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int durationMin, @NullableUtcDateTimeConverter()  DateTime? availableUntil, @JsonKey(unknownEnumValue: RecordingStatus.unknown)  RecordingStatus? status)?  $default,) {final _that = this;
switch (_that) {
case _LiveRecording() when $default != null:
return $default(_that.durationMin,_that.availableUntil,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveRecording extends LiveRecording {
  const _LiveRecording({this.durationMin = 0, @NullableUtcDateTimeConverter() this.availableUntil, @JsonKey(unknownEnumValue: RecordingStatus.unknown) this.status}): super._();
  factory _LiveRecording.fromJson(Map<String, dynamic> json) => _$LiveRecordingFromJson(json);

@override@JsonKey() final  int durationMin;
@override@NullableUtcDateTimeConverter() final  DateTime? availableUntil;
@override@JsonKey(unknownEnumValue: RecordingStatus.unknown) final  RecordingStatus? status;

/// Create a copy of LiveRecording
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveRecordingCopyWith<_LiveRecording> get copyWith => __$LiveRecordingCopyWithImpl<_LiveRecording>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveRecordingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveRecording&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.availableUntil, availableUntil) || other.availableUntil == availableUntil)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,durationMin,availableUntil,status);

@override
String toString() {
  return 'LiveRecording(durationMin: $durationMin, availableUntil: $availableUntil, status: $status)';
}


}

/// @nodoc
abstract mixin class _$LiveRecordingCopyWith<$Res> implements $LiveRecordingCopyWith<$Res> {
  factory _$LiveRecordingCopyWith(_LiveRecording value, $Res Function(_LiveRecording) _then) = __$LiveRecordingCopyWithImpl;
@override @useResult
$Res call({
 int durationMin,@NullableUtcDateTimeConverter() DateTime? availableUntil,@JsonKey(unknownEnumValue: RecordingStatus.unknown) RecordingStatus? status
});




}
/// @nodoc
class __$LiveRecordingCopyWithImpl<$Res>
    implements _$LiveRecordingCopyWith<$Res> {
  __$LiveRecordingCopyWithImpl(this._self, this._then);

  final _LiveRecording _self;
  final $Res Function(_LiveRecording) _then;

/// Create a copy of LiveRecording
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? durationMin = null,Object? availableUntil = freezed,Object? status = freezed,}) {
  return _then(_LiveRecording(
durationMin: null == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int,availableUntil: freezed == availableUntil ? _self.availableUntil : availableUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RecordingStatus?,
  ));
}


}


/// @nodoc
mixin _$LiveClass {

 String get id; String get courseId; String get title; String get instructorId;@UtcDateTimeConverter() DateTime get startsAt; int get durationMin; int? get capacity;/// On a learner's own row this counts **their** registration, not the class's (finding 17).
 int? get registered; int? get attending; int? get attended; bool get cancelled;/// When the host opened the built-in room; such a class is live only from here.
@NullableUtcDateTimeConverter() DateTime? get startedAt;/// When the host (or the academy, for a room left open) closed it.
@NullableUtcDateTimeConverter() DateTime? get endedAt; LiveRecording? get recording; String? get description; List<AgendaItem> get agenda;@JsonKey(unknownEnumValue: LiveVisibility.unknown) LiveVisibility get visibility; LiveMeeting get meeting;/// Minutes before the start that registrants are reminded.
 List<int> get reminders; String? get cancelReason; String? get chapterId;
/// Create a copy of LiveClass
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveClassCopyWith<LiveClass> get copyWith => _$LiveClassCopyWithImpl<LiveClass>(this as LiveClass, _$identity);

  /// Serializes this LiveClass to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveClass&&(identical(other.id, id) || other.id == id)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.title, title) || other.title == title)&&(identical(other.instructorId, instructorId) || other.instructorId == instructorId)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.registered, registered) || other.registered == registered)&&(identical(other.attending, attending) || other.attending == attending)&&(identical(other.attended, attended) || other.attended == attended)&&(identical(other.cancelled, cancelled) || other.cancelled == cancelled)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.recording, recording) || other.recording == recording)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.agenda, agenda)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.meeting, meeting) || other.meeting == meeting)&&const DeepCollectionEquality().equals(other.reminders, reminders)&&(identical(other.cancelReason, cancelReason) || other.cancelReason == cancelReason)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,courseId,title,instructorId,startsAt,durationMin,capacity,registered,attending,attended,cancelled,startedAt,endedAt,recording,description,const DeepCollectionEquality().hash(agenda),visibility,meeting,const DeepCollectionEquality().hash(reminders),cancelReason,chapterId]);

@override
String toString() {
  return 'LiveClass(id: $id, courseId: $courseId, title: $title, instructorId: $instructorId, startsAt: $startsAt, durationMin: $durationMin, capacity: $capacity, registered: $registered, attending: $attending, attended: $attended, cancelled: $cancelled, startedAt: $startedAt, endedAt: $endedAt, recording: $recording, description: $description, agenda: $agenda, visibility: $visibility, meeting: $meeting, reminders: $reminders, cancelReason: $cancelReason, chapterId: $chapterId)';
}


}

/// @nodoc
abstract mixin class $LiveClassCopyWith<$Res>  {
  factory $LiveClassCopyWith(LiveClass value, $Res Function(LiveClass) _then) = _$LiveClassCopyWithImpl;
@useResult
$Res call({
 String id, String courseId, String title, String instructorId,@UtcDateTimeConverter() DateTime startsAt, int durationMin, int? capacity, int? registered, int? attending, int? attended, bool cancelled,@NullableUtcDateTimeConverter() DateTime? startedAt,@NullableUtcDateTimeConverter() DateTime? endedAt, LiveRecording? recording, String? description, List<AgendaItem> agenda,@JsonKey(unknownEnumValue: LiveVisibility.unknown) LiveVisibility visibility, LiveMeeting meeting, List<int> reminders, String? cancelReason, String? chapterId
});


$LiveRecordingCopyWith<$Res>? get recording;$LiveMeetingCopyWith<$Res> get meeting;

}
/// @nodoc
class _$LiveClassCopyWithImpl<$Res>
    implements $LiveClassCopyWith<$Res> {
  _$LiveClassCopyWithImpl(this._self, this._then);

  final LiveClass _self;
  final $Res Function(LiveClass) _then;

/// Create a copy of LiveClass
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? courseId = null,Object? title = null,Object? instructorId = null,Object? startsAt = null,Object? durationMin = null,Object? capacity = freezed,Object? registered = freezed,Object? attending = freezed,Object? attended = freezed,Object? cancelled = null,Object? startedAt = freezed,Object? endedAt = freezed,Object? recording = freezed,Object? description = freezed,Object? agenda = null,Object? visibility = null,Object? meeting = null,Object? reminders = null,Object? cancelReason = freezed,Object? chapterId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,instructorId: null == instructorId ? _self.instructorId : instructorId // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,durationMin: null == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,registered: freezed == registered ? _self.registered : registered // ignore: cast_nullable_to_non_nullable
as int?,attending: freezed == attending ? _self.attending : attending // ignore: cast_nullable_to_non_nullable
as int?,attended: freezed == attended ? _self.attended : attended // ignore: cast_nullable_to_non_nullable
as int?,cancelled: null == cancelled ? _self.cancelled : cancelled // ignore: cast_nullable_to_non_nullable
as bool,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,recording: freezed == recording ? _self.recording : recording // ignore: cast_nullable_to_non_nullable
as LiveRecording?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,agenda: null == agenda ? _self.agenda : agenda // ignore: cast_nullable_to_non_nullable
as List<AgendaItem>,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as LiveVisibility,meeting: null == meeting ? _self.meeting : meeting // ignore: cast_nullable_to_non_nullable
as LiveMeeting,reminders: null == reminders ? _self.reminders : reminders // ignore: cast_nullable_to_non_nullable
as List<int>,cancelReason: freezed == cancelReason ? _self.cancelReason : cancelReason // ignore: cast_nullable_to_non_nullable
as String?,chapterId: freezed == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of LiveClass
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveRecordingCopyWith<$Res>? get recording {
    if (_self.recording == null) {
    return null;
  }

  return $LiveRecordingCopyWith<$Res>(_self.recording!, (value) {
    return _then(_self.copyWith(recording: value));
  });
}/// Create a copy of LiveClass
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveMeetingCopyWith<$Res> get meeting {
  
  return $LiveMeetingCopyWith<$Res>(_self.meeting, (value) {
    return _then(_self.copyWith(meeting: value));
  });
}
}


/// Adds pattern-matching-related methods to [LiveClass].
extension LiveClassPatterns on LiveClass {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveClass value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveClass() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveClass value)  $default,){
final _that = this;
switch (_that) {
case _LiveClass():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveClass value)?  $default,){
final _that = this;
switch (_that) {
case _LiveClass() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String courseId,  String title,  String instructorId, @UtcDateTimeConverter()  DateTime startsAt,  int durationMin,  int? capacity,  int? registered,  int? attending,  int? attended,  bool cancelled, @NullableUtcDateTimeConverter()  DateTime? startedAt, @NullableUtcDateTimeConverter()  DateTime? endedAt,  LiveRecording? recording,  String? description,  List<AgendaItem> agenda, @JsonKey(unknownEnumValue: LiveVisibility.unknown)  LiveVisibility visibility,  LiveMeeting meeting,  List<int> reminders,  String? cancelReason,  String? chapterId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveClass() when $default != null:
return $default(_that.id,_that.courseId,_that.title,_that.instructorId,_that.startsAt,_that.durationMin,_that.capacity,_that.registered,_that.attending,_that.attended,_that.cancelled,_that.startedAt,_that.endedAt,_that.recording,_that.description,_that.agenda,_that.visibility,_that.meeting,_that.reminders,_that.cancelReason,_that.chapterId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String courseId,  String title,  String instructorId, @UtcDateTimeConverter()  DateTime startsAt,  int durationMin,  int? capacity,  int? registered,  int? attending,  int? attended,  bool cancelled, @NullableUtcDateTimeConverter()  DateTime? startedAt, @NullableUtcDateTimeConverter()  DateTime? endedAt,  LiveRecording? recording,  String? description,  List<AgendaItem> agenda, @JsonKey(unknownEnumValue: LiveVisibility.unknown)  LiveVisibility visibility,  LiveMeeting meeting,  List<int> reminders,  String? cancelReason,  String? chapterId)  $default,) {final _that = this;
switch (_that) {
case _LiveClass():
return $default(_that.id,_that.courseId,_that.title,_that.instructorId,_that.startsAt,_that.durationMin,_that.capacity,_that.registered,_that.attending,_that.attended,_that.cancelled,_that.startedAt,_that.endedAt,_that.recording,_that.description,_that.agenda,_that.visibility,_that.meeting,_that.reminders,_that.cancelReason,_that.chapterId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String courseId,  String title,  String instructorId, @UtcDateTimeConverter()  DateTime startsAt,  int durationMin,  int? capacity,  int? registered,  int? attending,  int? attended,  bool cancelled, @NullableUtcDateTimeConverter()  DateTime? startedAt, @NullableUtcDateTimeConverter()  DateTime? endedAt,  LiveRecording? recording,  String? description,  List<AgendaItem> agenda, @JsonKey(unknownEnumValue: LiveVisibility.unknown)  LiveVisibility visibility,  LiveMeeting meeting,  List<int> reminders,  String? cancelReason,  String? chapterId)?  $default,) {final _that = this;
switch (_that) {
case _LiveClass() when $default != null:
return $default(_that.id,_that.courseId,_that.title,_that.instructorId,_that.startsAt,_that.durationMin,_that.capacity,_that.registered,_that.attending,_that.attended,_that.cancelled,_that.startedAt,_that.endedAt,_that.recording,_that.description,_that.agenda,_that.visibility,_that.meeting,_that.reminders,_that.cancelReason,_that.chapterId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveClass extends LiveClass {
  const _LiveClass({required this.id, this.courseId = '', this.title = '', this.instructorId = '', @UtcDateTimeConverter() required this.startsAt, this.durationMin = 0, this.capacity, this.registered, this.attending, this.attended, this.cancelled = false, @NullableUtcDateTimeConverter() this.startedAt, @NullableUtcDateTimeConverter() this.endedAt, this.recording, this.description, final  List<AgendaItem> agenda = const <AgendaItem>[], @JsonKey(unknownEnumValue: LiveVisibility.unknown) this.visibility = LiveVisibility.enrolled, this.meeting = const LiveMeeting(), final  List<int> reminders = const <int>[], this.cancelReason, this.chapterId}): _agenda = agenda,_reminders = reminders,super._();
  factory _LiveClass.fromJson(Map<String, dynamic> json) => _$LiveClassFromJson(json);

@override final  String id;
@override@JsonKey() final  String courseId;
@override@JsonKey() final  String title;
@override@JsonKey() final  String instructorId;
@override@UtcDateTimeConverter() final  DateTime startsAt;
@override@JsonKey() final  int durationMin;
@override final  int? capacity;
/// On a learner's own row this counts **their** registration, not the class's (finding 17).
@override final  int? registered;
@override final  int? attending;
@override final  int? attended;
@override@JsonKey() final  bool cancelled;
/// When the host opened the built-in room; such a class is live only from here.
@override@NullableUtcDateTimeConverter() final  DateTime? startedAt;
/// When the host (or the academy, for a room left open) closed it.
@override@NullableUtcDateTimeConverter() final  DateTime? endedAt;
@override final  LiveRecording? recording;
@override final  String? description;
 final  List<AgendaItem> _agenda;
@override@JsonKey() List<AgendaItem> get agenda {
  if (_agenda is EqualUnmodifiableListView) return _agenda;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_agenda);
}

@override@JsonKey(unknownEnumValue: LiveVisibility.unknown) final  LiveVisibility visibility;
@override@JsonKey() final  LiveMeeting meeting;
/// Minutes before the start that registrants are reminded.
 final  List<int> _reminders;
/// Minutes before the start that registrants are reminded.
@override@JsonKey() List<int> get reminders {
  if (_reminders is EqualUnmodifiableListView) return _reminders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reminders);
}

@override final  String? cancelReason;
@override final  String? chapterId;

/// Create a copy of LiveClass
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveClassCopyWith<_LiveClass> get copyWith => __$LiveClassCopyWithImpl<_LiveClass>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveClassToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveClass&&(identical(other.id, id) || other.id == id)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.title, title) || other.title == title)&&(identical(other.instructorId, instructorId) || other.instructorId == instructorId)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.registered, registered) || other.registered == registered)&&(identical(other.attending, attending) || other.attending == attending)&&(identical(other.attended, attended) || other.attended == attended)&&(identical(other.cancelled, cancelled) || other.cancelled == cancelled)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.recording, recording) || other.recording == recording)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._agenda, _agenda)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.meeting, meeting) || other.meeting == meeting)&&const DeepCollectionEquality().equals(other._reminders, _reminders)&&(identical(other.cancelReason, cancelReason) || other.cancelReason == cancelReason)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,courseId,title,instructorId,startsAt,durationMin,capacity,registered,attending,attended,cancelled,startedAt,endedAt,recording,description,const DeepCollectionEquality().hash(_agenda),visibility,meeting,const DeepCollectionEquality().hash(_reminders),cancelReason,chapterId]);

@override
String toString() {
  return 'LiveClass(id: $id, courseId: $courseId, title: $title, instructorId: $instructorId, startsAt: $startsAt, durationMin: $durationMin, capacity: $capacity, registered: $registered, attending: $attending, attended: $attended, cancelled: $cancelled, startedAt: $startedAt, endedAt: $endedAt, recording: $recording, description: $description, agenda: $agenda, visibility: $visibility, meeting: $meeting, reminders: $reminders, cancelReason: $cancelReason, chapterId: $chapterId)';
}


}

/// @nodoc
abstract mixin class _$LiveClassCopyWith<$Res> implements $LiveClassCopyWith<$Res> {
  factory _$LiveClassCopyWith(_LiveClass value, $Res Function(_LiveClass) _then) = __$LiveClassCopyWithImpl;
@override @useResult
$Res call({
 String id, String courseId, String title, String instructorId,@UtcDateTimeConverter() DateTime startsAt, int durationMin, int? capacity, int? registered, int? attending, int? attended, bool cancelled,@NullableUtcDateTimeConverter() DateTime? startedAt,@NullableUtcDateTimeConverter() DateTime? endedAt, LiveRecording? recording, String? description, List<AgendaItem> agenda,@JsonKey(unknownEnumValue: LiveVisibility.unknown) LiveVisibility visibility, LiveMeeting meeting, List<int> reminders, String? cancelReason, String? chapterId
});


@override $LiveRecordingCopyWith<$Res>? get recording;@override $LiveMeetingCopyWith<$Res> get meeting;

}
/// @nodoc
class __$LiveClassCopyWithImpl<$Res>
    implements _$LiveClassCopyWith<$Res> {
  __$LiveClassCopyWithImpl(this._self, this._then);

  final _LiveClass _self;
  final $Res Function(_LiveClass) _then;

/// Create a copy of LiveClass
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? courseId = null,Object? title = null,Object? instructorId = null,Object? startsAt = null,Object? durationMin = null,Object? capacity = freezed,Object? registered = freezed,Object? attending = freezed,Object? attended = freezed,Object? cancelled = null,Object? startedAt = freezed,Object? endedAt = freezed,Object? recording = freezed,Object? description = freezed,Object? agenda = null,Object? visibility = null,Object? meeting = null,Object? reminders = null,Object? cancelReason = freezed,Object? chapterId = freezed,}) {
  return _then(_LiveClass(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,instructorId: null == instructorId ? _self.instructorId : instructorId // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime,durationMin: null == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,registered: freezed == registered ? _self.registered : registered // ignore: cast_nullable_to_non_nullable
as int?,attending: freezed == attending ? _self.attending : attending // ignore: cast_nullable_to_non_nullable
as int?,attended: freezed == attended ? _self.attended : attended // ignore: cast_nullable_to_non_nullable
as int?,cancelled: null == cancelled ? _self.cancelled : cancelled // ignore: cast_nullable_to_non_nullable
as bool,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,recording: freezed == recording ? _self.recording : recording // ignore: cast_nullable_to_non_nullable
as LiveRecording?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,agenda: null == agenda ? _self._agenda : agenda // ignore: cast_nullable_to_non_nullable
as List<AgendaItem>,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as LiveVisibility,meeting: null == meeting ? _self.meeting : meeting // ignore: cast_nullable_to_non_nullable
as LiveMeeting,reminders: null == reminders ? _self._reminders : reminders // ignore: cast_nullable_to_non_nullable
as List<int>,cancelReason: freezed == cancelReason ? _self.cancelReason : cancelReason // ignore: cast_nullable_to_non_nullable
as String?,chapterId: freezed == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of LiveClass
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveRecordingCopyWith<$Res>? get recording {
    if (_self.recording == null) {
    return null;
  }

  return $LiveRecordingCopyWith<$Res>(_self.recording!, (value) {
    return _then(_self.copyWith(recording: value));
  });
}/// Create a copy of LiveClass
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveMeetingCopyWith<$Res> get meeting {
  
  return $LiveMeetingCopyWith<$Res>(_self.meeting, (value) {
    return _then(_self.copyWith(meeting: value));
  });
}
}


/// @nodoc
mixin _$LearnerLiveRow {

 LiveClass get liveClass;@JsonKey(unknownEnumValue: LivePhase.unknown) LivePhase get phase; String get courseTitle; String get instructorName;/// Whether **this** learner has a seat. Sent on upcoming rows only.
 bool get registered;/// On a past class: whether this learner joined it (null when they held no place).
 bool? get attended;
/// Create a copy of LearnerLiveRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearnerLiveRowCopyWith<LearnerLiveRow> get copyWith => _$LearnerLiveRowCopyWithImpl<LearnerLiveRow>(this as LearnerLiveRow, _$identity);

  /// Serializes this LearnerLiveRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearnerLiveRow&&(identical(other.liveClass, liveClass) || other.liveClass == liveClass)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.instructorName, instructorName) || other.instructorName == instructorName)&&(identical(other.registered, registered) || other.registered == registered)&&(identical(other.attended, attended) || other.attended == attended));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,liveClass,phase,courseTitle,instructorName,registered,attended);

@override
String toString() {
  return 'LearnerLiveRow(liveClass: $liveClass, phase: $phase, courseTitle: $courseTitle, instructorName: $instructorName, registered: $registered, attended: $attended)';
}


}

/// @nodoc
abstract mixin class $LearnerLiveRowCopyWith<$Res>  {
  factory $LearnerLiveRowCopyWith(LearnerLiveRow value, $Res Function(LearnerLiveRow) _then) = _$LearnerLiveRowCopyWithImpl;
@useResult
$Res call({
 LiveClass liveClass,@JsonKey(unknownEnumValue: LivePhase.unknown) LivePhase phase, String courseTitle, String instructorName, bool registered, bool? attended
});


$LiveClassCopyWith<$Res> get liveClass;

}
/// @nodoc
class _$LearnerLiveRowCopyWithImpl<$Res>
    implements $LearnerLiveRowCopyWith<$Res> {
  _$LearnerLiveRowCopyWithImpl(this._self, this._then);

  final LearnerLiveRow _self;
  final $Res Function(LearnerLiveRow) _then;

/// Create a copy of LearnerLiveRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? liveClass = null,Object? phase = null,Object? courseTitle = null,Object? instructorName = null,Object? registered = null,Object? attended = freezed,}) {
  return _then(_self.copyWith(
liveClass: null == liveClass ? _self.liveClass : liveClass // ignore: cast_nullable_to_non_nullable
as LiveClass,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as LivePhase,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,instructorName: null == instructorName ? _self.instructorName : instructorName // ignore: cast_nullable_to_non_nullable
as String,registered: null == registered ? _self.registered : registered // ignore: cast_nullable_to_non_nullable
as bool,attended: freezed == attended ? _self.attended : attended // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of LearnerLiveRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveClassCopyWith<$Res> get liveClass {
  
  return $LiveClassCopyWith<$Res>(_self.liveClass, (value) {
    return _then(_self.copyWith(liveClass: value));
  });
}
}


/// Adds pattern-matching-related methods to [LearnerLiveRow].
extension LearnerLiveRowPatterns on LearnerLiveRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearnerLiveRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearnerLiveRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearnerLiveRow value)  $default,){
final _that = this;
switch (_that) {
case _LearnerLiveRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearnerLiveRow value)?  $default,){
final _that = this;
switch (_that) {
case _LearnerLiveRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LiveClass liveClass, @JsonKey(unknownEnumValue: LivePhase.unknown)  LivePhase phase,  String courseTitle,  String instructorName,  bool registered,  bool? attended)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearnerLiveRow() when $default != null:
return $default(_that.liveClass,_that.phase,_that.courseTitle,_that.instructorName,_that.registered,_that.attended);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LiveClass liveClass, @JsonKey(unknownEnumValue: LivePhase.unknown)  LivePhase phase,  String courseTitle,  String instructorName,  bool registered,  bool? attended)  $default,) {final _that = this;
switch (_that) {
case _LearnerLiveRow():
return $default(_that.liveClass,_that.phase,_that.courseTitle,_that.instructorName,_that.registered,_that.attended);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LiveClass liveClass, @JsonKey(unknownEnumValue: LivePhase.unknown)  LivePhase phase,  String courseTitle,  String instructorName,  bool registered,  bool? attended)?  $default,) {final _that = this;
switch (_that) {
case _LearnerLiveRow() when $default != null:
return $default(_that.liveClass,_that.phase,_that.courseTitle,_that.instructorName,_that.registered,_that.attended);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LearnerLiveRow extends LearnerLiveRow {
  const _LearnerLiveRow({required this.liveClass, @JsonKey(unknownEnumValue: LivePhase.unknown) this.phase = LivePhase.unknown, this.courseTitle = '', this.instructorName = '', this.registered = false, this.attended}): super._();
  factory _LearnerLiveRow.fromJson(Map<String, dynamic> json) => _$LearnerLiveRowFromJson(json);

@override final  LiveClass liveClass;
@override@JsonKey(unknownEnumValue: LivePhase.unknown) final  LivePhase phase;
@override@JsonKey() final  String courseTitle;
@override@JsonKey() final  String instructorName;
/// Whether **this** learner has a seat. Sent on upcoming rows only.
@override@JsonKey() final  bool registered;
/// On a past class: whether this learner joined it (null when they held no place).
@override final  bool? attended;

/// Create a copy of LearnerLiveRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearnerLiveRowCopyWith<_LearnerLiveRow> get copyWith => __$LearnerLiveRowCopyWithImpl<_LearnerLiveRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearnerLiveRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearnerLiveRow&&(identical(other.liveClass, liveClass) || other.liveClass == liveClass)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.instructorName, instructorName) || other.instructorName == instructorName)&&(identical(other.registered, registered) || other.registered == registered)&&(identical(other.attended, attended) || other.attended == attended));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,liveClass,phase,courseTitle,instructorName,registered,attended);

@override
String toString() {
  return 'LearnerLiveRow(liveClass: $liveClass, phase: $phase, courseTitle: $courseTitle, instructorName: $instructorName, registered: $registered, attended: $attended)';
}


}

/// @nodoc
abstract mixin class _$LearnerLiveRowCopyWith<$Res> implements $LearnerLiveRowCopyWith<$Res> {
  factory _$LearnerLiveRowCopyWith(_LearnerLiveRow value, $Res Function(_LearnerLiveRow) _then) = __$LearnerLiveRowCopyWithImpl;
@override @useResult
$Res call({
 LiveClass liveClass,@JsonKey(unknownEnumValue: LivePhase.unknown) LivePhase phase, String courseTitle, String instructorName, bool registered, bool? attended
});


@override $LiveClassCopyWith<$Res> get liveClass;

}
/// @nodoc
class __$LearnerLiveRowCopyWithImpl<$Res>
    implements _$LearnerLiveRowCopyWith<$Res> {
  __$LearnerLiveRowCopyWithImpl(this._self, this._then);

  final _LearnerLiveRow _self;
  final $Res Function(_LearnerLiveRow) _then;

/// Create a copy of LearnerLiveRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? liveClass = null,Object? phase = null,Object? courseTitle = null,Object? instructorName = null,Object? registered = null,Object? attended = freezed,}) {
  return _then(_LearnerLiveRow(
liveClass: null == liveClass ? _self.liveClass : liveClass // ignore: cast_nullable_to_non_nullable
as LiveClass,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as LivePhase,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,instructorName: null == instructorName ? _self.instructorName : instructorName // ignore: cast_nullable_to_non_nullable
as String,registered: null == registered ? _self.registered : registered // ignore: cast_nullable_to_non_nullable
as bool,attended: freezed == attended ? _self.attended : attended // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of LearnerLiveRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveClassCopyWith<$Res> get liveClass {
  
  return $LiveClassCopyWith<$Res>(_self.liveClass, (value) {
    return _then(_self.copyWith(liveClass: value));
  });
}
}


/// @nodoc
mixin _$LiveSchedule {

 List<LearnerLiveRow> get live; List<LearnerLiveRow> get upcoming; List<LearnerLiveRow> get recordings;/// Past classes this learner held a place for, with whether they came.
 List<LearnerLiveRow> get history;
/// Create a copy of LiveSchedule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveScheduleCopyWith<LiveSchedule> get copyWith => _$LiveScheduleCopyWithImpl<LiveSchedule>(this as LiveSchedule, _$identity);

  /// Serializes this LiveSchedule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveSchedule&&const DeepCollectionEquality().equals(other.live, live)&&const DeepCollectionEquality().equals(other.upcoming, upcoming)&&const DeepCollectionEquality().equals(other.recordings, recordings)&&const DeepCollectionEquality().equals(other.history, history));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(live),const DeepCollectionEquality().hash(upcoming),const DeepCollectionEquality().hash(recordings),const DeepCollectionEquality().hash(history));

@override
String toString() {
  return 'LiveSchedule(live: $live, upcoming: $upcoming, recordings: $recordings, history: $history)';
}


}

/// @nodoc
abstract mixin class $LiveScheduleCopyWith<$Res>  {
  factory $LiveScheduleCopyWith(LiveSchedule value, $Res Function(LiveSchedule) _then) = _$LiveScheduleCopyWithImpl;
@useResult
$Res call({
 List<LearnerLiveRow> live, List<LearnerLiveRow> upcoming, List<LearnerLiveRow> recordings, List<LearnerLiveRow> history
});




}
/// @nodoc
class _$LiveScheduleCopyWithImpl<$Res>
    implements $LiveScheduleCopyWith<$Res> {
  _$LiveScheduleCopyWithImpl(this._self, this._then);

  final LiveSchedule _self;
  final $Res Function(LiveSchedule) _then;

/// Create a copy of LiveSchedule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? live = null,Object? upcoming = null,Object? recordings = null,Object? history = null,}) {
  return _then(_self.copyWith(
live: null == live ? _self.live : live // ignore: cast_nullable_to_non_nullable
as List<LearnerLiveRow>,upcoming: null == upcoming ? _self.upcoming : upcoming // ignore: cast_nullable_to_non_nullable
as List<LearnerLiveRow>,recordings: null == recordings ? _self.recordings : recordings // ignore: cast_nullable_to_non_nullable
as List<LearnerLiveRow>,history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as List<LearnerLiveRow>,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveSchedule].
extension LiveSchedulePatterns on LiveSchedule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveSchedule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveSchedule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveSchedule value)  $default,){
final _that = this;
switch (_that) {
case _LiveSchedule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveSchedule value)?  $default,){
final _that = this;
switch (_that) {
case _LiveSchedule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<LearnerLiveRow> live,  List<LearnerLiveRow> upcoming,  List<LearnerLiveRow> recordings,  List<LearnerLiveRow> history)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveSchedule() when $default != null:
return $default(_that.live,_that.upcoming,_that.recordings,_that.history);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<LearnerLiveRow> live,  List<LearnerLiveRow> upcoming,  List<LearnerLiveRow> recordings,  List<LearnerLiveRow> history)  $default,) {final _that = this;
switch (_that) {
case _LiveSchedule():
return $default(_that.live,_that.upcoming,_that.recordings,_that.history);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<LearnerLiveRow> live,  List<LearnerLiveRow> upcoming,  List<LearnerLiveRow> recordings,  List<LearnerLiveRow> history)?  $default,) {final _that = this;
switch (_that) {
case _LiveSchedule() when $default != null:
return $default(_that.live,_that.upcoming,_that.recordings,_that.history);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveSchedule extends LiveSchedule {
  const _LiveSchedule({final  List<LearnerLiveRow> live = const <LearnerLiveRow>[], final  List<LearnerLiveRow> upcoming = const <LearnerLiveRow>[], final  List<LearnerLiveRow> recordings = const <LearnerLiveRow>[], final  List<LearnerLiveRow> history = const <LearnerLiveRow>[]}): _live = live,_upcoming = upcoming,_recordings = recordings,_history = history,super._();
  factory _LiveSchedule.fromJson(Map<String, dynamic> json) => _$LiveScheduleFromJson(json);

 final  List<LearnerLiveRow> _live;
@override@JsonKey() List<LearnerLiveRow> get live {
  if (_live is EqualUnmodifiableListView) return _live;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_live);
}

 final  List<LearnerLiveRow> _upcoming;
@override@JsonKey() List<LearnerLiveRow> get upcoming {
  if (_upcoming is EqualUnmodifiableListView) return _upcoming;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_upcoming);
}

 final  List<LearnerLiveRow> _recordings;
@override@JsonKey() List<LearnerLiveRow> get recordings {
  if (_recordings is EqualUnmodifiableListView) return _recordings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recordings);
}

/// Past classes this learner held a place for, with whether they came.
 final  List<LearnerLiveRow> _history;
/// Past classes this learner held a place for, with whether they came.
@override@JsonKey() List<LearnerLiveRow> get history {
  if (_history is EqualUnmodifiableListView) return _history;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_history);
}


/// Create a copy of LiveSchedule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveScheduleCopyWith<_LiveSchedule> get copyWith => __$LiveScheduleCopyWithImpl<_LiveSchedule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveScheduleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveSchedule&&const DeepCollectionEquality().equals(other._live, _live)&&const DeepCollectionEquality().equals(other._upcoming, _upcoming)&&const DeepCollectionEquality().equals(other._recordings, _recordings)&&const DeepCollectionEquality().equals(other._history, _history));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_live),const DeepCollectionEquality().hash(_upcoming),const DeepCollectionEquality().hash(_recordings),const DeepCollectionEquality().hash(_history));

@override
String toString() {
  return 'LiveSchedule(live: $live, upcoming: $upcoming, recordings: $recordings, history: $history)';
}


}

/// @nodoc
abstract mixin class _$LiveScheduleCopyWith<$Res> implements $LiveScheduleCopyWith<$Res> {
  factory _$LiveScheduleCopyWith(_LiveSchedule value, $Res Function(_LiveSchedule) _then) = __$LiveScheduleCopyWithImpl;
@override @useResult
$Res call({
 List<LearnerLiveRow> live, List<LearnerLiveRow> upcoming, List<LearnerLiveRow> recordings, List<LearnerLiveRow> history
});




}
/// @nodoc
class __$LiveScheduleCopyWithImpl<$Res>
    implements _$LiveScheduleCopyWith<$Res> {
  __$LiveScheduleCopyWithImpl(this._self, this._then);

  final _LiveSchedule _self;
  final $Res Function(_LiveSchedule) _then;

/// Create a copy of LiveSchedule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? live = null,Object? upcoming = null,Object? recordings = null,Object? history = null,}) {
  return _then(_LiveSchedule(
live: null == live ? _self._live : live // ignore: cast_nullable_to_non_nullable
as List<LearnerLiveRow>,upcoming: null == upcoming ? _self._upcoming : upcoming // ignore: cast_nullable_to_non_nullable
as List<LearnerLiveRow>,recordings: null == recordings ? _self._recordings : recordings // ignore: cast_nullable_to_non_nullable
as List<LearnerLiveRow>,history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<LearnerLiveRow>,
  ));
}


}


/// @nodoc
mixin _$LiveRegistration {

 bool get registered;/// The route sends 999 for a class with no capacity at all; that is not a number to show.
 int get spotsLeft;
/// Create a copy of LiveRegistration
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveRegistrationCopyWith<LiveRegistration> get copyWith => _$LiveRegistrationCopyWithImpl<LiveRegistration>(this as LiveRegistration, _$identity);

  /// Serializes this LiveRegistration to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveRegistration&&(identical(other.registered, registered) || other.registered == registered)&&(identical(other.spotsLeft, spotsLeft) || other.spotsLeft == spotsLeft));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,registered,spotsLeft);

@override
String toString() {
  return 'LiveRegistration(registered: $registered, spotsLeft: $spotsLeft)';
}


}

/// @nodoc
abstract mixin class $LiveRegistrationCopyWith<$Res>  {
  factory $LiveRegistrationCopyWith(LiveRegistration value, $Res Function(LiveRegistration) _then) = _$LiveRegistrationCopyWithImpl;
@useResult
$Res call({
 bool registered, int spotsLeft
});




}
/// @nodoc
class _$LiveRegistrationCopyWithImpl<$Res>
    implements $LiveRegistrationCopyWith<$Res> {
  _$LiveRegistrationCopyWithImpl(this._self, this._then);

  final LiveRegistration _self;
  final $Res Function(LiveRegistration) _then;

/// Create a copy of LiveRegistration
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? registered = null,Object? spotsLeft = null,}) {
  return _then(_self.copyWith(
registered: null == registered ? _self.registered : registered // ignore: cast_nullable_to_non_nullable
as bool,spotsLeft: null == spotsLeft ? _self.spotsLeft : spotsLeft // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveRegistration].
extension LiveRegistrationPatterns on LiveRegistration {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveRegistration value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveRegistration() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveRegistration value)  $default,){
final _that = this;
switch (_that) {
case _LiveRegistration():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveRegistration value)?  $default,){
final _that = this;
switch (_that) {
case _LiveRegistration() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool registered,  int spotsLeft)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveRegistration() when $default != null:
return $default(_that.registered,_that.spotsLeft);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool registered,  int spotsLeft)  $default,) {final _that = this;
switch (_that) {
case _LiveRegistration():
return $default(_that.registered,_that.spotsLeft);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool registered,  int spotsLeft)?  $default,) {final _that = this;
switch (_that) {
case _LiveRegistration() when $default != null:
return $default(_that.registered,_that.spotsLeft);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveRegistration extends LiveRegistration {
  const _LiveRegistration({this.registered = false, this.spotsLeft = 999}): super._();
  factory _LiveRegistration.fromJson(Map<String, dynamic> json) => _$LiveRegistrationFromJson(json);

@override@JsonKey() final  bool registered;
/// The route sends 999 for a class with no capacity at all; that is not a number to show.
@override@JsonKey() final  int spotsLeft;

/// Create a copy of LiveRegistration
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveRegistrationCopyWith<_LiveRegistration> get copyWith => __$LiveRegistrationCopyWithImpl<_LiveRegistration>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveRegistrationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveRegistration&&(identical(other.registered, registered) || other.registered == registered)&&(identical(other.spotsLeft, spotsLeft) || other.spotsLeft == spotsLeft));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,registered,spotsLeft);

@override
String toString() {
  return 'LiveRegistration(registered: $registered, spotsLeft: $spotsLeft)';
}


}

/// @nodoc
abstract mixin class _$LiveRegistrationCopyWith<$Res> implements $LiveRegistrationCopyWith<$Res> {
  factory _$LiveRegistrationCopyWith(_LiveRegistration value, $Res Function(_LiveRegistration) _then) = __$LiveRegistrationCopyWithImpl;
@override @useResult
$Res call({
 bool registered, int spotsLeft
});




}
/// @nodoc
class __$LiveRegistrationCopyWithImpl<$Res>
    implements _$LiveRegistrationCopyWith<$Res> {
  __$LiveRegistrationCopyWithImpl(this._self, this._then);

  final _LiveRegistration _self;
  final $Res Function(_LiveRegistration) _then;

/// Create a copy of LiveRegistration
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? registered = null,Object? spotsLeft = null,}) {
  return _then(_LiveRegistration(
registered: null == registered ? _self.registered : registered // ignore: cast_nullable_to_non_nullable
as bool,spotsLeft: null == spotsLeft ? _self.spotsLeft : spotsLeft // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$LiveRoomJoin {

 String get provider; String get domain; String get room; String? get jwt; String get subject; String get displayName; String? get email; bool get moderator; bool get recording;
/// Create a copy of LiveRoomJoin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveRoomJoinCopyWith<LiveRoomJoin> get copyWith => _$LiveRoomJoinCopyWithImpl<LiveRoomJoin>(this as LiveRoomJoin, _$identity);

  /// Serializes this LiveRoomJoin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveRoomJoin&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.domain, domain) || other.domain == domain)&&(identical(other.room, room) || other.room == room)&&(identical(other.jwt, jwt) || other.jwt == jwt)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.moderator, moderator) || other.moderator == moderator)&&(identical(other.recording, recording) || other.recording == recording));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,domain,room,jwt,subject,displayName,email,moderator,recording);

@override
String toString() {
  return 'LiveRoomJoin(provider: $provider, domain: $domain, room: $room, jwt: $jwt, subject: $subject, displayName: $displayName, email: $email, moderator: $moderator, recording: $recording)';
}


}

/// @nodoc
abstract mixin class $LiveRoomJoinCopyWith<$Res>  {
  factory $LiveRoomJoinCopyWith(LiveRoomJoin value, $Res Function(LiveRoomJoin) _then) = _$LiveRoomJoinCopyWithImpl;
@useResult
$Res call({
 String provider, String domain, String room, String? jwt, String subject, String displayName, String? email, bool moderator, bool recording
});




}
/// @nodoc
class _$LiveRoomJoinCopyWithImpl<$Res>
    implements $LiveRoomJoinCopyWith<$Res> {
  _$LiveRoomJoinCopyWithImpl(this._self, this._then);

  final LiveRoomJoin _self;
  final $Res Function(LiveRoomJoin) _then;

/// Create a copy of LiveRoomJoin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = null,Object? domain = null,Object? room = null,Object? jwt = freezed,Object? subject = null,Object? displayName = null,Object? email = freezed,Object? moderator = null,Object? recording = null,}) {
  return _then(_self.copyWith(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,jwt: freezed == jwt ? _self.jwt : jwt // ignore: cast_nullable_to_non_nullable
as String?,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,moderator: null == moderator ? _self.moderator : moderator // ignore: cast_nullable_to_non_nullable
as bool,recording: null == recording ? _self.recording : recording // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveRoomJoin].
extension LiveRoomJoinPatterns on LiveRoomJoin {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveRoomJoin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveRoomJoin() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveRoomJoin value)  $default,){
final _that = this;
switch (_that) {
case _LiveRoomJoin():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveRoomJoin value)?  $default,){
final _that = this;
switch (_that) {
case _LiveRoomJoin() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String provider,  String domain,  String room,  String? jwt,  String subject,  String displayName,  String? email,  bool moderator,  bool recording)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveRoomJoin() when $default != null:
return $default(_that.provider,_that.domain,_that.room,_that.jwt,_that.subject,_that.displayName,_that.email,_that.moderator,_that.recording);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String provider,  String domain,  String room,  String? jwt,  String subject,  String displayName,  String? email,  bool moderator,  bool recording)  $default,) {final _that = this;
switch (_that) {
case _LiveRoomJoin():
return $default(_that.provider,_that.domain,_that.room,_that.jwt,_that.subject,_that.displayName,_that.email,_that.moderator,_that.recording);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String provider,  String domain,  String room,  String? jwt,  String subject,  String displayName,  String? email,  bool moderator,  bool recording)?  $default,) {final _that = this;
switch (_that) {
case _LiveRoomJoin() when $default != null:
return $default(_that.provider,_that.domain,_that.room,_that.jwt,_that.subject,_that.displayName,_that.email,_that.moderator,_that.recording);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveRoomJoin extends LiveRoomJoin {
  const _LiveRoomJoin({this.provider = 'jitsi', required this.domain, required this.room, this.jwt, this.subject = '', this.displayName = '', this.email, this.moderator = false, this.recording = false}): super._();
  factory _LiveRoomJoin.fromJson(Map<String, dynamic> json) => _$LiveRoomJoinFromJson(json);

@override@JsonKey() final  String provider;
@override final  String domain;
@override final  String room;
@override final  String? jwt;
@override@JsonKey() final  String subject;
@override@JsonKey() final  String displayName;
@override final  String? email;
@override@JsonKey() final  bool moderator;
@override@JsonKey() final  bool recording;

/// Create a copy of LiveRoomJoin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveRoomJoinCopyWith<_LiveRoomJoin> get copyWith => __$LiveRoomJoinCopyWithImpl<_LiveRoomJoin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveRoomJoinToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveRoomJoin&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.domain, domain) || other.domain == domain)&&(identical(other.room, room) || other.room == room)&&(identical(other.jwt, jwt) || other.jwt == jwt)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.moderator, moderator) || other.moderator == moderator)&&(identical(other.recording, recording) || other.recording == recording));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,domain,room,jwt,subject,displayName,email,moderator,recording);

@override
String toString() {
  return 'LiveRoomJoin(provider: $provider, domain: $domain, room: $room, jwt: $jwt, subject: $subject, displayName: $displayName, email: $email, moderator: $moderator, recording: $recording)';
}


}

/// @nodoc
abstract mixin class _$LiveRoomJoinCopyWith<$Res> implements $LiveRoomJoinCopyWith<$Res> {
  factory _$LiveRoomJoinCopyWith(_LiveRoomJoin value, $Res Function(_LiveRoomJoin) _then) = __$LiveRoomJoinCopyWithImpl;
@override @useResult
$Res call({
 String provider, String domain, String room, String? jwt, String subject, String displayName, String? email, bool moderator, bool recording
});




}
/// @nodoc
class __$LiveRoomJoinCopyWithImpl<$Res>
    implements _$LiveRoomJoinCopyWith<$Res> {
  __$LiveRoomJoinCopyWithImpl(this._self, this._then);

  final _LiveRoomJoin _self;
  final $Res Function(_LiveRoomJoin) _then;

/// Create a copy of LiveRoomJoin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? domain = null,Object? room = null,Object? jwt = freezed,Object? subject = null,Object? displayName = null,Object? email = freezed,Object? moderator = null,Object? recording = null,}) {
  return _then(_LiveRoomJoin(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,jwt: freezed == jwt ? _self.jwt : jwt // ignore: cast_nullable_to_non_nullable
as String?,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,moderator: null == moderator ? _self.moderator : moderator // ignore: cast_nullable_to_non_nullable
as bool,recording: null == recording ? _self.recording : recording // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$LiveJoin {

@JsonKey(unknownEnumValue: MeetingKind.unknown) MeetingKind get kind; LiveRoomJoin? get room; String? get link;
/// Create a copy of LiveJoin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveJoinCopyWith<LiveJoin> get copyWith => _$LiveJoinCopyWithImpl<LiveJoin>(this as LiveJoin, _$identity);

  /// Serializes this LiveJoin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveJoin&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.room, room) || other.room == room)&&(identical(other.link, link) || other.link == link));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,room,link);

@override
String toString() {
  return 'LiveJoin(kind: $kind, room: $room, link: $link)';
}


}

/// @nodoc
abstract mixin class $LiveJoinCopyWith<$Res>  {
  factory $LiveJoinCopyWith(LiveJoin value, $Res Function(LiveJoin) _then) = _$LiveJoinCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: MeetingKind.unknown) MeetingKind kind, LiveRoomJoin? room, String? link
});


$LiveRoomJoinCopyWith<$Res>? get room;

}
/// @nodoc
class _$LiveJoinCopyWithImpl<$Res>
    implements $LiveJoinCopyWith<$Res> {
  _$LiveJoinCopyWithImpl(this._self, this._then);

  final LiveJoin _self;
  final $Res Function(LiveJoin) _then;

/// Create a copy of LiveJoin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? room = freezed,Object? link = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MeetingKind,room: freezed == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as LiveRoomJoin?,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of LiveJoin
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveRoomJoinCopyWith<$Res>? get room {
    if (_self.room == null) {
    return null;
  }

  return $LiveRoomJoinCopyWith<$Res>(_self.room!, (value) {
    return _then(_self.copyWith(room: value));
  });
}
}


/// Adds pattern-matching-related methods to [LiveJoin].
extension LiveJoinPatterns on LiveJoin {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveJoin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveJoin() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveJoin value)  $default,){
final _that = this;
switch (_that) {
case _LiveJoin():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveJoin value)?  $default,){
final _that = this;
switch (_that) {
case _LiveJoin() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: MeetingKind.unknown)  MeetingKind kind,  LiveRoomJoin? room,  String? link)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveJoin() when $default != null:
return $default(_that.kind,_that.room,_that.link);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: MeetingKind.unknown)  MeetingKind kind,  LiveRoomJoin? room,  String? link)  $default,) {final _that = this;
switch (_that) {
case _LiveJoin():
return $default(_that.kind,_that.room,_that.link);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: MeetingKind.unknown)  MeetingKind kind,  LiveRoomJoin? room,  String? link)?  $default,) {final _that = this;
switch (_that) {
case _LiveJoin() when $default != null:
return $default(_that.kind,_that.room,_that.link);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveJoin implements LiveJoin {
  const _LiveJoin({@JsonKey(unknownEnumValue: MeetingKind.unknown) this.kind = MeetingKind.unknown, this.room, this.link});
  factory _LiveJoin.fromJson(Map<String, dynamic> json) => _$LiveJoinFromJson(json);

@override@JsonKey(unknownEnumValue: MeetingKind.unknown) final  MeetingKind kind;
@override final  LiveRoomJoin? room;
@override final  String? link;

/// Create a copy of LiveJoin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveJoinCopyWith<_LiveJoin> get copyWith => __$LiveJoinCopyWithImpl<_LiveJoin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveJoinToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveJoin&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.room, room) || other.room == room)&&(identical(other.link, link) || other.link == link));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,room,link);

@override
String toString() {
  return 'LiveJoin(kind: $kind, room: $room, link: $link)';
}


}

/// @nodoc
abstract mixin class _$LiveJoinCopyWith<$Res> implements $LiveJoinCopyWith<$Res> {
  factory _$LiveJoinCopyWith(_LiveJoin value, $Res Function(_LiveJoin) _then) = __$LiveJoinCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: MeetingKind.unknown) MeetingKind kind, LiveRoomJoin? room, String? link
});


@override $LiveRoomJoinCopyWith<$Res>? get room;

}
/// @nodoc
class __$LiveJoinCopyWithImpl<$Res>
    implements _$LiveJoinCopyWith<$Res> {
  __$LiveJoinCopyWithImpl(this._self, this._then);

  final _LiveJoin _self;
  final $Res Function(_LiveJoin) _then;

/// Create a copy of LiveJoin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? room = freezed,Object? link = freezed,}) {
  return _then(_LiveJoin(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MeetingKind,room: freezed == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as LiveRoomJoin?,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of LiveJoin
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveRoomJoinCopyWith<$Res>? get room {
    if (_self.room == null) {
    return null;
  }

  return $LiveRoomJoinCopyWith<$Res>(_self.room!, (value) {
    return _then(_self.copyWith(room: value));
  });
}
}

// dart format on
