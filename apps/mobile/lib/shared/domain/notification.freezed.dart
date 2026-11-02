// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationFact {

 String get label; String get value;
/// Create a copy of NotificationFact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationFactCopyWith<NotificationFact> get copyWith => _$NotificationFactCopyWithImpl<NotificationFact>(this as NotificationFact, _$identity);

  /// Serializes this NotificationFact to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationFact&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,value);

@override
String toString() {
  return 'NotificationFact(label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class $NotificationFactCopyWith<$Res>  {
  factory $NotificationFactCopyWith(NotificationFact value, $Res Function(NotificationFact) _then) = _$NotificationFactCopyWithImpl;
@useResult
$Res call({
 String label, String value
});




}
/// @nodoc
class _$NotificationFactCopyWithImpl<$Res>
    implements $NotificationFactCopyWith<$Res> {
  _$NotificationFactCopyWithImpl(this._self, this._then);

  final NotificationFact _self;
  final $Res Function(NotificationFact) _then;

/// Create a copy of NotificationFact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? value = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationFact].
extension NotificationFactPatterns on NotificationFact {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationFact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationFact() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationFact value)  $default,){
final _that = this;
switch (_that) {
case _NotificationFact():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationFact value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationFact() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationFact() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String value)  $default,) {final _that = this;
switch (_that) {
case _NotificationFact():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String value)?  $default,) {final _that = this;
switch (_that) {
case _NotificationFact() when $default != null:
return $default(_that.label,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationFact implements NotificationFact {
  const _NotificationFact({this.label = '', this.value = ''});
  factory _NotificationFact.fromJson(Map<String, dynamic> json) => _$NotificationFactFromJson(json);

@override@JsonKey() final  String label;
@override@JsonKey() final  String value;

/// Create a copy of NotificationFact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationFactCopyWith<_NotificationFact> get copyWith => __$NotificationFactCopyWithImpl<_NotificationFact>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationFactToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationFact&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,value);

@override
String toString() {
  return 'NotificationFact(label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class _$NotificationFactCopyWith<$Res> implements $NotificationFactCopyWith<$Res> {
  factory _$NotificationFactCopyWith(_NotificationFact value, $Res Function(_NotificationFact) _then) = __$NotificationFactCopyWithImpl;
@override @useResult
$Res call({
 String label, String value
});




}
/// @nodoc
class __$NotificationFactCopyWithImpl<$Res>
    implements _$NotificationFactCopyWith<$Res> {
  __$NotificationFactCopyWithImpl(this._self, this._then);

  final _NotificationFact _self;
  final $Res Function(_NotificationFact) _then;

/// Create a copy of NotificationFact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? value = null,}) {
  return _then(_NotificationFact(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NotificationAction {

 String get label; String get to;
/// Create a copy of NotificationAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationActionCopyWith<NotificationAction> get copyWith => _$NotificationActionCopyWithImpl<NotificationAction>(this as NotificationAction, _$identity);

  /// Serializes this NotificationAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationAction&&(identical(other.label, label) || other.label == label)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,to);

@override
String toString() {
  return 'NotificationAction(label: $label, to: $to)';
}


}

/// @nodoc
abstract mixin class $NotificationActionCopyWith<$Res>  {
  factory $NotificationActionCopyWith(NotificationAction value, $Res Function(NotificationAction) _then) = _$NotificationActionCopyWithImpl;
@useResult
$Res call({
 String label, String to
});




}
/// @nodoc
class _$NotificationActionCopyWithImpl<$Res>
    implements $NotificationActionCopyWith<$Res> {
  _$NotificationActionCopyWithImpl(this._self, this._then);

  final NotificationAction _self;
  final $Res Function(NotificationAction) _then;

/// Create a copy of NotificationAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? to = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationAction].
extension NotificationActionPatterns on NotificationAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationAction value)  $default,){
final _that = this;
switch (_that) {
case _NotificationAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationAction value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String to)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationAction() when $default != null:
return $default(_that.label,_that.to);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String to)  $default,) {final _that = this;
switch (_that) {
case _NotificationAction():
return $default(_that.label,_that.to);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String to)?  $default,) {final _that = this;
switch (_that) {
case _NotificationAction() when $default != null:
return $default(_that.label,_that.to);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationAction implements NotificationAction {
  const _NotificationAction({this.label = '', this.to = ''});
  factory _NotificationAction.fromJson(Map<String, dynamic> json) => _$NotificationActionFromJson(json);

@override@JsonKey() final  String label;
@override@JsonKey() final  String to;

/// Create a copy of NotificationAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationActionCopyWith<_NotificationAction> get copyWith => __$NotificationActionCopyWithImpl<_NotificationAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationAction&&(identical(other.label, label) || other.label == label)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,to);

@override
String toString() {
  return 'NotificationAction(label: $label, to: $to)';
}


}

/// @nodoc
abstract mixin class _$NotificationActionCopyWith<$Res> implements $NotificationActionCopyWith<$Res> {
  factory _$NotificationActionCopyWith(_NotificationAction value, $Res Function(_NotificationAction) _then) = __$NotificationActionCopyWithImpl;
@override @useResult
$Res call({
 String label, String to
});




}
/// @nodoc
class __$NotificationActionCopyWithImpl<$Res>
    implements _$NotificationActionCopyWith<$Res> {
  __$NotificationActionCopyWithImpl(this._self, this._then);

  final _NotificationAction _self;
  final $Res Function(_NotificationAction) _then;

/// Create a copy of NotificationAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? to = null,}) {
  return _then(_NotificationAction(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AppNotification {

 String get id;@JsonKey(unknownEnumValue: NotificationCategory.unknown) NotificationCategory get category; String get title;/// One or two sentences for the list and the bell.
 String get summary;/// Paragraphs for the detail page.
 List<String> get body;@UtcDateTimeConverter() DateTime get createdAt;@NullableUtcDateTimeConverter() DateTime? get readAt;/// Sent even while notifications are paused, and marked in the list.
 bool get important;/// Who caused it, when a person did.
 String? get actor; List<NotificationFact> get facts; NotificationAction? get action; NotificationAction? get secondaryAction;
/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppNotificationCopyWith<AppNotification> get copyWith => _$AppNotificationCopyWithImpl<AppNotification>(this as AppNotification, _$identity);

  /// Serializes this AppNotification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.body, body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.important, important) || other.important == important)&&(identical(other.actor, actor) || other.actor == actor)&&const DeepCollectionEquality().equals(other.facts, facts)&&(identical(other.action, action) || other.action == action)&&(identical(other.secondaryAction, secondaryAction) || other.secondaryAction == secondaryAction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,title,summary,const DeepCollectionEquality().hash(body),createdAt,readAt,important,actor,const DeepCollectionEquality().hash(facts),action,secondaryAction);

@override
String toString() {
  return 'AppNotification(id: $id, category: $category, title: $title, summary: $summary, body: $body, createdAt: $createdAt, readAt: $readAt, important: $important, actor: $actor, facts: $facts, action: $action, secondaryAction: $secondaryAction)';
}


}

/// @nodoc
abstract mixin class $AppNotificationCopyWith<$Res>  {
  factory $AppNotificationCopyWith(AppNotification value, $Res Function(AppNotification) _then) = _$AppNotificationCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: NotificationCategory.unknown) NotificationCategory category, String title, String summary, List<String> body,@UtcDateTimeConverter() DateTime createdAt,@NullableUtcDateTimeConverter() DateTime? readAt, bool important, String? actor, List<NotificationFact> facts, NotificationAction? action, NotificationAction? secondaryAction
});


$NotificationActionCopyWith<$Res>? get action;$NotificationActionCopyWith<$Res>? get secondaryAction;

}
/// @nodoc
class _$AppNotificationCopyWithImpl<$Res>
    implements $AppNotificationCopyWith<$Res> {
  _$AppNotificationCopyWithImpl(this._self, this._then);

  final AppNotification _self;
  final $Res Function(AppNotification) _then;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? category = null,Object? title = null,Object? summary = null,Object? body = null,Object? createdAt = null,Object? readAt = freezed,Object? important = null,Object? actor = freezed,Object? facts = null,Object? action = freezed,Object? secondaryAction = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as NotificationCategory,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,important: null == important ? _self.important : important // ignore: cast_nullable_to_non_nullable
as bool,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String?,facts: null == facts ? _self.facts : facts // ignore: cast_nullable_to_non_nullable
as List<NotificationFact>,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as NotificationAction?,secondaryAction: freezed == secondaryAction ? _self.secondaryAction : secondaryAction // ignore: cast_nullable_to_non_nullable
as NotificationAction?,
  ));
}
/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationActionCopyWith<$Res>? get action {
    if (_self.action == null) {
    return null;
  }

  return $NotificationActionCopyWith<$Res>(_self.action!, (value) {
    return _then(_self.copyWith(action: value));
  });
}/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationActionCopyWith<$Res>? get secondaryAction {
    if (_self.secondaryAction == null) {
    return null;
  }

  return $NotificationActionCopyWith<$Res>(_self.secondaryAction!, (value) {
    return _then(_self.copyWith(secondaryAction: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppNotification].
extension AppNotificationPatterns on AppNotification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppNotification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppNotification value)  $default,){
final _that = this;
switch (_that) {
case _AppNotification():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppNotification value)?  $default,){
final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: NotificationCategory.unknown)  NotificationCategory category,  String title,  String summary,  List<String> body, @UtcDateTimeConverter()  DateTime createdAt, @NullableUtcDateTimeConverter()  DateTime? readAt,  bool important,  String? actor,  List<NotificationFact> facts,  NotificationAction? action,  NotificationAction? secondaryAction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
return $default(_that.id,_that.category,_that.title,_that.summary,_that.body,_that.createdAt,_that.readAt,_that.important,_that.actor,_that.facts,_that.action,_that.secondaryAction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: NotificationCategory.unknown)  NotificationCategory category,  String title,  String summary,  List<String> body, @UtcDateTimeConverter()  DateTime createdAt, @NullableUtcDateTimeConverter()  DateTime? readAt,  bool important,  String? actor,  List<NotificationFact> facts,  NotificationAction? action,  NotificationAction? secondaryAction)  $default,) {final _that = this;
switch (_that) {
case _AppNotification():
return $default(_that.id,_that.category,_that.title,_that.summary,_that.body,_that.createdAt,_that.readAt,_that.important,_that.actor,_that.facts,_that.action,_that.secondaryAction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(unknownEnumValue: NotificationCategory.unknown)  NotificationCategory category,  String title,  String summary,  List<String> body, @UtcDateTimeConverter()  DateTime createdAt, @NullableUtcDateTimeConverter()  DateTime? readAt,  bool important,  String? actor,  List<NotificationFact> facts,  NotificationAction? action,  NotificationAction? secondaryAction)?  $default,) {final _that = this;
switch (_that) {
case _AppNotification() when $default != null:
return $default(_that.id,_that.category,_that.title,_that.summary,_that.body,_that.createdAt,_that.readAt,_that.important,_that.actor,_that.facts,_that.action,_that.secondaryAction);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppNotification extends AppNotification {
  const _AppNotification({required this.id, @JsonKey(unknownEnumValue: NotificationCategory.unknown) this.category = NotificationCategory.unknown, this.title = '', this.summary = '', final  List<String> body = const <String>[], @UtcDateTimeConverter() required this.createdAt, @NullableUtcDateTimeConverter() this.readAt, this.important = false, this.actor, final  List<NotificationFact> facts = const <NotificationFact>[], this.action, this.secondaryAction}): _body = body,_facts = facts,super._();
  factory _AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);

@override final  String id;
@override@JsonKey(unknownEnumValue: NotificationCategory.unknown) final  NotificationCategory category;
@override@JsonKey() final  String title;
/// One or two sentences for the list and the bell.
@override@JsonKey() final  String summary;
/// Paragraphs for the detail page.
 final  List<String> _body;
/// Paragraphs for the detail page.
@override@JsonKey() List<String> get body {
  if (_body is EqualUnmodifiableListView) return _body;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_body);
}

@override@UtcDateTimeConverter() final  DateTime createdAt;
@override@NullableUtcDateTimeConverter() final  DateTime? readAt;
/// Sent even while notifications are paused, and marked in the list.
@override@JsonKey() final  bool important;
/// Who caused it, when a person did.
@override final  String? actor;
 final  List<NotificationFact> _facts;
@override@JsonKey() List<NotificationFact> get facts {
  if (_facts is EqualUnmodifiableListView) return _facts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_facts);
}

@override final  NotificationAction? action;
@override final  NotificationAction? secondaryAction;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppNotificationCopyWith<_AppNotification> get copyWith => __$AppNotificationCopyWithImpl<_AppNotification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppNotificationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._body, _body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.important, important) || other.important == important)&&(identical(other.actor, actor) || other.actor == actor)&&const DeepCollectionEquality().equals(other._facts, _facts)&&(identical(other.action, action) || other.action == action)&&(identical(other.secondaryAction, secondaryAction) || other.secondaryAction == secondaryAction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,title,summary,const DeepCollectionEquality().hash(_body),createdAt,readAt,important,actor,const DeepCollectionEquality().hash(_facts),action,secondaryAction);

@override
String toString() {
  return 'AppNotification(id: $id, category: $category, title: $title, summary: $summary, body: $body, createdAt: $createdAt, readAt: $readAt, important: $important, actor: $actor, facts: $facts, action: $action, secondaryAction: $secondaryAction)';
}


}

/// @nodoc
abstract mixin class _$AppNotificationCopyWith<$Res> implements $AppNotificationCopyWith<$Res> {
  factory _$AppNotificationCopyWith(_AppNotification value, $Res Function(_AppNotification) _then) = __$AppNotificationCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: NotificationCategory.unknown) NotificationCategory category, String title, String summary, List<String> body,@UtcDateTimeConverter() DateTime createdAt,@NullableUtcDateTimeConverter() DateTime? readAt, bool important, String? actor, List<NotificationFact> facts, NotificationAction? action, NotificationAction? secondaryAction
});


@override $NotificationActionCopyWith<$Res>? get action;@override $NotificationActionCopyWith<$Res>? get secondaryAction;

}
/// @nodoc
class __$AppNotificationCopyWithImpl<$Res>
    implements _$AppNotificationCopyWith<$Res> {
  __$AppNotificationCopyWithImpl(this._self, this._then);

  final _AppNotification _self;
  final $Res Function(_AppNotification) _then;

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? title = null,Object? summary = null,Object? body = null,Object? createdAt = null,Object? readAt = freezed,Object? important = null,Object? actor = freezed,Object? facts = null,Object? action = freezed,Object? secondaryAction = freezed,}) {
  return _then(_AppNotification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as NotificationCategory,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self._body : body // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,important: null == important ? _self.important : important // ignore: cast_nullable_to_non_nullable
as bool,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String?,facts: null == facts ? _self._facts : facts // ignore: cast_nullable_to_non_nullable
as List<NotificationFact>,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as NotificationAction?,secondaryAction: freezed == secondaryAction ? _self.secondaryAction : secondaryAction // ignore: cast_nullable_to_non_nullable
as NotificationAction?,
  ));
}

