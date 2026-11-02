// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_attempt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReviewedQuestion {

@JsonKey(unknownEnumValue: AnswerState.unknown) AnswerState get state;/// May be negative: a wrong answer can cost marks.
 double get points;/// The learner's answer as submitted: option ids, or text.
 Object? get answer; List<String>? get correct; List<String>? get acceptedAnswers; String? get explanation;
/// Create a copy of ReviewedQuestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewedQuestionCopyWith<ReviewedQuestion> get copyWith => _$ReviewedQuestionCopyWithImpl<ReviewedQuestion>(this as ReviewedQuestion, _$identity);

  /// Serializes this ReviewedQuestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewedQuestion&&(identical(other.state, state) || other.state == state)&&(identical(other.points, points) || other.points == points)&&const DeepCollectionEquality().equals(other.answer, answer)&&const DeepCollectionEquality().equals(other.correct, correct)&&const DeepCollectionEquality().equals(other.acceptedAnswers, acceptedAnswers)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,state,points,const DeepCollectionEquality().hash(answer),const DeepCollectionEquality().hash(correct),const DeepCollectionEquality().hash(acceptedAnswers),explanation);

@override
String toString() {
  return 'ReviewedQuestion(state: $state, points: $points, answer: $answer, correct: $correct, acceptedAnswers: $acceptedAnswers, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class $ReviewedQuestionCopyWith<$Res>  {
  factory $ReviewedQuestionCopyWith(ReviewedQuestion value, $Res Function(ReviewedQuestion) _then) = _$ReviewedQuestionCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: AnswerState.unknown) AnswerState state, double points, Object? answer, List<String>? correct, List<String>? acceptedAnswers, String? explanation
});




}
/// @nodoc
class _$ReviewedQuestionCopyWithImpl<$Res>
    implements $ReviewedQuestionCopyWith<$Res> {
  _$ReviewedQuestionCopyWithImpl(this._self, this._then);

  final ReviewedQuestion _self;
  final $Res Function(ReviewedQuestion) _then;

/// Create a copy of ReviewedQuestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? state = null,Object? points = null,Object? answer = freezed,Object? correct = freezed,Object? acceptedAnswers = freezed,Object? explanation = freezed,}) {
  return _then(_self.copyWith(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AnswerState,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as double,answer: freezed == answer ? _self.answer : answer ,correct: freezed == correct ? _self.correct : correct // ignore: cast_nullable_to_non_nullable
as List<String>?,acceptedAnswers: freezed == acceptedAnswers ? _self.acceptedAnswers : acceptedAnswers // ignore: cast_nullable_to_non_nullable
as List<String>?,explanation: freezed == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReviewedQuestion].
extension ReviewedQuestionPatterns on ReviewedQuestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewedQuestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewedQuestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewedQuestion value)  $default,){
final _that = this;
switch (_that) {
case _ReviewedQuestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewedQuestion value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewedQuestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: AnswerState.unknown)  AnswerState state,  double points,  Object? answer,  List<String>? correct,  List<String>? acceptedAnswers,  String? explanation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewedQuestion() when $default != null:
return $default(_that.state,_that.points,_that.answer,_that.correct,_that.acceptedAnswers,_that.explanation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: AnswerState.unknown)  AnswerState state,  double points,  Object? answer,  List<String>? correct,  List<String>? acceptedAnswers,  String? explanation)  $default,) {final _that = this;
switch (_that) {
case _ReviewedQuestion():
return $default(_that.state,_that.points,_that.answer,_that.correct,_that.acceptedAnswers,_that.explanation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: AnswerState.unknown)  AnswerState state,  double points,  Object? answer,  List<String>? correct,  List<String>? acceptedAnswers,  String? explanation)?  $default,) {final _that = this;
switch (_that) {
case _ReviewedQuestion() when $default != null:
return $default(_that.state,_that.points,_that.answer,_that.correct,_that.acceptedAnswers,_that.explanation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReviewedQuestion implements ReviewedQuestion {
  const _ReviewedQuestion({@JsonKey(unknownEnumValue: AnswerState.unknown) this.state = AnswerState.unknown, this.points = 0, this.answer, final  List<String>? correct, final  List<String>? acceptedAnswers, this.explanation}): _correct = correct,_acceptedAnswers = acceptedAnswers;
  factory _ReviewedQuestion.fromJson(Map<String, dynamic> json) => _$ReviewedQuestionFromJson(json);

@override@JsonKey(unknownEnumValue: AnswerState.unknown) final  AnswerState state;
/// May be negative: a wrong answer can cost marks.
@override@JsonKey() final  double points;
/// The learner's answer as submitted: option ids, or text.
@override final  Object? answer;
 final  List<String>? _correct;
@override List<String>? get correct {
  final value = _correct;
  if (value == null) return null;
  if (_correct is EqualUnmodifiableListView) return _correct;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _acceptedAnswers;
@override List<String>? get acceptedAnswers {
  final value = _acceptedAnswers;
  if (value == null) return null;
  if (_acceptedAnswers is EqualUnmodifiableListView) return _acceptedAnswers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? explanation;

/// Create a copy of ReviewedQuestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewedQuestionCopyWith<_ReviewedQuestion> get copyWith => __$ReviewedQuestionCopyWithImpl<_ReviewedQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewedQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewedQuestion&&(identical(other.state, state) || other.state == state)&&(identical(other.points, points) || other.points == points)&&const DeepCollectionEquality().equals(other.answer, answer)&&const DeepCollectionEquality().equals(other._correct, _correct)&&const DeepCollectionEquality().equals(other._acceptedAnswers, _acceptedAnswers)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,state,points,const DeepCollectionEquality().hash(answer),const DeepCollectionEquality().hash(_correct),const DeepCollectionEquality().hash(_acceptedAnswers),explanation);

@override
String toString() {
  return 'ReviewedQuestion(state: $state, points: $points, answer: $answer, correct: $correct, acceptedAnswers: $acceptedAnswers, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class _$ReviewedQuestionCopyWith<$Res> implements $ReviewedQuestionCopyWith<$Res> {
  factory _$ReviewedQuestionCopyWith(_ReviewedQuestion value, $Res Function(_ReviewedQuestion) _then) = __$ReviewedQuestionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: AnswerState.unknown) AnswerState state, double points, Object? answer, List<String>? correct, List<String>? acceptedAnswers, String? explanation
});




}
/// @nodoc
class __$ReviewedQuestionCopyWithImpl<$Res>
    implements _$ReviewedQuestionCopyWith<$Res> {
  __$ReviewedQuestionCopyWithImpl(this._self, this._then);

  final _ReviewedQuestion _self;
  final $Res Function(_ReviewedQuestion) _then;

/// Create a copy of ReviewedQuestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? state = null,Object? points = null,Object? answer = freezed,Object? correct = freezed,Object? acceptedAnswers = freezed,Object? explanation = freezed,}) {
  return _then(_ReviewedQuestion(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AnswerState,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as double,answer: freezed == answer ? _self.answer : answer ,correct: freezed == correct ? _self._correct : correct // ignore: cast_nullable_to_non_nullable
as List<String>?,acceptedAnswers: freezed == acceptedAnswers ? _self._acceptedAnswers : acceptedAnswers // ignore: cast_nullable_to_non_nullable
as List<String>?,explanation: freezed == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AttemptReview {

 String get attemptId;@UtcDateTimeConverter() DateTime get submittedAt;@JsonKey(unknownEnumValue: ResultsVisibility.unknown) ResultsVisibility get showResults; bool get passed;/// Never below 0, even when [points] is.
 int? get percent; double? get points; double? get max; int? get passMark;/// Per question, only when the academy shows answers.
 Map<String, ReviewedQuestion>? get questions;/// The review is cut to the score while the learner can still take the quiz for credit.
 bool get keyWithheld;/// While the result is held until the quiz closes: when it is shown.
@NullableUtcDateTimeConverter() DateTime? get resultsAt;/// 1 for the first attempt; absent on attempts made before attempts were numbered.
 int? get attemptNo;@JsonKey(unknownEnumValue: AttemptFinish.unknown) AttemptFinish get finish;
/// Create a copy of AttemptReview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttemptReviewCopyWith<AttemptReview> get copyWith => _$AttemptReviewCopyWithImpl<AttemptReview>(this as AttemptReview, _$identity);

  /// Serializes this AttemptReview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttemptReview&&(identical(other.attemptId, attemptId) || other.attemptId == attemptId)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.showResults, showResults) || other.showResults == showResults)&&(identical(other.passed, passed) || other.passed == passed)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.points, points) || other.points == points)&&(identical(other.max, max) || other.max == max)&&(identical(other.passMark, passMark) || other.passMark == passMark)&&const DeepCollectionEquality().equals(other.questions, questions)&&(identical(other.keyWithheld, keyWithheld) || other.keyWithheld == keyWithheld)&&(identical(other.resultsAt, resultsAt) || other.resultsAt == resultsAt)&&(identical(other.attemptNo, attemptNo) || other.attemptNo == attemptNo)&&(identical(other.finish, finish) || other.finish == finish));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attemptId,submittedAt,showResults,passed,percent,points,max,passMark,const DeepCollectionEquality().hash(questions),keyWithheld,resultsAt,attemptNo,finish);

@override
String toString() {
  return 'AttemptReview(attemptId: $attemptId, submittedAt: $submittedAt, showResults: $showResults, passed: $passed, percent: $percent, points: $points, max: $max, passMark: $passMark, questions: $questions, keyWithheld: $keyWithheld, resultsAt: $resultsAt, attemptNo: $attemptNo, finish: $finish)';
}


}

/// @nodoc
abstract mixin class $AttemptReviewCopyWith<$Res>  {
  factory $AttemptReviewCopyWith(AttemptReview value, $Res Function(AttemptReview) _then) = _$AttemptReviewCopyWithImpl;
@useResult
$Res call({
 String attemptId,@UtcDateTimeConverter() DateTime submittedAt,@JsonKey(unknownEnumValue: ResultsVisibility.unknown) ResultsVisibility showResults, bool passed, int? percent, double? points, double? max, int? passMark, Map<String, ReviewedQuestion>? questions, bool keyWithheld,@NullableUtcDateTimeConverter() DateTime? resultsAt, int? attemptNo,@JsonKey(unknownEnumValue: AttemptFinish.unknown) AttemptFinish finish
});




}
/// @nodoc
class _$AttemptReviewCopyWithImpl<$Res>
    implements $AttemptReviewCopyWith<$Res> {
  _$AttemptReviewCopyWithImpl(this._self, this._then);

  final AttemptReview _self;
  final $Res Function(AttemptReview) _then;

/// Create a copy of AttemptReview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attemptId = null,Object? submittedAt = null,Object? showResults = null,Object? passed = null,Object? percent = freezed,Object? points = freezed,Object? max = freezed,Object? passMark = freezed,Object? questions = freezed,Object? keyWithheld = null,Object? resultsAt = freezed,Object? attemptNo = freezed,Object? finish = null,}) {
  return _then(_self.copyWith(
attemptId: null == attemptId ? _self.attemptId : attemptId // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,showResults: null == showResults ? _self.showResults : showResults // ignore: cast_nullable_to_non_nullable
as ResultsVisibility,passed: null == passed ? _self.passed : passed // ignore: cast_nullable_to_non_nullable
as bool,percent: freezed == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int?,points: freezed == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as double?,max: freezed == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as double?,passMark: freezed == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as int?,questions: freezed == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as Map<String, ReviewedQuestion>?,keyWithheld: null == keyWithheld ? _self.keyWithheld : keyWithheld // ignore: cast_nullable_to_non_nullable
as bool,resultsAt: freezed == resultsAt ? _self.resultsAt : resultsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,attemptNo: freezed == attemptNo ? _self.attemptNo : attemptNo // ignore: cast_nullable_to_non_nullable
as int?,finish: null == finish ? _self.finish : finish // ignore: cast_nullable_to_non_nullable
as AttemptFinish,
  ));
}

}


/// Adds pattern-matching-related methods to [AttemptReview].
extension AttemptReviewPatterns on AttemptReview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttemptReview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttemptReview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttemptReview value)  $default,){
final _that = this;
switch (_that) {
case _AttemptReview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttemptReview value)?  $default,){
final _that = this;
switch (_that) {
case _AttemptReview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String attemptId, @UtcDateTimeConverter()  DateTime submittedAt, @JsonKey(unknownEnumValue: ResultsVisibility.unknown)  ResultsVisibility showResults,  bool passed,  int? percent,  double? points,  double? max,  int? passMark,  Map<String, ReviewedQuestion>? questions,  bool keyWithheld, @NullableUtcDateTimeConverter()  DateTime? resultsAt,  int? attemptNo, @JsonKey(unknownEnumValue: AttemptFinish.unknown)  AttemptFinish finish)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttemptReview() when $default != null:
return $default(_that.attemptId,_that.submittedAt,_that.showResults,_that.passed,_that.percent,_that.points,_that.max,_that.passMark,_that.questions,_that.keyWithheld,_that.resultsAt,_that.attemptNo,_that.finish);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String attemptId, @UtcDateTimeConverter()  DateTime submittedAt, @JsonKey(unknownEnumValue: ResultsVisibility.unknown)  ResultsVisibility showResults,  bool passed,  int? percent,  double? points,  double? max,  int? passMark,  Map<String, ReviewedQuestion>? questions,  bool keyWithheld, @NullableUtcDateTimeConverter()  DateTime? resultsAt,  int? attemptNo, @JsonKey(unknownEnumValue: AttemptFinish.unknown)  AttemptFinish finish)  $default,) {final _that = this;
switch (_that) {
case _AttemptReview():
return $default(_that.attemptId,_that.submittedAt,_that.showResults,_that.passed,_that.percent,_that.points,_that.max,_that.passMark,_that.questions,_that.keyWithheld,_that.resultsAt,_that.attemptNo,_that.finish);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String attemptId, @UtcDateTimeConverter()  DateTime submittedAt, @JsonKey(unknownEnumValue: ResultsVisibility.unknown)  ResultsVisibility showResults,  bool passed,  int? percent,  double? points,  double? max,  int? passMark,  Map<String, ReviewedQuestion>? questions,  bool keyWithheld, @NullableUtcDateTimeConverter()  DateTime? resultsAt,  int? attemptNo, @JsonKey(unknownEnumValue: AttemptFinish.unknown)  AttemptFinish finish)?  $default,) {final _that = this;
switch (_that) {
case _AttemptReview() when $default != null:
return $default(_that.attemptId,_that.submittedAt,_that.showResults,_that.passed,_that.percent,_that.points,_that.max,_that.passMark,_that.questions,_that.keyWithheld,_that.resultsAt,_that.attemptNo,_that.finish);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttemptReview extends AttemptReview {
  const _AttemptReview({required this.attemptId, @UtcDateTimeConverter() required this.submittedAt, @JsonKey(unknownEnumValue: ResultsVisibility.unknown) this.showResults = ResultsVisibility.hidden, this.passed = false, this.percent, this.points, this.max, this.passMark, final  Map<String, ReviewedQuestion>? questions, this.keyWithheld = false, @NullableUtcDateTimeConverter() this.resultsAt, this.attemptNo, @JsonKey(unknownEnumValue: AttemptFinish.unknown) this.finish = AttemptFinish.submitted}): _questions = questions,super._();
  factory _AttemptReview.fromJson(Map<String, dynamic> json) => _$AttemptReviewFromJson(json);

@override final  String attemptId;
@override@UtcDateTimeConverter() final  DateTime submittedAt;
@override@JsonKey(unknownEnumValue: ResultsVisibility.unknown) final  ResultsVisibility showResults;
@override@JsonKey() final  bool passed;
/// Never below 0, even when [points] is.
@override final  int? percent;
@override final  double? points;
@override final  double? max;
@override final  int? passMark;
/// Per question, only when the academy shows answers.
 final  Map<String, ReviewedQuestion>? _questions;
/// Per question, only when the academy shows answers.
@override Map<String, ReviewedQuestion>? get questions {
  final value = _questions;
  if (value == null) return null;
  if (_questions is EqualUnmodifiableMapView) return _questions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// The review is cut to the score while the learner can still take the quiz for credit.
@override@JsonKey() final  bool keyWithheld;
/// While the result is held until the quiz closes: when it is shown.
@override@NullableUtcDateTimeConverter() final  DateTime? resultsAt;
/// 1 for the first attempt; absent on attempts made before attempts were numbered.
@override final  int? attemptNo;
@override@JsonKey(unknownEnumValue: AttemptFinish.unknown) final  AttemptFinish finish;

/// Create a copy of AttemptReview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttemptReviewCopyWith<_AttemptReview> get copyWith => __$AttemptReviewCopyWithImpl<_AttemptReview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttemptReviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttemptReview&&(identical(other.attemptId, attemptId) || other.attemptId == attemptId)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.showResults, showResults) || other.showResults == showResults)&&(identical(other.passed, passed) || other.passed == passed)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.points, points) || other.points == points)&&(identical(other.max, max) || other.max == max)&&(identical(other.passMark, passMark) || other.passMark == passMark)&&const DeepCollectionEquality().equals(other._questions, _questions)&&(identical(other.keyWithheld, keyWithheld) || other.keyWithheld == keyWithheld)&&(identical(other.resultsAt, resultsAt) || other.resultsAt == resultsAt)&&(identical(other.attemptNo, attemptNo) || other.attemptNo == attemptNo)&&(identical(other.finish, finish) || other.finish == finish));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attemptId,submittedAt,showResults,passed,percent,points,max,passMark,const DeepCollectionEquality().hash(_questions),keyWithheld,resultsAt,attemptNo,finish);

@override
String toString() {
  return 'AttemptReview(attemptId: $attemptId, submittedAt: $submittedAt, showResults: $showResults, passed: $passed, percent: $percent, points: $points, max: $max, passMark: $passMark, questions: $questions, keyWithheld: $keyWithheld, resultsAt: $resultsAt, attemptNo: $attemptNo, finish: $finish)';
}


}

/// @nodoc
abstract mixin class _$AttemptReviewCopyWith<$Res> implements $AttemptReviewCopyWith<$Res> {
  factory _$AttemptReviewCopyWith(_AttemptReview value, $Res Function(_AttemptReview) _then) = __$AttemptReviewCopyWithImpl;
@override @useResult
$Res call({
 String attemptId,@UtcDateTimeConverter() DateTime submittedAt,@JsonKey(unknownEnumValue: ResultsVisibility.unknown) ResultsVisibility showResults, bool passed, int? percent, double? points, double? max, int? passMark, Map<String, ReviewedQuestion>? questions, bool keyWithheld,@NullableUtcDateTimeConverter() DateTime? resultsAt, int? attemptNo,@JsonKey(unknownEnumValue: AttemptFinish.unknown) AttemptFinish finish
});




}
/// @nodoc
class __$AttemptReviewCopyWithImpl<$Res>
    implements _$AttemptReviewCopyWith<$Res> {
  __$AttemptReviewCopyWithImpl(this._self, this._then);

  final _AttemptReview _self;
  final $Res Function(_AttemptReview) _then;

/// Create a copy of AttemptReview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attemptId = null,Object? submittedAt = null,Object? showResults = null,Object? passed = null,Object? percent = freezed,Object? points = freezed,Object? max = freezed,Object? passMark = freezed,Object? questions = freezed,Object? keyWithheld = null,Object? resultsAt = freezed,Object? attemptNo = freezed,Object? finish = null,}) {
  return _then(_AttemptReview(
attemptId: null == attemptId ? _self.attemptId : attemptId // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,showResults: null == showResults ? _self.showResults : showResults // ignore: cast_nullable_to_non_nullable
as ResultsVisibility,passed: null == passed ? _self.passed : passed // ignore: cast_nullable_to_non_nullable
as bool,percent: freezed == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int?,points: freezed == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as double?,max: freezed == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as double?,passMark: freezed == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as int?,questions: freezed == questions ? _self._questions : questions // ignore: cast_nullable_to_non_nullable
as Map<String, ReviewedQuestion>?,keyWithheld: null == keyWithheld ? _self.keyWithheld : keyWithheld // ignore: cast_nullable_to_non_nullable
as bool,resultsAt: freezed == resultsAt ? _self.resultsAt : resultsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,attemptNo: freezed == attemptNo ? _self.attemptNo : attemptNo // ignore: cast_nullable_to_non_nullable
as int?,finish: null == finish ? _self.finish : finish // ignore: cast_nullable_to_non_nullable
as AttemptFinish,
  ));
}


}


/// @nodoc
mixin _$QuizAttempts {

 List<AttemptReview> get attempts; QuizStanding get standing;
/// Create a copy of QuizAttempts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizAttemptsCopyWith<QuizAttempts> get copyWith => _$QuizAttemptsCopyWithImpl<QuizAttempts>(this as QuizAttempts, _$identity);

  /// Serializes this QuizAttempts to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizAttempts&&const DeepCollectionEquality().equals(other.attempts, attempts)&&(identical(other.standing, standing) || other.standing == standing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(attempts),standing);

@override
String toString() {
  return 'QuizAttempts(attempts: $attempts, standing: $standing)';
}


}

/// @nodoc
abstract mixin class $QuizAttemptsCopyWith<$Res>  {
  factory $QuizAttemptsCopyWith(QuizAttempts value, $Res Function(QuizAttempts) _then) = _$QuizAttemptsCopyWithImpl;
@useResult
$Res call({
 List<AttemptReview> attempts, QuizStanding standing
});


$QuizStandingCopyWith<$Res> get standing;

}
/// @nodoc
class _$QuizAttemptsCopyWithImpl<$Res>
    implements $QuizAttemptsCopyWith<$Res> {
  _$QuizAttemptsCopyWithImpl(this._self, this._then);

  final QuizAttempts _self;
  final $Res Function(QuizAttempts) _then;

/// Create a copy of QuizAttempts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attempts = null,Object? standing = null,}) {
  return _then(_self.copyWith(
attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as List<AttemptReview>,standing: null == standing ? _self.standing : standing // ignore: cast_nullable_to_non_nullable
as QuizStanding,
  ));
}
/// Create a copy of QuizAttempts
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizStandingCopyWith<$Res> get standing {
  
  return $QuizStandingCopyWith<$Res>(_self.standing, (value) {
    return _then(_self.copyWith(standing: value));
  });
}
}


/// Adds pattern-matching-related methods to [QuizAttempts].
extension QuizAttemptsPatterns on QuizAttempts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizAttempts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizAttempts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizAttempts value)  $default,){
final _that = this;
switch (_that) {
case _QuizAttempts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizAttempts value)?  $default,){
final _that = this;
switch (_that) {
case _QuizAttempts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AttemptReview> attempts,  QuizStanding standing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizAttempts() when $default != null:
return $default(_that.attempts,_that.standing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AttemptReview> attempts,  QuizStanding standing)  $default,) {final _that = this;
switch (_that) {
case _QuizAttempts():
return $default(_that.attempts,_that.standing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AttemptReview> attempts,  QuizStanding standing)?  $default,) {final _that = this;
switch (_that) {
case _QuizAttempts() when $default != null:
return $default(_that.attempts,_that.standing);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizAttempts implements QuizAttempts {
  const _QuizAttempts({final  List<AttemptReview> attempts = const <AttemptReview>[], required this.standing}): _attempts = attempts;
  factory _QuizAttempts.fromJson(Map<String, dynamic> json) => _$QuizAttemptsFromJson(json);

 final  List<AttemptReview> _attempts;
@override@JsonKey() List<AttemptReview> get attempts {
  if (_attempts is EqualUnmodifiableListView) return _attempts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attempts);
}

@override final  QuizStanding standing;

/// Create a copy of QuizAttempts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizAttemptsCopyWith<_QuizAttempts> get copyWith => __$QuizAttemptsCopyWithImpl<_QuizAttempts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizAttemptsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizAttempts&&const DeepCollectionEquality().equals(other._attempts, _attempts)&&(identical(other.standing, standing) || other.standing == standing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_attempts),standing);

@override
String toString() {
  return 'QuizAttempts(attempts: $attempts, standing: $standing)';
}


}

/// @nodoc
abstract mixin class _$QuizAttemptsCopyWith<$Res> implements $QuizAttemptsCopyWith<$Res> {
  factory _$QuizAttemptsCopyWith(_QuizAttempts value, $Res Function(_QuizAttempts) _then) = __$QuizAttemptsCopyWithImpl;
@override @useResult
$Res call({
 List<AttemptReview> attempts, QuizStanding standing
});


@override $QuizStandingCopyWith<$Res> get standing;

}
/// @nodoc
class __$QuizAttemptsCopyWithImpl<$Res>
    implements _$QuizAttemptsCopyWith<$Res> {
  __$QuizAttemptsCopyWithImpl(this._self, this._then);

  final _QuizAttempts _self;
  final $Res Function(_QuizAttempts) _then;

/// Create a copy of QuizAttempts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attempts = null,Object? standing = null,}) {
  return _then(_QuizAttempts(
attempts: null == attempts ? _self._attempts : attempts // ignore: cast_nullable_to_non_nullable
as List<AttemptReview>,standing: null == standing ? _self.standing : standing // ignore: cast_nullable_to_non_nullable
as QuizStanding,
  ));
}

/// Create a copy of QuizAttempts
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizStandingCopyWith<$Res> get standing {
  
  return $QuizStandingCopyWith<$Res>(_self.standing, (value) {
    return _then(_self.copyWith(standing: value));
  });
}
}


/// @nodoc
mixin _$QuizHandIn {

 QuizSessionView get session;/// The lesson's completion, on a pass; null otherwise.
 CompleteResult? get completion;/// Whether the final sheet sent with this call was kept — false after the deadline, and on a
/// repeat.
 bool get answersAccepted; AttemptReview? get review; QuizStanding get standing;
/// Create a copy of QuizHandIn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizHandInCopyWith<QuizHandIn> get copyWith => _$QuizHandInCopyWithImpl<QuizHandIn>(this as QuizHandIn, _$identity);

  /// Serializes this QuizHandIn to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizHandIn&&(identical(other.session, session) || other.session == session)&&(identical(other.completion, completion) || other.completion == completion)&&(identical(other.answersAccepted, answersAccepted) || other.answersAccepted == answersAccepted)&&(identical(other.review, review) || other.review == review)&&(identical(other.standing, standing) || other.standing == standing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,session,completion,answersAccepted,review,standing);

@override
String toString() {
  return 'QuizHandIn(session: $session, completion: $completion, answersAccepted: $answersAccepted, review: $review, standing: $standing)';
}


}

/// @nodoc
abstract mixin class $QuizHandInCopyWith<$Res>  {
  factory $QuizHandInCopyWith(QuizHandIn value, $Res Function(QuizHandIn) _then) = _$QuizHandInCopyWithImpl;
@useResult
$Res call({
 QuizSessionView session, CompleteResult? completion, bool answersAccepted, AttemptReview? review, QuizStanding standing
});


$QuizSessionViewCopyWith<$Res> get session;$CompleteResultCopyWith<$Res>? get completion;$AttemptReviewCopyWith<$Res>? get review;$QuizStandingCopyWith<$Res> get standing;

}
/// @nodoc
class _$QuizHandInCopyWithImpl<$Res>
    implements $QuizHandInCopyWith<$Res> {
  _$QuizHandInCopyWithImpl(this._self, this._then);

  final QuizHandIn _self;
  final $Res Function(QuizHandIn) _then;

/// Create a copy of QuizHandIn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? session = null,Object? completion = freezed,Object? answersAccepted = null,Object? review = freezed,Object? standing = null,}) {
  return _then(_self.copyWith(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as QuizSessionView,completion: freezed == completion ? _self.completion : completion // ignore: cast_nullable_to_non_nullable
as CompleteResult?,answersAccepted: null == answersAccepted ? _self.answersAccepted : answersAccepted // ignore: cast_nullable_to_non_nullable
as bool,review: freezed == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as AttemptReview?,standing: null == standing ? _self.standing : standing // ignore: cast_nullable_to_non_nullable
as QuizStanding,
  ));
}
/// Create a copy of QuizHandIn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizSessionViewCopyWith<$Res> get session {
  
  return $QuizSessionViewCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}/// Create a copy of QuizHandIn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompleteResultCopyWith<$Res>? get completion {
    if (_self.completion == null) {
    return null;
  }

  return $CompleteResultCopyWith<$Res>(_self.completion!, (value) {
    return _then(_self.copyWith(completion: value));
  });
}/// Create a copy of QuizHandIn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AttemptReviewCopyWith<$Res>? get review {
    if (_self.review == null) {
    return null;
  }

  return $AttemptReviewCopyWith<$Res>(_self.review!, (value) {
    return _then(_self.copyWith(review: value));
  });
}/// Create a copy of QuizHandIn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizStandingCopyWith<$Res> get standing {
  
  return $QuizStandingCopyWith<$Res>(_self.standing, (value) {
    return _then(_self.copyWith(standing: value));
  });
}
}


