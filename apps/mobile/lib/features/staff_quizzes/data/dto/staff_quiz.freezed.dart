// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'staff_quiz.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StaffQuizOption {

 String get id; String get text;
/// Create a copy of StaffQuizOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffQuizOptionCopyWith<StaffQuizOption> get copyWith => _$StaffQuizOptionCopyWithImpl<StaffQuizOption>(this as StaffQuizOption, _$identity);

  /// Serializes this StaffQuizOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffQuizOption&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text);

@override
String toString() {
  return 'StaffQuizOption(id: $id, text: $text)';
}


}

/// @nodoc
abstract mixin class $StaffQuizOptionCopyWith<$Res>  {
  factory $StaffQuizOptionCopyWith(StaffQuizOption value, $Res Function(StaffQuizOption) _then) = _$StaffQuizOptionCopyWithImpl;
@useResult
$Res call({
 String id, String text
});




}
/// @nodoc
class _$StaffQuizOptionCopyWithImpl<$Res>
    implements $StaffQuizOptionCopyWith<$Res> {
  _$StaffQuizOptionCopyWithImpl(this._self, this._then);

  final StaffQuizOption _self;
  final $Res Function(StaffQuizOption) _then;

/// Create a copy of StaffQuizOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffQuizOption].
extension StaffQuizOptionPatterns on StaffQuizOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffQuizOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffQuizOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffQuizOption value)  $default,){
final _that = this;
switch (_that) {
case _StaffQuizOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffQuizOption value)?  $default,){
final _that = this;
switch (_that) {
case _StaffQuizOption() when $default != null:
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
case _StaffQuizOption() when $default != null:
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
case _StaffQuizOption():
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
case _StaffQuizOption() when $default != null:
return $default(_that.id,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffQuizOption implements StaffQuizOption {
  const _StaffQuizOption({required this.id, this.text = ''});
  factory _StaffQuizOption.fromJson(Map<String, dynamic> json) => _$StaffQuizOptionFromJson(json);

@override final  String id;
@override@JsonKey() final  String text;

/// Create a copy of StaffQuizOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffQuizOptionCopyWith<_StaffQuizOption> get copyWith => __$StaffQuizOptionCopyWithImpl<_StaffQuizOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffQuizOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffQuizOption&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text);

@override
String toString() {
  return 'StaffQuizOption(id: $id, text: $text)';
}


}

/// @nodoc
abstract mixin class _$StaffQuizOptionCopyWith<$Res> implements $StaffQuizOptionCopyWith<$Res> {
  factory _$StaffQuizOptionCopyWith(_StaffQuizOption value, $Res Function(_StaffQuizOption) _then) = __$StaffQuizOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String text
});




}
/// @nodoc
class __$StaffQuizOptionCopyWithImpl<$Res>
    implements _$StaffQuizOptionCopyWith<$Res> {
  __$StaffQuizOptionCopyWithImpl(this._self, this._then);

  final _StaffQuizOption _self;
  final $Res Function(_StaffQuizOption) _then;

/// Create a copy of StaffQuizOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,}) {
  return _then(_StaffQuizOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$StaffQuizQuestion {

 String get id;@JsonKey(unknownEnumValue: QuestionType.unknown) QuestionType get type; String get prompt; List<StaffQuizOption> get options;/// The ids of the correct options.
 List<String> get correct;/// Short answers the academy accepts, compared without case or surrounding space.
 List<String> get acceptedAnswers; int get points; String? get explanation;/// `required` on the wire; renamed because `required` is a Dart keyword in this position.
@JsonKey(name: 'required') bool get needed;
/// Create a copy of StaffQuizQuestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffQuizQuestionCopyWith<StaffQuizQuestion> get copyWith => _$StaffQuizQuestionCopyWithImpl<StaffQuizQuestion>(this as StaffQuizQuestion, _$identity);

  /// Serializes this StaffQuizQuestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffQuizQuestion&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&const DeepCollectionEquality().equals(other.options, options)&&const DeepCollectionEquality().equals(other.correct, correct)&&const DeepCollectionEquality().equals(other.acceptedAnswers, acceptedAnswers)&&(identical(other.points, points) || other.points == points)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.needed, needed) || other.needed == needed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,prompt,const DeepCollectionEquality().hash(options),const DeepCollectionEquality().hash(correct),const DeepCollectionEquality().hash(acceptedAnswers),points,explanation,needed);

@override
String toString() {
  return 'StaffQuizQuestion(id: $id, type: $type, prompt: $prompt, options: $options, correct: $correct, acceptedAnswers: $acceptedAnswers, points: $points, explanation: $explanation, needed: $needed)';
}


}

/// @nodoc
abstract mixin class $StaffQuizQuestionCopyWith<$Res>  {
  factory $StaffQuizQuestionCopyWith(StaffQuizQuestion value, $Res Function(StaffQuizQuestion) _then) = _$StaffQuizQuestionCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: QuestionType.unknown) QuestionType type, String prompt, List<StaffQuizOption> options, List<String> correct, List<String> acceptedAnswers, int points, String? explanation,@JsonKey(name: 'required') bool needed
});




}
/// @nodoc
class _$StaffQuizQuestionCopyWithImpl<$Res>
    implements $StaffQuizQuestionCopyWith<$Res> {
  _$StaffQuizQuestionCopyWithImpl(this._self, this._then);

  final StaffQuizQuestion _self;
  final $Res Function(StaffQuizQuestion) _then;

/// Create a copy of StaffQuizQuestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? prompt = null,Object? options = null,Object? correct = null,Object? acceptedAnswers = null,Object? points = null,Object? explanation = freezed,Object? needed = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as QuestionType,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<StaffQuizOption>,correct: null == correct ? _self.correct : correct // ignore: cast_nullable_to_non_nullable
as List<String>,acceptedAnswers: null == acceptedAnswers ? _self.acceptedAnswers : acceptedAnswers // ignore: cast_nullable_to_non_nullable
as List<String>,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,explanation: freezed == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String?,needed: null == needed ? _self.needed : needed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffQuizQuestion].
extension StaffQuizQuestionPatterns on StaffQuizQuestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffQuizQuestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffQuizQuestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffQuizQuestion value)  $default,){
final _that = this;
switch (_that) {
case _StaffQuizQuestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffQuizQuestion value)?  $default,){
final _that = this;
switch (_that) {
case _StaffQuizQuestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: QuestionType.unknown)  QuestionType type,  String prompt,  List<StaffQuizOption> options,  List<String> correct,  List<String> acceptedAnswers,  int points,  String? explanation, @JsonKey(name: 'required')  bool needed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffQuizQuestion() when $default != null:
return $default(_that.id,_that.type,_that.prompt,_that.options,_that.correct,_that.acceptedAnswers,_that.points,_that.explanation,_that.needed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: QuestionType.unknown)  QuestionType type,  String prompt,  List<StaffQuizOption> options,  List<String> correct,  List<String> acceptedAnswers,  int points,  String? explanation, @JsonKey(name: 'required')  bool needed)  $default,) {final _that = this;
switch (_that) {
case _StaffQuizQuestion():
return $default(_that.id,_that.type,_that.prompt,_that.options,_that.correct,_that.acceptedAnswers,_that.points,_that.explanation,_that.needed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(unknownEnumValue: QuestionType.unknown)  QuestionType type,  String prompt,  List<StaffQuizOption> options,  List<String> correct,  List<String> acceptedAnswers,  int points,  String? explanation, @JsonKey(name: 'required')  bool needed)?  $default,) {final _that = this;
switch (_that) {
case _StaffQuizQuestion() when $default != null:
return $default(_that.id,_that.type,_that.prompt,_that.options,_that.correct,_that.acceptedAnswers,_that.points,_that.explanation,_that.needed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffQuizQuestion extends StaffQuizQuestion {
  const _StaffQuizQuestion({required this.id, @JsonKey(unknownEnumValue: QuestionType.unknown) this.type = QuestionType.unknown, this.prompt = '', final  List<StaffQuizOption> options = const <StaffQuizOption>[], final  List<String> correct = const <String>[], final  List<String> acceptedAnswers = const <String>[], this.points = 0, this.explanation, @JsonKey(name: 'required') this.needed = true}): _options = options,_correct = correct,_acceptedAnswers = acceptedAnswers,super._();
  factory _StaffQuizQuestion.fromJson(Map<String, dynamic> json) => _$StaffQuizQuestionFromJson(json);

@override final  String id;
@override@JsonKey(unknownEnumValue: QuestionType.unknown) final  QuestionType type;
@override@JsonKey() final  String prompt;
 final  List<StaffQuizOption> _options;
@override@JsonKey() List<StaffQuizOption> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

/// The ids of the correct options.
 final  List<String> _correct;
/// The ids of the correct options.
@override@JsonKey() List<String> get correct {
  if (_correct is EqualUnmodifiableListView) return _correct;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_correct);
}

/// Short answers the academy accepts, compared without case or surrounding space.
 final  List<String> _acceptedAnswers;
/// Short answers the academy accepts, compared without case or surrounding space.
@override@JsonKey() List<String> get acceptedAnswers {
  if (_acceptedAnswers is EqualUnmodifiableListView) return _acceptedAnswers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_acceptedAnswers);
}

@override@JsonKey() final  int points;
@override final  String? explanation;
/// `required` on the wire; renamed because `required` is a Dart keyword in this position.
@override@JsonKey(name: 'required') final  bool needed;

/// Create a copy of StaffQuizQuestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffQuizQuestionCopyWith<_StaffQuizQuestion> get copyWith => __$StaffQuizQuestionCopyWithImpl<_StaffQuizQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffQuizQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffQuizQuestion&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&const DeepCollectionEquality().equals(other._options, _options)&&const DeepCollectionEquality().equals(other._correct, _correct)&&const DeepCollectionEquality().equals(other._acceptedAnswers, _acceptedAnswers)&&(identical(other.points, points) || other.points == points)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.needed, needed) || other.needed == needed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,prompt,const DeepCollectionEquality().hash(_options),const DeepCollectionEquality().hash(_correct),const DeepCollectionEquality().hash(_acceptedAnswers),points,explanation,needed);

@override
String toString() {
  return 'StaffQuizQuestion(id: $id, type: $type, prompt: $prompt, options: $options, correct: $correct, acceptedAnswers: $acceptedAnswers, points: $points, explanation: $explanation, needed: $needed)';
}


}

/// @nodoc
abstract mixin class _$StaffQuizQuestionCopyWith<$Res> implements $StaffQuizQuestionCopyWith<$Res> {
  factory _$StaffQuizQuestionCopyWith(_StaffQuizQuestion value, $Res Function(_StaffQuizQuestion) _then) = __$StaffQuizQuestionCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: QuestionType.unknown) QuestionType type, String prompt, List<StaffQuizOption> options, List<String> correct, List<String> acceptedAnswers, int points, String? explanation,@JsonKey(name: 'required') bool needed
});




}
/// @nodoc
class __$StaffQuizQuestionCopyWithImpl<$Res>
    implements _$StaffQuizQuestionCopyWith<$Res> {
  __$StaffQuizQuestionCopyWithImpl(this._self, this._then);

  final _StaffQuizQuestion _self;
  final $Res Function(_StaffQuizQuestion) _then;

/// Create a copy of StaffQuizQuestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? prompt = null,Object? options = null,Object? correct = null,Object? acceptedAnswers = null,Object? points = null,Object? explanation = freezed,Object? needed = null,}) {
  return _then(_StaffQuizQuestion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as QuestionType,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<StaffQuizOption>,correct: null == correct ? _self._correct : correct // ignore: cast_nullable_to_non_nullable
as List<String>,acceptedAnswers: null == acceptedAnswers ? _self._acceptedAnswers : acceptedAnswers // ignore: cast_nullable_to_non_nullable
as List<String>,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,explanation: freezed == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String?,needed: null == needed ? _self.needed : needed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$StaffQuizSettings {

/// Percent of the points needed to pass.
 int get passMark;/// 0 means as many as they like.
 int get attempts; int? get timeLimitMin; bool get shuffleQuestions; bool get shuffleOptions;@JsonKey(unknownEnumValue: ResultsVisibility.unknown) ResultsVisibility get showResults;
/// Create a copy of StaffQuizSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffQuizSettingsCopyWith<StaffQuizSettings> get copyWith => _$StaffQuizSettingsCopyWithImpl<StaffQuizSettings>(this as StaffQuizSettings, _$identity);

  /// Serializes this StaffQuizSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffQuizSettings&&(identical(other.passMark, passMark) || other.passMark == passMark)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.timeLimitMin, timeLimitMin) || other.timeLimitMin == timeLimitMin)&&(identical(other.shuffleQuestions, shuffleQuestions) || other.shuffleQuestions == shuffleQuestions)&&(identical(other.shuffleOptions, shuffleOptions) || other.shuffleOptions == shuffleOptions)&&(identical(other.showResults, showResults) || other.showResults == showResults));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,passMark,attempts,timeLimitMin,shuffleQuestions,shuffleOptions,showResults);

@override
String toString() {
  return 'StaffQuizSettings(passMark: $passMark, attempts: $attempts, timeLimitMin: $timeLimitMin, shuffleQuestions: $shuffleQuestions, shuffleOptions: $shuffleOptions, showResults: $showResults)';
}


}

/// @nodoc
abstract mixin class $StaffQuizSettingsCopyWith<$Res>  {
  factory $StaffQuizSettingsCopyWith(StaffQuizSettings value, $Res Function(StaffQuizSettings) _then) = _$StaffQuizSettingsCopyWithImpl;
@useResult
$Res call({
 int passMark, int attempts, int? timeLimitMin, bool shuffleQuestions, bool shuffleOptions,@JsonKey(unknownEnumValue: ResultsVisibility.unknown) ResultsVisibility showResults
});




}
/// @nodoc
class _$StaffQuizSettingsCopyWithImpl<$Res>
    implements $StaffQuizSettingsCopyWith<$Res> {
  _$StaffQuizSettingsCopyWithImpl(this._self, this._then);

  final StaffQuizSettings _self;
  final $Res Function(StaffQuizSettings) _then;

/// Create a copy of StaffQuizSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? passMark = null,Object? attempts = null,Object? timeLimitMin = freezed,Object? shuffleQuestions = null,Object? shuffleOptions = null,Object? showResults = null,}) {
  return _then(_self.copyWith(
passMark: null == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as int,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,timeLimitMin: freezed == timeLimitMin ? _self.timeLimitMin : timeLimitMin // ignore: cast_nullable_to_non_nullable
as int?,shuffleQuestions: null == shuffleQuestions ? _self.shuffleQuestions : shuffleQuestions // ignore: cast_nullable_to_non_nullable
as bool,shuffleOptions: null == shuffleOptions ? _self.shuffleOptions : shuffleOptions // ignore: cast_nullable_to_non_nullable
as bool,showResults: null == showResults ? _self.showResults : showResults // ignore: cast_nullable_to_non_nullable
as ResultsVisibility,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffQuizSettings].
extension StaffQuizSettingsPatterns on StaffQuizSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffQuizSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffQuizSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffQuizSettings value)  $default,){
final _that = this;
switch (_that) {
case _StaffQuizSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffQuizSettings value)?  $default,){
final _that = this;
switch (_that) {
case _StaffQuizSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int passMark,  int attempts,  int? timeLimitMin,  bool shuffleQuestions,  bool shuffleOptions, @JsonKey(unknownEnumValue: ResultsVisibility.unknown)  ResultsVisibility showResults)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffQuizSettings() when $default != null:
return $default(_that.passMark,_that.attempts,_that.timeLimitMin,_that.shuffleQuestions,_that.shuffleOptions,_that.showResults);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int passMark,  int attempts,  int? timeLimitMin,  bool shuffleQuestions,  bool shuffleOptions, @JsonKey(unknownEnumValue: ResultsVisibility.unknown)  ResultsVisibility showResults)  $default,) {final _that = this;
switch (_that) {
case _StaffQuizSettings():
return $default(_that.passMark,_that.attempts,_that.timeLimitMin,_that.shuffleQuestions,_that.shuffleOptions,_that.showResults);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int passMark,  int attempts,  int? timeLimitMin,  bool shuffleQuestions,  bool shuffleOptions, @JsonKey(unknownEnumValue: ResultsVisibility.unknown)  ResultsVisibility showResults)?  $default,) {final _that = this;
switch (_that) {
case _StaffQuizSettings() when $default != null:
return $default(_that.passMark,_that.attempts,_that.timeLimitMin,_that.shuffleQuestions,_that.shuffleOptions,_that.showResults);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffQuizSettings extends StaffQuizSettings {
  const _StaffQuizSettings({this.passMark = 70, this.attempts = 2, this.timeLimitMin, this.shuffleQuestions = false, this.shuffleOptions = true, @JsonKey(unknownEnumValue: ResultsVisibility.unknown) this.showResults = ResultsVisibility.scoreAndAnswers}): super._();
  factory _StaffQuizSettings.fromJson(Map<String, dynamic> json) => _$StaffQuizSettingsFromJson(json);

/// Percent of the points needed to pass.
@override@JsonKey() final  int passMark;
/// 0 means as many as they like.
@override@JsonKey() final  int attempts;
@override final  int? timeLimitMin;
@override@JsonKey() final  bool shuffleQuestions;
@override@JsonKey() final  bool shuffleOptions;
@override@JsonKey(unknownEnumValue: ResultsVisibility.unknown) final  ResultsVisibility showResults;

/// Create a copy of StaffQuizSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffQuizSettingsCopyWith<_StaffQuizSettings> get copyWith => __$StaffQuizSettingsCopyWithImpl<_StaffQuizSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffQuizSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffQuizSettings&&(identical(other.passMark, passMark) || other.passMark == passMark)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.timeLimitMin, timeLimitMin) || other.timeLimitMin == timeLimitMin)&&(identical(other.shuffleQuestions, shuffleQuestions) || other.shuffleQuestions == shuffleQuestions)&&(identical(other.shuffleOptions, shuffleOptions) || other.shuffleOptions == shuffleOptions)&&(identical(other.showResults, showResults) || other.showResults == showResults));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,passMark,attempts,timeLimitMin,shuffleQuestions,shuffleOptions,showResults);

@override
String toString() {
  return 'StaffQuizSettings(passMark: $passMark, attempts: $attempts, timeLimitMin: $timeLimitMin, shuffleQuestions: $shuffleQuestions, shuffleOptions: $shuffleOptions, showResults: $showResults)';
}


}

/// @nodoc
abstract mixin class _$StaffQuizSettingsCopyWith<$Res> implements $StaffQuizSettingsCopyWith<$Res> {
  factory _$StaffQuizSettingsCopyWith(_StaffQuizSettings value, $Res Function(_StaffQuizSettings) _then) = __$StaffQuizSettingsCopyWithImpl;
@override @useResult
$Res call({
 int passMark, int attempts, int? timeLimitMin, bool shuffleQuestions, bool shuffleOptions,@JsonKey(unknownEnumValue: ResultsVisibility.unknown) ResultsVisibility showResults
});




}
/// @nodoc
class __$StaffQuizSettingsCopyWithImpl<$Res>
    implements _$StaffQuizSettingsCopyWith<$Res> {
  __$StaffQuizSettingsCopyWithImpl(this._self, this._then);

  final _StaffQuizSettings _self;
  final $Res Function(_StaffQuizSettings) _then;

/// Create a copy of StaffQuizSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? passMark = null,Object? attempts = null,Object? timeLimitMin = freezed,Object? shuffleQuestions = null,Object? shuffleOptions = null,Object? showResults = null,}) {
  return _then(_StaffQuizSettings(
passMark: null == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as int,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,timeLimitMin: freezed == timeLimitMin ? _self.timeLimitMin : timeLimitMin // ignore: cast_nullable_to_non_nullable
as int?,shuffleQuestions: null == shuffleQuestions ? _self.shuffleQuestions : shuffleQuestions // ignore: cast_nullable_to_non_nullable
as bool,shuffleOptions: null == shuffleOptions ? _self.shuffleOptions : shuffleOptions // ignore: cast_nullable_to_non_nullable
as bool,showResults: null == showResults ? _self.showResults : showResults // ignore: cast_nullable_to_non_nullable
as ResultsVisibility,
  ));
}


}


/// @nodoc
mixin _$StaffQuiz {

 String get id; String get courseId; String? get chapterId;/// The assessment lesson that delivers it, when it is part of the curriculum.
 String? get lessonId; String get title; String get instructions;@JsonKey(unknownEnumValue: StaffQuizStatus.unknown) StaffQuizStatus get status; List<StaffQuizQuestion> get questions; StaffQuizSettings get settings;
/// Create a copy of StaffQuiz
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffQuizCopyWith<StaffQuiz> get copyWith => _$StaffQuizCopyWithImpl<StaffQuiz>(this as StaffQuiz, _$identity);

  /// Serializes this StaffQuiz to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffQuiz&&(identical(other.id, id) || other.id == id)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.lessonId, lessonId) || other.lessonId == lessonId)&&(identical(other.title, title) || other.title == title)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.questions, questions)&&(identical(other.settings, settings) || other.settings == settings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,courseId,chapterId,lessonId,title,instructions,status,const DeepCollectionEquality().hash(questions),settings);

@override
String toString() {
  return 'StaffQuiz(id: $id, courseId: $courseId, chapterId: $chapterId, lessonId: $lessonId, title: $title, instructions: $instructions, status: $status, questions: $questions, settings: $settings)';
}


}

/// @nodoc
abstract mixin class $StaffQuizCopyWith<$Res>  {
  factory $StaffQuizCopyWith(StaffQuiz value, $Res Function(StaffQuiz) _then) = _$StaffQuizCopyWithImpl;
@useResult
$Res call({
 String id, String courseId, String? chapterId, String? lessonId, String title, String instructions,@JsonKey(unknownEnumValue: StaffQuizStatus.unknown) StaffQuizStatus status, List<StaffQuizQuestion> questions, StaffQuizSettings settings
});


$StaffQuizSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class _$StaffQuizCopyWithImpl<$Res>
    implements $StaffQuizCopyWith<$Res> {
  _$StaffQuizCopyWithImpl(this._self, this._then);

  final StaffQuiz _self;
  final $Res Function(StaffQuiz) _then;

/// Create a copy of StaffQuiz
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? courseId = null,Object? chapterId = freezed,Object? lessonId = freezed,Object? title = null,Object? instructions = null,Object? status = null,Object? questions = null,Object? settings = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,chapterId: freezed == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String?,lessonId: freezed == lessonId ? _self.lessonId : lessonId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StaffQuizStatus,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as List<StaffQuizQuestion>,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as StaffQuizSettings,
  ));
}
/// Create a copy of StaffQuiz
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StaffQuizSettingsCopyWith<$Res> get settings {
  
  return $StaffQuizSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}


/// Adds pattern-matching-related methods to [StaffQuiz].
extension StaffQuizPatterns on StaffQuiz {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffQuiz value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffQuiz() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffQuiz value)  $default,){
final _that = this;
switch (_that) {
case _StaffQuiz():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffQuiz value)?  $default,){
final _that = this;
switch (_that) {
case _StaffQuiz() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String courseId,  String? chapterId,  String? lessonId,  String title,  String instructions, @JsonKey(unknownEnumValue: StaffQuizStatus.unknown)  StaffQuizStatus status,  List<StaffQuizQuestion> questions,  StaffQuizSettings settings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffQuiz() when $default != null:
return $default(_that.id,_that.courseId,_that.chapterId,_that.lessonId,_that.title,_that.instructions,_that.status,_that.questions,_that.settings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String courseId,  String? chapterId,  String? lessonId,  String title,  String instructions, @JsonKey(unknownEnumValue: StaffQuizStatus.unknown)  StaffQuizStatus status,  List<StaffQuizQuestion> questions,  StaffQuizSettings settings)  $default,) {final _that = this;
switch (_that) {
case _StaffQuiz():
return $default(_that.id,_that.courseId,_that.chapterId,_that.lessonId,_that.title,_that.instructions,_that.status,_that.questions,_that.settings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String courseId,  String? chapterId,  String? lessonId,  String title,  String instructions, @JsonKey(unknownEnumValue: StaffQuizStatus.unknown)  StaffQuizStatus status,  List<StaffQuizQuestion> questions,  StaffQuizSettings settings)?  $default,) {final _that = this;
switch (_that) {
case _StaffQuiz() when $default != null:
return $default(_that.id,_that.courseId,_that.chapterId,_that.lessonId,_that.title,_that.instructions,_that.status,_that.questions,_that.settings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffQuiz extends StaffQuiz {
  const _StaffQuiz({required this.id, this.courseId = '', this.chapterId, this.lessonId, this.title = '', this.instructions = '', @JsonKey(unknownEnumValue: StaffQuizStatus.unknown) this.status = StaffQuizStatus.draft, final  List<StaffQuizQuestion> questions = const <StaffQuizQuestion>[], this.settings = const StaffQuizSettings()}): _questions = questions,super._();
  factory _StaffQuiz.fromJson(Map<String, dynamic> json) => _$StaffQuizFromJson(json);

@override final  String id;
@override@JsonKey() final  String courseId;
@override final  String? chapterId;
/// The assessment lesson that delivers it, when it is part of the curriculum.
@override final  String? lessonId;
@override@JsonKey() final  String title;
@override@JsonKey() final  String instructions;
@override@JsonKey(unknownEnumValue: StaffQuizStatus.unknown) final  StaffQuizStatus status;
 final  List<StaffQuizQuestion> _questions;
@override@JsonKey() List<StaffQuizQuestion> get questions {
  if (_questions is EqualUnmodifiableListView) return _questions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_questions);
}

@override@JsonKey() final  StaffQuizSettings settings;

/// Create a copy of StaffQuiz
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffQuizCopyWith<_StaffQuiz> get copyWith => __$StaffQuizCopyWithImpl<_StaffQuiz>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffQuizToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffQuiz&&(identical(other.id, id) || other.id == id)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.chapterId, chapterId) || other.chapterId == chapterId)&&(identical(other.lessonId, lessonId) || other.lessonId == lessonId)&&(identical(other.title, title) || other.title == title)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._questions, _questions)&&(identical(other.settings, settings) || other.settings == settings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,courseId,chapterId,lessonId,title,instructions,status,const DeepCollectionEquality().hash(_questions),settings);

@override
String toString() {
  return 'StaffQuiz(id: $id, courseId: $courseId, chapterId: $chapterId, lessonId: $lessonId, title: $title, instructions: $instructions, status: $status, questions: $questions, settings: $settings)';
}


}

/// @nodoc
abstract mixin class _$StaffQuizCopyWith<$Res> implements $StaffQuizCopyWith<$Res> {
  factory _$StaffQuizCopyWith(_StaffQuiz value, $Res Function(_StaffQuiz) _then) = __$StaffQuizCopyWithImpl;
@override @useResult
$Res call({
 String id, String courseId, String? chapterId, String? lessonId, String title, String instructions,@JsonKey(unknownEnumValue: StaffQuizStatus.unknown) StaffQuizStatus status, List<StaffQuizQuestion> questions, StaffQuizSettings settings
});


@override $StaffQuizSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class __$StaffQuizCopyWithImpl<$Res>
    implements _$StaffQuizCopyWith<$Res> {
  __$StaffQuizCopyWithImpl(this._self, this._then);

  final _StaffQuiz _self;
  final $Res Function(_StaffQuiz) _then;

/// Create a copy of StaffQuiz
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? courseId = null,Object? chapterId = freezed,Object? lessonId = freezed,Object? title = null,Object? instructions = null,Object? status = null,Object? questions = null,Object? settings = null,}) {
  return _then(_StaffQuiz(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,chapterId: freezed == chapterId ? _self.chapterId : chapterId // ignore: cast_nullable_to_non_nullable
as String?,lessonId: freezed == lessonId ? _self.lessonId : lessonId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StaffQuizStatus,questions: null == questions ? _self._questions : questions // ignore: cast_nullable_to_non_nullable
as List<StaffQuizQuestion>,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as StaffQuizSettings,
  ));
}

/// Create a copy of StaffQuiz
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StaffQuizSettingsCopyWith<$Res> get settings {
  
  return $StaffQuizSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}


/// @nodoc
mixin _$StaffQuizRow {

 StaffQuiz get quiz; String get courseTitle; String? get chapterTitle; int get points; int get attempts; num? get passRate; num? get avgScore;
/// Create a copy of StaffQuizRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffQuizRowCopyWith<StaffQuizRow> get copyWith => _$StaffQuizRowCopyWithImpl<StaffQuizRow>(this as StaffQuizRow, _$identity);

  /// Serializes this StaffQuizRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffQuizRow&&(identical(other.quiz, quiz) || other.quiz == quiz)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.points, points) || other.points == points)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.passRate, passRate) || other.passRate == passRate)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quiz,courseTitle,chapterTitle,points,attempts,passRate,avgScore);

@override
String toString() {
  return 'StaffQuizRow(quiz: $quiz, courseTitle: $courseTitle, chapterTitle: $chapterTitle, points: $points, attempts: $attempts, passRate: $passRate, avgScore: $avgScore)';
}


}

/// @nodoc
abstract mixin class $StaffQuizRowCopyWith<$Res>  {
  factory $StaffQuizRowCopyWith(StaffQuizRow value, $Res Function(StaffQuizRow) _then) = _$StaffQuizRowCopyWithImpl;
@useResult
$Res call({
 StaffQuiz quiz, String courseTitle, String? chapterTitle, int points, int attempts, num? passRate, num? avgScore
});


$StaffQuizCopyWith<$Res> get quiz;

}
/// @nodoc
class _$StaffQuizRowCopyWithImpl<$Res>
    implements $StaffQuizRowCopyWith<$Res> {
  _$StaffQuizRowCopyWithImpl(this._self, this._then);

  final StaffQuizRow _self;
  final $Res Function(StaffQuizRow) _then;

/// Create a copy of StaffQuizRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quiz = null,Object? courseTitle = null,Object? chapterTitle = freezed,Object? points = null,Object? attempts = null,Object? passRate = freezed,Object? avgScore = freezed,}) {
  return _then(_self.copyWith(
quiz: null == quiz ? _self.quiz : quiz // ignore: cast_nullable_to_non_nullable
as StaffQuiz,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,chapterTitle: freezed == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String?,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,passRate: freezed == passRate ? _self.passRate : passRate // ignore: cast_nullable_to_non_nullable
as num?,avgScore: freezed == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}
/// Create a copy of StaffQuizRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StaffQuizCopyWith<$Res> get quiz {
  
  return $StaffQuizCopyWith<$Res>(_self.quiz, (value) {
    return _then(_self.copyWith(quiz: value));
  });
}
}


/// Adds pattern-matching-related methods to [StaffQuizRow].
extension StaffQuizRowPatterns on StaffQuizRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffQuizRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffQuizRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffQuizRow value)  $default,){
final _that = this;
switch (_that) {
case _StaffQuizRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffQuizRow value)?  $default,){
final _that = this;
switch (_that) {
case _StaffQuizRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StaffQuiz quiz,  String courseTitle,  String? chapterTitle,  int points,  int attempts,  num? passRate,  num? avgScore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffQuizRow() when $default != null:
return $default(_that.quiz,_that.courseTitle,_that.chapterTitle,_that.points,_that.attempts,_that.passRate,_that.avgScore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StaffQuiz quiz,  String courseTitle,  String? chapterTitle,  int points,  int attempts,  num? passRate,  num? avgScore)  $default,) {final _that = this;
switch (_that) {
case _StaffQuizRow():
return $default(_that.quiz,_that.courseTitle,_that.chapterTitle,_that.points,_that.attempts,_that.passRate,_that.avgScore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StaffQuiz quiz,  String courseTitle,  String? chapterTitle,  int points,  int attempts,  num? passRate,  num? avgScore)?  $default,) {final _that = this;
switch (_that) {
case _StaffQuizRow() when $default != null:
return $default(_that.quiz,_that.courseTitle,_that.chapterTitle,_that.points,_that.attempts,_that.passRate,_that.avgScore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffQuizRow implements StaffQuizRow {
  const _StaffQuizRow({required this.quiz, this.courseTitle = '', this.chapterTitle, this.points = 0, this.attempts = 0, this.passRate, this.avgScore});
  factory _StaffQuizRow.fromJson(Map<String, dynamic> json) => _$StaffQuizRowFromJson(json);

@override final  StaffQuiz quiz;
@override@JsonKey() final  String courseTitle;
@override final  String? chapterTitle;
@override@JsonKey() final  int points;
@override@JsonKey() final  int attempts;
@override final  num? passRate;
@override final  num? avgScore;

/// Create a copy of StaffQuizRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffQuizRowCopyWith<_StaffQuizRow> get copyWith => __$StaffQuizRowCopyWithImpl<_StaffQuizRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffQuizRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffQuizRow&&(identical(other.quiz, quiz) || other.quiz == quiz)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.chapterTitle, chapterTitle) || other.chapterTitle == chapterTitle)&&(identical(other.points, points) || other.points == points)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.passRate, passRate) || other.passRate == passRate)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quiz,courseTitle,chapterTitle,points,attempts,passRate,avgScore);

@override
String toString() {
  return 'StaffQuizRow(quiz: $quiz, courseTitle: $courseTitle, chapterTitle: $chapterTitle, points: $points, attempts: $attempts, passRate: $passRate, avgScore: $avgScore)';
}


}

/// @nodoc
abstract mixin class _$StaffQuizRowCopyWith<$Res> implements $StaffQuizRowCopyWith<$Res> {
  factory _$StaffQuizRowCopyWith(_StaffQuizRow value, $Res Function(_StaffQuizRow) _then) = __$StaffQuizRowCopyWithImpl;
@override @useResult
$Res call({
 StaffQuiz quiz, String courseTitle, String? chapterTitle, int points, int attempts, num? passRate, num? avgScore
});


@override $StaffQuizCopyWith<$Res> get quiz;

}
/// @nodoc
class __$StaffQuizRowCopyWithImpl<$Res>
    implements _$StaffQuizRowCopyWith<$Res> {
  __$StaffQuizRowCopyWithImpl(this._self, this._then);

  final _StaffQuizRow _self;
  final $Res Function(_StaffQuizRow) _then;

/// Create a copy of StaffQuizRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quiz = null,Object? courseTitle = null,Object? chapterTitle = freezed,Object? points = null,Object? attempts = null,Object? passRate = freezed,Object? avgScore = freezed,}) {
  return _then(_StaffQuizRow(
quiz: null == quiz ? _self.quiz : quiz // ignore: cast_nullable_to_non_nullable
as StaffQuiz,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,chapterTitle: freezed == chapterTitle ? _self.chapterTitle : chapterTitle // ignore: cast_nullable_to_non_nullable
as String?,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,passRate: freezed == passRate ? _self.passRate : passRate // ignore: cast_nullable_to_non_nullable
as num?,avgScore: freezed == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}

/// Create a copy of StaffQuizRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StaffQuizCopyWith<$Res> get quiz {
  
  return $StaffQuizCopyWith<$Res>(_self.quiz, (value) {
    return _then(_self.copyWith(quiz: value));
  });
}
}


/// @nodoc
mixin _$StaffQuizPage {

 List<StaffQuizRow> get rows; Map<String, int> get counts;
/// Create a copy of StaffQuizPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffQuizPageCopyWith<StaffQuizPage> get copyWith => _$StaffQuizPageCopyWithImpl<StaffQuizPage>(this as StaffQuizPage, _$identity);

  /// Serializes this StaffQuizPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaffQuizPage&&const DeepCollectionEquality().equals(other.rows, rows)&&const DeepCollectionEquality().equals(other.counts, counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(rows),const DeepCollectionEquality().hash(counts));

@override
String toString() {
  return 'StaffQuizPage(rows: $rows, counts: $counts)';
}


}

/// @nodoc
abstract mixin class $StaffQuizPageCopyWith<$Res>  {
  factory $StaffQuizPageCopyWith(StaffQuizPage value, $Res Function(StaffQuizPage) _then) = _$StaffQuizPageCopyWithImpl;
@useResult
$Res call({
 List<StaffQuizRow> rows, Map<String, int> counts
});




}
/// @nodoc
class _$StaffQuizPageCopyWithImpl<$Res>
    implements $StaffQuizPageCopyWith<$Res> {
  _$StaffQuizPageCopyWithImpl(this._self, this._then);

  final StaffQuizPage _self;
  final $Res Function(StaffQuizPage) _then;

/// Create a copy of StaffQuizPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? counts = null,}) {
  return _then(_self.copyWith(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<StaffQuizRow>,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [StaffQuizPage].
extension StaffQuizPagePatterns on StaffQuizPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaffQuizPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaffQuizPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaffQuizPage value)  $default,){
final _that = this;
switch (_that) {
case _StaffQuizPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaffQuizPage value)?  $default,){
final _that = this;
switch (_that) {
case _StaffQuizPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<StaffQuizRow> rows,  Map<String, int> counts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaffQuizPage() when $default != null:
return $default(_that.rows,_that.counts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<StaffQuizRow> rows,  Map<String, int> counts)  $default,) {final _that = this;
switch (_that) {
case _StaffQuizPage():
return $default(_that.rows,_that.counts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<StaffQuizRow> rows,  Map<String, int> counts)?  $default,) {final _that = this;
switch (_that) {
case _StaffQuizPage() when $default != null:
return $default(_that.rows,_that.counts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaffQuizPage extends StaffQuizPage {
  const _StaffQuizPage({final  List<StaffQuizRow> rows = const <StaffQuizRow>[], final  Map<String, int> counts = const <String, int>{}}): _rows = rows,_counts = counts,super._();
  factory _StaffQuizPage.fromJson(Map<String, dynamic> json) => _$StaffQuizPageFromJson(json);

 final  List<StaffQuizRow> _rows;
@override@JsonKey() List<StaffQuizRow> get rows {
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


/// Create a copy of StaffQuizPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffQuizPageCopyWith<_StaffQuizPage> get copyWith => __$StaffQuizPageCopyWithImpl<_StaffQuizPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffQuizPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaffQuizPage&&const DeepCollectionEquality().equals(other._rows, _rows)&&const DeepCollectionEquality().equals(other._counts, _counts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows),const DeepCollectionEquality().hash(_counts));

@override
String toString() {
  return 'StaffQuizPage(rows: $rows, counts: $counts)';
}


}

/// @nodoc
abstract mixin class _$StaffQuizPageCopyWith<$Res> implements $StaffQuizPageCopyWith<$Res> {
  factory _$StaffQuizPageCopyWith(_StaffQuizPage value, $Res Function(_StaffQuizPage) _then) = __$StaffQuizPageCopyWithImpl;
@override @useResult
$Res call({
 List<StaffQuizRow> rows, Map<String, int> counts
});




}
/// @nodoc
class __$StaffQuizPageCopyWithImpl<$Res>
    implements _$StaffQuizPageCopyWith<$Res> {
  __$StaffQuizPageCopyWithImpl(this._self, this._then);

  final _StaffQuizPage _self;
  final $Res Function(_StaffQuizPage) _then;

/// Create a copy of StaffQuizPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,Object? counts = null,}) {
  return _then(_StaffQuizPage(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<StaffQuizRow>,counts: null == counts ? _self._counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}


/// @nodoc
mixin _$ScoreBand {

 String get label; num get value;
/// Create a copy of ScoreBand
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScoreBandCopyWith<ScoreBand> get copyWith => _$ScoreBandCopyWithImpl<ScoreBand>(this as ScoreBand, _$identity);

  /// Serializes this ScoreBand to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScoreBand&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,value);

@override
String toString() {
  return 'ScoreBand(label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class $ScoreBandCopyWith<$Res>  {
  factory $ScoreBandCopyWith(ScoreBand value, $Res Function(ScoreBand) _then) = _$ScoreBandCopyWithImpl;
@useResult
$Res call({
 String label, num value
});




}
/// @nodoc
class _$ScoreBandCopyWithImpl<$Res>
    implements $ScoreBandCopyWith<$Res> {
  _$ScoreBandCopyWithImpl(this._self, this._then);

  final ScoreBand _self;
  final $Res Function(ScoreBand) _then;

/// Create a copy of ScoreBand
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? value = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [ScoreBand].
extension ScoreBandPatterns on ScoreBand {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScoreBand value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScoreBand() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScoreBand value)  $default,){
final _that = this;
switch (_that) {
case _ScoreBand():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScoreBand value)?  $default,){
final _that = this;
switch (_that) {
case _ScoreBand() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  num value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScoreBand() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  num value)  $default,) {final _that = this;
switch (_that) {
case _ScoreBand():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  num value)?  $default,) {final _that = this;
switch (_that) {
case _ScoreBand() when $default != null:
return $default(_that.label,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScoreBand implements ScoreBand {
  const _ScoreBand({this.label = '', this.value = 0});
  factory _ScoreBand.fromJson(Map<String, dynamic> json) => _$ScoreBandFromJson(json);

@override@JsonKey() final  String label;
@override@JsonKey() final  num value;

/// Create a copy of ScoreBand
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScoreBandCopyWith<_ScoreBand> get copyWith => __$ScoreBandCopyWithImpl<_ScoreBand>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScoreBandToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScoreBand&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,value);

@override
String toString() {
  return 'ScoreBand(label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class _$ScoreBandCopyWith<$Res> implements $ScoreBandCopyWith<$Res> {
  factory _$ScoreBandCopyWith(_ScoreBand value, $Res Function(_ScoreBand) _then) = __$ScoreBandCopyWithImpl;
@override @useResult
$Res call({
 String label, num value
});




}
/// @nodoc
class __$ScoreBandCopyWithImpl<$Res>
    implements _$ScoreBandCopyWith<$Res> {
  __$ScoreBandCopyWithImpl(this._self, this._then);

  final _ScoreBand _self;
  final $Res Function(_ScoreBand) _then;

/// Create a copy of ScoreBand
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? value = null,}) {
  return _then(_ScoreBand(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}


/// @nodoc
mixin _$QuestionStat {

 String get questionId; num get correctRate; String? get commonWrongOptionId;
/// Create a copy of QuestionStat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionStatCopyWith<QuestionStat> get copyWith => _$QuestionStatCopyWithImpl<QuestionStat>(this as QuestionStat, _$identity);

  /// Serializes this QuestionStat to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionStat&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.correctRate, correctRate) || other.correctRate == correctRate)&&(identical(other.commonWrongOptionId, commonWrongOptionId) || other.commonWrongOptionId == commonWrongOptionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionId,correctRate,commonWrongOptionId);

@override
String toString() {
  return 'QuestionStat(questionId: $questionId, correctRate: $correctRate, commonWrongOptionId: $commonWrongOptionId)';
}


}

/// @nodoc
abstract mixin class $QuestionStatCopyWith<$Res>  {
  factory $QuestionStatCopyWith(QuestionStat value, $Res Function(QuestionStat) _then) = _$QuestionStatCopyWithImpl;
@useResult
$Res call({
 String questionId, num correctRate, String? commonWrongOptionId
});




}
/// @nodoc
class _$QuestionStatCopyWithImpl<$Res>
    implements $QuestionStatCopyWith<$Res> {
  _$QuestionStatCopyWithImpl(this._self, this._then);

  final QuestionStat _self;
  final $Res Function(QuestionStat) _then;

/// Create a copy of QuestionStat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questionId = null,Object? correctRate = null,Object? commonWrongOptionId = freezed,}) {
  return _then(_self.copyWith(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,correctRate: null == correctRate ? _self.correctRate : correctRate // ignore: cast_nullable_to_non_nullable
as num,commonWrongOptionId: freezed == commonWrongOptionId ? _self.commonWrongOptionId : commonWrongOptionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuestionStat].
extension QuestionStatPatterns on QuestionStat {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuestionStat value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuestionStat() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuestionStat value)  $default,){
final _that = this;
switch (_that) {
case _QuestionStat():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuestionStat value)?  $default,){
final _that = this;
switch (_that) {
case _QuestionStat() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String questionId,  num correctRate,  String? commonWrongOptionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuestionStat() when $default != null:
return $default(_that.questionId,_that.correctRate,_that.commonWrongOptionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String questionId,  num correctRate,  String? commonWrongOptionId)  $default,) {final _that = this;
switch (_that) {
case _QuestionStat():
return $default(_that.questionId,_that.correctRate,_that.commonWrongOptionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String questionId,  num correctRate,  String? commonWrongOptionId)?  $default,) {final _that = this;
switch (_that) {
case _QuestionStat() when $default != null:
return $default(_that.questionId,_that.correctRate,_that.commonWrongOptionId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuestionStat implements QuestionStat {
  const _QuestionStat({this.questionId = '', this.correctRate = 0, this.commonWrongOptionId});
  factory _QuestionStat.fromJson(Map<String, dynamic> json) => _$QuestionStatFromJson(json);

@override@JsonKey() final  String questionId;
@override@JsonKey() final  num correctRate;
@override final  String? commonWrongOptionId;

/// Create a copy of QuestionStat
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionStatCopyWith<_QuestionStat> get copyWith => __$QuestionStatCopyWithImpl<_QuestionStat>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuestionStatToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuestionStat&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.correctRate, correctRate) || other.correctRate == correctRate)&&(identical(other.commonWrongOptionId, commonWrongOptionId) || other.commonWrongOptionId == commonWrongOptionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionId,correctRate,commonWrongOptionId);

@override
String toString() {
  return 'QuestionStat(questionId: $questionId, correctRate: $correctRate, commonWrongOptionId: $commonWrongOptionId)';
}


}

/// @nodoc
abstract mixin class _$QuestionStatCopyWith<$Res> implements $QuestionStatCopyWith<$Res> {
  factory _$QuestionStatCopyWith(_QuestionStat value, $Res Function(_QuestionStat) _then) = __$QuestionStatCopyWithImpl;
@override @useResult
$Res call({
 String questionId, num correctRate, String? commonWrongOptionId
});




}
/// @nodoc
class __$QuestionStatCopyWithImpl<$Res>
    implements _$QuestionStatCopyWith<$Res> {
  __$QuestionStatCopyWithImpl(this._self, this._then);

  final _QuestionStat _self;
  final $Res Function(_QuestionStat) _then;

/// Create a copy of QuestionStat
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? questionId = null,Object? correctRate = null,Object? commonWrongOptionId = freezed,}) {
  return _then(_QuestionStat(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,correctRate: null == correctRate ? _self.correctRate : correctRate // ignore: cast_nullable_to_non_nullable
as num,commonWrongOptionId: freezed == commonWrongOptionId ? _self.commonWrongOptionId : commonWrongOptionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$QuizStats {

 String get quizId; int get attempts; int get learners; num get passRate; num get avgScore; num get medianMinutes; List<ScoreBand> get distribution; List<QuestionStat> get questions;
/// Create a copy of QuizStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizStatsCopyWith<QuizStats> get copyWith => _$QuizStatsCopyWithImpl<QuizStats>(this as QuizStats, _$identity);

  /// Serializes this QuizStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizStats&&(identical(other.quizId, quizId) || other.quizId == quizId)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.learners, learners) || other.learners == learners)&&(identical(other.passRate, passRate) || other.passRate == passRate)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore)&&(identical(other.medianMinutes, medianMinutes) || other.medianMinutes == medianMinutes)&&const DeepCollectionEquality().equals(other.distribution, distribution)&&const DeepCollectionEquality().equals(other.questions, questions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quizId,attempts,learners,passRate,avgScore,medianMinutes,const DeepCollectionEquality().hash(distribution),const DeepCollectionEquality().hash(questions));

@override
String toString() {
  return 'QuizStats(quizId: $quizId, attempts: $attempts, learners: $learners, passRate: $passRate, avgScore: $avgScore, medianMinutes: $medianMinutes, distribution: $distribution, questions: $questions)';
}


}

/// @nodoc
abstract mixin class $QuizStatsCopyWith<$Res>  {
  factory $QuizStatsCopyWith(QuizStats value, $Res Function(QuizStats) _then) = _$QuizStatsCopyWithImpl;
@useResult
$Res call({
 String quizId, int attempts, int learners, num passRate, num avgScore, num medianMinutes, List<ScoreBand> distribution, List<QuestionStat> questions
});




}
/// @nodoc
class _$QuizStatsCopyWithImpl<$Res>
    implements $QuizStatsCopyWith<$Res> {
  _$QuizStatsCopyWithImpl(this._self, this._then);

  final QuizStats _self;
  final $Res Function(QuizStats) _then;

/// Create a copy of QuizStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quizId = null,Object? attempts = null,Object? learners = null,Object? passRate = null,Object? avgScore = null,Object? medianMinutes = null,Object? distribution = null,Object? questions = null,}) {
  return _then(_self.copyWith(
quizId: null == quizId ? _self.quizId : quizId // ignore: cast_nullable_to_non_nullable
as String,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,learners: null == learners ? _self.learners : learners // ignore: cast_nullable_to_non_nullable
as int,passRate: null == passRate ? _self.passRate : passRate // ignore: cast_nullable_to_non_nullable
as num,avgScore: null == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as num,medianMinutes: null == medianMinutes ? _self.medianMinutes : medianMinutes // ignore: cast_nullable_to_non_nullable
as num,distribution: null == distribution ? _self.distribution : distribution // ignore: cast_nullable_to_non_nullable
as List<ScoreBand>,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as List<QuestionStat>,
  ));
}

}


/// Adds pattern-matching-related methods to [QuizStats].
extension QuizStatsPatterns on QuizStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizStats value)  $default,){
final _that = this;
switch (_that) {
case _QuizStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizStats value)?  $default,){
final _that = this;
switch (_that) {
case _QuizStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String quizId,  int attempts,  int learners,  num passRate,  num avgScore,  num medianMinutes,  List<ScoreBand> distribution,  List<QuestionStat> questions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizStats() when $default != null:
return $default(_that.quizId,_that.attempts,_that.learners,_that.passRate,_that.avgScore,_that.medianMinutes,_that.distribution,_that.questions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String quizId,  int attempts,  int learners,  num passRate,  num avgScore,  num medianMinutes,  List<ScoreBand> distribution,  List<QuestionStat> questions)  $default,) {final _that = this;
switch (_that) {
case _QuizStats():
return $default(_that.quizId,_that.attempts,_that.learners,_that.passRate,_that.avgScore,_that.medianMinutes,_that.distribution,_that.questions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String quizId,  int attempts,  int learners,  num passRate,  num avgScore,  num medianMinutes,  List<ScoreBand> distribution,  List<QuestionStat> questions)?  $default,) {final _that = this;
switch (_that) {
case _QuizStats() when $default != null:
return $default(_that.quizId,_that.attempts,_that.learners,_that.passRate,_that.avgScore,_that.medianMinutes,_that.distribution,_that.questions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizStats extends QuizStats {
  const _QuizStats({this.quizId = '', this.attempts = 0, this.learners = 0, this.passRate = 0, this.avgScore = 0, this.medianMinutes = 0, final  List<ScoreBand> distribution = const <ScoreBand>[], final  List<QuestionStat> questions = const <QuestionStat>[]}): _distribution = distribution,_questions = questions,super._();
  factory _QuizStats.fromJson(Map<String, dynamic> json) => _$QuizStatsFromJson(json);

@override@JsonKey() final  String quizId;
@override@JsonKey() final  int attempts;
@override@JsonKey() final  int learners;
@override@JsonKey() final  num passRate;
@override@JsonKey() final  num avgScore;
@override@JsonKey() final  num medianMinutes;
 final  List<ScoreBand> _distribution;
@override@JsonKey() List<ScoreBand> get distribution {
  if (_distribution is EqualUnmodifiableListView) return _distribution;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_distribution);
}

 final  List<QuestionStat> _questions;
@override@JsonKey() List<QuestionStat> get questions {
  if (_questions is EqualUnmodifiableListView) return _questions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_questions);
}


/// Create a copy of QuizStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizStatsCopyWith<_QuizStats> get copyWith => __$QuizStatsCopyWithImpl<_QuizStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizStats&&(identical(other.quizId, quizId) || other.quizId == quizId)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.learners, learners) || other.learners == learners)&&(identical(other.passRate, passRate) || other.passRate == passRate)&&(identical(other.avgScore, avgScore) || other.avgScore == avgScore)&&(identical(other.medianMinutes, medianMinutes) || other.medianMinutes == medianMinutes)&&const DeepCollectionEquality().equals(other._distribution, _distribution)&&const DeepCollectionEquality().equals(other._questions, _questions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quizId,attempts,learners,passRate,avgScore,medianMinutes,const DeepCollectionEquality().hash(_distribution),const DeepCollectionEquality().hash(_questions));

@override
String toString() {
  return 'QuizStats(quizId: $quizId, attempts: $attempts, learners: $learners, passRate: $passRate, avgScore: $avgScore, medianMinutes: $medianMinutes, distribution: $distribution, questions: $questions)';
}


}

/// @nodoc
abstract mixin class _$QuizStatsCopyWith<$Res> implements $QuizStatsCopyWith<$Res> {
  factory _$QuizStatsCopyWith(_QuizStats value, $Res Function(_QuizStats) _then) = __$QuizStatsCopyWithImpl;
@override @useResult
$Res call({
 String quizId, int attempts, int learners, num passRate, num avgScore, num medianMinutes, List<ScoreBand> distribution, List<QuestionStat> questions
});




}
/// @nodoc
class __$QuizStatsCopyWithImpl<$Res>
    implements _$QuizStatsCopyWith<$Res> {
  __$QuizStatsCopyWithImpl(this._self, this._then);

  final _QuizStats _self;
  final $Res Function(_QuizStats) _then;

/// Create a copy of QuizStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quizId = null,Object? attempts = null,Object? learners = null,Object? passRate = null,Object? avgScore = null,Object? medianMinutes = null,Object? distribution = null,Object? questions = null,}) {
  return _then(_QuizStats(
quizId: null == quizId ? _self.quizId : quizId // ignore: cast_nullable_to_non_nullable
as String,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,learners: null == learners ? _self.learners : learners // ignore: cast_nullable_to_non_nullable
as int,passRate: null == passRate ? _self.passRate : passRate // ignore: cast_nullable_to_non_nullable
as num,avgScore: null == avgScore ? _self.avgScore : avgScore // ignore: cast_nullable_to_non_nullable
as num,medianMinutes: null == medianMinutes ? _self.medianMinutes : medianMinutes // ignore: cast_nullable_to_non_nullable
as num,distribution: null == distribution ? _self._distribution : distribution // ignore: cast_nullable_to_non_nullable
as List<ScoreBand>,questions: null == questions ? _self._questions : questions // ignore: cast_nullable_to_non_nullable
as List<QuestionStat>,
  ));
}


}

// dart format on
