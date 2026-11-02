// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'staff_instructor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AcademyInstructor {

 String get id; String get name; String get title; int? get yearsTeaching; String get email; String get bio; List<String> get expertise;@JsonKey(unknownEnumValue: InstructorStatus.unknown) InstructorStatus get status;@UtcDateTimeConverter() DateTime get joinedAt; String get city; List<String> get languages; String? get phone; MediaFile? get photo;
/// Create a copy of AcademyInstructor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AcademyInstructorCopyWith<AcademyInstructor> get copyWith => _$AcademyInstructorCopyWithImpl<AcademyInstructor>(this as AcademyInstructor, _$identity);

  /// Serializes this AcademyInstructor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AcademyInstructor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.yearsTeaching, yearsTeaching) || other.yearsTeaching == yearsTeaching)&&(identical(other.email, email) || other.email == email)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other.expertise, expertise)&&(identical(other.status, status) || other.status == status)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.city, city) || other.city == city)&&const DeepCollectionEquality().equals(other.languages, languages)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.photo, photo) || other.photo == photo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,title,yearsTeaching,email,bio,const DeepCollectionEquality().hash(expertise),status,joinedAt,city,const DeepCollectionEquality().hash(languages),phone,photo);

@override
String toString() {
  return 'AcademyInstructor(id: $id, name: $name, title: $title, yearsTeaching: $yearsTeaching, email: $email, bio: $bio, expertise: $expertise, status: $status, joinedAt: $joinedAt, city: $city, languages: $languages, phone: $phone, photo: $photo)';
}


}

/// @nodoc
abstract mixin class $AcademyInstructorCopyWith<$Res>  {
  factory $AcademyInstructorCopyWith(AcademyInstructor value, $Res Function(AcademyInstructor) _then) = _$AcademyInstructorCopyWithImpl;
@useResult
$Res call({
 String id, String name, String title, int? yearsTeaching, String email, String bio, List<String> expertise,@JsonKey(unknownEnumValue: InstructorStatus.unknown) InstructorStatus status,@UtcDateTimeConverter() DateTime joinedAt, String city, List<String> languages, String? phone, MediaFile? photo
});


$MediaFileCopyWith<$Res>? get photo;

}
/// @nodoc
class _$AcademyInstructorCopyWithImpl<$Res>
    implements $AcademyInstructorCopyWith<$Res> {
  _$AcademyInstructorCopyWithImpl(this._self, this._then);

  final AcademyInstructor _self;
  final $Res Function(AcademyInstructor) _then;

/// Create a copy of AcademyInstructor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? title = null,Object? yearsTeaching = freezed,Object? email = null,Object? bio = null,Object? expertise = null,Object? status = null,Object? joinedAt = null,Object? city = null,Object? languages = null,Object? phone = freezed,Object? photo = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,yearsTeaching: freezed == yearsTeaching ? _self.yearsTeaching : yearsTeaching // ignore: cast_nullable_to_non_nullable
as int?,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,expertise: null == expertise ? _self.expertise : expertise // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstructorStatus,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,languages: null == languages ? _self.languages : languages // ignore: cast_nullable_to_non_nullable
as List<String>,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as MediaFile?,
  ));
}
/// Create a copy of AcademyInstructor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaFileCopyWith<$Res>? get photo {
    if (_self.photo == null) {
    return null;
  }

  return $MediaFileCopyWith<$Res>(_self.photo!, (value) {
    return _then(_self.copyWith(photo: value));
  });
}
}


/// Adds pattern-matching-related methods to [AcademyInstructor].
extension AcademyInstructorPatterns on AcademyInstructor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AcademyInstructor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AcademyInstructor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AcademyInstructor value)  $default,){
final _that = this;
switch (_that) {
case _AcademyInstructor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AcademyInstructor value)?  $default,){
final _that = this;
switch (_that) {
case _AcademyInstructor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String title,  int? yearsTeaching,  String email,  String bio,  List<String> expertise, @JsonKey(unknownEnumValue: InstructorStatus.unknown)  InstructorStatus status, @UtcDateTimeConverter()  DateTime joinedAt,  String city,  List<String> languages,  String? phone,  MediaFile? photo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AcademyInstructor() when $default != null:
return $default(_that.id,_that.name,_that.title,_that.yearsTeaching,_that.email,_that.bio,_that.expertise,_that.status,_that.joinedAt,_that.city,_that.languages,_that.phone,_that.photo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String title,  int? yearsTeaching,  String email,  String bio,  List<String> expertise, @JsonKey(unknownEnumValue: InstructorStatus.unknown)  InstructorStatus status, @UtcDateTimeConverter()  DateTime joinedAt,  String city,  List<String> languages,  String? phone,  MediaFile? photo)  $default,) {final _that = this;
switch (_that) {
case _AcademyInstructor():
return $default(_that.id,_that.name,_that.title,_that.yearsTeaching,_that.email,_that.bio,_that.expertise,_that.status,_that.joinedAt,_that.city,_that.languages,_that.phone,_that.photo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String title,  int? yearsTeaching,  String email,  String bio,  List<String> expertise, @JsonKey(unknownEnumValue: InstructorStatus.unknown)  InstructorStatus status, @UtcDateTimeConverter()  DateTime joinedAt,  String city,  List<String> languages,  String? phone,  MediaFile? photo)?  $default,) {final _that = this;
switch (_that) {
case _AcademyInstructor() when $default != null:
return $default(_that.id,_that.name,_that.title,_that.yearsTeaching,_that.email,_that.bio,_that.expertise,_that.status,_that.joinedAt,_that.city,_that.languages,_that.phone,_that.photo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AcademyInstructor extends AcademyInstructor {
  const _AcademyInstructor({required this.id, this.name = '', this.title = '', this.yearsTeaching, this.email = '', this.bio = '', final  List<String> expertise = const <String>[], @JsonKey(unknownEnumValue: InstructorStatus.unknown) this.status = InstructorStatus.unknown, @UtcDateTimeConverter() required this.joinedAt, this.city = '', final  List<String> languages = const <String>[], this.phone, this.photo}): _expertise = expertise,_languages = languages,super._();
  factory _AcademyInstructor.fromJson(Map<String, dynamic> json) => _$AcademyInstructorFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String title;
@override final  int? yearsTeaching;
@override@JsonKey() final  String email;
@override@JsonKey() final  String bio;
 final  List<String> _expertise;
@override@JsonKey() List<String> get expertise {
  if (_expertise is EqualUnmodifiableListView) return _expertise;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expertise);
}

@override@JsonKey(unknownEnumValue: InstructorStatus.unknown) final  InstructorStatus status;
@override@UtcDateTimeConverter() final  DateTime joinedAt;
@override@JsonKey() final  String city;
 final  List<String> _languages;
@override@JsonKey() List<String> get languages {
  if (_languages is EqualUnmodifiableListView) return _languages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_languages);
}

@override final  String? phone;
@override final  MediaFile? photo;

/// Create a copy of AcademyInstructor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AcademyInstructorCopyWith<_AcademyInstructor> get copyWith => __$AcademyInstructorCopyWithImpl<_AcademyInstructor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AcademyInstructorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AcademyInstructor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.yearsTeaching, yearsTeaching) || other.yearsTeaching == yearsTeaching)&&(identical(other.email, email) || other.email == email)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other._expertise, _expertise)&&(identical(other.status, status) || other.status == status)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.city, city) || other.city == city)&&const DeepCollectionEquality().equals(other._languages, _languages)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.photo, photo) || other.photo == photo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,title,yearsTeaching,email,bio,const DeepCollectionEquality().hash(_expertise),status,joinedAt,city,const DeepCollectionEquality().hash(_languages),phone,photo);

@override
String toString() {
  return 'AcademyInstructor(id: $id, name: $name, title: $title, yearsTeaching: $yearsTeaching, email: $email, bio: $bio, expertise: $expertise, status: $status, joinedAt: $joinedAt, city: $city, languages: $languages, phone: $phone, photo: $photo)';
}


}

/// @nodoc
abstract mixin class _$AcademyInstructorCopyWith<$Res> implements $AcademyInstructorCopyWith<$Res> {
  factory _$AcademyInstructorCopyWith(_AcademyInstructor value, $Res Function(_AcademyInstructor) _then) = __$AcademyInstructorCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String title, int? yearsTeaching, String email, String bio, List<String> expertise,@JsonKey(unknownEnumValue: InstructorStatus.unknown) InstructorStatus status,@UtcDateTimeConverter() DateTime joinedAt, String city, List<String> languages, String? phone, MediaFile? photo
});


@override $MediaFileCopyWith<$Res>? get photo;

}
/// @nodoc
class __$AcademyInstructorCopyWithImpl<$Res>
    implements _$AcademyInstructorCopyWith<$Res> {
  __$AcademyInstructorCopyWithImpl(this._self, this._then);

  final _AcademyInstructor _self;
  final $Res Function(_AcademyInstructor) _then;

/// Create a copy of AcademyInstructor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? title = null,Object? yearsTeaching = freezed,Object? email = null,Object? bio = null,Object? expertise = null,Object? status = null,Object? joinedAt = null,Object? city = null,Object? languages = null,Object? phone = freezed,Object? photo = freezed,}) {
  return _then(_AcademyInstructor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,yearsTeaching: freezed == yearsTeaching ? _self.yearsTeaching : yearsTeaching // ignore: cast_nullable_to_non_nullable
as int?,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,expertise: null == expertise ? _self._expertise : expertise // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstructorStatus,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,languages: null == languages ? _self._languages : languages // ignore: cast_nullable_to_non_nullable
as List<String>,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as MediaFile?,
  ));
}

/// Create a copy of AcademyInstructor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaFileCopyWith<$Res>? get photo {
    if (_self.photo == null) {
    return null;
  }

  return $MediaFileCopyWith<$Res>(_self.photo!, (value) {
    return _then(_self.copyWith(photo: value));
  });
}
}


