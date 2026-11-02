// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LearnerQuizOption {

 String get id; String get text;
/// Create a copy of LearnerQuizOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearnerQuizOptionCopyWith<LearnerQuizOption> get copyWith => _$LearnerQuizOptionCopyWithImpl<LearnerQuizOption>(this as LearnerQuizOption, _$identity);

  /// Serializes this LearnerQuizOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearnerQuizOption&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text);

@override
String toString() {
  return 'LearnerQuizOption(id: $id, text: $text)';
}


}

/// @nodoc
abstract mixin class $LearnerQuizOptionCopyWith<$Res>  {
  factory $LearnerQuizOptionCopyWith(LearnerQuizOption value, $Res Function(LearnerQuizOption) _then) = _$LearnerQuizOptionCopyWithImpl;
@useResult
$Res call({
 String id, String text
});




}
/// @nodoc
class _$LearnerQuizOptionCopyWithImpl<$Res>
    implements $LearnerQuizOptionCopyWith<$Res> {
  _$LearnerQuizOptionCopyWithImpl(this._self, this._then);

  final LearnerQuizOption _self;
  final $Res Function(LearnerQuizOption) _then;

/// Create a copy of LearnerQuizOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LearnerQuizOption].
extension LearnerQuizOptionPatterns on LearnerQuizOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearnerQuizOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearnerQuizOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearnerQuizOption value)  $default,){
final _that = this;
switch (_that) {
case _LearnerQuizOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearnerQuizOption value)?  $default,){
final _that = this;
switch (_that) {
case _LearnerQuizOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearnerQuizOption() when $default != null:
return $default(_that.id,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String text)  $default,) {final _that = this;
switch (_that) {
case _LearnerQuizOption():
return $default(_that.id,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String text)?  $default,) {final _that = this;
switch (_that) {
case _LearnerQuizOption() when $default != null:
return $default(_that.id,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LearnerQuizOption implements LearnerQuizOption {
  const _LearnerQuizOption({required this.id, this.text = ''});
  factory _LearnerQuizOption.fromJson(Map<String, dynamic> json) => _$LearnerQuizOptionFromJson(json);

@override final  String id;
@override@JsonKey() final  String text;

/// Create a copy of LearnerQuizOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearnerQuizOptionCopyWith<_LearnerQuizOption> get copyWith => __$LearnerQuizOptionCopyWithImpl<_LearnerQuizOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearnerQuizOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearnerQuizOption&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text);

@override
String toString() {
  return 'LearnerQuizOption(id: $id, text: $text)';
}


}

/// @nodoc
abstract mixin class _$LearnerQuizOptionCopyWith<$Res> implements $LearnerQuizOptionCopyWith<$Res> {
  factory _$LearnerQuizOptionCopyWith(_LearnerQuizOption value, $Res Function(_LearnerQuizOption) _then) = __$LearnerQuizOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String text
});




}
/// @nodoc
class __$LearnerQuizOptionCopyWithImpl<$Res>
    implements _$LearnerQuizOptionCopyWith<$Res> {
  __$LearnerQuizOptionCopyWithImpl(this._self, this._then);

  final _LearnerQuizOption _self;
  final $Res Function(_LearnerQuizOption) _then;

/// Create a copy of LearnerQuizOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,}) {
  return _then(_LearnerQuizOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$LearnerQuizQuestion {

 String get id;@JsonKey(unknownEnumValue: QuestionType.unknown) QuestionType get type; String get prompt; List<LearnerQuizOption> get options; int get points; bool get required;/// Marks lost for a wrong answer — never for a blank one. Null or 0: none.
@JsonKey(includeIfNull: false) double? get negativePoints;
/// Create a copy of LearnerQuizQuestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearnerQuizQuestionCopyWith<LearnerQuizQuestion> get copyWith => _$LearnerQuizQuestionCopyWithImpl<LearnerQuizQuestion>(this as LearnerQuizQuestion, _$identity);

  /// Serializes this LearnerQuizQuestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearnerQuizQuestion&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&const DeepCollectionEquality().equals(other.options, options)&&(identical(other.points, points) || other.points == points)&&(identical(other.required, required) || other.required == required)&&(identical(other.negativePoints, negativePoints) || other.negativePoints == negativePoints));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,prompt,const DeepCollectionEquality().hash(options),points,required,negativePoints);

@override
String toString() {
  return 'LearnerQuizQuestion(id: $id, type: $type, prompt: $prompt, options: $options, points: $points, required: $required, negativePoints: $negativePoints)';
}


}

/// @nodoc
abstract mixin class $LearnerQuizQuestionCopyWith<$Res>  {
  factory $LearnerQuizQuestionCopyWith(LearnerQuizQuestion value, $Res Function(LearnerQuizQuestion) _then) = _$LearnerQuizQuestionCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: QuestionType.unknown) QuestionType type, String prompt, List<LearnerQuizOption> options, int points, bool required,@JsonKey(includeIfNull: false) double? negativePoints
});




}
/// @nodoc
class _$LearnerQuizQuestionCopyWithImpl<$Res>
    implements $LearnerQuizQuestionCopyWith<$Res> {
  _$LearnerQuizQuestionCopyWithImpl(this._self, this._then);

  final LearnerQuizQuestion _self;
  final $Res Function(LearnerQuizQuestion) _then;

/// Create a copy of LearnerQuizQuestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? prompt = null,Object? options = null,Object? points = null,Object? required = null,Object? negativePoints = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as QuestionType,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<LearnerQuizOption>,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,negativePoints: freezed == negativePoints ? _self.negativePoints : negativePoints // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [LearnerQuizQuestion].
extension LearnerQuizQuestionPatterns on LearnerQuizQuestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearnerQuizQuestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearnerQuizQuestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearnerQuizQuestion value)  $default,){
final _that = this;
switch (_that) {
case _LearnerQuizQuestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearnerQuizQuestion value)?  $default,){
final _that = this;
switch (_that) {
case _LearnerQuizQuestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: QuestionType.unknown)  QuestionType type,  String prompt,  List<LearnerQuizOption> options,  int points,  bool required, @JsonKey(includeIfNull: false)  double? negativePoints)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearnerQuizQuestion() when $default != null:
return $default(_that.id,_that.type,_that.prompt,_that.options,_that.points,_that.required,_that.negativePoints);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: QuestionType.unknown)  QuestionType type,  String prompt,  List<LearnerQuizOption> options,  int points,  bool required, @JsonKey(includeIfNull: false)  double? negativePoints)  $default,) {final _that = this;
switch (_that) {
case _LearnerQuizQuestion():
return $default(_that.id,_that.type,_that.prompt,_that.options,_that.points,_that.required,_that.negativePoints);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(unknownEnumValue: QuestionType.unknown)  QuestionType type,  String prompt,  List<LearnerQuizOption> options,  int points,  bool required, @JsonKey(includeIfNull: false)  double? negativePoints)?  $default,) {final _that = this;
switch (_that) {
case _LearnerQuizQuestion() when $default != null:
return $default(_that.id,_that.type,_that.prompt,_that.options,_that.points,_that.required,_that.negativePoints);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LearnerQuizQuestion extends LearnerQuizQuestion {
  const _LearnerQuizQuestion({required this.id, @JsonKey(unknownEnumValue: QuestionType.unknown) this.type = QuestionType.unknown, this.prompt = '', final  List<LearnerQuizOption> options = const <LearnerQuizOption>[], this.points = 0, this.required = false, @JsonKey(includeIfNull: false) this.negativePoints}): _options = options,super._();
  factory _LearnerQuizQuestion.fromJson(Map<String, dynamic> json) => _$LearnerQuizQuestionFromJson(json);

@override final  String id;
@override@JsonKey(unknownEnumValue: QuestionType.unknown) final  QuestionType type;
@override@JsonKey() final  String prompt;
 final  List<LearnerQuizOption> _options;
@override@JsonKey() List<LearnerQuizOption> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

@override@JsonKey() final  int points;
@override@JsonKey() final  bool required;
/// Marks lost for a wrong answer — never for a blank one. Null or 0: none.
@override@JsonKey(includeIfNull: false) final  double? negativePoints;

/// Create a copy of LearnerQuizQuestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearnerQuizQuestionCopyWith<_LearnerQuizQuestion> get copyWith => __$LearnerQuizQuestionCopyWithImpl<_LearnerQuizQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearnerQuizQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearnerQuizQuestion&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&const DeepCollectionEquality().equals(other._options, _options)&&(identical(other.points, points) || other.points == points)&&(identical(other.required, required) || other.required == required)&&(identical(other.negativePoints, negativePoints) || other.negativePoints == negativePoints));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,prompt,const DeepCollectionEquality().hash(_options),points,required,negativePoints);

@override
String toString() {
  return 'LearnerQuizQuestion(id: $id, type: $type, prompt: $prompt, options: $options, points: $points, required: $required, negativePoints: $negativePoints)';
}


}

/// @nodoc
abstract mixin class _$LearnerQuizQuestionCopyWith<$Res> implements $LearnerQuizQuestionCopyWith<$Res> {
  factory _$LearnerQuizQuestionCopyWith(_LearnerQuizQuestion value, $Res Function(_LearnerQuizQuestion) _then) = __$LearnerQuizQuestionCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: QuestionType.unknown) QuestionType type, String prompt, List<LearnerQuizOption> options, int points, bool required,@JsonKey(includeIfNull: false) double? negativePoints
});




}
/// @nodoc
class __$LearnerQuizQuestionCopyWithImpl<$Res>
    implements _$LearnerQuizQuestionCopyWith<$Res> {
  __$LearnerQuizQuestionCopyWithImpl(this._self, this._then);

  final _LearnerQuizQuestion _self;
  final $Res Function(_LearnerQuizQuestion) _then;

/// Create a copy of LearnerQuizQuestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? prompt = null,Object? options = null,Object? points = null,Object? required = null,Object? negativePoints = freezed,}) {
  return _then(_LearnerQuizQuestion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as QuestionType,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<LearnerQuizOption>,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,negativePoints: freezed == negativePoints ? _self.negativePoints : negativePoints // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$LearnerQuizSettings {

/// Percent of points needed to pass.
 int get passMark;/// 0 means unlimited.
 int get attempts; int? get timeLimitMin; bool get shuffleQuestions; bool get shuffleOptions;@JsonKey(unknownEnumValue: ResultsVisibility.unknown) ResultsVisibility get showResults;@JsonKey(unknownEnumValue: ResultsRelease.unknown) ResultsRelease get resultsRelease;/// No attempt starts before this moment, nor from [closesAt]; one under way when the quiz
/// closes is handed in with what was saved.
@NullableUtcDateTimeConverter() DateTime? get opensAt;@NullableUtcDateTimeConverter() DateTime? get closesAt;
/// Create a copy of LearnerQuizSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearnerQuizSettingsCopyWith<LearnerQuizSettings> get copyWith => _$LearnerQuizSettingsCopyWithImpl<LearnerQuizSettings>(this as LearnerQuizSettings, _$identity);

  /// Serializes this LearnerQuizSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearnerQuizSettings&&(identical(other.passMark, passMark) || other.passMark == passMark)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.timeLimitMin, timeLimitMin) || other.timeLimitMin == timeLimitMin)&&(identical(other.shuffleQuestions, shuffleQuestions) || other.shuffleQuestions == shuffleQuestions)&&(identical(other.shuffleOptions, shuffleOptions) || other.shuffleOptions == shuffleOptions)&&(identical(other.showResults, showResults) || other.showResults == showResults)&&(identical(other.resultsRelease, resultsRelease) || other.resultsRelease == resultsRelease)&&(identical(other.opensAt, opensAt) || other.opensAt == opensAt)&&(identical(other.closesAt, closesAt) || other.closesAt == closesAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,passMark,attempts,timeLimitMin,shuffleQuestions,shuffleOptions,showResults,resultsRelease,opensAt,closesAt);

@override
String toString() {
  return 'LearnerQuizSettings(passMark: $passMark, attempts: $attempts, timeLimitMin: $timeLimitMin, shuffleQuestions: $shuffleQuestions, shuffleOptions: $shuffleOptions, showResults: $showResults, resultsRelease: $resultsRelease, opensAt: $opensAt, closesAt: $closesAt)';
}


}

/// @nodoc
abstract mixin class $LearnerQuizSettingsCopyWith<$Res>  {
  factory $LearnerQuizSettingsCopyWith(LearnerQuizSettings value, $Res Function(LearnerQuizSettings) _then) = _$LearnerQuizSettingsCopyWithImpl;
@useResult
$Res call({
 int passMark, int attempts, int? timeLimitMin, bool shuffleQuestions, bool shuffleOptions,@JsonKey(unknownEnumValue: ResultsVisibility.unknown) ResultsVisibility showResults,@JsonKey(unknownEnumValue: ResultsRelease.unknown) ResultsRelease resultsRelease,@NullableUtcDateTimeConverter() DateTime? opensAt,@NullableUtcDateTimeConverter() DateTime? closesAt
});




}
/// @nodoc
class _$LearnerQuizSettingsCopyWithImpl<$Res>
    implements $LearnerQuizSettingsCopyWith<$Res> {
  _$LearnerQuizSettingsCopyWithImpl(this._self, this._then);

  final LearnerQuizSettings _self;
  final $Res Function(LearnerQuizSettings) _then;

/// Create a copy of LearnerQuizSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? passMark = null,Object? attempts = null,Object? timeLimitMin = freezed,Object? shuffleQuestions = null,Object? shuffleOptions = null,Object? showResults = null,Object? resultsRelease = null,Object? opensAt = freezed,Object? closesAt = freezed,}) {
  return _then(_self.copyWith(
passMark: null == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as int,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,timeLimitMin: freezed == timeLimitMin ? _self.timeLimitMin : timeLimitMin // ignore: cast_nullable_to_non_nullable
as int?,shuffleQuestions: null == shuffleQuestions ? _self.shuffleQuestions : shuffleQuestions // ignore: cast_nullable_to_non_nullable
as bool,shuffleOptions: null == shuffleOptions ? _self.shuffleOptions : shuffleOptions // ignore: cast_nullable_to_non_nullable
as bool,showResults: null == showResults ? _self.showResults : showResults // ignore: cast_nullable_to_non_nullable
as ResultsVisibility,resultsRelease: null == resultsRelease ? _self.resultsRelease : resultsRelease // ignore: cast_nullable_to_non_nullable
as ResultsRelease,opensAt: freezed == opensAt ? _self.opensAt : opensAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closesAt: freezed == closesAt ? _self.closesAt : closesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LearnerQuizSettings].
extension LearnerQuizSettingsPatterns on LearnerQuizSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearnerQuizSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearnerQuizSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearnerQuizSettings value)  $default,){
final _that = this;
switch (_that) {
case _LearnerQuizSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearnerQuizSettings value)?  $default,){
final _that = this;
switch (_that) {
case _LearnerQuizSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int passMark,  int attempts,  int? timeLimitMin,  bool shuffleQuestions,  bool shuffleOptions, @JsonKey(unknownEnumValue: ResultsVisibility.unknown)  ResultsVisibility showResults, @JsonKey(unknownEnumValue: ResultsRelease.unknown)  ResultsRelease resultsRelease, @NullableUtcDateTimeConverter()  DateTime? opensAt, @NullableUtcDateTimeConverter()  DateTime? closesAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearnerQuizSettings() when $default != null:
return $default(_that.passMark,_that.attempts,_that.timeLimitMin,_that.shuffleQuestions,_that.shuffleOptions,_that.showResults,_that.resultsRelease,_that.opensAt,_that.closesAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int passMark,  int attempts,  int? timeLimitMin,  bool shuffleQuestions,  bool shuffleOptions, @JsonKey(unknownEnumValue: ResultsVisibility.unknown)  ResultsVisibility showResults, @JsonKey(unknownEnumValue: ResultsRelease.unknown)  ResultsRelease resultsRelease, @NullableUtcDateTimeConverter()  DateTime? opensAt, @NullableUtcDateTimeConverter()  DateTime? closesAt)  $default,) {final _that = this;
switch (_that) {
case _LearnerQuizSettings():
return $default(_that.passMark,_that.attempts,_that.timeLimitMin,_that.shuffleQuestions,_that.shuffleOptions,_that.showResults,_that.resultsRelease,_that.opensAt,_that.closesAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int passMark,  int attempts,  int? timeLimitMin,  bool shuffleQuestions,  bool shuffleOptions, @JsonKey(unknownEnumValue: ResultsVisibility.unknown)  ResultsVisibility showResults, @JsonKey(unknownEnumValue: ResultsRelease.unknown)  ResultsRelease resultsRelease, @NullableUtcDateTimeConverter()  DateTime? opensAt, @NullableUtcDateTimeConverter()  DateTime? closesAt)?  $default,) {final _that = this;
switch (_that) {
case _LearnerQuizSettings() when $default != null:
return $default(_that.passMark,_that.attempts,_that.timeLimitMin,_that.shuffleQuestions,_that.shuffleOptions,_that.showResults,_that.resultsRelease,_that.opensAt,_that.closesAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LearnerQuizSettings implements LearnerQuizSettings {
  const _LearnerQuizSettings({this.passMark = 0, this.attempts = 0, this.timeLimitMin, this.shuffleQuestions = false, this.shuffleOptions = false, @JsonKey(unknownEnumValue: ResultsVisibility.unknown) this.showResults = ResultsVisibility.hidden, @JsonKey(unknownEnumValue: ResultsRelease.unknown) this.resultsRelease = ResultsRelease.onSubmit, @NullableUtcDateTimeConverter() this.opensAt, @NullableUtcDateTimeConverter() this.closesAt});
  factory _LearnerQuizSettings.fromJson(Map<String, dynamic> json) => _$LearnerQuizSettingsFromJson(json);

/// Percent of points needed to pass.
@override@JsonKey() final  int passMark;
/// 0 means unlimited.
@override@JsonKey() final  int attempts;
@override final  int? timeLimitMin;
@override@JsonKey() final  bool shuffleQuestions;
@override@JsonKey() final  bool shuffleOptions;
@override@JsonKey(unknownEnumValue: ResultsVisibility.unknown) final  ResultsVisibility showResults;
@override@JsonKey(unknownEnumValue: ResultsRelease.unknown) final  ResultsRelease resultsRelease;
/// No attempt starts before this moment, nor from [closesAt]; one under way when the quiz
/// closes is handed in with what was saved.
@override@NullableUtcDateTimeConverter() final  DateTime? opensAt;
@override@NullableUtcDateTimeConverter() final  DateTime? closesAt;

/// Create a copy of LearnerQuizSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearnerQuizSettingsCopyWith<_LearnerQuizSettings> get copyWith => __$LearnerQuizSettingsCopyWithImpl<_LearnerQuizSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearnerQuizSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearnerQuizSettings&&(identical(other.passMark, passMark) || other.passMark == passMark)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.timeLimitMin, timeLimitMin) || other.timeLimitMin == timeLimitMin)&&(identical(other.shuffleQuestions, shuffleQuestions) || other.shuffleQuestions == shuffleQuestions)&&(identical(other.shuffleOptions, shuffleOptions) || other.shuffleOptions == shuffleOptions)&&(identical(other.showResults, showResults) || other.showResults == showResults)&&(identical(other.resultsRelease, resultsRelease) || other.resultsRelease == resultsRelease)&&(identical(other.opensAt, opensAt) || other.opensAt == opensAt)&&(identical(other.closesAt, closesAt) || other.closesAt == closesAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,passMark,attempts,timeLimitMin,shuffleQuestions,shuffleOptions,showResults,resultsRelease,opensAt,closesAt);

@override
String toString() {
  return 'LearnerQuizSettings(passMark: $passMark, attempts: $attempts, timeLimitMin: $timeLimitMin, shuffleQuestions: $shuffleQuestions, shuffleOptions: $shuffleOptions, showResults: $showResults, resultsRelease: $resultsRelease, opensAt: $opensAt, closesAt: $closesAt)';
}


}

/// @nodoc
abstract mixin class _$LearnerQuizSettingsCopyWith<$Res> implements $LearnerQuizSettingsCopyWith<$Res> {
  factory _$LearnerQuizSettingsCopyWith(_LearnerQuizSettings value, $Res Function(_LearnerQuizSettings) _then) = __$LearnerQuizSettingsCopyWithImpl;
@override @useResult
$Res call({
 int passMark, int attempts, int? timeLimitMin, bool shuffleQuestions, bool shuffleOptions,@JsonKey(unknownEnumValue: ResultsVisibility.unknown) ResultsVisibility showResults,@JsonKey(unknownEnumValue: ResultsRelease.unknown) ResultsRelease resultsRelease,@NullableUtcDateTimeConverter() DateTime? opensAt,@NullableUtcDateTimeConverter() DateTime? closesAt
});




}
/// @nodoc
class __$LearnerQuizSettingsCopyWithImpl<$Res>
    implements _$LearnerQuizSettingsCopyWith<$Res> {
  __$LearnerQuizSettingsCopyWithImpl(this._self, this._then);

  final _LearnerQuizSettings _self;
  final $Res Function(_LearnerQuizSettings) _then;

/// Create a copy of LearnerQuizSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? passMark = null,Object? attempts = null,Object? timeLimitMin = freezed,Object? shuffleQuestions = null,Object? shuffleOptions = null,Object? showResults = null,Object? resultsRelease = null,Object? opensAt = freezed,Object? closesAt = freezed,}) {
  return _then(_LearnerQuizSettings(
passMark: null == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as int,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,timeLimitMin: freezed == timeLimitMin ? _self.timeLimitMin : timeLimitMin // ignore: cast_nullable_to_non_nullable
as int?,shuffleQuestions: null == shuffleQuestions ? _self.shuffleQuestions : shuffleQuestions // ignore: cast_nullable_to_non_nullable
as bool,shuffleOptions: null == shuffleOptions ? _self.shuffleOptions : shuffleOptions // ignore: cast_nullable_to_non_nullable
as bool,showResults: null == showResults ? _self.showResults : showResults // ignore: cast_nullable_to_non_nullable
as ResultsVisibility,resultsRelease: null == resultsRelease ? _self.resultsRelease : resultsRelease // ignore: cast_nullable_to_non_nullable
as ResultsRelease,opensAt: freezed == opensAt ? _self.opensAt : opensAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closesAt: freezed == closesAt ? _self.closesAt : closesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$LearnerQuiz {

 String get id; String get title; String get instructions; List<LearnerQuizQuestion> get questions; LearnerQuizSettings get settings;/// The server's own count of questions and points; null from a server before sessions.
@JsonKey(name: 'questionCount') int? get servedQuestionCount;@JsonKey(name: 'totalPoints') int? get servedTotalPoints;/// Attempts used so far, counting every session started.
 int get attemptsUsed;/// The attempt still open, to resume.
 QuizSessionView? get openSession;@JsonKey(unknownEnumValue: QuizWindow.unknown) QuizWindow get window;/// Some question costs marks for a wrong answer — said before an attempt is started.
 bool get negativeMarking;
/// Create a copy of LearnerQuiz
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearnerQuizCopyWith<LearnerQuiz> get copyWith => _$LearnerQuizCopyWithImpl<LearnerQuiz>(this as LearnerQuiz, _$identity);

  /// Serializes this LearnerQuiz to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearnerQuiz&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&const DeepCollectionEquality().equals(other.questions, questions)&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.servedQuestionCount, servedQuestionCount) || other.servedQuestionCount == servedQuestionCount)&&(identical(other.servedTotalPoints, servedTotalPoints) || other.servedTotalPoints == servedTotalPoints)&&(identical(other.attemptsUsed, attemptsUsed) || other.attemptsUsed == attemptsUsed)&&(identical(other.openSession, openSession) || other.openSession == openSession)&&(identical(other.window, window) || other.window == window)&&(identical(other.negativeMarking, negativeMarking) || other.negativeMarking == negativeMarking));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,instructions,const DeepCollectionEquality().hash(questions),settings,servedQuestionCount,servedTotalPoints,attemptsUsed,openSession,window,negativeMarking);

@override
String toString() {
  return 'LearnerQuiz(id: $id, title: $title, instructions: $instructions, questions: $questions, settings: $settings, servedQuestionCount: $servedQuestionCount, servedTotalPoints: $servedTotalPoints, attemptsUsed: $attemptsUsed, openSession: $openSession, window: $window, negativeMarking: $negativeMarking)';
}


}

/// @nodoc
abstract mixin class $LearnerQuizCopyWith<$Res>  {
  factory $LearnerQuizCopyWith(LearnerQuiz value, $Res Function(LearnerQuiz) _then) = _$LearnerQuizCopyWithImpl;
@useResult
$Res call({
 String id, String title, String instructions, List<LearnerQuizQuestion> questions, LearnerQuizSettings settings,@JsonKey(name: 'questionCount') int? servedQuestionCount,@JsonKey(name: 'totalPoints') int? servedTotalPoints, int attemptsUsed, QuizSessionView? openSession,@JsonKey(unknownEnumValue: QuizWindow.unknown) QuizWindow window, bool negativeMarking
});


$LearnerQuizSettingsCopyWith<$Res> get settings;$QuizSessionViewCopyWith<$Res>? get openSession;

}
/// @nodoc
class _$LearnerQuizCopyWithImpl<$Res>
    implements $LearnerQuizCopyWith<$Res> {
  _$LearnerQuizCopyWithImpl(this._self, this._then);

  final LearnerQuiz _self;
  final $Res Function(LearnerQuiz) _then;

/// Create a copy of LearnerQuiz
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? instructions = null,Object? questions = null,Object? settings = null,Object? servedQuestionCount = freezed,Object? servedTotalPoints = freezed,Object? attemptsUsed = null,Object? openSession = freezed,Object? window = null,Object? negativeMarking = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as List<LearnerQuizQuestion>,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as LearnerQuizSettings,servedQuestionCount: freezed == servedQuestionCount ? _self.servedQuestionCount : servedQuestionCount // ignore: cast_nullable_to_non_nullable
as int?,servedTotalPoints: freezed == servedTotalPoints ? _self.servedTotalPoints : servedTotalPoints // ignore: cast_nullable_to_non_nullable
as int?,attemptsUsed: null == attemptsUsed ? _self.attemptsUsed : attemptsUsed // ignore: cast_nullable_to_non_nullable
as int,openSession: freezed == openSession ? _self.openSession : openSession // ignore: cast_nullable_to_non_nullable
as QuizSessionView?,window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as QuizWindow,negativeMarking: null == negativeMarking ? _self.negativeMarking : negativeMarking // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of LearnerQuiz
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LearnerQuizSettingsCopyWith<$Res> get settings {
  
  return $LearnerQuizSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}/// Create a copy of LearnerQuiz
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizSessionViewCopyWith<$Res>? get openSession {
    if (_self.openSession == null) {
    return null;
  }

  return $QuizSessionViewCopyWith<$Res>(_self.openSession!, (value) {
    return _then(_self.copyWith(openSession: value));
  });
}
}


/// Adds pattern-matching-related methods to [LearnerQuiz].
extension LearnerQuizPatterns on LearnerQuiz {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearnerQuiz value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearnerQuiz() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearnerQuiz value)  $default,){
final _that = this;
switch (_that) {
case _LearnerQuiz():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearnerQuiz value)?  $default,){
final _that = this;
switch (_that) {
case _LearnerQuiz() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String instructions,  List<LearnerQuizQuestion> questions,  LearnerQuizSettings settings, @JsonKey(name: 'questionCount')  int? servedQuestionCount, @JsonKey(name: 'totalPoints')  int? servedTotalPoints,  int attemptsUsed,  QuizSessionView? openSession, @JsonKey(unknownEnumValue: QuizWindow.unknown)  QuizWindow window,  bool negativeMarking)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearnerQuiz() when $default != null:
return $default(_that.id,_that.title,_that.instructions,_that.questions,_that.settings,_that.servedQuestionCount,_that.servedTotalPoints,_that.attemptsUsed,_that.openSession,_that.window,_that.negativeMarking);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String instructions,  List<LearnerQuizQuestion> questions,  LearnerQuizSettings settings, @JsonKey(name: 'questionCount')  int? servedQuestionCount, @JsonKey(name: 'totalPoints')  int? servedTotalPoints,  int attemptsUsed,  QuizSessionView? openSession, @JsonKey(unknownEnumValue: QuizWindow.unknown)  QuizWindow window,  bool negativeMarking)  $default,) {final _that = this;
switch (_that) {
case _LearnerQuiz():
return $default(_that.id,_that.title,_that.instructions,_that.questions,_that.settings,_that.servedQuestionCount,_that.servedTotalPoints,_that.attemptsUsed,_that.openSession,_that.window,_that.negativeMarking);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String instructions,  List<LearnerQuizQuestion> questions,  LearnerQuizSettings settings, @JsonKey(name: 'questionCount')  int? servedQuestionCount, @JsonKey(name: 'totalPoints')  int? servedTotalPoints,  int attemptsUsed,  QuizSessionView? openSession, @JsonKey(unknownEnumValue: QuizWindow.unknown)  QuizWindow window,  bool negativeMarking)?  $default,) {final _that = this;
switch (_that) {
case _LearnerQuiz() when $default != null:
return $default(_that.id,_that.title,_that.instructions,_that.questions,_that.settings,_that.servedQuestionCount,_that.servedTotalPoints,_that.attemptsUsed,_that.openSession,_that.window,_that.negativeMarking);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LearnerQuiz extends LearnerQuiz {
  const _LearnerQuiz({required this.id, this.title = '', this.instructions = '', final  List<LearnerQuizQuestion> questions = const <LearnerQuizQuestion>[], this.settings = const LearnerQuizSettings(), @JsonKey(name: 'questionCount') this.servedQuestionCount, @JsonKey(name: 'totalPoints') this.servedTotalPoints, this.attemptsUsed = 0, this.openSession, @JsonKey(unknownEnumValue: QuizWindow.unknown) this.window = QuizWindow.open, this.negativeMarking = false}): _questions = questions,super._();
  factory _LearnerQuiz.fromJson(Map<String, dynamic> json) => _$LearnerQuizFromJson(json);

@override final  String id;
@override@JsonKey() final  String title;
@override@JsonKey() final  String instructions;
 final  List<LearnerQuizQuestion> _questions;
@override@JsonKey() List<LearnerQuizQuestion> get questions {
  if (_questions is EqualUnmodifiableListView) return _questions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_questions);
}

@override@JsonKey() final  LearnerQuizSettings settings;
/// The server's own count of questions and points; null from a server before sessions.
@override@JsonKey(name: 'questionCount') final  int? servedQuestionCount;
@override@JsonKey(name: 'totalPoints') final  int? servedTotalPoints;
/// Attempts used so far, counting every session started.
@override@JsonKey() final  int attemptsUsed;
/// The attempt still open, to resume.
@override final  QuizSessionView? openSession;
@override@JsonKey(unknownEnumValue: QuizWindow.unknown) final  QuizWindow window;
/// Some question costs marks for a wrong answer — said before an attempt is started.
@override@JsonKey() final  bool negativeMarking;

/// Create a copy of LearnerQuiz
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearnerQuizCopyWith<_LearnerQuiz> get copyWith => __$LearnerQuizCopyWithImpl<_LearnerQuiz>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearnerQuizToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearnerQuiz&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&const DeepCollectionEquality().equals(other._questions, _questions)&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.servedQuestionCount, servedQuestionCount) || other.servedQuestionCount == servedQuestionCount)&&(identical(other.servedTotalPoints, servedTotalPoints) || other.servedTotalPoints == servedTotalPoints)&&(identical(other.attemptsUsed, attemptsUsed) || other.attemptsUsed == attemptsUsed)&&(identical(other.openSession, openSession) || other.openSession == openSession)&&(identical(other.window, window) || other.window == window)&&(identical(other.negativeMarking, negativeMarking) || other.negativeMarking == negativeMarking));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,instructions,const DeepCollectionEquality().hash(_questions),settings,servedQuestionCount,servedTotalPoints,attemptsUsed,openSession,window,negativeMarking);

@override
String toString() {
  return 'LearnerQuiz(id: $id, title: $title, instructions: $instructions, questions: $questions, settings: $settings, servedQuestionCount: $servedQuestionCount, servedTotalPoints: $servedTotalPoints, attemptsUsed: $attemptsUsed, openSession: $openSession, window: $window, negativeMarking: $negativeMarking)';
}


}

/// @nodoc
abstract mixin class _$LearnerQuizCopyWith<$Res> implements $LearnerQuizCopyWith<$Res> {
  factory _$LearnerQuizCopyWith(_LearnerQuiz value, $Res Function(_LearnerQuiz) _then) = __$LearnerQuizCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String instructions, List<LearnerQuizQuestion> questions, LearnerQuizSettings settings,@JsonKey(name: 'questionCount') int? servedQuestionCount,@JsonKey(name: 'totalPoints') int? servedTotalPoints, int attemptsUsed, QuizSessionView? openSession,@JsonKey(unknownEnumValue: QuizWindow.unknown) QuizWindow window, bool negativeMarking
});


@override $LearnerQuizSettingsCopyWith<$Res> get settings;@override $QuizSessionViewCopyWith<$Res>? get openSession;

}
/// @nodoc
class __$LearnerQuizCopyWithImpl<$Res>
    implements _$LearnerQuizCopyWith<$Res> {
  __$LearnerQuizCopyWithImpl(this._self, this._then);

  final _LearnerQuiz _self;
  final $Res Function(_LearnerQuiz) _then;

/// Create a copy of LearnerQuiz
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? instructions = null,Object? questions = null,Object? settings = null,Object? servedQuestionCount = freezed,Object? servedTotalPoints = freezed,Object? attemptsUsed = null,Object? openSession = freezed,Object? window = null,Object? negativeMarking = null,}) {
  return _then(_LearnerQuiz(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,questions: null == questions ? _self._questions : questions // ignore: cast_nullable_to_non_nullable
as List<LearnerQuizQuestion>,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as LearnerQuizSettings,servedQuestionCount: freezed == servedQuestionCount ? _self.servedQuestionCount : servedQuestionCount // ignore: cast_nullable_to_non_nullable
as int?,servedTotalPoints: freezed == servedTotalPoints ? _self.servedTotalPoints : servedTotalPoints // ignore: cast_nullable_to_non_nullable
as int?,attemptsUsed: null == attemptsUsed ? _self.attemptsUsed : attemptsUsed // ignore: cast_nullable_to_non_nullable
as int,openSession: freezed == openSession ? _self.openSession : openSession // ignore: cast_nullable_to_non_nullable
as QuizSessionView?,window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as QuizWindow,negativeMarking: null == negativeMarking ? _self.negativeMarking : negativeMarking // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of LearnerQuiz
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LearnerQuizSettingsCopyWith<$Res> get settings {
  
  return $LearnerQuizSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}/// Create a copy of LearnerQuiz
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizSessionViewCopyWith<$Res>? get openSession {
    if (_self.openSession == null) {
    return null;
  }

  return $QuizSessionViewCopyWith<$Res>(_self.openSession!, (value) {
    return _then(_self.copyWith(openSession: value));
  });
}
}


/// @nodoc
mixin _$QuizSessionView {

 String get id; String get quizId; int get attemptNo;@JsonKey(unknownEnumValue: QuizSessionStatus.unknown) QuizSessionStatus get status;@UtcDateTimeConverter() DateTime get startedAt;/// Absent for an untimed quiz.
@NullableUtcDateTimeConverter() DateTime? get deadlineAt;/// The server's clock when it answered.
@NullableUtcDateTimeConverter() DateTime? get serverNow;/// Whole seconds to the deadline by the server's clock, never below 0; null when untimed.
 int? get remainingSec;/// The answers the server holds: option-id lists for choice questions, text for written ones.
 Map<String, dynamic> get answers;/// The highest save number the server has accepted. A save numbered no higher is ignored.
 int get answersSeq;@NullableUtcDateTimeConverter() DateTime? get savedAt;@NullableUtcDateTimeConverter() DateTime? get finishedAt;/// The scored attempt, once the session is finished.
 String? get attemptId;
/// Create a copy of QuizSessionView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizSessionViewCopyWith<QuizSessionView> get copyWith => _$QuizSessionViewCopyWithImpl<QuizSessionView>(this as QuizSessionView, _$identity);

  /// Serializes this QuizSessionView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizSessionView&&(identical(other.id, id) || other.id == id)&&(identical(other.quizId, quizId) || other.quizId == quizId)&&(identical(other.attemptNo, attemptNo) || other.attemptNo == attemptNo)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.deadlineAt, deadlineAt) || other.deadlineAt == deadlineAt)&&(identical(other.serverNow, serverNow) || other.serverNow == serverNow)&&(identical(other.remainingSec, remainingSec) || other.remainingSec == remainingSec)&&const DeepCollectionEquality().equals(other.answers, answers)&&(identical(other.answersSeq, answersSeq) || other.answersSeq == answersSeq)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.attemptId, attemptId) || other.attemptId == attemptId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,quizId,attemptNo,status,startedAt,deadlineAt,serverNow,remainingSec,const DeepCollectionEquality().hash(answers),answersSeq,savedAt,finishedAt,attemptId);

@override
String toString() {
  return 'QuizSessionView(id: $id, quizId: $quizId, attemptNo: $attemptNo, status: $status, startedAt: $startedAt, deadlineAt: $deadlineAt, serverNow: $serverNow, remainingSec: $remainingSec, answers: $answers, answersSeq: $answersSeq, savedAt: $savedAt, finishedAt: $finishedAt, attemptId: $attemptId)';
}


}

/// @nodoc
abstract mixin class $QuizSessionViewCopyWith<$Res>  {
  factory $QuizSessionViewCopyWith(QuizSessionView value, $Res Function(QuizSessionView) _then) = _$QuizSessionViewCopyWithImpl;
@useResult
$Res call({
 String id, String quizId, int attemptNo,@JsonKey(unknownEnumValue: QuizSessionStatus.unknown) QuizSessionStatus status,@UtcDateTimeConverter() DateTime startedAt,@NullableUtcDateTimeConverter() DateTime? deadlineAt,@NullableUtcDateTimeConverter() DateTime? serverNow, int? remainingSec, Map<String, dynamic> answers, int answersSeq,@NullableUtcDateTimeConverter() DateTime? savedAt,@NullableUtcDateTimeConverter() DateTime? finishedAt, String? attemptId
});




}
/// @nodoc
class _$QuizSessionViewCopyWithImpl<$Res>
    implements $QuizSessionViewCopyWith<$Res> {
  _$QuizSessionViewCopyWithImpl(this._self, this._then);

  final QuizSessionView _self;
  final $Res Function(QuizSessionView) _then;

/// Create a copy of QuizSessionView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? quizId = null,Object? attemptNo = null,Object? status = null,Object? startedAt = null,Object? deadlineAt = freezed,Object? serverNow = freezed,Object? remainingSec = freezed,Object? answers = null,Object? answersSeq = null,Object? savedAt = freezed,Object? finishedAt = freezed,Object? attemptId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,quizId: null == quizId ? _self.quizId : quizId // ignore: cast_nullable_to_non_nullable
as String,attemptNo: null == attemptNo ? _self.attemptNo : attemptNo // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QuizSessionStatus,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deadlineAt: freezed == deadlineAt ? _self.deadlineAt : deadlineAt // ignore: cast_nullable_to_non_nullable
as DateTime?,serverNow: freezed == serverNow ? _self.serverNow : serverNow // ignore: cast_nullable_to_non_nullable
as DateTime?,remainingSec: freezed == remainingSec ? _self.remainingSec : remainingSec // ignore: cast_nullable_to_non_nullable
as int?,answers: null == answers ? _self.answers : answers // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,answersSeq: null == answersSeq ? _self.answersSeq : answersSeq // ignore: cast_nullable_to_non_nullable
as int,savedAt: freezed == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,attemptId: freezed == attemptId ? _self.attemptId : attemptId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuizSessionView].
extension QuizSessionViewPatterns on QuizSessionView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizSessionView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizSessionView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizSessionView value)  $default,){
final _that = this;
switch (_that) {
case _QuizSessionView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizSessionView value)?  $default,){
final _that = this;
switch (_that) {
case _QuizSessionView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String quizId,  int attemptNo, @JsonKey(unknownEnumValue: QuizSessionStatus.unknown)  QuizSessionStatus status, @UtcDateTimeConverter()  DateTime startedAt, @NullableUtcDateTimeConverter()  DateTime? deadlineAt, @NullableUtcDateTimeConverter()  DateTime? serverNow,  int? remainingSec,  Map<String, dynamic> answers,  int answersSeq, @NullableUtcDateTimeConverter()  DateTime? savedAt, @NullableUtcDateTimeConverter()  DateTime? finishedAt,  String? attemptId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizSessionView() when $default != null:
return $default(_that.id,_that.quizId,_that.attemptNo,_that.status,_that.startedAt,_that.deadlineAt,_that.serverNow,_that.remainingSec,_that.answers,_that.answersSeq,_that.savedAt,_that.finishedAt,_that.attemptId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String quizId,  int attemptNo, @JsonKey(unknownEnumValue: QuizSessionStatus.unknown)  QuizSessionStatus status, @UtcDateTimeConverter()  DateTime startedAt, @NullableUtcDateTimeConverter()  DateTime? deadlineAt, @NullableUtcDateTimeConverter()  DateTime? serverNow,  int? remainingSec,  Map<String, dynamic> answers,  int answersSeq, @NullableUtcDateTimeConverter()  DateTime? savedAt, @NullableUtcDateTimeConverter()  DateTime? finishedAt,  String? attemptId)  $default,) {final _that = this;
switch (_that) {
case _QuizSessionView():
return $default(_that.id,_that.quizId,_that.attemptNo,_that.status,_that.startedAt,_that.deadlineAt,_that.serverNow,_that.remainingSec,_that.answers,_that.answersSeq,_that.savedAt,_that.finishedAt,_that.attemptId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String quizId,  int attemptNo, @JsonKey(unknownEnumValue: QuizSessionStatus.unknown)  QuizSessionStatus status, @UtcDateTimeConverter()  DateTime startedAt, @NullableUtcDateTimeConverter()  DateTime? deadlineAt, @NullableUtcDateTimeConverter()  DateTime? serverNow,  int? remainingSec,  Map<String, dynamic> answers,  int answersSeq, @NullableUtcDateTimeConverter()  DateTime? savedAt, @NullableUtcDateTimeConverter()  DateTime? finishedAt,  String? attemptId)?  $default,) {final _that = this;
switch (_that) {
case _QuizSessionView() when $default != null:
return $default(_that.id,_that.quizId,_that.attemptNo,_that.status,_that.startedAt,_that.deadlineAt,_that.serverNow,_that.remainingSec,_that.answers,_that.answersSeq,_that.savedAt,_that.finishedAt,_that.attemptId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizSessionView extends QuizSessionView {
  const _QuizSessionView({required this.id, this.quizId = '', this.attemptNo = 1, @JsonKey(unknownEnumValue: QuizSessionStatus.unknown) this.status = QuizSessionStatus.unknown, @UtcDateTimeConverter() required this.startedAt, @NullableUtcDateTimeConverter() this.deadlineAt, @NullableUtcDateTimeConverter() this.serverNow, this.remainingSec, final  Map<String, dynamic> answers = const <String, dynamic>{}, this.answersSeq = 0, @NullableUtcDateTimeConverter() this.savedAt, @NullableUtcDateTimeConverter() this.finishedAt, this.attemptId}): _answers = answers,super._();
  factory _QuizSessionView.fromJson(Map<String, dynamic> json) => _$QuizSessionViewFromJson(json);

@override final  String id;
@override@JsonKey() final  String quizId;
@override@JsonKey() final  int attemptNo;
@override@JsonKey(unknownEnumValue: QuizSessionStatus.unknown) final  QuizSessionStatus status;
@override@UtcDateTimeConverter() final  DateTime startedAt;
/// Absent for an untimed quiz.
@override@NullableUtcDateTimeConverter() final  DateTime? deadlineAt;
/// The server's clock when it answered.
@override@NullableUtcDateTimeConverter() final  DateTime? serverNow;
/// Whole seconds to the deadline by the server's clock, never below 0; null when untimed.
@override final  int? remainingSec;
/// The answers the server holds: option-id lists for choice questions, text for written ones.
 final  Map<String, dynamic> _answers;
/// The answers the server holds: option-id lists for choice questions, text for written ones.
@override@JsonKey() Map<String, dynamic> get answers {
  if (_answers is EqualUnmodifiableMapView) return _answers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_answers);
}

/// The highest save number the server has accepted. A save numbered no higher is ignored.
@override@JsonKey() final  int answersSeq;
@override@NullableUtcDateTimeConverter() final  DateTime? savedAt;
@override@NullableUtcDateTimeConverter() final  DateTime? finishedAt;
/// The scored attempt, once the session is finished.
@override final  String? attemptId;

/// Create a copy of QuizSessionView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizSessionViewCopyWith<_QuizSessionView> get copyWith => __$QuizSessionViewCopyWithImpl<_QuizSessionView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizSessionViewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizSessionView&&(identical(other.id, id) || other.id == id)&&(identical(other.quizId, quizId) || other.quizId == quizId)&&(identical(other.attemptNo, attemptNo) || other.attemptNo == attemptNo)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.deadlineAt, deadlineAt) || other.deadlineAt == deadlineAt)&&(identical(other.serverNow, serverNow) || other.serverNow == serverNow)&&(identical(other.remainingSec, remainingSec) || other.remainingSec == remainingSec)&&const DeepCollectionEquality().equals(other._answers, _answers)&&(identical(other.answersSeq, answersSeq) || other.answersSeq == answersSeq)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.attemptId, attemptId) || other.attemptId == attemptId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,quizId,attemptNo,status,startedAt,deadlineAt,serverNow,remainingSec,const DeepCollectionEquality().hash(_answers),answersSeq,savedAt,finishedAt,attemptId);

@override
String toString() {
  return 'QuizSessionView(id: $id, quizId: $quizId, attemptNo: $attemptNo, status: $status, startedAt: $startedAt, deadlineAt: $deadlineAt, serverNow: $serverNow, remainingSec: $remainingSec, answers: $answers, answersSeq: $answersSeq, savedAt: $savedAt, finishedAt: $finishedAt, attemptId: $attemptId)';
}


}

/// @nodoc
abstract mixin class _$QuizSessionViewCopyWith<$Res> implements $QuizSessionViewCopyWith<$Res> {
  factory _$QuizSessionViewCopyWith(_QuizSessionView value, $Res Function(_QuizSessionView) _then) = __$QuizSessionViewCopyWithImpl;
@override @useResult
$Res call({
 String id, String quizId, int attemptNo,@JsonKey(unknownEnumValue: QuizSessionStatus.unknown) QuizSessionStatus status,@UtcDateTimeConverter() DateTime startedAt,@NullableUtcDateTimeConverter() DateTime? deadlineAt,@NullableUtcDateTimeConverter() DateTime? serverNow, int? remainingSec, Map<String, dynamic> answers, int answersSeq,@NullableUtcDateTimeConverter() DateTime? savedAt,@NullableUtcDateTimeConverter() DateTime? finishedAt, String? attemptId
});




}
/// @nodoc
class __$QuizSessionViewCopyWithImpl<$Res>
    implements _$QuizSessionViewCopyWith<$Res> {
  __$QuizSessionViewCopyWithImpl(this._self, this._then);

  final _QuizSessionView _self;
  final $Res Function(_QuizSessionView) _then;

/// Create a copy of QuizSessionView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? quizId = null,Object? attemptNo = null,Object? status = null,Object? startedAt = null,Object? deadlineAt = freezed,Object? serverNow = freezed,Object? remainingSec = freezed,Object? answers = null,Object? answersSeq = null,Object? savedAt = freezed,Object? finishedAt = freezed,Object? attemptId = freezed,}) {
  return _then(_QuizSessionView(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,quizId: null == quizId ? _self.quizId : quizId // ignore: cast_nullable_to_non_nullable
as String,attemptNo: null == attemptNo ? _self.attemptNo : attemptNo // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QuizSessionStatus,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deadlineAt: freezed == deadlineAt ? _self.deadlineAt : deadlineAt // ignore: cast_nullable_to_non_nullable
as DateTime?,serverNow: freezed == serverNow ? _self.serverNow : serverNow // ignore: cast_nullable_to_non_nullable
as DateTime?,remainingSec: freezed == remainingSec ? _self.remainingSec : remainingSec // ignore: cast_nullable_to_non_nullable
as int?,answers: null == answers ? _self._answers : answers // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,answersSeq: null == answersSeq ? _self.answersSeq : answersSeq // ignore: cast_nullable_to_non_nullable
as int,savedAt: freezed == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,attemptId: freezed == attemptId ? _self.attemptId : attemptId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$QuizSessionStart {

 QuizSessionView get session; List<LearnerQuizQuestion> get questions;/// True when an open session was picked up again instead of a new attempt being started.
 bool get resumed;
/// Create a copy of QuizSessionStart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizSessionStartCopyWith<QuizSessionStart> get copyWith => _$QuizSessionStartCopyWithImpl<QuizSessionStart>(this as QuizSessionStart, _$identity);

  /// Serializes this QuizSessionStart to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizSessionStart&&(identical(other.session, session) || other.session == session)&&const DeepCollectionEquality().equals(other.questions, questions)&&(identical(other.resumed, resumed) || other.resumed == resumed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,session,const DeepCollectionEquality().hash(questions),resumed);

@override
String toString() {
  return 'QuizSessionStart(session: $session, questions: $questions, resumed: $resumed)';
}


}

/// @nodoc
abstract mixin class $QuizSessionStartCopyWith<$Res>  {
  factory $QuizSessionStartCopyWith(QuizSessionStart value, $Res Function(QuizSessionStart) _then) = _$QuizSessionStartCopyWithImpl;
@useResult
$Res call({
 QuizSessionView session, List<LearnerQuizQuestion> questions, bool resumed
});


$QuizSessionViewCopyWith<$Res> get session;

}
/// @nodoc
class _$QuizSessionStartCopyWithImpl<$Res>
    implements $QuizSessionStartCopyWith<$Res> {
  _$QuizSessionStartCopyWithImpl(this._self, this._then);

  final QuizSessionStart _self;
  final $Res Function(QuizSessionStart) _then;

/// Create a copy of QuizSessionStart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? session = null,Object? questions = null,Object? resumed = null,}) {
  return _then(_self.copyWith(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as QuizSessionView,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as List<LearnerQuizQuestion>,resumed: null == resumed ? _self.resumed : resumed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of QuizSessionStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizSessionViewCopyWith<$Res> get session {
  
  return $QuizSessionViewCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}


/// Adds pattern-matching-related methods to [QuizSessionStart].
extension QuizSessionStartPatterns on QuizSessionStart {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizSessionStart value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizSessionStart() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizSessionStart value)  $default,){
final _that = this;
switch (_that) {
case _QuizSessionStart():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizSessionStart value)?  $default,){
final _that = this;
switch (_that) {
case _QuizSessionStart() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( QuizSessionView session,  List<LearnerQuizQuestion> questions,  bool resumed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizSessionStart() when $default != null:
return $default(_that.session,_that.questions,_that.resumed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( QuizSessionView session,  List<LearnerQuizQuestion> questions,  bool resumed)  $default,) {final _that = this;
switch (_that) {
case _QuizSessionStart():
return $default(_that.session,_that.questions,_that.resumed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( QuizSessionView session,  List<LearnerQuizQuestion> questions,  bool resumed)?  $default,) {final _that = this;
switch (_that) {
case _QuizSessionStart() when $default != null:
return $default(_that.session,_that.questions,_that.resumed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizSessionStart implements QuizSessionStart {
  const _QuizSessionStart({required this.session, final  List<LearnerQuizQuestion> questions = const <LearnerQuizQuestion>[], this.resumed = false}): _questions = questions;
  factory _QuizSessionStart.fromJson(Map<String, dynamic> json) => _$QuizSessionStartFromJson(json);

@override final  QuizSessionView session;
 final  List<LearnerQuizQuestion> _questions;
@override@JsonKey() List<LearnerQuizQuestion> get questions {
  if (_questions is EqualUnmodifiableListView) return _questions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_questions);
}

/// True when an open session was picked up again instead of a new attempt being started.
@override@JsonKey() final  bool resumed;

/// Create a copy of QuizSessionStart
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizSessionStartCopyWith<_QuizSessionStart> get copyWith => __$QuizSessionStartCopyWithImpl<_QuizSessionStart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizSessionStartToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizSessionStart&&(identical(other.session, session) || other.session == session)&&const DeepCollectionEquality().equals(other._questions, _questions)&&(identical(other.resumed, resumed) || other.resumed == resumed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,session,const DeepCollectionEquality().hash(_questions),resumed);

@override
String toString() {
  return 'QuizSessionStart(session: $session, questions: $questions, resumed: $resumed)';
}


}

/// @nodoc
abstract mixin class _$QuizSessionStartCopyWith<$Res> implements $QuizSessionStartCopyWith<$Res> {
  factory _$QuizSessionStartCopyWith(_QuizSessionStart value, $Res Function(_QuizSessionStart) _then) = __$QuizSessionStartCopyWithImpl;
@override @useResult
$Res call({
 QuizSessionView session, List<LearnerQuizQuestion> questions, bool resumed
});


@override $QuizSessionViewCopyWith<$Res> get session;

}
/// @nodoc
class __$QuizSessionStartCopyWithImpl<$Res>
    implements _$QuizSessionStartCopyWith<$Res> {
  __$QuizSessionStartCopyWithImpl(this._self, this._then);

  final _QuizSessionStart _self;
  final $Res Function(_QuizSessionStart) _then;

/// Create a copy of QuizSessionStart
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? session = null,Object? questions = null,Object? resumed = null,}) {
  return _then(_QuizSessionStart(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as QuizSessionView,questions: null == questions ? _self._questions : questions // ignore: cast_nullable_to_non_nullable
as List<LearnerQuizQuestion>,resumed: null == resumed ? _self.resumed : resumed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of QuizSessionStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizSessionViewCopyWith<$Res> get session {
  
  return $QuizSessionViewCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}


/// @nodoc
mixin _$QuizStanding {

 String get quizId;@NullableUtcDateTimeConverter() DateTime? get serverNow;@JsonKey(unknownEnumValue: QuizWindow.unknown) QuizWindow get window;@NullableUtcDateTimeConverter() DateTime? get opensAt;@NullableUtcDateTimeConverter() DateTime? get closesAt;/// 0 means unlimited. Once passed, more attempts are practice and not limited.
 int get attemptsAllowed; int get attemptsUsed; bool get passed;/// The attempt still open, to resume.
 QuizSessionView? get openSession;/// True when an attempt is open to resume or a new one may start.
 bool get canStart;/// Why not, in the academy's words.
 String? get blockedReason;/// While results are held until the quiz closes: when they are shown.
@NullableUtcDateTimeConverter() DateTime? get resultsAt;
/// Create a copy of QuizStanding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizStandingCopyWith<QuizStanding> get copyWith => _$QuizStandingCopyWithImpl<QuizStanding>(this as QuizStanding, _$identity);

  /// Serializes this QuizStanding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizStanding&&(identical(other.quizId, quizId) || other.quizId == quizId)&&(identical(other.serverNow, serverNow) || other.serverNow == serverNow)&&(identical(other.window, window) || other.window == window)&&(identical(other.opensAt, opensAt) || other.opensAt == opensAt)&&(identical(other.closesAt, closesAt) || other.closesAt == closesAt)&&(identical(other.attemptsAllowed, attemptsAllowed) || other.attemptsAllowed == attemptsAllowed)&&(identical(other.attemptsUsed, attemptsUsed) || other.attemptsUsed == attemptsUsed)&&(identical(other.passed, passed) || other.passed == passed)&&(identical(other.openSession, openSession) || other.openSession == openSession)&&(identical(other.canStart, canStart) || other.canStart == canStart)&&(identical(other.blockedReason, blockedReason) || other.blockedReason == blockedReason)&&(identical(other.resultsAt, resultsAt) || other.resultsAt == resultsAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quizId,serverNow,window,opensAt,closesAt,attemptsAllowed,attemptsUsed,passed,openSession,canStart,blockedReason,resultsAt);

@override
String toString() {
  return 'QuizStanding(quizId: $quizId, serverNow: $serverNow, window: $window, opensAt: $opensAt, closesAt: $closesAt, attemptsAllowed: $attemptsAllowed, attemptsUsed: $attemptsUsed, passed: $passed, openSession: $openSession, canStart: $canStart, blockedReason: $blockedReason, resultsAt: $resultsAt)';
}


}

/// @nodoc
abstract mixin class $QuizStandingCopyWith<$Res>  {
  factory $QuizStandingCopyWith(QuizStanding value, $Res Function(QuizStanding) _then) = _$QuizStandingCopyWithImpl;
@useResult
$Res call({
 String quizId,@NullableUtcDateTimeConverter() DateTime? serverNow,@JsonKey(unknownEnumValue: QuizWindow.unknown) QuizWindow window,@NullableUtcDateTimeConverter() DateTime? opensAt,@NullableUtcDateTimeConverter() DateTime? closesAt, int attemptsAllowed, int attemptsUsed, bool passed, QuizSessionView? openSession, bool canStart, String? blockedReason,@NullableUtcDateTimeConverter() DateTime? resultsAt
});


$QuizSessionViewCopyWith<$Res>? get openSession;

}
/// @nodoc
class _$QuizStandingCopyWithImpl<$Res>
    implements $QuizStandingCopyWith<$Res> {
  _$QuizStandingCopyWithImpl(this._self, this._then);

  final QuizStanding _self;
  final $Res Function(QuizStanding) _then;

/// Create a copy of QuizStanding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quizId = null,Object? serverNow = freezed,Object? window = null,Object? opensAt = freezed,Object? closesAt = freezed,Object? attemptsAllowed = null,Object? attemptsUsed = null,Object? passed = null,Object? openSession = freezed,Object? canStart = null,Object? blockedReason = freezed,Object? resultsAt = freezed,}) {
  return _then(_self.copyWith(
quizId: null == quizId ? _self.quizId : quizId // ignore: cast_nullable_to_non_nullable
as String,serverNow: freezed == serverNow ? _self.serverNow : serverNow // ignore: cast_nullable_to_non_nullable
as DateTime?,window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as QuizWindow,opensAt: freezed == opensAt ? _self.opensAt : opensAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closesAt: freezed == closesAt ? _self.closesAt : closesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,attemptsAllowed: null == attemptsAllowed ? _self.attemptsAllowed : attemptsAllowed // ignore: cast_nullable_to_non_nullable
as int,attemptsUsed: null == attemptsUsed ? _self.attemptsUsed : attemptsUsed // ignore: cast_nullable_to_non_nullable
as int,passed: null == passed ? _self.passed : passed // ignore: cast_nullable_to_non_nullable
as bool,openSession: freezed == openSession ? _self.openSession : openSession // ignore: cast_nullable_to_non_nullable
as QuizSessionView?,canStart: null == canStart ? _self.canStart : canStart // ignore: cast_nullable_to_non_nullable
as bool,blockedReason: freezed == blockedReason ? _self.blockedReason : blockedReason // ignore: cast_nullable_to_non_nullable
as String?,resultsAt: freezed == resultsAt ? _self.resultsAt : resultsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of QuizStanding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizSessionViewCopyWith<$Res>? get openSession {
    if (_self.openSession == null) {
    return null;
  }

  return $QuizSessionViewCopyWith<$Res>(_self.openSession!, (value) {
    return _then(_self.copyWith(openSession: value));
  });
}
}


/// Adds pattern-matching-related methods to [QuizStanding].
extension QuizStandingPatterns on QuizStanding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizStanding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizStanding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizStanding value)  $default,){
final _that = this;
switch (_that) {
case _QuizStanding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizStanding value)?  $default,){
final _that = this;
switch (_that) {
case _QuizStanding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String quizId, @NullableUtcDateTimeConverter()  DateTime? serverNow, @JsonKey(unknownEnumValue: QuizWindow.unknown)  QuizWindow window, @NullableUtcDateTimeConverter()  DateTime? opensAt, @NullableUtcDateTimeConverter()  DateTime? closesAt,  int attemptsAllowed,  int attemptsUsed,  bool passed,  QuizSessionView? openSession,  bool canStart,  String? blockedReason, @NullableUtcDateTimeConverter()  DateTime? resultsAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizStanding() when $default != null:
return $default(_that.quizId,_that.serverNow,_that.window,_that.opensAt,_that.closesAt,_that.attemptsAllowed,_that.attemptsUsed,_that.passed,_that.openSession,_that.canStart,_that.blockedReason,_that.resultsAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String quizId, @NullableUtcDateTimeConverter()  DateTime? serverNow, @JsonKey(unknownEnumValue: QuizWindow.unknown)  QuizWindow window, @NullableUtcDateTimeConverter()  DateTime? opensAt, @NullableUtcDateTimeConverter()  DateTime? closesAt,  int attemptsAllowed,  int attemptsUsed,  bool passed,  QuizSessionView? openSession,  bool canStart,  String? blockedReason, @NullableUtcDateTimeConverter()  DateTime? resultsAt)  $default,) {final _that = this;
switch (_that) {
case _QuizStanding():
return $default(_that.quizId,_that.serverNow,_that.window,_that.opensAt,_that.closesAt,_that.attemptsAllowed,_that.attemptsUsed,_that.passed,_that.openSession,_that.canStart,_that.blockedReason,_that.resultsAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String quizId, @NullableUtcDateTimeConverter()  DateTime? serverNow, @JsonKey(unknownEnumValue: QuizWindow.unknown)  QuizWindow window, @NullableUtcDateTimeConverter()  DateTime? opensAt, @NullableUtcDateTimeConverter()  DateTime? closesAt,  int attemptsAllowed,  int attemptsUsed,  bool passed,  QuizSessionView? openSession,  bool canStart,  String? blockedReason, @NullableUtcDateTimeConverter()  DateTime? resultsAt)?  $default,) {final _that = this;
switch (_that) {
case _QuizStanding() when $default != null:
return $default(_that.quizId,_that.serverNow,_that.window,_that.opensAt,_that.closesAt,_that.attemptsAllowed,_that.attemptsUsed,_that.passed,_that.openSession,_that.canStart,_that.blockedReason,_that.resultsAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizStanding extends QuizStanding {
  const _QuizStanding({this.quizId = '', @NullableUtcDateTimeConverter() this.serverNow, @JsonKey(unknownEnumValue: QuizWindow.unknown) this.window = QuizWindow.open, @NullableUtcDateTimeConverter() this.opensAt, @NullableUtcDateTimeConverter() this.closesAt, this.attemptsAllowed = 0, this.attemptsUsed = 0, this.passed = false, this.openSession, this.canStart = false, this.blockedReason, @NullableUtcDateTimeConverter() this.resultsAt}): super._();
  factory _QuizStanding.fromJson(Map<String, dynamic> json) => _$QuizStandingFromJson(json);

@override@JsonKey() final  String quizId;
@override@NullableUtcDateTimeConverter() final  DateTime? serverNow;
@override@JsonKey(unknownEnumValue: QuizWindow.unknown) final  QuizWindow window;
@override@NullableUtcDateTimeConverter() final  DateTime? opensAt;
@override@NullableUtcDateTimeConverter() final  DateTime? closesAt;
/// 0 means unlimited. Once passed, more attempts are practice and not limited.
@override@JsonKey() final  int attemptsAllowed;
@override@JsonKey() final  int attemptsUsed;
@override@JsonKey() final  bool passed;
/// The attempt still open, to resume.
@override final  QuizSessionView? openSession;
/// True when an attempt is open to resume or a new one may start.
@override@JsonKey() final  bool canStart;
/// Why not, in the academy's words.
@override final  String? blockedReason;
/// While results are held until the quiz closes: when they are shown.
@override@NullableUtcDateTimeConverter() final  DateTime? resultsAt;

/// Create a copy of QuizStanding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizStandingCopyWith<_QuizStanding> get copyWith => __$QuizStandingCopyWithImpl<_QuizStanding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizStandingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizStanding&&(identical(other.quizId, quizId) || other.quizId == quizId)&&(identical(other.serverNow, serverNow) || other.serverNow == serverNow)&&(identical(other.window, window) || other.window == window)&&(identical(other.opensAt, opensAt) || other.opensAt == opensAt)&&(identical(other.closesAt, closesAt) || other.closesAt == closesAt)&&(identical(other.attemptsAllowed, attemptsAllowed) || other.attemptsAllowed == attemptsAllowed)&&(identical(other.attemptsUsed, attemptsUsed) || other.attemptsUsed == attemptsUsed)&&(identical(other.passed, passed) || other.passed == passed)&&(identical(other.openSession, openSession) || other.openSession == openSession)&&(identical(other.canStart, canStart) || other.canStart == canStart)&&(identical(other.blockedReason, blockedReason) || other.blockedReason == blockedReason)&&(identical(other.resultsAt, resultsAt) || other.resultsAt == resultsAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quizId,serverNow,window,opensAt,closesAt,attemptsAllowed,attemptsUsed,passed,openSession,canStart,blockedReason,resultsAt);

@override
String toString() {
  return 'QuizStanding(quizId: $quizId, serverNow: $serverNow, window: $window, opensAt: $opensAt, closesAt: $closesAt, attemptsAllowed: $attemptsAllowed, attemptsUsed: $attemptsUsed, passed: $passed, openSession: $openSession, canStart: $canStart, blockedReason: $blockedReason, resultsAt: $resultsAt)';
}


}

/// @nodoc
abstract mixin class _$QuizStandingCopyWith<$Res> implements $QuizStandingCopyWith<$Res> {
  factory _$QuizStandingCopyWith(_QuizStanding value, $Res Function(_QuizStanding) _then) = __$QuizStandingCopyWithImpl;
@override @useResult
$Res call({
 String quizId,@NullableUtcDateTimeConverter() DateTime? serverNow,@JsonKey(unknownEnumValue: QuizWindow.unknown) QuizWindow window,@NullableUtcDateTimeConverter() DateTime? opensAt,@NullableUtcDateTimeConverter() DateTime? closesAt, int attemptsAllowed, int attemptsUsed, bool passed, QuizSessionView? openSession, bool canStart, String? blockedReason,@NullableUtcDateTimeConverter() DateTime? resultsAt
});


@override $QuizSessionViewCopyWith<$Res>? get openSession;

}
/// @nodoc
class __$QuizStandingCopyWithImpl<$Res>
    implements _$QuizStandingCopyWith<$Res> {
  __$QuizStandingCopyWithImpl(this._self, this._then);

  final _QuizStanding _self;
  final $Res Function(_QuizStanding) _then;

/// Create a copy of QuizStanding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quizId = null,Object? serverNow = freezed,Object? window = null,Object? opensAt = freezed,Object? closesAt = freezed,Object? attemptsAllowed = null,Object? attemptsUsed = null,Object? passed = null,Object? openSession = freezed,Object? canStart = null,Object? blockedReason = freezed,Object? resultsAt = freezed,}) {
  return _then(_QuizStanding(
quizId: null == quizId ? _self.quizId : quizId // ignore: cast_nullable_to_non_nullable
as String,serverNow: freezed == serverNow ? _self.serverNow : serverNow // ignore: cast_nullable_to_non_nullable
as DateTime?,window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as QuizWindow,opensAt: freezed == opensAt ? _self.opensAt : opensAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closesAt: freezed == closesAt ? _self.closesAt : closesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,attemptsAllowed: null == attemptsAllowed ? _self.attemptsAllowed : attemptsAllowed // ignore: cast_nullable_to_non_nullable
as int,attemptsUsed: null == attemptsUsed ? _self.attemptsUsed : attemptsUsed // ignore: cast_nullable_to_non_nullable
as int,passed: null == passed ? _self.passed : passed // ignore: cast_nullable_to_non_nullable
as bool,openSession: freezed == openSession ? _self.openSession : openSession // ignore: cast_nullable_to_non_nullable
as QuizSessionView?,canStart: null == canStart ? _self.canStart : canStart // ignore: cast_nullable_to_non_nullable
as bool,blockedReason: freezed == blockedReason ? _self.blockedReason : blockedReason // ignore: cast_nullable_to_non_nullable
as String?,resultsAt: freezed == resultsAt ? _self.resultsAt : resultsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of QuizStanding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizSessionViewCopyWith<$Res>? get openSession {
    if (_self.openSession == null) {
    return null;
  }

  return $QuizSessionViewCopyWith<$Res>(_self.openSession!, (value) {
    return _then(_self.copyWith(openSession: value));
  });
}
}

// dart format on
