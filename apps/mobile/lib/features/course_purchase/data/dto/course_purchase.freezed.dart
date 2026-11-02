// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'course_purchase.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CoursePurchase {

 String get id; String get courseId; String get courseTitle;@JsonKey(unknownEnumValue: CoursePurchaseStatus.unknown) CoursePurchaseStatus get status; int get amount; String get currency; int get listPrice;/// Whether the course is open to the learner now — the only "it worked" the app believes.
 bool get enrolled; String? get failureMessage;/// Money the gateway took that opened nothing: the academy reviews it.
 bool get needsReview;@NullableUtcDateTimeConverter() DateTime? get createdAt;@NullableUtcDateTimeConverter() DateTime? get paidAt;
/// Create a copy of CoursePurchase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoursePurchaseCopyWith<CoursePurchase> get copyWith => _$CoursePurchaseCopyWithImpl<CoursePurchase>(this as CoursePurchase, _$identity);

  /// Serializes this CoursePurchase to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoursePurchase&&(identical(other.id, id) || other.id == id)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.status, status) || other.status == status)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.listPrice, listPrice) || other.listPrice == listPrice)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.failureMessage, failureMessage) || other.failureMessage == failureMessage)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,courseId,courseTitle,status,amount,currency,listPrice,enrolled,failureMessage,needsReview,createdAt,paidAt);

@override
String toString() {
  return 'CoursePurchase(id: $id, courseId: $courseId, courseTitle: $courseTitle, status: $status, amount: $amount, currency: $currency, listPrice: $listPrice, enrolled: $enrolled, failureMessage: $failureMessage, needsReview: $needsReview, createdAt: $createdAt, paidAt: $paidAt)';
}


}

/// @nodoc
abstract mixin class $CoursePurchaseCopyWith<$Res>  {
  factory $CoursePurchaseCopyWith(CoursePurchase value, $Res Function(CoursePurchase) _then) = _$CoursePurchaseCopyWithImpl;
@useResult
$Res call({
 String id, String courseId, String courseTitle,@JsonKey(unknownEnumValue: CoursePurchaseStatus.unknown) CoursePurchaseStatus status, int amount, String currency, int listPrice, bool enrolled, String? failureMessage, bool needsReview,@NullableUtcDateTimeConverter() DateTime? createdAt,@NullableUtcDateTimeConverter() DateTime? paidAt
});




}
/// @nodoc
class _$CoursePurchaseCopyWithImpl<$Res>
    implements $CoursePurchaseCopyWith<$Res> {
  _$CoursePurchaseCopyWithImpl(this._self, this._then);

  final CoursePurchase _self;
  final $Res Function(CoursePurchase) _then;

/// Create a copy of CoursePurchase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? courseId = null,Object? courseTitle = null,Object? status = null,Object? amount = null,Object? currency = null,Object? listPrice = null,Object? enrolled = null,Object? failureMessage = freezed,Object? needsReview = null,Object? createdAt = freezed,Object? paidAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CoursePurchaseStatus,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,listPrice: null == listPrice ? _self.listPrice : listPrice // ignore: cast_nullable_to_non_nullable
as int,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as bool,failureMessage: freezed == failureMessage ? _self.failureMessage : failureMessage // ignore: cast_nullable_to_non_nullable
as String?,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CoursePurchase].
extension CoursePurchasePatterns on CoursePurchase {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoursePurchase value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoursePurchase() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoursePurchase value)  $default,){
final _that = this;
switch (_that) {
case _CoursePurchase():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoursePurchase value)?  $default,){
final _that = this;
switch (_that) {
case _CoursePurchase() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String courseId,  String courseTitle, @JsonKey(unknownEnumValue: CoursePurchaseStatus.unknown)  CoursePurchaseStatus status,  int amount,  String currency,  int listPrice,  bool enrolled,  String? failureMessage,  bool needsReview, @NullableUtcDateTimeConverter()  DateTime? createdAt, @NullableUtcDateTimeConverter()  DateTime? paidAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoursePurchase() when $default != null:
return $default(_that.id,_that.courseId,_that.courseTitle,_that.status,_that.amount,_that.currency,_that.listPrice,_that.enrolled,_that.failureMessage,_that.needsReview,_that.createdAt,_that.paidAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String courseId,  String courseTitle, @JsonKey(unknownEnumValue: CoursePurchaseStatus.unknown)  CoursePurchaseStatus status,  int amount,  String currency,  int listPrice,  bool enrolled,  String? failureMessage,  bool needsReview, @NullableUtcDateTimeConverter()  DateTime? createdAt, @NullableUtcDateTimeConverter()  DateTime? paidAt)  $default,) {final _that = this;
switch (_that) {
case _CoursePurchase():
return $default(_that.id,_that.courseId,_that.courseTitle,_that.status,_that.amount,_that.currency,_that.listPrice,_that.enrolled,_that.failureMessage,_that.needsReview,_that.createdAt,_that.paidAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String courseId,  String courseTitle, @JsonKey(unknownEnumValue: CoursePurchaseStatus.unknown)  CoursePurchaseStatus status,  int amount,  String currency,  int listPrice,  bool enrolled,  String? failureMessage,  bool needsReview, @NullableUtcDateTimeConverter()  DateTime? createdAt, @NullableUtcDateTimeConverter()  DateTime? paidAt)?  $default,) {final _that = this;
switch (_that) {
case _CoursePurchase() when $default != null:
return $default(_that.id,_that.courseId,_that.courseTitle,_that.status,_that.amount,_that.currency,_that.listPrice,_that.enrolled,_that.failureMessage,_that.needsReview,_that.createdAt,_that.paidAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CoursePurchase extends CoursePurchase {
  const _CoursePurchase({required this.id, this.courseId = '', this.courseTitle = '', @JsonKey(unknownEnumValue: CoursePurchaseStatus.unknown) this.status = CoursePurchaseStatus.unknown, this.amount = 0, this.currency = 'INR', this.listPrice = 0, this.enrolled = false, this.failureMessage, this.needsReview = false, @NullableUtcDateTimeConverter() this.createdAt, @NullableUtcDateTimeConverter() this.paidAt}): super._();
  factory _CoursePurchase.fromJson(Map<String, dynamic> json) => _$CoursePurchaseFromJson(json);

@override final  String id;
@override@JsonKey() final  String courseId;
@override@JsonKey() final  String courseTitle;
@override@JsonKey(unknownEnumValue: CoursePurchaseStatus.unknown) final  CoursePurchaseStatus status;
@override@JsonKey() final  int amount;
@override@JsonKey() final  String currency;
@override@JsonKey() final  int listPrice;
/// Whether the course is open to the learner now — the only "it worked" the app believes.
@override@JsonKey() final  bool enrolled;
@override final  String? failureMessage;
/// Money the gateway took that opened nothing: the academy reviews it.
@override@JsonKey() final  bool needsReview;
@override@NullableUtcDateTimeConverter() final  DateTime? createdAt;
@override@NullableUtcDateTimeConverter() final  DateTime? paidAt;

/// Create a copy of CoursePurchase
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoursePurchaseCopyWith<_CoursePurchase> get copyWith => __$CoursePurchaseCopyWithImpl<_CoursePurchase>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoursePurchaseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoursePurchase&&(identical(other.id, id) || other.id == id)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.status, status) || other.status == status)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.listPrice, listPrice) || other.listPrice == listPrice)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.failureMessage, failureMessage) || other.failureMessage == failureMessage)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,courseId,courseTitle,status,amount,currency,listPrice,enrolled,failureMessage,needsReview,createdAt,paidAt);

