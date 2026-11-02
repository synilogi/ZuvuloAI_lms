// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'staff_live.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StaffLiveRow {

 LiveClass get liveClass;@JsonKey(unknownEnumValue: LivePhase.unknown) LivePhase get phase; String get courseTitle; String get instructorName;
/// Create a copy of StaffLiveRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffLiveRowCopyWith<StaffLiveRow> get copyWith => _$StaffLiveRowCopyWithImpl<StaffLiveRow>(this as StaffLiveRow, _$identity);

  /// Serializes this StaffLiveRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffLiveRow&&(identical(other.liveClass, liveClass) || other.liveClass == liveClass)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.instructorName, instructorName) || other.instructorName == instructorName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,liveClass,phase,courseTitle,instructorName);

@override
String toString() {
  return 'StaffLiveRow(liveClass: $liveClass, phase: $phase, courseTitle: $courseTitle, instructorName: $instructorName)';
}


}

/// @nodoc
abstract mixin class $StaffLiveRowCopyWith<$Res>  {
  factory $StaffLiveRowCopyWith(StaffLiveRow value, $Res Function(StaffLiveRow) _then) = _$StaffLiveRowCopyWithImpl;
@useResult
$Res call({
 LiveClass liveClass,@JsonKey(unknownEnumValue: LivePhase.unknown) LivePhase phase, String courseTitle, String instructorName
});


$LiveClassCopyWith<$Res> get liveClass;

}
/// @nodoc
class _$StaffLiveRowCopyWithImpl<$Res>
    implements $StaffLiveRowCopyWith<$Res> {
  _$StaffLiveRowCopyWithImpl(this._self, this._then);

  final StaffLiveRow _self;
  final $Res Function(StaffLiveRow) _then;

/// Create a copy of StaffLiveRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? liveClass = null,Object? phase = null,Object? courseTitle = null,Object? instructorName = null,}) {
  return _then(_self.copyWith(
liveClass: null == liveClass ? _self.liveClass : liveClass // ignore: cast_nullable_to_non_nullable
as LiveClass,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as LivePhase,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,instructorName: null == instructorName ? _self.instructorName : instructorName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of StaffLiveRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveClassCopyWith<$Res> get liveClass {
  
  return $LiveClassCopyWith<$Res>(_self.liveClass, (value) {
    return _then(_self.copyWith(liveClass: value));
  });
}
}


/// Adds pattern-matching-related methods to [StaffLiveRow].
extension StaffLiveRowPatterns on StaffLiveRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffLiveRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffLiveRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffLiveRow value)  $default,){
final _that = this;
switch (_that) {
case _StaffLiveRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffLiveRow value)?  $default,){
final _that = this;
switch (_that) {
case _StaffLiveRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LiveClass liveClass, @JsonKey(unknownEnumValue: LivePhase.unknown)  LivePhase phase,  String courseTitle,  String instructorName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffLiveRow() when $default != null:
return $default(_that.liveClass,_that.phase,_that.courseTitle,_that.instructorName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LiveClass liveClass, @JsonKey(unknownEnumValue: LivePhase.unknown)  LivePhase phase,  String courseTitle,  String instructorName)  $default,) {final _that = this;
switch (_that) {
case _StaffLiveRow():
return $default(_that.liveClass,_that.phase,_that.courseTitle,_that.instructorName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LiveClass liveClass, @JsonKey(unknownEnumValue: LivePhase.unknown)  LivePhase phase,  String courseTitle,  String instructorName)?  $default,) {final _that = this;
switch (_that) {
case _StaffLiveRow() when $default != null:
return $default(_that.liveClass,_that.phase,_that.courseTitle,_that.instructorName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffLiveRow extends StaffLiveRow {
  const _StaffLiveRow({required this.liveClass, @JsonKey(unknownEnumValue: LivePhase.unknown) this.phase = LivePhase.unknown, this.courseTitle = '', this.instructorName = ''}): super._();
  factory _StaffLiveRow.fromJson(Map<String, dynamic> json) => _$StaffLiveRowFromJson(json);

@override final  LiveClass liveClass;
@override@JsonKey(unknownEnumValue: LivePhase.unknown) final  LivePhase phase;
@override@JsonKey() final  String courseTitle;
@override@JsonKey() final  String instructorName;

/// Create a copy of StaffLiveRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffLiveRowCopyWith<_StaffLiveRow> get copyWith => __$StaffLiveRowCopyWithImpl<_StaffLiveRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffLiveRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffLiveRow&&(identical(other.liveClass, liveClass) || other.liveClass == liveClass)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.instructorName, instructorName) || other.instructorName == instructorName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,liveClass,phase,courseTitle,instructorName);

@override
String toString() {
  return 'StaffLiveRow(liveClass: $liveClass, phase: $phase, courseTitle: $courseTitle, instructorName: $instructorName)';
}


}

/// @nodoc
abstract mixin class _$StaffLiveRowCopyWith<$Res> implements $StaffLiveRowCopyWith<$Res> {
  factory _$StaffLiveRowCopyWith(_StaffLiveRow value, $Res Function(_StaffLiveRow) _then) = __$StaffLiveRowCopyWithImpl;
@override @useResult
$Res call({
 LiveClass liveClass,@JsonKey(unknownEnumValue: LivePhase.unknown) LivePhase phase, String courseTitle, String instructorName
});


@override $LiveClassCopyWith<$Res> get liveClass;

}
/// @nodoc
class __$StaffLiveRowCopyWithImpl<$Res>
    implements _$StaffLiveRowCopyWith<$Res> {
  __$StaffLiveRowCopyWithImpl(this._self, this._then);

  final _StaffLiveRow _self;
  final $Res Function(_StaffLiveRow) _then;

/// Create a copy of StaffLiveRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? liveClass = null,Object? phase = null,Object? courseTitle = null,Object? instructorName = null,}) {
  return _then(_StaffLiveRow(
liveClass: null == liveClass ? _self.liveClass : liveClass // ignore: cast_nullable_to_non_nullable
as LiveClass,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as LivePhase,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,instructorName: null == instructorName ? _self.instructorName : instructorName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of StaffLiveRow
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
mixin _$StaffLivePage {

 List<StaffLiveRow> get rows; int get total; Map<String, int> get counts;
/// Create a copy of StaffLivePage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffLivePageCopyWith<StaffLivePage> get copyWith => _$StaffLivePageCopyWithImpl<StaffLivePage>(this as StaffLivePage, _$identity);

  /// Serializes this StaffLivePage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffLivePage&&const DeepCollectionEquality().equals(other.rows, rows)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.counts, counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rows),total,const DeepCollectionEquality().hash(counts));

@override
String toString() {
  return 'StaffLivePage(rows: $rows, total: $total, counts: $counts)';
}


}

/// @nodoc
abstract mixin class $StaffLivePageCopyWith<$Res>  {
  factory $StaffLivePageCopyWith(StaffLivePage value, $Res Function(StaffLivePage) _then) = _$StaffLivePageCopyWithImpl;
@useResult
$Res call({
 List<StaffLiveRow> rows, int total, Map<String, int> counts
});




}
/// @nodoc
class _$StaffLivePageCopyWithImpl<$Res>
    implements $StaffLivePageCopyWith<$Res> {
  _$StaffLivePageCopyWithImpl(this._self, this._then);

  final StaffLivePage _self;
  final $Res Function(StaffLivePage) _then;

/// Create a copy of StaffLivePage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? total = null,Object? counts = null,}) {
  return _then(_self.copyWith(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<StaffLiveRow>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffLivePage].
extension StaffLivePagePatterns on StaffLivePage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffLivePage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffLivePage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffLivePage value)  $default,){
final _that = this;
switch (_that) {
case _StaffLivePage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffLivePage value)?  $default,){
final _that = this;
switch (_that) {
case _StaffLivePage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<StaffLiveRow> rows,  int total,  Map<String, int> counts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffLivePage() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<StaffLiveRow> rows,  int total,  Map<String, int> counts)  $default,) {final _that = this;
switch (_that) {
case _StaffLivePage():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<StaffLiveRow> rows,  int total,  Map<String, int> counts)?  $default,) {final _that = this;
switch (_that) {
case _StaffLivePage() when $default != null:
return $default(_that.rows,_that.total,_that.counts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffLivePage extends StaffLivePage {
  const _StaffLivePage({final  List<StaffLiveRow> rows = const <StaffLiveRow>[], this.total = 0, final  Map<String, int> counts = const <String, int>{}}): _rows = rows,_counts = counts,super._();
  factory _StaffLivePage.fromJson(Map<String, dynamic> json) => _$StaffLivePageFromJson(json);

 final  List<StaffLiveRow> _rows;
@override@JsonKey() List<StaffLiveRow> get rows {
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


/// Create a copy of StaffLivePage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffLivePageCopyWith<_StaffLivePage> get copyWith => __$StaffLivePageCopyWithImpl<_StaffLivePage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffLivePageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffLivePage&&const DeepCollectionEquality().equals(other._rows, _rows)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._counts, _counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows),total,const DeepCollectionEquality().hash(_counts));

@override
String toString() {
  return 'StaffLivePage(rows: $rows, total: $total, counts: $counts)';
}


}

/// @nodoc
abstract mixin class _$StaffLivePageCopyWith<$Res> implements $StaffLivePageCopyWith<$Res> {
  factory _$StaffLivePageCopyWith(_StaffLivePage value, $Res Function(_StaffLivePage) _then) = __$StaffLivePageCopyWithImpl;
@override @useResult
$Res call({
 List<StaffLiveRow> rows, int total, Map<String, int> counts
});




}
/// @nodoc
class __$StaffLivePageCopyWithImpl<$Res>
    implements _$StaffLivePageCopyWith<$Res> {
  __$StaffLivePageCopyWithImpl(this._self, this._then);

  final _StaffLivePage _self;
  final $Res Function(_StaffLivePage) _then;

/// Create a copy of StaffLivePage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,Object? total = null,Object? counts = null,}) {
  return _then(_StaffLivePage(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<StaffLiveRow>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self._counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}


/// @nodoc
mixin _$LiveAttendee {

 String get id; String get name; String get city; bool? get attended;/// When they first went into the room.
@NullableUtcDateTimeConverter() DateTime? get joinedAt;
/// Create a copy of LiveAttendee
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveAttendeeCopyWith<LiveAttendee> get copyWith => _$LiveAttendeeCopyWithImpl<LiveAttendee>(this as LiveAttendee, _$identity);

  /// Serializes this LiveAttendee to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveAttendee&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.attended, attended) || other.attended == attended)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,city,attended,joinedAt);

@override
String toString() {
  return 'LiveAttendee(id: $id, name: $name, city: $city, attended: $attended, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class $LiveAttendeeCopyWith<$Res>  {
  factory $LiveAttendeeCopyWith(LiveAttendee value, $Res Function(LiveAttendee) _then) = _$LiveAttendeeCopyWithImpl;
@useResult
$Res call({
 String id, String name, String city, bool? attended,@NullableUtcDateTimeConverter() DateTime? joinedAt
});




}
/// @nodoc
class _$LiveAttendeeCopyWithImpl<$Res>
    implements $LiveAttendeeCopyWith<$Res> {
  _$LiveAttendeeCopyWithImpl(this._self, this._then);

  final LiveAttendee _self;
  final $Res Function(LiveAttendee) _then;

/// Create a copy of LiveAttendee
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? city = null,Object? attended = freezed,Object? joinedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,attended: freezed == attended ? _self.attended : attended // ignore: cast_nullable_to_non_nullable
as bool?,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveAttendee].
extension LiveAttendeePatterns on LiveAttendee {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveAttendee value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveAttendee() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveAttendee value)  $default,){
final _that = this;
switch (_that) {
case _LiveAttendee():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveAttendee value)?  $default,){
final _that = this;
switch (_that) {
case _LiveAttendee() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String city,  bool? attended, @NullableUtcDateTimeConverter()  DateTime? joinedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveAttendee() when $default != null:
return $default(_that.id,_that.name,_that.city,_that.attended,_that.joinedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String city,  bool? attended, @NullableUtcDateTimeConverter()  DateTime? joinedAt)  $default,) {final _that = this;
switch (_that) {
case _LiveAttendee():
return $default(_that.id,_that.name,_that.city,_that.attended,_that.joinedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String city,  bool? attended, @NullableUtcDateTimeConverter()  DateTime? joinedAt)?  $default,) {final _that = this;
switch (_that) {
case _LiveAttendee() when $default != null:
return $default(_that.id,_that.name,_that.city,_that.attended,_that.joinedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveAttendee implements LiveAttendee {
  const _LiveAttendee({this.id = '', this.name = '', this.city = '', this.attended, @NullableUtcDateTimeConverter() this.joinedAt});
  factory _LiveAttendee.fromJson(Map<String, dynamic> json) => _$LiveAttendeeFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String city;
@override final  bool? attended;
/// When they first went into the room.
@override@NullableUtcDateTimeConverter() final  DateTime? joinedAt;

/// Create a copy of LiveAttendee
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveAttendeeCopyWith<_LiveAttendee> get copyWith => __$LiveAttendeeCopyWithImpl<_LiveAttendee>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveAttendeeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveAttendee&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.attended, attended) || other.attended == attended)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,city,attended,joinedAt);

@override
String toString() {
  return 'LiveAttendee(id: $id, name: $name, city: $city, attended: $attended, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class _$LiveAttendeeCopyWith<$Res> implements $LiveAttendeeCopyWith<$Res> {
  factory _$LiveAttendeeCopyWith(_LiveAttendee value, $Res Function(_LiveAttendee) _then) = __$LiveAttendeeCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String city, bool? attended,@NullableUtcDateTimeConverter() DateTime? joinedAt
});




}
/// @nodoc
class __$LiveAttendeeCopyWithImpl<$Res>
    implements _$LiveAttendeeCopyWith<$Res> {
  __$LiveAttendeeCopyWithImpl(this._self, this._then);

  final _LiveAttendee _self;
  final $Res Function(_LiveAttendee) _then;

/// Create a copy of LiveAttendee
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? city = null,Object? attended = freezed,Object? joinedAt = freezed,}) {
  return _then(_LiveAttendee(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,attended: freezed == attended ? _self.attended : attended // ignore: cast_nullable_to_non_nullable
as bool?,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$LiveNeighbour {

 String get id; String get title;@NullableUtcDateTimeConverter() DateTime? get startsAt;
/// Create a copy of LiveNeighbour
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveNeighbourCopyWith<LiveNeighbour> get copyWith => _$LiveNeighbourCopyWithImpl<LiveNeighbour>(this as LiveNeighbour, _$identity);

  /// Serializes this LiveNeighbour to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveNeighbour&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,startsAt);

@override
String toString() {
  return 'LiveNeighbour(id: $id, title: $title, startsAt: $startsAt)';
}


}

/// @nodoc
abstract mixin class $LiveNeighbourCopyWith<$Res>  {
  factory $LiveNeighbourCopyWith(LiveNeighbour value, $Res Function(LiveNeighbour) _then) = _$LiveNeighbourCopyWithImpl;
@useResult
$Res call({
 String id, String title,@NullableUtcDateTimeConverter() DateTime? startsAt
});




}
/// @nodoc
class _$LiveNeighbourCopyWithImpl<$Res>
    implements $LiveNeighbourCopyWith<$Res> {
  _$LiveNeighbourCopyWithImpl(this._self, this._then);

  final LiveNeighbour _self;
  final $Res Function(LiveNeighbour) _then;

/// Create a copy of LiveNeighbour
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? startsAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveNeighbour].
extension LiveNeighbourPatterns on LiveNeighbour {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveNeighbour value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveNeighbour() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveNeighbour value)  $default,){
final _that = this;
switch (_that) {
case _LiveNeighbour():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveNeighbour value)?  $default,){
final _that = this;
switch (_that) {
case _LiveNeighbour() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title, @NullableUtcDateTimeConverter()  DateTime? startsAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveNeighbour() when $default != null:
return $default(_that.id,_that.title,_that.startsAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title, @NullableUtcDateTimeConverter()  DateTime? startsAt)  $default,) {final _that = this;
switch (_that) {
case _LiveNeighbour():
return $default(_that.id,_that.title,_that.startsAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title, @NullableUtcDateTimeConverter()  DateTime? startsAt)?  $default,) {final _that = this;
switch (_that) {
case _LiveNeighbour() when $default != null:
return $default(_that.id,_that.title,_that.startsAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveNeighbour implements LiveNeighbour {
  const _LiveNeighbour({this.id = '', this.title = '', @NullableUtcDateTimeConverter() this.startsAt});
  factory _LiveNeighbour.fromJson(Map<String, dynamic> json) => _$LiveNeighbourFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String title;
@override@NullableUtcDateTimeConverter() final  DateTime? startsAt;

/// Create a copy of LiveNeighbour
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveNeighbourCopyWith<_LiveNeighbour> get copyWith => __$LiveNeighbourCopyWithImpl<_LiveNeighbour>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveNeighbourToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveNeighbour&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,startsAt);

@override
String toString() {
  return 'LiveNeighbour(id: $id, title: $title, startsAt: $startsAt)';
}


}

/// @nodoc
abstract mixin class _$LiveNeighbourCopyWith<$Res> implements $LiveNeighbourCopyWith<$Res> {
  factory _$LiveNeighbourCopyWith(_LiveNeighbour value, $Res Function(_LiveNeighbour) _then) = __$LiveNeighbourCopyWithImpl;
@override @useResult
$Res call({
 String id, String title,@NullableUtcDateTimeConverter() DateTime? startsAt
});




}
/// @nodoc
class __$LiveNeighbourCopyWithImpl<$Res>
    implements _$LiveNeighbourCopyWith<$Res> {
  __$LiveNeighbourCopyWithImpl(this._self, this._then);

  final _LiveNeighbour _self;
  final $Res Function(_LiveNeighbour) _then;

/// Create a copy of LiveNeighbour
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? startsAt = freezed,}) {
  return _then(_LiveNeighbour(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$StaffLiveDetail {

 LiveClass get liveClass;@JsonKey(unknownEnumValue: LivePhase.unknown) LivePhase get phase; String get courseTitle; String get instructorName; String get instructorTitle; List<LiveAttendee> get attendees; int get attendeeTotal;/// How often the recording has been watched, where the academy counts it.
 int? get recordingViews; LiveNeighbour? get previous; LiveNeighbour? get next;/// What the built-in room can do at this academy.
 LiveRoomInfo? get room;
/// Create a copy of StaffLiveDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffLiveDetailCopyWith<StaffLiveDetail> get copyWith => _$StaffLiveDetailCopyWithImpl<StaffLiveDetail>(this as StaffLiveDetail, _$identity);

  /// Serializes this StaffLiveDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffLiveDetail&&(identical(other.liveClass, liveClass) || other.liveClass == liveClass)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.instructorName, instructorName) || other.instructorName == instructorName)&&(identical(other.instructorTitle, instructorTitle) || other.instructorTitle == instructorTitle)&&const DeepCollectionEquality().equals(other.attendees, attendees)&&(identical(other.attendeeTotal, attendeeTotal) || other.attendeeTotal == attendeeTotal)&&(identical(other.recordingViews, recordingViews) || other.recordingViews == recordingViews)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.next, next) || other.next == next)&&(identical(other.room, room) || other.room == room));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,liveClass,phase,courseTitle,instructorName,instructorTitle,const DeepCollectionEquality().hash(attendees),attendeeTotal,recordingViews,previous,next,room);

@override
String toString() {
  return 'StaffLiveDetail(liveClass: $liveClass, phase: $phase, courseTitle: $courseTitle, instructorName: $instructorName, instructorTitle: $instructorTitle, attendees: $attendees, attendeeTotal: $attendeeTotal, recordingViews: $recordingViews, previous: $previous, next: $next, room: $room)';
}


}

/// @nodoc
abstract mixin class $StaffLiveDetailCopyWith<$Res>  {
  factory $StaffLiveDetailCopyWith(StaffLiveDetail value, $Res Function(StaffLiveDetail) _then) = _$StaffLiveDetailCopyWithImpl;
@useResult
$Res call({
 LiveClass liveClass,@JsonKey(unknownEnumValue: LivePhase.unknown) LivePhase phase, String courseTitle, String instructorName, String instructorTitle, List<LiveAttendee> attendees, int attendeeTotal, int? recordingViews, LiveNeighbour? previous, LiveNeighbour? next, LiveRoomInfo? room
});


$LiveClassCopyWith<$Res> get liveClass;$LiveNeighbourCopyWith<$Res>? get previous;$LiveNeighbourCopyWith<$Res>? get next;$LiveRoomInfoCopyWith<$Res>? get room;

}
/// @nodoc
class _$StaffLiveDetailCopyWithImpl<$Res>
    implements $StaffLiveDetailCopyWith<$Res> {
  _$StaffLiveDetailCopyWithImpl(this._self, this._then);

  final StaffLiveDetail _self;
  final $Res Function(StaffLiveDetail) _then;

/// Create a copy of StaffLiveDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? liveClass = null,Object? phase = null,Object? courseTitle = null,Object? instructorName = null,Object? instructorTitle = null,Object? attendees = null,Object? attendeeTotal = null,Object? recordingViews = freezed,Object? previous = freezed,Object? next = freezed,Object? room = freezed,}) {
  return _then(_self.copyWith(
liveClass: null == liveClass ? _self.liveClass : liveClass // ignore: cast_nullable_to_non_nullable
as LiveClass,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as LivePhase,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,instructorName: null == instructorName ? _self.instructorName : instructorName // ignore: cast_nullable_to_non_nullable
as String,instructorTitle: null == instructorTitle ? _self.instructorTitle : instructorTitle // ignore: cast_nullable_to_non_nullable
as String,attendees: null == attendees ? _self.attendees : attendees // ignore: cast_nullable_to_non_nullable
as List<LiveAttendee>,attendeeTotal: null == attendeeTotal ? _self.attendeeTotal : attendeeTotal // ignore: cast_nullable_to_non_nullable
as int,recordingViews: freezed == recordingViews ? _self.recordingViews : recordingViews // ignore: cast_nullable_to_non_nullable
as int?,previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as LiveNeighbour?,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as LiveNeighbour?,room: freezed == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as LiveRoomInfo?,
  ));
}
/// Create a copy of StaffLiveDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveClassCopyWith<$Res> get liveClass {
  
  return $LiveClassCopyWith<$Res>(_self.liveClass, (value) {
    return _then(_self.copyWith(liveClass: value));
  });
}/// Create a copy of StaffLiveDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveNeighbourCopyWith<$Res>? get previous {
    if (_self.previous == null) {
    return null;
  }

  return $LiveNeighbourCopyWith<$Res>(_self.previous!, (value) {
    return _then(_self.copyWith(previous: value));
  });
}/// Create a copy of StaffLiveDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveNeighbourCopyWith<$Res>? get next {
    if (_self.next == null) {
    return null;
  }

  return $LiveNeighbourCopyWith<$Res>(_self.next!, (value) {
    return _then(_self.copyWith(next: value));
  });
}/// Create a copy of StaffLiveDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveRoomInfoCopyWith<$Res>? get room {
    if (_self.room == null) {
    return null;
  }

  return $LiveRoomInfoCopyWith<$Res>(_self.room!, (value) {
    return _then(_self.copyWith(room: value));
  });
}
}


/// Adds pattern-matching-related methods to [StaffLiveDetail].
extension StaffLiveDetailPatterns on StaffLiveDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffLiveDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffLiveDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffLiveDetail value)  $default,){
final _that = this;
switch (_that) {
case _StaffLiveDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffLiveDetail value)?  $default,){
final _that = this;
switch (_that) {
case _StaffLiveDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LiveClass liveClass, @JsonKey(unknownEnumValue: LivePhase.unknown)  LivePhase phase,  String courseTitle,  String instructorName,  String instructorTitle,  List<LiveAttendee> attendees,  int attendeeTotal,  int? recordingViews,  LiveNeighbour? previous,  LiveNeighbour? next,  LiveRoomInfo? room)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffLiveDetail() when $default != null:
return $default(_that.liveClass,_that.phase,_that.courseTitle,_that.instructorName,_that.instructorTitle,_that.attendees,_that.attendeeTotal,_that.recordingViews,_that.previous,_that.next,_that.room);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LiveClass liveClass, @JsonKey(unknownEnumValue: LivePhase.unknown)  LivePhase phase,  String courseTitle,  String instructorName,  String instructorTitle,  List<LiveAttendee> attendees,  int attendeeTotal,  int? recordingViews,  LiveNeighbour? previous,  LiveNeighbour? next,  LiveRoomInfo? room)  $default,) {final _that = this;
switch (_that) {
case _StaffLiveDetail():
return $default(_that.liveClass,_that.phase,_that.courseTitle,_that.instructorName,_that.instructorTitle,_that.attendees,_that.attendeeTotal,_that.recordingViews,_that.previous,_that.next,_that.room);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LiveClass liveClass, @JsonKey(unknownEnumValue: LivePhase.unknown)  LivePhase phase,  String courseTitle,  String instructorName,  String instructorTitle,  List<LiveAttendee> attendees,  int attendeeTotal,  int? recordingViews,  LiveNeighbour? previous,  LiveNeighbour? next,  LiveRoomInfo? room)?  $default,) {final _that = this;
switch (_that) {
case _StaffLiveDetail() when $default != null:
return $default(_that.liveClass,_that.phase,_that.courseTitle,_that.instructorName,_that.instructorTitle,_that.attendees,_that.attendeeTotal,_that.recordingViews,_that.previous,_that.next,_that.room);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffLiveDetail extends StaffLiveDetail {
  const _StaffLiveDetail({required this.liveClass, @JsonKey(unknownEnumValue: LivePhase.unknown) this.phase = LivePhase.unknown, this.courseTitle = '', this.instructorName = '', this.instructorTitle = '', final  List<LiveAttendee> attendees = const <LiveAttendee>[], this.attendeeTotal = 0, this.recordingViews, this.previous, this.next, this.room}): _attendees = attendees,super._();
  factory _StaffLiveDetail.fromJson(Map<String, dynamic> json) => _$StaffLiveDetailFromJson(json);

@override final  LiveClass liveClass;
@override@JsonKey(unknownEnumValue: LivePhase.unknown) final  LivePhase phase;
@override@JsonKey() final  String courseTitle;
@override@JsonKey() final  String instructorName;
@override@JsonKey() final  String instructorTitle;
 final  List<LiveAttendee> _attendees;
@override@JsonKey() List<LiveAttendee> get attendees {
  if (_attendees is EqualUnmodifiableListView) return _attendees;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attendees);
}

@override@JsonKey() final  int attendeeTotal;
/// How often the recording has been watched, where the academy counts it.
@override final  int? recordingViews;
@override final  LiveNeighbour? previous;
@override final  LiveNeighbour? next;
/// What the built-in room can do at this academy.
@override final  LiveRoomInfo? room;

/// Create a copy of StaffLiveDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffLiveDetailCopyWith<_StaffLiveDetail> get copyWith => __$StaffLiveDetailCopyWithImpl<_StaffLiveDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffLiveDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffLiveDetail&&(identical(other.liveClass, liveClass) || other.liveClass == liveClass)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.instructorName, instructorName) || other.instructorName == instructorName)&&(identical(other.instructorTitle, instructorTitle) || other.instructorTitle == instructorTitle)&&const DeepCollectionEquality().equals(other._attendees, _attendees)&&(identical(other.attendeeTotal, attendeeTotal) || other.attendeeTotal == attendeeTotal)&&(identical(other.recordingViews, recordingViews) || other.recordingViews == recordingViews)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.next, next) || other.next == next)&&(identical(other.room, room) || other.room == room));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,liveClass,phase,courseTitle,instructorName,instructorTitle,const DeepCollectionEquality().hash(_attendees),attendeeTotal,recordingViews,previous,next,room);

@override
String toString() {
  return 'StaffLiveDetail(liveClass: $liveClass, phase: $phase, courseTitle: $courseTitle, instructorName: $instructorName, instructorTitle: $instructorTitle, attendees: $attendees, attendeeTotal: $attendeeTotal, recordingViews: $recordingViews, previous: $previous, next: $next, room: $room)';
}


}

/// @nodoc
abstract mixin class _$StaffLiveDetailCopyWith<$Res> implements $StaffLiveDetailCopyWith<$Res> {
  factory _$StaffLiveDetailCopyWith(_StaffLiveDetail value, $Res Function(_StaffLiveDetail) _then) = __$StaffLiveDetailCopyWithImpl;
@override @useResult
$Res call({
 LiveClass liveClass,@JsonKey(unknownEnumValue: LivePhase.unknown) LivePhase phase, String courseTitle, String instructorName, String instructorTitle, List<LiveAttendee> attendees, int attendeeTotal, int? recordingViews, LiveNeighbour? previous, LiveNeighbour? next, LiveRoomInfo? room
});


@override $LiveClassCopyWith<$Res> get liveClass;@override $LiveNeighbourCopyWith<$Res>? get previous;@override $LiveNeighbourCopyWith<$Res>? get next;@override $LiveRoomInfoCopyWith<$Res>? get room;

}
/// @nodoc
class __$StaffLiveDetailCopyWithImpl<$Res>
    implements _$StaffLiveDetailCopyWith<$Res> {
  __$StaffLiveDetailCopyWithImpl(this._self, this._then);

  final _StaffLiveDetail _self;
  final $Res Function(_StaffLiveDetail) _then;

/// Create a copy of StaffLiveDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? liveClass = null,Object? phase = null,Object? courseTitle = null,Object? instructorName = null,Object? instructorTitle = null,Object? attendees = null,Object? attendeeTotal = null,Object? recordingViews = freezed,Object? previous = freezed,Object? next = freezed,Object? room = freezed,}) {
  return _then(_StaffLiveDetail(
liveClass: null == liveClass ? _self.liveClass : liveClass // ignore: cast_nullable_to_non_nullable
as LiveClass,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as LivePhase,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,instructorName: null == instructorName ? _self.instructorName : instructorName // ignore: cast_nullable_to_non_nullable
as String,instructorTitle: null == instructorTitle ? _self.instructorTitle : instructorTitle // ignore: cast_nullable_to_non_nullable
as String,attendees: null == attendees ? _self._attendees : attendees // ignore: cast_nullable_to_non_nullable
as List<LiveAttendee>,attendeeTotal: null == attendeeTotal ? _self.attendeeTotal : attendeeTotal // ignore: cast_nullable_to_non_nullable
as int,recordingViews: freezed == recordingViews ? _self.recordingViews : recordingViews // ignore: cast_nullable_to_non_nullable
as int?,previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as LiveNeighbour?,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as LiveNeighbour?,room: freezed == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as LiveRoomInfo?,
  ));
}

/// Create a copy of StaffLiveDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveClassCopyWith<$Res> get liveClass {
  
  return $LiveClassCopyWith<$Res>(_self.liveClass, (value) {
    return _then(_self.copyWith(liveClass: value));
  });
}/// Create a copy of StaffLiveDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveNeighbourCopyWith<$Res>? get previous {
    if (_self.previous == null) {
    return null;
  }

  return $LiveNeighbourCopyWith<$Res>(_self.previous!, (value) {
    return _then(_self.copyWith(previous: value));
  });
}/// Create a copy of StaffLiveDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveNeighbourCopyWith<$Res>? get next {
    if (_self.next == null) {
    return null;
  }

  return $LiveNeighbourCopyWith<$Res>(_self.next!, (value) {
    return _then(_self.copyWith(next: value));
  });
}/// Create a copy of StaffLiveDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveRoomInfoCopyWith<$Res>? get room {
    if (_self.room == null) {
    return null;
  }

  return $LiveRoomInfoCopyWith<$Res>(_self.room!, (value) {
    return _then(_self.copyWith(room: value));
  });
}
}


/// @nodoc
mixin _$LiveRoomInfo {

 String get provider; bool get recording; bool get canStart;
/// Create a copy of LiveRoomInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveRoomInfoCopyWith<LiveRoomInfo> get copyWith => _$LiveRoomInfoCopyWithImpl<LiveRoomInfo>(this as LiveRoomInfo, _$identity);

  /// Serializes this LiveRoomInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveRoomInfo&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.recording, recording) || other.recording == recording)&&(identical(other.canStart, canStart) || other.canStart == canStart));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,recording,canStart);

@override
String toString() {
  return 'LiveRoomInfo(provider: $provider, recording: $recording, canStart: $canStart)';
}


}

/// @nodoc
abstract mixin class $LiveRoomInfoCopyWith<$Res>  {
  factory $LiveRoomInfoCopyWith(LiveRoomInfo value, $Res Function(LiveRoomInfo) _then) = _$LiveRoomInfoCopyWithImpl;
@useResult
$Res call({
 String provider, bool recording, bool canStart
});




}
/// @nodoc
class _$LiveRoomInfoCopyWithImpl<$Res>
    implements $LiveRoomInfoCopyWith<$Res> {
  _$LiveRoomInfoCopyWithImpl(this._self, this._then);

  final LiveRoomInfo _self;
  final $Res Function(LiveRoomInfo) _then;

/// Create a copy of LiveRoomInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = null,Object? recording = null,Object? canStart = null,}) {
  return _then(_self.copyWith(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,recording: null == recording ? _self.recording : recording // ignore: cast_nullable_to_non_nullable
as bool,canStart: null == canStart ? _self.canStart : canStart // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveRoomInfo].
extension LiveRoomInfoPatterns on LiveRoomInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveRoomInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveRoomInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveRoomInfo value)  $default,){
final _that = this;
switch (_that) {
case _LiveRoomInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveRoomInfo value)?  $default,){
final _that = this;
switch (_that) {
case _LiveRoomInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String provider,  bool recording,  bool canStart)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveRoomInfo() when $default != null:
return $default(_that.provider,_that.recording,_that.canStart);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String provider,  bool recording,  bool canStart)  $default,) {final _that = this;
switch (_that) {
case _LiveRoomInfo():
return $default(_that.provider,_that.recording,_that.canStart);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String provider,  bool recording,  bool canStart)?  $default,) {final _that = this;
switch (_that) {
case _LiveRoomInfo() when $default != null:
return $default(_that.provider,_that.recording,_that.canStart);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveRoomInfo implements LiveRoomInfo {
  const _LiveRoomInfo({this.provider = 'jitsi', this.recording = false, this.canStart = false});
  factory _LiveRoomInfo.fromJson(Map<String, dynamic> json) => _$LiveRoomInfoFromJson(json);

@override@JsonKey() final  String provider;
@override@JsonKey() final  bool recording;
@override@JsonKey() final  bool canStart;

/// Create a copy of LiveRoomInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveRoomInfoCopyWith<_LiveRoomInfo> get copyWith => __$LiveRoomInfoCopyWithImpl<_LiveRoomInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveRoomInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveRoomInfo&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.recording, recording) || other.recording == recording)&&(identical(other.canStart, canStart) || other.canStart == canStart));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,recording,canStart);

@override
String toString() {
  return 'LiveRoomInfo(provider: $provider, recording: $recording, canStart: $canStart)';
}


}

/// @nodoc
abstract mixin class _$LiveRoomInfoCopyWith<$Res> implements $LiveRoomInfoCopyWith<$Res> {
  factory _$LiveRoomInfoCopyWith(_LiveRoomInfo value, $Res Function(_LiveRoomInfo) _then) = __$LiveRoomInfoCopyWithImpl;
@override @useResult
$Res call({
 String provider, bool recording, bool canStart
});




}
/// @nodoc
class __$LiveRoomInfoCopyWithImpl<$Res>
    implements _$LiveRoomInfoCopyWith<$Res> {
  __$LiveRoomInfoCopyWithImpl(this._self, this._then);

  final _LiveRoomInfo _self;
  final $Res Function(_LiveRoomInfo) _then;

/// Create a copy of LiveRoomInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? recording = null,Object? canStart = null,}) {
  return _then(_LiveRoomInfo(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,recording: null == recording ? _self.recording : recording // ignore: cast_nullable_to_non_nullable
as bool,canStart: null == canStart ? _self.canStart : canStart // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$LiveStarted {

 LiveClass get liveClass; LiveRoomJoin get room;
/// Create a copy of LiveStarted
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveStartedCopyWith<LiveStarted> get copyWith => _$LiveStartedCopyWithImpl<LiveStarted>(this as LiveStarted, _$identity);

  /// Serializes this LiveStarted to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveStarted&&(identical(other.liveClass, liveClass) || other.liveClass == liveClass)&&(identical(other.room, room) || other.room == room));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,liveClass,room);

@override
String toString() {
  return 'LiveStarted(liveClass: $liveClass, room: $room)';
}


}

/// @nodoc
abstract mixin class $LiveStartedCopyWith<$Res>  {
  factory $LiveStartedCopyWith(LiveStarted value, $Res Function(LiveStarted) _then) = _$LiveStartedCopyWithImpl;
@useResult
$Res call({
 LiveClass liveClass, LiveRoomJoin room
});


$LiveClassCopyWith<$Res> get liveClass;$LiveRoomJoinCopyWith<$Res> get room;

}
/// @nodoc
class _$LiveStartedCopyWithImpl<$Res>
    implements $LiveStartedCopyWith<$Res> {
  _$LiveStartedCopyWithImpl(this._self, this._then);

  final LiveStarted _self;
  final $Res Function(LiveStarted) _then;

/// Create a copy of LiveStarted
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? liveClass = null,Object? room = null,}) {
  return _then(_self.copyWith(
liveClass: null == liveClass ? _self.liveClass : liveClass // ignore: cast_nullable_to_non_nullable
as LiveClass,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as LiveRoomJoin,
  ));
}
/// Create a copy of LiveStarted
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveClassCopyWith<$Res> get liveClass {
  
  return $LiveClassCopyWith<$Res>(_self.liveClass, (value) {
    return _then(_self.copyWith(liveClass: value));
  });
}/// Create a copy of LiveStarted
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveRoomJoinCopyWith<$Res> get room {
  
  return $LiveRoomJoinCopyWith<$Res>(_self.room, (value) {
    return _then(_self.copyWith(room: value));
  });
}
}


/// Adds pattern-matching-related methods to [LiveStarted].
extension LiveStartedPatterns on LiveStarted {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveStarted value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveStarted() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveStarted value)  $default,){
final _that = this;
switch (_that) {
case _LiveStarted():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveStarted value)?  $default,){
final _that = this;
switch (_that) {
case _LiveStarted() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LiveClass liveClass,  LiveRoomJoin room)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveStarted() when $default != null:
return $default(_that.liveClass,_that.room);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LiveClass liveClass,  LiveRoomJoin room)  $default,) {final _that = this;
switch (_that) {
case _LiveStarted():
return $default(_that.liveClass,_that.room);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LiveClass liveClass,  LiveRoomJoin room)?  $default,) {final _that = this;
switch (_that) {
case _LiveStarted() when $default != null:
return $default(_that.liveClass,_that.room);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveStarted implements LiveStarted {
  const _LiveStarted({required this.liveClass, required this.room});
  factory _LiveStarted.fromJson(Map<String, dynamic> json) => _$LiveStartedFromJson(json);

@override final  LiveClass liveClass;
@override final  LiveRoomJoin room;

/// Create a copy of LiveStarted
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveStartedCopyWith<_LiveStarted> get copyWith => __$LiveStartedCopyWithImpl<_LiveStarted>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveStartedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveStarted&&(identical(other.liveClass, liveClass) || other.liveClass == liveClass)&&(identical(other.room, room) || other.room == room));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,liveClass,room);

@override
String toString() {
  return 'LiveStarted(liveClass: $liveClass, room: $room)';
}


}

/// @nodoc
abstract mixin class _$LiveStartedCopyWith<$Res> implements $LiveStartedCopyWith<$Res> {
  factory _$LiveStartedCopyWith(_LiveStarted value, $Res Function(_LiveStarted) _then) = __$LiveStartedCopyWithImpl;
@override @useResult
$Res call({
 LiveClass liveClass, LiveRoomJoin room
});


@override $LiveClassCopyWith<$Res> get liveClass;@override $LiveRoomJoinCopyWith<$Res> get room;

}
/// @nodoc
class __$LiveStartedCopyWithImpl<$Res>
    implements _$LiveStartedCopyWith<$Res> {
  __$LiveStartedCopyWithImpl(this._self, this._then);

  final _LiveStarted _self;
  final $Res Function(_LiveStarted) _then;

/// Create a copy of LiveStarted
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? liveClass = null,Object? room = null,}) {
  return _then(_LiveStarted(
liveClass: null == liveClass ? _self.liveClass : liveClass // ignore: cast_nullable_to_non_nullable
as LiveClass,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as LiveRoomJoin,
  ));
}

/// Create a copy of LiveStarted
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveClassCopyWith<$Res> get liveClass {
  
  return $LiveClassCopyWith<$Res>(_self.liveClass, (value) {
    return _then(_self.copyWith(liveClass: value));
  });
}/// Create a copy of LiveStarted
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LiveRoomJoinCopyWith<$Res> get room {
  
  return $LiveRoomJoinCopyWith<$Res>(_self.room, (value) {
    return _then(_self.copyWith(room: value));
  });
}
}

/// @nodoc
mixin _$LiveClassForm {

 String get courseId; String get title; String get instructorId; DateTime? get startsAt; int get durationMin; int? get capacity; String get description; List<AgendaItem> get agenda; LiveVisibility get visibility; MeetingKind get meetingKind; String get meetingLink; List<int> get reminders; String? get chapterId;
/// Create a copy of LiveClassForm
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveClassFormCopyWith<LiveClassForm> get copyWith => _$LiveClassFormCopyWithImpl<LiveClassForm>(this as LiveClassForm, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveClassForm&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.title, title) || other.title == title)&&(identical(other.instructorId, instructorId) || other.instructorId == instructorId)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.agenda, agenda)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.meetingKind, meetingKind) || other.meetingKind == meetingKind)&&(identical(other.meetingLink, meetingLink) || other.meetingLink == meetingLink)&&const DeepCollectionEquality().equals(other.reminders, reminders)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId));
}


@override
int get hashCode => Object.hash(runtimeType,courseId,title,instructorId,startsAt,durationMin,capacity,description,const DeepCollectionEquality().hash(agenda),visibility,meetingKind,meetingLink,const DeepCollectionEquality().hash(reminders),chapterId);

@override
String toString() {
  return 'LiveClassForm(courseId: $courseId, title: $title, instructorId: $instructorId, startsAt: $startsAt, durationMin: $durationMin, capacity: $capacity, description: $description, agenda: $agenda, visibility: $visibility, meetingKind: $meetingKind, meetingLink: $meetingLink, reminders: $reminders, chapterId: $chapterId)';
}


}

/// @nodoc
abstract mixin class $LiveClassFormCopyWith<$Res>  {
  factory $LiveClassFormCopyWith(LiveClassForm value, $Res Function(LiveClassForm) _then) = _$LiveClassFormCopyWithImpl;
@useResult
$Res call({
 String courseId, String title, String instructorId, DateTime? startsAt, int durationMin, int? capacity, String description, List<AgendaItem> agenda, LiveVisibility visibility, MeetingKind meetingKind, String meetingLink, List<int> reminders, String? chapterId
});




}
/// @nodoc
class _$LiveClassFormCopyWithImpl<$Res>
    implements $LiveClassFormCopyWith<$Res> {
  _$LiveClassFormCopyWithImpl(this._self, this._then);

  final LiveClassForm _self;
  final $Res Function(LiveClassForm) _then;

/// Create a copy of LiveClassForm
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? courseId = null,Object? title = null,Object? instructorId = null,Object? startsAt = freezed,Object? durationMin = null,Object? capacity = freezed,Object? description = null,Object? agenda = null,Object? visibility = null,Object? meetingKind = null,Object? meetingLink = null,Object? reminders = null,Object? chapterId = freezed,}) {
  return _then(_self.copyWith(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,instructorId: null == instructorId ? _self.instructorId : instructorId // ignore: cast_nullable_to_non_nullable
as String,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,durationMin: null == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,agenda: null == agenda ? _self.agenda : agenda // ignore: cast_nullable_to_non_nullable
as List<AgendaItem>,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as LiveVisibility,meetingKind: null == meetingKind ? _self.meetingKind : meetingKind // ignore: cast_nullable_to_non_nullable
as MeetingKind,meetingLink: null == meetingLink ? _self.meetingLink : meetingLink // ignore: cast_nullable_to_non_nullable
as String,reminders: null == reminders ? _self.reminders : reminders // ignore: cast_nullable_to_non_nullable
as List<int>,chapterId: freezed == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveClassForm].
extension LiveClassFormPatterns on LiveClassForm {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveClassForm value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveClassForm() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveClassForm value)  $default,){
final _that = this;
switch (_that) {
case _LiveClassForm():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveClassForm value)?  $default,){
final _that = this;
switch (_that) {
case _LiveClassForm() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String courseId,  String title,  String instructorId,  DateTime? startsAt,  int durationMin,  int? capacity,  String description,  List<AgendaItem> agenda,  LiveVisibility visibility,  MeetingKind meetingKind,  String meetingLink,  List<int> reminders,  String? chapterId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveClassForm() when $default != null:
return $default(_that.courseId,_that.title,_that.instructorId,_that.startsAt,_that.durationMin,_that.capacity,_that.description,_that.agenda,_that.visibility,_that.meetingKind,_that.meetingLink,_that.reminders,_that.chapterId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String courseId,  String title,  String instructorId,  DateTime? startsAt,  int durationMin,  int? capacity,  String description,  List<AgendaItem> agenda,  LiveVisibility visibility,  MeetingKind meetingKind,  String meetingLink,  List<int> reminders,  String? chapterId)  $default,) {final _that = this;
switch (_that) {
case _LiveClassForm():
return $default(_that.courseId,_that.title,_that.instructorId,_that.startsAt,_that.durationMin,_that.capacity,_that.description,_that.agenda,_that.visibility,_that.meetingKind,_that.meetingLink,_that.reminders,_that.chapterId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String courseId,  String title,  String instructorId,  DateTime? startsAt,  int durationMin,  int? capacity,  String description,  List<AgendaItem> agenda,  LiveVisibility visibility,  MeetingKind meetingKind,  String meetingLink,  List<int> reminders,  String? chapterId)?  $default,) {final _that = this;
switch (_that) {
case _LiveClassForm() when $default != null:
return $default(_that.courseId,_that.title,_that.instructorId,_that.startsAt,_that.durationMin,_that.capacity,_that.description,_that.agenda,_that.visibility,_that.meetingKind,_that.meetingLink,_that.reminders,_that.chapterId);case _:
  return null;

}
}

}

/// @nodoc


class _LiveClassForm extends LiveClassForm {
  const _LiveClassForm({this.courseId = '', this.title = '', this.instructorId = '', this.startsAt, this.durationMin = 60, this.capacity, this.description = '', final  List<AgendaItem> agenda = const <AgendaItem>[], this.visibility = LiveVisibility.enrolled, this.meetingKind = MeetingKind.room, this.meetingLink = '', final  List<int> reminders = const <int>[], this.chapterId}): _agenda = agenda,_reminders = reminders,super._();
  

@override@JsonKey() final  String courseId;
@override@JsonKey() final  String title;
@override@JsonKey() final  String instructorId;
@override final  DateTime? startsAt;
@override@JsonKey() final  int durationMin;
@override final  int? capacity;
@override@JsonKey() final  String description;
 final  List<AgendaItem> _agenda;
@override@JsonKey() List<AgendaItem> get agenda {
  if (_agenda is EqualUnmodifiableListView) return _agenda;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_agenda);
}

@override@JsonKey() final  LiveVisibility visibility;
@override@JsonKey() final  MeetingKind meetingKind;
@override@JsonKey() final  String meetingLink;
 final  List<int> _reminders;
@override@JsonKey() List<int> get reminders {
  if (_reminders is EqualUnmodifiableListView) return _reminders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reminders);
}

@override final  String? chapterId;

/// Create a copy of LiveClassForm
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveClassFormCopyWith<_LiveClassForm> get copyWith => __$LiveClassFormCopyWithImpl<_LiveClassForm>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveClassForm&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.title, title) || other.title == title)&&(identical(other.instructorId, instructorId) || other.instructorId == instructorId)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._agenda, _agenda)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.meetingKind, meetingKind) || other.meetingKind == meetingKind)&&(identical(other.meetingLink, meetingLink) || other.meetingLink == meetingLink)&&const DeepCollectionEquality().equals(other._reminders, _reminders)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId));
}