/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationActionCopyWith<$Res>? get action {
    if (_self.action == null) {
    return null;
  }

  return $NotificationActionCopyWith<$Res>(_self.action!, (value) {
    return _then(_self.copyWith(action: value));
  });
}/// Create a copy of AppNotification
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationActionCopyWith<$Res>? get secondaryAction {
    if (_self.secondaryAction == null) {
    return null;
  }

  return $NotificationActionCopyWith<$Res>(_self.secondaryAction!, (value) {
    return _then(_self.copyWith(secondaryAction: value));
  });
}
}


/// @nodoc
mixin _$NotificationPage {

 List<AppNotification> get rows;/// How many match the current filter, which may be more than [rows] holds.
 int get total;/// Unread across **every** category, whatever the filter — this is the bell's number.
 int get unread; Map<String, int> get counts;
/// Create a copy of NotificationPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPageCopyWith<NotificationPage> get copyWith => _$NotificationPageCopyWithImpl<NotificationPage>(this as NotificationPage, _$identity);

  /// Serializes this NotificationPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPage&&const DeepCollectionEquality().equals(other.rows, rows)&&(identical(other.total, total) || other.total == total)&&(identical(other.unread, unread) || other.unread == unread)&&const DeepCollectionEquality().equals(other.counts, counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rows),total,unread,const DeepCollectionEquality().hash(counts));

@override
String toString() {
  return 'NotificationPage(rows: $rows, total: $total, unread: $unread, counts: $counts)';
}


}