@override
String toString() {
  return 'CoursePurchase(id: $id, courseId: $courseId, courseTitle: $courseTitle, status: $status, amount: $amount, currency: $currency, listPrice: $listPrice, enrolled: $enrolled, failureMessage: $failureMessage, needsReview: $needsReview, createdAt: $createdAt, paidAt: $paidAt)';
}


}

/// @nodoc
abstract mixin class _$CoursePurchaseCopyWith<$Res> implements $CoursePurchaseCopyWith<$Res> {
  factory _$CoursePurchaseCopyWith(_CoursePurchase value, $Res Function(_CoursePurchase) _then) = __$CoursePurchaseCopyWithImpl;
@override @useResult
$Res call({
 String id, String courseId, String courseTitle,@JsonKey(unknownEnumValue: CoursePurchaseStatus.unknown) CoursePurchaseStatus status, int amount, String currency, int listPrice, bool enrolled, String? failureMessage, bool needsReview,@NullableUtcDateTimeConverter() DateTime? createdAt,@NullableUtcDateTimeConverter() DateTime? paidAt
});




}
/// @nodoc
class __$CoursePurchaseCopyWithImpl<$Res>
    implements _$CoursePurchaseCopyWith<$Res> {
  __$CoursePurchaseCopyWithImpl(this._self, this._then);

  final _CoursePurchase _self;
  final $Res Function(_CoursePurchase) _then;

/// Create a copy of CoursePurchase
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? courseId = null,Object? courseTitle = null,Object? status = null,Object? amount = null,Object? currency = null,Object? listPrice = null,Object? enrolled = null,Object? failureMessage = freezed,Object? needsReview = null,Object? createdAt = freezed,Object? paidAt = freezed,}) {
  return _then(_CoursePurchase(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CoursePurchaseStatus,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,listPrice: null == listPrice ? _self.listPrice : listPrice // ignore: cast_nullable_to_non_nullable
as int,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as bool,failureMessage: freezed == failureMessage ? _self.failureMessage : failureMessage // ignore: cast_nullable_to_non_nullable
as String?,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CheckoutPrefill {

 String get name; String get email;
/// Create a copy of CheckoutPrefill
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckoutPrefillCopyWith<CheckoutPrefill> get copyWith => _$CheckoutPrefillCopyWithImpl<CheckoutPrefill>(this as CheckoutPrefill, _$identity);

  /// Serializes this CheckoutPrefill to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckoutPrefill&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,email);

@override
String toString() {
  return 'CheckoutPrefill(name: $name, email: $email)';
}


}

/// @nodoc
abstract mixin class $CheckoutPrefillCopyWith<$Res>  {
  factory $CheckoutPrefillCopyWith(CheckoutPrefill value, $Res Function(CheckoutPrefill) _then) = _$CheckoutPrefillCopyWithImpl;
@useResult
$Res call({
 String name, String email
});




}
/// @nodoc
class _$CheckoutPrefillCopyWithImpl<$Res>
    implements $CheckoutPrefillCopyWith<$Res> {
  _$CheckoutPrefillCopyWithImpl(this._self, this._then);

  final CheckoutPrefill _self;
  final $Res Function(CheckoutPrefill) _then;

/// Create a copy of CheckoutPrefill
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? email = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckoutPrefill].
extension CheckoutPrefillPatterns on CheckoutPrefill {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckoutPrefill value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckoutPrefill() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckoutPrefill value)  $default,){
final _that = this;
switch (_that) {
case _CheckoutPrefill():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckoutPrefill value)?  $default,){
final _that = this;
switch (_that) {
case _CheckoutPrefill() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String email)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckoutPrefill() when $default != null:
return $default(_that.name,_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String email)  $default,) {final _that = this;
switch (_that) {
case _CheckoutPrefill():
return $default(_that.name,_that.email);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String email)?  $default,) {final _that = this;
switch (_that) {
case _CheckoutPrefill() when $default != null:
return $default(_that.name,_that.email);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckoutPrefill implements CheckoutPrefill {
  const _CheckoutPrefill({this.name = '', this.email = ''});
  factory _CheckoutPrefill.fromJson(Map<String, dynamic> json) => _$CheckoutPrefillFromJson(json);

@override@JsonKey() final  String name;
@override@JsonKey() final  String email;

/// Create a copy of CheckoutPrefill
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckoutPrefillCopyWith<_CheckoutPrefill> get copyWith => __$CheckoutPrefillCopyWithImpl<_CheckoutPrefill>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckoutPrefillToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckoutPrefill&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,email);

@override
String toString() {
  return 'CheckoutPrefill(name: $name, email: $email)';
}


}

/// @nodoc
abstract mixin class _$CheckoutPrefillCopyWith<$Res> implements $CheckoutPrefillCopyWith<$Res> {
  factory _$CheckoutPrefillCopyWith(_CheckoutPrefill value, $Res Function(_CheckoutPrefill) _then) = __$CheckoutPrefillCopyWithImpl;
@override @useResult
$Res call({
 String name, String email
});




}
/// @nodoc
class __$CheckoutPrefillCopyWithImpl<$Res>
    implements _$CheckoutPrefillCopyWith<$Res> {
  __$CheckoutPrefillCopyWithImpl(this._self, this._then);

  final _CheckoutPrefill _self;
  final $Res Function(_CheckoutPrefill) _then;

/// Create a copy of CheckoutPrefill
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? email = null,}) {
  return _then(_CheckoutPrefill(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CourseCheckout {

 String get provider; String? get keyId; String get orderId; int get amount; String get currency; String? get redirectUrl; String get description; CheckoutPrefill? get prefill;
/// Create a copy of CourseCheckout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourseCheckoutCopyWith<CourseCheckout> get copyWith => _$CourseCheckoutCopyWithImpl<CourseCheckout>(this as CourseCheckout, _$identity);

  /// Serializes this CourseCheckout to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CourseCheckout&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.keyId, keyId) || other.keyId == keyId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.redirectUrl, redirectUrl) || other.redirectUrl == redirectUrl)&&(identical(other.description, description) || other.description == description)&&(identical(other.prefill, prefill) || other.prefill == prefill));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,keyId,orderId,amount,currency,redirectUrl,description,prefill);

@override
String toString() {
  return 'CourseCheckout(provider: $provider, keyId: $keyId, orderId: $orderId, amount: $amount, currency: $currency, redirectUrl: $redirectUrl, description: $description, prefill: $prefill)';
}


}

/// @nodoc
abstract mixin class $CourseCheckoutCopyWith<$Res>  {
  factory $CourseCheckoutCopyWith(CourseCheckout value, $Res Function(CourseCheckout) _then) = _$CourseCheckoutCopyWithImpl;
@useResult
$Res call({
 String provider, String? keyId, String orderId, int amount, String currency, String? redirectUrl, String description, CheckoutPrefill? prefill
});


$CheckoutPrefillCopyWith<$Res>? get prefill;

}
/// @nodoc
class _$CourseCheckoutCopyWithImpl<$Res>
    implements $CourseCheckoutCopyWith<$Res> {
  _$CourseCheckoutCopyWithImpl(this._self, this._then);

  final CourseCheckout _self;
  final $Res Function(CourseCheckout) _then;

/// Create a copy of CourseCheckout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = null,Object? keyId = freezed,Object? orderId = null,Object? amount = null,Object? currency = null,Object? redirectUrl = freezed,Object? description = null,Object? prefill = freezed,}) {
  return _then(_self.copyWith(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,keyId: freezed == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String?,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,redirectUrl: freezed == redirectUrl ? _self.redirectUrl : redirectUrl // ignore: cast_nullable_to_non_nullable
as String?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,prefill: freezed == prefill ? _self.prefill : prefill // ignore: cast_nullable_to_non_nullable
as CheckoutPrefill?,
  ));
}
/// Create a copy of CourseCheckout
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CheckoutPrefillCopyWith<$Res>? get prefill {
    if (_self.prefill == null) {
    return null;
  }

  return $CheckoutPrefillCopyWith<$Res>(_self.prefill!, (value) {
    return _then(_self.copyWith(prefill: value));
  });
}
}


/// Adds pattern-matching-related methods to [CourseCheckout].
extension CourseCheckoutPatterns on CourseCheckout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CourseCheckout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CourseCheckout() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CourseCheckout value)  $default,){
final _that = this;
switch (_that) {
case _CourseCheckout():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CourseCheckout value)?  $default,){
final _that = this;
switch (_that) {
case _CourseCheckout() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String provider,  String? keyId,  String orderId,  int amount,  String currency,  String? redirectUrl,  String description,  CheckoutPrefill? prefill)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CourseCheckout() when $default != null:
return $default(_that.provider,_that.keyId,_that.orderId,_that.amount,_that.currency,_that.redirectUrl,_that.description,_that.prefill);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String provider,  String? keyId,  String orderId,  int amount,  String currency,  String? redirectUrl,  String description,  CheckoutPrefill? prefill)  $default,) {final _that = this;
switch (_that) {
case _CourseCheckout():
return $default(_that.provider,_that.keyId,_that.orderId,_that.amount,_that.currency,_that.redirectUrl,_that.description,_that.prefill);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String provider,  String? keyId,  String orderId,  int amount,  String currency,  String? redirectUrl,  String description,  CheckoutPrefill? prefill)?  $default,) {final _that = this;
switch (_that) {
case _CourseCheckout() when $default != null:
return $default(_that.provider,_that.keyId,_that.orderId,_that.amount,_that.currency,_that.redirectUrl,_that.description,_that.prefill);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CourseCheckout implements CourseCheckout {
  const _CourseCheckout({this.provider = '', this.keyId, this.orderId = '', this.amount = 0, this.currency = 'INR', this.redirectUrl, this.description = '', this.prefill});
  factory _CourseCheckout.fromJson(Map<String, dynamic> json) => _$CourseCheckoutFromJson(json);

@override@JsonKey() final  String provider;
@override final  String? keyId;
@override@JsonKey() final  String orderId;
@override@JsonKey() final  int amount;
@override@JsonKey() final  String currency;
@override final  String? redirectUrl;
@override@JsonKey() final  String description;
@override final  CheckoutPrefill? prefill;

/// Create a copy of CourseCheckout
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourseCheckoutCopyWith<_CourseCheckout> get copyWith => __$CourseCheckoutCopyWithImpl<_CourseCheckout>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourseCheckoutToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CourseCheckout&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.keyId, keyId) || other.keyId == keyId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.redirectUrl, redirectUrl) || other.redirectUrl == redirectUrl)&&(identical(other.description, description) || other.description == description)&&(identical(other.prefill, prefill) || other.prefill == prefill));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,keyId,orderId,amount,currency,redirectUrl,description,prefill);

