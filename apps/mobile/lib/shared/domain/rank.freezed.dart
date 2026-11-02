// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rank.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Rank {

 String get id; String get title; int get order;/// What this standing means for the learner.
 String get descriptor; List<CertificateCriterion> get criteria;
/// Create a copy of Rank
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RankCopyWith<Rank> get copyWith => _$RankCopyWithImpl<Rank>(this as Rank, _$identity);

  /// Serializes this Rank to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Rank&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order)&&(identical(other.descriptor, descriptor) || other.descriptor == descriptor)&&const DeepCollectionEquality().equals(other.criteria, criteria));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,order,descriptor,const DeepCollectionEquality().hash(criteria));

@override
String toString() {
  return 'Rank(id: $id, title: $title, order: $order, descriptor: $descriptor, criteria: $criteria)';
}


}

/// @nodoc
abstract mixin class $RankCopyWith<$Res>  {
  factory $RankCopyWith(Rank value, $Res Function(Rank) _then) = _$RankCopyWithImpl;
@useResult
$Res call({
 String id, String title, int order, String descriptor, List<CertificateCriterion> criteria
});




}
/// @nodoc
class _$RankCopyWithImpl<$Res>
    implements $RankCopyWith<$Res> {
  _$RankCopyWithImpl(this._self, this._then);

  final Rank _self;
  final $Res Function(Rank) _then;

/// Create a copy of Rank
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? order = null,Object? descriptor = null,Object? criteria = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,descriptor: null == descriptor ? _self.descriptor : descriptor // ignore: cast_nullable_to_non_nullable
as String,criteria: null == criteria ? _self.criteria : criteria // ignore: cast_nullable_to_non_nullable
as List<CertificateCriterion>,
  ));
}

}


/// Adds pattern-matching-related methods to [Rank].
extension RankPatterns on Rank {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Rank value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Rank() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Rank value)  $default,){
final _that = this;
switch (_that) {
case _Rank():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Rank value)?  $default,){
final _that = this;
switch (_that) {
case _Rank() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  int order,  String descriptor,  List<CertificateCriterion> criteria)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Rank() when $default != null:
return $default(_that.id,_that.title,_that.order,_that.descriptor,_that.criteria);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  int order,  String descriptor,  List<CertificateCriterion> criteria)  $default,) {final _that = this;
switch (_that) {
case _Rank():
return $default(_that.id,_that.title,_that.order,_that.descriptor,_that.criteria);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  int order,  String descriptor,  List<CertificateCriterion> criteria)?  $default,) {final _that = this;
switch (_that) {
case _Rank() when $default != null:
return $default(_that.id,_that.title,_that.order,_that.descriptor,_that.criteria);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Rank implements Rank {
  const _Rank({this.id = '', this.title = '', this.order = 0, this.descriptor = '', final  List<CertificateCriterion> criteria = const <CertificateCriterion>[]}): _criteria = criteria;
  factory _Rank.fromJson(Map<String, dynamic> json) => _$RankFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String title;
@override@JsonKey() final  int order;
/// What this standing means for the learner.
@override@JsonKey() final  String descriptor;
 final  List<CertificateCriterion> _criteria;
@override@JsonKey() List<CertificateCriterion> get criteria {
  if (_criteria is EqualUnmodifiableListView) return _criteria;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_criteria);
}


/// Create a copy of Rank
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RankCopyWith<_Rank> get copyWith => __$RankCopyWithImpl<_Rank>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RankToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Rank&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order)&&(identical(other.descriptor, descriptor) || other.descriptor == descriptor)&&const DeepCollectionEquality().equals(other._criteria, _criteria));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,order,descriptor,const DeepCollectionEquality().hash(_criteria));

@override
String toString() {
  return 'Rank(id: $id, title: $title, order: $order, descriptor: $descriptor, criteria: $criteria)';
}


}

/// @nodoc
abstract mixin class _$RankCopyWith<$Res> implements $RankCopyWith<$Res> {
  factory _$RankCopyWith(_Rank value, $Res Function(_Rank) _then) = __$RankCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, int order, String descriptor, List<CertificateCriterion> criteria
});




}
/// @nodoc
class __$RankCopyWithImpl<$Res>
    implements _$RankCopyWith<$Res> {
  __$RankCopyWithImpl(this._self, this._then);

  final _Rank _self;
  final $Res Function(_Rank) _then;

/// Create a copy of Rank
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? order = null,Object? descriptor = null,Object? criteria = null,}) {
  return _then(_Rank(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,descriptor: null == descriptor ? _self.descriptor : descriptor // ignore: cast_nullable_to_non_nullable
as String,criteria: null == criteria ? _self._criteria : criteria // ignore: cast_nullable_to_non_nullable
as List<CertificateCriterion>,
  ));
}


}


