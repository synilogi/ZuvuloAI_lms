// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'help_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HelpCategory {

 String get id; String get name; String get description;@JsonKey(unknownEnumValue: HelpCategoryIcon.unknown) HelpCategoryIcon get icon; int get order;
/// Create a copy of HelpCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HelpCategoryCopyWith<HelpCategory> get copyWith => _$HelpCategoryCopyWithImpl<HelpCategory>(this as HelpCategory, _$identity);

  /// Serializes this HelpCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HelpCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,icon,order);

@override
String toString() {
  return 'HelpCategory(id: $id, name: $name, description: $description, icon: $icon, order: $order)';
}


}

/// @nodoc
abstract mixin class $HelpCategoryCopyWith<$Res>  {
  factory $HelpCategoryCopyWith(HelpCategory value, $Res Function(HelpCategory) _then) = _$HelpCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description,@JsonKey(unknownEnumValue: HelpCategoryIcon.unknown) HelpCategoryIcon icon, int order
});




}
/// @nodoc
class _$HelpCategoryCopyWithImpl<$Res>
    implements $HelpCategoryCopyWith<$Res> {
  _$HelpCategoryCopyWithImpl(this._self, this._then);

  final HelpCategory _self;
  final $Res Function(HelpCategory) _then;

/// Create a copy of HelpCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? icon = null,Object? order = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as HelpCategoryIcon,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [HelpCategory].
extension HelpCategoryPatterns on HelpCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HelpCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HelpCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HelpCategory value)  $default,){
final _that = this;
switch (_that) {
case _HelpCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HelpCategory value)?  $default,){
final _that = this;
switch (_that) {
case _HelpCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description, @JsonKey(unknownEnumValue: HelpCategoryIcon.unknown)  HelpCategoryIcon icon,  int order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HelpCategory() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.icon,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description, @JsonKey(unknownEnumValue: HelpCategoryIcon.unknown)  HelpCategoryIcon icon,  int order)  $default,) {final _that = this;
switch (_that) {
case _HelpCategory():
return $default(_that.id,_that.name,_that.description,_that.icon,_that.order);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description, @JsonKey(unknownEnumValue: HelpCategoryIcon.unknown)  HelpCategoryIcon icon,  int order)?  $default,) {final _that = this;
switch (_that) {
case _HelpCategory() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.icon,_that.order);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HelpCategory implements HelpCategory {
  const _HelpCategory({required this.id, required this.name, this.description = '', @JsonKey(unknownEnumValue: HelpCategoryIcon.unknown) this.icon = HelpCategoryIcon.unknown, this.order = 0});
  factory _HelpCategory.fromJson(Map<String, dynamic> json) => _$HelpCategoryFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String description;
@override@JsonKey(unknownEnumValue: HelpCategoryIcon.unknown) final  HelpCategoryIcon icon;
@override@JsonKey() final  int order;

/// Create a copy of HelpCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HelpCategoryCopyWith<_HelpCategory> get copyWith => __$HelpCategoryCopyWithImpl<_HelpCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HelpCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HelpCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,icon,order);

@override
String toString() {
  return 'HelpCategory(id: $id, name: $name, description: $description, icon: $icon, order: $order)';
}


}

/// @nodoc
abstract mixin class _$HelpCategoryCopyWith<$Res> implements $HelpCategoryCopyWith<$Res> {
  factory _$HelpCategoryCopyWith(_HelpCategory value, $Res Function(_HelpCategory) _then) = __$HelpCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description,@JsonKey(unknownEnumValue: HelpCategoryIcon.unknown) HelpCategoryIcon icon, int order
});




}
/// @nodoc
class __$HelpCategoryCopyWithImpl<$Res>
    implements _$HelpCategoryCopyWith<$Res> {
  __$HelpCategoryCopyWithImpl(this._self, this._then);

  final _HelpCategory _self;
  final $Res Function(_HelpCategory) _then;

/// Create a copy of HelpCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? icon = null,Object? order = null,}) {
  return _then(_HelpCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as HelpCategoryIcon,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$HelpCategorySummary {

 HelpCategory get category; int get articleCount;
/// Create a copy of HelpCategorySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HelpCategorySummaryCopyWith<HelpCategorySummary> get copyWith => _$HelpCategorySummaryCopyWithImpl<HelpCategorySummary>(this as HelpCategorySummary, _$identity);

  /// Serializes this HelpCategorySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HelpCategorySummary&&(identical(other.category, category) || other.category == category)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,articleCount);

@override
String toString() {
  return 'HelpCategorySummary(category: $category, articleCount: $articleCount)';
}


}

/// @nodoc
abstract mixin class $HelpCategorySummaryCopyWith<$Res>  {
  factory $HelpCategorySummaryCopyWith(HelpCategorySummary value, $Res Function(HelpCategorySummary) _then) = _$HelpCategorySummaryCopyWithImpl;
@useResult
$Res call({
 HelpCategory category, int articleCount
});


$HelpCategoryCopyWith<$Res> get category;

}
/// @nodoc
class _$HelpCategorySummaryCopyWithImpl<$Res>
    implements $HelpCategorySummaryCopyWith<$Res> {
  _$HelpCategorySummaryCopyWithImpl(this._self, this._then);

  final HelpCategorySummary _self;
  final $Res Function(HelpCategorySummary) _then;

/// Create a copy of HelpCategorySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? articleCount = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as HelpCategory,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of HelpCategorySummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HelpCategoryCopyWith<$Res> get category {
  
  return $HelpCategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [HelpCategorySummary].
extension HelpCategorySummaryPatterns on HelpCategorySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HelpCategorySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HelpCategorySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HelpCategorySummary value)  $default,){
final _that = this;
switch (_that) {
case _HelpCategorySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HelpCategorySummary value)?  $default,){
final _that = this;
switch (_that) {
case _HelpCategorySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( HelpCategory category,  int articleCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HelpCategorySummary() when $default != null:
return $default(_that.category,_that.articleCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( HelpCategory category,  int articleCount)  $default,) {final _that = this;
switch (_that) {
case _HelpCategorySummary():
return $default(_that.category,_that.articleCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( HelpCategory category,  int articleCount)?  $default,) {final _that = this;
switch (_that) {
case _HelpCategorySummary() when $default != null:
return $default(_that.category,_that.articleCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HelpCategorySummary implements HelpCategorySummary {
  const _HelpCategorySummary({required this.category, this.articleCount = 0});
  factory _HelpCategorySummary.fromJson(Map<String, dynamic> json) => _$HelpCategorySummaryFromJson(json);

@override final  HelpCategory category;
@override@JsonKey() final  int articleCount;

/// Create a copy of HelpCategorySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HelpCategorySummaryCopyWith<_HelpCategorySummary> get copyWith => __$HelpCategorySummaryCopyWithImpl<_HelpCategorySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HelpCategorySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HelpCategorySummary&&(identical(other.category, category) || other.category == category)&&(identical(other.articleCount, articleCount) || other.articleCount == articleCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,articleCount);

@override
String toString() {
  return 'HelpCategorySummary(category: $category, articleCount: $articleCount)';
}


}

/// @nodoc
abstract mixin class _$HelpCategorySummaryCopyWith<$Res> implements $HelpCategorySummaryCopyWith<$Res> {
  factory _$HelpCategorySummaryCopyWith(_HelpCategorySummary value, $Res Function(_HelpCategorySummary) _then) = __$HelpCategorySummaryCopyWithImpl;
@override @useResult
$Res call({
 HelpCategory category, int articleCount
});


@override $HelpCategoryCopyWith<$Res> get category;

}
/// @nodoc
class __$HelpCategorySummaryCopyWithImpl<$Res>
    implements _$HelpCategorySummaryCopyWith<$Res> {
  __$HelpCategorySummaryCopyWithImpl(this._self, this._then);

  final _HelpCategorySummary _self;
  final $Res Function(_HelpCategorySummary) _then;

/// Create a copy of HelpCategorySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? articleCount = null,}) {
  return _then(_HelpCategorySummary(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as HelpCategory,articleCount: null == articleCount ? _self.articleCount : articleCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of HelpCategorySummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HelpCategoryCopyWith<$Res> get category {
  
  return $HelpCategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// @nodoc
mixin _$HelpArticle {

 String get id; String get slug; String get categoryId; String get title; String get summary; String get body;@JsonKey(unknownEnumValue: HelpAudience.all) HelpAudience get audience; List<String> get tags; int get readMinutes;@UtcDateTimeConverter() DateTime get updatedAt; bool get popular;
/// Create a copy of HelpArticle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HelpArticleCopyWith<HelpArticle> get copyWith => _$HelpArticleCopyWithImpl<HelpArticle>(this as HelpArticle, _$identity);

  /// Serializes this HelpArticle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HelpArticle&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.body, body) || other.body == body)&&(identical(other.audience, audience) || other.audience == audience)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.readMinutes, readMinutes) || other.readMinutes == readMinutes)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.popular, popular) || other.popular == popular));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,categoryId,title,summary,body,audience,const DeepCollectionEquality().hash(tags),readMinutes,updatedAt,popular);

@override
String toString() {
  return 'HelpArticle(id: $id, slug: $slug, categoryId: $categoryId, title: $title, summary: $summary, body: $body, audience: $audience, tags: $tags, readMinutes: $readMinutes, updatedAt: $updatedAt, popular: $popular)';
}


}

/// @nodoc
abstract mixin class $HelpArticleCopyWith<$Res>  {
  factory $HelpArticleCopyWith(HelpArticle value, $Res Function(HelpArticle) _then) = _$HelpArticleCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String categoryId, String title, String summary, String body,@JsonKey(unknownEnumValue: HelpAudience.all) HelpAudience audience, List<String> tags, int readMinutes,@UtcDateTimeConverter() DateTime updatedAt, bool popular
});




}
/// @nodoc
class _$HelpArticleCopyWithImpl<$Res>
    implements $HelpArticleCopyWith<$Res> {
  _$HelpArticleCopyWithImpl(this._self, this._then);

  final HelpArticle _self;
  final $Res Function(HelpArticle) _then;

/// Create a copy of HelpArticle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? categoryId = null,Object? title = null,Object? summary = null,Object? body = null,Object? audience = null,Object? tags = null,Object? readMinutes = null,Object? updatedAt = null,Object? popular = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as HelpAudience,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,readMinutes: null == readMinutes ? _self.readMinutes : readMinutes // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,popular: null == popular ? _self.popular : popular // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [HelpArticle].
extension HelpArticlePatterns on HelpArticle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HelpArticle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HelpArticle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HelpArticle value)  $default,){
final _that = this;
switch (_that) {
case _HelpArticle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HelpArticle value)?  $default,){
final _that = this;
switch (_that) {
case _HelpArticle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String categoryId,  String title,  String summary,  String body, @JsonKey(unknownEnumValue: HelpAudience.all)  HelpAudience audience,  List<String> tags,  int readMinutes, @UtcDateTimeConverter()  DateTime updatedAt,  bool popular)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HelpArticle() when $default != null:
return $default(_that.id,_that.slug,_that.categoryId,_that.title,_that.summary,_that.body,_that.audience,_that.tags,_that.readMinutes,_that.updatedAt,_that.popular);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String categoryId,  String title,  String summary,  String body, @JsonKey(unknownEnumValue: HelpAudience.all)  HelpAudience audience,  List<String> tags,  int readMinutes, @UtcDateTimeConverter()  DateTime updatedAt,  bool popular)  $default,) {final _that = this;
switch (_that) {
case _HelpArticle():
return $default(_that.id,_that.slug,_that.categoryId,_that.title,_that.summary,_that.body,_that.audience,_that.tags,_that.readMinutes,_that.updatedAt,_that.popular);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String categoryId,  String title,  String summary,  String body, @JsonKey(unknownEnumValue: HelpAudience.all)  HelpAudience audience,  List<String> tags,  int readMinutes, @UtcDateTimeConverter()  DateTime updatedAt,  bool popular)?  $default,) {final _that = this;
switch (_that) {
case _HelpArticle() when $default != null:
return $default(_that.id,_that.slug,_that.categoryId,_that.title,_that.summary,_that.body,_that.audience,_that.tags,_that.readMinutes,_that.updatedAt,_that.popular);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HelpArticle implements HelpArticle {
  const _HelpArticle({required this.id, required this.slug, required this.categoryId, required this.title, this.summary = '', this.body = '', @JsonKey(unknownEnumValue: HelpAudience.all) this.audience = HelpAudience.all, final  List<String> tags = const <String>[], this.readMinutes = 0, @UtcDateTimeConverter() required this.updatedAt, this.popular = false}): _tags = tags;
  factory _HelpArticle.fromJson(Map<String, dynamic> json) => _$HelpArticleFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String categoryId;
@override final  String title;
@override@JsonKey() final  String summary;
@override@JsonKey() final  String body;
@override@JsonKey(unknownEnumValue: HelpAudience.all) final  HelpAudience audience;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  int readMinutes;
@override@UtcDateTimeConverter() final  DateTime updatedAt;
@override@JsonKey() final  bool popular;

/// Create a copy of HelpArticle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HelpArticleCopyWith<_HelpArticle> get copyWith => __$HelpArticleCopyWithImpl<_HelpArticle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HelpArticleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HelpArticle&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.body, body) || other.body == body)&&(identical(other.audience, audience) || other.audience == audience)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.readMinutes, readMinutes) || other.readMinutes == readMinutes)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.popular, popular) || other.popular == popular));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,categoryId,title,summary,body,audience,const DeepCollectionEquality().hash(_tags),readMinutes,updatedAt,popular);

@override
String toString() {
  return 'HelpArticle(id: $id, slug: $slug, categoryId: $categoryId, title: $title, summary: $summary, body: $body, audience: $audience, tags: $tags, readMinutes: $readMinutes, updatedAt: $updatedAt, popular: $popular)';
}


}

/// @nodoc
abstract mixin class _$HelpArticleCopyWith<$Res> implements $HelpArticleCopyWith<$Res> {
  factory _$HelpArticleCopyWith(_HelpArticle value, $Res Function(_HelpArticle) _then) = __$HelpArticleCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String categoryId, String title, String summary, String body,@JsonKey(unknownEnumValue: HelpAudience.all) HelpAudience audience, List<String> tags, int readMinutes,@UtcDateTimeConverter() DateTime updatedAt, bool popular
});




}
/// @nodoc
class __$HelpArticleCopyWithImpl<$Res>
    implements _$HelpArticleCopyWith<$Res> {
  __$HelpArticleCopyWithImpl(this._self, this._then);

  final _HelpArticle _self;
  final $Res Function(_HelpArticle) _then;

/// Create a copy of HelpArticle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? categoryId = null,Object? title = null,Object? summary = null,Object? body = null,Object? audience = null,Object? tags = null,Object? readMinutes = null,Object? updatedAt = null,Object? popular = null,}) {
  return _then(_HelpArticle(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as HelpAudience,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,readMinutes: null == readMinutes ? _self.readMinutes : readMinutes // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,popular: null == popular ? _self.popular : popular // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$HelpArticleListItem {

 HelpArticle get article; String get categoryName;
/// Create a copy of HelpArticleListItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HelpArticleListItemCopyWith<HelpArticleListItem> get copyWith => _$HelpArticleListItemCopyWithImpl<HelpArticleListItem>(this as HelpArticleListItem, _$identity);

  /// Serializes this HelpArticleListItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HelpArticleListItem&&(identical(other.article, article) || other.article == article)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,article,categoryName);

@override
String toString() {
  return 'HelpArticleListItem(article: $article, categoryName: $categoryName)';
}


}

/// @nodoc
abstract mixin class $HelpArticleListItemCopyWith<$Res>  {
  factory $HelpArticleListItemCopyWith(HelpArticleListItem value, $Res Function(HelpArticleListItem) _then) = _$HelpArticleListItemCopyWithImpl;
@useResult
$Res call({
 HelpArticle article, String categoryName
});


$HelpArticleCopyWith<$Res> get article;

}
/// @nodoc
class _$HelpArticleListItemCopyWithImpl<$Res>
    implements $HelpArticleListItemCopyWith<$Res> {
  _$HelpArticleListItemCopyWithImpl(this._self, this._then);

  final HelpArticleListItem _self;
  final $Res Function(HelpArticleListItem) _then;

/// Create a copy of HelpArticleListItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? article = null,Object? categoryName = null,}) {
  return _then(_self.copyWith(
article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as HelpArticle,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of HelpArticleListItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HelpArticleCopyWith<$Res> get article {
  
  return $HelpArticleCopyWith<$Res>(_self.article, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}


/// Adds pattern-matching-related methods to [HelpArticleListItem].
extension HelpArticleListItemPatterns on HelpArticleListItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HelpArticleListItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HelpArticleListItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HelpArticleListItem value)  $default,){
final _that = this;
switch (_that) {
case _HelpArticleListItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HelpArticleListItem value)?  $default,){
final _that = this;
switch (_that) {
case _HelpArticleListItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( HelpArticle article,  String categoryName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HelpArticleListItem() when $default != null:
return $default(_that.article,_that.categoryName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( HelpArticle article,  String categoryName)  $default,) {final _that = this;
switch (_that) {
case _HelpArticleListItem():
return $default(_that.article,_that.categoryName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( HelpArticle article,  String categoryName)?  $default,) {final _that = this;
switch (_that) {
case _HelpArticleListItem() when $default != null:
return $default(_that.article,_that.categoryName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HelpArticleListItem implements HelpArticleListItem {
  const _HelpArticleListItem({required this.article, this.categoryName = ''});
  factory _HelpArticleListItem.fromJson(Map<String, dynamic> json) => _$HelpArticleListItemFromJson(json);

@override final  HelpArticle article;
@override@JsonKey() final  String categoryName;

/// Create a copy of HelpArticleListItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HelpArticleListItemCopyWith<_HelpArticleListItem> get copyWith => __$HelpArticleListItemCopyWithImpl<_HelpArticleListItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HelpArticleListItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HelpArticleListItem&&(identical(other.article, article) || other.article == article)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,article,categoryName);

@override
String toString() {
  return 'HelpArticleListItem(article: $article, categoryName: $categoryName)';
}


}

/// @nodoc
abstract mixin class _$HelpArticleListItemCopyWith<$Res> implements $HelpArticleListItemCopyWith<$Res> {
  factory _$HelpArticleListItemCopyWith(_HelpArticleListItem value, $Res Function(_HelpArticleListItem) _then) = __$HelpArticleListItemCopyWithImpl;
@override @useResult
$Res call({
 HelpArticle article, String categoryName
});


@override $HelpArticleCopyWith<$Res> get article;

}
/// @nodoc
class __$HelpArticleListItemCopyWithImpl<$Res>
    implements _$HelpArticleListItemCopyWith<$Res> {
  __$HelpArticleListItemCopyWithImpl(this._self, this._then);

  final _HelpArticleListItem _self;
  final $Res Function(_HelpArticleListItem) _then;

/// Create a copy of HelpArticleListItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? article = null,Object? categoryName = null,}) {
  return _then(_HelpArticleListItem(
article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as HelpArticle,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of HelpArticleListItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HelpArticleCopyWith<$Res> get article {
  
  return $HelpArticleCopyWith<$Res>(_self.article, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}


/// @nodoc
mixin _$HelpArticleDetail {

 HelpArticle get article; String get categoryName; List<HelpArticleListItem> get related;
/// Create a copy of HelpArticleDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HelpArticleDetailCopyWith<HelpArticleDetail> get copyWith => _$HelpArticleDetailCopyWithImpl<HelpArticleDetail>(this as HelpArticleDetail, _$identity);

  /// Serializes this HelpArticleDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HelpArticleDetail&&(identical(other.article, article) || other.article == article)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&const DeepCollectionEquality().equals(other.related, related));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,article,categoryName,const DeepCollectionEquality().hash(related));

@override
String toString() {
  return 'HelpArticleDetail(article: $article, categoryName: $categoryName, related: $related)';
}


}

/// @nodoc
abstract mixin class $HelpArticleDetailCopyWith<$Res>  {
  factory $HelpArticleDetailCopyWith(HelpArticleDetail value, $Res Function(HelpArticleDetail) _then) = _$HelpArticleDetailCopyWithImpl;
@useResult
$Res call({
 HelpArticle article, String categoryName, List<HelpArticleListItem> related
});


$HelpArticleCopyWith<$Res> get article;

}
/// @nodoc
class _$HelpArticleDetailCopyWithImpl<$Res>
    implements $HelpArticleDetailCopyWith<$Res> {
  _$HelpArticleDetailCopyWithImpl(this._self, this._then);

  final HelpArticleDetail _self;
  final $Res Function(HelpArticleDetail) _then;

/// Create a copy of HelpArticleDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? article = null,Object? categoryName = null,Object? related = null,}) {
  return _then(_self.copyWith(
article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as HelpArticle,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,related: null == related ? _self.related : related // ignore: cast_nullable_to_non_nullable
as List<HelpArticleListItem>,
  ));
}
/// Create a copy of HelpArticleDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HelpArticleCopyWith<$Res> get article {
  
  return $HelpArticleCopyWith<$Res>(_self.article, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}


/// Adds pattern-matching-related methods to [HelpArticleDetail].
extension HelpArticleDetailPatterns on HelpArticleDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HelpArticleDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HelpArticleDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HelpArticleDetail value)  $default,){
final _that = this;
switch (_that) {
case _HelpArticleDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HelpArticleDetail value)?  $default,){
final _that = this;
switch (_that) {
case _HelpArticleDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( HelpArticle article,  String categoryName,  List<HelpArticleListItem> related)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HelpArticleDetail() when $default != null:
return $default(_that.article,_that.categoryName,_that.related);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( HelpArticle article,  String categoryName,  List<HelpArticleListItem> related)  $default,) {final _that = this;
switch (_that) {
case _HelpArticleDetail():
return $default(_that.article,_that.categoryName,_that.related);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( HelpArticle article,  String categoryName,  List<HelpArticleListItem> related)?  $default,) {final _that = this;
switch (_that) {
case _HelpArticleDetail() when $default != null:
return $default(_that.article,_that.categoryName,_that.related);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HelpArticleDetail implements HelpArticleDetail {
  const _HelpArticleDetail({required this.article, this.categoryName = '', final  List<HelpArticleListItem> related = const <HelpArticleListItem>[]}): _related = related;
  factory _HelpArticleDetail.fromJson(Map<String, dynamic> json) => _$HelpArticleDetailFromJson(json);

@override final  HelpArticle article;
@override@JsonKey() final  String categoryName;
 final  List<HelpArticleListItem> _related;
@override@JsonKey() List<HelpArticleListItem> get related {
  if (_related is EqualUnmodifiableListView) return _related;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_related);
}


/// Create a copy of HelpArticleDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HelpArticleDetailCopyWith<_HelpArticleDetail> get copyWith => __$HelpArticleDetailCopyWithImpl<_HelpArticleDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HelpArticleDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HelpArticleDetail&&(identical(other.article, article) || other.article == article)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&const DeepCollectionEquality().equals(other._related, _related));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,article,categoryName,const DeepCollectionEquality().hash(_related));

@override
String toString() {
  return 'HelpArticleDetail(article: $article, categoryName: $categoryName, related: $related)';
}


}

/// @nodoc
abstract mixin class _$HelpArticleDetailCopyWith<$Res> implements $HelpArticleDetailCopyWith<$Res> {
  factory _$HelpArticleDetailCopyWith(_HelpArticleDetail value, $Res Function(_HelpArticleDetail) _then) = __$HelpArticleDetailCopyWithImpl;
@override @useResult
$Res call({
 HelpArticle article, String categoryName, List<HelpArticleListItem> related
});


@override $HelpArticleCopyWith<$Res> get article;

}
/// @nodoc
class __$HelpArticleDetailCopyWithImpl<$Res>
    implements _$HelpArticleDetailCopyWith<$Res> {
  __$HelpArticleDetailCopyWithImpl(this._self, this._then);

  final _HelpArticleDetail _self;
  final $Res Function(_HelpArticleDetail) _then;

/// Create a copy of HelpArticleDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? article = null,Object? categoryName = null,Object? related = null,}) {
  return _then(_HelpArticleDetail(
article: null == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as HelpArticle,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,related: null == related ? _self._related : related // ignore: cast_nullable_to_non_nullable
as List<HelpArticleListItem>,
  ));
}

/// Create a copy of HelpArticleDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HelpArticleCopyWith<$Res> get article {
  
  return $HelpArticleCopyWith<$Res>(_self.article, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}

// dart format on