@override
String toString() {
  return 'CourseCheckout(provider: $provider, keyId: $keyId, orderId: $orderId, amount: $amount, currency: $currency, redirectUrl: $redirectUrl, description: $description, prefill: $prefill)';
}


}

/// @nodoc
abstract mixin class _$CourseCheckoutCopyWith<$Res> implements $CourseCheckoutCopyWith<$Res> {
  factory _$CourseCheckoutCopyWith(_CourseCheckout value, $Res Function(_CourseCheckout) _then) = __$CourseCheckoutCopyWithImpl;
@override @useResult
$Res call({
 String provider, String? keyId, String orderId, int amount, String currency, String? redirectUrl, String description, CheckoutPrefill? prefill
});


@override $CheckoutPrefillCopyWith<$Res>? get prefill;

}
/// @nodoc
class __$CourseCheckoutCopyWithImpl<$Res>
    implements _$CourseCheckoutCopyWith<$Res> {
  __$CourseCheckoutCopyWithImpl(this._self, this._then);

  final _CourseCheckout _self;
  final $Res Function(_CourseCheckout) _then;

/// Create a copy of CourseCheckout
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? keyId = freezed,Object? orderId = null,Object? amount = null,Object? currency = null,Object? redirectUrl = freezed,Object? description = null,Object? prefill = freezed,}) {
  return _then(_CourseCheckout(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,keyId: freezed == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String?,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,redirectUrl: freezed == redirectUrl ? _self.redirectUrl : redirectUrl // ignore: cast_nullable_to_non_nullable
as String?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,prefill: freezed == prefill ? _self.prefill : prefill // ignore: cast_nullable_to_non_nullable
as CheckoutPrefill?,
  ));
}