/// @nodoc
mixin _$RankStanding {

 String get rankId; Map<String, String> get achieved; Map<String, num> get progress;
/// Create a copy of RankStanding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RankStandingCopyWith<RankStanding> get copyWith => _$RankStandingCopyWithImpl<RankStanding>(this as RankStanding, _$identity);

  /// Serializes this RankStanding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RankStanding&&(identical(other.rankId, rankId) || other.rankId == rankId)&&const DeepCollectionEquality().equals(other.achieved, achieved)&&const DeepCollectionEquality().equals(other.progress, progress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rankId,const DeepCollectionEquality().hash(achieved),const DeepCollectionEquality().hash(progress));

@override
String toString() {
  return 'RankStanding(rankId: $rankId, achieved: $achieved, progress: $progress)';
}


}

/// @nodoc
abstract mixin class $RankStandingCopyWith<$Res>  {
  factory $RankStandingCopyWith(RankStanding value, $Res Function(RankStanding) _then) = _$RankStandingCopyWithImpl;
@useResult
$Res call({
 String rankId, Map<String, String> achieved, Map<String, num> progress
});




}
/// @nodoc
class _$RankStandingCopyWithImpl<$Res>
    implements $RankStandingCopyWith<$Res> {
  _$RankStandingCopyWithImpl(this._self, this._then);

  final RankStanding _self;
  final $Res Function(RankStanding) _then;

/// Create a copy of RankStanding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rankId = null,Object? achieved = null,Object? progress = null,}) {
  return _then(_self.copyWith(
rankId: null == rankId ? _self.rankId : rankId // ignore: cast_nullable_to_non_nullable
as String,achieved: null == achieved ? _self.achieved : achieved // ignore: cast_nullable_to_non_nullable
as Map<String, String>,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as Map<String, num>,
  ));
}

}


/// Adds pattern-matching-related methods to [RankStanding].
extension RankStandingPatterns on RankStanding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RankStanding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RankStanding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RankStanding value)  $default,){
final _that = this;
switch (_that) {
case _RankStanding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RankStanding value)?  $default,){
final _that = this;
switch (_that) {
case _RankStanding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String rankId,  Map<String, String> achieved,  Map<String, num> progress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RankStanding() when $default != null:
return $default(_that.rankId,_that.achieved,_that.progress);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String rankId,  Map<String, String> achieved,  Map<String, num> progress)  $default,) {final _that = this;
switch (_that) {
case _RankStanding():
return $default(_that.rankId,_that.achieved,_that.progress);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String rankId,  Map<String, String> achieved,  Map<String, num> progress)?  $default,) {final _that = this;
switch (_that) {
case _RankStanding() when $default != null:
return $default(_that.rankId,_that.achieved,_that.progress);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RankStanding implements RankStanding {
  const _RankStanding({this.rankId = '', final  Map<String, String> achieved = const <String, String>{}, final  Map<String, num> progress = const <String, num>{}}): _achieved = achieved,_progress = progress;
  factory _RankStanding.fromJson(Map<String, dynamic> json) => _$RankStandingFromJson(json);

@override@JsonKey() final  String rankId;
 final  Map<String, String> _achieved;
@override@JsonKey() Map<String, String> get achieved {
  if (_achieved is EqualUnmodifiableMapView) return _achieved;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_achieved);
}

 final  Map<String, num> _progress;
@override@JsonKey() Map<String, num> get progress {
  if (_progress is EqualUnmodifiableMapView) return _progress;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_progress);
}


/// Create a copy of RankStanding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RankStandingCopyWith<_RankStanding> get copyWith => __$RankStandingCopyWithImpl<_RankStanding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RankStandingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RankStanding&&(identical(other.rankId, rankId) || other.rankId == rankId)&&const DeepCollectionEquality().equals(other._achieved, _achieved)&&const DeepCollectionEquality().equals(other._progress, _progress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rankId,const DeepCollectionEquality().hash(_achieved),const DeepCollectionEquality().hash(_progress));

@override
String toString() {
  return 'RankStanding(rankId: $rankId, achieved: $achieved, progress: $progress)';
}


}

/// @nodoc
abstract mixin class _$RankStandingCopyWith<$Res> implements $RankStandingCopyWith<$Res> {
  factory _$RankStandingCopyWith(_RankStanding value, $Res Function(_RankStanding) _then) = __$RankStandingCopyWithImpl;
@override @useResult
$Res call({
 String rankId, Map<String, String> achieved, Map<String, num> progress
});




}
/// @nodoc
class __$RankStandingCopyWithImpl<$Res>
    implements _$RankStandingCopyWith<$Res> {
  __$RankStandingCopyWithImpl(this._self, this._then);

  final _RankStanding _self;
  final $Res Function(_RankStanding) _then;

/// Create a copy of RankStanding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rankId = null,Object? achieved = null,Object? progress = null,}) {
  return _then(_RankStanding(
rankId: null == rankId ? _self.rankId : rankId // ignore: cast_nullable_to_non_nullable
as String,achieved: null == achieved ? _self._achieved : achieved // ignore: cast_nullable_to_non_nullable
as Map<String, String>,progress: null == progress ? _self._progress : progress // ignore: cast_nullable_to_non_nullable
as Map<String, num>,
  ));
}


}