/// @nodoc
mixin _$InstructorCourseBrief {

 String get id; String get title;@JsonKey(unknownEnumValue: CourseStatus.unknown) CourseStatus get status;
/// Create a copy of InstructorCourseBrief
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstructorCourseBriefCopyWith<InstructorCourseBrief> get copyWith => _$InstructorCourseBriefCopyWithImpl<InstructorCourseBrief>(this as InstructorCourseBrief, _$identity);

  /// Serializes this InstructorCourseBrief to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstructorCourseBrief&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,status);

@override
String toString() {
  return 'InstructorCourseBrief(id: $id, title: $title, status: $status)';
}


}

/// @nodoc
abstract mixin class $InstructorCourseBriefCopyWith<$Res>  {
  factory $InstructorCourseBriefCopyWith(InstructorCourseBrief value, $Res Function(InstructorCourseBrief) _then) = _$InstructorCourseBriefCopyWithImpl;
@useResult
$Res call({
 String id, String title,@JsonKey(unknownEnumValue: CourseStatus.unknown) CourseStatus status
});




}
/// @nodoc
class _$InstructorCourseBriefCopyWithImpl<$Res>
    implements $InstructorCourseBriefCopyWith<$Res> {
  _$InstructorCourseBriefCopyWithImpl(this._self, this._then);

  final InstructorCourseBrief _self;
  final $Res Function(InstructorCourseBrief) _then;

/// Create a copy of InstructorCourseBrief
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CourseStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [InstructorCourseBrief].
extension InstructorCourseBriefPatterns on InstructorCourseBrief {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstructorCourseBrief value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstructorCourseBrief() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstructorCourseBrief value)  $default,){
final _that = this;
switch (_that) {
case _InstructorCourseBrief():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstructorCourseBrief value)?  $default,){
final _that = this;
switch (_that) {
case _InstructorCourseBrief() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title, @JsonKey(unknownEnumValue: CourseStatus.unknown)  CourseStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstructorCourseBrief() when $default != null:
return $default(_that.id,_that.title,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title, @JsonKey(unknownEnumValue: CourseStatus.unknown)  CourseStatus status)  $default,) {final _that = this;
switch (_that) {
case _InstructorCourseBrief():
return $default(_that.id,_that.title,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title, @JsonKey(unknownEnumValue: CourseStatus.unknown)  CourseStatus status)?  $default,) {final _that = this;
switch (_that) {
case _InstructorCourseBrief() when $default != null:
return $default(_that.id,_that.title,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstructorCourseBrief implements InstructorCourseBrief {
  const _InstructorCourseBrief({this.id = '', this.title = '', @JsonKey(unknownEnumValue: CourseStatus.unknown) this.status = CourseStatus.unknown});
  factory _InstructorCourseBrief.fromJson(Map<String, dynamic> json) => _$InstructorCourseBriefFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String title;
@override@JsonKey(unknownEnumValue: CourseStatus.unknown) final  CourseStatus status;

/// Create a copy of InstructorCourseBrief
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstructorCourseBriefCopyWith<_InstructorCourseBrief> get copyWith => __$InstructorCourseBriefCopyWithImpl<_InstructorCourseBrief>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstructorCourseBriefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstructorCourseBrief&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,status);

@override
String toString() {
  return 'InstructorCourseBrief(id: $id, title: $title, status: $status)';
}


}

/// @nodoc
abstract mixin class _$InstructorCourseBriefCopyWith<$Res> implements $InstructorCourseBriefCopyWith<$Res> {
  factory _$InstructorCourseBriefCopyWith(_InstructorCourseBrief value, $Res Function(_InstructorCourseBrief) _then) = __$InstructorCourseBriefCopyWithImpl;
@override @useResult
$Res call({
 String id, String title,@JsonKey(unknownEnumValue: CourseStatus.unknown) CourseStatus status
});




}
/// @nodoc
class __$InstructorCourseBriefCopyWithImpl<$Res>
    implements _$InstructorCourseBriefCopyWith<$Res> {
  __$InstructorCourseBriefCopyWithImpl(this._self, this._then);

  final _InstructorCourseBrief _self;
  final $Res Function(_InstructorCourseBrief) _then;

/// Create a copy of InstructorCourseBrief
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? status = null,}) {
  return _then(_InstructorCourseBrief(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CourseStatus,
  ));
}


}


/// @nodoc
mixin _$InstructorRow {

 AcademyInstructor get instructor; List<InstructorCourseBrief> get courses; int get students;/// Weighted across their published courses; `null` until a course has been rated.
 double? get rating; int get ratingCount;/// Percentage; `null` when they have no settled enrolments to compute one from.
 int? get completion; int get toReview; int get overdue;
/// Create a copy of InstructorRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstructorRowCopyWith<InstructorRow> get copyWith => _$InstructorRowCopyWithImpl<InstructorRow>(this as InstructorRow, _$identity);

  /// Serializes this InstructorRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstructorRow&&(identical(other.instructor, instructor) || other.instructor == instructor)&&const DeepCollectionEquality().equals(other.courses, courses)&&(identical(other.students, students) || other.students == students)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.completion, completion) || other.completion == completion)&&(identical(other.toReview, toReview) || other.toReview == toReview)&&(identical(other.overdue, overdue) || other.overdue == overdue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,instructor,const DeepCollectionEquality().hash(courses),students,rating,ratingCount,completion,toReview,overdue);

@override
String toString() {
  return 'InstructorRow(instructor: $instructor, courses: $courses, students: $students, rating: $rating, ratingCount: $ratingCount, completion: $completion, toReview: $toReview, overdue: $overdue)';
}


}

/// @nodoc
abstract mixin class $InstructorRowCopyWith<$Res>  {
  factory $InstructorRowCopyWith(InstructorRow value, $Res Function(InstructorRow) _then) = _$InstructorRowCopyWithImpl;
@useResult
$Res call({
 AcademyInstructor instructor, List<InstructorCourseBrief> courses, int students, double? rating, int ratingCount, int? completion, int toReview, int overdue
});


$AcademyInstructorCopyWith<$Res> get instructor;

}
/// @nodoc
class _$InstructorRowCopyWithImpl<$Res>
    implements $InstructorRowCopyWith<$Res> {
  _$InstructorRowCopyWithImpl(this._self, this._then);

  final InstructorRow _self;
  final $Res Function(InstructorRow) _then;

/// Create a copy of InstructorRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? instructor = null,Object? courses = null,Object? students = null,Object? rating = freezed,Object? ratingCount = null,Object? completion = freezed,Object? toReview = null,Object? overdue = null,}) {
  return _then(_self.copyWith(
instructor: null == instructor ? _self.instructor : instructor // ignore: cast_nullable_to_non_nullable
as AcademyInstructor,courses: null == courses ? _self.courses : courses // ignore: cast_nullable_to_non_nullable
as List<InstructorCourseBrief>,students: null == students ? _self.students : students // ignore: cast_nullable_to_non_nullable
as int,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,completion: freezed == completion ? _self.completion : completion // ignore: cast_nullable_to_non_nullable
as int?,toReview: null == toReview ? _self.toReview : toReview // ignore: cast_nullable_to_non_nullable
as int,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of InstructorRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AcademyInstructorCopyWith<$Res> get instructor {
  
  return $AcademyInstructorCopyWith<$Res>(_self.instructor, (value) {
    return _then(_self.copyWith(instructor: value));
  });
}
}


/// Adds pattern-matching-related methods to [InstructorRow].
extension InstructorRowPatterns on InstructorRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstructorRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstructorRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstructorRow value)  $default,){
final _that = this;
switch (_that) {
case _InstructorRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstructorRow value)?  $default,){
final _that = this;
switch (_that) {
case _InstructorRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AcademyInstructor instructor,  List<InstructorCourseBrief> courses,  int students,  double? rating,  int ratingCount,  int? completion,  int toReview,  int overdue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstructorRow() when $default != null:
return $default(_that.instructor,_that.courses,_that.students,_that.rating,_that.ratingCount,_that.completion,_that.toReview,_that.overdue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AcademyInstructor instructor,  List<InstructorCourseBrief> courses,  int students,  double? rating,  int ratingCount,  int? completion,  int toReview,  int overdue)  $default,) {final _that = this;
switch (_that) {
case _InstructorRow():
return $default(_that.instructor,_that.courses,_that.students,_that.rating,_that.ratingCount,_that.completion,_that.toReview,_that.overdue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AcademyInstructor instructor,  List<InstructorCourseBrief> courses,  int students,  double? rating,  int ratingCount,  int? completion,  int toReview,  int overdue)?  $default,) {final _that = this;
switch (_that) {
case _InstructorRow() when $default != null:
return $default(_that.instructor,_that.courses,_that.students,_that.rating,_that.ratingCount,_that.completion,_that.toReview,_that.overdue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstructorRow extends InstructorRow {
  const _InstructorRow({required this.instructor, final  List<InstructorCourseBrief> courses = const <InstructorCourseBrief>[], this.students = 0, this.rating, this.ratingCount = 0, this.completion, this.toReview = 0, this.overdue = 0}): _courses = courses,super._();
  factory _InstructorRow.fromJson(Map<String, dynamic> json) => _$InstructorRowFromJson(json);

@override final  AcademyInstructor instructor;
 final  List<InstructorCourseBrief> _courses;
@override@JsonKey() List<InstructorCourseBrief> get courses {
  if (_courses is EqualUnmodifiableListView) return _courses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_courses);
}

@override@JsonKey() final  int students;
/// Weighted across their published courses; `null` until a course has been rated.
@override final  double? rating;
@override@JsonKey() final  int ratingCount;
/// Percentage; `null` when they have no settled enrolments to compute one from.
@override final  int? completion;
@override@JsonKey() final  int toReview;
@override@JsonKey() final  int overdue;

/// Create a copy of InstructorRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstructorRowCopyWith<_InstructorRow> get copyWith => __$InstructorRowCopyWithImpl<_InstructorRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstructorRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstructorRow&&(identical(other.instructor, instructor) || other.instructor == instructor)&&const DeepCollectionEquality().equals(other._courses, _courses)&&(identical(other.students, students) || other.students == students)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.completion, completion) || other.completion == completion)&&(identical(other.toReview, toReview) || other.toReview == toReview)&&(identical(other.overdue, overdue) || other.overdue == overdue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,instructor,const DeepCollectionEquality().hash(_courses),students,rating,ratingCount,completion,toReview,overdue);

@override
String toString() {
  return 'InstructorRow(instructor: $instructor, courses: $courses, students: $students, rating: $rating, ratingCount: $ratingCount, completion: $completion, toReview: $toReview, overdue: $overdue)';
}


}

/// @nodoc
abstract mixin class _$InstructorRowCopyWith<$Res> implements $InstructorRowCopyWith<$Res> {
  factory _$InstructorRowCopyWith(_InstructorRow value, $Res Function(_InstructorRow) _then) = __$InstructorRowCopyWithImpl;
@override @useResult
$Res call({
 AcademyInstructor instructor, List<InstructorCourseBrief> courses, int students, double? rating, int ratingCount, int? completion, int toReview, int overdue
});


@override $AcademyInstructorCopyWith<$Res> get instructor;

}
/// @nodoc
class __$InstructorRowCopyWithImpl<$Res>
    implements _$InstructorRowCopyWith<$Res> {
  __$InstructorRowCopyWithImpl(this._self, this._then);

  final _InstructorRow _self;
  final $Res Function(_InstructorRow) _then;

/// Create a copy of InstructorRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? instructor = null,Object? courses = null,Object? students = null,Object? rating = freezed,Object? ratingCount = null,Object? completion = freezed,Object? toReview = null,Object? overdue = null,}) {
  return _then(_InstructorRow(
instructor: null == instructor ? _self.instructor : instructor // ignore: cast_nullable_to_non_nullable
as AcademyInstructor,courses: null == courses ? _self._courses : courses // ignore: cast_nullable_to_non_nullable
as List<InstructorCourseBrief>,students: null == students ? _self.students : students // ignore: cast_nullable_to_non_nullable
as int,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,completion: freezed == completion ? _self.completion : completion // ignore: cast_nullable_to_non_nullable
as int?,toReview: null == toReview ? _self.toReview : toReview // ignore: cast_nullable_to_non_nullable
as int,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of InstructorRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AcademyInstructorCopyWith<$Res> get instructor {
  
  return $AcademyInstructorCopyWith<$Res>(_self.instructor, (value) {
    return _then(_self.copyWith(instructor: value));
  });
}
}


/// @nodoc
mixin _$InstructorDirectory {

 List<InstructorRow> get rows; Map<String, int> get counts; List<String> get expertise;
/// Create a copy of InstructorDirectory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstructorDirectoryCopyWith<InstructorDirectory> get copyWith => _$InstructorDirectoryCopyWithImpl<InstructorDirectory>(this as InstructorDirectory, _$identity);

  /// Serializes this InstructorDirectory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstructorDirectory&&const DeepCollectionEquality().equals(other.rows, rows)&&const DeepCollectionEquality().equals(other.counts, counts)&&const DeepCollectionEquality().equals(other.expertise, expertise));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rows),const DeepCollectionEquality().hash(counts),const DeepCollectionEquality().hash(expertise));

@override
String toString() {
  return 'InstructorDirectory(rows: $rows, counts: $counts, expertise: $expertise)';
}


}

/// @nodoc
abstract mixin class $InstructorDirectoryCopyWith<$Res>  {
  factory $InstructorDirectoryCopyWith(InstructorDirectory value, $Res Function(InstructorDirectory) _then) = _$InstructorDirectoryCopyWithImpl;
@useResult
$Res call({
 List<InstructorRow> rows, Map<String, int> counts, List<String> expertise
});




}
/// @nodoc
class _$InstructorDirectoryCopyWithImpl<$Res>
    implements $InstructorDirectoryCopyWith<$Res> {
  _$InstructorDirectoryCopyWithImpl(this._self, this._then);

  final InstructorDirectory _self;
  final $Res Function(InstructorDirectory) _then;

/// Create a copy of InstructorDirectory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? counts = null,Object? expertise = null,}) {
  return _then(_self.copyWith(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<InstructorRow>,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,expertise: null == expertise ? _self.expertise : expertise // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [InstructorDirectory].
extension InstructorDirectoryPatterns on InstructorDirectory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstructorDirectory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstructorDirectory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstructorDirectory value)  $default,){
final _that = this;
switch (_that) {
case _InstructorDirectory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstructorDirectory value)?  $default,){
final _that = this;
switch (_that) {
case _InstructorDirectory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<InstructorRow> rows,  Map<String, int> counts,  List<String> expertise)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstructorDirectory() when $default != null:
return $default(_that.rows,_that.counts,_that.expertise);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<InstructorRow> rows,  Map<String, int> counts,  List<String> expertise)  $default,) {final _that = this;
switch (_that) {
case _InstructorDirectory():
return $default(_that.rows,_that.counts,_that.expertise);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<InstructorRow> rows,  Map<String, int> counts,  List<String> expertise)?  $default,) {final _that = this;
switch (_that) {
case _InstructorDirectory() when $default != null:
return $default(_that.rows,_that.counts,_that.expertise);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstructorDirectory extends InstructorDirectory {
  const _InstructorDirectory({final  List<InstructorRow> rows = const <InstructorRow>[], final  Map<String, int> counts = const <String, int>{}, final  List<String> expertise = const <String>[]}): _rows = rows,_counts = counts,_expertise = expertise,super._();
  factory _InstructorDirectory.fromJson(Map<String, dynamic> json) => _$InstructorDirectoryFromJson(json);

 final  List<InstructorRow> _rows;
@override@JsonKey() List<InstructorRow> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

 final  Map<String, int> _counts;
@override@JsonKey() Map<String, int> get counts {
  if (_counts is EqualUnmodifiableMapView) return _counts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_counts);
}

 final  List<String> _expertise;
@override@JsonKey() List<String> get expertise {
  if (_expertise is EqualUnmodifiableListView) return _expertise;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expertise);
}


/// Create a copy of InstructorDirectory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstructorDirectoryCopyWith<_InstructorDirectory> get copyWith => __$InstructorDirectoryCopyWithImpl<_InstructorDirectory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstructorDirectoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstructorDirectory&&const DeepCollectionEquality().equals(other._rows, _rows)&&const DeepCollectionEquality().equals(other._counts, _counts)&&const DeepCollectionEquality().equals(other._expertise, _expertise));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows),const DeepCollectionEquality().hash(_counts),const DeepCollectionEquality().hash(_expertise));

@override
String toString() {
  return 'InstructorDirectory(rows: $rows, counts: $counts, expertise: $expertise)';
}


}

/// @nodoc
abstract mixin class _$InstructorDirectoryCopyWith<$Res> implements $InstructorDirectoryCopyWith<$Res> {
  factory _$InstructorDirectoryCopyWith(_InstructorDirectory value, $Res Function(_InstructorDirectory) _then) = __$InstructorDirectoryCopyWithImpl;
@override @useResult
$Res call({
 List<InstructorRow> rows, Map<String, int> counts, List<String> expertise
});




}
/// @nodoc
class __$InstructorDirectoryCopyWithImpl<$Res>
    implements _$InstructorDirectoryCopyWith<$Res> {
  __$InstructorDirectoryCopyWithImpl(this._self, this._then);

  final _InstructorDirectory _self;
  final $Res Function(_InstructorDirectory) _then;

/// Create a copy of InstructorDirectory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,Object? counts = null,Object? expertise = null,}) {
  return _then(_InstructorDirectory(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<InstructorRow>,counts: null == counts ? _self._counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,expertise: null == expertise ? _self._expertise : expertise // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$InstructorCourse {

 String get id; String get title;@JsonKey(unknownEnumValue: CourseStatus.unknown) CourseStatus get status; String get levelTitle; String? get coverMotif;/// The uploaded cover image (`/catalog/covers/<id>`), or null when the motif is the cover.
 String? get coverImageUrl;/// `lead` or `co` — the academy decides which from the course's own instructor list.
 String get role; List<String> get coInstructors; int get enrolled; int get activeLearners; double? get rating; int? get ratingCount; int? get completion; int get lessons;@UtcDateTimeConverter() DateTime get updatedAt;
/// Create a copy of InstructorCourse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstructorCourseCopyWith<InstructorCourse> get copyWith => _$InstructorCourseCopyWithImpl<InstructorCourse>(this as InstructorCourse, _$identity);

  /// Serializes this InstructorCourse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstructorCourse&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.levelTitle, levelTitle) || other.levelTitle == levelTitle)&&(identical(other.coverMotif, coverMotif) || other.coverMotif == coverMotif)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other.coInstructors, coInstructors)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.activeLearners, activeLearners) || other.activeLearners == activeLearners)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.completion, completion) || other.completion == completion)&&(identical(other.lessons, lessons) || other.lessons == lessons)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,status,levelTitle,coverMotif,coverImageUrl,role,const DeepCollectionEquality().hash(coInstructors),enrolled,activeLearners,rating,ratingCount,completion,lessons,updatedAt);

@override
String toString() {
  return 'InstructorCourse(id: $id, title: $title, status: $status, levelTitle: $levelTitle, coverMotif: $coverMotif, coverImageUrl: $coverImageUrl, role: $role, coInstructors: $coInstructors, enrolled: $enrolled, activeLearners: $activeLearners, rating: $rating, ratingCount: $ratingCount, completion: $completion, lessons: $lessons, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $InstructorCourseCopyWith<$Res>  {
  factory $InstructorCourseCopyWith(InstructorCourse value, $Res Function(InstructorCourse) _then) = _$InstructorCourseCopyWithImpl;
@useResult
$Res call({
 String id, String title,@JsonKey(unknownEnumValue: CourseStatus.unknown) CourseStatus status, String levelTitle, String? coverMotif, String? coverImageUrl, String role, List<String> coInstructors, int enrolled, int activeLearners, double? rating, int? ratingCount, int? completion, int lessons,@UtcDateTimeConverter() DateTime updatedAt
});




}
/// @nodoc
class _$InstructorCourseCopyWithImpl<$Res>
    implements $InstructorCourseCopyWith<$Res> {
  _$InstructorCourseCopyWithImpl(this._self, this._then);

  final InstructorCourse _self;
  final $Res Function(InstructorCourse) _then;

/// Create a copy of InstructorCourse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? status = null,Object? levelTitle = null,Object? coverMotif = freezed,Object? coverImageUrl = freezed,Object? role = null,Object? coInstructors = null,Object? enrolled = null,Object? activeLearners = null,Object? rating = freezed,Object? ratingCount = freezed,Object? completion = freezed,Object? lessons = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CourseStatus,levelTitle: null == levelTitle ? _self.levelTitle : levelTitle // ignore: cast_nullable_to_non_nullable
as String,coverMotif: freezed == coverMotif ? _self.coverMotif : coverMotif // ignore: cast_nullable_to_non_nullable
as String?,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,coInstructors: null == coInstructors ? _self.coInstructors : coInstructors // ignore: cast_nullable_to_non_nullable
as List<String>,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as int,activeLearners: null == activeLearners ? _self.activeLearners : activeLearners // ignore: cast_nullable_to_non_nullable
as int,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: freezed == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int?,completion: freezed == completion ? _self.completion : completion // ignore: cast_nullable_to_non_nullable
as int?,lessons: null == lessons ? _self.lessons : lessons // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [InstructorCourse].
extension InstructorCoursePatterns on InstructorCourse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstructorCourse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstructorCourse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstructorCourse value)  $default,){
final _that = this;
switch (_that) {
case _InstructorCourse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstructorCourse value)?  $default,){
final _that = this;
switch (_that) {
case _InstructorCourse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title, @JsonKey(unknownEnumValue: CourseStatus.unknown)  CourseStatus status,  String levelTitle,  String? coverMotif,  String? coverImageUrl,  String role,  List<String> coInstructors,  int enrolled,  int activeLearners,  double? rating,  int? ratingCount,  int? completion,  int lessons, @UtcDateTimeConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstructorCourse() when $default != null:
return $default(_that.id,_that.title,_that.status,_that.levelTitle,_that.coverMotif,_that.coverImageUrl,_that.role,_that.coInstructors,_that.enrolled,_that.activeLearners,_that.rating,_that.ratingCount,_that.completion,_that.lessons,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title, @JsonKey(unknownEnumValue: CourseStatus.unknown)  CourseStatus status,  String levelTitle,  String? coverMotif,  String? coverImageUrl,  String role,  List<String> coInstructors,  int enrolled,  int activeLearners,  double? rating,  int? ratingCount,  int? completion,  int lessons, @UtcDateTimeConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _InstructorCourse():
return $default(_that.id,_that.title,_that.status,_that.levelTitle,_that.coverMotif,_that.coverImageUrl,_that.role,_that.coInstructors,_that.enrolled,_that.activeLearners,_that.rating,_that.ratingCount,_that.completion,_that.lessons,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title, @JsonKey(unknownEnumValue: CourseStatus.unknown)  CourseStatus status,  String levelTitle,  String? coverMotif,  String? coverImageUrl,  String role,  List<String> coInstructors,  int enrolled,  int activeLearners,  double? rating,  int? ratingCount,  int? completion,  int lessons, @UtcDateTimeConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _InstructorCourse() when $default != null:
return $default(_that.id,_that.title,_that.status,_that.levelTitle,_that.coverMotif,_that.coverImageUrl,_that.role,_that.coInstructors,_that.enrolled,_that.activeLearners,_that.rating,_that.ratingCount,_that.completion,_that.lessons,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstructorCourse extends InstructorCourse {
  const _InstructorCourse({this.id = '', this.title = '', @JsonKey(unknownEnumValue: CourseStatus.unknown) this.status = CourseStatus.unknown, this.levelTitle = '', this.coverMotif, this.coverImageUrl, this.role = '', final  List<String> coInstructors = const <String>[], this.enrolled = 0, this.activeLearners = 0, this.rating, this.ratingCount, this.completion, this.lessons = 0, @UtcDateTimeConverter() required this.updatedAt}): _coInstructors = coInstructors,super._();
  factory _InstructorCourse.fromJson(Map<String, dynamic> json) => _$InstructorCourseFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String title;
@override@JsonKey(unknownEnumValue: CourseStatus.unknown) final  CourseStatus status;
@override@JsonKey() final  String levelTitle;
@override final  String? coverMotif;
/// The uploaded cover image (`/catalog/covers/<id>`), or null when the motif is the cover.
@override final  String? coverImageUrl;
/// `lead` or `co` — the academy decides which from the course's own instructor list.
@override@JsonKey() final  String role;
 final  List<String> _coInstructors;
@override@JsonKey() List<String> get coInstructors {
  if (_coInstructors is EqualUnmodifiableListView) return _coInstructors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_coInstructors);
}

@override@JsonKey() final  int enrolled;
@override@JsonKey() final  int activeLearners;
@override final  double? rating;
@override final  int? ratingCount;
@override final  int? completion;
@override@JsonKey() final  int lessons;
@override@UtcDateTimeConverter() final  DateTime updatedAt;

/// Create a copy of InstructorCourse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstructorCourseCopyWith<_InstructorCourse> get copyWith => __$InstructorCourseCopyWithImpl<_InstructorCourse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstructorCourseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstructorCourse&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.levelTitle, levelTitle) || other.levelTitle == levelTitle)&&(identical(other.coverMotif, coverMotif) || other.coverMotif == coverMotif)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other._coInstructors, _coInstructors)&&(identical(other.enrolled, enrolled) || other.enrolled == enrolled)&&(identical(other.activeLearners, activeLearners) || other.activeLearners == activeLearners)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.completion, completion) || other.completion == completion)&&(identical(other.lessons, lessons) || other.lessons == lessons)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,status,levelTitle,coverMotif,coverImageUrl,role,const DeepCollectionEquality().hash(_coInstructors),enrolled,activeLearners,rating,ratingCount,completion,lessons,updatedAt);

@override
String toString() {
  return 'InstructorCourse(id: $id, title: $title, status: $status, levelTitle: $levelTitle, coverMotif: $coverMotif, coverImageUrl: $coverImageUrl, role: $role, coInstructors: $coInstructors, enrolled: $enrolled, activeLearners: $activeLearners, rating: $rating, ratingCount: $ratingCount, completion: $completion, lessons: $lessons, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$InstructorCourseCopyWith<$Res> implements $InstructorCourseCopyWith<$Res> {
  factory _$InstructorCourseCopyWith(_InstructorCourse value, $Res Function(_InstructorCourse) _then) = __$InstructorCourseCopyWithImpl;
@override @useResult
$Res call({
 String id, String title,@JsonKey(unknownEnumValue: CourseStatus.unknown) CourseStatus status, String levelTitle, String? coverMotif, String? coverImageUrl, String role, List<String> coInstructors, int enrolled, int activeLearners, double? rating, int? ratingCount, int? completion, int lessons,@UtcDateTimeConverter() DateTime updatedAt
});




}
/// @nodoc
class __$InstructorCourseCopyWithImpl<$Res>
    implements _$InstructorCourseCopyWith<$Res> {
  __$InstructorCourseCopyWithImpl(this._self, this._then);

  final _InstructorCourse _self;
  final $Res Function(_InstructorCourse) _then;

/// Create a copy of InstructorCourse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? status = null,Object? levelTitle = null,Object? coverMotif = freezed,Object? coverImageUrl = freezed,Object? role = null,Object? coInstructors = null,Object? enrolled = null,Object? activeLearners = null,Object? rating = freezed,Object? ratingCount = freezed,Object? completion = freezed,Object? lessons = null,Object? updatedAt = null,}) {
  return _then(_InstructorCourse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CourseStatus,levelTitle: null == levelTitle ? _self.levelTitle : levelTitle // ignore: cast_nullable_to_non_nullable
as String,coverMotif: freezed == coverMotif ? _self.coverMotif : coverMotif // ignore: cast_nullable_to_non_nullable
as String?,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,coInstructors: null == coInstructors ? _self._coInstructors : coInstructors // ignore: cast_nullable_to_non_nullable
as List<String>,enrolled: null == enrolled ? _self.enrolled : enrolled // ignore: cast_nullable_to_non_nullable
as int,activeLearners: null == activeLearners ? _self.activeLearners : activeLearners // ignore: cast_nullable_to_non_nullable
as int,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: freezed == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int?,completion: freezed == completion ? _self.completion : completion // ignore: cast_nullable_to_non_nullable
as int?,lessons: null == lessons ? _self.lessons : lessons // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$CityCount {

 String get city; int get count;
/// Create a copy of CityCount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CityCountCopyWith<CityCount> get copyWith => _$CityCountCopyWithImpl<CityCount>(this as CityCount, _$identity);

  /// Serializes this CityCount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CityCount&&(identical(other.city, city) || other.city == city)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,city,count);

@override
String toString() {
  return 'CityCount(city: $city, count: $count)';
}


}

/// @nodoc
abstract mixin class $CityCountCopyWith<$Res>  {
  factory $CityCountCopyWith(CityCount value, $Res Function(CityCount) _then) = _$CityCountCopyWithImpl;
@useResult
$Res call({
 String city, int count
});




}
/// @nodoc
class _$CityCountCopyWithImpl<$Res>
    implements $CityCountCopyWith<$Res> {
  _$CityCountCopyWithImpl(this._self, this._then);

  final CityCount _self;
  final $Res Function(CityCount) _then;

/// Create a copy of CityCount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? city = null,Object? count = null,}) {
  return _then(_self.copyWith(
city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CityCount].
extension CityCountPatterns on CityCount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CityCount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CityCount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CityCount value)  $default,){
final _that = this;
switch (_that) {
case _CityCount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CityCount value)?  $default,){
final _that = this;
switch (_that) {
case _CityCount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String city,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CityCount() when $default != null:
return $default(_that.city,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String city,  int count)  $default,) {final _that = this;
switch (_that) {
case _CityCount():
return $default(_that.city,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String city,  int count)?  $default,) {final _that = this;
switch (_that) {
case _CityCount() when $default != null:
return $default(_that.city,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CityCount implements CityCount {
  const _CityCount({this.city = '', this.count = 0});
  factory _CityCount.fromJson(Map<String, dynamic> json) => _$CityCountFromJson(json);

@override@JsonKey() final  String city;
@override@JsonKey() final  int count;

/// Create a copy of CityCount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CityCountCopyWith<_CityCount> get copyWith => __$CityCountCopyWithImpl<_CityCount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CityCountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CityCount&&(identical(other.city, city) || other.city == city)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,city,count);

@override
String toString() {
  return 'CityCount(city: $city, count: $count)';
}


}

/// @nodoc
abstract mixin class _$CityCountCopyWith<$Res> implements $CityCountCopyWith<$Res> {
  factory _$CityCountCopyWith(_CityCount value, $Res Function(_CityCount) _then) = __$CityCountCopyWithImpl;
@override @useResult
$Res call({
 String city, int count
});




}
/// @nodoc
class __$CityCountCopyWithImpl<$Res>
    implements _$CityCountCopyWith<$Res> {
  __$CityCountCopyWithImpl(this._self, this._then);

  final _CityCount _self;
  final $Res Function(_CityCount) _then;

/// Create a copy of CityCount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? city = null,Object? count = null,}) {
  return _then(_CityCount(
city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$InstructorReach {

 int get students; int get active; int get completed; int get newThisMonth; List<CityCount> get cities;
/// Create a copy of InstructorReach
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstructorReachCopyWith<InstructorReach> get copyWith => _$InstructorReachCopyWithImpl<InstructorReach>(this as InstructorReach, _$identity);

  /// Serializes this InstructorReach to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstructorReach&&(identical(other.students, students) || other.students == students)&&(identical(other.active, active) || other.active == active)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.newThisMonth, newThisMonth) || other.newThisMonth == newThisMonth)&&const DeepCollectionEquality().equals(other.cities, cities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,students,active,completed,newThisMonth,const DeepCollectionEquality().hash(cities));

@override
String toString() {
  return 'InstructorReach(students: $students, active: $active, completed: $completed, newThisMonth: $newThisMonth, cities: $cities)';
}


}

/// @nodoc
abstract mixin class $InstructorReachCopyWith<$Res>  {
  factory $InstructorReachCopyWith(InstructorReach value, $Res Function(InstructorReach) _then) = _$InstructorReachCopyWithImpl;
@useResult
$Res call({
 int students, int active, int completed, int newThisMonth, List<CityCount> cities
});




}
/// @nodoc
class _$InstructorReachCopyWithImpl<$Res>
    implements $InstructorReachCopyWith<$Res> {
  _$InstructorReachCopyWithImpl(this._self, this._then);

  final InstructorReach _self;
  final $Res Function(InstructorReach) _then;

/// Create a copy of InstructorReach
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? students = null,Object? active = null,Object? completed = null,Object? newThisMonth = null,Object? cities = null,}) {
  return _then(_self.copyWith(
students: null == students ? _self.students : students // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as int,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int,newThisMonth: null == newThisMonth ? _self.newThisMonth : newThisMonth // ignore: cast_nullable_to_non_nullable
as int,cities: null == cities ? _self.cities : cities // ignore: cast_nullable_to_non_nullable
as List<CityCount>,
  ));
}

}


/// Adds pattern-matching-related methods to [InstructorReach].
extension InstructorReachPatterns on InstructorReach {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstructorReach value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstructorReach() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstructorReach value)  $default,){
final _that = this;
switch (_that) {
case _InstructorReach():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstructorReach value)?  $default,){
final _that = this;
switch (_that) {
case _InstructorReach() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int students,  int active,  int completed,  int newThisMonth,  List<CityCount> cities)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstructorReach() when $default != null:
return $default(_that.students,_that.active,_that.completed,_that.newThisMonth,_that.cities);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int students,  int active,  int completed,  int newThisMonth,  List<CityCount> cities)  $default,) {final _that = this;
switch (_that) {
case _InstructorReach():
return $default(_that.students,_that.active,_that.completed,_that.newThisMonth,_that.cities);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int students,  int active,  int completed,  int newThisMonth,  List<CityCount> cities)?  $default,) {final _that = this;
switch (_that) {
case _InstructorReach() when $default != null:
return $default(_that.students,_that.active,_that.completed,_that.newThisMonth,_that.cities);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstructorReach implements InstructorReach {
  const _InstructorReach({this.students = 0, this.active = 0, this.completed = 0, this.newThisMonth = 0, final  List<CityCount> cities = const <CityCount>[]}): _cities = cities;
  factory _InstructorReach.fromJson(Map<String, dynamic> json) => _$InstructorReachFromJson(json);

@override@JsonKey() final  int students;
@override@JsonKey() final  int active;
@override@JsonKey() final  int completed;
@override@JsonKey() final  int newThisMonth;
 final  List<CityCount> _cities;
@override@JsonKey() List<CityCount> get cities {
  if (_cities is EqualUnmodifiableListView) return _cities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cities);
}


/// Create a copy of InstructorReach
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstructorReachCopyWith<_InstructorReach> get copyWith => __$InstructorReachCopyWithImpl<_InstructorReach>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstructorReachToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstructorReach&&(identical(other.students, students) || other.students == students)&&(identical(other.active, active) || other.active == active)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.newThisMonth, newThisMonth) || other.newThisMonth == newThisMonth)&&const DeepCollectionEquality().equals(other._cities, _cities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,students,active,completed,newThisMonth,const DeepCollectionEquality().hash(_cities));

@override
String toString() {
  return 'InstructorReach(students: $students, active: $active, completed: $completed, newThisMonth: $newThisMonth, cities: $cities)';
}


}

/// @nodoc
abstract mixin class _$InstructorReachCopyWith<$Res> implements $InstructorReachCopyWith<$Res> {
  factory _$InstructorReachCopyWith(_InstructorReach value, $Res Function(_InstructorReach) _then) = __$InstructorReachCopyWithImpl;
@override @useResult
$Res call({
 int students, int active, int completed, int newThisMonth, List<CityCount> cities
});




}
/// @nodoc
class __$InstructorReachCopyWithImpl<$Res>
    implements _$InstructorReachCopyWith<$Res> {
  __$InstructorReachCopyWithImpl(this._self, this._then);

  final _InstructorReach _self;
  final $Res Function(_InstructorReach) _then;

/// Create a copy of InstructorReach
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? students = null,Object? active = null,Object? completed = null,Object? newThisMonth = null,Object? cities = null,}) {
  return _then(_InstructorReach(
students: null == students ? _self.students : students // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as int,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int,newThisMonth: null == newThisMonth ? _self.newThisMonth : newThisMonth // ignore: cast_nullable_to_non_nullable
as int,cities: null == cities ? _self._cities : cities // ignore: cast_nullable_to_non_nullable
as List<CityCount>,
  ));
}


}


/// @nodoc
mixin _$MonthCount {

 String get label;/// "Sep 2026", or "Sep so far" for the month in progress.
 String get detail; num get value;
/// Create a copy of MonthCount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthCountCopyWith<MonthCount> get copyWith => _$MonthCountCopyWithImpl<MonthCount>(this as MonthCount, _$identity);

  /// Serializes this MonthCount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthCount&&(identical(other.label, label) || other.label == label)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,detail,value);

@override
String toString() {
  return 'MonthCount(label: $label, detail: $detail, value: $value)';
}


}

/// @nodoc
abstract mixin class $MonthCountCopyWith<$Res>  {
  factory $MonthCountCopyWith(MonthCount value, $Res Function(MonthCount) _then) = _$MonthCountCopyWithImpl;
@useResult
$Res call({
 String label, String detail, num value
});




}
/// @nodoc
class _$MonthCountCopyWithImpl<$Res>
    implements $MonthCountCopyWith<$Res> {
  _$MonthCountCopyWithImpl(this._self, this._then);

  final MonthCount _self;
  final $Res Function(MonthCount) _then;

/// Create a copy of MonthCount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? detail = null,Object? value = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthCount].
extension MonthCountPatterns on MonthCount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthCount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthCount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthCount value)  $default,){
final _that = this;
switch (_that) {
case _MonthCount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthCount value)?  $default,){
final _that = this;
switch (_that) {
case _MonthCount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String detail,  num value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthCount() when $default != null:
return $default(_that.label,_that.detail,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String detail,  num value)  $default,) {final _that = this;
switch (_that) {
case _MonthCount():
return $default(_that.label,_that.detail,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String detail,  num value)?  $default,) {final _that = this;
switch (_that) {
case _MonthCount() when $default != null:
return $default(_that.label,_that.detail,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonthCount implements MonthCount {
  const _MonthCount({this.label = '', this.detail = '', this.value = 0});
  factory _MonthCount.fromJson(Map<String, dynamic> json) => _$MonthCountFromJson(json);

@override@JsonKey() final  String label;
/// "Sep 2026", or "Sep so far" for the month in progress.
@override@JsonKey() final  String detail;
@override@JsonKey() final  num value;

/// Create a copy of MonthCount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthCountCopyWith<_MonthCount> get copyWith => __$MonthCountCopyWithImpl<_MonthCount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonthCountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthCount&&(identical(other.label, label) || other.label == label)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,detail,value);

@override
String toString() {
  return 'MonthCount(label: $label, detail: $detail, value: $value)';
}


}

/// @nodoc
abstract mixin class _$MonthCountCopyWith<$Res> implements $MonthCountCopyWith<$Res> {
  factory _$MonthCountCopyWith(_MonthCount value, $Res Function(_MonthCount) _then) = __$MonthCountCopyWithImpl;
@override @useResult
$Res call({
 String label, String detail, num value
});




}
/// @nodoc
class __$MonthCountCopyWithImpl<$Res>
    implements _$MonthCountCopyWith<$Res> {
  __$MonthCountCopyWithImpl(this._self, this._then);

  final _MonthCount _self;
  final $Res Function(_MonthCount) _then;

/// Create a copy of MonthCount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? detail = null,Object? value = null,}) {
  return _then(_MonthCount(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}


/// @nodoc
mixin _$InstructorPerformance {

 double? get rating; int get ratingCount; double get academyRating; int? get completion; int get academyCompletion;/// Median hours from hand-in to a decision; `null` until they have reviewed one.
 int? get reviewHoursMedian;/// Percentage reviewed inside the academy's 48-hour window.
 int? get reviewsOnTime; int get reviewed; int get toReview; int get liveDelivered; int get liveUpcoming;/// Percentage of registrations that attended; `null` until attendance was taken.
 int? get attendance; List<MonthCount> get enrollmentsByMonth;
/// Create a copy of InstructorPerformance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstructorPerformanceCopyWith<InstructorPerformance> get copyWith => _$InstructorPerformanceCopyWithImpl<InstructorPerformance>(this as InstructorPerformance, _$identity);

  /// Serializes this InstructorPerformance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstructorPerformance&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.academyRating, academyRating) || other.academyRating == academyRating)&&(identical(other.completion, completion) || other.completion == completion)&&(identical(other.academyCompletion, academyCompletion) || other.academyCompletion == academyCompletion)&&(identical(other.reviewHoursMedian, reviewHoursMedian) || other.reviewHoursMedian == reviewHoursMedian)&&(identical(other.reviewsOnTime, reviewsOnTime) || other.reviewsOnTime == reviewsOnTime)&&(identical(other.reviewed, reviewed) || other.reviewed == reviewed)&&(identical(other.toReview, toReview) || other.toReview == toReview)&&(identical(other.liveDelivered, liveDelivered) || other.liveDelivered == liveDelivered)&&(identical(other.liveUpcoming, liveUpcoming) || other.liveUpcoming == liveUpcoming)&&(identical(other.attendance, attendance) || other.attendance == attendance)&&const DeepCollectionEquality().equals(other.enrollmentsByMonth, enrollmentsByMonth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rating,ratingCount,academyRating,completion,academyCompletion,reviewHoursMedian,reviewsOnTime,reviewed,toReview,liveDelivered,liveUpcoming,attendance,const DeepCollectionEquality().hash(enrollmentsByMonth));

@override
String toString() {
  return 'InstructorPerformance(rating: $rating, ratingCount: $ratingCount, academyRating: $academyRating, completion: $completion, academyCompletion: $academyCompletion, reviewHoursMedian: $reviewHoursMedian, reviewsOnTime: $reviewsOnTime, reviewed: $reviewed, toReview: $toReview, liveDelivered: $liveDelivered, liveUpcoming: $liveUpcoming, attendance: $attendance, enrollmentsByMonth: $enrollmentsByMonth)';
}


}

/// @nodoc
abstract mixin class $InstructorPerformanceCopyWith<$Res>  {
  factory $InstructorPerformanceCopyWith(InstructorPerformance value, $Res Function(InstructorPerformance) _then) = _$InstructorPerformanceCopyWithImpl;
@useResult
$Res call({
 double? rating, int ratingCount, double academyRating, int? completion, int academyCompletion, int? reviewHoursMedian, int? reviewsOnTime, int reviewed, int toReview, int liveDelivered, int liveUpcoming, int? attendance, List<MonthCount> enrollmentsByMonth
});




}
/// @nodoc
class _$InstructorPerformanceCopyWithImpl<$Res>
    implements $InstructorPerformanceCopyWith<$Res> {
  _$InstructorPerformanceCopyWithImpl(this._self, this._then);

  final InstructorPerformance _self;
  final $Res Function(InstructorPerformance) _then;

/// Create a copy of InstructorPerformance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rating = freezed,Object? ratingCount = null,Object? academyRating = null,Object? completion = freezed,Object? academyCompletion = null,Object? reviewHoursMedian = freezed,Object? reviewsOnTime = freezed,Object? reviewed = null,Object? toReview = null,Object? liveDelivered = null,Object? liveUpcoming = null,Object? attendance = freezed,Object? enrollmentsByMonth = null,}) {
  return _then(_self.copyWith(
rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,academyRating: null == academyRating ? _self.academyRating : academyRating // ignore: cast_nullable_to_non_nullable
as double,completion: freezed == completion ? _self.completion : completion // ignore: cast_nullable_to_non_nullable
as int?,academyCompletion: null == academyCompletion ? _self.academyCompletion : academyCompletion // ignore: cast_nullable_to_non_nullable
as int,reviewHoursMedian: freezed == reviewHoursMedian ? _self.reviewHoursMedian : reviewHoursMedian // ignore: cast_nullable_to_non_nullable
as int?,reviewsOnTime: freezed == reviewsOnTime ? _self.reviewsOnTime : reviewsOnTime // ignore: cast_nullable_to_non_nullable
as int?,reviewed: null == reviewed ? _self.reviewed : reviewed // ignore: cast_nullable_to_non_nullable
as int,toReview: null == toReview ? _self.toReview : toReview // ignore: cast_nullable_to_non_nullable
as int,liveDelivered: null == liveDelivered ? _self.liveDelivered : liveDelivered // ignore: cast_nullable_to_non_nullable
as int,liveUpcoming: null == liveUpcoming ? _self.liveUpcoming : liveUpcoming // ignore: cast_nullable_to_non_nullable
as int,attendance: freezed == attendance ? _self.attendance : attendance // ignore: cast_nullable_to_non_nullable
as int?,enrollmentsByMonth: null == enrollmentsByMonth ? _self.enrollmentsByMonth : enrollmentsByMonth // ignore: cast_nullable_to_non_nullable
as List<MonthCount>,
  ));
}

}


/// Adds pattern-matching-related methods to [InstructorPerformance].
extension InstructorPerformancePatterns on InstructorPerformance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstructorPerformance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstructorPerformance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstructorPerformance value)  $default,){
final _that = this;
switch (_that) {
case _InstructorPerformance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstructorPerformance value)?  $default,){
final _that = this;
switch (_that) {
case _InstructorPerformance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? rating,  int ratingCount,  double academyRating,  int? completion,  int academyCompletion,  int? reviewHoursMedian,  int? reviewsOnTime,  int reviewed,  int toReview,  int liveDelivered,  int liveUpcoming,  int? attendance,  List<MonthCount> enrollmentsByMonth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstructorPerformance() when $default != null:
return $default(_that.rating,_that.ratingCount,_that.academyRating,_that.completion,_that.academyCompletion,_that.reviewHoursMedian,_that.reviewsOnTime,_that.reviewed,_that.toReview,_that.liveDelivered,_that.liveUpcoming,_that.attendance,_that.enrollmentsByMonth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? rating,  int ratingCount,  double academyRating,  int? completion,  int academyCompletion,  int? reviewHoursMedian,  int? reviewsOnTime,  int reviewed,  int toReview,  int liveDelivered,  int liveUpcoming,  int? attendance,  List<MonthCount> enrollmentsByMonth)  $default,) {final _that = this;
switch (_that) {
case _InstructorPerformance():
return $default(_that.rating,_that.ratingCount,_that.academyRating,_that.completion,_that.academyCompletion,_that.reviewHoursMedian,_that.reviewsOnTime,_that.reviewed,_that.toReview,_that.liveDelivered,_that.liveUpcoming,_that.attendance,_that.enrollmentsByMonth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? rating,  int ratingCount,  double academyRating,  int? completion,  int academyCompletion,  int? reviewHoursMedian,  int? reviewsOnTime,  int reviewed,  int toReview,  int liveDelivered,  int liveUpcoming,  int? attendance,  List<MonthCount> enrollmentsByMonth)?  $default,) {final _that = this;
switch (_that) {
case _InstructorPerformance() when $default != null:
return $default(_that.rating,_that.ratingCount,_that.academyRating,_that.completion,_that.academyCompletion,_that.reviewHoursMedian,_that.reviewsOnTime,_that.reviewed,_that.toReview,_that.liveDelivered,_that.liveUpcoming,_that.attendance,_that.enrollmentsByMonth);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstructorPerformance extends InstructorPerformance {
  const _InstructorPerformance({this.rating, this.ratingCount = 0, this.academyRating = 0, this.completion, this.academyCompletion = 0, this.reviewHoursMedian, this.reviewsOnTime, this.reviewed = 0, this.toReview = 0, this.liveDelivered = 0, this.liveUpcoming = 0, this.attendance, final  List<MonthCount> enrollmentsByMonth = const <MonthCount>[]}): _enrollmentsByMonth = enrollmentsByMonth,super._();
  factory _InstructorPerformance.fromJson(Map<String, dynamic> json) => _$InstructorPerformanceFromJson(json);

@override final  double? rating;
@override@JsonKey() final  int ratingCount;
@override@JsonKey() final  double academyRating;
@override final  int? completion;
@override@JsonKey() final  int academyCompletion;
/// Median hours from hand-in to a decision; `null` until they have reviewed one.
@override final  int? reviewHoursMedian;
/// Percentage reviewed inside the academy's 48-hour window.
@override final  int? reviewsOnTime;
@override@JsonKey() final  int reviewed;
@override@JsonKey() final  int toReview;
@override@JsonKey() final  int liveDelivered;
@override@JsonKey() final  int liveUpcoming;
/// Percentage of registrations that attended; `null` until attendance was taken.
@override final  int? attendance;
 final  List<MonthCount> _enrollmentsByMonth;
@override@JsonKey() List<MonthCount> get enrollmentsByMonth {
  if (_enrollmentsByMonth is EqualUnmodifiableListView) return _enrollmentsByMonth;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_enrollmentsByMonth);
}


/// Create a copy of InstructorPerformance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstructorPerformanceCopyWith<_InstructorPerformance> get copyWith => __$InstructorPerformanceCopyWithImpl<_InstructorPerformance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstructorPerformanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstructorPerformance&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.academyRating, academyRating) || other.academyRating == academyRating)&&(identical(other.completion, completion) || other.completion == completion)&&(identical(other.academyCompletion, academyCompletion) || other.academyCompletion == academyCompletion)&&(identical(other.reviewHoursMedian, reviewHoursMedian) || other.reviewHoursMedian == reviewHoursMedian)&&(identical(other.reviewsOnTime, reviewsOnTime) || other.reviewsOnTime == reviewsOnTime)&&(identical(other.reviewed, reviewed) || other.reviewed == reviewed)&&(identical(other.toReview, toReview) || other.toReview == toReview)&&(identical(other.liveDelivered, liveDelivered) || other.liveDelivered == liveDelivered)&&(identical(other.liveUpcoming, liveUpcoming) || other.liveUpcoming == liveUpcoming)&&(identical(other.attendance, attendance) || other.attendance == attendance)&&const DeepCollectionEquality().equals(other._enrollmentsByMonth, _enrollmentsByMonth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rating,ratingCount,academyRating,completion,academyCompletion,reviewHoursMedian,reviewsOnTime,reviewed,toReview,liveDelivered,liveUpcoming,attendance,const DeepCollectionEquality().hash(_enrollmentsByMonth));

@override
String toString() {
  return 'InstructorPerformance(rating: $rating, ratingCount: $ratingCount, academyRating: $academyRating, completion: $completion, academyCompletion: $academyCompletion, reviewHoursMedian: $reviewHoursMedian, reviewsOnTime: $reviewsOnTime, reviewed: $reviewed, toReview: $toReview, liveDelivered: $liveDelivered, liveUpcoming: $liveUpcoming, attendance: $attendance, enrollmentsByMonth: $enrollmentsByMonth)';
}


}

/// @nodoc
abstract mixin class _$InstructorPerformanceCopyWith<$Res> implements $InstructorPerformanceCopyWith<$Res> {
  factory _$InstructorPerformanceCopyWith(_InstructorPerformance value, $Res Function(_InstructorPerformance) _then) = __$InstructorPerformanceCopyWithImpl;
@override @useResult
$Res call({
 double? rating, int ratingCount, double academyRating, int? completion, int academyCompletion, int? reviewHoursMedian, int? reviewsOnTime, int reviewed, int toReview, int liveDelivered, int liveUpcoming, int? attendance, List<MonthCount> enrollmentsByMonth
});




}
/// @nodoc
class __$InstructorPerformanceCopyWithImpl<$Res>
    implements _$InstructorPerformanceCopyWith<$Res> {
  __$InstructorPerformanceCopyWithImpl(this._self, this._then);

  final _InstructorPerformance _self;
  final $Res Function(_InstructorPerformance) _then;

/// Create a copy of InstructorPerformance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rating = freezed,Object? ratingCount = null,Object? academyRating = null,Object? completion = freezed,Object? academyCompletion = null,Object? reviewHoursMedian = freezed,Object? reviewsOnTime = freezed,Object? reviewed = null,Object? toReview = null,Object? liveDelivered = null,Object? liveUpcoming = null,Object? attendance = freezed,Object? enrollmentsByMonth = null,}) {
  return _then(_InstructorPerformance(
rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,academyRating: null == academyRating ? _self.academyRating : academyRating // ignore: cast_nullable_to_non_nullable
as double,completion: freezed == completion ? _self.completion : completion // ignore: cast_nullable_to_non_nullable
as int?,academyCompletion: null == academyCompletion ? _self.academyCompletion : academyCompletion // ignore: cast_nullable_to_non_nullable
as int,reviewHoursMedian: freezed == reviewHoursMedian ? _self.reviewHoursMedian : reviewHoursMedian // ignore: cast_nullable_to_non_nullable
as int?,reviewsOnTime: freezed == reviewsOnTime ? _self.reviewsOnTime : reviewsOnTime // ignore: cast_nullable_to_non_nullable
as int?,reviewed: null == reviewed ? _self.reviewed : reviewed // ignore: cast_nullable_to_non_nullable
as int,toReview: null == toReview ? _self.toReview : toReview // ignore: cast_nullable_to_non_nullable
as int,liveDelivered: null == liveDelivered ? _self.liveDelivered : liveDelivered // ignore: cast_nullable_to_non_nullable
as int,liveUpcoming: null == liveUpcoming ? _self.liveUpcoming : liveUpcoming // ignore: cast_nullable_to_non_nullable
as int,attendance: freezed == attendance ? _self.attendance : attendance // ignore: cast_nullable_to_non_nullable
as int?,enrollmentsByMonth: null == enrollmentsByMonth ? _self._enrollmentsByMonth : enrollmentsByMonth // ignore: cast_nullable_to_non_nullable
as List<MonthCount>,
  ));
}


}


/// @nodoc
mixin _$InstructorDetail {

 AcademyInstructor get instructor; List<InstructorCourse> get courses; InstructorReach get reach; InstructorPerformance get performance; List<AdminEvent> get activity;
/// Create a copy of InstructorDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstructorDetailCopyWith<InstructorDetail> get copyWith => _$InstructorDetailCopyWithImpl<InstructorDetail>(this as InstructorDetail, _$identity);

  /// Serializes this InstructorDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstructorDetail&&(identical(other.instructor, instructor) || other.instructor == instructor)&&const DeepCollectionEquality().equals(other.courses, courses)&&(identical(other.reach, reach) || other.reach == reach)&&(identical(other.performance, performance) || other.performance == performance)&&const DeepCollectionEquality().equals(other.activity, activity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,instructor,const DeepCollectionEquality().hash(courses),reach,performance,const DeepCollectionEquality().hash(activity));

@override
String toString() {
  return 'InstructorDetail(instructor: $instructor, courses: $courses, reach: $reach, performance: $performance, activity: $activity)';
}


}

/// @nodoc
abstract mixin class $InstructorDetailCopyWith<$Res>  {
  factory $InstructorDetailCopyWith(InstructorDetail value, $Res Function(InstructorDetail) _then) = _$InstructorDetailCopyWithImpl;
@useResult
$Res call({
 AcademyInstructor instructor, List<InstructorCourse> courses, InstructorReach reach, InstructorPerformance performance, List<AdminEvent> activity
});


$AcademyInstructorCopyWith<$Res> get instructor;$InstructorReachCopyWith<$Res> get reach;$InstructorPerformanceCopyWith<$Res> get performance;

}
/// @nodoc
class _$InstructorDetailCopyWithImpl<$Res>
    implements $InstructorDetailCopyWith<$Res> {
  _$InstructorDetailCopyWithImpl(this._self, this._then);

  final InstructorDetail _self;
  final $Res Function(InstructorDetail) _then;

/// Create a copy of InstructorDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? instructor = null,Object? courses = null,Object? reach = null,Object? performance = null,Object? activity = null,}) {
  return _then(_self.copyWith(
instructor: null == instructor ? _self.instructor : instructor // ignore: cast_nullable_to_non_nullable
as AcademyInstructor,courses: null == courses ? _self.courses : courses // ignore: cast_nullable_to_non_nullable
as List<InstructorCourse>,reach: null == reach ? _self.reach : reach // ignore: cast_nullable_to_non_nullable
as InstructorReach,performance: null == performance ? _self.performance : performance // ignore: cast_nullable_to_non_nullable
as InstructorPerformance,activity: null == activity ? _self.activity : activity // ignore: cast_nullable_to_non_nullable
as List<AdminEvent>,
  ));
}
/// Create a copy of InstructorDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AcademyInstructorCopyWith<$Res> get instructor {
  
  return $AcademyInstructorCopyWith<$Res>(_self.instructor, (value) {
    return _then(_self.copyWith(instructor: value));
  });
}/// Create a copy of InstructorDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstructorReachCopyWith<$Res> get reach {
  
  return $InstructorReachCopyWith<$Res>(_self.reach, (value) {
    return _then(_self.copyWith(reach: value));
  });
}/// Create a copy of InstructorDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstructorPerformanceCopyWith<$Res> get performance {
  
  return $InstructorPerformanceCopyWith<$Res>(_self.performance, (value) {
    return _then(_self.copyWith(performance: value));
  });
}
}


/// Adds pattern-matching-related methods to [InstructorDetail].
extension InstructorDetailPatterns on InstructorDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstructorDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstructorDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstructorDetail value)  $default,){
final _that = this;
switch (_that) {
case _InstructorDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstructorDetail value)?  $default,){
final _that = this;
switch (_that) {
case _InstructorDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AcademyInstructor instructor,  List<InstructorCourse> courses,  InstructorReach reach,  InstructorPerformance performance,  List<AdminEvent> activity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstructorDetail() when $default != null:
return $default(_that.instructor,_that.courses,_that.reach,_that.performance,_that.activity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AcademyInstructor instructor,  List<InstructorCourse> courses,  InstructorReach reach,  InstructorPerformance performance,  List<AdminEvent> activity)  $default,) {final _that = this;
switch (_that) {
case _InstructorDetail():
return $default(_that.instructor,_that.courses,_that.reach,_that.performance,_that.activity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AcademyInstructor instructor,  List<InstructorCourse> courses,  InstructorReach reach,  InstructorPerformance performance,  List<AdminEvent> activity)?  $default,) {final _that = this;
switch (_that) {
case _InstructorDetail() when $default != null:
return $default(_that.instructor,_that.courses,_that.reach,_that.performance,_that.activity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstructorDetail implements InstructorDetail {
  const _InstructorDetail({required this.instructor, final  List<InstructorCourse> courses = const <InstructorCourse>[], this.reach = const InstructorReach(), this.performance = const InstructorPerformance(), final  List<AdminEvent> activity = const <AdminEvent>[]}): _courses = courses,_activity = activity;
  factory _InstructorDetail.fromJson(Map<String, dynamic> json) => _$InstructorDetailFromJson(json);

@override final  AcademyInstructor instructor;
 final  List<InstructorCourse> _courses;
@override@JsonKey() List<InstructorCourse> get courses {
  if (_courses is EqualUnmodifiableListView) return _courses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_courses);
}

@override@JsonKey() final  InstructorReach reach;
@override@JsonKey() final  InstructorPerformance performance;
 final  List<AdminEvent> _activity;
@override@JsonKey() List<AdminEvent> get activity {
  if (_activity is EqualUnmodifiableListView) return _activity;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activity);
}


/// Create a copy of InstructorDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstructorDetailCopyWith<_InstructorDetail> get copyWith => __$InstructorDetailCopyWithImpl<_InstructorDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstructorDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstructorDetail&&(identical(other.instructor, instructor) || other.instructor == instructor)&&const DeepCollectionEquality().equals(other._courses, _courses)&&(identical(other.reach, reach) || other.reach == reach)&&(identical(other.performance, performance) || other.performance == performance)&&const DeepCollectionEquality().equals(other._activity, _activity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,instructor,const DeepCollectionEquality().hash(_courses),reach,performance,const DeepCollectionEquality().hash(_activity));

@override
String toString() {
  return 'InstructorDetail(instructor: $instructor, courses: $courses, reach: $reach, performance: $performance, activity: $activity)';
}


}

/// @nodoc
abstract mixin class _$InstructorDetailCopyWith<$Res> implements $InstructorDetailCopyWith<$Res> {
  factory _$InstructorDetailCopyWith(_InstructorDetail value, $Res Function(_InstructorDetail) _then) = __$InstructorDetailCopyWithImpl;
@override @useResult
$Res call({
 AcademyInstructor instructor, List<InstructorCourse> courses, InstructorReach reach, InstructorPerformance performance, List<AdminEvent> activity
});


@override $AcademyInstructorCopyWith<$Res> get instructor;@override $InstructorReachCopyWith<$Res> get reach;@override $InstructorPerformanceCopyWith<$Res> get performance;

}
/// @nodoc
class __$InstructorDetailCopyWithImpl<$Res>
    implements _$InstructorDetailCopyWith<$Res> {
  __$InstructorDetailCopyWithImpl(this._self, this._then);

  final _InstructorDetail _self;
  final $Res Function(_InstructorDetail) _then;

/// Create a copy of InstructorDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? instructor = null,Object? courses = null,Object? reach = null,Object? performance = null,Object? activity = null,}) {
  return _then(_InstructorDetail(
instructor: null == instructor ? _self.instructor : instructor // ignore: cast_nullable_to_non_nullable
as AcademyInstructor,courses: null == courses ? _self._courses : courses // ignore: cast_nullable_to_non_nullable
as List<InstructorCourse>,reach: null == reach ? _self.reach : reach // ignore: cast_nullable_to_non_nullable
as InstructorReach,performance: null == performance ? _self.performance : performance // ignore: cast_nullable_to_non_nullable
as InstructorPerformance,activity: null == activity ? _self._activity : activity // ignore: cast_nullable_to_non_nullable
as List<AdminEvent>,
  ));
}

/// Create a copy of InstructorDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AcademyInstructorCopyWith<$Res> get instructor {
  
  return $AcademyInstructorCopyWith<$Res>(_self.instructor, (value) {
    return _then(_self.copyWith(instructor: value));
  });
}/// Create a copy of InstructorDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstructorReachCopyWith<$Res> get reach {
  
  return $InstructorReachCopyWith<$Res>(_self.reach, (value) {
    return _then(_self.copyWith(reach: value));
  });
}/// Create a copy of InstructorDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstructorPerformanceCopyWith<$Res> get performance {
  
  return $InstructorPerformanceCopyWith<$Res>(_self.performance, (value) {
    return _then(_self.copyWith(performance: value));
  });
}
}

/// @nodoc
mixin _$InstructorForm {

 String get name; String get title; String get email; String get bio; List<String> get expertise; InstructorStatus get status; String get city; List<String> get languages; List<String> get courseIds; String? get phone; int? get yearsTeaching;
/// Create a copy of InstructorForm
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstructorFormCopyWith<InstructorForm> get copyWith => _$InstructorFormCopyWithImpl<InstructorForm>(this as InstructorForm, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstructorForm&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.email, email) || other.email == email)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other.expertise, expertise)&&(identical(other.status, status) || other.status == status)&&(identical(other.city, city) || other.city == city)&&const DeepCollectionEquality().equals(other.languages, languages)&&const DeepCollectionEquality().equals(other.courseIds, courseIds)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.yearsTeaching, yearsTeaching) || other.yearsTeaching == yearsTeaching));
}


@override
int get hashCode => Object.hash(runtimeType,name,title,email,bio,const DeepCollectionEquality().hash(expertise),status,city,const DeepCollectionEquality().hash(languages),const DeepCollectionEquality().hash(courseIds),phone,yearsTeaching);

@override
String toString() {
  return 'InstructorForm(name: $name, title: $title, email: $email, bio: $bio, expertise: $expertise, status: $status, city: $city, languages: $languages, courseIds: $courseIds, phone: $phone, yearsTeaching: $yearsTeaching)';
}


}

/// @nodoc
abstract mixin class $InstructorFormCopyWith<$Res>  {
  factory $InstructorFormCopyWith(InstructorForm value, $Res Function(InstructorForm) _then) = _$InstructorFormCopyWithImpl;
@useResult
$Res call({
 String name, String title, String email, String bio, List<String> expertise, InstructorStatus status, String city, List<String> languages, List<String> courseIds, String? phone, int? yearsTeaching
});




}
/// @nodoc
class _$InstructorFormCopyWithImpl<$Res>
    implements $InstructorFormCopyWith<$Res> {
  _$InstructorFormCopyWithImpl(this._self, this._then);

  final InstructorForm _self;
  final $Res Function(InstructorForm) _then;

/// Create a copy of InstructorForm
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? title = null,Object? email = null,Object? bio = null,Object? expertise = null,Object? status = null,Object? city = null,Object? languages = null,Object? courseIds = null,Object? phone = freezed,Object? yearsTeaching = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,expertise: null == expertise ? _self.expertise : expertise // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstructorStatus,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,languages: null == languages ? _self.languages : languages // ignore: cast_nullable_to_non_nullable
as List<String>,courseIds: null == courseIds ? _self.courseIds : courseIds // ignore: cast_nullable_to_non_nullable
as List<String>,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,yearsTeaching: freezed == yearsTeaching ? _self.yearsTeaching : yearsTeaching // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [InstructorForm].
extension InstructorFormPatterns on InstructorForm {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstructorForm value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstructorForm() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstructorForm value)  $default,){
final _that = this;
switch (_that) {
case _InstructorForm():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstructorForm value)?  $default,){
final _that = this;
switch (_that) {
case _InstructorForm() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String title,  String email,  String bio,  List<String> expertise,  InstructorStatus status,  String city,  List<String> languages,  List<String> courseIds,  String? phone,  int? yearsTeaching)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstructorForm() when $default != null:
return $default(_that.name,_that.title,_that.email,_that.bio,_that.expertise,_that.status,_that.city,_that.languages,_that.courseIds,_that.phone,_that.yearsTeaching);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String title,  String email,  String bio,  List<String> expertise,  InstructorStatus status,  String city,  List<String> languages,  List<String> courseIds,  String? phone,  int? yearsTeaching)  $default,) {final _that = this;
switch (_that) {
case _InstructorForm():
return $default(_that.name,_that.title,_that.email,_that.bio,_that.expertise,_that.status,_that.city,_that.languages,_that.courseIds,_that.phone,_that.yearsTeaching);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String title,  String email,  String bio,  List<String> expertise,  InstructorStatus status,  String city,  List<String> languages,  List<String> courseIds,  String? phone,  int? yearsTeaching)?  $default,) {final _that = this;
switch (_that) {
case _InstructorForm() when $default != null:
return $default(_that.name,_that.title,_that.email,_that.bio,_that.expertise,_that.status,_that.city,_that.languages,_that.courseIds,_that.phone,_that.yearsTeaching);case _:
  return null;

}
}

}

/// @nodoc


class _InstructorForm extends InstructorForm {
  const _InstructorForm({this.name = '', this.title = '', this.email = '', this.bio = '', final  List<String> expertise = const <String>[], this.status = InstructorStatus.invited, this.city = '', final  List<String> languages = const <String>[], final  List<String> courseIds = const <String>[], this.phone, this.yearsTeaching}): _expertise = expertise,_languages = languages,_courseIds = courseIds,super._();
  

@override@JsonKey() final  String name;
@override@JsonKey() final  String title;
@override@JsonKey() final  String email;
@override@JsonKey() final  String bio;
 final  List<String> _expertise;
@override@JsonKey() List<String> get expertise {
  if (_expertise is EqualUnmodifiableListView) return _expertise;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expertise);
}

@override@JsonKey() final  InstructorStatus status;
@override@JsonKey() final  String city;
 final  List<String> _languages;
@override@JsonKey() List<String> get languages {
  if (_languages is EqualUnmodifiableListView) return _languages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_languages);
}

 final  List<String> _courseIds;
@override@JsonKey() List<String> get courseIds {
  if (_courseIds is EqualUnmodifiableListView) return _courseIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_courseIds);
}

@override final  String? phone;
@override final  int? yearsTeaching;

/// Create a copy of InstructorForm
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstructorFormCopyWith<_InstructorForm> get copyWith => __$InstructorFormCopyWithImpl<_InstructorForm>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstructorForm&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.email, email) || other.email == email)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other._expertise, _expertise)&&(identical(other.status, status) || other.status == status)&&(identical(other.city, city) || other.city == city)&&const DeepCollectionEquality().equals(other._languages, _languages)&&const DeepCollectionEquality().equals(other._courseIds, _courseIds)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.yearsTeaching, yearsTeaching) || other.yearsTeaching == yearsTeaching));
}