/// Create a copy of CourseCheckout
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CheckoutPrefillCopyWith<$Res>? get prefill {
    if (_self.prefill == null) {
    return null;
  }

  return $CheckoutPrefillCopyWith<$Res>(_self.prefill!, (value) {
    return _then(_self.copyWith(prefill: value));
  });
}
}


/// @nodoc
mixin _$CoursePurchaseStart {

 CoursePurchase get purchase; CourseCheckout get checkout;
/// Create a copy of CoursePurchaseStart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoursePurchaseStartCopyWith<CoursePurchaseStart> get copyWith => _$CoursePurchaseStartCopyWithImpl<CoursePurchaseStart>(this as CoursePurchaseStart, _$identity);

  /// Serializes this CoursePurchaseStart to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoursePurchaseStart&&(identical(other.purchase, purchase) || other.purchase == purchase)&&(identical(other.checkout, checkout) || other.checkout == checkout));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,purchase,checkout);

@override
String toString() {
  return 'CoursePurchaseStart(purchase: $purchase, checkout: $checkout)';
}


}

/// @nodoc
abstract mixin class $CoursePurchaseStartCopyWith<$Res>  {
  factory $CoursePurchaseStartCopyWith(CoursePurchaseStart value, $Res Function(CoursePurchaseStart) _then) = _$CoursePurchaseStartCopyWithImpl;
@useResult
$Res call({
 CoursePurchase purchase, CourseCheckout checkout
});


$CoursePurchaseCopyWith<$Res> get purchase;$CourseCheckoutCopyWith<$Res> get checkout;

}
/// @nodoc
class _$CoursePurchaseStartCopyWithImpl<$Res>
    implements $CoursePurchaseStartCopyWith<$Res> {
  _$CoursePurchaseStartCopyWithImpl(this._self, this._then);

  final CoursePurchaseStart _self;
  final $Res Function(CoursePurchaseStart) _then;

/// Create a copy of CoursePurchaseStart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? purchase = null,Object? checkout = null,}) {
  return _then(_self.copyWith(
purchase: null == purchase ? _self.purchase : purchase // ignore: cast_nullable_to_non_nullable
as CoursePurchase,checkout: null == checkout ? _self.checkout : checkout // ignore: cast_nullable_to_non_nullable
as CourseCheckout,
  ));
}
/// Create a copy of CoursePurchaseStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoursePurchaseCopyWith<$Res> get purchase {
  
  return $CoursePurchaseCopyWith<$Res>(_self.purchase, (value) {
    return _then(_self.copyWith(purchase: value));
  });
}/// Create a copy of CoursePurchaseStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseCheckoutCopyWith<$Res> get checkout {
  
  return $CourseCheckoutCopyWith<$Res>(_self.checkout, (value) {
    return _then(_self.copyWith(checkout: value));
  });
}
}