@override
int get hashCode => Object.hash(runtimeType,courseId,title,instructorId,startsAt,durationMin,capacity,description,const DeepCollectionEquality().hash(_agenda),visibility,meetingKind,meetingLink,const DeepCollectionEquality().hash(_reminders),chapterId);

@override
String toString() {
  return 'LiveClassForm(courseId: $courseId, title: $title, instructorId: $instructorId, startsAt: $startsAt, durationMin: $durationMin, capacity: $capacity, description: $description, agenda: $agenda, visibility: $visibility, meetingKind: $meetingKind, meetingLink: $meetingLink, reminders: $reminders, chapterId: $chapterId)';
}


}

/// @nodoc
abstract mixin class _$LiveClassFormCopyWith<$Res> implements $LiveClassFormCopyWith<$Res> {
  factory _$LiveClassFormCopyWith(_LiveClassForm value, $Res Function(_LiveClassForm) _then) = __$LiveClassFormCopyWithImpl;
@override @useResult
$Res call({
 String courseId, String title, String instructorId, DateTime? startsAt, int durationMin, int? capacity, String description, List<AgendaItem> agenda, LiveVisibility visibility, MeetingKind meetingKind, String meetingLink, List<int> reminders, String? chapterId
});




}
/// @nodoc
class __$LiveClassFormCopyWithImpl<$Res>
    implements _$LiveClassFormCopyWith<$Res> {
  __$LiveClassFormCopyWithImpl(this._self, this._then);

  final _LiveClassForm _self;
  final $Res Function(_LiveClassForm) _then;

/// Create a copy of LiveClassForm
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? courseId = null,Object? title = null,Object? instructorId = null,Object? startsAt = freezed,Object? durationMin = null,Object? capacity = freezed,Object? description = null,Object? agenda = null,Object? visibility = null,Object? meetingKind = null,Object? meetingLink = null,Object? reminders = null,Object? chapterId = freezed,}) {
  return _then(_LiveClassForm(
courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,instructorId: null == instructorId ? _self.instructorId : instructorId // ignore: cast_nullable_to_non_nullable
as String,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,durationMin: null == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,agenda: null == agenda ? _self._agenda : agenda // ignore: cast_nullable_to_non_nullable
as List<AgendaItem>,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as LiveVisibility,meetingKind: null == meetingKind ? _self.meetingKind : meetingKind // ignore: cast_nullable_to_non_nullable
as MeetingKind,meetingLink: null == meetingLink ? _self.meetingLink : meetingLink // ignore: cast_nullable_to_non_nullable
as String,reminders: null == reminders ? _self._reminders : reminders // ignore: cast_nullable_to_non_nullable
as List<int>,chapterId: freezed == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