/// Adds pattern-matching-related methods to [QuizHandIn].
extension QuizHandInPatterns on QuizHandIn {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizHandIn value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizHandIn() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizHandIn value)  $default,){
final _that = this;
switch (_that) {
case _QuizHandIn():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizHandIn value)?  $default,){
final _that = this;
switch (_that) {
case _QuizHandIn() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( QuizSessionView session,  CompleteResult? completion,  bool answersAccepted,  AttemptReview? review,  QuizStanding standing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizHandIn() when $default != null:
return $default(_that.session,_that.completion,_that.answersAccepted,_that.review,_that.standing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( QuizSessionView session,  CompleteResult? completion,  bool answersAccepted,  AttemptReview? review,  QuizStanding standing)  $default,) {final _that = this;
switch (_that) {
case _QuizHandIn():
return $default(_that.session,_that.completion,_that.answersAccepted,_that.review,_that.standing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( QuizSessionView session,  CompleteResult? completion,  bool answersAccepted,  AttemptReview? review,  QuizStanding standing)?  $default,) {final _that = this;
switch (_that) {
case _QuizHandIn() when $default != null:
return $default(_that.session,_that.completion,_that.answersAccepted,_that.review,_that.standing);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizHandIn implements QuizHandIn {
  const _QuizHandIn({required this.session, this.completion, this.answersAccepted = false, this.review, required this.standing});
  factory _QuizHandIn.fromJson(Map<String, dynamic> json) => _$QuizHandInFromJson(json);

@override final  QuizSessionView session;
/// The lesson's completion, on a pass; null otherwise.
@override final  CompleteResult? completion;
/// Whether the final sheet sent with this call was kept — false after the deadline, and on a
/// repeat.
@override@JsonKey() final  bool answersAccepted;
@override final  AttemptReview? review;
@override final  QuizStanding standing;

/// Create a copy of QuizHandIn
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizHandInCopyWith<_QuizHandIn> get copyWith => __$QuizHandInCopyWithImpl<_QuizHandIn>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizHandInToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizHandIn&&(identical(other.session, session) || other.session == session)&&(identical(other.completion, completion) || other.completion == completion)&&(identical(other.answersAccepted, answersAccepted) || other.answersAccepted == answersAccepted)&&(identical(other.review, review) || other.review == review)&&(identical(other.standing, standing) || other.standing == standing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,session,completion,answersAccepted,review,standing);

@override
String toString() {
  return 'QuizHandIn(session: $session, completion: $completion, answersAccepted: $answersAccepted, review: $review, standing: $standing)';
}


}

/// @nodoc
abstract mixin class _$QuizHandInCopyWith<$Res> implements $QuizHandInCopyWith<$Res> {
  factory _$QuizHandInCopyWith(_QuizHandIn value, $Res Function(_QuizHandIn) _then) = __$QuizHandInCopyWithImpl;
@override @useResult
$Res call({
 QuizSessionView session, CompleteResult? completion, bool answersAccepted, AttemptReview? review, QuizStanding standing
});


@override $QuizSessionViewCopyWith<$Res> get session;@override $CompleteResultCopyWith<$Res>? get completion;@override $AttemptReviewCopyWith<$Res>? get review;@override $QuizStandingCopyWith<$Res> get standing;

}
/// @nodoc
class __$QuizHandInCopyWithImpl<$Res>
    implements _$QuizHandInCopyWith<$Res> {
  __$QuizHandInCopyWithImpl(this._self, this._then);

  final _QuizHandIn _self;
  final $Res Function(_QuizHandIn) _then;

/// Create a copy of QuizHandIn
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? session = null,Object? completion = freezed,Object? answersAccepted = null,Object? review = freezed,Object? standing = null,}) {
  return _then(_QuizHandIn(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as QuizSessionView,completion: freezed == completion ? _self.completion : completion // ignore: cast_nullable_to_non_nullable
as CompleteResult?,answersAccepted: null == answersAccepted ? _self.answersAccepted : answersAccepted // ignore: cast_nullable_to_non_nullable
as bool,review: freezed == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as AttemptReview?,standing: null == standing ? _self.standing : standing // ignore: cast_nullable_to_non_nullable
as QuizStanding,
  ));
}

/// Create a copy of QuizHandIn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizSessionViewCopyWith<$Res> get session {
  
  return $QuizSessionViewCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}/// Create a copy of QuizHandIn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompleteResultCopyWith<$Res>? get completion {
    if (_self.completion == null) {
    return null;
  }

  return $CompleteResultCopyWith<$Res>(_self.completion!, (value) {
    return _then(_self.copyWith(completion: value));
  });
}/// Create a copy of QuizHandIn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AttemptReviewCopyWith<$Res>? get review {
    if (_self.review == null) {
    return null;
  }

  return $AttemptReviewCopyWith<$Res>(_self.review!, (value) {
    return _then(_self.copyWith(review: value));
  });
}/// Create a copy of QuizHandIn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizStandingCopyWith<$Res> get standing {
  
  return $QuizStandingCopyWith<$Res>(_self.standing, (value) {
    return _then(_self.copyWith(standing: value));
  });
}
}

// dart format on