/// Adds pattern-matching-related methods to [CoursePurchaseStart].
extension CoursePurchaseStartPatterns on CoursePurchaseStart {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoursePurchaseStart value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoursePurchaseStart() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoursePurchaseStart value)  $default,){
final _that = this;
switch (_that) {
case _CoursePurchaseStart():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoursePurchaseStart value)?  $default,){
final _that = this;
switch (_that) {
case _CoursePurchaseStart() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CoursePurchase purchase,  CourseCheckout checkout)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoursePurchaseStart() when $default != null:
return $default(_that.purchase,_that.checkout);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CoursePurchase purchase,  CourseCheckout checkout)  $default,) {final _that = this;
switch (_that) {
case _CoursePurchaseStart():
return $default(_that.purchase,_that.checkout);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CoursePurchase purchase,  CourseCheckout checkout)?  $default,) {final _that = this;
switch (_that) {
case _CoursePurchaseStart() when $default != null:
return $default(_that.purchase,_that.checkout);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CoursePurchaseStart implements CoursePurchaseStart {
  const _CoursePurchaseStart({required this.purchase, required this.checkout});
  factory _CoursePurchaseStart.fromJson(Map<String, dynamic> json) => _$CoursePurchaseStartFromJson(json);

@override final  CoursePurchase purchase;
@override final  CourseCheckout checkout;

/// Create a copy of CoursePurchaseStart
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoursePurchaseStartCopyWith<_CoursePurchaseStart> get copyWith => __$CoursePurchaseStartCopyWithImpl<_CoursePurchaseStart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoursePurchaseStartToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoursePurchaseStart&&(identical(other.purchase, purchase) || other.purchase == purchase)&&(identical(other.checkout, checkout) || other.checkout == checkout));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,purchase,checkout);

@override
String toString() {
  return 'CoursePurchaseStart(purchase: $purchase, checkout: $checkout)';
}


}

