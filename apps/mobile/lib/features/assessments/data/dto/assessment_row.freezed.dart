// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assessment_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AssessmentRow {

 String get id; String get lessonId; String get courseId; String get courseTitle; String get title; int get questions; int get durationMin; int get passMark;/// 0 means unlimited.
 int get attemptsAllowed; int get attemptsUsed;@JsonKey(unknownEnumValue: AssessmentState.unknown) AssessmentState get state; String? get lockedReason;/// The learner's best percentage so far. Absent while results are held until the quiz closes.
 int? get score;@JsonKey(unknownEnumValue: QuizWindow.unknown) QuizWindow get window;@NullableUtcDateTimeConverter() DateTime? get opensAt;@NullableUtcDateTimeConverter() DateTime? get closesAt;/// When the attempt under way must be handed in, by the server's clock.
@NullableUtcDateTimeConverter() DateTime? get deadlineAt;/// While results are held until the quiz closes: when they are shown.
@NullableUtcDateTimeConverter() DateTime? get resultsAt;/// Some question costs marks for a wrong answer.
 bool get negativeMarking;/// The learner has passed: further attempts are practice, and not limited.
 bool get passed;
/// Create a copy of AssessmentRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssessmentRowCopyWith<AssessmentRow> get copyWith => _$AssessmentRowCopyWithImpl<AssessmentRow>(this as AssessmentRow, _$identity);

  /// Serializes this AssessmentRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssessmentRow&&(identical(other.id, id) || other.id == id)&&(identical(other.lessonId, lessonId) || other.lessonId == lessonId)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.title, title) || other.title == title)&&(identical(other.questions, questions) || other.questions == questions)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.passMark, passMark) || other.passMark == passMark)&&(identical(other.attemptsAllowed, attemptsAllowed) || other.attemptsAllowed == attemptsAllowed)&&(identical(other.attemptsUsed, attemptsUsed) || other.attemptsUsed == attemptsUsed)&&(identical(other.state, state) || other.state == state)&&(identical(other.lockedReason, lockedReason) || other.lockedReason == lockedReason)&&(identical(other.score, score) || other.score == score)&&(identical(other.window, window) || other.window == window)&&(identical(other.opensAt, opensAt) || other.opensAt == opensAt)&&(identical(other.closesAt, closesAt) || other.closesAt == closesAt)&&(identical(other.deadlineAt, deadlineAt) || other.deadlineAt == deadlineAt)&&(identical(other.resultsAt, resultsAt) || other.resultsAt == resultsAt)&&(identical(other.negativeMarking, negativeMarking) || other.negativeMarking == negativeMarking)&&(identical(other.passed, passed) || other.passed == passed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,lessonId,courseId,courseTitle,title,questions,durationMin,passMark,attemptsAllowed,attemptsUsed,state,lockedReason,score,window,opensAt,closesAt,deadlineAt,resultsAt,negativeMarking,passed]);

@override
String toString() {
  return 'AssessmentRow(id: $id, lessonId: $lessonId, courseId: $courseId, courseTitle: $courseTitle, title: $title, questions: $questions, durationMin: $durationMin, passMark: $passMark, attemptsAllowed: $attemptsAllowed, attemptsUsed: $attemptsUsed, state: $state, lockedReason: $lockedReason, score: $score, window: $window, opensAt: $opensAt, closesAt: $closesAt, deadlineAt: $deadlineAt, resultsAt: $resultsAt, negativeMarking: $negativeMarking, passed: $passed)';
}


}

