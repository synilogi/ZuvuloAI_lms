// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lesson_view.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LessonLink {

 String get id; String get title; bool get locked;
/// Create a copy of LessonLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonLinkCopyWith<LessonLink> get copyWith => _$LessonLinkCopyWithImpl<LessonLink>(this as LessonLink, _$identity);

  /// Serializes this LessonLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonLink&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.locked, locked) || other.locked == locked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,locked);

@override
String toString() {
  return 'LessonLink(id: $id, title: $title, locked: $locked)';
}


}

/// @nodoc
abstract mixin class $LessonLinkCopyWith<$Res>  {
  factory $LessonLinkCopyWith(LessonLink value, $Res Function(LessonLink) _then) = _$LessonLinkCopyWithImpl;
@useResult
$Res call({
 String id, String title, bool locked
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? locked = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  bool locked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonLink() when $default != null:
return $default(_that.id,_that.title,_that.locked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  bool locked)  $default,) {final _that = this;
switch (_that) {
case _LessonLink():
return $default(_that.id,_that.title,_that.locked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  bool locked)?  $default,) {final _that = this;
switch (_that) {
case _LessonLink() when $default != null:
return $default(_that.id,_that.title,_that.locked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonLink implements LessonLink {
  const _LessonLink({required this.id, this.title = '', this.locked = false});
  factory _LessonLink.fromJson(Map<String, dynamic> json) => _$LessonLinkFromJson(json);

@override final  String id;
@override@JsonKey() final  String title;
@override@JsonKey() final  bool locked;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonLink&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.locked, locked) || other.locked == locked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,locked);

@override
String toString() {
  return 'LessonLink(id: $id, title: $title, locked: $locked)';
}


}

/// @nodoc
abstract mixin class _$LessonLinkCopyWith<$Res> implements $LessonLinkCopyWith<$Res> {
  factory _$LessonLinkCopyWith(_LessonLink value, $Res Function(_LessonLink) _then) = __$LessonLinkCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, bool locked
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? locked = null,}) {
  return _then(_LessonLink(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$LessonPosition {

 int get index; int get total;
/// Create a copy of LessonPosition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonPositionCopyWith<LessonPosition> get copyWith => _$LessonPositionCopyWithImpl<LessonPosition>(this as LessonPosition, _$identity);

  /// Serializes this LessonPosition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonPosition&&(identical(other.index, index) || other.index == index)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,total);

@override
String toString() {
  return 'LessonPosition(index: $index, total: $total)';
}


}

/// @nodoc
abstract mixin class $LessonPositionCopyWith<$Res>  {
  factory $LessonPositionCopyWith(LessonPosition value, $Res Function(LessonPosition) _then) = _$LessonPositionCopyWithImpl;
@useResult
$Res call({
 int index, int total
});




}
/// @nodoc
class _$LessonPositionCopyWithImpl<$Res>
    implements $LessonPositionCopyWith<$Res> {
  _$LessonPositionCopyWithImpl(this._self, this._then);

  final LessonPosition _self;
  final $Res Function(LessonPosition) _then;

/// Create a copy of LessonPosition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? total = null,}) {
  return _then(_self.copyWith(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonPosition].
extension LessonPositionPatterns on LessonPosition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonPosition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonPosition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonPosition value)  $default,){
final _that = this;
switch (_that) {
case _LessonPosition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonPosition value)?  $default,){
final _that = this;
switch (_that) {
case _LessonPosition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonPosition() when $default != null:
return $default(_that.index,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  int total)  $default,) {final _that = this;
switch (_that) {
case _LessonPosition():
return $default(_that.index,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  int total)?  $default,) {final _that = this;
switch (_that) {
case _LessonPosition() when $default != null:
return $default(_that.index,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonPosition extends LessonPosition {
  const _LessonPosition({this.index = 0, this.total = 0}): super._();
  factory _LessonPosition.fromJson(Map<String, dynamic> json) => _$LessonPositionFromJson(json);

@override@JsonKey() final  int index;
@override@JsonKey() final  int total;

/// Create a copy of LessonPosition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonPositionCopyWith<_LessonPosition> get copyWith => __$LessonPositionCopyWithImpl<_LessonPosition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonPositionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonPosition&&(identical(other.index, index) || other.index == index)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,index,total);

@override
String toString() {
  return 'LessonPosition(index: $index, total: $total)';
}


}

/// @nodoc
abstract mixin class _$LessonPositionCopyWith<$Res> implements $LessonPositionCopyWith<$Res> {
  factory _$LessonPositionCopyWith(_LessonPosition value, $Res Function(_LessonPosition) _then) = __$LessonPositionCopyWithImpl;
@override @useResult
$Res call({
 int index, int total
});




}
/// @nodoc
class __$LessonPositionCopyWithImpl<$Res>
    implements _$LessonPositionCopyWith<$Res> {
  __$LessonPositionCopyWithImpl(this._self, this._then);

  final _LessonPosition _self;
  final $Res Function(_LessonPosition) _then;

/// Create a copy of LessonPosition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? total = null,}) {
  return _then(_LessonPosition(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$LessonAssignmentSummary {

 String get id; String get title;/// The server's own word: not-started, draft, submitted, under-review, graded, overdue, closed.
 String get state;@NullableUtcDateTimeConverter() DateTime? get dueAt;
/// Create a copy of LessonAssignmentSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonAssignmentSummaryCopyWith<LessonAssignmentSummary> get copyWith => _$LessonAssignmentSummaryCopyWithImpl<LessonAssignmentSummary>(this as LessonAssignmentSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonAssignmentSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.state, state) || other.state == state)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,state,dueAt);

@override
String toString() {
  return 'LessonAssignmentSummary(id: $id, title: $title, state: $state, dueAt: $dueAt)';
}


}

/// @nodoc
abstract mixin class $LessonAssignmentSummaryCopyWith<$Res>  {
  factory $LessonAssignmentSummaryCopyWith(LessonAssignmentSummary value, $Res Function(LessonAssignmentSummary) _then) = _$LessonAssignmentSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String title, String state,@NullableUtcDateTimeConverter() DateTime? dueAt
});




}
/// @nodoc
class _$LessonAssignmentSummaryCopyWithImpl<$Res>
    implements $LessonAssignmentSummaryCopyWith<$Res> {
  _$LessonAssignmentSummaryCopyWithImpl(this._self, this._then);

  final LessonAssignmentSummary _self;
  final $Res Function(LessonAssignmentSummary) _then;

/// Create a copy of LessonAssignmentSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? state = null,Object? dueAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonAssignmentSummary].
extension LessonAssignmentSummaryPatterns on LessonAssignmentSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonAssignmentSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonAssignmentSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonAssignmentSummary value)  $default,){
final _that = this;
switch (_that) {
case _LessonAssignmentSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonAssignmentSummary value)?  $default,){
final _that = this;
switch (_that) {
case _LessonAssignmentSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String state, @NullableUtcDateTimeConverter()  DateTime? dueAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonAssignmentSummary() when $default != null:
return $default(_that.id,_that.title,_that.state,_that.dueAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String state, @NullableUtcDateTimeConverter()  DateTime? dueAt)  $default,) {final _that = this;
switch (_that) {
case _LessonAssignmentSummary():
return $default(_that.id,_that.title,_that.state,_that.dueAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String state, @NullableUtcDateTimeConverter()  DateTime? dueAt)?  $default,) {final _that = this;
switch (_that) {
case _LessonAssignmentSummary() when $default != null:
return $default(_that.id,_that.title,_that.state,_that.dueAt);case _:
  return null;

}
}

}

/// @nodoc


class _LessonAssignmentSummary implements LessonAssignmentSummary {
  const _LessonAssignmentSummary({required this.id, this.title = '', this.state = '', @NullableUtcDateTimeConverter() this.dueAt});
  

@override final  String id;
@override@JsonKey() final  String title;
/// The server's own word: not-started, draft, submitted, under-review, graded, overdue, closed.
@override@JsonKey() final  String state;
@override@NullableUtcDateTimeConverter() final  DateTime? dueAt;

/// Create a copy of LessonAssignmentSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonAssignmentSummaryCopyWith<_LessonAssignmentSummary> get copyWith => __$LessonAssignmentSummaryCopyWithImpl<_LessonAssignmentSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonAssignmentSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.state, state) || other.state == state)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,state,dueAt);

@override
String toString() {
  return 'LessonAssignmentSummary(id: $id, title: $title, state: $state, dueAt: $dueAt)';
}


}

/// @nodoc
abstract mixin class _$LessonAssignmentSummaryCopyWith<$Res> implements $LessonAssignmentSummaryCopyWith<$Res> {
  factory _$LessonAssignmentSummaryCopyWith(_LessonAssignmentSummary value, $Res Function(_LessonAssignmentSummary) _then) = __$LessonAssignmentSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String state,@NullableUtcDateTimeConverter() DateTime? dueAt
});




}
/// @nodoc
class __$LessonAssignmentSummaryCopyWithImpl<$Res>
    implements _$LessonAssignmentSummaryCopyWith<$Res> {
  __$LessonAssignmentSummaryCopyWithImpl(this._self, this._then);

  final _LessonAssignmentSummary _self;
  final $Res Function(_LessonAssignmentSummary) _then;

/// Create a copy of LessonAssignmentSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? state = null,Object? dueAt = freezed,}) {
  return _then(_LessonAssignmentSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$LessonView {

 Course get course; Lesson get lesson; CourseProgressSnapshot get snapshot; ProgressSummary get progress; bool get enrolled; int get chapterIndex; int get lessonIndex;/// "2.3"
 String get number; LessonPosition get position;@JsonKey(unknownEnumValue: ProgressState.unknown) ProgressState get state; LessonProgress? get lessonProgress;@JsonKey(unknownEnumValue: LessonAccess.unknown) LessonAccess get access;/// Why it is closed, in the academy's words.
 String? get lockedReason; LessonLink? get previous; LessonLink? get next;/// The quiz this lesson delivers, without its answer key — the route sends it that way and
/// the model could not hold one anyway (`shared/domain/quiz.dart`).
 LearnerQuiz? get quiz;/// The learner's best score on the linked quiz, as a percentage.
 int? get quizBest;@JsonKey(fromJson: _assignmentFrom, includeToJson: false) LessonAssignmentSummary? get assignment; List<String> get instructorNames; String get note; bool get bookmarked;/// The academy's watch threshold, as a percentage.
 int get threshold;
/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonViewCopyWith<LessonView> get copyWith => _$LessonViewCopyWithImpl<LessonView>(this as LessonView, _$identity);

  /// Serializes this LessonView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonView&&(identical(other.course, course) || other.course == course)&&(identical(other.lesson, lesson) || other.lesson == lesson)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.lessonIndex, lessonIndex) || other.lessonIndex == lessonIndex)&&(identical(other.number, number) || other.number == number)&&(identical(other.position, position) || other.position == position)&&(identical(other.state, state) || other.state == state)&&(identical(other.lessonProgress, lessonProgress) || other.lessonProgress == lessonProgress)&&(identical(other.access, access) || other.access == access)&&(identical(other.lockedReason, lockedReason) || other.lockedReason == lockedReason)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.next, next) || other.next == next)&&(identical(other.quiz, quiz) || other.quiz == quiz)&&(identical(other.quizBest, quizBest) || other.quizBest == quizBest)&&(identical(other.assignment, assignment) || other.assignment == assignment)&&const DeepCollectionEquality().equals(other.instructorNames, instructorNames)&&(identical(other.note, note) || other.note == note)&&(identical(other.bookmarked, bookmarked) || other.bookmarked == bookmarked)&&(identical(other.threshold, threshold) || other.threshold == threshold));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,course,lesson,snapshot,progress,enrolled,chapterIndex,lessonIndex,number,position,state,lessonProgress,access,lockedReason,previous,next,quiz,quizBest,assignment,const DeepCollectionEquality().hash(instructorNames),note,bookmarked,threshold]);

@override
String toString() {
  return 'LessonView(course: $course, lesson: $lesson, snapshot: $snapshot, progress: $progress, enrolled: $enrolled, chapterIndex: $chapterIndex, lessonIndex: $lessonIndex, number: $number, position: $position, state: $state, lessonProgress: $lessonProgress, access: $access, lockedReason: $lockedReason, previous: $previous, next: $next, quiz: $quiz, quizBest: $quizBest, assignment: $assignment, instructorNames: $instructorNames, note: $note, bookmarked: $bookmarked, threshold: $threshold)';
}


}

/// @nodoc
abstract mixin class $LessonViewCopyWith<$Res>  {
  factory $LessonViewCopyWith(LessonView value, $Res Function(LessonView) _then) = _$LessonViewCopyWithImpl;
@useResult
$Res call({
 Course course, Lesson lesson, CourseProgressSnapshot snapshot, ProgressSummary progress, bool enrolled, int chapterIndex, int lessonIndex, String number, LessonPosition position,@JsonKey(unknownEnumValue: ProgressState.unknown) ProgressState state, LessonProgress? lessonProgress,@JsonKey(unknownEnumValue: LessonAccess.unknown) LessonAccess access, String? lockedReason, LessonLink? previous, LessonLink? next, LearnerQuiz? quiz, int? quizBest,@JsonKey(fromJson: _assignmentFrom, includeToJson: false) LessonAssignmentSummary? assignment, List<String> instructorNames, String note, bool bookmarked, int threshold
});


$CourseCopyWith<$Res> get course;$LessonCopyWith<$Res> get lesson;$CourseProgressSnapshotCopyWith<$Res> get snapshot;$ProgressSummaryCopyWith<$Res> get progress;$LessonPositionCopyWith<$Res> get position;$LessonProgressCopyWith<$Res>? get lessonProgress;$LessonLinkCopyWith<$Res>? get previous;$LessonLinkCopyWith<$Res>? get next;$LearnerQuizCopyWith<$Res>? get quiz;$LessonAssignmentSummaryCopyWith<$Res>? get assignment;

}
/// @nodoc
class _$LessonViewCopyWithImpl<$Res>
    implements $LessonViewCopyWith<$Res> {
  _$LessonViewCopyWithImpl(this._self, this._then);

  final LessonView _self;
  final $Res Function(LessonView) _then;

/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? course = null,Object? lesson = null,Object? snapshot = null,Object? progress = null,Object? enrolled = null,Object? chapterIndex = null,Object? lessonIndex = null,Object? number = null,Object? position = null,Object? state = null,Object? lessonProgress = freezed,Object? access = null,Object? lockedReason = freezed,Object? previous = freezed,Object? next = freezed,Object? quiz = freezed,Object? quizBest = freezed,Object? assignment = freezed,Object? instructorNames = null,Object? note = null,Object? bookmarked = null,Object? threshold = null,}) {
  return _then(_self.copyWith(
course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as Course,lesson: null == lesson ? _self.lesson : lesson // ignore: cast_nullable_to_non_nullable
as Lesson,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as CourseProgressSnapshot,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as ProgressSummary,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as bool,chapterIndex: null == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int,lessonIndex: null == lessonIndex ? _self.lessonIndex : lessonIndex // ignore: cast_nullable_to_non_nullable
as int,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as LessonPosition,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ProgressState,lessonProgress: freezed == lessonProgress ? _self.lessonProgress : lessonProgress // ignore: cast_nullable_to_non_nullable
as LessonProgress?,access: null == access ? _self.access : access // ignore: cast_nullable_to_non_nullable
as LessonAccess,lockedReason: freezed == lockedReason ? _self.lockedReason : lockedReason // ignore: cast_nullable_to_non_nullable
as String?,previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as LessonLink?,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as LessonLink?,quiz: freezed == quiz ? _self.quiz : quiz // ignore: cast_nullable_to_non_nullable
as LearnerQuiz?,quizBest: freezed == quizBest ? _self.quizBest : quizBest // ignore: cast_nullable_to_non_nullable
as int?,assignment: freezed == assignment ? _self.assignment : assignment // ignore: cast_nullable_to_non_nullable
as LessonAssignmentSummary?,instructorNames: null == instructorNames ? _self.instructorNames : instructorNames // ignore: cast_nullable_to_non_nullable
as List<String>,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,bookmarked: null == bookmarked ? _self.bookmarked : bookmarked // ignore: cast_nullable_to_non_nullable
as bool,threshold: null == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseCopyWith<$Res> get course {
  
  return $CourseCopyWith<$Res>(_self.course, (value) {
    return _then(_self.copyWith(course: value));
  });
}/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonCopyWith<$Res> get lesson {
  
  return $LessonCopyWith<$Res>(_self.lesson, (value) {
    return _then(_self.copyWith(lesson: value));
  });
}/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseProgressSnapshotCopyWith<$Res> get snapshot {
  
  return $CourseProgressSnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProgressSummaryCopyWith<$Res> get progress {
  
  return $ProgressSummaryCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonPositionCopyWith<$Res> get position {
  
  return $LessonPositionCopyWith<$Res>(_self.position, (value) {
    return _then(_self.copyWith(position: value));
  });
}/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonProgressCopyWith<$Res>? get lessonProgress {
    if (_self.lessonProgress == null) {
    return null;
  }

  return $LessonProgressCopyWith<$Res>(_self.lessonProgress!, (value) {
    return _then(_self.copyWith(lessonProgress: value));
  });
}/// Create a copy of LessonView
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
}/// Create a copy of LessonView
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
}/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LearnerQuizCopyWith<$Res>? get quiz {
    if (_self.quiz == null) {
    return null;
  }

  return $LearnerQuizCopyWith<$Res>(_self.quiz!, (value) {
    return _then(_self.copyWith(quiz: value));
  });
}/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonAssignmentSummaryCopyWith<$Res>? get assignment {
    if (_self.assignment == null) {
    return null;
  }

  return $LessonAssignmentSummaryCopyWith<$Res>(_self.assignment!, (value) {
    return _then(_self.copyWith(assignment: value));
  });
}
}


/// Adds pattern-matching-related methods to [LessonView].
extension LessonViewPatterns on LessonView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonView value)  $default,){
final _that = this;
switch (_that) {
case _LessonView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonView value)?  $default,){
final _that = this;
switch (_that) {
case _LessonView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Course course,  Lesson lesson,  CourseProgressSnapshot snapshot,  ProgressSummary progress,  bool enrolled,  int chapterIndex,  int lessonIndex,  String number,  LessonPosition position, @JsonKey(unknownEnumValue: ProgressState.unknown)  ProgressState state,  LessonProgress? lessonProgress, @JsonKey(unknownEnumValue: LessonAccess.unknown)  LessonAccess access,  String? lockedReason,  LessonLink? previous,  LessonLink? next,  LearnerQuiz? quiz,  int? quizBest, @JsonKey(fromJson: _assignmentFrom, includeToJson: false)  LessonAssignmentSummary? assignment,  List<String> instructorNames,  String note,  bool bookmarked,  int threshold)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonView() when $default != null:
return $default(_that.course,_that.lesson,_that.snapshot,_that.progress,_that.enrolled,_that.chapterIndex,_that.lessonIndex,_that.number,_that.position,_that.state,_that.lessonProgress,_that.access,_that.lockedReason,_that.previous,_that.next,_that.quiz,_that.quizBest,_that.assignment,_that.instructorNames,_that.note,_that.bookmarked,_that.threshold);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Course course,  Lesson lesson,  CourseProgressSnapshot snapshot,  ProgressSummary progress,  bool enrolled,  int chapterIndex,  int lessonIndex,  String number,  LessonPosition position, @JsonKey(unknownEnumValue: ProgressState.unknown)  ProgressState state,  LessonProgress? lessonProgress, @JsonKey(unknownEnumValue: LessonAccess.unknown)  LessonAccess access,  String? lockedReason,  LessonLink? previous,  LessonLink? next,  LearnerQuiz? quiz,  int? quizBest, @JsonKey(fromJson: _assignmentFrom, includeToJson: false)  LessonAssignmentSummary? assignment,  List<String> instructorNames,  String note,  bool bookmarked,  int threshold)  $default,) {final _that = this;
switch (_that) {
case _LessonView():
return $default(_that.course,_that.lesson,_that.snapshot,_that.progress,_that.enrolled,_that.chapterIndex,_that.lessonIndex,_that.number,_that.position,_that.state,_that.lessonProgress,_that.access,_that.lockedReason,_that.previous,_that.next,_that.quiz,_that.quizBest,_that.assignment,_that.instructorNames,_that.note,_that.bookmarked,_that.threshold);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Course course,  Lesson lesson,  CourseProgressSnapshot snapshot,  ProgressSummary progress,  bool enrolled,  int chapterIndex,  int lessonIndex,  String number,  LessonPosition position, @JsonKey(unknownEnumValue: ProgressState.unknown)  ProgressState state,  LessonProgress? lessonProgress, @JsonKey(unknownEnumValue: LessonAccess.unknown)  LessonAccess access,  String? lockedReason,  LessonLink? previous,  LessonLink? next,  LearnerQuiz? quiz,  int? quizBest, @JsonKey(fromJson: _assignmentFrom, includeToJson: false)  LessonAssignmentSummary? assignment,  List<String> instructorNames,  String note,  bool bookmarked,  int threshold)?  $default,) {final _that = this;
switch (_that) {
case _LessonView() when $default != null:
return $default(_that.course,_that.lesson,_that.snapshot,_that.progress,_that.enrolled,_that.chapterIndex,_that.lessonIndex,_that.number,_that.position,_that.state,_that.lessonProgress,_that.access,_that.lockedReason,_that.previous,_that.next,_that.quiz,_that.quizBest,_that.assignment,_that.instructorNames,_that.note,_that.bookmarked,_that.threshold);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonView extends LessonView {
  const _LessonView({required this.course, required this.lesson, required this.snapshot, required this.progress, this.enrolled = false, this.chapterIndex = 0, this.lessonIndex = 0, this.number = '', this.position = const LessonPosition(), @JsonKey(unknownEnumValue: ProgressState.unknown) this.state = ProgressState.notStarted, this.lessonProgress, @JsonKey(unknownEnumValue: LessonAccess.unknown) this.access = LessonAccess.unknown, this.lockedReason, this.previous, this.next, this.quiz, this.quizBest, @JsonKey(fromJson: _assignmentFrom, includeToJson: false) this.assignment, final  List<String> instructorNames = const <String>[], this.note = '', this.bookmarked = false, this.threshold = 0}): _instructorNames = instructorNames,super._();
  factory _LessonView.fromJson(Map<String, dynamic> json) => _$LessonViewFromJson(json);

@override final  Course course;
@override final  Lesson lesson;
@override final  CourseProgressSnapshot snapshot;
@override final  ProgressSummary progress;
@override@JsonKey() final  bool enrolled;
@override@JsonKey() final  int chapterIndex;
@override@JsonKey() final  int lessonIndex;
/// "2.3"
@override@JsonKey() final  String number;
@override@JsonKey() final  LessonPosition position;
@override@JsonKey(unknownEnumValue: ProgressState.unknown) final  ProgressState state;
@override final  LessonProgress? lessonProgress;
@override@JsonKey(unknownEnumValue: LessonAccess.unknown) final  LessonAccess access;
/// Why it is closed, in the academy's words.
@override final  String? lockedReason;
@override final  LessonLink? previous;
@override final  LessonLink? next;
/// The quiz this lesson delivers, without its answer key — the route sends it that way and
/// the model could not hold one anyway (`shared/domain/quiz.dart`).
@override final  LearnerQuiz? quiz;
/// The learner's best score on the linked quiz, as a percentage.
@override final  int? quizBest;
@override@JsonKey(fromJson: _assignmentFrom, includeToJson: false) final  LessonAssignmentSummary? assignment;
 final  List<String> _instructorNames;
@override@JsonKey() List<String> get instructorNames {
  if (_instructorNames is EqualUnmodifiableListView) return _instructorNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_instructorNames);
}

@override@JsonKey() final  String note;
@override@JsonKey() final  bool bookmarked;
/// The academy's watch threshold, as a percentage.
@override@JsonKey() final  int threshold;

/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonViewCopyWith<_LessonView> get copyWith => __$LessonViewCopyWithImpl<_LessonView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonViewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonView&&(identical(other.course, course) || other.course == course)&&(identical(other.lesson, lesson) || other.lesson == lesson)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.chapterIndex, chapterIndex) || other.chapterIndex == chapterIndex)&&(identical(other.lessonIndex, lessonIndex) || other.lessonIndex == lessonIndex)&&(identical(other.number, number) || other.number == number)&&(identical(other.position, position) || other.position == position)&&(identical(other.state, state) || other.state == state)&&(identical(other.lessonProgress, lessonProgress) || other.lessonProgress == lessonProgress)&&(identical(other.access, access) || other.access == access)&&(identical(other.lockedReason, lockedReason) || other.lockedReason == lockedReason)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.next, next) || other.next == next)&&(identical(other.quiz, quiz) || other.quiz == quiz)&&(identical(other.quizBest, quizBest) || other.quizBest == quizBest)&&(identical(other.assignment, assignment) || other.assignment == assignment)&&const DeepCollectionEquality().equals(other._instructorNames, _instructorNames)&&(identical(other.note, note) || other.note == note)&&(identical(other.bookmarked, bookmarked) || other.bookmarked == bookmarked)&&(identical(other.threshold, threshold) || other.threshold == threshold));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,course,lesson,snapshot,progress,enrolled,chapterIndex,lessonIndex,number,position,state,lessonProgress,access,lockedReason,previous,next,quiz,quizBest,assignment,const DeepCollectionEquality().hash(_instructorNames),note,bookmarked,threshold]);

@override
String toString() {
  return 'LessonView(course: $course, lesson: $lesson, snapshot: $snapshot, progress: $progress, enrolled: $enrolled, chapterIndex: $chapterIndex, lessonIndex: $lessonIndex, number: $number, position: $position, state: $state, lessonProgress: $lessonProgress, access: $access, lockedReason: $lockedReason, previous: $previous, next: $next, quiz: $quiz, quizBest: $quizBest, assignment: $assignment, instructorNames: $instructorNames, note: $note, bookmarked: $bookmarked, threshold: $threshold)';
}


}

/// @nodoc
abstract mixin class _$LessonViewCopyWith<$Res> implements $LessonViewCopyWith<$Res> {
  factory _$LessonViewCopyWith(_LessonView value, $Res Function(_LessonView) _then) = __$LessonViewCopyWithImpl;
@override @useResult
$Res call({
 Course course, Lesson lesson, CourseProgressSnapshot snapshot, ProgressSummary progress, bool enrolled, int chapterIndex, int lessonIndex, String number, LessonPosition position,@JsonKey(unknownEnumValue: ProgressState.unknown) ProgressState state, LessonProgress? lessonProgress,@JsonKey(unknownEnumValue: LessonAccess.unknown) LessonAccess access, String? lockedReason, LessonLink? previous, LessonLink? next, LearnerQuiz? quiz, int? quizBest,@JsonKey(fromJson: _assignmentFrom, includeToJson: false) LessonAssignmentSummary? assignment, List<String> instructorNames, String note, bool bookmarked, int threshold
});


@override $CourseCopyWith<$Res> get course;@override $LessonCopyWith<$Res> get lesson;@override $CourseProgressSnapshotCopyWith<$Res> get snapshot;@override $ProgressSummaryCopyWith<$Res> get progress;@override $LessonPositionCopyWith<$Res> get position;@override $LessonProgressCopyWith<$Res>? get lessonProgress;@override $LessonLinkCopyWith<$Res>? get previous;@override $LessonLinkCopyWith<$Res>? get next;@override $LearnerQuizCopyWith<$Res>? get quiz;@override $LessonAssignmentSummaryCopyWith<$Res>? get assignment;

}
/// @nodoc
class __$LessonViewCopyWithImpl<$Res>
    implements _$LessonViewCopyWith<$Res> {
  __$LessonViewCopyWithImpl(this._self, this._then);

  final _LessonView _self;
  final $Res Function(_LessonView) _then;

/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? course = null,Object? lesson = null,Object? snapshot = null,Object? progress = null,Object? enrolled = null,Object? chapterIndex = null,Object? lessonIndex = null,Object? number = null,Object? position = null,Object? state = null,Object? lessonProgress = freezed,Object? access = null,Object? lockedReason = freezed,Object? previous = freezed,Object? next = freezed,Object? quiz = freezed,Object? quizBest = freezed,Object? assignment = freezed,Object? instructorNames = null,Object? note = null,Object? bookmarked = null,Object? threshold = null,}) {
  return _then(_LessonView(
course: null == course ? _self.course : course // ignore: cast_nullable_to_non_nullable
as Course,lesson: null == lesson ? _self.lesson : lesson // ignore: cast_nullable_to_non_nullable
as Lesson,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as CourseProgressSnapshot,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as ProgressSummary,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as bool,chapterIndex: null == chapterIndex ? _self.chapterIndex : chapterIndex // ignore: cast_nullable_to_non_nullable
as int,lessonIndex: null == lessonIndex ? _self.lessonIndex : lessonIndex // ignore: cast_nullable_to_non_nullable
as int,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as LessonPosition,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ProgressState,lessonProgress: freezed == lessonProgress ? _self.lessonProgress : lessonProgress // ignore: cast_nullable_to_non_nullable
as LessonProgress?,access: null == access ? _self.access : access // ignore: cast_nullable_to_non_nullable
as LessonAccess,lockedReason: freezed == lockedReason ? _self.lockedReason : lockedReason // ignore: cast_nullable_to_non_nullable
as String?,previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as LessonLink?,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as LessonLink?,quiz: freezed == quiz ? _self.quiz : quiz // ignore: cast_nullable_to_non_nullable
as LearnerQuiz?,quizBest: freezed == quizBest ? _self.quizBest : quizBest // ignore: cast_nullable_to_non_nullable
as int?,assignment: freezed == assignment ? _self.assignment : assignment // ignore: cast_nullable_to_non_nullable
as LessonAssignmentSummary?,instructorNames: null == instructorNames ? _self._instructorNames : instructorNames // ignore: cast_nullable_to_non_nullable
as List<String>,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,bookmarked: null == bookmarked ? _self.bookmarked : bookmarked // ignore: cast_nullable_to_non_nullable
as bool,threshold: null == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseCopyWith<$Res> get course {
  
  return $CourseCopyWith<$Res>(_self.course, (value) {
    return _then(_self.copyWith(course: value));
  });
}/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonCopyWith<$Res> get lesson {
  
  return $LessonCopyWith<$Res>(_self.lesson, (value) {
    return _then(_self.copyWith(lesson: value));
  });
}/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseProgressSnapshotCopyWith<$Res> get snapshot {
  
  return $CourseProgressSnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProgressSummaryCopyWith<$Res> get progress {
  
  return $ProgressSummaryCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonPositionCopyWith<$Res> get position {
  
  return $LessonPositionCopyWith<$Res>(_self.position, (value) {
    return _then(_self.copyWith(position: value));
  });
}/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonProgressCopyWith<$Res>? get lessonProgress {
    if (_self.lessonProgress == null) {
    return null;
  }

  return $LessonProgressCopyWith<$Res>(_self.lessonProgress!, (value) {
    return _then(_self.copyWith(lessonProgress: value));
  });
}/// Create a copy of LessonView
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
}/// Create a copy of LessonView
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
}/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LearnerQuizCopyWith<$Res>? get quiz {
    if (_self.quiz == null) {
    return null;
  }

  return $LearnerQuizCopyWith<$Res>(_self.quiz!, (value) {
    return _then(_self.copyWith(quiz: value));
  });
}/// Create a copy of LessonView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonAssignmentSummaryCopyWith<$Res>? get assignment {
    if (_self.assignment == null) {
    return null;
  }

  return $LessonAssignmentSummaryCopyWith<$Res>(_self.assignment!, (value) {
    return _then(_self.copyWith(assignment: value));
  });
}
}

// dart format on