/// @nodoc
abstract mixin class _$CoursePurchaseStartCopyWith<$Res> implements $CoursePurchaseStartCopyWith<$Res> {
  factory _$CoursePurchaseStartCopyWith(_CoursePurchaseStart value, $Res Function(_CoursePurchaseStart) _then) = __$CoursePurchaseStartCopyWithImpl;
@override @useResult
$Res call({
 CoursePurchase purchase, CourseCheckout checkout
});


@override $CoursePurchaseCopyWith<$Res> get purchase;@override $CourseCheckoutCopyWith<$Res> get checkout;

}
/// @nodoc
class __$CoursePurchaseStartCopyWithImpl<$Res>
    implements _$CoursePurchaseStartCopyWith<$Res> {
  __$CoursePurchaseStartCopyWithImpl(this._self, this._then);

  final _CoursePurchaseStart _self;
  final $Res Function(_CoursePurchaseStart) _then;

/// Create a copy of CoursePurchaseStart
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? purchase = null,Object? checkout = null,}) {
  return _then(_CoursePurchaseStart(
purchase: null == purchase ? _self.purchase : purchase // ignore: cast_nullable_to_non_nullable
as CoursePurchase,checkout: null == checkout ? _self.checkout : checkout // ignore: cast_nullable_to_non_nullable
as CourseCheckout,
  ));
}

/// Create a copy of CoursePurchaseStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoursePurchaseCopyWith<$Res> get purchase {
  
  return $CoursePurchaseCopyWith<$Res>(_self.purchase, (value) {
    return _then(_self.copyWith(purchase: value));
  });
}/// Create a copy of CoursePurchaseStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CourseCheckoutCopyWith<$Res> get checkout {
  
  return $CourseCheckoutCopyWith<$Res>(_self.checkout, (value) {
    return _then(_self.copyWith(checkout: value));
  });
}
}


/// @nodoc
mixin _$PurchaseOutcome {

@JsonKey(unknownEnumValue: PurchaseOutcomeStatus.unknown) PurchaseOutcomeStatus get status; bool get enrolled; String get message;
/// Create a copy of PurchaseOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseOutcomeCopyWith<PurchaseOutcome> get copyWith => _$PurchaseOutcomeCopyWithImpl<PurchaseOutcome>(this as PurchaseOutcome, _$identity);

  /// Serializes this PurchaseOutcome to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseOutcome&&(identical(other.status, status) || other.status == status)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,enrolled,message);

@override
String toString() {
  return 'PurchaseOutcome(status: $status, enrolled: $enrolled, message: $message)';
}


}