/// @nodoc
abstract mixin class $NotificationPageCopyWith<$Res>  {
  factory $NotificationPageCopyWith(NotificationPage value, $Res Function(NotificationPage) _then) = _$NotificationPageCopyWithImpl;
@useResult
$Res call({
 List<AppNotification> rows, int total, int unread, Map<String, int> counts
});




}
/// @nodoc
class _$NotificationPageCopyWithImpl<$Res>
    implements $NotificationPageCopyWith<$Res> {
  _$NotificationPageCopyWithImpl(this._self, this._then);

  final NotificationPage _self;
  final $Res Function(NotificationPage) _then;

/// Create a copy of NotificationPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? total = null,Object? unread = null,Object? counts = null,}) {
  return _then(_self.copyWith(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<AppNotification>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,unread: null == unread ? _self.unread : unread // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationPage].
extension NotificationPagePatterns on NotificationPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPage value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPage value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AppNotification> rows,  int total,  int unread,  Map<String, int> counts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPage() when $default != null:
return $default(_that.rows,_that.total,_that.unread,_that.counts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AppNotification> rows,  int total,  int unread,  Map<String, int> counts)  $default,) {final _that = this;
switch (_that) {
case _NotificationPage():
return $default(_that.rows,_that.total,_that.unread,_that.counts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AppNotification> rows,  int total,  int unread,  Map<String, int> counts)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPage() when $default != null:
return $default(_that.rows,_that.total,_that.unread,_that.counts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationPage extends NotificationPage {
  const _NotificationPage({final  List<AppNotification> rows = const <AppNotification>[], this.total = 0, this.unread = 0, final  Map<String, int> counts = const <String, int>{}}): _rows = rows,_counts = counts,super._();
  factory _NotificationPage.fromJson(Map<String, dynamic> json) => _$NotificationPageFromJson(json);

 final  List<AppNotification> _rows;
@override@JsonKey() List<AppNotification> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

/// How many match the current filter, which may be more than [rows] holds.
@override@JsonKey() final  int total;
/// Unread across **every** category, whatever the filter — this is the bell's number.
@override@JsonKey() final  int unread;
 final  Map<String, int> _counts;
@override@JsonKey() Map<String, int> get counts {
  if (_counts is EqualUnmodifiableMapView) return _counts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_counts);
}


/// Create a copy of NotificationPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPageCopyWith<_NotificationPage> get copyWith => __$NotificationPageCopyWithImpl<_NotificationPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPage&&const DeepCollectionEquality().equals(other._rows, _rows)&&(identical(other.total, total) || other.total == total)&&(identical(other.unread, unread) || other.unread == unread)&&const DeepCollectionEquality().equals(other._counts, _counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows),total,unread,const DeepCollectionEquality().hash(_counts));

@override
String toString() {
  return 'NotificationPage(rows: $rows, total: $total, unread: $unread, counts: $counts)';
}


}

/// @nodoc
abstract mixin class _$NotificationPageCopyWith<$Res> implements $NotificationPageCopyWith<$Res> {
  factory _$NotificationPageCopyWith(_NotificationPage value, $Res Function(_NotificationPage) _then) = __$NotificationPageCopyWithImpl;
@override @useResult
$Res call({
 List<AppNotification> rows, int total, int unread, Map<String, int> counts
});




}
/// @nodoc
class __$NotificationPageCopyWithImpl<$Res>
    implements _$NotificationPageCopyWith<$Res> {
  __$NotificationPageCopyWithImpl(this._self, this._then);

  final _NotificationPage _self;
  final $Res Function(_NotificationPage) _then;

/// Create a copy of NotificationPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,Object? total = null,Object? unread = null,Object? counts = null,}) {
  return _then(_NotificationPage(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<AppNotification>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,unread: null == unread ? _self.unread : unread // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self._counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}


/// @nodoc
mixin _$NotificationDetail {

 AppNotification get notification; List<AppNotification> get related; Map<String, bool> get channels;
/// Create a copy of NotificationDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationDetailCopyWith<NotificationDetail> get copyWith => _$NotificationDetailCopyWithImpl<NotificationDetail>(this as NotificationDetail, _$identity);

  /// Serializes this NotificationDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationDetail&&(identical(other.notification, notification) || other.notification == notification)&&const DeepCollectionEquality().equals(other.related, related)&&const DeepCollectionEquality().equals(other.channels, channels));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notification,const DeepCollectionEquality().hash(related),const DeepCollectionEquality().hash(channels));

@override
String toString() {
  return 'NotificationDetail(notification: $notification, related: $related, channels: $channels)';
}


}

/// @nodoc
abstract mixin class $NotificationDetailCopyWith<$Res>  {
  factory $NotificationDetailCopyWith(NotificationDetail value, $Res Function(NotificationDetail) _then) = _$NotificationDetailCopyWithImpl;
@useResult
$Res call({
 AppNotification notification, List<AppNotification> related, Map<String, bool> channels
});


$AppNotificationCopyWith<$Res> get notification;

}
/// @nodoc
class _$NotificationDetailCopyWithImpl<$Res>
    implements $NotificationDetailCopyWith<$Res> {
  _$NotificationDetailCopyWithImpl(this._self, this._then);

  final NotificationDetail _self;
  final $Res Function(NotificationDetail) _then;

/// Create a copy of NotificationDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notification = null,Object? related = null,Object? channels = null,}) {
  return _then(_self.copyWith(
notification: null == notification ? _self.notification : notification // ignore: cast_nullable_to_non_nullable
as AppNotification,related: null == related ? _self.related : related // ignore: cast_nullable_to_non_nullable
as List<AppNotification>,channels: null == channels ? _self.channels : channels // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}
/// Create a copy of NotificationDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppNotificationCopyWith<$Res> get notification {
  
  return $AppNotificationCopyWith<$Res>(_self.notification, (value) {
    return _then(_self.copyWith(notification: value));
  });
}
}


/// Adds pattern-matching-related methods to [NotificationDetail].
extension NotificationDetailPatterns on NotificationDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationDetail value)  $default,){
final _that = this;
switch (_that) {
case _NotificationDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationDetail value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppNotification notification,  List<AppNotification> related,  Map<String, bool> channels)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationDetail() when $default != null:
return $default(_that.notification,_that.related,_that.channels);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppNotification notification,  List<AppNotification> related,  Map<String, bool> channels)  $default,) {final _that = this;
switch (_that) {
case _NotificationDetail():
return $default(_that.notification,_that.related,_that.channels);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppNotification notification,  List<AppNotification> related,  Map<String, bool> channels)?  $default,) {final _that = this;
switch (_that) {
case _NotificationDetail() when $default != null:
return $default(_that.notification,_that.related,_that.channels);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationDetail extends NotificationDetail {
  const _NotificationDetail({required this.notification, final  List<AppNotification> related = const <AppNotification>[], final  Map<String, bool> channels = const <String, bool>{}}): _related = related,_channels = channels,super._();
  factory _NotificationDetail.fromJson(Map<String, dynamic> json) => _$NotificationDetailFromJson(json);

@override final  AppNotification notification;
 final  List<AppNotification> _related;
@override@JsonKey() List<AppNotification> get related {
  if (_related is EqualUnmodifiableListView) return _related;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_related);
}

 final  Map<String, bool> _channels;
@override@JsonKey() Map<String, bool> get channels {
  if (_channels is EqualUnmodifiableMapView) return _channels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_channels);
}


/// Create a copy of NotificationDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationDetailCopyWith<_NotificationDetail> get copyWith => __$NotificationDetailCopyWithImpl<_NotificationDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationDetail&&(identical(other.notification, notification) || other.notification == notification)&&const DeepCollectionEquality().equals(other._related, _related)&&const DeepCollectionEquality().equals(other._channels, _channels));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notification,const DeepCollectionEquality().hash(_related),const DeepCollectionEquality().hash(_channels));

@override
String toString() {
  return 'NotificationDetail(notification: $notification, related: $related, channels: $channels)';
}


}

/// @nodoc
abstract mixin class _$NotificationDetailCopyWith<$Res> implements $NotificationDetailCopyWith<$Res> {
  factory _$NotificationDetailCopyWith(_NotificationDetail value, $Res Function(_NotificationDetail) _then) = __$NotificationDetailCopyWithImpl;
@override @useResult
$Res call({
 AppNotification notification, List<AppNotification> related, Map<String, bool> channels
});


@override $AppNotificationCopyWith<$Res> get notification;

}
/// @nodoc
class __$NotificationDetailCopyWithImpl<$Res>
    implements _$NotificationDetailCopyWith<$Res> {
  __$NotificationDetailCopyWithImpl(this._self, this._then);

  final _NotificationDetail _self;
  final $Res Function(_NotificationDetail) _then;

/// Create a copy of NotificationDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notification = null,Object? related = null,Object? channels = null,}) {
  return _then(_NotificationDetail(
notification: null == notification ? _self.notification : notification // ignore: cast_nullable_to_non_nullable
as AppNotification,related: null == related ? _self._related : related // ignore: cast_nullable_to_non_nullable
as List<AppNotification>,channels: null == channels ? _self._channels : channels // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}

/// Create a copy of NotificationDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppNotificationCopyWith<$Res> get notification {
  
  return $AppNotificationCopyWith<$Res>(_self.notification, (value) {
    return _then(_self.copyWith(notification: value));
  });
}
}


/// @nodoc
mixin _$CategoryPreference {

@JsonKey(unknownEnumValue: NotificationCategory.unknown) NotificationCategory get category; Map<String, bool> get channels;
/// Create a copy of CategoryPreference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryPreferenceCopyWith<CategoryPreference> get copyWith => _$CategoryPreferenceCopyWithImpl<CategoryPreference>(this as CategoryPreference, _$identity);

  /// Serializes this CategoryPreference to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryPreference&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.channels, channels));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,const DeepCollectionEquality().hash(channels));

@override
String toString() {
  return 'CategoryPreference(category: $category, channels: $channels)';
}


}

/// @nodoc
abstract mixin class $CategoryPreferenceCopyWith<$Res>  {
  factory $CategoryPreferenceCopyWith(CategoryPreference value, $Res Function(CategoryPreference) _then) = _$CategoryPreferenceCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: NotificationCategory.unknown) NotificationCategory category, Map<String, bool> channels
});




}
/// @nodoc
class _$CategoryPreferenceCopyWithImpl<$Res>
    implements $CategoryPreferenceCopyWith<$Res> {
  _$CategoryPreferenceCopyWithImpl(this._self, this._then);

  final CategoryPreference _self;
  final $Res Function(CategoryPreference) _then;

/// Create a copy of CategoryPreference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? channels = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as NotificationCategory,channels: null == channels ? _self.channels : channels // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryPreference].
extension CategoryPreferencePatterns on CategoryPreference {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryPreference value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryPreference() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryPreference value)  $default,){
final _that = this;
switch (_that) {
case _CategoryPreference():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryPreference value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryPreference() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: NotificationCategory.unknown)  NotificationCategory category,  Map<String, bool> channels)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryPreference() when $default != null:
return $default(_that.category,_that.channels);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: NotificationCategory.unknown)  NotificationCategory category,  Map<String, bool> channels)  $default,) {final _that = this;
switch (_that) {
case _CategoryPreference():
return $default(_that.category,_that.channels);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: NotificationCategory.unknown)  NotificationCategory category,  Map<String, bool> channels)?  $default,) {final _that = this;
switch (_that) {
case _CategoryPreference() when $default != null:
return $default(_that.category,_that.channels);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryPreference extends CategoryPreference {
  const _CategoryPreference({@JsonKey(unknownEnumValue: NotificationCategory.unknown) this.category = NotificationCategory.unknown, final  Map<String, bool> channels = const <String, bool>{}}): _channels = channels,super._();
  factory _CategoryPreference.fromJson(Map<String, dynamic> json) => _$CategoryPreferenceFromJson(json);

@override@JsonKey(unknownEnumValue: NotificationCategory.unknown) final  NotificationCategory category;
 final  Map<String, bool> _channels;
@override@JsonKey() Map<String, bool> get channels {
  if (_channels is EqualUnmodifiableMapView) return _channels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_channels);
}


/// Create a copy of CategoryPreference
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryPreferenceCopyWith<_CategoryPreference> get copyWith => __$CategoryPreferenceCopyWithImpl<_CategoryPreference>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryPreferenceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryPreference&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._channels, _channels));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,const DeepCollectionEquality().hash(_channels));