/// @nodoc
abstract mixin class $AssessmentRowCopyWith<$Res>  {
  factory $AssessmentRowCopyWith(AssessmentRow value, $Res Function(AssessmentRow) _then) = _$AssessmentRowCopyWithImpl;
@useResult
$Res call({
 String id, String lessonId, String courseId, String courseTitle, String title, int questions, int durationMin, int passMark, int attemptsAllowed, int attemptsUsed,@JsonKey(unknownEnumValue: AssessmentState.unknown) AssessmentState state, String? lockedReason, int? score,@JsonKey(unknownEnumValue: QuizWindow.unknown) QuizWindow window,@NullableUtcDateTimeConverter() DateTime? opensAt,@NullableUtcDateTimeConverter() DateTime? closesAt,@NullableUtcDateTimeConverter() DateTime? deadlineAt,@NullableUtcDateTimeConverter() DateTime? resultsAt, bool negativeMarking, bool passed
});




}
/// @nodoc
class _$AssessmentRowCopyWithImpl<$Res>
    implements $AssessmentRowCopyWith<$Res> {
  _$AssessmentRowCopyWithImpl(this._self, this._then);

  final AssessmentRow _self;
  final $Res Function(AssessmentRow) _then;

/// Create a copy of AssessmentRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? lessonId = null,Object? courseId = null,Object? courseTitle = null,Object? title = null,Object? questions = null,Object? durationMin = null,Object? passMark = null,Object? attemptsAllowed = null,Object? attemptsUsed = null,Object? state = null,Object? lockedReason = freezed,Object? score = freezed,Object? window = null,Object? opensAt = freezed,Object? closesAt = freezed,Object? deadlineAt = freezed,Object? resultsAt = freezed,Object? negativeMarking = null,Object? passed = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lessonId: null == lessonId ? _self.lessonId : lessonId // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as int,durationMin: null == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int,passMark: null == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as int,attemptsAllowed: null == attemptsAllowed ? _self.attemptsAllowed : attemptsAllowed // ignore: cast_nullable_to_non_nullable
as int,attemptsUsed: null == attemptsUsed ? _self.attemptsUsed : attemptsUsed // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AssessmentState,lockedReason: freezed == lockedReason ? _self.lockedReason : lockedReason // ignore: cast_nullable_to_non_nullable
as String?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int?,window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as QuizWindow,opensAt: freezed == opensAt ? _self.opensAt : opensAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closesAt: freezed == closesAt ? _self.closesAt : closesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deadlineAt: freezed == deadlineAt ? _self.deadlineAt : deadlineAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resultsAt: freezed == resultsAt ? _self.resultsAt : resultsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,negativeMarking: null == negativeMarking ? _self.negativeMarking : negativeMarking // ignore: cast_nullable_to_non_nullable
as bool,passed: null == passed ? _self.passed : passed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AssessmentRow].
extension AssessmentRowPatterns on AssessmentRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssessmentRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssessmentRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssessmentRow value)  $default,){
final _that = this;
switch (_that) {
case _AssessmentRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssessmentRow value)?  $default,){
final _that = this;
switch (_that) {
case _AssessmentRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String lessonId,  String courseId,  String courseTitle,  String title,  int questions,  int durationMin,  int passMark,  int attemptsAllowed,  int attemptsUsed, @JsonKey(unknownEnumValue: AssessmentState.unknown)  AssessmentState state,  String? lockedReason,  int? score, @JsonKey(unknownEnumValue: QuizWindow.unknown)  QuizWindow window, @NullableUtcDateTimeConverter()  DateTime? opensAt, @NullableUtcDateTimeConverter()  DateTime? closesAt, @NullableUtcDateTimeConverter()  DateTime? deadlineAt, @NullableUtcDateTimeConverter()  DateTime? resultsAt,  bool negativeMarking,  bool passed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssessmentRow() when $default != null:
return $default(_that.id,_that.lessonId,_that.courseId,_that.courseTitle,_that.title,_that.questions,_that.durationMin,_that.passMark,_that.attemptsAllowed,_that.attemptsUsed,_that.state,_that.lockedReason,_that.score,_that.window,_that.opensAt,_that.closesAt,_that.deadlineAt,_that.resultsAt,_that.negativeMarking,_that.passed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String lessonId,  String courseId,  String courseTitle,  String title,  int questions,  int durationMin,  int passMark,  int attemptsAllowed,  int attemptsUsed, @JsonKey(unknownEnumValue: AssessmentState.unknown)  AssessmentState state,  String? lockedReason,  int? score, @JsonKey(unknownEnumValue: QuizWindow.unknown)  QuizWindow window, @NullableUtcDateTimeConverter()  DateTime? opensAt, @NullableUtcDateTimeConverter()  DateTime? closesAt, @NullableUtcDateTimeConverter()  DateTime? deadlineAt, @NullableUtcDateTimeConverter()  DateTime? resultsAt,  bool negativeMarking,  bool passed)  $default,) {final _that = this;
switch (_that) {
case _AssessmentRow():
return $default(_that.id,_that.lessonId,_that.courseId,_that.courseTitle,_that.title,_that.questions,_that.durationMin,_that.passMark,_that.attemptsAllowed,_that.attemptsUsed,_that.state,_that.lockedReason,_that.score,_that.window,_that.opensAt,_that.closesAt,_that.deadlineAt,_that.resultsAt,_that.negativeMarking,_that.passed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String lessonId,  String courseId,  String courseTitle,  String title,  int questions,  int durationMin,  int passMark,  int attemptsAllowed,  int attemptsUsed, @JsonKey(unknownEnumValue: AssessmentState.unknown)  AssessmentState state,  String? lockedReason,  int? score, @JsonKey(unknownEnumValue: QuizWindow.unknown)  QuizWindow window, @NullableUtcDateTimeConverter()  DateTime? opensAt, @NullableUtcDateTimeConverter()  DateTime? closesAt, @NullableUtcDateTimeConverter()  DateTime? deadlineAt, @NullableUtcDateTimeConverter()  DateTime? resultsAt,  bool negativeMarking,  bool passed)?  $default,) {final _that = this;
switch (_that) {
case _AssessmentRow() when $default != null:
return $default(_that.id,_that.lessonId,_that.courseId,_that.courseTitle,_that.title,_that.questions,_that.durationMin,_that.passMark,_that.attemptsAllowed,_that.attemptsUsed,_that.state,_that.lockedReason,_that.score,_that.window,_that.opensAt,_that.closesAt,_that.deadlineAt,_that.resultsAt,_that.negativeMarking,_that.passed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssessmentRow extends AssessmentRow {
  const _AssessmentRow({required this.id, required this.lessonId, required this.courseId, this.courseTitle = '', this.title = '', this.questions = 0, this.durationMin = 0, this.passMark = 0, this.attemptsAllowed = 0, this.attemptsUsed = 0, @JsonKey(unknownEnumValue: AssessmentState.unknown) this.state = AssessmentState.unknown, this.lockedReason, this.score, @JsonKey(unknownEnumValue: QuizWindow.unknown) this.window = QuizWindow.open, @NullableUtcDateTimeConverter() this.opensAt, @NullableUtcDateTimeConverter() this.closesAt, @NullableUtcDateTimeConverter() this.deadlineAt, @NullableUtcDateTimeConverter() this.resultsAt, this.negativeMarking = false, this.passed = false}): super._();
  factory _AssessmentRow.fromJson(Map<String, dynamic> json) => _$AssessmentRowFromJson(json);

@override final  String id;
@override final  String lessonId;
@override final  String courseId;
@override@JsonKey() final  String courseTitle;
@override@JsonKey() final  String title;
@override@JsonKey() final  int questions;
@override@JsonKey() final  int durationMin;
@override@JsonKey() final  int passMark;
/// 0 means unlimited.
@override@JsonKey() final  int attemptsAllowed;
@override@JsonKey() final  int attemptsUsed;
@override@JsonKey(unknownEnumValue: AssessmentState.unknown) final  AssessmentState state;
@override final  String? lockedReason;
/// The learner's best percentage so far. Absent while results are held until the quiz closes.
@override final  int? score;
@override@JsonKey(unknownEnumValue: QuizWindow.unknown) final  QuizWindow window;
@override@NullableUtcDateTimeConverter() final  DateTime? opensAt;
@override@NullableUtcDateTimeConverter() final  DateTime? closesAt;
/// When the attempt under way must be handed in, by the server's clock.
@override@NullableUtcDateTimeConverter() final  DateTime? deadlineAt;
/// While results are held until the quiz closes: when they are shown.
@override@NullableUtcDateTimeConverter() final  DateTime? resultsAt;
/// Some question costs marks for a wrong answer.
@override@JsonKey() final  bool negativeMarking;
/// The learner has passed: further attempts are practice, and not limited.
@override@JsonKey() final  bool passed;

/// Create a copy of AssessmentRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssessmentRowCopyWith<_AssessmentRow> get copyWith => __$AssessmentRowCopyWithImpl<_AssessmentRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssessmentRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssessmentRow&&(identical(other.id, id) || other.id == id)&&(identical(other.lessonId, lessonId) || other.lessonId == lessonId)&&(identical(other.courseId, courseId) || other.courseId == courseId)&&(identical(other.courseTitle, courseTitle) || other.courseTitle == courseTitle)&&(identical(other.title, title) || other.title == title)&&(identical(other.questions, questions) || other.questions == questions)&&(identical(other.durationMin, durationMin) || other.durationMin == durationMin)&&(identical(other.passMark, passMark) || other.passMark == passMark)&&(identical(other.attemptsAllowed, attemptsAllowed) || other.attemptsAllowed == attemptsAllowed)&&(identical(other.attemptsUsed, attemptsUsed) || other.attemptsUsed == attemptsUsed)&&(identical(other.state, state) || other.state == state)&&(identical(other.lockedReason, lockedReason) || other.lockedReason == lockedReason)&&(identical(other.score, score) || other.score == score)&&(identical(other.window, window) || other.window == window)&&(identical(other.opensAt, opensAt) || other.opensAt == opensAt)&&(identical(other.closesAt, closesAt) || other.closesAt == closesAt)&&(identical(other.deadlineAt, deadlineAt) || other.deadlineAt == deadlineAt)&&(identical(other.resultsAt, resultsAt) || other.resultsAt == resultsAt)&&(identical(other.negativeMarking, negativeMarking) || other.negativeMarking == negativeMarking)&&(identical(other.passed, passed) || other.passed == passed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,lessonId,courseId,courseTitle,title,questions,durationMin,passMark,attemptsAllowed,attemptsUsed,state,lockedReason,score,window,opensAt,closesAt,deadlineAt,resultsAt,negativeMarking,passed]);

@override
String toString() {
  return 'AssessmentRow(id: $id, lessonId: $lessonId, courseId: $courseId, courseTitle: $courseTitle, title: $title, questions: $questions, durationMin: $durationMin, passMark: $passMark, attemptsAllowed: $attemptsAllowed, attemptsUsed: $attemptsUsed, state: $state, lockedReason: $lockedReason, score: $score, window: $window, opensAt: $opensAt, closesAt: $closesAt, deadlineAt: $deadlineAt, resultsAt: $resultsAt, negativeMarking: $negativeMarking, passed: $passed)';
}


}

/// @nodoc
abstract mixin class _$AssessmentRowCopyWith<$Res> implements $AssessmentRowCopyWith<$Res> {
  factory _$AssessmentRowCopyWith(_AssessmentRow value, $Res Function(_AssessmentRow) _then) = __$AssessmentRowCopyWithImpl;
@override @useResult
$Res call({
 String id, String lessonId, String courseId, String courseTitle, String title, int questions, int durationMin, int passMark, int attemptsAllowed, int attemptsUsed,@JsonKey(unknownEnumValue: AssessmentState.unknown) AssessmentState state, String? lockedReason, int? score,@JsonKey(unknownEnumValue: QuizWindow.unknown) QuizWindow window,@NullableUtcDateTimeConverter() DateTime? opensAt,@NullableUtcDateTimeConverter() DateTime? closesAt,@NullableUtcDateTimeConverter() DateTime? deadlineAt,@NullableUtcDateTimeConverter() DateTime? resultsAt, bool negativeMarking, bool passed
});




}
/// @nodoc
class __$AssessmentRowCopyWithImpl<$Res>
    implements _$AssessmentRowCopyWith<$Res> {
  __$AssessmentRowCopyWithImpl(this._self, this._then);

  final _AssessmentRow _self;
  final $Res Function(_AssessmentRow) _then;

/// Create a copy of AssessmentRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? lessonId = null,Object? courseId = null,Object? courseTitle = null,Object? title = null,Object? questions = null,Object? durationMin = null,Object? passMark = null,Object? attemptsAllowed = null,Object? attemptsUsed = null,Object? state = null,Object? lockedReason = freezed,Object? score = freezed,Object? window = null,Object? opensAt = freezed,Object? closesAt = freezed,Object? deadlineAt = freezed,Object? resultsAt = freezed,Object? negativeMarking = null,Object? passed = null,}) {
  return _then(_AssessmentRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lessonId: null == lessonId ? _self.lessonId : lessonId // ignore: cast_nullable_to_non_nullable
as String,courseId: null == courseId ? _self.courseId : courseId // ignore: cast_nullable_to_non_nullable
as String,courseTitle: null == courseTitle ? _self.courseTitle : courseTitle // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as int,durationMin: null == durationMin ? _self.durationMin : durationMin // ignore: cast_nullable_to_non_nullable
as int,passMark: null == passMark ? _self.passMark : passMark // ignore: cast_nullable_to_non_nullable
as int,attemptsAllowed: null == attemptsAllowed ? _self.attemptsAllowed : attemptsAllowed // ignore: cast_nullable_to_non_nullable
as int,attemptsUsed: null == attemptsUsed ? _self.attemptsUsed : attemptsUsed // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AssessmentState,lockedReason: freezed == lockedReason ? _self.lockedReason : lockedReason // ignore: cast_nullable_to_non_nullable
as String?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int?,window: null == window ? _self.window : window // ignore: cast_nullable_to_non_nullable
as QuizWindow,opensAt: freezed == opensAt ? _self.opensAt : opensAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closesAt: freezed == closesAt ? _self.closesAt : closesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deadlineAt: freezed == deadlineAt ? _self.deadlineAt : deadlineAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resultsAt: freezed == resultsAt ? _self.resultsAt : resultsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,negativeMarking: null == negativeMarking ? _self.negativeMarking : negativeMarking // ignore: cast_nullable_to_non_nullable
as bool,passed: null == passed ? _self.passed : passed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