/// @nodoc
abstract mixin class $PurchaseOutcomeCopyWith<$Res>  {
  factory $PurchaseOutcomeCopyWith(PurchaseOutcome value, $Res Function(PurchaseOutcome) _then) = _$PurchaseOutcomeCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: PurchaseOutcomeStatus.unknown) PurchaseOutcomeStatus status, bool enrolled, String message
});




}
/// @nodoc
class _$PurchaseOutcomeCopyWithImpl<$Res>
    implements $PurchaseOutcomeCopyWith<$Res> {
  _$PurchaseOutcomeCopyWithImpl(this._self, this._then);

  final PurchaseOutcome _self;
  final $Res Function(PurchaseOutcome) _then;

/// Create a copy of PurchaseOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? enrolled = null,Object? message = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PurchaseOutcomeStatus,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as bool,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PurchaseOutcome].
extension PurchaseOutcomePatterns on PurchaseOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PurchaseOutcome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PurchaseOutcome() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PurchaseOutcome value)  $default,){
final _that = this;
switch (_that) {
case _PurchaseOutcome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PurchaseOutcome value)?  $default,){
final _that = this;
switch (_that) {
case _PurchaseOutcome() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: PurchaseOutcomeStatus.unknown)  PurchaseOutcomeStatus status,  bool enrolled,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurchaseOutcome() when $default != null:
return $default(_that.status,_that.enrolled,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: PurchaseOutcomeStatus.unknown)  PurchaseOutcomeStatus status,  bool enrolled,  String message)  $default,) {final _that = this;
switch (_that) {
case _PurchaseOutcome():
return $default(_that.status,_that.enrolled,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: PurchaseOutcomeStatus.unknown)  PurchaseOutcomeStatus status,  bool enrolled,  String message)?  $default,) {final _that = this;
switch (_that) {
case _PurchaseOutcome() when $default != null:
return $default(_that.status,_that.enrolled,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PurchaseOutcome implements PurchaseOutcome {
  const _PurchaseOutcome({@JsonKey(unknownEnumValue: PurchaseOutcomeStatus.unknown) this.status = PurchaseOutcomeStatus.unknown, this.enrolled = false, this.message = ''});
  factory _PurchaseOutcome.fromJson(Map<String, dynamic> json) => _$PurchaseOutcomeFromJson(json);

@override@JsonKey(unknownEnumValue: PurchaseOutcomeStatus.unknown) final  PurchaseOutcomeStatus status;
@override@JsonKey() final  bool enrolled;
@override@JsonKey() final  String message;

/// Create a copy of PurchaseOutcome
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseOutcomeCopyWith<_PurchaseOutcome> get copyWith => __$PurchaseOutcomeCopyWithImpl<_PurchaseOutcome>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PurchaseOutcomeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseOutcome&&(identical(other.status, status) || other.status == status)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,enrolled,message);

@override
String toString() {
  return 'PurchaseOutcome(status: $status, enrolled: $enrolled, message: $message)';
}


}

/// @nodoc
abstract mixin class _$PurchaseOutcomeCopyWith<$Res> implements $PurchaseOutcomeCopyWith<$Res> {
  factory _$PurchaseOutcomeCopyWith(_PurchaseOutcome value, $Res Function(_PurchaseOutcome) _then) = __$PurchaseOutcomeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: PurchaseOutcomeStatus.unknown) PurchaseOutcomeStatus status, bool enrolled, String message
});




}
/// @nodoc
class __$PurchaseOutcomeCopyWithImpl<$Res>
    implements _$PurchaseOutcomeCopyWith<$Res> {
  __$PurchaseOutcomeCopyWithImpl(this._self, this._then);

  final _PurchaseOutcome _self;
  final $Res Function(_PurchaseOutcome) _then;

/// Create a copy of PurchaseOutcome
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? enrolled = null,Object? message = null,}) {
  return _then(_PurchaseOutcome(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PurchaseOutcomeStatus,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as bool,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PurchaseConfirmation {

 CoursePurchase get purchase; PurchaseOutcome get outcome;
/// Create a copy of PurchaseConfirmation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseConfirmationCopyWith<PurchaseConfirmation> get copyWith => _$PurchaseConfirmationCopyWithImpl<PurchaseConfirmation>(this as PurchaseConfirmation, _$identity);

  /// Serializes this PurchaseConfirmation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseConfirmation&&(identical(other.purchase, purchase) || other.purchase == purchase)&&(identical(other.outcome, outcome) || other.outcome == outcome));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,purchase,outcome);

@override
String toString() {
  return 'PurchaseConfirmation(purchase: $purchase, outcome: $outcome)';
}


}

/// @nodoc
abstract mixin class $PurchaseConfirmationCopyWith<$Res>  {
  factory $PurchaseConfirmationCopyWith(PurchaseConfirmation value, $Res Function(PurchaseConfirmation) _then) = _$PurchaseConfirmationCopyWithImpl;
@useResult
$Res call({
 CoursePurchase purchase, PurchaseOutcome outcome
});


$CoursePurchaseCopyWith<$Res> get purchase;$PurchaseOutcomeCopyWith<$Res> get outcome;

}
/// @nodoc
class _$PurchaseConfirmationCopyWithImpl<$Res>
    implements $PurchaseConfirmationCopyWith<$Res> {
  _$PurchaseConfirmationCopyWithImpl(this._self, this._then);

  final PurchaseConfirmation _self;
  final $Res Function(PurchaseConfirmation) _then;

/// Create a copy of PurchaseConfirmation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? purchase = null,Object? outcome = null,}) {
  return _then(_self.copyWith(
purchase: null == purchase ? _self.purchase : purchase // ignore: cast_nullable_to_non_nullable
as CoursePurchase,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as PurchaseOutcome,
  ));
}
/// Create a copy of PurchaseConfirmation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoursePurchaseCopyWith<$Res> get purchase {
  
  return $CoursePurchaseCopyWith<$Res>(_self.purchase, (value) {
    return _then(_self.copyWith(purchase: value));
  });
}/// Create a copy of PurchaseConfirmation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PurchaseOutcomeCopyWith<$Res> get outcome {
  
  return $PurchaseOutcomeCopyWith<$Res>(_self.outcome, (value) {
    return _then(_self.copyWith(outcome: value));
  });
}
}