/// @nodoc
mixin _$RankLadder {

 List<Rank> get ranks; RankStanding get standing;
/// Create a copy of RankLadder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RankLadderCopyWith<RankLadder> get copyWith => _$RankLadderCopyWithImpl<RankLadder>(this as RankLadder, _$identity);

  /// Serializes this RankLadder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RankLadder&&const DeepCollectionEquality().equals(other.ranks, ranks)&&(identical(other.standing, standing) || other.standing == standing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(ranks),standing);

@override
String toString() {
  return 'RankLadder(ranks: $ranks, standing: $standing)';
}


}

/// @nodoc
abstract mixin class $RankLadderCopyWith<$Res>  {
  factory $RankLadderCopyWith(RankLadder value, $Res Function(RankLadder) _then) = _$RankLadderCopyWithImpl;
@useResult
$Res call({
 List<Rank> ranks, RankStanding standing
});


$RankStandingCopyWith<$Res> get standing;

}
/// @nodoc
class _$RankLadderCopyWithImpl<$Res>
    implements $RankLadderCopyWith<$Res> {
  _$RankLadderCopyWithImpl(this._self, this._then);

  final RankLadder _self;
  final $Res Function(RankLadder) _then;

/// Create a copy of RankLadder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ranks = null,Object? standing = null,}) {
  return _then(_self.copyWith(
ranks: null == ranks ? _self.ranks : ranks // ignore: cast_nullable_to_non_nullable
as List<Rank>,standing: null == standing ? _self.standing : standing // ignore: cast_nullable_to_non_nullable
as RankStanding,
  ));
}
/// Create a copy of RankLadder
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RankStandingCopyWith<$Res> get standing {
  
  return $RankStandingCopyWith<$Res>(_self.standing, (value) {
    return _then(_self.copyWith(standing: value));
  });
}
}


/// Adds pattern-matching-related methods to [RankLadder].
extension RankLadderPatterns on RankLadder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RankLadder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RankLadder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RankLadder value)  $default,){
final _that = this;
switch (_that) {
case _RankLadder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RankLadder value)?  $default,){
final _that = this;
switch (_that) {
case _RankLadder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Rank> ranks,  RankStanding standing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RankLadder() when $default != null:
return $default(_that.ranks,_that.standing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Rank> ranks,  RankStanding standing)  $default,) {final _that = this;
switch (_that) {
case _RankLadder():
return $default(_that.ranks,_that.standing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Rank> ranks,  RankStanding standing)?  $default,) {final _that = this;
switch (_that) {
case _RankLadder() when $default != null:
return $default(_that.ranks,_that.standing);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RankLadder extends RankLadder {
  const _RankLadder({final  List<Rank> ranks = const <Rank>[], this.standing = const RankStanding()}): _ranks = ranks,super._();
  factory _RankLadder.fromJson(Map<String, dynamic> json) => _$RankLadderFromJson(json);

 final  List<Rank> _ranks;
@override@JsonKey() List<Rank> get ranks {
  if (_ranks is EqualUnmodifiableListView) return _ranks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ranks);
}

@override@JsonKey() final  RankStanding standing;

/// Create a copy of RankLadder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RankLadderCopyWith<_RankLadder> get copyWith => __$RankLadderCopyWithImpl<_RankLadder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RankLadderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RankLadder&&const DeepCollectionEquality().equals(other._ranks, _ranks)&&(identical(other.standing, standing) || other.standing == standing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_ranks),standing);

@override
String toString() {
  return 'RankLadder(ranks: $ranks, standing: $standing)';
}


}

/// @nodoc
abstract mixin class _$RankLadderCopyWith<$Res> implements $RankLadderCopyWith<$Res> {
  factory _$RankLadderCopyWith(_RankLadder value, $Res Function(_RankLadder) _then) = __$RankLadderCopyWithImpl;
@override @useResult
$Res call({
 List<Rank> ranks, RankStanding standing
});


@override $RankStandingCopyWith<$Res> get standing;

}
/// @nodoc
class __$RankLadderCopyWithImpl<$Res>
    implements _$RankLadderCopyWith<$Res> {
  __$RankLadderCopyWithImpl(this._self, this._then);

  final _RankLadder _self;
  final $Res Function(_RankLadder) _then;

/// Create a copy of RankLadder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ranks = null,Object? standing = null,}) {
  return _then(_RankLadder(
ranks: null == ranks ? _self._ranks : ranks // ignore: cast_nullable_to_non_nullable
as List<Rank>,standing: null == standing ? _self.standing : standing // ignore: cast_nullable_to_non_nullable
as RankStanding,
  ));
}

/// Create a copy of RankLadder
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RankStandingCopyWith<$Res> get standing {
  
  return $RankStandingCopyWith<$Res>(_self.standing, (value) {
    return _then(_self.copyWith(standing: value));
  });
}
}

// dart format on