@override
int get hashCode => Object.hash(runtimeType,name,title,email,bio,const DeepCollectionEquality().hash(_expertise),status,city,const DeepCollectionEquality().hash(_languages),const DeepCollectionEquality().hash(_courseIds),phone,yearsTeaching);

@override
String toString() {
  return 'InstructorForm(name: $name, title: $title, email: $email, bio: $bio, expertise: $expertise, status: $status, city: $city, languages: $languages, courseIds: $courseIds, phone: $phone, yearsTeaching: $yearsTeaching)';
}


}

/// @nodoc
abstract mixin class _$InstructorFormCopyWith<$Res> implements $InstructorFormCopyWith<$Res> {
  factory _$InstructorFormCopyWith(_InstructorForm value, $Res Function(_InstructorForm) _then) = __$InstructorFormCopyWithImpl;
@override @useResult
$Res call({
 String name, String title, String email, String bio, List<String> expertise, InstructorStatus status, String city, List<String> languages, List<String> courseIds, String? phone, int? yearsTeaching
});




}
/// @nodoc
class __$InstructorFormCopyWithImpl<$Res>
    implements _$InstructorFormCopyWith<$Res> {
  __$InstructorFormCopyWithImpl(this._self, this._then);

  final _InstructorForm _self;
  final $Res Function(_InstructorForm) _then;

/// Create a copy of InstructorForm
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? title = null,Object? email = null,Object? bio = null,Object? expertise = null,Object? status = null,Object? city = null,Object? languages = null,Object? courseIds = null,Object? phone = freezed,Object? yearsTeaching = freezed,}) {
  return _then(_InstructorForm(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,expertise: null == expertise ? _self._expertise : expertise // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstructorStatus,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,languages: null == languages ? _self._languages : languages // ignore: cast_nullable_to_non_nullable
as List<String>,courseIds: null == courseIds ? _self._courseIds : courseIds // ignore: cast_nullable_to_non_nullable
as List<String>,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,yearsTeaching: freezed == yearsTeaching ? _self.yearsTeaching : yearsTeaching // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