/// Adds pattern-matching-related methods to [PurchaseConfirmation].
extension PurchaseConfirmationPatterns on PurchaseConfirmation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PurchaseConfirmation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PurchaseConfirmation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PurchaseConfirmation value)  $default,){
final _that = this;
switch (_that) {
case _PurchaseConfirmation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PurchaseConfirmation value)?  $default,){
final _that = this;
switch (_that) {
case _PurchaseConfirmation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CoursePurchase purchase,  PurchaseOutcome outcome)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurchaseConfirmation() when $default != null:
return $default(_that.purchase,_that.outcome);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CoursePurchase purchase,  PurchaseOutcome outcome)  $default,) {final _that = this;
switch (_that) {
case _PurchaseConfirmation():
return $default(_that.purchase,_that.outcome);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CoursePurchase purchase,  PurchaseOutcome outcome)?  $default,) {final _that = this;
switch (_that) {
case _PurchaseConfirmation() when $default != null:
return $default(_that.purchase,_that.outcome);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PurchaseConfirmation implements PurchaseConfirmation {
  const _PurchaseConfirmation({required this.purchase, required this.outcome});
  factory _PurchaseConfirmation.fromJson(Map<String, dynamic> json) => _$PurchaseConfirmationFromJson(json);

@override final  CoursePurchase purchase;
@override final  PurchaseOutcome outcome;

/// Create a copy of PurchaseConfirmation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseConfirmationCopyWith<_PurchaseConfirmation> get copyWith => __$PurchaseConfirmationCopyWithImpl<_PurchaseConfirmation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PurchaseConfirmationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseConfirmation&&(identical(other.purchase, purchase) || other.purchase == purchase)&&(identical(other.outcome, outcome) || other.outcome == outcome));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,purchase,outcome);

@override
String toString() {
  return 'PurchaseConfirmation(purchase: $purchase, outcome: $outcome)';
}


}

/// @nodoc
abstract mixin class _$PurchaseConfirmationCopyWith<$Res> implements $PurchaseConfirmationCopyWith<$Res> {
  factory _$PurchaseConfirmationCopyWith(_PurchaseConfirmation value, $Res Function(_PurchaseConfirmation) _then) = __$PurchaseConfirmationCopyWithImpl;
@override @useResult
$Res call({
 CoursePurchase purchase, PurchaseOutcome outcome
});


@override $CoursePurchaseCopyWith<$Res> get purchase;@override $PurchaseOutcomeCopyWith<$Res> get outcome;

}
/// @nodoc
class __$PurchaseConfirmationCopyWithImpl<$Res>
    implements _$PurchaseConfirmationCopyWith<$Res> {
  __$PurchaseConfirmationCopyWithImpl(this._self, this._then);

  final _PurchaseConfirmation _self;
  final $Res Function(_PurchaseConfirmation) _then;

/// Create a copy of PurchaseConfirmation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? purchase = null,Object? outcome = null,}) {
  return _then(_PurchaseConfirmation(
purchase: null == purchase ? _self.purchase : purchase // ignore: cast_nullable_to_non_nullable
as CoursePurchase,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as PurchaseOutcome,
  ));
}

/// Create a copy of PurchaseConfirmation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoursePurchaseCopyWith<$Res> get purchase {
  
  return $CoursePurchaseCopyWith<$Res>(_self.purchase, (value) {
    return _then(_self.copyWith(purchase: value));
  });
}/// Create a copy of PurchaseConfirmation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PurchaseOutcomeCopyWith<$Res> get outcome {
  
  return $PurchaseOutcomeCopyWith<$Res>(_self.outcome, (value) {
    return _then(_self.copyWith(outcome: value));
  });
}
}

// dart format on