@override
String toString() {
  return 'CategoryPreference(category: $category, channels: $channels)';
}


}

/// @nodoc
abstract mixin class _$CategoryPreferenceCopyWith<$Res> implements $CategoryPreferenceCopyWith<$Res> {
  factory _$CategoryPreferenceCopyWith(_CategoryPreference value, $Res Function(_CategoryPreference) _then) = __$CategoryPreferenceCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: NotificationCategory.unknown) NotificationCategory category, Map<String, bool> channels
});




}
/// @nodoc
class __$CategoryPreferenceCopyWithImpl<$Res>
    implements _$CategoryPreferenceCopyWith<$Res> {
  __$CategoryPreferenceCopyWithImpl(this._self, this._then);

  final _CategoryPreference _self;
  final $Res Function(_CategoryPreference) _then;

/// Create a copy of CategoryPreference
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? channels = null,}) {
  return _then(_CategoryPreference(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as NotificationCategory,channels: null == channels ? _self._channels : channels // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}


}


/// @nodoc
mixin _$QuietHours {

 bool get enabled; String get from; String get to;
/// Create a copy of QuietHours
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuietHoursCopyWith<QuietHours> get copyWith => _$QuietHoursCopyWithImpl<QuietHours>(this as QuietHours, _$identity);

  /// Serializes this QuietHours to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuietHours&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,from,to);

@override
String toString() {
  return 'QuietHours(enabled: $enabled, from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class $QuietHoursCopyWith<$Res>  {
  factory $QuietHoursCopyWith(QuietHours value, $Res Function(QuietHours) _then) = _$QuietHoursCopyWithImpl;
@useResult
$Res call({
 bool enabled, String from, String to
});




}
/// @nodoc
class _$QuietHoursCopyWithImpl<$Res>
    implements $QuietHoursCopyWith<$Res> {
  _$QuietHoursCopyWithImpl(this._self, this._then);

  final QuietHours _self;
  final $Res Function(QuietHours) _then;

/// Create a copy of QuietHours
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? from = null,Object? to = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [QuietHours].
extension QuietHoursPatterns on QuietHours {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuietHours value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuietHours() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuietHours value)  $default,){
final _that = this;
switch (_that) {
case _QuietHours():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuietHours value)?  $default,){
final _that = this;
switch (_that) {
case _QuietHours() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  String from,  String to)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuietHours() when $default != null:
return $default(_that.enabled,_that.from,_that.to);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  String from,  String to)  $default,) {final _that = this;
switch (_that) {
case _QuietHours():
return $default(_that.enabled,_that.from,_that.to);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  String from,  String to)?  $default,) {final _that = this;
switch (_that) {
case _QuietHours() when $default != null:
return $default(_that.enabled,_that.from,_that.to);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuietHours implements QuietHours {
  const _QuietHours({this.enabled = false, this.from = '22:00', this.to = '07:00'});
  factory _QuietHours.fromJson(Map<String, dynamic> json) => _$QuietHoursFromJson(json);

@override@JsonKey() final  bool enabled;
@override@JsonKey() final  String from;
@override@JsonKey() final  String to;

/// Create a copy of QuietHours
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuietHoursCopyWith<_QuietHours> get copyWith => __$QuietHoursCopyWithImpl<_QuietHours>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuietHoursToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuietHours&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,from,to);

@override
String toString() {
  return 'QuietHours(enabled: $enabled, from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class _$QuietHoursCopyWith<$Res> implements $QuietHoursCopyWith<$Res> {
  factory _$QuietHoursCopyWith(_QuietHours value, $Res Function(_QuietHours) _then) = __$QuietHoursCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, String from, String to
});




}
/// @nodoc
class __$QuietHoursCopyWithImpl<$Res>
    implements _$QuietHoursCopyWith<$Res> {
  __$QuietHoursCopyWithImpl(this._self, this._then);

  final _QuietHours _self;
  final $Res Function(_QuietHours) _then;

/// Create a copy of QuietHours
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? from = null,Object? to = null,}) {
  return _then(_QuietHours(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NotificationSettings {

 List<CategoryPreference> get categories;@JsonKey(unknownEnumValue: EmailDigest.unknown) EmailDigest get emailDigest; QuietHours get quietHours;/// Until then only important notifications arrive.
@NullableUtcDateTimeConverter() DateTime? get pausedUntil;/// Only the read sends this; the write answers without it.
 String? get smsNumber;
/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationSettingsCopyWith<NotificationSettings> get copyWith => _$NotificationSettingsCopyWithImpl<NotificationSettings>(this as NotificationSettings, _$identity);

  /// Serializes this NotificationSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationSettings&&const DeepCollectionEquality().equals(other.categories, categories)&&(identical(other.emailDigest, emailDigest) || other.emailDigest == emailDigest)&&(identical(other.quietHours, quietHours) || other.quietHours == quietHours)&&(identical(other.pausedUntil, pausedUntil) || other.pausedUntil == pausedUntil)&&(identical(other.smsNumber, smsNumber) || other.smsNumber == smsNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(categories),emailDigest,quietHours,pausedUntil,smsNumber);

@override
String toString() {
  return 'NotificationSettings(categories: $categories, emailDigest: $emailDigest, quietHours: $quietHours, pausedUntil: $pausedUntil, smsNumber: $smsNumber)';
}


}

/// @nodoc
abstract mixin class $NotificationSettingsCopyWith<$Res>  {
  factory $NotificationSettingsCopyWith(NotificationSettings value, $Res Function(NotificationSettings) _then) = _$NotificationSettingsCopyWithImpl;
@useResult
$Res call({
 List<CategoryPreference> categories,@JsonKey(unknownEnumValue: EmailDigest.unknown) EmailDigest emailDigest, QuietHours quietHours,@NullableUtcDateTimeConverter() DateTime? pausedUntil, String? smsNumber
});


$QuietHoursCopyWith<$Res> get quietHours;

}
/// @nodoc
class _$NotificationSettingsCopyWithImpl<$Res>
    implements $NotificationSettingsCopyWith<$Res> {
  _$NotificationSettingsCopyWithImpl(this._self, this._then);

  final NotificationSettings _self;
  final $Res Function(NotificationSettings) _then;

/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categories = null,Object? emailDigest = null,Object? quietHours = null,Object? pausedUntil = freezed,Object? smsNumber = freezed,}) {
  return _then(_self.copyWith(
categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<CategoryPreference>,emailDigest: null == emailDigest ? _self.emailDigest : emailDigest // ignore: cast_nullable_to_non_nullable
as EmailDigest,quietHours: null == quietHours ? _self.quietHours : quietHours // ignore: cast_nullable_to_non_nullable
as QuietHours,pausedUntil: freezed == pausedUntil ? _self.pausedUntil : pausedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,smsNumber: freezed == smsNumber ? _self.smsNumber : smsNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuietHoursCopyWith<$Res> get quietHours {
  
  return $QuietHoursCopyWith<$Res>(_self.quietHours, (value) {
    return _then(_self.copyWith(quietHours: value));
  });
}
}


/// Adds pattern-matching-related methods to [NotificationSettings].
extension NotificationSettingsPatterns on NotificationSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationSettings value)  $default,){
final _that = this;
switch (_that) {
case _NotificationSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationSettings value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CategoryPreference> categories, @JsonKey(unknownEnumValue: EmailDigest.unknown)  EmailDigest emailDigest,  QuietHours quietHours, @NullableUtcDateTimeConverter()  DateTime? pausedUntil,  String? smsNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationSettings() when $default != null:
return $default(_that.categories,_that.emailDigest,_that.quietHours,_that.pausedUntil,_that.smsNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CategoryPreference> categories, @JsonKey(unknownEnumValue: EmailDigest.unknown)  EmailDigest emailDigest,  QuietHours quietHours, @NullableUtcDateTimeConverter()  DateTime? pausedUntil,  String? smsNumber)  $default,) {final _that = this;
switch (_that) {
case _NotificationSettings():
return $default(_that.categories,_that.emailDigest,_that.quietHours,_that.pausedUntil,_that.smsNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CategoryPreference> categories, @JsonKey(unknownEnumValue: EmailDigest.unknown)  EmailDigest emailDigest,  QuietHours quietHours, @NullableUtcDateTimeConverter()  DateTime? pausedUntil,  String? smsNumber)?  $default,) {final _that = this;
switch (_that) {
case _NotificationSettings() when $default != null:
return $default(_that.categories,_that.emailDigest,_that.quietHours,_that.pausedUntil,_that.smsNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationSettings extends NotificationSettings {
  const _NotificationSettings({final  List<CategoryPreference> categories = const <CategoryPreference>[], @JsonKey(unknownEnumValue: EmailDigest.unknown) this.emailDigest = EmailDigest.instant, this.quietHours = const QuietHours(), @NullableUtcDateTimeConverter() this.pausedUntil, this.smsNumber}): _categories = categories,super._();
  factory _NotificationSettings.fromJson(Map<String, dynamic> json) => _$NotificationSettingsFromJson(json);

 final  List<CategoryPreference> _categories;
@override@JsonKey() List<CategoryPreference> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

@override@JsonKey(unknownEnumValue: EmailDigest.unknown) final  EmailDigest emailDigest;
@override@JsonKey() final  QuietHours quietHours;
/// Until then only important notifications arrive.
@override@NullableUtcDateTimeConverter() final  DateTime? pausedUntil;
/// Only the read sends this; the write answers without it.
@override final  String? smsNumber;

/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationSettingsCopyWith<_NotificationSettings> get copyWith => __$NotificationSettingsCopyWithImpl<_NotificationSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationSettings&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.emailDigest, emailDigest) || other.emailDigest == emailDigest)&&(identical(other.quietHours, quietHours) || other.quietHours == quietHours)&&(identical(other.pausedUntil, pausedUntil) || other.pausedUntil == pausedUntil)&&(identical(other.smsNumber, smsNumber) || other.smsNumber == smsNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categories),emailDigest,quietHours,pausedUntil,smsNumber);

@override
String toString() {
  return 'NotificationSettings(categories: $categories, emailDigest: $emailDigest, quietHours: $quietHours, pausedUntil: $pausedUntil, smsNumber: $smsNumber)';
}


}

/// @nodoc
abstract mixin class _$NotificationSettingsCopyWith<$Res> implements $NotificationSettingsCopyWith<$Res> {
  factory _$NotificationSettingsCopyWith(_NotificationSettings value, $Res Function(_NotificationSettings) _then) = __$NotificationSettingsCopyWithImpl;
@override @useResult
$Res call({
 List<CategoryPreference> categories,@JsonKey(unknownEnumValue: EmailDigest.unknown) EmailDigest emailDigest, QuietHours quietHours,@NullableUtcDateTimeConverter() DateTime? pausedUntil, String? smsNumber
});


@override $QuietHoursCopyWith<$Res> get quietHours;

}
/// @nodoc
class __$NotificationSettingsCopyWithImpl<$Res>
    implements _$NotificationSettingsCopyWith<$Res> {
  __$NotificationSettingsCopyWithImpl(this._self, this._then);

  final _NotificationSettings _self;
  final $Res Function(_NotificationSettings) _then;

/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categories = null,Object? emailDigest = null,Object? quietHours = null,Object? pausedUntil = freezed,Object? smsNumber = freezed,}) {
  return _then(_NotificationSettings(
categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<CategoryPreference>,emailDigest: null == emailDigest ? _self.emailDigest : emailDigest // ignore: cast_nullable_to_non_nullable
as EmailDigest,quietHours: null == quietHours ? _self.quietHours : quietHours // ignore: cast_nullable_to_non_nullable
as QuietHours,pausedUntil: freezed == pausedUntil ? _self.pausedUntil : pausedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,smsNumber: freezed == smsNumber ? _self.smsNumber : smsNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of NotificationSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuietHoursCopyWith<$Res> get quietHours {
  
  return $QuietHoursCopyWith<$Res>(_self.quietHours, (value) {
    return _then(_self.copyWith(quietHours: value));
  });
}
}

// dart format on
