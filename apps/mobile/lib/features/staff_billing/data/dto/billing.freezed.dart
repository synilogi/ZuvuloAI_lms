// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'billing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BillingCustomer {

 String get id; String get name; String get email; String get city; String get country; int get learners;
/// Create a copy of BillingCustomer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillingCustomerCopyWith<BillingCustomer> get copyWith => _$BillingCustomerCopyWithImpl<BillingCustomer>(this as BillingCustomer, _$identity);

  /// Serializes this BillingCustomer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillingCustomer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.city, city) || other.city == city)&&(identical(other.country, country) || other.country == country)&&(identical(other.learners, learners) || other.learners == learners));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,city,country,learners);

@override
String toString() {
  return 'BillingCustomer(id: $id, name: $name, email: $email, city: $city, country: $country, learners: $learners)';
}


}

/// @nodoc
abstract mixin class $BillingCustomerCopyWith<$Res>  {
  factory $BillingCustomerCopyWith(BillingCustomer value, $Res Function(BillingCustomer) _then) = _$BillingCustomerCopyWithImpl;
@useResult
$Res call({
 String id, String name, String email, String city, String country, int learners
});




}
/// @nodoc
class _$BillingCustomerCopyWithImpl<$Res>
    implements $BillingCustomerCopyWith<$Res> {
  _$BillingCustomerCopyWithImpl(this._self, this._then);

  final BillingCustomer _self;
  final $Res Function(BillingCustomer) _then;

/// Create a copy of BillingCustomer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,Object? city = null,Object? country = null,Object? learners = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,learners: null == learners ? _self.learners : learners // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BillingCustomer].
extension BillingCustomerPatterns on BillingCustomer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BillingCustomer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BillingCustomer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BillingCustomer value)  $default,){
final _that = this;
switch (_that) {
case _BillingCustomer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BillingCustomer value)?  $default,){
final _that = this;
switch (_that) {
case _BillingCustomer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String email,  String city,  String country,  int learners)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BillingCustomer() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.city,_that.country,_that.learners);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String email,  String city,  String country,  int learners)  $default,) {final _that = this;
switch (_that) {
case _BillingCustomer():
return $default(_that.id,_that.name,_that.email,_that.city,_that.country,_that.learners);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String email,  String city,  String country,  int learners)?  $default,) {final _that = this;
switch (_that) {
case _BillingCustomer() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.city,_that.country,_that.learners);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BillingCustomer implements BillingCustomer {
  const _BillingCustomer({this.id = '', this.name = '', this.email = '', this.city = '', this.country = '', this.learners = 0});
  factory _BillingCustomer.fromJson(Map<String, dynamic> json) => _$BillingCustomerFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String email;
@override@JsonKey() final  String city;
@override@JsonKey() final  String country;
@override@JsonKey() final  int learners;

/// Create a copy of BillingCustomer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillingCustomerCopyWith<_BillingCustomer> get copyWith => __$BillingCustomerCopyWithImpl<_BillingCustomer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillingCustomerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BillingCustomer&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.city, city) || other.city == city)&&(identical(other.country, country) || other.country == country)&&(identical(other.learners, learners) || other.learners == learners));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,city,country,learners);

@override
String toString() {
  return 'BillingCustomer(id: $id, name: $name, email: $email, city: $city, country: $country, learners: $learners)';
}


}

/// @nodoc
abstract mixin class _$BillingCustomerCopyWith<$Res> implements $BillingCustomerCopyWith<$Res> {
  factory _$BillingCustomerCopyWith(_BillingCustomer value, $Res Function(_BillingCustomer) _then) = __$BillingCustomerCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String email, String city, String country, int learners
});




}
/// @nodoc
class __$BillingCustomerCopyWithImpl<$Res>
    implements _$BillingCustomerCopyWith<$Res> {
  __$BillingCustomerCopyWithImpl(this._self, this._then);

  final _BillingCustomer _self;
  final $Res Function(_BillingCustomer) _then;

/// Create a copy of BillingCustomer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,Object? city = null,Object? country = null,Object? learners = null,}) {
  return _then(_BillingCustomer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,learners: null == learners ? _self.learners : learners // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PaymentMethodView {

@JsonKey(unknownEnumValue: PaymentMethodKind.unknown) PaymentMethodKind get kind; String get brand; String? get last4; String? get expiry;
/// Create a copy of PaymentMethodView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentMethodViewCopyWith<PaymentMethodView> get copyWith => _$PaymentMethodViewCopyWithImpl<PaymentMethodView>(this as PaymentMethodView, _$identity);

  /// Serializes this PaymentMethodView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentMethodView&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.expiry, expiry) || other.expiry == expiry));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,brand,last4,expiry);

@override
String toString() {
  return 'PaymentMethodView(kind: $kind, brand: $brand, last4: $last4, expiry: $expiry)';
}


}

/// @nodoc
abstract mixin class $PaymentMethodViewCopyWith<$Res>  {
  factory $PaymentMethodViewCopyWith(PaymentMethodView value, $Res Function(PaymentMethodView) _then) = _$PaymentMethodViewCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: PaymentMethodKind.unknown) PaymentMethodKind kind, String brand, String? last4, String? expiry
});




}
/// @nodoc
class _$PaymentMethodViewCopyWithImpl<$Res>
    implements $PaymentMethodViewCopyWith<$Res> {
  _$PaymentMethodViewCopyWithImpl(this._self, this._then);

  final PaymentMethodView _self;
  final $Res Function(PaymentMethodView) _then;

/// Create a copy of PaymentMethodView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? brand = null,Object? last4 = freezed,Object? expiry = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PaymentMethodKind,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,last4: freezed == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String?,expiry: freezed == expiry ? _self.expiry : expiry // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentMethodView].
extension PaymentMethodViewPatterns on PaymentMethodView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentMethodView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentMethodView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentMethodView value)  $default,){
final _that = this;
switch (_that) {
case _PaymentMethodView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentMethodView value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentMethodView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: PaymentMethodKind.unknown)  PaymentMethodKind kind,  String brand,  String? last4,  String? expiry)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentMethodView() when $default != null:
return $default(_that.kind,_that.brand,_that.last4,_that.expiry);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: PaymentMethodKind.unknown)  PaymentMethodKind kind,  String brand,  String? last4,  String? expiry)  $default,) {final _that = this;
switch (_that) {
case _PaymentMethodView():
return $default(_that.kind,_that.brand,_that.last4,_that.expiry);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: PaymentMethodKind.unknown)  PaymentMethodKind kind,  String brand,  String? last4,  String? expiry)?  $default,) {final _that = this;
switch (_that) {
case _PaymentMethodView() when $default != null:
return $default(_that.kind,_that.brand,_that.last4,_that.expiry);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentMethodView extends PaymentMethodView {
  const _PaymentMethodView({@JsonKey(unknownEnumValue: PaymentMethodKind.unknown) this.kind = PaymentMethodKind.unknown, this.brand = '', this.last4, this.expiry}): super._();
  factory _PaymentMethodView.fromJson(Map<String, dynamic> json) => _$PaymentMethodViewFromJson(json);

@override@JsonKey(unknownEnumValue: PaymentMethodKind.unknown) final  PaymentMethodKind kind;
@override@JsonKey() final  String brand;
@override final  String? last4;
@override final  String? expiry;

/// Create a copy of PaymentMethodView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentMethodViewCopyWith<_PaymentMethodView> get copyWith => __$PaymentMethodViewCopyWithImpl<_PaymentMethodView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentMethodViewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentMethodView&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.expiry, expiry) || other.expiry == expiry));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,brand,last4,expiry);

@override
String toString() {
  return 'PaymentMethodView(kind: $kind, brand: $brand, last4: $last4, expiry: $expiry)';
}


}

/// @nodoc
abstract mixin class _$PaymentMethodViewCopyWith<$Res> implements $PaymentMethodViewCopyWith<$Res> {
  factory _$PaymentMethodViewCopyWith(_PaymentMethodView value, $Res Function(_PaymentMethodView) _then) = __$PaymentMethodViewCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: PaymentMethodKind.unknown) PaymentMethodKind kind, String brand, String? last4, String? expiry
});




}
/// @nodoc
class __$PaymentMethodViewCopyWithImpl<$Res>
    implements _$PaymentMethodViewCopyWith<$Res> {
  __$PaymentMethodViewCopyWithImpl(this._self, this._then);

  final _PaymentMethodView _self;
  final $Res Function(_PaymentMethodView) _then;

/// Create a copy of PaymentMethodView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? brand = null,Object? last4 = freezed,Object? expiry = freezed,}) {
  return _then(_PaymentMethodView(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PaymentMethodKind,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,last4: freezed == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String?,expiry: freezed == expiry ? _self.expiry : expiry // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SubscriptionView {

 String get id; BillingCustomer get customer; String get planId;@JsonKey(unknownEnumValue: SubscriptionStatus.unknown) SubscriptionStatus get status;@JsonKey(unknownEnumValue: BillingCycle.unknown) BillingCycle get cycle;/// Minor units, charged each cycle.
 int get amount; String get currency;@UtcDateTimeConverter() DateTime get startedAt;/// When the period ends: the renewal date, or the last day of a cancelling subscription.
@UtcDateTimeConverter() DateTime get renewsAt;@NullableUtcDateTimeConverter() DateTime? get trialStartedAt;@NullableUtcDateTimeConverter() DateTime? get trialEndsAt;@NullableUtcDateTimeConverter() DateTime? get canceledAt; String? get cancelReason; String? get cancelAt;@NullableUtcDateTimeConverter() DateTime? get pausedAt;@NullableUtcDateTimeConverter() DateTime? get resumesAt; PaymentMethodView get paymentMethod;@NullableUtcDateTimeConverter() DateTime? get lastPaymentAt;@JsonKey(unknownEnumValue: InvoiceStatus.unknown) InvoiceStatus? get lastPaymentStatus;/// Past-due only: what is owed, in minor units, and when the next retry runs.
 int? get amountDue;@NullableUtcDateTimeConverter() DateTime? get nextRetryAt;/// Past-due only: when access closes if nothing is paid.
@NullableUtcDateTimeConverter() DateTime? get graceEndsAt; int? get retriesUsed; String? get notes;
/// Create a copy of SubscriptionView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionViewCopyWith<SubscriptionView> get copyWith => _$SubscriptionViewCopyWithImpl<SubscriptionView>(this as SubscriptionView, _$identity);

  /// Serializes this SubscriptionView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionView&&(identical(other.id, id) || other.id == id)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.status, status) || other.status == status)&&(identical(other.cycle, cycle) || other.cycle == cycle)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.renewsAt, renewsAt) || other.renewsAt == renewsAt)&&(identical(other.trialStartedAt, trialStartedAt) || other.trialStartedAt == trialStartedAt)&&(identical(other.trialEndsAt, trialEndsAt) || other.trialEndsAt == trialEndsAt)&&(identical(other.canceledAt, canceledAt) || other.canceledAt == canceledAt)&&(identical(other.cancelReason, cancelReason) || other.cancelReason == cancelReason)&&(identical(other.cancelAt, cancelAt) || other.cancelAt == cancelAt)&&(identical(other.pausedAt, pausedAt) || other.pausedAt == pausedAt)&&(identical(other.resumesAt, resumesAt) || other.resumesAt == resumesAt)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.lastPaymentAt, lastPaymentAt) || other.lastPaymentAt == lastPaymentAt)&&(identical(other.lastPaymentStatus, lastPaymentStatus) || other.lastPaymentStatus == lastPaymentStatus)&&(identical(other.amountDue, amountDue) || other.amountDue == amountDue)&&(identical(other.nextRetryAt, nextRetryAt) || other.nextRetryAt == nextRetryAt)&&(identical(other.graceEndsAt, graceEndsAt) || other.graceEndsAt == graceEndsAt)&&(identical(other.retriesUsed, retriesUsed) || other.retriesUsed == retriesUsed)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,customer,planId,status,cycle,amount,currency,startedAt,renewsAt,trialStartedAt,trialEndsAt,canceledAt,cancelReason,cancelAt,pausedAt,resumesAt,paymentMethod,lastPaymentAt,lastPaymentStatus,amountDue,nextRetryAt,graceEndsAt,retriesUsed,notes]);

@override
String toString() {
  return 'SubscriptionView(id: $id, customer: $customer, planId: $planId, status: $status, cycle: $cycle, amount: $amount, currency: $currency, startedAt: $startedAt, renewsAt: $renewsAt, trialStartedAt: $trialStartedAt, trialEndsAt: $trialEndsAt, canceledAt: $canceledAt, cancelReason: $cancelReason, cancelAt: $cancelAt, pausedAt: $pausedAt, resumesAt: $resumesAt, paymentMethod: $paymentMethod, lastPaymentAt: $lastPaymentAt, lastPaymentStatus: $lastPaymentStatus, amountDue: $amountDue, nextRetryAt: $nextRetryAt, graceEndsAt: $graceEndsAt, retriesUsed: $retriesUsed, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $SubscriptionViewCopyWith<$Res>  {
  factory $SubscriptionViewCopyWith(SubscriptionView value, $Res Function(SubscriptionView) _then) = _$SubscriptionViewCopyWithImpl;
@useResult
$Res call({
 String id, BillingCustomer customer, String planId,@JsonKey(unknownEnumValue: SubscriptionStatus.unknown) SubscriptionStatus status,@JsonKey(unknownEnumValue: BillingCycle.unknown) BillingCycle cycle, int amount, String currency,@UtcDateTimeConverter() DateTime startedAt,@UtcDateTimeConverter() DateTime renewsAt,@NullableUtcDateTimeConverter() DateTime? trialStartedAt,@NullableUtcDateTimeConverter() DateTime? trialEndsAt,@NullableUtcDateTimeConverter() DateTime? canceledAt, String? cancelReason, String? cancelAt,@NullableUtcDateTimeConverter() DateTime? pausedAt,@NullableUtcDateTimeConverter() DateTime? resumesAt, PaymentMethodView paymentMethod,@NullableUtcDateTimeConverter() DateTime? lastPaymentAt,@JsonKey(unknownEnumValue: InvoiceStatus.unknown) InvoiceStatus? lastPaymentStatus, int? amountDue,@NullableUtcDateTimeConverter() DateTime? nextRetryAt,@NullableUtcDateTimeConverter() DateTime? graceEndsAt, int? retriesUsed, String? notes
});


$BillingCustomerCopyWith<$Res> get customer;$PaymentMethodViewCopyWith<$Res> get paymentMethod;

}
/// @nodoc
class _$SubscriptionViewCopyWithImpl<$Res>
    implements $SubscriptionViewCopyWith<$Res> {
  _$SubscriptionViewCopyWithImpl(this._self, this._then);

  final SubscriptionView _self;
  final $Res Function(SubscriptionView) _then;

/// Create a copy of SubscriptionView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? customer = null,Object? planId = null,Object? status = null,Object? cycle = null,Object? amount = null,Object? currency = null,Object? startedAt = null,Object? renewsAt = null,Object? trialStartedAt = freezed,Object? trialEndsAt = freezed,Object? canceledAt = freezed,Object? cancelReason = freezed,Object? cancelAt = freezed,Object? pausedAt = freezed,Object? resumesAt = freezed,Object? paymentMethod = null,Object? lastPaymentAt = freezed,Object? lastPaymentStatus = freezed,Object? amountDue = freezed,Object? nextRetryAt = freezed,Object? graceEndsAt = freezed,Object? retriesUsed = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as BillingCustomer,planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubscriptionStatus,cycle: null == cycle ? _self.cycle : cycle // ignore: cast_nullable_to_non_nullable
as BillingCycle,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,renewsAt: null == renewsAt ? _self.renewsAt : renewsAt // ignore: cast_nullable_to_non_nullable
as DateTime,trialStartedAt: freezed == trialStartedAt ? _self.trialStartedAt : trialStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,trialEndsAt: freezed == trialEndsAt ? _self.trialEndsAt : trialEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,canceledAt: freezed == canceledAt ? _self.canceledAt : canceledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancelReason: freezed == cancelReason ? _self.cancelReason : cancelReason // ignore: cast_nullable_to_non_nullable
as String?,cancelAt: freezed == cancelAt ? _self.cancelAt : cancelAt // ignore: cast_nullable_to_non_nullable
as String?,pausedAt: freezed == pausedAt ? _self.pausedAt : pausedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resumesAt: freezed == resumesAt ? _self.resumesAt : resumesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PaymentMethodView,lastPaymentAt: freezed == lastPaymentAt ? _self.lastPaymentAt : lastPaymentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastPaymentStatus: freezed == lastPaymentStatus ? _self.lastPaymentStatus : lastPaymentStatus // ignore: cast_nullable_to_non_nullable
as InvoiceStatus?,amountDue: freezed == amountDue ? _self.amountDue : amountDue // ignore: cast_nullable_to_non_nullable
as int?,nextRetryAt: freezed == nextRetryAt ? _self.nextRetryAt : nextRetryAt // ignore: cast_nullable_to_non_nullable
as DateTime?,graceEndsAt: freezed == graceEndsAt ? _self.graceEndsAt : graceEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,retriesUsed: freezed == retriesUsed ? _self.retriesUsed : retriesUsed // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of SubscriptionView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BillingCustomerCopyWith<$Res> get customer {
  
  return $BillingCustomerCopyWith<$Res>(_self.customer, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of SubscriptionView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentMethodViewCopyWith<$Res> get paymentMethod {
  
  return $PaymentMethodViewCopyWith<$Res>(_self.paymentMethod, (value) {
    return _then(_self.copyWith(paymentMethod: value));
  });
}
}


/// Adds pattern-matching-related methods to [SubscriptionView].
extension SubscriptionViewPatterns on SubscriptionView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionView value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionView value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  BillingCustomer customer,  String planId, @JsonKey(unknownEnumValue: SubscriptionStatus.unknown)  SubscriptionStatus status, @JsonKey(unknownEnumValue: BillingCycle.unknown)  BillingCycle cycle,  int amount,  String currency, @UtcDateTimeConverter()  DateTime startedAt, @UtcDateTimeConverter()  DateTime renewsAt, @NullableUtcDateTimeConverter()  DateTime? trialStartedAt, @NullableUtcDateTimeConverter()  DateTime? trialEndsAt, @NullableUtcDateTimeConverter()  DateTime? canceledAt,  String? cancelReason,  String? cancelAt, @NullableUtcDateTimeConverter()  DateTime? pausedAt, @NullableUtcDateTimeConverter()  DateTime? resumesAt,  PaymentMethodView paymentMethod, @NullableUtcDateTimeConverter()  DateTime? lastPaymentAt, @JsonKey(unknownEnumValue: InvoiceStatus.unknown)  InvoiceStatus? lastPaymentStatus,  int? amountDue, @NullableUtcDateTimeConverter()  DateTime? nextRetryAt, @NullableUtcDateTimeConverter()  DateTime? graceEndsAt,  int? retriesUsed,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionView() when $default != null:
return $default(_that.id,_that.customer,_that.planId,_that.status,_that.cycle,_that.amount,_that.currency,_that.startedAt,_that.renewsAt,_that.trialStartedAt,_that.trialEndsAt,_that.canceledAt,_that.cancelReason,_that.cancelAt,_that.pausedAt,_that.resumesAt,_that.paymentMethod,_that.lastPaymentAt,_that.lastPaymentStatus,_that.amountDue,_that.nextRetryAt,_that.graceEndsAt,_that.retriesUsed,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  BillingCustomer customer,  String planId, @JsonKey(unknownEnumValue: SubscriptionStatus.unknown)  SubscriptionStatus status, @JsonKey(unknownEnumValue: BillingCycle.unknown)  BillingCycle cycle,  int amount,  String currency, @UtcDateTimeConverter()  DateTime startedAt, @UtcDateTimeConverter()  DateTime renewsAt, @NullableUtcDateTimeConverter()  DateTime? trialStartedAt, @NullableUtcDateTimeConverter()  DateTime? trialEndsAt, @NullableUtcDateTimeConverter()  DateTime? canceledAt,  String? cancelReason,  String? cancelAt, @NullableUtcDateTimeConverter()  DateTime? pausedAt, @NullableUtcDateTimeConverter()  DateTime? resumesAt,  PaymentMethodView paymentMethod, @NullableUtcDateTimeConverter()  DateTime? lastPaymentAt, @JsonKey(unknownEnumValue: InvoiceStatus.unknown)  InvoiceStatus? lastPaymentStatus,  int? amountDue, @NullableUtcDateTimeConverter()  DateTime? nextRetryAt, @NullableUtcDateTimeConverter()  DateTime? graceEndsAt,  int? retriesUsed,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionView():
return $default(_that.id,_that.customer,_that.planId,_that.status,_that.cycle,_that.amount,_that.currency,_that.startedAt,_that.renewsAt,_that.trialStartedAt,_that.trialEndsAt,_that.canceledAt,_that.cancelReason,_that.cancelAt,_that.pausedAt,_that.resumesAt,_that.paymentMethod,_that.lastPaymentAt,_that.lastPaymentStatus,_that.amountDue,_that.nextRetryAt,_that.graceEndsAt,_that.retriesUsed,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  BillingCustomer customer,  String planId, @JsonKey(unknownEnumValue: SubscriptionStatus.unknown)  SubscriptionStatus status, @JsonKey(unknownEnumValue: BillingCycle.unknown)  BillingCycle cycle,  int amount,  String currency, @UtcDateTimeConverter()  DateTime startedAt, @UtcDateTimeConverter()  DateTime renewsAt, @NullableUtcDateTimeConverter()  DateTime? trialStartedAt, @NullableUtcDateTimeConverter()  DateTime? trialEndsAt, @NullableUtcDateTimeConverter()  DateTime? canceledAt,  String? cancelReason,  String? cancelAt, @NullableUtcDateTimeConverter()  DateTime? pausedAt, @NullableUtcDateTimeConverter()  DateTime? resumesAt,  PaymentMethodView paymentMethod, @NullableUtcDateTimeConverter()  DateTime? lastPaymentAt, @JsonKey(unknownEnumValue: InvoiceStatus.unknown)  InvoiceStatus? lastPaymentStatus,  int? amountDue, @NullableUtcDateTimeConverter()  DateTime? nextRetryAt, @NullableUtcDateTimeConverter()  DateTime? graceEndsAt,  int? retriesUsed,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionView() when $default != null:
return $default(_that.id,_that.customer,_that.planId,_that.status,_that.cycle,_that.amount,_that.currency,_that.startedAt,_that.renewsAt,_that.trialStartedAt,_that.trialEndsAt,_that.canceledAt,_that.cancelReason,_that.cancelAt,_that.pausedAt,_that.resumesAt,_that.paymentMethod,_that.lastPaymentAt,_that.lastPaymentStatus,_that.amountDue,_that.nextRetryAt,_that.graceEndsAt,_that.retriesUsed,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubscriptionView extends SubscriptionView {
  const _SubscriptionView({this.id = '', this.customer = const BillingCustomer(), this.planId = '', @JsonKey(unknownEnumValue: SubscriptionStatus.unknown) this.status = SubscriptionStatus.unknown, @JsonKey(unknownEnumValue: BillingCycle.unknown) this.cycle = BillingCycle.unknown, this.amount = 0, this.currency = 'INR', @UtcDateTimeConverter() required this.startedAt, @UtcDateTimeConverter() required this.renewsAt, @NullableUtcDateTimeConverter() this.trialStartedAt, @NullableUtcDateTimeConverter() this.trialEndsAt, @NullableUtcDateTimeConverter() this.canceledAt, this.cancelReason, this.cancelAt, @NullableUtcDateTimeConverter() this.pausedAt, @NullableUtcDateTimeConverter() this.resumesAt, this.paymentMethod = const PaymentMethodView(), @NullableUtcDateTimeConverter() this.lastPaymentAt, @JsonKey(unknownEnumValue: InvoiceStatus.unknown) this.lastPaymentStatus, this.amountDue, @NullableUtcDateTimeConverter() this.nextRetryAt, @NullableUtcDateTimeConverter() this.graceEndsAt, this.retriesUsed, this.notes}): super._();
  factory _SubscriptionView.fromJson(Map<String, dynamic> json) => _$SubscriptionViewFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  BillingCustomer customer;
@override@JsonKey() final  String planId;
@override@JsonKey(unknownEnumValue: SubscriptionStatus.unknown) final  SubscriptionStatus status;
@override@JsonKey(unknownEnumValue: BillingCycle.unknown) final  BillingCycle cycle;
/// Minor units, charged each cycle.
@override@JsonKey() final  int amount;
@override@JsonKey() final  String currency;
@override@UtcDateTimeConverter() final  DateTime startedAt;
/// When the period ends: the renewal date, or the last day of a cancelling subscription.
@override@UtcDateTimeConverter() final  DateTime renewsAt;
@override@NullableUtcDateTimeConverter() final  DateTime? trialStartedAt;
@override@NullableUtcDateTimeConverter() final  DateTime? trialEndsAt;
@override@NullableUtcDateTimeConverter() final  DateTime? canceledAt;
@override final  String? cancelReason;
@override final  String? cancelAt;
@override@NullableUtcDateTimeConverter() final  DateTime? pausedAt;
@override@NullableUtcDateTimeConverter() final  DateTime? resumesAt;
@override@JsonKey() final  PaymentMethodView paymentMethod;
@override@NullableUtcDateTimeConverter() final  DateTime? lastPaymentAt;
@override@JsonKey(unknownEnumValue: InvoiceStatus.unknown) final  InvoiceStatus? lastPaymentStatus;
/// Past-due only: what is owed, in minor units, and when the next retry runs.
@override final  int? amountDue;
@override@NullableUtcDateTimeConverter() final  DateTime? nextRetryAt;
/// Past-due only: when access closes if nothing is paid.
@override@NullableUtcDateTimeConverter() final  DateTime? graceEndsAt;
@override final  int? retriesUsed;
@override final  String? notes;

/// Create a copy of SubscriptionView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionViewCopyWith<_SubscriptionView> get copyWith => __$SubscriptionViewCopyWithImpl<_SubscriptionView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionViewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionView&&(identical(other.id, id) || other.id == id)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.status, status) || other.status == status)&&(identical(other.cycle, cycle) || other.cycle == cycle)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.renewsAt, renewsAt) || other.renewsAt == renewsAt)&&(identical(other.trialStartedAt, trialStartedAt) || other.trialStartedAt == trialStartedAt)&&(identical(other.trialEndsAt, trialEndsAt) || other.trialEndsAt == trialEndsAt)&&(identical(other.canceledAt, canceledAt) || other.canceledAt == canceledAt)&&(identical(other.cancelReason, cancelReason) || other.cancelReason == cancelReason)&&(identical(other.cancelAt, cancelAt) || other.cancelAt == cancelAt)&&(identical(other.pausedAt, pausedAt) || other.pausedAt == pausedAt)&&(identical(other.resumesAt, resumesAt) || other.resumesAt == resumesAt)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.lastPaymentAt, lastPaymentAt) || other.lastPaymentAt == lastPaymentAt)&&(identical(other.lastPaymentStatus, lastPaymentStatus) || other.lastPaymentStatus == lastPaymentStatus)&&(identical(other.amountDue, amountDue) || other.amountDue == amountDue)&&(identical(other.nextRetryAt, nextRetryAt) || other.nextRetryAt == nextRetryAt)&&(identical(other.graceEndsAt, graceEndsAt) || other.graceEndsAt == graceEndsAt)&&(identical(other.retriesUsed, retriesUsed) || other.retriesUsed == retriesUsed)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,customer,planId,status,cycle,amount,currency,startedAt,renewsAt,trialStartedAt,trialEndsAt,canceledAt,cancelReason,cancelAt,pausedAt,resumesAt,paymentMethod,lastPaymentAt,lastPaymentStatus,amountDue,nextRetryAt,graceEndsAt,retriesUsed,notes]);

@override
String toString() {
  return 'SubscriptionView(id: $id, customer: $customer, planId: $planId, status: $status, cycle: $cycle, amount: $amount, currency: $currency, startedAt: $startedAt, renewsAt: $renewsAt, trialStartedAt: $trialStartedAt, trialEndsAt: $trialEndsAt, canceledAt: $canceledAt, cancelReason: $cancelReason, cancelAt: $cancelAt, pausedAt: $pausedAt, resumesAt: $resumesAt, paymentMethod: $paymentMethod, lastPaymentAt: $lastPaymentAt, lastPaymentStatus: $lastPaymentStatus, amountDue: $amountDue, nextRetryAt: $nextRetryAt, graceEndsAt: $graceEndsAt, retriesUsed: $retriesUsed, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionViewCopyWith<$Res> implements $SubscriptionViewCopyWith<$Res> {
  factory _$SubscriptionViewCopyWith(_SubscriptionView value, $Res Function(_SubscriptionView) _then) = __$SubscriptionViewCopyWithImpl;
@override @useResult
$Res call({
 String id, BillingCustomer customer, String planId,@JsonKey(unknownEnumValue: SubscriptionStatus.unknown) SubscriptionStatus status,@JsonKey(unknownEnumValue: BillingCycle.unknown) BillingCycle cycle, int amount, String currency,@UtcDateTimeConverter() DateTime startedAt,@UtcDateTimeConverter() DateTime renewsAt,@NullableUtcDateTimeConverter() DateTime? trialStartedAt,@NullableUtcDateTimeConverter() DateTime? trialEndsAt,@NullableUtcDateTimeConverter() DateTime? canceledAt, String? cancelReason, String? cancelAt,@NullableUtcDateTimeConverter() DateTime? pausedAt,@NullableUtcDateTimeConverter() DateTime? resumesAt, PaymentMethodView paymentMethod,@NullableUtcDateTimeConverter() DateTime? lastPaymentAt,@JsonKey(unknownEnumValue: InvoiceStatus.unknown) InvoiceStatus? lastPaymentStatus, int? amountDue,@NullableUtcDateTimeConverter() DateTime? nextRetryAt,@NullableUtcDateTimeConverter() DateTime? graceEndsAt, int? retriesUsed, String? notes
});


@override $BillingCustomerCopyWith<$Res> get customer;@override $PaymentMethodViewCopyWith<$Res> get paymentMethod;

}
/// @nodoc
class __$SubscriptionViewCopyWithImpl<$Res>
    implements _$SubscriptionViewCopyWith<$Res> {
  __$SubscriptionViewCopyWithImpl(this._self, this._then);

  final _SubscriptionView _self;
  final $Res Function(_SubscriptionView) _then;

/// Create a copy of SubscriptionView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? customer = null,Object? planId = null,Object? status = null,Object? cycle = null,Object? amount = null,Object? currency = null,Object? startedAt = null,Object? renewsAt = null,Object? trialStartedAt = freezed,Object? trialEndsAt = freezed,Object? canceledAt = freezed,Object? cancelReason = freezed,Object? cancelAt = freezed,Object? pausedAt = freezed,Object? resumesAt = freezed,Object? paymentMethod = null,Object? lastPaymentAt = freezed,Object? lastPaymentStatus = freezed,Object? amountDue = freezed,Object? nextRetryAt = freezed,Object? graceEndsAt = freezed,Object? retriesUsed = freezed,Object? notes = freezed,}) {
  return _then(_SubscriptionView(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as BillingCustomer,planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubscriptionStatus,cycle: null == cycle ? _self.cycle : cycle // ignore: cast_nullable_to_non_nullable
as BillingCycle,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,renewsAt: null == renewsAt ? _self.renewsAt : renewsAt // ignore: cast_nullable_to_non_nullable
as DateTime,trialStartedAt: freezed == trialStartedAt ? _self.trialStartedAt : trialStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,trialEndsAt: freezed == trialEndsAt ? _self.trialEndsAt : trialEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,canceledAt: freezed == canceledAt ? _self.canceledAt : canceledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancelReason: freezed == cancelReason ? _self.cancelReason : cancelReason // ignore: cast_nullable_to_non_nullable
as String?,cancelAt: freezed == cancelAt ? _self.cancelAt : cancelAt // ignore: cast_nullable_to_non_nullable
as String?,pausedAt: freezed == pausedAt ? _self.pausedAt : pausedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resumesAt: freezed == resumesAt ? _self.resumesAt : resumesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PaymentMethodView,lastPaymentAt: freezed == lastPaymentAt ? _self.lastPaymentAt : lastPaymentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastPaymentStatus: freezed == lastPaymentStatus ? _self.lastPaymentStatus : lastPaymentStatus // ignore: cast_nullable_to_non_nullable
as InvoiceStatus?,amountDue: freezed == amountDue ? _self.amountDue : amountDue // ignore: cast_nullable_to_non_nullable
as int?,nextRetryAt: freezed == nextRetryAt ? _self.nextRetryAt : nextRetryAt // ignore: cast_nullable_to_non_nullable
as DateTime?,graceEndsAt: freezed == graceEndsAt ? _self.graceEndsAt : graceEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,retriesUsed: freezed == retriesUsed ? _self.retriesUsed : retriesUsed // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of SubscriptionView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BillingCustomerCopyWith<$Res> get customer {
  
  return $BillingCustomerCopyWith<$Res>(_self.customer, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of SubscriptionView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentMethodViewCopyWith<$Res> get paymentMethod {
  
  return $PaymentMethodViewCopyWith<$Res>(_self.paymentMethod, (value) {
    return _then(_self.copyWith(paymentMethod: value));
  });
}
}


/// @nodoc
mixin _$PlanView {

 String get id; String get name; String get description; String get code;/// Minor units.
 int get monthlyPrice; int get annualPrice; String get currency; List<String> get cycles; bool get trialEnabled; int get trialDays;/// `null` for a limit with no ceiling.
 Map<String, int?> get limits; List<String> get features; String get status; int get order;
/// Create a copy of PlanView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanViewCopyWith<PlanView> get copyWith => _$PlanViewCopyWithImpl<PlanView>(this as PlanView, _$identity);

  /// Serializes this PlanView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanView&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.code, code) || other.code == code)&&(identical(other.monthlyPrice, monthlyPrice) || other.monthlyPrice == monthlyPrice)&&(identical(other.annualPrice, annualPrice) || other.annualPrice == annualPrice)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other.cycles, cycles)&&(identical(other.trialEnabled, trialEnabled) || other.trialEnabled == trialEnabled)&&(identical(other.trialDays, trialDays) || other.trialDays == trialDays)&&const DeepCollectionEquality().equals(other.limits, limits)&&const DeepCollectionEquality().equals(other.features, features)&&(identical(other.status, status) || other.status == status)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,code,monthlyPrice,annualPrice,currency,const DeepCollectionEquality().hash(cycles),trialEnabled,trialDays,const DeepCollectionEquality().hash(limits),const DeepCollectionEquality().hash(features),status,order);

@override
String toString() {
  return 'PlanView(id: $id, name: $name, description: $description, code: $code, monthlyPrice: $monthlyPrice, annualPrice: $annualPrice, currency: $currency, cycles: $cycles, trialEnabled: $trialEnabled, trialDays: $trialDays, limits: $limits, features: $features, status: $status, order: $order)';
}


}

/// @nodoc
abstract mixin class $PlanViewCopyWith<$Res>  {
  factory $PlanViewCopyWith(PlanView value, $Res Function(PlanView) _then) = _$PlanViewCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, String code, int monthlyPrice, int annualPrice, String currency, List<String> cycles, bool trialEnabled, int trialDays, Map<String, int?> limits, List<String> features, String status, int order
});




}
/// @nodoc
class _$PlanViewCopyWithImpl<$Res>
    implements $PlanViewCopyWith<$Res> {
  _$PlanViewCopyWithImpl(this._self, this._then);

  final PlanView _self;
  final $Res Function(PlanView) _then;

/// Create a copy of PlanView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? code = null,Object? monthlyPrice = null,Object? annualPrice = null,Object? currency = null,Object? cycles = null,Object? trialEnabled = null,Object? trialDays = null,Object? limits = null,Object? features = null,Object? status = null,Object? order = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,monthlyPrice: null == monthlyPrice ? _self.monthlyPrice : monthlyPrice // ignore: cast_nullable_to_non_nullable
as int,annualPrice: null == annualPrice ? _self.annualPrice : annualPrice // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,cycles: null == cycles ? _self.cycles : cycles // ignore: cast_nullable_to_non_nullable
as List<String>,trialEnabled: null == trialEnabled ? _self.trialEnabled : trialEnabled // ignore: cast_nullable_to_non_nullable
as bool,trialDays: null == trialDays ? _self.trialDays : trialDays // ignore: cast_nullable_to_non_nullable
as int,limits: null == limits ? _self.limits : limits // ignore: cast_nullable_to_non_nullable
as Map<String, int?>,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanView].
extension PlanViewPatterns on PlanView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanView value)  $default,){
final _that = this;
switch (_that) {
case _PlanView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanView value)?  $default,){
final _that = this;
switch (_that) {
case _PlanView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  String code,  int monthlyPrice,  int annualPrice,  String currency,  List<String> cycles,  bool trialEnabled,  int trialDays,  Map<String, int?> limits,  List<String> features,  String status,  int order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanView() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.code,_that.monthlyPrice,_that.annualPrice,_that.currency,_that.cycles,_that.trialEnabled,_that.trialDays,_that.limits,_that.features,_that.status,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  String code,  int monthlyPrice,  int annualPrice,  String currency,  List<String> cycles,  bool trialEnabled,  int trialDays,  Map<String, int?> limits,  List<String> features,  String status,  int order)  $default,) {final _that = this;
switch (_that) {
case _PlanView():
return $default(_that.id,_that.name,_that.description,_that.code,_that.monthlyPrice,_that.annualPrice,_that.currency,_that.cycles,_that.trialEnabled,_that.trialDays,_that.limits,_that.features,_that.status,_that.order);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  String code,  int monthlyPrice,  int annualPrice,  String currency,  List<String> cycles,  bool trialEnabled,  int trialDays,  Map<String, int?> limits,  List<String> features,  String status,  int order)?  $default,) {final _that = this;
switch (_that) {
case _PlanView() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.code,_that.monthlyPrice,_that.annualPrice,_that.currency,_that.cycles,_that.trialEnabled,_that.trialDays,_that.limits,_that.features,_that.status,_that.order);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanView extends PlanView {
  const _PlanView({this.id = '', this.name = '', this.description = '', this.code = '', this.monthlyPrice = 0, this.annualPrice = 0, this.currency = 'INR', final  List<String> cycles = const <String>[], this.trialEnabled = false, this.trialDays = 0, final  Map<String, int?> limits = const <String, int?>{}, final  List<String> features = const <String>[], this.status = '', this.order = 0}): _cycles = cycles,_limits = limits,_features = features,super._();
  factory _PlanView.fromJson(Map<String, dynamic> json) => _$PlanViewFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String description;
@override@JsonKey() final  String code;
/// Minor units.
@override@JsonKey() final  int monthlyPrice;
@override@JsonKey() final  int annualPrice;
@override@JsonKey() final  String currency;
 final  List<String> _cycles;
@override@JsonKey() List<String> get cycles {
  if (_cycles is EqualUnmodifiableListView) return _cycles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cycles);
}

@override@JsonKey() final  bool trialEnabled;
@override@JsonKey() final  int trialDays;
/// `null` for a limit with no ceiling.
 final  Map<String, int?> _limits;
/// `null` for a limit with no ceiling.
@override@JsonKey() Map<String, int?> get limits {
  if (_limits is EqualUnmodifiableMapView) return _limits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_limits);
}

 final  List<String> _features;
@override@JsonKey() List<String> get features {
  if (_features is EqualUnmodifiableListView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_features);
}

@override@JsonKey() final  String status;
@override@JsonKey() final  int order;

/// Create a copy of PlanView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanViewCopyWith<_PlanView> get copyWith => __$PlanViewCopyWithImpl<_PlanView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanViewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanView&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.code, code) || other.code == code)&&(identical(other.monthlyPrice, monthlyPrice) || other.monthlyPrice == monthlyPrice)&&(identical(other.annualPrice, annualPrice) || other.annualPrice == annualPrice)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other._cycles, _cycles)&&(identical(other.trialEnabled, trialEnabled) || other.trialEnabled == trialEnabled)&&(identical(other.trialDays, trialDays) || other.trialDays == trialDays)&&const DeepCollectionEquality().equals(other._limits, _limits)&&const DeepCollectionEquality().equals(other._features, _features)&&(identical(other.status, status) || other.status == status)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,code,monthlyPrice,annualPrice,currency,const DeepCollectionEquality().hash(_cycles),trialEnabled,trialDays,const DeepCollectionEquality().hash(_limits),const DeepCollectionEquality().hash(_features),status,order);

@override
String toString() {
  return 'PlanView(id: $id, name: $name, description: $description, code: $code, monthlyPrice: $monthlyPrice, annualPrice: $annualPrice, currency: $currency, cycles: $cycles, trialEnabled: $trialEnabled, trialDays: $trialDays, limits: $limits, features: $features, status: $status, order: $order)';
}


}

/// @nodoc
abstract mixin class _$PlanViewCopyWith<$Res> implements $PlanViewCopyWith<$Res> {
  factory _$PlanViewCopyWith(_PlanView value, $Res Function(_PlanView) _then) = __$PlanViewCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, String code, int monthlyPrice, int annualPrice, String currency, List<String> cycles, bool trialEnabled, int trialDays, Map<String, int?> limits, List<String> features, String status, int order
});




}
/// @nodoc
class __$PlanViewCopyWithImpl<$Res>
    implements _$PlanViewCopyWith<$Res> {
  __$PlanViewCopyWithImpl(this._self, this._then);

  final _PlanView _self;
  final $Res Function(_PlanView) _then;

/// Create a copy of PlanView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? code = null,Object? monthlyPrice = null,Object? annualPrice = null,Object? currency = null,Object? cycles = null,Object? trialEnabled = null,Object? trialDays = null,Object? limits = null,Object? features = null,Object? status = null,Object? order = null,}) {
  return _then(_PlanView(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,monthlyPrice: null == monthlyPrice ? _self.monthlyPrice : monthlyPrice // ignore: cast_nullable_to_non_nullable
as int,annualPrice: null == annualPrice ? _self.annualPrice : annualPrice // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,cycles: null == cycles ? _self._cycles : cycles // ignore: cast_nullable_to_non_nullable
as List<String>,trialEnabled: null == trialEnabled ? _self.trialEnabled : trialEnabled // ignore: cast_nullable_to_non_nullable
as bool,trialDays: null == trialDays ? _self.trialDays : trialDays // ignore: cast_nullable_to_non_nullable
as int,limits: null == limits ? _self._limits : limits // ignore: cast_nullable_to_non_nullable
as Map<String, int?>,features: null == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$UsageLine {

 String get limit; String get label; int get used; int? get allowed; int? get remaining;
/// Create a copy of UsageLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UsageLineCopyWith<UsageLine> get copyWith => _$UsageLineCopyWithImpl<UsageLine>(this as UsageLine, _$identity);

  /// Serializes this UsageLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsageLine&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.label, label) || other.label == label)&&(identical(other.used, used) || other.used == used)&&(identical(other.allowed, allowed) || other.allowed == allowed)&&(identical(other.remaining, remaining) || other.remaining == remaining));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,limit,label,used,allowed,remaining);

@override
String toString() {
  return 'UsageLine(limit: $limit, label: $label, used: $used, allowed: $allowed, remaining: $remaining)';
}


}

/// @nodoc
abstract mixin class $UsageLineCopyWith<$Res>  {
  factory $UsageLineCopyWith(UsageLine value, $Res Function(UsageLine) _then) = _$UsageLineCopyWithImpl;
@useResult
$Res call({
 String limit, String label, int used, int? allowed, int? remaining
});




}
/// @nodoc
class _$UsageLineCopyWithImpl<$Res>
    implements $UsageLineCopyWith<$Res> {
  _$UsageLineCopyWithImpl(this._self, this._then);

  final UsageLine _self;
  final $Res Function(UsageLine) _then;

/// Create a copy of UsageLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? limit = null,Object? label = null,Object? used = null,Object? allowed = freezed,Object? remaining = freezed,}) {
  return _then(_self.copyWith(
limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,used: null == used ? _self.used : used // ignore: cast_nullable_to_non_nullable
as int,allowed: freezed == allowed ? _self.allowed : allowed // ignore: cast_nullable_to_non_nullable
as int?,remaining: freezed == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [UsageLine].
extension UsageLinePatterns on UsageLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UsageLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UsageLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UsageLine value)  $default,){
final _that = this;
switch (_that) {
case _UsageLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UsageLine value)?  $default,){
final _that = this;
switch (_that) {
case _UsageLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String limit,  String label,  int used,  int? allowed,  int? remaining)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UsageLine() when $default != null:
return $default(_that.limit,_that.label,_that.used,_that.allowed,_that.remaining);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String limit,  String label,  int used,  int? allowed,  int? remaining)  $default,) {final _that = this;
switch (_that) {
case _UsageLine():
return $default(_that.limit,_that.label,_that.used,_that.allowed,_that.remaining);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String limit,  String label,  int used,  int? allowed,  int? remaining)?  $default,) {final _that = this;
switch (_that) {
case _UsageLine() when $default != null:
return $default(_that.limit,_that.label,_that.used,_that.allowed,_that.remaining);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UsageLine extends UsageLine {
  const _UsageLine({this.limit = '', this.label = '', this.used = 0, this.allowed, this.remaining}): super._();
  factory _UsageLine.fromJson(Map<String, dynamic> json) => _$UsageLineFromJson(json);

@override@JsonKey() final  String limit;
@override@JsonKey() final  String label;
@override@JsonKey() final  int used;
@override final  int? allowed;
@override final  int? remaining;

/// Create a copy of UsageLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UsageLineCopyWith<_UsageLine> get copyWith => __$UsageLineCopyWithImpl<_UsageLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UsageLineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UsageLine&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.label, label) || other.label == label)&&(identical(other.used, used) || other.used == used)&&(identical(other.allowed, allowed) || other.allowed == allowed)&&(identical(other.remaining, remaining) || other.remaining == remaining));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,limit,label,used,allowed,remaining);

@override
String toString() {
  return 'UsageLine(limit: $limit, label: $label, used: $used, allowed: $allowed, remaining: $remaining)';
}


}

/// @nodoc
abstract mixin class _$UsageLineCopyWith<$Res> implements $UsageLineCopyWith<$Res> {
  factory _$UsageLineCopyWith(_UsageLine value, $Res Function(_UsageLine) _then) = __$UsageLineCopyWithImpl;
@override @useResult
$Res call({
 String limit, String label, int used, int? allowed, int? remaining
});




}
/// @nodoc
class __$UsageLineCopyWithImpl<$Res>
    implements _$UsageLineCopyWith<$Res> {
  __$UsageLineCopyWithImpl(this._self, this._then);

  final _UsageLine _self;
  final $Res Function(_UsageLine) _then;

/// Create a copy of UsageLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? limit = null,Object? label = null,Object? used = null,Object? allowed = freezed,Object? remaining = freezed,}) {
  return _then(_UsageLine(
limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,used: null == used ? _self.used : used // ignore: cast_nullable_to_non_nullable
as int,allowed: freezed == allowed ? _self.allowed : allowed // ignore: cast_nullable_to_non_nullable
as int?,remaining: freezed == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$FeatureLine {

 String get key; String get label; bool get included;@JsonKey(unknownEnumValue: FeatureEnforcement.unknown) FeatureEnforcement get enforcement;
/// Create a copy of FeatureLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeatureLineCopyWith<FeatureLine> get copyWith => _$FeatureLineCopyWithImpl<FeatureLine>(this as FeatureLine, _$identity);

  /// Serializes this FeatureLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeatureLine&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.included, included) || other.included == included)&&(identical(other.enforcement, enforcement) || other.enforcement == enforcement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,label,included,enforcement);

@override
String toString() {
  return 'FeatureLine(key: $key, label: $label, included: $included, enforcement: $enforcement)';
}


}

/// @nodoc
abstract mixin class $FeatureLineCopyWith<$Res>  {
  factory $FeatureLineCopyWith(FeatureLine value, $Res Function(FeatureLine) _then) = _$FeatureLineCopyWithImpl;
@useResult
$Res call({
 String key, String label, bool included,@JsonKey(unknownEnumValue: FeatureEnforcement.unknown) FeatureEnforcement enforcement
});




}
/// @nodoc
class _$FeatureLineCopyWithImpl<$Res>
    implements $FeatureLineCopyWith<$Res> {
  _$FeatureLineCopyWithImpl(this._self, this._then);

  final FeatureLine _self;
  final $Res Function(FeatureLine) _then;

/// Create a copy of FeatureLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? label = null,Object? included = null,Object? enforcement = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,included: null == included ? _self.included : included // ignore: cast_nullable_to_non_nullable
as bool,enforcement: null == enforcement ? _self.enforcement : enforcement // ignore: cast_nullable_to_non_nullable
as FeatureEnforcement,
  ));
}

}


/// Adds pattern-matching-related methods to [FeatureLine].
extension FeatureLinePatterns on FeatureLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeatureLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeatureLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeatureLine value)  $default,){
final _that = this;
switch (_that) {
case _FeatureLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeatureLine value)?  $default,){
final _that = this;
switch (_that) {
case _FeatureLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String label,  bool included, @JsonKey(unknownEnumValue: FeatureEnforcement.unknown)  FeatureEnforcement enforcement)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeatureLine() when $default != null:
return $default(_that.key,_that.label,_that.included,_that.enforcement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String label,  bool included, @JsonKey(unknownEnumValue: FeatureEnforcement.unknown)  FeatureEnforcement enforcement)  $default,) {final _that = this;
switch (_that) {
case _FeatureLine():
return $default(_that.key,_that.label,_that.included,_that.enforcement);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String label,  bool included, @JsonKey(unknownEnumValue: FeatureEnforcement.unknown)  FeatureEnforcement enforcement)?  $default,) {final _that = this;
switch (_that) {
case _FeatureLine() when $default != null:
return $default(_that.key,_that.label,_that.included,_that.enforcement);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FeatureLine extends FeatureLine {
  const _FeatureLine({this.key = '', this.label = '', this.included = false, @JsonKey(unknownEnumValue: FeatureEnforcement.unknown) this.enforcement = FeatureEnforcement.unknown}): super._();
  factory _FeatureLine.fromJson(Map<String, dynamic> json) => _$FeatureLineFromJson(json);

@override@JsonKey() final  String key;
@override@JsonKey() final  String label;
@override@JsonKey() final  bool included;
@override@JsonKey(unknownEnumValue: FeatureEnforcement.unknown) final  FeatureEnforcement enforcement;

/// Create a copy of FeatureLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeatureLineCopyWith<_FeatureLine> get copyWith => __$FeatureLineCopyWithImpl<_FeatureLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FeatureLineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeatureLine&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.included, included) || other.included == included)&&(identical(other.enforcement, enforcement) || other.enforcement == enforcement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,label,included,enforcement);

@override
String toString() {
  return 'FeatureLine(key: $key, label: $label, included: $included, enforcement: $enforcement)';
}


}

/// @nodoc
abstract mixin class _$FeatureLineCopyWith<$Res> implements $FeatureLineCopyWith<$Res> {
  factory _$FeatureLineCopyWith(_FeatureLine value, $Res Function(_FeatureLine) _then) = __$FeatureLineCopyWithImpl;
@override @useResult
$Res call({
 String key, String label, bool included,@JsonKey(unknownEnumValue: FeatureEnforcement.unknown) FeatureEnforcement enforcement
});




}
/// @nodoc
class __$FeatureLineCopyWithImpl<$Res>
    implements _$FeatureLineCopyWith<$Res> {
  __$FeatureLineCopyWithImpl(this._self, this._then);

  final _FeatureLine _self;
  final $Res Function(_FeatureLine) _then;

/// Create a copy of FeatureLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? label = null,Object? included = null,Object? enforcement = null,}) {
  return _then(_FeatureLine(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,included: null == included ? _self.included : included // ignore: cast_nullable_to_non_nullable
as bool,enforcement: null == enforcement ? _self.enforcement : enforcement // ignore: cast_nullable_to_non_nullable
as FeatureEnforcement,
  ));
}


}


/// @nodoc
mixin _$OpenPlanChange {

 String get id; String get direction; String get status; String get toPlanId; String get toPlanName;@JsonKey(unknownEnumValue: BillingCycle.unknown) BillingCycle get toCycle;/// Minor units: the unused value credited, and what is charged now. Both 0 for a downgrade.
 int get credit; int get charge; String get currency;@NullableUtcDateTimeConverter() DateTime? get effectiveAt;@UtcDateTimeConverter() DateTime get quotedAt;
/// Create a copy of OpenPlanChange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenPlanChangeCopyWith<OpenPlanChange> get copyWith => _$OpenPlanChangeCopyWithImpl<OpenPlanChange>(this as OpenPlanChange, _$identity);

  /// Serializes this OpenPlanChange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenPlanChange&&(identical(other.id, id) || other.id == id)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.status, status) || other.status == status)&&(identical(other.toPlanId, toPlanId) || other.toPlanId == toPlanId)&&(identical(other.toPlanName, toPlanName) || other.toPlanName == toPlanName)&&(identical(other.toCycle, toCycle) || other.toCycle == toCycle)&&(identical(other.credit, credit) || other.credit == credit)&&(identical(other.charge, charge) || other.charge == charge)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.effectiveAt, effectiveAt) || other.effectiveAt == effectiveAt)&&(identical(other.quotedAt, quotedAt) || other.quotedAt == quotedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,direction,status,toPlanId,toPlanName,toCycle,credit,charge,currency,effectiveAt,quotedAt);

@override
String toString() {
  return 'OpenPlanChange(id: $id, direction: $direction, status: $status, toPlanId: $toPlanId, toPlanName: $toPlanName, toCycle: $toCycle, credit: $credit, charge: $charge, currency: $currency, effectiveAt: $effectiveAt, quotedAt: $quotedAt)';
}


}

/// @nodoc
abstract mixin class $OpenPlanChangeCopyWith<$Res>  {
  factory $OpenPlanChangeCopyWith(OpenPlanChange value, $Res Function(OpenPlanChange) _then) = _$OpenPlanChangeCopyWithImpl;
@useResult
$Res call({
 String id, String direction, String status, String toPlanId, String toPlanName,@JsonKey(unknownEnumValue: BillingCycle.unknown) BillingCycle toCycle, int credit, int charge, String currency,@NullableUtcDateTimeConverter() DateTime? effectiveAt,@UtcDateTimeConverter() DateTime quotedAt
});




}
/// @nodoc
class _$OpenPlanChangeCopyWithImpl<$Res>
    implements $OpenPlanChangeCopyWith<$Res> {
  _$OpenPlanChangeCopyWithImpl(this._self, this._then);

  final OpenPlanChange _self;
  final $Res Function(OpenPlanChange) _then;

/// Create a copy of OpenPlanChange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? direction = null,Object? status = null,Object? toPlanId = null,Object? toPlanName = null,Object? toCycle = null,Object? credit = null,Object? charge = null,Object? currency = null,Object? effectiveAt = freezed,Object? quotedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,toPlanId: null == toPlanId ? _self.toPlanId : toPlanId // ignore: cast_nullable_to_non_nullable
as String,toPlanName: null == toPlanName ? _self.toPlanName : toPlanName // ignore: cast_nullable_to_non_nullable
as String,toCycle: null == toCycle ? _self.toCycle : toCycle // ignore: cast_nullable_to_non_nullable
as BillingCycle,credit: null == credit ? _self.credit : credit // ignore: cast_nullable_to_non_nullable
as int,charge: null == charge ? _self.charge : charge // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,effectiveAt: freezed == effectiveAt ? _self.effectiveAt : effectiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,quotedAt: null == quotedAt ? _self.quotedAt : quotedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenPlanChange].
extension OpenPlanChangePatterns on OpenPlanChange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenPlanChange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenPlanChange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenPlanChange value)  $default,){
final _that = this;
switch (_that) {
case _OpenPlanChange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenPlanChange value)?  $default,){
final _that = this;
switch (_that) {
case _OpenPlanChange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String direction,  String status,  String toPlanId,  String toPlanName, @JsonKey(unknownEnumValue: BillingCycle.unknown)  BillingCycle toCycle,  int credit,  int charge,  String currency, @NullableUtcDateTimeConverter()  DateTime? effectiveAt, @UtcDateTimeConverter()  DateTime quotedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenPlanChange() when $default != null:
return $default(_that.id,_that.direction,_that.status,_that.toPlanId,_that.toPlanName,_that.toCycle,_that.credit,_that.charge,_that.currency,_that.effectiveAt,_that.quotedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String direction,  String status,  String toPlanId,  String toPlanName, @JsonKey(unknownEnumValue: BillingCycle.unknown)  BillingCycle toCycle,  int credit,  int charge,  String currency, @NullableUtcDateTimeConverter()  DateTime? effectiveAt, @UtcDateTimeConverter()  DateTime quotedAt)  $default,) {final _that = this;
switch (_that) {
case _OpenPlanChange():
return $default(_that.id,_that.direction,_that.status,_that.toPlanId,_that.toPlanName,_that.toCycle,_that.credit,_that.charge,_that.currency,_that.effectiveAt,_that.quotedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String direction,  String status,  String toPlanId,  String toPlanName, @JsonKey(unknownEnumValue: BillingCycle.unknown)  BillingCycle toCycle,  int credit,  int charge,  String currency, @NullableUtcDateTimeConverter()  DateTime? effectiveAt, @UtcDateTimeConverter()  DateTime quotedAt)?  $default,) {final _that = this;
switch (_that) {
case _OpenPlanChange() when $default != null:
return $default(_that.id,_that.direction,_that.status,_that.toPlanId,_that.toPlanName,_that.toCycle,_that.credit,_that.charge,_that.currency,_that.effectiveAt,_that.quotedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpenPlanChange extends OpenPlanChange {
  const _OpenPlanChange({this.id = '', this.direction = '', this.status = '', this.toPlanId = '', this.toPlanName = '', @JsonKey(unknownEnumValue: BillingCycle.unknown) this.toCycle = BillingCycle.unknown, this.credit = 0, this.charge = 0, this.currency = 'INR', @NullableUtcDateTimeConverter() this.effectiveAt, @UtcDateTimeConverter() required this.quotedAt}): super._();
  factory _OpenPlanChange.fromJson(Map<String, dynamic> json) => _$OpenPlanChangeFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String direction;
@override@JsonKey() final  String status;
@override@JsonKey() final  String toPlanId;
@override@JsonKey() final  String toPlanName;
@override@JsonKey(unknownEnumValue: BillingCycle.unknown) final  BillingCycle toCycle;
/// Minor units: the unused value credited, and what is charged now. Both 0 for a downgrade.
@override@JsonKey() final  int credit;
@override@JsonKey() final  int charge;
@override@JsonKey() final  String currency;
@override@NullableUtcDateTimeConverter() final  DateTime? effectiveAt;
@override@UtcDateTimeConverter() final  DateTime quotedAt;

/// Create a copy of OpenPlanChange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenPlanChangeCopyWith<_OpenPlanChange> get copyWith => __$OpenPlanChangeCopyWithImpl<_OpenPlanChange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpenPlanChangeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenPlanChange&&(identical(other.id, id) || other.id == id)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.status, status) || other.status == status)&&(identical(other.toPlanId, toPlanId) || other.toPlanId == toPlanId)&&(identical(other.toPlanName, toPlanName) || other.toPlanName == toPlanName)&&(identical(other.toCycle, toCycle) || other.toCycle == toCycle)&&(identical(other.credit, credit) || other.credit == credit)&&(identical(other.charge, charge) || other.charge == charge)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.effectiveAt, effectiveAt) || other.effectiveAt == effectiveAt)&&(identical(other.quotedAt, quotedAt) || other.quotedAt == quotedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,direction,status,toPlanId,toPlanName,toCycle,credit,charge,currency,effectiveAt,quotedAt);

@override
String toString() {
  return 'OpenPlanChange(id: $id, direction: $direction, status: $status, toPlanId: $toPlanId, toPlanName: $toPlanName, toCycle: $toCycle, credit: $credit, charge: $charge, currency: $currency, effectiveAt: $effectiveAt, quotedAt: $quotedAt)';
}


}

/// @nodoc
abstract mixin class _$OpenPlanChangeCopyWith<$Res> implements $OpenPlanChangeCopyWith<$Res> {
  factory _$OpenPlanChangeCopyWith(_OpenPlanChange value, $Res Function(_OpenPlanChange) _then) = __$OpenPlanChangeCopyWithImpl;
@override @useResult
$Res call({
 String id, String direction, String status, String toPlanId, String toPlanName,@JsonKey(unknownEnumValue: BillingCycle.unknown) BillingCycle toCycle, int credit, int charge, String currency,@NullableUtcDateTimeConverter() DateTime? effectiveAt,@UtcDateTimeConverter() DateTime quotedAt
});




}
/// @nodoc
class __$OpenPlanChangeCopyWithImpl<$Res>
    implements _$OpenPlanChangeCopyWith<$Res> {
  __$OpenPlanChangeCopyWithImpl(this._self, this._then);

  final _OpenPlanChange _self;
  final $Res Function(_OpenPlanChange) _then;

/// Create a copy of OpenPlanChange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? direction = null,Object? status = null,Object? toPlanId = null,Object? toPlanName = null,Object? toCycle = null,Object? credit = null,Object? charge = null,Object? currency = null,Object? effectiveAt = freezed,Object? quotedAt = null,}) {
  return _then(_OpenPlanChange(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,toPlanId: null == toPlanId ? _self.toPlanId : toPlanId // ignore: cast_nullable_to_non_nullable
as String,toPlanName: null == toPlanName ? _self.toPlanName : toPlanName // ignore: cast_nullable_to_non_nullable
as String,toCycle: null == toCycle ? _self.toCycle : toCycle // ignore: cast_nullable_to_non_nullable
as BillingCycle,credit: null == credit ? _self.credit : credit // ignore: cast_nullable_to_non_nullable
as int,charge: null == charge ? _self.charge : charge // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,effectiveAt: freezed == effectiveAt ? _self.effectiveAt : effectiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,quotedAt: null == quotedAt ? _self.quotedAt : quotedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$TenantPayment {

 String get id; String? get invoiceNumber; int get amount; String get currency;@JsonKey(unknownEnumValue: TenantPaymentStatus.unknown) TenantPaymentStatus get status; int get refunded;/// "Visa •••• 4242", "UPI" — never more.
 String? get method;@UtcDateTimeConverter() DateTime get at; String? get failureMessage;
/// Create a copy of TenantPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TenantPaymentCopyWith<TenantPayment> get copyWith => _$TenantPaymentCopyWithImpl<TenantPayment>(this as TenantPayment, _$identity);

  /// Serializes this TenantPayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TenantPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.invoiceNumber, invoiceNumber) || other.invoiceNumber == invoiceNumber)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.refunded, refunded) || other.refunded == refunded)&&(identical(other.method, method) || other.method == method)&&(identical(other.at, at) || other.at == at)&&(identical(other.failureMessage, failureMessage) || other.failureMessage == failureMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,invoiceNumber,amount,currency,status,refunded,method,at,failureMessage);

@override
String toString() {
  return 'TenantPayment(id: $id, invoiceNumber: $invoiceNumber, amount: $amount, currency: $currency, status: $status, refunded: $refunded, method: $method, at: $at, failureMessage: $failureMessage)';
}


}

/// @nodoc
abstract mixin class $TenantPaymentCopyWith<$Res>  {
  factory $TenantPaymentCopyWith(TenantPayment value, $Res Function(TenantPayment) _then) = _$TenantPaymentCopyWithImpl;
@useResult
$Res call({
 String id, String? invoiceNumber, int amount, String currency,@JsonKey(unknownEnumValue: TenantPaymentStatus.unknown) TenantPaymentStatus status, int refunded, String? method,@UtcDateTimeConverter() DateTime at, String? failureMessage
});




}
/// @nodoc
class _$TenantPaymentCopyWithImpl<$Res>
    implements $TenantPaymentCopyWith<$Res> {
  _$TenantPaymentCopyWithImpl(this._self, this._then);

  final TenantPayment _self;
  final $Res Function(TenantPayment) _then;

/// Create a copy of TenantPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? invoiceNumber = freezed,Object? amount = null,Object? currency = null,Object? status = null,Object? refunded = null,Object? method = freezed,Object? at = null,Object? failureMessage = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,invoiceNumber: freezed == invoiceNumber ? _self.invoiceNumber : invoiceNumber // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TenantPaymentStatus,refunded: null == refunded ? _self.refunded : refunded // ignore: cast_nullable_to_non_nullable
as int,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,failureMessage: freezed == failureMessage ? _self.failureMessage : failureMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TenantPayment].
extension TenantPaymentPatterns on TenantPayment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TenantPayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TenantPayment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TenantPayment value)  $default,){
final _that = this;
switch (_that) {
case _TenantPayment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TenantPayment value)?  $default,){
final _that = this;
switch (_that) {
case _TenantPayment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? invoiceNumber,  int amount,  String currency, @JsonKey(unknownEnumValue: TenantPaymentStatus.unknown)  TenantPaymentStatus status,  int refunded,  String? method, @UtcDateTimeConverter()  DateTime at,  String? failureMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TenantPayment() when $default != null:
return $default(_that.id,_that.invoiceNumber,_that.amount,_that.currency,_that.status,_that.refunded,_that.method,_that.at,_that.failureMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? invoiceNumber,  int amount,  String currency, @JsonKey(unknownEnumValue: TenantPaymentStatus.unknown)  TenantPaymentStatus status,  int refunded,  String? method, @UtcDateTimeConverter()  DateTime at,  String? failureMessage)  $default,) {final _that = this;
switch (_that) {
case _TenantPayment():
return $default(_that.id,_that.invoiceNumber,_that.amount,_that.currency,_that.status,_that.refunded,_that.method,_that.at,_that.failureMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? invoiceNumber,  int amount,  String currency, @JsonKey(unknownEnumValue: TenantPaymentStatus.unknown)  TenantPaymentStatus status,  int refunded,  String? method, @UtcDateTimeConverter()  DateTime at,  String? failureMessage)?  $default,) {final _that = this;
switch (_that) {
case _TenantPayment() when $default != null:
return $default(_that.id,_that.invoiceNumber,_that.amount,_that.currency,_that.status,_that.refunded,_that.method,_that.at,_that.failureMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TenantPayment implements TenantPayment {
  const _TenantPayment({this.id = '', this.invoiceNumber, this.amount = 0, this.currency = 'INR', @JsonKey(unknownEnumValue: TenantPaymentStatus.unknown) this.status = TenantPaymentStatus.unknown, this.refunded = 0, this.method, @UtcDateTimeConverter() required this.at, this.failureMessage});
  factory _TenantPayment.fromJson(Map<String, dynamic> json) => _$TenantPaymentFromJson(json);

@override@JsonKey() final  String id;
@override final  String? invoiceNumber;
@override@JsonKey() final  int amount;
@override@JsonKey() final  String currency;
@override@JsonKey(unknownEnumValue: TenantPaymentStatus.unknown) final  TenantPaymentStatus status;
@override@JsonKey() final  int refunded;
/// "Visa •••• 4242", "UPI" — never more.
@override final  String? method;
@override@UtcDateTimeConverter() final  DateTime at;
@override final  String? failureMessage;

/// Create a copy of TenantPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TenantPaymentCopyWith<_TenantPayment> get copyWith => __$TenantPaymentCopyWithImpl<_TenantPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TenantPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TenantPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.invoiceNumber, invoiceNumber) || other.invoiceNumber == invoiceNumber)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.refunded, refunded) || other.refunded == refunded)&&(identical(other.method, method) || other.method == method)&&(identical(other.at, at) || other.at == at)&&(identical(other.failureMessage, failureMessage) || other.failureMessage == failureMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,invoiceNumber,amount,currency,status,refunded,method,at,failureMessage);

@override
String toString() {
  return 'TenantPayment(id: $id, invoiceNumber: $invoiceNumber, amount: $amount, currency: $currency, status: $status, refunded: $refunded, method: $method, at: $at, failureMessage: $failureMessage)';
}


}

/// @nodoc
abstract mixin class _$TenantPaymentCopyWith<$Res> implements $TenantPaymentCopyWith<$Res> {
  factory _$TenantPaymentCopyWith(_TenantPayment value, $Res Function(_TenantPayment) _then) = __$TenantPaymentCopyWithImpl;
@override @useResult
$Res call({
 String id, String? invoiceNumber, int amount, String currency,@JsonKey(unknownEnumValue: TenantPaymentStatus.unknown) TenantPaymentStatus status, int refunded, String? method,@UtcDateTimeConverter() DateTime at, String? failureMessage
});




}
/// @nodoc
class __$TenantPaymentCopyWithImpl<$Res>
    implements _$TenantPaymentCopyWith<$Res> {
  __$TenantPaymentCopyWithImpl(this._self, this._then);

  final _TenantPayment _self;
  final $Res Function(_TenantPayment) _then;

/// Create a copy of TenantPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? invoiceNumber = freezed,Object? amount = null,Object? currency = null,Object? status = null,Object? refunded = null,Object? method = freezed,Object? at = null,Object? failureMessage = freezed,}) {
  return _then(_TenantPayment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,invoiceNumber: freezed == invoiceNumber ? _self.invoiceNumber : invoiceNumber // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TenantPaymentStatus,refunded: null == refunded ? _self.refunded : refunded // ignore: cast_nullable_to_non_nullable
as int,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,failureMessage: freezed == failureMessage ? _self.failureMessage : failureMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$InvoiceLine {

 String get description; int get quantity; int get unitAmount;
/// Create a copy of InvoiceLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvoiceLineCopyWith<InvoiceLine> get copyWith => _$InvoiceLineCopyWithImpl<InvoiceLine>(this as InvoiceLine, _$identity);

  /// Serializes this InvoiceLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvoiceLine&&(identical(other.description, description) || other.description == description)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitAmount, unitAmount) || other.unitAmount == unitAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,quantity,unitAmount);

@override
String toString() {
  return 'InvoiceLine(description: $description, quantity: $quantity, unitAmount: $unitAmount)';
}


}

/// @nodoc
abstract mixin class $InvoiceLineCopyWith<$Res>  {
  factory $InvoiceLineCopyWith(InvoiceLine value, $Res Function(InvoiceLine) _then) = _$InvoiceLineCopyWithImpl;
@useResult
$Res call({
 String description, int quantity, int unitAmount
});




}
/// @nodoc
class _$InvoiceLineCopyWithImpl<$Res>
    implements $InvoiceLineCopyWith<$Res> {
  _$InvoiceLineCopyWithImpl(this._self, this._then);

  final InvoiceLine _self;
  final $Res Function(InvoiceLine) _then;

/// Create a copy of InvoiceLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? description = null,Object? quantity = null,Object? unitAmount = null,}) {
  return _then(_self.copyWith(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitAmount: null == unitAmount ? _self.unitAmount : unitAmount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [InvoiceLine].
extension InvoiceLinePatterns on InvoiceLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvoiceLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvoiceLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvoiceLine value)  $default,){
final _that = this;
switch (_that) {
case _InvoiceLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvoiceLine value)?  $default,){
final _that = this;
switch (_that) {
case _InvoiceLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String description,  int quantity,  int unitAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvoiceLine() when $default != null:
return $default(_that.description,_that.quantity,_that.unitAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String description,  int quantity,  int unitAmount)  $default,) {final _that = this;
switch (_that) {
case _InvoiceLine():
return $default(_that.description,_that.quantity,_that.unitAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String description,  int quantity,  int unitAmount)?  $default,) {final _that = this;
switch (_that) {
case _InvoiceLine() when $default != null:
return $default(_that.description,_that.quantity,_that.unitAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvoiceLine implements InvoiceLine {
  const _InvoiceLine({this.description = '', this.quantity = 1, this.unitAmount = 0});
  factory _InvoiceLine.fromJson(Map<String, dynamic> json) => _$InvoiceLineFromJson(json);

@override@JsonKey() final  String description;
@override@JsonKey() final  int quantity;
@override@JsonKey() final  int unitAmount;

/// Create a copy of InvoiceLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvoiceLineCopyWith<_InvoiceLine> get copyWith => __$InvoiceLineCopyWithImpl<_InvoiceLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvoiceLineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvoiceLine&&(identical(other.description, description) || other.description == description)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitAmount, unitAmount) || other.unitAmount == unitAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,quantity,unitAmount);

@override
String toString() {
  return 'InvoiceLine(description: $description, quantity: $quantity, unitAmount: $unitAmount)';
}


}

/// @nodoc
abstract mixin class _$InvoiceLineCopyWith<$Res> implements $InvoiceLineCopyWith<$Res> {
  factory _$InvoiceLineCopyWith(_InvoiceLine value, $Res Function(_InvoiceLine) _then) = __$InvoiceLineCopyWithImpl;
@override @useResult
$Res call({
 String description, int quantity, int unitAmount
});




}
/// @nodoc
class __$InvoiceLineCopyWithImpl<$Res>
    implements _$InvoiceLineCopyWith<$Res> {
  __$InvoiceLineCopyWithImpl(this._self, this._then);

  final _InvoiceLine _self;
  final $Res Function(_InvoiceLine) _then;

/// Create a copy of InvoiceLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? description = null,Object? quantity = null,Object? unitAmount = null,}) {
  return _then(_InvoiceLine(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitAmount: null == unitAmount ? _self.unitAmount : unitAmount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$InvoiceAmounts {

 int get subtotal; int get tax; int get total;
/// Create a copy of InvoiceAmounts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvoiceAmountsCopyWith<InvoiceAmounts> get copyWith => _$InvoiceAmountsCopyWithImpl<InvoiceAmounts>(this as InvoiceAmounts, _$identity);

  /// Serializes this InvoiceAmounts to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvoiceAmounts&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.tax, tax) || other.tax == tax)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subtotal,tax,total);

@override
String toString() {
  return 'InvoiceAmounts(subtotal: $subtotal, tax: $tax, total: $total)';
}


}

/// @nodoc
abstract mixin class $InvoiceAmountsCopyWith<$Res>  {
  factory $InvoiceAmountsCopyWith(InvoiceAmounts value, $Res Function(InvoiceAmounts) _then) = _$InvoiceAmountsCopyWithImpl;
@useResult
$Res call({
 int subtotal, int tax, int total
});




}
/// @nodoc
class _$InvoiceAmountsCopyWithImpl<$Res>
    implements $InvoiceAmountsCopyWith<$Res> {
  _$InvoiceAmountsCopyWithImpl(this._self, this._then);

  final InvoiceAmounts _self;
  final $Res Function(InvoiceAmounts) _then;

/// Create a copy of InvoiceAmounts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subtotal = null,Object? tax = null,Object? total = null,}) {
  return _then(_self.copyWith(
subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as int,tax: null == tax ? _self.tax : tax // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [InvoiceAmounts].
extension InvoiceAmountsPatterns on InvoiceAmounts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvoiceAmounts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvoiceAmounts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvoiceAmounts value)  $default,){
final _that = this;
switch (_that) {
case _InvoiceAmounts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvoiceAmounts value)?  $default,){
final _that = this;
switch (_that) {
case _InvoiceAmounts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int subtotal,  int tax,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvoiceAmounts() when $default != null:
return $default(_that.subtotal,_that.tax,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int subtotal,  int tax,  int total)  $default,) {final _that = this;
switch (_that) {
case _InvoiceAmounts():
return $default(_that.subtotal,_that.tax,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int subtotal,  int tax,  int total)?  $default,) {final _that = this;
switch (_that) {
case _InvoiceAmounts() when $default != null:
return $default(_that.subtotal,_that.tax,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvoiceAmounts implements InvoiceAmounts {
  const _InvoiceAmounts({this.subtotal = 0, this.tax = 0, this.total = 0});
  factory _InvoiceAmounts.fromJson(Map<String, dynamic> json) => _$InvoiceAmountsFromJson(json);

@override@JsonKey() final  int subtotal;
@override@JsonKey() final  int tax;
@override@JsonKey() final  int total;

/// Create a copy of InvoiceAmounts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvoiceAmountsCopyWith<_InvoiceAmounts> get copyWith => __$InvoiceAmountsCopyWithImpl<_InvoiceAmounts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvoiceAmountsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvoiceAmounts&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.tax, tax) || other.tax == tax)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subtotal,tax,total);

@override
String toString() {
  return 'InvoiceAmounts(subtotal: $subtotal, tax: $tax, total: $total)';
}


}

/// @nodoc
abstract mixin class _$InvoiceAmountsCopyWith<$Res> implements $InvoiceAmountsCopyWith<$Res> {
  factory _$InvoiceAmountsCopyWith(_InvoiceAmounts value, $Res Function(_InvoiceAmounts) _then) = __$InvoiceAmountsCopyWithImpl;
@override @useResult
$Res call({
 int subtotal, int tax, int total
});




}
/// @nodoc
class __$InvoiceAmountsCopyWithImpl<$Res>
    implements _$InvoiceAmountsCopyWith<$Res> {
  __$InvoiceAmountsCopyWithImpl(this._self, this._then);

  final _InvoiceAmounts _self;
  final $Res Function(_InvoiceAmounts) _then;

/// Create a copy of InvoiceAmounts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subtotal = null,Object? tax = null,Object? total = null,}) {
  return _then(_InvoiceAmounts(
subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as int,tax: null == tax ? _self.tax : tax // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$InvoiceView {

 String get id;/// Human-facing, e.g. "INV-2026-0148".
 String get number; String get subscriptionId; String get customerId; String get customerName; String get planName;@JsonKey(unknownEnumValue: BillingCycle.unknown) BillingCycle get cycle;@UtcDateTimeConverter() DateTime get issuedAt;@UtcDateTimeConverter() DateTime get periodStart;@UtcDateTimeConverter() DateTime get periodEnd; List<InvoiceLine> get lines;/// Per cent of the subtotal, e.g. 18 for GST.
 num get taxPercent; String get currency;@JsonKey(unknownEnumValue: InvoiceStatus.unknown) InvoiceStatus get status;@NullableUtcDateTimeConverter() DateTime? get paidAt; PaymentMethodView get method;/// Why a payment failed or was refunded — shown in place of a paid date.
 String? get note; List<String> get billingAddress;/// Present on every invoice the billing API serves.
 InvoiceAmounts? get amounts;
/// Create a copy of InvoiceView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvoiceViewCopyWith<InvoiceView> get copyWith => _$InvoiceViewCopyWithImpl<InvoiceView>(this as InvoiceView, _$identity);

  /// Serializes this InvoiceView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvoiceView&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.planName, planName) || other.planName == planName)&&(identical(other.cycle, cycle) || other.cycle == cycle)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&const DeepCollectionEquality().equals(other.lines, lines)&&(identical(other.taxPercent, taxPercent) || other.taxPercent == taxPercent)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.method, method) || other.method == method)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other.billingAddress, billingAddress)&&(identical(other.amounts, amounts) || other.amounts == amounts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,number,subscriptionId,customerId,customerName,planName,cycle,issuedAt,periodStart,periodEnd,const DeepCollectionEquality().hash(lines),taxPercent,currency,status,paidAt,method,note,const DeepCollectionEquality().hash(billingAddress),amounts]);

@override
String toString() {
  return 'InvoiceView(id: $id, number: $number, subscriptionId: $subscriptionId, customerId: $customerId, customerName: $customerName, planName: $planName, cycle: $cycle, issuedAt: $issuedAt, periodStart: $periodStart, periodEnd: $periodEnd, lines: $lines, taxPercent: $taxPercent, currency: $currency, status: $status, paidAt: $paidAt, method: $method, note: $note, billingAddress: $billingAddress, amounts: $amounts)';
}


}

/// @nodoc
abstract mixin class $InvoiceViewCopyWith<$Res>  {
  factory $InvoiceViewCopyWith(InvoiceView value, $Res Function(InvoiceView) _then) = _$InvoiceViewCopyWithImpl;
@useResult
$Res call({
 String id, String number, String subscriptionId, String customerId, String customerName, String planName,@JsonKey(unknownEnumValue: BillingCycle.unknown) BillingCycle cycle,@UtcDateTimeConverter() DateTime issuedAt,@UtcDateTimeConverter() DateTime periodStart,@UtcDateTimeConverter() DateTime periodEnd, List<InvoiceLine> lines, num taxPercent, String currency,@JsonKey(unknownEnumValue: InvoiceStatus.unknown) InvoiceStatus status,@NullableUtcDateTimeConverter() DateTime? paidAt, PaymentMethodView method, String? note, List<String> billingAddress, InvoiceAmounts? amounts
});


$PaymentMethodViewCopyWith<$Res> get method;$InvoiceAmountsCopyWith<$Res>? get amounts;

}
/// @nodoc
class _$InvoiceViewCopyWithImpl<$Res>
    implements $InvoiceViewCopyWith<$Res> {
  _$InvoiceViewCopyWithImpl(this._self, this._then);

  final InvoiceView _self;
  final $Res Function(InvoiceView) _then;

/// Create a copy of InvoiceView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? subscriptionId = null,Object? customerId = null,Object? customerName = null,Object? planName = null,Object? cycle = null,Object? issuedAt = null,Object? periodStart = null,Object? periodEnd = null,Object? lines = null,Object? taxPercent = null,Object? currency = null,Object? status = null,Object? paidAt = freezed,Object? method = null,Object? note = freezed,Object? billingAddress = null,Object? amounts = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,subscriptionId: null == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,customerName: null == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String,planName: null == planName ? _self.planName : planName // ignore: cast_nullable_to_non_nullable
as String,cycle: null == cycle ? _self.cycle : cycle // ignore: cast_nullable_to_non_nullable
as BillingCycle,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<InvoiceLine>,taxPercent: null == taxPercent ? _self.taxPercent : taxPercent // ignore: cast_nullable_to_non_nullable
as num,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InvoiceStatus,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as PaymentMethodView,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,billingAddress: null == billingAddress ? _self.billingAddress : billingAddress // ignore: cast_nullable_to_non_nullable
as List<String>,amounts: freezed == amounts ? _self.amounts : amounts // ignore: cast_nullable_to_non_nullable
as InvoiceAmounts?,
  ));
}
/// Create a copy of InvoiceView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentMethodViewCopyWith<$Res> get method {
  
  return $PaymentMethodViewCopyWith<$Res>(_self.method, (value) {
    return _then(_self.copyWith(method: value));
  });
}/// Create a copy of InvoiceView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvoiceAmountsCopyWith<$Res>? get amounts {
    if (_self.amounts == null) {
    return null;
  }

  return $InvoiceAmountsCopyWith<$Res>(_self.amounts!, (value) {
    return _then(_self.copyWith(amounts: value));
  });
}
}


/// Adds pattern-matching-related methods to [InvoiceView].
extension InvoiceViewPatterns on InvoiceView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvoiceView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvoiceView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvoiceView value)  $default,){
final _that = this;
switch (_that) {
case _InvoiceView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvoiceView value)?  $default,){
final _that = this;
switch (_that) {
case _InvoiceView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String number,  String subscriptionId,  String customerId,  String customerName,  String planName, @JsonKey(unknownEnumValue: BillingCycle.unknown)  BillingCycle cycle, @UtcDateTimeConverter()  DateTime issuedAt, @UtcDateTimeConverter()  DateTime periodStart, @UtcDateTimeConverter()  DateTime periodEnd,  List<InvoiceLine> lines,  num taxPercent,  String currency, @JsonKey(unknownEnumValue: InvoiceStatus.unknown)  InvoiceStatus status, @NullableUtcDateTimeConverter()  DateTime? paidAt,  PaymentMethodView method,  String? note,  List<String> billingAddress,  InvoiceAmounts? amounts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvoiceView() when $default != null:
return $default(_that.id,_that.number,_that.subscriptionId,_that.customerId,_that.customerName,_that.planName,_that.cycle,_that.issuedAt,_that.periodStart,_that.periodEnd,_that.lines,_that.taxPercent,_that.currency,_that.status,_that.paidAt,_that.method,_that.note,_that.billingAddress,_that.amounts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String number,  String subscriptionId,  String customerId,  String customerName,  String planName, @JsonKey(unknownEnumValue: BillingCycle.unknown)  BillingCycle cycle, @UtcDateTimeConverter()  DateTime issuedAt, @UtcDateTimeConverter()  DateTime periodStart, @UtcDateTimeConverter()  DateTime periodEnd,  List<InvoiceLine> lines,  num taxPercent,  String currency, @JsonKey(unknownEnumValue: InvoiceStatus.unknown)  InvoiceStatus status, @NullableUtcDateTimeConverter()  DateTime? paidAt,  PaymentMethodView method,  String? note,  List<String> billingAddress,  InvoiceAmounts? amounts)  $default,) {final _that = this;
switch (_that) {
case _InvoiceView():
return $default(_that.id,_that.number,_that.subscriptionId,_that.customerId,_that.customerName,_that.planName,_that.cycle,_that.issuedAt,_that.periodStart,_that.periodEnd,_that.lines,_that.taxPercent,_that.currency,_that.status,_that.paidAt,_that.method,_that.note,_that.billingAddress,_that.amounts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String number,  String subscriptionId,  String customerId,  String customerName,  String planName, @JsonKey(unknownEnumValue: BillingCycle.unknown)  BillingCycle cycle, @UtcDateTimeConverter()  DateTime issuedAt, @UtcDateTimeConverter()  DateTime periodStart, @UtcDateTimeConverter()  DateTime periodEnd,  List<InvoiceLine> lines,  num taxPercent,  String currency, @JsonKey(unknownEnumValue: InvoiceStatus.unknown)  InvoiceStatus status, @NullableUtcDateTimeConverter()  DateTime? paidAt,  PaymentMethodView method,  String? note,  List<String> billingAddress,  InvoiceAmounts? amounts)?  $default,) {final _that = this;
switch (_that) {
case _InvoiceView() when $default != null:
return $default(_that.id,_that.number,_that.subscriptionId,_that.customerId,_that.customerName,_that.planName,_that.cycle,_that.issuedAt,_that.periodStart,_that.periodEnd,_that.lines,_that.taxPercent,_that.currency,_that.status,_that.paidAt,_that.method,_that.note,_that.billingAddress,_that.amounts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvoiceView extends InvoiceView {
  const _InvoiceView({this.id = '', this.number = '', this.subscriptionId = '', this.customerId = '', this.customerName = '', this.planName = '', @JsonKey(unknownEnumValue: BillingCycle.unknown) this.cycle = BillingCycle.unknown, @UtcDateTimeConverter() required this.issuedAt, @UtcDateTimeConverter() required this.periodStart, @UtcDateTimeConverter() required this.periodEnd, final  List<InvoiceLine> lines = const <InvoiceLine>[], this.taxPercent = 0, this.currency = 'INR', @JsonKey(unknownEnumValue: InvoiceStatus.unknown) this.status = InvoiceStatus.unknown, @NullableUtcDateTimeConverter() this.paidAt, this.method = const PaymentMethodView(), this.note, final  List<String> billingAddress = const <String>[], this.amounts}): _lines = lines,_billingAddress = billingAddress,super._();
  factory _InvoiceView.fromJson(Map<String, dynamic> json) => _$InvoiceViewFromJson(json);

@override@JsonKey() final  String id;
/// Human-facing, e.g. "INV-2026-0148".
@override@JsonKey() final  String number;
@override@JsonKey() final  String subscriptionId;
@override@JsonKey() final  String customerId;
@override@JsonKey() final  String customerName;
@override@JsonKey() final  String planName;
@override@JsonKey(unknownEnumValue: BillingCycle.unknown) final  BillingCycle cycle;
@override@UtcDateTimeConverter() final  DateTime issuedAt;
@override@UtcDateTimeConverter() final  DateTime periodStart;
@override@UtcDateTimeConverter() final  DateTime periodEnd;
 final  List<InvoiceLine> _lines;
@override@JsonKey() List<InvoiceLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

/// Per cent of the subtotal, e.g. 18 for GST.
@override@JsonKey() final  num taxPercent;
@override@JsonKey() final  String currency;
@override@JsonKey(unknownEnumValue: InvoiceStatus.unknown) final  InvoiceStatus status;
@override@NullableUtcDateTimeConverter() final  DateTime? paidAt;
@override@JsonKey() final  PaymentMethodView method;
/// Why a payment failed or was refunded — shown in place of a paid date.
@override final  String? note;
 final  List<String> _billingAddress;
@override@JsonKey() List<String> get billingAddress {
  if (_billingAddress is EqualUnmodifiableListView) return _billingAddress;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_billingAddress);
}

/// Present on every invoice the billing API serves.
@override final  InvoiceAmounts? amounts;

/// Create a copy of InvoiceView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvoiceViewCopyWith<_InvoiceView> get copyWith => __$InvoiceViewCopyWithImpl<_InvoiceView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvoiceViewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvoiceView&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.planName, planName) || other.planName == planName)&&(identical(other.cycle, cycle) || other.cycle == cycle)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&const DeepCollectionEquality().equals(other._lines, _lines)&&(identical(other.taxPercent, taxPercent) || other.taxPercent == taxPercent)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.method, method) || other.method == method)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other._billingAddress, _billingAddress)&&(identical(other.amounts, amounts) || other.amounts == amounts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,number,subscriptionId,customerId,customerName,planName,cycle,issuedAt,periodStart,periodEnd,const DeepCollectionEquality().hash(_lines),taxPercent,currency,status,paidAt,method,note,const DeepCollectionEquality().hash(_billingAddress),amounts]);

@override
String toString() {
  return 'InvoiceView(id: $id, number: $number, subscriptionId: $subscriptionId, customerId: $customerId, customerName: $customerName, planName: $planName, cycle: $cycle, issuedAt: $issuedAt, periodStart: $periodStart, periodEnd: $periodEnd, lines: $lines, taxPercent: $taxPercent, currency: $currency, status: $status, paidAt: $paidAt, method: $method, note: $note, billingAddress: $billingAddress, amounts: $amounts)';
}


}

/// @nodoc
abstract mixin class _$InvoiceViewCopyWith<$Res> implements $InvoiceViewCopyWith<$Res> {
  factory _$InvoiceViewCopyWith(_InvoiceView value, $Res Function(_InvoiceView) _then) = __$InvoiceViewCopyWithImpl;
@override @useResult
$Res call({
 String id, String number, String subscriptionId, String customerId, String customerName, String planName,@JsonKey(unknownEnumValue: BillingCycle.unknown) BillingCycle cycle,@UtcDateTimeConverter() DateTime issuedAt,@UtcDateTimeConverter() DateTime periodStart,@UtcDateTimeConverter() DateTime periodEnd, List<InvoiceLine> lines, num taxPercent, String currency,@JsonKey(unknownEnumValue: InvoiceStatus.unknown) InvoiceStatus status,@NullableUtcDateTimeConverter() DateTime? paidAt, PaymentMethodView method, String? note, List<String> billingAddress, InvoiceAmounts? amounts
});


@override $PaymentMethodViewCopyWith<$Res> get method;@override $InvoiceAmountsCopyWith<$Res>? get amounts;

}
/// @nodoc
class __$InvoiceViewCopyWithImpl<$Res>
    implements _$InvoiceViewCopyWith<$Res> {
  __$InvoiceViewCopyWithImpl(this._self, this._then);

  final _InvoiceView _self;
  final $Res Function(_InvoiceView) _then;

/// Create a copy of InvoiceView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? subscriptionId = null,Object? customerId = null,Object? customerName = null,Object? planName = null,Object? cycle = null,Object? issuedAt = null,Object? periodStart = null,Object? periodEnd = null,Object? lines = null,Object? taxPercent = null,Object? currency = null,Object? status = null,Object? paidAt = freezed,Object? method = null,Object? note = freezed,Object? billingAddress = null,Object? amounts = freezed,}) {
  return _then(_InvoiceView(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,subscriptionId: null == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,customerName: null == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String,planName: null == planName ? _self.planName : planName // ignore: cast_nullable_to_non_nullable
as String,cycle: null == cycle ? _self.cycle : cycle // ignore: cast_nullable_to_non_nullable
as BillingCycle,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<InvoiceLine>,taxPercent: null == taxPercent ? _self.taxPercent : taxPercent // ignore: cast_nullable_to_non_nullable
as num,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InvoiceStatus,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as PaymentMethodView,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,billingAddress: null == billingAddress ? _self._billingAddress : billingAddress // ignore: cast_nullable_to_non_nullable
as List<String>,amounts: freezed == amounts ? _self.amounts : amounts // ignore: cast_nullable_to_non_nullable
as InvoiceAmounts?,
  ));
}

/// Create a copy of InvoiceView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentMethodViewCopyWith<$Res> get method {
  
  return $PaymentMethodViewCopyWith<$Res>(_self.method, (value) {
    return _then(_self.copyWith(method: value));
  });
}/// Create a copy of InvoiceView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvoiceAmountsCopyWith<$Res>? get amounts {
    if (_self.amounts == null) {
    return null;
  }

  return $InvoiceAmountsCopyWith<$Res>(_self.amounts!, (value) {
    return _then(_self.copyWith(amounts: value));
  });
}
}


/// @nodoc
mixin _$TenantBilling {

 BillingAcademy get academy;/// The live subscription, or the most recent one; `null` when the academy has never subscribed.
 SubscriptionView? get subscription; PlanView? get plan;/// No plan is served: the academy keeps what it has and cannot add to it until it renews.
 bool get restricted;/// Whether the platform enforces plans yet. While it does not, nothing is refused for a limit or
/// a missing plan, so the screen does not warn of a block that will not happen.
 bool get enforced; OpenPlanChange? get openChange; List<UsageLine> get usage; List<FeatureLine> get features; List<InvoiceView> get invoices; List<TenantPayment> get payments; List<PlanView> get plans;/// Whether online payment is connected. Until it is, an upgrade can be quoted but not paid.
 bool get checkoutAvailable;/// Whether the academy may start a free trial now: no live subscription, and none had before
/// (`trialAvailable` in `apps/api/src/lib/subscriptions.ts`). The academy's word, never inferred.
 bool get trialAvailable;
/// Create a copy of TenantBilling
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TenantBillingCopyWith<TenantBilling> get copyWith => _$TenantBillingCopyWithImpl<TenantBilling>(this as TenantBilling, _$identity);

  /// Serializes this TenantBilling to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TenantBilling&&(identical(other.academy, academy) || other.academy == academy)&&(identical(other.subscription, subscription) || other.subscription == subscription)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.restricted, restricted) || other.restricted == restricted)&&(identical(other.enforced, enforced) || other.enforced == enforced)&&(identical(other.openChange, openChange) || other.openChange == openChange)&&const DeepCollectionEquality().equals(other.usage, usage)&&const DeepCollectionEquality().equals(other.features, features)&&const DeepCollectionEquality().equals(other.invoices, invoices)&&const DeepCollectionEquality().equals(other.payments, payments)&&const DeepCollectionEquality().equals(other.plans, plans)&&(identical(other.checkoutAvailable, checkoutAvailable) || other.checkoutAvailable == checkoutAvailable)&&(identical(other.trialAvailable, trialAvailable) || other.trialAvailable == trialAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,academy,subscription,plan,restricted,enforced,openChange,const DeepCollectionEquality().hash(usage),const DeepCollectionEquality().hash(features),const DeepCollectionEquality().hash(invoices),const DeepCollectionEquality().hash(payments),const DeepCollectionEquality().hash(plans),checkoutAvailable,trialAvailable);

@override
String toString() {
  return 'TenantBilling(academy: $academy, subscription: $subscription, plan: $plan, restricted: $restricted, enforced: $enforced, openChange: $openChange, usage: $usage, features: $features, invoices: $invoices, payments: $payments, plans: $plans, checkoutAvailable: $checkoutAvailable, trialAvailable: $trialAvailable)';
}


}

/// @nodoc
abstract mixin class $TenantBillingCopyWith<$Res>  {
  factory $TenantBillingCopyWith(TenantBilling value, $Res Function(TenantBilling) _then) = _$TenantBillingCopyWithImpl;
@useResult
$Res call({
 BillingAcademy academy, SubscriptionView? subscription, PlanView? plan, bool restricted, bool enforced, OpenPlanChange? openChange, List<UsageLine> usage, List<FeatureLine> features, List<InvoiceView> invoices, List<TenantPayment> payments, List<PlanView> plans, bool checkoutAvailable, bool trialAvailable
});


$BillingAcademyCopyWith<$Res> get academy;$SubscriptionViewCopyWith<$Res>? get subscription;$PlanViewCopyWith<$Res>? get plan;$OpenPlanChangeCopyWith<$Res>? get openChange;

}
/// @nodoc
class _$TenantBillingCopyWithImpl<$Res>
    implements $TenantBillingCopyWith<$Res> {
  _$TenantBillingCopyWithImpl(this._self, this._then);

  final TenantBilling _self;
  final $Res Function(TenantBilling) _then;

/// Create a copy of TenantBilling
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? academy = null,Object? subscription = freezed,Object? plan = freezed,Object? restricted = null,Object? enforced = null,Object? openChange = freezed,Object? usage = null,Object? features = null,Object? invoices = null,Object? payments = null,Object? plans = null,Object? checkoutAvailable = null,Object? trialAvailable = null,}) {
  return _then(_self.copyWith(
academy: null == academy ? _self.academy : academy // ignore: cast_nullable_to_non_nullable
as BillingAcademy,subscription: freezed == subscription ? _self.subscription : subscription // ignore: cast_nullable_to_non_nullable
as SubscriptionView?,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PlanView?,restricted: null == restricted ? _self.restricted : restricted // ignore: cast_nullable_to_non_nullable
as bool,enforced: null == enforced ? _self.enforced : enforced // ignore: cast_nullable_to_non_nullable
as bool,openChange: freezed == openChange ? _self.openChange : openChange // ignore: cast_nullable_to_non_nullable
as OpenPlanChange?,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as List<UsageLine>,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as List<FeatureLine>,invoices: null == invoices ? _self.invoices : invoices // ignore: cast_nullable_to_non_nullable
as List<InvoiceView>,payments: null == payments ? _self.payments : payments // ignore: cast_nullable_to_non_nullable
as List<TenantPayment>,plans: null == plans ? _self.plans : plans // ignore: cast_nullable_to_non_nullable
as List<PlanView>,checkoutAvailable: null == checkoutAvailable ? _self.checkoutAvailable : checkoutAvailable // ignore: cast_nullable_to_non_nullable
as bool,trialAvailable: null == trialAvailable ? _self.trialAvailable : trialAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of TenantBilling
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BillingAcademyCopyWith<$Res> get academy {
  
  return $BillingAcademyCopyWith<$Res>(_self.academy, (value) {
    return _then(_self.copyWith(academy: value));
  });
}/// Create a copy of TenantBilling
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubscriptionViewCopyWith<$Res>? get subscription {
    if (_self.subscription == null) {
    return null;
  }

  return $SubscriptionViewCopyWith<$Res>(_self.subscription!, (value) {
    return _then(_self.copyWith(subscription: value));
  });
}/// Create a copy of TenantBilling
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanViewCopyWith<$Res>? get plan {
    if (_self.plan == null) {
    return null;
  }

  return $PlanViewCopyWith<$Res>(_self.plan!, (value) {
    return _then(_self.copyWith(plan: value));
  });
}/// Create a copy of TenantBilling
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpenPlanChangeCopyWith<$Res>? get openChange {
    if (_self.openChange == null) {
    return null;
  }

  return $OpenPlanChangeCopyWith<$Res>(_self.openChange!, (value) {
    return _then(_self.copyWith(openChange: value));
  });
}
}


/// Adds pattern-matching-related methods to [TenantBilling].
extension TenantBillingPatterns on TenantBilling {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TenantBilling value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TenantBilling() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TenantBilling value)  $default,){
final _that = this;
switch (_that) {
case _TenantBilling():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TenantBilling value)?  $default,){
final _that = this;
switch (_that) {
case _TenantBilling() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BillingAcademy academy,  SubscriptionView? subscription,  PlanView? plan,  bool restricted,  bool enforced,  OpenPlanChange? openChange,  List<UsageLine> usage,  List<FeatureLine> features,  List<InvoiceView> invoices,  List<TenantPayment> payments,  List<PlanView> plans,  bool checkoutAvailable,  bool trialAvailable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TenantBilling() when $default != null:
return $default(_that.academy,_that.subscription,_that.plan,_that.restricted,_that.enforced,_that.openChange,_that.usage,_that.features,_that.invoices,_that.payments,_that.plans,_that.checkoutAvailable,_that.trialAvailable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BillingAcademy academy,  SubscriptionView? subscription,  PlanView? plan,  bool restricted,  bool enforced,  OpenPlanChange? openChange,  List<UsageLine> usage,  List<FeatureLine> features,  List<InvoiceView> invoices,  List<TenantPayment> payments,  List<PlanView> plans,  bool checkoutAvailable,  bool trialAvailable)  $default,) {final _that = this;
switch (_that) {
case _TenantBilling():
return $default(_that.academy,_that.subscription,_that.plan,_that.restricted,_that.enforced,_that.openChange,_that.usage,_that.features,_that.invoices,_that.payments,_that.plans,_that.checkoutAvailable,_that.trialAvailable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BillingAcademy academy,  SubscriptionView? subscription,  PlanView? plan,  bool restricted,  bool enforced,  OpenPlanChange? openChange,  List<UsageLine> usage,  List<FeatureLine> features,  List<InvoiceView> invoices,  List<TenantPayment> payments,  List<PlanView> plans,  bool checkoutAvailable,  bool trialAvailable)?  $default,) {final _that = this;
switch (_that) {
case _TenantBilling() when $default != null:
return $default(_that.academy,_that.subscription,_that.plan,_that.restricted,_that.enforced,_that.openChange,_that.usage,_that.features,_that.invoices,_that.payments,_that.plans,_that.checkoutAvailable,_that.trialAvailable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TenantBilling extends TenantBilling {
  const _TenantBilling({this.academy = const BillingAcademy(), this.subscription, this.plan, this.restricted = false, this.enforced = false, this.openChange, final  List<UsageLine> usage = const <UsageLine>[], final  List<FeatureLine> features = const <FeatureLine>[], final  List<InvoiceView> invoices = const <InvoiceView>[], final  List<TenantPayment> payments = const <TenantPayment>[], final  List<PlanView> plans = const <PlanView>[], this.checkoutAvailable = false, this.trialAvailable = false}): _usage = usage,_features = features,_invoices = invoices,_payments = payments,_plans = plans,super._();
  factory _TenantBilling.fromJson(Map<String, dynamic> json) => _$TenantBillingFromJson(json);

@override@JsonKey() final  BillingAcademy academy;
/// The live subscription, or the most recent one; `null` when the academy has never subscribed.
@override final  SubscriptionView? subscription;
@override final  PlanView? plan;
/// No plan is served: the academy keeps what it has and cannot add to it until it renews.
@override@JsonKey() final  bool restricted;
/// Whether the platform enforces plans yet. While it does not, nothing is refused for a limit or
/// a missing plan, so the screen does not warn of a block that will not happen.
@override@JsonKey() final  bool enforced;
@override final  OpenPlanChange? openChange;
 final  List<UsageLine> _usage;
@override@JsonKey() List<UsageLine> get usage {
  if (_usage is EqualUnmodifiableListView) return _usage;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_usage);
}

 final  List<FeatureLine> _features;
@override@JsonKey() List<FeatureLine> get features {
  if (_features is EqualUnmodifiableListView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_features);
}

 final  List<InvoiceView> _invoices;
@override@JsonKey() List<InvoiceView> get invoices {
  if (_invoices is EqualUnmodifiableListView) return _invoices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_invoices);
}

 final  List<TenantPayment> _payments;
@override@JsonKey() List<TenantPayment> get payments {
  if (_payments is EqualUnmodifiableListView) return _payments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_payments);
}

 final  List<PlanView> _plans;
@override@JsonKey() List<PlanView> get plans {
  if (_plans is EqualUnmodifiableListView) return _plans;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_plans);
}

/// Whether online payment is connected. Until it is, an upgrade can be quoted but not paid.
@override@JsonKey() final  bool checkoutAvailable;
/// Whether the academy may start a free trial now: no live subscription, and none had before
/// (`trialAvailable` in `apps/api/src/lib/subscriptions.ts`). The academy's word, never inferred.
@override@JsonKey() final  bool trialAvailable;

/// Create a copy of TenantBilling
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TenantBillingCopyWith<_TenantBilling> get copyWith => __$TenantBillingCopyWithImpl<_TenantBilling>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TenantBillingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TenantBilling&&(identical(other.academy, academy) || other.academy == academy)&&(identical(other.subscription, subscription) || other.subscription == subscription)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.restricted, restricted) || other.restricted == restricted)&&(identical(other.enforced, enforced) || other.enforced == enforced)&&(identical(other.openChange, openChange) || other.openChange == openChange)&&const DeepCollectionEquality().equals(other._usage, _usage)&&const DeepCollectionEquality().equals(other._features, _features)&&const DeepCollectionEquality().equals(other._invoices, _invoices)&&const DeepCollectionEquality().equals(other._payments, _payments)&&const DeepCollectionEquality().equals(other._plans, _plans)&&(identical(other.checkoutAvailable, checkoutAvailable) || other.checkoutAvailable == checkoutAvailable)&&(identical(other.trialAvailable, trialAvailable) || other.trialAvailable == trialAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,academy,subscription,plan,restricted,enforced,openChange,const DeepCollectionEquality().hash(_usage),const DeepCollectionEquality().hash(_features),const DeepCollectionEquality().hash(_invoices),const DeepCollectionEquality().hash(_payments),const DeepCollectionEquality().hash(_plans),checkoutAvailable,trialAvailable);

@override
String toString() {
  return 'TenantBilling(academy: $academy, subscription: $subscription, plan: $plan, restricted: $restricted, enforced: $enforced, openChange: $openChange, usage: $usage, features: $features, invoices: $invoices, payments: $payments, plans: $plans, checkoutAvailable: $checkoutAvailable, trialAvailable: $trialAvailable)';
}


}

/// @nodoc
abstract mixin class _$TenantBillingCopyWith<$Res> implements $TenantBillingCopyWith<$Res> {
  factory _$TenantBillingCopyWith(_TenantBilling value, $Res Function(_TenantBilling) _then) = __$TenantBillingCopyWithImpl;
@override @useResult
$Res call({
 BillingAcademy academy, SubscriptionView? subscription, PlanView? plan, bool restricted, bool enforced, OpenPlanChange? openChange, List<UsageLine> usage, List<FeatureLine> features, List<InvoiceView> invoices, List<TenantPayment> payments, List<PlanView> plans, bool checkoutAvailable, bool trialAvailable
});


@override $BillingAcademyCopyWith<$Res> get academy;@override $SubscriptionViewCopyWith<$Res>? get subscription;@override $PlanViewCopyWith<$Res>? get plan;@override $OpenPlanChangeCopyWith<$Res>? get openChange;

}
/// @nodoc
class __$TenantBillingCopyWithImpl<$Res>
    implements _$TenantBillingCopyWith<$Res> {
  __$TenantBillingCopyWithImpl(this._self, this._then);

  final _TenantBilling _self;
  final $Res Function(_TenantBilling) _then;

/// Create a copy of TenantBilling
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? academy = null,Object? subscription = freezed,Object? plan = freezed,Object? restricted = null,Object? enforced = null,Object? openChange = freezed,Object? usage = null,Object? features = null,Object? invoices = null,Object? payments = null,Object? plans = null,Object? checkoutAvailable = null,Object? trialAvailable = null,}) {
  return _then(_TenantBilling(
academy: null == academy ? _self.academy : academy // ignore: cast_nullable_to_non_nullable
as BillingAcademy,subscription: freezed == subscription ? _self.subscription : subscription // ignore: cast_nullable_to_non_nullable
as SubscriptionView?,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as PlanView?,restricted: null == restricted ? _self.restricted : restricted // ignore: cast_nullable_to_non_nullable
as bool,enforced: null == enforced ? _self.enforced : enforced // ignore: cast_nullable_to_non_nullable
as bool,openChange: freezed == openChange ? _self.openChange : openChange // ignore: cast_nullable_to_non_nullable
as OpenPlanChange?,usage: null == usage ? _self._usage : usage // ignore: cast_nullable_to_non_nullable
as List<UsageLine>,features: null == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as List<FeatureLine>,invoices: null == invoices ? _self._invoices : invoices // ignore: cast_nullable_to_non_nullable
as List<InvoiceView>,payments: null == payments ? _self._payments : payments // ignore: cast_nullable_to_non_nullable
as List<TenantPayment>,plans: null == plans ? _self._plans : plans // ignore: cast_nullable_to_non_nullable
as List<PlanView>,checkoutAvailable: null == checkoutAvailable ? _self.checkoutAvailable : checkoutAvailable // ignore: cast_nullable_to_non_nullable
as bool,trialAvailable: null == trialAvailable ? _self.trialAvailable : trialAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of TenantBilling
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BillingAcademyCopyWith<$Res> get academy {
  
  return $BillingAcademyCopyWith<$Res>(_self.academy, (value) {
    return _then(_self.copyWith(academy: value));
  });
}/// Create a copy of TenantBilling
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubscriptionViewCopyWith<$Res>? get subscription {
    if (_self.subscription == null) {
    return null;
  }

  return $SubscriptionViewCopyWith<$Res>(_self.subscription!, (value) {
    return _then(_self.copyWith(subscription: value));
  });
}/// Create a copy of TenantBilling
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanViewCopyWith<$Res>? get plan {
    if (_self.plan == null) {
    return null;
  }

  return $PlanViewCopyWith<$Res>(_self.plan!, (value) {
    return _then(_self.copyWith(plan: value));
  });
}/// Create a copy of TenantBilling
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpenPlanChangeCopyWith<$Res>? get openChange {
    if (_self.openChange == null) {
    return null;
  }

  return $OpenPlanChangeCopyWith<$Res>(_self.openChange!, (value) {
    return _then(_self.copyWith(openChange: value));
  });
}
}


/// @nodoc
mixin _$StartedTrial {

 String get id; String get planId;@JsonKey(unknownEnumValue: SubscriptionState.unknown) SubscriptionState get status;@JsonKey(name: 'billingCycle', unknownEnumValue: BillingCycle.unknown) BillingCycle get cycle;@NullableUtcDateTimeConverter() DateTime? get trialStartAt;@NullableUtcDateTimeConverter() DateTime? get trialEndAt;
/// Create a copy of StartedTrial
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StartedTrialCopyWith<StartedTrial> get copyWith => _$StartedTrialCopyWithImpl<StartedTrial>(this as StartedTrial, _$identity);

  /// Serializes this StartedTrial to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StartedTrial&&(identical(other.id, id) || other.id == id)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.status, status) || other.status == status)&&(identical(other.cycle, cycle) || other.cycle == cycle)&&(identical(other.trialStartAt, trialStartAt) || other.trialStartAt == trialStartAt)&&(identical(other.trialEndAt, trialEndAt) || other.trialEndAt == trialEndAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,planId,status,cycle,trialStartAt,trialEndAt);

@override
String toString() {
  return 'StartedTrial(id: $id, planId: $planId, status: $status, cycle: $cycle, trialStartAt: $trialStartAt, trialEndAt: $trialEndAt)';
}


}

/// @nodoc
abstract mixin class $StartedTrialCopyWith<$Res>  {
  factory $StartedTrialCopyWith(StartedTrial value, $Res Function(StartedTrial) _then) = _$StartedTrialCopyWithImpl;
@useResult
$Res call({
 String id, String planId,@JsonKey(unknownEnumValue: SubscriptionState.unknown) SubscriptionState status,@JsonKey(name: 'billingCycle', unknownEnumValue: BillingCycle.unknown) BillingCycle cycle,@NullableUtcDateTimeConverter() DateTime? trialStartAt,@NullableUtcDateTimeConverter() DateTime? trialEndAt
});




}
/// @nodoc
class _$StartedTrialCopyWithImpl<$Res>
    implements $StartedTrialCopyWith<$Res> {
  _$StartedTrialCopyWithImpl(this._self, this._then);

  final StartedTrial _self;
  final $Res Function(StartedTrial) _then;

/// Create a copy of StartedTrial
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? planId = null,Object? status = null,Object? cycle = null,Object? trialStartAt = freezed,Object? trialEndAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubscriptionState,cycle: null == cycle ? _self.cycle : cycle // ignore: cast_nullable_to_non_nullable
as BillingCycle,trialStartAt: freezed == trialStartAt ? _self.trialStartAt : trialStartAt // ignore: cast_nullable_to_non_nullable
as DateTime?,trialEndAt: freezed == trialEndAt ? _self.trialEndAt : trialEndAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [StartedTrial].
extension StartedTrialPatterns on StartedTrial {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StartedTrial value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StartedTrial() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StartedTrial value)  $default,){
final _that = this;
switch (_that) {
case _StartedTrial():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StartedTrial value)?  $default,){
final _that = this;
switch (_that) {
case _StartedTrial() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String planId, @JsonKey(unknownEnumValue: SubscriptionState.unknown)  SubscriptionState status, @JsonKey(name: 'billingCycle', unknownEnumValue: BillingCycle.unknown)  BillingCycle cycle, @NullableUtcDateTimeConverter()  DateTime? trialStartAt, @NullableUtcDateTimeConverter()  DateTime? trialEndAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StartedTrial() when $default != null:
return $default(_that.id,_that.planId,_that.status,_that.cycle,_that.trialStartAt,_that.trialEndAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String planId, @JsonKey(unknownEnumValue: SubscriptionState.unknown)  SubscriptionState status, @JsonKey(name: 'billingCycle', unknownEnumValue: BillingCycle.unknown)  BillingCycle cycle, @NullableUtcDateTimeConverter()  DateTime? trialStartAt, @NullableUtcDateTimeConverter()  DateTime? trialEndAt)  $default,) {final _that = this;
switch (_that) {
case _StartedTrial():
return $default(_that.id,_that.planId,_that.status,_that.cycle,_that.trialStartAt,_that.trialEndAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String planId, @JsonKey(unknownEnumValue: SubscriptionState.unknown)  SubscriptionState status, @JsonKey(name: 'billingCycle', unknownEnumValue: BillingCycle.unknown)  BillingCycle cycle, @NullableUtcDateTimeConverter()  DateTime? trialStartAt, @NullableUtcDateTimeConverter()  DateTime? trialEndAt)?  $default,) {final _that = this;
switch (_that) {
case _StartedTrial() when $default != null:
return $default(_that.id,_that.planId,_that.status,_that.cycle,_that.trialStartAt,_that.trialEndAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StartedTrial implements StartedTrial {
  const _StartedTrial({this.id = '', this.planId = '', @JsonKey(unknownEnumValue: SubscriptionState.unknown) this.status = SubscriptionState.unknown, @JsonKey(name: 'billingCycle', unknownEnumValue: BillingCycle.unknown) this.cycle = BillingCycle.unknown, @NullableUtcDateTimeConverter() this.trialStartAt, @NullableUtcDateTimeConverter() this.trialEndAt});
  factory _StartedTrial.fromJson(Map<String, dynamic> json) => _$StartedTrialFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String planId;
@override@JsonKey(unknownEnumValue: SubscriptionState.unknown) final  SubscriptionState status;
@override@JsonKey(name: 'billingCycle', unknownEnumValue: BillingCycle.unknown) final  BillingCycle cycle;
@override@NullableUtcDateTimeConverter() final  DateTime? trialStartAt;
@override@NullableUtcDateTimeConverter() final  DateTime? trialEndAt;

/// Create a copy of StartedTrial
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StartedTrialCopyWith<_StartedTrial> get copyWith => __$StartedTrialCopyWithImpl<_StartedTrial>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StartedTrialToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StartedTrial&&(identical(other.id, id) || other.id == id)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.status, status) || other.status == status)&&(identical(other.cycle, cycle) || other.cycle == cycle)&&(identical(other.trialStartAt, trialStartAt) || other.trialStartAt == trialStartAt)&&(identical(other.trialEndAt, trialEndAt) || other.trialEndAt == trialEndAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,planId,status,cycle,trialStartAt,trialEndAt);

@override
String toString() {
  return 'StartedTrial(id: $id, planId: $planId, status: $status, cycle: $cycle, trialStartAt: $trialStartAt, trialEndAt: $trialEndAt)';
}


}

/// @nodoc
abstract mixin class _$StartedTrialCopyWith<$Res> implements $StartedTrialCopyWith<$Res> {
  factory _$StartedTrialCopyWith(_StartedTrial value, $Res Function(_StartedTrial) _then) = __$StartedTrialCopyWithImpl;
@override @useResult
$Res call({
 String id, String planId,@JsonKey(unknownEnumValue: SubscriptionState.unknown) SubscriptionState status,@JsonKey(name: 'billingCycle', unknownEnumValue: BillingCycle.unknown) BillingCycle cycle,@NullableUtcDateTimeConverter() DateTime? trialStartAt,@NullableUtcDateTimeConverter() DateTime? trialEndAt
});




}
/// @nodoc
class __$StartedTrialCopyWithImpl<$Res>
    implements _$StartedTrialCopyWith<$Res> {
  __$StartedTrialCopyWithImpl(this._self, this._then);

  final _StartedTrial _self;
  final $Res Function(_StartedTrial) _then;

/// Create a copy of StartedTrial
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? planId = null,Object? status = null,Object? cycle = null,Object? trialStartAt = freezed,Object? trialEndAt = freezed,}) {
  return _then(_StartedTrial(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SubscriptionState,cycle: null == cycle ? _self.cycle : cycle // ignore: cast_nullable_to_non_nullable
as BillingCycle,trialStartAt: freezed == trialStartAt ? _self.trialStartAt : trialStartAt // ignore: cast_nullable_to_non_nullable
as DateTime?,trialEndAt: freezed == trialEndAt ? _self.trialEndAt : trialEndAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$BillingAcademy {

 String get id; String get name;
/// Create a copy of BillingAcademy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillingAcademyCopyWith<BillingAcademy> get copyWith => _$BillingAcademyCopyWithImpl<BillingAcademy>(this as BillingAcademy, _$identity);

  /// Serializes this BillingAcademy to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillingAcademy&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'BillingAcademy(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $BillingAcademyCopyWith<$Res>  {
  factory $BillingAcademyCopyWith(BillingAcademy value, $Res Function(BillingAcademy) _then) = _$BillingAcademyCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$BillingAcademyCopyWithImpl<$Res>
    implements $BillingAcademyCopyWith<$Res> {
  _$BillingAcademyCopyWithImpl(this._self, this._then);

  final BillingAcademy _self;
  final $Res Function(BillingAcademy) _then;

/// Create a copy of BillingAcademy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BillingAcademy].
extension BillingAcademyPatterns on BillingAcademy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BillingAcademy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BillingAcademy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BillingAcademy value)  $default,){
final _that = this;
switch (_that) {
case _BillingAcademy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BillingAcademy value)?  $default,){
final _that = this;
switch (_that) {
case _BillingAcademy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BillingAcademy() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name)  $default,) {final _that = this;
switch (_that) {
case _BillingAcademy():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _BillingAcademy() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BillingAcademy implements BillingAcademy {
  const _BillingAcademy({this.id = '', this.name = ''});
  factory _BillingAcademy.fromJson(Map<String, dynamic> json) => _$BillingAcademyFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String name;

/// Create a copy of BillingAcademy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillingAcademyCopyWith<_BillingAcademy> get copyWith => __$BillingAcademyCopyWithImpl<_BillingAcademy>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillingAcademyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BillingAcademy&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'BillingAcademy(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$BillingAcademyCopyWith<$Res> implements $BillingAcademyCopyWith<$Res> {
  factory _$BillingAcademyCopyWith(_BillingAcademy value, $Res Function(_BillingAcademy) _then) = __$BillingAcademyCopyWithImpl;
@override @useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$BillingAcademyCopyWithImpl<$Res>
    implements _$BillingAcademyCopyWith<$Res> {
  __$BillingAcademyCopyWithImpl(this._self, this._then);

  final _BillingAcademy _self;
  final $Res Function(_BillingAcademy) _then;

/// Create a copy of BillingAcademy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_BillingAcademy(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CheckoutParams {

 String get provider; String? get keyId; String get orderId;/// Minor units — the academy's figure, never the app's.
 int get amount; String get currency; String? get redirectUrl;
/// Create a copy of CheckoutParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckoutParamsCopyWith<CheckoutParams> get copyWith => _$CheckoutParamsCopyWithImpl<CheckoutParams>(this as CheckoutParams, _$identity);

  /// Serializes this CheckoutParams to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckoutParams&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.keyId, keyId) || other.keyId == keyId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.redirectUrl, redirectUrl) || other.redirectUrl == redirectUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,keyId,orderId,amount,currency,redirectUrl);

@override
String toString() {
  return 'CheckoutParams(provider: $provider, keyId: $keyId, orderId: $orderId, amount: $amount, currency: $currency, redirectUrl: $redirectUrl)';
}


}

/// @nodoc
abstract mixin class $CheckoutParamsCopyWith<$Res>  {
  factory $CheckoutParamsCopyWith(CheckoutParams value, $Res Function(CheckoutParams) _then) = _$CheckoutParamsCopyWithImpl;
@useResult
$Res call({
 String provider, String? keyId, String orderId, int amount, String currency, String? redirectUrl
});




}
/// @nodoc
class _$CheckoutParamsCopyWithImpl<$Res>
    implements $CheckoutParamsCopyWith<$Res> {
  _$CheckoutParamsCopyWithImpl(this._self, this._then);

  final CheckoutParams _self;
  final $Res Function(CheckoutParams) _then;

/// Create a copy of CheckoutParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = null,Object? keyId = freezed,Object? orderId = null,Object? amount = null,Object? currency = null,Object? redirectUrl = freezed,}) {
  return _then(_self.copyWith(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,keyId: freezed == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String?,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,redirectUrl: freezed == redirectUrl ? _self.redirectUrl : redirectUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckoutParams].
extension CheckoutParamsPatterns on CheckoutParams {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckoutParams value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckoutParams() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckoutParams value)  $default,){
final _that = this;
switch (_that) {
case _CheckoutParams():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckoutParams value)?  $default,){
final _that = this;
switch (_that) {
case _CheckoutParams() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String provider,  String? keyId,  String orderId,  int amount,  String currency,  String? redirectUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckoutParams() when $default != null:
return $default(_that.provider,_that.keyId,_that.orderId,_that.amount,_that.currency,_that.redirectUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String provider,  String? keyId,  String orderId,  int amount,  String currency,  String? redirectUrl)  $default,) {final _that = this;
switch (_that) {
case _CheckoutParams():
return $default(_that.provider,_that.keyId,_that.orderId,_that.amount,_that.currency,_that.redirectUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String provider,  String? keyId,  String orderId,  int amount,  String currency,  String? redirectUrl)?  $default,) {final _that = this;
switch (_that) {
case _CheckoutParams() when $default != null:
return $default(_that.provider,_that.keyId,_that.orderId,_that.amount,_that.currency,_that.redirectUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckoutParams implements CheckoutParams {
  const _CheckoutParams({this.provider = '', this.keyId, this.orderId = '', this.amount = 0, this.currency = 'INR', this.redirectUrl});
  factory _CheckoutParams.fromJson(Map<String, dynamic> json) => _$CheckoutParamsFromJson(json);

@override@JsonKey() final  String provider;
@override final  String? keyId;
@override@JsonKey() final  String orderId;
/// Minor units — the academy's figure, never the app's.
@override@JsonKey() final  int amount;
@override@JsonKey() final  String currency;
@override final  String? redirectUrl;

/// Create a copy of CheckoutParams
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckoutParamsCopyWith<_CheckoutParams> get copyWith => __$CheckoutParamsCopyWithImpl<_CheckoutParams>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckoutParamsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckoutParams&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.keyId, keyId) || other.keyId == keyId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.redirectUrl, redirectUrl) || other.redirectUrl == redirectUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,keyId,orderId,amount,currency,redirectUrl);

@override
String toString() {
  return 'CheckoutParams(provider: $provider, keyId: $keyId, orderId: $orderId, amount: $amount, currency: $currency, redirectUrl: $redirectUrl)';
}


}

/// @nodoc
abstract mixin class _$CheckoutParamsCopyWith<$Res> implements $CheckoutParamsCopyWith<$Res> {
  factory _$CheckoutParamsCopyWith(_CheckoutParams value, $Res Function(_CheckoutParams) _then) = __$CheckoutParamsCopyWithImpl;
@override @useResult
$Res call({
 String provider, String? keyId, String orderId, int amount, String currency, String? redirectUrl
});




}
/// @nodoc
class __$CheckoutParamsCopyWithImpl<$Res>
    implements _$CheckoutParamsCopyWith<$Res> {
  __$CheckoutParamsCopyWithImpl(this._self, this._then);

  final _CheckoutParams _self;
  final $Res Function(_CheckoutParams) _then;

/// Create a copy of CheckoutParams
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? keyId = freezed,Object? orderId = null,Object? amount = null,Object? currency = null,Object? redirectUrl = freezed,}) {
  return _then(_CheckoutParams(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,keyId: freezed == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String?,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,redirectUrl: freezed == redirectUrl ? _self.redirectUrl : redirectUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CheckoutInvoice {

 String get id; String get number; int get total; String get currency;
/// Create a copy of CheckoutInvoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckoutInvoiceCopyWith<CheckoutInvoice> get copyWith => _$CheckoutInvoiceCopyWithImpl<CheckoutInvoice>(this as CheckoutInvoice, _$identity);

  /// Serializes this CheckoutInvoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckoutInvoice&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.total, total) || other.total == total)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,total,currency);

@override
String toString() {
  return 'CheckoutInvoice(id: $id, number: $number, total: $total, currency: $currency)';
}


}

/// @nodoc
abstract mixin class $CheckoutInvoiceCopyWith<$Res>  {
  factory $CheckoutInvoiceCopyWith(CheckoutInvoice value, $Res Function(CheckoutInvoice) _then) = _$CheckoutInvoiceCopyWithImpl;
@useResult
$Res call({
 String id, String number, int total, String currency
});




}
/// @nodoc
class _$CheckoutInvoiceCopyWithImpl<$Res>
    implements $CheckoutInvoiceCopyWith<$Res> {
  _$CheckoutInvoiceCopyWithImpl(this._self, this._then);

  final CheckoutInvoice _self;
  final $Res Function(CheckoutInvoice) _then;

/// Create a copy of CheckoutInvoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? total = null,Object? currency = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckoutInvoice].
extension CheckoutInvoicePatterns on CheckoutInvoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckoutInvoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckoutInvoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckoutInvoice value)  $default,){
final _that = this;
switch (_that) {
case _CheckoutInvoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckoutInvoice value)?  $default,){
final _that = this;
switch (_that) {
case _CheckoutInvoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String number,  int total,  String currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckoutInvoice() when $default != null:
return $default(_that.id,_that.number,_that.total,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String number,  int total,  String currency)  $default,) {final _that = this;
switch (_that) {
case _CheckoutInvoice():
return $default(_that.id,_that.number,_that.total,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String number,  int total,  String currency)?  $default,) {final _that = this;
switch (_that) {
case _CheckoutInvoice() when $default != null:
return $default(_that.id,_that.number,_that.total,_that.currency);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckoutInvoice implements CheckoutInvoice {
  const _CheckoutInvoice({this.id = '', this.number = '', this.total = 0, this.currency = 'INR'});
  factory _CheckoutInvoice.fromJson(Map<String, dynamic> json) => _$CheckoutInvoiceFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String number;
@override@JsonKey() final  int total;
@override@JsonKey() final  String currency;

/// Create a copy of CheckoutInvoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckoutInvoiceCopyWith<_CheckoutInvoice> get copyWith => __$CheckoutInvoiceCopyWithImpl<_CheckoutInvoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckoutInvoiceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckoutInvoice&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.total, total) || other.total == total)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,total,currency);

@override
String toString() {
  return 'CheckoutInvoice(id: $id, number: $number, total: $total, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$CheckoutInvoiceCopyWith<$Res> implements $CheckoutInvoiceCopyWith<$Res> {
  factory _$CheckoutInvoiceCopyWith(_CheckoutInvoice value, $Res Function(_CheckoutInvoice) _then) = __$CheckoutInvoiceCopyWithImpl;
@override @useResult
$Res call({
 String id, String number, int total, String currency
});




}
/// @nodoc
class __$CheckoutInvoiceCopyWithImpl<$Res>
    implements _$CheckoutInvoiceCopyWith<$Res> {
  __$CheckoutInvoiceCopyWithImpl(this._self, this._then);

  final _CheckoutInvoice _self;
  final $Res Function(_CheckoutInvoice) _then;

/// Create a copy of CheckoutInvoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? total = null,Object? currency = null,}) {
  return _then(_CheckoutInvoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CheckoutStart {

 CheckoutParams get checkout; CheckoutInvoice get invoice;
/// Create a copy of CheckoutStart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckoutStartCopyWith<CheckoutStart> get copyWith => _$CheckoutStartCopyWithImpl<CheckoutStart>(this as CheckoutStart, _$identity);

  /// Serializes this CheckoutStart to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckoutStart&&(identical(other.checkout, checkout) || other.checkout == checkout)&&(identical(other.invoice, invoice) || other.invoice == invoice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,checkout,invoice);

@override
String toString() {
  return 'CheckoutStart(checkout: $checkout, invoice: $invoice)';
}


}

/// @nodoc
abstract mixin class $CheckoutStartCopyWith<$Res>  {
  factory $CheckoutStartCopyWith(CheckoutStart value, $Res Function(CheckoutStart) _then) = _$CheckoutStartCopyWithImpl;
@useResult
$Res call({
 CheckoutParams checkout, CheckoutInvoice invoice
});


$CheckoutParamsCopyWith<$Res> get checkout;$CheckoutInvoiceCopyWith<$Res> get invoice;

}
/// @nodoc
class _$CheckoutStartCopyWithImpl<$Res>
    implements $CheckoutStartCopyWith<$Res> {
  _$CheckoutStartCopyWithImpl(this._self, this._then);

  final CheckoutStart _self;
  final $Res Function(CheckoutStart) _then;

/// Create a copy of CheckoutStart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? checkout = null,Object? invoice = null,}) {
  return _then(_self.copyWith(
checkout: null == checkout ? _self.checkout : checkout // ignore: cast_nullable_to_non_nullable
as CheckoutParams,invoice: null == invoice ? _self.invoice : invoice // ignore: cast_nullable_to_non_nullable
as CheckoutInvoice,
  ));
}
/// Create a copy of CheckoutStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CheckoutParamsCopyWith<$Res> get checkout {
  
  return $CheckoutParamsCopyWith<$Res>(_self.checkout, (value) {
    return _then(_self.copyWith(checkout: value));
  });
}/// Create a copy of CheckoutStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CheckoutInvoiceCopyWith<$Res> get invoice {
  
  return $CheckoutInvoiceCopyWith<$Res>(_self.invoice, (value) {
    return _then(_self.copyWith(invoice: value));
  });
}
}


/// Adds pattern-matching-related methods to [CheckoutStart].
extension CheckoutStartPatterns on CheckoutStart {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckoutStart value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckoutStart() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckoutStart value)  $default,){
final _that = this;
switch (_that) {
case _CheckoutStart():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckoutStart value)?  $default,){
final _that = this;
switch (_that) {
case _CheckoutStart() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CheckoutParams checkout,  CheckoutInvoice invoice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckoutStart() when $default != null:
return $default(_that.checkout,_that.invoice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CheckoutParams checkout,  CheckoutInvoice invoice)  $default,) {final _that = this;
switch (_that) {
case _CheckoutStart():
return $default(_that.checkout,_that.invoice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CheckoutParams checkout,  CheckoutInvoice invoice)?  $default,) {final _that = this;
switch (_that) {
case _CheckoutStart() when $default != null:
return $default(_that.checkout,_that.invoice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckoutStart implements CheckoutStart {
  const _CheckoutStart({this.checkout = const CheckoutParams(), this.invoice = const CheckoutInvoice()});
  factory _CheckoutStart.fromJson(Map<String, dynamic> json) => _$CheckoutStartFromJson(json);

@override@JsonKey() final  CheckoutParams checkout;
@override@JsonKey() final  CheckoutInvoice invoice;

/// Create a copy of CheckoutStart
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckoutStartCopyWith<_CheckoutStart> get copyWith => __$CheckoutStartCopyWithImpl<_CheckoutStart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckoutStartToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckoutStart&&(identical(other.checkout, checkout) || other.checkout == checkout)&&(identical(other.invoice, invoice) || other.invoice == invoice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,checkout,invoice);

@override
String toString() {
  return 'CheckoutStart(checkout: $checkout, invoice: $invoice)';
}


}

/// @nodoc
abstract mixin class _$CheckoutStartCopyWith<$Res> implements $CheckoutStartCopyWith<$Res> {
  factory _$CheckoutStartCopyWith(_CheckoutStart value, $Res Function(_CheckoutStart) _then) = __$CheckoutStartCopyWithImpl;
@override @useResult
$Res call({
 CheckoutParams checkout, CheckoutInvoice invoice
});


@override $CheckoutParamsCopyWith<$Res> get checkout;@override $CheckoutInvoiceCopyWith<$Res> get invoice;

}
/// @nodoc
class __$CheckoutStartCopyWithImpl<$Res>
    implements _$CheckoutStartCopyWith<$Res> {
  __$CheckoutStartCopyWithImpl(this._self, this._then);

  final _CheckoutStart _self;
  final $Res Function(_CheckoutStart) _then;

/// Create a copy of CheckoutStart
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? checkout = null,Object? invoice = null,}) {
  return _then(_CheckoutStart(
checkout: null == checkout ? _self.checkout : checkout // ignore: cast_nullable_to_non_nullable
as CheckoutParams,invoice: null == invoice ? _self.invoice : invoice // ignore: cast_nullable_to_non_nullable
as CheckoutInvoice,
  ));
}

/// Create a copy of CheckoutStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CheckoutParamsCopyWith<$Res> get checkout {
  
  return $CheckoutParamsCopyWith<$Res>(_self.checkout, (value) {
    return _then(_self.copyWith(checkout: value));
  });
}/// Create a copy of CheckoutStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CheckoutInvoiceCopyWith<$Res> get invoice {
  
  return $CheckoutInvoiceCopyWith<$Res>(_self.invoice, (value) {
    return _then(_self.copyWith(invoice: value));
  });
}
}


/// @nodoc
mixin _$CheckoutOutcome {

@JsonKey(unknownEnumValue: ProviderPaymentStatus.unknown) ProviderPaymentStatus get status;/// Whether this call settled the invoice.
 bool get settled;/// Whether the subscription moved as the invoice was for.
 bool get applied; String get message;
/// Create a copy of CheckoutOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckoutOutcomeCopyWith<CheckoutOutcome> get copyWith => _$CheckoutOutcomeCopyWithImpl<CheckoutOutcome>(this as CheckoutOutcome, _$identity);

  /// Serializes this CheckoutOutcome to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckoutOutcome&&(identical(other.status, status) || other.status == status)&&(identical(other.settled, settled) || other.settled == settled)&&(identical(other.applied, applied) || other.applied == applied)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,settled,applied,message);

@override
String toString() {
  return 'CheckoutOutcome(status: $status, settled: $settled, applied: $applied, message: $message)';
}


}

/// @nodoc
abstract mixin class $CheckoutOutcomeCopyWith<$Res>  {
  factory $CheckoutOutcomeCopyWith(CheckoutOutcome value, $Res Function(CheckoutOutcome) _then) = _$CheckoutOutcomeCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: ProviderPaymentStatus.unknown) ProviderPaymentStatus status, bool settled, bool applied, String message
});




}
/// @nodoc
class _$CheckoutOutcomeCopyWithImpl<$Res>
    implements $CheckoutOutcomeCopyWith<$Res> {
  _$CheckoutOutcomeCopyWithImpl(this._self, this._then);

  final CheckoutOutcome _self;
  final $Res Function(CheckoutOutcome) _then;

/// Create a copy of CheckoutOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? settled = null,Object? applied = null,Object? message = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProviderPaymentStatus,settled: null == settled ? _self.settled : settled // ignore: cast_nullable_to_non_nullable
as bool,applied: null == applied ? _self.applied : applied // ignore: cast_nullable_to_non_nullable
as bool,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckoutOutcome].
extension CheckoutOutcomePatterns on CheckoutOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckoutOutcome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckoutOutcome() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckoutOutcome value)  $default,){
final _that = this;
switch (_that) {
case _CheckoutOutcome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckoutOutcome value)?  $default,){
final _that = this;
switch (_that) {
case _CheckoutOutcome() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: ProviderPaymentStatus.unknown)  ProviderPaymentStatus status,  bool settled,  bool applied,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckoutOutcome() when $default != null:
return $default(_that.status,_that.settled,_that.applied,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: ProviderPaymentStatus.unknown)  ProviderPaymentStatus status,  bool settled,  bool applied,  String message)  $default,) {final _that = this;
switch (_that) {
case _CheckoutOutcome():
return $default(_that.status,_that.settled,_that.applied,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: ProviderPaymentStatus.unknown)  ProviderPaymentStatus status,  bool settled,  bool applied,  String message)?  $default,) {final _that = this;
switch (_that) {
case _CheckoutOutcome() when $default != null:
return $default(_that.status,_that.settled,_that.applied,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckoutOutcome extends CheckoutOutcome {
  const _CheckoutOutcome({@JsonKey(unknownEnumValue: ProviderPaymentStatus.unknown) this.status = ProviderPaymentStatus.unknown, this.settled = false, this.applied = false, this.message = ''}): super._();
  factory _CheckoutOutcome.fromJson(Map<String, dynamic> json) => _$CheckoutOutcomeFromJson(json);

@override@JsonKey(unknownEnumValue: ProviderPaymentStatus.unknown) final  ProviderPaymentStatus status;
/// Whether this call settled the invoice.
@override@JsonKey() final  bool settled;
/// Whether the subscription moved as the invoice was for.
@override@JsonKey() final  bool applied;
@override@JsonKey() final  String message;

/// Create a copy of CheckoutOutcome
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckoutOutcomeCopyWith<_CheckoutOutcome> get copyWith => __$CheckoutOutcomeCopyWithImpl<_CheckoutOutcome>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckoutOutcomeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckoutOutcome&&(identical(other.status, status) || other.status == status)&&(identical(other.settled, settled) || other.settled == settled)&&(identical(other.applied, applied) || other.applied == applied)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,settled,applied,message);

@override
String toString() {
  return 'CheckoutOutcome(status: $status, settled: $settled, applied: $applied, message: $message)';
}


}

/// @nodoc
abstract mixin class _$CheckoutOutcomeCopyWith<$Res> implements $CheckoutOutcomeCopyWith<$Res> {
  factory _$CheckoutOutcomeCopyWith(_CheckoutOutcome value, $Res Function(_CheckoutOutcome) _then) = __$CheckoutOutcomeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: ProviderPaymentStatus.unknown) ProviderPaymentStatus status, bool settled, bool applied, String message
});




}
/// @nodoc
class __$CheckoutOutcomeCopyWithImpl<$Res>
    implements _$CheckoutOutcomeCopyWith<$Res> {
  __$CheckoutOutcomeCopyWithImpl(this._self, this._then);

  final _CheckoutOutcome _self;
  final $Res Function(_CheckoutOutcome) _then;

/// Create a copy of CheckoutOutcome
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? settled = null,Object? applied = null,Object? message = null,}) {
  return _then(_CheckoutOutcome(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProviderPaymentStatus,settled: null == settled ? _self.settled : settled // ignore: cast_nullable_to_non_nullable
as bool,applied: null == applied ? _self.applied : applied // ignore: cast_nullable_to_non_nullable
as bool,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TaxLine {

 String get code; String get label; int get rateBps; int get amount;
/// Create a copy of TaxLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaxLineCopyWith<TaxLine> get copyWith => _$TaxLineCopyWithImpl<TaxLine>(this as TaxLine, _$identity);

  /// Serializes this TaxLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaxLine&&(identical(other.code, code) || other.code == code)&&(identical(other.label, label) || other.label == label)&&(identical(other.rateBps, rateBps) || other.rateBps == rateBps)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,label,rateBps,amount);

@override
String toString() {
  return 'TaxLine(code: $code, label: $label, rateBps: $rateBps, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $TaxLineCopyWith<$Res>  {
  factory $TaxLineCopyWith(TaxLine value, $Res Function(TaxLine) _then) = _$TaxLineCopyWithImpl;
@useResult
$Res call({
 String code, String label, int rateBps, int amount
});




}
/// @nodoc
class _$TaxLineCopyWithImpl<$Res>
    implements $TaxLineCopyWith<$Res> {
  _$TaxLineCopyWithImpl(this._self, this._then);

  final TaxLine _self;
  final $Res Function(TaxLine) _then;

/// Create a copy of TaxLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? label = null,Object? rateBps = null,Object? amount = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,rateBps: null == rateBps ? _self.rateBps : rateBps // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TaxLine].
extension TaxLinePatterns on TaxLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaxLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaxLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaxLine value)  $default,){
final _that = this;
switch (_that) {
case _TaxLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaxLine value)?  $default,){
final _that = this;
switch (_that) {
case _TaxLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String label,  int rateBps,  int amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaxLine() when $default != null:
return $default(_that.code,_that.label,_that.rateBps,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String label,  int rateBps,  int amount)  $default,) {final _that = this;
switch (_that) {
case _TaxLine():
return $default(_that.code,_that.label,_that.rateBps,_that.amount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String label,  int rateBps,  int amount)?  $default,) {final _that = this;
switch (_that) {
case _TaxLine() when $default != null:
return $default(_that.code,_that.label,_that.rateBps,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaxLine implements TaxLine {
  const _TaxLine({this.code = '', this.label = '', this.rateBps = 0, this.amount = 0});
  factory _TaxLine.fromJson(Map<String, dynamic> json) => _$TaxLineFromJson(json);

@override@JsonKey() final  String code;
@override@JsonKey() final  String label;
@override@JsonKey() final  int rateBps;
@override@JsonKey() final  int amount;

/// Create a copy of TaxLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaxLineCopyWith<_TaxLine> get copyWith => __$TaxLineCopyWithImpl<_TaxLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaxLineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaxLine&&(identical(other.code, code) || other.code == code)&&(identical(other.label, label) || other.label == label)&&(identical(other.rateBps, rateBps) || other.rateBps == rateBps)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,label,rateBps,amount);

@override
String toString() {
  return 'TaxLine(code: $code, label: $label, rateBps: $rateBps, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$TaxLineCopyWith<$Res> implements $TaxLineCopyWith<$Res> {
  factory _$TaxLineCopyWith(_TaxLine value, $Res Function(_TaxLine) _then) = __$TaxLineCopyWithImpl;
@override @useResult
$Res call({
 String code, String label, int rateBps, int amount
});




}
/// @nodoc
class __$TaxLineCopyWithImpl<$Res>
    implements _$TaxLineCopyWith<$Res> {
  __$TaxLineCopyWithImpl(this._self, this._then);

  final _TaxLine _self;
  final $Res Function(_TaxLine) _then;

/// Create a copy of TaxLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? label = null,Object? rateBps = null,Object? amount = null,}) {
  return _then(_TaxLine(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,rateBps: null == rateBps ? _self.rateBps : rateBps // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PayableQuote {

 String get currency; int get net; List<TaxLine> get lines; int get tax; int get gross; bool get inclusive; String get purpose;
/// Create a copy of PayableQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayableQuoteCopyWith<PayableQuote> get copyWith => _$PayableQuoteCopyWithImpl<PayableQuote>(this as PayableQuote, _$identity);

  /// Serializes this PayableQuote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayableQuote&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.net, net) || other.net == net)&&const DeepCollectionEquality().equals(other.lines, lines)&&(identical(other.tax, tax) || other.tax == tax)&&(identical(other.gross, gross) || other.gross == gross)&&(identical(other.inclusive, inclusive) || other.inclusive == inclusive)&&(identical(other.purpose, purpose) || other.purpose == purpose));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currency,net,const DeepCollectionEquality().hash(lines),tax,gross,inclusive,purpose);

@override
String toString() {
  return 'PayableQuote(currency: $currency, net: $net, lines: $lines, tax: $tax, gross: $gross, inclusive: $inclusive, purpose: $purpose)';
}


}

/// @nodoc
abstract mixin class $PayableQuoteCopyWith<$Res>  {
  factory $PayableQuoteCopyWith(PayableQuote value, $Res Function(PayableQuote) _then) = _$PayableQuoteCopyWithImpl;
@useResult
$Res call({
 String currency, int net, List<TaxLine> lines, int tax, int gross, bool inclusive, String purpose
});




}
/// @nodoc
class _$PayableQuoteCopyWithImpl<$Res>
    implements $PayableQuoteCopyWith<$Res> {
  _$PayableQuoteCopyWithImpl(this._self, this._then);

  final PayableQuote _self;
  final $Res Function(PayableQuote) _then;

/// Create a copy of PayableQuote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currency = null,Object? net = null,Object? lines = null,Object? tax = null,Object? gross = null,Object? inclusive = null,Object? purpose = null,}) {
  return _then(_self.copyWith(
currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<TaxLine>,tax: null == tax ? _self.tax : tax // ignore: cast_nullable_to_non_nullable
as int,gross: null == gross ? _self.gross : gross // ignore: cast_nullable_to_non_nullable
as int,inclusive: null == inclusive ? _self.inclusive : inclusive // ignore: cast_nullable_to_non_nullable
as bool,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PayableQuote].
extension PayableQuotePatterns on PayableQuote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PayableQuote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PayableQuote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PayableQuote value)  $default,){
final _that = this;
switch (_that) {
case _PayableQuote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PayableQuote value)?  $default,){
final _that = this;
switch (_that) {
case _PayableQuote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String currency,  int net,  List<TaxLine> lines,  int tax,  int gross,  bool inclusive,  String purpose)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PayableQuote() when $default != null:
return $default(_that.currency,_that.net,_that.lines,_that.tax,_that.gross,_that.inclusive,_that.purpose);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String currency,  int net,  List<TaxLine> lines,  int tax,  int gross,  bool inclusive,  String purpose)  $default,) {final _that = this;
switch (_that) {
case _PayableQuote():
return $default(_that.currency,_that.net,_that.lines,_that.tax,_that.gross,_that.inclusive,_that.purpose);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String currency,  int net,  List<TaxLine> lines,  int tax,  int gross,  bool inclusive,  String purpose)?  $default,) {final _that = this;
switch (_that) {
case _PayableQuote() when $default != null:
return $default(_that.currency,_that.net,_that.lines,_that.tax,_that.gross,_that.inclusive,_that.purpose);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PayableQuote implements PayableQuote {
  const _PayableQuote({this.currency = 'INR', this.net = 0, final  List<TaxLine> lines = const <TaxLine>[], this.tax = 0, this.gross = 0, this.inclusive = false, this.purpose = ''}): _lines = lines;
  factory _PayableQuote.fromJson(Map<String, dynamic> json) => _$PayableQuoteFromJson(json);

@override@JsonKey() final  String currency;
@override@JsonKey() final  int net;
 final  List<TaxLine> _lines;
@override@JsonKey() List<TaxLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

@override@JsonKey() final  int tax;
@override@JsonKey() final  int gross;
@override@JsonKey() final  bool inclusive;
@override@JsonKey() final  String purpose;

/// Create a copy of PayableQuote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayableQuoteCopyWith<_PayableQuote> get copyWith => __$PayableQuoteCopyWithImpl<_PayableQuote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PayableQuoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayableQuote&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.net, net) || other.net == net)&&const DeepCollectionEquality().equals(other._lines, _lines)&&(identical(other.tax, tax) || other.tax == tax)&&(identical(other.gross, gross) || other.gross == gross)&&(identical(other.inclusive, inclusive) || other.inclusive == inclusive)&&(identical(other.purpose, purpose) || other.purpose == purpose));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currency,net,const DeepCollectionEquality().hash(_lines),tax,gross,inclusive,purpose);

@override
String toString() {
  return 'PayableQuote(currency: $currency, net: $net, lines: $lines, tax: $tax, gross: $gross, inclusive: $inclusive, purpose: $purpose)';
}


}

/// @nodoc
abstract mixin class _$PayableQuoteCopyWith<$Res> implements $PayableQuoteCopyWith<$Res> {
  factory _$PayableQuoteCopyWith(_PayableQuote value, $Res Function(_PayableQuote) _then) = __$PayableQuoteCopyWithImpl;
@override @useResult
$Res call({
 String currency, int net, List<TaxLine> lines, int tax, int gross, bool inclusive, String purpose
});




}
/// @nodoc
class __$PayableQuoteCopyWithImpl<$Res>
    implements _$PayableQuoteCopyWith<$Res> {
  __$PayableQuoteCopyWithImpl(this._self, this._then);

  final _PayableQuote _self;
  final $Res Function(_PayableQuote) _then;

/// Create a copy of PayableQuote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currency = null,Object? net = null,Object? lines = null,Object? tax = null,Object? gross = null,Object? inclusive = null,Object? purpose = null,}) {
  return _then(_PayableQuote(
currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<TaxLine>,tax: null == tax ? _self.tax : tax // ignore: cast_nullable_to_non_nullable
as int,gross: null == gross ? _self.gross : gross // ignore: cast_nullable_to_non_nullable
as int,inclusive: null == inclusive ? _self.inclusive : inclusive // ignore: cast_nullable_to_non_nullable
as bool,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PlanChangeStart {

 OpenPlanChange get change; PayableQuote? get payable;
/// Create a copy of PlanChangeStart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanChangeStartCopyWith<PlanChangeStart> get copyWith => _$PlanChangeStartCopyWithImpl<PlanChangeStart>(this as PlanChangeStart, _$identity);

  /// Serializes this PlanChangeStart to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanChangeStart&&(identical(other.change, change) || other.change == change)&&(identical(other.payable, payable) || other.payable == payable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,change,payable);

@override
String toString() {
  return 'PlanChangeStart(change: $change, payable: $payable)';
}


}

/// @nodoc
abstract mixin class $PlanChangeStartCopyWith<$Res>  {
  factory $PlanChangeStartCopyWith(PlanChangeStart value, $Res Function(PlanChangeStart) _then) = _$PlanChangeStartCopyWithImpl;
@useResult
$Res call({
 OpenPlanChange change, PayableQuote? payable
});


$OpenPlanChangeCopyWith<$Res> get change;$PayableQuoteCopyWith<$Res>? get payable;

}
/// @nodoc
class _$PlanChangeStartCopyWithImpl<$Res>
    implements $PlanChangeStartCopyWith<$Res> {
  _$PlanChangeStartCopyWithImpl(this._self, this._then);

  final PlanChangeStart _self;
  final $Res Function(PlanChangeStart) _then;

/// Create a copy of PlanChangeStart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? change = null,Object? payable = freezed,}) {
  return _then(_self.copyWith(
change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as OpenPlanChange,payable: freezed == payable ? _self.payable : payable // ignore: cast_nullable_to_non_nullable
as PayableQuote?,
  ));
}
/// Create a copy of PlanChangeStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpenPlanChangeCopyWith<$Res> get change {
  
  return $OpenPlanChangeCopyWith<$Res>(_self.change, (value) {
    return _then(_self.copyWith(change: value));
  });
}/// Create a copy of PlanChangeStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PayableQuoteCopyWith<$Res>? get payable {
    if (_self.payable == null) {
    return null;
  }

  return $PayableQuoteCopyWith<$Res>(_self.payable!, (value) {
    return _then(_self.copyWith(payable: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlanChangeStart].
extension PlanChangeStartPatterns on PlanChangeStart {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanChangeStart value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanChangeStart() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanChangeStart value)  $default,){
final _that = this;
switch (_that) {
case _PlanChangeStart():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanChangeStart value)?  $default,){
final _that = this;
switch (_that) {
case _PlanChangeStart() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OpenPlanChange change,  PayableQuote? payable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanChangeStart() when $default != null:
return $default(_that.change,_that.payable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OpenPlanChange change,  PayableQuote? payable)  $default,) {final _that = this;
switch (_that) {
case _PlanChangeStart():
return $default(_that.change,_that.payable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OpenPlanChange change,  PayableQuote? payable)?  $default,) {final _that = this;
switch (_that) {
case _PlanChangeStart() when $default != null:
return $default(_that.change,_that.payable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanChangeStart implements PlanChangeStart {
  const _PlanChangeStart({required this.change, this.payable});
  factory _PlanChangeStart.fromJson(Map<String, dynamic> json) => _$PlanChangeStartFromJson(json);

@override final  OpenPlanChange change;
@override final  PayableQuote? payable;

/// Create a copy of PlanChangeStart
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanChangeStartCopyWith<_PlanChangeStart> get copyWith => __$PlanChangeStartCopyWithImpl<_PlanChangeStart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanChangeStartToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanChangeStart&&(identical(other.change, change) || other.change == change)&&(identical(other.payable, payable) || other.payable == payable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,change,payable);

@override
String toString() {
  return 'PlanChangeStart(change: $change, payable: $payable)';
}


}

/// @nodoc
abstract mixin class _$PlanChangeStartCopyWith<$Res> implements $PlanChangeStartCopyWith<$Res> {
  factory _$PlanChangeStartCopyWith(_PlanChangeStart value, $Res Function(_PlanChangeStart) _then) = __$PlanChangeStartCopyWithImpl;
@override @useResult
$Res call({
 OpenPlanChange change, PayableQuote? payable
});


@override $OpenPlanChangeCopyWith<$Res> get change;@override $PayableQuoteCopyWith<$Res>? get payable;

}
/// @nodoc
class __$PlanChangeStartCopyWithImpl<$Res>
    implements _$PlanChangeStartCopyWith<$Res> {
  __$PlanChangeStartCopyWithImpl(this._self, this._then);

  final _PlanChangeStart _self;
  final $Res Function(_PlanChangeStart) _then;

/// Create a copy of PlanChangeStart
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? change = null,Object? payable = freezed,}) {
  return _then(_PlanChangeStart(
change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as OpenPlanChange,payable: freezed == payable ? _self.payable : payable // ignore: cast_nullable_to_non_nullable
as PayableQuote?,
  ));
}

/// Create a copy of PlanChangeStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpenPlanChangeCopyWith<$Res> get change {
  
  return $OpenPlanChangeCopyWith<$Res>(_self.change, (value) {
    return _then(_self.copyWith(change: value));
  });
}/// Create a copy of PlanChangeStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PayableQuoteCopyWith<$Res>? get payable {
    if (_self.payable == null) {
    return null;
  }

  return $PayableQuoteCopyWith<$Res>(_self.payable!, (value) {
    return _then(_self.copyWith(payable: value));
  });
}
}


/// @nodoc
mixin _$PreviewTarget {

 String get planId; String get planName;@JsonKey(unknownEnumValue: BillingCycle.unknown) BillingCycle get cycle; int get amount;
/// Create a copy of PreviewTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreviewTargetCopyWith<PreviewTarget> get copyWith => _$PreviewTargetCopyWithImpl<PreviewTarget>(this as PreviewTarget, _$identity);

  /// Serializes this PreviewTarget to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreviewTarget&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.planName, planName) || other.planName == planName)&&(identical(other.cycle, cycle) || other.cycle == cycle)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,planId,planName,cycle,amount);

@override
String toString() {
  return 'PreviewTarget(planId: $planId, planName: $planName, cycle: $cycle, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $PreviewTargetCopyWith<$Res>  {
  factory $PreviewTargetCopyWith(PreviewTarget value, $Res Function(PreviewTarget) _then) = _$PreviewTargetCopyWithImpl;
@useResult
$Res call({
 String planId, String planName,@JsonKey(unknownEnumValue: BillingCycle.unknown) BillingCycle cycle, int amount
});




}
/// @nodoc
class _$PreviewTargetCopyWithImpl<$Res>
    implements $PreviewTargetCopyWith<$Res> {
  _$PreviewTargetCopyWithImpl(this._self, this._then);

  final PreviewTarget _self;
  final $Res Function(PreviewTarget) _then;

/// Create a copy of PreviewTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? planId = null,Object? planName = null,Object? cycle = null,Object? amount = null,}) {
  return _then(_self.copyWith(
planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,planName: null == planName ? _self.planName : planName // ignore: cast_nullable_to_non_nullable
as String,cycle: null == cycle ? _self.cycle : cycle // ignore: cast_nullable_to_non_nullable
as BillingCycle,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PreviewTarget].
extension PreviewTargetPatterns on PreviewTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PreviewTarget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PreviewTarget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PreviewTarget value)  $default,){
final _that = this;
switch (_that) {
case _PreviewTarget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PreviewTarget value)?  $default,){
final _that = this;
switch (_that) {
case _PreviewTarget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String planId,  String planName, @JsonKey(unknownEnumValue: BillingCycle.unknown)  BillingCycle cycle,  int amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PreviewTarget() when $default != null:
return $default(_that.planId,_that.planName,_that.cycle,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String planId,  String planName, @JsonKey(unknownEnumValue: BillingCycle.unknown)  BillingCycle cycle,  int amount)  $default,) {final _that = this;
switch (_that) {
case _PreviewTarget():
return $default(_that.planId,_that.planName,_that.cycle,_that.amount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String planId,  String planName, @JsonKey(unknownEnumValue: BillingCycle.unknown)  BillingCycle cycle,  int amount)?  $default,) {final _that = this;
switch (_that) {
case _PreviewTarget() when $default != null:
return $default(_that.planId,_that.planName,_that.cycle,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PreviewTarget implements PreviewTarget {
  const _PreviewTarget({this.planId = '', this.planName = '', @JsonKey(unknownEnumValue: BillingCycle.unknown) this.cycle = BillingCycle.unknown, this.amount = 0});
  factory _PreviewTarget.fromJson(Map<String, dynamic> json) => _$PreviewTargetFromJson(json);

@override@JsonKey() final  String planId;
@override@JsonKey() final  String planName;
@override@JsonKey(unknownEnumValue: BillingCycle.unknown) final  BillingCycle cycle;
@override@JsonKey() final  int amount;

/// Create a copy of PreviewTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreviewTargetCopyWith<_PreviewTarget> get copyWith => __$PreviewTargetCopyWithImpl<_PreviewTarget>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PreviewTargetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PreviewTarget&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.planName, planName) || other.planName == planName)&&(identical(other.cycle, cycle) || other.cycle == cycle)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,planId,planName,cycle,amount);

@override
String toString() {
  return 'PreviewTarget(planId: $planId, planName: $planName, cycle: $cycle, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$PreviewTargetCopyWith<$Res> implements $PreviewTargetCopyWith<$Res> {
  factory _$PreviewTargetCopyWith(_PreviewTarget value, $Res Function(_PreviewTarget) _then) = __$PreviewTargetCopyWithImpl;
@override @useResult
$Res call({
 String planId, String planName,@JsonKey(unknownEnumValue: BillingCycle.unknown) BillingCycle cycle, int amount
});




}
/// @nodoc
class __$PreviewTargetCopyWithImpl<$Res>
    implements _$PreviewTargetCopyWith<$Res> {
  __$PreviewTargetCopyWithImpl(this._self, this._then);

  final _PreviewTarget _self;
  final $Res Function(_PreviewTarget) _then;

/// Create a copy of PreviewTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? planId = null,Object? planName = null,Object? cycle = null,Object? amount = null,}) {
  return _then(_PreviewTarget(
planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,planName: null == planName ? _self.planName : planName // ignore: cast_nullable_to_non_nullable
as String,cycle: null == cycle ? _self.cycle : cycle // ignore: cast_nullable_to_non_nullable
as BillingCycle,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PreviewPayable {

 int get net; int get tax; int get gross;
/// Create a copy of PreviewPayable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreviewPayableCopyWith<PreviewPayable> get copyWith => _$PreviewPayableCopyWithImpl<PreviewPayable>(this as PreviewPayable, _$identity);

  /// Serializes this PreviewPayable to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreviewPayable&&(identical(other.net, net) || other.net == net)&&(identical(other.tax, tax) || other.tax == tax)&&(identical(other.gross, gross) || other.gross == gross));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,net,tax,gross);

@override
String toString() {
  return 'PreviewPayable(net: $net, tax: $tax, gross: $gross)';
}


}

/// @nodoc
abstract mixin class $PreviewPayableCopyWith<$Res>  {
  factory $PreviewPayableCopyWith(PreviewPayable value, $Res Function(PreviewPayable) _then) = _$PreviewPayableCopyWithImpl;
@useResult
$Res call({
 int net, int tax, int gross
});




}
/// @nodoc
class _$PreviewPayableCopyWithImpl<$Res>
    implements $PreviewPayableCopyWith<$Res> {
  _$PreviewPayableCopyWithImpl(this._self, this._then);

  final PreviewPayable _self;
  final $Res Function(PreviewPayable) _then;

/// Create a copy of PreviewPayable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? net = null,Object? tax = null,Object? gross = null,}) {
  return _then(_self.copyWith(
net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,tax: null == tax ? _self.tax : tax // ignore: cast_nullable_to_non_nullable
as int,gross: null == gross ? _self.gross : gross // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PreviewPayable].
extension PreviewPayablePatterns on PreviewPayable {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PreviewPayable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PreviewPayable() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PreviewPayable value)  $default,){
final _that = this;
switch (_that) {
case _PreviewPayable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PreviewPayable value)?  $default,){
final _that = this;
switch (_that) {
case _PreviewPayable() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int net,  int tax,  int gross)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PreviewPayable() when $default != null:
return $default(_that.net,_that.tax,_that.gross);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int net,  int tax,  int gross)  $default,) {final _that = this;
switch (_that) {
case _PreviewPayable():
return $default(_that.net,_that.tax,_that.gross);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int net,  int tax,  int gross)?  $default,) {final _that = this;
switch (_that) {
case _PreviewPayable() when $default != null:
return $default(_that.net,_that.tax,_that.gross);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PreviewPayable implements PreviewPayable {
  const _PreviewPayable({this.net = 0, this.tax = 0, this.gross = 0});
  factory _PreviewPayable.fromJson(Map<String, dynamic> json) => _$PreviewPayableFromJson(json);

@override@JsonKey() final  int net;
@override@JsonKey() final  int tax;
@override@JsonKey() final  int gross;

/// Create a copy of PreviewPayable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreviewPayableCopyWith<_PreviewPayable> get copyWith => __$PreviewPayableCopyWithImpl<_PreviewPayable>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PreviewPayableToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PreviewPayable&&(identical(other.net, net) || other.net == net)&&(identical(other.tax, tax) || other.tax == tax)&&(identical(other.gross, gross) || other.gross == gross));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,net,tax,gross);

@override
String toString() {
  return 'PreviewPayable(net: $net, tax: $tax, gross: $gross)';
}


}

/// @nodoc
abstract mixin class _$PreviewPayableCopyWith<$Res> implements $PreviewPayableCopyWith<$Res> {
  factory _$PreviewPayableCopyWith(_PreviewPayable value, $Res Function(_PreviewPayable) _then) = __$PreviewPayableCopyWithImpl;
@override @useResult
$Res call({
 int net, int tax, int gross
});




}
/// @nodoc
class __$PreviewPayableCopyWithImpl<$Res>
    implements _$PreviewPayableCopyWith<$Res> {
  __$PreviewPayableCopyWithImpl(this._self, this._then);

  final _PreviewPayable _self;
  final $Res Function(_PreviewPayable) _then;

/// Create a copy of PreviewPayable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? net = null,Object? tax = null,Object? gross = null,}) {
  return _then(_PreviewPayable(
net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,tax: null == tax ? _self.tax : tax // ignore: cast_nullable_to_non_nullable
as int,gross: null == gross ? _self.gross : gross // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$LimitConflict {

 String get limit; int get usage; int get newLimit;
/// Create a copy of LimitConflict
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LimitConflictCopyWith<LimitConflict> get copyWith => _$LimitConflictCopyWithImpl<LimitConflict>(this as LimitConflict, _$identity);

  /// Serializes this LimitConflict to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LimitConflict&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.newLimit, newLimit) || other.newLimit == newLimit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,limit,usage,newLimit);

@override
String toString() {
  return 'LimitConflict(limit: $limit, usage: $usage, newLimit: $newLimit)';
}


}

/// @nodoc
abstract mixin class $LimitConflictCopyWith<$Res>  {
  factory $LimitConflictCopyWith(LimitConflict value, $Res Function(LimitConflict) _then) = _$LimitConflictCopyWithImpl;
@useResult
$Res call({
 String limit, int usage, int newLimit
});




}
/// @nodoc
class _$LimitConflictCopyWithImpl<$Res>
    implements $LimitConflictCopyWith<$Res> {
  _$LimitConflictCopyWithImpl(this._self, this._then);

  final LimitConflict _self;
  final $Res Function(LimitConflict) _then;

/// Create a copy of LimitConflict
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? limit = null,Object? usage = null,Object? newLimit = null,}) {
  return _then(_self.copyWith(
limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as String,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as int,newLimit: null == newLimit ? _self.newLimit : newLimit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LimitConflict].
extension LimitConflictPatterns on LimitConflict {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LimitConflict value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LimitConflict() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LimitConflict value)  $default,){
final _that = this;
switch (_that) {
case _LimitConflict():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LimitConflict value)?  $default,){
final _that = this;
switch (_that) {
case _LimitConflict() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String limit,  int usage,  int newLimit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LimitConflict() when $default != null:
return $default(_that.limit,_that.usage,_that.newLimit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String limit,  int usage,  int newLimit)  $default,) {final _that = this;
switch (_that) {
case _LimitConflict():
return $default(_that.limit,_that.usage,_that.newLimit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String limit,  int usage,  int newLimit)?  $default,) {final _that = this;
switch (_that) {
case _LimitConflict() when $default != null:
return $default(_that.limit,_that.usage,_that.newLimit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LimitConflict implements LimitConflict {
  const _LimitConflict({this.limit = '', this.usage = 0, this.newLimit = 0});
  factory _LimitConflict.fromJson(Map<String, dynamic> json) => _$LimitConflictFromJson(json);

@override@JsonKey() final  String limit;
@override@JsonKey() final  int usage;
@override@JsonKey() final  int newLimit;

/// Create a copy of LimitConflict
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LimitConflictCopyWith<_LimitConflict> get copyWith => __$LimitConflictCopyWithImpl<_LimitConflict>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LimitConflictToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LimitConflict&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.newLimit, newLimit) || other.newLimit == newLimit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,limit,usage,newLimit);

@override
String toString() {
  return 'LimitConflict(limit: $limit, usage: $usage, newLimit: $newLimit)';
}


}

/// @nodoc
abstract mixin class _$LimitConflictCopyWith<$Res> implements $LimitConflictCopyWith<$Res> {
  factory _$LimitConflictCopyWith(_LimitConflict value, $Res Function(_LimitConflict) _then) = __$LimitConflictCopyWithImpl;
@override @useResult
$Res call({
 String limit, int usage, int newLimit
});




}
/// @nodoc
class __$LimitConflictCopyWithImpl<$Res>
    implements _$LimitConflictCopyWith<$Res> {
  __$LimitConflictCopyWithImpl(this._self, this._then);

  final _LimitConflict _self;
  final $Res Function(_LimitConflict) _then;

/// Create a copy of LimitConflict
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? limit = null,Object? usage = null,Object? newLimit = null,}) {
  return _then(_LimitConflict(
limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as String,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as int,newLimit: null == newLimit ? _self.newLimit : newLimit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PlanChangePreview {

@JsonKey(unknownEnumValue: PlanChangeKind.unknown) PlanChangeKind get kind;@JsonKey(name: 'when', unknownEnumValue: PlanChangeTiming.unknown) PlanChangeTiming get timing;@UtcDateTimeConverter() DateTime get appliesAt; PreviewTarget get to; String get currency; int get credit; int get charge; int get forfeited;/// `null` when nothing is charged now, or when the academy has no billing address to tax it by.
 PreviewPayable? get payable;/// The change is charged, and its tax needs the academy's billing address first.
 bool get needsBillingAddress; List<LimitConflict> get conflicts;
/// Create a copy of PlanChangePreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanChangePreviewCopyWith<PlanChangePreview> get copyWith => _$PlanChangePreviewCopyWithImpl<PlanChangePreview>(this as PlanChangePreview, _$identity);

  /// Serializes this PlanChangePreview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanChangePreview&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.timing, timing) || other.timing == timing)&&(identical(other.appliesAt, appliesAt) || other.appliesAt == appliesAt)&&(identical(other.to, to) || other.to == to)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.credit, credit) || other.credit == credit)&&(identical(other.charge, charge) || other.charge == charge)&&(identical(other.forfeited, forfeited) || other.forfeited == forfeited)&&(identical(other.payable, payable) || other.payable == payable)&&(identical(other.needsBillingAddress, needsBillingAddress) || other.needsBillingAddress == needsBillingAddress)&&const DeepCollectionEquality().equals(other.conflicts, conflicts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,timing,appliesAt,to,currency,credit,charge,forfeited,payable,needsBillingAddress,const DeepCollectionEquality().hash(conflicts));

@override
String toString() {
  return 'PlanChangePreview(kind: $kind, timing: $timing, appliesAt: $appliesAt, to: $to, currency: $currency, credit: $credit, charge: $charge, forfeited: $forfeited, payable: $payable, needsBillingAddress: $needsBillingAddress, conflicts: $conflicts)';
}


}

/// @nodoc
abstract mixin class $PlanChangePreviewCopyWith<$Res>  {
  factory $PlanChangePreviewCopyWith(PlanChangePreview value, $Res Function(PlanChangePreview) _then) = _$PlanChangePreviewCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: PlanChangeKind.unknown) PlanChangeKind kind,@JsonKey(name: 'when', unknownEnumValue: PlanChangeTiming.unknown) PlanChangeTiming timing,@UtcDateTimeConverter() DateTime appliesAt, PreviewTarget to, String currency, int credit, int charge, int forfeited, PreviewPayable? payable, bool needsBillingAddress, List<LimitConflict> conflicts
});


$PreviewTargetCopyWith<$Res> get to;$PreviewPayableCopyWith<$Res>? get payable;

}
/// @nodoc
class _$PlanChangePreviewCopyWithImpl<$Res>
    implements $PlanChangePreviewCopyWith<$Res> {
  _$PlanChangePreviewCopyWithImpl(this._self, this._then);

  final PlanChangePreview _self;
  final $Res Function(PlanChangePreview) _then;

/// Create a copy of PlanChangePreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? timing = null,Object? appliesAt = null,Object? to = null,Object? currency = null,Object? credit = null,Object? charge = null,Object? forfeited = null,Object? payable = freezed,Object? needsBillingAddress = null,Object? conflicts = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PlanChangeKind,timing: null == timing ? _self.timing : timing // ignore: cast_nullable_to_non_nullable
as PlanChangeTiming,appliesAt: null == appliesAt ? _self.appliesAt : appliesAt // ignore: cast_nullable_to_non_nullable
as DateTime,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as PreviewTarget,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,credit: null == credit ? _self.credit : credit // ignore: cast_nullable_to_non_nullable
as int,charge: null == charge ? _self.charge : charge // ignore: cast_nullable_to_non_nullable
as int,forfeited: null == forfeited ? _self.forfeited : forfeited // ignore: cast_nullable_to_non_nullable
as int,payable: freezed == payable ? _self.payable : payable // ignore: cast_nullable_to_non_nullable
as PreviewPayable?,needsBillingAddress: null == needsBillingAddress ? _self.needsBillingAddress : needsBillingAddress // ignore: cast_nullable_to_non_nullable
as bool,conflicts: null == conflicts ? _self.conflicts : conflicts // ignore: cast_nullable_to_non_nullable
as List<LimitConflict>,
  ));
}
/// Create a copy of PlanChangePreview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PreviewTargetCopyWith<$Res> get to {
  
  return $PreviewTargetCopyWith<$Res>(_self.to, (value) {
    return _then(_self.copyWith(to: value));
  });
}/// Create a copy of PlanChangePreview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PreviewPayableCopyWith<$Res>? get payable {
    if (_self.payable == null) {
    return null;
  }

  return $PreviewPayableCopyWith<$Res>(_self.payable!, (value) {
    return _then(_self.copyWith(payable: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlanChangePreview].
extension PlanChangePreviewPatterns on PlanChangePreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanChangePreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanChangePreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanChangePreview value)  $default,){
final _that = this;
switch (_that) {
case _PlanChangePreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanChangePreview value)?  $default,){
final _that = this;
switch (_that) {
case _PlanChangePreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: PlanChangeKind.unknown)  PlanChangeKind kind, @JsonKey(name: 'when', unknownEnumValue: PlanChangeTiming.unknown)  PlanChangeTiming timing, @UtcDateTimeConverter()  DateTime appliesAt,  PreviewTarget to,  String currency,  int credit,  int charge,  int forfeited,  PreviewPayable? payable,  bool needsBillingAddress,  List<LimitConflict> conflicts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanChangePreview() when $default != null:
return $default(_that.kind,_that.timing,_that.appliesAt,_that.to,_that.currency,_that.credit,_that.charge,_that.forfeited,_that.payable,_that.needsBillingAddress,_that.conflicts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: PlanChangeKind.unknown)  PlanChangeKind kind, @JsonKey(name: 'when', unknownEnumValue: PlanChangeTiming.unknown)  PlanChangeTiming timing, @UtcDateTimeConverter()  DateTime appliesAt,  PreviewTarget to,  String currency,  int credit,  int charge,  int forfeited,  PreviewPayable? payable,  bool needsBillingAddress,  List<LimitConflict> conflicts)  $default,) {final _that = this;
switch (_that) {
case _PlanChangePreview():
return $default(_that.kind,_that.timing,_that.appliesAt,_that.to,_that.currency,_that.credit,_that.charge,_that.forfeited,_that.payable,_that.needsBillingAddress,_that.conflicts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: PlanChangeKind.unknown)  PlanChangeKind kind, @JsonKey(name: 'when', unknownEnumValue: PlanChangeTiming.unknown)  PlanChangeTiming timing, @UtcDateTimeConverter()  DateTime appliesAt,  PreviewTarget to,  String currency,  int credit,  int charge,  int forfeited,  PreviewPayable? payable,  bool needsBillingAddress,  List<LimitConflict> conflicts)?  $default,) {final _that = this;
switch (_that) {
case _PlanChangePreview() when $default != null:
return $default(_that.kind,_that.timing,_that.appliesAt,_that.to,_that.currency,_that.credit,_that.charge,_that.forfeited,_that.payable,_that.needsBillingAddress,_that.conflicts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanChangePreview extends PlanChangePreview {
  const _PlanChangePreview({@JsonKey(unknownEnumValue: PlanChangeKind.unknown) this.kind = PlanChangeKind.unknown, @JsonKey(name: 'when', unknownEnumValue: PlanChangeTiming.unknown) this.timing = PlanChangeTiming.unknown, @UtcDateTimeConverter() required this.appliesAt, this.to = const PreviewTarget(), this.currency = 'INR', this.credit = 0, this.charge = 0, this.forfeited = 0, this.payable, this.needsBillingAddress = false, final  List<LimitConflict> conflicts = const <LimitConflict>[]}): _conflicts = conflicts,super._();
  factory _PlanChangePreview.fromJson(Map<String, dynamic> json) => _$PlanChangePreviewFromJson(json);

@override@JsonKey(unknownEnumValue: PlanChangeKind.unknown) final  PlanChangeKind kind;
@override@JsonKey(name: 'when', unknownEnumValue: PlanChangeTiming.unknown) final  PlanChangeTiming timing;
@override@UtcDateTimeConverter() final  DateTime appliesAt;
@override@JsonKey() final  PreviewTarget to;
@override@JsonKey() final  String currency;
@override@JsonKey() final  int credit;
@override@JsonKey() final  int charge;
@override@JsonKey() final  int forfeited;
/// `null` when nothing is charged now, or when the academy has no billing address to tax it by.
@override final  PreviewPayable? payable;
/// The change is charged, and its tax needs the academy's billing address first.
@override@JsonKey() final  bool needsBillingAddress;
 final  List<LimitConflict> _conflicts;
@override@JsonKey() List<LimitConflict> get conflicts {
  if (_conflicts is EqualUnmodifiableListView) return _conflicts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_conflicts);
}


/// Create a copy of PlanChangePreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanChangePreviewCopyWith<_PlanChangePreview> get copyWith => __$PlanChangePreviewCopyWithImpl<_PlanChangePreview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanChangePreviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanChangePreview&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.timing, timing) || other.timing == timing)&&(identical(other.appliesAt, appliesAt) || other.appliesAt == appliesAt)&&(identical(other.to, to) || other.to == to)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.credit, credit) || other.credit == credit)&&(identical(other.charge, charge) || other.charge == charge)&&(identical(other.forfeited, forfeited) || other.forfeited == forfeited)&&(identical(other.payable, payable) || other.payable == payable)&&(identical(other.needsBillingAddress, needsBillingAddress) || other.needsBillingAddress == needsBillingAddress)&&const DeepCollectionEquality().equals(other._conflicts, _conflicts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,timing,appliesAt,to,currency,credit,charge,forfeited,payable,needsBillingAddress,const DeepCollectionEquality().hash(_conflicts));

@override
String toString() {
  return 'PlanChangePreview(kind: $kind, timing: $timing, appliesAt: $appliesAt, to: $to, currency: $currency, credit: $credit, charge: $charge, forfeited: $forfeited, payable: $payable, needsBillingAddress: $needsBillingAddress, conflicts: $conflicts)';
}


}

/// @nodoc
abstract mixin class _$PlanChangePreviewCopyWith<$Res> implements $PlanChangePreviewCopyWith<$Res> {
  factory _$PlanChangePreviewCopyWith(_PlanChangePreview value, $Res Function(_PlanChangePreview) _then) = __$PlanChangePreviewCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: PlanChangeKind.unknown) PlanChangeKind kind,@JsonKey(name: 'when', unknownEnumValue: PlanChangeTiming.unknown) PlanChangeTiming timing,@UtcDateTimeConverter() DateTime appliesAt, PreviewTarget to, String currency, int credit, int charge, int forfeited, PreviewPayable? payable, bool needsBillingAddress, List<LimitConflict> conflicts
});


@override $PreviewTargetCopyWith<$Res> get to;@override $PreviewPayableCopyWith<$Res>? get payable;

}
/// @nodoc
class __$PlanChangePreviewCopyWithImpl<$Res>
    implements _$PlanChangePreviewCopyWith<$Res> {
  __$PlanChangePreviewCopyWithImpl(this._self, this._then);

  final _PlanChangePreview _self;
  final $Res Function(_PlanChangePreview) _then;

/// Create a copy of PlanChangePreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? timing = null,Object? appliesAt = null,Object? to = null,Object? currency = null,Object? credit = null,Object? charge = null,Object? forfeited = null,Object? payable = freezed,Object? needsBillingAddress = null,Object? conflicts = null,}) {
  return _then(_PlanChangePreview(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PlanChangeKind,timing: null == timing ? _self.timing : timing // ignore: cast_nullable_to_non_nullable
as PlanChangeTiming,appliesAt: null == appliesAt ? _self.appliesAt : appliesAt // ignore: cast_nullable_to_non_nullable
as DateTime,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as PreviewTarget,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,credit: null == credit ? _self.credit : credit // ignore: cast_nullable_to_non_nullable
as int,charge: null == charge ? _self.charge : charge // ignore: cast_nullable_to_non_nullable
as int,forfeited: null == forfeited ? _self.forfeited : forfeited // ignore: cast_nullable_to_non_nullable
as int,payable: freezed == payable ? _self.payable : payable // ignore: cast_nullable_to_non_nullable
as PreviewPayable?,needsBillingAddress: null == needsBillingAddress ? _self.needsBillingAddress : needsBillingAddress // ignore: cast_nullable_to_non_nullable
as bool,conflicts: null == conflicts ? _self._conflicts : conflicts // ignore: cast_nullable_to_non_nullable
as List<LimitConflict>,
  ));
}

/// Create a copy of PlanChangePreview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PreviewTargetCopyWith<$Res> get to {
  
  return $PreviewTargetCopyWith<$Res>(_self.to, (value) {
    return _then(_self.copyWith(to: value));
  });
}/// Create a copy of PlanChangePreview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PreviewPayableCopyWith<$Res>? get payable {
    if (_self.payable == null) {
    return null;
  }

  return $PreviewPayableCopyWith<$Res>(_self.payable!, (value) {
    return _then(_self.copyWith(payable: value));
  });
}
}


/// @nodoc
mixin _$BillingDetails {

 String get legalName; String get email; String get addressLine1; String? get addressLine2; String get city; String? get region; String get postalCode;/// ISO 3166-1 alpha-2, e.g. `IN`.
 String get country; String? get taxRegistration;
/// Create a copy of BillingDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillingDetailsCopyWith<BillingDetails> get copyWith => _$BillingDetailsCopyWithImpl<BillingDetails>(this as BillingDetails, _$identity);

  /// Serializes this BillingDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillingDetails&&(identical(other.legalName, legalName) || other.legalName == legalName)&&(identical(other.email, email) || other.email == email)&&(identical(other.addressLine1, addressLine1) || other.addressLine1 == addressLine1)&&(identical(other.addressLine2, addressLine2) || other.addressLine2 == addressLine2)&&(identical(other.city, city) || other.city == city)&&(identical(other.region, region) || other.region == region)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.country, country) || other.country == country)&&(identical(other.taxRegistration, taxRegistration) || other.taxRegistration == taxRegistration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,legalName,email,addressLine1,addressLine2,city,region,postalCode,country,taxRegistration);

@override
String toString() {
  return 'BillingDetails(legalName: $legalName, email: $email, addressLine1: $addressLine1, addressLine2: $addressLine2, city: $city, region: $region, postalCode: $postalCode, country: $country, taxRegistration: $taxRegistration)';
}


}

/// @nodoc
abstract mixin class $BillingDetailsCopyWith<$Res>  {
  factory $BillingDetailsCopyWith(BillingDetails value, $Res Function(BillingDetails) _then) = _$BillingDetailsCopyWithImpl;
@useResult
$Res call({
 String legalName, String email, String addressLine1, String? addressLine2, String city, String? region, String postalCode, String country, String? taxRegistration
});




}
/// @nodoc
class _$BillingDetailsCopyWithImpl<$Res>
    implements $BillingDetailsCopyWith<$Res> {
  _$BillingDetailsCopyWithImpl(this._self, this._then);

  final BillingDetails _self;
  final $Res Function(BillingDetails) _then;

/// Create a copy of BillingDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? legalName = null,Object? email = null,Object? addressLine1 = null,Object? addressLine2 = freezed,Object? city = null,Object? region = freezed,Object? postalCode = null,Object? country = null,Object? taxRegistration = freezed,}) {
  return _then(_self.copyWith(
legalName: null == legalName ? _self.legalName : legalName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,addressLine1: null == addressLine1 ? _self.addressLine1 : addressLine1 // ignore: cast_nullable_to_non_nullable
as String,addressLine2: freezed == addressLine2 ? _self.addressLine2 : addressLine2 // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String?,postalCode: null == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,taxRegistration: freezed == taxRegistration ? _self.taxRegistration : taxRegistration // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BillingDetails].
extension BillingDetailsPatterns on BillingDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BillingDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BillingDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BillingDetails value)  $default,){
final _that = this;
switch (_that) {
case _BillingDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BillingDetails value)?  $default,){
final _that = this;
switch (_that) {
case _BillingDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String legalName,  String email,  String addressLine1,  String? addressLine2,  String city,  String? region,  String postalCode,  String country,  String? taxRegistration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BillingDetails() when $default != null:
return $default(_that.legalName,_that.email,_that.addressLine1,_that.addressLine2,_that.city,_that.region,_that.postalCode,_that.country,_that.taxRegistration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String legalName,  String email,  String addressLine1,  String? addressLine2,  String city,  String? region,  String postalCode,  String country,  String? taxRegistration)  $default,) {final _that = this;
switch (_that) {
case _BillingDetails():
return $default(_that.legalName,_that.email,_that.addressLine1,_that.addressLine2,_that.city,_that.region,_that.postalCode,_that.country,_that.taxRegistration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String legalName,  String email,  String addressLine1,  String? addressLine2,  String city,  String? region,  String postalCode,  String country,  String? taxRegistration)?  $default,) {final _that = this;
switch (_that) {
case _BillingDetails() when $default != null:
return $default(_that.legalName,_that.email,_that.addressLine1,_that.addressLine2,_that.city,_that.region,_that.postalCode,_that.country,_that.taxRegistration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BillingDetails extends BillingDetails {
  const _BillingDetails({this.legalName = '', this.email = '', this.addressLine1 = '', this.addressLine2, this.city = '', this.region, this.postalCode = '', this.country = 'IN', this.taxRegistration}): super._();
  factory _BillingDetails.fromJson(Map<String, dynamic> json) => _$BillingDetailsFromJson(json);

@override@JsonKey() final  String legalName;
@override@JsonKey() final  String email;
@override@JsonKey() final  String addressLine1;
@override final  String? addressLine2;
@override@JsonKey() final  String city;
@override final  String? region;
@override@JsonKey() final  String postalCode;
/// ISO 3166-1 alpha-2, e.g. `IN`.
@override@JsonKey() final  String country;
@override final  String? taxRegistration;

/// Create a copy of BillingDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillingDetailsCopyWith<_BillingDetails> get copyWith => __$BillingDetailsCopyWithImpl<_BillingDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillingDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BillingDetails&&(identical(other.legalName, legalName) || other.legalName == legalName)&&(identical(other.email, email) || other.email == email)&&(identical(other.addressLine1, addressLine1) || other.addressLine1 == addressLine1)&&(identical(other.addressLine2, addressLine2) || other.addressLine2 == addressLine2)&&(identical(other.city, city) || other.city == city)&&(identical(other.region, region) || other.region == region)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.country, country) || other.country == country)&&(identical(other.taxRegistration, taxRegistration) || other.taxRegistration == taxRegistration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,legalName,email,addressLine1,addressLine2,city,region,postalCode,country,taxRegistration);

@override
String toString() {
  return 'BillingDetails(legalName: $legalName, email: $email, addressLine1: $addressLine1, addressLine2: $addressLine2, city: $city, region: $region, postalCode: $postalCode, country: $country, taxRegistration: $taxRegistration)';
}


}

/// @nodoc
abstract mixin class _$BillingDetailsCopyWith<$Res> implements $BillingDetailsCopyWith<$Res> {
  factory _$BillingDetailsCopyWith(_BillingDetails value, $Res Function(_BillingDetails) _then) = __$BillingDetailsCopyWithImpl;
@override @useResult
$Res call({
 String legalName, String email, String addressLine1, String? addressLine2, String city, String? region, String postalCode, String country, String? taxRegistration
});




}
/// @nodoc
class __$BillingDetailsCopyWithImpl<$Res>
    implements _$BillingDetailsCopyWith<$Res> {
  __$BillingDetailsCopyWithImpl(this._self, this._then);

  final _BillingDetails _self;
  final $Res Function(_BillingDetails) _then;

/// Create a copy of BillingDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? legalName = null,Object? email = null,Object? addressLine1 = null,Object? addressLine2 = freezed,Object? city = null,Object? region = freezed,Object? postalCode = null,Object? country = null,Object? taxRegistration = freezed,}) {
  return _then(_BillingDetails(
legalName: null == legalName ? _self.legalName : legalName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,addressLine1: null == addressLine1 ? _self.addressLine1 : addressLine1 // ignore: cast_nullable_to_non_nullable
as String,addressLine2: freezed == addressLine2 ? _self.addressLine2 : addressLine2 // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String?,postalCode: null == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,taxRegistration: freezed == taxRegistration ? _self.taxRegistration : taxRegistration // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
